from unittest.mock import Mock

import pygame

from src.enums.enemy_type import EnemyType
from src.events import Events
from src.sprites.spider_enemy import SpiderEnemy


def create_spider_enemy(rect, min_y_position):
    # Full constructor requires costumes and tile details, which are irrelevant for the culling rectangle
    spider_enemy = object.__new__(SpiderEnemy)
    spider_enemy.rect = rect
    spider_enemy.min_y_position = min_y_position
    return spider_enemy


def create_spider_enemy_to_kill(game_manager, enemy_type, score):
    # Full constructor requires costumes and tile details, which are irrelevant for the kill
    spider_enemy = object.__new__(SpiderEnemy)
    pygame.sprite.Sprite.__init__(spider_enemy)
    spider_enemy.rect = pygame.Rect(0, 0, 64, 64)
    spider_enemy.sound_manager = Mock()
    spider_enemy.game_manager = game_manager
    spider_enemy.enemy_type = enemy_type
    spider_enemy.score = score
    return spider_enemy


class TestGetCullingRect:
    def test_covers_net_anchor_above_sprite(self):
        spider_enemy = create_spider_enemy(pygame.Rect(100, 300, 64, 64), 100)
        assert spider_enemy.get_culling_rect() == pygame.Rect(100, 100, 64, 264)

    def test_equals_sprite_rect_at_start_position(self):
        spider_enemy = create_spider_enemy(pygame.Rect(100, 100, 64, 64), 100)
        assert spider_enemy.get_culling_rect() == pygame.Rect(100, 100, 64, 64)


class TestKill:
    def test_adds_score_records_kill_and_posts_tombstone(self, game_manager, post_event_mock):
        spider_enemy = create_spider_enemy_to_kill(game_manager, EnemyType.SPIDER_SMALL, 300)

        spider_enemy.kill()

        enemy_record = game_manager.current_level_stats.get_enemy_record(EnemyType.SPIDER_SMALL)
        assert game_manager.score == 300
        assert (enemy_record.killed, enemy_record.score) == (1, 300)
        assert Events.ADD_TOMBSTONE_EVENT in [call.args[0].type for call in post_event_mock.call_args_list]
