from __future__ import annotations


def main() -> None:
    import pygame

    from .persistence.store import Store
    from .puzzles.schema import load_all
    from .ui.app import SIZE, App

    pygame.init()
    pygame.display.set_caption("Structura")
    screen = pygame.display.set_mode(SIZE, pygame.SCALED | pygame.RESIZABLE)
    app = App(Store(), load_all(), screen=screen)
    try:
        app.run()
    finally:
        app.store.close()
        pygame.quit()


if __name__ == "__main__":
    main()
