"""Settings panel drawing and input helper."""

import pygame

from settings import CYAN, MUTED, RESOLUTIONS, WHITE


class SettingsMenu:
    def __init__(self):
        self.rows = (
            ("Master volume", "master_volume"),
            ("Music volume", "music_volume"),
            ("Sound effects", "sfx_volume"),
            ("Display mode", "fullscreen"),
            ("Resolution", "resolution"),
            ("Frame-rate display", "show_fps"),
            ("Difficulty", "difficulty"),
        )
        self.row_step = 44
        self.controls = {}
        self.last_changed = ""

    def draw(self, surface, small_font, save_data, center_x, top):
        self.row_step = min(50, max(34, surface.get_height() * 0.07))
        self.controls = {}
        panel = pygame.Rect(
            round(center_x - min(320, surface.get_width() * 0.42)),
            round(top - 10),
            round(min(640, surface.get_width() * 0.84)),
            round(self.row_step * len(self.rows) + 18),
        )
        pygame.draw.rect(surface, (8, 15, 34), panel, border_radius=14)
        pygame.draw.rect(surface, (45, 68, 109), panel, 1, border_radius=14)
        for index, (label, key) in enumerate(self.rows):
            y = round(top + index * self.row_step)
            self.controls[key] = pygame.Rect(panel.left, y - 4, panel.width, self.row_step)
            surface.blit(small_font.render(label, True, WHITE), (panel.left + 18, y + 3))
            if key.endswith("_volume"):
                value = save_data[key]
                rail = pygame.Rect(round(center_x + 45), y + 14, 180, 6)
                self.controls[key] = rail.inflate(24, self.row_step - 8)
                pygame.draw.rect(surface, (34, 48, 73), rail, border_radius=4)
                pygame.draw.rect(
                    surface, CYAN,
                    (rail.x, rail.y, round(rail.width * value), rail.height),
                    border_radius=4,
                )
                pygame.draw.circle(
                    surface, WHITE, (rail.x + round(rail.width * value), rail.centery), 7
                )
                value_text = small_font.render(f"{round(value * 100)}%", True, MUTED)
                surface.blit(value_text, value_text.get_rect(midleft=(rail.right + 18, rail.centery)))
            else:
                if key == "fullscreen":
                    value = "FULLSCREEN" if save_data[key] else "WINDOWED"
                elif key == "show_fps":
                    value = "ON" if save_data[key] else "OFF"
                elif key == "resolution":
                    value = save_data[key]
                else:
                    value = save_data[key].upper()
                value_surface = small_font.render(f"<  {value}  >", True, CYAN)
                value_rect = value_surface.get_rect(midright=(panel.right - 20, y + 15))
                surface.blit(value_surface, value_rect)
                self.controls[key] = value_rect.inflate(24, self.row_step - 8)
            pygame.draw.line(
                surface, (29, 42, 66),
                (panel.left + 16, y + self.row_step - 2),
                (panel.right - 16, y + self.row_step - 2),
            )

    def handle_click(self, position, save_data, center_x):
        self.last_changed = ""
        if not self.controls:
            return False
        for key, rect in self.controls.items():
            if not rect.collidepoint(position):
                continue
            if key.endswith("_volume"):
                save_data[key] = max(0.0, min(1.0, (position[0] - (center_x + 45)) / 180))
            elif key in ("fullscreen", "show_fps"):
                save_data[key] = not save_data[key]
            elif key == "resolution":
                choices = tuple(f"{width}x{height}" for width, height in RESOLUTIONS)
                index = (choices.index(save_data[key]) + 1) % len(choices)
                save_data[key] = choices[index]
            elif key == "difficulty":
                choices = ("easy", "normal", "hard")
                index = (choices.index(save_data[key]) + 1) % len(choices)
                save_data[key] = choices[index]
            self.last_changed = key
            return True
        return False
