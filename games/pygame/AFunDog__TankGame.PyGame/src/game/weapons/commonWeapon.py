from loguru import logger
from game.bullets.commonBullet import CommonBullet, CommonBulletData
from game.events.eventManager import EventManager
from game.events.globalEvents import GlobalEvents
from game.gameObject import GameObject, GameObjectFactory

from game.sceneManager import SceneManager
from game.scenes.gameScene import GameScene
from game.weapons.weapon import Weapon
from pygame.event import Event

from online.onlineManager import OnlineManager


BULLET_DISAPPEAR_EVENT_TYPE = EventManager.allocateEventType()


class CommonWeapon(Weapon):
    """
    正常坦克武器
    发射普通炮弹
    """

    MAX_BULLET = 5
    __shootBulletCount = 0
    __bullets: set[CommonBullet]
    __totalBulletCount = 0

    def __init__(self, owner: GameObject):
        super().__init__(owner)
        self.__bullets = set()
        

    def fire(self):
        BULLET_SHOOT_DIS = self.owner.surface.get_width() / 2 + 4
        self.__shootBulletCount += 1


        GlobalEvents.GameObjectAdding(
            f"{self.owner.key}_Bullet_{self.__totalBulletCount}",
            CommonBulletData(
                self.owner.body.position.x + self.owner.body.rotation_vector.x * BULLET_SHOOT_DIS,
                self.owner.body.position.y + self.owner.body.rotation_vector.y * BULLET_SHOOT_DIS,
                self.owner.body.angle,
            ),
        )
        self.__totalBulletCount += 1
        
    def __onGameObjectAdded(self,obj : GameObject):
        if isinstance(obj, CommonBullet):
            def __onBulletRemoved(obj : GameObject):
                if obj in self.__bullets:
                    self.__bullets.remove(obj)
                    self.__shootBulletCount = max(0, self.__shootBulletCount - 1)
            obj.Removed += __onBulletRemoved
            self.__bullets.add(obj)
            logger.debug(f"坦克发射子弹 {self} {obj}")

    def canFire(self) -> bool:
        return self.__shootBulletCount < CommonWeapon.MAX_BULLET

    def canUse(self) -> bool:
        return True

    def onPicked(self):
        GlobalEvents.GameObjectAdded += self.__onGameObjectAdded
        ...

    def onDropped(self):
        GlobalEvents.GameObjectAdded -= self.__onGameObjectAdded
        ...

