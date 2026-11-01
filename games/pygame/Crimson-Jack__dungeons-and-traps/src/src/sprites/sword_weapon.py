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


class SwordWeapon(CustomDrawSprite):
    def __init__(self, position, groups, game_manager, enemy_sprites, obstacle_sprites, moving_obstacle_sprites):
        super().__init__(groups)

        # Sound
        self.sound_manager = SoundManager()

        # Base
        self.game_manager = game_manager

        # Sprite animation variables
        self.sprites = SpriteHelper.get_all_sword_sprites()
        self.costume_switching_threshold = 1
        self.number_of_sprites = 8
        self.costume_step_counter = 0
        self.costume_step_counter_increment = 2
        self.costume_index = 0

        # Image
        self.image = self.sprites['right'][0]
        self.rect = self.image.get_rect(topleft=position)
        self.hit_box = self.rect

        # Direction and states
        self.direction = Direction.RIGHT
        self.is_armed = True
        self.is_moving = False
        self.is_blocked = False

        # Enemies
        self.enemy_sprites = enemy_sprites

        # Obstacles
        self.obstacle_sprites = obstacle_sprites
        self.moving_obstacle_sprites = moving_obstacle_sprites

        # Other
        self.damage_power = 5

    def set_costume(self, new_direction, index):
        self.direction = new_direction
        # Set image based on direction
        if self.direction == Direction.RIGHT:
            self.image = self.sprites['right'][index]
        elif self.direction == Direction.LEFT:
            self.image = self.sprites['left'][index]
        elif (self.direction == Direction.UP or
              self.direction == Direction.LEFT_UP or
              self.direction == Direction.RIGHT_UP):
            self.image = self.sprites['up'][index]
        elif (self.direction == Direction.DOWN or
              self.direction == Direction.LEFT_DOWN or
              self.direction == Direction.RIGHT_DOWN):
            self.image = self.sprites['down'][index]

    def set_position(self, position):
        # Calculate additional offset
        new_position = [position[0], position[1]]
        position_offset = GameHelper.multiply_by_tile_size_ratio(24)
        # Add additional offset to the base position
        if self.direction == Direction.RIGHT:
            new_position[0] += position_offset
        elif self.direction == Direction.LEFT:
            new_position[0] -= position_offset
        elif (self.direction == Direction.DOWN or
              self.direction == Direction.LEFT_DOWN or
              self.direction == Direction.RIGHT_DOWN):
            new_position[1] += position_offset
        elif (self.direction == Direction.UP or
              self.direction == Direction.LEFT_UP or
              self.direction == Direction.RIGHT_UP):
            new_position[1] -= position_offset

        self.rect = self.image.get_rect(topleft=new_position)
        self.hit_box = self.rect

    def update(self):
        self.change_costume()
        if self.is_armed and self.is_moving:
            self.move()

    def custom_draw(self, game_surface, offset):
        if self.is_armed and self.is_moving and not self.is_blocked:
            # Draw sprite
            offset_position = self.rect.topleft + offset
            game_surface.blit(self.image, offset_position)

    def move(self):
        # Check collision
        self.check_collision()
        # Increase costume step counter
        self.costume_step_counter += self.costume_step_counter_increment

    def check_collision(self):
        # Check collision with enemy sprites
        for sprite in self.enemy_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if pygame.sprite.spritecollide(self, pygame.sprite.GroupSingle(sprite), False,
                                               pygame.sprite.collide_mask):
                    sprite_hit_box = sprite.hit_box
                    if isinstance(sprite, DamageableEnemy):
                        self.sound_manager.play_sfx(SoundEffect.DECREASE_ENEMY_ENERGY_USING_SWORD)
                        self.game_manager.decrease_sword_energy()
                        sprite.decrease_energy(self.damage_power)
                        self.create_particle_effect(sprite_hit_box, 1, Settings.ENEMY_PARTICLE_COLORS)
        # Check collision with obstacle sprites
        for sprite in self.obstacle_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if pygame.sprite.spritecollide(self, pygame.sprite.GroupSingle(sprite), False,
                                               pygame.sprite.collide_mask):
                    self.is_moving = False
                    self.is_blocked = True
        # Check collision with moving obstacle sprites
        for sprite in self.moving_obstacle_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if pygame.sprite.spritecollide(self, pygame.sprite.GroupSingle(sprite), False,
                                               pygame.sprite.collide_mask):
                    self.is_moving = False
                    self.is_blocked = True

    def create_particle_effect(self, target_sprite_hit_box, number_of_sparks, colors):
        collided_position = GameHelper.get_collided_rectangle(target_sprite_hit_box, self.hit_box).center
        pygame.event.post(
            pygame.event.Event(Events.ADD_PARTICLE_EFFECT_EVENT,
                               {"position": collided_position,
                                "number_of_sparks": number_of_sparks,
                                "colors": colors}))

    def change_costume(self):
        # Change costume only if threshold exceeded
        if self.costume_step_counter > self.costume_switching_threshold:
            # Reset counter and increase costume index
            self.costume_step_counter = 0
            self.costume_index += 1

            # If it's the last costume - start from the first costume (index = 0)
            if self.costume_index >= self.number_of_sprites:
                self.costume_index = 0
                pygame.event.post(pygame.event.Event(Events.PLAYER_IS_NOT_USING_WEAPON_EVENT))

            # Set new image
            self.set_costume(self.direction, self.costume_index)

    def arm_weapon(self):
        self.is_armed = True

    def disarm_weapon(self):
        self.is_armed = False

    def start_cutting(self):
        if not self.is_moving:
            self.sound_manager.play_sfx(SoundEffect.STRIKE_WITH_SWORD)
        self.is_moving = True

    def stop_cutting(self):
        self.is_moving = False
