"""Gameplay screen: highway, input, HUD, boost meter, round end."""

from __future__ import annotations

import pygame

from ..core.scene import Scene
from ..engine.rhythm import RhythmEngine
from ..ui import theme
from ..ui.highway import HW, HIT_Y, HighwayView, key_labels

POPUP_LIFE = 0.55
END_LINGER = 1.6


class PlayScene(Scene):
    def __init__(self, game, level):
        super().__init__(game)
        self.level = level
        self._frozen_pos = None      # set once the level end is reached
        self.engine = RhythmEngine(level.notes, self._clock)
        self.highway = HighwayView()
        self.popups = []          # [text, color, life]
        self.error = None
        self._end_timer = 0.0

        try:
            game.audio.play(level.audio_path)
        except pygame.error as exc:
            self.error = f"Could not play audio: {exc}"

    def _clock(self) -> float:
        """Song clock; freezes at the level end so notes stop moving."""
        if self._frozen_pos is not None:
            return self._frozen_pos
        return self.game.audio.position_ms()

    # ------------------------------------------------------------- input
    def _lane_map(self) -> dict:
        mapping = {}
        for i in range(4):
            key = self.game.config.lane_key(i)
            if key is not None:
                mapping[key] = i
        return mapping

    def handle_event(self, event) -> None:
        if self.error:
            if event.type in (pygame.KEYDOWN, pygame.MOUSEBUTTONDOWN):
                self._to_list()
            return

        if event.type == pygame.KEYDOWN:
            cfg = self.game.config
            if event.key == cfg.key("cancel"):
                self._to_list()
                return
            lanes = self._lane_map()
            if event.key in lanes:
                self.engine.press_lane(lanes[event.key])
            elif event.key == cfg.key("boost"):
                self.engine.press_boost()
        elif event.type == pygame.KEYUP:
            lanes = self._lane_map()
            if event.key in lanes:
                self.engine.release_lane(lanes[event.key])

    def _to_list(self) -> None:
        self.game.audio.stop()
        from .play_list import PlayListScene
        self.game.scenes.change(PlayListScene(self.game))

    # ------------------------------------------------------------ update
    def update(self, dt: float) -> None:
        if self.error:
            self._end_timer += dt
            if self._end_timer > 3.0:
                self._to_list()
            return

        self.engine.update(dt)
        self._dt = dt

        for judgment in self.engine.pop_judgments():
            color = theme.RATING_COLORS[judgment.rating]
            text = judgment.rating.upper()
            if judgment.rating != "miss" and judgment.offset is not None:
                ms = abs(judgment.offset)
                text = f"{text}  {ms:.0f}ms"
            self.popups.append([text, color, POPUP_LIFE])
            self.highway.hit_effect(judgment.lane, judgment.rating)

        for popup in self.popups:
            popup[2] -= dt
        self.popups = [p for p in self.popups if p[2] > 0]

        if self._frozen_pos is None:
            pos = self._clock()
            reached_end = (self.level.end is not None
                           and pos >= self.level.end)
            if reached_end or self.game.audio.finished:
                self._frozen_pos = pos
                self.game.audio.stop()
                # release any keys still held: the round is over, so no
                # further sustain points should accrue during the linger
                for lane in range(4):
                    if self.engine.lane_states[lane]:
                        self.engine.release_lane(lane)
        else:
            self._end_timer += dt
            if self._end_timer >= END_LINGER:
                self._finish()

    def _finish(self) -> None:
        summary = self.engine.summary()
        from .results import ResultsScene
        self.game.scenes.change(ResultsScene(self.game, self.level, summary))

    # -------------------------------------------------------------- draw
    def draw(self, surface) -> None:
        if self.error:
            theme.title_text(surface, "AUDIO ERROR", theme.BASE_W // 2, 240, 36,
                             glow=theme.MAGENTA)
            theme.draw_text(surface, self.error, theme.BASE_W // 2, 320, 18,
                            color=theme.RED, align="center")
            return

        song_pos = self._clock()
        cfg = self.game.config
        self.highway.draw(surface, song_pos, self.engine.notes,
                          lane_down=self.engine.lane_states,
                          labels=key_labels(cfg), dt=getattr(self, "_dt", 0.0))

        self._draw_hud(surface, song_pos)
        self._draw_boost(surface)
        self._draw_popups(surface)

        theme.draw_text(surface, self.level.name, HW.centerx, 14, size=18,
                        color=theme.LAVENDER, align="center",
                        glow=theme.VIOLET)
        theme.draw_text(surface,
                        f"{cfg.label('cancel')} = quit to menu",
                        theme.BASE_W - 24, 16,
                        size=14, color=theme.DIM, align="right")

    @property
    def accuracy(self) -> float:
        c = self.engine.counts
        total = sum(c.values())
        if not total:
            return 100.0
        got = c["perfect"] + c["great"] * 0.75 + c["good"] * 0.5
        return 100.0 * got / total

    def _draw_hud(self, surface, song_pos) -> None:
        # score / combo card (same spot as before, neon restyle)
        box = pygame.Rect(180, HIT_Y - 34, 175, 68)
        theme.panel(surface, box, fill=theme.PANEL, border=theme.CYAN,
                    radius=10, glow=theme.VIOLET)
        e = self.engine
        theme.draw_text(surface, f"{e.score_display:,}", box.x + 12, box.y + 8,
                        size=26, color=theme.WHITE, glow=theme.VIOLET)
        theme.draw_text(surface, f"x{e.combo}", box.right - 12, box.y + 8,
                        size=26, color=theme.CYAN, align="right",
                        glow=theme.MAGENTA)
        theme.draw_text(surface, "SCORE", box.x + 14, box.y + 44, size=12,
                        color=theme.DIM)
        theme.draw_text(surface, "COMBO", box.right - 14, box.y + 44, size=12,
                        color=theme.DIM, align="right")
        theme.draw_text(surface, f"ACC {self.accuracy:.1f}%",
                        box.x + 2, box.bottom + 8, size=18,
                        color=theme.LAVENDER, glow=theme.VIOLET)

        # song progress bar above the highway
        bar = pygame.Rect(HW.x, 40, HW.w, 7)
        theme.panel(surface, bar, fill=(14, 10, 34), border=theme.BORDER,
                    radius=4, width=1)
        total = self.level.end or 0
        frac = 1.0 if not total else max(0.0, min(1.0, song_pos / total))
        if frac > 0:
            fill = pygame.Rect(bar.x + 1, bar.y + 1,
                               int((bar.w - 2) * frac), bar.h - 2)
            theme.alpha_rect(surface, fill, theme.CYAN, 235, radius=4)
            head = pygame.Rect(fill.right - 3, bar.y - 4, 6, bar.h + 8)
            theme.glow_rect(surface, head, theme.WHITE, radius=3, intensity=90)
        if total:
            cur, tgt = divmod(int(song_pos // 1000), int(total // 1000) or 1)
            theme.draw_text(surface, f"{cur // 60:02d}:{cur % 60:02d} / "
                                     f"{tgt // 60:02d}:{tgt % 60:02d}",
                            bar.right, bar.y + 12, size=13,
                            color=theme.DIM, align="right")

    def _draw_boost(self, surface) -> None:
        """Vertical neon boost meter along the right edge of the highway."""
        e = self.engine
        meter = pygame.Rect(HW.right + 18, HW.y, 26, HW.h)
        theme.panel(surface, meter, fill=(13, 9, 30), border=theme.BORDER,
                    radius=12, glow=theme.MAGENTA if e.boost_active else None)

        frac = e.boost_charge / 100.0
        if frac > 0:
            fh = max(4, int((meter.h - 8) * frac))
            color = theme.MAGENTA if e.boost_active else theme.CYAN
            fill = pygame.Rect(meter.x + 4, meter.bottom - 4 - fh,
                               meter.w - 8, fh)
            theme.alpha_rect(surface, fill.inflate(8, 4), color, 70, radius=10)
            theme.alpha_rect(surface, fill, color, 240, radius=8)
            # segment ticks
            for k in range(1, 4):
                y = meter.bottom - int((meter.h - 8) * k / 4)
                pygame.draw.line(surface, (18, 12, 40),
                                 (meter.x + 4, y), (meter.right - 4, y), 2)

        if e.boost_active:
            theme.draw_text(surface, "2X", meter.centerx, meter.y - 24,
                            size=20, color=theme.WHITE, align="center",
                            glow=theme.MAGENTA)

        theme.draw_text(surface, "BOOST", meter.centerx, meter.bottom + 8,
                        size=14, color=theme.MAGENTA if e.boost_active
                        else theme.DIM, align="center")
        theme.draw_text(surface, self.game.config.label("boost"),
                        meter.centerx, meter.bottom + 28, size=13,
                        color=theme.DIM, align="center")

    def _draw_popups(self, surface) -> None:
        if not self.popups:
            return
        text, color, life = max(self.popups, key=lambda p: p[2])
        is_miss = "MISS" in text
        size = 44 if is_miss else 36
        alpha = int(255 * min(1.0, life / POPUP_LIFE * 1.6))
        f = theme.font(size)
        img = f.render(text, True, color)
        img.set_alpha(alpha)
        rect = img.get_rect(midbottom=(HW.centerx, HIT_Y - 130))
        for dx, dy, tone, mul in ((-3, 0, color, 3), (3, 0, color, 3),
                                  (0, -3, color, 3), (0, 3, color, 3),
                                  (0, 0, theme.WHITE, 1)):
            halo = f.render(text, True, tone)
            halo.set_alpha(alpha // mul)
            surface.blit(halo, rect.move(dx, dy))
        surface.blit(img, rect)
