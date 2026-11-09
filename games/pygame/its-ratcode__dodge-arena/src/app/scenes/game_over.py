"""The game over scene: what the run was worth, and what to do next."""

import math

import pygame

from app import config
from app.entities.laser import Laser
from app.render.icons import draw_icon
from app.render.text import draw_glowing_text, draw_text
from app.scenes.base import Scene, card_rect, dim, draw_card, draw_stat_tile, ease_out
from app.theme.accessibility import A11Y, wobble
from app.theme.palette import PALETTE, danger_color
from app.theme.styles import CARD_PAD
from app.ui.widgets import Button, ButtonGroup
from app.util.mathx import lerp_color
from app.util.timefmt import fmt_time

CARD_DELAY = config.DEATH_SEQUENCE_TIME     # s of slow-motion death beat before the card appears
CARD_SLIDE = 0.3        # s for the card to slide into place
CARD_SIZE = (760, 430)
COUNT_UP = 0.9          # s for the coins tile to count up to its total
TILE_W, TILE_H, TILE_GAP = 164, 100, 14
BUTTON_ROW = ((230, "Play again"), (190, "Shop"), (230, "Main menu"))     # widths, left to right
BUTTON_ROW_GAP = 16


class GameOverScene(Scene):
    """First a short slow-motion beat with pulsing red edges, then the card.
    Input is ignored until the card is in place, so keys mashed while dying
    can't skip it by accident."""

    music = "ducked"

    def __init__(self, game) -> None:
        super().__init__(game)
        self.age = 0.0
        self.danger_at_death = game.world.danger
        buttons = [
            Button("Play again", game.start_run, hotkey=lambda: game.settings.keybinds["restart"], primary=True,
                   icon="play", size=(BUTTON_ROW[0][0], 50)),
            Button("Shop", game.open_shop, hotkey="s", icon="coin", size=(BUTTON_ROW[1][0], 50)),
            Button("Main menu", game.open_main_menu, hotkey="escape", icon="exit", size=(BUTTON_ROW[2][0], 50)),
        ]
        self.buttons = ButtonGroup(buttons)

    @property
    def shown(self) -> float:
        """0 -> 1 as the card slides in."""
        return ease_out((self.age - CARD_DELAY) / CARD_SLIDE)

    def card(self) -> pygame.Rect:
        slide = wobble(30 * (1 - self.shown))             # with reduced motion it only fades in
        return card_rect(*CARD_SIZE, offset_y=round(slide))

    def layout_buttons(self, card: pygame.Rect) -> None:
        """One row along the bottom of the card, centered."""
        total = sum(w for w, _ in BUTTON_ROW) + BUTTON_ROW_GAP * (len(BUTTON_ROW) - 1)
        x = card.centerx - total // 2
        for button in self.buttons.buttons:
            button.rect.bottomleft = (x, card.bottom - CARD_PAD)
            x = button.rect.right + BUTTON_ROW_GAP

    def handle_event(self, event: pygame.event.Event) -> None:
        if self.shown >= 1:
            self.buttons.handle_event(event)

    def update(self, dt: float) -> None:
        if self.age < CARD_DELAY <= self.age + dt and self.game.result and self.game.result.new_best:
            self.game.audio.play("new_best")               # a fanfare as the card arrives
        if self.age < CARD_DELAY:
            self.game.world.update_aftermath(dt * config.DEATH_SLOWMO)     # threats drift on in slow motion
        self.age += dt
        self.layout_buttons(self.card())
        self.buttons.update(dt)

    def draw(self, surface: pygame.Surface) -> None:
        self.game.draw_world(surface)
        # Red edges: pulsing during the death beat (steady with reduced flashing), then calm.
        if self.age < CARD_DELAY:
            pulse = 0.5 if A11Y.reduce_flashing else 0.5 + 0.5 * math.sin(self.age * 18)
            self.game.red_vignette.set_alpha(int(150 + 100 * pulse))
        else:
            self.game.red_vignette.set_alpha(110)
        surface.blit(self.game.red_vignette, (0, 0))
        dim(surface, round(170 * self.shown))
        if self.shown <= 0:
            return
        world, result, profile = self.game.world, self.game.result, self.game.profile
        card = self.card()
        draw_card(surface, card)
        cx = card.centerx
        title = draw_glowing_text(surface, "GAME OVER", "title", PALETTE.danger, midtop=(cx, card.top + 14))
        if world.killer is not None:
            what = "a laser" if isinstance(world.killer, Laser) else "a bolt"
            cause = f"Hit by {what} at {fmt_time(world.survival_time)}"
        else:
            cause = f"Run ended at {fmt_time(world.survival_time)}"
        calls = world.close_calls
        cause += f"   |   {calls} close call{'' if calls == 1 else 's'}"
        draw_text(surface, cause, "body", PALETTE.text_dim, midtop=(cx, title.bottom - 4))

        if result.new_best:
            # A ribbon that gently pulses (steady with reduced flashing).
            pulse = 0.5 if A11Y.reduce_flashing else 0.5 + 0.5 * math.sin(self.age * 5)
            ribbon = pygame.Rect(0, 0, 230, 28)
            ribbon.midtop = (cx, title.bottom + 24)
            pygame.draw.rect(surface, lerp_color(PALETTE.warning, PALETTE.coin_shine, pulse * 0.6), ribbon,
                             border_radius=14)
            draw_text(surface, "NEW PERSONAL BEST", "label", PALETTE.panel_bottom, center=ribbon.center)
        elif not result.counted:
            draw_text(surface, "Assists were on (Settings > Gameplay): best time not recorded", "small",
                      PALETTE.text_faint, midtop=(cx, title.bottom + 28))

        # Four tiles; the coins count up.
        shown_coins = round(result.coins * ease_out((self.age - CARD_DELAY - 0.25) / COUNT_UP))
        tiles = (("SURVIVED", fmt_time(world.survival_time), PALETTE.text, None),
                 ("BEST", fmt_time(profile.best_time), PALETTE.warning if result.new_best else PALETTE.text, None),
                 ("COINS EARNED", f"+{shown_coins}", PALETTE.coin,
                  f"{result.picked_up} picked  +  {result.bonus} bonus"),
                 ("DANGER", f"{int(self.danger_at_death * 100)}%", danger_color(self.danger_at_death), None))
        x = cx - (TILE_W * 4 + TILE_GAP * 3) // 2
        y = card.top + 176
        for label, value, color, note in tiles:
            draw_stat_tile(surface, pygame.Rect(x, y, TILE_W, TILE_H), label, value, color, "timer", note)
            x += TILE_W + TILE_GAP
        wallet = draw_text(surface, f"Wallet  {profile.coins:,}", "button", PALETTE.text_dim,
                           midtop=(cx + 12, y + TILE_H + 18))
        draw_icon(surface, "coin", (wallet.left - 14, wallet.centery), 16, PALETTE.coin)
        self.buttons.draw(surface)
