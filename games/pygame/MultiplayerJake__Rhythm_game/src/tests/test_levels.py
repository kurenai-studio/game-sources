import json
import os
import tempfile
import unittest
import wave

from game.services.levels import LevelLibrary


def write_wav(path, frames=800):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(8000)
        w.writeframes(b"\x00\x00" * frames)


class TestLevels(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.lib = LevelLibrary(self.dir)
        self.src = os.path.join(self.dir, "source.wav")
        write_wav(self.src)

    def test_sanitize(self):
        self.assertEqual(LevelLibrary.sanitize("a/b:c*?d"), "a_b_c__d")
        self.assertEqual(LevelLibrary.sanitize("   "), "level")

    def test_create_and_scan(self):
        info = self.lib.create("My Song", self.src)
        self.assertTrue(info.valid)
        self.assertTrue(os.path.isfile(info.audio_path))
        self.assertTrue(os.path.isfile(info.json_path))
        levels = self.lib.scan()
        self.assertEqual(len(levels), 1)
        self.assertTrue(levels[0].valid)

    def test_collision_suffix(self):
        a = self.lib.create("Dup", self.src)
        b = self.lib.create("Dup", self.src)
        self.assertNotEqual(a.name, b.name)
        self.assertTrue(b.name.startswith("Dup_"))

    def test_broken_json_flagged(self):
        info = self.lib.create("Broken", self.src)
        with open(info.json_path, "w", encoding="utf-8") as fh:
            fh.write("{not json")
        level = self.lib.scan()[0]
        self.assertFalse(level.valid)

    def test_missing_audio_flagged(self):
        info = self.lib.create("Gone", self.src)
        os.remove(info.audio_path)
        level = self.lib.scan()[0]
        self.assertFalse(level.valid)

    def test_notes_roundtrip(self):
        info = self.lib.create("Chart", self.src)
        info.notes = [{"lane": 0, "time": 100.0, "end": None, "boost": False},
                      {"lane": 3, "time": 500.0, "end": 900.0, "boost": True}]
        self.lib.write(info)
        loaded = self.lib.scan()[0]
        self.assertEqual(len(loaded.notes), 2)
        self.assertEqual(loaded.notes[1]["end"], 900.0)
        self.assertTrue(loaded.notes[1]["boost"])

    def test_end_roundtrip(self):
        info = self.lib.create("Long", self.src)
        info.end = 5432.0
        self.lib.write(info)
        self.assertEqual(self.lib.scan()[0].end, 5432.0)

    def test_missing_or_bad_end_is_none(self):
        info = self.lib.create("NoEnd", self.src)
        with open(info.json_path, "w", encoding="utf-8") as fh:
            json.dump({"name": "NoEnd", "audio": info.audio_file,
                       "notes": []}, fh)
        self.assertIsNone(self.lib.scan()[0].end)

        with open(info.json_path, "w", encoding="utf-8") as fh:
            json.dump({"name": "NoEnd", "audio": info.audio_file,
                       "end": "soon", "notes": []}, fh)
        level = self.lib.scan()[0]
        self.assertTrue(level.valid)
        self.assertIsNone(level.end)


if __name__ == "__main__":
    unittest.main()
