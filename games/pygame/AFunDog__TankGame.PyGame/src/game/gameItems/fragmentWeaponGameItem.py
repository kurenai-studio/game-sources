from loguru import logger
from game.gameItems.gameItem import GameItem, GameItemData
from game.defines import SMALL_FONT
from game.gameObject import GameObject, GameObjectData
from game.tank import Tank

from pygame import image, transform


class FragmentWeaponGameItemData(GameItemData):
    def __init__(self, mapX: int, mapY: int, x: float, y: float, angle: float):
        super().__init__(mapX, mapY, x, y)
        self.angle = angle


class FragmentWeaponGameItem(GameItem):

    def __init__(self, key: str, data: FragmentWeaponGameItemData):
        GameObject.__init__(self, key, data)
        GameItem.__init__(self, data)
        self.body.angle = data.angle
        o_img = image.load("assets/bomb_item.png").convert_alpha()
        img = transform.smoothscale(o_img, self.surface.get_size())
        self.surface.blit(img, (0, 0))

    @staticmethod
    def onTouched(tank: Tank):
        from game.weapons.explosiveBombWeapon import ExplosiveBombWeapon

        tank.weapon = ExplosiveBombWeapon(tank)
        logger.debug(f"当前坦克道具 {tank.weapon}")

    def getData(self) -> GameObjectData:
        return FragmentWeaponGameItemData(
            self.mapX, self.mapY, self.body.position[0], self.body.position[1], self.body.angle
        )

    def setData(self, data: GameObjectData):
        ...