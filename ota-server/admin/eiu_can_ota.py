#!/usr/bin/env python3
"""Simulated AEF-CAN V1 maintenance transport for resumable EIU OTA."""
from dataclasses import dataclass
import zlib
from eiu_ota_sim import Image, SimulatedEIU

CAN_IDS={"CONTROL":0x5C0,"META":0x5C1,"DATA":0x5C2,"STATUS":0x5C3,"CHECKPOINT":0x5C4}
OP={"BEGIN":1,"FINISH":2,"ACTIVATE":3,"QUERY":4}
CHECKPOINT_BYTES=4096

@dataclass
class Reply:
    status:str
    sequence:int=0
    detail:str=""
    transfer_id:int=0
    committed_offset:int=0
    checkpoint_crc32:int=0

class EIUCanOtaEndpoint:
    def __init__(self,eiu:SimulatedEIU,persistent=None):
        self.eiu=eiu
        self.store=persistent if persistent is not None else {}
        self.expected_sequence=0; self.image=None; self.transfer_id=0
        self._block=bytearray()

    def begin(self,image:Image,transfer_id:int=1):
        saved=self.store.get("checkpoint")
        if saved and saved["transfer_id"]==transfer_id and saved["sha256"]==image.sha256:
            ok,why=self.eiu.begin(image)
            if not ok:return Reply("REJECTED",detail=why)
            committed=saved["committed_offset"]
            self.eiu.write_block(image.payload[:committed])
            self.image=image; self.transfer_id=transfer_id
            self.expected_sequence=(committed+5)//6
            return Reply("RESUME",self.expected_sequence,transfer_id=transfer_id,
                         committed_offset=committed,checkpoint_crc32=saved["crc32"])
        ok,why=self.eiu.begin(image)
        if not ok:return Reply("REJECTED",detail=why)
        self.image=image; self.transfer_id=transfer_id; self.expected_sequence=0
        self._block=bytearray()
        return Reply("READY",transfer_id=transfer_id)

    def query(self):
        saved=self.store.get("checkpoint")
        if not saved:return Reply("NO_TRANSFER")
        return Reply("CHECKPOINT",transfer_id=saved["transfer_id"],
                     committed_offset=saved["committed_offset"],
                     checkpoint_crc32=saved["crc32"])

    def data(self,sequence:int,payload:bytes):
        if len(payload)>6:return Reply("REJECTED",sequence,"payload-too-large")
        if sequence!=self.expected_sequence:return Reply("REJECTED",self.expected_sequence,"sequence")
        self.eiu.write_block(payload); self._block.extend(payload)
        self.expected_sequence=(self.expected_sequence+1)&0xFFFF
        received=len(self.eiu._received)
        boundary=(received//CHECKPOINT_BYTES)*CHECKPOINT_BYTES
        saved=self.store.get("checkpoint",{}).get("committed_offset",0)
        if boundary>saved:
            block=bytes(self.eiu._received[boundary-CHECKPOINT_BYTES:boundary])
            crc=zlib.crc32(block)&0xffffffff
            self.store["checkpoint"]={"transfer_id":self.transfer_id,"sha256":self.image.sha256,
                                      "committed_offset":boundary,"crc32":crc}
            self._block=bytearray(self.eiu._received[boundary:])
            return Reply("CHECKPOINT",sequence,transfer_id=self.transfer_id,
                         committed_offset=boundary,checkpoint_crc32=crc)
        return Reply("ACK",sequence,transfer_id=self.transfer_id,committed_offset=saved)

    def finish(self):
        ok,why=self.eiu.finish()
        if ok:self.store.pop("checkpoint",None)
        return Reply("VERIFIED" if ok else "REJECTED",detail=why,transfer_id=self.transfer_id)

    def activate(self,engine_rpm:int):
        ok,why=self.eiu.activate(engine_rpm)
        return Reply("REBOOT_PENDING" if ok else "REJECTED",detail=why)

def transfer_image(endpoint,image,transfer_id=1,start_offset=0,corrupt_sequence=None):
    r=endpoint.begin(image,transfer_id)
    if r.status not in ("READY","RESUME"):return r
    offset=r.committed_offset if r.status=="RESUME" else start_offset
    seq=(offset+5)//6
    for pos in range(offset,len(image.payload),6):
        chunk=image.payload[pos:pos+6]
        if corrupt_sequence==seq and chunk:chunk=bytes([chunk[0]^1])+chunk[1:]
        r=endpoint.data(seq,chunk)
        if r.status not in ("ACK","CHECKPOINT"):return r
        seq=(seq+1)&0xffff
    return endpoint.finish()
