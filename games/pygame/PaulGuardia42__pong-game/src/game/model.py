import math
import random
from dataclasses import dataclass

import pygame


WINDOW_WIDTH = 960
WINDOW_HEIGHT = 540
PADDLE_WIDTH = 16
PADDLE_HEIGHT = 110
BALL_SIZE = 14


@dataclass
class Paddle:
    x: int
    y: int
    width: int = PADDLE_WIDTH
    height: int = PADDLE_HEIGHT
    color: tuple[int, int, int] = (255, 255, 255)
    speed: float = 520.0

    def __post_init__(self):
        self.rect = pygame.Rect(self.x, self.y, self.width, self.height)

    def move(self, direction: int, dt: float) -> None:
        self.rect.y += direction * self.speed * dt

    def clamp(self) -> None:
        self.rect.y = max(0, min(self.rect.y, WINDOW_HEIGHT - self.rect.height))


@dataclass
class Ball:
    x: int
    y: int
    size: int = BALL_SIZE
    speed: float = 430.0
    color: tuple[int, int, int] = (255, 255, 255)

    def __post_init__(self):
        self.rect = pygame.Rect(self.x, self.y, self.size, self.size)
        self.velocity = [self.speed, self.speed * 0.4]

    def reset(self, direction: int) -> None:
        self.rect.center = (WINDOW_WIDTH // 2, WINDOW_HEIGHT // 2)
        angle = random.uniform(-0.8, 0.8)
        self.velocity = [direction * self.speed, math.sin(angle) * self.speed]

    def update(self, dt: float, left_paddle: Paddle, right_paddle: Paddle, game: "PongModel") -> None:
        self.rect.x += self.velocity[0] * dt
        self.rect.y += self.velocity[1] * dt

        if self.rect.top <= 0:
            self.rect.top = 0
            self.velocity[1] *= -1
        elif self.rect.bottom >= WINDOW_HEIGHT:
            self.rect.bottom = WINDOW_HEIGHT
            self.velocity[1] *= -1

        if self.rect.colliderect(left_paddle.rect):
            self.rect.left = left_paddle.rect.right
            self._bounce(left_paddle, 1)
        elif self.rect.colliderect(right_paddle.rect):
            self.rect.right = right_paddle.rect.left
            self._bounce(right_paddle, -1)

        if self.rect.left <= 0:
            game.right_score += 1
            game.handle_score()
        elif self.rect.right >= WINDOW_WIDTH:
            game.left_score += 1
            game.handle_score()

    def _bounce(self, paddle: Paddle, direction: int) -> None:
        speed = max(abs(self.velocity[0]), 430.0) + 30.0
        offset = (self.rect.centery - paddle.rect.centery) / (paddle.rect.height / 2)
        self.velocity[0] = direction * speed
        self.velocity[1] = offset * 360.0

        length = math.hypot(self.velocity[0], self.velocity[1]) or 1.0
        self.velocity[0] = (self.velocity[0] / length) * speed
        self.velocity[1] = (self.velocity[1] / length) * speed


class PongModel:
    WINNING_SCORE = 7

    def __init__(self):
        self.state = "menu"
        self.mode = None
        self.left_score = 0
        self.right_score = 0
        self.winner = None

        self.left_paddle = Paddle(24, WINDOW_HEIGHT // 2 - PADDLE_HEIGHT // 2, PADDLE_WIDTH, PADDLE_HEIGHT, (255, 255, 255))
        self.right_paddle = Paddle(WINDOW_WIDTH - 24 - PADDLE_WIDTH, WINDOW_HEIGHT // 2 - PADDLE_HEIGHT // 2, PADDLE_WIDTH, PADDLE_HEIGHT, (255, 255, 255))
        self.ball = Ball(WINDOW_WIDTH // 2 - BALL_SIZE // 2, WINDOW_HEIGHT // 2 - BALL_SIZE // 2)

    def start_game(self, mode: str) -> None:
        self.mode = mode
        self.state = "playing"
        self.left_score = 0
        self.right_score = 0
        self.winner = None

        self.left_paddle.rect.y = WINDOW_HEIGHT // 2 - PADDLE_HEIGHT // 2
        self.right_paddle.rect.y = WINDOW_HEIGHT // 2 - PADDLE_HEIGHT // 2
        self.ball.reset(random.choice([-1, 1]))

    def handle_score(self) -> None:
        if self.left_score >= self.WINNING_SCORE or self.right_score >= self.WINNING_SCORE:
            self.state = "game_over"
            if self.mode == "single":
                self.winner = "Player 1" if self.left_score > self.right_score else "CPU"
            else:
                self.winner = "Player 1" if self.left_score > self.right_score else "Player 2"
            return

        if self.left_score > self.right_score:
            self.ball.reset(1)
        else:
            self.ball.reset(-1)

    def update(self, dt: float, keys: pygame.key.ScancodeWrapper) -> None:
        if self.state != "playing":
            return

        left_direction = 0
        if keys[pygame.K_w]:
            left_direction -= 1
        if keys[pygame.K_s]:
            left_direction += 1
        self.left_paddle.move(left_direction, dt)
        self.left_paddle.clamp()

        if self.mode == "single":
            self._update_cpu(dt)
        elif self.mode == "two_player":
            right_direction = 0
            if keys[pygame.K_UP]:
                right_direction -= 1
            if keys[pygame.K_DOWN]:
                right_direction += 1
            self.right_paddle.move(right_direction, dt)
            self.right_paddle.clamp()

        self.ball.update(dt, self.left_paddle, self.right_paddle, self)

    def _update_cpu(self, dt: float) -> None:
        target_y = self.ball.rect.centery - self.right_paddle.rect.height / 2
        if self.ball.rect.x > WINDOW_WIDTH * 0.35:
            if self.right_paddle.rect.centery < target_y:
                self.right_paddle.move(1, dt)
            elif self.right_paddle.rect.centery > target_y:
                self.right_paddle.move(-1, dt)
        self.right_paddle.clamp()
