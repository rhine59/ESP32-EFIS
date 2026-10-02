#!/usr/bin/env python3
"""Transport-neutral simulated SMUX OTA target.

Models the SMUX side of the future AEF-CAN maintenance service. This is a
state-machine/test double only: it does not claim CAN, flash or bootloader
hardware validation.
"""
from dataclasses import dataclass, field
import hashlib

@dataclass(frozen=True)
class Image:
    product: str
    hardware: str
    version: str
    payload: bytes
    sha256: str

    @classmethod
    def make(cls, version: str, payload: bytes, hardware: str = "SMUX-V1"):
        return cls("ESP32-EFIS-SMUX", hardware, version, payload,
                   hashlib.sha256(payload).hexdigest())

@dataclass
class SimulatedEIU:
    hardware: str = "SMUX-V1"
    bootloader: str = "1.0"
    protocol: str = "AEF-CAN-1"
    active_slot: str = "A"
    slots: dict = field(default_factory=lambda: {"A": "1.0.0", "B": None})
    configuration: dict = field(default_factory=lambda: {
        "J1-1": "EGT_1", "J1-2": "EGT_2", "J2-1": "OIL_TEMP"
    })
    _candidate: Image | None = None
    _received: bytearray = field(default_factory=bytearray)
    _pending_slot: str | None = None
    _previous_slot: str | None = None

    @property
    def version(self):
        return self.slots[self.active_slot]

    def announce(self):
        return {"device": "SMUX", "hardware": self.hardware,
                "firmware": self.version, "bootloader": self.bootloader,
                "protocol": self.protocol}

    def begin(self, image: Image):
        if image.product != "ESP32-EFIS-SMUX":
            return False, "wrong-product"
        if image.hardware != self.hardware:
            return False, "wrong-hardware"
        self._candidate = image
        self._received = bytearray()
        return True, "ready"

    def write_block(self, data: bytes):
        if self._candidate is None:
            raise RuntimeError("no update in progress")
        self._received.extend(data)
        return len(self._received)

    def finish(self):
        if self._candidate is None:
            return False, "no-update"
        digest = hashlib.sha256(bytes(self._received)).hexdigest()
        if digest != self._candidate.sha256:
            self._candidate = None
            self._received = bytearray()
            return False, "hash-failure"
        inactive = "B" if self.active_slot == "A" else "A"
        self.slots[inactive] = self._candidate.version
        self._pending_slot = inactive
        return True, "verified"

    def activate(self, engine_rpm: int):
        if engine_rpm != 0:
            return False, "engine-running"
        if self._pending_slot is None:
            return False, "nothing-pending"
        self._previous_slot = self.active_slot
        self.active_slot = self._pending_slot
        self._pending_slot = None
        return True, "reboot-pending"

    def first_boot(self, healthy: bool):
        if self._previous_slot is None:
            return self.version, "normal"
        if healthy:
            self._previous_slot = None
            self._candidate = None
            self._received = bytearray()
            return self.version, "confirmed"
        failed = self.active_slot
        self.active_slot = self._previous_slot
        self._previous_slot = None
        self.slots[failed] = None
        self._candidate = None
        self._received = bytearray()
        return self.version, "rolled-back"
