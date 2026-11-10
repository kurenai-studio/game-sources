"""
Lane Legends: Human vs AI
ai_agent.py - Tabular Q-Learning Agent with State Discretization and Real-Time Explainability.
"""

import json
import random
from pathlib import Path
from typing import Dict, List, Tuple, Optional

from settings import (
    RL_ALPHA,
    RL_GAMMA,
    DIST_NEAR,
    DIST_MEDIUM,
    STATE_DIST_NEAR,
    STATE_DIST_MEDIUM,
    STATE_DIST_FAR,
    ACTION_LEFT,
    ACTION_STAY,
    ACTION_RIGHT,
    ACTION_NAMES,
    Q_TABLE_FILE,
)


class QLearningAgent:
    """
    Tabular Q-Learning agent for autonomous obstacle avoidance and lane navigation.
    
    State Space:
      - car_lane: 0 (Left), 1 (Center), 2 (Right)
      - left_dist: 0 (Near), 1 (Medium), 2 (Far/None)
      - mid_dist: 0 (Near), 1 (Medium), 2 (Far/None)
      - right_dist: 0 (Near), 1 (Medium), 2 (Far/None)
      Total Discrete States = 3 * 3 * 3 * 3 = 81 states.
      
    Action Space:
      - 0: MOVE_LEFT (invalid if in lane 0)
      - 1: STAY (always valid)
      - 2: MOVE_RIGHT (invalid if in lane 2)
    """

    def __init__(
        self,
        alpha: float = RL_ALPHA,
        gamma: float = RL_GAMMA,
        epsilon: float = 0.0,
    ):
        self.alpha = alpha
        self.gamma = gamma
        self.epsilon = epsilon
        self.episodes_trained = 0
        self.training_history: List[float] = []

        # Q-Table mapping: state_str -> [Q(s, left), Q(s, stay), Q(s, right)]
        self.q_table: Dict[str, List[float]] = {}
        self.initialize_q_table()

    def initialize_q_table(self) -> None:
        """Pre-populate the Q-table with zeros for all 81 valid states."""
        for lane in range(3):
            for dl in range(3):
                for dm in range(3):
                    for dr in range(3):
                        key = self.make_state_key(lane, dl, dm, dr)
                        # Invalid actions get initialized to heavily negative score
                        q_vals = [0.0, 0.0, 0.0]
                        if lane == 0:
                            q_vals[ACTION_LEFT] = -999.0
                        if lane == 2:
                            q_vals[ACTION_RIGHT] = -999.0
                        self.q_table[key] = q_vals

    @staticmethod
    def discretize_distance(distance_px: float) -> int:
        """Discretize continuous distance in pixels into Near (0), Medium (1), or Far/None (2)."""
        if distance_px < 0:
            return STATE_DIST_FAR
        if distance_px <= DIST_NEAR:
            return STATE_DIST_NEAR
        elif distance_px <= DIST_MEDIUM:
            return STATE_DIST_MEDIUM
        else:
            return STATE_DIST_FAR

    @staticmethod
    def make_state_key(lane: int, dl: int, dm: int, dr: int) -> str:
        """Create a compact standardized string key for state storage."""
        return f"{lane},{dl},{dm},{dr}"

    def encode_state(
        self,
        car_lane: int,
        dist_left_px: float,
        dist_mid_px: float,
        dist_right_px: float,
    ) -> str:
        """Convert continuous game observations into discrete state key."""
        dl = self.discretize_distance(dist_left_px)
        dm = self.discretize_distance(dist_mid_px)
        dr = self.discretize_distance(dist_right_px)
        lane = max(0, min(2, int(car_lane)))
        return self.make_state_key(lane, dl, dm, dr)

    @staticmethod
    def decode_state(state_key: str) -> Tuple[int, int, int, int]:
        """Decode state string back into (lane, dl, dm, dr)."""
        parts = [int(p) for p in state_key.split(",")]
        return parts[0], parts[1], parts[2], parts[3]

    @staticmethod
    def get_valid_actions(lane: int) -> List[int]:
        """Return list of geometrically valid actions for the current lane."""
        valid = [ACTION_STAY]
        if lane > 0:
            valid.append(ACTION_LEFT)
        if lane < 2:
            valid.append(ACTION_RIGHT)
        return valid

    def get_q_values(self, state_key: str) -> List[float]:
        """Retrieve Q-values for state, initializing if unseen."""
        if state_key not in self.q_table:
            lane, _, _, _ = self.decode_state(state_key)
            q_vals = [0.0, 0.0, 0.0]
            if lane == 0:
                q_vals[ACTION_LEFT] = -999.0
            if lane == 2:
                q_vals[ACTION_RIGHT] = -999.0
            self.q_table[state_key] = q_vals
        return self.q_table[state_key]

    def choose_action(
        self,
        state_key: str,
        epsilon: Optional[float] = None,
    ) -> int:
        """
        Choose action using epsilon-greedy action selection.
        Enforces validity: never selects an action that drives off-track.
        """
        eps = self.epsilon if epsilon is None else epsilon
        lane, _, _, _ = self.decode_state(state_key)
        valid_actions = self.get_valid_actions(lane)

        # Exploration: pick a random valid action
        if random.random() < eps:
            return random.choice(valid_actions)

        # Exploitation: pick highest Q-value among valid actions
        q_values = self.get_q_values(state_key)
        best_val = -float("inf")
        best_actions = []

        for action in valid_actions:
            val = q_values[action]
            if val > best_val:
                best_val = val
                best_actions = [action]
            elif abs(val - best_val) < 1e-6:
                best_actions.append(action)

        return random.choice(best_actions)

    def update(
        self,
        state_key: str,
        action: int,
        reward: float,
        next_state_key: str,
        done: bool = False,
    ) -> float:
        """
        Perform standard Bellman equation Q-learning update:
        Q(s, a) = Q(s, a) + alpha * [reward + gamma * max_a' Q(s', a') - Q(s, a)]
        """
        q_vals = self.get_q_values(state_key)
        old_val = q_vals[action]

        if done:
            target = reward
        else:
            next_lane, _, _, _ = self.decode_state(next_state_key)
            next_valid = self.get_valid_actions(next_lane)
            next_q = self.get_q_values(next_state_key)
            max_next_q = max(next_q[a] for a in next_valid)
            target = reward + self.gamma * max_next_q

        # Q-learning update step
        new_val = old_val + self.alpha * (target - old_val)
        q_vals[action] = round(new_val, 4)
        self.q_table[state_key] = q_vals

        return new_val

    def explain_decision(
        self,
        state_key: str,
        action: int,
    ) -> Dict[str, any]:
        """
        Generate explainability telemetry payload:
        Breaks down why the AI made this choice given the current lane & obstacle radar.
        """
        lane, dl, dm, dr = self.decode_state(state_key)
        lane_names = ["LEFT (0)", "CENTER (1)", "RIGHT (2)"]
        dist_names = ["NEAR ⚠️", "MEDIUM ⚡", "CLEAR / FAR ✅"]

        radar = [dl, dm, dr]
        curr_dist = radar[lane]
        action_name = ACTION_NAMES[action]
        q_values = self.get_q_values(state_key)

        reason = ""
        # Dynamic reason generation based on genuine game factors
        if action == ACTION_STAY:
            if curr_dist == STATE_DIST_FAR:
                reason = "Current lane is completely CLEAR. Maintaining straight line to maximize speed."
            elif curr_dist == STATE_DIST_MEDIUM:
                reason = "Obstacle detected at medium distance ahead, but lane is currently safe. Holding course."
            else:
                reason = "Surrounding lanes are equally or more hazardous. Holding lane and bracing for impact."
        elif action == ACTION_LEFT:
            target_dist = radar[lane - 1]
            if curr_dist == STATE_DIST_NEAR:
                reason = f"Imminent obstacle in current lane! Left lane is {dist_names[target_dist]}, providing emergency escape."
            else:
                reason = f"Left lane has superior clearance ({dist_names[target_dist]}) than current lane."
        elif action == ACTION_RIGHT:
            target_dist = radar[lane + 1]
            if curr_dist == STATE_DIST_NEAR:
                reason = f"Imminent obstacle in current lane! Right lane is {dist_names[target_dist]}, providing emergency escape."
            else:
                reason = f"Right lane has superior clearance ({dist_names[target_dist]}) than current lane."

        return {
            "state_key": state_key,
            "lane_label": lane_names[lane],
            "left_radar": dist_names[dl],
            "mid_radar": dist_names[dm],
            "right_radar": dist_names[dr],
            "action": action,
            "action_name": action_name,
            "q_values": {
                ACTION_NAMES[a]: round(q_values[a], 2)
                for a in range(3)
            },
            "selected_q": round(q_values[action], 2),
            "reason": reason,
        }

    def save(self, filepath: Optional[Path] = None) -> bool:
        """Save Q-table and metadata to JSON file."""
        target_file = filepath or Q_TABLE_FILE
        target_file.parent.mkdir(parents=True, exist_ok=True)
        data = {
            "algorithm": "Tabular Q-Learning",
            "episodes_trained": self.episodes_trained,
            "alpha": self.alpha,
            "gamma": self.gamma,
            "num_states": len(self.q_table),
            "q_table": self.q_table,
        }
        try:
            with open(target_file, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
            return True
        except Exception as e:
            print(f"[AI Agent] Failed to save Q-table: {e}")
            return False

    def load(self, filepath: Optional[Path] = None) -> bool:
        """Load trained Q-table and metadata from JSON file."""
        target_file = filepath or Q_TABLE_FILE
        if not target_file.exists():
            return False
        try:
            with open(target_file, "r", encoding="utf-8") as f:
                data = json.load(f)
            self.q_table = data.get("q_table", {})
            self.episodes_trained = data.get("episodes_trained", 0)
            self.alpha = data.get("alpha", self.alpha)
            self.gamma = data.get("gamma", self.gamma)
            return True
        except Exception as e:
            print(f"[AI Agent] Corrupted or invalid Q-table file: {e}")
            return False
