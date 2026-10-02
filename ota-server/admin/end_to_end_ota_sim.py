#!/usr/bin/env python3
"""End-to-end resumable OTA simulation: release service -> Horizon -> AEF-CAN -> SMUX."""
from dataclasses import dataclass,field
import hashlib,zlib
from smux_ota_sim import Image
from smux_can_ota import DATA_BYTES,BLOCK_BYTES
EFIS_CHECKPOINT_BYTES=65536
@dataclass
class EFISStager:
    persistent:dict=field(default_factory=dict)
    def begin(self,image):
        s=self.persistent.get("stage")
        if not s or s["sha256"]!=image.sha256 or s["size"]!=len(image.payload):
            s={"sha256":image.sha256,"size":len(image.payload),"data":bytearray(),"committed_offset":0,"verified":False};self.persistent["stage"]=s
        return s["committed_offset"]
    def receive(self,image,stop_after=None):
        offset=self.begin(image);s=self.persistent["stage"];limit=len(image.payload) if stop_after is None else min(len(image.payload),stop_after)
        while offset<limit:
            end=min(offset+EFIS_CHECKPOINT_BYTES,limit);s["data"].extend(image.payload[offset:end]);offset=end;s["committed_offset"]=offset
        return offset
    def verify(self,image):
        s=self.persistent["stage"];ok=len(s["data"])==len(image.payload) and hashlib.sha256(bytes(s["data"])).hexdigest()==image.sha256;s["verified"]=ok;return ok
    def image(self,image):
        if not self.persistent["stage"].get("verified"):raise RuntimeError("Horizon image not verified")
        return Image.make(image.version,bytes(self.persistent["stage"]["data"]),image.hardware)
def send_blocks(ep,payload,offset=0,limit=None):
    end=len(payload) if limit is None else min(len(payload),limit);r=None
    while offset<end:
        raw=payload[offset:min(offset+BLOCK_BYTES,end)];seq=0
        for p in range(0,len(raw),DATA_BYTES):
            r=ep.data(seq,raw[p:p+DATA_BYTES])
            if r.status!="FRAME_ACCEPTED":return offset,r
            seq=(seq+1)&0xff
        r=ep.block_commit(zlib.crc32(raw)&0xffffffff)
        if not r.status.startswith("BLOCK_ACK"):return offset,r
        offset+=len(raw)
    return offset,r
