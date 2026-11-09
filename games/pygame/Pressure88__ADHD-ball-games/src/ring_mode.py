"""Realtime concentric rotating-ring game mode."""

from __future__ import annotations

import math
import sys
from dataclasses import dataclass, field

import pygame


BALL_RADIUS = 13
GAP_HALF_ANGLE = 0.36
MAX_EVENTS_PER_FRAME = 1_000
MAX_SWEEPS_PER_FRAME = 2_000
GRAVITY = 520.0
RING_SHRINK_SPEED = 20.0
RING_ANGULAR_SPEED = 0.55
BACKGROUND = (12, 15, 29)
RING_COLORS = (
    (94, 189, 255), (120, 151, 255), (162, 128, 250), (218, 117, 220),
    (255, 116, 160), (255, 152, 111), (250, 197, 93), (110, 226, 176),
)
RING_BALL_COLOR = (255, 194, 86)


@dataclass(frozen=True)
class RingBehavior:
    name: str = "Аркадный мяч"
    color: tuple[int, int, int] = RING_BALL_COLOR
    start_speed: float = 300.0


@dataclass
class Ring:
    radius: float
    gap_angle: float
    angular_speed: float
    color: tuple[int, int, int]
    alive: bool = True


@dataclass
class RingBall:
    x: float
    y: float
    vx: float
    vy: float
    speed: float
    hits: int = 0
    trail: list[tuple[float, float]] = field(default_factory=list)
    pending_time: float = 0.0


@dataclass
class RingGame:
    center_x: float
    center_y: float
    rings: list[Ring]
    ball: RingBall
    active_index: int = 0
    won: bool = False
    cleared: int = 0
    spacing: float = 0.0
    next_ring_id: int = 0


def make_ring_game(field_rect: pygame.Rect, speed: float = 300.0) -> RingGame:
    if not math.isfinite(speed):
        speed = sys.float_info.max if speed > 0 else 0.0
    speed = max(1.0, speed)
    cx, cy = float(field_rect.centerx), float(field_rect.centery)
    count = 8
    inner_radius = 48.0
    spacing = 64.0
    rings = [_make_ring(inner_radius + i * spacing, i) for i in range(count)]
    angle = -0.71
    ball = RingBall(cx, cy, speed * math.cos(angle), speed * math.sin(angle), speed)
    return RingGame(cx, cy, rings, ball, spacing=spacing, next_ring_id=count)


def _make_ring(radius: float, ring_id: int) -> Ring:
    return Ring(radius, (0.53 + ring_id * 1.71) % math.tau,
                RING_ANGULAR_SPEED,
                RING_COLORS[ring_id % len(RING_COLORS)])


def _replenish_rings(game: RingGame) -> None:
    # Keep a stream of rings ahead of the ball. Future rings start beyond the
    # visible edge of the fixed camera.
    while len(game.rings) < 8:
        radius = game.rings[-1].radius + game.spacing if game.rings else 48.0
        game.rings.append(_make_ring(radius, game.next_ring_id))
        game.next_ring_id += 1


def _advance(game: RingGame, duration: float) -> None:
    ball = game.ball
    ball.x += ball.vx * duration
    ball.y += ball.vy * duration + 0.5 * GRAVITY * duration * duration
    ball.vy += GRAVITY * duration
    ball.speed = math.hypot(ball.vx, ball.vy)
    for ring in game.rings:
        if ring.alive:
            ring.gap_angle = (ring.gap_angle + ring.angular_speed * duration) % math.tau
            ring.radius = max(BALL_RADIUS + 1, ring.radius - RING_SHRINK_SPEED * duration)


def _clearance(game: RingGame, ring: Ring, duration: float) -> float:
    ball = game.ball
    x = ball.x + ball.vx * duration - game.center_x
    y = (ball.y + ball.vy * duration + 0.5 * GRAVITY * duration * duration
         - game.center_y)
    radius = max(BALL_RADIUS + 1, ring.radius - RING_SHRINK_SPEED * duration)
    return math.hypot(x, y) - (radius - BALL_RADIUS)


def _time_to_ring_contact(game: RingGame, ring: Ring, limit: float) -> float | None:
    speed = max(1.0, math.hypot(game.ball.vx, game.ball.vy))
    clearance = _clearance(game, ring, 0.0)
    if clearance >= 0:
        return 0.0

    elapsed = 0.0
    while elapsed < limit:
        step = min(limit - elapsed, 1 / 120, 3.0 / speed)
        next_time = elapsed + step
        if _clearance(game, ring, next_time) >= 0:
            low, high = elapsed, next_time
            for _ in range(24):
                middle = (low + high) * 0.5
                if _clearance(game, ring, middle) >= 0:
                    high = middle
                else:
                    low = middle
            return high
        elapsed = next_time
    return None


def _normalize_ball_speed(ball: RingBall) -> None:
    magnitude = math.hypot(ball.vx, ball.vy)
    if math.isfinite(magnitude):
        ball.speed = magnitude
    else:
        ball.speed = sys.float_info.max


def update_ring_game(game: RingGame, behavior, dt: float) -> bool:
    """Advance the endless ring stream; excess work carries to later frames."""
    ball = game.ball
    remaining = dt + ball.pending_time
    ball.pending_time = 0.0
    events = 0
    sweeps = 0
    _replenish_rings(game)

    while remaining > 0:
        _replenish_rings(game)
        ring = game.rings[0]
        event_time = _time_to_ring_contact(game, ring, remaining)
        sweeps += 1
        if event_time is None:
            _advance(game, remaining)
            remaining = 0.0
            break

        _advance(game, event_time)
        remaining = max(0.0, remaining - event_time)
        events += 1
        dx, dy = ball.x - game.center_x, ball.y - game.center_y
        distance_from_center = math.hypot(dx, dy) or 1.0
        nx, ny = dx / distance_from_center, dy / distance_from_center
        ball_angle = math.atan2(dy, dx)
        angle_delta = (ball_angle - ring.gap_angle + math.pi) % math.tau - math.pi

        opening = GAP_HALF_ANGLE
        if abs(angle_delta) <= opening:
            ring.alive = False
            game.rings.pop(0)
            game.cleared += 1
            ball.hits += 1
            _normalize_ball_speed(ball)
        else:
            dot = ball.vx * nx + ball.vy * ny
            ball.vx -= 2 * dot * nx
            ball.vy -= 2 * dot * ny
            # A small angular deflection makes successive impacts sample new angles.
            turn = 0.018 if ball.hits % 2 == 0 else -0.018
            cos_turn, sin_turn = math.cos(turn), math.sin(turn)
            vx = ball.vx * cos_turn - ball.vy * sin_turn
            vy = ball.vx * sin_turn + ball.vy * cos_turn
            ball.vx, ball.vy = vx, vy
            # Keep the ball just inside the ring after impact so floating point
            # rounding cannot produce a second zero-distance collision.
            ball.x -= nx * 0.1
            ball.y -= ny * 0.1
            ball.hits += 1
            _normalize_ball_speed(ball)

        if events >= MAX_EVENTS_PER_FRAME or sweeps >= MAX_SWEEPS_PER_FRAME:
            ball.pending_time = remaining
            break

    ball.trail.append((ball.x, ball.y))
    if len(ball.trail) > 16:
        ball.trail.pop(0)
    return False


def _draw_text(surface, text, font, color, position):
    image = font.render(str(text), True, color)
    surface.blit(image, image.get_rect(center=position))


def _short_number(value: float) -> str:
    suffixes = ("", " тыс.", " млн.", " млрд.", " трлн.", " квадрлн.")
    number = float(value)
    index = 0
    while abs(number) >= 1000 and index < len(suffixes) - 1:
        number /= 1000
        index += 1
    if index == len(suffixes) - 1 and abs(number) >= 1000:
        return f"{float(value):.2e}".replace(".", ",")
    if index == 0:
        return str(int(number))
    return f"{number:.1f}".rstrip("0").rstrip(".").replace(".", ",") + suffixes[index]


def draw_ring_game(surface, fonts, game: RingGame, behavior, elapsed: float,
                   ended: bool, menu_rect: pygame.Rect, restart_rect: pygame.Rect):
    title_font, medium_font, small_font = fonts
    surface.fill(BACKGROUND)
    _draw_text(surface, "КОЛЬЦА", title_font, (239, 242, 255), (surface.get_width() // 2, 38))
    menu_button = pygame.Rect(menu_rect)
    pygame.draw.rect(surface, (29, 36, 58), menu_button, border_radius=9)
    pygame.draw.rect(surface, (67, 81, 116), menu_button, width=1, border_radius=9)
    _draw_text(surface, "МЕНЮ", small_font, (201, 211, 234), menu_button.center)

    cx, cy = round(game.center_x), round(game.center_y)
    gap_half = GAP_HALF_ANGLE
    for index, ring in enumerate(game.rings):
        if not ring.alive:
            continue
        bounds = pygame.Rect(round(cx - ring.radius), round(cy - ring.radius),
                             round(ring.radius * 2), round(ring.radius * 2))
        # Generate the arc points with the same screen-coordinate angle math as
        # collision detection, avoiding pygame.draw.arc's angle convention.
        start = ring.gap_angle + gap_half
        sweep = math.tau - 2 * gap_half
        segments = max(48, round(sweep * ring.radius / 3))
        points = [(round(cx + ring.radius * math.cos(start + sweep * i / segments)),
                   round(cy + ring.radius * math.sin(start + sweep * i / segments)))
                  for i in range(segments + 1)]
        pygame.draw.lines(surface, ring.color, False, points, 4)
        pygame.draw.circle(surface, (45, 52, 76), (cx, cy), 3 + index // 3)

    for index, (tx, ty) in enumerate(game.ball.trail):
        radius = 3 + round(5 * (index + 1) / max(1, len(game.ball.trail)))
        pygame.draw.circle(surface, behavior.color, (round(tx), round(ty)), radius)
    bx, by = round(game.ball.x), round(game.ball.y)
    pygame.draw.circle(surface, (255, 255, 255), (bx, by), BALL_RADIUS + 3)
    pygame.draw.circle(surface, behavior.color, (bx, by), BALL_RADIUS)
    pygame.draw.circle(surface, (255, 255, 255), (bx - 4, by - 5), 4)

    _draw_text(surface, f"ПРОЙДЕНО КОЛЕЦ: {game.cleared}",
               small_font, (190, 204, 232), (surface.get_width() // 2, 78))
    _draw_text(surface,
               f"СКОРОСТЬ { _short_number(game.ball.speed) } px/s    ·    ОТСКОКИ {game.ball.hits}",
               small_font, (208, 216, 237), (surface.get_width() // 2, 920))
