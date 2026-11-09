"""The shop: spend coins on upgrades, or sell them back for exactly what they cost."""

import pygame

from app.progression.upgrades import UPGRADES, Upgrade, effect_text
from app.render.icons import draw_icon
from app.render.shapes import draw_glow, draw_panel
from app.render.text import draw_hint_row, draw_text, text_size
from app.scenes.base import Scene, card_rect, dim, draw_card
from app.theme.palette import PALETTE
from app.theme.styles import PANEL_STYLES, RADIUS_MD, RADIUS_SM
from app.ui.widgets import Button, ButtonGroup, play_ui_sound
from app.util.mathx import lerp_color

PANEL_SIZE = (980, 700)
PAD = 32
ROW_W, ROW_H, ROW_GAP, COLUMN_GAP = 448, 108, 12, 20
ROWS_TOP = 108          # px below the panel's top
MESSAGE_TIME = 2.5      # s a "Bought ..." message stays
CONFIRM_TIME = 3.0      # s to click "Refund all" a second time
STEP = 30               # px; the - and + buttons


def describe(upgrade: Upgrade, width: int) -> str:
    """The row's description on one line: what it does and what a level adds, or just the second part
    if both don't fit."""
    per_level = (f"{upgrade.effect.format(upgrade.step)} per level" if upgrade.effect
                 else f"-{upgrade.step:g} s recharge per extra level")
    full = f"{upgrade.summary} {per_level[0].upper()}{per_level[1:]}."
    return full if text_size(full, "small")[0] <= width else per_level[0].upper() + per_level[1:] + "."


class UpgradeCard(Button):
    """One upgrade: a click buys (or sells, on the - button), a right click sells. Enter buys too;
    the shop adds + / - and Del for the focused card."""

    def __init__(self, upgrade: Upgrade, shop: "ShopScene") -> None:
        super().__init__(upgrade.name, lambda: shop.buy(upgrade), size=(ROW_W, ROW_H))
        self.upgrade = upgrade
        self.shop = shop

    @property
    def minus_rect(self) -> pygame.Rect:
        return self.plus_rect.move(-(STEP + 8), 0)

    @property
    def plus_rect(self) -> pygame.Rect:
        rect = pygame.Rect(0, 0, STEP, STEP)
        rect.midright = (self.rect.right - 14, self.rect.bottom - 24)
        return rect

    def activate(self) -> None:
        self.shop.buy(self.upgrade)

    def click(self, pos) -> None:
        if self.minus_rect.collidepoint(pos):
            self.shop.sell(self.upgrade)
        else:
            self.shop.buy(self.upgrade)

    def right_click(self, pos) -> None:
        self.shop.sell(self.upgrade)

    def draw(self, surface: pygame.Surface) -> None:
        profile = self.shop.game.profile
        u = self.upgrade
        level, price = profile.level(u.id), profile.cost(u.id)
        maxed = price is None
        color = getattr(PALETTE, u.color_name)
        h = self.highlight
        r = self.rect.move(0, 2) if self.pressed else self.rect
        draw_panel(surface, r, "button")
        if maxed:
            border = lerp_color(PALETTE.success, PALETTE.panel_bottom, 0.45)
        else:
            border = lerp_color(PALETTE.line, PALETTE.accent, h)
        pygame.draw.rect(surface, border, r, 2 if h > 0.5 else 1, border_radius=PANEL_STYLES["button"].radius)

        # Icon tile; it glows once owned.
        tile = pygame.Rect(r.x + 14, r.y + 14, 60, 60)
        pygame.draw.rect(surface, PALETTE.panel_bottom, tile, border_radius=RADIUS_MD)
        pygame.draw.rect(surface, lerp_color(PALETTE.border, color, 0.4 + 0.6 * h), tile, 1, border_radius=RADIUS_MD)
        if level:
            draw_glow(surface, color, tile.center, 30, int(70 + 50 * h))
        dim_icon = level == 0 and h < 0.3
        draw_icon(surface, u.icon, tile.center, 32, lerp_color(color, PALETTE.text_faint, 0.5) if dim_icon else color)

        tx = tile.right + 14
        draw_text(surface, u.name, "button", PALETTE.text, shadow=True, topleft=(tx, r.y + 12))
        # Price, top right: red when you can't afford it yet.
        if maxed:
            draw_text(surface, "MAXED", "label", PALETTE.success, topright=(r.right - 16, r.y + 15))
        else:
            price_color = PALETTE.coin if profile.coins >= price else PALETTE.danger
            price_rect = draw_text(surface, f"{price:,}", "button", price_color, topright=(r.right - 16, r.y + 12))
            draw_icon(surface, "coin", (price_rect.left - 11, price_rect.centery), 14, PALETTE.coin)
        draw_text(surface, describe(u, r.right - 16 - tx), "small", PALETTE.text_dim, topleft=(tx, r.y + 38))

        # Bottom row: level pips, "Lv 2/5", then what the next level gives (or the total, once maxed).
        cy = r.bottom - 24
        for i in range(u.max_level):
            pip = pygame.Rect(tx + i * 14, cy - 5, 10, 10)
            if i < level:
                pygame.draw.rect(surface, PALETTE.coin, pip, border_radius=3)
            else:
                pygame.draw.rect(surface, PALETTE.line, pip, 1, border_radius=3)
        x = tx + u.max_level * 14 + 8
        end = self.minus_rect.left - 8                     # everything must fit before the - button
        if maxed:
            text, color = effect_text(u, level), PALETTE.text_dim
        else:
            text, color = f"Next: {effect_text(u, level + 1)}", PALETTE.success
        level_text = f"Lv {level}/{u.max_level}"
        with_level = text_size(level_text, "tiny")[0] + 10 + text_size(text, "tiny")[0]
        if x + with_level <= end:                           # "Lv 2/5   Next: ..."
            lv = draw_text(surface, level_text, "tiny", PALETTE.text_faint, midleft=(x, cy))
            draw_text(surface, text, "tiny", color, midleft=(lv.right + 10, cy))
        elif x + text_size(text, "tiny")[0] <= end:         # no room for both: the pips already show the level
            draw_text(surface, text, "tiny", color, midleft=(x, cy))
        else:
            draw_text(surface, level_text, "tiny", PALETTE.text_faint, midleft=(x, cy))
        self._draw_step(surface, self.minus_rect, "-", level > 0)
        self._draw_step(surface, self.plus_rect, "+", not maxed and profile.coins >= price)

    @staticmethod
    def _draw_step(surface: pygame.Surface, rect: pygame.Rect, text: str, enabled: bool) -> None:
        hovered = enabled and rect.collidepoint(pygame.mouse.get_pos())
        background = PALETTE.panel_top if hovered else PALETTE.panel_bottom
        border = PALETTE.accent if hovered else (PALETTE.line if enabled else PALETTE.border)
        pygame.draw.rect(surface, background, rect, border_radius=RADIUS_SM)
        pygame.draw.rect(surface, border, rect, 1, border_radius=RADIUS_SM)
        draw_text(surface, text, "button", PALETTE.text if enabled else PALETTE.text_faint, center=rect.center)


class ShopScene(Scene):
    """Upgrade rows in two columns. ``back`` is the scene to return to (main menu or game over)."""

    def __init__(self, game, back: Scene) -> None:
        super().__init__(game)
        self.back = back
        self.message = ""
        self.message_color = PALETTE.text
        self.message_timer = 0.0
        self.confirm_timer = 0.0
        self.panel = card_rect(*PANEL_SIZE)
        p = self.panel

        self.cards: list[UpgradeCard] = []
        for i, upgrade in enumerate(UPGRADES):
            card = UpgradeCard(upgrade, self)
            column, row = i % 2, i // 2
            card.rect.topleft = (p.x + PAD + column * (ROW_W + COLUMN_GAP), p.y + ROWS_TOP + row * (ROW_H + ROW_GAP))
            self.cards.append(card)
        self.refund_all = Button(lambda: "Click again to confirm" if self.confirm_timer > 0 else "Refund all",
                                 self.refund_everything, icon="coin", size=(250, 46), variant="danger")
        self.refund_all.rect.bottomleft = (p.x + PAD, p.bottom - 24)
        back_button = Button("Back", self.go_back, hotkey="escape", primary=True, sound="back", size=(200, 46))
        back_button.rect.bottomright = (p.right - PAD, p.bottom - 24)
        self.group = ButtonGroup([*self.cards, self.refund_all, back_button])

    # --- Buying and selling --------------------------------------------------------------------------
    def buy(self, upgrade: Upgrade) -> None:
        profile = self.game.profile
        price = profile.cost(upgrade.id)
        if price is None:
            self.say(f"{upgrade.name} is already maxed.", PALETTE.text_dim)
            play_ui_sound("error")
        elif profile.buy(upgrade.id):
            self.say(f"Bought {upgrade.name}  -  level {profile.level(upgrade.id)}", PALETTE.success)
            play_ui_sound("buy")
        else:
            self.say(f"Not enough coins  -  {price - profile.coins} more needed", PALETTE.danger)
            play_ui_sound("error")

    def sell(self, upgrade: Upgrade) -> None:
        refund = self.game.profile.sell(upgrade.id)
        if refund is None:
            self.say(f"{upgrade.name} is already at level 0.", PALETTE.text_dim)
            play_ui_sound("error")
        else:
            self.say(f"Sold a level of {upgrade.name}  -  +{refund} coins", PALETTE.coin)
            play_ui_sound("sell")

    def refund_everything(self) -> None:
        if self.confirm_timer <= 0:
            self.confirm_timer = CONFIRM_TIME
            return
        self.confirm_timer = 0
        total = self.game.profile.sell_all()
        self.say(f"Refunded {total} coins" if total else "Nothing to refund", PALETTE.coin)

    def say(self, text: str, color) -> None:
        self.message, self.message_color, self.message_timer = text, color, MESSAGE_TIME

    def go_back(self) -> None:
        self.game.scene = self.back

    # --- Scene -------------------------------------------------------------------------------------
    def handle_event(self, event: pygame.event.Event) -> None:
        focused = self.group.buttons[self.group.focus]
        if event.type == pygame.KEYDOWN and isinstance(focused, UpgradeCard):
            if event.key in (pygame.K_PLUS, pygame.K_EQUALS, pygame.K_KP_PLUS):
                self.buy(focused.upgrade)
                return
            if event.key in (pygame.K_MINUS, pygame.K_KP_MINUS, pygame.K_DELETE, pygame.K_BACKSPACE):
                self.sell(focused.upgrade)
                return
        self.group.handle_event(event)

    def update(self, dt: float) -> None:
        self.refund_all.enabled = any(self.game.profile.levels.values())
        self.message_timer = max(0.0, self.message_timer - dt)
        self.confirm_timer = max(0.0, self.confirm_timer - dt)
        self.group.update(dt)

    def draw(self, surface: pygame.Surface) -> None:
        surface.fill(PALETTE.background)
        surface.blit(self.game.background, (0, 0))
        dim(surface, 120)
        p = self.panel
        draw_card(surface, p)
        draw_text(surface, "SHOP", "heading", PALETTE.text, shadow=True, topleft=(p.x + PAD, p.y + 22))
        draw_text(surface, "Permanent upgrades for every run. Sell any level for a full refund.", "small",
                  PALETTE.text_dim, topleft=(p.x + PAD + 2, p.y + 72))
        self.draw_wallet(surface)
        self.group.draw(surface)
        draw_hint_row(surface, [(["ENTER", "+"], "Buy"), (["DEL", "-"], "Sell"), (["ESC"], "Back")],
                      p.centerx, p.bottom - 57, align="center")
        if self.message_timer > 0:
            color = lerp_color(PALETTE.panel_bottom, self.message_color, min(1.0, self.message_timer / 0.4))
            draw_text(surface, self.message, "button", color, shadow=True, center=(p.centerx, p.bottom - 88))

    def draw_wallet(self, surface: pygame.Surface) -> None:
        coins = f"{self.game.profile.coins:,}"
        chip = pygame.Rect(0, 0, text_size(coins, "timer")[0] + 64, 46)
        chip.topright = (self.panel.right - PAD, self.panel.y + 26)
        draw_panel(surface, chip, "chip")
        draw_icon(surface, "coin", (chip.x + 24, chip.centery), 22, PALETTE.coin)
        draw_text(surface, coins, "timer", PALETTE.coin, shadow=True, midleft=(chip.x + 44, chip.centery))
