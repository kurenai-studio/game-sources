"""
CYBER MAZE RUNNER 2.0
Master Game Launcher (Pure Pygame Engine).
1280x720 Virtual Backbuffer, Universal Aspect Scaler, Gamepad & Hotplug Support.
"""

import os
import sys

# Ensure project root is in Python module search path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

# Optional Windows DPI awareness for crisp rendering
if sys.platform == "win32":
    try:
        import ctypes
        ctypes.windll.user32.SetProcessDPIAware()
    except Exception:
        pass

import pygame
from database.db_manager import DatabaseManager
from core.display_manager import DisplayManager
from game.state_manager import StateManager

def main():
    # Initialize Core Pygame Subsystems
    pygame.init()
    pygame.font.init()

    # Audio mixer initialization (safe fallback if no audio device)
    try:
        pygame.mixer.init(frequency=44100, size=-16, channels=2, buffer=512)
    except Exception:
        pass

    # Ensure Database is initialized
    db = DatabaseManager()

    # Initialize Universal Display Engine (Windowed or Fullscreen)
    display_manager = DisplayManager()
    display_manager.init_display()

    # Start the Master State Machine
    state_manager = StateManager(display_manager)
    state_manager.run()

if __name__ == "__main__":
    main()
