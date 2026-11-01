from graphlib import TopologicalSorter

import pygame

from src.events import Events
from src.enums.direction import Direction
from src.enums.sound_effect import SoundEffect
from src.enums.weapon_type import WeaponType
from src.game_helper import GameHelper
from src.sound_manager import SoundManager
from src.sprites.bow_weapon import BowWeapon
from src.sprites.custom_draw_sprite import CustomDrawSprite
from src.sprites.explosion_weapon import ExplosionWeapon
from src.sprites.item_to_collect import ItemToCollect
from src.sprites.powerup import Powerup
from src.sprites.sword_weapon import SwordWeapon
from src.sprite_helper import SpriteHelper


class Player(CustomDrawSprite):
    def __init__(self, position, groups, weapon_groups, speed, exit_points, obstacle_sprites, moving_obstacle_sprites,
                 passage_sprites, teleport_sprites, collectable_sprites, enemy_sprites, hostile_force_sprites,
                 game_manager):
        super().__init__(groups)

        # Sound
        self.sound_manager = SoundManager()
        self.sound_switching_threshold = 8
        self.sound_counter = 0

        # Create sprite animation variables
        self.costume_switching_threshold = 5
        self.number_of_sprites = 4
        self.step_counter = 0
        self.costume_index = 0
        self.sprites = SpriteHelper.get_all_player_sprites(self.number_of_sprites)

        # Image
        self.position = position
        self.image = self.sprites['right'][0]
        self.rect = self.image.get_rect(topleft=self.position)
        self.hit_box = self.rect.inflate(GameHelper.multiply_by_tile_size_ratio(-5), 0)

        # Movement variables
        self.is_moving = False
        self.movement_vector = pygame.math.Vector2()
        self.movement_direction = Direction.RIGHT
        self.previous_movement_direction = Direction.RIGHT
        self.speed = speed

        # Real position is required to store the real distance, which is then cast to integer
        self.real_x_position = float(self.hit_box.x)
        self.real_y_position = float(self.hit_box.y)

        # Groups of collision
        self.exit_points = exit_points
        self.moving_obstacle_sprites = moving_obstacle_sprites
        self.obstacle_sprites = obstacle_sprites
        self.passage_sprites = passage_sprites
        self.teleport_sprites = teleport_sprites
        self.collectable_sprites = collectable_sprites
        self.enemy_sprites = enemy_sprites
        self.hostile_force_sprites = hostile_force_sprites

        # Game state
        self.game_manager = game_manager

        # State variables
        self.visible = True
        self.collided_with_enemy = False

        # Player weapon
        self.weapon_is_in_use = False
        self.sword_weapon = SwordWeapon(position, weapon_groups, game_manager, enemy_sprites, obstacle_sprites,
                                        moving_obstacle_sprites)
        self.bow_weapon = BowWeapon(position, weapon_groups, enemy_sprites, obstacle_sprites, moving_obstacle_sprites)
        self.explosion_weapon = ExplosionWeapon(position, weapon_groups, enemy_sprites)

        # Tile position
        self.tile_position = GameHelper.get_tile_by_point(self.get_center_point())
        self.game_manager.set_player_tile_position(self.tile_position)

    def get_input(self):
        self.movement_vector = self.game_manager.player_movement_vector
        self.movement_direction = self.game_manager.player_movement_direction
        self.weapon_is_in_use = self.game_manager.player_is_using_weapon

    def set_costume(self, current_direction, index):
        # Select appropriate costume for sprite
        if current_direction == Direction.RIGHT:
            self.image = self.sprites['right'][index]
        elif current_direction == Direction.LEFT:
            self.image = self.sprites['left'][index]
        elif current_direction == Direction.UP:
            self.image = self.sprites['up'][index]
        elif current_direction == Direction.DOWN:
            self.image = self.sprites['down'][index]
        elif current_direction == Direction.RIGHT_UP:
            self.image = self.sprites['right_up'][index]
        elif current_direction == Direction.RIGHT_DOWN:
            self.image = self.sprites['right_down'][index]
        elif current_direction == Direction.LEFT_UP:
            self.image = self.sprites['left_up'][index]
        elif current_direction == Direction.LEFT_DOWN:
            self.image = self.sprites['left_down'][index]

    def reset_costume(self):
        # Reset counter and costume index
        self.step_counter = 0
        self.costume_index = 0

        # Set image based on direction and costume index
        self.set_costume(self.movement_direction, self.costume_index)

    def change_costume(self):
        if self.is_moving:
            # Change costume only if threshold exceeded
            if self.step_counter > self.costume_switching_threshold:
                # Reset counter and increase costume index
                self.step_counter = 0
                self.costume_index += 1

                # If it's the last costume - start from the second costume (index = 1)
                if self.costume_index > self.number_of_sprites:
                    self.costume_index = 1

                # Set image based on direction and costume index
                self.set_costume(self.movement_direction, self.costume_index)

                # Sfx
                self.sound_manager.play_sfx(SoundEffect.MOVE_PLAYER)

            # The player's move is complete
            self.is_moving = False
        else:
            # Player is not moving
            # Reset costume if the time elapsed: 2 * threshold
            if self.step_counter > self.costume_switching_threshold * 2:
                # Reset counter and costume index
                self.step_counter = 0
                self.costume_index = 0

                # Set image based on direction and costume index
                self.set_costume(self.previous_movement_direction, self.costume_index)

    def move(self):
        # Normalize vector
        if self.movement_vector.magnitude() != 0:
            self.movement_vector = self.movement_vector.normalize()

        # Calculate real y position
        self.real_x_position += float(self.movement_vector.x * self.speed)
        self.real_y_position += float(self.movement_vector.y * self.speed)

        # Cast real position to integer and check the collision
        self.hit_box.x = int(self.real_x_position)
        self.check_horizontal_collision()
        self.hit_box.y = int(self.real_y_position)
        self.check_vertical_collision()
        self.check_collision()

        # If direction was changed
        if self.movement_direction != self.previous_movement_direction:
            # - set the first costume
            self.reset_costume()
            # - set the first costume for sword weapon and unblock the movement
            self.sword_weapon.set_costume(self.movement_direction, 0)
            self.sword_weapon.is_blocked = False
            # - set costume for bow
            self.bow_weapon.set_costume(self.movement_direction)
            # - set costume for explosion
            self.explosion_weapon.set_costume(self.movement_direction)

        # Check the movement
        if self.rect.center != self.hit_box.center:
            # Set the movement offset
            self.rect.center = self.hit_box.center

            # Player is moving
            self.is_moving = True

            # Save previous direction
            self.previous_movement_direction = self.movement_direction

            # Set player's new tile position
            new_tile_position = GameHelper.get_tile_by_point(self.get_center_point())
            if new_tile_position != self.tile_position:
                self.tile_position = new_tile_position
                self.game_manager.set_player_tile_position(self.tile_position)
                pygame.event.post(pygame.event.Event(Events.PLAYER_TILE_POSITION_CHANGED_EVENT))

        # Increase step counter
        self.step_counter += 1

    def check_collision(self):
        self.collided_with_enemy = False

        # Check collision with exit points
        for sprite in self.exit_points:
            if sprite.visible and sprite.hit_box.colliderect(self.hit_box):
                self.sound_manager.play_sfx(SoundEffect.COMPLETE_LEVEL)
                # Player is invisible
                self.visible = False
                # Trigger teleport player to next level event
                pygame.event.post(pygame.event.Event(Events.START_TELEPORT_PLAYER_TO_NEXT_LEVEL_EVENT))

        # Check collision with teleport sprites
        for sprite in self.teleport_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if not sprite.check_is_selected():
                    destinations = list(
                        filter(lambda item: item.port_name == sprite.destination, self.teleport_sprites))
                    if len(destinations) == 1:
                        self.sound_manager.play_sfx(SoundEffect.TELEPORT)
                        destination = destinations[0]
                        # Destination is selected = blocked for teleportation
                        destination.select()
                        # Player is invisible
                        self.visible = False
                        # Trigger teleport event
                        pygame.event.post(
                            pygame.event.Event(Events.TELEPORT_PLAYER_EVENT, {"position": destination.rect.topleft}))
            else:
                if self.visible:
                    # Unselect = unblock
                    sprite.unselect()

        # Check collision with collectable sprites and powerups
        for sprite in self.collectable_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if isinstance(sprite, ItemToCollect):
                    sprite.collect()
                if isinstance(sprite, Powerup):
                    sprite.activate()

        # Check collision with enemy sprites
        for sprite in self.enemy_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if pygame.sprite.spritecollide(self, pygame.sprite.GroupSingle(sprite), False,
                                               pygame.sprite.collide_mask):
                    if self.sound_counter > self.sound_switching_threshold:
                        self.sound_manager.play_sfx(SoundEffect.COLLIDE_PLAYER_WITH_ENEMY)
                        self.sound_counter = 0
                    else:
                        self.sound_counter += 1
                    self.collided_with_enemy = True
                    self.game_manager.decrease_player_energy(sprite.get_damage_power())

        # Check collision with hostile force sprites
        for sprite in self.hostile_force_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if pygame.sprite.spritecollide(self, pygame.sprite.GroupSingle(sprite), False,
                                               pygame.sprite.collide_mask):
                    if self.sound_counter > self.sound_switching_threshold:
                        self.sound_manager.play_sfx(SoundEffect.COLLIDE_PLAYER_WITH_HOSTILE_FORCE)
                        self.sound_counter = 0
                    else:
                        self.sound_counter += 1
                    self.collided_with_enemy = True
                    self.game_manager.decrease_player_energy(sprite.get_damage_power())

    def check_horizontal_collision(self):
        # Obstacle
        for sprite in self.obstacle_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if sprite in self.passage_sprites and self.game_manager.is_key_collected(sprite.key_name):
                    # Remove if key_name matches
                    sprite.kill()
                if self.movement_vector.x > 0:
                    self.hit_box.right = sprite.hit_box.left
                if self.movement_vector.x < 0:
                    self.hit_box.left = sprite.hit_box.right
                # Adjust position after collision
                self.real_x_position = float(self.hit_box.x)
                self.real_y_position = float(self.hit_box.y)

        # Moving obstacle
        for sprite in self.moving_obstacle_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if not sprite.move_obstacle_if_allowed(self.movement_direction):
                    # Obstacle has not been moved
                    if self.movement_vector.x > 0:
                        self.hit_box.right = sprite.hit_box.left
                    if self.movement_vector.x < 0:
                        self.hit_box.left = sprite.hit_box.right
                    # Adjust position after collision
                    self.real_x_position = float(self.hit_box.x)
                    self.real_y_position = float(self.hit_box.y)

    def check_vertical_collision(self):
        # Obstacle
        for sprite in self.obstacle_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if sprite in self.passage_sprites and self.game_manager.is_key_collected(sprite.key_name):
                    # Remove if key_name matches
                    sprite.kill()
                if self.movement_vector.y > 0:
                    self.hit_box.bottom = sprite.hit_box.top
                if self.movement_vector.y < 0:
                    self.hit_box.top = sprite.hit_box.bottom
                # Adjust position after collision
                self.real_x_position = float(self.hit_box.x)
                self.real_y_position = float(self.hit_box.y)

        # Moving obstacle
        for sprite in self.moving_obstacle_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if not sprite.move_obstacle_if_allowed(self.movement_direction):
                    # Obstacle has not been moved
                    if self.movement_vector.y > 0:
                        self.hit_box.bottom = sprite.hit_box.top
                    if self.movement_vector.y < 0:
                        self.hit_box.top = sprite.hit_box.bottom
                    # Adjust position after collision
                    self.real_x_position = float(self.hit_box.x)
                    self.real_y_position = float(self.hit_box.y)

    def use_weapon(self):
        if self.game_manager.weapon_type == WeaponType.NONE:
            self.sword_weapon.disarm_weapon()
            self.bow_weapon.disarm_weapon()
            self.explosion_weapon.disarm_weapon()
            pygame.event.post(pygame.event.Event(Events.PLAYER_IS_NOT_USING_WEAPON_EVENT))

        elif self.game_manager.weapon_type == WeaponType.SWORD:
            self.bow_weapon.disarm_weapon()
            self.explosion_weapon.disarm_weapon()
            self.sword_weapon.set_position(self.rect.topleft)
            self.sword_weapon.arm_weapon()
            if self.weapon_is_in_use:
                self.sword_weapon.start_cutting()
            else:
                self.sword_weapon.stop_cutting()

        elif self.game_manager.weapon_type == WeaponType.BOW:
            self.sword_weapon.disarm_weapon()
            self.explosion_weapon.disarm_weapon()
            self.bow_weapon.set_position(self.rect.topleft)
            self.bow_weapon.arm_weapon()
            if self.weapon_is_in_use:
                if self.game_manager.number_of_arrows > 0:
                    self.bow_weapon.fire()
                    self.game_manager.decrease_number_of_arrows()
                pygame.event.post(pygame.event.Event(Events.PLAYER_IS_NOT_USING_WEAPON_EVENT))

        elif self.game_manager.weapon_type == WeaponType.EXPLOSION:
            self.sword_weapon.disarm_weapon()
            self.bow_weapon.disarm_weapon()
            self.explosion_weapon.set_position(self.rect.topleft)
            self.explosion_weapon.arm_weapon()
            if self.weapon_is_in_use:
                if self.game_manager.number_of_explosions > 0:
                    if self.explosion_weapon.fire():
                        self.game_manager.decrease_number_of_explosions()
                pygame.event.post(pygame.event.Event(Events.PLAYER_IS_NOT_USING_WEAPON_EVENT))

    def update(self):
        if self.visible:
            self.get_input()
            self.change_costume()
            self.move()
        # NOTE: move() may set visible=False via teleport/exit collision.
        # Re-checked here to prevent weapon firing during transition animations.
        if self.visible:
            self.use_weapon()

    def custom_draw(self, game_surface, offset):
        if self.visible:
            # Draw sprite
            offset_position = self.rect.topleft + offset
            game_surface.blit(self.image, offset_position)

            # Draw an outline if it is collided
            if self.collided_with_enemy:
                outline_image = pygame.surface.Surface.copy(self.image)
                mask = pygame.mask.from_surface(self.image)
                mask_outline = mask.outline()
                pygame.draw.polygon(outline_image, (255, 255, 255), mask_outline,
                                    int(GameHelper.multiply_by_tile_size_ratio(1, 1)))
                game_surface.blit(outline_image, offset_position)

    def get_center_point(self):
        return self.hit_box.center

    def disable(self):
        self.visible = False
        self.sword_weapon.disarm_weapon()
        self.bow_weapon.disarm_weapon()
        self.explosion_weapon.disarm_weapon()

    def enable(self):
        self.visible = True

    def trigger_tombstone_creation(self):
        self.sound_manager.play_sfx(SoundEffect.LOST_LIFE)
        pygame.event.post(pygame.event.Event(Events.ADD_TOMBSTONE_EVENT, {"position": self.rect.topleft}))

    def trigger_vanishing_point_creation(self):
        pygame.event.post(pygame.event.Event(Events.ADD_VANISHING_POINT_EVENT, {"position": self.rect.topleft}))

    def respawn(self, position=None):
        if position is None:
            position = self.position
        self.change_position(position)

    def change_position(self, new_position):
        self.rect = self.image.get_rect(topleft=new_position)
        self.hit_box = self.rect.inflate(GameHelper.multiply_by_tile_size_ratio(-5), 0)
        self.real_x_position = float(self.hit_box.x)
        self.real_y_position = float(self.hit_box.y)
