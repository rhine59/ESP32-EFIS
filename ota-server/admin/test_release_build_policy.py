import unittest
from release_build_policy import validate_release_build

class BuildPolicyTests(unittest.TestCase):
    def test_valid(self):
        self.assertEqual(validate_release_build('42', 'build:12'), (42,12))
        self.assertEqual(validate_release_build(0, 'build:0'), (0,0))
        self.assertEqual(validate_release_build(2147483647, 'build:2147483647'), (2147483647,2147483647))
    def test_reject_invalid(self):
        for build, minimum in [(-1,'build:0'), (True,'build:0'),('01','build:0'),
            (2147483648,'build:0'), (2,'0.0.0'), (2,'build:03'), (2,'build:3'),
            (2,'build:-1'), (2,'build:2147483648'), (2,'build:1 '),
            (2,'build:+1'), (2,'build:'), (2,'BUILD:1')]:
            with self.subTest(build=build,minimum=minimum):
                with self.assertRaises(ValueError):
                    validate_release_build(build, minimum)
if __name__ == '__main__': unittest.main()
