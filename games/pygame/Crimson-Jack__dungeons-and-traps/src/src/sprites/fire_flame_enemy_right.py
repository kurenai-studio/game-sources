import pygame

from settings import Settings
from src.sprites.fire_flame_enemy import FireFlameEnemy
from src.sprite_costume import SpriteCostume
from src.tile_details.fire_flame_tile_details import FireFlameTileDetails


class FireFlameEnemyRight(FireFlameEnemy):
    def __init__(self, sprites: list[SpriteCostume], position, groups, details: FireFlameTileDetails, moving_obstacle_sprites):
        super().__init__(sprites, position, groups, details, moving_obstacle_sprites)

        # Rectangle from image
        self.rect = self.image.get_rect(topright=(position[0] + Settings.TILE_SIZE, position[1]))
        self.hit_box = self.rect

        # Max left and right positions of the flame
        self.max_rect_left_flame_position = self.rect.left
        self.max_rect_right_flame_position = self.rect.right

        # Movement variables
        self.movement_vector = pygame.math.Vector2((1, 0))
        self.speed = details.speed

        # Real position is required to store the real distance, which is then cast to integer
        self.real_x_position = float(self.hit_box.right)

    def get_merged_image(self) -> pygame.surface.Surface:
        merged_image = pygame.surface.Surface((Settings.TILE_SIZE*self.tail_length, Settings.TILE_SIZE))
        merged_image = merged_image.convert_alpha()
        merged_image.fill((0, 0, 0, 0))

        for index in range(self.tail_length):
            # TODO: Add a property to the selected mode:
            #  [1] - all tiles in a merged sprite have the same costume
            #  [2] - each tile in a merged sprite has a different costume
            frame_costume_index = (self.tail_length - index + self.costume_index) % self.number_of_sprites
            base_image = self.sprites[frame_costume_index].image
            merged_image.blit(base_image, (Settings.TILE_SIZE * index, 0))

        return merged_image

    def set_new_image(self):
        # super().set_new_image()
        self.image = self.get_merged_image()

        # Change (increase or decrease) rectangle and hit_box
        self.rect = self.image.get_rect(topright=self.rect.topright)
        self.hit_box = self.rect

    def move(self):
        # Calculate real y position
        self.real_x_position += float(self.movement_vector.x * self.speed)

        # Check collision with moving obstacles
        (collision_detected, collision_hit_box_left) = self.check_collision()
        if collision_detected:
            # Set fire flame left border
            self.hit_box.right = collision_hit_box_left
            # Change movement vector always to the right direction
            self.movement_vector.x = -1
            # Adjust position after collision
            self.real_x_position = float(self.hit_box.right)
        else:
            # Check start position
            if self.real_x_position > self.max_rect_right_flame_position + self.max_fire_length - Settings.TILE_SIZE:
                # Reverse
                self.movement_vector.x *= -1
            # Check fire flame length
            elif self.real_x_position < self.max_rect_right_flame_position - Settings.TILE_SIZE:
                # Reverse
                self.movement_vector.x *= -1
                # Stop the moving
                self.is_moving = False

        # Cast real position to integer
        self.hit_box.right = int(self.real_x_position)

        # Set the movement offset
        self.rect.center = self.hit_box.center

        # Adjust offset
        # This is necessary for offsets that are not TILE_SIZE dividers
        x_remainder = self.rect.right % Settings.TILE_SIZE

        if x_remainder < self.speed:
            self.hit_box.right = self.hit_box.right - x_remainder
            self.rect.center = self.hit_box.center

        # Recognize the moment when fire flame moves to a new area
        if self.hit_box.right % Settings.TILE_SIZE == 0:

            # Calculate the length
            self.tail_length = (self.hit_box.right - self.max_rect_left_flame_position) // Settings.TILE_SIZE
            if self.tail_length < 1:
                self.tail_length = 1

            if self.movement_vector.x < 0:
                self.tail_length -= 1

            # Set image
            self.set_new_image()

        # Increase costume step counter
        self.costume_step_counter += 1

    def check_collision(self):
        is_collision_detected = False
        hit_box_left = 0

        # Moving obstacle
        for sprite in self.moving_obstacle_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                # Save collided sprite right border
                hit_box_left = sprite.hit_box.left
                # Collision was detected
                is_collision_detected = True
                break

        return is_collision_detected, hit_box_left

    def refresh_obstacle_map(self):
        # Check if moving obstacle is collided with the flame
        collision_detected, collision_hit_box_left = self.check_collision()
        if collision_detected:
            # Calculate tail length
            self.tail_length_after_collision = ((collision_hit_box_left - self.max_rect_left_flame_position)
                                                // Settings.TILE_SIZE)
            # Set flag - reset is required for the image
            self.reset_is_required_for_image = True
