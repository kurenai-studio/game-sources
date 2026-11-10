"""
Lane Legends: Human vs AI
ui.py - Arcade UI system: menus, HUD, telemetry overlay, countdown, high scores,
difficulty selection, and technical architecture documentation.
"""

import math
from typing import Dict, List, Tuple, Optional, Any

import pygame
from settings import (
    WINDOW_WIDTH,
    WINDOW_HEIGHT,
    RACE_DISTANCE_METERS,
    METERS_PER_PIXEL,
    KMH_CONVERSION,
    DIFFICULTY_PROFILES,
    DIFFICULTY_EASY,
    DIFFICULTY_MEDIUM,
    DIFFICULTY_HARD,
    ACTION_NAMES,
    COLOR_BG,
    COLOR_DARK_CARD,
    COLOR_CARD_BORDER,
    COLOR_CYAN,
    COLOR_CYAN_GLOW,
    COLOR_ORANGE,
    COLOR_ORANGE_GLOW,
    COLOR_CRIMSON,
    COLOR_CRIMSON_GLOW,
    COLOR_GREEN,
    COLOR_YELLOW,
    COLOR_WHITE,
    COLOR_OFFWHITE,
    COLOR_MUTED,
)
from entities import Car


class Button:
    """Arcade button with smooth hover animation and click detection."""
    def __init__(
        self,
        rect: pygame.Rect,
        text: str,
        tag: str,
        accent_color: Tuple[int, int, int] = COLOR_CYAN,
        font_size: int = 22,
    ):
        self.rect = rect
        self.text = text
        self.tag = tag
        self.accent_color = accent_color
        self.font = pygame.font.SysFont("impact", font_size)
        self.is_hovered = False

    def update(self, mouse_pos: Tuple[int, int]) -> None:
        """Check hover state."""
        self.is_hovered = self.rect.collidepoint(mouse_pos)

    def render(self, surface: pygame.Surface) -> None:
        """Draw neon arcade button."""
        # Hover glow and offset
        border_color = self.accent_color if self.is_hovered else COLOR_CARD_BORDER
        bg_color = (30, 36, 48) if self.is_hovered else COLOR_DARK_CARD

        pygame.draw.rect(surface, bg_color, self.rect, border_radius=8)
        pygame.draw.rect(surface, border_color, self.rect, 2, border_radius=8)

        # Hover accent corner pill
        if self.is_hovered:
            pygame.draw.rect(surface, self.accent_color, (self.rect.x, self.rect.y, 6, self.rect.height), border_radius=3)

        text_color = COLOR_WHITE if self.is_hovered else COLOR_OFFWHITE
        txt_surf = self.font.render(self.text, True, text_color)
        txt_rect = txt_surf.get_rect(center=self.rect.center)
        surface.blit(txt_surf, txt_rect)


class UIManager:
    """
    Orchestrates all menus, HUDs, telemetry graphs, and interactive overlays.
    """

    def __init__(self):
        # Fonts
        self.font_title = pygame.font.SysFont("impact", 54)
        self.font_subtitle = pygame.font.SysFont("arialblack", 18)
        self.font_heading = pygame.font.SysFont("impact", 28)
        self.font_body = pygame.font.SysFont("arial", 15)
        self.font_body_bold = pygame.font.SysFont("arial", 15, bold=True)
        self.font_hud_large = pygame.font.SysFont("impact", 32)
        self.font_hud_small = pygame.font.SysFont("arial", 13, bold=True)
        self.font_telemetry = pygame.font.SysFont("consolas", 13)

        # State notifications (e.g. "COLLISION!", "NITRO!")
        self.notifications: List[Dict[str, Any]] = []

    def add_notification(self, text: str, color: Tuple[int, int, int], duration: float = 1.2) -> None:
        """Enqueue an in-race visual notification badge."""
        self.notifications.append({
            "text": text,
            "color": color,
            "timer": duration,
            "max_timer": duration,
        })

    def update_notifications(self, dt: float) -> None:
        """Tick down notification lifetimes."""
        for n in self.notifications:
            n["timer"] -= dt
        self.notifications = [n for n in self.notifications if n["timer"] > 0]

    # -------------------------------------------------------------------------
    # 1. MAIN MENU
    # -------------------------------------------------------------------------
    def render_main_menu(
        self,
        surface: pygame.Surface,
        buttons: List[Button],
        selected_index: int,
        current_difficulty: str,
    ) -> None:
        """Render stylish arcade main menu screen."""
        surface.fill(COLOR_BG)

        # Animated background racing streaks
        time_sec = pygame.time.get_ticks() * 0.003
        for i in range(14):
            streak_x = (i * 95 + int(time_sec * 50)) % WINDOW_WIDTH
            pygame.draw.line(surface, (20, 25, 36), (streak_x, 0), (streak_x + 120, WINDOW_HEIGHT), 2)

        # Main Title Box
        title_y = 75
        title_surf = self.font_title.render("LANE LEGENDS", True, COLOR_CYAN)
        title_rect = title_surf.get_rect(center=(WINDOW_WIDTH // 2, title_y))
        # Title Glow effect
        glow_surf = self.font_title.render("LANE LEGENDS", True, COLOR_CYAN_GLOW)
        surface.blit(glow_surf, title_rect.move(2, 2))
        surface.blit(title_surf, title_rect)

        # Subtitle
        sub_surf = self.font_subtitle.render("Human vs Machine — Who Rules the Road?", True, (255, 200, 50))
        sub_rect = sub_surf.get_rect(center=(WINDOW_WIDTH // 2, title_y + 48))
        surface.blit(sub_surf, sub_rect)

        # Badge showing current difficulty
        diff_info = DIFFICULTY_PROFILES[current_difficulty]
        diff_badge = self.font_hud_small.render(
            f"AI OPPONENT: {diff_info['name']} [{diff_info['tag']}]", True, COLOR_CRIMSON
        )
        badge_rect = diff_badge.get_rect(center=(WINDOW_WIDTH // 2, title_y + 80))
        surface.blit(diff_badge, badge_rect)

        # Render menu buttons
        for idx, btn in enumerate(buttons):
            # Highlight keyboard-selected button
            if idx == selected_index:
                btn.is_hovered = True
            btn.render(surface)

        # Bottom help footer
        footer_text = self.font_body.render(
            "Use UP / DOWN Arrows or Mouse to select  |  ENTER to confirm  |  M to Mute Sound",
            True,
            COLOR_MUTED,
        )
        surface.blit(footer_text, footer_text.get_rect(center=(WINDOW_WIDTH // 2, WINDOW_HEIGHT - 35)))

    # -------------------------------------------------------------------------
    # 2. DIFFICULTY SELECTION SCREEN
    # -------------------------------------------------------------------------
    def render_difficulty_screen(
        self,
        surface: pygame.Surface,
        current_difficulty: str,
        back_button: Button,
    ) -> None:
        """Render 3 difficulty selection cards with stats comparison."""
        surface.fill(COLOR_BG)

        # Title
        title_surf = self.font_heading.render("SELECT AI OPPONENT & DIFFICULTY", True, COLOR_WHITE)
        surface.blit(title_surf, title_surf.get_rect(center=(WINDOW_WIDTH // 2, 60)))

        sub_surf = self.font_body.render(
            "All difficulty levels utilize the same trained Q-Learning model with calibrated reaction times & policies.",
            True,
            COLOR_MUTED,
        )
        surface.blit(sub_surf, sub_surf.get_rect(center=(WINDOW_WIDTH // 2, 95)))

        card_width = 360
        card_height = 420
        start_x = 80
        gap = 50

        diff_keys = [DIFFICULTY_EASY, DIFFICULTY_MEDIUM, DIFFICULTY_HARD]
        theme_colors = [COLOR_GREEN, COLOR_ORANGE, COLOR_CRIMSON]

        mouse_pos = pygame.mouse.get_pos()

        for i, key in enumerate(diff_keys):
            info = DIFFICULTY_PROFILES[key]
            cx = start_x + i * (card_width + gap)
            cy = 140
            rect = pygame.Rect(cx, cy, card_width, card_height)

            is_selected = (key == current_difficulty)
            is_hovered = rect.collidepoint(mouse_pos)
            color = theme_colors[i]

            bg_col = (28, 34, 46) if is_hovered else COLOR_DARK_CARD
            border_col = color if (is_selected or is_hovered) else COLOR_CARD_BORDER
            border_w = 4 if is_selected else 2

            pygame.draw.rect(surface, bg_col, rect, border_radius=12)
            pygame.draw.rect(surface, border_col, rect, border_w, border_radius=12)

            # Selected indicator banner
            if is_selected:
                banner_rect = pygame.Rect(cx, cy, card_width, 34)
                pygame.draw.rect(surface, color, banner_rect, border_top_left_radius=12, border_top_right_radius=12)
                act_txt = self.font_hud_small.render("ACTIVE SELECTION", True, (15, 18, 24))
                surface.blit(act_txt, act_txt.get_rect(center=banner_rect.center))

            # Name & Tag
            name_surf = self.font_heading.render(info["name"], True, color)
            surface.blit(name_surf, name_surf.get_rect(center=(cx + card_width // 2, cy + 65)))

            tag_surf = self.font_hud_small.render(f"LEVEL: {info['tag']}", True, COLOR_OFFWHITE)
            surface.blit(tag_surf, tag_surf.get_rect(center=(cx + card_width // 2, cy + 98)))

            # Description
            desc_surf = self.font_body.render(info["description"], True, COLOR_OFFWHITE)
            surface.blit(desc_surf, desc_surf.get_rect(center=(cx + card_width // 2, cy + 135)))

            # Technical Parameter Specs Box
            spec_y = cy + 175
            spec_box = pygame.Rect(cx + 20, spec_y, card_width - 40, 160)
            pygame.draw.rect(surface, (16, 20, 28), spec_box, border_radius=8)
            pygame.draw.rect(surface, COLOR_CARD_BORDER, spec_box, 1, border_radius=8)

            specs = [
                ("Speed Multiplier:", f"{info['speed_multiplier']}x"),
                ("Reaction Interval:", f"{info['reaction_interval']} sec"),
                ("Action Epsilon:", f"{int(info['epsilon_randomness'] * 100)}% random"),
                ("Nitro Threshold:", f">{int(info['nitro_threshold'])}% charge"),
            ]

            for s_idx, (k, v) in enumerate(specs):
                lbl = self.font_body.render(k, True, COLOR_MUTED)
                val = self.font_body_bold.render(v, True, COLOR_WHITE)
                surface.blit(lbl, (cx + 34, spec_y + 14 + s_idx * 34))
                surface.blit(val, (cx + card_width - 34 - val.get_width(), spec_y + 14 + s_idx * 34))

            # Click to select prompt
            btn_lbl = self.font_hud_small.render(
                "SELECTED" if is_selected else "CLICK OR PRESS [1-3] TO SELECT",
                True,
                color if is_selected else COLOR_MUTED,
            )
            surface.blit(btn_lbl, btn_lbl.get_rect(center=(cx + card_width // 2, cy + card_height - 35)))

        back_button.update(mouse_pos)
        back_button.render(surface)

    # -------------------------------------------------------------------------
    # 3. HOW TO PLAY SCREEN
    # -------------------------------------------------------------------------
    def render_how_to_play(self, surface: pygame.Surface, back_button: Button) -> None:
        """Render controls diagrams, obstacle guide, and racing objectives."""
        surface.fill(COLOR_BG)

        title = self.font_heading.render("HOW TO PLAY & CONTROLS", True, COLOR_WHITE)
        surface.blit(title, title.get_rect(center=(WINDOW_WIDTH // 2, 45)))

        # Two Control Panels Side by Side
        # Player 1 Controls (Left)
        p1_rect = pygame.Rect(80, 90, 520, 240)
        pygame.draw.rect(surface, COLOR_DARK_CARD, p1_rect, border_radius=10)
        pygame.draw.rect(surface, COLOR_CYAN, p1_rect, 2, border_radius=10)

        p1_title = self.font_heading.render("PLAYER 1 (LEFT TRACK)", True, COLOR_CYAN)
        surface.blit(p1_title, (p1_rect.x + 24, p1_rect.y + 16))

        p1_controls = [
            ("Move Left", "[ A ]"),
            ("Move Right", "[ D ]"),
            ("Nitro Boost", "[ W ]  (Requires boost charge)"),
            ("Brake / Coast", "[ S ]  (Quick recharge)"),
        ]
        for idx, (action, key) in enumerate(p1_controls):
            lbl = self.font_body.render(action, True, COLOR_OFFWHITE)
            key_txt = self.font_body_bold.render(key, True, COLOR_CYAN)
            surface.blit(lbl, (p1_rect.x + 30, p1_rect.y + 65 + idx * 40))
            surface.blit(key_txt, (p1_rect.x + 220, p1_rect.y + 65 + idx * 40))

        # Player 2 Controls (Right)
        p2_rect = pygame.Rect(680, 90, 520, 240)
        pygame.draw.rect(surface, COLOR_DARK_CARD, p2_rect, border_radius=10)
        pygame.draw.rect(surface, COLOR_ORANGE, p2_rect, 2, border_radius=10)

        p2_title = self.font_heading.render("PLAYER 2 (RIGHT TRACK - 2P MODE)", True, COLOR_ORANGE)
        surface.blit(p2_title, (p2_rect.x + 24, p2_rect.y + 16))

        p2_controls = [
            ("Move Left", "[ LEFT ARROW ]"),
            ("Move Right", "[ RIGHT ARROW ]"),
            ("Nitro Boost", "[ UP ARROW ]  (Requires boost charge)"),
            ("Brake / Coast", "[ DOWN ARROW ] (Quick recharge)"),
        ]
        for idx, (action, key) in enumerate(p2_controls):
            lbl = self.font_body.render(action, True, COLOR_OFFWHITE)
            key_txt = self.font_body_bold.render(key, True, COLOR_ORANGE)
            surface.blit(lbl, (p2_rect.x + 30, p2_rect.y + 65 + idx * 40))
            surface.blit(key_txt, (p2_rect.x + 220, p2_rect.y + 65 + idx * 40))

        # Bottom Obstacle Guide
        obs_box = pygame.Rect(80, 355, 1120, 240)
        pygame.draw.rect(surface, COLOR_DARK_CARD, obs_box, border_radius=10)
        pygame.draw.rect(surface, COLOR_CARD_BORDER, obs_box, 1, border_radius=10)

        obs_title = self.font_heading.render("RACE OBSTACLES & HAZARDS", True, COLOR_YELLOW)
        surface.blit(obs_title, (obs_box.x + 24, obs_box.y + 16))

        hazards = [
            ("Traffic Cars", "Slower vehicles cruising in lanes. Avoid direct rear-end collisions."),
            ("Road Barriers", "Heavy orange-striped barricades. Severe speed penalty upon impact."),
            ("Traffic Cones", "Work-zone markers. Deducts points and slows down momentum."),
            ("Oil Slicks", "Glossy dark slicks that induce steering drift and immediate drag."),
        ]
        for idx, (name, desc) in enumerate(hazards):
            h_name = self.font_body_bold.render(f"• {name}:", True, COLOR_WHITE)
            h_desc = self.font_body.render(desc, True, COLOR_OFFWHITE)
            surface.blit(h_name, (obs_box.x + 30, obs_box.y + 60 + idx * 42))
            surface.blit(h_desc, (obs_box.x + 190, obs_box.y + 60 + idx * 42))

        # Global Hotkeys
        hotkeys = self.font_hud_small.render(
            "HOTKEYS:  [ P / ESC ] Pause Game   |   [ M ] Toggle Sound Mute   |   [ I / E ] Toggle AI Live Telemetry Overlay",
            True,
            COLOR_MUTED,
        )
        surface.blit(hotkeys, hotkeys.get_rect(center=(WINDOW_WIDTH // 2, 615)))

        back_button.update(pygame.mouse.get_pos())
        back_button.render(surface)

    # -------------------------------------------------------------------------
    # 4. HIGH SCORES & LEADERBOARD SCREEN
    # -------------------------------------------------------------------------
    def render_high_scores(
        self,
        surface: pygame.Surface,
        leaderboard: List[Dict[str, Any]],
        tallies: Dict[str, Any],
        back_button: Button,
    ) -> None:
        """Render persistent high scores, leaderboard, and head-to-head win tallies."""
        surface.fill(COLOR_BG)

        title = self.font_heading.render("RACE RECORDS & LEADERBOARD", True, COLOR_WHITE)
        surface.blit(title, title.get_rect(center=(WINDOW_WIDTH // 2, 45)))

        # Win / Loss Summary Bar
        h_tally = tallies.get("human_vs_ai", {"human_wins": 0, "ai_wins": 0, "draws": 0})
        p_tally = tallies.get("pvp", {"p1_wins": 0, "p2_wins": 0, "draws": 0})

        tally_rect = pygame.Rect(100, 85, 1080, 55)
        pygame.draw.rect(surface, COLOR_DARK_CARD, tally_rect, border_radius=8)
        pygame.draw.rect(surface, COLOR_CARD_BORDER, tally_rect, 1, border_radius=8)

        tally_str = (
            f"HUMAN vs AI:  Human Wins: {h_tally.get('human_wins', 0)}  |  "
            f"AI Wins: {h_tally.get('ai_wins', 0)}  |  "
            f"Draws: {h_tally.get('draws', 0)}    ///    "
            f"2-PLAYER:  P1 Wins: {p_tally.get('p1_wins', 0)}  |  "
            f"P2 Wins: {p_tally.get('p2_wins', 0)}"
        )
        t_surf = self.font_hud_small.render(tally_str, True, COLOR_CYAN)
        surface.blit(t_surf, t_surf.get_rect(center=tally_rect.center))

        # Top 10 Table Card
        table_rect = pygame.Rect(100, 160, 1080, 440)
        pygame.draw.rect(surface, COLOR_DARK_CARD, table_rect, border_radius=10)
        pygame.draw.rect(surface, COLOR_CARD_BORDER, table_rect, 1, border_radius=10)

        # Header Row
        headers = [("RANK", 140), ("RACER", 280), ("SCORE", 440), ("FINISH TIME", 620), ("MODE", 800), ("DATE", 1000)]
        pygame.draw.rect(surface, (28, 34, 46), (100, 160, 1080, 36), border_top_left_radius=10, border_top_right_radius=10)
        for h_text, hx in headers:
            h_lbl = self.font_hud_small.render(h_text, True, COLOR_YELLOW)
            surface.blit(h_lbl, h_lbl.get_rect(center=(hx, 178)))

        # Rows
        if not leaderboard:
            empty_txt = self.font_body.render("No races recorded yet. Complete your first race to establish records!", True, COLOR_MUTED)
            surface.blit(empty_txt, empty_txt.get_rect(center=(WINDOW_WIDTH // 2, 360)))
        else:
            for idx, entry in enumerate(leaderboard[:10]):
                ry = 212 + idx * 36
                if idx % 2 == 1:
                    pygame.draw.rect(surface, (18, 22, 30), (102, ry - 14, 1076, 32))

                rank_str = f"#{idx + 1}"
                if idx == 0:
                    rank_str = "🥇 1ST"
                elif idx == 1:
                    rank_str = "🥈 2ND"
                elif idx == 2:
                    rank_str = "🥉 3RD"

                col_rank = COLOR_YELLOW if idx < 3 else COLOR_OFFWHITE

                r_surf = self.font_body_bold.render(rank_str, True, col_rank)
                p_surf = self.font_body.render(str(entry.get("player", "Unknown")), True, COLOR_WHITE)
                s_surf = self.font_body_bold.render(f"{entry.get('score', 0):,}", True, COLOR_CYAN)
                t_surf = self.font_body.render(f"{entry.get('time', 0.0):.2f}s", True, COLOR_OFFWHITE)
                m_surf = self.font_body.render(str(entry.get("mode", "-")), True, COLOR_MUTED)
                d_surf = self.font_body.render(str(entry.get("date", "-")), True, COLOR_MUTED)

                surface.blit(r_surf, r_surf.get_rect(center=(140, ry)))
                surface.blit(p_surf, (220, ry - 10))
                surface.blit(s_surf, s_surf.get_rect(center=(440, ry)))
                surface.blit(t_surf, t_surf.get_rect(center=(620, ry)))
                surface.blit(m_surf, m_surf.get_rect(center=(800, ry)))
                surface.blit(d_surf, d_surf.get_rect(center=(1000, ry)))

        back_button.update(pygame.mouse.get_pos())
        back_button.render(surface)

    # -------------------------------------------------------------------------
    # 5. AI ARCHITECTURE & EXPLAINABILITY SCREEN
    # -------------------------------------------------------------------------
    def render_ai_info(self, surface: pygame.Surface, back_button: Button) -> None:
        """Technical overview of the Tabular Q-Learning system architecture."""
        surface.fill(COLOR_BG)

        title = self.font_heading.render("AI SYSTEM ARCHITECTURE — TABULAR Q-LEARNING", True, COLOR_WHITE)
        surface.blit(title, title.get_rect(center=(WINDOW_WIDTH // 2, 40)))

        main_box = pygame.Rect(80, 75, 1120, 545)
        pygame.draw.rect(surface, COLOR_DARK_CARD, main_box, border_radius=10)
        pygame.draw.rect(surface, COLOR_CYAN, main_box, 1, border_radius=10)

        topics = [
            ("1. Algorithm", "Model-free, off-policy Tabular Q-Learning. Directly learns optimal state-action values without environment transition dynamics."),
            ("2. State Space (81 States)", "State S = (Lane, Left_Dist, Mid_Dist, Right_Dist). 3 lanes * 3 distances (Near, Medium, Far) = 81 discrete states."),
            ("3. Action Space", "3 Discrete Actions: 0 = MOVE_LEFT, 1 = STAY, 2 = MOVE_RIGHT. Actions leading off-track are masked as invalid (-999.0)."),
            ("4. Bellman Update Rule", "Q(s, a) = Q(s, a) + alpha * [ r + gamma * max_a' Q(s', a') - Q(s, a) ]. Learning rate alpha=0.15, discount factor gamma=0.90."),
            ("5. Reward Function", "Progress: +1.0 | Obstacle Pass: +10.0 | Safe Lane Avoidance: +6.0 | Unnecessary Change: -1.5 | Collision: -28.0 | Finish: +35.0."),
            ("6. Training Simulation", "Headless offline training across 1,600 episodes with epsilon-greedy decay (1.0 -> 0.03). Saves to data/q_table.json."),
            ("7. Difficulty Calibration", "All difficulties share the same trained Q-table; Cyber Cheetah uses 0% randomness and 0.12s reaction interval."),
            ("8. Live Explainability", "Press [ I ] or [ E ] during racing to display the real-time AI reasoning card with live Q-values and decision rationale!"),
        ]

        for idx, (head, body) in enumerate(topics):
            hy = main_box.y + 22 + idx * 64
            h_surf = self.font_body_bold.render(head, True, COLOR_YELLOW)
            b_surf = self.font_body.render(body, True, COLOR_OFFWHITE)
            surface.blit(h_surf, (main_box.x + 24, hy))
            surface.blit(b_surf, (main_box.x + 24, hy + 20))

        back_button.update(pygame.mouse.get_pos())
        back_button.render(surface)

    # -------------------------------------------------------------------------
    # 6. IN-RACE HUD & SPEEDOMETERS
    # -------------------------------------------------------------------------
    def render_in_race_hud(
        self,
        surface: pygame.Surface,
        car_p1: Car,
        car_p2: Car,
        race_distance: float,
        ai_telemetry: Optional[Dict[str, Any]],
        show_telemetry: bool,
    ) -> None:
        """Render speedometers, nitro meters, race progress bar, and notifications."""
        # A. Top Race Progress Bar
        total_px = race_distance / METERS_PER_PIXEL
        p1_prog = min(1.0, car_p1.distance_traveled / total_px)
        p2_prog = min(1.0, car_p2.distance_traveled / total_px)

        bar_w = 480
        bar_h = 16
        bar_x = (WINDOW_WIDTH - bar_w) // 2
        bar_y = 12

        # Progress bar background
        pygame.draw.rect(surface, (20, 24, 34), (bar_x, bar_y, bar_w, bar_h), border_radius=8)
        pygame.draw.rect(surface, COLOR_CARD_BORDER, (bar_x, bar_y, bar_w, bar_h), 1, border_radius=8)

        # Chequered flag icon at finish of bar
        flag_font = self.font_hud_small.render("🏁", True, COLOR_WHITE)
        surface.blit(flag_font, (bar_x + bar_w + 8, bar_y - 2))

        # P1 progress pin
        p1_pin_x = bar_x + int(bar_w * p1_prog)
        pygame.draw.circle(surface, COLOR_CYAN, (p1_pin_x, bar_y + bar_h // 2), 7)
        pygame.draw.circle(surface, COLOR_WHITE, (p1_pin_x, bar_y + bar_h // 2), 3)

        # P2 progress pin
        p2_pin_x = bar_x + int(bar_w * p2_prog)
        p2_col = COLOR_CRIMSON if car_p2.is_ai else COLOR_ORANGE
        pygame.draw.circle(surface, p2_col, (p2_pin_x, bar_y + bar_h // 2), 7)
        pygame.draw.circle(surface, COLOR_WHITE, (p2_pin_x, bar_y + bar_h // 2), 3)

        # B. Left Track HUD (Player 1)
        self._render_car_hud(surface, car=car_p1, left_x=70, theme_color=COLOR_CYAN, label="PLAYER 1")

        # C. Right Track HUD (Player 2 / AI)
        lbl_p2 = f"AI: {car_p2.name}" if car_p2.is_ai else "PLAYER 2"
        self._render_car_hud(surface, car=car_p2, left_x=730, theme_color=p2_col, label=lbl_p2)

        # D. Floating Notifications / Events
        self._render_notifications(surface)

        # E. Live AI Telemetry Card (Toggleable)
        if show_telemetry and ai_telemetry:
            self._render_ai_telemetry_card(surface, ai_telemetry)

    def _render_car_hud(
        self,
        surface: pygame.Surface,
        car: Car,
        left_x: int,
        theme_color: Tuple[int, int, int],
        label: str,
    ) -> None:
        """Render speedometer, score, and nitro gauge for one racer."""
        hud_w = 480
        hud_h = 75
        hud_y = 10

        # Semi-transparent dark card
        card_surf = pygame.Surface((hud_w, hud_h), pygame.SRCALPHA)
        pygame.draw.rect(card_surf, (16, 20, 28, 220), (0, 0, hud_w, hud_h), border_radius=8)
        pygame.draw.rect(card_surf, theme_color, (0, 0, hud_w, hud_h), 2, border_radius=8)
        surface.blit(card_surf, (left_x, hud_y))

        # Racer Label & Score
        name_txt = self.font_hud_small.render(label, True, theme_color)
        score_txt = self.font_hud_large.render(f"{car.score:,}", True, COLOR_WHITE)
        surface.blit(name_txt, (left_x + 16, hud_y + 10))
        surface.blit(score_txt, (left_x + 16, hud_y + 28))

        # Speedometer (km/h)
        kmh = int(car.speed * KMH_CONVERSION)
        spd_val = self.font_hud_large.render(f"{kmh}", True, COLOR_YELLOW if car.is_nitro_active else COLOR_OFFWHITE)
        spd_unit = self.font_hud_small.render("KM/H", True, COLOR_MUTED)
        surface.blit(spd_val, (left_x + 220, hud_y + 24))
        surface.blit(spd_unit, (left_x + 220 + spd_val.get_width() + 4, hud_y + 36))

        # Nitro Gauge
        gauge_x = left_x + 325
        gauge_y = hud_y + 32
        gauge_w = 135
        gauge_h = 18

        pygame.draw.rect(surface, (25, 30, 42), (gauge_x, gauge_y, gauge_w, gauge_h), border_radius=4)
        nitro_pct = car.nitro_meter / 100.0
        fill_w = int(gauge_w * nitro_pct)
        if fill_w > 0:
            fill_col = COLOR_CYAN if not car.is_nitro_active else COLOR_YELLOW
            pygame.draw.rect(surface, fill_col, (gauge_x, gauge_y, fill_w, gauge_h), border_radius=4)
        pygame.draw.rect(surface, COLOR_CARD_BORDER, (gauge_x, gauge_y, gauge_w, gauge_h), 1, border_radius=4)

        nitro_lbl = self.font_hud_small.render(
            "⚡ NITRO BOOST" if not car.is_nitro_active else "🔥 BOOST ACTIVE",
            True,
            COLOR_YELLOW if car.is_nitro_active else COLOR_CYAN,
        )
        surface.blit(nitro_lbl, (gauge_x, hud_y + 12))

    def _render_notifications(self, surface: pygame.Surface) -> None:
        """Render pop-up event notifications."""
        ny = 110
        for n in self.notifications:
            txt_surf = self.font_hud_small.render(n["text"], True, n["color"])
            badge_w = txt_surf.get_width() + 24
            badge_h = 28
            badge_rect = pygame.Rect((WINDOW_WIDTH - badge_w) // 2, ny, badge_w, badge_h)

            bg_surf = pygame.Surface((badge_w, badge_h), pygame.SRCALPHA)
            pygame.draw.rect(bg_surf, (15, 18, 24, 210), (0, 0, badge_w, badge_h), border_radius=6)
            pygame.draw.rect(bg_surf, n["color"], (0, 0, badge_w, badge_h), 1, border_radius=6)
            surface.blit(bg_surf, badge_rect.topleft)
            surface.blit(txt_surf, txt_surf.get_rect(center=badge_rect.center))
            ny += 34

    def _render_ai_telemetry_card(self, surface: pygame.Surface, telemetry: Dict[str, Any]) -> None:
        """Render live AI explainability telemetry overlay for performance analysis."""
        card_w = 420
        card_h = 240
        card_x = 760
        card_y = 100

        card_surf = pygame.Surface((card_w, card_h), pygame.SRCALPHA)
        pygame.draw.rect(card_surf, (12, 16, 24, 235), (0, 0, card_w, card_h), border_radius=10)
        pygame.draw.rect(card_surf, COLOR_CRIMSON, (0, 0, card_w, card_h), 2, border_radius=10)
        surface.blit(card_surf, (card_x, card_y))

        # Title
        t_title = self.font_hud_small.render("🧠 AI REASONING TELEMETRY (Q-LEARNING)", True, COLOR_CRIMSON)
        surface.blit(t_title, (card_x + 16, card_y + 12))

        # State description
        state_str = f"STATE: {telemetry['lane_label']}  |  L:{telemetry['left_radar']} M:{telemetry['mid_radar']} R:{telemetry['right_radar']}"
        s_surf = self.font_telemetry.render(state_str, True, COLOR_OFFWHITE)
        surface.blit(s_surf, (card_x + 16, card_y + 38))

        # Action selected
        act_str = f"ACTION SELECTED: {telemetry['action_name']}  (Q = {telemetry['selected_q']:+.2f})"
        a_surf = self.font_body_bold.render(act_str, True, COLOR_YELLOW)
        surface.blit(a_surf, (card_x + 16, card_y + 60))

        # Q-Values visualization bars
        q_vals = telemetry.get("q_values", {})
        bar_base_y = card_y + 88
        for i, a_name in enumerate(ACTION_NAMES):
            val = q_vals.get(a_name, 0.0)
            is_chosen = (a_name == telemetry["action_name"])

            q_lbl = self.font_telemetry.render(f"{a_name[:5]:5s}: {val:+6.1f}", True, COLOR_WHITE if is_chosen else COLOR_MUTED)
            surface.blit(q_lbl, (card_x + 16, bar_base_y + i * 22))

            # Visual bar
            bar_len = max(0, min(140, int(abs(val) * 3.5)))
            bar_col = COLOR_GREEN if val >= 0 else COLOR_CRIMSON
            if is_chosen:
                bar_col = COLOR_YELLOW
            pygame.draw.rect(surface, bar_col, (card_x + 155, bar_base_y + i * 22 + 3, bar_len, 12), border_radius=2)

        # Natural language reason
        r_title = self.font_telemetry.render("RATIONALE:", True, COLOR_MUTED)
        surface.blit(r_title, (card_x + 16, card_y + 160))

        # Word wrap reason
        reason_txt = telemetry.get("reason", "")
        r_surf = self.font_body.render(reason_txt[:100], True, COLOR_OFFWHITE)
        surface.blit(r_surf, (card_x + 16, card_y + 180))
        if len(reason_txt) > 100:
            r_surf2 = self.font_body.render(reason_txt[100:200], True, COLOR_OFFWHITE)
            surface.blit(r_surf2, (card_x + 16, card_y + 200))

        hint_txt = self.font_telemetry.render("[ I ] or [ E ] to toggle overlay", True, COLOR_MUTED)
        surface.blit(hint_txt, (card_x + card_w - 220, card_y + card_h - 20))

    # -------------------------------------------------------------------------
    # 7. COUNTDOWN OVERLAY
    # -------------------------------------------------------------------------
    def render_countdown(self, surface: pygame.Surface, seconds_remaining: float) -> None:
        """Render 3, 2, 1, GO! starting countdown overlay."""
        text = "3"
        color = COLOR_YELLOW
        if seconds_remaining < 0.8:
            text = "GO!"
            color = COLOR_GREEN
        elif seconds_remaining < 1.8:
            text = "1"
            color = COLOR_YELLOW
        elif seconds_remaining < 2.8:
            text = "2"
            color = COLOR_ORANGE

        font_cd = pygame.font.SysFont("impact", 110)
        cd_surf = font_cd.render(text, True, color)
        cd_rect = cd_surf.get_rect(center=(WINDOW_WIDTH // 2, WINDOW_HEIGHT // 2 - 30))

        # Shadow
        shadow_surf = font_cd.render(text, True, (10, 12, 18))
        surface.blit(shadow_surf, cd_rect.move(4, 4))
        surface.blit(cd_surf, cd_rect)

    # -------------------------------------------------------------------------
    # 8. PAUSE SCREEN
    # -------------------------------------------------------------------------
    def render_pause_menu(self, surface: pygame.Surface, buttons: List[Button]) -> None:
        """Render pause dialog overlay."""
        overlay = pygame.Surface((WINDOW_WIDTH, WINDOW_HEIGHT), pygame.SRCALPHA)
        overlay.fill((10, 12, 18, 180))
        surface.blit(overlay, (0, 0))

        box_w = 420
        box_h = 320
        box_rect = pygame.Rect((WINDOW_WIDTH - box_w) // 2, (WINDOW_HEIGHT - box_h) // 2, box_w, box_h)
        pygame.draw.rect(surface, COLOR_DARK_CARD, box_rect, border_radius=12)
        pygame.draw.rect(surface, COLOR_CYAN, box_rect, 2, border_radius=12)

        title = self.font_heading.render("RACE PAUSED", True, COLOR_WHITE)
        surface.blit(title, title.get_rect(center=(WINDOW_WIDTH // 2, box_rect.y + 45)))

        mouse_pos = pygame.mouse.get_pos()
        for btn in buttons:
            btn.update(mouse_pos)
            btn.render(surface)

    # -------------------------------------------------------------------------
    # 9. RESULTS & GAME OVER SCREEN
    # -------------------------------------------------------------------------
    def render_results_screen(
        self,
        surface: pygame.Surface,
        winner_name: str,
        car_p1: Car,
        car_p2: Car,
        buttons: List[Button],
    ) -> None:
        """Render winner podium, race comparison metrics, and restart buttons."""
        surface.fill(COLOR_BG)

        # Winner Banner
        is_p1_win = ("Player 1" in winner_name)
        banner_col = COLOR_CYAN if is_p1_win else (COLOR_CRIMSON if car_p2.is_ai else COLOR_ORANGE)

        win_title = self.font_title.render(f"🏆 {winner_name.upper()} WINS! 🏆", True, banner_col)
        surface.blit(win_title, win_title.get_rect(center=(WINDOW_WIDTH // 2, 70)))

        sub = self.font_subtitle.render("Official Race Results & Performance Metrics", True, COLOR_MUTED)
        surface.blit(sub, sub.get_rect(center=(WINDOW_WIDTH // 2, 125)))

        # Comparison Table Card
        card_w = 900
        card_h = 380
        card_x = (WINDOW_WIDTH - card_w) // 2
        card_y = 160

        card_rect = pygame.Rect(card_x, card_y, card_w, card_h)
        pygame.draw.rect(surface, COLOR_DARK_CARD, card_rect, border_radius=12)
        pygame.draw.rect(surface, COLOR_CARD_BORDER, card_rect, 1, border_radius=12)

        # Header Columns
        pygame.draw.rect(surface, (28, 34, 46), (card_x, card_y, card_w, 42), border_top_left_radius=12, border_top_right_radius=12)

        lbl_metric = self.font_hud_small.render("METRIC", True, COLOR_YELLOW)
        lbl_p1 = self.font_hud_small.render("PLAYER 1", True, COLOR_CYAN)
        lbl_p2 = self.font_hud_small.render(car_p2.name.upper(), True, COLOR_CRIMSON if car_p2.is_ai else COLOR_ORANGE)

        surface.blit(lbl_metric, (card_x + 50, card_y + 14))
        surface.blit(lbl_p1, lbl_p1.get_rect(center=(card_x + 460, card_y + 21)))
        surface.blit(lbl_p2, lbl_p2.get_rect(center=(card_x + 730, card_y + 21)))

        metrics = [
            ("Final Score", f"{car_p1.score:,} pts", f"{car_p2.score:,} pts"),
            ("Finish Time", f"{car_p1.finish_time:.2f} s", f"{car_p2.finish_time:.2f} s"),
            ("Distance Covered", f"{int(car_p1.distance_traveled * METERS_PER_PIXEL)} m", f"{int(car_p2.distance_traveled * METERS_PER_PIXEL)} m"),
            ("Obstacles Passed", f"{car_p1.obstacles_passed}", f"{car_p2.obstacles_passed}"),
            ("Collisions Suffered", f"{car_p1.collisions_count}", f"{car_p2.collisions_count}"),
            ("Nitro Boosts Engaged", f"{car_p1.boosts_used}", f"{car_p2.boosts_used}"),
        ]

        for idx, (m_name, v1, v2) in enumerate(metrics):
            my = card_y + 60 + idx * 46
            if idx % 2 == 1:
                pygame.draw.rect(surface, (18, 22, 30), (card_x + 4, my - 8, card_w - 8, 40))

            m_lbl = self.font_body_bold.render(m_name, True, COLOR_WHITE)
            v1_lbl = self.font_body.render(v1, True, COLOR_OFFWHITE)
            v2_lbl = self.font_body.render(v2, True, COLOR_OFFWHITE)

            surface.blit(m_lbl, (card_x + 50, my))
            surface.blit(v1_lbl, v1_lbl.get_rect(center=(card_x + 460, my + 8)))
            surface.blit(v2_lbl, v2_lbl.get_rect(center=(card_x + 730, my + 8)))

        # Buttons (Play Again, Main Menu)
        mouse_pos = pygame.mouse.get_pos()
        for btn in buttons:
            btn.update(mouse_pos)
            btn.render(surface)
