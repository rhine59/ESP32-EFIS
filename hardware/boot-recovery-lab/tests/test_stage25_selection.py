from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[3]
class Stage25Design(unittest.TestCase):
    def test_document_explicitly_rejects_premature_approval(self):
        text=(ROOT/'docs/REDONE-STAGE25-SECURE-ELEMENT-SELECTION.md').read_text()
        for term in ('Microchip ATECC608','NXP SE050','NO-GO','Secure Boot V2','power-failure','unconfirmed candidate','replacement'):
            self.assertIn(term,text)
