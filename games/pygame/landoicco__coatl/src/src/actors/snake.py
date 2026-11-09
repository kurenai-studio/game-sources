import pygame
from pygame.math import Vector2

UP, DOWN, LEFT, RIGHT = (0, -1), (0, 1), (-1, 0), (1, 0)
DIRECTION_NAMES = {UP: "up", DOWN: "down", LEFT: "left", RIGHT: "right"}

# Body sprite for a segment, keyed by the directions of its two neighbors
BODY_SPRITES = {
    frozenset({UP, DOWN}): "body_vertical",
    frozenset({LEFT, RIGHT}): "body_horizontal",
    frozenset({UP, LEFT}): "body_topleft",
    frozenset({UP, RIGHT}): "body_topright",
    frozenset({DOWN, LEFT}): "body_bottomleft",
    frozenset({DOWN, RIGHT}): "body_bottomright",
}


class Snake:
    def __init__(self, configs):
        self.body = [Vector2(5, 10), Vector2(4, 10), Vector2(3, 10)]
        self.direction = Vector2(0, 0)
        self.next_direction = Vector2(0, 0)
        self.new_block = False
        self.configs = configs

        # Head and tail sprites, keyed by the direction they point to
        self.heads = {
            d: configs.sprite(f"head_{n}") for d, n in DIRECTION_NAMES.items()
        }
        self.tails = {
            d: configs.sprite(f"tail_{n}") for d, n in DIRECTION_NAMES.items()
        }
        self.bodies = {key: configs.sprite(name) for key, name in BODY_SPRITES.items()}

        self.crunch_sound = pygame.mixer.Sound(
            self.configs.assets_path + "apple_bite.ogg"
        )

    def draw_snake(self):
        for index, block in enumerate(self.body):
            block_rect = pygame.Rect(
                int(block.x * self.configs.cell_size),
                int(block.y * self.configs.cell_size),
                self.configs.cell_size,
                self.configs.cell_size,
            )
            if index == 0:
                sprite = self.heads[tuple(block - self.body[1])]
            elif index == len(self.body) - 1:
                sprite = self.tails[tuple(block - self.body[index - 1])]
            else:
                previous_block = tuple(self.body[index + 1] - block)
                next_block = tuple(self.body[index - 1] - block)
                sprite = self.bodies[frozenset({previous_block, next_block})]
            self.configs.screen.blit(sprite, block_rect)

    def change_direction(self, direction):
        # Applied on the next move, so several key presses in one tick can't reverse the snake
        self.next_direction = direction

    def move_snake(self):
        # Ignore directions that would turn the head back into the body
        if self.body[0] + self.next_direction != self.body[1]:
            self.direction = self.next_direction

        # Stay still until the player picks a first direction
        if self.direction == Vector2(0, 0):
            return

        body_copy = self.body[:-1]
        if self.new_block:
            self.new_block = False
            body_copy = self.body[:]
        body_copy.insert(0, body_copy[0] + self.direction)
        self.body = body_copy[:]

    def add_block(self):
        self.new_block = True

    def play_crunch_sound(self):
        self.crunch_sound.play()

    def reset(self):
        self.body = [Vector2(5, 10), Vector2(4, 10), Vector2(3, 10)]
        self.direction = Vector2(0, 0)
        self.next_direction = Vector2(0, 0)
