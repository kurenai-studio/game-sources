from abc import ABC, abstractmethod
import math
from random import randint
import random
from typing import Any, Callable, Sequence
from loguru import logger
from pygame import K_DOWN, K_ESCAPE, KEYDOWN, KEYUP, QUIT, Rect, Surface
import pygame
from pygame import transform
from pygame.event import Event
from pygame.freetype import Font
from pymunk import Space

# from game.gameLoop import GameLoop
from game import tank
from game.controls.floatMenu import FloatMenu
from game.controls.selectionControl import Selection, SelectionControl
from game.defines import (
    BACKGROUND,
    FLOATMENU_HEIGHT,
    FLOATMENU_WIDTH,
    FONT_COLOR,
    MEDIAN_FONT,
    ONLINE_KEYDOWN_EVENT_TYPE,
    ONLINE_KEYUP_EVENT_TYPE,
    SELECTION_HEIGHT,
    WINDOW_HEIGHT,
    WINDOW_WIDTH,
)
from game.events.eventDelegate import EventDelegate
from game.events.globalEvents import GlobalEvents
from game.events.timerManager import Timer
from game.gameObject import GameObject, GameObjectData, GameObjectFactory
from game.operateable import Operateable, Operation
from game.sceneManager import SCENE_TYPE, SceneManager
from game.spaces.gameObjectSpace import GAMEOBJECT_SPACE_TYPE, GameObjectSpace
from game.events.eventManager import EventManager
from game.gameItemManager import GameItemManager
from game.gameMap import (
    MAP_MAX_HEIGHT,
    MAP_MAX_WIDTH,
    MAP_MIN_HEIGHT,
    MAP_MIN_WIDTH,
    MARGIN_X,
    MARGIN_Y,
    PLOT_HEIGHT,
    PLOT_WIDTH,
    GameMap,
    GameMapData,
)
from game.scenes.scene import Scene
from game.tank import TANK_REMOVED_EVENT_TYPE, TANK_COLOR, Tank, TankData
from game.weapons.weaponFactory import WEAPON_TYPE
from online.onlineData import ConfirmOnlineData, GameUpdateData
from online.onlineManager import OnlineManager

SCORE_UI_HEIGHT = 192

# TODO 继续完成
# FIXME 子弹射到视图外，为留下痕迹


class ClientGameScene(Scene):

    __gameObjectSpace: GameObjectSpace

    __ui: Surface
    __gameUI: Surface
    __scoreUI: Surface
    __gameMenu: FloatMenu

    @property
    def ui(self):
        return self.__ui

    @property
    def gameObjectSpace(self):
        return self.__gameObjectSpace

    def __init__(self):
        logger.info("游戏场景初始化")

        self.GameLoaded = EventDelegate[None]("游戏加载完毕")

        self.__gameObjectSpace = GameObjectSpace()
        # self.__existObjects = dict[str,int]()
        self.registerEvents()

        self.__gameUI = pygame.Surface(
            (
                WINDOW_WIDTH,
                WINDOW_HEIGHT - SCORE_UI_HEIGHT,
            )
        )
        self.__scoreUI = pygame.Surface((WINDOW_WIDTH, SCORE_UI_HEIGHT))
        self.__ui = pygame.Surface((WINDOW_WIDTH, WINDOW_HEIGHT))
        self.__gameMenu = FloatMenu(
            self.__ui,
            FLOATMENU_WIDTH,
            480,
            SelectionControl(
                FLOATMENU_WIDTH,
                480,
                [
                    Selection(
                        lambda: "返回主菜单",
                        SELECTION_HEIGHT,
                        lambda: SceneManager.changeScene(SCENE_TYPE.START_SCENE),
                    ),
                    Selection(
                        lambda: "退出游戏",
                        SELECTION_HEIGHT,
                        lambda: EventManager.raiseEventType(QUIT),
                    ),
                ],
            ),
        )

        self.__scores = dict[str, int]()
        # self.__isScoreChanged = False
        # self.__updateDataTimer = Timer(self.__onUpdateData, 500)
        # self.__updateDataTimer.callBack()
        self.__updateDataTimer = Timer(
            lambda: OnlineManager.sendData(ConfirmOnlineData(True)), 500
        )
        self.__updateDataTimer.callBack()

        OnlineManager.GameObjectChanged += self.__onGameObjectChanged

    def registerEvents(self):
        GlobalEvents.GameObjectAdding += self.__onGameObjectAdding
        # GlobalEvents.GameObjectAdded += self.__onGameObjectAdded
        GlobalEvents.GameObjectRemoving += self.__onGameObjectRemoving
        GlobalEvents.GameObjectsClearing += self.__onGameObjectClearing
        GlobalEvents.GameScoreUpdated += self.__onGameScoreUpdated
        # EventManager.addHandler(GAME_OBJECT_ADD_EVENT_TYPE,self.__onGameObjectAdded)
        # EventManager.addHandler(GAME_OBJECT_REMOVE_EVENT_TYPE,self.__onGameObjectRemoved)
        # EventManager.addHandler(GAME_OBJECT_CLEAR_EVENT_TYPE,self.__onClearGameObject)

    def unregisterEvents(self):
        self.GameLoaded.clear()
        GlobalEvents.GameObjectAdding.clear()
        # GlobalEvents.GameObjectAdded.clear()
        GlobalEvents.GameObjectRemoving.clear()
        GlobalEvents.GameObjectsClearing.clear()

        GlobalEvents.GameScoreUpdated.clear()
        # EventManager.removeHandler(GAME_OBJECT_ADD_EVENT_TYPE)
        # EventManager.removeHandler(GAME_OBJECT_REMOVE_EVENT_TYPE)
        # EventManager.removeHandler(GAME_OBJECT_CLEAR_EVENT_TYPE)

    def __onUpdateData(self):
        # OnlineManager.sendData(ConfirmOnlineData(True))
        ...

    def __onGameScoreUpdated(self, scores: dict[str, int]):
        self.__scores = scores
        # logger.debug(f"更新得分 {self.__scores}")

    def __onGameObjectChanged(self, key: str, data: GameObjectData):
        # self.__existObjects[key] = 0
        if key in self.__gameObjectSpace.objects:
            self.__gameObjectSpace.objects[key].setData(data)
        else:
            logger.debug(f"{key} 该游戏对象不存在 重新创建")
            self.__gameObjectSpace.registerObject(GameObjectFactory.create(key, data))
            

    def __onGameObjectAdding(self, key: str, data: GameObjectData):
        logger.debug(f"{key} adding")
        self.__gameObjectSpace.registerObject(GameObjectFactory.create(key, data))
        # self.__existObjects[key] = 0

    # def __onGameObjectAdded(self, obj: GameObject):
    #     if isinstance(obj, Tank):
    #         obj.Removed += self.__onTankRemoved
    #         self.__tanks.add(obj)

    # def __onTankRemoved(self, obj: GameObject):
    #     assert isinstance(obj, Tank)
    #     self.__tanks.discard(obj)

    def __onGameObjectRemoving(self, key: str):
        logger.debug(f"{key} removing")
        # if key in self.__existObjects:
        #     self.__existObjects.pop(key)
        if key in self.__gameObjectSpace.objects:
            self.__gameObjectSpace.removeObject(key)
        else:
            logger.warning(f"对象{key}不存在 删除操作无效")

    def __onGameObjectClearing(self, _: None):
        self.__gameObjectSpace.clearObjects()

    def startNewTurn(self) -> bool:
        """
        开始新一轮游戏
        返回值False则代表开始最后一轮，之后不在重新开始
        """
        GlobalEvents.GameObjectsClearing(None)
        gameMapData = self.generateMapData()

        # 决定渲染顺序
        GlobalEvents.GameObjectAdding("GameMap", gameMapData)

        return True

    def generateMapData(self) -> GameMapData:
        # 地图初始化
        width = randint(MAP_MIN_WIDTH // 2, MAP_MAX_WIDTH // 2) * 2 + 1
        height = randint(MAP_MIN_HEIGHT // 2, MAP_MAX_HEIGHT // 2) * 2 + 1
        return GameMapData(width, height)

    def process(self, event: Event):
        if self.__gameMenu.isMenuShow:
            self.__gameMenu.process(event)
            if self.__gameMenu.isMenuShow is False:
                return

        if event.type == KEYDOWN:
            if event.key == K_ESCAPE:
                if self.__gameMenu.isMenuShow is False:
                    self.__gameMenu.show()
        self.__trySendKeyEvent(event)

    def update(self, delta: float):

        # self.__gameObjectSpace.updateObjects(delta,False)
        # for key in self.__existObjects:
        #     self.__existObjects[key] += 1

        # delKeys = [key for key in self.__existObjects if self.__existObjects[key] > 10]
        # for key in delKeys:
        #     self.__existObjects.pop(key)
        #     self.__onGameObjectRemoving(key)

        # 更新画面
        self.updateGameMap(delta)
        self.__ui.blit(
            self.__gameUI,
            (0, 0),
        )
        self.updateScoreBoard(delta)
        self.__ui.blit(self.__scoreUI, (0, WINDOW_HEIGHT - self.__scoreUI.get_height()))
        self.updateGameMenu(delta)

        self.__updateDataTimer.update(delta)
        OnlineManager.tryUpdateData()

    def updateGameMap(self, delta: float):
        self.__gameUI.fill(BACKGROUND)
        self.__gameObjectSpace.renderObjects(self.__gameUI)

    def updateScoreBoard(self, delta: float):
        # if self.__isScoreChanged is False:
        #     return
        for key in self.__scores:
            if key not in self.__gameObjectSpace.objects:
                return

        self.__scoreUI.fill(BACKGROUND)

        SCORE_PART_WIDTH = 320

        basePoint = ((self.__scoreUI.get_width() - SCORE_PART_WIDTH * len(self.__scores)) / 2, 36)
        for i, key in enumerate(self.__scores):
            if key in self.__gameObjectSpace.objects:
                self.__scoreUI.blit(
                    self.__gameObjectSpace.objects[key].surface,
                    (basePoint[0] + i * SCORE_PART_WIDTH, basePoint[1]),
                )
                self.__scoreUI.blit(
                    MEDIAN_FONT.render(f"{self.__scores[key]}", FONT_COLOR)[0],
                    (basePoint[0] + 100 + i * SCORE_PART_WIDTH, basePoint[1]),
                )
            # else:
            #     self.__isScoreChanged = True

    def updateGameMenu(self, delta: float):
        self.__gameMenu.update(delta)
        if self.__gameMenu.isMenuShow and not EventManager.isTimerPaused():
            EventManager.pauseTimer()
        elif not self.__gameMenu.isMenuShow and EventManager.isTimerPaused():
            EventManager.resumeTimer()

    def onEntered(self):
        # EventManager.addHandler(TANK_REMOVED_EVENT_TYPE, self.onTankRemoved)
        ...

    def onLeaved(self):
        # EventManager.removeHandler(TANK_REMOVED_EVENT_TYPE, self.onTankRemoved)
        self.unregisterEvents()
        self.gameObjectSpace.clearObjects()

    def __trySendKeyEvent(self, event: Event):
        if OnlineManager.isConnected() and OnlineManager.isClient():
            if event.type == KEYDOWN:
                OnlineManager.sendEvent(ONLINE_KEYDOWN_EVENT_TYPE, {"key": event.key})
            elif event.type == KEYUP:
                OnlineManager.sendEvent(ONLINE_KEYUP_EVENT_TYPE, {"key": event.key})
