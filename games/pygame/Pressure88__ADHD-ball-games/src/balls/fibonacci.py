"""Damage follows Fibonacci values, advancing every twelve bounce events."""


class Behavior:
    name = "Фибоначчи"
    description = "Урон по Фибоначчи; шаг каждые 8 отскоков"
    color = (95, 224, 173)
    damage_steps = (
        1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610,
        987, 1597, 2584, 4181, 6765, 10946, 17711, 28657, 46368,
        75025, 121393, 196418, 317811, 514229, 832040,
    )

    def initial_speed(self):
        return 240.0

    def damage(self, hits, ball, plank_number):
        step = min(max(0, (hits - 1) // 8), len(self.damage_steps) - 1)
        return self.damage_steps[step]

    def on_bounce(self, ball, hits, plank_number):
        pass
