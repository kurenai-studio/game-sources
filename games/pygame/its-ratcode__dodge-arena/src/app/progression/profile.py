"""The player's profile: coins, upgrade levels and best time, kept in the save file."""

import math
from dataclasses import dataclass

from app import config
from app.core.storage import SaveFile
from app.progression.upgrades import UPGRADE_BY_ID, UPGRADES, RunStats


def survival_bonus(seconds: float) -> int:
    """Coins paid at the end of a run just for staying alive."""
    return int(seconds * config.COINS_PER_SECOND_SURVIVED)


@dataclass(frozen=True)
class RunResult:
    """What a finished run was worth, for the game over screen."""

    time: float
    picked_up: int
    bonus: int
    new_best: bool
    counted: bool = True                # False when assists were on, so it couldn't set a best time

    @property
    def coins(self) -> int:
        return self.picked_up + self.bonus


def _is_int(value) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)    # JSON true is not a number


class Profile:
    """Loads its ``progress`` section, validates it, and saves after every change.

    Selling refunds exactly what the last level cost, so trying a build never
    loses coins.
    """

    SECTION = "progress"

    def __init__(self, save_file: SaveFile) -> None:
        self.save_file = save_file
        self.coins = 0
        self.best_time = 0.0
        self.levels = {u.id: 0 for u in UPGRADES}
        self._load(save_file.section(self.SECTION))

    def _load(self, data: dict) -> None:
        """Take each saved value only if it is valid; anything else keeps its default."""
        coins = data.get("coins")
        if _is_int(coins) and coins >= 0:
            self.coins = coins
        best = data.get("best_time")
        if (_is_int(best) or isinstance(best, float)) and math.isfinite(best) and best >= 0:
            self.best_time = float(best)
        levels = data.get("upgrades")
        if isinstance(levels, dict):
            for uid, upgrade in UPGRADE_BY_ID.items():
                level = levels.get(uid)
                if _is_int(level):
                    self.levels[uid] = max(0, min(upgrade.max_level, level))

    def to_dict(self) -> dict:
        return {"coins": self.coins, "best_time": round(self.best_time, 2), "upgrades": dict(self.levels)}

    def save(self) -> bool:
        return self.save_file.write(self.SECTION, self.to_dict())

    def stats(self) -> RunStats:
        return RunStats.from_levels(self.levels)

    # --- Runs ------------------------------------------------------------------------------
    def record_run(self, seconds: float, picked_up: int, counts_for_best: bool = True) -> RunResult:
        """Bank a finished run's coins (and its best time, if it counts), then save."""
        new_best = counts_for_best and seconds > self.best_time
        result = RunResult(seconds, picked_up, survival_bonus(seconds), new_best, counts_for_best)
        self.coins += result.coins
        if new_best:
            self.best_time = seconds
        self.save()
        return result

    # --- Upgrades ----------------------------------------------------------------------------
    def level(self, uid: str) -> int:
        return self.levels[uid]

    def cost(self, uid: str) -> int | None:
        """Price of the next level, or None at max level."""
        upgrade = UPGRADE_BY_ID[uid]
        level = self.levels[uid]
        return None if level >= upgrade.max_level else upgrade.cost(level)

    def can_buy(self, uid: str) -> bool:
        price = self.cost(uid)
        return price is not None and self.coins >= price

    def buy(self, uid: str) -> bool:
        if not self.can_buy(uid):
            return False
        self.coins -= self.cost(uid)
        self.levels[uid] += 1
        self.save()
        return True

    def refund(self, uid: str) -> int | None:
        """What selling one level gives back (what it cost), or None at level 0."""
        level = self.levels[uid]
        return UPGRADE_BY_ID[uid].cost(level - 1) if level > 0 else None

    def sell(self, uid: str) -> int | None:
        refund = self.refund(uid)
        if refund is None:
            return None
        self.levels[uid] -= 1
        self.coins += refund
        self.save()
        return refund

    def sell_all(self) -> int:
        """Sell every level of every upgrade. Returns the coins refunded."""
        total = 0
        for uid in self.levels:
            while self.levels[uid] > 0:
                total += self.refund(uid)
                self.levels[uid] -= 1
        self.coins += total
        self.save()
        return total
