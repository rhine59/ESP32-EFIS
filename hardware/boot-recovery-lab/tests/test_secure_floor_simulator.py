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

class ReleaseConfirmationPolicy(unittest.TestCase):
    def setUp(self):
        self.element=m.SimulatedElement(floor=8)
        self.options=dict(candidate=10,signed_minimum=8,running_build=9,
                          signature_ok=True,boot_health_ok=True,
                          operator_ground_confirmed=True,recovery_floor_compatible=True)

    def review(self, **overrides):
        opts=dict(self.options);opts.update(overrides)
        return m.review_release_confirmation(self.element,m.SimulatedVerifier(),
                                             bytes(range(16)),**opts)

    def test_valid_release_commit(self):
        self.assertTrue(self.review())
        self.assertEqual(self.element.floor,10)

    def test_invalid_signed_minimum_or_running_version(self):
        for overrides in ({'signed_minimum':10},{'running_build':7},
                          {'candidate':8},{'candidate':9},
                          {'signed_minimum':-1},{'candidate':True}):
            with self.subTest(overrides=overrides):
                with self.assertRaises(m.TrustFailure):self.review(**overrides)
                self.assertEqual(self.element.floor,8)

    def test_independent_evidence_gates(self):
        for name in ('signature_ok','boot_health_ok','operator_ground_confirmed',
                     'recovery_floor_compatible'):
            with self.subTest(gate=name):
                with self.assertRaises(m.TrustFailure):self.review(**{name:False})
                self.assertEqual(self.element.floor,8)

    def test_before_commit_power_cut_does_not_advance(self):
        with self.assertRaises(m.TrustFailure):self.review(fault='before_commit')
        self.assertEqual(self.element.floor,8)

    def test_after_commit_power_cut_requires_fresh_authenticated_read(self):
        with self.assertRaises(m.TrustFailure):self.review(fault='after_commit')
        self.assertEqual(self.element.floor,10)
        self.assertEqual(m.SimulatedVerifier().verify(
            self.element.respond(bytes(range(1,17))),bytes(range(1,17))),10)
        with self.assertRaises(m.TrustFailure):self.review(candidate=9)

class ConfirmationGate(unittest.TestCase):
    def setUp(self):
        self.element=m.SimulatedElement(floor=8)
        self.verifier=m.SimulatedVerifier()
        self.nonce=bytes(range(16))
        self.conditions=dict(signature_ok=True,boot_health_ok=True,
                             operator_ground_confirmed=True,recovery_floor_compatible=True)
    def test_every_independent_gate_required(self):
        for gate in self.conditions:
            values=dict(self.conditions);values[gate]=False
            with self.assertRaises(m.TrustFailure):
                m.confirm_and_advance(self.element,self.verifier,self.nonce,10,**values)
            self.assertEqual(self.element.floor,8)
    def test_confirmed_advance_and_no_downgrade(self):
        self.assertTrue(m.confirm_and_advance(self.element,self.verifier,self.nonce,10,**self.conditions))
        self.assertEqual(self.element.floor,10)
        with self.assertRaises(m.TrustFailure):
            m.confirm_and_advance(self.element,m.SimulatedVerifier(),bytes(range(1,17)),9,**self.conditions)
    def test_power_loss_requires_reconciliation(self):
        with self.assertRaises(m.TrustFailure):
            m.confirm_and_advance(self.element,self.verifier,self.nonce,10,fault='after_commit',**self.conditions)
        self.assertEqual(self.element.floor,10)
        fresh=m.SimulatedVerifier()
        self.assertEqual(fresh.verify(self.element.respond(bytes(range(1,17))),bytes(range(1,17))),10)
    def test_replay_fails_even_if_all_gates_true(self):
        self.verifier.verify(self.element.respond(self.nonce),self.nonce)
        with self.assertRaises(m.TrustFailure):
            m.confirm_and_advance(self.element,self.verifier,self.nonce,10,**self.conditions)
        self.assertEqual(self.element.floor,8)
