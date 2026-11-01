"""Global constants. Pure data - this module never imports pygame."""
import os

# --------------------------------------------------------------------------- paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
DATA_DIR = os.path.join(BASE_DIR, "data")
LEVELS_DIR = os.path.join(DATA_DIR, "levels")

# --------------------------------------------------------------------------- window
GAME_TITLE = "ROBOT DUO: ADVENTURES"
SCREEN_W = 1000
SCREEN_H = 650
FPS = 60
MAX_DT = 1.0 / 30.0          # clamp so a lag spike can never tunnel through floors

# --------------------------------------------------------------------------- world
TILE = 40                    # size of one grid cell, in pixels

# --------------------------------------------------------------------------- player physics (px, seconds)
PLAYER_W = 28
PLAYER_H = 42
GRAVITY = 2200.0
MAX_FALL_SPEED = 900.0
MOVE_SPEED = 250.0
ACCEL_GROUND = 2800.0
ACCEL_AIR = 1800.0
FRICTION_GROUND = 3200.0
FRICTION_AIR = 700.0
JUMP_SPEED = 820.0           # apex ~ 3.8 tiles
JUMP_RELEASE_SPEED = 280.0   # releasing the key early caps the upward speed (variable jump)
COYOTE_TIME = 0.10           # grace period to jump after walking off a ledge
JUMP_BUFFER = 0.12           # jump pressed slightly before landing still counts
LAND_ANIM_TIME = 0.16
LAND_MIN_SPEED = 380.0       # minimum fall speed that triggers landing squash / dust

# --------------------------------------------------------------------------- mechanisms
DOOR_SPEED = 2.4             # fraction of a door opened per second
BRIDGE_SPEED = 520.0         # px / s
MOVER_THICKNESS = 18
BRIDGE_THICKNESS = 16
FADING_THICKNESS = 20
FALL_DEATH_MARGIN = 70       # px below the map before a falling robot dies

# --------------------------------------------------------------------------- gameplay
DEATH_RESTART_DELAY = 1.4
VICTORY_DELAY = 2.2
CRYSTAL_SCORE = 150
FULL_CLEAR_BONUS = 1000

# --------------------------------------------------------------------------- palette
C_RED = (214, 40, 44)
C_RED_DARK = (140, 20, 30)
C_RED_LIGHT = (255, 120, 104)
C_CYAN = (34, 170, 232)
C_CYAN_DARK = (16, 96, 170)
C_CYAN_LIGHT = (140, 224, 255)
C_YELLOW = (255, 214, 58)
C_LAVA = (255, 98, 26)
C_WATER = (70, 176, 255)
C_METAL = (58, 66, 84)
C_WHITE = (240, 246, 255)
C_BLACK = (10, 12, 20)
C_GREEN = (70, 255, 150)
C_UI_BG = (14, 22, 44)
C_UI_PANEL = (24, 40, 76)
C_UI_ACCENT = (54, 150, 255)

# --------------------------------------------------------------------------- default user settings
DEFAULT_SETTINGS = {
    "music_volume": 0.5,
    "sfx_volume": 0.7,
    "fullscreen": False,
    "control_mode": "dual",   # "dual": both key sets always live | "single": only the selected robot moves
}
