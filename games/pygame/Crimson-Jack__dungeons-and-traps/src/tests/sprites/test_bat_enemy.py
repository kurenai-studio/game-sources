from unittest.mock import Mock

import pygame

from src.enums.enemy_type import EnemyType
from src.events import Events
from src.sprites.bat_enemy import BatEnemy


def create_bat_enemy_to_kill(game_manager, enemy_type, score):
    # Full constructor requires costumes and tile details, which are irrelevant for the kill
    bat_enemy = object.__new__(BatEnemy)
    pygame.sprite.Sprite.__init__(bat_enemy)
    bat_enemy.rect = pygame.Rect(0, 0, 64, 64)
    bat_enemy.sound_manager = Mock()
    bat_enemy.game_manager = game_manager
    bat_enemy.enemy_type = enemy_type
    bat_enemy.score = score
    return bat_enemy


class TestKill:
    def test_adds_score_records_kill_and_posts_tombstone(self, game_manager, post_event_mock):
        bat_enemy = create_bat_enemy_to_kill(game_manager, EnemyType.BAT, 300)

        bat_enemy.kill()

        enemy_record = game_manager.current_level_stats.get_enemy_record(EnemyType.BAT)
        assert game_manager.score == 300
        assert (enemy_record.killed, enemy_record.score) == (1, 300)
        assert Events.ADD_TOMBSTONE_EVENT in [call.args[0].type for call in post_event_mock.call_args_list]
