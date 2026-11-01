from collections import Counter
from unittest.mock import Mock

import pygame
import pytest

from src import level_catalog
from src.enums.enemy_type import EnemyType
from src.enums.lighting_status import LightingStatus
from src.level import Level
from src.sprites.tombstone import Tombstone
from src.tile_details.octopus_tile_details import OctopusTileDetails


def create_level_with_effects(tombstones=None, vanishing_points=None):
    # Full constructor loads a TMX map, which is irrelevant for removing expired effects
    level = object.__new__(Level)
    level._tombstones = tombstones or []
    level._vanishing_points = vanishing_points or []
    level._particle_effect_group = Mock()
    return level


def create_tombstone(group, is_expired):
    last_slide_counter = -1 if is_expired else 10
    return Tombstone([pygame.Surface((1, 1))], (0, 0), (group,), last_slide_counter)


def create_effect(is_expired):
    effect = Mock()
    effect.is_expired.return_value = is_expired
    return effect


@pytest.mark.refactoring
class TestRemoveUnnecessaryEffects:
    def test_removes_adjacent_expired_tombstones_in_one_call(self):
        group = pygame.sprite.Group()
        first_expired_tombstone = create_tombstone(group, is_expired=True)
        second_expired_tombstone = create_tombstone(group, is_expired=True)
        active_tombstone = create_tombstone(group, is_expired=False)
        level = create_level_with_effects(
            tombstones=[first_expired_tombstone, second_expired_tombstone, active_tombstone])

        level._remove_unnecessary_effects()

        assert level._tombstones == [active_tombstone]
        assert group.sprites() == [active_tombstone]

    def test_keeps_active_tombstones_in_order(self):
        group = pygame.sprite.Group()
        first_active_tombstone = create_tombstone(group, is_expired=False)
        expired_tombstone = create_tombstone(group, is_expired=True)
        second_active_tombstone = create_tombstone(group, is_expired=False)
        level = create_level_with_effects(
            tombstones=[first_active_tombstone, expired_tombstone, second_active_tombstone])

        level._remove_unnecessary_effects()

        assert level._tombstones == [first_active_tombstone, second_active_tombstone]

    def test_removes_and_kills_adjacent_expired_vanishing_points(self):
        first_expired_vanishing_point = create_effect(is_expired=True)
        second_expired_vanishing_point = create_effect(is_expired=True)
        active_vanishing_point = create_effect(is_expired=False)
        level = create_level_with_effects(
            vanishing_points=[first_expired_vanishing_point, second_expired_vanishing_point, active_vanishing_point])

        level._remove_unnecessary_effects()

        assert level._vanishing_points == [active_vanishing_point]
        first_expired_vanishing_point.kill.assert_called_once()
        second_expired_vanishing_point.kill.assert_called_once()
        active_vanishing_point.kill.assert_not_called()

    def test_removes_expired_particle_effects(self):
        level = create_level_with_effects()

        level._remove_unnecessary_effects()

        level._particle_effect_group.remove_expired.assert_called_once()


@pytest.mark.refactoring
class TestShowExitPoint:
    def test_missing_exit_point_raises_value_error(self):
        # Full constructor loads a TMX map, which is irrelevant for showing the exit point
        level = object.__new__(Level)
        level._exit_point = None
        level._blast_effect = Mock()

        with pytest.raises(ValueError, match='exit-point'):
            level.show_exit_point()

        level._blast_effect.run.assert_not_called()

    def test_shows_exit_point_with_blast_effect(self):
        level = object.__new__(Level)
        level._exit_point = Mock()
        level._blast_effect = Mock()

        level.show_exit_point()

        level._blast_effect.run.assert_called_once()
        level._exit_point.show.assert_called_once()


@pytest.mark.refactoring
class TestEnableTiltEffect:
    def test_passes_speed_to_tilt_effect(self):
        # Full constructor loads a TMX map, which is irrelevant for enabling the tilt effect
        level = object.__new__(Level)
        level._tilt_effect = Mock()

        level.enable_tilt_effect(0.5)

        level._tilt_effect.enable.assert_called_once_with(0.5)


def count_sprite_classes(group):
    return dict(Counter(type(sprite).__name__ for sprite in group))


# basic.tmx is the only map that contains all sprite layers
@pytest.fixture
def basic_level(game):
    level_filenames = [level_details.source_file for level_details in level_catalog.LEVELS]
    game.game_manager.clear_settings_for_first_level(level_filenames.index('basic.tmx'))
    game.screen_manager.rebuild_level()
    return game.screen_manager.level


@pytest.mark.refactoring
class TestVisibleArea:
    def test_map_larger_than_game_surface_fills_it(self, basic_level):
        assert basic_level._visible_area_screen_position == [0, 80]
        assert basic_level._visible_area_rect == pygame.Rect(0, 0, 1200, 496)

    def test_map_narrower_than_game_surface_is_centered_horizontally(self, game):
        # The game starts on the first level, s01_level_01.tmx, which is 20 tiles wide
        level = game.screen_manager.level
        assert level._visible_area_screen_position == [120, 80]
        assert level._visible_area_rect == pygame.Rect(0, 0, 960, 496)


def find_new_enemy(level, existing_enemies):
    new_enemies = [sprite for sprite in level._level_sprite_groups.enemy_sprites if sprite not in existing_enemies]
    assert len(new_enemies) == 1
    return new_enemies[0]


@pytest.mark.refactoring
class TestCreateSpawnedEnemies:
    def test_monster_has_four_costumes_of_six_frames(self, basic_level):
        existing_enemies = set(basic_level._level_sprite_groups.enemy_sprites)

        basic_level.create_monster((0, 0))

        monster = find_new_enemy(basic_level, existing_enemies)
        assert type(monster).__name__ == 'MonsterEnemy'
        assert [costume.number_of_frames for costume in monster.sprites] == [6] * 4

    def test_boss_octopus_has_sixteen_costumes_of_six_frames(self, basic_level):
        existing_enemies = set(basic_level._level_sprite_groups.enemy_sprites)

        basic_level.create_boss_octopus()

        boss_octopus = find_new_enemy(basic_level, existing_enemies)
        assert type(boss_octopus).__name__ == 'OctopusEnemy'
        assert [costume.number_of_frames for costume in boss_octopus.sprites] == [6] * 16


@pytest.mark.refactoring
class TestDrawDarkness:
    @pytest.fixture
    def lit_level(self, basic_level):
        # One frame sets the camera offset around the player
        basic_level.run()
        return basic_level

    @staticmethod
    def get_player_and_corner_points(level):
        offset = level._camera.offset
        player_point = (int(level._visible_area_screen_position[0] + level._player.rect.centerx + offset.x),
                        int(level._visible_area_screen_position[1] + level._player.rect.centery + offset.y))
        corner_point = (level._visible_area_screen_position[0] + 2, level._visible_area_screen_position[1] + 2)
        return player_point, corner_point

    @pytest.mark.parametrize('lighting_status, player_color, corner_color', [
        (LightingStatus.LIGHT_ON, (255, 255, 255), (255, 255, 255)),
        (LightingStatus.TWILIGHT, (105, 105, 105), (0, 0, 0)),
        (LightingStatus.TORCHLIGHT, (255, 255, 255), (0, 0, 0)),
    ])
    def test_darkness_around_player(self, game, lit_level, lighting_status, player_color, corner_color):
        player_point, corner_point = self.get_player_and_corner_points(lit_level)
        game.game_manager._lighting_status = lighting_status
        lit_level._screen.fill((255, 255, 255))

        lit_level._draw_darkness()

        assert tuple(lit_level._screen.get_at(player_point))[:3] == player_color
        assert tuple(lit_level._screen.get_at(corner_point))[:3] == corner_color


@pytest.mark.refactoring
class TestCreateSpritesFromBasicMap:
    def test_bottom_background_layer(self, basic_level):
        assert count_sprite_classes(basic_level._level_sprite_groups.bottom_background_layer) == {
            'CheckPoint': 1, 'ExitPoint': 1, 'Ground': 600}

    def test_bottom_sprites_layer(self, basic_level):
        assert count_sprite_classes(basic_level._level_sprite_groups.bottom_sprites_layer) == {
            'BowPowerup': 5, 'Diamond': 1, 'EnergyPowerup': 3, 'ExplosionPowerup': 1, 'FireFlameEnemyLeft': 1,
            'FireFlameEnemyRight': 2, 'Key': 2, 'LifePowerup': 1, 'LightingSpell': 3, 'SwordPowerup': 2,
            'Teleport': 3}

    def test_middle_sprites_layer(self, basic_level):
        assert count_sprite_classes(basic_level._level_sprite_groups.middle_sprites_layer) == {
            'BowWeapon': 1, 'DemolishedWall': 18, 'Door': 2, 'ExplosionWeapon': 1, 'Player': 1, 'Stone': 39,
            'SwordWeapon': 1, 'Wall': 206}

    def test_top_sprites_layer(self, basic_level):
        assert count_sprite_classes(basic_level._level_sprite_groups.top_sprites_layer) == {
            'BatEnemy': 1, 'GhostEnemy': 3, 'MonsterEnemy': 3, 'SpiderEnemy': 3}

    def test_the_highest_sprites_layer(self, basic_level):
        assert count_sprite_classes(basic_level._level_sprite_groups.the_highest_sprites_layer) == {'OctopusEnemy': 1}

    def test_functional_groups(self, basic_level):
        assert {group_name: len(getattr(basic_level._level_sprite_groups, group_name)) for group_name in (
            'exit_points', 'obstacle_sprites', 'moving_obstacle_sprites', 'removable_obstacle_sprites',
            'passage_sprites', 'teleport_sprites', 'collectable_sprites', 'enemy_sprites',
            'hostile_force_sprites')} == {
            'exit_points': 1, 'obstacle_sprites': 226, 'moving_obstacle_sprites': 39,
            'removable_obstacle_sprites': 18, 'passage_sprites': 2, 'teleport_sprites': 3,
            'collectable_sprites': 19, 'enemy_sprites': 11, 'hostile_force_sprites': 3}

    def test_obstacle_map_merges_walls_stones_demolished_walls_and_doors(self, basic_level):
        obstacle_map_items = basic_level._obstacle_map.items
        assert (len(obstacle_map_items), len(obstacle_map_items[0])) == (20, 30)
        # 206 walls, 39 stones, 18 demolished walls and 2 doors
        assert sum(sum(row) for row in obstacle_map_items) == 265

    def test_registers_diamonds_and_keys_in_game_manager(self, game, basic_level):
        assert len(game.game_manager.diamonds) == 1
        assert len(game.game_manager.keys) == 2

    def test_records_enemy_spawns(self, game, basic_level):
        level_stats = game.game_manager.current_level_stats
        assert {enemy_type: level_stats.get_enemy_record(enemy_type).count for enemy_type in EnemyType
                if level_stats.get_enemy_record(enemy_type).count} == {
            EnemyType.SPIDER_SMALL: 1, EnemyType.SPIDER_MEDIUM: 1, EnemyType.SPIDER_BIG: 1,
            EnemyType.MONSTER_BLUE: 1, EnemyType.MONSTER_GREEN: 1, EnemyType.MONSTER_RED: 1, EnemyType.BAT: 1}


class TestCreateBossOctopus:
    def test_shows_boss_with_full_energy(self, game, basic_level):
        boss_energy = OctopusTileDetails(None, None).energy

        basic_level.create_boss_octopus()

        assert game.game_manager.is_boss_visible is True
        assert game.game_manager.boss_energy == boss_energy
        assert game.game_manager.boss_max_energy == boss_energy


class TestCreateMonster:
    def test_records_spawn_of_deaf_monster(self, game, basic_level):
        deaf_monster_types = (EnemyType.MONSTER_BLUE_DEAF, EnemyType.MONSTER_GREEN_DEAF, EnemyType.MONSTER_RED_DEAF)
        level_stats = game.game_manager.current_level_stats
        count_before = sum(level_stats.get_enemy_record(enemy_type).count for enemy_type in deaf_monster_types)

        basic_level.create_monster((0, 0))

        assert sum(level_stats.get_enemy_record(enemy_type).count for enemy_type in deaf_monster_types) == count_before + 1
