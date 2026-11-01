"""
2048 — classic puzzle game in Python + Pygame.

Controls:
  Arrow keys / WASD  — move tiles
  R                  — restart
  Enter / Space      — continue after winning
  Esc / Q            — quit
"""

from __future__ import annotations

from game.ui import GameApp


def main() -> None:
    GameApp().run()


if __name__ == "__main__":
    main()
