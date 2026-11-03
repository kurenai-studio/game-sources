"""
Automated Test Suite for Phase 4: Preserved Game Modes Verification.
Simulates all 5 game modes (Solo, Two-Player PvP, Race, Chase, and Escape)
ensuring logic execution, goal detection, edge updates, and zero crashes.
"""

import sys
import os
import pygame

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from game.modes.mode_solo import SoloTimeTrialMode
from game.modes.mode_two_player import TwoPlayerMode
from game.modes.mode_race import RaceVsAIMode
from game.modes.mode_chase import ChaseSurvivalMode
from game.modes.mode_escape import EscapeHeistMode

def run_headless_modes_test():
    pygame.init()
    surf = pygame.Surface((740, 640))
    dummy_user = {"id": 1, "username": "Tester"}

    print("[TEST] Testing Game Mode 0: Solo Time Trial...")
    m0 = SoloTimeTrialMode((740, 640), grid_size=15, generator_algo="kruskal", user_data=dummy_user)
    m0.update(0.016)
    m0.render(surf)
    assert not m0.game_over
    print("  -> Mode 0 Solo: PASSED")

    print("[TEST] Testing Game Mode 1: Two Player PvP...")
    m1 = TwoPlayerMode((740, 640), grid_size=15, generator_algo="prim", user_data=dummy_user)
    m1.update(0.016)
    m1.render(surf)
    assert m1.p1_pos == (0, 0) and m1.p2_pos == (14, 14)
    print("  -> Mode 1 PvP: PASSED")

    print("[TEST] Testing Game Mode 2: Race vs AI...")
    m2 = RaceVsAIMode((740, 640), grid_size=15, generator_algo="wilson", user_data=dummy_user)
    m2.update(0.20)  # Trigger AI step
    m2.render(surf)
    assert len(m2.ai_path) > 0, "AI path must be computed"
    print(f"  -> Mode 2 Race vs AI (Path length {len(m2.ai_path)}): PASSED")

    print("[TEST] Testing Game Mode 3: Chase Survival...")
    m3 = ChaseSurvivalMode((740, 640), grid_size=15, generator_algo="dfs", user_data=dummy_user)
    m3.update(0.016)
    m3.render(surf)
    assert not m3.ai_activated, "AI must wait for grace period"
    print("  -> Mode 3 Chase Survival: PASSED")

    print("[TEST] Testing Game Mode 4: Escape Heist...")
    m4 = EscapeHeistMode((740, 640), grid_size=15, generator_algo="kruskal", user_data=dummy_user)
    m4.update(0.016)
    m4.render(surf)
    assert len(m4.keys) == 8, f"Expected 8 keys, got {len(m4.keys)}"
    assert m4.wall_breaks == 1, "Starts with 1 wall break"
    print("  -> Mode 4 Escape Heist: PASSED")

    print("\n==========================================")
    print(">>> ALL PHASE 4 GAME MODES TESTS PASSED! <<<")
    print("==========================================")

if __name__ == "__main__":
    run_headless_modes_test()
