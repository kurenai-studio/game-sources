"""The player: a circle that walks in a straight line to where you click."""

import math

import pygame
from pygame.math import Vector2

from app import config
from app.render.shapes import draw_alpha_circle, draw_glow
from app.theme.accessibility import wobble
from app.theme.palette import PALETTE
from app.util.mathx import Color, clamp


class SpeedBuff:
    """A temporary speed multiplier (e.g. Sprint)."""

    def __init__(self, multiplier: float, duration: float) -> None:
        self.multiplier = multiplier
        self.duration = duration
        self.remaining = duration


class Player:
    """Moves toward ``destination`` at its current speed and stops exactly there.

    Ability states live here too: a shield bubble (blocks one hit), a dash
    (a fast, fixed-distance move that overrides walking until it ends) and
    named speed buffs that multiply the walking speed.
    """

    def __init__(self, pos, speed: float = config.PLAYER_SPEED) -> None:
        self.pos = Vector2(pos)
        self.destination = Vector2(pos)
        self.facing = Vector2(1, 0)            # last movement direction
        self.radius = config.PLAYER_RADIUS
        self.base_speed = speed                 # walking speed before buffs (Swift Boots raises it)
        self.speed_buffs: dict[str, SpeedBuff] = {}
        self.shield_remaining = 0.0
        self.shield_duration = 0.0
        self.dash_target: Vector2 | None = None
        self.dash_speed = 0.0
        self.stasis_remaining = 0.0             # frozen and untouchable (Stasis power-up)
        self.invulnerable_remaining = 0.0       # untouchable but free to move (after Second Wind)
        self.trail: list[tuple[Vector2, Color]] = []    # recent positions while moving fast
        self.age = 0.0                                  # s alive; drives small animations

    # --- Speed --------------------------------------------------------------------------
    @property
    def speed(self) -> float:
        speed = self.base_speed
        for buff in self.speed_buffs.values():
            speed *= buff.multiplier
        return speed

    def add_speed_buff(self, name: str, multiplier: float, duration: float) -> None:
        """Add or refresh a buff. Reusing a name replaces it instead of stacking."""
        self.speed_buffs[name] = SpeedBuff(multiplier, duration)

    @property
    def sprinting(self) -> bool:
        return "sprint" in self.speed_buffs

    # --- Shield -------------------------------------------------------------------------
    def add_shield(self, duration: float) -> None:
        self.shield_remaining = duration
        self.shield_duration = duration

    @property
    def shielded(self) -> bool:
        return self.shield_remaining > 0

    def consume_shield(self) -> bool:
        """Break the shield to block a hit. Returns False if there was none."""
        if not self.shielded:
            return False
        self.shield_remaining = 0.0
        return True

    @property
    def hit_radius(self) -> float:
        """While shielded, the bubble is the hitbox."""
        return config.SHIELD_RADIUS if self.shielded else self.radius

    # --- Stasis and invulnerability ------------------------------------------------------------
    def enter_stasis(self, duration: float) -> None:
        """Freeze in place. A dash is cancelled; a move order given now runs after it ends."""
        self.stasis_remaining = duration
        self.dash_target = None
        self.destination = Vector2(self.pos)

    @property
    def in_stasis(self) -> bool:
        return self.stasis_remaining > 0

    @property
    def invulnerable(self) -> bool:
        """Nothing can hit the player: bolts and lasers pass straight through."""
        return self.in_stasis or self.invulnerable_remaining > 0

    # --- Movement -----------------------------------------------------------------------
    def clamp_to_arena(self, point) -> Vector2:
        """Keep a point inside the window so the whole circle stays visible."""
        return Vector2(clamp(point[0], self.radius, config.SCREEN_WIDTH - self.radius),
                       clamp(point[1], self.radius, config.SCREEN_HEIGHT - self.radius))

    def move_to(self, point) -> None:
        """Set a new walk destination (resumed after a dash if given mid-dash)."""
        self.destination = self.clamp_to_arena(point)

    def start_dash(self, target, speed: float) -> None:
        self.dash_target = self.clamp_to_arena(target)
        self.dash_speed = speed
        self.destination = Vector2(self.dash_target)    # stop where the dash ends

    @property
    def dashing(self) -> bool:
        return self.dash_target is not None

    def teleport(self, point) -> None:
        """Jump instantly. Cancels a dash and stops at the landing spot."""
        self.pos = self.clamp_to_arena(point)
        self.destination = Vector2(self.pos)
        self.dash_target = None
        self.trail.clear()

    def update(self, dt: float) -> None:
        self.age += dt
        self.shield_remaining = max(0.0, self.shield_remaining - dt)
        for name, buff in list(self.speed_buffs.items()):
            buff.remaining -= dt
            if buff.remaining <= 0:
                del self.speed_buffs[name]
        self.invulnerable_remaining = max(0.0, self.invulnerable_remaining - dt)
        if self.in_stasis:
            self.stasis_remaining = max(0.0, self.stasis_remaining - dt)
            if self.trail:
                self.trail.pop(0)
            return                                    # frozen: no movement this frame

        if self.dashing:
            arrived = self._step_toward(self.dash_target, self.dash_speed * dt)
            if arrived:
                self.dash_target = None
        else:
            self._step_toward(self.destination, self.speed * dt)

        # The trail grows while moving fast and shrinks away afterwards.
        if self.dashing or self.sprinting:
            self.trail.append((Vector2(self.pos), PALETTE.dash if self.dashing else PALETTE.sprint))
            if len(self.trail) > config.SPEED_TRAIL_LENGTH:
                self.trail.pop(0)
        elif self.trail:
            self.trail.pop(0)

    def _step_toward(self, target: Vector2, step: float) -> bool:
        """Move up to ``step`` px toward ``target``. Returns True on arrival."""
        to_target = target - self.pos
        distance = to_target.length()
        if distance > 0:
            self.facing = to_target / distance
        if distance <= step:
            self.pos = Vector2(target)                # arrive exactly, no overshoot
            return True
        self.pos += to_target * (step / distance)
        return False

    # --- Drawing ------------------------------------------------------------------------
    def draw(self, surface: pygame.Surface, show_path: bool = False) -> None:
        if show_path and not self.dashing and not self.in_stasis:
            self._draw_path(surface)
        count = len(self.trail)
        for i, (point, color) in enumerate(self.trail):
            k = (i + 1) / count                       # older = smaller and fainter
            draw_alpha_circle(surface, color, point, self.radius * (0.4 + 0.6 * k), 80 * k)
        if self.sprinting:
            r = self.radius + 7 + wobble(math.sin(self.age * 18) * 2.5)
            draw_alpha_circle(surface, PALETTE.sprint, self.pos, r, 50)
            draw_alpha_circle(surface, PALETTE.sprint, self.pos, r, 220, width=2)
        body, light, outline = PALETTE.player, PALETTE.player_light, PALETTE.player_outline
        if self.in_stasis:
            # A golden statue.
            body, light, outline = PALETTE.stasis, PALETTE.coin_shine, PALETTE.coin_shine
            draw_glow(surface, PALETTE.stasis, self.pos, self.radius * 3.4, 200)
        elif self.invulnerable_remaining > 0:
            # Saved by Second Wind: a pulsing golden ring while untouchable.
            outline = PALETTE.second_wind
            r = self.radius + 8 + wobble(math.sin(self.age * 14) * 2)
            draw_alpha_circle(surface, PALETTE.second_wind, self.pos, r, 210, width=2)
        draw_glow(surface, body, self.pos, self.radius * 3, 110)
        pygame.draw.circle(surface, body, self.pos, self.radius)
        highlight = self.pos - Vector2(self.radius, self.radius) * 0.3
        pygame.draw.circle(surface, light, highlight, self.radius * 0.45)
        pygame.draw.circle(surface, outline, self.pos, self.radius, 2)
        # A small notch showing which way the player last moved.
        side = Vector2(-self.facing.y, self.facing.x)
        base = self.pos + self.facing * (self.radius + 1)
        tip = self.pos + self.facing * (self.radius + 7)
        pygame.draw.polygon(surface, outline, [tip, base + side * 5, base - side * 5])
        if self.shielded:
            self._draw_shield(surface)

    def _draw_path(self, surface: pygame.Surface) -> None:
        """Faint dots from the player to where they are walking."""
        to_target = self.destination - self.pos
        distance = to_target.length()
        if distance < config.PATH_DOT_SPACING:
            return
        step = to_target / distance * config.PATH_DOT_SPACING
        for i in range(1, int(distance // config.PATH_DOT_SPACING) + 1):
            draw_alpha_circle(surface, PALETTE.marker, self.pos + step * i, 2, 110)

    def _draw_shield(self, surface: pygame.Surface) -> None:
        r = config.SHIELD_RADIUS
        draw_alpha_circle(surface, PALETTE.shield, self.pos, r, 50)
        draw_alpha_circle(surface, PALETTE.shield, self.pos, r, 230, width=2)
        # An arc around the bubble shows how long it has left (clockwise from the top).
        left = self.shield_remaining / self.shield_duration
        box = pygame.Rect(0, 0, (r + 6) * 2, (r + 6) * 2)
        box.center = (int(self.pos.x), int(self.pos.y))
        start = math.pi / 2
        pygame.draw.arc(surface, PALETTE.shield, box, start, start + math.tau * left, 3)
