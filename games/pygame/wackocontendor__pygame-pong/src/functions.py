# Example file showing a basic pygame "game loop"
import pygame
import math

class Player():
    def __init__(self, color, speed, x_pos, y_pos):
        self.height = 130
        self.width = 10
        self.speed = speed
        self.surface = pygame.Surface((self.width, self.height))
        self.surface.fill(color)
        self.pos = pygame.Vector2((x_pos, y_pos))

    def move(self, up=False, down=False):
        if up == True:
            self.pos.y -= self.speed
        if down == True:
            self.pos.y += self.speed
        if self.pos.y > 590:
            self.pos.y = 590
        if self.pos.y < 0:
            self.pos.y = 0

class Ball():
    def __init__(self, color, speed, x_pos, y_pos):
        self.height = 20
        self.width = 20
        self.speed = speed
        self.surface = pygame.Surface((self.width, self.height))
        self.surface.fill(color)
        self.pos = pygame.Vector2((x_pos, y_pos))

    def move(self, x_multiplier, y_multiplier, angle):
        self.pos.x += x_multiplier * self.speed * abs(math.cos(angle))
        self.pos.y += y_multiplier * self.speed * abs(math.sin(angle))