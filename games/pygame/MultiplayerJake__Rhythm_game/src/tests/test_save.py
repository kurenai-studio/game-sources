import os
import tempfile
import unittest

from game.services.save_system import SaveSystem


class TestSaveSystem(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.path = os.path.join(self.dir, "stats.dat")
        self.save = SaveSystem(self.path)

    def test_defaults(self):
        self.assertEqual(self.save.high_score("Song"), 0)

    def test_roundtrip(self):
        self.assertTrue(self.save.record_score("Song", 1234))
        reread = SaveSystem(self.path)
        self.assertEqual(reread.high_score("Song"), 1234)

    def test_lower_score_is_not_high(self):
        self.save.record_score("Song", 500)
        self.assertFalse(self.save.record_score("Song", 400))
        self.assertEqual(self.save.high_score("Song"), 500)

    def test_tamper_is_rejected(self):
        self.save.record_score("Song", 9999)
        with open(self.path, "r+b") as fh:
            data = bytearray(fh.read())
            # flip one base64 char in the payload region
            idx = 0 if data[0] != ord("A") else 1
            data[idx] = ord("Z") if data[idx] != ord("Z") else ord("A")
            fh.seek(0)
            fh.write(bytes(data))
        reloaded = SaveSystem(self.path)
        self.assertEqual(reloaded.high_score("Song"), 0)
        self.assertTrue(os.path.exists(self.path + ".bak"))

    def test_plain_text_is_rejected(self):
        with open(self.path, "w", encoding="utf-8") as fh:
            fh.write('{"highscores": {"Song": 999999}}')
        reloaded = SaveSystem(self.path)
        self.assertEqual(reloaded.high_score("Song"), 0)


if __name__ == "__main__":
    unittest.main()
