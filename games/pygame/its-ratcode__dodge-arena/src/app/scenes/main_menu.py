"""The main menu: title and buttons on the left, your profile on the right."""

import random

import pygame
from pygame.math import Vector2

from app import config
from app.entities.bolt import Bolt
from app.meta import APP_NAME, VERSION
from app.progression.upgrades import UPGRADES, second_wind_cooldown
from app.render.icons import draw_icon
from app.render.shapes import draw_glow, draw_panel
from app.render.text import (draw_hint_row, draw_spaced, draw_text, line_height, render_glow, render_gradient,
                             wrap_text)
from app.scenes.base import Scene, dim
from app.theme.accessibility import A11Y
from app.theme.palette import PALETTE
from app.theme.styles import BUTTON_WIDTH
from app.ui.guide_content import tips
from app.ui.widgets import Button, ButtonList
from app.util.mathx import lerp_color
from app.util.timefmt import fmt_time

DEMO_BOLT_INTERVAL = 0.45      # s between decorative bolts crossing the background
DEMO_BOLT_SPEED = 260          # px/s
LEFT = 96                      # px; the left column (title, buttons, hints)
CARD = pygame.Rect(config.SCREEN_WIDTH - 96 - 380, 200, 380, 350)     # the profile card


class MainMenuScene(Scene):
    """Harmless bolts drift across the arena behind the menu to show what the game is about."""

    def __init__(self, game) -> None:
        super().__init__(game)
        self.age = 0.0
        self.bolts: list[Bolt] = []
        self.bolt_timer = 0.0
        self.tip = random.choice(tips(game.settings))
        self.buttons = ButtonList([
            Button("Play", game.start_run, primary=True, icon="play"),
            Button("How to play", game.open_guide, hotkey="h", icon="book"),
            Button("Shop", game.open_shop, hotkey="s", icon="coin"),
            Button("Settings", game.open_settings, icon="gear"),
            Button("Quit", game.quit, hotkey="escape", icon="exit"),
        ], center=(LEFT + BUTTON_WIDTH // 2, 474))

    def handle_event(self, event: pygame.event.Event) -> None:
        self.buttons.handle_event(event)

    def update(self, dt: float) -> None:
        self.age += dt
        self.buttons.update(dt)
        self.bolt_timer -= dt
        if A11Y.reduced_motion:
            self.bolts.clear()                         # no decorative movement behind the menu
        elif self.bolt_timer <= 0:
            self.bolt_timer += DEMO_BOLT_INTERVAL
            self.bolts.append(self.demo_bolt())
        for bolt in self.bolts:
            bolt.update(dt)
        self.bolts = [b for b in self.bolts if not b.is_off_screen()]

    @staticmethod
    def demo_bolt() -> Bolt:
        """A slow bolt from a random edge toward a random point in the arena."""
        w, h = config.SCREEN_WIDTH, config.SCREEN_HEIGHT
        edge = random.choice(((random.uniform(0, w), -40), (random.uniform(0, w), h + 40),
                              (-40, random.uniform(0, h)), (w + 40, random.uniform(0, h))))
        target = Vector2(random.uniform(w * 0.2, w * 0.8), random.uniform(h * 0.2, h * 0.8))
        return Bolt(edge, target, DEMO_BOLT_SPEED)

    def draw(self, surface: pygame.Surface) -> None:
        surface.fill(PALETTE.background)
        surface.blit(self.game.background, (0, 0))
        for bolt in self.bolts:
            bolt.draw(surface)
        dim(surface, 140)

        draw_glow(surface, PALETTE.accent, (LEFT + 150, 160), 230, 40)
        bottom = self.draw_logo(surface)
        pygame.draw.rect(surface, PALETTE.accent, (LEFT + 4, bottom + 10, 64, 3), border_radius=2)
        draw_text(surface, "Dodge the bolts. Outlast the lasers. Survive.", "small", PALETTE.text_dim,
                  topleft=(LEFT + 4, bottom + 22))
        self.buttons.draw(surface)
        self.draw_profile(surface)

        draw_hint_row(surface, [(["ARROWS"], "Navigate"), (["ENTER"], "Select"), (["ESC"], "Quit")],
                      LEFT, config.SCREEN_HEIGHT - 44)
        draw_text(surface, f"v{VERSION}", "tiny", PALETTE.text_faint,
                  bottomright=(config.SCREEN_WIDTH - 24, config.SCREEN_HEIGHT - 20))

    @staticmethod
    def draw_logo(surface: pygame.Surface) -> int:
        """The game's name: the first word big, with a gradient and a glow, the rest letter-spaced under it.
        Returns the y of its bottom edge."""
        first, _, rest = APP_NAME.upper().partition(" ")
        # White fading to ice: lighter than the cyan buttons, so the name stands on its own.
        logo = render_gradient(first, "logo", PALETTE.text, lerp_color(PALETTE.accent, PALETTE.text, 0.45))
        shadow = render_gradient(first, "logo", PALETTE.key_shadow, PALETTE.key_shadow)
        glow = render_glow(first, "logo", PALETTE.accent)
        rect = logo.get_rect(topleft=(LEFT - 4, 86))
        glow.set_alpha(120)
        surface.blit(glow, glow.get_rect(center=rect.center))
        surface.blit(shadow, rect.move(3, 4))
        surface.blit(logo, rect)
        if not rest:
            return rect.bottom
        return draw_spaced(surface, rest, "timer", PALETTE.accent, 14, topleft=(LEFT + 2, rect.bottom - 8)).bottom

    def draw_profile(self, surface: pygame.Surface) -> None:
        """Coins, best time, upgrades owned, Second Wind, and a tip."""
        profile = self.game.profile
        draw_panel(surface, CARD, "frame")
        draw_spaced(surface, "PROFILE", "label", PALETTE.accent, 4, topleft=(CARD.x + 26, CARD.y + 24))
        owned = sum(profile.levels.values())
        total = sum(u.max_level for u in UPGRADES)
        wind = second_wind_cooldown(profile.level("second_wind"))
        rows = (
            ("coin", PALETTE.coin, "Coins", f"{profile.coins:,}", PALETTE.coin),
            ("time_warp", PALETTE.accent, "Best survival",
             fmt_time(profile.best_time) if profile.best_time > 0 else "--", PALETTE.text),
            ("boots", PALETTE.player, "Upgrades", f"{owned} / {total}", PALETTE.text),
            ("second_wind", PALETTE.second_wind, "Second Wind",
             "Locked" if wind is None else f"{wind:g} s recharge",
             PALETTE.text_faint if wind is None else PALETTE.second_wind),
        )
        y = CARD.y + 56
        for icon, icon_color, label, value, value_color in rows:
            draw_icon(surface, icon, (CARD.x + 40, y + 18), 22, icon_color)
            draw_text(surface, label, "body", PALETTE.text_dim, midleft=(CARD.x + 64, y + 18))
            draw_text(surface, value, "button", value_color, midright=(CARD.right - 26, y + 18))
            pygame.draw.line(surface, PALETTE.border, (CARD.x + 24, y + 40), (CARD.right - 24, y + 40))
            y += 48
        draw_spaced(surface, "TIP", "label", PALETTE.accent, 4, topleft=(CARD.x + 26, y + 14))
        step = line_height("small")
        for i, line in enumerate(wrap_text(self.tip, "small", CARD.width - 52)[:3]):
            draw_text(surface, line, "small", PALETTE.text_dim, topleft=(CARD.x + 26, y + 34 + i * step))
