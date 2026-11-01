import pygame

from settings import Settings
from src.sprite_costume import SpriteCostume
from src.spritesheet import SpriteSheet


class SpriteHelper:
    # Source (originate) tile size
    SOURCE_TILE_SIZE = 16
    SCALE = int(Settings.TILE_SIZE), int(Settings.TILE_SIZE)
    KEY_COLOR = 0, 0, 0

    @staticmethod
    def _create_sprite_sheet(path: str, source_size: int, size: tuple[float, float], key_color) -> SpriteSheet:
        sprite_sheet = SpriteSheet(
            pygame.image.load(path).convert_alpha(),
            source_size,
            source_size,
            size,
            key_color
        )

        return sprite_sheet

    @staticmethod
    def get_sprite_image(sprite_sheet_name: str, row: int, cell: int):
        sprite_sheet = SpriteHelper._create_sprite_sheet(f'img/{sprite_sheet_name}.png', SpriteHelper.SOURCE_TILE_SIZE, SpriteHelper.SCALE, SpriteHelper.KEY_COLOR)
        return sprite_sheet.get_image(row, cell)

    @staticmethod
    def get_large_sprite_image(name, row: int, cell: int, number_of_tiles: int):
        octopus_source_tile_size = SpriteHelper.SOURCE_TILE_SIZE * number_of_tiles
        octopus_scale = int(Settings.TILE_SIZE * number_of_tiles), int(Settings.TILE_SIZE * number_of_tiles)
        sprite_sheet = SpriteHelper._create_sprite_sheet(f'img/{name}.png', octopus_source_tile_size, octopus_scale, SpriteHelper.KEY_COLOR)
        return sprite_sheet.get_image(row, cell)

    @staticmethod
    def get_sprite_costumes_matrix(sprite_sheet_name: str, sprite_costumes: list[SpriteCostume]) -> list[list[SpriteCostume]]:
        sprite_sheet = SpriteHelper._create_sprite_sheet(f'img/{sprite_sheet_name}.png', SpriteHelper.SOURCE_TILE_SIZE, SpriteHelper.SCALE, SpriteHelper.KEY_COLOR)
        result = list()

        for cell in range(0, len(sprite_costumes)):
            rows = list()
            for row in range(0, sprite_sheet.number_of_rows):
                rows.append(
                    SpriteCostume(sprite_sheet.get_image(row, cell), sprite_costumes[cell].number_of_frames)
                )
            result.append(rows)

        return result

    @staticmethod
    def get_all_player_sprites(number_of_sprites):
        sprite_sheet = SpriteHelper._create_sprite_sheet('img/player.png', SpriteHelper.SOURCE_TILE_SIZE, SpriteHelper.SCALE, SpriteHelper.KEY_COLOR)

        sprites = {
            'left': [],
            'right': [],
            'up': [],
            'down': [],
            'right_down': [],
            'left_down': [],
            'left_up': [],
            'right_up': []}

        # Sprites with the state: standing
        sprites['right'].append(sprite_sheet.get_image(0, 0))
        sprites['left'].append(sprite_sheet.get_image(2, 0))
        sprites['up'].append(sprite_sheet.get_image(4, 0))
        sprites['down'].append(sprite_sheet.get_image(6, 0))
        sprites['right_down'].append(sprite_sheet.get_image(6, 0))
        sprites['right_up'].append(sprite_sheet.get_image(4, 0))
        sprites['left_down'].append(sprite_sheet.get_image(6, 0))
        sprites['left_up'].append(sprite_sheet.get_image(4, 0))

        # Sprites with the state: walking
        for number in range(0, number_of_sprites):
            sprites['right'].append(sprite_sheet.get_image(1, number))
            sprites['left'].append(sprite_sheet.get_image(3, number))
            sprites['up'].append(sprite_sheet.get_image(5, number))
            sprites['down'].append(sprite_sheet.get_image(7, number))
            sprites['right_down'].append(sprite_sheet.get_image(7, number))
            sprites['right_up'].append(sprite_sheet.get_image(5, number))
            sprites['left_down'].append(sprite_sheet.get_image(7, number))
            sprites['left_up'].append(sprite_sheet.get_image(5, number))

        return sprites

    @staticmethod
    def get_life_sprite():
        sprite_sheet = SpriteHelper._create_sprite_sheet('img/misc.png', SpriteHelper.SOURCE_TILE_SIZE, (64, 64), SpriteHelper.KEY_COLOR)
        return sprite_sheet.get_image(1, 2)

    @staticmethod
    def get_all_arrow_sprites():
        sprite_sheet = SpriteHelper._create_sprite_sheet('img/arrow.png', SpriteHelper.SOURCE_TILE_SIZE, SpriteHelper.SCALE, SpriteHelper.KEY_COLOR)

        sprites = {
            'left': [],
            'right': [],
            'up': [],
            'down': [],
            'right_up': [],
            'left_up': [],
            'right_down': [],
            'left_down': []
        }

        sprites['right'].append(sprite_sheet.get_image(0, 0))
        sprites['left'].append(sprite_sheet.get_image(1, 0))
        sprites['up'].append(sprite_sheet.get_image(2, 0))
        sprites['down'].append(sprite_sheet.get_image(3, 0))
        sprites['right_up'].append(sprite_sheet.get_image(4, 0))
        sprites['left_up'].append(sprite_sheet.get_image(5, 0))
        sprites['right_down'].append(sprite_sheet.get_image(6, 0))
        sprites['left_down'].append(sprite_sheet.get_image(7, 0))

        return sprites

    @staticmethod
    def get_all_sword_sprites():
        sprite_sheet = SpriteHelper._create_sprite_sheet('img/sword.png', SpriteHelper.SOURCE_TILE_SIZE, SpriteHelper.SCALE, SpriteHelper.KEY_COLOR)

        sprites = {
            'left': [],
            'right': [],
            'up': [],
            'down': []}

        sprites['right'].append(sprite_sheet.get_image(0, 0))
        sprites['right'].append(sprite_sheet.get_image(0, 1))
        sprites['right'].append(sprite_sheet.get_image(0, 2))
        sprites['right'].append(sprite_sheet.get_image(0, 3))
        sprites['right'].append(sprite_sheet.get_image(0, 3))
        sprites['right'].append(sprite_sheet.get_image(0, 3))
        sprites['right'].append(sprite_sheet.get_image(0, 3))
        sprites['right'].append(sprite_sheet.get_image(0, 3))

        sprites['left'].append(sprite_sheet.get_image(1, 0))
        sprites['left'].append(sprite_sheet.get_image(1, 1))
        sprites['left'].append(sprite_sheet.get_image(1, 2))
        sprites['left'].append(sprite_sheet.get_image(1, 3))
        sprites['left'].append(sprite_sheet.get_image(1, 3))
        sprites['left'].append(sprite_sheet.get_image(1, 3))
        sprites['left'].append(sprite_sheet.get_image(1, 3))
        sprites['left'].append(sprite_sheet.get_image(1, 3))

        sprites['up'].append(sprite_sheet.get_image(2, 0))
        sprites['up'].append(sprite_sheet.get_image(2, 1))
        sprites['up'].append(sprite_sheet.get_image(2, 2))
        sprites['up'].append(sprite_sheet.get_image(2, 3))
        sprites['up'].append(sprite_sheet.get_image(2, 3))
        sprites['up'].append(sprite_sheet.get_image(2, 3))
        sprites['up'].append(sprite_sheet.get_image(2, 3))
        sprites['up'].append(sprite_sheet.get_image(2, 3))

        sprites['down'].append(sprite_sheet.get_image(3, 0))
        sprites['down'].append(sprite_sheet.get_image(3, 1))
        sprites['down'].append(sprite_sheet.get_image(3, 2))
        sprites['down'].append(sprite_sheet.get_image(3, 3))
        sprites['down'].append(sprite_sheet.get_image(3, 3))
        sprites['down'].append(sprite_sheet.get_image(3, 3))
        sprites['down'].append(sprite_sheet.get_image(3, 3))
        sprites['down'].append(sprite_sheet.get_image(3, 3))

        return sprites

    @staticmethod
    def get_all_tombstone_sprites():
        sprite_sheet = SpriteHelper._create_sprite_sheet('img/skull.png', SpriteHelper.SOURCE_TILE_SIZE, SpriteHelper.SCALE, SpriteHelper.KEY_COLOR)

        sprites = list()
        sprites.append(sprite_sheet.get_image(0, 0))
        sprites.append(sprite_sheet.get_image(0, 1))
        sprites.append(sprite_sheet.get_image(0, 2))
        sprites.append(sprite_sheet.get_image(0, 3))

        return sprites

    @staticmethod
    def get_all_boss_tombstone_sprites():
        source_tile_size = SpriteHelper.SOURCE_TILE_SIZE * 3
        scale = int(Settings.TILE_SIZE * 3), int(Settings.TILE_SIZE * 3)
        sprite_sheet = SpriteHelper._create_sprite_sheet('img/vanishing-flare-point.png', source_tile_size, scale, SpriteHelper.KEY_COLOR)

        sprites = list()
        sprites.append(sprite_sheet.get_image(0, 0))
        sprites.append(sprite_sheet.get_image(0, 1))
        sprites.append(sprite_sheet.get_image(0, 2))
        sprites.append(sprite_sheet.get_image(0, 3))
        sprites.append(sprite_sheet.get_image(0, 4))
        sprites.append(sprite_sheet.get_image(0, 5))
        sprites.append(sprite_sheet.get_image(0, 6))
        sprites.append(sprite_sheet.get_image(0, 7))
        sprites.append(sprite_sheet.get_image(0, 8))
        sprites.append(sprite_sheet.get_image(0, 9))
        sprites.append(sprite_sheet.get_image(0, 10))
        sprites.append(sprite_sheet.get_image(0, 11))
        sprites.append(sprite_sheet.get_image(0, 12))
        sprites.append(sprite_sheet.get_image(0, 13))
        sprites.append(sprite_sheet.get_image(0, 14))
        sprites.append(sprite_sheet.get_image(0, 15))
        sprites.append(sprite_sheet.get_image(0, 16))
        sprites.append(sprite_sheet.get_image(0, 17))

        return sprites

    @staticmethod
    def get_all_vanishing_point_sprites():
        sprite_sheet = SpriteHelper._create_sprite_sheet('img/vanishing-point.png', SpriteHelper.SOURCE_TILE_SIZE, SpriteHelper.SCALE, SpriteHelper.KEY_COLOR)

        sprites = list()
        sprites.append(sprite_sheet.get_image(0, 0))
        sprites.append(sprite_sheet.get_image(0, 1))
        sprites.append(sprite_sheet.get_image(0, 2))
        sprites.append(sprite_sheet.get_image(0, 3))
        sprites.append(sprite_sheet.get_image(0, 4))
        sprites.append(sprite_sheet.get_image(0, 5))
        sprites.append(sprite_sheet.get_image(0, 6))
        sprites.append(sprite_sheet.get_image(0, 7))

        return sprites

    @staticmethod
    def get_all_bow_sprites():
        sprite_sheet = SpriteHelper._create_sprite_sheet('img/bow.png', SpriteHelper.SOURCE_TILE_SIZE, SpriteHelper.SCALE, SpriteHelper.KEY_COLOR)

        sprites = {
            'left': [],
            'right': [],
            'up': [],
            'down': [],
            'right_down': [],
            'left_down': [],
            'left_up': [],
            'right_up': []}

        sprites['right'].append(sprite_sheet.get_image(0, 0))
        sprites['left'].append(sprite_sheet.get_image(1, 0))
        sprites['up'].append(sprite_sheet.get_image(2, 0))
        sprites['down'].append(sprite_sheet.get_image(3, 0))
        sprites['right_up'].append(sprite_sheet.get_image(4, 0))
        sprites['left_up'].append(sprite_sheet.get_image(5, 0))
        sprites['right_down'].append(sprite_sheet.get_image(6, 0))
        sprites['left_down'].append(sprite_sheet.get_image(7, 0))

        return sprites

    @staticmethod
    def get_all_tnt_sprites():
        sprite_sheet = SpriteHelper._create_sprite_sheet('img/tnt.png', SpriteHelper.SOURCE_TILE_SIZE, SpriteHelper.SCALE, SpriteHelper.KEY_COLOR)

        sprites = {
            'left': [],
            'right': [],
            'up': [],
            'down': []}

        sprites['right'].append(sprite_sheet.get_image(0, 0))
        sprites['left'].append(sprite_sheet.get_image(1, 0))
        sprites['up'].append(sprite_sheet.get_image(2, 0))
        sprites['down'].append(sprite_sheet.get_image(3, 0))

        return sprites

    @staticmethod
    def get_enemy_icon(enemy_type, size: tuple[int, int]) -> pygame.Surface:
        sprite_sheet = SpriteHelper._create_sprite_sheet(f'img/{enemy_type.value}.png', SpriteHelper.SOURCE_TILE_SIZE, size, SpriteHelper.KEY_COLOR)
        return sprite_sheet.get_image(0, 0)

    @staticmethod
    def get_all_monster_sprites(name):
        sprite_sheet = SpriteHelper._create_sprite_sheet(f'img/{name}.png', SpriteHelper.SOURCE_TILE_SIZE, SpriteHelper.SCALE, SpriteHelper.KEY_COLOR)

        sprites = list()

        sprites.append(sprite_sheet.get_image(0, 0))
        sprites.append(sprite_sheet.get_image(0, 1))
        sprites.append(sprite_sheet.get_image(0, 2))
        sprites.append(sprite_sheet.get_image(0, 3))

        return sprites

    @staticmethod
    def get_all_octopus_sprites(name):
        octopus_source_tile_size = SpriteHelper.SOURCE_TILE_SIZE * 3
        octopus_scale = int(Settings.TILE_SIZE * 3), int(Settings.TILE_SIZE * 3)
        sprite_sheet = SpriteHelper._create_sprite_sheet(f'img/{name}.png', octopus_source_tile_size, octopus_scale, SpriteHelper.KEY_COLOR)

        sprites = list()

        sprites.append(sprite_sheet.get_image(0, 0))
        sprites.append(sprite_sheet.get_image(0, 1))
        sprites.append(sprite_sheet.get_image(0, 2))
        sprites.append(sprite_sheet.get_image(0, 3))

        sprites.append(sprite_sheet.get_image(0, 4))
        sprites.append(sprite_sheet.get_image(0, 5))
        sprites.append(sprite_sheet.get_image(0, 6))
        sprites.append(sprite_sheet.get_image(0, 7))

        sprites.append(sprite_sheet.get_image(0, 8))
        sprites.append(sprite_sheet.get_image(0, 9))
        sprites.append(sprite_sheet.get_image(0, 10))
        sprites.append(sprite_sheet.get_image(0, 11))

        sprites.append(sprite_sheet.get_image(0, 12))
        sprites.append(sprite_sheet.get_image(0, 13))
        sprites.append(sprite_sheet.get_image(0, 14))
        sprites.append(sprite_sheet.get_image(0, 15))

        return sprites

    @staticmethod
    def get_sword_images_to_header_view():
        sprite_sheet = SpriteHelper._create_sprite_sheet(f'img/misc.png', SpriteHelper.SOURCE_TILE_SIZE, (64, 64), SpriteHelper.KEY_COLOR)

        images = list()
        images.append(sprite_sheet.get_image(2, 0))
        images.append(sprite_sheet.get_image(2, 1))
        images.append(sprite_sheet.get_image(2, 2))
        images.append(sprite_sheet.get_image(2, 3))
        images.append(sprite_sheet.get_image(2, 4))

        return images

    @staticmethod
    def get_bow_image_to_header_view():
        sprite_sheet = SpriteHelper._create_sprite_sheet(f'img/misc.png', SpriteHelper.SOURCE_TILE_SIZE, (64, 64), SpriteHelper.KEY_COLOR)
        return sprite_sheet.get_image(1, 1)

    @staticmethod
    def get_explosion_image_to_header_view():
        sprite_sheet = SpriteHelper._create_sprite_sheet(f'img/misc.png', SpriteHelper.SOURCE_TILE_SIZE, (64, 64), SpriteHelper.KEY_COLOR)
        return sprite_sheet.get_image(1, 0)

    @staticmethod
    def get_all_fire_ball_enemy_sprites():
        sprite_sheet = SpriteHelper._create_sprite_sheet('img/fireball.png', SpriteHelper.SOURCE_TILE_SIZE, SpriteHelper.SCALE, SpriteHelper.KEY_COLOR)

        sprites = list()

        sprites.append(sprite_sheet.get_image(0, 0))
        sprites.append(sprite_sheet.get_image(0, 1))
        sprites.append(sprite_sheet.get_image(0, 2))
        sprites.append(sprite_sheet.get_image(0, 3))

        return sprites

    @staticmethod
    def get_game_over_lose_image(size: tuple[int, int]) -> pygame.Surface:
        game_over_image_source_size = 120
        sprite_sheet = SpriteHelper._create_sprite_sheet('img/game-over-you-lose.png', game_over_image_source_size, size, SpriteHelper.KEY_COLOR)
        return sprite_sheet.get_image(0, 0)

    @staticmethod
    def get_game_over_win_image(size: tuple[int, int]) -> pygame.Surface:
        game_over_image_source_size = 120
        sprite_sheet = SpriteHelper._create_sprite_sheet('img/game-over-you-win.png', game_over_image_source_size, size, SpriteHelper.KEY_COLOR)
        return sprite_sheet.get_image(0, 0)

    @staticmethod
    def get_loading_page_image(size: tuple[int, int]) -> pygame.Surface:
        loading_page_image_source_width = 320
        loading_page_image_source_height = 192
        sprite_sheet = SpriteSheet(
            pygame.image.load('img/loading-page.png').convert_alpha(),
            loading_page_image_source_width,
            loading_page_image_source_height,
            size,
            None
        )
        return sprite_sheet.get_image(0, 0)

    @staticmethod
    def get_all_egg_sprites():
        sprite_sheet = SpriteHelper._create_sprite_sheet('img/egg.png', SpriteHelper.SOURCE_TILE_SIZE, SpriteHelper.SCALE, SpriteHelper.KEY_COLOR)

        sprites = list()

        sprites.append(sprite_sheet.get_image(0, 0))
        sprites.append(sprite_sheet.get_image(0, 1))
        sprites.append(sprite_sheet.get_image(0, 2))
        sprites.append(sprite_sheet.get_image(0, 3))

        return sprites
