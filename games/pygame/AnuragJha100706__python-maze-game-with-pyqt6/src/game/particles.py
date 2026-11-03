"""
Particle Simulation Engine.
Provides particle effects for character motion, wall demolition,
key collections, and victory fireworks without impacting frame rates.
"""

import random
import pygame
from typing import List, Tuple

Color = Tuple[int, int, int]

class Particle:
    """Represents an individual animated particle."""
    def __init__(self, x: float, y: float, vx: float, vy: float, color: Color, life: int, radius: float = 2.5):
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.color = color
        self.life = life
        self.max_life = life
        self.radius = radius

    def update(self) -> bool:
        """Updates particle position and decay. Returns False when dead."""
        self.x += self.vx
        self.y += self.vy
        self.vx *= 0.94
        self.vy *= 0.94
        self.life -= 1
        return self.life > 0

    def draw(self, surface: pygame.Surface):
        if self.life > 0:
            alpha_ratio = self.life / self.max_life
            cur_radius = max(1.0, self.radius * alpha_ratio)
            pygame.draw.circle(surface, self.color, (int(self.x), int(self.y)), int(cur_radius))


class ParticleSystem:
    """Manages active particles, burst emissions, and updates."""
    def __init__(self):
        self.particles: List[Particle] = []

    def emit_dust(self, x: float, y: float, color: Color = (0, 240, 255)):
        """Emits subtle motion dust particles behind moving entities."""
        for _ in range(2):
            vx = random.uniform(-0.5, 0.5)
            vy = random.uniform(-0.5, 0.5)
            self.particles.append(Particle(x, y, vx, vy, color, life=15, radius=2.0))

    def emit_explosion(self, x: float, y: float, count: int = 30, color: Color = (255, 149, 0)):
        """Emits blast particles for wall demolitions."""
        for _ in range(count):
            angle = random.uniform(0, 6.28)
            speed = random.uniform(1.0, 4.5)
            vx = speed * random.uniform(-1, 1)
            vy = speed * random.uniform(-1, 1)
            c = random.choice([color, (255, 204, 0), (239, 71, 111)])
            self.particles.append(Particle(x, y, vx, vy, c, life=random.randint(20, 40), radius=3.5))

    def emit_key_sparkle(self, x: float, y: float, count: int = 20):
        """Emits golden sparkles when collecting an unlock key."""
        for _ in range(count):
            vx = random.uniform(-2.0, 2.0)
            vy = random.uniform(-2.0, 2.0)
            self.particles.append(Particle(x, y, vx, vy, (255, 215, 0), life=25, radius=2.5))

    def emit_victory(self, width: int, height: int, count: int = 50):
        """Emits celebratory victory fireworks."""
        cx, cy = width // 2, height // 2
        palette = [(0, 240, 255), (6, 214, 160), (255, 183, 3), (123, 44, 191)]
        for _ in range(count):
            vx = random.uniform(-5.0, 5.0)
            vy = random.uniform(-5.0, 5.0)
            c = random.choice(palette)
            self.particles.append(Particle(cx, cy, vx, vy, c, life=random.randint(30, 60), radius=4.0))

    def update_and_draw(self, surface: pygame.Surface):
        """Updates all particles and renders them onto the target surface."""
        surviving = []
        for p in self.particles:
            if p.update():
                p.draw(surface)
                surviving.append(p)
        self.particles = surviving

    def clear(self):
        self.particles.clear()
