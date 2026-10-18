import tempfile
import unittest
from pathlib import Path
from provision_usb_local import load_credentials


class CredentialParsingTests(unittest.TestCase):
    def test_valid(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'credentials'
            path.write_text('Wi-Fi password: ' + 'a'*20 + '\nX-Lab-Token: ' + 'b'*40 + '\n')
            self.assertEqual(load_credentials(path), ('a'*20, 'b'*40))

    def test_invalid(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'credentials'
            path.write_text('Wi-Fi password: short\nX-Lab-Token: short\n')
            with self.assertRaises(ValueError):
                load_credentials(path)


if __name__ == '__main__':
    unittest.main()
