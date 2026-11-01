import random

import pygame

from settings import Settings
from src.events import Events
from src.abstract_classes.pathfinding_enemy import PathfindingEnemy
from src.abstract_classes.damageable_enemy import DamageableEnemy
from src.abstract_classes.obstacle_map_observer import ObstacleMapObserver
from src.enums.sound_effect import SoundEffect
from src.game_helper import GameHelper
from src.search_path_algorithms.greedy_best_first_search import GreedyBestFirstSearch
from src.sound_manager import SoundManager
from src.sprite_costume import SpriteCostume
from src.sprites.custom_draw_sprite import CustomDrawSprite
from src.sprites.fire_ball_enemy import FireBallEnemy
from src.tile_details.octopus_tile_details import OctopusTileDetails


class OctopusEnemy(CustomDrawSprite, PathfindingEnemy, DamageableEnemy, ObstacleMapObserver):
    def __init__(self, sprites: list[SpriteCostume], sprite_image_in_damage_state: pygame.Surface, position, groups,
                 game_manager, details: OctopusTileDetails, obstacle_map, obstacle_sprites, moving_obstacle_sprites):
        super().__init__(groups)

        # Sound
        self.sound_manager = SoundManager()

        # Base
        self.game_manager = game_manager
        self.damage_power = details.damage_power
        self.score = details.score
        self.is_boss = details.is_boss

        # Energy
        self.max_energy = details.energy
        self.energy = self.max_energy

        # Sprite animation variables
        self.sprites = sprites
        self.number_of_sprites = len(self.sprites)
        self.costume_step_counter = 0
        self.costume_index = 0

        # Sprite in a damage state
        self.sprite_in_damage_state = sprite_image_in_damage_state

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
        self.range = 12

        # Set positions on map
        self.current_position_on_map = [
            (self.rect.right // Settings.TILE_SIZE) - 2,
            (self.rect.bottom // Settings.TILE_SIZE) - 2
        ]
        self.new_position_on_map = list(self.current_position_on_map)

        # Path variables
        self.all_tiles = set()
        self.obstacles = set()
        self.create_all_tiles_and_obstacles_lists()
        self.search_path = GreedyBestFirstSearch()
        self.path = []

        # Real position is required to store the real distance, which is then cast to integer
        self.real_x_position = float(self.hit_box.x)
        self.real_y_position = float(self.hit_box.y)

        # Obstacles and Moving obstacles
        self.obstacle_sprites = obstacle_sprites
        self.moving_obstacle_sprites = moving_obstacle_sprites

        # State variables
        self.collided_with_weapon = False
        self.is_resting = False

        # Fireball
        self.fire_ball_counter = 0
        self.fire_ball_switching_threshold = 120
        self.fire_balls = list()

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

        self.check_fireball()

        if self.is_moving:
            self.move()
        else:
            if self.is_resting:
                self.start_delay_counter -= 1
                if self.start_delay_counter < 0:
                    self.start_delay_counter = self.start_delay
                    self.is_resting = False
            if not self.is_resting:
                if self.is_player_in_range():
                    self.calculate_path_to_player()
                    if self.try_to_set_movement_vector_from_path():
                        self.is_moving = True
                if not self.is_moving:
                    if self.try_to_set_random_movement_vector():
                        self.path.clear()
                        self.is_moving = True

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
            self.new_position_on_map[0] = (self.rect.right // Settings.TILE_SIZE) - 2

        if self.rect.bottom % Settings.TILE_SIZE == 0:
            self.new_position_on_map[1] = (self.rect.bottom // Settings.TILE_SIZE) - 2

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

        # Increase fireball counter
        self.fire_ball_counter += 1

    def check_collision_with_all_obstacles(self):
        # Note, that for this case monster collision with the obstacle is checked based on the obstacle
        # rectangle, not a hitbox. The reason is to avoid monster to be over the obstacle.
        is_collision_detected = False
        octopus_center_hitbox = self.rect.inflate(-Settings.TILE_SIZE * 2, -Settings.TILE_SIZE * 2)

        # Obstacle
        for sprite in self.obstacle_sprites:
            if sprite.rect.colliderect(octopus_center_hitbox):
                if self.movement_vector.x > 0:
                    self.hit_box.right = sprite.rect.left + Settings.TILE_SIZE
                    is_collision_detected = True
                    break
                elif self.movement_vector.x < 0:
                    self.hit_box.left = sprite.rect.right - Settings.TILE_SIZE
                    is_collision_detected = True
                    break
                elif self.movement_vector.y > 0:
                    self.hit_box.bottom = sprite.rect.top + Settings.TILE_SIZE
                    is_collision_detected = True
                    break
                elif self.movement_vector.y < 0:
                    self.hit_box.top = sprite.rect.bottom - Settings.TILE_SIZE
                    is_collision_detected = True
                    break

        if not is_collision_detected:
            # Moving obstacle
            for sprite in self.moving_obstacle_sprites:
                if sprite.rect.colliderect(octopus_center_hitbox):
                    if self.movement_vector.x > 0:
                        self.hit_box.right = sprite.rect.left + Settings.TILE_SIZE
                        is_collision_detected = True
                        break
                    elif self.movement_vector.x < 0:
                        self.hit_box.left = sprite.rect.right - Settings.TILE_SIZE
                        is_collision_detected = True
                        break
                    elif self.movement_vector.y > 0:
                        self.hit_box.bottom = sprite.rect.top + Settings.TILE_SIZE
                        is_collision_detected = True
                        break
                    elif self.movement_vector.y < 0:
                        self.hit_box.top = sprite.rect.bottom - Settings.TILE_SIZE
                        is_collision_detected = True
                        break

        return is_collision_detected

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
        if self.is_player_in_range():
            self.calculate_path_to_player()

    def set_player_tile_position(self):
        # Player has changed position - calculate a new path
        if self.is_player_in_range():
            self.calculate_path_to_player()

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

        self.game_manager.set_boss_energy(self.energy)
        pygame.event.post(pygame.event.Event(Events.CHANGE_ENERGY_EVENT))

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
            self.image = self.sprite_in_damage_state

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

    def is_player_in_range(self):
        monster_tile_position = tuple(self.current_position_on_map)
        player_tile_position = self.game_manager.player_tile_position

        distance = abs(monster_tile_position[0] - player_tile_position[0]), abs(
            monster_tile_position[1] - player_tile_position[1])

        return distance[0] < self.range and distance[1] < self.range

    def kill(self):
        self.sound_manager.play_sfx(SoundEffect.KILL_OCTOPUS)
        super().kill()
        self.game_manager.increase_score(self.score)

        pygame.event.post(pygame.event.Event(Events.ADD_BOSS_TOMBSTONE_EVENT, {"position": self.rect.topleft}))
        pygame.event.post(pygame.event.Event(Events.ADD_BOSS_TOMBSTONE_EVENT, {"position": self.rect.bottomleft}))
        pygame.event.post(pygame.event.Event(Events.ADD_BOSS_TOMBSTONE_EVENT, {"position": self.rect.topright}))
        pygame.event.post(pygame.event.Event(Events.ADD_BOSS_TOMBSTONE_EVENT, {"position": (self.rect.left, self.rect.top - self.rect.height)}))
        pygame.event.post(pygame.event.Event(Events.ADD_BOSS_TOMBSTONE_EVENT, {"position": (self.rect.left - self.rect.width, self.rect.top)}))

        if self.is_boss:
            pygame.event.post(pygame.event.Event(Events.TILT_EFFECT_EVENT, {"tilt_cursor_increment_value": 0.5}))
            pygame.event.post(pygame.event.Event(Events.START_TELEPORT_PLAYER_TO_NEXT_LEVEL_EVENT))

    def get_damage_power(self):
        return self.damage_power

    def check_fireball(self):
        if self.fire_ball_counter > self.fire_ball_switching_threshold:
            self.fire_ball_counter = 0

            if len(self.path) > 0:
                center_rectangle = self.rect.inflate(-Settings.TILE_SIZE * 2, -Settings.TILE_SIZE * 2)
                self.fire_balls.append(
                    FireBallEnemy(center_rectangle.topleft,
                                  tuple(self.groups()),
                                  self.game_manager,
                                  self.obstacle_sprites,
                                  self.moving_obstacle_sprites)
                )
