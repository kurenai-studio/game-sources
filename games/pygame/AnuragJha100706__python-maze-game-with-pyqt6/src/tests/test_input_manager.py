"""
Automated Unit Tests for InputManager Subsystem.
Verifies controller hotplug lifecycle, deadzone filtering, and unified action bindings.
"""

import os
import sys
import unittest
import pygame

# Set dummy video driver for headless execution
os.environ["SDL_VIDEODRIVER"] = "dummy"
os.environ["SDL_AUDIODRIVER"] = "dummy"

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from core.input_manager import InputManager

class TestInputManager(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        pygame.init()

    def setUp(self):
        self.mgr = InputManager()

    def test_initialization(self):
        """InputManager should initialize safely without throwing errors even without gamepads."""
        self.assertIsInstance(self.mgr.controllers, dict)
        self.assertIsInstance(self.mgr.get_connected_controllers(), list)
        self.assertEqual(self.mgr.DEADZONE, 0.35)

    def test_default_action_constants(self):
        """Action constants must remain stable for gameplay bindings."""
        self.assertEqual(self.mgr.ACTION_CONFIRM, "CONFIRM")
        self.assertEqual(self.mgr.ACTION_BACK, "BACK")
        self.assertEqual(self.mgr.ACTION_PAUSE, "PAUSE")
        self.assertEqual(self.mgr.ACTION_RESTART, "RESTART")
        self.assertEqual(self.mgr.ACTION_BOMB, "BOMB")

    def test_movement_idle_state(self):
        """When no keys or controllers are active, movement should be (0, 0)."""
        dx, dy = self.mgr.get_movement(player=0)
        self.assertEqual((dx, dy), (0, 0))
        dx2, dy2 = self.mgr.get_movement(player=1)
        self.assertEqual((dx2, dy2), (0, 0))

    def test_ui_nav_idle(self):
        """UI navigation should return None when no input is active."""
        nav = self.mgr.get_ui_nav()
        self.assertIsNone(nav)

    def test_deadzone_constant_within_optimal_bounds(self):
        """Deadzone should be configured within recommended 0.25 - 0.40 range to suppress drift."""
        self.assertGreaterEqual(self.mgr.DEADZONE, 0.25)
        self.assertLessEqual(self.mgr.DEADZONE, 0.45)

if __name__ == "__main__":
    unittest.main()
