"""Damage grows gently with the total bounce count."""

import math


class Behavior:
    name = "Формула урона"
    description = "Урон растёт квадратично, ступенями по отскокам"
    color = (255, 194, 79)

    def initial_speed(self):
        return 340.0

    def damage(self, hits, ball, plank_number):
        return 1 + (hits // 4) ** 2

    def on_bounce(self, ball, hits, plank_number):
        pass
