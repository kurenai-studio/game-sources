import pygame
from circleshape import CircleShape
from constants import LINE_WIDTH, ASTEROID_MIN_RADIUS, SCORE_LARGE, SCORE_MEDIUM, SCORE_SMALL
from logger import log_event
import random

class Asteroid(CircleShape):

    def __init__(self, x: float, y: float, radius: float) -> None:
        super().__init__(x, y, radius)

    def draw(self, screen: pygame.Surface):
        pygame.draw.circle(screen, "white", self.position, self.radius, LINE_WIDTH)

    def update(self, dt):
        self.position += self.velocity * dt

    def score_value(self) -> int:
        if self.radius >= ASTEROID_MIN_RADIUS * 3:
            return SCORE_LARGE
        elif self.radius >= ASTEROID_MIN_RADIUS * 2:
            return SCORE_MEDIUM
        return SCORE_SMALL

    def split(self):
        self.kill()
        if self.radius <= ASTEROID_MIN_RADIUS:
            return
        else:
            log_event("asteroid_split")
            first_asteroids_velocity = self.velocity.rotate(random.uniform(20, 50))
            second_asteroids_velocity = self.velocity.rotate(random.uniform(20, 50) * -1)
            first_asteroids_radius = self.radius - ASTEROID_MIN_RADIUS
            second_asteroids_radius = self.radius - ASTEROID_MIN_RADIUS
            firstAsteroid = Asteroid(self.position.x, self.position.y, first_asteroids_radius)
            secondAsteroid = Asteroid(self.position.x, self.position.y, second_asteroids_radius)
            firstAsteroid.velocity = first_asteroids_velocity * 1.2
            secondAsteroid.velocity = second_asteroids_velocity * 1.2


