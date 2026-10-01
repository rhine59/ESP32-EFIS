#!/usr/bin/env python3
from eiu_ota_sim import Image,SimulatedEIU
from eiu_can_ota import EIUCanOtaEndpoint
from end_to_end_ota_sim import EFISStager,EFIS_CHECKPOINT_BYTES

def check(ok,msg):
    if not ok: raise AssertionError(msg)
    print(f"PASS  {msg}")

source=Image.make("4.0.0",b"SERVER-EFIS-EIU"*12000)
efis_store={}; st=EFISStager(efis_store)
cut=EFIS_CHECKPOINT_BYTES*2
n=st.receive(source,cut); check(n==cut,"server->EFIS interruption reaches persistent checkpoint")
st2=EFISStager(efis_store); check(st2.begin(source)==cut,"EFIS restart resumes server download at committed offset")
check(st2.receive(source)==len(source.payload),"server download completes without restarting")
check(st2.verify(source),"EFIS verifies complete staged image before CAN delivery")
staged=st2.image(source)

# Interrupt EIU transfer after at least two durable 4 KiB checkpoints.
eiu_store={}; e=SimulatedEIU(); ep=EIUCanOtaEndpoint(e,eiu_store)
r=ep.begin(staged,77); seq=0
target=9000
for pos in range(0,target,6):
    ep.data(seq,staged.payload[pos:min(pos+6,target)]);seq+=1
committed=ep.query().committed_offset
check(committed>=8192,"EFIS->EIU interruption leaves durable CAN checkpoint")
check(e.version=="1.0.0","interrupted CAN delivery leaves known-good EIU firmware running")

# Simulated power cycle: new volatile EIU/endpoint, same durable update metadata.
e2=SimulatedEIU(); ep2=EIUCanOtaEndpoint(e2,eiu_store)
r=ep2.begin(staged,77); check(r.status=="RESUME" and r.committed_offset==committed,"EIU restart resumes from durable offset")
seq=r.sequence
for pos in range(committed,len(staged.payload),6):
    ep2.data(seq,staged.payload[pos:pos+6]);seq+=1
check(ep2.finish().status=="VERIFIED","resumed end-to-end image verifies at EIU")
check(e2.version=="1.0.0","verified candidate still does not replace active firmware")
check(ep2.activate(0).status=="REBOOT_PENDING","explicit activation accepted")
v,state=e2.first_boot(True); check(v=="4.0.0" and state=="confirmed","end-to-end recovered update boots and confirms")
print("\nALL END-TO-END RESUMABLE OTA TESTS PASSED")
