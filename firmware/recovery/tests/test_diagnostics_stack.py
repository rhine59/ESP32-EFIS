"""Source regression checks for recovery USB diagnostics stack safety."""
import re
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class TestDiagnosticsStack(unittest.TestCase):
    def test_usb_report_is_heap_allocated(self):
        source=(ROOT/'main'/'diagnostics.c').read_text()
        body=source.split('void recovery_diagnostics_print(void)',1)[1]
        self.assertRegex(body,r'heap_caps_malloc\s*\(\s*4096')
        self.assertRegex(body,r'heap_caps_free\s*\(\s*report\s*\)')
        self.assertNotRegex(body,r'char\s+report\s*\[\s*4096\s*\]')
        self.assertRegex(body,r'if\s*\(\s*!report\s*\)')
    def test_http_report_remains_heap_allocated(self):
        source=(ROOT/'main'/'recovery_wifi.c').read_text()
        self.assertIn('heap_caps_malloc(4096,MALLOC_CAP_8BIT)',source)
