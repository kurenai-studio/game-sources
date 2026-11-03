import pygame
import random

from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from asteroidfield import AsteroidField
from circleshape import CircleShape
from constants import *
from logger import log_event


class Asteroid(CircleShape):

    def __init__(self, x: float, y: float, radius: float, velocity: pygame.Vector2 = pygame.Vector2(0)) -> None:
        super().__init__(x, y, radius)
        self.velocity = velocity
        vertex_count = random.randint(ASTEROID_MIN_VERTICES, ASTEROID_MAX_VERTICES)
        self.shape = [
            pygame.Vector2.from_polar((
                radius * random.uniform(ASTEROID_SHAPE_JITTER_MIN, ASTEROID_SHAPE_JITTER_MAX),
                i * 360 / vertex_count,
            ))
            for i in range(vertex_count)
        ]

    def draw(self, screen: pygame.Surface) -> None:
        points = [self.position + point for point in self.shape]
        pygame.draw.polygon(screen, "white", points, LINE_WIDTH)

    def update(self, dt: float) -> None:
        self.position += self.velocity * dt

    def split(self, field: "AsteroidField") -> None:
        self.kill()
        field.asteroid_no -= 1
        if self.radius > ASTEROID_MIN_RADIUS:
            log_event("asteroid_split")
            field.asteroid_no += 2
            angle = random.uniform(20, 50)
            new_radius = self.radius - ASTEROID_MIN_RADIUS

            velocity = self.velocity.rotate(-angle) * 1.2
            Asteroid(self.position.x, self.position.y, new_radius, velocity)

            velocity = self.velocity.rotate(angle) * 1.2
            Asteroid(self.position.x, self.position.y, new_radius, velocity)
