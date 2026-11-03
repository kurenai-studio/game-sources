"""
Universal Display & Resolution Scaling Engine (Virtual Backbuffer).
Renders internal scenes to a 1280x720 canvas, scales to any physical monitor resolution
(1080p, 1440p, 4K, ultrawide) with pillarbox/letterbox margins, and maps mouse events.
"""

import sys
import pygame
from typing import Tuple, Optional
from database.db_manager import DatabaseManager

class DisplayManager:
    """Manages virtual backbuffer, aspect ratio scaling, fullscreen toggles, and mouse projections."""

    VIRTUAL_WIDTH = 1280
    VIRTUAL_HEIGHT = 720

    def __init__(self):
        self.db = DatabaseManager()
        self.virtual_surface = pygame.Surface((self.VIRTUAL_WIDTH, self.VIRTUAL_HEIGHT))
        self.is_fullscreen = False
        self.physical_screen: Optional[pygame.Surface] = None

        self.scale = 1.0
        self.offset_x = 0
        self.offset_y = 0
        self.scaled_w = self.VIRTUAL_WIDTH
        self.scaled_h = self.VIRTUAL_HEIGHT

        # Load saved display mode preference from SQLite
        saved_mode = self.db.get_setting("display_mode", "windowed")
        self.is_fullscreen = (saved_mode == "fullscreen")

    def init_display(self) -> pygame.Surface:
        """Initializes the physical window or fullscreen display."""
        flags = pygame.DOUBLEBUF | pygame.HWSURFACE
        if self.is_fullscreen:
            flags |= pygame.FULLSCREEN
            info = pygame.display.Info()
            phys_w, phys_h = info.current_w, info.current_h
        else:
            phys_w, phys_h = self.VIRTUAL_WIDTH, self.VIRTUAL_HEIGHT

        self.physical_screen = pygame.display.set_mode((phys_w, phys_h), flags)
        pygame.display.set_caption("CYBER MAZE RUNNER // ARCADE ACTION")
        self.recalculate_scaling(phys_w, phys_h)
        return self.virtual_surface

    def toggle_fullscreen(self):
        """Toggles between Windowed and Borderless Fullscreen modes."""
        self.is_fullscreen = not self.is_fullscreen
        self.db.set_setting("display_mode", "fullscreen" if self.is_fullscreen else "windowed")
        self.init_display()

    def recalculate_scaling(self, phys_w: int, phys_h: int):
        """Calculates aspect-correct scaling factor and letterbox/pillarbox margins."""
        scale_x = phys_w / self.VIRTUAL_WIDTH
        scale_y = phys_h / self.VIRTUAL_HEIGHT
        self.scale = min(scale_x, scale_y)

        self.scaled_w = int(self.VIRTUAL_WIDTH * self.scale)
        self.scaled_h = int(self.VIRTUAL_HEIGHT * self.scale)

        self.offset_x = (phys_w - self.scaled_w) // 2
        self.offset_y = (phys_h - self.scaled_h) // 2

    def transform_mouse_pos(self, phys_x: int, phys_y: int) -> Tuple[int, int]:
        """Transforms physical display coordinates back into virtual 1280x720 coordinates."""
        if self.scale <= 0:
            return phys_x, phys_y

        virt_x = int((phys_x - self.offset_x) / self.scale)
        virt_y = int((phys_y - self.offset_y) / self.scale)
        return virt_x, virt_y

    def map_event(self, event: pygame.event.Event) -> pygame.event.Event:
        """Translates mouse event positions from physical display to virtual backbuffer."""
        if event.type in (pygame.MOUSEMOTION, pygame.MOUSEBUTTONDOWN, pygame.MOUSEBUTTONUP):
            new_pos = self.transform_mouse_pos(*event.pos)
            # Create a clone of the event with virtual position
            event_dict = dict(event.__dict__)
            event_dict["pos"] = new_pos
            return pygame.event.Event(event.type, event_dict)
        return event

    def present(self):
        """Scales virtual surface and blits to physical display with letterbox presentation."""
        if not self.physical_screen:
            try:
                pygame.display.flip()
            except Exception:
                pass
            return

        if self.is_fullscreen:
            # Clear pillarboxes/letterboxes to black
            self.physical_screen.fill((0, 0, 0))

            # Scale virtual canvas
            if self.scaled_w == self.VIRTUAL_WIDTH and self.scaled_h == self.VIRTUAL_HEIGHT:
                scaled_surface = self.virtual_surface
            else:
                scaled_surface = pygame.transform.smoothscale(self.virtual_surface, (self.scaled_w, self.scaled_h))

            self.physical_screen.blit(scaled_surface, (self.offset_x, self.offset_y))
        else:
            self.physical_screen.blit(self.virtual_surface, (0, 0))

        pygame.display.flip()
