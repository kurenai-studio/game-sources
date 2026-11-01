from unittest.mock import Mock

import pytest

from src import level_catalog
from src.enums.direction import Direction
from src.enums.enemy_type import EnemyType
from src.enums.sound_effect import SoundEffect
from src.enums.weapon_type import WeaponType
from src.events import Events
from src.game_manager import GameManager
from src.level_stats import LevelStats


def create_key(key_name):
    return Mock(key_name=key_name)


def get_posted_event_types(post_event_mock):
    return [call.args[0].type for call in post_event_mock.call_args_list]


@pytest.mark.refactoring
class TestCurrentLevelDetails:
    def test_returns_first_level_at_start(self, game_manager):
        assert game_manager.current_level_details is level_catalog.LEVELS[0]

    def test_returns_last_level_for_last_index(self, game_manager):
        game_manager._level_index = len(level_catalog.LEVELS) - 1

        assert game_manager.current_level_details is level_catalog.LEVELS[-1]

    def test_follows_level_change(self, game_manager):
        game_manager._level_index = 2

        assert game_manager.current_level_details is level_catalog.LEVELS[2]


@pytest.mark.refactoring
class TestNumberOfUsedSwordThresholds:
    @pytest.mark.parametrize('sword_energy, expected_number_of_used_thresholds', [
        (100, 0),
        (81, 0),
        (80, 1),
        (61, 1),
        (60, 2),
        (40, 3),
        (21, 3),
        (20, 4),
        (1, 4),
    ])
    def test_returns_used_thresholds_for_sword_energy(self, game_manager, sword_energy, expected_number_of_used_thresholds):
        game_manager._sword_energy = sword_energy

        assert game_manager.number_of_used_sword_thresholds == expected_number_of_used_thresholds


@pytest.mark.refactoring
class TestClearSettingsForFirstLevel:
    def test_resets_number_of_explosions(self, game_manager):
        game_manager._number_of_explosions = 3

        game_manager.clear_settings_for_first_level()

        assert game_manager.number_of_explosions == 0


@pytest.mark.refactoring
class TestIsKeyCollected:
    def test_returns_false_when_no_key_is_collected(self, game_manager):
        assert game_manager.is_key_collected('red') is False

    def test_returns_true_when_key_with_given_name_is_collected(self, game_manager):
        game_manager._collected_keys = [create_key('blue'), create_key('red')]

        assert game_manager.is_key_collected('red') is True

    def test_returns_false_when_only_keys_with_other_names_are_collected(self, game_manager):
        game_manager._collected_keys = [create_key('blue'), create_key('green')]

        assert game_manager.is_key_collected('red') is False


class TestSetPlayerMovement:
    @pytest.mark.parametrize('delta_x, delta_y, expected_direction', [
        (1, 0, Direction.RIGHT),
        (1, 1, Direction.RIGHT_DOWN),
        (0, 1, Direction.DOWN),
        (-1, 1, Direction.LEFT_DOWN),
        (-1, 0, Direction.LEFT),
        (-1, -1, Direction.LEFT_UP),
        (0, -1, Direction.UP),
        (1, -1, Direction.RIGHT_UP),
    ])
    def test_sets_direction_matching_movement(self, game_manager, delta_x, delta_y, expected_direction):
        game_manager.set_player_movement(delta_x, delta_y)

        assert game_manager.player_movement_direction == expected_direction

    @pytest.mark.refactoring
    def test_zero_movement_keeps_previous_direction(self, game_manager):
        game_manager._player_movement_direction = Direction.LEFT_UP

        game_manager.set_player_movement(0, 0)

        assert game_manager.player_movement_direction == Direction.LEFT_UP

    def test_released_key_stops_player_and_keeps_direction(self, game_manager):
        game_manager.set_player_movement(0, 1)
        game_manager.set_player_movement(0, -1)

        assert game_manager.player_movement_vector == (0, 0)
        assert game_manager.player_movement_direction == Direction.DOWN

    def test_component_greater_than_one_keeps_direction(self, game_manager):
        game_manager.set_player_movement(0, 1)
        game_manager.set_player_movement(0, 1)

        assert game_manager.player_movement_vector == (0, 2)
        assert game_manager.player_movement_direction == Direction.DOWN

    def test_combined_movements_set_diagonal_direction(self, game_manager):
        game_manager.set_player_movement(1, 0)
        game_manager.set_player_movement(0, 1)

        assert game_manager.player_movement_vector == (1, 1)
        assert game_manager.player_movement_direction == Direction.RIGHT_DOWN


@pytest.mark.refactoring
class TestGetAggregateCollectableStats:
    def test_sums_records_of_all_levels(self, game_manager):
        first_level_stats = LevelStats()
        for _ in range(5):
            first_level_stats.record_diamond_placed()
            first_level_stats.record_diamond_collected(10)
        first_level_stats.record_key_placed()
        first_level_stats.record_key_collected(30)
        first_level_stats.record_bonus_awarded(500)

        second_level_stats = LevelStats()
        for _ in range(3):
            second_level_stats.record_diamond_placed()
        second_level_stats.record_diamond_collected(10)
        second_level_stats.record_diamond_collected(10)
        second_level_stats.record_key_placed()

        game_manager._level_stats = [first_level_stats, second_level_stats]

        diamond_totals, key_totals, bonus_totals = game_manager.get_aggregate_collectable_stats()

        assert (diamond_totals.count, diamond_totals.collected, diamond_totals.score) == (8, 7, 70)
        assert (key_totals.count, key_totals.collected, key_totals.score) == (2, 1, 30)
        assert (bonus_totals.awarded, bonus_totals.score) == (1, 500)


@pytest.mark.refactoring
class TestGetAggregateKillStats:
    def test_sums_records_of_all_levels(self, game_manager):
        first_level_stats = LevelStats()
        first_level_stats.record_enemy_spawn(EnemyType.BAT)
        first_level_stats.record_enemy_spawn(EnemyType.BAT)
        first_level_stats.record_enemy_kill(EnemyType.BAT, 20)

        second_level_stats = LevelStats()
        second_level_stats.record_enemy_spawn(EnemyType.BAT)
        second_level_stats.record_enemy_kill(EnemyType.BAT, 20)
        second_level_stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        second_level_stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)

        game_manager._level_stats = [first_level_stats, second_level_stats]

        totals = game_manager.get_aggregate_kill_stats()

        bat_totals = totals[EnemyType.BAT]
        spider_small_totals = totals[EnemyType.SPIDER_SMALL]
        assert (bat_totals.count, bat_totals.killed, bat_totals.score) == (3, 2, 40)
        assert (spider_small_totals.count, spider_small_totals.killed, spider_small_totals.score) == (1, 1, 50)

    def test_returns_zero_records_for_enemy_types_absent_in_all_levels(self, game_manager):
        game_manager._level_stats = [LevelStats(), LevelStats()]

        totals = game_manager.get_aggregate_kill_stats()

        assert set(totals) == set(EnemyType)
        assert all((record.count, record.killed, record.score) == (0, 0, 0) for record in totals.values())


# Decrease method, amount field, weapon type and another weapon selected after the weapon is depleted
WEAPON_AMOUNTS = [
    ('decrease_sword_energy', '_sword_energy', WeaponType.SWORD, WeaponType.BOW),
    ('decrease_number_of_arrows', '_number_of_arrows', WeaponType.BOW, WeaponType.SWORD),
    ('decrease_number_of_explosions', '_number_of_explosions', WeaponType.EXPLOSION, WeaponType.SWORD),
]


@pytest.mark.refactoring
@pytest.mark.parametrize('decrease_method_name, amount_field_name, weapon_type, other_weapon_type', WEAPON_AMOUNTS)
class TestDecreaseWeaponAmount:
    def test_decreases_amount_and_keeps_weapon(self, game_manager, post_event_mock, decrease_method_name,
                                               amount_field_name, weapon_type, other_weapon_type):
        setattr(game_manager, amount_field_name, 3)
        game_manager._collected_weapons = [weapon_type]
        game_manager._weapon_type = weapon_type

        getattr(game_manager, decrease_method_name)()

        assert getattr(game_manager, amount_field_name) == 2
        assert game_manager.collected_weapons == [weapon_type]
        assert game_manager.weapon_type == weapon_type
        assert get_posted_event_types(post_event_mock) == [Events.CHANGE_WEAPON_CAPACITY_EVENT]

    def test_depleting_only_weapon_selects_no_weapon(self, game_manager, post_event_mock, decrease_method_name,
                                                     amount_field_name, weapon_type, other_weapon_type):
        setattr(game_manager, amount_field_name, 1)
        game_manager._collected_weapons = [weapon_type]
        game_manager._weapon_type = weapon_type

        getattr(game_manager, decrease_method_name)()

        assert getattr(game_manager, amount_field_name) == 0
        assert game_manager.collected_weapons == [WeaponType.NONE]
        assert game_manager.weapon_type == WeaponType.NONE

    def test_depleting_weapon_selects_other_collected_weapon(self, game_manager, post_event_mock, decrease_method_name,
                                                             amount_field_name, weapon_type, other_weapon_type):
        setattr(game_manager, amount_field_name, 1)
        game_manager._collected_weapons = [weapon_type, other_weapon_type]
        game_manager._weapon_type = weapon_type

        getattr(game_manager, decrease_method_name)()

        assert game_manager.collected_weapons == [other_weapon_type]
        assert game_manager.weapon_type == other_weapon_type
        assert get_posted_event_types(post_event_mock) == [Events.CHANGE_WEAPON_EVENT]

    def test_amount_does_not_go_below_zero(self, game_manager, post_event_mock, decrease_method_name,
                                           amount_field_name, weapon_type, other_weapon_type):
        setattr(game_manager, amount_field_name, 0)
        game_manager._collected_weapons = [weapon_type]
        game_manager._weapon_type = weapon_type

        getattr(game_manager, decrease_method_name)()

        assert getattr(game_manager, amount_field_name) == 0


@pytest.mark.refactoring
class TestSwitchWeapon:
    def test_next_weapon_skips_weapons_not_collected(self, game_manager, post_event_mock):
        game_manager._collected_weapons = [WeaponType.NONE, WeaponType.BOW]
        game_manager._weapon_type = WeaponType.NONE

        game_manager.set_next_weapon()

        assert game_manager.weapon_type == WeaponType.BOW

    def test_next_weapon_wraps_around_from_last_weapon(self, game_manager, post_event_mock):
        game_manager._collected_weapons = [WeaponType.SWORD, WeaponType.EXPLOSION]
        game_manager._weapon_type = WeaponType.EXPLOSION

        game_manager.set_next_weapon()

        assert game_manager.weapon_type == WeaponType.SWORD

    def test_previous_weapon_skips_weapons_not_collected_and_wraps_around(self, game_manager, post_event_mock):
        game_manager._collected_weapons = [WeaponType.SWORD, WeaponType.EXPLOSION]
        game_manager._weapon_type = WeaponType.SWORD

        game_manager.set_previous_weapon()

        assert game_manager.weapon_type == WeaponType.EXPLOSION

    @pytest.mark.parametrize('switch_method_name', ['set_next_weapon', 'set_previous_weapon'])
    def test_weapon_change_plays_sound_and_posts_event(self, game_manager, post_event_mock, switch_method_name):
        game_manager._collected_weapons = [WeaponType.SWORD, WeaponType.EXPLOSION]
        game_manager._weapon_type = WeaponType.SWORD

        getattr(game_manager, switch_method_name)()

        game_manager._sound_manager.play_sfx.assert_called_once_with(SoundEffect.CHANGE_WEAPON)
        assert get_posted_event_types(post_event_mock) == [Events.CHANGE_WEAPON_EVENT]

    @pytest.mark.parametrize('switch_method_name', ['set_next_weapon', 'set_previous_weapon'])
    def test_single_weapon_stays_without_sound_and_event(self, game_manager, post_event_mock, switch_method_name):
        game_manager._collected_weapons = [WeaponType.SWORD]
        game_manager._weapon_type = WeaponType.SWORD

        getattr(game_manager, switch_method_name)()

        assert game_manager.weapon_type == WeaponType.SWORD
        game_manager._sound_manager.play_sfx.assert_not_called()
        assert get_posted_event_types(post_event_mock) == []


class TestShowBoss:
    def test_sets_full_energy_and_visibility(self, game_manager):
        game_manager.show_boss(300)

        assert game_manager.boss_max_energy == 300
        assert game_manager.boss_energy == 300
        assert game_manager.is_boss_visible is True


@pytest.mark.refactoring
class TestRecordEnemySpawn:
    def test_records_spawn_in_current_level_stats(self, game_manager):
        previous_level_stats = LevelStats()
        current_level_stats = LevelStats()
        game_manager._level_stats = [previous_level_stats, current_level_stats]

        game_manager.record_enemy_spawn(EnemyType.BAT)

        assert current_level_stats.get_enemy_record(EnemyType.BAT).count == 1
        assert previous_level_stats.get_enemy_record(EnemyType.BAT).count == 0


@pytest.mark.refactoring
class TestAwardEnemyKill:
    def test_adds_score_and_records_kill_in_current_level_stats(self, game_manager, post_event_mock):
        previous_level_stats = LevelStats()
        current_level_stats = LevelStats()
        game_manager._level_stats = [previous_level_stats, current_level_stats]

        game_manager.award_enemy_kill(EnemyType.BAT, 300)

        current_record = current_level_stats.get_enemy_record(EnemyType.BAT)
        assert game_manager.score == 300
        assert (current_record.killed, current_record.score) == (1, 300)
        assert previous_level_stats.get_enemy_record(EnemyType.BAT).killed == 0
        assert get_posted_event_types(post_event_mock) == [Events.CHANGE_SCORE_EVENT]


class TestSetBossEnergy:
    def test_sets_current_energy_only(self, game_manager):
        game_manager.show_boss(300)

        game_manager.set_boss_energy(120)

        assert game_manager.boss_energy == 120
        assert game_manager.boss_max_energy == 300


class TestValidateSecretCode:
    def test_returns_index_of_first_campaign_level(self, game_manager):
        assert game_manager.validate_secret_code('c1') == 0

    def test_returns_index_of_test_map(self, game_manager):
        level_filenames = [level_details.source_file for level_details in level_catalog.LEVELS]

        assert game_manager.validate_secret_code('a2') == level_filenames.index('basic_arena.tmx')

    @pytest.mark.parametrize('code', ['unknown', ''])
    def test_returns_none_for_code_of_no_level(self, game_manager, code):
        assert game_manager.validate_secret_code(code) is None

    def test_can_be_called_without_instance(self):
        assert GameManager.validate_secret_code('c1') == 0
