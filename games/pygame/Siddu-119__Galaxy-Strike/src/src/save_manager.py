"""Small, resilient JSON save-file manager."""

from copy import deepcopy
import json
import os

from settings import SAVE_PATH


DEFAULT_SAVE = {
    "high_score": 0,
    "credits": 0,
    "best_level": 0,
    "unlocked_level": 1,
    "completed_levels": [],
    "games_played": 0,
    "music_volume": 0.45,
    "sfx_volume": 0.65,
    "master_volume": 0.8,
    "music_enabled": True,
    "fullscreen": False,
    "resolution": "1280x720",
    "show_fps": True,
    "difficulty": "normal",
    "achievements": [],
    "total_kills": 0,
    "bosses_defeated": [],
    "ship_skin": 0,
}


class SaveManager:
    def __init__(self, path=SAVE_PATH):
        self.path = path
        self.data = deepcopy(DEFAULT_SAVE)
        self.load()

    def load(self):
        try:
            os.makedirs(os.path.dirname(self.path), exist_ok=True)
            with open(self.path, "r", encoding="utf-8") as save_file:
                loaded = json.load(save_file)
            if isinstance(loaded, dict):
                has_campaign_unlock = type(loaded.get("unlocked_level")) is int
                for key, default in DEFAULT_SAVE.items():
                    if key in loaded and isinstance(loaded[key], type(default)):
                        self.data[key] = loaded[key]
                self.data["achievements"] = list(dict.fromkeys(
                    achievement for achievement in self.data["achievements"]
                    if isinstance(achievement, str)
                ))[:100]
                self.data["bosses_defeated"] = list(dict.fromkeys(
                    boss for boss in self.data["bosses_defeated"]
                    if isinstance(boss, str) and
                    boss in ("alien_destroyer", "galactic_warship", "galaxy_overlord")
                ))
                self.data["total_kills"] = max(0, self.data["total_kills"])
                for key in ("master_volume", "music_volume", "sfx_volume"):
                    self.data[key] = max(0.0, min(1.0, float(self.data[key])))
                if self.data["resolution"] not in ("960x540", "1280x720", "1600x900"):
                    self.data["resolution"] = "1280x720"
                if self.data["difficulty"] not in ("easy", "normal", "hard"):
                    self.data["difficulty"] = "normal"
                completed = self.data["completed_levels"]
                self.data["completed_levels"] = sorted({
                    level for level in completed
                    if type(level) is int and 1 <= level <= 10
                })
                self.data["best_level"] = max(
                    0, min(10, self.data["best_level"])
                )
                if not has_campaign_unlock:
                    legacy_best = self.data["best_level"]
                    if legacy_best > 1:
                        self.data["completed_levels"] = sorted(set(
                            self.data["completed_levels"] + list(range(1, legacy_best + 1))
                        ))
                    elif legacy_best == 1 and "first_sector" in self.data["achievements"]:
                        self.data["completed_levels"] = sorted(
                            set(self.data["completed_levels"] + [1])
                        )
                        legacy_best = 1
                completed_set = set(self.data["completed_levels"])
                contiguous_completed = []
                for level_number in range(1, 11):
                    if level_number not in completed_set:
                        break
                    contiguous_completed.append(level_number)
                self.data["completed_levels"] = contiguous_completed
                self.data["best_level"] = len(contiguous_completed)
                self.data["unlocked_level"] = min(10, max(1, len(contiguous_completed) + 1))
        except FileNotFoundError:
            self.save()
        except (OSError, json.JSONDecodeError) as error:
            print(f"Save data could not be loaded ({error}); using defaults.")
            self.save()

    def save(self):
        try:
            os.makedirs(os.path.dirname(self.path), exist_ok=True)
            temporary_path = self.path + ".tmp"
            with open(temporary_path, "w", encoding="utf-8") as save_file:
                json.dump(self.data, save_file, indent=2)
            os.replace(temporary_path, self.path)
        except OSError as error:
            print(f"Save data could not be written: {error}")

    def award(self, key, amount):
        self.data[key] = self.data.get(key, 0) + amount
        self.save()

    def unlock(self, achievement):
        if achievement not in self.data["achievements"]:
            self.data["achievements"].append(achievement)
            self.save()
