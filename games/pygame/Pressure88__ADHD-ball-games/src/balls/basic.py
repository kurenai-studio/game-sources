"""Steady quadratic damage growth based on the number of bounces."""


class Behavior:
    name = "Обычный"
    description = "Урон растёт квадратично со счётчиком отскоков"
    color = (255, 103, 145)

    def initial_speed(self):
        return 300.0

    def damage(self, hits, ball, plank_number):
        return 1 + (hits // 8) ** 2

    def on_bounce(self, ball, hits, plank_number):
        pass
