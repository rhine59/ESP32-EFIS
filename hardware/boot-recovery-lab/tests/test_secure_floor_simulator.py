import importlib.util
from pathlib import Path
import unittest
from dataclasses import replace
ROOT=Path(__file__).resolve().parents[3]
path=ROOT/'hardware/boot-recovery-lab/tools/secure_floor_simulator.py'
spec=importlib.util.spec_from_file_location('secure_floor_simulator',path)
m=importlib.util.module_from_spec(spec)
import sys
sys.modules[spec.name]=m
spec.loader.exec_module(m)
class SecureFloorSimulator(unittest.TestCase):
    def setUp(self):
        self.e=m.SimulatedElement(floor=8)
        self.v=m.SimulatedVerifier()
        self.n=bytes(range(16))
    def test_authenticated_fresh_read(self):
        self.assertEqual(self.v.verify(self.e.respond(self.n),self.n),8)
    def test_replay_rejected(self):
        reply=self.e.respond(self.n)
        self.v.verify(reply,self.n)
        with self.assertRaises(m.TrustFailure):self.v.verify(reply,self.n)
    def test_wrong_identity_and_swapped_element(self):
        for device in ('other','redone-test'):
            e=m.SimulatedElement(device=device,key=b'wrong-key',floor=8)
            with self.assertRaises(m.TrustFailure):self.v.verify(e.respond(self.n),self.n)
    def test_forged_counter_rejected(self):
        with self.assertRaises(m.TrustFailure):self.v.verify(replace(self.e.respond(self.n),floor=1),self.n)
    def test_wrong_nonce_and_epoch_rejected(self):
        reply=self.e.respond(self.n)
        with self.assertRaises(m.TrustFailure):self.v.verify(reply,bytes(range(1,17)))
        with self.assertRaises(m.TrustFailure):self.v.verify(replace(reply,epoch=1),self.n)
    def test_missing_element(self):
        self.e.present=False
        with self.assertRaises(m.TrustFailure):self.e.respond(self.n)
    def test_power_loss_before_and_after_abstract_commit(self):
        with self.assertRaises(m.TrustFailure):self.e.advance(10,'before_commit')
        self.assertEqual(self.e.floor,8)
        with self.assertRaises(m.TrustFailure):self.e.advance(10,'after_commit')
        self.assertEqual(self.e.floor,10)
        with self.assertRaises(m.TrustFailure):self.e.advance(9)
    def test_overflow_and_negative_floor_rejected(self):
        for value in (-1,m.MAX_BUILD+1):
            with self.assertRaises(m.TrustFailure):self.e.advance(value)
    def test_policy(self):
        self.assertTrue(m.allow_candidate(10,9,9,8))
        for args in ((7,0,9,8),(10,10,9,8),(10,9,7,8),(8,0,9,8),(-1,0,9,8),(True,0,9,8)):
            self.assertFalse(m.allow_candidate(*args))
    def test_never_authorises_physical_actions(self):
        result=m.simulate()
        self.assertFalse(result['hardware_attested'])
        self.assertFalse(result['physical_flash_authorized'])
        self.assertEqual(result['partition_b_decision'],'NO-GO')
