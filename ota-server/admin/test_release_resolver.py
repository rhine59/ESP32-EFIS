#!/usr/bin/env python3
from release_resolver import NodeState,Artifact,Requirement,resolve_order,rollback_safe

def caps(*x): return frozenset(x)
def check(ok,msg):
    if not ok: raise AssertionError(msg)
    print("PASS ",msg)

old={
 "horizon":NodeState("horizon","2.4.0",1,2,caps("ENGINE_DATA_V1","OTA_V1"),"H1"),
 "eiu":NodeState("eiu","1.7.0",1,2,caps("ENGINE_DATA_V1","OTA_V1"),"E1"),
}
# New EIU preserves V1 and adds V2. New Horizon requires V2, so EIU must go first.
release=[
 Artifact("eiu","1.9.0",1,3,caps("ENGINE_DATA_V1","ENGINE_DATA_V2","OTA_V1"),"E1"),
 Artifact("horizon","2.5.0",1,3,caps("ENGINE_DATA_V1","ENGINE_DATA_V2","OTA_V1"),"H1",
          (Requirement("eiu",1,3,caps("ENGINE_DATA_V2")),)),
]
order=resolve_order(old,release)
check(order==["eiu","horizon"],"resolver selects EIU before dependent Horizon")
ok,why=rollback_safe(old,release,order)
check(ok,"coordinated release preserves rollback compatibility")

# Missing required capability cannot be resolved.
bad=[
 Artifact("eiu","1.8.0",1,3,caps("ENGINE_DATA_V1","OTA_V1"),"E1"),
 release[1],
]
try:
    resolve_order(old,bad)
    raise AssertionError("missing capability accepted")
except ValueError:
    print("PASS  missing required capability blocks release")

# Hardware mismatch is rejected.
wrong=[
 Artifact("eiu","1.9.0",1,3,caps("ENGINE_DATA_V1","ENGINE_DATA_V2","OTA_V1"),"E2"),
 release[1],
]
try:
    resolve_order(old,wrong)
    raise AssertionError("wrong hardware accepted")
except ValueError:
    print("PASS  wrong hardware blocks release")

# Major protocol break with no transition path is not normal OTA.
major=[
 Artifact("eiu","2.0.0",2,0,caps("ENGINE_DATA_V2"),"E1"),
 Artifact("horizon","3.0.0",2,0,caps("ENGINE_DATA_V2"),"H1",
          (Requirement("eiu",2,0,caps("ENGINE_DATA_V2")),)),
]
try:
    resolve_order(old,major)
    raise AssertionError("unsafe major migration accepted")
except ValueError:
    print("PASS  incompatible major transition requires special migration")

print("\nALL RELEASE DEPENDENCY TESTS PASSED")
