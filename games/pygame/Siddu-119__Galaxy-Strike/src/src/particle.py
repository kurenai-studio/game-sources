"""Lightweight particles and screen-space starfield."""

import math
import random

import pygame


class Particle:
    def __init__(self, x, y, color, velocity=None, life=0.55, radius=3):
        angle = random.random() * math.tau
        speed = random.uniform(35, 220)
        self.pos = pygame.Vector2(x, y)
        self.previous_pos = self.pos.copy()
        self.vel = pygame.Vector2(velocity) if velocity else pygame.Vector2(
            math.cos(angle) * speed, math.sin(angle) * speed
        )
        self.color = color
        self.life = life
        self.max_life = life
        self.radius = radius

    def update(self, dt):
        self.life -= dt
        self.previous_pos.update(self.pos)
        self.pos += self.vel * dt
        self.vel *= max(0.0, 1.0 - dt * 1.7)
        return self.life > 0

    def draw(self, surface):
        ratio = max(0.0, self.life / self.max_life)
        radius = max(1, int(self.radius * ratio))
        position = (round(self.pos.x), round(self.pos.y))
        previous = (round(self.previous_pos.x), round(self.previous_pos.y))
        glow = tuple(channel // 3 for channel in self.color)
        if position != previous and radius > 1:
            pygame.draw.line(surface, glow, previous, position, max(1, radius))
        pygame.draw.circle(surface, glow, position, radius + 2)
        pygame.draw.circle(surface, self.color, position, radius)
        if radius > 1:
            pygame.draw.circle(surface, (245, 249, 255), position, max(1, radius // 3))


class Starfield:
    def __init__(self, width, height, count=150):
        self.width = width
        self.height = height
        self.stars = [
            [random.uniform(0, width), random.uniform(0, height),
             random.uniform(15, 95), random.uniform(0.7, 2.2)]
            for _ in range(count)
        ]
        self.time = 0.0

    def resize(self, width, height):
        self.width, self.height = width, height

    def update(self, dt, speed_scale=1.0):
        self.time += dt
        for star in self.stars:
            star[1] += star[2] * dt * speed_scale
            if star[1] > self.height:
                star[1] = -2
                star[0] = random.uniform(0, self.width)

    def draw(self, surface):
        for index, (x, y, _, size) in enumerate(self.stars):
            pulse = 0.68 + 0.32 * math.sin(self.time * 2.3 + index)
            color = (int(75 * pulse), int(115 * pulse), int(178 * pulse))
            pygame.draw.circle(surface, color, (int(x), int(y)), max(1, int(size)))


def burst(particles, x, y, color, count=16, speed=1.0):
    for _ in range(count):
        particle = Particle(x, y, color, life=random.uniform(0.25, 0.8),
                            radius=random.randint(2, 5))
        particle.vel *= speed
        particles.append(particle)
