import pygame

pygame.init()

screen = pygame.display.set_mode((640, 480))
clock = pygame.time.Clock()
font = pygame.font.SysFont(None, 36)

x, y, = 320, 240
dx, dy = 3, 3
radius = 20

score = 0

running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    x += dx
    y += dy
    
    if x - radius < 0 or x + radius > 640:
        dx = -dx
        score += 1

    if y - radius < 0 or y + radius > 480:
        dy = -dy
        score += 1

    screen.fill((0, 0, 0))
    score_text = font.render(f"Score: {score}", True, (255, 255, 255))
    screen.blit(score_text, (10, 10))
    pygame.draw.circle(screen, (255, 0, 0), (x, y), radius)
    pygame.display.flip()
    clock.tick(60)

pygame.quit()



