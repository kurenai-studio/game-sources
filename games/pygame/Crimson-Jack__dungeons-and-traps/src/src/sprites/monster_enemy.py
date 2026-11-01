import random

import pygame

from settings import Settings
from src.events import Events
from src.abstract_classes.pathfinding_enemy import PathfindingEnemy
from src.abstract_classes.damageable_enemy import DamageableEnemy
from src.abstract_classes.obstacle_map_observer import ObstacleMapObserver
from src.enums.enemy_type import EnemyType
from src.enums.sound_effect import SoundEffect
from src.game_helper import GameHelper
from src.geometry_helper import GeometryHelper
from src.factories.search_path_algorithm_factory import SearchPathAlgorithmFactory
from src.sound_manager import SoundManager
from src.sprite_costume import SpriteCostume
from src.sprites.custom_draw_sprite import CustomDrawSprite
from src.tile_details.monster_tile_details import MonsterTileDetails


class MonsterEnemy(CustomDrawSprite, PathfindingEnemy, DamageableEnemy, ObstacleMapObserver):
    def __init__(self, sprites: list[SpriteCostume], sprite_image_in_damage_state: pygame.Surface, position, groups,
                 game_manager, enemy_type: EnemyType, details: MonsterTileDetails, obstacle_map, obstacle_sprites,
                 moving_obstacle_sprites, hostile_force_sprites):
        super().__init__(groups)

        # Sound
        self.sound_manager = SoundManager()

        # Base
        self.game_manager = game_manager
        self.enemy_type = enemy_type
        self.damage_power = details.damage_power
        self.score = details.score
        self.attack_only_when_visible = details.attack_only_when_visible

        # Energy
        self.max_energy = details.energy
        self.energy = self.max_energy

        # Sprite animation variables
        self.sprites = sprites
        self.number_of_sprites = len(self.sprites)
        self.costume_step_counter = 0
        self.costume_index = 0

        # Sprite image in a damage state
        self.sprite_image_in_damage_state = sprite_image_in_damage_state

        # Image
        self.image = self.sprites[0].image
        self.rect = self.image.get_rect(topleft=position)
        self.hit_box = self.rect

        # Obstacle map
        self.obstacle_map = obstacle_map

        # Movement variables
        self.speed = details.speed
        self.full_speed = self.speed
        self.not_full_speed = self.speed * 0.6
        self.movement_vector = pygame.math.Vector2(0, 0)
        self.is_moving = False
        self.start_delay = details.start_delay
        self.start_delay_counter = self.start_delay
        self.range = 10

        # Set positions on map
        self.current_position_on_map = [
            (self.rect.right // Settings.TILE_SIZE) - 1,
            (self.rect.bottom // Settings.TILE_SIZE) - 1
        ]
        self.new_position_on_map = list(self.current_position_on_map)

        # Path variables
        self.all_tiles = set()
        self.obstacles = set()
        self.create_all_tiles_and_obstacles_lists()
        self.search_path = SearchPathAlgorithmFactory.create(details.search_path_algorithm)
        self.path = []

        # Real position is required to store the real distance, which is then cast to integer
        self.real_x_position = float(self.hit_box.x)
        self.real_y_position = float(self.hit_box.y)

        # Obstacles and Moving obstacles
        self.obstacle_sprites = obstacle_sprites
        self.moving_obstacle_sprites = moving_obstacle_sprites

        # Hostile forces
        self.hostile_force_sprites = hostile_force_sprites

        # State variables
        self.collided_with_weapon = False
        self.is_resting = False

    def create_all_tiles_and_obstacles_lists(self):
        for x in range(len(self.obstacle_map.items)):
            for y in range(len(self.obstacle_map.items[x])):
                if self.obstacle_map.items[x][y] > 0:
                    self.obstacles.add((y, x))
                else:
                    self.all_tiles.add((y, x))

    def update(self):
        if len(self.path) > 0:
            # If path is defined, full speed chase
            self.speed = self.full_speed
        else:
            # If path is not defined, the monster walks slowly
            self.speed = self.not_full_speed

        if self.number_of_sprites > 1:
            self.change_costume()

        if self.is_moving:
            self.move()
        else:
            if self.is_resting:
                self.start_delay_counter -= 1
                if self.start_delay_counter < 0:
                    self.start_delay_counter = self.start_delay
                    self.is_resting = False
            if not self.is_resting:
                if self.is_player_in_range() and self.verify_attack_readiness():
                    self.calculate_path_to_player()
                    if self.try_to_set_movement_vector_from_path():
                        self.is_moving = True
                if not self.is_moving:
                    if self.try_to_set_random_movement_vector():
                        self.path.clear()
                        self.is_moving = True

        self.check_collision_with_hostile_forces()

    def move(self):
        # Calculate real position
        if self.movement_vector:
            self.real_x_position += float(self.movement_vector.x * self.speed)
            self.real_y_position += float(self.movement_vector.y * self.speed)

        # Cast real position to integer
        self.hit_box.x = int(self.real_x_position)
        self.hit_box.y = int(self.real_y_position)

        # Adjust offset
        # This is necessary for offsets that are not TILE_SIZE dividers
        x_remainder = self.rect.right % Settings.TILE_SIZE
        y_remainder = self.rect.bottom % Settings.TILE_SIZE

        if x_remainder < self.speed:
            # TODO: Calculate value based on the direction
            self.hit_box.x = self.hit_box.x - x_remainder

        if y_remainder < self.speed:
            # TODO: Calculate value based on the direction
            self.hit_box.y = self.hit_box.y - y_remainder

        # Check collisions with obstacles and moving obstacles
        if self.check_collision_with_all_obstacles():
            # Adjust position after collision
            self.real_x_position = float(self.hit_box.x)
            self.real_y_position = float(self.hit_box.y)
            # Remove path
            self.path.clear()
            # Try to find random vector
            self.try_to_set_random_movement_vector()

        # Recognize the moment when monster moves to a new area
        # In this case TILE_SIZE is a divisor of "right" or "bottom"
        if self.rect.right % Settings.TILE_SIZE == 0:
            self.new_position_on_map[0] = (self.rect.right // Settings.TILE_SIZE) - 1

        if self.rect.bottom % Settings.TILE_SIZE == 0:
            self.new_position_on_map[1] = (self.rect.bottom // Settings.TILE_SIZE) - 1

        # If position was changed, change position and determine new direction
        if self.current_position_on_map != self.new_position_on_map:
            # Adjust real position
            self.real_x_position = self.hit_box.x
            self.real_y_position = self.hit_box.y

            # Change current position (x or y or both)
            if self.current_position_on_map[0] != self.new_position_on_map[0]:
                self.current_position_on_map[0] = self.new_position_on_map[0]
            if self.current_position_on_map[1] != self.new_position_on_map[1]:
                self.current_position_on_map[1] = self.new_position_on_map[1]

            # Find out if the next move is possible
            if not self.try_to_set_movement_vector_from_path():
                self.is_moving = False

        # Increase costume step counter
        self.costume_step_counter += 1

    def check_collision_with_all_obstacles(self):
        # Note, that for this case monster collision with the obstacle is checked based on the obstacle
        # rectangle, not a hitbox. The reason is to avoid monster to be over the obstacle.
        is_collision_detected = False
        monster_hitbox = self.hit_box

        # Obstacle
        for sprite in self.obstacle_sprites:
            if sprite.rect.colliderect(monster_hitbox):
                if self.movement_vector.x > 0:
                    self.hit_box.right = sprite.rect.left
                    is_collision_detected = True
                    break
                elif self.movement_vector.x < 0:
                    self.hit_box.left = sprite.rect.right
                    is_collision_detected = True
                    break
                elif self.movement_vector.y > 0:
                    self.hit_box.bottom = sprite.rect.top
                    is_collision_detected = True
                    break
                elif self.movement_vector.y < 0:
                    self.hit_box.top = sprite.rect.bottom
                    is_collision_detected = True
                    break

        if not is_collision_detected:
            # Moving obstacle
            for sprite in self.moving_obstacle_sprites:
                if sprite.rect.colliderect(monster_hitbox):
                    if self.movement_vector.x > 0:
                        self.hit_box.right = sprite.rect.left
                        is_collision_detected = True
                        break
                    elif self.movement_vector.x < 0:
                        self.hit_box.left = sprite.rect.right
                        is_collision_detected = True
                        break
                    elif self.movement_vector.y > 0:
                        self.hit_box.bottom = sprite.rect.top
                        is_collision_detected = True
                        break
                    elif self.movement_vector.y < 0:
                        self.hit_box.top = sprite.rect.bottom
                        is_collision_detected = True
                        break

        return is_collision_detected

    def check_collision_with_hostile_forces(self):
        for sprite in self.hostile_force_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if pygame.sprite.spritecollide(self, pygame.sprite.GroupSingle(sprite), False,
                                               pygame.sprite.collide_mask):
                    self.sound_manager.play_sfx(SoundEffect.DECREASE_ENEMY_ENERGY_USING_SWORD)
                    self.decrease_energy(sprite.get_damage_power())

    def try_to_set_movement_vector_from_path(self):
        movement_vector = None

        if self.is_player_in_range():
            for index, item in enumerate(self.path):
                if item == tuple(self.current_position_on_map) and index + 1 < len(self.path):
                    next_position_on_map = self.path[index + 1]
                    movement_vector = pygame.math.Vector2(
                        next_position_on_map[0] - self.current_position_on_map[0],
                        next_position_on_map[1] - self.current_position_on_map[1])
                    break

        self.movement_vector = movement_vector
        return self.movement_vector is not None

    def try_to_set_random_movement_vector(self):
        movement_vector = None

        # Find the first empty tile nearby the monster
        possible_vectors = [
            pygame.math.Vector2(-1, 0),
            pygame.math.Vector2(1, 0),
            pygame.math.Vector2(0, -1),
            pygame.math.Vector2(0, 1),
        ]

        possible_vectors_length = len(possible_vectors)

        while possible_vectors_length > 0:
            random_value = random.randint(0, possible_vectors_length-1)
            verified_tile = (
                int(self.current_position_on_map[0] + possible_vectors[random_value][0]),
                int(self.current_position_on_map[1] + possible_vectors[random_value][1])
            )

            if verified_tile in self.obstacles:
                # Chose another tile
                possible_vectors.remove(possible_vectors[random_value])
                possible_vectors_length -= 1
            else:
                # The vector has been found and the tile is empty
                movement_vector = possible_vectors[random_value]
                break

        self.movement_vector = movement_vector
        return self.movement_vector is not None

    def refresh_obstacle_map(self):
        # The obstacle map has changed - regenerate lists and calculate a new path
        self.all_tiles = set()
        self.obstacles = set()
        self.create_all_tiles_and_obstacles_lists()
        if self.is_player_in_range() and self.verify_attack_readiness():
            self.calculate_path_to_player()

    def set_player_tile_position(self):
        # Player has changed position - calculate a new path
        if self.is_player_in_range() and self.verify_attack_readiness():
            self.calculate_path_to_player()

    def get_possible_obstacles(self, start_position, end_position):
        possible_obstacles = list()

        if start_position[0] < end_position[0]:
            dx = 1
        elif start_position[0] > end_position[0]:
            dx = -1
        else:
            dx = 1

        if start_position[1] < end_position[1]:
            dy = 1
        elif start_position[1] > end_position[1]:
            dy = -1
        else:
            dy = 1

        for item in self.obstacles:
            if (start_position[0] * dx - item[0] * dx <= 0 and end_position[0] * dx - item[0] * dx >= 0
                    and start_position[1] * dy - item[1] * dy <= 0 and end_position[1] * dy - item[1] * dy >= 0):
                possible_obstacles.append(item)

        return possible_obstacles

    def verify_attack_readiness(self):
        if self.attack_only_when_visible:
            return self.check_line_of_fire()
        else:
            # If visibility is not important, the attack can be performed at any time
            return True

    def check_line_of_fire(self):
        start_position = self.current_position_on_map[0], self.current_position_on_map[1]
        end_position = self.game_manager.player_tile_position

        possible_obstacles = self.get_possible_obstacles(start_position, end_position)

        start_vector = pygame.Vector2(GameHelper.get_tile_center_position(start_position))
        end_vector = pygame.Vector2(GameHelper.get_tile_center_position(end_position))

        for obstacle in possible_obstacles:
            rect = pygame.Rect(obstacle[0] * Settings.TILE_SIZE, obstacle[1] * Settings.TILE_SIZE, Settings.TILE_SIZE, Settings.TILE_SIZE)
            intersection = GeometryHelper.check_intersection_of_segment_with_rectangle(start_vector, end_vector, rect)
            if intersection:
                return False

        return True

    def calculate_path_to_player(self):
        start_position = tuple(self.current_position_on_map)
        end_position = self.game_manager.player_tile_position

        # Get path
        self.path = self.search_path.search(self.all_tiles, start_position, end_position, self.obstacle_map,
                                             self.range)

        if self.search_path.is_end_reached:
            # Reverse the path (direction: from monster to player)
            self.path.reverse()
            # Add player position to the end of the path
            self.path.append(self.game_manager.player_tile_position)

    def decrease_energy(self, energy_decrease_step):
        self.collided_with_weapon = True
        self.is_resting = True
        self.is_moving = False

        if self.energy > 0:
            self.energy -= energy_decrease_step
            if self.energy < 0:
                self.energy = 0

        if self.energy == 0:
            self.kill()

    def custom_draw(self, game_surface, offset):
        # Draw sprite
        offset_position = self.rect.topleft + offset
        game_surface.blit(self.image, offset_position)

        # Draw an outline if it is collided
        if self.collided_with_weapon:
            outline_image = pygame.surface.Surface.copy(self.image)
            mask = pygame.mask.from_surface(self.image)
            mask_outline = mask.outline()
            pygame.draw.polygon(outline_image, (255, 255, 255), mask_outline,
                                int(GameHelper.multiply_by_tile_size_ratio(1, 1)))
            game_surface.blit(outline_image, offset_position)

            # Reset status of collided with weapon
            self.collided_with_weapon = False

    def change_costume(self):
        if self.is_resting:
            self.image = self.sprite_image_in_damage_state

        # Change costume only if threshold exceeded
        if self.costume_step_counter > self.sprites[self.costume_index].number_of_frames:

            # Reset counter and increase costume index
            self.costume_step_counter = 0
            self.costume_index += 1

            # If it's the last costume
            if self.costume_index >= self.number_of_sprites:
                # Start from the first costume (index = 0)
                self.costume_index = 0
                # Sfx
                if self.path is not None and len(self.path) > 0:
                    self.sound_manager.play_sfx(SoundEffect.MOVE_ENEMY)

            # Set new image
            self.image = self.sprites[self.costume_index].image

    def is_player_in_range(self):
        monster_tile_position = tuple(self.current_position_on_map)
        player_tile_position = self.game_manager.player_tile_position

        distance = abs(monster_tile_position[0] - player_tile_position[0]), abs(
            monster_tile_position[1] - player_tile_position[1])

        return distance[0] < self.range and distance[1] < self.range

    def kill(self):
        self.sound_manager.play_sfx(SoundEffect.KILL_ENEMY)
        super().kill()
        self.game_manager.award_enemy_kill(self.enemy_type, self.score)
        pygame.event.post(pygame.event.Event(Events.ADD_TOMBSTONE_EVENT, {"position": self.rect.topleft}))

    def get_damage_power(self):
        return self.damage_power
