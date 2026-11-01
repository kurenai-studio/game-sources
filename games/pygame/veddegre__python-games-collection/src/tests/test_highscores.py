import json
import os
import sys
import tempfile
import unittest
import unittest.mock

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from highscores import (  # noqa: E402
    clear_all_scores,
    clear_score,
    get_high_score,
    get_low_score,
    save_best_time,
    save_high_score,
    save_low_score,
)


class HighscoresTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.scores_file = os.path.join(self.tmp.name, "scores.json")
        self.patch = unittest.mock.patch("highscores.scores_path", return_value=self.scores_file)
        self.patch.start()

    def tearDown(self):
        self.patch.stop()
        self.tmp.cleanup()

    def test_save_low_score_keeps_best(self):
        self.assertTrue(save_low_score("maze_explorer", 40))
        self.assertFalse(save_low_score("maze_explorer", 50))
        self.assertTrue(save_low_score("maze_explorer", 30))
        self.assertEqual(get_low_score("maze_explorer"), 30)

    def test_save_high_score_keeps_best(self):
        self.assertTrue(save_high_score("snake", 10))
        self.assertFalse(save_high_score("snake", 5))
        self.assertTrue(save_high_score("snake", 20))

    def test_clear_score_and_all(self):
        save_high_score("snake", 5)
        save_low_score("maze_explorer", 12)
        self.assertTrue(clear_score("snake"))
        self.assertEqual(get_high_score("snake"), 0)
        self.assertEqual(get_low_score("maze_explorer"), 12)
        self.assertTrue(clear_all_scores())
        with open(self.scores_file, encoding="utf-8") as fh:
            self.assertEqual(json.load(fh), {})

    def test_save_best_time(self):
        self.assertTrue(save_best_time("minesweeper_time", 120.5))
        self.assertFalse(save_best_time("minesweeper_time", 130.0))
        self.assertTrue(save_best_time("minesweeper_time", 90.0))


if __name__ == "__main__":
    unittest.main()
