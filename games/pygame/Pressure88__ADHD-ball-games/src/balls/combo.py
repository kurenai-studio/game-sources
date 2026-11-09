"""Repeated hits on the same plank build a small damage combo."""


class Behavior:
    name = "Комбо"
    description = "Урон растёт кубически при серии по одной планке"
    color = (255, 132, 105)

    def __init__(self):
        self.last_plank = None
        self.streak = 0

    def initial_speed(self):
        return 300.0

    def damage(self, hits, ball, plank_number):
        streak = self.streak if self.last_plank == plank_number else 0
        return 1 + streak ** 3

    def on_bounce(self, ball, hits, plank_number):
        # The ceiling uses plank_number 0; it should not break a plank-hit streak.
        if plank_number <= 0:
            return
        if self.last_plank == plank_number:
            self.streak += 1
        else:
            self.last_plank = plank_number
            self.streak = 0
