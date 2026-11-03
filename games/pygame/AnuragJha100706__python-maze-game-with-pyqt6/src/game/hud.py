"""
In-Game Telemetry & HUD Renderer (Publication Grade).
Draws live millisecond digital stopwatches, key gauges, wall breaker charges,
tactical threat proximity radars, and game over overlays onto the viewport.
"""

import math
import time
import pygame
from typing import Dict, Any, Optional

class GameHUD:
    """Publication-Grade Real-Time Telemetry HUD Overlay."""

    def __init__(self, width: int, hud_height: int = 60):
        self.width = width
        self.height = hud_height
        pygame.font.init()
        self.font_title = pygame.font.SysFont("segoeui", 13, bold=True)
        self.font_mono = pygame.font.SysFont("consolas", 15, bold=True)
        self.font_small = pygame.font.SysFont("segoeui", 12)
        self.font_badge = pygame.font.SysFont("consolas", 11, bold=True)
        self.font_big = pygame.font.SysFont("segoeui", 32, bold=True)

    def draw_hud(self, surface: pygame.Surface, telemetry: Dict[str, Any]):
        """Renders bottom tactical telemetry bar onto the viewport."""
        w = surface.get_width()
        h = surface.get_height()
        hud_rect = pygame.Rect(0, h - self.height, w, self.height)

        # Titanium dark background
        pygame.draw.rect(surface, (16, 21, 33), hud_rect)
        pygame.draw.line(surface, (0, 240, 255), (0, hud_rect.top), (w, hud_rect.top), 2)

        mode_id = telemetry.get("mode_id", 0)
        elapsed_sec = telemetry.get("elapsed_time", 0.0)
        steps = telemetry.get("steps", 0)

        # 1. Mode Badge Pill (Left)
        badge_text = telemetry.get("mode_badge", f"MODE {mode_id}")
        badge_pill = pygame.Rect(20, hud_rect.centery - 16, 95, 32)
        pygame.draw.rect(surface, (24, 30, 48), badge_pill, border_radius=16)
        pygame.draw.rect(surface, (0, 240, 255), badge_pill, width=1, border_radius=16)

        b_surf = self.font_badge.render(badge_text, True, (0, 240, 255))
        surface.blit(b_surf, b_surf.get_rect(center=badge_pill.center))

        mode_name = telemetry.get("mode_name", "Cyber Grid")
        n_surf = self.font_title.render(mode_name, True, (248, 249, 250))
        surface.blit(n_surf, (126, hud_rect.centery - n_surf.get_height() // 2))

        # 2. Digital Stopwatch
        t_box = pygame.Rect(300, hud_rect.centery - 15, 120, 30)
        pygame.draw.rect(surface, (11, 14, 23), t_box, border_radius=6)
        pygame.draw.rect(surface, (34, 43, 66), t_box, width=1, border_radius=6)
        time_str = f"TIME: {elapsed_sec:05.2f}s"
        t_surf = self.font_mono.render(time_str, True, (6, 214, 160))
        surface.blit(t_surf, t_surf.get_rect(center=t_box.center))

        # 3. Steps Counter
        st_box = pygame.Rect(432, hud_rect.centery - 15, 110, 30)
        pygame.draw.rect(surface, (11, 14, 23), st_box, border_radius=6)
        pygame.draw.rect(surface, (34, 43, 66), st_box, width=1, border_radius=6)
        step_str = f"STEPS: {steps}"
        st_surf = self.font_badge.render(step_str, True, (248, 249, 250))
        surface.blit(st_surf, st_surf.get_rect(center=st_box.center))

        # 4. Mode-Specific Telemetry (Center-Right)
        if mode_id == 4:  # Escape Heist
            keys_left = telemetry.get("keys_left", 0)
            wall_breaks = telemetry.get("wall_breaks", 0)

            k_str = f"KEYS: {8 - keys_left}/8"
            k_surf = self.font_mono.render(k_str, True, (255, 183, 3) if keys_left > 0 else (6, 214, 160))
            surface.blit(k_surf, (560, hud_rect.centery - k_surf.get_height() // 2))

            wb_str = f"BREAKERS: {wall_breaks} [SPACE]"
            wb_surf = self.font_mono.render(wb_str, True, (157, 78, 221) if wall_breaks > 0 else (92, 103, 125))
            surface.blit(wb_surf, (715, hud_rect.centery - wb_surf.get_height() // 2))

        elif mode_id == 3:  # Chase Survival
            ai_dist = telemetry.get("ai_distance", 99)
            if ai_dist <= 4:
                alert_col = (239, 71, 111)
                alert_text = f"!! RADAR ALERT: HUNTER {ai_dist:.0f} TILES AWAY !!"
            else:
                alert_col = (255, 183, 3)
                alert_text = f"RADAR: Hunter distance {ai_dist:.0f} tiles"
            r_surf = self.font_title.render(alert_text, True, alert_col)
            surface.blit(r_surf, (560, hud_rect.centery - r_surf.get_height() // 2))

        elif mode_id == 1:  # Two Player PvP
            p1_dist = telemetry.get("p1_dist", 0)
            p2_dist = telemetry.get("p2_dist", 0)
            pvp_text = f"P1 (Cyan): {p1_dist:.0f}m  |  P2 (Purple): {p2_dist:.0f}m"
            pvp_surf = self.font_mono.render(pvp_text, True, (0, 240, 255))
            surface.blit(pvp_surf, (560, hud_rect.centery - pvp_surf.get_height() // 2))

        elif mode_id == 2:  # Race vs AI
            ai_dist = telemetry.get("ai_dist_to_goal", 0)
            p_dist = telemetry.get("p_dist_to_goal", 0)
            lead = ai_dist - p_dist
            status_lead = f"(Lead: +{lead:.0f}m)" if lead >= 0 else f"(Lag: {lead:.0f}m)"
            race_text = f"YOU: {p_dist:.0f}m  vs  AI: {ai_dist:.0f}m  {status_lead}"
            race_surf = self.font_mono.render(race_text, True, (255, 183, 3))
            surface.blit(race_surf, (560, hud_rect.centery - race_surf.get_height() // 2))

        # Instructions (Far Right)
        controls_surf = self.font_small.render("[Arrows / WASD] Move  [ESC] Pause", True, (142, 154, 175))
        surface.blit(controls_surf, (w - controls_surf.get_width() - 20, hud_rect.centery - controls_surf.get_height() // 2))

    def draw_game_over(self, surface: pygame.Surface, won: bool, title_text: str, subtitle_text: str):
        """Draws modal overlay when round completes."""
        w = surface.get_width()
        h = surface.get_height()
        overlay = pygame.Surface((w, h), pygame.SRCALPHA)
        overlay.fill((11, 14, 23, 220))
        surface.blit(overlay, (0, 0))

        cx = w // 2
        cy = h // 2

        # Modal Box
        box_w, box_h = 560, 240
        box_rect = pygame.Rect(cx - box_w // 2, cy - box_h // 2, box_w, box_h)
        border_col = (6, 214, 160) if won else (239, 71, 111)

        # Ambient Glow
        glow_surf = pygame.Surface((box_w + 16, box_h + 16), pygame.SRCALPHA)
        pygame.draw.rect(glow_surf, (*border_col, 40), glow_surf.get_rect(), border_radius=16)
        surface.blit(glow_surf, (box_rect.x - 8, box_rect.y - 8))

        pygame.draw.rect(surface, (19, 24, 38), box_rect, border_radius=12)
        pygame.draw.rect(surface, border_col, box_rect, width=2, border_radius=12)

        # Corner notches
        c_len = 16
        pygame.draw.line(surface, border_col, (box_rect.x, box_rect.y), (box_rect.x + c_len, box_rect.y), 3)
        pygame.draw.line(surface, border_col, (box_rect.x, box_rect.y), (box_rect.x, box_rect.y + c_len), 3)
        pygame.draw.line(surface, border_col, (box_rect.right - c_len, box_rect.bottom), (box_rect.right, box_rect.bottom), 3)
        pygame.draw.line(surface, border_col, (box_rect.right, box_rect.bottom - c_len), (box_rect.right, box_rect.bottom), 3)

        title_surf = self.font_big.render(title_text, True, border_col)
        surface.blit(title_surf, (cx - title_surf.get_width() // 2, box_rect.y + 36))

        sub_surf = self.font_mono.render(subtitle_text, True, (248, 249, 250))
        surface.blit(sub_surf, (cx - sub_surf.get_width() // 2, box_rect.y + 95))

        # Pulsating continue prompt
        pulse = 0.5 + 0.5 * math.sin(time.time() * 5.0)
        p_col = (int(0 + 240 * pulse), int(240 * pulse), 255)
        prompt_surf = self.font_title.render("Press [ENTER] to return to Mode Select  or  [R] to Retry", True, p_col)
        surface.blit(prompt_surf, (cx - prompt_surf.get_width() // 2, box_rect.y + 155))
