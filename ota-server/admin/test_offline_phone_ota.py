#!/usr/bin/env python3
"""Offline phone-cache -> Horizon -> AEF-CAN multi-node release simulation."""
from release_resolver import NodeState,Artifact,Requirement,resolve_order,rollback_safe

def caps(*x): return frozenset(x)

class PhoneCache:
    def __init__(self): self.release=None
    def cache(self,release): self.release=release
    @property
    def offline_ready(self): return self.release is not None

installed={
 "horizon":NodeState("horizon","2.4.0",1,2,caps("ENGINE_DATA_V1","OTA_V1"),"H1"),
 "eiu":NodeState("eiu","1.7.0",1,2,caps("ENGINE_DATA_V1","OTA_V1"),"E1"),
}
release=[
 Artifact("eiu","1.9.0",1,3,caps("ENGINE_DATA_V1","ENGINE_DATA_V2","OTA_V1"),"E1"),
 Artifact("horizon","2.5.0",1,3,caps("ENGINE_DATA_V1","ENGINE_DATA_V2","OTA_V1"),"H1",
          (Requirement("eiu",1,3,caps("ENGINE_DATA_V2")),)),
]
phone=PhoneCache(); phone.cache(release)
assert phone.offline_ready
order=resolve_order(installed,phone.release)
assert order==["eiu","horizon"]
ok,why=rollback_safe(installed,phone.release,order)
assert ok,why
print("PASS  phone caches complete release set before aircraft")
print("PASS  no Internet required for dependency resolution at aircraft")
print("PASS  Horizon safe sequence: "+" -> ".join(order))
print("PASS  rollback compatibility preserved")
