"""Small animation building blocks: easing, tweens, shakes, ripples, particles,
and the screen fade. Purely visual; nothing here touches game state."""
from __future__ import annotations

import math
import random

import pygame


# ---- easing -----------------------------------------------------------------
def ease_out_cubic(t: float) -> float:
    return 1 - (1 - t) ** 3


def ease_out_back(t: float, s: float = 1.70158) -> float:
    t -= 1
    return 1 + (s + 1) * t ** 3 + s * t ** 2


def ease_in_out_sine(t: float) -> float:
    return -(math.cos(math.pi * t) - 1) / 2


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def mix(c1, c2, t: float) -> tuple:
    return tuple(int(lerp(a, b, max(0.0, min(1.0, t)))) for a, b in zip(c1, c2))


# ---- tween --------------------------------------------------------------------
class Tween:
    def __init__(self, duration: float, delay: float = 0.0):
        self.duration = max(duration, 1e-6)
        self.elapsed = -delay

    def update(self, dt: float) -> None:
        self.elapsed += dt

    @property
    def progress(self) -> float:
        return max(0.0, min(1.0, self.elapsed / self.duration))

    @property
    def done(self) -> bool:
        return self.elapsed >= self.duration


class Shake:
    """Decaying horizontal wobble."""

    def __init__(self, duration: float = 0.0, amplitude: float = 8.0, freq: float = 38.0):
        self.tween = Tween(duration)
        self.amplitude, self.freq = amplitude, freq
        if duration == 0:
            self.tween.elapsed = 1

    def update(self, dt: float) -> None:
        self.tween.update(dt)

    @property
    def active(self) -> bool:
        return not self.tween.done

    def offset(self) -> tuple[int, int]:
        if not self.active:
            return (0, 0)
        t = self.tween.progress
        decay = (1 - t) ** 2
        return (int(round(self.amplitude * decay * math.sin(self.tween.elapsed * self.freq))),
                int(round(self.amplitude * 0.3 * decay * math.cos(self.tween.elapsed * self.freq * 0.7))))


class Ripple:
    def __init__(self, pos, colour, duration: float = 0.6, radius: float = 60):
        self.pos, self.colour, self.radius = pos, colour, radius
        self.tween = Tween(duration)

    def update(self, dt: float) -> None:
        self.tween.update(dt)

    @property
    def done(self) -> bool:
        return self.tween.done

    @property
    def current_radius(self) -> float:
        return self.radius * ease_out_cubic(self.tween.progress)

    def draw(self, surf) -> None:
        if self.done:
            return
        t = self.tween.progress
        r = max(2, int(self.current_radius))
        layer = pygame.Surface((r * 2 + 6, r * 2 + 6), pygame.SRCALPHA)
        pygame.draw.circle(layer, (*self.colour, int(220 * (1 - t))), (r + 3, r + 3), r, max(1, int(5 * (1 - t)) + 1))
        surf.blit(layer, (self.pos[0] - r - 3, self.pos[1] - r - 3))


class Particles:
    GRAVITY = 520.0

    def __init__(self, rng: random.Random | None = None):
        self.rng = rng or random.Random()
        self.items: list[list] = []   # x, y, vx, vy, life, max_life, colour, size, spin

    def burst(self, pos, n: int, colours, speed: float = 380.0) -> None:
        for _ in range(n):
            a = self.rng.uniform(-math.pi, 0) if self.rng.random() < 0.8 else self.rng.uniform(0, math.pi)
            v = self.rng.uniform(0.35, 1.0) * speed
            life = self.rng.uniform(0.8, 1.6)
            self.items.append([pos[0], pos[1], math.cos(a) * v, math.sin(a) * v, life, life,
                               self.rng.choice(colours), self.rng.uniform(4, 9), self.rng.uniform(0, 6.28)])

    def update(self, dt: float) -> None:
        for p in self.items:
            p[0] += p[2] * dt
            p[1] += p[3] * dt
            p[3] += self.GRAVITY * dt
            p[2] *= 0.99
            p[4] -= dt
            p[8] += dt * 8
        self.items = [p for p in self.items if p[4] > 0]

    def draw(self, surf) -> None:
        for x, y, _, _, life, max_life, colour, size, spin in self.items:
            w = max(1, int(size * abs(math.cos(spin))))
            rect = pygame.Rect(0, 0, w, int(size))
            rect.center = (int(x), int(y))
            fade = min(1.0, life / (max_life * 0.4))
            pygame.draw.rect(surf, mix((14, 18, 32), colour, fade), rect)


class Effects:
    """A bag of free-floating effects a scene updates and draws on top."""

    def __init__(self):
        self.particles = Particles()
        self.ripples: list[Ripple] = []

    def ripple(self, pos, colour, **kw) -> None:
        self.ripples.append(Ripple(pos, colour, **kw))

    def update(self, dt: float) -> None:
        self.particles.update(dt)
        for r in self.ripples:
            r.update(dt)
        self.ripples = [r for r in self.ripples if not r.done]

    def draw(self, surf) -> None:
        for r in self.ripples:
            r.draw(surf)
        self.particles.draw(surf)


class Fade:
    """Fade-in from the background colour after a scene change. The new scene
    is already live underneath; this is only an overlay."""

    def __init__(self, duration: float = 0.28):
        self.duration = duration
        self.tween = Tween(duration)
        self.tween.elapsed = duration

    def start(self) -> None:
        self.tween = Tween(self.duration)

    def update(self, dt: float) -> None:
        self.tween.update(dt)

    @property
    def alpha(self) -> int:
        return int(255 * (1 - ease_out_cubic(self.tween.progress)))

    def draw(self, surf, colour) -> None:
        if self.alpha <= 0:
            return
        overlay = pygame.Surface(surf.get_size())
        overlay.fill(colour)
        overlay.set_alpha(self.alpha)
        surf.blit(overlay, (0, 0))
