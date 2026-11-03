"""Shared configuration for the game."""

from pathlib import Path


WIDTH = 960
HEIGHT = 540
FPS = 60
TITLE = "Nebula Strike"

ROOT_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT_DIR / "data"
RANKING_PATH = DATA_DIR / "ranking.json"

INK = (230, 244, 255)
MUTED = (139, 167, 191)
CYAN = (62, 225, 255)
BLUE = (60, 112, 255)
VIOLET = (155, 93, 229)
MAGENTA = (255, 79, 182)
ORANGE = (255, 160, 67)
GREEN = (82, 224, 151)
RED = (255, 78, 101)
DARK = (4, 8, 24)
PANEL = (12, 24, 52)

BOSS_DELAY_MS = 30_000
PLAYER_INVULNERABLE_MS = 1_200
RANKING_LIMIT = 10
