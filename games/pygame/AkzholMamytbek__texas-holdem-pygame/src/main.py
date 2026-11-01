"""Texas Hold'em: you vs Shark vs Dealer. Run: python3 main.py"""
import pygame

from gui import HEIGHT, WIDTH, PokerApp


def main():
    pygame.init()
    screen = pygame.display.set_mode((WIDTH, HEIGHT))
    pygame.display.set_caption("Texas Hold'em — You vs Shark vs Dealer")
    clock = pygame.time.Clock()
    app = PokerApp(screen)

    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT or \
                    (event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE):
                running = False
            else:
                app.handle_event(event)
        app.update()
        app.draw()
        pygame.display.flip()
        clock.tick(60)
    pygame.quit()


if __name__ == "__main__":
    main()
