import pygame

from circleshape import CircleShape
from constants import *


class Shot(CircleShape):

    def __init__(self, x: float, y: float, rotation, velocity=0) -> None:
        super().__init__(x, y, SHOT_RADIUS)
        self.rotation = rotation
        self.velocity = velocity

    def draw(self, screen: pygame.Surface) -> None:
        offset = pygame.Vector2(0, SHOT_LENGTH/2).rotate(self.rotation)
        pygame.draw.line(screen, "white", self.position + offset, self.position - offset, LINE_WIDTH)

    def update(self, dt: float) -> None:
        self.position += self.velocity * dt
