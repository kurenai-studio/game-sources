from unittest.mock import MagicMock, Mock, call

import pytest
import pytmx

from settings import Settings
from src.level_sprite_builder import LevelSpriteBuilder


def create_level_sprite_builder_with_tmx_data(tmx_data):
    # Full constructor builds the whole world from a real TMX map, so the map is replaced by a mock
    level_sprite_builder = object.__new__(LevelSpriteBuilder)
    level_sprite_builder._tmx_data = tmx_data
    return level_sprite_builder


def create_tmx_data(get_object_by_name=None, visible_layers=()):
    tmx_data = Mock()
    tmx_data.tilewidth = 16
    tmx_data.tileheight = 16
    tmx_data.get_object_by_name.side_effect = get_object_by_name
    tmx_data.visible_layers = list(visible_layers)
    return tmx_data


def create_layer(name, layer_type=pytmx.TiledTileLayer, layer_class=Mock):
    # The spec makes isinstance() recognise the mock as the given kind of TMX layer
    layer = layer_class(spec=layer_type)
    layer.name = name
    return layer


def raise_value_error(name):
    raise ValueError(name)


def raise_key_error(name):
    raise KeyError(name)


@pytest.mark.refactoring
class TestGetVisibleObject:
    def test_returns_visible_object(self):
        tiled_object = Mock(visible=True)
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(
            create_tmx_data(get_object_by_name=lambda name: tiled_object))
        assert level_sprite_builder._get_visible_object('check-point') is tiled_object

    def test_returns_none_for_invisible_object(self):
        tiled_object = Mock(visible=False)
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(
            create_tmx_data(get_object_by_name=lambda name: tiled_object))
        assert level_sprite_builder._get_visible_object('check-point') is None

    def test_returns_none_when_object_raises_value_error(self):
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(
            create_tmx_data(get_object_by_name=raise_value_error))
        assert level_sprite_builder._get_visible_object('check-point') is None

    def test_returns_none_when_object_raises_key_error(self):
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(
            create_tmx_data(get_object_by_name=raise_key_error))
        assert level_sprite_builder._get_visible_object('check-point') is None


@pytest.mark.refactoring
class TestGetVisibleLayer:
    def test_returns_visible_layer_with_given_name(self):
        ground_layer = create_layer('ground')
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(
            create_tmx_data(visible_layers=[create_layer('obstacle'), ground_layer]))
        assert level_sprite_builder._get_visible_layer('ground', pytmx.TiledTileLayer) is ground_layer

    def test_returns_none_for_layer_of_other_type(self):
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(
            create_tmx_data(visible_layers=[create_layer('ground', pytmx.TiledObjectGroup)]))
        assert level_sprite_builder._get_visible_layer('ground', pytmx.TiledTileLayer) is None

    def test_returns_none_for_invisible_layer(self):
        # Invisible layers are absent from visible_layers
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(
            create_tmx_data(visible_layers=[create_layer('obstacle')]))
        assert level_sprite_builder._get_visible_layer('ground', pytmx.TiledTileLayer) is None

    def test_returns_none_for_map_without_layers(self):
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(create_tmx_data())
        assert level_sprite_builder._get_visible_layer('ground', pytmx.TiledTileLayer) is None


@pytest.mark.refactoring
class TestGetBossPointPosition:
    def test_returns_none_without_boss_point(self):
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(
            create_tmx_data(get_object_by_name=raise_value_error))
        assert level_sprite_builder._get_boss_point_position() is None

    def test_returns_position_in_pixels(self, monkeypatch):
        monkeypatch.setattr(Settings, 'TILE_SIZE', 64)
        boss_object = Mock(visible=True, x=48, y=80)
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(
            create_tmx_data(get_object_by_name=lambda name: boss_object))
        assert level_sprite_builder._get_boss_point_position() == (3 * 64, 5 * 64)


@pytest.mark.refactoring
class TestCreatePlayer:
    def test_missing_player_raises_value_error(self):
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(
            create_tmx_data(get_object_by_name=raise_value_error))
        with pytest.raises(ValueError, match='player'):
            level_sprite_builder._create_player()

    def test_invisible_player_raises_value_error(self):
        player_object = Mock(visible=False)
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(
            create_tmx_data(get_object_by_name=lambda name: player_object))
        with pytest.raises(ValueError, match='player'):
            level_sprite_builder._create_player()


@pytest.mark.refactoring
class TestCreateSpritesFromLayer:
    def test_passes_each_tile_with_position_in_pixels(self, monkeypatch):
        monkeypatch.setattr(Settings, 'TILE_SIZE', 64)
        first_image = Mock()
        second_image = Mock()
        layer = create_layer('ground')
        layer.tiles.return_value = [(0, 0, first_image), (3, 5, second_image)]
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(create_tmx_data(visible_layers=[layer]))
        create_sprite = Mock()

        level_sprite_builder._create_sprites_from_layer('ground', create_sprite)

        assert create_sprite.call_args_list == [call(first_image, layer, (0, 0)),
                                                call(second_image, layer, (3 * 64, 5 * 64))]

    def test_skips_missing_layer(self):
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(create_tmx_data())
        create_sprite = Mock()

        level_sprite_builder._create_sprites_from_layer('ground', create_sprite)

        create_sprite.assert_not_called()


@pytest.mark.refactoring
class TestCreateSpritesFromObjectLayer:
    def test_passes_only_visible_objects_with_tile_position(self, monkeypatch):
        monkeypatch.setattr(Settings, 'TILE_SIZE', 64)
        visible_item = Mock(visible=True, x=48, y=80, rotation=0)
        invisible_item = Mock(visible=False, x=0, y=0, rotation=0)
        layer = create_layer('teleport', pytmx.TiledObjectGroup, MagicMock)
        layer.__iter__.return_value = [visible_item, invisible_item]
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(create_tmx_data(visible_layers=[layer]))
        create_sprite = Mock()

        level_sprite_builder._create_sprites_from_object_layer('teleport', create_sprite)

        create_sprite.assert_called_once_with(visible_item, layer, (3 * 64, 5 * 64))

    def test_skips_missing_layer(self):
        level_sprite_builder = create_level_sprite_builder_with_tmx_data(create_tmx_data())
        create_sprite = Mock()

        level_sprite_builder._create_sprites_from_object_layer('teleport', create_sprite)

        create_sprite.assert_not_called()
