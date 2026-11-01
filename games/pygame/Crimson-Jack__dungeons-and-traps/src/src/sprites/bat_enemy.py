import random

import pygame

from settings import Settings
from src.events import Events
from src.abstract_classes.damageable_enemy import DamageableEnemy
from src.abstract_classes.obstacle_map_observer import ObstacleMapObserver
from src.enums.enemy_type import EnemyType
from src.enums.sound_effect import SoundEffect
from src.game_helper import GameHelper
from src.search_path_algorithms.breadth_first_search import BreadthFirstSearch
from src.sound_manager import SoundManager
from src.sprite_costume import SpriteCostume
from src.sprites.custom_draw_sprite import CustomDrawSprite
from src.tile_details.bat_tile_details import BatTileDetails


class BatEnemy(CustomDrawSprite, DamageableEnemy, ObstacleMapObserver):
    def __init__(self, sprites: list[SpriteCostume], sprite_image_in_damage_state: pygame.Surface, position, groups,
                 game_manager, enemy_type: EnemyType, details: BatTileDetails, obstacle_map, moving_obstacle_sprites,
                 hostile_force_sprites):
        super().__init__(groups)

        # Sound
        self.sound_manager = SoundManager()

        # Base
        self.game_manager = game_manager
        self.enemy_type = enemy_type
        self.damage_power = details.damage_power
        self.score = details.score

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

        # Track variables
        self.track = list()
        self.create_track(self.current_position_on_map, details.points_path)
        self.track_position = self.get_next_track_position()

        # Path variables
        self.all_tiles = set()
        self.obstacles = set()
        self.create_all_tiles_and_obstacles_lists()
        self.breadth_first_search = BreadthFirstSearch()
        self.path = []

        # Real position is required to store the real distance, which is then cast to integer
        self.real_x_position = float(self.hit_box.x)
        self.real_y_position = float(self.hit_box.y)

        # Moving obstacles
        self.moving_obstacle_sprites = moving_obstacle_sprites

        # Hostile forces
        self.hostile_force_sprites = hostile_force_sprites

        # State variables
        self.collided_with_weapon = False
        self.is_resting = False

    def create_track(self, starting_point, points_path):
        # Create relative track from points
        relative_track = list()
        # Add points in one direction
        for point in points_path:
            relative_track.append(point)
        # Add points in the opposite direction (reverse)
        for value in reversed(points_path):
            relative_track.append((-value[0], -value[1]))

        # Convert path from relative to absolute
        self.track.append((starting_point[0], starting_point[1]))
        for point in relative_track:
            self.track.append((self.track[-1][0] + point[0], self.track[-1][1] + point[1]))

    def create_all_tiles_and_obstacles_lists(self):
        for x in range(len(self.obstacle_map.items)):
            for y in range(len(self.obstacle_map.items[x])):
                if self.obstacle_map.items[x][y] > 0:
                    self.obstacles.add((y, x))
                else:
                    self.all_tiles.add((y, x))

    def update(self):
        if self.number_of_sprites > 1:
            self.change_costume()

        if self.is_moving:
            self.move()
        else:
            if not self.is_resting:
                self.set_next_move()
            else:
                self.start_delay_counter -= 1
                if self.start_delay_counter < 0:
                    self.is_resting = False
                    self.start_delay_counter = self.start_delay
                    self.set_next_move()

        self.check_collision_with_hostile_forces()

    def set_next_move(self):
        if self.check_can_move():
            if self.check_if_all_track_positions_are_blocked():
                if self.try_to_set_random_movement_vector():
                    self.is_moving = True
                    self.path.clear()
            else:
                self.calculate_path()
                if self.try_to_set_movement_vector_from_path():
                    self.is_moving = True

                if not self.is_moving:
                    self.track_position = self.get_next_track_position()
                    self.calculate_path()
                    if self.try_to_set_movement_vector_from_path():
                        self.is_moving = True

    def check_can_move(self):
        # If all neighbours are obstacles - stop the movement
        tile_top = self.obstacle_map.items[self.current_position_on_map[1] - 1][self.current_position_on_map[0]]
        tile_bottom = self.obstacle_map.items[self.current_position_on_map[1] + 1][self.current_position_on_map[0]]
        tile_left = self.obstacle_map.items[self.current_position_on_map[1]][self.current_position_on_map[0] - 1]
        tile_right = self.obstacle_map.items[self.current_position_on_map[1]][self.current_position_on_map[0] + 1]
        if tile_top and tile_bottom and tile_left and tile_right:
            return False
        else:
            return True

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

        if self.check_collision_with_moving_obstacles():
            # Collision with moving obstacle sprites was detected
            # Monster must be moved to the last valid position (using current map position)
            self.hit_box.x = self.current_position_on_map[0] * Settings.TILE_SIZE
            self.hit_box.y = self.current_position_on_map[1] * Settings.TILE_SIZE

            # Adjust real position after collision
            self.real_x_position = float(self.hit_box.x)
            self.real_y_position = float(self.hit_box.y)

            # Stop moving and early return
            self.is_moving = False
        else:
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

    def check_collision_with_moving_obstacles(self):
        is_collision_detected = False

        for sprite in self.moving_obstacle_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                is_collision_detected = True
                break

        return is_collision_detected

    def check_collision_with_hostile_forces(self):
        for sprite in self.hostile_force_sprites:
            if sprite.hit_box.colliderect(self.hit_box):
                if pygame.sprite.spritecollide(self, pygame.sprite.GroupSingle(sprite), False,
                                               pygame.sprite.collide_mask):
                    self.decrease_energy(sprite.get_damage_power())

    def try_to_set_movement_vector_from_path(self):
        movement_vector = None

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
        self.calculate_path()

    def calculate_path(self):
        start_position = tuple(self.current_position_on_map)
        end_position = self.track_position

        # Get path
        self.path = self.breadth_first_search.search(self.all_tiles, start_position, end_position,
                                                       obstacle_map=self.obstacle_map, max_distance=self.range)

        if self.breadth_first_search.is_end_reached:
            # Reverse the path (direction: from monster to player)
            self.path.reverse()
            # Add player position to the end of the path
            self.path.append(self.track_position)

    def get_next_track_position(self):
        self.track.append(self.track[0])
        self.track.remove(self.track[0])

        return self.track[0]

    def check_if_all_track_positions_are_blocked(self):
        # Assumption - all route points are blocked
        all_blocked = True

        # Remove current position on the map form the track and convert list to set (to remove duplicates)
        track_without_current_position = set(filter(lambda point: point != tuple(self.current_position_on_map),
                                                    self.track))

        for item in track_without_current_position:
            # Check whether the track point is located at the location of the obstacle
            if item not in self.obstacles:
                start_position = tuple(self.current_position_on_map)
                end_position = item
                # Check whether the track point is reachable
                self.breadth_first_search.search(self.all_tiles, start_position, end_position,
                                                  obstacle_map=self.obstacle_map, max_distance=self.range)
                if self.breadth_first_search.is_end_reached:
                    all_blocked = False
                    break

        return all_blocked

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

            # If it's the last costume - start from the second costume (index = 1)
            if self.costume_index >= self.number_of_sprites:
                self.costume_index = 0

            # Set new image
            self.image = self.sprites[self.costume_index].image

    def kill(self):
        self.sound_manager.play_sfx(SoundEffect.KILL_ENEMY)
        super().kill()
        self.game_manager.award_enemy_kill(self.enemy_type, self.score)
        pygame.event.post(pygame.event.Event(Events.ADD_TOMBSTONE_EVENT, {"position": self.rect.topleft}))

    def get_damage_power(self):
        return self.damage_power
