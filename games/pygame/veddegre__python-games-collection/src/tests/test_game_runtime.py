"""Non-GUI tests for launcher path safety and packaging helpers."""
import json
import os
import sys
import tempfile
import unittest
import unittest.mock

# Project root on sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from game_runtime import (  # noqa: E402
    _subprocess_launch_cmd,
    game_file_from_argv,
    get_user_data_dir,
    launch_game_subprocess,
    migrate_legacy_scores_if_needed,
    resolve_game_path,
    scores_path,
    setup_logging,
)


class ResolveGamePathTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = self.tmp.name
        self.game = os.path.join(self.root, "solitaire.py")
        with open(self.game, "w", encoding="utf-8") as fh:
            fh.write("# stub\n")

    def tearDown(self):
        self.tmp.cleanup()

    def test_accepts_bare_filename(self):
        resolved = resolve_game_path("solitaire.py", self.root)
        self.assertEqual(resolved, os.path.realpath(self.game))

    def test_rejects_parent_traversal(self):
        self.assertIsNone(resolve_game_path("../solitaire.py", self.root))

    def test_rejects_absolute_path(self):
        self.assertIsNone(resolve_game_path(self.game, self.root))

    def test_rejects_non_py(self):
        with open(os.path.join(self.root, "notes.txt"), "w", encoding="utf-8") as fh:
            fh.write("x")
        self.assertIsNone(resolve_game_path("notes.txt", self.root))


class SubprocessCmdTests(unittest.TestCase):
    def test_dev_cmd_includes_menu_and_game_flag(self):
        with unittest.mock.patch.object(sys, "frozen", False, create=True):
            cmd = _subprocess_launch_cmd("snake_game.py")
        self.assertIn("--game", cmd)
        self.assertIn("snake_game.py", cmd)
        self.assertTrue(any(p.endswith("menu.py") for p in cmd))
        self.assertFalse(any(" " in part for part in cmd))  # list form, no shell quoting needed

    def test_frozen_cmd_uses_executable_only(self):
        with unittest.mock.patch.object(sys, "frozen", True, create=True):
            with unittest.mock.patch.object(sys, "executable", "/Apps/GamesCollection"):
                cmd = _subprocess_launch_cmd("snake_game.py")
        self.assertEqual(cmd, ["/Apps/GamesCollection", "--game", "snake_game.py"])


class ScoresMigrationTests(unittest.TestCase):
    def test_migrates_legacy_scores_once(self):
        with tempfile.TemporaryDirectory() as tmp:
            legacy = os.path.join(tmp, "scores.json")
            with open(legacy, "w", encoding="utf-8") as fh:
                json.dump({"snake": 10}, fh)

            user_dir = os.path.join(tmp, "userdata")
            os.makedirs(user_dir)

            with unittest.mock.patch("game_runtime.legacy_scores_path", return_value=legacy):
                with unittest.mock.patch("game_runtime.get_user_data_dir", return_value=user_dir):
                    with unittest.mock.patch("game_runtime.scores_path") as sp:
                        user_scores = os.path.join(user_dir, "scores.json")
                        sp.side_effect = lambda: user_scores
                        setup_logging()
                        migrate_legacy_scores_if_needed()
                        self.assertTrue(os.path.exists(user_scores))
                        with open(user_scores, encoding="utf-8") as fh:
                            data = json.load(fh)
                        self.assertEqual(data["snake"], 10)


class ArgParseTests(unittest.TestCase):
    def test_game_file_from_argv(self):
        self.assertEqual(
            game_file_from_argv(["menu.py", "--game", "hangman.py"]),
            "hangman.py",
        )
        self.assertIsNone(game_file_from_argv(["menu.py"]))


class LaunchSubprocessTests(unittest.TestCase):
    def test_rejects_invalid_game_without_spawning(self):
        with unittest.mock.patch("game_runtime.subprocess.run") as run:
            code = launch_game_subprocess("../../etc/passwd", tempfile.gettempdir())
        self.assertEqual(code, 1)
        run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
