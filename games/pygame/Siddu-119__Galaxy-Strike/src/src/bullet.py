"""Player and enemy projectiles."""

import math

import pygame


class Bullet:
    def __init__(self, x, y, vx=0, vy=-650, damage=1, color=(70, 235, 255),
                 radius=5, friendly=True, beam=False, explosive=False, missile=False,
                 laser=False):
        self.pos = pygame.Vector2(x, y)
        self.vel = pygame.Vector2(vx, vy)
        self.damage = damage
        self.color = color
        self.radius = radius
        self.friendly = friendly
        self.beam = beam
        self.explosive = explosive
        self.missile = missile
        self.laser = laser
        self.alive = True
        self.age = 0.0

    def update(self, dt, bounds):
        self.age += dt
        self.pos += self.vel * dt
        margin = self.radius + 12
        if (self.pos.y < -margin or self.pos.y > bounds[1] + margin or
                self.pos.x < -margin or self.pos.x > bounds[0] + margin):
            self.alive = False

    def draw(self, surface):
        x, y = int(self.pos.x), int(self.pos.y)
        if self.beam:
            end_y = max(-12, y - 150)
            pygame.draw.line(surface, (28, 73, 123), (x, y), (x, end_y), 28)
            pygame.draw.line(surface, (35, 136, 196), (x, y), (x, end_y), 20)
            pygame.draw.line(surface, self.color, (x, y), (x, end_y), 10)
            pygame.draw.line(surface, (245, 255, 255), (x, y), (x, end_y), 3)
        elif self.laser:
            tail = (int(x - self.vel.x * 0.045), int(y - self.vel.y * 0.045))
            pygame.draw.line(surface, (32, 75, 141), tail, (x, y), self.radius * 6)
            pygame.draw.line(surface, (55, 142, 255), tail, (x, y), self.radius * 4)
            pygame.draw.line(surface, self.color, tail, (x, y), self.radius * 2)
            pygame.draw.circle(surface, (238, 255, 255), (x, y), self.radius)
        elif self.missile:
            direction = self.vel.normalize() if self.vel.length_squared() else pygame.Vector2(0, -1)
            perpendicular = pygame.Vector2(-direction.y, direction.x)
            center = pygame.Vector2(x, y)
            nose = center + direction * 11
            tail = center - direction * 8
            left = tail + perpendicular * 6
            right = tail - perpendicular * 6
            points = [tuple(round(value) for value in point) for point in
                      (nose, left, center - direction * 2, right)]
            flame_start = center - direction * 7
            flame_end = center - direction * 15
            pygame.draw.polygon(surface, self.color, points)
            pygame.draw.line(
                surface, (255, 230, 160),
                tuple(round(value) for value in flame_start),
                tuple(round(value) for value in flame_end), 3,
            )
        else:
            tail = (int(x - self.vel.x * 0.018), int(y - self.vel.y * 0.018))
            pygame.draw.circle(surface, (23, 74, 113), (x, y), self.radius + 4)
            pygame.draw.line(surface, (35, 136, 196), tail, (x, y), self.radius * 3)
            pygame.draw.line(surface, self.color, tail, (x, y), self.radius * 2)
            pygame.draw.circle(surface, (115, 245, 255), (x, y), self.radius)
            pygame.draw.circle(surface, (245, 255, 255), (x, y), max(2, self.radius // 2))
            if self.explosive:
                pygame.draw.circle(surface, (255, 195, 91), (x, y), self.radius + 3, 1)


def aimed_bullet(x, y, target, speed=260, color=(255, 106, 154), damage=1):
    direction = pygame.Vector2(target) - pygame.Vector2(x, y)
    if direction.length_squared() == 0:
        direction = pygame.Vector2(0, 1)
    direction = direction.normalize() * speed
    return Bullet(x, y, direction.x, direction.y, damage, color, 6, False)
