import pygame
from tile import DotColor, Tile
from settings import *


class Screen:
    def __init__(self):
        self.display_surf = pygame.display.get_surface()
        self.surf = self.make_surf()
        self.stop = False

    def make_surf(self):
        raise NotImplementedError

    def draw(self):
        self.display_surf.blit(self.surf, (0, 0))
        pygame.display.update()

    def click(self, pos):
        self.stop = True


class IntroScreen(Screen):
    def __init__(self):
        super().__init__()

    def make_surf(self):
        black = (0, 25, 0)
        green = (155, 220, 155)

        surf = pygame.surface.Surface(self.display_surf.get_size())
        surf.fill(green)
        font = pygame.font.SysFont('Arial', SCREEN_WIDTH // 10)
        text = font.render('DOTS', False, black)
        text_pos = (self.display_surf.get_width() // 2 - text.get_width() // 2, self.display_surf.get_height() // 4)

        surf.blit(text, text_pos)
        return surf


class GameFieldScreen(Screen):
    def __init__(self, game_round):
        self.game_round = game_round
        self.game_field = game_round.game_field
        super().__init__()
        self.tile_group = pygame.sprite.Group()
        self.make_tiles()

    def make_surf(self):
        line_width = TILE_SIZE // 10
        space_between_lines = TILE_SIZE - line_width
        start_pos = (space_between_lines // 2, space_between_lines // 2)

        surf = pygame.Surface(pygame.display.get_surface().get_size())

        # Colors
        white = (250, 255, 255)
        red = (165, 100, 140)
        blue = (160, 200, 215)

        pos_x, pos_y = start_pos

        # Draw white background
        surf.fill(white)

        # Draw horizontal lines
        for y in range(self.game_field.height):
            pygame.draw.line(surf, blue, [0, pos_y], [SCREEN_WIDTH, pos_y], line_width)
            pos_y += space_between_lines

        # Draw vertical lines
        for x in range(self.game_field.width):
            pygame.draw.line(surf, blue, [pos_x, 0], [pos_x, SCREEN_HEIGHT], line_width)
            pos_x += space_between_lines

        # Draw red vertical line
        pygame.draw.line(surf, red, [pos_x, 0], [pos_x, SCREEN_HEIGHT], line_width)
        return surf

    def make_tiles(self):
        line_width = TILE_SIZE // 10
        space_between_lines = TILE_SIZE - line_width
        start_pos = (space_between_lines // 2, space_between_lines // 2)
        dot_radius = TILE_SIZE // 3

        for y, row in enumerate(self.game_field.map):
            for x in range(len(row)):
                pos_x = x * space_between_lines + start_pos[0] - TILE_SIZE // 3
                pos_y = y * space_between_lines + start_pos[1] - TILE_SIZE // 3
                pos = (pos_x, pos_y)
                Tile((x, y), pos, dot_radius * 2.5).add(self.tile_group)

    def draw(self):
        self.display_surf.blit(self.surf, (0, 0))
        pygame.display.update()

    def update(self):
        for tile in self.tile_group:
            x, y = tile.map_pos
            dot_color = DotColor(self.game_field.map[y][x])
            tile.fill(dot_color)
        self.tile_group.draw(self.display_surf)
        pygame.display.update()

    def click(self, pos):
        for tile in self.tile_group:
            if tile.rect.collidepoint(pos):
                self.game_round.get_tile(tile)
                return


class GameOverScreen(Screen):
    def __init__(self, winner_name):
        self.winner_name = winner_name
        super().__init__()

    def make_surf(self):
        black = (0, 25, 0)
        green = (155, 220, 155)

        surf = pygame.surface.Surface(self.display_surf.get_size())
        surf.fill(green)
        font = pygame.font.SysFont('Arial', SCREEN_WIDTH // 10)
        text = font.render('GAME OVER', False, black)
        text_pos = (self.display_surf.get_width() // 2 - text.get_width() // 2, self.display_surf.get_height() // 4)

        winner = font.render(self.winner_name + ' wins', False, black)
        winner_pos = (self.display_surf.get_width() // 2 - winner.get_width() // 2, self.display_surf.get_height() // 2)

        surf.blit(text, text_pos)
        surf.blit(winner, winner_pos)
        return surf
