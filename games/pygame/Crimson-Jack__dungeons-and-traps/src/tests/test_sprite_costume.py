import pygame

from src.sprite_costume import SpriteCostume


class TestSpriteCostume:
    def test_stores_image_and_number_of_frames(self):
        image = pygame.Surface((1, 1))

        sprite_costume = SpriteCostume(image, 4)

        assert sprite_costume.image is image
        assert sprite_costume.number_of_frames == 4


class TestCreateList:
    def test_creates_costume_for_each_image_in_order(self):
        images = [pygame.Surface((1, 1)), pygame.Surface((2, 2)), pygame.Surface((3, 3))]

        sprite_costumes = SpriteCostume.create_list(images, 6)

        assert [sprite_costume.image for sprite_costume in sprite_costumes] == images
        assert [sprite_costume.number_of_frames for sprite_costume in sprite_costumes] == [6, 6, 6]

    def test_returns_empty_list_for_no_images(self):
        assert SpriteCostume.create_list([], 6) == []
