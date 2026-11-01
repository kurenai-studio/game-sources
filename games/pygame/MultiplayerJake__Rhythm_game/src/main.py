"""Rhythm Fest entry point."""

import os
import sys

# PyInstaller onefile: anchor everything (music_levels/, stats.dat,
# settings.json) to the folder holding the exe, so a double-click or a
# shortcut with a different working directory behaves the same.
if getattr(sys, "frozen", False):
    os.chdir(os.path.dirname(sys.executable))

# windowed (no-console) builds have no stdout/stderr - the game's
# diagnostic prints would crash on None, so send them to the null device
if sys.stdout is None:
    sys.stdout = open(os.devnull, "w", encoding="utf-8")
if sys.stderr is None:
    sys.stderr = open(os.devnull, "w", encoding="utf-8")

from game.core.app import Game


def main() -> None:
    Game().run()


if __name__ == "__main__":
    main()
