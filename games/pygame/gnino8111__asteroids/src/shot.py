from constants import SHOT_RADIUS, LINE_WIDTH
from circleshape import CircleShape
import pygame

class Shot(CircleShape):

    def __init__(self, x: float, y: float):
        super().__init__(x, y, SHOT_RADIUS)

    def draw(self, screen: pygame.Surface):
        pygame.draw.circle(screen, "white", self.position, self.radius, LINE_WIDTH)

    def update(self, dt):
        self.position += self.velocity * dt