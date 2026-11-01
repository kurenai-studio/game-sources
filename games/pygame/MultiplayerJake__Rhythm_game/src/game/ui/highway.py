"""HighwayView: the 4-lane neon note highway (gameplay + editor).

Cyberpunk rendering language:
* thick capsule notes with a white/pale-cyan core and layered neon glow;
* hold notes as thick vertical energy beams with a glowing end capsule;
* boost (special) notes in neon magenta/violet;
* hit-line bursts, lane flashes and sparkle particles spawned through
  :meth:`hit_effect`.

The geometry (``HW``, ``HIT_Y``, fixed 1.6 s travel) is unchanged so the
gameplay feel stays identical - this module only draws.
"""

from __future__ import annotations

import math
import random

import pygame

from . import theme

TRAVEL_MS = 1600.0            # fixed note travel time (top -> hit line)
HW = pygame.Rect(360, 60, 560, 420)
HIT_Y = HW.y + int(HW.h * 0.80)   # 396
LANE_PAD = 8
LANE_GAP = 5

HOLDING = "holding"           # mirrors game.engine.note.HOLDING

_NOTE_H = 28                  # chunky capsule notes
_RIBBON_W = 0.52              # thick energy beam
_CAPSULE_W = 0.88

_SPARKS_PER_SEC = 34.0
_SPARK_LIFE = (0.4, 0.85)


def _get(note, key, default=None):
    if isinstance(note, dict):
        return note.get(key, default)
    return getattr(note, key, default)


class HighwayView:
    def __init__(self):
        self._sparks = []              # active sparkle particles
        self._hold_acc = [0.0] * 4     # per-lane spawn accumulator
        self._t = 0.0                  # local clock for pulses
        self._flash = [0.0] * 4        # per-lane hit flash (0..1)
        self._flash_color = [theme.CYAN] * 4
        self._fx = pygame.Surface((HW.w, HW.h), pygame.SRCALPHA)

    # ------------------------------------------------------------ geometry
    def lane_rects(self) -> list:
        inner_w = HW.w - 2 * LANE_PAD
        lw = (inner_w - 3 * LANE_GAP) / 4
        return [pygame.Rect(HW.x + LANE_PAD + i * (lw + LANE_GAP),
                            HW.y + 4, lw, HW.h - 8) for i in range(4)]

    @property
    def px_per_ms(self) -> float:
        return (HIT_Y - HW.y) / TRAVEL_MS

    def y_for(self, time_ms: float, song_pos: float) -> float:
        return HIT_Y - (time_ms - song_pos) * self.px_per_ms

    # ---------------------------------------------------------- hit effects
    def hit_effect(self, lane: int, rating: str = "perfect") -> None:
        """Spawn a radial burst, lane flash and sparks for a judgment."""
        if not 0 <= lane < 4:
            return
        color = theme.RATING_COLORS.get(rating, theme.CYAN)
        self._flash[lane] = 1.0
        self._flash_color[lane] = color

        lanes = self.lane_rects()
        lr = lanes[lane]
        cx = lr.centerx
        n = 16 if rating in ("perfect", "great") else 10
        for _ in range(n):
            ang = random.uniform(0, math.tau)
            speed = random.uniform(70, 210)
            self._sparks.append({
                "x": cx + random.uniform(-lr.w * 0.3, lr.w * 0.3),
                "y": HIT_Y + random.uniform(-6, 6),
                "vx": math.cos(ang) * speed,
                "vy": math.sin(ang) * speed * 0.7 - 40,
                "life": 0.0,
                "max": random.uniform(0.25, 0.5),
                "r": random.uniform(2.0, 5.0),
                "color": color,
                "burst": True,
            })
        # expanding radial ring
        self._sparks.append({"x": cx, "y": HIT_Y, "vx": 0.0, "vy": 0.0,
                             "life": 0.0, "max": 0.32, "r": 6.0,
                             "color": color, "ring": lr.w * 0.55})

    # ---------------------------------------------------------------- draw
    def draw(self, surface, song_pos, notes, lane_down=None,
             labels=None, highlight_lane=None, dt=0.0):
        self._t += max(dt, 0.0)
        self._step_fx(dt)

        theme.panel(surface, HW, fill=(13, 9, 30),
                    border=theme.BORDER_BRIGHT, radius=10, width=2,
                    glow=theme.VIOLET)

        lanes = self.lane_rects()
        for i, lr in enumerate(lanes):
            down = bool(lane_down and lane_down[i])
            fill = theme.PANEL_LIGHT if down else theme.PANEL
            theme.alpha_rect(surface, lr, fill, 235 if down else 190,
                             radius=6)
            if down:
                pygame.draw.rect(surface, theme.CYAN, lr, 2, border_radius=6)
            # futuristic lane dividers with periodic bright ticks
            if i:
                x = lr.x - LANE_GAP // 2
                pygame.draw.line(surface, (48, 32, 96),
                                 (x, lr.y), (x, lr.bottom), 1)
                for k in range(6):
                    ty = lr.y + 24 + k * 68 + int(self._t * 18) % 68
                    if ty < lr.bottom - 6:
                        pygame.draw.line(surface, theme.VIOLET,
                                         (x - 2, ty), (x + 2, ty), 2)

        prev = surface.get_clip()
        surface.set_clip(HW.inflate(0, 40))
        self._draw_notes(surface, song_pos, notes, lanes, dt)
        self._draw_hits(surface, lanes)
        surface.set_clip(prev)

        self._draw_hit_line(surface)
        self._draw_receptors(surface, lanes, lane_down)

        if labels:
            for i, text in enumerate(labels):
                if not text:
                    continue
                cx = lanes[i].centerx
                active = bool(lane_down and lane_down[i])
                theme.draw_text(surface, text, cx, HW.bottom + 10, size=48,
                                color=theme.WHITE if active else theme.LAVENDER,
                                align="center",
                                glow=theme.MAGENTA if active else theme.VIOLET)

    # --------------------------------------------------------------- notes
    def _draw_notes(self, surface, song_pos, notes, lanes, dt):
        for note in notes:
            t = _get(note, "time")
            if t is None:
                continue
            lane = int(_get(note, "lane", 0))
            if not 0 <= lane < 4:
                continue
            end = _get(note, "end")
            boost = bool(_get(note, "boost", False))
            status = _get(note, "status")
            holding = status == HOLDING

            y_head = self.y_for(t, song_pos)
            y_tail = self.y_for(end, song_pos) if end is not None else None

            # skip notes that cannot be seen: still far above the highway,
            # or (tap notes) already below it. A sustain is never culled by
            # its head alone - during a hold the head travels far below the
            # highway while the beam and tail stay visible, so checks must
            # use the beam's top end (y_tail) instead (a 10 s hold used to
            # vanish ~0.8 s after the hit while the hold still counted).
            if y_head < HW.y - 60 and (y_tail is None or y_tail < HW.y - 60):
                if t - song_pos > TRAVEL_MS + 400:
                    continue
            if y_tail is None:
                if y_head > HW.bottom + 80:
                    continue
            elif y_tail > HW.bottom + 80:
                # whole sustain has slid past the bottom of the highway
                continue

            lr = lanes[lane]
            cx = lr.centerx
            color = theme.MAGENTA if boost else theme.CYAN

            # "released" = the player let go early: the tail is dropped,
            # so nothing is drawn any more (otherwise a long released
            # sustain would linger on screen until its original end time)
            done = status in ("hit", "missed", "released")
            if y_tail is not None and not done:
                self._draw_beam(surface, lr, y_head, y_tail, color, boost,
                                holding, dt, lane)

            if done:
                continue
            self._draw_capsule(surface, lr, cx, y_head, color, boost, holding)

    def _draw_capsule(self, surface, lr, cx, y_head, color, boost, holding):
        w = lr.w * _CAPSULE_W
        cap = pygame.Rect(cx - w / 2, y_head - _NOTE_H / 2, w, _NOTE_H)
        # layered neon glow: outer magenta/cyan + tight white halo
        theme.glow_rect(surface, cap, color, radius=14, intensity=90)
        body = cap.inflate(-6, -6)
        pygame.draw.rect(surface, theme.lerp(color, theme.BG, 0.25), body,
                         border_radius=10)
        core = cap.inflate(-16, -12)
        if core.w > 4 and core.h > 3:
            pygame.draw.rect(surface, theme.WHITE, core, border_radius=8)
            pygame.draw.rect(surface, theme.lerp(color, theme.WHITE, 0.6),
                             pygame.Rect(core.x, core.y, core.w, 3),
                             border_radius=2)
        pygame.draw.rect(surface, color, cap, 2, border_radius=14)
        if holding:
            pulse = 0.5 + 0.5 * math.sin(self._t * 12.0)
            ring = cap.inflate(int(8 + 10 * pulse), int(4 + 6 * pulse))
            pygame.draw.rect(surface, theme.lerp(color, theme.WHITE, pulse),
                             ring, 2, border_radius=18)

    def _draw_beam(self, surface, lr, y_head, y_tail, color, boost,
                   holding, dt, lane):
        top = min(y_head, y_tail)
        bottom = max(y_head, y_tail)
        rw = lr.w * _RIBBON_W
        beam = pygame.Rect(lr.centerx - rw / 2, top, rw,
                           max(bottom - top, 3))
        # soft outer glow, saturated body, bright energy core
        theme.alpha_rect(surface, beam.inflate(14, 6), color, 70,
                         radius=beam.h // 2)
        theme.alpha_rect(surface, beam, color, 210, radius=int(rw * 0.3))
        core = pygame.Rect(beam.centerx - 3, beam.y + 4, 6,
                           max(beam.h - 8, 2))
        pygame.draw.rect(surface, theme.WHITE, core, border_radius=3)
        # travelling energy pulses down the beam
        if beam.h > 40:
            step = 34
            off = int(self._t * 220) % step
            y = beam.bottom - off
            while y > beam.y + step:
                pygame.draw.rect(surface, theme.lerp(color, theme.WHITE, 0.7),
                                 pygame.Rect(beam.centerx - 6, y, 12, 6),
                                 border_radius=3)
                y -= step
        # glowing end capsule
        end_cap = pygame.Rect(beam.centerx - rw * 0.62, bottom - 8,
                              rw * 1.24, 16)
        theme.glow_rect(surface, end_cap, color, radius=10, intensity=80)
        pygame.draw.rect(surface, theme.WHITE,
                         end_cap.inflate(-10, -6), border_radius=8)
        if holding:
            pulse = 0.5 + 0.5 * math.sin(self._t * 12.0)
            pygame.draw.rect(surface, theme.lerp(color, theme.WHITE, pulse),
                             beam.inflate(4, 0), 2, border_radius=int(rw * 0.3))
            self._spawn_hold_sparks(lane, beam, color, boost, dt)

    # ---------------------------------------------------------- receptors
    def _draw_hit_line(self, surface):
        hl = pygame.Rect(HW.x + 6, HIT_Y - 4, HW.w - 12, 8)
        theme.glow_rect(surface, hl, theme.YELLOW, radius=4, intensity=110)
        # travelling shimmer along the line
        span = HW.w - 40
        x = HW.x + 20 + (math.sin(self._t * 1.6) * 0.5 + 0.5) * span
        shimmer = pygame.Rect(x - 46, HIT_Y - 3, 92, 6)
        theme.alpha_rect(surface, shimmer, theme.WHITE, 150, radius=3)

    def _draw_receptors(self, surface, lanes, lane_down):
        for i, lr in enumerate(lanes):
            rec = pygame.Rect(lr.x + lr.w * (1 - _CAPSULE_W) / 2,
                              HIT_Y - _NOTE_H // 2,
                              lr.w * _CAPSULE_W, _NOTE_H)
            held = bool(lane_down and lane_down[i])
            color = theme.CYAN if held else theme.BORDER
            if held:
                theme.glow_rect(surface, rec, theme.CYAN, radius=14,
                                intensity=100)
                pygame.draw.rect(surface, theme.lerp(theme.CYAN, theme.BG, 0.55),
                                 rec.inflate(-8, -6), border_radius=11)
            pygame.draw.rect(surface, color, rec, 2, border_radius=14)
            pygame.draw.rect(surface, theme.lerp(color, theme.WHITE, 0.5),
                             pygame.Rect(rec.x + 8, rec.y + 3, rec.w - 16, 2),
                             border_radius=1)

    # ---------------------------------------------------- flashes + sparks
    def _draw_hits(self, surface, lanes):
        for i in range(4):
            a = self._flash[i]
            if a <= 0.01:
                continue
            lr = lanes[i]
            theme.alpha_rect(surface, lr, self._flash_color[i],
                             int(90 * a), radius=6)
        for s in self._sparks:
            t = 1.0 - s["life"] / s["max"]
            col = theme.lerp(theme.BG, s["color"], t)
            if "ring" in s:
                r = s["ring"] * (1.0 - t) + 10
                theme.alpha_rect(surface,
                                 pygame.Rect(s["x"] - r, s["y"] - r,
                                             int(r * 2), int(r * 2)),
                                 s["color"], int(140 * t), radius=int(r))
                continue
            r = s["r"] * (0.4 + 0.6 * t)
            pygame.draw.polygon(surface, col, _star(s["x"], s["y"], r))
            if t > 0.55:
                pygame.draw.polygon(surface, theme.WHITE,
                                    _star(s["x"], s["y"], r * 0.4))

    def _spawn_hold_sparks(self, lane, beam, color, boost, dt):
        self._hold_acc[lane] += dt * _SPARKS_PER_SEC
        while self._hold_acc[lane] >= 1.0:
            self._hold_acc[lane] -= 1.0
            # keep sparks inside the highway even when the beam of a long
            # hold runs far below it
            top = HIT_Y - _NOTE_H // 2
            bottom = max(top + 8, min(beam.bottom, HW.bottom))
            self._sparks.append({
                "x": random.uniform(beam.left - 4, beam.right + 4),
                "y": random.uniform(top, bottom),
                "vx": random.uniform(-16, 16),
                "vy": random.uniform(-72, -18),
                "life": 0.0,
                "max": random.uniform(*_SPARK_LIFE),
                "r": random.uniform(2.4, 5.6),
                "color": theme.MAGENTA if boost else color,
            })

    def _step_fx(self, dt):
        for i in range(4):
            if self._flash[i] > 0:
                self._flash[i] = max(0.0, self._flash[i] - dt * 3.4)
        if dt <= 0 or not self._sparks:
            return
        alive = []
        for s in self._sparks:
            s["life"] += dt
            if s["life"] >= s["max"]:
                continue
            s["x"] += s["vx"] * dt
            s["y"] += s["vy"] * dt
            s["vy"] += 60 * dt
            alive.append(s)
        self._sparks = alive


def _star(cx, cy, r, sharp=0.34):
    pts = []
    for i in range(8):
        a = -math.pi / 2 + i * math.pi / 4
        rr = r if i % 2 == 0 else r * sharp
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return pts


def key_labels(config) -> list:
    labels = []
    for i in range(4):
        name = config.lane_keys[i]
        labels.append(name.upper() if name else "-")
    return labels
