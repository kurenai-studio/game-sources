"""The ball gains speed after every bounce."""

import sys


class Behavior:
    name = "Ускоряющийся"
    description = "Скорость +1%; урон растёт вместе со скоростью"
    color = (86, 213, 255)

    def initial_speed(self):
        return 300.0

    def damage(self, hits, ball, plank_number):
        return 1 + ball.speed / 10_000

    def on_bounce(self, ball, hits, plank_number):
        # Saturate only at Python's largest finite float to avoid inf/NaN physics.
        if ball.speed >= sys.float_info.max / 1.01:
            ball.speed = sys.float_info.max
        else:
            ball.speed *= 1.01
