"""
Integration Test for Lane Legends game loop, rendering, and AI decision pipeline.
Runs in headless or software mode for 180 frames without crashing.
"""

import os
import sys
import unittest
from pathlib import Path

# Add project root to path
PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Set SDL to dummy driver if running on headless server / test runner
os.environ["SDL_VIDEODRIVER"] = "dummy"
os.environ["SDL_AUDIODRIVER"] = "dummy"

import pygame
from game import Game, STATE_RACING, MODE_VS_AI, MODE_PVP


class TestGameIntegration(unittest.TestCase):
    def test_full_game_loop_vs_ai(self):
        """Simulate 180 frames of active Player vs AI gameplay."""
        game = Game()
        self.assertIsNotNone(game.ai_agent)
        self.assertGreater(len(game.ai_agent.q_table), 0)

        # Start race vs AI
        game.start_race(MODE_VS_AI)
        game.state = STATE_RACING  # Skip countdown directly for test speed

        # Run 180 frames (~3 simulated seconds)
        dt = 1.0 / 60.0
        for frame in range(180):
            # Test player lane changes
            if frame == 30:
                game.car_p1.change_lane(-1)
            elif frame == 60:
                game.car_p1.change_lane(1)
            elif frame == 90:
                game.car_p1.activate_nitro()

            # Execute update and render
            game._update(dt)
            game._render()

        # Verify car progressed forward
        self.assertGreater(game.car_p1.distance_traveled, 0)
        self.assertGreater(game.car_p2.distance_traveled, 0)
        # Verify AI made at least one telemetry decision
        self.assertIsNotNone(game.ai_latest_telemetry)
        self.assertIn("q_values", game.ai_latest_telemetry)

    def test_full_game_loop_pvp(self):
        """Simulate 120 frames of 2-Player local multiplayer gameplay."""
        game = Game()
        game.start_race(MODE_PVP)
        game.state = STATE_RACING

        dt = 1.0 / 60.0
        for frame in range(120):
            if frame == 20:
                game.car_p2.change_lane(1)
            elif frame == 50:
                game.car_p2.activate_nitro()

            game._update(dt)
            game._render()

        self.assertFalse(game.car_p2.is_ai)
        self.assertGreater(game.car_p2.distance_traveled, 0)


if __name__ == "__main__":
    unittest.main()
