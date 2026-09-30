#!/usr/bin/env python3
"""Validate structural invariants of protocol/aef-can.yaml."""
from pathlib import Path
import sys
try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: python -m pip install PyYAML")

ROOT=Path(__file__).resolve().parents[1]
SPEC=ROOT/"protocol"/"aef-can.yaml"
doc=yaml.safe_load(SPEC.read_text())
errors=[]
p=doc["protocol"]; t=p["transport"]
if t["baseline"]!="classical-can": errors.append("V1 baseline must be classical-can")
if t["identifier_bits"]!=11: errors.append("V1 identifiers must be 11-bit")
ids={}
sizes={"uint8":1,"int8":1,"uint16":2,"int16":2,"uint32":4,"int32":4}
for m in doc["messages"]:
    mid=m["id"]
    if not 0 <= mid <= 0x7ff: errors.append(f"{m['name']}: ID outside 11-bit range")
    if mid in ids: errors.append(f"{m['name']}: duplicate ID with {ids[mid]}")
    ids[mid]=m["name"]
    used=[]
    for f in m.get("fields",[]):
        n=f.get("length",sizes.get(f["type"]))
        if n is None: errors.append(f"{m['name']}.{f['name']}: unknown size")
        else: used.extend(range(f["offset"],f["offset"]+n))
    if used and max(used)>=8: errors.append(f"{m['name']}: field exceeds 8-byte Classical CAN payload")
    if len(used)!=len(set(used)): errors.append(f"{m['name']}: overlapping fields")
for name,val in doc["sensor_states"].items():
    if not 0 <= val <= 255: errors.append(f"sensor state {name} outside uint8")
if errors:
    print("\n".join("ERROR: "+e for e in errors)); sys.exit(1)
print(f"PASS: {p['name']} {p['version']['major']}.{p['version']['minor']} — {len(ids)} message definitions validated")
