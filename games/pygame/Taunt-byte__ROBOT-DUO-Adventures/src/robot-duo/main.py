"""ROBOT DUO: ADVENTURES - run with:  python main.py"""
import sys

try:
    import pygame  # noqa: F401
except ImportError:
    sys.exit("Pygame is required.  Install it with:  pip install -r requirements.txt")

from src.game import Game


def main():
    Game().run()


if __name__ == "__main__":
    main()
