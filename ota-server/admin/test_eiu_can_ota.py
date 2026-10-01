#!/usr/bin/env python3
from eiu_ota_sim import Image,SimulatedEIU
from eiu_can_ota import *

def check(ok,msg):
    if not ok:raise AssertionError(msg)
    print(f"PASS  {msg}")

img=Image.make("2.1.0",b"AEF-CAN-EIU-IMAGE"*9000)
store={}; e=SimulatedEIU(); ep=EIUCanOtaEndpoint(e,store)
r=ep.begin(img,37); check(r.status=="READY","new transfer ready")

# A complete 4 KiB block is volatile/ACKed, not a durable flash checkpoint.
raw=img.payload[:BLOCK_BYTES]; seq=0
for p in range(0,len(raw),DATA_BYTES):
    check(ep.data(seq,raw[p:p+DATA_BYTES]).status=="FRAME_ACCEPTED","7-byte FW_DATA frame accepted")
    seq=(seq+1)&0xff
check(ep.block_commit(zlib.crc32(raw)&0xffffffff).status=="BLOCK_ACK","4 KiB block CRC/ACK is volatile")
check(ep.query().status=="NO_CHECKPOINT","4 KiB progress does not write durable checkpoint")

# Transfer through first 64 KiB boundary.
offset=BLOCK_BYTES
while offset<DURABLE_CHECKPOINT_BYTES:
    raw=img.payload[offset:offset+BLOCK_BYTES]; seq=0
    for p in range(0,len(raw),DATA_BYTES):
        ep.data(seq,raw[p:p+DATA_BYTES]);seq=(seq+1)&0xff
    ep.block_commit(zlib.crc32(raw)&0xffffffff);offset+=len(raw)
q=ep.query(); check(q.committed_offset==DURABLE_CHECKPOINT_BYTES,"64 KiB durable checkpoint recorded")
check(len(store["journal"])==1,"checkpoint journal appends rather than rewriting per block")
check(e.version=="1.0.0","active A/B slot unchanged during transfer")

# Power loss discards volatile progress but resumes at newest durable record.
extra=img.payload[offset:offset+BLOCK_BYTES];seq=0
for p in range(0,len(extra),DATA_BYTES): ep.data(seq,extra[p:p+DATA_BYTES]);seq=(seq+1)&0xff
ep.block_commit(zlib.crc32(extra)&0xffffffff)
e2=SimulatedEIU(); ep2=EIUCanOtaEndpoint(e2,store)
r=ep2.begin(img,37);check(r.status=="RESUME" and r.committed_offset==DURABLE_CHECKPOINT_BYTES,"power loss resumes at durable 64 KiB checkpoint")

# Corrupt/incomplete newest journal records are ignored.
bad=ep2.journal.append(img,37,DURABLE_CHECKPOINT_BYTES*2,incomplete=True)
r=EIUCanOtaEndpoint(SimulatedEIU(),store).begin(img,37)
check(r.committed_offset==DURABLE_CHECKPOINT_BYTES,"incomplete newest checkpoint ignored")
store["journal"][-1]["incomplete"]=False; store["journal"][-1]["record_crc32"]^=1
r=EIUCanOtaEndpoint(SimulatedEIU(),store).begin(img,37)
check(r.committed_offset==DURABLE_CHECKPOINT_BYTES,"corrupt newest checkpoint ignored")

# Wrong image identity cannot inherit the journal.
other=Image.make("2.2.0",b"DIFFERENT"*10000)
r=EIUCanOtaEndpoint(SimulatedEIU(),store).begin(other,37)
check(r.status=="READY" and r.committed_offset==0,"different image cannot inherit checkpoint")

# CRC NACK does not write the block to candidate flash.
e3=SimulatedEIU(); ep3=EIUCanOtaEndpoint(e3,{})
ep3.begin(img,99); raw=img.payload[:BLOCK_BYTES];seq=0
for p in range(0,len(raw),DATA_BYTES):ep3.data(seq,raw[p:p+DATA_BYTES]);seq=(seq+1)&0xff
check(ep3.block_commit((zlib.crc32(raw)&0xffffffff)^1).status=="NACK","bad 4 KiB CRC is NACKed")
check(len(e3._received)==0,"NACKed block is not committed to candidate")

# Complete resume, verify, activate and confirm.
ep4=EIUCanOtaEndpoint(SimulatedEIU(),store); r=ep4.begin(img,37); offset=r.committed_offset
while offset<len(img.payload):
    raw=img.payload[offset:min(offset+BLOCK_BYTES,len(img.payload))];seq=0
    for p in range(0,len(raw),DATA_BYTES):ep4.data(seq,raw[p:p+DATA_BYTES]);seq=(seq+1)&0xff
    check(ep4.block_commit(zlib.crc32(raw)&0xffffffff).status.startswith("BLOCK_ACK"),"block accepted")
    offset+=len(raw)
check(ep4.finish().status=="VERIFIED","complete image verifies")
check(ep4.eiu.version=="1.0.0","verified candidate still leaves active slot untouched")
check(ep4.activate(0).status=="REBOOT_PENDING","explicit stationary activation accepted")
v,state=ep4.eiu.first_boot(True);check(v=="2.1.0" and state=="confirmed","trial boot confirms new slot")
print("\nALL PRODUCTION-MODEL AEF-CAN EIU OTA TESTS PASSED")
