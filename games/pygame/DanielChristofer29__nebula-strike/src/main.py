"""Nebula Strike command-line entry point."""

from __future__ import annotations

import argparse
import os
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Execute Nebula Strike.")
    parser.add_argument(
        "--capture-screenshots",
        type=Path,
        metavar="DIRECTORY",
        help="Renderiza telas demonstrativas sem abrir uma janela interativa.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.capture_screenshots:
        os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
        os.environ.setdefault("SDL_AUDIODRIVER", "dummy")

    from game.app import GameApp

    app = GameApp(audio_enabled=not bool(args.capture_screenshots))
    if args.capture_screenshots:
        for path in app.capture_screenshots(args.capture_screenshots):
            print(path)
        return
    app.run()


if __name__ == "__main__":
    main()
