# ruff: noqa: E402
import os
from pathlib import Path

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
os.environ.setdefault("SDL_AUDIODRIVER", "dummy")
os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")

import pygame

from python_game_suite.lucky9.gui import Lucky9Gui
from python_game_suite.lucky9.gui_engine import Lucky9Session


def main() -> None:
    deck = [
        ("A", chr(9829)),
        ("9", chr(9824)),
        ("5", chr(9830)),
        ("2", chr(9827)),
    ] * 10
    pygame.init()
    session = Lucky9Session(deck_factory=lambda: deck)
    session.place_bet(1_000)
    session.hit()
    gui = Lucky9Gui(session)
    surface = pygame.Surface((960, 600))
    gui.render(surface)
    output = Path("docs/screenshot.png")
    output.parent.mkdir(parents=True, exist_ok=True)
    pygame.image.save(surface, str(output))
    pygame.quit()
    print(f"Wrote {output}")


if __name__ == "__main__":
    main()
