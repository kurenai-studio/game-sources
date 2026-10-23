import math
from typing import Sequence
from loguru import logger
from pygame import Surface
from pymunk import Body, Shape
from game.bullets.explosiveBomb import ExplosiveBomb, ExplosiveBombData
from game.effects.explosiveBombEffect import ExplosiveBombEffectData
from game.events.eventManager import EventManager
from game.events.globalEvents import GlobalEvents
from game.gameObject import GameObject
from game.weapons.weapon import Weapon
from pygame.event import Event

# TODO 在系统清除炮弹时，不产生爆炸效果


class ExplosiveBombWeapon(Weapon):
    """
    高爆炮弹武器
    发生高爆炮弹
    """

    __isShooted: bool = False
    __bomb: ExplosiveBomb | None = None

    def __init__(self, owner: GameObject):
        super().__init__(owner)

    def fire(self):

        BULLET_SHOOT_DIS = self.owner.surface.get_width() / 2 + 4
        self.__isShooted = True

        GlobalEvents.GameObjectAdding(
            f"{self.owner.key}_ExplosiveBomb_{id(self)}",
            ExplosiveBombData(
                self.owner.body.position[0] + self.owner.body.rotation_vector[0] * BULLET_SHOOT_DIS,
                self.owner.body.position[1] + self.owner.body.rotation_vector[1] * BULLET_SHOOT_DIS,
                self.owner.body.angle,
            ),
        )

    def __onGameObjectAdded(self, obj: GameObject):
        if isinstance(obj, ExplosiveBomb):
            GlobalEvents.GameObjectAdded -= self.__onGameObjectAdded
            self.__bomb = obj
            self.__bomb.Removed += self.__onBombRemoved
            logger.debug(f"坦克发射子弹 {self} {self.__bomb}")

    def __onBombRemoved(self, obj: GameObject):
        assert isinstance(obj, ExplosiveBomb)
        GlobalEvents.GameObjectAdding(
            f"{obj.key}_effect",
            ExplosiveBombEffectData(obj.body.position[0], obj.body.position[1], 0),
        )

    def canFire(self) -> bool:
        return not self.__isShooted

    def canUse(self) -> bool:
        return not self.__isShooted

    def onPicked(self):
        GlobalEvents.GameObjectAdded += self.__onGameObjectAdded

    def onDropped(self):
        ...
