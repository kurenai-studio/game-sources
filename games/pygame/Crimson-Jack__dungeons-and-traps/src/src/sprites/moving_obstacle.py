import pygame

from settings import Settings
from src.events import Events
from src.bar import Bar
from src.color_set import ColorSet
from src.enums.direction import Direction
from src.game_helper import GameHelper
from src.sprites.custom_draw_sprite import CustomDrawSprite


class MovingObstacle(CustomDrawSprite):
    def __init__(self, image, position: list, groups, game_manager, obstacle_map_items, collision_sprites):
        super().__init__(groups)
        self.position = position
        self.image = pygame.transform.scale(image, (Settings.TILE_SIZE, Settings.TILE_SIZE))
        self.rect = self.image.get_rect(topleft=position)
        self.obstacle_map_items = obstacle_map_items
        self.collision_sprites = collision_sprites
        self.game_manager = game_manager

        # Power variables to move obstacle
        self.power = 0
        self.power_step = 5
        self.power_needed_to_move_obstacle = 50

        # Create power bar
        bar_width = Settings.TILE_SIZE - GameHelper.multiply_by_tile_size_ratio(10)
        bar_height = GameHelper.multiply_by_tile_size_ratio(12, 9)
        bar_left, bar_top = self.get_bar_position()
        bar_colors = ColorSet([
            ((0, 25), (255, 0, 0)),
            ((25, 50), (200, 0, 0)),
            ((50, 75), (114, 0, 20)),
            ((75, 100), (0, 0, 0))
        ])
        self.power_bar = Bar(
            position=(bar_left, bar_top),
            width=bar_width,
            height=bar_height,
            bar_colors=bar_colors,
            outline_color=(64, 78, 107),
            background_color=(254, 240, 202))

    def calculate_new_position(self, movement_direction):
        new_position_x = self.position[0]
        new_position_y = self.position[1]

        # Calculate a new position
        if movement_direction == Direction.RIGHT:
            new_position_x = self.position[0] + Settings.TILE_SIZE
            new_position_y = self.position[1]
        elif movement_direction == Direction.LEFT:
            new_position_x = self.position[0] - Settings.TILE_SIZE
            new_position_y = self.position[1]
        elif movement_direction == Direction.UP:
            new_position_x = self.position[0]
            new_position_y = self.position[1] - Settings.TILE_SIZE
        elif movement_direction == Direction.DOWN:
            new_position_x = self.position[0]
            new_position_y = self.position[1] + Settings.TILE_SIZE

        # Calculate new position on the map
        new_map_x = new_position_x // Settings.TILE_SIZE
        new_map_y = new_position_y // Settings.TILE_SIZE

        return new_position_x, new_position_y, new_map_x, new_map_y

    def check_if_destination_tile_is_empty(self, new_position_x, new_position_y):
        source_hit_box = pygame.rect.Rect(new_position_x, new_position_y, Settings.TILE_SIZE,
                                          Settings.TILE_SIZE)
        for collision_sprite_group in self.collision_sprites:
            for sprite in collision_sprite_group:
                if sprite.hit_box.colliderect(source_hit_box):
                    return False
        return True

    def move_obstacle_if_allowed(self, movement_direction):
        # Increase power
        self.increase_power()

        # Get old position
        old_position_x, old_position_y = self.position[0], self.position[1]
        # Calculate old position on the map
        old_map_x = old_position_x // Settings.TILE_SIZE
        old_map_y = old_position_y // Settings.TILE_SIZE
        # Get a new position and a new position on map
        new_position_x, new_position_y, new_map_x, new_map_y = self.calculate_new_position(movement_direction)

        # Execute the movement if it's allowed
        if self.power > self.power_needed_to_move_obstacle:
            if self.check_if_destination_tile_is_empty(new_position_x, new_position_y):
                # Set new coordinates
                self.position = [new_position_x, new_position_y]
                # Set a new bar position
                bar_left, bar_top = self.get_bar_position()
                self.power_bar.change_position((bar_left, bar_top))
                # Change rectangle position
                self.rect.x = int(self.position[0])
                self.rect.y = int(self.position[1])
                # Change obstacle map
                self.obstacle_map_items[old_map_y][old_map_x] = 0
                self.obstacle_map_items[new_map_y][new_map_x] = 1
                # Raise event to refresh obstacle map
                pygame.event.post(pygame.event.Event(Events.REFRESH_OBSTACLE_MAP_EVENT))
                # Reset power
                self.reset_power()
                # Obstacle has been moved
                return True
            else:
                # Obstacle has not been moved
                return False
        else:
            # Obstacle has not been moved
            return False

    def decrease_power(self):
        if self.power > 0:
            self.power -= self.power_step // 2

    def increase_power(self):
        if self.power <= self.power_needed_to_move_obstacle:
            self.power += self.power_step

    def reset_power(self):
        self.power = self.power_needed_to_move_obstacle // 3

    def update(self):
        super().update()
        self.decrease_power()

    def custom_draw(self, game_surface, offset):
        offset_position = self.rect.topleft + offset
        game_surface.blit(self.image, offset_position)

        power_value = self.power if self.power <= self.power_needed_to_move_obstacle \
            else self.power_needed_to_move_obstacle

        if power_value > 0:
            self.power_bar.draw(game_surface, power_value, self.power_needed_to_move_obstacle, offset)

    def get_culling_rect(self):
        # The power bar is drawn above the obstacle, outside the sprite rectangle
        power_bar_rect = pygame.rect.Rect(self.power_bar.position, (self.power_bar.width, self.power_bar.height))
        return self.rect.union(power_bar_rect)

    def get_bar_position(self):
        left_offset = GameHelper.multiply_by_tile_size_ratio(10) // 2
        bar_left = self.position[0] + left_offset
        bar_top = self.position[1] - GameHelper.multiply_by_tile_size_ratio(16)
        return bar_left, bar_top

