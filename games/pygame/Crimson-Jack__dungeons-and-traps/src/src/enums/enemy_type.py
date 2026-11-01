from enum import Enum


class EnemyType(Enum):
    # Spider types
    SPIDER_SMALL = 'spider-enemy-small'
    SPIDER_MEDIUM = 'spider-enemy-medium'
    SPIDER_BIG = 'spider-enemy-big'

    # Monster types
    MONSTER_BLUE = 'monster-enemy-blue'
    MONSTER_GREEN = 'monster-enemy-green'
    MONSTER_RED = 'monster-enemy-red'
    MONSTER_BLUE_DEAF = 'monster-enemy-blue-deaf'
    MONSTER_GREEN_DEAF = 'monster-enemy-green-deaf'
    MONSTER_RED_DEAF = 'monster-enemy-red-deaf'

    # Bat
    BAT = 'bat-enemy'

    @classmethod
    def from_name(cls, name: str) -> 'EnemyType':
        for member in cls:
            if member.value == name:
                return member

        parts = name.split('-')
        suggestions = []

        while parts and not suggestions:
            parts.pop()
            prefix = '-'.join(parts)
            for member in cls:
                if member.value.startswith(prefix):
                    suggestions.append(member.value)

        if not suggestions:
            suggestions = [member.value for member in cls]

        raise ValueError(f"Unknown enemy type: {name!r}. Did you mean one of: {suggestions}")

    def is_spider(self) -> bool:
        return self in (
            EnemyType.SPIDER_SMALL,
            EnemyType.SPIDER_MEDIUM,
            EnemyType.SPIDER_BIG,
        )

    def is_monster(self) -> bool:
        return self in (
            EnemyType.MONSTER_BLUE,
            EnemyType.MONSTER_GREEN,
            EnemyType.MONSTER_RED,
            EnemyType.MONSTER_BLUE_DEAF,
            EnemyType.MONSTER_GREEN_DEAF,
            EnemyType.MONSTER_RED_DEAF,
        )

    def is_bat(self) -> bool:
        return self == EnemyType.BAT
