from pathlib import Path
import tempfile
import unittest

from game.storage import SaveSystem


class SaveSystemTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary_directory.name)
        self.saves = SaveSystem(self.directory)

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def test_progress_round_trip_and_clear(self) -> None:
        self.saves.save_progress(score=240, lives=1, elapsed_seconds=27)
        self.assertEqual(
            self.saves.load_progress(),
            {"score": 240, "lives": 1, "elapsed_seconds": 27},
        )
        self.assertTrue(self.saves.has_progress())

        self.saves.clear_progress()
        self.assertIsNone(self.saves.load_progress())

    def test_ranking_is_sorted_sanitized_and_limited(self) -> None:
        for index in range(14):
            self.saves.save_score(f" piloto {index} ", index * 10, 40 - index)

        ranking = self.saves.load_ranking()
        self.assertEqual(len(ranking), 10)
        self.assertEqual(ranking[0].score, 130)
        self.assertEqual(ranking[0].name, "PILOTO 13")
        self.assertGreaterEqual(ranking[0].score, ranking[-1].score)

    def test_corrupted_files_do_not_crash(self) -> None:
        self.directory.mkdir(parents=True, exist_ok=True)
        (self.directory / "progress.json").write_text("not json", encoding="utf-8")
        (self.directory / "ranking.json").write_text("{broken", encoding="utf-8")

        self.assertIsNone(self.saves.load_progress())
        self.assertEqual(self.saves.load_ranking(), [])


if __name__ == "__main__":
    unittest.main()
