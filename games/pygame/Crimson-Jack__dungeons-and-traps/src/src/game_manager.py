from collections.abc import Callable

import pygame


from src.events import Events
from src.enemy_kill_record import EnemyKillRecord
from src.enums.direction import Direction
from src.enums.enemy_type import EnemyType
from src.enums.game_status import GameStatus
from src.bonus_record import BonusRecord
from src.collectable_record import CollectableRecord
from src.level_stats import LevelStats
from src.enums.sound_effect import SoundEffect
from src.level_catalog import LEVELS
from src.level_details import LevelDetails
from src.enums.lighting_status import LightingStatus
from src.enums.weapon_type import WeaponType
from src.sound_manager import SoundManager
from src.sprites.diamond import Diamond
from src.sprites.key import Key


class GameManager:
    """Shared game state: game status, level progress, player, weapons, collected items, boss and level statistics.
    Posts custom events when the state changes."""

    def __init__(self) -> None:
        self._game_status = GameStatus.FIRST_PAGE
        self._lighting_status = LightingStatus.LIGHT_ON

        self._level_index = 0
        self._lives = 2
        self._score = 0

        self._weapon_type = WeaponType.NONE
        self._collected_weapons = [self._weapon_type]
        self._number_of_arrows = 0
        self._sword_max_energy = 100
        self._number_of_explosions = 0
        self._number_of_sword_thresholds = 5
        self._sword_energy = self._sword_max_energy

        self._diamonds = list()
        self._collected_diamonds = list()
        self._keys = list()
        self._collected_keys = list()

        self._player_max_energy = 800
        self._player_energy = self._player_max_energy
        self._player_tile_position = (0, 0)
        self._player_movement_vector = pygame.Vector2()
        self._player_movement_direction = Direction.RIGHT
        self._player_is_using_weapon = False

        self._is_boss_visible = False
        self._boss_max_energy = 0
        self._boss_energy = self._boss_max_energy

        self._check_point_position = None

        # Level stats — one entry per level, persists until game over
        self._level_stats: list[LevelStats] = [LevelStats()]

        # Sound
        self._sound_manager = SoundManager()

    @property
    def game_status(self) -> GameStatus:
        """Current game status: the screen or game phase that is active."""
        return self._game_status

    @property
    def lighting_status(self) -> LightingStatus:
        """Current lighting of the level; changed only by a lighting spell."""
        return self._lighting_status

    @property
    def level_index(self) -> int:
        """Index of the current level in the level catalog."""
        return self._level_index

    @property
    def lives(self) -> int:
        """Number of lives left."""
        return self._lives

    @property
    def score(self) -> int:
        """Current score of the player."""
        return self._score

    @property
    def weapon_type(self) -> WeaponType:
        """Weapon currently selected by the player."""
        return self._weapon_type

    @property
    def collected_weapons(self) -> list[WeaponType]:
        """Weapons collected by the player; NONE when no weapon is collected."""
        return self._collected_weapons

    @property
    def number_of_arrows(self) -> int:
        """Number of arrows left for the bow."""
        return self._number_of_arrows

    @property
    def number_of_explosions(self) -> int:
        """Number of explosions left."""
        return self._number_of_explosions

    @property
    def diamonds(self) -> list[Diamond]:
        """Diamonds placed on the current level."""
        return self._diamonds

    @property
    def keys(self) -> list[Key]:
        """Keys placed on the current level."""
        return self._keys

    @property
    def player_max_energy(self) -> int:
        """Maximum energy of the player."""
        return self._player_max_energy

    @property
    def player_energy(self) -> float:
        """Current energy of the player."""
        return self._player_energy

    @property
    def player_tile_position(self) -> tuple[int, int]:
        """Tile position of the player on the map."""
        return self._player_tile_position

    @property
    def player_movement_vector(self) -> pygame.Vector2:
        """Sum of the movement steps of the pressed movement keys."""
        return self._player_movement_vector

    @property
    def player_movement_direction(self) -> Direction:
        """Direction the player is facing."""
        return self._player_movement_direction

    @property
    def player_is_using_weapon(self) -> bool:
        """Whether the player is using the selected weapon."""
        return self._player_is_using_weapon

    @property
    def is_boss_visible(self) -> bool:
        """Whether the boss is shown on the current level."""
        return self._is_boss_visible

    @property
    def boss_max_energy(self) -> int:
        """Maximum energy of the boss."""
        return self._boss_max_energy

    @property
    def boss_energy(self) -> int:
        """Current energy of the boss."""
        return self._boss_energy

    @property
    def check_point_position(self) -> tuple[int, int] | None:
        """Position of the last collected check point; None before any is collected."""
        return self._check_point_position

    @property
    def current_level_stats(self) -> LevelStats:
        """Statistics of the current level."""
        return self._level_stats[-1]

    @property
    def current_level_details(self) -> LevelDetails:
        """Details of the level currently being played."""
        return LEVELS[self._level_index]

    @property
    def number_of_used_sword_thresholds(self) -> int:
        """Number of used sword thresholds, from 0 (full energy) to (number_of_sword_thresholds - 1)."""
        threshold = self._sword_max_energy // self._number_of_sword_thresholds
        return (self._sword_max_energy - self._sword_energy) // threshold

    def clear_settings_for_first_level(self, level_index: int = 0) -> None:
        """
        Reset the whole game progress and prepare the given level as the first one of a new game.

        :param level_index: index of the level in the level catalog to start from
        """
        self._lighting_status = LightingStatus.LIGHT_ON

        self._level_index = level_index
        self._lives = 2
        self._score = 0

        self._weapon_type = WeaponType.NONE
        self._collected_weapons = [self._weapon_type]
        self._number_of_arrows = 0
        self._number_of_explosions = 0
        self._sword_energy = self._sword_max_energy

        self._diamonds.clear()
        self._collected_diamonds.clear()
        self._keys.clear()
        self._collected_keys.clear()

        self._restore_player_energy()
        self._reset_player_direction()

        self._is_boss_visible = False

        self._check_point_position = None

        self._level_stats = [LevelStats()]

    def clear_settings_for_next_level(self) -> None:
        """Move to the next level, keeping lives, score, weapons, player energy and lighting."""
        self._level_index += 1

        self._diamonds.clear()
        self._collected_diamonds.clear()
        self._keys.clear()
        self._collected_keys.clear()

        self._reset_player_direction()

        self._is_boss_visible = False

        self._check_point_position = None

        self._level_stats.append(LevelStats())

    def clear_settings_for_current_level(self) -> None:
        """
        Prepare the current level to be played again: restore the light and the player energy
        and reset the level statistics.
        """
        self._lighting_status = LightingStatus.LIGHT_ON

        self._diamonds.clear()
        self._collected_diamonds.clear()
        self._keys.clear()
        self._collected_keys.clear()

        self._restore_player_energy()
        self._reset_player_direction()

        self._is_boss_visible = False

        self._check_point_position = None

        self.current_level_stats.reset()

    def set_studio_page(self) -> None:
        """Set the game status to STUDIO_PAGE."""
        self._game_status = GameStatus.STUDIO_PAGE

    def set_loading_page(self) -> None:
        """Set the game status to LOADING_PAGE."""
        self._game_status = GameStatus.LOADING_PAGE

    def set_first_page(self) -> None:
        """Set the game status to FIRST_PAGE."""
        self._game_status = GameStatus.FIRST_PAGE

    def set_secret_code(self) -> None:
        """Set the game status to SECRET_CODE."""
        self._game_status = GameStatus.SECRET_CODE

    def set_credits(self) -> None:
        """Set the game status to CREDITS."""
        self._game_status = GameStatus.CREDITS

    def set_secret_code_is_valid(self) -> None:
        """Set the game status to SECRET_CODE_IS_VALID."""
        self._game_status = GameStatus.SECRET_CODE_IS_VALID

    def set_next_level(self) -> None:
        """Set the game status to NEXT_LEVEL."""
        self._game_status = GameStatus.NEXT_LEVEL

    def set_game_is_running(self) -> None:
        """Set the game status to GAME_IS_RUNNING."""
        self._game_status = GameStatus.GAME_IS_RUNNING

    def set_level_completed(self) -> None:
        """Set the game status to LEVEL_COMPLETED."""
        self._game_status = GameStatus.LEVEL_COMPLETED

    def set_game_over(self) -> None:
        """Set the game status to GAME_OVER."""
        self._game_status = GameStatus.GAME_OVER

    def set_you_win(self) -> None:
        """Set the game status to YOU_WIN."""
        self._game_status = GameStatus.YOU_WIN

    def set_summary(self) -> None:
        """Set the game status to SUMMARY."""
        self._game_status = GameStatus.SUMMARY

    def get_aggregate_collectable_stats(self) -> tuple[CollectableRecord, CollectableRecord, BonusRecord]:
        """
        Sum the diamond, key and bonus records of all played levels.

        :return: diamond totals, key totals and bonus totals
        """
        diamond_totals = CollectableRecord()
        key_totals = CollectableRecord()
        bonus_totals = BonusRecord()
        for stats in self._level_stats:
            diamond_totals.add(stats.get_diamond_record())
            key_totals.add(stats.get_key_record())
            bonus_totals.add(stats.get_bonus_record())
        return diamond_totals, key_totals, bonus_totals

    def get_aggregate_kill_stats(self) -> dict[EnemyType, EnemyKillRecord]:
        """
        Sum the enemy kill records of all played levels.

        :return: totals for every enemy type
        """
        totals = {enemy_type: EnemyKillRecord() for enemy_type in EnemyType}
        for stats in self._level_stats:
            for enemy_type in EnemyType:
                totals[enemy_type].add(stats.get_enemy_record(enemy_type))
        return totals

    def switch_pause_state(self) -> None:
        """Pause the running game, or resume the paused one."""
        if self._game_status == GameStatus.GAME_IS_PAUSED:
            self._game_status = GameStatus.GAME_IS_RUNNING
        else:
            self._game_status = GameStatus.GAME_IS_PAUSED

    def load_next_level(self) -> None:
        """Post YOU_WIN_EVENT after the last level of the campaign, otherwise NEXT_LEVEL_EVENT."""
        if self.current_level_details.is_final_level or self._level_index == len(LEVELS) - 1:
            pygame.event.post(pygame.event.Event(Events.YOU_WIN_EVENT))
        else:
            pygame.event.post(pygame.event.Event(Events.NEXT_LEVEL_EVENT))

    def decrease_number_of_lives(self) -> None:
        """Take one life without posting any event; used when the level is restarted from the pause menu."""
        self._lives -= 1

    def increase_score(self, value: int) -> None:
        """
        Add points to the score and post CHANGE_SCORE_EVENT.

        :param value: number of points
        """
        self._score += value
        pygame.event.post(pygame.event.Event(Events.CHANGE_SCORE_EVENT))

    def collect_sword_powerup(self) -> None:
        """Add the sword with full energy and select it."""
        self._add_weapon(WeaponType.SWORD)
        self._sword_energy = self._sword_max_energy
        self._remove_weapon(WeaponType.NONE)
        self._weapon_type = WeaponType.SWORD
        pygame.event.post(pygame.event.Event(Events.CHANGE_WEAPON_EVENT))

    def collect_bow_powerup(self, number_of_arrows: int) -> None:
        """
        Add the bow with more arrows and select it.

        :param number_of_arrows: arrows added to the ones left
        """
        self._add_weapon(WeaponType.BOW)
        self._number_of_arrows += number_of_arrows
        self._remove_weapon(WeaponType.NONE)
        self._weapon_type = WeaponType.BOW
        pygame.event.post(pygame.event.Event(Events.CHANGE_WEAPON_EVENT))

    def collect_explosion_powerup(self, number_of_explosions: int) -> None:
        """
        Add the explosion weapon with more explosions and select it.

        :param number_of_explosions: explosions added to the ones left
        """
        self._add_weapon(WeaponType.EXPLOSION)
        self._number_of_explosions += number_of_explosions
        self._remove_weapon(WeaponType.NONE)
        self._weapon_type = WeaponType.EXPLOSION
        pygame.event.post(pygame.event.Event(Events.CHANGE_WEAPON_EVENT))

    def set_next_weapon(self) -> None:
        """Select the next collected weapon; play a sound when the weapon changes."""
        self._switch_weapon(WeaponType.next)

    def set_previous_weapon(self) -> None:
        """Select the previous collected weapon; play a sound when the weapon changes."""
        self._switch_weapon(WeaponType.previous)

    def decrease_sword_energy(self) -> None:
        """Use one point of the sword energy; a depleted sword is removed and the next weapon is selected."""
        if self._sword_energy > 0:
            self._sword_energy -= 1
        self._update_weapon_after_use(WeaponType.SWORD, self._sword_energy)

    def decrease_number_of_arrows(self) -> None:
        """Use one arrow; a bow without arrows is removed and the next weapon is selected."""
        if self._number_of_arrows > 0:
            self._number_of_arrows -= 1
        self._update_weapon_after_use(WeaponType.BOW, self._number_of_arrows)

    def decrease_number_of_explosions(self) -> None:
        """Use one explosion; when none are left, the explosion weapon is removed and the next weapon is selected."""
        if self._number_of_explosions > 0:
            self._number_of_explosions -= 1
        self._update_weapon_after_use(WeaponType.EXPLOSION, self._number_of_explosions)

    def add_diamond(self, diamond: Diamond) -> None:
        """
        Register a diamond placed on the current level.

        :param diamond: placed diamond
        """
        self._diamonds.append(diamond)
        self.current_level_stats.record_diamond_placed()

    def collect_diamond(self, diamond: Diamond) -> None:
        """
        Collect a diamond and add its score.
        The last diamond opens the exit point or, on a level without one, removes the obstacles and creates the boss.

        :param diamond: collected diamond
        """
        self._collected_diamonds.append(diamond)
        self._score += diamond.score
        self.current_level_stats.record_diamond_collected(diamond.score)
        pygame.event.post(pygame.event.Event(Events.COLLECT_DIAMOND_EVENT))
        if len(self._collected_diamonds) == len(self._diamonds):
            if self.current_level_details.exit_point_enabled:
                pygame.event.post(pygame.event.Event(Events.EXIT_POINT_IS_OPEN_EVENT))
            else:
                pygame.event.post(pygame.event.Event(Events.REMOVE_OBSTACLES_EVENT))
                pygame.event.post(pygame.event.Event(Events.CREATE_BOSS_OCTOPUS_EVENT))

    def add_key(self, key: Key) -> None:
        """
        Register a key placed on the current level.

        :param key: placed key
        """
        self._keys.append(key)
        self.current_level_stats.record_key_placed()

    def collect_key(self, key: Key) -> None:
        """
        Collect a key and add its score.

        :param key: collected key
        """
        self._collected_keys.append(key)
        self._score += key.score
        self.current_level_stats.record_key_collected(key.score)
        pygame.event.post(pygame.event.Event(Events.COLLECT_KEY_EVENT))

    def award_completion_bonus(self, score: int) -> None:
        """
        Add the bonus for defeating all enemies of the level and record it.

        :param score: bonus points
        """
        self.increase_score(score)
        self.current_level_stats.record_bonus_awarded(score)

    def award_enemy_kill(self, enemy_type: EnemyType, score: int) -> None:
        """
        Add the score for a killed enemy and record the kill on the current level.

        :param enemy_type: type of the killed enemy
        :param score: score for the killed enemy
        """
        self.increase_score(score)
        self.current_level_stats.record_enemy_kill(enemy_type, score)

    def record_enemy_spawn(self, enemy_type: EnemyType) -> None:
        """
        Record an enemy that appeared on the current level.

        :param enemy_type: type of the enemy
        """
        self.current_level_stats.record_enemy_spawn(enemy_type)

    def show_boss(self, energy: int) -> None:
        """
        Show the boss with full energy.

        :param energy: maximum and starting energy of the boss
        """
        self._boss_max_energy = energy
        self._boss_energy = energy
        self._is_boss_visible = True

    def set_boss_energy(self, energy: int) -> None:
        """
        Set the current energy of the boss.

        :param energy: current energy of the boss
        """
        self._boss_energy = energy

    def is_key_collected(self, key_name: str) -> bool:
        """
        Check whether a key with the given name is collected.

        :param key_name: name of the key that opens a door
        :return: True when such a key is collected
        """
        return any(key.key_name == key_name for key in self._collected_keys)

    def collect_life_powerup(self) -> None:
        """Add one life and post COLLECT_LIFE_EVENT."""
        self._lives += 1
        pygame.event.post(pygame.event.Event(Events.COLLECT_LIFE_EVENT))

    def decrease_player_energy(self, damage_power: int = 1) -> None:
        """
        Take energy from the player; when it runs out, the player loses a life.

        :param damage_power: energy taken
        """
        if self._player_energy > 0:
            self._player_energy -= damage_power
            if self._player_energy <= 0:
                self._lose_life()
            else:
                pygame.event.post(pygame.event.Event(Events.CHANGE_ENERGY_EVENT))

    def increase_player_energy(self, volume: int, is_percentage: bool = True) -> None:
        """
        Give energy to the player, up to the maximum.

        :param volume: energy added, or percent of the maximum energy
        :param is_percentage: whether volume is a percentage of the maximum energy
        """
        if is_percentage:
            self._player_energy += volume * self._player_max_energy / 100
        else:
            self._player_energy += volume
        if self._player_energy > self._player_max_energy:
            self._player_energy = self._player_max_energy
        pygame.event.post(pygame.event.Event(Events.CHANGE_ENERGY_EVENT))

    def set_player_movement(self, delta_x: int, delta_y: int) -> None:
        """
        Add the movement step of a pressed or released movement key and update the direction the player faces.

        :param delta_x: horizontal step
        :param delta_y: vertical step
        """
        self._player_movement_vector.x += delta_x
        self._player_movement_vector.y += delta_y

        # A stopped player keeps facing the last direction
        if self._player_movement_vector != (0, 0):
            self._player_movement_direction = Direction.from_vector(self._player_movement_vector)

    def reset_player_movement(self) -> None:
        """Stop the player."""
        self._player_movement_vector.x = 0
        self._player_movement_vector.y = 0

    def set_player_is_using_weapon(self, status: bool) -> None:
        """
        Set whether the player is using the selected weapon.

        :param status: True when the player is using the weapon
        """
        self._player_is_using_weapon = status

    def set_player_tile_position(self, position: tuple[int, int]) -> None:
        """
        Store the tile position of the player on the map.

        :param position: tile position of the player
        """
        self._player_tile_position = position

    def collect_check_point(self, position: tuple[int, int]) -> None:
        """
        Store the check point where the player respawns after losing a life.

        :param position: position of the check point
        """
        self._check_point_position = position

    def set_lighting_spell(self, lighting_status: LightingStatus) -> None:
        """
        Change the lighting of the level to the one of a collected lighting spell.

        :param lighting_status: lighting of the spell
        """
        self._lighting_status = lighting_status

    @staticmethod
    def validate_secret_code(code: str) -> int | None:
        """
        Find the level with the given secret code.

        :param code: typed secret code
        :return: index of the level in the level catalog, or None when no level has this code
        """
        for level_index, level_details in enumerate(LEVELS):
            if level_details.secret_code == code:
                return level_index
        return None

    def _update_weapon_after_use(self, weapon_type: WeaponType, remaining_amount: int) -> None:
        # A depleted weapon is removed and the next collected weapon is selected
        if remaining_amount <= 0:
            self._remove_weapon(weapon_type)
            if len(self._collected_weapons) == 0:
                self._add_weapon(WeaponType.NONE)
            self.set_next_weapon()
        else:
            pygame.event.post(pygame.event.Event(Events.CHANGE_WEAPON_CAPACITY_EVENT))

    def _switch_weapon(self, get_next_or_previous: Callable[[WeaponType], WeaponType]) -> None:
        # Step through the weapon types until a collected one is found; play a sound only when the weapon changes
        current_weapon_type = self._weapon_type
        self._weapon_type = get_next_or_previous(self._weapon_type)
        while self._weapon_type not in self._collected_weapons:
            self._weapon_type = get_next_or_previous(self._weapon_type)
        if current_weapon_type != self._weapon_type:
            self._sound_manager.play_sfx(SoundEffect.CHANGE_WEAPON)
            pygame.event.post(pygame.event.Event(Events.CHANGE_WEAPON_EVENT))

    def _lose_life(self) -> None:
        # Take a life; with lives left the player gets full energy back, otherwise the game is over
        self._lives -= 1
        if self._lives > 0:
            self._restore_player_energy()
            self._reset_player_direction()
            pygame.event.post(pygame.event.Event(Events.PLAYER_LOST_LIFE_EVENT))
        else:
            pygame.event.post(pygame.event.Event(Events.GAME_OVER_EVENT))

    def _add_weapon(self, weapon: WeaponType) -> None:
        # Each weapon type is collected at most once
        if weapon not in self._collected_weapons:
            self._collected_weapons.append(weapon)

    def _remove_weapon(self, weapon: WeaponType) -> None:
        # Only a collected weapon is removed
        if weapon in self._collected_weapons:
            self._collected_weapons.remove(weapon)

    def _restore_player_energy(self) -> None:
        # Fill the player energy up to the maximum
        self._player_energy = self._player_max_energy

    def _reset_player_direction(self) -> None:
        # The player faces right at the start of a level and after losing a life
        self._player_movement_direction = Direction.RIGHT
