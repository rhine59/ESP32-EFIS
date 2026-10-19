"""Compile and execute the production C policy against untrusted/failing backends."""
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CRYPTO = ROOT / 'components/redone_crypto'

class NativeReleasePolicy(unittest.TestCase):
    def test_fail_closed_policy(self):
        with tempfile.TemporaryDirectory() as temp:
            executable = Path(temp) / 'release-policy-test'
            subprocess.run(['cc', '-std=c11', '-Wall', '-Wextra', '-Werror',
                            '-I', str(CRYPTO), str(ROOT / 'tests/test_release_policy.c'),
                            str(CRYPTO / 'redone_release_policy.c'), '-o', str(executable)],
                           check=True, capture_output=True, text=True)
            result = subprocess.run([str(executable)], check=True,
                                    capture_output=True, text=True)
            self.assertIn('release trust policy PASS', result.stdout)

if __name__ == '__main__':
    unittest.main()
