from abc import ABC, abstractmethod
from enum import Enum
from typing import Sequence, final

from loguru import logger
from pygame import Rect, Surface
from pymunk import Body, Space, Vec2d

from game.events.globalEvents import GlobalEvents
from game.gameObject import GameObject


class GAMEOBJECT_SPACE_TYPE(Enum):
    EMPTY = 0
    LOCAL = 1
    SERVER = 2
    CLIENT = 3


class GameObjectSpace:



    @property
    def objects(self) -> dict[str, GameObject]:
        """
        游戏对象列表
        """
        return self.__objects

    @property
    def space(self) -> Space:
        """
        物理空间
        """
        return self.__space

    @property
    def spaceRegion(self) -> Rect | None:
        """
        空间有效区域
        """
        return self.__spaceRegion

    @spaceRegion.setter
    def spaceRegion(self, value: Rect | None): 
        self.__spaceRegion = value

    def __init__(self):
        self.__objects = dict[str, GameObject]()
        self.__space = Space()
        self.__spaceRegion: Rect | None = None
        """
        空间范围
        超过这个范围的物体会被移除世界
        """
        self.__space.damping = 0

    def registerObject(self, object: GameObject):
        """
        注册游戏对象
        """
        if object.key in self.__objects:
            return
        self.__objects[object.key] = object
        object.setBody(self.space)
        object.onEntered()
        GlobalEvents.GameObjectAdded(object)

    def removeObject(self, key: str):
        """
        移除游戏对象
        """
        if key not in self.__objects:
            return
        obj = self.__objects[key]
        self.__objects.pop(key)
        obj.removeBody(self.space)
        obj.onRemoved()

    def clearObjects(self):
        """
        清除所有游戏对象
        """
        temp: list[GameObject] = [obj for obj in self.__objects.values()]
        self.__objects.clear()

        for obj in temp:
            obj.removeBody(self.space)
            obj.onRemoved()

        logger.debug(f"所有游戏对象已被清除")

    def updateObjects(self, delta: float,physical : bool = True):
        """
        更新游戏对象
        """
        from game.operateable import Operateable

        for key in self.objects.values():
            if isinstance(key, Operateable):
                key.operate(delta)
        if physical:
            DETAIL_NUM = 8
            for i in range(DETAIL_NUM):
                self.__space.step(delta / DETAIL_NUM)

        for obj in self.__objects.values():
            obj.update(delta)

        if self.__spaceRegion is not None and physical:
            deleteList = [
                key
                for key in self.__objects
                if not self.__spaceRegion.collidepoint(self.__objects[key].body.position)
            ]
            for key in deleteList:
                self.removeObject(key)
                logger.debug(f"游戏物体 {key} 超出世界范围")

    def renderObjects(self, screen : Surface):
        """
        渲染游戏对象
        """
        copy = self.__objects.copy()
        for obj in copy.values():
            obj.render(screen)

    def getGameObjectByBody(self, body : Body) -> GameObject | None:
        """
        通过游戏刚体获取对应的游戏对象
        """
        for obj in self.__objects.values():
            if obj.body == body:
                return obj
        return None

    def getGameObjectsByPosition(self,pos : Vec2d,rad : float) -> Sequence[GameObject]:
        res = list[GameObject]()
        for obj in self.__objects.values():
            objPos : Vec2d = obj.body.position
            dis = ((objPos.x - pos.x) ** 2 + (objPos.y - pos.y) ** 2 ) ** 0.5
            if dis <= rad:
                res.append(obj)
        return res

    def containObject(self, object: GameObject) -> bool:
        """
        判断游戏对象是否在游戏世界中
        """
        return object in self.__objects.values()
