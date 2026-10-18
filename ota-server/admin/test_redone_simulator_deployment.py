#!/usr/bin/env python3
"""Isolated, non-flashable RedOne A/B OTA deployment and rollback exercise."""
from dataclasses import dataclass
from pathlib import Path
import hashlib

FIXTURES = Path(__file__).resolve().parents[1] / 'test-fixtures' / 'redone-ota'
VERSIONS = {'A': '0.1.0-sim-A', 'B': '0.1.1-sim-B'}
SHA256 = {
    'A': 'aa0621fe57d4b5d6831c963c0e5c52b693493e9d7e6585797826bc80c6a4c06d',
    'B': 'f9acbce913f72c1c235a1fb11e7eb766737bb4a12765132153df2646aaee97df',
}

@dataclass(frozen=True)
class SimRelease:
    version: str
    payload: bytes
    digest: str

class IsolatedPublisher:
    def __init__(self):
        self.releases = {}
        self.published = None

    def stage(self, label):
        version = VERSIONS[label]
        payload = (FIXTURES / f'redone-{version}.bin').read_bytes()
        assert len(payload) == 4096
        assert payload.startswith(b'MICROSKY-HORIZON-SIMULATOR-OTA\nNON-FLASHABLE TEST PAYLOAD\n')
        assert payload[0] != 0xe9, 'must never resemble an ESP32 bootable image'
        digest = hashlib.sha256(payload).hexdigest()
        assert digest == SHA256[label], 'fixture checksum mismatch'
        self.releases[label] = SimRelease(version, payload, digest)
        return self.releases[label]

    def publish(self, label):
        assert label in self.releases
        self.published = label

    def download(self):
        assert self.published is not None
        return self.releases[self.published]

class SimulatedRedOne:
    def __init__(self):
        self.active = 'A'
        self.slots = {'A': None, 'B': None}
        self.candidate = None
        self.previous = None

    def stage(self, release):
        assert hashlib.sha256(release.payload).hexdigest() == release.digest
        assert release.payload.startswith(b'MICROSKY-HORIZON-SIMULATOR-OTA\n')
        self.candidate = release

    def activate(self):
        assert self.candidate is not None
        self.previous = self.active
        self.active = 'B' if self.active == 'A' else 'A'
        self.slots[self.active] = self.candidate
        self.candidate = None

    def rollback(self):
        assert self.previous is not None
        self.active, self.previous = self.previous, None


def run():
    publisher = IsolatedPublisher()
    a, b = publisher.stage('A'), publisher.stage('B')
    assert a.payload != b.payload
    print('PASS  two distinct non-flashable RedOne test images validated')
    device = SimulatedRedOne()
    device.slots['A'] = a
    publisher.publish('B')
    downloaded = publisher.download()
    assert downloaded.version == VERSIONS['B']
    print('PASS  simulator publisher exposes B for download')
    device.stage(downloaded)
    assert device.slots[device.active].version == VERSIONS['A']
    print('PASS  staged B does not change running A')
    device.activate()
    assert device.slots[device.active].version == VERSIONS['B']
    print('PASS  explicit activation switches running version to B')
    device.rollback()
    assert device.slots[device.active].version == VERSIONS['A']
    print('PASS  rollback restores running version A')
    tampered = SimRelease(b.version, b.payload[:-1] + bytes([b.payload[-1] ^ 1]), b.digest)
    try:
        device.stage(tampered)
    except AssertionError:
        print('PASS  corrupted download rejected before staging')
    else:
        raise AssertionError('corrupt payload was accepted')
    assert device.slots[device.active].version == VERSIONS['A']
    print('ALL REDONE SIMULATOR DEPLOYMENT TESTS PASSED')

if __name__ == '__main__':
    run()
