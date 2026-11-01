"""Ten-stage campaign definitions and score-scaled wave scheduling."""

import random


LEVELS = [
    {
        "title": "FIRST CONTACT",
        "subtitle": "Unknown signals cross the frontier.",
        "theme": "basic",
        "challenge": "Learn the enemy's basic patrol patterns.",
        "background": ((4, 9, 25), (16, 28, 67), (32, 85, 133), "stars"),
    },
    {
        "title": "ASTEROID FIELD",
        "subtitle": "Hostile fighters weave through the debris.",
        "theme": "fast",
        "challenge": "Fast zigzag ships and shifting asteroid lanes.",
        "background": ((10, 12, 24), (53, 38, 48), (174, 123, 87), "asteroids"),
    },
    {
        "title": "ALIEN INVASION",
        "subtitle": "The first wave is only the beginning.",
        "theme": "mixed",
        "challenge": "Mixed formations arrive in increasingly dense waves.",
        "background": ((11, 5, 28), (57, 21, 75), (170, 64, 154), "rift"),
    },
    {
        "title": "DARK NEBULA",
        "subtitle": "Sensors are unreliable in the violet haze.",
        "theme": "shooting",
        "challenge": "Aimed gunships strike through the nebula.",
        "background": ((4, 8, 24), (30, 18, 83), (93, 65, 183), "nebula"),
    },
    {
        "title": "DESTROYER'S TERRITORY",
        "subtitle": "An Alien Destroyer guards the outer passage.",
        "theme": "heavy",
        "challenge": "Break the armored screen and defeat the Alien Destroyer.",
        "background": ((19, 5, 25), (72, 18, 52), (223, 65, 114), "warzone"),
    },
    {
        "title": "GALACTIC WARZONE",
        "subtitle": "The entire enemy fleet has mobilized.",
        "theme": "shooting",
        "challenge": "Gunships coordinate volleys with heavy escorts.",
        "background": ((4, 12, 29), (14, 43, 82), (50, 151, 196), "fleet"),
    },
    {
        "title": "METEOR STORM",
        "subtitle": "Hostile pilots hide among blazing debris.",
        "theme": "kamikaze",
        "challenge": "Fast divers and kamikaze ships pressure your position.",
        "background": ((20, 8, 22), (79, 35, 40), (255, 131, 73), "meteors"),
    },
    {
        "title": "ENEMY ARMADA",
        "subtitle": "A wall of warships blocks the jump gate.",
        "theme": "mixed",
        "challenge": "Large mixed formations leave few safe lanes.",
        "background": ((5, 10, 29), (23, 36, 82), (81, 127, 210), "armada"),
    },
    {
        "title": "OVERLORD'S DOMAIN",
        "subtitle": "The Galactic Warship stands between you and the core.",
        "theme": "elite",
        "challenge": "Elite escorts protect the Galactic Warship.",
        "background": ((17, 5, 27), (70, 18, 67), (206, 62, 151), "domain"),
    },
    {
        "title": "FINAL GALAXY BATTLE",
        "subtitle": "One last fight for every world in the galaxy.",
        "theme": "mixed",
        "challenge": "Endure the final armada and destroy the Ultimate Overlord.",
        "background": ((19, 6, 25), (89, 24, 47), (255, 181, 78), "final"),
    },
]


class Level:
    def __init__(self, number):
        self.number = max(1, min(10, number))
        definition = LEVELS[self.number - 1]
        self.title = definition["title"]
        self.subtitle = definition["subtitle"]
        self.theme = definition["theme"]
        self.challenge = definition["challenge"]
        self.background = definition["background"]
        self.elapsed = 0.0
        self.spawn_timer = 1.2
        self.duration = 34.0 + self.number * 1.1
        self.boss_level = self.number in (5, 9, 10)
        self.boss_spawned = False
        self.complete = False
        self.spawned = 0
        self.formation = "line"

    def update(self, dt, score=0, difficulty_scale=1.0):
        self.elapsed += dt
        self.spawn_timer -= dt
        spawn = []
        score_tier = min(6, max(0, score) // 2500)
        level_pressure = self.number - 1
        interval = max(
            0.34,
            (1.3 - level_pressure * 0.065 - score_tier * 0.04) /
            max(0.5, difficulty_scale),
        )
        if self.spawn_timer <= 0 and self.elapsed < self.duration - 1:
            self.spawn_timer = interval * random.uniform(0.82, 1.18)
            count = 1
            if self.number >= 2 and random.random() < 0.3:
                count = 2
            if self.number >= 4 and random.random() < 0.23:
                count = 3
            if self.number >= 7 and random.random() < 0.12:
                count = 4
            self.formation = random.choice(("line", "v", "column", "scatter"))
            for _ in range(count):
                spawn.append(self._choose_enemy())
                self.spawned += 1
        boss_ready = (
            self.boss_level and not self.boss_spawned and
            self.elapsed >= self.duration * 0.68
        )
        if boss_ready:
            self.boss_spawned = True
        return spawn, boss_ready

    def _choose_enemy(self):
        if self.theme != "mixed" and random.random() < 0.58:
            return self.theme
        pools = {
            1: ("basic",),
            2: ("basic", "fast"),
            3: ("basic", "fast", "shooting"),
            4: ("basic", "fast", "shooting", "heavy"),
            5: ("basic", "heavy", "shooting"),
            6: ("basic", "heavy", "shooting", "elite"),
            7: ("fast", "kamikaze", "shooting"),
            8: ("fast", "heavy", "shooting", "elite"),
            9: ("heavy", "shooting", "elite"),
            10: ("fast", "heavy", "shooting", "kamikaze", "elite"),
        }
        return random.choice(pools[self.number])

    def formation_positions(self, width, count):
        if count <= 0:
            return []
        spacing = 68
        span = spacing * max(0, count - 1)
        center = random.uniform(45 + span / 2, width - 45 - span / 2)
        positions = []
        for index in range(count):
            offset = (index - (count - 1) / 2) * spacing
            if self.formation == "column":
                x, y = center + random.uniform(-18, 18), -38 - index * 44
            elif self.formation == "v":
                x, y = center + offset, -38 - abs(offset) * 0.48
            elif self.formation == "scatter":
                x, y = random.uniform(30, width - 30), -38 - random.uniform(0, 32)
            else:
                x, y = center + offset, -38
            positions.append((max(30, min(width - 30, x)), y))
        return positions

    def mark_complete(self):
        self.complete = True

    def reward(self):
        return 400 + self.number * 275

    def credit_reward(self):
        return 125 + self.number * 50
