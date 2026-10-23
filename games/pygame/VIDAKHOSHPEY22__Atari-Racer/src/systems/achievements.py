from data.achievements import ACHIEVEMENTS
from utils.persistence import load_stats, save_stats, load_achievements, save_achievements

class AchievementManager:
    def __init__(self):
        self.stats = load_stats()
        self.unlocked = load_achievements()
        self.pending = []

    def record(self, key, amount=1):
        self.stats[key] = self.stats.get(key, 0) + amount
        self._check()

    def set_stat(self, key, value):
        if value > self.stats.get(key, 0):
            self.stats[key] = value
            self._check()

    def _check(self):
        for ach in ACHIEVEMENTS:
            if ach["id"] not in self.unlocked and ach["check"](self.stats):
                self.unlocked.add(ach["id"])
                self.pending.append(ach)

    def pop_pending(self):
        return self.pending.pop(0) if self.pending else None

    def save(self):
        save_stats(self.stats)
        save_achievements(self.unlocked)
