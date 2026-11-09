"""The in-game HUD.

Layout:
    top center      timer pill, danger bar, pop-up messages under it
    middle          "GET READY" / "GO!" at the start of a run
    top right       your coins plus this run's, best time under them
    top left        controls cheat-sheet and frame rate (each can be turned off)
    bottom center   ability bar (abilities | utility spells | power-up), key labels under the boxes
    left of bar     Second Wind if owned (ready, or recharging), then the active effects
                    (stasis, shield, sprint ...) with the time they have left
    right of bar    the held power-up's card: what it does, its key, and a bar of how long it keeps
"""

from __future__ import annotations

import math
from functools import lru_cache
from typing import TYPE_CHECKING

import pygame

from app import config
from app.render.icons import draw_icon
from app.render.shapes import (draw_bar, draw_cooldown_sweep, draw_glow, draw_panel,
                               draw_progress_ring)
from app.render.text import (HintRow, draw_hint_row, draw_keycap, draw_spaced, draw_text, ellipsize, get_font,
                             line_height, text_size, wrap_text)
from app.skills.loadout import SkillSlot
from app.theme.accessibility import A11Y, wobble
from app.theme.palette import PALETTE, danger_color
from app.theme.styles import (HUD_BAR_PAD, HUD_BUFF_RADIUS, HUD_GROUP_GAP, HUD_KEYCAP_SPACE, HUD_MARGIN,
                              HUD_SLOT, HUD_SLOT_GAP, PANEL_STYLES)
from app.util.mathx import Color, clamp, lerp_color
from app.util.timefmt import fmt_time

if TYPE_CHECKING:                       # the HUD only reads a World; it never creates one
    from app.core.world import World

TOAST_TOP = 104         # px; the first pop-up message sits just under the danger label


@lru_cache(maxsize=8)
def _banner(text: str, color: Color) -> pygame.Surface:
    """ "GET READY" / "GO!" rendered once (big text is slow to render every frame)."""
    return get_font("banner").render(text, True, color)


@lru_cache(maxsize=32)
def _toast_pill(text: str, color: Color, icon: str | None) -> pygame.Surface:
    """A message pill, built once per text and color; only its alpha changes while it shows."""
    width = text_size(text, "button")[0] + (56 if icon else 32)
    pill = pygame.Surface((width, 34), pygame.SRCALPHA)
    pygame.draw.rect(pill, (*PALETTE.panel_bottom, 235), pill.get_rect(), border_radius=17)
    pygame.draw.rect(pill, (*color, 255), pill.get_rect(), 1, border_radius=17)
    x = 16
    if icon:
        draw_icon(pill, icon, (x + 8, 17), 16, color)
        x += 26
    draw_text(pill, text, "button", PALETTE.text, midleft=(x, 17))
    return pill


class Hud:
    """Draws the HUD for a World. Holds no game state of its own."""

    def draw(self, surface: pygame.Surface, world: World, fps: float | None = None,
             hints: list[HintRow] | None = None, best_time: float = 0.0, wallet: int | None = None,
             mouse: tuple[int, int] | None = None) -> None:
        """``hints`` are the rows of the controls cheat-sheet (None = hidden); ``best_time`` shows under the
        coins; ``wallet`` is the coins saved before this run (None = show only this run's coins); ``mouse``
        shows a tooltip for the box under it (None = no tooltips, e.g. behind a menu)."""
        self.draw_timer(surface, world)
        self.draw_coins(surface, world, best_time, wallet)
        y = HUD_MARGIN + 4
        for row in hints or []:
            draw_hint_row(surface, row, HUD_MARGIN + 4, y)
            y += 28
        if fps is not None:
            draw_text(surface, f"{fps:.0f} FPS", "label", PALETTE.text_faint, shadow=True, topleft=(HUD_MARGIN + 4, y))
        slots = [*world.loadout, world.powerup_slot]
        groups = self.slot_groups(world)
        bar, rects = self.bar_layout(groups)
        draw_panel(surface, bar, "frame")
        for i, (slot, rect) in enumerate(zip(slots, rects)):
            if i and groups[i] != groups[i - 1]:
                x = rect.x - (HUD_GROUP_GAP + HUD_SLOT_GAP) // 2
                pygame.draw.line(surface, PALETTE.line, (x, rect.y + 8), (x, rect.bottom - 8))
            if slot.skill is None:
                self.draw_empty_slot(surface, slot, rect)
            else:
                self.draw_slot(surface, world, slot, rect)
        left = bar.left
        if world.second_wind:
            self.draw_second_wind(surface, world, bar)
            left -= 16 + HUD_BUFF_RADIUS * 2
        self.draw_buffs(surface, world, bar, left)
        if world.powerup_slot.skill:
            self.draw_held_powerup(surface, world, bar, bar.right)
        self.draw_toasts(surface, world)
        self.draw_intro(surface, world)
        if mouse is not None:
            hovered = self.hovered(world, slots, groups, rects, bar, mouse)
            if hovered:
                self.draw_tooltip(surface, world, *hovered, bar)

    # --- Tooltips -------------------------------------------------------------------------------
    GROUP_LABELS = ("ABILITY", "UTILITY SPELL", "POWER-UP")

    def hovered(self, world: World, slots, groups, rects, bar: pygame.Rect, mouse):
        """(skill, caption, anchor rect) for the box or badge under the mouse, or None."""
        for slot, group, rect in zip(slots, groups, rects):
            if rect.collidepoint(mouse) and slot.skill:
                return slot.skill, f"{self.GROUP_LABELS[group]}   {slot.key_label}", rect
        if world.second_wind:
            r = HUD_BUFF_RADIUS
            badge = pygame.Rect(0, 0, r * 2, r * 2)
            badge.center = (bar.left - 16 - r, bar.centery - 6)
            if badge.collidepoint(mouse):
                return world.second_wind, "PASSIVE", badge
        return None

    def draw_tooltip(self, surface: pygame.Surface, world: World, skill, caption: str, anchor: pygame.Rect,
                     bar: pygame.Rect) -> None:
        """Name, type and key, what it does with your real numbers, and its cooldown."""
        lines = wrap_text(skill.describe(world), "small", 268)
        if skill is world.powerup_slot.skill:
            footer = f"One use  -  expires in {world.powerup_hold:.0f} s"
        elif skill is world.second_wind:
            footer = f"Recharge {skill.cooldown:g} s" + ("  -  READY" if skill.ready else "")
        else:
            footer = f"Cooldown {skill.cooldown:g} s"
        step = line_height("small")
        tip = pygame.Rect(0, 0, 300, 64 + len(lines) * step + 36)
        tip.midbottom = (anchor.centerx, bar.top - 10)
        tip.x = max(10, min(config.SCREEN_WIDTH - tip.width - 10, tip.x))
        draw_panel(surface, tip, "card")
        pygame.draw.rect(surface, skill.color, (tip.x + 1, tip.y + 12, 3, 26), border_radius=2)
        draw_text(surface, skill.name, "button", skill.color, shadow=True, topleft=(tip.x + 16, tip.y + 12))
        draw_spaced(surface, caption, "tiny", PALETTE.text_faint, 2, topleft=(tip.x + 16, tip.y + 38))
        y = tip.y + 60
        for line in lines:
            draw_text(surface, line, "small", PALETTE.text_dim, topleft=(tip.x + 16, y))
            y += step
        pygame.draw.line(surface, PALETTE.border, (tip.x + 16, y + 6), (tip.right - 16, y + 6))
        draw_text(surface, footer, "label", PALETTE.accent, topleft=(tip.x + 16, y + 14))

    # --- Messages ------------------------------------------------------------------------------
    @staticmethod
    def draw_toasts(surface: pygame.Surface, world: World) -> None:
        """The newest three messages, stacked under the danger bar."""
        y = TOAST_TOP
        for toast in world.toasts[-3:]:
            pill = _toast_pill(toast.text, getattr(PALETTE, toast.color_name), toast.icon)
            pill.set_alpha(toast.alpha)
            surface.blit(pill, pill.get_rect(midtop=(config.SCREEN_WIDTH // 2, round(y + toast.slide))))
            y += 40

    @staticmethod
    def draw_intro(surface: pygame.Surface, world: World) -> None:
        """ "GET READY" for a moment at the start of a run, then "GO!"."""
        t = world.survival_time
        ready, go = config.INTRO_READY_TIME, config.INTRO_GO_TIME
        if t >= ready + go or world.over:
            return
        if t < ready:
            k = t / ready
            text, color, size = "GET READY", PALETTE.text, 1.0
            alpha = 255 * min(1.0, k * 4) * (1.0 if k < 0.8 else (1 - k) / 0.2)
        else:
            k = (t - ready) / go
            text, color = "GO!", PALETTE.accent
            size = 1.0 + wobble(0.3 * (1 - k))                    # a small pop, unless motion is reduced
            alpha = 255 * (1 - k)
        image = _banner(text, color)
        if size != 1.0:
            image = pygame.transform.smoothscale_by(image, size)
        image.set_alpha(int(alpha))
        surface.blit(image, image.get_rect(center=(config.SCREEN_WIDTH // 2, config.SCREEN_HEIGHT // 2 - 90)))

    # --- Timer and danger -----------------------------------------------------------------
    def draw_timer(self, surface: pygame.Surface, world: World) -> None:
        cx = config.SCREEN_WIDTH // 2
        pill = pygame.Rect(0, 0, 196, 44)
        pill.midtop = (cx, HUD_MARGIN)
        draw_panel(surface, pill, "chip")
        draw_text(surface, fmt_time(world.survival_time), "timer", PALETTE.text, shadow=True, center=pill.center)

        danger = world.danger
        color = danger_color(danger)
        if danger >= 1:
            # At max danger the bar pulses between red and white (a steady mix with reduced flashing).
            pulse = 0.0 if A11Y.reduce_flashing else math.sin(world.survival_time * 7)
            color = lerp_color(PALETTE.danger, PALETTE.text, 0.3 + 0.3 * pulse)
        bar = pygame.Rect(0, 0, pill.width, 6)
        bar.midtop = (cx, pill.bottom + 8)
        draw_bar(surface, bar, danger, color)
        label = "DANGER MAX" if danger >= 1 else f"DANGER {int(danger * 100)}%"
        draw_spaced(surface, label, "label", color, 2, midtop=(cx, bar.bottom + 5))

    def draw_coins(self, surface: pygame.Surface, world: World, best_time: float, wallet: int | None) -> None:
        """Your coins and, in green, what this run has added so far, with the best time to beat underneath."""
        main = f"{wallet:,}" if wallet is not None else str(world.coins_picked)
        gain = f"+{world.coins_picked}" if wallet is not None else ""
        width = 50 + text_size(main, "cooldown")[0] + (text_size(gain, "button")[0] + 10 if gain else 0)
        chip = pygame.Rect(0, 0, max(96, width), 36)
        chip.topright = (config.SCREEN_WIDTH - HUD_MARGIN, HUD_MARGIN)
        draw_panel(surface, chip, "chip")
        draw_icon(surface, "coin", (chip.x + 20, chip.centery), 20, PALETTE.coin)
        text = draw_text(surface, main, "cooldown", PALETTE.coin, shadow=True, midleft=(chip.x + 36, chip.centery))
        if gain:
            draw_text(surface, gain, "button", PALETTE.success, shadow=True, midleft=(text.right + 10, chip.centery))
        if best_time > 0:
            draw_text(surface, f"BEST {fmt_time(best_time)}", "label", PALETTE.text_faint, shadow=True,
                      topright=(chip.right - 4, chip.bottom + 6))

    def draw_held_powerup(self, surface: pygame.Surface, world: World, bar: pygame.Rect, left: int) -> None:
        """A card right of the bar for the held power-up: what it does, its key, and how long it keeps."""
        skill = world.powerup_slot.skill
        rect = pygame.Rect(left + 16, bar.y + 6, 0, bar.height - 12)
        rect.width = min(300, config.SCREEN_WIDTH - HUD_MARGIN - rect.x)
        draw_panel(surface, rect, "chip")
        pygame.draw.rect(surface, skill.color, (rect.x + 6, rect.y + 10, 3, rect.height - 20), border_radius=2)
        draw_icon(surface, skill.icon, (rect.x + 30, rect.y + 24), 24, skill.color)
        name = draw_text(surface, skill.name, "button", skill.color, shadow=True, midleft=(rect.x + 52, rect.y + 22))
        draw_keycap(surface, world.powerup_slot.key_label, midleft=(name.right + 10, name.centery))
        line = ellipsize(skill.summary, "tiny", rect.width - 64)
        draw_text(surface, line, "tiny", PALETTE.text_dim, topleft=(rect.x + 52, rect.y + 38))
        draw_bar(surface, pygame.Rect(rect.x + 52, rect.bottom - 12, rect.width - 66, 4),
                 world.powerup_hold / config.POWERUP_HOLD_TIME, skill.color)

    # --- Ability bar -----------------------------------------------------------------------
    @staticmethod
    def slot_groups(world: World) -> list[int]:
        """Group of each box, in bar order: 0 = abilities, 1 = utility spells, 2 = power-up."""
        return [1 if slot.skill.is_utility else 0 for slot in world.loadout] + [2]

    def bar_layout(self, groups: list[int]) -> tuple[pygame.Rect, list[pygame.Rect]]:
        """The frame around the bar and one rect per box, centered at the bottom.
        A wider gap separates the groups."""
        xs, x = [], 0
        for i in range(len(groups)):
            if i:
                x += HUD_SLOT_GAP + (HUD_GROUP_GAP if groups[i] != groups[i - 1] else 0)
            xs.append(x)
            x += HUD_SLOT
        bar = pygame.Rect(0, 0, x + HUD_BAR_PAD * 2, HUD_SLOT + HUD_BAR_PAD + HUD_KEYCAP_SPACE)
        bar.midbottom = (config.SCREEN_WIDTH // 2, config.SCREEN_HEIGHT - HUD_MARGIN)
        rects = [pygame.Rect(bar.x + HUD_BAR_PAD + sx, bar.y + HUD_BAR_PAD, HUD_SLOT, HUD_SLOT) for sx in xs]
        return bar, rects

    def draw_slot(self, surface: pygame.Surface, world: World, slot: SkillSlot, rect: pygame.Rect) -> None:
        skill = slot.skill
        radius = PANEL_STYLES["slot"].radius
        draw_panel(surface, rect, "slot")
        if skill.ready:
            draw_glow(surface, skill.color, rect.center, 26, 60)
            icon_color = skill.color
        else:
            icon_color = lerp_color(skill.color, PALETTE.text_faint, 0.65)
        draw_icon(surface, skill.icon, (rect.centerx, rect.centery - 2), 30, icon_color)

        if not skill.ready:
            draw_cooldown_sweep(surface, rect, skill.cooldown_fraction, radius)
            seconds = skill.remaining
            text = f"{math.ceil(seconds)}" if seconds >= 1 else f"{seconds:0.1f}"
            draw_text(surface, text, "cooldown", PALETTE.text, shadow=True, center=rect.center)

        # While the effect lasts: an outer outline and a draining strip along the bottom.
        active = clamp(skill.active_fraction(world), 0.0, 1.0)
        if active > 0:
            pygame.draw.rect(surface, lerp_color(skill.color, PALETTE.panel_bottom, 0.45), rect.inflate(6, 6), 2,
                             border_radius=radius + 3)
            pygame.draw.rect(surface, skill.color, (rect.x + 5, rect.bottom - 7, round((rect.width - 10) * active), 3),
                             border_radius=2)

        pygame.draw.rect(surface, skill.color if skill.ready else PALETTE.line, rect,
                         2 if skill.ready else 1, border_radius=radius)
        if skill.ready_flash > 0:
            # Just came off cooldown: a bright outline grows out and fades.
            f = skill.ready_flash
            grow = int(10 * (1 - f))
            pygame.draw.rect(surface, lerp_color(PALETTE.panel_bottom, PALETTE.text, f),
                             rect.inflate(grow * 2, grow * 2), 2, border_radius=radius + grow)
        draw_keycap(surface, slot.key_label, midtop=(rect.centerx, rect.bottom - 8))

    @staticmethod
    def draw_empty_slot(surface: pygame.Surface, slot: SkillSlot, rect: pygame.Rect) -> None:
        """The power-up box with nothing held: a faint dashed diamond."""
        draw_panel(surface, rect, "slot")
        draw_icon(surface, "empty", (rect.centerx, rect.centery - 2), 30, PALETTE.text_faint)
        pygame.draw.rect(surface, PALETTE.line, rect, 1, border_radius=PANEL_STYLES["slot"].radius)
        draw_keycap(surface, slot.key_label, midtop=(rect.centerx, rect.bottom - 8))

    # --- Second Wind ---------------------------------------------------------------------------
    def draw_second_wind(self, surface: pygame.Surface, world: World, bar: pygame.Rect) -> None:
        """A badge left of the bar: bright when ready, a filling ring while it recharges."""
        skill = world.second_wind
        r = HUD_BUFF_RADIUS
        x, cy = bar.left - 16 - r, bar.centery - 6
        pygame.draw.circle(surface, PALETTE.panel_bottom, (x, cy), r)
        if skill.ready:
            draw_glow(surface, skill.color, (x, cy), r * 1.6, 70)
            pygame.draw.circle(surface, skill.color, (x, cy), r, 2)
            draw_icon(surface, skill.icon, (x, cy), 22, skill.color)
            label, label_color = "READY", skill.color
        else:
            pygame.draw.circle(surface, PALETTE.line, (x, cy), r, 1)
            draw_progress_ring(surface, (x, cy), r, 1 - skill.cooldown_fraction, skill.color, 3)
            draw_icon(surface, skill.icon, (x, cy), 22, lerp_color(skill.color, PALETTE.text_faint, 0.65))
            label, label_color = f"{math.ceil(skill.remaining)}s", PALETTE.text_dim
        if skill.ready_flash > 0:
            grow = int(10 * (1 - skill.ready_flash))
            pygame.draw.circle(surface, lerp_color(PALETTE.panel_bottom, PALETTE.text, skill.ready_flash),
                               (x, cy), r + grow, 2)
        draw_text(surface, label, "tiny", label_color, shadow=True, midtop=(x, cy + r + 4))

    # --- Active effects ----------------------------------------------------------------------
    @staticmethod
    def buff_list(world: World) -> list[tuple[str, Color, float, float]]:
        """(icon, color, fraction left, seconds left) for each active effect."""
        p = world.player
        buffs = []
        if p.in_stasis:
            buffs.append(("stasis", PALETTE.stasis, p.stasis_remaining / config.STASIS_DURATION, p.stasis_remaining))
        if p.invulnerable_remaining > 0:
            buffs.append(("second_wind", PALETTE.second_wind,
                          p.invulnerable_remaining / config.SECOND_WIND_INVULN_TIME, p.invulnerable_remaining))
        if world.time_warped:
            buffs.append(("time_warp", PALETTE.time_warp,
                          world.time_warp_remaining / config.TIME_WARP_DURATION, world.time_warp_remaining))
        if world.coin_rush:
            buffs.append(("coin_rush", PALETTE.coin,
                          world.coin_rush_remaining / config.COIN_RUSH_DURATION, world.coin_rush_remaining))
        if p.shielded:
            buffs.append(("shield", PALETTE.shield, p.shield_remaining / p.shield_duration, p.shield_remaining))
        sprint = p.speed_buffs.get("sprint")
        if sprint:
            buffs.append(("sprint", PALETTE.sprint, sprint.remaining / sprint.duration, sprint.remaining))
        return buffs

    def draw_buffs(self, surface: pygame.Surface, world: World, bar: pygame.Rect, left: int) -> None:
        """Right to left, starting at ``left`` (the bar, or the Second Wind badge)."""
        r = HUD_BUFF_RADIUS
        x, cy = left - 16 - r, bar.centery - 6
        for icon, color, fraction, seconds in self.buff_list(world):
            pygame.draw.circle(surface, PALETTE.panel_bottom, (x, cy), r)
            pygame.draw.circle(surface, PALETTE.line, (x, cy), r, 1)
            draw_progress_ring(surface, (x, cy), r, fraction, color, 3)
            draw_icon(surface, icon, (x, cy), 20, color)
            draw_text(surface, f"{seconds:0.1f}", "tiny", PALETTE.text_dim, shadow=True, midtop=(x, cy + r + 4))
            x -= 2 * r + 10
