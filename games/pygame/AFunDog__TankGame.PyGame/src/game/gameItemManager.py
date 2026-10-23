from typing import Callable

from loguru import logger

from game.events.delegate import Delegate
from game.events.timerManager import Timer, TimerManager

from .events.globalEvents import GlobalEvents
from .gameObject import GameObject, GameObjectData
from .gameItems.fragmentWeaponGameItem import FragmentWeaponGameItemData
from .gameItems.remoteControlMissileGameItem import (
    RemoteControlMissileGameItemData,
)
from .gameItems.gameItem import GameItem
from .gameItems.ghostWeaponGameItem import GhostWeaponGameItemData
from .gameMap import MAP_PLOT_TYPE, GameMap
import random



class GameItemManager:

    @property
    def gameMap(self):
        return self.__gameMap

    @property
    def gameItems(self):
        return self.__gameItems

    def __init__(self, gameMap: GameMap,timerManager : TimerManager):
        self.__gameMap = gameMap
        self.__timerManager = timerManager
        self.__gameItems: list[GameItem] = []
        self.__gameItemCount: int = 0
        self.__isStarted: bool = False
        self.__genTimer: Timer | None = None

        self.GameItemGenerated = Delegate[GameObjectData](f"游戏物品生成")
        self.GameItemGenerated += self.__onGameItemGenerated

    def startGenerate(self):
        if self.__isStarted:
            return
        self.__isStarted = True
        GlobalEvents.GameObjectAdded += self.__onGameObjectAdded
        self.__genTimer = self.GameItemGenerated.createTimer(
            5000, 1, self.__generateRandomItemData()
        )
        self.__timerManager.setTimer(self.__genTimer)

    def cancelGenerate(self):
        self.__isStarted = False
        GlobalEvents.GameObjectAdded -= self.__onGameObjectAdded
        if self.__genTimer is not None:
            self.__genTimer.cancel()
            self.__genTimer = None

    def __onGameItemGenerated(self, data: GameObjectData):
        GlobalEvents.GameObjectAdding(f"GameItem_{self.__gameItemCount}", data)
        self.__gameItemCount += 1

    def __onGameObjectAdded(self, obj: GameObject):
        from online.onlineManager import OnlineManager
        if isinstance(obj, GameItem):
            if OnlineManager.isConnected() and OnlineManager.isClient():
                return
            self.__gameItems.append(obj)
            obj.Removed += self.__onGameItemRemoved
            self.__genTimer = self.GameItemGenerated.createTimer(
                5000 + len(self.__gameItems) * 5000, 1, self.__generateRandomItemData()
            )
            self.__timerManager.setTimer(self.__genTimer)

    def __generateRandomItemData(self) -> GameObjectData:
        # 生成不会重复，且不在墙面上的物品位置
        # mapX mapY : 地图上的格子位置
        # x y : 实际坐标
        mapX, mapY = random.randint(0, self.__gameMap.width - 1), random.randint(
            0, self.__gameMap.height - 1
        )
        x, y = self.__gameMap.getPlotPos(mapX, mapY)
        samePosFilter: Callable[[GameItem], bool] = lambda it: it.mapX == mapX or it.mapY == mapY
        while self.__gameMap.map[mapX, mapY] == MAP_PLOT_TYPE.MAP_BLOCK or any(
            filter(samePosFilter, self.__gameItems)
        ):
            mapX, mapY = random.randint(0, self.__gameMap.width - 1), random.randint(
                0, self.__gameMap.height - 1
            )
            x, y = self.__gameMap.getPlotPos(mapX, mapY)

        x += random.uniform(-5, 5)
        y += random.uniform(-5, 5)
        logger.debug(f"生成游戏物品位置 {mapX} {mapY} {x} {y}")
        return random.choice(
            [
                FragmentWeaponGameItemData,
                GhostWeaponGameItemData,
                RemoteControlMissileGameItemData,
            ]
        )(mapX, mapY, x, y, random.uniform(-0.5, 0.5))

    def __onGameItemRemoved(self, obj: GameObject):
        assert isinstance(obj, GameItem)
        if obj in self.__gameItems:
            self.__gameItems.remove(obj)

    def reset(self, gameMap: GameMap):
        self.cancelGenerate()
        self.__gameItems.clear()
        self.__gameMap = gameMap
