from loguru import logger
from numpy import isin
from game.bullets.commonBullet import CommonBullet
from game.bullets.ghostBullet import GhostBullet, GhostBulletData
from game.events.eventManager import EventManager
from game.events.globalEvents import GlobalEvents
from game.gameObject import GameObject, GameObjectFactory
from game.sceneManager import SceneManager
from game.scenes.gameScene import GameScene
from game.tank import Tank
from game.weapons.weapon import Weapon
from pygame.event import Event

GHOST_DISAPPEAR_EVENT_TYPE = EventManager.allocateEventType()


class GhostWeapon(Weapon):
    """
    幽灵坦克武器
    发射幽灵子弹
    """

    TOTAL_MAX_BULLET = 10
    MAX_BULLET = 5
    __shootBulletCount: int = 0
    __totalShootBulletCount: int = 0
    __bullets: set[GhostBullet]

    def __init__(self, owner: GameObject):
        super().__init__(owner)
        self.__bullets = set()

    def fire(self):
        BULLET_SHOOT_DIS = self.owner.surface.get_width() / 2 + 2

        # if self.owner.body.space:

        self.__shootBulletCount += 1
        self.__totalShootBulletCount += 1


        GlobalEvents.GameObjectAdding(
            f"{self.owner.key}_GhostBullet_{self.__totalShootBulletCount}",
            GhostBulletData(
                self.owner.body.position[0] + self.owner.body.rotation_vector[0] * BULLET_SHOOT_DIS,
                self.owner.body.position[1] + self.owner.body.rotation_vector[1] * BULLET_SHOOT_DIS,
                self.owner.body.angle,
            ),
        )
    def __onGameObjectAdded(self,obj : GameObject):
        if isinstance(obj, GhostBullet):
            def __onBulletRemoved(obj : GameObject):
                if obj in self.__bullets:
                    self.__bullets.remove(obj)
                    self.__shootBulletCount = max(0, self.__shootBulletCount - 1)
            obj.Removed += __onBulletRemoved
            self.__bullets.add(obj)
            logger.debug(f"坦克发射子弹 {self} {obj}")


    def canFire(self) -> bool:
        return self.__shootBulletCount < GhostWeapon.MAX_BULLET

    def canUse(self) -> bool:
        return self.__totalShootBulletCount < GhostWeapon.TOTAL_MAX_BULLET

    def onPicked(self):
        GlobalEvents.GameObjectAdded += self.__onGameObjectAdded
        ...

    def onDropped(self):
        GlobalEvents.GameObjectAdded -= self.__onGameObjectAdded
        ...