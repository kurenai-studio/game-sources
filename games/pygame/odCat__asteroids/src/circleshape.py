import pygame


class CircleShape(pygame.sprite.Sprite):

    def __init__(self, x: float, y: float, radius: float) -> None:
        if hasattr(self, "containers"):
            super().__init__(*self.containers)
        else:
            super().__init__()

        self.position = pygame.Vector2(x, y)
        self.velocity = pygame.Vector2(0, 0)
        self.radius = radius

    def draw(self, screen: pygame.Surface) -> None:
        pass

    def update(self, dt: float) -> None:
        pass

    def collies_with(self, other: "CircleShape") -> bool:
        distance = self.position.distance_to(other.position)
        if distance <= self.radius + other.radius:
            return True
        else:
            return False
