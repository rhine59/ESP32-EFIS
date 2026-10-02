#!/usr/bin/env python3
"""AEF-CAN production-model SMUX OTA transport simulation.

Classical CAN V1 model:
- FW_DATA carries one local sequence byte + up to seven firmware bytes.
- 4 KiB transfer blocks are CRC32 checked and ACK/NACKed as units.
- 4 KiB progress is volatile.
- durable resume checkpoints are append-only journal records nominally every 64 KiB.
This is executable protocol simulation, not physical CAN/flash validation.
"""
from dataclasses import dataclass
import zlib
from smux_ota_sim import Image, SimulatedEIU

CAN_IDS={"CONTROL":0x5C0,"META":0x5C1,"DATA":0x5C2,"STATUS":0x5C3,"CHECKPOINT":0x5C4}
OP={"BEGIN":1,"FINISH":2,"ACTIVATE":3,"QUERY":4}
DATA_BYTES=7
BLOCK_BYTES=4096
DURABLE_CHECKPOINT_BYTES=65536
JOURNAL_SLOTS=16

@dataclass
class Reply:
    status:str
    sequence:int=0
    detail:str=""
    transfer_id:int=0
    committed_offset:int=0
    checkpoint_crc32:int=0

class CheckpointJournal:
    def __init__(self,store):
        self.store=store
        self.store.setdefault("journal",[])
        self.store.setdefault("generation",0)
    def _valid(self,r,image,transfer_id):
        if r.get("incomplete"): return False
        body=f'{r["generation"]}:{r["transfer_id"]}:{r["sha256"]}:{r["committed_offset"]}'.encode()
        return (r.get("record_crc32")==zlib.crc32(body)&0xffffffff and
                r["transfer_id"]==transfer_id and r["sha256"]==image.sha256)
    def newest(self,image,transfer_id):
        valid=[r for r in self.store["journal"] if self._valid(r,image,transfer_id)]
        return max(valid,key=lambda r:r["generation"]) if valid else None
    def append(self,image,transfer_id,offset,incomplete=False):
        self.store["generation"]+=1; g=self.store["generation"]
        body=f"{g}:{transfer_id}:{image.sha256}:{offset}".encode()
        r={"generation":g,"transfer_id":transfer_id,"sha256":image.sha256,
           "committed_offset":offset,"record_crc32":zlib.crc32(body)&0xffffffff}
        if incomplete:r["incomplete"]=True
        self.store["journal"].append(r)
        if len(self.store["journal"])>JOURNAL_SLOTS:
            # Model rotating/reclaiming journal space, never a fixed checkpoint sector.
            self.store["journal"]=self.store["journal"][-JOURNAL_SLOTS:]
        return r

class EIUCanOtaEndpoint:
    def __init__(self,smux:SimulatedEIU,persistent=None):
        self.smux=smux; self.store=persistent if persistent is not None else {}
        self.journal=CheckpointJournal(self.store)
        self.expected_sequence=0; self.image=None; self.transfer_id=0
        self.block_start=0; self.block=bytearray(); self.volatile_committed=0

    def begin(self,image:Image,transfer_id:int=1):
        saved=self.journal.newest(image,transfer_id)
        ok,why=self.smux.begin(image)
        if not ok:return Reply("REJECTED",detail=why)
        self.image=image; self.transfer_id=transfer_id
        committed=saved["committed_offset"] if saved else 0
        if committed:
            self.smux.write_block(image.payload[:committed])
        self.block_start=committed; self.volatile_committed=committed; self.block=bytearray()
        self.expected_sequence=0
        return Reply("RESUME" if saved else "READY",0,transfer_id=transfer_id,
                     committed_offset=committed,
                     checkpoint_crc32=(saved or {}).get("record_crc32",0))

    def query(self):
        if self.image is None:return Reply("NO_TRANSFER")
        saved=self.journal.newest(self.image,self.transfer_id)
        if not saved:return Reply("NO_CHECKPOINT",transfer_id=self.transfer_id)
        return Reply("CHECKPOINT",transfer_id=self.transfer_id,
                     committed_offset=saved["committed_offset"],
                     checkpoint_crc32=saved["record_crc32"])

    def data(self,sequence:int,payload:bytes):
        if len(payload)>DATA_BYTES:return Reply("REJECTED",self.expected_sequence,"payload-too-large")
        if sequence!=self.expected_sequence:return Reply("REJECTED",self.expected_sequence,"sequence")
        self.block.extend(payload); self.expected_sequence=(self.expected_sequence+1)&0xff
        return Reply("FRAME_ACCEPTED",sequence,transfer_id=self.transfer_id,
                     committed_offset=self.volatile_committed)

    def block_commit(self,expected_crc32:int):
        if not self.block:return Reply("NACK",detail="empty-block")
        actual=zlib.crc32(self.block)&0xffffffff
        if actual!=expected_crc32:
            self.block=bytearray(); self.expected_sequence=0
            return Reply("NACK",detail="block-crc32",transfer_id=self.transfer_id,
                         committed_offset=self.volatile_committed)
        self.smux.write_block(bytes(self.block)); self.volatile_committed+=len(self.block)
        self.block=bytearray(); self.expected_sequence=0
        # Persist only complete 64 KiB boundaries. Final verification is separate.
        durable=(self.volatile_committed//DURABLE_CHECKPOINT_BYTES)*DURABLE_CHECKPOINT_BYTES
        saved=self.journal.newest(self.image,self.transfer_id)
        prior=saved["committed_offset"] if saved else 0
        if durable>prior:
            r=self.journal.append(self.image,self.transfer_id,durable)
            return Reply("BLOCK_ACK_CHECKPOINT",transfer_id=self.transfer_id,
                         committed_offset=durable,checkpoint_crc32=r["record_crc32"])
        return Reply("BLOCK_ACK",transfer_id=self.transfer_id,
                     committed_offset=self.volatile_committed)

    def finish(self):
        if self.block:return Reply("REJECTED",detail="uncommitted-block",transfer_id=self.transfer_id)
        ok,why=self.smux.finish()
        return Reply("VERIFIED" if ok else "REJECTED",detail=why,transfer_id=self.transfer_id)

    def activate(self,engine_rpm:int):
        ok,why=self.smux.activate(engine_rpm)
        return Reply("REBOOT_PENDING" if ok else "REJECTED",detail=why)

def transfer_image(endpoint,image,transfer_id=1,corrupt_block=None):
    r=endpoint.begin(image,transfer_id)
    if r.status not in ("READY","RESUME"):return r
    offset=r.committed_offset
    block_no=offset//BLOCK_BYTES
    while offset<len(image.payload):
        raw=image.payload[offset:min(offset+BLOCK_BYTES,len(image.payload))]
        seq=0
        for p in range(0,len(raw),DATA_BYTES):
            rr=endpoint.data(seq,raw[p:p+DATA_BYTES])
            if rr.status!="FRAME_ACCEPTED":return rr
            seq=(seq+1)&0xff
        crc=zlib.crc32(raw)&0xffffffff
        if corrupt_block==block_no:crc^=1
        rr=endpoint.block_commit(crc)
        if rr.status=="NACK":return rr
        offset+=len(raw); block_no+=1
    return endpoint.finish()
