#!/usr/bin/env python3
"""Offline threat-model simulator; HMAC fixtures are NOT hardware attestation."""
import hashlib
import hmac
import json
from dataclasses import dataclass

MAX_BUILD = 2**31-1

class TrustFailure(Exception):
    pass

@dataclass(frozen=True)
class Reply:
    device: str
    nonce: bytes
    floor: int
    epoch: int
    mac: bytes

class SimulatedElement:
    """In-memory model only. Real I2C and secure-element APIs are not implemented."""
    def __init__(self, device='redone-test', key=b'offline-test-key', floor=0, epoch=0):
        self.device, self._key, self.floor, self.epoch = device, key, floor, epoch
        self.present = True

    def respond(self, nonce):
        if not self.present:
            raise TrustFailure('element unavailable')
        if len(nonce) < 16:
            raise TrustFailure('nonce too short')
        payload = encode(self.device, nonce, self.floor, self.epoch)
        return Reply(self.device, nonce, self.floor, self.epoch,
                     hmac.digest(self._key, payload, 'sha256'))

    def advance(self, candidate, fault=None):
        if not self.present or not 0 <= candidate <= MAX_BUILD or candidate < self.floor:
            raise TrustFailure('invalid advance')
        if fault == 'before_commit':
            raise TrustFailure('simulated power cut before commit')
        self.floor = candidate  # abstract atomic commit, NOT a hardware guarantee
        if fault == 'after_commit':
            raise TrustFailure('simulated power cut after commit')

def encode(device, nonce, floor, epoch):
    if not 0 <= floor <= MAX_BUILD or not 0 <= epoch <= MAX_BUILD:
        raise TrustFailure('invalid state')
    return (b'redone-floor-simulation-v1\0' + device.encode('ascii') + b'\0' +
            len(nonce).to_bytes(2,'big') + nonce + floor.to_bytes(4,'big') + epoch.to_bytes(4,'big'))

class SimulatedVerifier:
    def __init__(self, device='redone-test', key=b'offline-test-key', epoch=0):
        self.device, self._key, self.epoch = device, key, epoch
        self._used_nonces = set()

    def verify(self, reply, expected_nonce):
        if (len(expected_nonce) < 16 or reply.nonce != expected_nonce or
            reply.device != self.device or reply.epoch != self.epoch or
            expected_nonce in self._used_nonces):
            raise TrustFailure('identity, freshness or epoch mismatch')
        expected = hmac.digest(self._key, encode(reply.device, reply.nonce, reply.floor, reply.epoch), 'sha256')
        if not hmac.compare_digest(reply.mac, expected):
            raise TrustFailure('authentication failed')
        self._used_nonces.add(expected_nonce)
        return reply.floor

def allow_candidate(candidate, signed_minimum, running, installed_floor):
    return (all(isinstance(x,int) and not isinstance(x,bool) and 0 <= x <= MAX_BUILD
                for x in (candidate,signed_minimum,running,installed_floor)) and
            running >= installed_floor and candidate >= running and
            candidate >= installed_floor and signed_minimum <= running)

def simulate():
    element = SimulatedElement(floor=8)
    verifier = SimulatedVerifier()
    nonce = bytes(range(16))
    observed = verifier.verify(element.respond(nonce), nonce)
    eligible = allow_candidate(10,9,9,observed)
    element.advance(10)
    return {'mode':'offline-simulation-only', 'authenticated_fixture':True,
            'policy_candidate_eligible':eligible,'simulated_floor_after_commit':element.floor,
            'hardware_attested':False,'physical_flash_authorized':False,
            'partition_b_decision':'NO-GO'}

if __name__ == '__main__':
    print(json.dumps(simulate(),indent=2))
