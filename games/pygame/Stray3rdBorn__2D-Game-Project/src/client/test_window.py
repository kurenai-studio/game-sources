import pygame

pygame.init()
screen = pygame.display.set_mode((600, 400))
pygame.display.set_caption("Test window")
clock = pygame.time.Clock()

running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    screen.fill((20, 20, 28))
    pygame.draw.circle(screen, (80, 200, 255), (300, 200), 14)
    pygame.display.flip()
    clock.tick(60)

pygame.quit()