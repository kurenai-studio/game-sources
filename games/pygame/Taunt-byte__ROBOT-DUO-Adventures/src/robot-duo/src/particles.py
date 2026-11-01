"""Particle effects (sparkles, dust, confetti, explosions) and ambient floating motes."""
import math
import random
import pygame


class Particle:
    __slots__ = ("x", "y", "vx", "vy", "life", "max_life", "color", "size", "gravity", "drag", "shape", "rot", "spin")

    def __init__(self, x, y, vx, vy, life, color, size, gravity=0.0, drag=0.0, shape="circle"):
        self.x, self.y, self.vx, self.vy = x, y, vx, vy
        self.life = self.max_life = life
        self.color, self.size, self.gravity, self.drag, self.shape = color, size, gravity, drag, shape
        self.rot = random.uniform(0, 6.28)
        self.spin = random.uniform(-8, 8)


class ParticleSystem:
    MAX = 700

    def __init__(self):
        self.items = []
        self.rng = random.Random(3)

    def _add(self, p):
        if len(self.items) < self.MAX:
            self.items.append(p)

    def burst(self, x, y, color, count=14, speed=180, size=4, life=0.6, gravity=400, shape="circle"):
        for _ in range(count):
            a = self.rng.uniform(0, 2 * math.pi)
            v = self.rng.uniform(0.3, 1.0) * speed
            self._add(Particle(x, y, math.cos(a) * v, math.sin(a) * v, life * self.rng.uniform(0.6, 1.0),
                               color, size * self.rng.uniform(0.6, 1.2), gravity, 1.5, shape))

    def sparkle(self, x, y, color=(255, 230, 90)):
        self.burst(x, y, color, 10, 150, 5, 0.55, 80, "star")
        self.burst(x, y, (255, 255, 255), 5, 90, 3, 0.4, 0, "circle")

    def dust(self, x, y, count=6):
        for _ in range(count):
            d = self.rng.choice((-1, 1))
            self._add(Particle(x + self.rng.uniform(-8, 8), y, d * self.rng.uniform(20, 90),
                               -self.rng.uniform(10, 50), 0.4, (200, 210, 225), self.rng.uniform(2, 4.5),
                               -40, 3.0))

    def explosion(self, x, y, color):
        self.burst(x, y, color, 26, 320, 6, 0.9, 700, "square")
        self.burst(x, y, (255, 240, 180), 12, 260, 4, 0.5, 200, "star")
        self.burst(x, y, (90, 96, 110), 10, 220, 5, 1.0, 900, "square")

    def confetti(self, x, y, count=40):
        cols = [(255, 214, 58), (255, 90, 90), (80, 200, 255), (110, 255, 160), (255, 140, 240)]
        for _ in range(count):
            self._add(Particle(x + self.rng.uniform(-60, 60), y, self.rng.uniform(-160, 160),
                               -self.rng.uniform(260, 520), 1.8, self.rng.choice(cols), 5, 600, 0.6, "square"))

    def ember(self, x, y, color=(255, 150, 40)):
        self._add(Particle(x, y, self.rng.uniform(-15, 15), -self.rng.uniform(40, 110), self.rng.uniform(0.5, 1.1),
                           color, self.rng.uniform(1.5, 3.2), -20, 0.5))

    def bubble(self, x, y):
        self._add(Particle(x, y, self.rng.uniform(-10, 10), -self.rng.uniform(30, 70), 0.8,
                           (190, 230, 255), self.rng.uniform(1.5, 3), -10, 0.3))

    def update(self, dt):
        alive = []
        for p in self.items:
            p.life -= dt
            if p.life <= 0:
                continue
            p.vy += p.gravity * dt
            k = max(0.0, 1.0 - p.drag * dt)
            p.vx *= k
            p.x += p.vx * dt
            p.y += p.vy * dt
            p.rot += p.spin * dt
            alive.append(p)
        self.items = alive

    def draw(self, screen, ox, oy):
        for p in self.items:
            f = p.life / p.max_life
            r = max(1.0, p.size * (0.4 + 0.6 * f))
            x, y = p.x - ox, p.y - oy
            if p.shape == "circle":
                pygame.draw.circle(screen, p.color, (int(x), int(y)), int(r))
            elif p.shape == "star":
                pts = []
                for i in range(8):
                    rad = r * 1.6 if i % 2 == 0 else r * 0.5
                    a = p.rot + i * math.pi / 4
                    pts.append((x + math.cos(a) * rad, y + math.sin(a) * rad))
                pygame.draw.polygon(screen, p.color, pts)
            else:
                c, s = math.cos(p.rot) * r, math.sin(p.rot) * r
                pygame.draw.polygon(screen, p.color, [(x - c - s, y - s + c), (x + c - s, y + s + c),
                                                      (x + c + s, y + s - c), (x - c + s, y - s - c)])


class AmbientFX:
    """Slow floating motes (dust, embers, spores) in screen space with parallax."""
    THEME_COLORS = {"factory": (255, 190, 90), "abandoned": (210, 190, 160), "lab": (140, 240, 255),
                    "cave": (200, 150, 255), "core": (255, 120, 60), "space": (200, 220, 255)}

    def __init__(self, theme, view_w, view_h, count=40, seed=5):
        rng = random.Random(seed)
        self.w, self.h = view_w, view_h
        self.color = self.THEME_COLORS.get(theme, (255, 255, 255))
        self.motes = [[rng.uniform(0, view_w), rng.uniform(0, view_h), rng.uniform(6, 22),
                       rng.uniform(0, 6.28), rng.uniform(1, 2.6)] for _ in range(count)]
        self.t = 0.0

    def update(self, dt):
        self.t += dt
        for m in self.motes:
            m[1] -= m[2] * dt
            if m[1] < -4:
                m[1] = self.h + 4

    def draw(self, screen, cam_x):
        for x, y, sp, ph, size in self.motes:
            px = (x - cam_x * 0.35 + math.sin(self.t + ph) * 12) % self.w
            a = 0.5 + 0.5 * math.sin(self.t * 2 + ph)
            col = tuple(int(c * (0.35 + 0.65 * a)) for c in self.color)
            pygame.draw.circle(screen, col, (int(px), int(y)), int(size))
