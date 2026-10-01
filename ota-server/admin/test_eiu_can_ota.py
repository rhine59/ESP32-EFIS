#!/usr/bin/env python3
"""AEF-CAN EIU OTA transport regression tests."""
from eiu_ota_sim import Image,SimulatedEIU
from eiu_can_ota import EIUCanOtaEndpoint,transfer_image

def check(ok,msg):
    if not ok: raise AssertionError(msg)
    print(f"PASS  {msg}")

img=Image.make("2.1.0",b"AEF-CAN-EIU-IMAGE"*31)
e=SimulatedEIU(); ep=EIUCanOtaEndpoint(e)

r=ep.begin(img); check(r.status=="READY","BEGIN -> READY")
r=ep.data(1,b"abcdef"); check(r.status=="REJECTED" and r.detail=="sequence" and r.sequence==0,"out-of-order block rejected")
r=ep.data(0,b"abcdefg"); check(r.status=="REJECTED" and r.detail=="payload-too-large","Classical CAN data payload limit enforced")

e=SimulatedEIU(); ep=EIUCanOtaEndpoint(e)
r=transfer_image(ep,img,corrupt_sequence=2); check(r.status=="REJECTED" and r.detail=="hash-failure","end-to-end corruption rejected")
check(e.version=="1.0.0","failed transfer leaves running slot unchanged")

e=SimulatedEIU(); ep=EIUCanOtaEndpoint(e); baseline=dict(e.configuration)
r=transfer_image(ep,img); check(r.status=="VERIFIED","segmented AEF-CAN transfer verifies")
r=ep.activate(900); check(r.status=="REJECTED" and r.detail=="engine-running","CAN activation rejected while engine running")
r=ep.activate(0); check(r.status=="REBOOT_PENDING","CAN activation accepted at RPM zero")
v,state=e.first_boot(True); check(v=="2.1.0" and state=="confirmed","new EIU image confirmed after reboot")
check(e.configuration==baseline,"commissioning preserved across CAN update")
print("\nALL SIMULATED AEF-CAN EIU OTA TESTS PASSED")
