"""
Cyberpunk UI Component Library (Publication Grade).
Features Chamfered Buttons, Glowing Inputs, Animated Sliders,
Tactile Audio Integration, and Micro-Animations.
"""

import time
import math
import pygame
from typing import Tuple, Optional, Callable, List
from game.audio import SoundFX

Color = Tuple[int, int, int]

class Button:
    """Publication-Grade Cyberpunk Interactive Button."""

    def __init__(
        self,
        x: int,
        y: int,
        width: int,
        height: int,
        text: str,
        callback: Optional[Callable] = None,
        color: Color = (19, 24, 38),
        hover_color: Color = (0, 240, 255),
        text_color: Color = (248, 249, 250),
        font_size: int = 15,
        border_radius: int = 6,
        shortcut: str = "",
        accent_color: Optional[Color] = None
    ):
        self.rect = pygame.Rect(x, y, width, height)
        self.base_y = y
        self.text = text
        self.callback = callback
        self.color = color
        self.hover_color = hover_color
        self.text_color = text_color
        self.accent_color = accent_color or (0, 240, 255)
        self.font = pygame.font.SysFont("segoeui", font_size, bold=True)
        self.font_sub = pygame.font.SysFont("consolas", 11, bold=True)
        self.border_radius = border_radius
        self.shortcut = shortcut

        self.is_hovered = False
        self.is_pressed = False
        self.hover_anim = 0.0  # 0.0 to 1.0 smooth interpolation

    def handle_event(self, event: pygame.event.Event) -> bool:
        if event.type == pygame.MOUSEMOTION:
            prev_hover = self.is_hovered
            self.is_hovered = self.rect.collidepoint(event.pos)
            if self.is_hovered and not prev_hover:
                SoundFX.play_hover()

        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.rect.collidepoint(event.pos):
                self.is_pressed = True

        elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
            if self.is_pressed and self.rect.collidepoint(event.pos):
                self.is_pressed = False
                SoundFX.play_click()
                if self.callback:
                    self.callback()
                return True
            self.is_pressed = False
        return False

    def update(self, dt: float):
        target = 1.0 if self.is_hovered else 0.0
        self.hover_anim += (target - self.hover_anim) * min(1.0, 16.0 * dt)

    def draw(self, surface: pygame.Surface):
        # Micro-elevation on hover (-2px)
        elev = int(self.hover_anim * 2.0)
        draw_rect = pygame.Rect(self.rect.x, self.base_y - elev, self.rect.width, self.rect.height)

        # 1. Soft Ambient Outer Glow on hover
        if self.hover_anim > 0.05:
            glow_w = draw_rect.width + 12
            glow_h = draw_rect.height + 12
            glow_surf = pygame.Surface((glow_w, glow_h), pygame.SRCALPHA)
            alpha = int(self.hover_anim * 50)
            r, g, b = self.accent_color
            pygame.draw.rect(glow_surf, (r, g, b, alpha), glow_surf.get_rect(), border_radius=self.border_radius + 4)
            surface.blit(glow_surf, (draw_rect.x - 6, draw_rect.y - 6))

        # 2. Button Fill
        if self.is_hovered and self.hover_color == (0, 240, 255):
            bg_col = (0, 240, 255)
            border_col = (255, 255, 255)
            txt_col = (11, 14, 23)
        else:
            # Interpolate background towards dark card hover
            bg_col = self.color if not self.is_hovered else (27, 34, 53)
            border_col = self.accent_color if self.is_hovered else (34, 43, 66)
            txt_col = self.text_color

        pygame.draw.rect(surface, bg_col, draw_rect, border_radius=self.border_radius)
        pygame.draw.rect(surface, border_col, draw_rect, width=1 if not self.is_hovered else 2, border_radius=self.border_radius)

        # 3. Tactical Corner Notches
        if self.is_hovered:
            corner_len = 8
            # Top-left corner mark
            pygame.draw.line(surface, self.accent_color, (draw_rect.x, draw_rect.y), (draw_rect.x + corner_len, draw_rect.y), 2)
            pygame.draw.line(surface, self.accent_color, (draw_rect.x, draw_rect.y), (draw_rect.x, draw_rect.y + corner_len), 2)
            # Bottom-right corner mark
            pygame.draw.line(surface, self.accent_color, (draw_rect.right - corner_len, draw_rect.bottom), (draw_rect.right, draw_rect.bottom), 2)
            pygame.draw.line(surface, self.accent_color, (draw_rect.right, draw_rect.bottom - corner_len), (draw_rect.right, draw_rect.bottom), 2)

        # 4. Text Label
        txt_surf = self.font.render(self.text, True, txt_col)
        txt_rect = txt_surf.get_rect(center=draw_rect.center)

        if self.shortcut:
            # Shift text slightly left to accommodate shortcut badge on right
            txt_rect.centerx -= 16
            surface.blit(txt_surf, txt_rect)
            sc_col = (142, 154, 175) if not self.is_hovered else (11, 14, 23)
            sc_surf = self.font_sub.render(self.shortcut, True, sc_col)
            surface.blit(sc_surf, (draw_rect.right - sc_surf.get_width() - 14, draw_rect.centery - sc_surf.get_height() // 2))
        else:
            surface.blit(txt_surf, txt_rect)


class TextInput:
    """Cyberpunk Text Input with Sound, Blinking Caret & Shake on Error."""

    def __init__(
        self,
        x: int,
        y: int,
        width: int,
        height: int,
        placeholder: str = "",
        is_password: bool = False,
        font_size: int = 15,
        max_chars: int = 30
    ):
        self.rect = pygame.Rect(x, y, width, height)
        self.base_x = x
        self.text = ""
        self.placeholder = placeholder
        self.is_password = is_password
        self.max_chars = max_chars
        self.font = pygame.font.SysFont("segoeui", font_size)
        self.active = False
        self.cursor_visible = True
        self.last_cursor_toggle = time.time()

        # Error shake animation
        self.shake_time = 0.0

    def trigger_shake(self):
        self.shake_time = 0.25

    def handle_event(self, event: pygame.event.Event) -> bool:
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            prev = self.active
            self.active = self.rect.collidepoint(event.pos)
            if self.active and not prev:
                SoundFX.play_click()
            return self.active

        elif event.type == pygame.KEYDOWN and self.active:
            if event.key == pygame.K_BACKSPACE:
                if len(self.text) > 0:
                    self.text = self.text[:-1]
                    SoundFX.play_step()
            elif event.key in (pygame.K_RETURN, pygame.K_TAB):
                return True
            else:
                if len(event.unicode) > 0 and event.unicode.isprintable():
                    if len(self.text) < self.max_chars:
                        self.text += event.unicode
                        SoundFX.play_step()
            return True
        return False

    def update(self, dt: float):
        if self.shake_time > 0:
            self.shake_time -= dt
            offset = int(math.sin(self.shake_time * 50.0) * 6.0)
            self.rect.x = self.base_x + offset
        else:
            self.rect.x = self.base_x

    def draw(self, surface: pygame.Surface):
        border_col = (0, 240, 255) if self.active else (34, 43, 66)
        bg_col = (24, 30, 48) if self.active else (18, 22, 34)

        # Outer active glow
        if self.active:
            glow_rect = self.rect.inflate(6, 6)
            glow_surf = pygame.Surface((glow_rect.width, glow_rect.height), pygame.SRCALPHA)
            pygame.draw.rect(glow_surf, (0, 240, 255, 40), glow_surf.get_rect(), border_radius=8)
            surface.blit(glow_surf, glow_rect.topleft)

        pygame.draw.rect(surface, bg_col, self.rect, border_radius=6)
        pygame.draw.rect(surface, border_col, self.rect, width=2 if self.active else 1, border_radius=6)

        # Display text or placeholder
        if self.text:
            display_text = "*" * len(self.text) if self.is_password else self.text
            txt_surf = self.font.render(display_text, True, (248, 249, 250))
        else:
            txt_surf = self.font.render(self.placeholder, True, (92, 103, 125))

        surface.blit(txt_surf, (self.rect.x + 14, self.rect.centery - txt_surf.get_height() // 2))

        # Blinking vertical caret
        if self.active:
            if time.time() - self.last_cursor_toggle > 0.45:
                self.cursor_visible = not self.cursor_visible
                self.last_cursor_toggle = time.time()

            if self.cursor_visible:
                cx = self.rect.x + 14 + (txt_surf.get_width() if self.text else 0) + 2
                cy1 = self.rect.centery - 10
                cy2 = self.rect.centery + 10
                pygame.draw.line(surface, (0, 240, 255), (cx, cy1), (cx, cy2), 2)


class CyberToggle:
    """Animated Pill Toggle Switch [ENABLED / DISABLED]."""

    def __init__(
        self,
        x: int,
        y: int,
        width: int = 120,
        height: int = 34,
        initial_state: bool = True,
        on_toggle: Optional[Callable[[bool], None]] = None
    ):
        self.rect = pygame.Rect(x, y, width, height)
        self.state = initial_state
        self.on_toggle = on_toggle
        self.font = pygame.font.SysFont("consolas", 11, bold=True)
        self.anim_val = 1.0 if initial_state else 0.0

    def handle_event(self, event: pygame.event.Event) -> bool:
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.rect.collidepoint(event.pos):
                self.state = not self.state
                SoundFX.play_click()
                if self.on_toggle:
                    self.on_toggle(self.state)
                return True
        return False

    def update(self, dt: float):
        target = 1.0 if self.state else 0.0
        self.anim_val += (target - self.anim_val) * min(1.0, 16.0 * dt)

    def draw(self, surface: pygame.Surface):
        bg_col = (18, 22, 34)
        border_col = (6, 214, 160) if self.state else (239, 71, 111)

        pygame.draw.rect(surface, bg_col, self.rect, border_radius=17)
        pygame.draw.rect(surface, border_col, self.rect, width=1, border_radius=17)

        # Sliding Knob
        knob_w = self.rect.width // 2
        knob_x = self.rect.x + int(self.anim_val * (self.rect.width - knob_w))
        knob_rect = pygame.Rect(knob_x, self.rect.y + 2, knob_w, self.rect.height - 4)

        knob_col = (6, 214, 160) if self.state else (239, 71, 111)
        pygame.draw.rect(surface, knob_col, knob_rect, border_radius=15)

        txt_str = "ON" if self.state else "OFF"
        txt_surf = self.font.render(txt_str, True, (11, 14, 23))
        surface.blit(txt_surf, txt_surf.get_rect(center=knob_rect.center))


class CyberSlider:
    """Publication-Grade Draggable Slider for Volume & Numeric Adjustments."""

    def __init__(
        self,
        x: int,
        y: int,
        width: int = 200,
        height: int = 24,
        min_val: float = 0.0,
        max_val: float = 1.0,
        initial_val: float = 1.0,
        on_change: Optional[Callable[[float], None]] = None,
        accent_color: Color = (0, 240, 255),
        format_pct: bool = True
    ):
        self.rect = pygame.Rect(x, y, width, height)
        self.min_val = min_val
        self.max_val = max_val
        self.value = max(min_val, min(max_val, initial_val))
        self.on_change = on_change
        self.accent_color = accent_color
        self.format_pct = format_pct
        self.font = pygame.font.SysFont("consolas", 11, bold=True)

        self.is_dragging = False
        self.is_hovered = False
        self.hover_anim = 0.0

    def get_normalized(self) -> float:
        """Returns 0.0 to 1.0 representing current position."""
        if self.max_val == self.min_val:
            return 0.0
        return (self.value - self.min_val) / (self.max_val - self.min_val)

    def set_normalized(self, norm: float):
        norm = max(0.0, min(1.0, norm))
        new_val = self.min_val + norm * (self.max_val - self.min_val)
        if abs(new_val - self.value) > 0.001:
            self.value = new_val
            if self.on_change:
                self.on_change(self.value)

    def set_value(self, val: float):
        self.value = max(self.min_val, min(self.max_val, val))

    def handle_event(self, event: pygame.event.Event) -> bool:
        if event.type == pygame.MOUSEMOTION:
            thumb_radius = self.rect.height // 2 + 4
            norm = self.get_normalized()
            thumb_x = self.rect.x + int(norm * self.rect.width)
            thumb_rect = pygame.Rect(thumb_x - thumb_radius, self.rect.centery - thumb_radius, thumb_radius * 2, thumb_radius * 2)

            self.is_hovered = self.rect.collidepoint(event.pos) or thumb_rect.collidepoint(event.pos)

            if self.is_dragging:
                rel_x = event.pos[0] - self.rect.x
                norm = rel_x / max(1, self.rect.width)
                self.set_normalized(norm)
                return True

        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            thumb_radius = self.rect.height // 2 + 6
            norm = self.get_normalized()
            thumb_x = self.rect.x + int(norm * self.rect.width)
            hit_rect = self.rect.inflate(12, 12)

            if hit_rect.collidepoint(event.pos):
                self.is_dragging = True
                rel_x = event.pos[0] - self.rect.x
                norm = rel_x / max(1, self.rect.width)
                self.set_normalized(norm)
                SoundFX.play_click()
                return True

        elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
            if self.is_dragging:
                self.is_dragging = False
                return True

        return False

    def update(self, dt: float):
        target = 1.0 if (self.is_hovered or self.is_dragging) else 0.0
        self.hover_anim += (target - self.hover_anim) * min(1.0, 16.0 * dt)

    def draw(self, surface: pygame.Surface):
        # 1. Background Groove Track
        track_h = 8
        track_y = self.rect.centery - track_h // 2
        track_rect = pygame.Rect(self.rect.x, track_y, self.rect.width, track_h)
        pygame.draw.rect(surface, (18, 22, 34), track_rect, border_radius=4)
        pygame.draw.rect(surface, (34, 43, 66), track_rect, width=1, border_radius=4)

        # 2. Progress Fill Bar
        norm = self.get_normalized()
        fill_w = max(4, int(norm * self.rect.width))
        fill_rect = pygame.Rect(self.rect.x, track_y, fill_w, track_h)
        pygame.draw.rect(surface, self.accent_color, fill_rect, border_radius=4)

        # 3. Draggable Thumb Knob
        thumb_x = self.rect.x + int(norm * self.rect.width)
        thumb_y = self.rect.centery
        thumb_radius = 8 + int(self.hover_anim * 2.0)

        # Outer Glow around thumb on hover/drag
        if self.hover_anim > 0.05:
            glow_surf = pygame.Surface((thumb_radius * 4, thumb_radius * 4), pygame.SRCALPHA)
            alpha = int(self.hover_anim * 60)
            r, g, b = self.accent_color
            pygame.draw.circle(glow_surf, (r, g, b, alpha), (thumb_radius * 2, thumb_radius * 2), thumb_radius + 4)
            surface.blit(glow_surf, (thumb_x - thumb_radius * 2, thumb_y - thumb_radius * 2))

        # Thumb Circle
        pygame.draw.circle(surface, self.accent_color, (thumb_x, thumb_y), thumb_radius)
        pygame.draw.circle(surface, (11, 14, 23), (thumb_x, thumb_y), max(2, thumb_radius - 3))

        # 4. Text Value Label to right of slider
        if self.format_pct:
            pct_val = int(norm * 100)
            val_text = f"{pct_val}%"
        else:
            val_text = f"{self.value:.1f}"

        txt_surf = self.font.render(val_text, True, (248, 249, 250) if self.hover_anim > 0.3 else (142, 154, 175))
        surface.blit(txt_surf, (self.rect.right + 12, self.rect.centery - txt_surf.get_height() // 2))

