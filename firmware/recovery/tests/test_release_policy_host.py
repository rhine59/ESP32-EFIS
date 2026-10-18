import subprocess
import tempfile
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class ReleasePolicyHost(unittest.TestCase):
    def test_compiled_policy(self):
        with tempfile.TemporaryDirectory() as d:
            binary=Path(d)/'release_policy_test'
            cmd=['cc','-std=c11','-Wall','-Wextra','-Werror','-I'+str(ROOT/'components/redone_crypto'),str(ROOT/'tests/test_release_policy.c'),str(ROOT/'components/redone_crypto/redone_release_policy.c'),'-o',str(binary)]
            subprocess.run(cmd,check=True,capture_output=True,text=True)
            self.assertIn('PASS',subprocess.run([str(binary)],check=True,capture_output=True,text=True).stdout)
