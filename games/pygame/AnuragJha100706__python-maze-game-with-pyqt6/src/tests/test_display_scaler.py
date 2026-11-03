"""
Automated Unit Tests for DisplayManager & Resolution Scaling Engine.
Verifies pillarbox/letterbox calculations, coordinate projections, and mouse event mapping.
"""

import os
import sys
import unittest
import pygame

# Set dummy video driver for headless execution
os.environ["SDL_VIDEODRIVER"] = "dummy"
os.environ["SDL_AUDIODRIVER"] = "dummy"

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from core.display_manager import DisplayManager

class TestDisplayScaler(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        pygame.init()

    def setUp(self):
        self.dm = DisplayManager()

    def test_virtual_canvas_dimensions(self):
        """Virtual canvas must always be strictly 1280x720."""
        self.assertEqual(self.dm.VIRTUAL_WIDTH, 1280)
        self.assertEqual(self.dm.VIRTUAL_HEIGHT, 720)
        self.assertEqual(self.dm.virtual_surface.get_size(), (1280, 720))

    def test_recalculate_scaling_1080p(self):
        """1920x1080 is an exact 16:9 ratio, scale should be 1.5 with 0 offset."""
        self.dm.recalculate_scaling(1920, 1080)
        self.assertAlmostEqual(self.dm.scale, 1.5, places=4)
        self.assertEqual(self.dm.scaled_w, 1920)
        self.assertEqual(self.dm.scaled_h, 1080)
        self.assertEqual(self.dm.offset_x, 0)
        self.assertEqual(self.dm.offset_y, 0)

    def test_recalculate_scaling_ultrawide(self):
        """2560x1080 ultrawide (21:9) should scale by height with pillarbox margins."""
        self.dm.recalculate_scaling(2560, 1080)
        self.assertAlmostEqual(self.dm.scale, 1.5, places=4)
        self.assertEqual(self.dm.scaled_w, 1920)
        self.assertEqual(self.dm.scaled_h, 1080)
        # Pillarbox offset on left and right: (2560 - 1920) // 2 = 320
        self.assertEqual(self.dm.offset_x, 320)
        self.assertEqual(self.dm.offset_y, 0)

    def test_recalculate_scaling_letterbox(self):
        """1280x1024 (5:4) monitor should scale by width with letterbox margins."""
        self.dm.recalculate_scaling(1280, 1024)
        self.assertAlmostEqual(self.dm.scale, 1.0, places=4)
        self.assertEqual(self.dm.scaled_w, 1280)
        self.assertEqual(self.dm.scaled_h, 720)
        self.assertEqual(self.dm.offset_x, 0)
        # Letterbox offset top/bottom: (1024 - 720) // 2 = 152
        self.assertEqual(self.dm.offset_y, 152)

    def test_mouse_coordinate_projection(self):
        """Verifies mapping of physical monitor clicks back to 1280x720 canvas."""
        # Scenario: Ultrawide 2560x1080 (offset_x=320, offset_y=0, scale=1.5)
        self.dm.recalculate_scaling(2560, 1080)

        # Physical click at center of viewport (320 + 960 = 1280, 540)
        virt_x, virt_y = self.dm.transform_mouse_pos(1280, 540)
        self.assertEqual(virt_x, 640)
        self.assertEqual(virt_y, 360)

        # Physical click at top-left corner of active game area (320, 0)
        virt_x, virt_y = self.dm.transform_mouse_pos(320, 0)
        self.assertEqual(virt_x, 0)
        self.assertEqual(virt_y, 0)

    def test_map_mouse_event(self):
        """Verifies pygame event cloning with transformed pos."""
        self.dm.recalculate_scaling(1920, 1080)  # scale = 1.5
        phys_event = pygame.event.Event(pygame.MOUSEBUTTONDOWN, {"pos": (960, 540), "button": 1})
        mapped = self.dm.map_event(phys_event)

        self.assertEqual(mapped.type, pygame.MOUSEBUTTONDOWN)
        self.assertEqual(mapped.pos, (640, 360))
        self.assertEqual(mapped.button, 1)

if __name__ == "__main__":
    unittest.main()
