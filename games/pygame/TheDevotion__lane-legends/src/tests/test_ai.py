"""
Unit Tests for Q-Learning Agent and RL Training Simulation.
"""

import sys
import unittest
from pathlib import Path

# Add project root to path
PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from settings import (
    ACTION_LEFT,
    ACTION_STAY,
    ACTION_RIGHT,
    STATE_DIST_NEAR,
    STATE_DIST_MEDIUM,
    STATE_DIST_FAR,
    DIST_NEAR,
    DIST_MEDIUM,
)
from ai_agent import QLearningAgent
from ai_trainer import HeadlessRacingEnv


class TestQLearningAgent(unittest.TestCase):
    def setUp(self):
        self.agent = QLearningAgent(alpha=0.15, gamma=0.90)

    def test_state_space_size(self):
        """Verify the state space covers exactly 81 states (3 * 3 * 3 * 3)."""
        self.assertEqual(len(self.agent.q_table), 81)

    def test_distance_discretization(self):
        """Test continuous to discrete distance categorization."""
        self.assertEqual(self.agent.discretize_distance(50.0), STATE_DIST_NEAR)
        self.assertEqual(self.agent.discretize_distance(DIST_NEAR), STATE_DIST_NEAR)
        self.assertEqual(self.agent.discretize_distance(DIST_NEAR + 10.0), STATE_DIST_MEDIUM)
        self.assertEqual(self.agent.discretize_distance(DIST_MEDIUM), STATE_DIST_MEDIUM)
        self.assertEqual(self.agent.discretize_distance(DIST_MEDIUM + 50.0), STATE_DIST_FAR)
        self.assertEqual(self.agent.discretize_distance(9999.0), STATE_DIST_FAR)

    def test_state_encoding_decoding(self):
        """Test encoding and decoding round-trip."""
        key = self.agent.make_state_key(1, 0, 2, 1)
        self.assertEqual(key, "1,0,2,1")
        lane, dl, dm, dr = self.agent.decode_state(key)
        self.assertEqual((lane, dl, dm, dr), (1, 0, 2, 1))

    def test_valid_actions_masking(self):
        """Verify invalid lane movements are strictly masked."""
        # Lane 0 (Leftmost): cannot move left
        valid_0 = self.agent.get_valid_actions(0)
        self.assertIn(ACTION_STAY, valid_0)
        self.assertIn(ACTION_RIGHT, valid_0)
        self.assertNotIn(ACTION_LEFT, valid_0)

        # Lane 1 (Center): can move left, stay, or right
        valid_1 = self.agent.get_valid_actions(1)
        self.assertIn(ACTION_LEFT, valid_1)
        self.assertIn(ACTION_STAY, valid_1)
        self.assertIn(ACTION_RIGHT, valid_1)

        # Lane 2 (Rightmost): cannot move right
        valid_2 = self.agent.get_valid_actions(2)
        self.assertIn(ACTION_LEFT, valid_2)
        self.assertIn(ACTION_STAY, valid_2)
        self.assertNotIn(ACTION_RIGHT, valid_2)

    def test_invalid_action_q_value(self):
        """Verify invalid actions in initial Q-table have heavily negative values."""
        q_lane0 = self.agent.get_q_values("0,2,2,2")
        self.assertLess(q_lane0[ACTION_LEFT], -500.0)

        q_lane2 = self.agent.get_q_values("2,2,2,2")
        self.assertLess(q_lane2[ACTION_RIGHT], -500.0)

    def test_q_learning_update_step(self):
        """Verify Bellman update equation: Q(s,a) = Q(s,a) + alpha * [r + gamma * max Q(s',a') - Q(s,a)]."""
        s = "1,2,2,2"
        a = ACTION_STAY
        r = 10.0
        s_next = "1,2,2,2"
        # Initial Q(s, a) = 0.0, Q(s', a') = 0.0
        # Expected new Q = 0.0 + 0.15 * [10.0 + 0.9 * 0.0 - 0.0] = 1.5
        new_q = self.agent.update(s, a, r, s_next, done=False)
        self.assertAlmostEqual(new_q, 1.5, places=3)
        self.assertAlmostEqual(self.agent.get_q_values(s)[a], 1.5, places=3)

    def test_explainability_payload(self):
        """Test dynamic explanation output."""
        # State: In middle lane (1), obstacle Near in center, Left clear, Right clear
        s = "1,2,0,2"
        # Artificially set high Q for MOVE_LEFT
        self.agent.q_table[s] = [25.0, -20.0, 10.0]
        explanation = self.agent.explain_decision(s, ACTION_LEFT)

        self.assertEqual(explanation["action"], ACTION_LEFT)
        self.assertEqual(explanation["action_name"], "MOVE_LEFT")
        self.assertIn("emergency escape", explanation["reason"].lower())
        self.assertEqual(explanation["selected_q"], 25.0)

    def test_save_and_load(self, tmp_path=None):
        """Test Q-table serialization and loading from JSON."""
        test_file = PROJECT_ROOT / "data" / "test_q_table.json"
        try:
            self.agent.episodes_trained = 500
            self.agent.q_table["1,0,0,0"] = [5.5, -10.0, 8.2]
            saved = self.agent.save(test_file)
            self.assertTrue(saved)

            new_agent = QLearningAgent()
            loaded = new_agent.load(test_file)
            self.assertTrue(loaded)
            self.assertEqual(new_agent.episodes_trained, 500)
            self.assertEqual(new_agent.get_q_values("1,0,0,0"), [5.5, -10.0, 8.2])
        finally:
            if test_file.exists():
                test_file.unlink()


class TestHeadlessEnvironment(unittest.TestCase):
    def test_environment_reset_and_step(self):
        """Verify headless training environment advances and produces valid states and rewards."""
        env = HeadlessRacingEnv(track_length=2000.0)
        state_key = env.reset()
        self.assertIsInstance(state_key, str)

        next_state, reward, done, info = env.step(ACTION_STAY)
        self.assertIsInstance(next_state, str)
        self.assertIsInstance(reward, float)
        self.assertIsInstance(done, bool)
        self.assertIn("collision", info)


if __name__ == "__main__":
    unittest.main()
