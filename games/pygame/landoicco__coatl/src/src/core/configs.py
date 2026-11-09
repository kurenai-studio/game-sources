import sys
from pathlib import Path

import pygame

# PyInstaller unpacks bundled data into sys._MEIPASS; otherwise use the repo root
if getattr(sys, "frozen", False):
    BASE_PATH = Path(sys._MEIPASS)
else:
    BASE_PATH = Path(__file__).resolve().parents[2]

# Spritesheet layout: sprite name -> (column, row) in a grid of SPRITE_SIZE cells
SPRITE_SIZE = 40
SPRITE_CELLS = {
    "head_up": (0, 0),
    "head_right": (1, 0),
    "head_down": (2, 0),
    "head_left": (3, 0),
    "tail_up": (0, 1),
    "tail_right": (1, 1),
    "tail_down": (2, 1),
    "tail_left": (3, 1),
    "body_vertical": (0, 2),
    "body_horizontal": (1, 2),
    "body_topleft": (2, 2),
    "body_topright": (3, 2),
    "body_bottomleft": (0, 3),
    "body_bottomright": (1, 3),
    "apple": (2, 3),
}


# Contains all shared data between classes
class Configs:
    # Window settings
    cell_size = 40
    cell_number = 20

    # Paths to assets
    assets_path = str(BASE_PATH / "assets") + "/"

    # Author's portfolio, linked from the splash screen
    portfolio_url = "https://licaza.dev"

    # Pygame configs
    pygame.mixer.pre_init(44100, -16, 2, 512)
    pygame.init()

    screen = pygame.display.set_mode((cell_number * cell_size, cell_number * cell_size))
    snake_icon = pygame.image.load(assets_path + "snake_icon.png")
    pygame.display.set_icon(snake_icon)
    pygame.display.set_caption("Coatl. | Classic snake game")
    clock = pygame.time.Clock()
    spritesheet = pygame.image.load(assets_path + "spritesheet.png").convert_alpha()

    # BG Music
    pygame.mixer.music.load(assets_path + "gone-fishing.mp3")

    @classmethod
    def sprite(cls, name):
        # Cut a single sprite out of the spritesheet (shares pixels, no copy)
        col, row = SPRITE_CELLS[name]
        return cls.spritesheet.subsurface(
            (col * SPRITE_SIZE, row * SPRITE_SIZE, SPRITE_SIZE, SPRITE_SIZE)
        )


class Font:
    GAME = pygame.font.Font(Configs.assets_path + "AtkinsonHyperlegibleMono.ttf", 30)
    SUBHEADER = pygame.font.Font(
        Configs.assets_path + "AtkinsonHyperlegibleMono.ttf", 15
    )
    HEADER = pygame.font.Font(Configs.assets_path + "AtkinsonHyperlegibleMono.ttf", 50)
    HEADER.set_bold(True)


class Color:
    # Splash
    BACKGROUND = (168, 184, 160)
    PRIMARY = (167, 109, 93)
    SECONDARY = (44, 44, 44)

    # Wall
    WALL_PRIMARY = (219, 217, 183)
    WALL_SECONDARY = (245, 232, 216)
