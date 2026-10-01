#!/usr/bin/env python3
from eiu_ota_sim import Image,SimulatedEIU
from eiu_can_ota import EIUCanOtaEndpoint,DURABLE_CHECKPOINT_BYTES
from end_to_end_ota_sim import EFISStager,EFIS_CHECKPOINT_BYTES,send_blocks
def check(ok,msg):
    if not ok:raise AssertionError(msg)
    print(f"PASS  {msg}")
source=Image.make("4.0.0",b"SERVER-HORIZON-EIU"*12000)
efis_store={};st=EFISStager(efis_store);cut=EFIS_CHECKPOINT_BYTES*2
check(st.receive(source,cut)==cut,"server->Horizon interruption reaches persistent checkpoint")
st2=EFISStager(efis_store);check(st2.begin(source)==cut,"Horizon restart resumes server download")
check(st2.receive(source)==len(source.payload),"server download completes")
check(st2.verify(source),"Horizon verifies complete cached image before CAN delivery")
staged=st2.image(source)

# Deliver enough complete 4 KiB blocks to cross 64 KiB, then add volatile progress.
store={};e=SimulatedEIU();ep=EIUCanOtaEndpoint(e,store);ep.begin(staged,77)
offset,_=send_blocks(ep,staged.payload,0,DURABLE_CHECKPOINT_BYTES)
check(ep.query().committed_offset==DURABLE_CHECKPOINT_BYTES,"Horizon->EIU leaves 64 KiB durable checkpoint")
offset,_=send_blocks(ep,staged.payload,offset,offset+8192)
check(ep.query().committed_offset==DURABLE_CHECKPOINT_BYTES,"extra 4 KiB blocks remain volatile for restart")
check(e.version=="1.0.0","interrupted delivery leaves known-good EIU active")

# Power cycle: resume at durable offset and retransmit later volatile blocks.
e2=SimulatedEIU();ep2=EIUCanOtaEndpoint(e2,store);r=ep2.begin(staged,77)
check(r.status=="RESUME" and r.committed_offset==DURABLE_CHECKPOINT_BYTES,"EIU restart resumes at durable journal offset")
offset,_=send_blocks(ep2,staged.payload,r.committed_offset)
check(offset==len(staged.payload),"resumed CAN delivery completes")
check(ep2.finish().status=="VERIFIED","complete EIU candidate verifies")
check(e2.version=="1.0.0","verification does not replace active slot")
check(ep2.activate(0).status=="REBOOT_PENDING","explicit maintenance activation accepted")
v,state=e2.first_boot(True);check(v=="4.0.0" and state=="confirmed","trial boot confirms and preserves rollback discipline")
print("\nALL END-TO-END PRODUCTION-MODEL OTA TESTS PASSED")
