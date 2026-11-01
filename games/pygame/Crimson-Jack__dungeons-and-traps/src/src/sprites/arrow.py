import math

import pygame

from settings import Settings
from src.events import Events
from src.abstract_classes.damageable_enemy import DamageableEnemy
from src.enums.direction import Direction
from src.enums.sound_effect import SoundEffect
from src.game_helper import GameHelper
from src.sound_manager import SoundManager
from src.sprites.custom_draw_sprite import CustomDrawSprite
from src.sprite_helper import SpriteHelper


class Arrow(CustomDrawSprite):
    def __init__(self, position, groups, enemy_sprites, obstacle_sprites, moving_obstacle_sprites, arrow_direction):
        super().__init__(groups)

        # Sound
        self.sound_manager = SoundManager()

        # Direction and states
        self.direction = arrow_direction

        # Image
        self.image = self.get_image()
        self.rect = self.image.get_rect(topleft=position)
        self.hit_box = self.rect

        # Enemies
        self.enemy_sprites = enemy_sprites

        # Obstacles
        self.obstacle_sprites = obstacle_sprites
        self.moving_obstacle_sprites = moving_obstacle_sprites

        # Properties
        self.speed = GameHelper.multiply_by_tile_size_ratio(13)
        if (
                self.direction == Direction.RIGHT_UP or
                self.direction == Direction.LEFT_UP or
                self.direction == Direction.RIGHT_DOWN or
                self.direction == Direction.LEFT_DOWN
        ):
            # Normalize
            self.speed = self.speed / math.sqrt(2)

        self.damage_power = 60

    def get_image(self):
        sprites = SpriteHelper.get_all_arrow_sprites()

        image = None

        if self.direction == Direction.RIGHT:
            image = sprites['right'][0]
        elif self.direction == Direction.LEFT:
            image = sprites['left'][0]
        elif self.direction == Direction.UP:
            image = sprites['up'][0]
        elif self.direction == Direction.DOWN:
            image = sprites['down'][0]
        elif self.direction == Direction.RIGHT_UP:
            image = sprites['right_up'][0]
        elif self.direction == Direction.LEFT_UP:
            image = sprites['left_up'][0]
        elif self.direction == Direction.RIGHT_DOWN:
            image = sprites['right_down'][0]
        elif self.direction == Direction.LEFT_DOWN:
            image = sprites['left_down'][0]

        return image

    def custom_draw(self, game_surface, offset):
        offset_position = self.rect.topleft + offset
        game_surface.blit(self.image, offset_position)

    def update(self):
        self.move()

    def move(self):
        if self.direction == Direction.RIGHT:
            self.hit_box.x += self.speed
        elif self.direction == Direction.LEFT:
            self.hit_box.x -= self.speed
        elif self.direction == Direction.UP:
            self.hit_box.y -= self.speed
        elif self.direction == Direction.DOWN:
            self.hit_box.y += self.speed
        elif self.direction == Direction.RIGHT_UP:
            self.hit_box.x += self.speed
            self.hit_box.y -= self.speed
        elif self.direction == Direction.LEFT_UP:
            self.hit_box.x -= self.speed
            self.hit_box.y -= self.speed
        elif self.direction == Direction.RIGHT_DOWN:
            self.hit_box.x += self.speed
            self.hit_box.y += self.speed
        elif self.direction == Direction.LEFT_DOWN:
            self.hit_box.x -= self.speed
            self.hit_box.y += self.speed

        # Check collision
        self.check_collision()

    def check_collision(self):
        # Check collision with enemy sprites
        for sprite in self.enemy_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if pygame.sprite.spritecollide(self, pygame.sprite.GroupSingle(sprite), False,
                                               pygame.sprite.collide_mask):
                    sprite_hit_box = sprite.hit_box
                    if isinstance(sprite, DamageableEnemy):
                        self.sound_manager.play_sfx(SoundEffect.DECREASE_ENEMY_ENERGY_USING_BOW)
                        sprite.decrease_energy(self.damage_power)
                        self.kill()
                        self.create_particle_effect(sprite_hit_box, 12, Settings.ENEMY_PARTICLE_COLORS)
        # Check collision with obstacle sprites
        for sprite in self.obstacle_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if pygame.sprite.spritecollide(self, pygame.sprite.GroupSingle(sprite), False,
                                               pygame.sprite.collide_mask):
                    self.sound_manager.play_sfx(SoundEffect.COLLIDE_ARROW_WITH_OBSTACLE)
                    self.kill()
                    self.create_particle_effect(sprite.hit_box, 12, Settings.OBSTACLE_PARTICLE_COLORS)
        # Check collision with moving obstacle sprites
        for sprite in self.moving_obstacle_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if pygame.sprite.spritecollide(self, pygame.sprite.GroupSingle(sprite), False,
                                               pygame.sprite.collide_mask):
                    self.sound_manager.play_sfx(SoundEffect.COLLIDE_ARROW_WITH_OBSTACLE)
                    self.kill()
                    self.create_particle_effect(sprite.hit_box, 12, Settings.OBSTACLE_PARTICLE_COLORS)

    def create_particle_effect(self, target_sprite_hit_box, number_of_sparks, colors):
        collided_position = GameHelper.get_collided_rectangle(target_sprite_hit_box, self.hit_box).center
        pygame.event.post(
            pygame.event.Event(Events.ADD_PARTICLE_EFFECT_EVENT,
                               {"position": collided_position,
                                "number_of_sparks": number_of_sparks,
                                "colors": colors}))
