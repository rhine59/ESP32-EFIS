#!/usr/bin/env python3
from eiu_ota_sim import Image,SimulatedEIU
from eiu_can_ota import EIUCanOtaEndpoint,transfer_image,CHECKPOINT_BYTES

def check(ok,msg):
    if not ok:raise AssertionError(msg)
    print(f"PASS  {msg}")

img=Image.make("2.1.0",b"AEF-CAN-EIU-IMAGE"*600)
store={}; e=SimulatedEIU(); ep=EIUCanOtaEndpoint(e,store)
r=ep.begin(img,37); check(r.status=="READY","new transfer ready")
seq=0
while len(e._received)<CHECKPOINT_BYTES+600:
    r=ep.data(seq,img.payload[seq*6:seq*6+6]); seq+=1
check(store["checkpoint"]["committed_offset"]==CHECKPOINT_BYTES,"4 KiB durable checkpoint recorded")
committed=store["checkpoint"]["committed_offset"]
check(ep.query().committed_offset==committed,"checkpoint query reports absolute byte offset")

# simulate power loss: volatile endpoint/EIU receive state disappears, durable checkpoint survives
e2=SimulatedEIU(); ep2=EIUCanOtaEndpoint(e2,store)
r=ep2.begin(img,37); check(r.status=="RESUME" and r.committed_offset==committed,"matching transfer resumes after restart")
seq=r.sequence
for pos in range(committed,len(img.payload),6):
    r=ep2.data(seq,img.payload[pos:pos+6]); seq+=1
r=ep2.finish(); check(r.status=="VERIFIED","resumed image verifies end-to-end")
check(e2.version=="1.0.0","known-good running slot untouched before activation")
r=ep2.activate(0); check(r.status=="REBOOT_PENDING","verified resumed image can activate")
v,state=e2.first_boot(True); check(v=="2.1.0" and state=="confirmed","resumed update confirms")

# mismatched image/transfer must not reuse checkpoint
store={}; e=SimulatedEIU(); ep=EIUCanOtaEndpoint(e,store); ep.begin(img,50)
seq=0
while len(e._received)<CHECKPOINT_BYTES:
    ep.data(seq,img.payload[seq*6:seq*6+6]);seq+=1
other=Image.make("2.2.0",b"DIFFERENT"*700)
e3=SimulatedEIU(); r=EIUCanOtaEndpoint(e3,store).begin(other,50)
check(r.status=="READY" and r.committed_offset==0,"different image cannot inherit checkpoint")
print("\nALL RESUMABLE AEF-CAN EIU OTA TESTS PASSED")
