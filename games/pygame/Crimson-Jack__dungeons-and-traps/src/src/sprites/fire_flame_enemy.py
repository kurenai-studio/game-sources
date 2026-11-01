import pygame.surface

from settings import Settings
from src.abstract_classes.obstacle_map_observer import ObstacleMapObserver
from src.sprites.custom_draw_sprite import CustomDrawSprite
from src.sprite_costume import SpriteCostume
from src.tile_details.fire_flame_tile_details import FireFlameTileDetails


class FireFlameEnemy(CustomDrawSprite, ObstacleMapObserver):
    def __init__(self, sprites: list[SpriteCostume], position, groups, details: FireFlameTileDetails, moving_obstacle_sprites):
        super().__init__(groups)

        # Base
        self.damage_power = details.damage_power

        # Sprite animation variables
        self.sprites = sprites
        self.number_of_sprites = len(self.sprites)
        self.costume_switching_threshold = 14
        self.costume_step_counter = 0
        self.costume_index = 0

        # Image
        self.tail_length = 2
        self.image = self.get_merged_image()
        self.rect = self.image.get_rect(topleft=position)
        self.hit_box = self.rect

        # Movement variables
        self.is_moving = False
        self.max_fire_length = details.fire_length * Settings.TILE_SIZE

        # Motion variables
        self.motion_schedule = details.motion_schedule
        self.motion_step_counter = 0
        self.motion_index = 0
        self.motion_switching_threshold = self.motion_schedule[self.motion_index]

        # Moving obstacles
        self.moving_obstacle_sprites = moving_obstacle_sprites

        # Indicates the requirement to reset the image
        self.reset_is_required_for_image = False
        self.tail_length_after_collision = self.tail_length

    def get_merged_image(self) -> pygame.surface.Surface:
        pass

    def set_new_image(self):
        pass

    def custom_draw(self, game_surface, offset):
        # Draw sprite if reset is not required
        if not self.reset_is_required_for_image:
            offset_position = self.rect.topleft + offset
            game_surface.blit(self.image, offset_position)

    def move(self):
        pass

    def change_motion(self):
        # Change motion only if threshold exceeded
        if self.motion_step_counter > self.motion_switching_threshold:
            # Reset counter and increase motion index
            self.motion_step_counter = 0
            self.motion_index += 1
            # If it's the last motion state - start from the first state (index = 0)
            if self.motion_index >= len(self.motion_schedule):
                self.motion_index = 0

            # Set a new threshold from motion schedule
            self.motion_switching_threshold = self.motion_schedule[self.motion_index]

            # Start the moving
            self.is_moving = True

        # Increase step counter
        self.motion_step_counter += 1

        # Increase costume step counter
        self.costume_step_counter += 1

    def update(self):
        self.change_costume()
        if self.is_moving:
            self.move()
        else:
            self.change_motion()

        # Reset the image length if it's required
        if self.reset_is_required_for_image:
            # Set a new image
            self.tail_length = self.tail_length_after_collision
            self.set_new_image()
            # Reset is not required anymore
            self.reset_is_required_for_image = False

    def change_costume(self):
        # Change costume only if threshold exceeded
        if self.costume_step_counter > self.costume_switching_threshold:

            # Reset counter and increase costume index
            self.costume_step_counter = 0
            self.costume_index += 1

            # If it's the last costume - start from the second costume (index = 1)
            if self.costume_index > self.number_of_sprites:
                self.costume_index = 1

            # Set new image
            self.set_new_image()

    def get_damage_power(self):
        return self.damage_power
