import pytest

from src.enums.enemy_type import EnemyType


class TestEnemyTypeFromName:
    def test_returns_correct_member_for_spider_small(self):
        assert EnemyType.from_name('spider-enemy-small') == EnemyType.SPIDER_SMALL

    def test_returns_correct_member_for_spider_medium(self):
        assert EnemyType.from_name('spider-enemy-medium') == EnemyType.SPIDER_MEDIUM

    def test_returns_correct_member_for_spider_big(self):
        assert EnemyType.from_name('spider-enemy-big') == EnemyType.SPIDER_BIG

    def test_returns_correct_member_for_monster_blue(self):
        assert EnemyType.from_name('monster-enemy-blue') == EnemyType.MONSTER_BLUE

    def test_returns_correct_member_for_monster_green(self):
        assert EnemyType.from_name('monster-enemy-green') == EnemyType.MONSTER_GREEN

    def test_returns_correct_member_for_monster_red(self):
        assert EnemyType.from_name('monster-enemy-red') == EnemyType.MONSTER_RED

    def test_returns_correct_member_for_monster_blue_deaf(self):
        assert EnemyType.from_name('monster-enemy-blue-deaf') == EnemyType.MONSTER_BLUE_DEAF

    def test_returns_correct_member_for_monster_green_deaf(self):
        assert EnemyType.from_name('monster-enemy-green-deaf') == EnemyType.MONSTER_GREEN_DEAF

    def test_returns_correct_member_for_monster_red_deaf(self):
        assert EnemyType.from_name('monster-enemy-red-deaf') == EnemyType.MONSTER_RED_DEAF

    def test_returns_correct_member_for_bat(self):
        assert EnemyType.from_name('bat-enemy') == EnemyType.BAT

    def test_raises_value_error_for_unknown_name(self):
        with pytest.raises(ValueError):
            EnemyType.from_name('unknown-enemy')

    def test_error_message_suggests_monster_types_for_unknown_monster(self):
        with pytest.raises(ValueError, match='monster-enemy-blue'):
            EnemyType.from_name('monster-enemy-gray')

    def test_error_message_suggests_spider_types_for_unknown_spider(self):
        with pytest.raises(ValueError, match='spider-enemy-small'):
            EnemyType.from_name('spider-enemy-huge')


class TestEnemyTypeIsSpider:
    def test_spider_small_is_spider(self):
        assert EnemyType.SPIDER_SMALL.is_spider()

    def test_spider_medium_is_spider(self):
        assert EnemyType.SPIDER_MEDIUM.is_spider()

    def test_spider_big_is_spider(self):
        assert EnemyType.SPIDER_BIG.is_spider()

    def test_monster_is_not_spider(self):
        assert not EnemyType.MONSTER_BLUE.is_spider()

    def test_bat_is_not_spider(self):
        assert not EnemyType.BAT.is_spider()


class TestEnemyTypeIsMonster:
    def test_monster_blue_is_monster(self):
        assert EnemyType.MONSTER_BLUE.is_monster()

    def test_monster_red_deaf_is_monster(self):
        assert EnemyType.MONSTER_RED_DEAF.is_monster()

    def test_spider_is_not_monster(self):
        assert not EnemyType.SPIDER_SMALL.is_monster()

    def test_bat_is_not_monster(self):
        assert not EnemyType.BAT.is_monster()


class TestEnemyTypeIsBat:
    def test_bat_is_bat(self):
        assert EnemyType.BAT.is_bat()

    def test_spider_is_not_bat(self):
        assert not EnemyType.SPIDER_SMALL.is_bat()

    def test_monster_is_not_bat(self):
        assert not EnemyType.MONSTER_BLUE.is_bat()
