"""
Settings Screen (Publication Grade).
Allows players to customize maze generation algorithms, default grid dimensions,
visual particle effects, master & SFX volume sliders, display modes, and gamepad controllers.
Persists all selections directly to SQLite.
"""

import pygame
from typing import Dict, Any, Tuple, Callable, Optional
from .widgets import Button, CyberToggle, CyberSlider
from database.db_manager import DatabaseManager
from game.audio import SoundFX

class SettingsScreen:
    """Publication-Grade Dual-Column Settings UI in Pure Pygame."""

    def __init__(
        self,
        surface_size: Tuple[int, int],
        on_back: Callable[[], None],
        display_mgr: Optional[Any] = None,
        input_mgr: Optional[Any] = None
    ):
        self.width, self.height = surface_size
        self.on_back = on_back
        self.display_mgr = display_mgr
        self.input_mgr = input_mgr
        self.db = DatabaseManager()

        self.font_title = pygame.font.SysFont("segoeui", 26, bold=True)
        self.font_sub = pygame.font.SysFont("segoeui", 13)
        self.font_section = pygame.font.SysFont("segoeui", 14, bold=True)
        self.font_label = pygame.font.SysFont("segoeui", 12, bold=True)
        self.font_hint = pygame.font.SysFont("segoeui", 11)
        self.font_status = pygame.font.SysFont("segoeui", 13, bold=True)
        self.font_badge = pygame.font.SysFont("consolas", 11, bold=True)

        self.grid_size = 20
        self.generator_algo = "kruskal"
        self.particles_enabled = True
        self.sfx_enabled = True
        self.master_vol = 1.0
        self.sfx_vol = 1.0

        self.status_msg = ""
        self.status_timer = 0.0

        self._load_settings()

        # Top Navigation & Bottom Save Button
        self.btn_back = Button(40, 24, 110, 38, "BACK", self._handle_back, color=(19, 24, 38), font_size=13, shortcut="[ESC]")
        self.btn_save = Button(self.width // 2 - 130, 632, 260, 46, "SAVE CONFIGURATION", self._save_settings, color=(0, 240, 255), text_color=(11, 14, 23), font_size=14)

        # --- LEFT COLUMN: Generation & Display ---
        lx = 135
        # Grid Dimension buttons
        self.grid_buttons = []
        sizes = [15, 20, 25, 30, 35]
        for i, s in enumerate(sizes):
            b = Button(lx + i * 86, 172, 76, 34, f"{s}x{s}", lambda sz=s: self._set_grid(sz), font_size=12)
            self.grid_buttons.append((s, b))

        # Algorithm Selection Buttons (2 rows x 2 columns)
        self.algo_buttons = []
        algos = [
            ("Kruskal (MST)", "kruskal"),
            ("Prim (Branch)", "prim"),
            ("Wilson (UST)", "wilson"),
            ("DFS (Winding)", "dfs")
        ]
        for i, (name, val) in enumerate(algos):
            bx = lx if i % 2 == 0 else lx + 225
            by = 265 if i < 2 else 310
            b = Button(bx, by, 215, 34, name, lambda v=val: self._set_algo(v), font_size=11)
            self.algo_buttons.append((val, b))

        # Display Mode Toggle Button
        disp_txt = "FULLSCREEN [F11]" if (self.display_mgr and self.display_mgr.is_fullscreen) else "WINDOWED (1280x720)"
        self.btn_display_mode = Button(lx, 428, 220, 36, disp_txt, self._toggle_display_mode, font_size=11)

        # --- RIGHT COLUMN: Audio & Graphics ---
        rx = 675

        # Audio FX Toggle
        self.toggle_sfx = CyberToggle(rx + 280, 160, 110, 32, initial_state=self.sfx_enabled, on_toggle=self._on_toggle_sfx)

        # Master & SFX Volume Sliders
        self.slider_master = CyberSlider(
            rx, 238, width=280, height=20,
            initial_val=self.master_vol,
            on_change=self._on_master_vol_change,
            accent_color=(0, 240, 255)
        )
        self.slider_sfx = CyberSlider(
            rx, 308, width=280, height=20,
            initial_val=self.sfx_vol,
            on_change=self._on_sfx_vol_change,
            accent_color=(6, 214, 160)
        )

        # Particle FX Toggle
        self.toggle_particles = CyberToggle(rx + 280, 428, 110, 32, initial_state=self.particles_enabled, on_toggle=self._on_toggle_particles)

    def _handle_back(self):
        SoundFX.play_click()
        self.on_back()

    def _load_settings(self):
        try:
            sz = self.db.get_setting("grid_size", "20")
            self.grid_size = int(sz)
            self.generator_algo = self.db.get_setting("generator_algo", "kruskal")
            self.particles_enabled = self.db.get_setting("particles_enabled", "1") == "1"
            self.sfx_enabled = self.db.get_setting("sfx_enabled", "1") == "1"
            self.master_vol = float(self.db.get_setting("master_volume", "1.0"))
            self.sfx_vol = float(self.db.get_setting("sfx_volume", "1.0"))

            SoundFX.set_enabled(self.sfx_enabled)
            SoundFX.set_master_volume(self.master_vol)
            SoundFX.set_sfx_volume(self.sfx_vol)
        except Exception:
            pass

    def _set_grid(self, s: int):
        self.grid_size = s
        SoundFX.play_click()

    def _set_algo(self, algo: str):
        self.generator_algo = algo
        SoundFX.play_click()

    def _toggle_display_mode(self):
        if self.display_mgr:
            self.display_mgr.toggle_fullscreen()
            self.btn_display_mode.text = "FULLSCREEN [F11]" if self.display_mgr.is_fullscreen else "WINDOWED (1280x720)"
            SoundFX.play_click()

    def _on_master_vol_change(self, val: float):
        self.master_vol = val
        SoundFX.set_master_volume(val)
        SoundFX.play_test_beep()

    def _on_sfx_vol_change(self, val: float):
        self.sfx_vol = val
        SoundFX.set_sfx_volume(val)
        SoundFX.play_test_beep()

    def _on_toggle_particles(self, val: bool):
        self.particles_enabled = val

    def _toggle_particles(self):
        self.particles_enabled = not self.particles_enabled
        self.toggle_particles.state = self.particles_enabled

    def _on_toggle_sfx(self, val: bool):
        self.sfx_enabled = val
        SoundFX.set_enabled(val)
        if val:
            SoundFX.play_victory()

    def _toggle_sfx(self):
        self.sfx_enabled = not self.sfx_enabled
        self.toggle_sfx.state = self.sfx_enabled
        SoundFX.set_enabled(self.sfx_enabled)

    def _save_settings(self):
        try:
            self.db.set_setting("grid_size", str(self.grid_size))
            self.db.set_setting("generator_algo", self.generator_algo)
            self.db.set_setting("particles_enabled", "1" if self.particles_enabled else "0")
            self.db.set_setting("sfx_enabled", "1" if self.sfx_enabled else "0")
            self.db.set_setting("master_volume", f"{self.master_vol:.2f}")
            self.db.set_setting("sfx_volume", f"{self.sfx_vol:.2f}")

            SoundFX.set_enabled(self.sfx_enabled)
            SoundFX.set_master_volume(self.master_vol)
            SoundFX.set_sfx_volume(self.sfx_vol)
            SoundFX.play_victory()

            self.status_msg = "[OK] Configuration saved to database!"
            self.status_timer = 2.5
        except Exception as e:
            self.status_msg = f"Error saving: {e}"
            self.status_timer = 2.5

    def handle_event(self, event: pygame.event.Event):
        self.btn_back.handle_event(event)
        self.btn_save.handle_event(event)
        self.btn_display_mode.handle_event(event)
        self.toggle_particles.handle_event(event)
        self.toggle_sfx.handle_event(event)
        self.slider_master.handle_event(event)
        self.slider_sfx.handle_event(event)

        for s, btn in self.grid_buttons:
            btn.handle_event(event)
        for val, btn in self.algo_buttons:
            btn.handle_event(event)

        if event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
            self._handle_back()

    def update(self, dt: float):
        self.btn_back.update(dt)
        self.btn_save.update(dt)
        self.btn_display_mode.update(dt)
        self.toggle_particles.update(dt)
        self.toggle_sfx.update(dt)
        self.slider_master.update(dt)
        self.slider_sfx.update(dt)

        # Sync display mode button label if toggled externally via F11
        if self.display_mgr:
            curr_txt = "FULLSCREEN [F11]" if self.display_mgr.is_fullscreen else "WINDOWED (1280x720)"
            if self.btn_display_mode.text != curr_txt:
                self.btn_display_mode.text = curr_txt

        for s, btn in self.grid_buttons:
            btn.update(dt)
        for val, btn in self.algo_buttons:
            btn.update(dt)

        if self.status_timer > 0:
            self.status_timer -= dt
            if self.status_timer <= 0:
                self.status_msg = ""

    def render(self, surface: pygame.Surface):
        surface.fill((11, 14, 23))

        # Title Header
        title_surf = self.font_title.render("SYSTEM SETTINGS // CONFIGURATION", True, (0, 240, 255))
        surface.blit(title_surf, (self.width // 2 - title_surf.get_width() // 2, 20))

        sub_surf = self.font_sub.render("Hardware calibration, audio synthesis, display scaling, and generation algorithms", True, (142, 154, 175))
        surface.blit(sub_surf, (self.width // 2 - sub_surf.get_width() // 2, 54))

        self.btn_back.draw(surface)

        # Main Settings Card (Dual Column)
        card_x = 90
        card_y = 96
        card_w = self.width - 180
        card_h = 520
        box = pygame.Rect(card_x, card_y, card_w, card_h)
        pygame.draw.rect(surface, (19, 24, 38), box, border_radius=8)
        pygame.draw.rect(surface, (34, 43, 66), box, width=1, border_radius=8)

        # Center Column Divider
        cx = self.width // 2
        pygame.draw.line(surface, (34, 43, 66), (cx, card_y + 20), (cx, card_y + card_h - 20), 1)

        # ================= LEFT COLUMN =================
        lx = card_x + 35

        # Section 1: Maze Generation
        sec1 = self.font_section.render("1. MAZE GENERATION ENGINE", True, (0, 240, 255))
        surface.blit(sec1, (lx, 118))

        lbl_grid = self.font_label.render("DEFAULT GRID SIZE:", True, (248, 249, 250))
        surface.blit(lbl_grid, (lx, 148))
        for s, btn in self.grid_buttons:
            if s == self.grid_size:
                btn.color = (0, 240, 255)
                btn.text_color = (11, 14, 23)
            else:
                btn.color = (24, 30, 48)
                btn.text_color = (248, 249, 250)
            btn.draw(surface)

        lbl_algo = self.font_label.render("GENERATOR ALGORITHM:", True, (248, 249, 250))
        surface.blit(lbl_algo, (lx, 238))
        for val, btn in self.algo_buttons:
            if val == self.generator_algo:
                btn.color = (6, 214, 160)
                btn.text_color = (11, 14, 23)
            else:
                btn.color = (24, 30, 48)
                btn.text_color = (248, 249, 250)
            btn.draw(surface)

        # Horizontal separator in left column
        pygame.draw.line(surface, (34, 43, 66), (lx, 360), (cx - 35, 360), 1)

        # Section 2: Hardware & Display
        sec2 = self.font_section.render("2. HARDWARE & DISPLAY", True, (0, 240, 255))
        surface.blit(sec2, (lx, 375))

        lbl_disp = self.font_label.render("DISPLAY MODE:", True, (248, 249, 250))
        surface.blit(lbl_disp, (lx, 404))
        self.btn_display_mode.draw(surface)

        # Controller / Gamepad Status Badge
        lbl_joy = self.font_label.render("GAMEPAD / CONTROLLER:", True, (248, 249, 250))
        surface.blit(lbl_joy, (lx, 480))

        if self.input_mgr and self.input_mgr.is_controller_connected():
            ctrl_names = self.input_mgr.get_connected_controllers()
            joy_name = ctrl_names[0] if ctrl_names else "Detected"
            if len(joy_name) > 26:
                joy_name = joy_name[:24] + ".."
            joy_status = f"[CONNECTED] {joy_name}"
            col_joy = (6, 214, 160)
        else:
            joy_status = "[KEYBOARD ACTIVE] Plug gamepad anytime (Hotplug)"
            col_joy = (142, 154, 175)

        badge_surf = self.font_badge.render(joy_status, True, col_joy)
        surface.blit(badge_surf, (lx, 506))

        # ================= RIGHT COLUMN =================
        rx = cx + 35

        # Section 3: Audio Synthesis
        sec3 = self.font_section.render("3. AUDIO SYNTHESIS", True, (0, 240, 255))
        surface.blit(sec3, (rx, 118))

        lbl_sfx_tog = self.font_label.render("SYNTHESIZER MASTER TOGGLE:", True, (248, 249, 250))
        surface.blit(lbl_sfx_tog, (rx, 166))
        self.toggle_sfx.draw(surface)

        lbl_mvol = self.font_label.render("MASTER VOLUME:", True, (248, 249, 250))
        surface.blit(lbl_mvol, (rx, 214))
        self.slider_master.draw(surface)

        lbl_svol = self.font_label.render("SFX / EFFECT VOLUME:", True, (248, 249, 250))
        surface.blit(lbl_svol, (rx, 284))
        self.slider_sfx.draw(surface)

        # Horizontal separator in right column
        pygame.draw.line(surface, (34, 43, 66), (rx, 360), (card_x + card_w - 35, 360), 1)

        # Section 4: Graphics & Engine
        sec4 = self.font_section.render("4. GRAPHICS & ENGINE", True, (0, 240, 255))
        surface.blit(sec4, (rx, 375))

        lbl_part = self.font_label.render("PARTICLE FX (DUST, BLASTS):", True, (248, 249, 250))
        surface.blit(lbl_part, (rx, 434))
        self.toggle_particles.draw(surface)

        engine_badge = self.font_badge.render("ENGINE: PYGAME 2.6+ // 1280x720 VIRTUAL // 60 FPS", True, (92, 103, 125))
        surface.blit(engine_badge, (rx, 496))

        # Bottom Status Feedback
        if self.status_msg:
            status_surf = self.font_status.render(self.status_msg, True, (6, 214, 160) if "[OK]" in self.status_msg else (239, 71, 111))
            surface.blit(status_surf, (self.width // 2 - status_surf.get_width() // 2, 606))

        # Bottom Save Button
        self.btn_save.draw(surface)
