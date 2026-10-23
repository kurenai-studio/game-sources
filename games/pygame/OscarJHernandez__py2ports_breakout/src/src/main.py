"""Breakout gameplay, developed from the public py2port_pygame_template."""
import math
import pygame
from app import MUTED, PANEL, run

LAYOUTS = (
    ("1111111111", "1111111111", "1111111111", "1111111111"),
    ("1100110011", "1111111111", "0111111110", "0011111100", "0001111000"),
    ("1010101010", "0101010101", "1111111111", "0111111110", "1100000011", "0011111100"),
)


class Game:
    title = "py2ports Breakout"
    subtitle = "Three levels. Three lives. One more try."
    hint = "Left / right: paddle     A / Enter: launch     Start / P: pause"
    accent = (255, 195, 99)
    radius = 6

    def __init__(self):
        self.reset()
        self.state = "menu"

    @property
    def speed(self):
        return 235 + (self.level - 1) * 55

    def reset(self):
        self.score, self.lives, self.level = 0, 3, 1
        self.paddle_x = 320.0
        self.state = "playing"
        self.load_level()

    def load_level(self):
        self.bricks = [pygame.Rect(34 + col * 58, 112 + row * 27, 50, 19)
                       for row, line in enumerate(LAYOUTS[self.level - 1]) for col, cell in enumerate(line) if cell == "1"]
        self.reset_ball()

    def reset_ball(self):
        self.ready = True
        self.ball_x, self.ball_y = self.paddle_x, 405.0
        self.vx, self.vy = self.speed * 0.4, -self.speed * math.sqrt(0.84)

    def handle(self, action):
        if action == "confirm":
            if self.state == "paused":
                self.state = "playing"
            elif self.state in ("menu", "over", "won"):
                self.reset()
            elif self.ready:
                self.ready = False
        elif action == "pause" and self.state in ("playing", "paused"):
            self.state = "paused" if self.state == "playing" else "playing"
        elif action == "back":
            self.state = "paused" if self.state == "playing" else "menu"

    def update(self, dt, horizontal=0):
        if self.state != "playing":
            return
        remaining = min(dt, 0.1)
        while remaining > 0 and self.state == "playing":
            tick = min(remaining, 1/240)
            remaining -= tick
            self.paddle_x = max(70, min(570, self.paddle_x + horizontal * 390 * tick))
            if self.ready:
                self.ball_x = self.paddle_x
                continue
            previous_y = self.ball_y
            self.ball_x += self.vx * tick
            self.ball_y += self.vy * tick
            if self.ball_x < 30:
                self.ball_x, self.vx = 30, abs(self.vx)
            elif self.ball_x > 610:
                self.ball_x, self.vx = 610, -abs(self.vx)
            if self.ball_y < 102:
                self.ball_y, self.vy = 102, abs(self.vy)
            ball = pygame.Rect(round(self.ball_x - self.radius), round(self.ball_y - self.radius), 12, 12)
            paddle = pygame.Rect(round(self.paddle_x - 46), 418, 92, 12)
            if self.vy > 0 and ball.colliderect(paddle) and previous_y + self.radius <= paddle.top + 2:
                angle = (self.ball_x - self.paddle_x) / 46 * 1.05
                self.vx, self.vy = self.speed * math.sin(angle), -self.speed * math.cos(angle)
                self.ball_y = paddle.top - self.radius
            for brick in self.bricks:
                if ball.colliderect(brick):
                    self.bricks.remove(brick)
                    self.score += 10
                    if previous_y + self.radius <= brick.top + 2 or previous_y - self.radius >= brick.bottom - 2:
                        self.vy = -self.vy
                    else:
                        self.vx = -self.vx
                    break
            if not self.bricks:
                if self.level == len(LAYOUTS):
                    self.state = "won"
                else:
                    self.level += 1
                    self.load_level()
            elif self.ball_y - self.radius > 448:
                self.lives -= 1
                if self.lives == 0:
                    self.state = "over"
                else:
                    self.reset_ball()

    def draw(self, view):
        surface = view.surface
        pygame.draw.rect(surface, PANEL, (24, 96, 592, 352), border_radius=8)
        colors = ((255, 121, 117), (255, 195, 99), (92, 231, 164), (105, 176, 243), (185, 152, 244), (239, 149, 211))
        for brick in self.bricks:
            pygame.draw.rect(surface, colors[((brick.y-112)//27) % len(colors)], brick, border_radius=4)
        pygame.draw.rect(surface, self.accent, (round(self.paddle_x-46), 418, 92, 12), border_radius=6)
        pygame.draw.circle(surface, (237, 244, 248), (round(self.ball_x), round(self.ball_y)), self.radius)
        status = f"LEVEL {self.level}/3     LIVES {self.lives}"
        view.text(status, 320, 76, 20, MUTED, True)
        if self.ready and self.state == "playing":
            view.text("A / Enter to launch", 320, 340, 26, self.accent, True)


def main():
    run(Game, "py2ports_breakout", "BREAKOUT_FULLSCREEN")


if __name__ == "__main__":
    main()
