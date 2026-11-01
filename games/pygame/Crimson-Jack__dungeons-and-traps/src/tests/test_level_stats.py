import pytest

from src.enums.enemy_type import EnemyType
from src.level_stats import LevelStats


class TestLevelStatsRecordEnemySpawn:
    def test_increases_count_for_enemy_type(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).count == 1

    def test_accumulates_count_for_same_enemy_type(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).count == 2

    def test_does_not_affect_killed(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).killed == 0

    def test_does_not_affect_score(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).score == 0

    def test_tracks_different_enemy_types_independently(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        stats.record_enemy_spawn(EnemyType.MONSTER_BLUE)
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).count == 1
        assert stats.get_enemy_record(EnemyType.MONSTER_BLUE).count == 1


class TestLevelStatsRecordEnemyKill:
    def test_increases_killed_for_enemy_type(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).killed == 1

    def test_increases_score_for_enemy_type(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).score == 50

    def test_accumulates_killed_for_same_enemy_type(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).killed == 2

    def test_accumulates_score_for_same_enemy_type(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).score == 100

    def test_does_not_affect_count(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).count == 0

    def test_tracks_different_enemy_types_independently(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        stats.record_enemy_kill(EnemyType.MONSTER_BLUE, 300)
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).killed == 1
        assert stats.get_enemy_record(EnemyType.MONSTER_BLUE).killed == 1


class TestLevelStatsReset:
    def test_resets_enemy_count_to_zero(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        stats.reset()
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).count == 0

    def test_resets_enemy_killed_to_zero(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        stats.reset()
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).killed == 0

    def test_resets_enemy_score_to_zero(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        stats.reset()
        assert stats.get_enemy_record(EnemyType.SPIDER_SMALL).score == 0

    def test_resets_diamond_record(self):
        stats = LevelStats()
        stats.record_diamond_placed()
        stats.record_diamond_collected(100)
        stats.reset()
        assert stats.get_diamond_record().count == 0
        assert stats.get_diamond_record().collected == 0
        assert stats.get_diamond_record().score == 0

    def test_resets_key_record(self):
        stats = LevelStats()
        stats.record_key_placed()
        stats.record_key_collected(200)
        stats.reset()
        assert stats.get_key_record().count == 0
        assert stats.get_key_record().collected == 0
        assert stats.get_key_record().score == 0

    def test_resets_bonus_record(self):
        stats = LevelStats()
        stats.record_bonus_awarded(1000)
        stats.reset()
        assert stats.get_bonus_record().awarded == 0
        assert stats.get_bonus_record().score == 0


@pytest.mark.refactoring
class TestLevelStatsTotals:
    def test_total_enemy_count_sums_spawned_for_all_enemy_types(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        stats.record_enemy_spawn(EnemyType.MONSTER_BLUE)
        assert stats._total_enemy_count() == 3

    def test_total_enemy_count_is_zero_initially(self):
        stats = LevelStats()
        assert stats._total_enemy_count() == 0

    def test_total_enemy_kills_sums_killed_for_all_enemy_types(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        stats.record_enemy_kill(EnemyType.MONSTER_BLUE, 300)
        assert stats._total_enemy_kills() == 3

    def test_total_enemy_kills_is_zero_initially(self):
        stats = LevelStats()
        assert stats._total_enemy_kills() == 0

    def test_total_enemy_kills_does_not_count_spawned_only_enemies(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        assert stats._total_enemy_kills() == 0


class TestLevelStatsAllEnemiesDefeated:
    def test_returns_true_when_all_spawned_enemies_killed(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        stats.record_enemy_spawn(EnemyType.MONSTER_BLUE)
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        stats.record_enemy_kill(EnemyType.MONSTER_BLUE, 300)
        assert stats.all_enemies_defeated() is True

    def test_returns_false_when_not_all_enemies_killed(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        stats.record_enemy_spawn(EnemyType.MONSTER_BLUE)
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        assert stats.all_enemies_defeated() is False

    def test_returns_false_when_no_enemies_spawned(self):
        stats = LevelStats()
        assert stats.all_enemies_defeated() is False

    def test_returns_false_when_no_enemies_killed(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        assert stats.all_enemies_defeated() is False


@pytest.mark.refactoring
class TestLevelStatsGroupRecords:
    def test_get_enemy_spider_records_returns_only_spider_types(self):
        stats = LevelStats()
        for enemy_type in stats._get_enemy_spider_records():
            assert enemy_type.is_spider()

    def test_get_enemy_monster_records_returns_only_monster_types(self):
        stats = LevelStats()
        for enemy_type in stats._get_enemy_monster_records():
            assert enemy_type.is_monster()

    def test_get_enemy_bat_records_returns_only_bat_types(self):
        stats = LevelStats()
        for enemy_type in stats._get_enemy_bat_records():
            assert enemy_type.is_bat()

    def test_get_enemy_spider_records_contains_all_spider_types(self):
        stats = LevelStats()
        assert len(stats._get_enemy_spider_records()) == 3

    def test_get_enemy_monster_records_contains_all_monster_types(self):
        stats = LevelStats()
        assert len(stats._get_enemy_monster_records()) == 6

    def test_get_enemy_bat_records_contains_all_bat_types(self):
        stats = LevelStats()
        assert len(stats._get_enemy_bat_records()) == 1


class TestLevelStatsGroupTotals:
    def test_get_enemy_spider_total_count(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        stats.record_enemy_spawn(EnemyType.SPIDER_MEDIUM)
        stats.record_enemy_spawn(EnemyType.MONSTER_BLUE)
        assert stats.get_enemy_spider_total_count() == 2

    def test_get_enemy_spider_total_kills(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        stats.record_enemy_kill(EnemyType.SPIDER_MEDIUM, 75)
        stats.record_enemy_kill(EnemyType.MONSTER_BLUE, 300)
        assert stats.get_enemy_spider_total_kills() == 2

    def test_get_enemy_spider_total_score(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        stats.record_enemy_kill(EnemyType.SPIDER_MEDIUM, 75)
        stats.record_enemy_kill(EnemyType.MONSTER_BLUE, 300)
        assert stats.get_enemy_spider_total_score() == 125

    def test_get_enemy_monster_total_count(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.MONSTER_BLUE)
        stats.record_enemy_spawn(EnemyType.MONSTER_RED)
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        assert stats.get_enemy_monster_total_count() == 2

    def test_get_enemy_monster_total_kills(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.MONSTER_BLUE, 300)
        stats.record_enemy_kill(EnemyType.MONSTER_RED, 300)
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        assert stats.get_enemy_monster_total_kills() == 2

    def test_get_enemy_monster_total_score(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.MONSTER_BLUE, 300)
        stats.record_enemy_kill(EnemyType.MONSTER_RED, 250)
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        assert stats.get_enemy_monster_total_score() == 550

    def test_get_enemy_bat_total_count(self):
        stats = LevelStats()
        stats.record_enemy_spawn(EnemyType.BAT)
        stats.record_enemy_spawn(EnemyType.BAT)
        stats.record_enemy_spawn(EnemyType.SPIDER_SMALL)
        assert stats.get_enemy_bat_total_count() == 2

    def test_get_enemy_bat_total_kills(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.BAT, 100)
        stats.record_enemy_kill(EnemyType.BAT, 100)
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        assert stats.get_enemy_bat_total_kills() == 2

    def test_get_enemy_bat_total_score(self):
        stats = LevelStats()
        stats.record_enemy_kill(EnemyType.BAT, 100)
        stats.record_enemy_kill(EnemyType.BAT, 100)
        stats.record_enemy_kill(EnemyType.SPIDER_SMALL, 50)
        assert stats.get_enemy_bat_total_score() == 200

    def test_group_totals_are_zero_initially(self):
        stats = LevelStats()
        assert stats.get_enemy_spider_total_count() == 0
        assert stats.get_enemy_monster_total_count() == 0
        assert stats.get_enemy_bat_total_count() == 0


class TestLevelStatsDiamonds:
    def test_record_diamond_placed_increases_count(self):
        stats = LevelStats()
        stats.record_diamond_placed()
        assert stats.get_diamond_record().count == 1

    def test_record_diamond_placed_accumulates(self):
        stats = LevelStats()
        stats.record_diamond_placed()
        stats.record_diamond_placed()
        assert stats.get_diamond_record().count == 2

    def test_record_diamond_collected_increases_collected(self):
        stats = LevelStats()
        stats.record_diamond_collected(100)
        assert stats.get_diamond_record().collected == 1

    def test_record_diamond_collected_increases_score(self):
        stats = LevelStats()
        stats.record_diamond_collected(100)
        assert stats.get_diamond_record().score == 100

    def test_record_diamond_collected_accumulates(self):
        stats = LevelStats()
        stats.record_diamond_collected(100)
        stats.record_diamond_collected(150)
        assert stats.get_diamond_record().collected == 2
        assert stats.get_diamond_record().score == 250

    def test_record_diamond_placed_does_not_affect_collected(self):
        stats = LevelStats()
        stats.record_diamond_placed()
        assert stats.get_diamond_record().collected == 0

    def test_initial_diamond_record_is_zero(self):
        stats = LevelStats()
        record = stats.get_diamond_record()
        assert record.count == 0
        assert record.collected == 0
        assert record.score == 0


class TestLevelStatsKeys:
    def test_record_key_placed_increases_count(self):
        stats = LevelStats()
        stats.record_key_placed()
        assert stats.get_key_record().count == 1

    def test_record_key_placed_accumulates(self):
        stats = LevelStats()
        stats.record_key_placed()
        stats.record_key_placed()
        assert stats.get_key_record().count == 2

    def test_record_key_collected_increases_collected(self):
        stats = LevelStats()
        stats.record_key_collected(200)
        assert stats.get_key_record().collected == 1

    def test_record_key_collected_increases_score(self):
        stats = LevelStats()
        stats.record_key_collected(200)
        assert stats.get_key_record().score == 200

    def test_record_key_collected_accumulates(self):
        stats = LevelStats()
        stats.record_key_collected(200)
        stats.record_key_collected(200)
        assert stats.get_key_record().collected == 2
        assert stats.get_key_record().score == 400

    def test_record_key_placed_does_not_affect_collected(self):
        stats = LevelStats()
        stats.record_key_placed()
        assert stats.get_key_record().collected == 0

    def test_initial_key_record_is_zero(self):
        stats = LevelStats()
        record = stats.get_key_record()
        assert record.count == 0
        assert record.collected == 0
        assert record.score == 0


class TestLevelStatsBonus:
    def test_record_bonus_awarded_increases_awarded(self):
        stats = LevelStats()
        stats.record_bonus_awarded(1000)
        assert stats.get_bonus_record().awarded == 1

    def test_record_bonus_awarded_increases_score(self):
        stats = LevelStats()
        stats.record_bonus_awarded(1000)
        assert stats.get_bonus_record().score == 1000

    def test_record_bonus_awarded_accumulates(self):
        stats = LevelStats()
        stats.record_bonus_awarded(1000)
        stats.record_bonus_awarded(1000)
        assert stats.get_bonus_record().awarded == 2
        assert stats.get_bonus_record().score == 2000

    def test_initial_bonus_record_is_zero(self):
        stats = LevelStats()
        record = stats.get_bonus_record()
        assert record.awarded == 0
        assert record.score == 0
