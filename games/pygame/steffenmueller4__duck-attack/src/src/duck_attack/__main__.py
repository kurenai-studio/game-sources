"""Entry point: ``python -m duck_attack`` or the ``duck-attack`` command."""

from duck_attack.game import Game


def main() -> None:
    Game().run()


if __name__ == "__main__":
    main()
