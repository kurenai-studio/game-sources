"""Fly Fight desktop game."""

import argparse
import json
import math
import os
import random
import sys
import time
from pathlib import Path

import pygame

WIDTH, HEIGHT = 1600, 960
ARENA_WIDTH = 1120
PANEL_X = 1140
ARENA_TOP = 96
ARENA_BOTTOM = HEIGHT - 34
FLY_RADIUS = 12
CATCH_RADIUS = 30       # how close the cursor must get to "catch" the fly
CATCH_HOLD_FRAMES = 30  # about 0.5 s at the 60 FPS game loop
FLY_ESCAPE_SPEED = 32.0  # pixels/frame once the giant fiber fires
FLY_FRICTION = 0.94
FLY_CRUISE_SPEED = 9.0
FLY_TURN_RATE = 0.11
CURSOR_SPEED = 420.0     # keyboard cursor speed in pixels/second
WEAPONS = (
    ("BLASTER", 18, 520, 0.18, 1, (90, 220, 255), "normal"),
    ("SHOTGUN", 10, 460, 0.42, 5, (255, 190, 80), "normal"),
    ("BURST", 8, 600, 0.30, 3, (190, 120, 255), "normal"),
    ("PLASMA", 34, 300, 0.65, 1, (120, 255, 170), "normal"),
    ("RAIL", 55, 900, 0.95, 1, (255, 100, 130), "pierce"),
    ("SEEKER", 22, 360, 0.55, 1, (255, 120, 230), "seeker"),
    ("NOVA", 7, 400, 0.72, 9, (255, 235, 100), "nova"),
    ("NEEDLE", 12, 820, 0.08, 1, (120, 190, 255), "needle"),
    ("EMP", 6, 430, 0.85, 1, (110, 170, 255), "neuro_emp"),
    ("JAMMER", 5, 390, 0.70, 3, (205, 110, 255), "neuro_jam"),
    ("SYNAPSE", 9, 470, 0.52, 1, (80, 255, 210), "neuro_overload"),
)
CATEGORY_WEAPONS = {
    "ESCAPE": (8, 9, 10),
    "ADVANCE": (0, 2, 7),
    "STEER": (5,),
    "RETREAT": (1,),
    "STRIKE": (3, 4),
    "LUNGE": (6,),
}
CATEGORIES = ("ESCAPE", "ADVANCE", "STEER", "RETREAT", "STRIKE", "LUNGE")


class BrainEscapeController:
    """Connect the game threat to the real FlyBrain escape readout."""

    def __init__(self, log_path=None):
        try:
            import numpy as np
            from flybrain import FeatureDetectors, FlyBrain
        except ImportError as exc:
            raise RuntimeError(
                "The real brain needs the repository environment. "
                "Activate .venv and install -r requirements.txt."
            ) from exc

        self.np = np
        self.brain = FlyBrain(device="auto", sensory_input=False)
        self.detectors = FeatureDetectors(self.brain)
        self.escape = np.concatenate((
            self.brain.groups.get("escape_L", np.array([], dtype=np.int64)),
            self.brain.groups.get("escape_R", np.array([], dtype=np.int64)),
        ))
        if len(self.escape) == 0:
            raise RuntimeError(
                "Brain data has no escape_L/escape_R readout groups. "
                "Run `python -m flybrain download` or rebuild the data."
            )
        self.last_fired = 0
        self.last_drive = {}
        self.last_state = "scanning"
        self.learning_level = 0.0
        self.dopamine_hits = 0
        self.history = []
        self.total_spikes = 0
        self.category_rates = {category: 0.0 for category in CATEGORIES}
        self.dominant_category = "NEUTRAL"
        self._category_weapon_cursor = {category: 0 for category in CATEGORIES}
        self.step_count = 0
        self._last_escape = False
        self.log_file = None
        self.log_path = None
        if log_path != "off":
            if log_path is None:
                stamp = time.strftime("%Y%m%d_%H%M%S")
                log_path = os.path.join("brain_logs", f"brain_session_{stamp}.jsonl")
            path = Path(log_path)
            path.parent.mkdir(parents=True, exist_ok=True)
            self.log_path = str(path.resolve())
            self.log_file = path.open("w", encoding="utf-8")
            self.log_file.write(json.dumps({
                "type": "session",
                "schema": "flybrain-catch-v1",
                "device": self.brain.device,
                "neurons": int(self.brain.n),
                "connections": int(len(self.brain.indices)),
                "dt": float(self.brain.dt),
                "weapons": [{"name": w[0], "damage": w[1], "kind": w[6]} for w in WEAPONS],
                "note": "Connectome weights are frozen; dopamine changes task encoder only.",
            }) + "\n")
            self.log_file.flush()
        self.map_points = []
        self.spike_points = []
        self.map_aspect = 1.0
        if self.brain.positions is not None:
            valid = self.np.isfinite(self.brain.positions).all(axis=1)
            points = self.brain.positions[valid][:, [0, 2]]
            if len(points):
                lo = self.np.percentile(points, 1, axis=0)
                hi = self.np.percentile(points, 99, axis=0)
                span = self.np.maximum(hi - lo, 1)
                stride = max(1, len(points) // 1400)
                self.map_points = [
                    ((float(p[0] - lo[0]) / float(span[0])),
                     (float(p[1] - lo[1]) / float(span[1])))
                    for p in points[::stride]
                ]
                self.map_lo = lo
                self.map_span = span
                self.map_aspect = max(0.1, min(10.0, float(span[0] / span[1])))
        self.readouts = {
            "escape": self.escape,
            "steer": np.concatenate((
                self.brain.groups.get("steer_L", np.array([], dtype=np.int64)),
                self.brain.groups.get("steer_R", np.array([], dtype=np.int64)),
            )),
            "forward": np.concatenate((
                self.brain.groups.get("forward_L", np.array([], dtype=np.int64)),
                self.brain.groups.get("forward_R", np.array([], dtype=np.int64)),
            )),
            "backward": np.concatenate((
                self.brain.groups.get("backward_L", np.array([], dtype=np.int64)),
                self.brain.groups.get("backward_R", np.array([], dtype=np.int64)),
            )),
            "punch": np.concatenate((
                self.brain.groups.get("punch_L", np.array([], dtype=np.int64)),
                self.brain.groups.get("punch_R", np.array([], dtype=np.int64)),
            )),
            "kick": np.concatenate((
                self.brain.groups.get("kick_L", np.array([], dtype=np.int64)),
                self.brain.groups.get("kick_R", np.array([], dtype=np.int64)),
            )),
        }
        self.group_names = {
            "ESCAPE": "escape", "ADVANCE": "forward", "STEER": "steer",
            "RETREAT": "backward", "STRIKE": "punch", "LUNGE": "kick",
        }

    def choose_weapon(self, category):
        choices = CATEGORY_WEAPONS.get(category, ())
        if not choices:
            return None
        cursor = self._category_weapon_cursor[category]
        weapon = choices[cursor % len(choices)]
        self._category_weapon_cursor[category] = cursor + 1
        return weapon

    def step(self, cursor_pos, fly_pos, state) -> bool:
        dx = float(cursor_pos[0] - fly_pos[0])
        distance = max(1.0, float(math.hypot(dx, cursor_pos[1] - fly_pos[1])))
        threat = 1.0 if state["approach_speed_norm"] > 0 else 0.0
        inject = self.detectors.inject(
            opp=(dx, FLY_RADIUS * 2.0),
            threat=threat,
        )
        self.step_count += 1
        if self.step_count % 2:
            return self._last_escape and distance < CATCH_RADIUS * 6
        fired = self.brain.step(inject=inject)
        self.last_fired = int(self.np.intersect1d(fired, self.escape).size)
        self.spike_points = []
        if self.brain.positions is not None and len(fired):
            for p in self.brain.positions[fired[:500]][:, [0, 2]]:
                px = float((p[0] - self.map_lo[0]) / self.map_span[0])
                py = float((p[1] - self.map_lo[1]) / self.map_span[1])
                if math.isfinite(px) and math.isfinite(py):
                    self.spike_points.append((max(0.0, min(1.0, px)), max(0.0, min(1.0, py))))
        self.last_drive = dict(self.detectors.last)
        self.last_state = "ESCAPE" if self.last_fired else ("THREAT" if threat else "TRACKING")
        self.total_spikes += len(fired)
        side = "L" if dx < 0 else "R"
        self.category_rates = {}
        for category, readout_name in self.group_names.items():
            group = self.brain.groups.get(f"{readout_name}_{side}", self.np.array([], dtype=self.np.int64))
            spikes = int(self.np.intersect1d(fired, group).size)
            self.category_rates[category] = spikes / max(1, len(group))
        peak_category, peak_rate = max(self.category_rates.items(), key=lambda item: item[1])
        self.dominant_category = peak_category if peak_rate >= 0.01 else "NEUTRAL"
        self.history.append({
            "escape": self.last_fired,
            "steer": int(self.np.intersect1d(fired, self.readouts["steer"]).size),
            "forward": int(self.np.intersect1d(fired, self.readouts["forward"]).size),
            "loom": max(self.last_drive.get("loomL", 0.0), self.last_drive.get("loomR", 0.0)),
            "threat": max(self.last_drive.get("threatL", 0.0), self.last_drive.get("threatR", 0.0)),
        })
        self.history = self.history[-36:]
        self._last_escape = self.last_fired > 0
        if self.log_file and self.step_count % 5 == 0:
            self.log_file.write(json.dumps({
                "type": "step",
                "tick": self.step_count,
                "distance": round(distance, 3),
                "input": {
                    "dx": round(dx, 3),
                    "approach_speed_norm": round(float(state["approach_speed_norm"]), 4),
                    "loomL": round(float(self.last_drive.get("loomL", 0)), 4),
                    "loomR": round(float(self.last_drive.get("loomR", 0)), 4),
                    "threatL": round(float(self.last_drive.get("threatL", 0)), 4),
                    "threatR": round(float(self.last_drive.get("threatR", 0)), 4),
                },
                "output": {
                    "state": self.last_state,
                    "dominant_category": self.dominant_category,
                    "category_rates": {k: round(v, 5) for k, v in self.category_rates.items()},
                    "escape_spikes": self.last_fired,
                    "steer_spikes": self.history[-1]["steer"],
                    "forward_spikes": self.history[-1]["forward"],
                    "total_spikes": self.total_spikes,
                },
                "learning": {
                    "dopamine_hits": self.dopamine_hits,
                    "level": round(self.learning_level, 4),
                },
            }) + "\n")
            self.log_file.flush()
        return self._last_escape and distance < CATCH_RADIUS * 4

    def dopamine_hit(self) -> None:
        """Apply a small persistent reward to the fly's adaptive interface.

        The connectome weights stay frozen; learning changes the task-level
        encoder/readout, just like a dopamine-gated readout around a reservoir.
        """
        self.dopamine_hits += 1
        self.learning_level = min(1.0, self.learning_level + 0.08)
        self.detectors.p["loom_gain"] = min(16.0, 10.0 + self.learning_level * 6.0)
        self.detectors.p["threat_max"] = min(1.0, 0.8 + self.learning_level * 0.2)
        if self.log_file:
            self.log_file.write(json.dumps({
                "type": "dopamine",
                "tick": self.step_count,
                "hits": self.dopamine_hits,
                "learning_level": round(self.learning_level, 4),
            }) + "\n")
            self.log_file.flush()

    def learn_label(self) -> str:
        return f"dopamine {self.dopamine_hits}  learning {self.learning_level:.2f}"

    def close(self):
        if self.log_file:
            self.log_file.write(json.dumps({
                "type": "end",
                "ticks": self.step_count,
                "total_spikes": self.total_spikes,
            }) + "\n")
            self.log_file.close()
            self.log_file = None

    def event(self, name, **data):
        if self.log_file:
            self.log_file.write(json.dumps({
                "type": "event", "tick": self.step_count, "name": name, **data
            }) + "\n")
            self.log_file.flush()


class CatchTheFly:
    """Headless-friendly game core. Call step(cursor_pos, escape_triggered)."""

    def __init__(self, render=True, fly_pos=None):
        self.render_enabled = render
        if render:
            pygame.init()
            self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
            pygame.display.set_caption("Catch the Fly")
            self.clock = pygame.time.Clock()
            self.font = pygame.font.SysFont(None, 32)
        self.reset(fly_pos)

    def reset(self, fly_pos=None):
        self.fly_pos = list(fly_pos) if fly_pos else [ARENA_WIDTH / 2, (ARENA_TOP + ARENA_BOTTOM) / 2]
        self.fly_vel = [0.0, 0.0]
        self.wander_phase = random.random() * math.tau
        # Do not carry the previous round's distance into the new round.
        # Otherwise the first frame can look like a large approach burst.
        self._prev_dist = None
        self.escaping = False
        self.escape_frames_left = 0
        self.caught = False
        self.escaped = False
        self.catch_hold_frames = 0
        self.escape_count = 0
        self.frames = 0
        return self.get_state((ARENA_WIDTH * 0.1, ARENA_TOP + HEIGHT * 0.1))

    def get_state(self, cursor_pos):
        """Returns features describing the threat, from the fly's point of view.

        - dx_norm, dy_norm: direction FROM fly TO cursor, unit vector (which
          side the threat is on -- used to pick left vs right stimulation)
        - dist_norm: 0 (touching) .. 1 (far across the whole screen)
        - approach_speed_norm: how fast the cursor is closing the distance
          (this is what looming detectors actually respond to: getting
          bigger/closer, not just being close)
        """
        dx = cursor_pos[0] - self.fly_pos[0]
        dy = cursor_pos[1] - self.fly_pos[1]
        dist = math.hypot(dx, dy)
        max_dist = math.hypot(ARENA_WIDTH, ARENA_BOTTOM - ARENA_TOP)
        dist_norm = min(1.0, dist / max_dist)

        if self._prev_dist is None:
            self._prev_dist = dist
        approach_speed = self._prev_dist - dist  # positive = getting closer
        self._prev_dist = dist
        approach_speed_norm = max(-1.0, min(1.0, approach_speed / 20.0))

        if dist > 1e-6:
            dx_norm, dy_norm = dx / dist, dy / dist
        else:
            dx_norm, dy_norm = 0.0, 0.0

        return {
            "dx_norm": dx_norm,
            "dy_norm": dy_norm,
            "dist_norm": dist_norm,
            "approach_speed_norm": approach_speed_norm,
        }

    def step(self, cursor_pos, escape_triggered: bool, catch_radius=CATCH_RADIUS,
             behavior="NEUTRAL"):
        """Advance one frame.

        cursor_pos: (x, y) of the threat/cursor this frame
        escape_triggered: True if the brain's giant fiber fired this frame
        """
        if self.caught or self.escaped:
            return self.get_state(cursor_pos), self.caught, self.escaped

        self.frames += 1
        self.wander_phase += FLY_TURN_RATE

        # The fly is always in motion. The connectome controls escape bursts,
        # while this gentle cruise keeps the target readable between threats.
        if not self.escaping:
            # Keep a visible sideways drift instead of converging to a
            # nearly stationary point when the cursor is far away.
            target_x = (
                math.cos(self.wander_phase) * FLY_CRUISE_SPEED
                + math.sin(self.wander_phase * 2.7) * 2.5
            )
            target_y = (
                math.sin(self.wander_phase * 0.83) * FLY_CRUISE_SPEED
                + math.cos(self.wander_phase * 2.1) * 2.5
            )
            self.fly_vel[0] += (target_x - self.fly_vel[0]) * 0.14
            self.fly_vel[1] += (target_y - self.fly_vel[1]) * 0.14
            speed = math.hypot(*self.fly_vel)
            if speed < 3.0:
                self.fly_vel[0] += math.cos(self.wander_phase) * 1.4
                self.fly_vel[1] += math.sin(self.wander_phase) * 1.4
            dx = cursor_pos[0] - self.fly_pos[0]
            dy = cursor_pos[1] - self.fly_pos[1]
            distance = math.hypot(dx, dy) or 1.0
            if behavior in ("ADVANCE", "STRIKE", "LUNGE") and distance > 180:
                self.fly_vel[0] += dx / distance * 0.9
                self.fly_vel[1] += dy / distance * 0.9
            elif behavior == "RETREAT":
                self.fly_vel[0] -= dx / distance * 1.4
                self.fly_vel[1] -= dy / distance * 1.4
            elif behavior == "STEER":
                self.fly_vel[0] += -dy / distance * 1.2
                self.fly_vel[1] += dx / distance * 1.2
            self.fly_pos[0] += self.fly_vel[0]
            self.fly_pos[1] += self.fly_vel[1]
            self.fly_pos[0] = max(FLY_RADIUS, min(ARENA_WIDTH - FLY_RADIUS, self.fly_pos[0]))
            self.fly_pos[1] = max(ARENA_TOP + FLY_RADIUS, min(ARENA_BOTTOM - FLY_RADIUS, self.fly_pos[1]))

        if escape_triggered:
            # (Re-)trigger a flee burst. Re-triggering while already
            # escaping lets the fly correct its direction if the cursor is
            # still closing in.
            self.escaping = True
            self.escape_frames_left = 20
            # A real escape breaks the player's grip immediately.
            self.catch_hold_frames = 0
            self.escape_count += 1

            away_x = self.fly_pos[0] - cursor_pos[0]
            away_y = self.fly_pos[1] - cursor_pos[1]
            d = math.hypot(away_x, away_y) or 1.0
            away_x, away_y = away_x / d, away_y / d

            # Blend "away from cursor" with "away from the nearest corner,"
            # weighted by how close the fly already is to that corner. Pure
            # away-from-cursor can point straight into a wall/corner when
            # the fly is already pinned there (fleeing "away from" a cursor
            # that approaches diagonally from open space means fleeing
            # further into the corner) -- the corner term pulls the flee
            # direction back toward open space in that situation, while
            # barely affecting behavior away from corners.
            margin_x = min(self.fly_pos[0], ARENA_WIDTH - self.fly_pos[0])
            margin_y = min(self.fly_pos[1] - ARENA_TOP, ARENA_BOTTOM - self.fly_pos[1])
            corner_closeness = 1.0 - min(1.0, min(margin_x, margin_y) / 80.0)

            # Direction from the fly back toward the open centre of the map.
            # The old code used fly - centre, which pointed farther out of a
            # corner and made the fly pin itself against the boundary.
            center_x = ARENA_WIDTH / 2 - self.fly_pos[0]
            center_y = (ARENA_TOP + ARENA_BOTTOM) / 2 - self.fly_pos[1]
            cd = math.hypot(center_x, center_y) or 1.0
            center_x, center_y = center_x / cd, center_y / cd

            blend = corner_closeness  # 0 = pure away-from-cursor, 1 = pure away-from-corner
            vx = away_x * (1 - blend) + center_x * blend
            vy = away_y * (1 - blend) + center_y * blend
            vd = math.hypot(vx, vy) or 1.0

            self.fly_vel = [vx / vd * FLY_ESCAPE_SPEED, vy / vd * FLY_ESCAPE_SPEED]

        if self.escaping:
            self.fly_pos[0] += self.fly_vel[0]
            self.fly_pos[1] += self.fly_vel[1]
            self.fly_vel[0] *= FLY_FRICTION
            self.fly_vel[1] *= FLY_FRICTION

            # Bounce off walls instead of just clamping position, so the fly
            # doesn't get pinned dead in a corner while cornered by the cursor.
            if self.fly_pos[0] < FLY_RADIUS:
                self.fly_pos[0] = FLY_RADIUS
                self.fly_vel[0] = abs(self.fly_vel[0])
            elif self.fly_pos[0] > ARENA_WIDTH - FLY_RADIUS:
                self.fly_pos[0] = ARENA_WIDTH - FLY_RADIUS
                self.fly_vel[0] = -abs(self.fly_vel[0])
            if self.fly_pos[1] < ARENA_TOP + FLY_RADIUS:
                self.fly_pos[1] = ARENA_TOP + FLY_RADIUS
                self.fly_vel[1] = abs(self.fly_vel[1])
            elif self.fly_pos[1] > ARENA_BOTTOM - FLY_RADIUS:
                self.fly_pos[1] = ARENA_BOTTOM - FLY_RADIUS
                self.fly_vel[1] = -abs(self.fly_vel[1])

            self.escape_frames_left -= 1
            if self.escape_frames_left <= 0:
                self.escaping = False

        dist_to_cursor = math.hypot(cursor_pos[0] - self.fly_pos[0], cursor_pos[1] - self.fly_pos[1])
        if dist_to_cursor < catch_radius and not self.escaping:
            # The cursor must stay over the fly. A quick touch is not enough.
            self.catch_hold_frames = min(CATCH_HOLD_FRAMES, self.catch_hold_frames + 1)
            if self.catch_hold_frames >= CATCH_HOLD_FRAMES:
                self.caught = True
        elif dist_to_cursor < catch_radius:
            # Keep a tiny bit of progress while the fly is escaping, but do
            # not let the player win by holding the cursor in place.
            self.catch_hold_frames = max(0, self.catch_hold_frames - 3)
        else:
            # Leaving the catch ring loses the grip, making movement matter.
            self.catch_hold_frames = max(0, self.catch_hold_frames - 2)
        if not self.caught and self.frames > 600:  # ~10s at 60fps: threat gave up
            self.escaped = True

        return self.get_state(cursor_pos), self.caught, self.escaped

    def render(self, cursor_pos):
        if not self.render_enabled:
            return
        self.screen.fill((20, 20, 30))
        pygame.draw.circle(self.screen, (255, 80, 80), (int(cursor_pos[0]), int(cursor_pos[1])), CATCH_RADIUS, 2)
        # Hold-to-catch progress ring: the fly is only caught after a full arc.
        progress = self.catch_hold_frames / CATCH_HOLD_FRAMES
        if progress > 0:
            rect = pygame.Rect(
                int(self.fly_pos[0] - CATCH_RADIUS - 6),
                int(self.fly_pos[1] - CATCH_RADIUS - 6),
                (CATCH_RADIUS + 6) * 2,
                (CATCH_RADIUS + 6) * 2,
            )
            pygame.draw.arc(self.screen, (70, 240, 130), rect, -math.pi / 2,
                            -math.pi / 2 + math.tau * progress, 5)
        fly_color = (255, 220, 0) if not self.escaping else (255, 100, 100)
        pygame.draw.circle(self.screen, fly_color, (int(self.fly_pos[0]), int(self.fly_pos[1])), FLY_RADIUS)
        if self.caught:
            msg = self.font.render("CAUGHT! You beat the giant fiber.", True, (0, 255, 0))
            self.screen.blit(msg, (WIDTH // 2 - 220, 20))
        elif self.escaped:
            msg = self.font.render("The fly escaped. Real reflex wins.", True, (255, 150, 0))
            self.screen.blit(msg, (WIDTH // 2 - 200, 20))
        else:
            hold = self.catch_hold_frames / 60.0
            info = self.font.render(
                f"Hold on fly: {hold:.1f}/{CATCH_HOLD_FRAMES / 60:.1f}s   Escapes: {self.escape_count}",
                True, (225, 225, 235))
            self.screen.blit(info, (18, HEIGHT - 42))
        pygame.display.flip()


class Particle:
    def __init__(self, x, y, color, speed=None, life=0.6, size=None):
        angle = random.random() * math.tau
        speed = speed if speed is not None else random.uniform(1.5, 6.0)
        self.x, self.y = x, y
        self.vx, self.vy = math.cos(angle) * speed, math.sin(angle) * speed
        self.life = self.max_life = life
        self.size = size if size is not None else random.uniform(2, 5)
        self.color = color

    def update(self, dt):
        self.x += self.vx * dt * 60
        self.y += self.vy * dt * 60
        self.vx *= 0.97
        self.vy *= 0.97
        self.life -= dt
        return self.life > 0


def draw_text(screen, font, text, pos, center=False, color=(235, 240, 255)):
    surf = font.render(text, True, color)
    rect = surf.get_rect()
    if center:
        rect.center = pos
    else:
        rect.topleft = pos
    screen.blit(surf, rect)


def play_test(use_brain=False):
    """Play the arcade game, optionally driven by the real connectome."""
    pygame.init()
    screen = pygame.display.set_mode((WIDTH, HEIGHT), pygame.RESIZABLE | pygame.SCALED)
    pygame.display.set_caption("FLY FIGHT // ARCADE")
    clock = pygame.time.Clock()
    fullscreen = False

    def toggle_fullscreen():
        nonlocal screen, fullscreen
        try:
            pygame.display.toggle_fullscreen()
        except pygame.error:
            fullscreen = not fullscreen
            flags = pygame.FULLSCREEN | pygame.SCALED if fullscreen else pygame.RESIZABLE | pygame.SCALED
            screen = pygame.display.set_mode((WIDTH, HEIGHT), flags)
        fullscreen = bool(pygame.display.get_surface().get_flags() & pygame.FULLSCREEN)
        pygame.event.clear(pygame.VIDEORESIZE)
        pygame.mouse.set_pos((ARENA_WIDTH // 2, (ARENA_TOP + ARENA_BOTTOM) // 2))

    title_font = pygame.font.SysFont("arial", 30, bold=True)
    hud_font = pygame.font.SysFont("arial", 22, bold=True)
    small_font = pygame.font.SysFont("arial", 17)
    huge_font = pygame.font.SysFont("arial", 54, bold=True)

    game = CatchTheFly(render=False)
    brain_log = os.environ.get("FLY_BRAIN_LOG")
    brain_controller = BrainEscapeController(brain_log) if use_brain else None
    player_hp = 100
    fly_hp = 100
    total_time = 0.0
    shake = 0.0
    flash = 0.0
    paused = False
    game_over = False
    started = False
    cursor_pos = [ARENA_WIDTH / 2, (ARENA_TOP + ARENA_BOTTOM) / 2]

    particles = []
    trails = []
    stars = [(random.randrange(WIDTH), random.randrange(HEIGHT), random.choice([1, 1, 1, 2]))
             for _ in range(90)]

    # Power-ups: magnet and time bonus.
    powerups = []
    bullets = []
    player_weapon = 0
    fly_weapon = 1
    player_fire_cooldown = 0.0
    fly_fire_cooldown = 0.0
    hit_flash = 0.0
    neuro_emp = 0.0
    neuro_jam = 0.0
    neuro_overload = 0.0

    def spawn_fly():
        margin = 70
        pos = (random.randint(margin, ARENA_WIDTH-margin),
               random.randint(ARENA_TOP + margin, ARENA_BOTTOM-margin))
        game.reset(pos)

    player_deaths = 0
    fly_deaths = 0
    player_kills = 0
    fly_kills = 0
    death_banner = ""
    death_banner_time = 0.0

    def reset_round():
        nonlocal player_hp, fly_hp, paused, game_over
        nonlocal started, cursor_pos, player_fire_cooldown, fly_fire_cooldown
        nonlocal player_deaths, fly_deaths, player_kills, fly_kills
        nonlocal death_banner, death_banner_time
        nonlocal neuro_emp, neuro_jam, neuro_overload
        player_hp = 100
        fly_hp = 100
        player_deaths = 0
        fly_deaths = 0
        neuro_emp = 0.0
        neuro_jam = 0.0
        neuro_overload = 0.0
        death_banner = ""
        death_banner_time = 0.0
        paused = False
        game_over = False
        started = False
        powerups.clear()
        particles.clear()
        trails.clear()
        bullets.clear()
        player_fire_cooldown = 0.0
        fly_fire_cooldown = 0.0
        cursor_pos = [ARENA_WIDTH / 2, (ARENA_TOP + ARENA_BOTTOM) / 2]
        pygame.mouse.set_pos(cursor_pos)
        spawn_fly()

    def fire(x, y, target_x, target_y, owner, weapon_index):
        name, damage, speed, cooldown, count, color, kind = WEAPONS[weapon_index]
        if brain_controller is not None:
            brain_controller.event("fire", owner=owner, weapon=name, kind=kind)
        dx, dy = target_x - x, target_y - y
        distance = math.hypot(dx, dy) or 1.0
        angle = math.atan2(dy, dx)
        spread = 0.16 if count > 1 else 0
        for shot in range(count):
            offset = (shot - (count - 1) / 2) * spread
            bullets.append({
                "x": x, "y": y, "vx": math.cos(angle + offset) * speed,
                "vy": math.sin(angle + offset) * speed, "owner": owner,
                "weapon": weapon_index, "damage": damage, "color": color, "life": 1.8,
                "kind": kind, "pierce": kind == "pierce",
            })

    def burst(x, y, color=(255, 220, 80), amount=28):
        for _ in range(min(amount, 18)):
            particles.append(Particle(x, y, color, life=random.uniform(.35, .8)))
        del particles[:-260]

    def brain_meter(label, value, y, color):
        value = max(0.0, min(1.0, float(value)))
        draw_text(screen, small_font, label, (PANEL_X + 18, y), color=(185, 195, 215))
        pygame.draw.rect(screen, (32, 40, 58), (PANEL_X + 144, y + 3, 130, 10), border_radius=4)
        if value:
            pygame.draw.rect(screen, color, (PANEL_X + 144, y + 3, int(value * 130), 10), border_radius=4)
        draw_text(screen, small_font, f"{value:.2f}", (PANEL_X + 282, y), color=color)

    def draw_brain_map(x, y, width, height):
        rect = pygame.Rect(x, y, width, height)
        pygame.draw.rect(screen, (8, 12, 22), rect, border_radius=6)
        pygame.draw.rect(screen, (34, 46, 66), rect, 1, border_radius=6)
        if brain_controller is None:
            return
        # Fit the connectome into the card without changing its geometry.
        # The old direct width/height mapping stretched the neural tissue.
        inner = pygame.Rect(x + 6, y + 22, width - 12, height - 28)
        if brain_controller.map_aspect >= inner.width / inner.height:
            map_width = inner.width
            map_height = max(1, int(map_width / brain_controller.map_aspect))
        else:
            map_height = inner.height
            map_width = max(1, int(map_height * brain_controller.map_aspect))
        map_x = inner.x + (inner.width - map_width) // 2
        map_y = inner.y + (inner.height - map_height) // 2
        for px, py in brain_controller.map_points:
            pygame.draw.circle(screen, (58, 71, 92),
                               (map_x + int(px * map_width), map_y + int(py * map_height)), 1)
        for px, py in brain_controller.spike_points:
            pygame.draw.circle(screen, (255, 178, 62),
                               (map_x + int(px * map_width), map_y + int(py * map_height)), 2)
        draw_text(screen, small_font, "NERVE MAP", (x + 8, y + 6),
                  color=(115, 130, 160))

    spawn_fly()

    running = True
    try:
      while running:
        dt = min(clock.tick(60) / 1000.0, 0.04)
        total_time += dt

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.VIDEORESIZE:
                pass
            elif event.type == pygame.MOUSEBUTTONDOWN and not game_over:
                started = True
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    if fullscreen:
                        toggle_fullscreen()
                    else:
                        running = False
                elif event.key == pygame.K_F11:
                    toggle_fullscreen()
                elif pygame.K_1 <= event.key <= pygame.K_9:
                    player_weapon = event.key - pygame.K_1
                elif event.key == pygame.K_0:
                    player_weapon = 9
                elif event.key == pygame.K_p and not game_over:
                    if started:
                        paused = not paused
                elif event.key == pygame.K_r:
                    reset_round()
                elif event.key == pygame.K_SPACE and game_over:
                    reset_round()
                    started = True
                elif event.key in (pygame.K_SPACE, pygame.K_RETURN) and not game_over:
                    started = True

        keys = pygame.key.get_pressed()
        cursor = list(pygame.mouse.get_pos())
        move_x = int(keys[pygame.K_RIGHT] or keys[pygame.K_d]) - int(
            keys[pygame.K_LEFT] or keys[pygame.K_a])
        move_y = int(keys[pygame.K_DOWN] or keys[pygame.K_s]) - int(
            keys[pygame.K_UP] or keys[pygame.K_w])
        if move_x or move_y:
            cursor_pos[0] = max(0, min(ARENA_WIDTH, cursor_pos[0] + move_x * CURSOR_SPEED * dt))
            cursor_pos[1] = max(ARENA_TOP, min(ARENA_BOTTOM, cursor_pos[1] + move_y * CURSOR_SPEED * dt))
            cursor = cursor_pos
        else:
            cursor_pos = [float(max(0, min(ARENA_WIDTH, cursor[0]))),
                          float(max(ARENA_TOP, min(ARENA_BOTTOM, cursor[1])))]
            cursor = cursor_pos

        if started and not paused and not game_over:
            state = game.get_state(cursor)
            if neuro_jam > 0:
                state["approach_speed_norm"] *= 0.28
            if brain_controller is not None:
                brain_escape = brain_controller.step(cursor, game.fly_pos, state)
                fly_category = brain_controller.dominant_category
            else:
                brain_escape = (
                    state["dist_norm"] < 0.22
                    and state["approach_speed_norm"] > 0.10
                )
                fly_category = "ESCAPE" if brain_escape else "NEUTRAL"
            if neuro_emp > 0:
                brain_escape = False
            if neuro_overload > 0:
                brain_escape = brain_escape and random.random() > 0.35
            # This mode is a duel, so proximity never ends the round; HP does.
            state, caught, escaped = game.step(
                cursor, brain_escape, catch_radius=0, behavior=fly_category)

            player_fire_cooldown = max(0.0, player_fire_cooldown - dt)
            fly_fire_cooldown = max(0.0, fly_fire_cooldown - dt)
            mouse_fire = pygame.mouse.get_pressed()[0]
            if (mouse_fire or keys[pygame.K_f]) and player_fire_cooldown <= 0:
                fire(cursor[0], cursor[1], game.fly_pos[0], game.fly_pos[1], "player", player_weapon)
                player_fire_cooldown = WEAPONS[player_weapon][3]
            if fly_fire_cooldown <= 0 and game.fly_pos and fly_category not in ("ESCAPE", "NEUTRAL"):
                category_weapon = brain_controller.choose_weapon(fly_category) if brain_controller else None
                if category_weapon is not None:
                    fly_weapon = category_weapon
                    fire(game.fly_pos[0], game.fly_pos[1], cursor[0], cursor[1], "fly", fly_weapon)
                    if brain_controller is not None:
                        brain_controller.event(
                            "brain_attack",
                            dominant_category=fly_category,
                            weapon=WEAPONS[fly_weapon][0],
                            category_rates={k: round(v, 5) for k, v in brain_controller.category_rates.items()},
                        )
                    fly_fire_cooldown = WEAPONS[fly_weapon][3] * 1.8

            for bullet in bullets:
                if bullet["kind"] == "seeker":
                    target = game.fly_pos if bullet["owner"] == "player" else cursor
                    tx, ty = target[0] - bullet["x"], target[1] - bullet["y"]
                    target_angle = math.atan2(ty, tx)
                    current_angle = math.atan2(bullet["vy"], bullet["vx"])
                    delta = (target_angle - current_angle + math.pi) % math.tau - math.pi
                    turn = max(-0.08, min(0.08, delta))
                    angle = current_angle + turn
                    speed = math.hypot(bullet["vx"], bullet["vy"])
                    bullet["vx"], bullet["vy"] = math.cos(angle) * speed, math.sin(angle) * speed
                bullet["x"] += bullet["vx"] * dt
                bullet["y"] += bullet["vy"] * dt
                bullet["life"] -= dt
            for bullet in bullets[:]:
                hit = math.hypot(bullet["x"] - game.fly_pos[0], bullet["y"] - game.fly_pos[1]) < FLY_RADIUS + 8
                hit_player = math.hypot(bullet["x"] - cursor[0], bullet["y"] - cursor[1]) < 16
                if bullet["owner"] == "player" and hit:
                    fly_hp = max(0, fly_hp - bullet["damage"])
                    if bullet["kind"] == "neuro_emp":
                        neuro_emp = max(neuro_emp, 2.8)
                    elif bullet["kind"] == "neuro_jam":
                        neuro_jam = max(neuro_jam, 4.0)
                    elif bullet["kind"] == "neuro_overload":
                        neuro_overload = max(neuro_overload, 3.2)
                    if brain_controller is not None:
                        brain_controller.event(
                            "hit", target="fly", weapon=WEAPONS[bullet["weapon"]][0],
                            hp=fly_hp, neural_effect=bullet["kind"],
                        )
                    hit_flash = 0.16
                    burst(game.fly_pos[0], game.fly_pos[1], (255, 210, 80), 10)
                    if not bullet["pierce"]:
                        bullet["life"] = 0
                elif bullet["owner"] == "fly" and hit_player:
                    player_hp = max(0, player_hp - bullet["damage"])
                    hit_flash = 0.16
                    shake = 6
                    burst(cursor[0], cursor[1], (255, 80, 90), 12)
                    if brain_controller is not None:
                        brain_controller.event(
                            "hit", target="player", weapon=WEAPONS[bullet["weapon"]][0],
                            hp=player_hp,
                        )
                    bullet["life"] = 0
                if bullet["life"] <= 0 or not (0 <= bullet["x"] <= ARENA_WIDTH and ARENA_TOP <= bullet["y"] <= ARENA_BOTTOM):
                    if bullet in bullets:
                        bullets.remove(bullet)
            if fly_hp <= 0:
                player_kills += 1
                fly_deaths += 1
                death_banner = "FLY DESTROYED  ·  RESPAWN"
                death_banner_time = 1.5
                fly_hp = 100
                game.reset((random.randint(70, ARENA_WIDTH - 70),
                            random.randint(ARENA_TOP + 70, ARENA_BOTTOM - 70)))
                bullets[:] = [b for b in bullets if b["owner"] != "player"]
                burst(game.fly_pos[0], game.fly_pos[1], (255, 220, 70), 45)
                if brain_controller is not None:
                    brain_controller.event("death", target="fly", killer="player")
            if player_hp <= 0:
                fly_kills += 1
                player_deaths += 1
                death_banner = "PLAYER DESTROYED  ·  RESPAWN"
                death_banner_time = 1.5
                if brain_controller is not None:
                    brain_controller.dopamine_hit()
                    fly_weapon = (fly_weapon + 1 + brain_controller.dopamine_hits) % len(WEAPONS)
                player_hp = 100
                cursor_pos = [ARENA_WIDTH / 2, (ARENA_TOP + ARENA_BOTTOM) / 2]
                bullets[:] = [b for b in bullets if b["owner"] != "fly"]
                burst(cursor_pos[0], cursor_pos[1], (90, 220, 255), 35)
                if brain_controller is not None:
                    brain_controller.event("death", target="player", killer="fly")

            # Trail behind the fly while it is moving.
            if len(trails) == 0 or math.hypot(
                game.fly_pos[0] - trails[-1][0], game.fly_pos[1] - trails[-1][1]
            ) > 5:
                trails.append((game.fly_pos[0], game.fly_pos[1], 0.5))
            trails = [(x, y, life-dt) for x, y, life in trails if life-dt > 0][-18:]

            if caught:
                shake = 12
                flash = 0.18
                burst(game.fly_pos[0], game.fly_pos[1], (90, 255, 150), 45)

            elif escaped:
                shake = 8
                flash = 0.12
                burst(game.fly_pos[0], game.fly_pos[1], (255, 100, 90), 20)


        # Effects update even when paused for a tiny bit of life.
        particles = [p for p in particles if p.update(dt)]
        shake = max(0, shake - dt * 30)
        flash = max(0, flash - dt)
        hit_flash = max(0, hit_flash - dt)
        neuro_emp = max(0.0, neuro_emp - dt)
        neuro_jam = max(0.0, neuro_jam - dt)
        neuro_overload = max(0.0, neuro_overload - dt)
        death_banner_time = max(0.0, death_banner_time - dt)

        ox = random.uniform(-shake, shake) if shake else 0
        oy = random.uniform(-shake, shake) if shake else 0

        screen.fill((9, 11, 22))

        for x, y, size in stars:
            twinkle = 110 + int(70 * math.sin(total_time * 2 + x * .03))
            pygame.draw.circle(screen, (twinkle, twinkle, min(255, twinkle+20)),
                               (int(x), int(y)), size)
        grid_shift = int(total_time * 12) % 40
        for x in range(-40, ARENA_WIDTH + 40, 40):
            pygame.draw.line(screen, (18, 24, 43), (x, 70-grid_shift), (x, HEIGHT), 1)
        for y in range(70-grid_shift, HEIGHT, 40):
            pygame.draw.line(screen, (18, 24, 43), (0, y), (WIDTH, y), 1)

        pygame.draw.rect(screen, (65, 78, 120), (12, 88, ARENA_WIDTH-24, HEIGHT-102), 2, border_radius=14)

        for x, y, life in trails:
            r = max(1, int(9 * life))
            pygame.draw.circle(screen, (255, 130, 55), (int(x+ox), int(y+oy)), r)

        for bullet in bullets:
            color = bullet["color"]
            pygame.draw.circle(screen, color, (int(bullet["x"] + ox), int(bullet["y"] + oy)), 5)
            pygame.draw.circle(screen, (255, 255, 255), (int(bullet["x"] + ox), int(bullet["y"] + oy)), 2)

        catch_r = CATCH_RADIUS
        pygame.draw.circle(screen, (255, 90, 110), (int(cursor[0]+ox), int(cursor[1]+oy)), catch_r, 2)
        pygame.draw.circle(screen, (255, 90, 110), (int(cursor[0]+ox), int(cursor[1]+oy)), 4)

        fx, fy = int(game.fly_pos[0]+ox), int(game.fly_pos[1]+oy)
        fly_col = (255, 90, 90) if game.escaping else (255, 220, 60)
        for rr, alpha in [(28, 35), (21, 55)]:
            glow = pygame.Surface((rr*2, rr*2), pygame.SRCALPHA)
            pygame.draw.circle(glow, (*fly_col, alpha), (rr, rr), rr)
            screen.blit(glow, (fx-rr, fy-rr))
        pygame.draw.circle(screen, fly_col, (fx, fy), FLY_RADIUS)
        pygame.draw.circle(screen, (30, 30, 40), (fx-4, fy-2), 3)
        pygame.draw.circle(screen, (30, 30, 40), (fx+4, fy-2), 3)

        if game.catch_hold_frames:
            progress = game.catch_hold_frames / CATCH_HOLD_FRAMES
            rect = pygame.Rect(fx-catch_r-7, fy-catch_r-7, (catch_r+7)*2, (catch_r+7)*2)
            pygame.draw.arc(screen, (80, 255, 160), rect, -math.pi/2,
                            -math.pi/2 + math.tau*progress, 6)

        pygame.draw.rect(screen, (12, 16, 30), (0, 0, WIDTH, 88))
        draw_text(screen, title_font, "FLY FIGHT", (18, 14))
        if brain_controller is not None:
            draw_text(screen, small_font,
                      f"REAL CONNECTOME  ·  {brain_controller.brain.device.upper()}",
                      (18, 50), color=(120, 220, 255))
            draw_text(screen, small_font,
                      f"{brain_controller.brain.n:,} neurons · {len(brain_controller.brain.indices):,} connections",
                      (18, 70), color=(115, 130, 160))
        draw_text(screen, hud_font, f"YOU HP {player_hp}", (420, 18), color=(90, 220, 255))
        draw_text(screen, hud_font, f"FLY HP {fly_hp}", (620, 18), color=(255, 110, 100))
        pygame.draw.rect(screen, (34, 42, 58), (420, 55, 160, 13), border_radius=4)
        pygame.draw.rect(screen, (90, 220, 255), (420, 55, int(player_hp * 1.6), 13), border_radius=4)
        pygame.draw.rect(screen, (34, 42, 58), (620, 55, 160, 13), border_radius=4)
        pygame.draw.rect(screen, (255, 110, 100), (620, 55, int(fly_hp * 1.6), 13), border_radius=4)
        draw_text(screen, small_font, f"WEAPON {player_weapon + 1}: {WEAPONS[player_weapon][0]}",
                  (820, 18), color=WEAPONS[player_weapon][5])
        draw_text(screen, small_font, "1-9/0 switch · hold F/click fire", (820, 52), color=(170, 180, 205))
        draw_text(screen, small_font, "FLY BRAIN  " + (
            brain_controller.dominant_category if brain_controller else "NEUTRAL"),
                  (820, 70), color=(255, 205, 90))

        draw_text(screen, small_font,
                  "[P] pause   [R] restart   [F11] fullscreen   [1-9/0] weapons   [F/click] fire   [ESC] quit",
                  (18, HEIGHT-27))


        pygame.draw.rect(screen, (12, 16, 30), (PANEL_X, 96, WIDTH - PANEL_X, HEIGHT - 130), border_radius=10)
        pygame.draw.rect(screen, (26, 34, 52), (PANEL_X + 10, 104, WIDTH - PANEL_X - 20, 54), border_radius=8)
        draw_text(screen, hud_font, "FLY BRAIN", (PANEL_X + 20, 112), color=(120, 220, 255))
        draw_text(screen, small_font, "LIVE CONNECTOME TELEMETRY", (PANEL_X + 20, 140), color=(115, 130, 160))
        if brain_controller is not None:
            status_color = (255, 110, 100) if brain_controller.last_state == "ESCAPE" else (255, 205, 90) if brain_controller.last_state == "THREAT" else (120, 255, 170)
            draw_text(screen, hud_font, brain_controller.last_state, (PANEL_X + 188, 118), color=status_color)
            draw_text(screen, small_font, f"spikes total  {brain_controller.total_spikes:,}", (PANEL_X + 18, 176), color=(170, 180, 205))
            draw_brain_map(PANEL_X + 18, 194, 380, 125)
            draw_text(screen, small_font, "EYES → BRAIN  ·  L / R", (PANEL_X + 18, 332), color=(115, 130, 160))
            y = 354
            for label, key, color in (
                ("loom L", "loomL", (90, 220, 255)), ("loom R", "loomR", (90, 220, 255)),
                ("threat L", "threatL", (255, 110, 100)), ("threat R", "threatR", (255, 110, 100)),
                ("chase L", "chaseL", (190, 120, 255)), ("chase R", "chaseR", (190, 120, 255)),
            ):
                brain_meter(label, brain_controller.last_drive.get(key, 0.0), y, color)
                y += 20
            draw_text(screen, small_font, "BRAIN → BUTTONS", (PANEL_X + 18, y + 5), color=(115, 130, 160))
            y += 26
            for label, key, color in (("DNp01 escape", "escape", (255, 110, 100)),
                                      ("DNa02 steer", "steer", (255, 205, 90)),
                                      ("DNg100 move", "forward", (120, 255, 170))):
                latest = brain_controller.history[-1].get(key, 0) if brain_controller.history else 0
                brain_meter(label, latest / 3.0, y, color)
                y += 20
            draw_text(screen, small_font, "ACTIVITY  · last 36 steps", (PANEL_X + 18, y + 5), color=(115, 130, 160))
            chart = pygame.Rect(PANEL_X + 18, y + 25, 380, 42)
            pygame.draw.rect(screen, (8, 12, 22), chart, border_radius=5)
            history = brain_controller.history
            if len(history) > 1:
                points = []
                for i, item in enumerate(history):
                    px = chart.left + int(i / (len(history) - 1) * chart.width)
                    py = chart.bottom - int(min(1.0, item["escape"] / 2.0) * chart.height)
                    points.append((px, py))
                pygame.draw.lines(screen, (255, 110, 100), False, points, 2)
                points = [(chart.left + int(i / (len(history) - 1) * chart.width),
                           chart.bottom - int(min(1.0, item["loom"]) * chart.height))
                          for i, item in enumerate(history)]
                pygame.draw.lines(screen, (90, 220, 255), False, points, 2)
            draw_text(screen, small_font, "red: escape · blue: looming", (PANEL_X + 18, y + 73), color=(150, 165, 190))
        else:
            draw_text(screen, small_font, "STANDALONE THRESHOLD MODE", (PANEL_X + 18, 180), color=(255, 200, 100))
            draw_text(screen, small_font, "Run --brain for live neural activity.", (PANEL_X + 18, 210), color=(170, 180, 205))
        draw_text(screen, small_font, "OBJECTIVE", (PANEL_X + 18, 662), color=(115, 130, 160))
        draw_text(screen, small_font, "Shoot · respawn · adapt · repeat", (PANEL_X + 18, 682), color=(220, 225, 240))
        neuro_status = []
        if neuro_emp > 0:
            neuro_status.append(f"EMP {neuro_emp:.1f}s")
        if neuro_jam > 0:
            neuro_status.append(f"JAM {neuro_jam:.1f}s")
        if neuro_overload > 0:
            neuro_status.append(f"OVERLOAD {neuro_overload:.1f}s")
        draw_text(screen, small_font, "NEURAL EFFECT  " + (" · ".join(neuro_status) if neuro_status else "CLEAR"),
                  (PANEL_X + 18, 700), color=(110, 170, 255) if neuro_status else (125, 140, 165))
        if brain_controller is not None:
            draw_text(screen, small_font, f"DOMINANT  {brain_controller.dominant_category}",
                      (PANEL_X + 220, 700), color=(120, 255, 170))
        draw_text(screen, small_font, f"KILLS  YOU {player_kills}  ·  FLY {fly_kills}",
                  (PANEL_X + 18, 722), color=(170, 180, 205))
        draw_text(screen, small_font, f"RESPAWNS  YOU {player_deaths}  ·  FLY {fly_deaths}",
                  (PANEL_X + 18, 742), color=(125, 140, 165))
        if brain_controller is not None:
            draw_text(screen, small_font, brain_controller.learn_label(),
                      (PANEL_X + 18, 762), color=(255, 205, 90))
        draw_text(screen, small_font, "ARSENAL  ·  1-9/0", (PANEL_X + 18, 786), color=(115, 130, 160))
        for i, (name, damage, speed, cooldown, count, color, kind) in enumerate(WEAPONS):
            key = str(i + 1) if i < 9 else "0"
            marker = ">" if i == player_weapon else " "
            draw_text(screen, small_font, f"{marker} {key} {name:<8} {damage:02d} dmg",
                      (PANEL_X + 18, 806 + i * 15), color=color if i == player_weapon else (150, 165, 190))
        draw_text(screen, small_font, f"FLY LOADOUT  {WEAPONS[fly_weapon][0]}",
                  (PANEL_X + 220, 786), color=WEAPONS[fly_weapon][5])

        for p in particles:
            ratio = max(0, p.life / p.max_life)
            pygame.draw.circle(screen, p.color,
                               (int(p.x+ox), int(p.y+oy)),
                               max(1, int(p.size * ratio)))

        if paused and not game_over:
            pygame.draw.rect(screen, (5, 7, 14), (0, 0, ARENA_WIDTH, HEIGHT))
            draw_text(screen, huge_font, "PAUSED", (ARENA_WIDTH//2, HEIGHT//2-20), center=True)
            draw_text(screen, small_font, "Press P to continue", (ARENA_WIDTH//2, HEIGHT//2+35), center=True)

        if not started and not game_over:
            pygame.draw.rect(screen, (5, 7, 14), (0, 0, ARENA_WIDTH, HEIGHT))
            draw_text(screen, huge_font, "CATCH THE FLY", (ARENA_WIDTH//2, 245), center=True)
            draw_text(screen, title_font, "Destroy the fly before it destroys you.", (ARENA_WIDTH//2, 325), center=True)
            draw_text(screen, small_font, "Mouse/WASD move · hold click or F to fire · 1-9/0 weapons", (ARENA_WIDTH//2, 365), center=True)
            draw_text(screen, hud_font, "Click, SPACE, or ENTER to start", (ARENA_WIDTH//2, 425), center=True)

        if game_over:
            pygame.draw.rect(screen, (5, 7, 14), (0, 0, ARENA_WIDTH, HEIGHT))
            result = "YOU WIN!" if player_hp > 0 else "THE FLY WINS!"
            result_color = (90, 255, 160) if player_hp > 0 else (255, 110, 100)
            draw_text(screen, huge_font, result, (ARENA_WIDTH//2, 235), center=True, color=result_color)
            draw_text(screen, title_font, f"YOU HP {player_hp}   —   FLY HP {fly_hp}", (ARENA_WIDTH//2, 320), center=True)
            draw_text(screen, hud_font, "The match ends when one health bar reaches zero.", (ARENA_WIDTH//2, 370), center=True)
            draw_text(screen, small_font, "SPACE = play again    R = reset", (ARENA_WIDTH//2, 435), center=True)

        if hit_flash:
            flash_alpha = int(150 * hit_flash / 0.16)
            target = cursor if player_hp < 100 else game.fly_pos
            impact = pygame.Surface((90, 90), pygame.SRCALPHA)
            pygame.draw.circle(impact, (255, 70, 90, flash_alpha),
                               (45, 45), 38, 4)
            screen.blit(impact, (int(target[0] - 45), int(target[1] - 45)))
        if death_banner_time:
            banner_color = (255, 110, 100) if "PLAYER" in death_banner else (255, 205, 90)
            draw_text(screen, huge_font, death_banner, (ARENA_WIDTH // 2, 150),
                      center=True, color=banner_color)

        pygame.display.flip()

    finally:
        if brain_controller is not None:
            brain_controller.close()
        pygame.quit()
    sys.exit()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--test", action="store_true", help="play the upgraded standalone arcade mode")
    parser.add_argument("--brain", action="store_true", help="play using the real flybrain connectome")
    args = parser.parse_args()
    if args.test or args.brain:
        play_test(use_brain=args.brain)
    else:
        print("Run with --test for standalone mode, or --brain for the real connectome.")
        print("Prepare brain data with: python -m flybrain download")
