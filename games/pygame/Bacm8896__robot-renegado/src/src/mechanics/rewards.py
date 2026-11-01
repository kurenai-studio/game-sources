"""Rewards System (Prioridad 4): seguimiento de los desbloqueos permanentes que dan las bases enemigas destruidas.

El tracker vive en el ResourceManager (`res.reward_tracker`), así que persiste entre mapas y se guarda en los checkpoints."""
import pygame

from src.config import UNITS as U


class RewardTracker:
    def __init__(self):
        self.unlocked_rewards = set()                 # {"AURA_PART_1", "PLAYER_UPGRADE_2", ...}
        self.aura_parts_count = 0                     # 0-6
        self.player_upgrades_count = 0                # 0-6
        self.drone_upgrades = {"recon": False, "attack": False, "bomber": False, "trooper": False}
        self.reward_history = []                      # [{"id", "name", "timestamp"}] en orden de obtención

    def add_reward(self, reward_id):
        """Desbloquea un reward. False si ya lo tenías o el id no existe."""
        if reward_id in self.unlocked_rewards or reward_id not in U.REWARD_DEFINITIONS:
            return False
        reward = U.REWARD_DEFINITIONS[reward_id]
        self.unlocked_rewards.add(reward_id)
        self.reward_history.append({"id": reward_id, "name": reward["name"], "timestamp": pygame.time.get_ticks()})
        if reward["type"] == "aura_part":
            self.aura_parts_count = min(6, self.aura_parts_count + 1)
        elif reward["type"] == "player_upgrade":
            self.player_upgrades_count = min(6, self.player_upgrades_count + 1)
        elif reward["type"] == "drone_upgrade":
            self.drone_upgrades[reward["drone_type"]] = True
        return True

    def is_unlocked(self, reward_id):
        return reward_id in self.unlocked_rewards

    def get_progress(self):
        return {"aura_parts": f"{self.aura_parts_count}/6", "player_upgrades": f"{self.player_upgrades_count}/6",
                "drone_upgrades": sum(self.drone_upgrades.values()), "total_rewards": len(self.unlocked_rewards)}

    def aura_complete(self):
        return self.aura_parts_count == 6

    # --- efectos ---
    def player_bonus(self, key):
        """Suma del bonus `key` de las mejoras de Operador desbloqueadas (0 si ninguna lo da)."""
        return sum(U.REWARD_DEFINITIONS[r]["bonus"].get(key, 0) for r in self.unlocked_rewards
                   if U.REWARD_DEFINITIONS[r]["type"] == "player_upgrade")

    def drone_bonus(self, drone_type):
        """Bonus de la mejora de recompensa del dron `drone_type` (vacío si no está desbloqueada)."""
        for rid in self.unlocked_rewards:
            spec = U.REWARD_DEFINITIONS[rid]
            if spec["type"] == "drone_upgrade" and spec["drone_type"] == drone_type:
                return dict(spec["bonus"])
        return {}
