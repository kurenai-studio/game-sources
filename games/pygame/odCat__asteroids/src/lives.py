import pygame

from constants import ASTEROID_MAX_RADIUS, PLAYER_RADIUS


def draw_lives(screen: pygame.Surface, number: int) -> None:
    height = width = ASTEROID_MAX_RADIUS
    for _ in range(number):
        position = pygame.Vector2(height, width)
        pygame.draw.polygon(screen, "white", triangle(position), 0)
        height += ASTEROID_MAX_RADIUS

def triangle(position: pygame.Vector2) -> list[pygame.Vector2]:
    forward_unit = pygame.Vector2(0, 1).rotate(0) * 0.75
    lateral_unit = pygame.Vector2(0, 1).rotate(0 + 90) * PLAYER_RADIUS * 0.75

    apex = position + forward_unit * PLAYER_RADIUS
    left_vertex = position - forward_unit * PLAYER_RADIUS - lateral_unit
    right_vertex = position - forward_unit * PLAYER_RADIUS + lateral_unit

    return [apex, left_vertex, right_vertex]
