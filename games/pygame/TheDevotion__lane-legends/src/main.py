"""
Lane Legends: Human vs AI
main.py - Application Entry Point.
"""

import sys
from pathlib import Path

# Fix stdout encoding on Windows
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

from settings import DATA_DIR, Q_TABLE_FILE, HIGH_SCORES_FILE
from ai_trainer import ensure_trained_agent
from scoreboard import Scoreboard
from game import Game


def main():
    print("=" * 70)
    print(">>> LANE LEGENDS: HUMAN VS AI <<<")
    print("2D Arcade Car Racing with Authentic Tabular Q-Learning")
    print("=" * 70)

    # 1. Ensure required data directories exist
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    # 2. Verify or train RL Agent
    print("[INIT] Checking Tabular Q-Learning model...")
    agent = ensure_trained_agent(Q_TABLE_FILE)
    print(f"[INIT] Q-Table loaded successfully ({len(agent.q_table)} states, {agent.episodes_trained} episodes).")

    # 3. Verify high scores database
    Scoreboard(HIGH_SCORES_FILE)
    print("[INIT] High scores database verified.")

    # 4. Launch Pygame Game Engine
    print("[INIT] Launching graphics engine...")
    game = Game()
    game.run()


if __name__ == "__main__":
    main()
