"""
Unit Tests for Game Entities, Dual Track Symmetry, Physics, and Scoreboard.
"""

import sys
import unittest
from pathlib import Path

# Add project root to path
PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from settings import (
    TRACK_1_LANES,
    TRACK_2_LANES,
    CAR_P1_COLOR,
    NITRO_CAPACITY,
    OBSTACLE_TRAFFIC,
    OBSTACLE_OIL,
)
from entities import Car
from track import DualTrackManager
from scoreboard import Scoreboard


class TestCarPhysics(unittest.TestCase):
    def setUp(self):
        self.car = Car(
            name="Test Racer",
            color=CAR_P1_COLOR,
            lanes=TRACK_1_LANES,
            start_lane=1,
            is_ai=False,
        )

    def test_lane_change_boundaries(self):
        """Test lane changing cannot exceed lane bounds 0 and 2."""
        self.assertEqual(self.car.current_lane, 1)

        # Move Left to 0
        moved = self.car.change_lane(-1)
        self.assertTrue(moved)
        self.assertEqual(self.car.current_lane, 0)

        # Attempt Move Left beyond boundary -> should fail
        moved_again = self.car.change_lane(-1)
        self.assertFalse(moved_again)
        self.assertEqual(self.car.current_lane, 0)

        # Move Right to 1, then to 2
        self.car.change_lane(1)
        self.assertEqual(self.car.current_lane, 1)
        self.car.change_lane(1)
        self.assertEqual(self.car.current_lane, 2)

        # Attempt Move Right beyond boundary -> should fail
        moved_right_again = self.car.change_lane(1)
        self.assertFalse(moved_right_again)
        self.assertEqual(self.car.current_lane, 2)

    def test_nitro_activation_and_drain(self):
        """Test nitro triggers speed surge and drains the nitro meter."""
        self.assertEqual(self.car.nitro_meter, NITRO_CAPACITY)
        self.assertFalse(self.car.is_nitro_active)

        # Activate nitro
        activated = self.car.activate_nitro()
        self.assertTrue(activated)
        self.assertTrue(self.car.is_nitro_active)
        self.assertEqual(self.car.boosts_used, 1)

        # Update over 0.5 seconds
        initial_speed = self.car.speed
        self.car.update(0.5)
        self.assertLess(self.car.nitro_meter, NITRO_CAPACITY)
        self.assertGreater(self.car.speed, initial_speed)

    def test_collision_speed_drop_and_invulnerability(self):
        """Test collision penalizes speed and grants temporary invulnerability."""
        initial_score = 500
        self.car.score = initial_score
        initial_speed = self.car.speed

        self.car.handle_collision(OBSTACLE_TRAFFIC)
        self.assertEqual(self.car.collisions_count, 1)
        self.assertGreater(self.car.invulnerable_timer, 0.0)
        self.assertLess(self.car.speed, initial_speed)
        self.assertLess(self.car.score, initial_score)

        # Repeated hit during invulnerability should not trigger additional collision
        self.car.handle_collision(OBSTACLE_TRAFFIC)
        self.assertEqual(self.car.collisions_count, 1)


class TestTrackSymmetryAndFairness(unittest.TestCase):
    def setUp(self):
        self.track_mgr = DualTrackManager(seed=4242)

    def test_track_obstacle_symmetry(self):
        """Verify Track 1 and Track 2 have identical obstacle count, types, and distances."""
        t1_obs = self.track_mgr.track_1_obstacles
        t2_obs = self.track_mgr.track_2_obstacles

        self.assertEqual(len(t1_obs), len(t2_obs))
        self.assertGreater(len(t1_obs), 10)

        for o1, o2 in zip(t1_obs, t2_obs):
            self.assertEqual(o1.obstacle_type, o2.obstacle_type)
            self.assertEqual(o1.lane, o2.lane)
            self.assertEqual(o1.world_distance, o2.world_distance)

    def test_solvable_lanes(self):
        """Verify that at any obstacle checkpoint, at least one lane remains open."""
        # Group blueprints by world distance
        groups = {}
        for bp in self.track_mgr.blueprints:
            groups.setdefault(bp.world_dist, set()).add(bp.lane)

        for dist, blocked_lanes in groups.items():
            self.assertLess(len(blocked_lanes), 3, f"All 3 lanes blocked at distance {dist}!")


class TestScoreboardPersistence(unittest.TestCase):
    def test_recording_and_leaderboard_sorting(self):
        """Test that scoreboard tallies outcomes and orders top scores descending."""
        test_file = PROJECT_ROOT / "data" / "test_high_scores.json"
        try:
            sb = Scoreboard(test_file)

            # Record race 1: Player 1 wins
            sb.record_race_result(
                mode="vs_ai",
                p1_stats={"name": "Alice", "score": 3400, "finish_time": 28.5, "is_ai": False},
                p2_stats={"name": "Cyber Cheetah", "score": 2900, "finish_time": 30.1, "is_ai": True},
                winner_name="Player 1 (Alice)",
                difficulty="HARD",
            )

            # Record race 2: Higher score
            sb.record_race_result(
                mode="vs_ai",
                p1_stats={"name": "Bob", "score": 4200, "finish_time": 26.2, "is_ai": False},
                p2_stats={"name": "Cyber Cheetah", "score": 3100, "finish_time": 29.0, "is_ai": True},
                winner_name="Player 1 (Bob)",
                difficulty="HARD",
            )

            leaderboard = sb.get_leaderboard()
            self.assertEqual(len(leaderboard), 2)
            self.assertEqual(leaderboard[0]["player"], "Bob")
            self.assertEqual(leaderboard[0]["score"], 4200)
            self.assertEqual(leaderboard[1]["player"], "Alice")

            # Check human win tally
            tallies = sb.get_tallies()
            self.assertEqual(tallies["human_vs_ai"]["human_wins"], 2)

            # Test reload from disk
            sb_reloaded = Scoreboard(test_file)
            self.assertEqual(len(sb_reloaded.get_leaderboard()), 2)
            self.assertEqual(sb_reloaded.get_leaderboard()[0]["score"], 4200)
        finally:
            if test_file.exists():
                test_file.unlink()


if __name__ == "__main__":
    unittest.main()
