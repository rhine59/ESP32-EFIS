#!/usr/bin/env python3
"""End-to-end resumable OTA simulation: release service -> EFIS -> AEF-CAN -> EIU."""
from dataclasses import dataclass,field
import hashlib
from eiu_ota_sim import Image,SimulatedEIU
from eiu_can_ota import EIUCanOtaEndpoint

EFIS_CHECKPOINT_BYTES=65536

@dataclass
class EFISStager:
    persistent:dict=field(default_factory=dict)
    def begin(self,image):
        s=self.persistent.get("stage")
        if not s or s["sha256"]!=image.sha256 or s["size"]!=len(image.payload):
            s={"sha256":image.sha256,"size":len(image.payload),"data":bytearray(),"committed_offset":0,"verified":False}
            self.persistent["stage"]=s
        return s["committed_offset"]
    def receive(self,image,stop_after=None):
        offset=self.begin(image); s=self.persistent["stage"]
        limit=len(image.payload) if stop_after is None else min(len(image.payload),stop_after)
        while offset<limit:
            end=min(offset+EFIS_CHECKPOINT_BYTES,limit)
            s["data"].extend(image.payload[offset:end]); offset=end
            s["committed_offset"]=offset
        return offset
    def verify(self,image):
        s=self.persistent["stage"]
        ok=len(s["data"])==len(image.payload) and hashlib.sha256(bytes(s["data"])).hexdigest()==image.sha256
        s["verified"]=ok
        return ok
    def image(self,image):
        if not self.persistent["stage"].get("verified"): raise RuntimeError("EFIS image not verified")
        return Image.make(image.version,bytes(self.persistent["stage"]["data"]),image.hardware)

def send_to_eiu(stager,source,eiu_store,interrupt_after=None):
    staged=stager.image(source); e=SimulatedEIU(); ep=EIUCanOtaEndpoint(e,eiu_store)
    r=ep.begin(staged,77); offset=r.committed_offset if r.status=="RESUME" else 0
    seq=(offset+5)//6
    limit=len(staged.payload) if interrupt_after is None else min(len(staged.payload),interrupt_after)
    for pos in range(offset,limit,6):
        r=ep.data(seq,staged.payload[pos:min(pos+6,limit)]); seq+=1
    if limit<len(staged.payload): return e,ep,False
    return e,ep,ep.finish().status=="VERIFIED"
