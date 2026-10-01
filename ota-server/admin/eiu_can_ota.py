#!/usr/bin/env python3
"""Simulated AEF-CAN V1 maintenance transport for EIU OTA.

Uses 8-byte Classical CAN payload semantics. DATA carries a 16-bit sequence
number plus up to 6 image bytes. This is executable protocol modelling, not a
physical CAN driver.
"""
from dataclasses import dataclass
from eiu_ota_sim import Image, SimulatedEIU

CAN_IDS={"CONTROL":0x5C0,"META":0x5C1,"DATA":0x5C2,"STATUS":0x5C3}
OP={"BEGIN":1,"FINISH":2,"ACTIVATE":3}
STATUS={"READY":1,"ACK":2,"VERIFIED":3,"REJECTED":4,"REBOOT_PENDING":5}

@dataclass
class Reply:
    status: str
    sequence: int=0
    detail: str=""

class EIUCanOtaEndpoint:
    def __init__(self,eiu:SimulatedEIU):
        self.eiu=eiu; self.expected_sequence=0; self.image=None

    def begin(self,image:Image):
        ok,why=self.eiu.begin(image)
        if ok:
            self.image=image; self.expected_sequence=0
            return Reply("READY")
        return Reply("REJECTED",detail=why)

    def data(self,sequence:int,payload:bytes):
        if len(payload)>6: return Reply("REJECTED",sequence,"payload-too-large")
        if sequence!=self.expected_sequence:
            return Reply("REJECTED",self.expected_sequence,"sequence")
        self.eiu.write_block(payload)
        self.expected_sequence=(self.expected_sequence+1)&0xFFFF
        return Reply("ACK",sequence)

    def finish(self):
        ok,why=self.eiu.finish()
        return Reply("VERIFIED" if ok else "REJECTED",detail=why)

    def activate(self,engine_rpm:int):
        ok,why=self.eiu.activate(engine_rpm)
        return Reply("REBOOT_PENDING" if ok else "REJECTED",detail=why)

def transfer_image(endpoint,image,corrupt_sequence=None):
    r=endpoint.begin(image)
    if r.status!="READY": return r
    seq=0
    for offset in range(0,len(image.payload),6):
        chunk=image.payload[offset:offset+6]
        if corrupt_sequence==seq and chunk:
            chunk=bytes([chunk[0]^0x01])+chunk[1:]
        r=endpoint.data(seq,chunk)
        if r.status!="ACK": return r
        seq=(seq+1)&0xFFFF
    return endpoint.finish()
