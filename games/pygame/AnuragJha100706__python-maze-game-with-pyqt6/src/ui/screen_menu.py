"""
Main Title Menu Screen (Publication Grade).
Features Parallax Starfield, Animated Cyber Horizon Grid, Glowing Title Treatment,
Keyboard Shortcut Listeners, and Runner Profile HUD.
"""

import math
import random
import pygame
from typing import Dict, Any, Tuple, Callable
from .widgets import Button

class MainMenuScreen:
    """Publication-Grade Main Title & Navigation Menu."""

    def __init__(
        self,
        surface_size: Tuple[int, int],
        on_navigate: Callable[[str], None],
        user_data: Dict[str, Any]
    ):
        self.width, self.height = surface_size
        self.on_navigate = on_navigate
        self.user_data = user_data

        self.font_logo = pygame.font.SysFont("segoeui", 58, bold=True)
        self.font_sub = pygame.font.SysFont("segoeui", 14, bold=True)
        self.font_badge = pygame.font.SysFont("consolas", 11, bold=True)
        self.font_user = pygame.font.SysFont("segoeui", 13, bold=True)

        # Multi-layer Parallax Starfield
        self.stars_deep = [
            [random.randint(0, self.width), random.randint(0, self.height), random.uniform(0.4, 1.2)]
            for _ in range(70)
        ]
        self.stars_near = [
            [random.randint(0, self.width), random.randint(0, self.height), random.uniform(1.8, 3.0)]
            for _ in range(25)
        ]
        self.stars = self.stars_deep
        self.grid_offset = 0.0

        # Menu Buttons with Keyboard Shortcuts
        btn_w, btn_h = 340, 52
        cx = (self.width - btn_w) // 2
        start_y = 280
        gap = 64

        self.buttons = [
            Button(cx, start_y, btn_w, btn_h, "PLAY MISSION", lambda: self.on_navigate("MODE_SELECT"), color=(0, 240, 255), text_color=(11, 14, 23), shortcut="[P]"),
            Button(cx, start_y + gap, btn_w, btn_h, "HALL OF FAME", lambda: self.on_navigate("LEADERBOARD"), shortcut="[H]"),
            Button(cx, start_y + gap * 2, btn_w, btn_h, "SETTINGS", lambda: self.on_navigate("SETTINGS"), shortcut="[S]"),
            Button(cx, start_y + gap * 3, btn_w, btn_h, "SWITCH RUNNER", lambda: self.on_navigate("AUTH"), color=(19, 24, 38), font_size=13, shortcut="[U]"),
            Button(cx, start_y + gap * 4, btn_w, btn_h, "EXIT GAME", lambda: self.on_navigate("EXIT"), color=(19, 24, 38), hover_color=(239, 71, 111), font_size=13, shortcut="[ESC]")
        ]

    def set_user(self, user_data: Dict[str, Any]):
        self.user_data = user_data

    def handle_event(self, event: pygame.event.Event):
        for btn in self.buttons:
            btn.handle_event(event)

        # Keyboard Navigation Shortcuts
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_p:
                self.on_navigate("MODE_SELECT")
            elif event.key == pygame.K_h:
                self.on_navigate("LEADERBOARD")
            elif event.key == pygame.K_s:
                self.on_navigate("SETTINGS")
            elif event.key == pygame.K_u:
                self.on_navigate("AUTH")
            elif event.key == pygame.K_ESCAPE:
                self.on_navigate("EXIT")

    def update(self, dt: float):
        # Update Parallax Starfield
        for s in self.stars_deep:
            s[1] += s[2] * 12 * dt
            if s[1] > self.height:
                s[1] = 0
                s[0] = random.randint(0, self.width)

        for s in self.stars_near:
            s[1] += s[2] * 28 * dt
            if s[1] > self.height:
                s[1] = 0
                s[0] = random.randint(0, self.width)

        # Animated Horizon Grid scroll
        self.grid_offset = (self.grid_offset + 30 * dt) % 40.0

        for btn in self.buttons:
            btn.update(dt)

    def render(self, surface: pygame.Surface):
        surface.fill((11, 14, 23))

        # Render Deep Stars
        for s in self.stars_deep:
            b = int(min(255, s[2] * 80))
            pygame.draw.circle(surface, (b, b, b), (int(s[0]), int(s[1])), 1)

        # Render Horizon Perspective Grid (Bottom 180px)
        horizon_y = self.height - 180
        for i in range(12):
            y = horizon_y + int((i / 11.0) ** 2 * 180) + int(self.grid_offset) % 18
            if y < self.height:
                alpha = int(((y - horizon_y) / 180.0) * 45)
                pygame.draw.line(surface, (18, 30, 48), (0, y), (self.width, y), 1)

        cx = self.width // 2
        for gx in range(0, self.width + 100, 70):
            pygame.draw.line(surface, (18, 30, 48), (cx, horizon_y), (gx, self.height), 1)

        # Render Near Stars
        for s in self.stars_near:
            b = int(min(255, s[2] * 70))
            pygame.draw.circle(surface, (0, b, b + 40), (int(s[0]), int(s[1])), int(s[2]))

        # Pulse Title Glow
        pulse = 0.5 + 0.5 * math.sin(pygame.time.get_ticks() / 350.0)

        # Chromatic / Glow Background Layer
        glow_alpha = int(40 + 30 * pulse)
        glow_surf = self.font_logo.render("CYBER MAZE RUNNER", True, (0, 180, 200))
        surface.blit(glow_surf, (cx - glow_surf.get_width() // 2, 90))

        # Sharp Foreground Title
        title_surf = self.font_logo.render("CYBER MAZE RUNNER", True, (0, 240, 255))
        surface.blit(title_surf, (cx - title_surf.get_width() // 2 - 1, 88))

        # Subtitle & Release Tag
        sub_surf = self.font_sub.render("// 60 FPS PURE CYBER GRID ACTION //", True, (142, 154, 175))
        surface.blit(sub_surf, (cx - sub_surf.get_width() // 2, 160))

        ver_surf = self.font_badge.render("[ v2.4.0 FINAL RELEASE ]", True, (6, 214, 160))
        surface.blit(ver_surf, (cx - ver_surf.get_width() // 2, 190))

        # Top-Right Runner Status Pill
        user_name = str(self.user_data.get("username", "Guest")).upper()
        user_text = f"RUNNER: {user_name}"
        u_surf = self.font_user.render(user_text, True, (6, 214, 160))
        pill_w = u_surf.get_width() + 32
        pill_rect = pygame.Rect(self.width - pill_w - 35, 25, pill_w, 34)

        pygame.draw.rect(surface, (19, 24, 38), pill_rect, border_radius=17)
        pygame.draw.rect(surface, (34, 43, 66), pill_rect, width=1, border_radius=17)

        # Pulse online LED
        pygame.draw.circle(surface, (6, 214, 160), (pill_rect.x + 14, pill_rect.centery), 4)
        surface.blit(u_surf, (pill_rect.x + 24, pill_rect.centery - u_surf.get_height() // 2))

        # Draw Menu Buttons
        for btn in self.buttons:
            btn.draw(surface)
