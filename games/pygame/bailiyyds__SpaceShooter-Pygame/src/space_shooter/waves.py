"""波次系统：根据波数决定敌人数量、种类比例和速度，难度逐步上升。"""
import random
from entities import Enemy
from settings import WIDTH


class WaveManager:
    def __init__(self):
        self.wave = 0
        self.queue = []
        self.spawn_timer = 0.0
        self.rest = 2.0          # 波次间隔

    def plan(self, n):
        """第 n 波：数量 8+3n，第 2 波起出现 weaver，第 3 波起出现 gunner。"""
        count = 8 + 3 * n
        kinds = []
        for i in range(count):
            if n >= 3 and i % 6 == 5:
                kinds.append("gunner")
            elif n >= 2 and i % 3 == 1:
                kinds.append("weaver")
            else:
                kinds.append("grunt")
        random.shuffle(kinds)
        return kinds

    @property
    def interval(self):
        return max(0.18, 0.55 - self.wave * 0.05)

    @property
    def speed_scale(self):
        return min(1.8, 1.0 + self.wave * 0.06)

    def update(self, dt, game):
        if not self.queue:
            if any(e.alive for e in game.enemies):
                return
            self.rest -= dt
            if self.rest <= 0:
                self.wave += 1
                self.queue = self.plan(self.wave)
                self.rest = 2.0
                game.banner(f"第 {self.wave} 波")
            return
        self.spawn_timer -= dt
        if self.spawn_timer <= 0:
            self.spawn_timer = self.interval
            kind = self.queue.pop()
            margin = 80 if kind == "weaver" else 30
            game.enemies.append(Enemy(random.uniform(margin, WIDTH - margin), kind, self.speed_scale))
