"""
Mode Selection Carousel Screen (Publication Grade).
Features Mode Themed Accent Cards, Smooth Elevation Physics,
Segmented Grid Dimension Controls, and Calibrated Non-Overlapping Layout.
"""

import math
import pygame
from typing import Dict, Any, Tuple, Callable, List
from .widgets import Button
from game.audio import SoundFX

class ModeSelectScreen:
    """Publication-Grade Visual Mode Selector featuring all 5 preserved game modes."""

    def __init__(
        self,
        surface_size: Tuple[int, int],
        on_launch: Callable[[int, int], None],
        on_back: Callable[[], None]
    ):
        self.width, self.height = surface_size
        self.on_launch = on_launch
        self.on_back = on_back

        self.selected_mode = 0
        self.selected_grid_size = 20
        self.hovered_card = -1

        self.font_title = pygame.font.SysFont("segoeui", 26, bold=True)
        self.font_card_title = pygame.font.SysFont("segoeui", 15, bold=True)
        self.font_desc = pygame.font.SysFont("segoeui", 11)
        self.font_badge = pygame.font.SysFont("consolas", 11, bold=True)
        self.font_diff = pygame.font.SysFont("consolas", 12, bold=True)

        # 5 Mode Cards Layout (Horizontal Row)
        # Total available width = 1280. 5 * 224 + 4 * 18 = 1120 + 72 = 1192px.
        self.card_width = 224
        self.card_height = 340
        self.card_gap = 18
        total_w = 5 * self.card_width + 4 * self.card_gap
        self.cards_start_x = (self.width - total_w) // 2
        self.cards_y = 96

        # Card elevation states (smooth float)
        self.card_elevs = [0.0] * 5

        # Navigation
        self.btn_back = Button(35, 20, 95, 36, "BACK", self._handle_back, color=(19, 24, 38), font_size=12, shortcut="[ESC]")

        # Centered Grid Size Buttons Row (y = 462, 26px below cards)
        cx = self.width // 2
        self.size_buttons: List[Tuple[int, Button]] = []
        sizes = [15, 20, 25, 30]
        btn_w, btn_h, gap = 82, 36, 12
        total_btns_w = len(sizes) * btn_w + (len(sizes) - 1) * gap
        # Label offset to left of buttons
        start_btns_x = cx - total_btns_w // 2 + 55
        self.grid_label_pos = (start_btns_x - 145, 471)

        for i, s in enumerate(sizes):
            b = Button(start_btns_x + i * (btn_w + gap), 462, btn_w, btn_h, f"{s}x{s}", lambda sz=s: self._set_size(sz), font_size=12)
            self.size_buttons.append((s, b))

        # Bottom Launch CTA Button (y = 538, 40px below size buttons)
        self.btn_launch = Button(cx - 170, 538, 340, 52, "INITIATE PROTOCOL", self._handle_launch, color=(0, 240, 255), text_color=(11, 14, 23), font_size=16)

    def _set_size(self, s: int):
        self.selected_grid_size = s
        SoundFX.play_click()

    def _handle_back(self):
        SoundFX.play_click()
        self.on_back()

    def _handle_launch(self):
        SoundFX.play_click()
        self.on_launch(self.selected_mode, self.selected_grid_size)

    def handle_event(self, event: pygame.event.Event):
        self.btn_launch.handle_event(event)
        self.btn_back.handle_event(event)

        for s, btn in self.size_buttons:
            btn.handle_event(event)

        # Mouse motion over cards
        if event.type == pygame.MOUSEMOTION:
            prev_hover = self.hovered_card
            self.hovered_card = -1
            for i in range(5):
                card_x = self.cards_start_x + i * (self.card_width + self.card_gap)
                r = pygame.Rect(card_x, self.cards_y, self.card_width, self.card_height)
                if r.collidepoint(event.pos):
                    self.hovered_card = i
                    if prev_hover != i:
                        SoundFX.play_hover()
                    break

        # Click on Mode Cards
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            for i in range(5):
                card_x = self.cards_start_x + i * (self.card_width + self.card_gap)
                r = pygame.Rect(card_x, self.cards_y, self.card_width, self.card_height)
                if r.collidepoint(event.pos):
                    if self.selected_mode != i:
                        self.selected_mode = i
                        SoundFX.play_click()

        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                self._handle_back()
            elif event.key == pygame.K_RETURN:
                self._handle_launch()

    def update(self, dt: float):
        self.btn_launch.update(dt)
        self.btn_back.update(dt)
        for s, btn in self.size_buttons:
            btn.update(dt)

        for i in range(5):
            target = 1.0 if (self.hovered_card == i or self.selected_mode == i) else 0.0
            self.card_elevs[i] += (target - self.card_elevs[i]) * min(1.0, 14.0 * dt)

    def render(self, surface: pygame.Surface):
        surface.fill((11, 14, 23))

        self.btn_back.draw(surface)

        # Header Title
        title_surf = self.font_title.render("SELECT MISSION PROTOCOL", True, (0, 240, 255))
        surface.blit(title_surf, (self.width // 2 - title_surf.get_width() // 2, 22))

        sub_surf = self.font_desc.render("Choose cyber arena rules, difficulty, and grid dimension", True, (142, 154, 175))
        surface.blit(sub_surf, (self.width // 2 - sub_surf.get_width() // 2, 58))

        # Mode Metadata
        mode_data = [
            ("MODE 0", "SOLO TRIAL", "Speedrun against the clock. Navigate from start to opposite exit.", "Controls: Arrow Keys", "LEVEL 1/5", (0, 240, 255)),
            ("MODE 1", "TWO PLAYER", "Split-screen 1v1 local racing. Outmaneuver your opponent.", "P1: Arrows | P2: WASD", "LEVEL 2/5", (157, 78, 221)),
            ("MODE 2", "RACE VS AI", "Head-to-head race against an optimal heuristic pathfinder.", "Controls: Arrow Keys", "LEVEL 3/5", (255, 183, 3)),
            ("MODE 3", "CHASE SURVIVAL", "Survive the Hunter AI! Stalks your dynamic shortest path.", "Controls: Arrow Keys", "LEVEL 4/5", (239, 71, 111)),
            ("MODE 4", "ESCAPE HEIST", "Find 8 keys & blast walls with Spacebar Wall Breakers.", "Arrows + SPACE to blast", "LEVEL 5/5", (6, 214, 160))
        ]

        for i, (badge, title, desc, controls, diff, col) in enumerate(mode_data):
            card_x = self.cards_start_x + i * (self.card_width + self.card_gap)
            elev = int(self.card_elevs[i] * 5.0)
            card_y = self.cards_y - elev
            r = pygame.Rect(card_x, card_y, self.card_width, self.card_height)

            is_sel = (self.selected_mode == i)
            is_hov = (self.hovered_card == i)

            # Outer glow on selected / hovered
            if is_sel or is_hov:
                glow_r = r.inflate(10, 10)
                glow_surf = pygame.Surface((glow_r.width, glow_r.height), pygame.SRCALPHA)
                alpha = 55 if is_sel else 25
                pygame.draw.rect(glow_surf, (*col, alpha), glow_surf.get_rect(), border_radius=12)
                surface.blit(glow_surf, glow_r.topleft)

            # Card Background
            bg_col = (24, 30, 48) if is_sel else (19, 24, 38)
            border_col = col if is_sel else ((col[0]//2, col[1]//2, col[2]//2) if is_hov else (34, 43, 66))
            border_w = 2 if is_sel else 1

            pygame.draw.rect(surface, bg_col, r, border_radius=8)
            pygame.draw.rect(surface, border_col, r, width=border_w, border_radius=8)

            # Top Accent Color Strip
            pygame.draw.rect(surface, col, pygame.Rect(card_x, card_y, self.card_width, 4), border_top_left_radius=8, border_top_right_radius=8)

            # Badge Pill
            b_surf = self.font_badge.render(badge, True, col)
            surface.blit(b_surf, (card_x + 16, card_y + 16))

            # Mode Title
            t_surf = self.font_card_title.render(title, True, (248, 249, 250))
            surface.blit(t_surf, (card_x + 16, card_y + 36))

            # Difficulty
            d_label = self.font_desc.render("Threat Level:", True, (142, 154, 175))
            surface.blit(d_label, (card_x + 16, card_y + 64))
            diff_surf = self.font_diff.render(diff, True, col)
            surface.blit(diff_surf, (card_x + 16, card_y + 80))

            # Description (word wrapped)
            words = desc.split()
            lines = []
            curr_l = ""
            for w in words:
                test_l = f"{curr_l} {w}".strip()
                if self.font_desc.size(test_l)[0] < self.card_width - 32:
                    curr_l = test_l
                else:
                    lines.append(curr_l)
                    curr_l = w
            if curr_l:
                lines.append(curr_l)

            for line_idx, line in enumerate(lines):
                l_surf = self.font_desc.render(line, True, (142, 154, 175))
                surface.blit(l_surf, (card_x + 16, card_y + 110 + line_idx * 16))

            # Controls Box
            ctrl_box = pygame.Rect(card_x + 14, card_y + 215, self.card_width - 28, 48)
            pygame.draw.rect(surface, (14, 18, 28), ctrl_box, border_radius=6)
            pygame.draw.rect(surface, (34, 43, 66), ctrl_box, width=1, border_radius=6)

            ctrl_lbl = self.font_badge.render("INPUT BINDINGS", True, (92, 103, 125))
            surface.blit(ctrl_lbl, (ctrl_box.x + 8, ctrl_box.y + 6))
            ctrl_val = self.font_desc.render(controls, True, (248, 249, 250))
            surface.blit(ctrl_val, (ctrl_box.x + 8, ctrl_box.y + 24))

            # Selection status footer
            if is_sel:
                status_surf = self.font_badge.render("ACTIVE SELECTION", True, col)
                surface.blit(status_surf, (card_x + self.card_width // 2 - status_surf.get_width() // 2, card_y + 300))

        # Grid Dimension Selector Label & Buttons
        lbl_size = self.font_badge.render("ARENA DIMENSION:", True, (142, 154, 175))
        surface.blit(lbl_size, self.grid_label_pos)

        for s, btn in self.size_buttons:
            if s == self.selected_grid_size:
                btn.color = (0, 240, 255)
                btn.text_color = (11, 14, 23)
            else:
                btn.color = (19, 24, 38)
                btn.text_color = (248, 249, 250)
            btn.draw(surface)

        # Bottom Launch CTA Button
        self.btn_launch.draw(surface)
