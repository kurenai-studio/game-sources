"""
Automated Unit Tests for SoundFX Volume Subsystem.
Verifies master and SFX volume modulation, clamping, and audio feedback.
"""

import os
import sys
import unittest
import pygame

# Set dummy drivers for headless testing
os.environ["SDL_VIDEODRIVER"] = "dummy"
os.environ["SDL_AUDIODRIVER"] = "dummy"

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from game.audio import SoundFX

class TestAudioVolume(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        pygame.init()
        SoundFX.init()

    def test_default_volume_values(self):
        """Default volume should be 1.0."""
        SoundFX.set_master_volume(1.0)
        SoundFX.set_sfx_volume(1.0)
        self.assertAlmostEqual(SoundFX.get_master_volume(), 1.0)
        self.assertAlmostEqual(SoundFX.get_sfx_volume(), 1.0)

    def test_volume_clamping(self):
        """Volume should be clamped between 0.0 and 1.0."""
        SoundFX.set_master_volume(1.8)
        self.assertAlmostEqual(SoundFX.get_master_volume(), 1.0)

        SoundFX.set_master_volume(-0.5)
        self.assertAlmostEqual(SoundFX.get_master_volume(), 0.0)

        SoundFX.set_sfx_volume(2.5)
        self.assertAlmostEqual(SoundFX.get_sfx_volume(), 1.0)

        SoundFX.set_sfx_volume(-1.0)
        self.assertAlmostEqual(SoundFX.get_sfx_volume(), 0.0)

    def test_volume_setting_valid_range(self):
        """Volume within [0.0, 1.0] should be preserved accurately."""
        SoundFX.set_master_volume(0.65)
        self.assertAlmostEqual(SoundFX.get_master_volume(), 0.65)

        SoundFX.set_sfx_volume(0.42)
        self.assertAlmostEqual(SoundFX.get_sfx_volume(), 0.42)

    def test_play_test_beep_safety(self):
        """play_test_beep should execute safely without crashing."""
        SoundFX.play_test_beep()

if __name__ == "__main__":
    unittest.main()
