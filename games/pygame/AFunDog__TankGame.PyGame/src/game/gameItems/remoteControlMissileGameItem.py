from loguru import logger
from game.gameItems.gameItem import GameItem, GameItemData
from pygame.freetype import Font
from pygame import image, transform

from game.gameObject import GameObject, GameObjectData
from game.tank import Tank


class RemoteControlMissileGameItemData(GameItemData):
    def __init__(self, mapX: int, mapY: int, x: float, y: float, angle: float):
        super().__init__(mapX, mapY, x, y)
        self.angle = angle


class RemoteControlMissileGameItem(GameItem):

    def __init__(self, key: str, data: RemoteControlMissileGameItemData):
        GameObject.__init__(self, key, data)
        GameItem.__init__(self, data)
        self.body.angle = data.angle
        o_img = image.load("assets/missile_item.png").convert_alpha()
        img = transform.smoothscale(o_img, self.surface.get_size())
        self.surface.blit(img, (0, 0))

    @staticmethod
    def onTouched(tank: Tank):
        from game.weapons.remoteControlMissileWeapon import RemoteControlMissileWeapon

        tank.weapon = RemoteControlMissileWeapon(tank)
        logger.debug(f"当前坦克道具 {tank.weapon}")

    def getData(self) -> GameObjectData:
        return RemoteControlMissileGameItemData(
            self.mapX, self.mapY, self.body.position[0], self.body.position[1], self.body.angle
        )

    def setData(self, data: GameObjectData):
        ...