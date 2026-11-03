from pathlib import Path
import os
import tempfile
import unittest

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
os.environ.setdefault("SDL_AUDIODRIVER", "dummy")

import pygame

from game.audio import ProceduralAudio
from game.config import HEIGHT, WIDTH
from game.scenes import GameScene, MenuScene
from game.storage import SaveSystem


class SceneSmokeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        pygame.init()
        cls.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        cls.audio = ProceduralAudio(enabled=False)

    @classmethod
    def tearDownClass(cls) -> None:
        pygame.quit()

    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.saves = SaveSystem(Path(self.temporary_directory.name))

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def test_menu_and_gameplay_render(self) -> None:
        menu = MenuScene(self.screen, self.audio, self.saves)
        menu.draw()
        self.assertGreater(self.screen.get_bounding_rect().width, 0)

        scene = GameScene(self.screen, self.audio, seed=29)
        scene.prepare_preview(boss=True)
        scene.draw()
        self.assertIsNotNone(scene.boss)
        self.assertGreater(self.screen.get_bounding_rect().height, 0)

    def test_loaded_lives_reach_player(self) -> None:
        progress = {"score": 120, "lives": 1, "elapsed_seconds": 23}
        scene = GameScene(self.screen, self.audio, progress=progress, seed=29)

        self.assertEqual(scene.score, 120)
        self.assertEqual(scene.player.lives, 1)
        self.assertEqual(scene.elapsed_offset, 23)

    def test_close_event_exits_menu(self) -> None:
        pygame.event.post(pygame.event.Event(pygame.QUIT))
        menu = MenuScene(self.screen, self.audio, self.saves)
        self.assertEqual(menu.run(), "quit")

    def test_close_event_exits_gameplay(self) -> None:
        pygame.event.post(pygame.event.Event(pygame.QUIT))
        scene = GameScene(self.screen, self.audio, seed=29)
        self.assertEqual(scene.run()["status"], "quit")

    def test_boss_appears_after_thirty_seconds(self) -> None:
        scene = GameScene(self.screen, self.audio, seed=29)
        scene.session_started_at = 0
        scene.update(0.016, 30_100)
        self.assertIsNotNone(scene.boss)


if __name__ == "__main__":
    unittest.main()
