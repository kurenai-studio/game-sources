from abc import ABC, abstractmethod
import math
from loguru import logger
from pygame import Surface, transform,mixer
from pymunk import Arbiter, Body, CollisionHandler, Poly, ShapeFilter, Space
from game.events.eventManager import EventManager
from game.events.globalEvents import GlobalEvents
from game.gameObject import GameObject, GameObjectData
from game.sceneManager import SceneManager

from game.tank import TANK_COLLISION_TYPE, Tank
from typing import Any
from pygame.event import Event

GAMEITEM_COLLISION_TYPE = 3


class GameItemData(GameObjectData, ABC):
    def __init__(self, mapX: int, mapY: int, x: float, y: float):
        self.mapX = mapX
        self.mapY = mapY
        self.x = x
        self.y = y


class GameItem(GameObject, ABC):
    """
    游戏道具类
    """

    __collisionHandler: CollisionHandler

    @property
    def mapX(self):
        return self.__mapX

    @property
    def mapY(self):
        return self.__mapY

    def __init__(self, data: GameItemData):
        self.surface = Surface((30, 30))
        self.surface.set_colorkey((255, 0, 255))
        self.surface.fill((255, 0, 255))

        self.__mapX = data.mapX
        self.__mapY = data.mapY
        self.body = Body(body_type=Body.KINEMATIC)
        self.body.position = (data.x, data.y)

        self.shapes = [Poly.create_box(self.body, self.surface.get_size())]
        for shape in self.shapes:
            shape.sensor = True
            shape.collision_type = GAMEITEM_COLLISION_TYPE
            # shape.filter = ShapeFilter(categories=0b0001)

        self.__appearSound = mixer.Sound("assets/item_appear.mp3")
        self.__appearSound.set_volume(0.1)

    def render(self, screen: Surface):
        r = transform.rotate(self.surface, math.degrees(-self.body.angle))
        screen.blit(r, r.get_rect(center=self.body.position))

    def setBody(self, space: Space):
        super().setBody(space)
        self.__collisionHandler = space.add_collision_handler(
            GAMEITEM_COLLISION_TYPE, TANK_COLLISION_TYPE
        )
        self.__collisionHandler.begin = GameItem.__onTankTouched

    @staticmethod
    def __onTankTouched(arbiter: Arbiter, space: Space, data: dict[Any, Any]):
        from game.scenes.gameScene import GameScene

        if isinstance((gameScene := SceneManager.getCurrentScene()), GameScene):

            item = gameScene.gameObjectSpace.getGameObjectByBody(arbiter.shapes[0].body)
            tank = gameScene.gameObjectSpace.getGameObjectByBody(arbiter.shapes[1].body)
            if isinstance(item, GameItem) and isinstance(tank, Tank):
                item.onTouched(tank)
                GlobalEvents.GameObjectRemoving(item.key)
            logger.debug(f"道具被坦克碰撞 {item} {tank}")
        return True

    @staticmethod
    @abstractmethod
    def onTouched(tank: Tank):
        ...

    def onEntered(self):
        super().onEntered()
        self.__appearSound.play()

