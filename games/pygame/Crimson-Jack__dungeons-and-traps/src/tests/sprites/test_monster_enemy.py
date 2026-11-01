from unittest.mock import Mock

import pygame

from src.enums.enemy_type import EnemyType
from src.events import Events
from src.sprites.monster_enemy import MonsterEnemy


def create_monster_enemy_to_kill(game_manager, enemy_type, score):
    # Full constructor requires costumes and tile details, which are irrelevant for the kill
    monster_enemy = object.__new__(MonsterEnemy)
    pygame.sprite.Sprite.__init__(monster_enemy)
    monster_enemy.rect = pygame.Rect(0, 0, 64, 64)
    monster_enemy.sound_manager = Mock()
    monster_enemy.game_manager = game_manager
    monster_enemy.enemy_type = enemy_type
    monster_enemy.score = score
    return monster_enemy


class TestKill:
    def test_adds_score_records_kill_and_posts_tombstone(self, game_manager, post_event_mock):
        monster_enemy = create_monster_enemy_to_kill(game_manager, EnemyType.MONSTER_BLUE, 300)

        monster_enemy.kill()

        enemy_record = game_manager.current_level_stats.get_enemy_record(EnemyType.MONSTER_BLUE)
        assert game_manager.score == 300
        assert (enemy_record.killed, enemy_record.score) == (1, 300)
        assert Events.ADD_TOMBSTONE_EVENT in [call.args[0].type for call in post_event_mock.call_args_list]
