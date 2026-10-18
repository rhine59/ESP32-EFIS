import subprocess
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/publish-release.sh'

class ShellStagingPolicyTests(unittest.TestCase):
    def run_invalid(self, build, minimum):
        result = subprocess.run(['sh', str(SCRIPT), 'unit-test-never-created', build,
                                 '/definitely/not/a/firmware.bin', minimum],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn('Invalid signed release build policy', result.stderr)
    def test_legacy_semver_rejected_before_file_access(self):
        self.run_invalid('10', '0.0.0')
    def test_out_of_range_rejected_before_file_access(self):
        self.run_invalid('2147483648', 'build:0')
    def test_floor_exceeding_candidate_rejected(self):
        self.run_invalid('4', 'build:5')
    def test_leading_zero_rejected(self):
        self.run_invalid('04', 'build:0')

if __name__ == '__main__': unittest.main()
