"""Draw the explosion animations (assets/images/explosion1.png and explosion2.png).

Each file is a horizontal strip of square frames: the burst grows, its colours cool from
white-hot to orange, and then it fades away. The explosions are generated rather than
downloaded, so they are original artwork covered by this project's licence.
Run from the project folder:

    python tools/make_explosions.py
"""
import math
import os
import random

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
import pygame  # noqa: E402

IMAGE_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "images")

SUPERSAMPLE = 4  # draw larger, then scale down for smooth edges
HOT = ((255, 255, 235), (255, 235, 120), (255, 170, 40), (235, 90, 30))  # core to edge, when new
COOL = ((255, 210, 120), (255, 150, 40), (220, 80, 30), (150, 40, 30))  # core to edge, at the end

# (file name, frame size in pixels, number of frames, random seed)
EXPLOSIONS = [
    ("explosion1.png", 40, 8, 1),  # alien explosion
    ("explosion2.png", 80, 10, 2),  # player explosion
]


def mix(colour_a, colour_b, amount):
    return tuple(round(a + (b - a) * amount) for a, b in zip(colour_a, colour_b))


def starburst(rng, centre, radius, points, spikiness):
    """Corners of a jagged star shape around a centre point."""
    corners = []
    for i in range(points * 2):
        angle = math.pi * i / points + rng.uniform(-0.12, 0.12)
        reach = radius if i % 2 == 0 else radius * (1 - spikiness)
        reach *= rng.uniform(0.85, 1.0)
        corners.append((centre + reach * math.cos(angle), centre + reach * math.sin(angle)))
    return corners


def draw_frame(size, seed, progress):
    """One frame of an explosion. progress goes from 0 (just started) to 1 (finished)."""
    rng = random.Random(seed)  # the same seed every frame keeps the shape steady as it grows
    big = size * SUPERSAMPLE
    centre = big / 2
    full_radius = big / 2 - SUPERSAMPLE
    growth = 0.35 + 0.65 * min(1.0, progress * 2.2)
    radius = full_radius * growth
    core, inner, middle, outer = (mix(hot, cool, progress) for hot, cool in zip(HOT, COOL))
    surface = pygame.Surface((big, big), pygame.SRCALPHA)

    for _ in range(6):  # sparks fly outwards as it grows
        angle = rng.uniform(0, 2 * math.pi)
        distance = full_radius * rng.uniform(0.55, 0.92) * min(1.0, 0.4 + progress * 1.2)
        spark = (centre + distance * math.cos(angle), centre + distance * math.sin(angle))
        pygame.draw.circle(surface, middle, spark, full_radius * rng.uniform(0.04, 0.08))

    pygame.draw.polygon(surface, outer, starburst(rng, centre, radius * 0.85, 9, 0.45))
    pygame.draw.polygon(surface, middle, starburst(rng, centre, radius * 0.62, 8, 0.35))
    pygame.draw.polygon(surface, inner, starburst(rng, centre, radius * 0.4, 7, 0.25))
    if progress < 0.7:  # the white-hot core burns out
        pygame.draw.circle(surface, core, (centre, centre), radius * 0.18 * (1 - progress))

    fade = 1.0 if progress < 0.45 else max(0.0, 1 - (progress - 0.45) / 0.55)
    surface.fill((255, 255, 255, round(255 * fade)), special_flags=pygame.BLEND_RGBA_MULT)
    return pygame.transform.smoothscale(surface, (size, size))


def draw_strip(size, frames, seed):
    """All the frames of one explosion, side by side."""
    strip = pygame.Surface((size * frames, size), pygame.SRCALPHA)
    for i in range(frames):
        strip.blit(draw_frame(size, seed, i / (frames - 1)), (i * size, 0))
    return strip


def main():
    pygame.init()
    for file_name, size, frames, seed in EXPLOSIONS:
        path = os.path.join(IMAGE_DIR, file_name)
        pygame.image.save(draw_strip(size, frames, seed), path)
        print(f"saved {path} ({frames} frames of {size}x{size})")


if __name__ == "__main__":
    main()
