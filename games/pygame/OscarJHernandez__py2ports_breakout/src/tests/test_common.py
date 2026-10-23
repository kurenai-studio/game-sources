import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

os.environ.update(SDL_VIDEODRIVER="dummy", SDL_AUDIODRIVER="dummy", PYGAME_HIDE_SUPPORT_PROMPT="1")
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
import pygame
from app import Inputs, Scores, View, render
from main import Game


class ScoreTests(unittest.TestCase):
    def test_persist_only_highest(self):
        with tempfile.TemporaryDirectory() as directory:
            scores = Scores("game", directory)
            scores.record(20)
            scores.record(10)
            self.assertEqual(Scores("game", directory).best, 20)
            self.assertEqual(json.loads(scores.path.read_text()), {"high_score": 20})

    def test_corrupt_and_invalid_scores(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "scores.json"
            for value in ("bad json", "null", "[]", '{"high_score": -5}', '{"high_score": true}', '{}'):
                path.write_text(value)
                with self.subTest(value=value):
                    self.assertEqual(Scores("game", directory).best, 0)

    def test_failed_atomic_save_preserves_previous_file(self):
        with tempfile.TemporaryDirectory() as directory:
            scores = Scores("game", directory)
            scores.record(10)
            with patch("app.os.replace", side_effect=PermissionError("read-only")):
                scores.record(30)
            self.assertEqual(scores.best, 30)
            self.assertEqual(Scores("game", directory).best, 10)
            self.assertEqual([p.name for p in Path(directory).iterdir()], ["scores.json"])

    def test_unwritable_location_does_not_prevent_play(self):
        with tempfile.TemporaryDirectory() as directory:
            blocker = Path(directory) / "file"
            blocker.write_text("not a directory")
            scores = Scores("game", blocker / "data")
            scores.record(40)
            self.assertEqual(scores.best, 40)

    def test_device_data_directory_takes_precedence(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.dict(os.environ, {"PY2PORTS_DATA_DIR": directory}):
                self.assertEqual(Scores("game").path, Path(directory) / "scores.json")

    def test_xdg_fallback(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.dict(os.environ, {"XDG_DATA_HOME": directory}):
                with patch.dict(os.environ) as environment:
                    environment.pop("PY2PORTS_DATA_DIR", None)
                    self.assertEqual(Scores("game").path, Path(directory) / "game/scores.json")


class InputTests(unittest.TestCase):
    def setUp(self):
        self.inputs = Inputs()

    def event(self, kind, **fields):
        return self.inputs.event(pygame.event.Event(kind, **fields))

    def test_keyboard_press_and_release(self):
        self.assertEqual(self.event(pygame.KEYDOWN, key=pygame.K_a), ["left"])
        self.assertEqual(self.inputs.horizontal, -1)
        self.assertEqual(self.event(pygame.KEYDOWN, key=pygame.K_a), [])
        self.event(pygame.KEYUP, key=pygame.K_a)
        self.assertEqual(self.inputs.horizontal, 0)
        self.assertEqual(self.event(pygame.KEYDOWN, key=pygame.K_RETURN), ["confirm"])
        self.assertEqual(self.event(pygame.KEYDOWN, key=pygame.K_p), ["pause"])
        self.assertEqual(self.event(pygame.KEYDOWN, key=pygame.K_ESCAPE), ["back"])

    def test_standard_controller_buttons(self):
        self.assertEqual(self.event(pygame.CONTROLLERBUTTONDOWN, instance_id=3, button=pygame.CONTROLLER_BUTTON_A), ["confirm"])
        self.assertEqual(self.event(pygame.CONTROLLERBUTTONDOWN, instance_id=3, button=pygame.CONTROLLER_BUTTON_START), ["pause"])
        self.event(pygame.CONTROLLERBUTTONDOWN, instance_id=3, button=pygame.CONTROLLER_BUTTON_DPAD_RIGHT)
        self.assertEqual(self.inputs.horizontal, 1)
        self.event(pygame.CONTROLLERBUTTONUP, instance_id=3, button=pygame.CONTROLLER_BUTTON_DPAD_RIGHT)
        self.assertEqual(self.inputs.horizontal, 0)

    def test_controller_axis_deadzone_and_direction_changes(self):
        self.assertEqual(self.event(pygame.CONTROLLERAXISMOTION, instance_id=3, axis=0, value=-1), [])
        self.assertEqual(self.event(pygame.CONTROLLERAXISMOTION, instance_id=3, axis=0, value=32000), ["right"])
        self.assertEqual(self.inputs.horizontal, 1)
        self.event(pygame.CONTROLLERAXISMOTION, instance_id=3, axis=0, value=0)
        self.assertEqual(self.inputs.horizontal, 0)

    def test_unmapped_hat_and_axis(self):
        self.assertEqual(self.event(pygame.JOYHATMOTION, instance_id=2, value=(0, 1)), ["up"])
        self.assertEqual(self.event(pygame.JOYHATMOTION, instance_id=2, value=(-1, 0)), ["left"])
        self.assertEqual(self.inputs.horizontal, -1)
        self.event(pygame.JOYHATMOTION, instance_id=2, value=(0, 0))
        self.assertEqual(self.inputs.horizontal, 0)
        self.assertEqual(self.event(pygame.JOYAXISMOTION, instance_id=2, axis=0, value=0.8), ["right"])
        self.assertEqual(self.event(pygame.JOYBUTTONDOWN, instance_id=2, button=0), ["confirm"])

    def test_mapped_joystick_events_are_not_duplicated(self):
        self.inputs.mapped.add(2)
        self.assertEqual(self.event(pygame.JOYHATMOTION, instance_id=2, value=(1, 0)), [])
        self.assertEqual(self.event(pygame.JOYAXISMOTION, instance_id=2, axis=0, value=1.0), [])
        self.assertEqual(self.event(pygame.JOYBUTTONDOWN, instance_id=2, button=0), [])

    def test_unplug_and_focus_loss_clear_movement(self):
        self.event(pygame.JOYHATMOTION, instance_id=2, value=(1, 0))
        self.event(pygame.JOYDEVICEREMOVED, instance_id=2)
        self.assertEqual(self.inputs.horizontal, 0)
        self.event(pygame.KEYDOWN, key=pygame.K_d)
        self.assertEqual(self.event(pygame.WINDOWFOCUSLOST), ["focus_lost"])
        self.assertEqual(self.inputs.horizontal, 0)

    def test_unavailable_controller_is_nonfatal(self):
        with patch("pygame.joystick.Joystick", side_effect=pygame.error("missing")):
            self.inputs.open_device(0)
        self.assertEqual(self.inputs.devices, {})


class RenderingTests(unittest.TestCase):
    def test_every_screen_renders(self):
        pygame.font.init()
        try:
            surface = pygame.Surface((640, 480))
            view = View(surface)
            game = Game()
            for state in ("menu", "playing", "paused", "over", "won"):
                game.state = state
                render(view, game, 50)
                self.assertNotEqual(surface.get_at((320, 200)), surface.get_at((0, 0)))
        finally:
            pygame.font.quit()
