"""Level discovery, scoring and persistent save data (progress + user settings). No pygame."""
import glob
import json
import os
from . import settings as S
from .level import Level

RANK_ORDER = {"S": 4, "A": 3, "B": 2, "C": 1}


def compute_rank(time_s, par, crystals, total):
    """S/A/B/C from crystal ratio and speed relative to the level's par time."""
    ratio = crystals / total if total else 1.0
    if ratio >= 1.0 and time_s <= par:
        return "S"
    if ratio >= 0.8 and time_s <= par * 1.5:
        return "A"
    if ratio >= 0.5 and time_s <= par * 2.2:
        return "B"
    return "C"


def compute_score(time_s, par, crystals, total):
    time_bonus = max(0, int((par * 1.5 - time_s) * 20))
    bonus = S.FULL_CLEAR_BONUS if total and crystals >= total else 0
    return crystals * S.CRYSTAL_SCORE + time_bonus + bonus


def format_time(seconds):
    seconds = max(0.0, seconds)
    return "%02d:%02d" % (int(seconds) // 60, int(seconds) % 60)


class LevelManager:
    """Knows where the level files are and loads fresh Level objects on demand."""

    def __init__(self, directory=S.LEVELS_DIR):
        self.paths = sorted(glob.glob(os.path.join(directory, "level_*.json")))
        self.meta = []
        for p in self.paths:                       # light read, just for the menu cards
            with open(p, "r", encoding="utf-8") as fh:
                d = json.load(fh)
            self.meta.append({"name": d.get("name", "?"), "subtitle": d.get("subtitle", ""),
                              "theme": d.get("theme", "factory")})

    @property
    def count(self):
        return len(self.paths)

    def load(self, index):
        return Level.from_file(self.paths[index], index)

    def has_next(self, index):
        return index + 1 < self.count


class SaveData:
    """Progress + settings stored as JSON in the user's home directory (falls back to ./data)."""

    def __init__(self):
        self.settings = dict(S.DEFAULT_SETTINGS)
        self.unlocked = 1                # number of unlocked levels
        self.best = {}                   # str(level index) -> {time, crystals, rank, score}
        self.path = self._pick_path()

    @staticmethod
    def _pick_path():
        home = os.path.join(os.path.expanduser("~"), ".robot_duo")
        try:
            os.makedirs(home, exist_ok=True)
            return os.path.join(home, "save.json")
        except OSError:
            return os.path.join(S.DATA_DIR, "save.json")

    @classmethod
    def load(cls):
        sd = cls()
        try:
            with open(sd.path, "r", encoding="utf-8") as fh:
                raw = json.load(fh)
            sd.settings.update({k: v for k, v in raw.get("settings", {}).items() if k in S.DEFAULT_SETTINGS})
            sd.unlocked = max(1, int(raw.get("unlocked", 1)))
            sd.best = dict(raw.get("best", {}))
        except (OSError, ValueError, TypeError):
            pass                         # first run or corrupt file: start fresh
        return sd

    def save(self):
        try:
            with open(self.path, "w", encoding="utf-8") as fh:
                json.dump({"settings": self.settings, "unlocked": self.unlocked, "best": self.best}, fh, indent=2)
        except OSError:
            pass                         # read-only disk: the game still works

    def record(self, index, time_s, crystals, rank, score, level_count):
        """Store a result; returns True if it is a new best score."""
        key = str(index)
        prev = self.best.get(key)
        is_best = prev is None or score > prev.get("score", 0)
        if is_best:
            self.best[key] = {"time": round(time_s, 2), "crystals": crystals, "rank": rank, "score": score}
        self.unlocked = max(self.unlocked, min(level_count, index + 2))
        self.save()
        return is_best
