#!/usr/bin/env python3
"""Regression tests for the transport-neutral simulated SMUX OTA target."""
from smux_ota_sim import Image, SimulatedEIU

def check(ok, msg):
    if not ok:
        raise AssertionError(msg)
    print(f"PASS  {msg}")

def transfer(smux, image, payload=None, block=37):
    ok, why=smux.begin(image); check(ok, "candidate accepted")
    data=image.payload if payload is None else payload
    for i in range(0,len(data),block):
        smux.write_block(data[i:i+block])
    return smux.finish()

v2=Image.make("2.0.0", b"SMUX-V2-GREEN-LED"*64)
v3=Image.make("3.0.0", b"SMUX-V3-BLUE-LED"*64)

e=SimulatedEIU()
baseline=dict(e.configuration)
check(e.announce()["firmware"]=="1.0.0", "discovery reports running firmware")
ok,why=e.begin(Image.make("9.0.0",b"x",hardware="SMUX-V2")); check(not ok and why=="wrong-hardware","wrong hardware rejected")

ok,why=transfer(e,v2); check(ok and why=="verified","v2 complete image verifies")
ok,why=e.activate(1800); check(not ok and why=="engine-running","activation blocked with engine running")
ok,why=e.activate(0); check(ok,"activation allowed at RPM zero")
version,state=e.first_boot(True); check(version=="2.0.0" and state=="confirmed","v2 first boot confirmed")
check(e.configuration==baseline,"commissioned configuration preserved")

bad=bytearray(v3.payload); bad[-1]^=0xFF
ok,why=e.begin(v3); check(ok,"v3 candidate accepted")
for i in range(0,len(bad),41): e.write_block(bytes(bad[i:i+41]))
ok,why=e.finish(); check(not ok and why=="hash-failure","corrupt transfer rejected")
check(e.version=="2.0.0","corrupt transfer leaves active firmware unchanged")

ok,why=transfer(e,v3); check(ok,"v3 verifies")
ok,why=e.activate(0); check(ok,"v3 activation requested")
version,state=e.first_boot(False); check(version=="2.0.0" and state=="rolled-back","failed first boot rolls back")
check(e.configuration==baseline,"configuration survives rollback")

print("\nALL SIMULATED SMUX OTA TESTS PASSED")
