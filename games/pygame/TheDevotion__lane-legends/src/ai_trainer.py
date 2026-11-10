"""
Lane Legends: Human vs AI
ai_trainer.py - Offline Reinforcement Learning Training Environment for Q-Learning Agent.

This module provides an optimized, headless training loop that trains the tabular Q-Learning
agent across hundreds or thousands of simulated races until high-performance obstacle avoidance
and lane discipline policy converges.
"""

import sys
import random
import time
from pathlib import Path
from typing import List, Tuple, Optional

# Ensure UTF-8 output on Windows consoles if possible
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

from settings import (
    RL_ALPHA,
    RL_GAMMA,
    RL_EPSILON_START,
    RL_EPSILON_MIN,
    RL_EPSILON_DECAY,
    RL_TRAINING_EPISODES,
    DIST_NEAR,
    DIST_MEDIUM,
    STATE_DIST_NEAR,
    STATE_DIST_MEDIUM,
    STATE_DIST_FAR,
    ACTION_LEFT,
    ACTION_STAY,
    ACTION_RIGHT,
    ACTION_NAMES,
    REWARD_PROGRESS,
    REWARD_PASS_OBSTACLE,
    REWARD_AVOID_DANGER,
    REWARD_UNNECESSARY_CHANGE,
    REWARD_COLLISION,
    REWARD_FINISH,
    Q_TABLE_FILE,
)
from ai_agent import QLearningAgent


class TrainingObstacle:
    """Simulated obstacle on a track lane."""
    def __init__(self, lane: int, distance: float):
        self.lane = lane
        self.distance = distance  # pixels ahead of car


class HeadlessRacingEnv:
    """
    Lightweight, deterministic, headless 2D racing environment for rapid RL training.
    Executes thousands of steps per second without graphical overhead.
    """

    def __init__(self, track_length: float = 12000.0, step_speed: float = 24.0):
        self.track_length = track_length
        self.step_speed = step_speed
        self.car_lane = 1
        self.distance_traveled = 0.0
        self.obstacles: List[TrainingObstacle] = []
        self.reset()

    def reset(self) -> str:
        """Reset the environment for a new episode."""
        self.car_lane = random.choice([0, 1, 2])
        self.distance_traveled = 0.0
        self.obstacles.clear()

        # Generate a balanced stream of obstacles with at least one escape lane always open
        current_y = 400.0
        while current_y < self.track_length:
            pattern_type = random.random()
            if pattern_type < 0.65:
                # Single obstacle
                blocked_lane = random.choice([0, 1, 2])
                self.obstacles.append(TrainingObstacle(blocked_lane, current_y))
            else:
                # Double obstacle (2 lanes blocked, 1 open escape lane)
                open_lane = random.choice([0, 1, 2])
                for l in range(3):
                    if l != open_lane:
                        self.obstacles.append(TrainingObstacle(l, current_y))

            # Space between obstacles: 300 to 520 px
            current_y += random.uniform(320.0, 520.0)

        return self.get_state_key()

    def get_radar_distances(self) -> Tuple[float, float, float]:
        """Compute nearest obstacle distance ahead for each of the 3 lanes."""
        dists = [9999.0, 9999.0, 9999.0]
        for obs in self.obstacles:
            if obs.distance >= 0:
                if obs.distance < dists[obs.lane]:
                    dists[obs.lane] = obs.distance
        return dists[0], dists[1], dists[2]

    def get_state_key(self) -> str:
        """Encode current state into discrete string representation."""
        dl, dm, dr = self.get_radar_distances()
        lane = self.car_lane
        dl_disc = QLearningAgent.discretize_distance(dl)
        dm_disc = QLearningAgent.discretize_distance(dm)
        dr_disc = QLearningAgent.discretize_distance(dr)
        return QLearningAgent.make_state_key(lane, dl_disc, dm_disc, dr_disc)

    def step(self, action: int) -> Tuple[str, float, bool, dict]:
        """
        Advance one simulation step.
        Returns: (next_state_key, reward, done, info)
        """
        # Prior radar for evaluation
        prev_dl, prev_dm, prev_dr = self.get_radar_distances()
        prev_radar = [prev_dl, prev_dm, prev_dr]
        prev_lane = self.car_lane
        danger_in_prev_lane = prev_radar[prev_lane] <= DIST_NEAR

        # Apply lane change
        lane_changed = False
        if action == ACTION_LEFT and self.car_lane > 0:
            self.car_lane -= 1
            lane_changed = True
        elif action == ACTION_RIGHT and self.car_lane < 2:
            self.car_lane += 1
            lane_changed = True

        # Advance road
        self.distance_traveled += self.step_speed
        for obs in self.obstacles:
            obs.distance -= self.step_speed

        # Check collisions and passed obstacles
        collision = False
        passed_obstacles = 0

        for obs in self.obstacles:
            # Collision box window: near contact zone
            if -25.0 <= obs.distance <= 35.0 and obs.lane == self.car_lane:
                collision = True
            elif -40.0 <= obs.distance < -10.0:
                passed_obstacles += 1

        # Purge passed obstacles
        self.obstacles = [obs for obs in self.obstacles if obs.distance > -50.0]

        # Calculate Reward
        reward = REWARD_PROGRESS
        done = False
        info = {"collision": False, "passed": passed_obstacles}

        if collision:
            reward = REWARD_COLLISION
            info["collision"] = True
        elif passed_obstacles > 0:
            reward += passed_obstacles * REWARD_PASS_OBSTACLE

        # Avoidance bonus vs Unnecessary lane switch penalty
        if lane_changed:
            if danger_in_prev_lane:
                reward += REWARD_AVOID_DANGER
            elif prev_radar[prev_lane] > DIST_MEDIUM:
                reward += REWARD_UNNECESSARY_CHANGE

        # Check race finish
        if self.distance_traveled >= self.track_length:
            reward += REWARD_FINISH
            done = True

        next_state_key = self.get_state_key()
        return next_state_key, reward, done, info


def train_agent(
    episodes: int = RL_TRAINING_EPISODES,
    save_path: Optional[Path] = None,
    verbose: bool = True,
) -> QLearningAgent:
    """
    Train tabular Q-Learning agent on simulated obstacle tracks.
    """
    target_path = save_path or Q_TABLE_FILE
    agent = QLearningAgent(alpha=RL_ALPHA, gamma=RL_GAMMA)
    env = HeadlessRacingEnv()

    epsilon = RL_EPSILON_START
    start_time = time.time()

    if verbose:
        print("=" * 70)
        print(">>> LANE LEGENDS: TABULAR Q-LEARNING AGENT TRAINING <<<")
        print("=" * 70)
        print(f"Episodes: {episodes} | Alpha: {RL_ALPHA} | Gamma: {RL_GAMMA}")
        print(f"Discrete States: 81 | Target File: {target_path.name}")
        print("-" * 70)

    total_rewards = []
    total_collisions = []

    for ep in range(1, episodes + 1):
        state_key = env.reset()
        episode_reward = 0.0
        episode_collisions = 0
        done = False

        while not done:
            action = agent.choose_action(state_key, epsilon=epsilon)
            next_state_key, reward, done, info = env.step(action)

            # Standard Q-learning Bellman update
            agent.update(state_key, action, reward, next_state_key, done)

            state_key = next_state_key
            episode_reward += reward
            if info["collision"]:
                episode_collisions += 1

        total_rewards.append(episode_reward)
        total_collisions.append(episode_collisions)

        # Decay exploration rate
        epsilon = max(RL_EPSILON_MIN, epsilon * RL_EPSILON_DECAY)

        # Periodic logging
        if verbose and (ep % 200 == 0 or ep == episodes):
            recent_rewards = total_rewards[-200:]
            recent_collisions = total_collisions[-200:]
            avg_rew = sum(recent_rewards) / len(recent_rewards)
            avg_col = sum(recent_collisions) / len(recent_collisions)
            elapsed = time.time() - start_time
            print(
                f"Episode {ep:4d}/{episodes:4d} | "
                f"Avg Reward: {avg_rew:6.1f} | "
                f"Avg Collisions: {avg_col:4.2f} | "
                f"Epsilon: {epsilon:.3f} | "
                f"Elapsed: {elapsed:.2f}s"
            )

    agent.episodes_trained = episodes
    agent.save(target_path)

    if verbose:
        print("-" * 70)
        print(f"[OK] Training completed in {time.time() - start_time:.2f} seconds!")
        print(f"[SAVE] Q-Table successfully saved to: {target_path}")
        print("=" * 70)

    return agent


def ensure_trained_agent(filepath: Optional[Path] = None) -> QLearningAgent:
    """
    Ensure a trained agent exists. If q_table.json is present, loads it.
    If missing or corrupt, triggers fast automatic training and saves it.
    """
    target_path = filepath or Q_TABLE_FILE
    agent = QLearningAgent()
    if agent.load(target_path) and agent.episodes_trained > 0:
        return agent

    print("[AI Trainer] Trained Q-table not found or corrupted. Auto-training a fresh model...")
    return train_agent(episodes=RL_TRAINING_EPISODES, save_path=target_path, verbose=False)


if __name__ == "__main__":
    episodes_arg = RL_TRAINING_EPISODES
    if len(sys.argv) > 1:
        try:
            episodes_arg = int(sys.argv[1])
        except ValueError:
            pass
    train_agent(episodes=episodes_arg)
