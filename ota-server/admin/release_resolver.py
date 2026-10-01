#!/usr/bin/env python3
"""Generic AEF-CAN multi-node release-set compatibility resolver."""
from dataclasses import dataclass
from typing import FrozenSet, Iterable

@dataclass(frozen=True)
class NodeState:
    node_type: str
    firmware: str
    protocol_major: int
    protocol_minor: int
    capabilities: FrozenSet[str]
    hardware: str = "*"

@dataclass(frozen=True)
class Artifact:
    node_type: str
    firmware: str
    protocol_major: int
    protocol_minor: int
    capabilities: FrozenSet[str]
    hardware: str = "*"
    requires: tuple = ()

@dataclass(frozen=True)
class Requirement:
    node_type: str
    protocol_major: int
    min_protocol_minor: int = 0
    capabilities: FrozenSet[str] = frozenset()

def satisfies(node: NodeState, req: Requirement) -> bool:
    return (node.node_type == req.node_type
            and node.protocol_major == req.protocol_major
            and node.protocol_minor >= req.min_protocol_minor
            and req.capabilities.issubset(node.capabilities))

def as_state(a: Artifact) -> NodeState:
    return NodeState(a.node_type,a.firmware,a.protocol_major,a.protocol_minor,a.capabilities,a.hardware)

def compatible(state: dict[str,NodeState], artifacts: Iterable[Artifact]) -> tuple[bool,str]:
    for a in artifacts:
        installed=state.get(a.node_type)
        if installed and a.hardware not in ("*",installed.hardware):
            return False,f"{a.node_type}: hardware {installed.hardware} incompatible with artifact {a.hardware}"
        for req in a.requires:
            peer=state.get(req.node_type)
            if not peer or not satisfies(peer,req):
                return False,f"{a.node_type} requires {req.node_type} protocol {req.protocol_major}.{req.min_protocol_minor}+ capabilities {sorted(req.capabilities)}"
    return True,"compatible"

def resolve_order(installed: dict[str,NodeState], artifacts: Iterable[Artifact]) -> list[str]:
    artifacts={a.node_type:a for a in artifacts}
    pending=set(artifacts); state=dict(installed); order=[]
    while pending:
        progressed=False
        for name in sorted(pending):
            candidate=dict(state); candidate[name]=as_state(artifacts[name])
            ok,_=compatible(candidate,artifacts.values())
            if ok:
                state=candidate; order.append(name); pending.remove(name); progressed=True; break
        if not progressed:
            reasons=[]
            for name in sorted(pending):
                candidate=dict(state); candidate[name]=as_state(artifacts[name])
                ok,why=compatible(candidate,artifacts.values())
                if not ok: reasons.append(f"{name}: {why}")
            raise ValueError("no safe update order; "+("; ".join(reasons)))
    return order

def rollback_safe(installed: dict[str,NodeState], artifacts: Iterable[Artifact], order: list[str]) -> tuple[bool,str]:
    artifacts={a.node_type:a for a in artifacts}; state=dict(installed)
    for name in order:
        before=state[name]
        state[name]=as_state(artifacts[name])
        ok,why=compatible(state,artifacts.values())
        if not ok: return False,f"after {name}: {why}"
        # Candidate may roll back while already-updated peers remain new.
        trial=dict(state); trial[name]=before
        ok,why=compatible(trial,artifacts.values())
        if not ok: return False,f"rollback of {name} unsafe: {why}"
    return True,"rollback-safe"
