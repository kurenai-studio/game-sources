"""
In-Engine Authentication Screen (Publication Grade).
Features Cyberpunk Terminal Styling, Database Connectivity Status,
Shake-on-Error Input Animation, and Seamless Guest Access.
"""

import time
import math
import pygame
from typing import Dict, Any, Tuple, Callable
from database.db_manager import DatabaseManager
from .widgets import Button, TextInput
from game.audio import SoundFX

class AuthScreen:
    """Publication-Grade In-Engine Authentication Terminal."""

    def __init__(self, surface_size: Tuple[int, int], on_auth_success: Callable[[Dict[str, Any]], None]):
        self.width, self.height = surface_size
        self.on_auth_success = on_auth_success
        self.db = DatabaseManager()

        self.font_title = pygame.font.SysFont("segoeui", 28, bold=True)
        self.font_mono = pygame.font.SysFont("consolas", 11, bold=True)
        self.font_label = pygame.font.SysFont("segoeui", 12, bold=True)
        self.font_status = pygame.font.SysFont("segoeui", 13)

        self.is_register_mode = False
        self.status_msg = ""
        self.status_color = (239, 71, 111)

        # Centered Container Card
        card_w, card_h = 460, 520
        self.card_rect = pygame.Rect((self.width - card_w) // 2, (self.height - card_h) // 2, card_w, card_h)

        # Inputs
        cx = self.card_rect.x + 45
        y = self.card_rect.y + 115
        input_w = 370

        self.input_user = TextInput(cx, y, input_w, 42, placeholder="Enter runner callsign")
        self.input_pass = TextInput(cx, y + 68, input_w, 42, placeholder="Enter security passphrase", is_password=True)
        self.input_age = TextInput(cx, y + 136, input_w, 42, placeholder="Age (e.g. 21)")

        # Buttons
        self.btn_submit = Button(cx, y + 208, input_w, 46, "AUTHENTICATE", callback=self._handle_submit, color=(0, 240, 255), text_color=(11, 14, 23))
        self.btn_toggle_mode = Button(cx, y + 264, input_w, 36, "Create New Account", callback=self._toggle_mode, color=(19, 24, 38), text_color=(142, 154, 175), font_size=12)
        self.btn_guest = Button(cx, y + 312, input_w, 40, "INSTANT GUEST PASS", callback=self._login_guest, color=(14, 34, 30), text_color=(6, 214, 160), accent_color=(6, 214, 160), font_size=13)

    def _toggle_mode(self):
        self.is_register_mode = not self.is_register_mode
        self.status_msg = ""
        if self.is_register_mode:
            self.btn_submit.text = "REGISTER RUNNER"
            self.btn_toggle_mode.text = "Already registered? Sign In"
        else:
            self.btn_submit.text = "AUTHENTICATE"
            self.btn_toggle_mode.text = "Create New Account"

    def _handle_submit(self):
        username = self.input_user.text.strip()
        password = self.input_pass.text.strip()

        if not username or not password:
            self.status_msg = "Please enter both username and password."
            self.status_color = (239, 71, 111)
            self.input_user.trigger_shake()
            self.input_pass.trigger_shake()
            SoundFX.play_defeat()
            return

        if self.is_register_mode:
            try:
                age = int(self.input_age.text.strip())
            except ValueError:
                age = 20
            ok, msg = self.db.register_user(username, password, age, "Unspecified")
            if ok:
                self.status_msg = "Account created! You can now authenticate."
                self.status_color = (6, 214, 160)
                SoundFX.play_victory()
                self._toggle_mode()
            else:
                self.status_msg = msg
                self.status_color = (239, 71, 111)
                self.input_user.trigger_shake()
                SoundFX.play_defeat()
        else:
            ok, user_data, msg = self.db.authenticate_user(username, password)
            if ok and user_data:
                SoundFX.play_click()
                self.on_auth_success(user_data)
            else:
                self.status_msg = msg
                self.status_color = (239, 71, 111)
                self.input_pass.trigger_shake()
                SoundFX.play_defeat()

    def _login_guest(self):
        guest_data = {"id": 1, "username": "Guest_Runner", "age": 22, "gender": "Other"}
        SoundFX.play_click()
        self.on_auth_success(guest_data)

    def handle_event(self, event: pygame.event.Event):
        self.input_user.handle_event(event)
        self.input_pass.handle_event(event)
        if self.is_register_mode:
            self.input_age.handle_event(event)

        self.btn_submit.handle_event(event)
        self.btn_toggle_mode.handle_event(event)
        self.btn_guest.handle_event(event)

        if event.type == pygame.KEYDOWN and event.key == pygame.K_RETURN:
            self._handle_submit()

    def update(self, dt: float):
        self.input_user.update(dt)
        self.input_pass.update(dt)
        self.input_age.update(dt)
        self.btn_submit.update(dt)
        self.btn_toggle_mode.update(dt)
        self.btn_guest.update(dt)

    def render(self, surface: pygame.Surface):
        surface.fill((11, 14, 23))

        # Ambient Grid Horizon Background
        for gy in range(self.height - 200, self.height, 25):
            alpha = int(((gy - (self.height - 200)) / 200) * 40)
            pygame.draw.line(surface, (20, 26, 42), (0, gy), (self.width, gy), 1)

        # Card Backdrop Shadow & Frame
        glow_rect = self.card_rect.inflate(16, 16)
        glow_surf = pygame.Surface((glow_rect.width, glow_rect.height), pygame.SRCALPHA)
        pygame.draw.rect(glow_surf, (0, 240, 255, 20), glow_surf.get_rect(), border_radius=16)
        surface.blit(glow_surf, glow_rect.topleft)

        pygame.draw.rect(surface, (19, 24, 38), self.card_rect, border_radius=12)
        pygame.draw.rect(surface, (34, 43, 66), self.card_rect, width=1, border_radius=12)

        # Tactical Corner Marks
        c_len = 16
        cr = self.card_rect
        pygame.draw.line(surface, (0, 240, 255), (cr.x, cr.y), (cr.x + c_len, cr.y), 2)
        pygame.draw.line(surface, (0, 240, 255), (cr.x, cr.y), (cr.x, cr.y + c_len), 2)
        pygame.draw.line(surface, (0, 240, 255), (cr.right - c_len, cr.bottom), (cr.right, cr.bottom), 2)
        pygame.draw.line(surface, (0, 240, 255), (cr.right, cr.bottom - c_len), (cr.right, cr.bottom), 2)

        # Top System Status Indicator
        pulse = 0.5 + 0.5 * math.sin(time.time() * 4.0)
        led_alpha = int(180 + 75 * pulse)
        led_surf = pygame.Surface((10, 10), pygame.SRCALPHA)
        pygame.draw.circle(led_surf, (6, 214, 160, led_alpha), (5, 5), 4)
        surface.blit(led_surf, (cr.x + 24, cr.y + 22))

        status_tag = self.font_mono.render("GRID ACCESS TERMINAL // SECURE PBKDF2", True, (142, 154, 175))
        surface.blit(status_tag, (cr.x + 40, cr.y + 18))

        # Title
        title_text = "RUNNER AUTH" if not self.is_register_mode else "NEW RUNNER ENROLL"
        title_surf = self.font_title.render(title_text, True, (0, 240, 255))
        surface.blit(title_surf, (cr.centerx - title_surf.get_width() // 2, cr.y + 45))

        # Labels
        lbl_u = self.font_label.render("CALLSIGN", True, (142, 154, 175))
        surface.blit(lbl_u, (self.input_user.rect.x, self.input_user.rect.y - 18))
        self.input_user.draw(surface)

        lbl_p = self.font_label.render("SECURITY PASSPHRASE", True, (142, 154, 175))
        surface.blit(lbl_p, (self.input_pass.rect.x, self.input_pass.rect.y - 18))
        self.input_pass.draw(surface)

        if self.is_register_mode:
            lbl_a = self.font_label.render("AGE", True, (142, 154, 175))
            surface.blit(lbl_a, (self.input_age.rect.x, self.input_age.rect.y - 18))
            self.input_age.draw(surface)

        # Status Message
        if self.status_msg:
            msg_surf = self.font_status.render(self.status_msg, True, self.status_color)
            surface.blit(msg_surf, (cr.centerx - msg_surf.get_width() // 2, cr.y + 360))

        # Buttons
        self.btn_submit.draw(surface)
        self.btn_toggle_mode.draw(surface)
        self.btn_guest.draw(surface)
