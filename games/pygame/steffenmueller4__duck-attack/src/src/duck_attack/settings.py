"""Game-wide constants."""

from pathlib import Path

TITLE = "Duck Attack"
SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720
FPS = 60

ASSETS_DIR = Path(__file__).parent / "assets"
BACKGROUND_IMAGE = ASSETS_DIR / "images" / "background.png"
DUCK_IMAGE = ASSETS_DIR / "images" / "duck.png"
CROSSHAIR_IMAGE = ASSETS_DIR / "images" / "crosshair.png"
AMBIENT_SOUNDS = [ASSETS_DIR / "sounds" / f"duck_{i}.mp3" for i in (1, 2, 3)]

# A random ambient duck sound plays every AMBIENT_MIN_DELAY..AMBIENT_MAX_DELAY seconds.
AMBIENT_MIN_DELAY = 2.0
AMBIENT_MAX_DELAY = 7.0
AMBIENT_VOLUME = 0.6  # 0.0 - 1.0

# Every shot (hit or miss) plays this sound.
SHOT_SOUND = ASSETS_DIR / "sounds" / "shot_1.mp3"
SHOT_VOLUME = 0.8  # 0.0 - 1.0

CROSSHAIR_SIZE = 64  # cursor size in pixels (square)
# Aim point as a fraction of the image size: the red dot, which sits slightly above center.
CROSSHAIR_HOTSPOT = (0.501, 0.485)

DUCK_WIDTH = 140  # on-screen width in pixels; height keeps the image's aspect ratio
DUCK_SPEED = 260  # pixels per second
DUCK_FALL_GRAVITY = 1500  # pixels per second squared, for shot ducks

# Each duck gets a random distance, expressed as a scale factor of DUCK_WIDTH:
# 1.0 is the closest (full size), smaller values are farther away.
DUCK_MIN_SCALE = 0.35
DUCK_MAX_SCALE = 1.0

# Points for a full-size duck. Farther ducks are worth more (POINTS_PER_HIT / scale,
# rounded to POINTS_ROUNDING): e.g. 10 at scale 1.0, 20 at 0.5, 30 at 0.35.
POINTS_PER_HIT = 10
POINTS_ROUNDING = 5
MISS_PENALTY = 5  # points subtracted for every shot that hits no duck

# Ducks fly somewhere in the sky band between these y positions.
DUCK_MIN_Y = 40
DUCK_MAX_Y = 320

ROUND_DURATION = 30  # seconds
SCORE_SCREEN_DURATION = 10  # seconds the final score is shown before the high-score list
TIME_WARNING = 10  # seconds left from which the timer turns red

HIGHSCORES_FILE = Path.home() / ".duck-attack" / "highscores.json"
MAX_HIGHSCORES = 10

# The last entered player name is remembered here and prefilled before the next round.
PLAYER_NAME_FILE = Path.home() / ".duck-attack" / "player.txt"
PLAYER_NAME_MAX_LENGTH = 16

HUD_FONT_SIZE = 48
HUD_MARGIN = 20  # distance of score/timer from the screen corners in pixels
TEXT_COLOR = (255, 255, 255)
TEXT_SHADOW_COLOR = (20, 20, 20)
WARNING_COLOR = (255, 80, 60)
HIGHLIGHT_COLOR = (255, 215, 0)
OVERLAY_COLOR = (0, 0, 0, 150)  # dims the background behind the end-of-round screens
