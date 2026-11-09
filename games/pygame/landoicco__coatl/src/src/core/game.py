import pygame

from actors import Fruit, Snake

from .configs import Color, Font
from .splash import show_splash_screen


class Game:
    def __init__(self, configs):
        self.configs = configs

        self.snake = Snake(configs)
        self.fruit = Fruit(configs)
        self.fruit.randomize(self.snake.body)

        # Play bg music
        pygame.mixer.music.play(-1)  # Loop

    def update(self):
        self.snake.move_snake()
        self.check_collisions()
        self.check_fail()

    def draw_elements(self):
        self.draw_background()
        self.fruit.draw_fruit()
        self.snake.draw_snake()
        self.draw_score()

    def check_collisions(self):
        if self.fruit.pos == self.snake.body[0]:
            self.snake.play_crunch_sound()
            self.fruit.randomize(self.snake.body)
            self.snake.add_block()

    def check_fail(self):
        if (
            not 0 <= self.snake.body[0].x < self.configs.cell_number
            or not 0 <= self.snake.body[0].y < self.configs.cell_number
        ):
            self.game_over()
        for block in self.snake.body[1:]:
            if block == self.snake.body[0]:
                self.game_over()

    def draw_background(self):
        grass_color = Color.WALL_SECONDARY
        for row in range(self.configs.cell_number):
            if row % 2 == 0:
                for col in range(self.configs.cell_number):
                    if col % 2 == 0:
                        grass_rect = pygame.Rect(
                            col * self.configs.cell_size,
                            row * self.configs.cell_size,
                            self.configs.cell_size,
                            self.configs.cell_size,
                        )
                        pygame.draw.rect(self.configs.screen, grass_color, grass_rect)
            else:
                for col in range(self.configs.cell_number):
                    if col % 2 != 0:
                        grass_rect = pygame.Rect(
                            col * self.configs.cell_size,
                            row * self.configs.cell_size,
                            self.configs.cell_size,
                            self.configs.cell_size,
                        )
                        pygame.draw.rect(self.configs.screen, grass_color, grass_rect)

    def game_over(self):
        # Draw splash screen on game over
        score = len(self.snake.body) - 3
        if score > 0:
            show_splash_screen(score)

        self.snake.reset()
        self.fruit.randomize(self.snake.body)

    def draw_score(self):
        score_text = str(len(self.snake.body) - 3)
        score_surface = Font.GAME.render(score_text, True, (56, 74, 12))
        score_x = int(
            self.configs.cell_size * self.configs.cell_number
            - ((self.configs.cell_size * self.configs.cell_number) / 2)
        )
        score_y = int(self.configs.cell_size * self.configs.cell_number - 15)
        score_rect = score_surface.get_rect(midbottom=(score_x, score_y))
        apple_rect = self.fruit.image.get_rect(
            midright=(score_rect.left, score_rect.centery)
        )
        bg_rect = pygame.Rect(
            apple_rect.left,
            apple_rect.top,
            apple_rect.width + score_rect.width + 10,
            apple_rect.height,
        )

        pygame.draw.rect(self.configs.screen, Color.BACKGROUND, bg_rect)
        self.configs.screen.blit(score_surface, score_rect)
        self.configs.screen.blit(self.fruit.image, apple_rect)
        pygame.draw.rect(self.configs.screen, (0, 0, 0), bg_rect, 2)
