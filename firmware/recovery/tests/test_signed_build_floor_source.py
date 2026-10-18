"""Offline source-level regression checks; physical signed-release tests still required."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class SignedBuildFloorSource(unittest.TestCase):
    def test_signed_floor_is_checked_only_after_signature(self):
        source=(ROOT/'components/redone_crypto/redone_envelope.c').read_text()
        self.assertIn('if (result == 0)',source)
        self.assertIn('signed_build_floor(minimum->valuestring, &signed_floor)',source)
        self.assertIn('signed_floor>build->valueint',source)
        self.assertGreater(source.index('signed_build_floor(minimum->valuestring'),source.index('if (result == 0)'))
    def test_rejects_overflow_and_noncanonical_claims(self):
        source=(ROOT/'components/redone_crypto/redone_envelope.c').read_text()
        self.assertIn('INT32_MAX-digit',source)
        self.assertIn("digits[0]=='0' && digits[1]",source)
        self.assertIn('verified->signed_minimum_build=signed_floor',source)
