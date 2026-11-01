from src.bonus_record import BonusRecord
from src.collectable_record import CollectableRecord
from src.enemy_kill_record import EnemyKillRecord
from src.enums.enemy_type import EnemyType


class LevelStats:
    """Statistics of one level: enemies by type, diamonds, keys and the completion bonus."""

    def __init__(self) -> None:
        """Start with empty records for every enemy type, diamonds, keys and the bonus."""
        self._enemy_stats: dict[EnemyType, EnemyKillRecord] = {
            enemy_type: EnemyKillRecord() for enemy_type in EnemyType
        }
        self._diamond_record = CollectableRecord()
        self._key_record = CollectableRecord()
        self._bonus_record = BonusRecord()

    # Enemy

    def record_enemy_spawn(self, enemy_type: EnemyType) -> None:
        """
        Record an enemy that appeared on the level.

        :param enemy_type: type of the enemy
        """
        self._enemy_stats[enemy_type].record_spawn()

    def record_enemy_kill(self, enemy_type: EnemyType, score: int) -> None:
        """
        Record a killed enemy and its points.

        :param enemy_type: type of the enemy
        :param score: points of the enemy
        """
        self._enemy_stats[enemy_type].record_kill(score)

    def get_enemy_record(self, enemy_type: EnemyType) -> EnemyKillRecord:
        """
        Return the record of the given enemy type.

        :param enemy_type: type of the enemy
        :return: record of the enemy type
        """
        return self._enemy_stats[enemy_type]

    def get_enemy_spider_total_count(self) -> int:
        """Number of spiders that appeared on the level."""
        return sum(record.count for record in self._get_enemy_spider_records().values())

    def get_enemy_spider_total_kills(self) -> int:
        """Number of spiders killed."""
        return sum(record.killed for record in self._get_enemy_spider_records().values())

    def get_enemy_spider_total_score(self) -> int:
        """Points given by the killed spiders."""
        return sum(record.score for record in self._get_enemy_spider_records().values())

    def get_enemy_monster_total_count(self) -> int:
        """Number of monsters that appeared on the level."""
        return sum(record.count for record in self._get_enemy_monster_records().values())

    def get_enemy_monster_total_kills(self) -> int:
        """Number of monsters killed."""
        return sum(record.killed for record in self._get_enemy_monster_records().values())

    def get_enemy_monster_total_score(self) -> int:
        """Points given by the killed monsters."""
        return sum(record.score for record in self._get_enemy_monster_records().values())

    def get_enemy_bat_total_count(self) -> int:
        """Number of bats that appeared on the level."""
        return sum(record.count for record in self._get_enemy_bat_records().values())

    def get_enemy_bat_total_kills(self) -> int:
        """Number of bats killed."""
        return sum(record.killed for record in self._get_enemy_bat_records().values())

    def get_enemy_bat_total_score(self) -> int:
        """Points given by the killed bats."""
        return sum(record.score for record in self._get_enemy_bat_records().values())

    def all_enemies_defeated(self) -> bool:
        """
        Check whether any enemy appeared and all of them were killed.

        :return: True when the completion bonus is due
        """
        return self._total_enemy_count() > 0 and self._total_enemy_kills() == self._total_enemy_count()

    # Diamonds

    def record_diamond_placed(self) -> None:
        """Record a diamond placed on the map."""
        self._diamond_record.record_placed()

    def record_diamond_collected(self, score: int) -> None:
        """
        Record a collected diamond and its points.

        :param score: points of the diamond
        """
        self._diamond_record.record_collected(score)

    def get_diamond_record(self) -> CollectableRecord:
        """Return the record of diamonds."""
        return self._diamond_record

    # Keys

    def record_key_placed(self) -> None:
        """Record a key placed on the map."""
        self._key_record.record_placed()

    def record_key_collected(self, score: int) -> None:
        """
        Record a collected key and its points.

        :param score: points of the key
        """
        self._key_record.record_collected(score)

    def get_key_record(self) -> CollectableRecord:
        """Return the record of keys."""
        return self._key_record

    # Bonus

    def record_bonus_awarded(self, score: int) -> None:
        """
        Record the awarded completion bonus.

        :param score: points of the bonus
        """
        self._bonus_record.record_award(score)

    def get_bonus_record(self) -> BonusRecord:
        """Return the record of the completion bonus."""
        return self._bonus_record

    # Reset

    def reset(self) -> None:
        """Clear all records before the level is played again."""
        for record in self._enemy_stats.values():
            record.reset()
        self._diamond_record.reset()
        self._key_record.reset()
        self._bonus_record.reset()

    def _get_enemy_spider_records(self) -> dict[EnemyType, EnemyKillRecord]:
        # Records of the spider types only
        return {enemy_type: record for enemy_type, record in self._enemy_stats.items() if enemy_type.is_spider()}

    def _get_enemy_monster_records(self) -> dict[EnemyType, EnemyKillRecord]:
        # Records of the monster types only
        return {enemy_type: record for enemy_type, record in self._enemy_stats.items() if enemy_type.is_monster()}

    def _get_enemy_bat_records(self) -> dict[EnemyType, EnemyKillRecord]:
        # Records of the bat types only
        return {enemy_type: record for enemy_type, record in self._enemy_stats.items() if enemy_type.is_bat()}

    def _total_enemy_count(self) -> int:
        # Number of enemies of all types that appeared
        return sum(record.count for record in self._enemy_stats.values())

    def _total_enemy_kills(self) -> int:
        # Number of enemies of all types that were killed
        return sum(record.killed for record in self._enemy_stats.values())
