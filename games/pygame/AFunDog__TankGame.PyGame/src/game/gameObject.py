from abc import ABC, abstractmethod
from typing import Callable, TypeVar, final
from loguru import logger
from pygame import Surface
from pymunk import Body, Shape, Space

from game.events.delegate import Delegate


class GameObjectData(ABC): ...


class GameObject(ABC):
    """
    游戏物体抽象基类
    """

    surface: Surface
    """
    物体图像
    """

    body: Body
    """
    物理世界物体
    """

    shapes: list[Shape]
    """
    物理世界复合形状
    """

    @property
    def key(self) -> str:
        """
        游戏对象的唯一标识符

        并且需要在不同电脑上保持一致
        """
        return self.__key

    @final
    @property
    def isExist(self):
        """判断物体是否处在游戏空间中"""

        if self.CurrentSpace is not None:
            return self.CurrentSpace.containObject(self)
        else:
            return False

    @final
    @property
    def CurrentSpace(self):
        """获取当前物体所处在的游戏空间 如果不存在返回None"""
        from .sceneManager import SceneManager
        from .scenes.gameScene import GameScene
        from .scenes.clientGameScene import ClientGameScene

        curScene = SceneManager.getCurrentScene()
        if isinstance(curScene, GameScene) or isinstance(curScene, ClientGameScene):
            return curScene.gameObjectSpace
        else:
            return None

    @abstractmethod
    def __init__(self, key: str, data: GameObjectData):
        """从游戏对象数据进行初始化"""

        self.__key = key
        """游戏对象的唯一标识符"""

        self.Entered = Delegate[GameObject](f"{key} 进入游戏空间")
        """当物体进入游戏空间时触发"""

        self.Removed = Delegate[GameObject](f"{key} 被移除游戏空间")
        """当物体被移除游戏空间时触发"""

    @abstractmethod
    def render(self, screen: Surface):
        """
        每帧绘制物体
        """
        pass

    def update(self, delta: float):
        """
        每帧调用更新函数
        """
        ...

    def setBody(self, space: Space):
        """
        设置物理世界物体
        """
        space.add(self.body, *self.shapes)

    def removeBody(self, space: Space):
        """
        移除物理世界物体
        """
        space.remove(self.body, *self.shapes)

    def onEntered(self):
        self.Entered(self)
        ...

    def onRemoved(self):
        self.Removed(self)
        ...

    @abstractmethod
    def getData(self) -> GameObjectData:
        """从当前游戏对象获取游戏对象数据"""
        ...

    def setData(self, data: GameObjectData):
        """从游戏对象数据设置更改当前游戏对象"""
        raise NotImplementedError("游戏对象不支持重新设置数据")


@final
class GameObjectFactory(ABC):
    """
    游戏对象工厂
    根据游戏对象数据生成游戏对象实例
    """

    @staticmethod
    def create(key: str, data: GameObjectData) -> GameObject:
        from .gameMap import GameMapData, GameMap
        from .tank import TankData, Tank
        from .bullets.commonBullet import CommonBulletData, CommonBullet
        from .bullets.explosiveBomb import ExplosiveBombData, ExplosiveBomb
        from .bullets.ghostBullet import GhostBulletData, GhostBullet
        from .bullets.missile import MissileData, Missile
        from .gameItems.fragmentWeaponGameItem import (
            FragmentWeaponGameItemData,
            FragmentWeaponGameItem,
        )
        from .gameItems.ghostWeaponGameItem import GhostWeaponGameItemData, GhostWeaponGameItem
        from .gameItems.remoteControlMissileGameItem import (
            RemoteControlMissileGameItemData,
            RemoteControlMissileGameItem,
        )
        from .effects.explosiveBombEffect import ExplosiveBombEffectData, ExplosiveBombEffect

        recipe: dict[type[GameObjectData], type[GameObject]] = {
            GameMapData: GameMap,
            TankData: Tank,
            CommonBulletData: CommonBullet,
            ExplosiveBombData: ExplosiveBomb,
            GhostBulletData: GhostBullet,
            MissileData: Missile,
            FragmentWeaponGameItemData: FragmentWeaponGameItem,
            GhostWeaponGameItemData: GhostWeaponGameItem,
            RemoteControlMissileGameItemData: RemoteControlMissileGameItem,
            ExplosiveBombEffectData: ExplosiveBombEffect,
        }

        if type(data) in recipe:
            return recipe[type(data)](key, data)
        else:
            # logger.error(f"无法创建游戏对象 {key,type(data)}")
            raise TypeError(f"无法创建游戏对象 {key, type(data)}")
