"""Shared configuration for Galaxy Strike."""

WIDTH = 1280
HEIGHT = 720
FPS = 60
TITLE = "GALAXY STRIKE"
PLAYER_SPEED = 430.0
PLAYER_RADIUS = 19
SAVE_PATH = "data/save.json"
RESOLUTIONS = ((960, 540), (1280, 720), (1600, 900))
DIFFICULTY_MULTIPLIERS = {"easy": 0.82, "normal": 1.0, "hard": 1.2}

BACKGROUND = (5, 8, 24)
PANEL = (13, 20, 45)
CYAN = (68, 232, 255)
BLUE = (76, 125, 255)
PINK = (255, 75, 170)
GOLD = (255, 205, 87)
WHITE = (235, 244, 255)
MUTED = (140, 162, 197)

SKINS = [
    {"name": "NOVA", "main": (76, 230, 255), "trim": (255, 255, 255)},
    {"name": "COMET", "main": (255, 105, 155), "trim": (255, 220, 235)},
    {"name": "ORBIT", "main": (181, 133, 255), "trim": (238, 220, 255)},
    {"name": "SOLAR", "main": (255, 195, 72), "trim": (255, 246, 190)},
]
