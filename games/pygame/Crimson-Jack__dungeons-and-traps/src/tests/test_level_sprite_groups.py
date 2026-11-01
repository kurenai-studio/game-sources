import pygame
import pytest

from src.camera_group import CameraGroup
from src.camera_group_with_y_sort import CameraGroupWithYSort
from src.level_sprite_groups import LevelSpriteGroups

VISIBLE_GROUP_NAMES = ('bottom_background_layer', 'bottom_sprites_layer', 'middle_sprites_layer',
                       'top_sprites_layer', 'the_highest_sprites_layer')
FUNCTIONAL_GROUP_NAMES = ('exit_points', 'obstacle_sprites', 'moving_obstacle_sprites', 'removable_obstacle_sprites',
                          'passage_sprites', 'teleport_sprites', 'collectable_sprites', 'enemy_sprites',
                          'hostile_force_sprites')


def create_level_sprite_groups():
    return LevelSpriteGroups(pygame.Surface((320, 240)))


class TestLevelSpriteGroups:
    def test_middle_layer_sorts_sprites_by_y(self):
        assert type(create_level_sprite_groups().middle_sprites_layer) is CameraGroupWithYSort

    def test_other_visible_layers_are_camera_groups(self):
        level_sprite_groups = create_level_sprite_groups()
        for group_name in VISIBLE_GROUP_NAMES:
            if group_name != 'middle_sprites_layer':
                assert type(getattr(level_sprite_groups, group_name)) is CameraGroup, group_name

    def test_functional_groups_are_plain_groups(self):
        level_sprite_groups = create_level_sprite_groups()
        for group_name in FUNCTIONAL_GROUP_NAMES:
            assert type(getattr(level_sprite_groups, group_name)) is pygame.sprite.Group, group_name

    def test_all_groups_are_separate_and_empty(self):
        level_sprite_groups = create_level_sprite_groups()
        groups = [getattr(level_sprite_groups, group_name)
                  for group_name in VISIBLE_GROUP_NAMES + FUNCTIONAL_GROUP_NAMES]
        assert len({id(group) for group in groups}) == 14
        assert all(len(group) == 0 for group in groups)

    @pytest.mark.refactoring
    def test_visible_layers_use_given_surface(self):
        game_surface = pygame.Surface((320, 240))
        level_sprite_groups = LevelSpriteGroups(game_surface)
        for group_name in VISIBLE_GROUP_NAMES:
            camera_group = getattr(level_sprite_groups, group_name)
            assert camera_group._game_surface is game_surface, group_name
