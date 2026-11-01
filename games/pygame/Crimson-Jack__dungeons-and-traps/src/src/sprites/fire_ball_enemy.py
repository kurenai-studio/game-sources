import math

import pygame

from settings import Settings
from src.events import Events
from src.enums.sound_effect import SoundEffect
from src.game_helper import GameHelper
from src.sound_manager import SoundManager
from src.sprite_helper import SpriteHelper


class FireBallEnemy(pygame.sprite.Sprite):
    def __init__(self, position, groups, game_manager, obstacle_sprites, moving_obstacle_sprites):
        super().__init__(*groups)

        # Sound
        self.sound_manager = SoundManager()

        # Base
        self.game_manager = game_manager
        self.damage_power = 30

        # Sprite animation variables
        self.sprites = SpriteHelper.get_all_fire_ball_enemy_sprites()
        self.number_of_sprites = len(self.sprites)
        self.costume_switching_threshold = 10
        self.costume_step_counter = 0
        self.costume_index = 0

        # Image
        self.image = self.sprites[0]
        self.rect = self.image.get_rect(topleft=position)
        self.hit_box = self.rect

        # Player position
        self.player_top_left_position = GameHelper.get_point_by_tile(self.game_manager.player_tile_position)

        # Obstacles
        self.obstacle_sprites = obstacle_sprites
        self.moving_obstacle_sprites = moving_obstacle_sprites

        # Movement variables
        self.speed = GameHelper.multiply_by_tile_size_ratio(10)
        self.movement_vector = pygame.math.Vector2((1, 0))
        self.set_movement_vector()

        # Distance properties
        self.path_distance = 0
        self.path_distance_threshold = Settings.TILE_SIZE * 10

        # Real position is required to store the real distance, which is then cast to integer
        self.real_x_position = float(self.hit_box.x)
        self.real_y_position = float(self.hit_box.y)

    def update(self):
        if self.number_of_sprites > 1:
            self.change_costume()

        self.move()

        if self.path_distance > self.path_distance_threshold:
            tile = GameHelper.get_tile_by_point(self.hit_box)
            position = GameHelper.get_point_by_tile(tile)

            if abs(self.hit_box.x - position[0]) <= 2 and abs(self.hit_box.y - position[1]) <= 2:
                pygame.event.post(
                    pygame.event.Event(Events.CREATE_EGG_EVENT, {"position": position}))
                self.kill()

    def move(self):
        # Calculate real y position
        self.real_x_position += float(self.movement_vector.x * self.speed)
        self.real_y_position += float(self.movement_vector.y * self.speed)

        # Cast real position to integer
        self.hit_box.x = int(self.real_x_position)
        self.hit_box.y = int(self.real_y_position)

        # Increase distance
        self.path_distance += self.speed

        # Check collision
        self.check_collision()

        # Increase costume step counter
        self.costume_step_counter += 1

    def check_collision(self):
        # Check collision with obstacle sprites
        for sprite in self.obstacle_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if pygame.sprite.spritecollide(self, pygame.sprite.GroupSingle(sprite), False,
                                               pygame.sprite.collide_mask):
                    self.sound_manager.play_sfx(SoundEffect.COLLIDE_FIREBALL_WITH_OBSTACLE)
                    self.kill()
                    self.create_particle_effect(sprite.hit_box, 12, Settings.OBSTACLE_PARTICLE_COLORS)
                    pygame.event.post(pygame.event.Event(Events.TILT_EFFECT_EVENT))
        # Check collision with moving obstacle sprites
        for sprite in self.moving_obstacle_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if pygame.sprite.spritecollide(self, pygame.sprite.GroupSingle(sprite), False,
                                               pygame.sprite.collide_mask):
                    self.sound_manager.play_sfx(SoundEffect.COLLIDE_FIREBALL_WITH_OBSTACLE)
                    self.kill()
                    self.create_particle_effect(sprite.hit_box, 12, Settings.OBSTACLE_PARTICLE_COLORS)
                    pygame.event.post(pygame.event.Event(Events.TILT_EFFECT_EVENT))

    def create_particle_effect(self, target_sprite_hit_box, number_of_sparks, colors):
        collided_position = GameHelper.get_collided_rectangle(target_sprite_hit_box, self.hit_box).center
        pygame.event.post(
            pygame.event.Event(Events.ADD_PARTICLE_EFFECT_EVENT,
                               {"position": collided_position,
                                "number_of_sparks": number_of_sparks,
                                "colors": colors}))

    def set_movement_vector(self):
        distance = math.sqrt(
            (self.rect.topleft[0] - self.player_top_left_position[0]) ** 2 +
            (self.rect.topleft[1] - self.player_top_left_position[1]) ** 2
        )

        x = (self.player_top_left_position[0] - self.rect.topleft[0])
        y = (self.player_top_left_position[1] - self.rect.topleft[1])

        if distance != 0:
            self.movement_vector = pygame.math.Vector2(x / distance, y / distance)

    def change_costume(self):
        # Change costume only if threshold exceeded
        if self.costume_step_counter > self.costume_switching_threshold:

            # Reset counter and increase costume index
            self.costume_step_counter = 0
            self.costume_index += 1

            # If it's the last costume - start from the second costume (index = 1)
            if self.costume_index >= self.number_of_sprites:
                self.costume_index = 0

            # Set new image
            self.image = self.sprites[self.costume_index]

    def get_damage_power(self):
        return self.damage_power
