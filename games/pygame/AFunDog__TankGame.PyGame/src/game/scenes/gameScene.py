from abc import ABC, abstractmethod
import math
import random
from typing import Any, Callable, Literal, Sequence
from loguru import logger
from pygame import K_DOWN, K_ESCAPE, KEYDOWN, KEYUP, QUIT, K_b, K_w, Rect, Surface
import pygame
from pygame import transform
from pygame.event import Event
from pygame.freetype import Font
from pymunk import Space

# from game.gameLoop import GameLoop
from game import tank
from game.ai import AI
from game.controls.floatMenu import FloatMenu
from game.controls.selectionControl import Selection, SelectionControl
from game.controls.textbox import TextBox
from game.defines import (
    BACKGROUND,
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
from game.events.timerManager import TimerManager
from game.gameLoop import GameLoop
from game.gameObject import GameObject, GameObjectData, GameObjectFactory
from game.keyPressedManager import KEY_PRESS_TYPE
from game.operateable import Operateable, Operation
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
from online.onlineData import GameUpdateData
from pymunk.pygame_util import DrawOptions


SPACE_DEBUG = False

SCORE_UI_HEIGHT = 192


class GameSceneConfig:
    def __init__(self, playerNum: Literal[1, 2], aiNum: Literal[0, 1]):
        self.playerNum = playerNum
        self.aiNum = aiNum


class GameScene(Scene):

    __gameObjectSpace: GameObjectSpace
    __gameItemManager: GameItemManager | None = None

    __gameMap: GameMap

    __ui: Surface
    __gameUI: Surface
    __scoreUI: Surface
    __gameMenu: FloatMenu

    # __redTank: Tank
    # __greenTank: Tank

    __isLoaded: bool = False
    __isGameOver: bool = False
    __isScoreChanged: bool = True

    GameOvered: EventDelegate[None]
    GameLoaded: EventDelegate[None]

    @property
    def ui(self):
        return self.__ui

    @property
    def gameMap(self):
        return self.__gameMap

    @gameMap.setter
    def gameMap(self, value: GameMap):
        self.__gameMap = value

    @property
    def gameObjectSpace(self):
        return self.__gameObjectSpace

    @property
    def gameItemManager(self):
        return self.__gameItemManager

    def __init__(self, config: GameSceneConfig):
        logger.info("游戏场景初始化")

        self.GameLoaded = EventDelegate[None]("游戏加载完毕")
        self.GameOvered = EventDelegate[None]("本轮游戏结束")

        self.__config = config
        self.__tanks = list[Tank]()
        self.__scores = [0 for i in range(self.__config.aiNum + self.__config.playerNum)]
        self.__timerManager = TimerManager()
        self.__gameObjectSpace = GameObjectSpace()
        self.registerEvents()

        self.__gameUI = pygame.Surface(
            (
                WINDOW_WIDTH,
                WINDOW_HEIGHT - SCORE_UI_HEIGHT,
            )
        )
        self.__scoreUI = pygame.Surface((WINDOW_WIDTH, SCORE_UI_HEIGHT))
        self.__ui = pygame.Surface((WINDOW_WIDTH, WINDOW_HEIGHT))

        self.__initGameMenu()
        self.__initGameMap()


        self.__ai: AI | None = None

        if SPACE_DEBUG:
            self.__debug = DrawOptions(self.__ui)

        self.__sendDataCount = 0

    def registerEvents(self):
        self.GameOvered += self.__onGameOvered
        self.GameLoaded += self.__onGameLoaded
        GlobalEvents.GameObjectAdding += self.__onGameObjectAdding
        GlobalEvents.GameObjectAdded += self.__onGameObjectAdded
        GlobalEvents.GameObjectRemoving += self.__onGameObjectRemoving
        GlobalEvents.GameObjectsClearing += self.__onGameObjectClearing
        # EventManager.addHandler(GAME_OBJECT_ADD_EVENT_TYPE,self.__onGameObjectAdded)
        # EventManager.addHandler(GAME_OBJECT_REMOVE_EVENT_TYPE,self.__onGameObjectRemoved)
        # EventManager.addHandler(GAME_OBJECT_CLEAR_EVENT_TYPE,self.__onClearGameObject)

    def unregisterEvents(self):
        self.GameOvered.clear()
        self.GameLoaded.clear()
        GlobalEvents.GameObjectAdding.clear()
        GlobalEvents.GameObjectAdded.clear()
        GlobalEvents.GameObjectRemoving.clear()
        GlobalEvents.GameObjectsClearing.clear()
        # EventManager.removeHandler(GAME_OBJECT_ADD_EVENT_TYPE)
        # EventManager.removeHandler(GAME_OBJECT_REMOVE_EVENT_TYPE)
        # EventManager.removeHandler(GAME_OBJECT_CLEAR_EVENT_TYPE)

    def __initGameMenu(self):
        from online.onlineManager import OnlineManager

        def __backToStart():
            from ..sceneManager import SceneManager, SCENE_TYPE

            SceneManager.changeScene(SCENE_TYPE.START_SCENE)

        portTextBox = TextBox("开放端口号", "8900")

        def __getOnlineInfo():
            if OnlineManager.isConnected():
                if OnlineManager.isServer():
                    return "已创建服务器"
                elif OnlineManager.isClient():
                    return "已连接服务器"
            return "创建局域网游戏"

        def __onConnected(_: None):
            # 发送初始数据
            datas = dict[str, GameObjectData]()
            for key in self.gameObjectSpace.objects:
                datas[key] = self.gameObjectSpace.objects[key].getData()
            socres = dict[str, int]()
            for i, tank in enumerate(self.__tanks):
                socres[tank.key] = self.__scores[i]
            # GlobalEvents.GameScoreUpdated(socres)
            # logger.info(f"发送初始数据 {datas}")
            OnlineManager.sendData(GameUpdateData(socres, datas))

            # OnlineManager.sendData(GameUpdateData(datas))

            p2Tank = self.gameObjectSpace.objects["P2Tank"]
            if isinstance(p2Tank, Tank):
                p2Tank.operation = Operation(
                    pygame.K_w,
                    pygame.K_s,
                    pygame.K_a,
                    pygame.K_d,
                    pygame.K_g,
                    KEY_PRESS_TYPE.ONLINE,
                )

        def __createServer():
            try:
                OnlineManager.ConnectionStarted += __onConnected
                OnlineManager.createServer("0.0.0.0", int(portTextBox.text))
            except Exception as e:
                logger.exception("创建服务器失败", e)

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
                        __backToStart,
                    ),
                    Selection(portTextBox, SELECTION_HEIGHT),
                    Selection(__getOnlineInfo, SELECTION_HEIGHT, __createServer),
                    Selection(
                        lambda: "退出游戏",
                        SELECTION_HEIGHT,
                        lambda: EventManager.raiseEventType(QUIT),
                    ),
                ],
            ),
        )

    def __gameMapAdded(self):
        if self.__gameItemManager is not None:
            self.__gameItemManager.reset(self.__gameMap)
        else:
            self.__gameItemManager = GameItemManager(self.__gameMap, self.__timerManager)
        if self.gameObjectSpace is not None:
            self.gameObjectSpace.spaceRegion = Rect(
                0, 0, self.__gameMap.surface.get_width(), self.__gameMap.surface.get_height()
            )
        # 随后加载坦克
        self.__initTanks()

    def __onGameObjectAdding(self, key: str, data: GameObjectData):
        self.__gameObjectSpace.registerObject(GameObjectFactory.create(key, data))

    def __onGameObjectAdded(self, obj: GameObject):
        if isinstance(obj, Tank):

            obj.Removed += self.__onTankRemoved
            if obj.key == "AITank":
                self.__ai = AI(obj, self.gameMap)
            self.__tanks.append(obj)
            if len(self.__tanks) == self.__config.aiNum + self.__config.playerNum:
                self.GameLoaded(None)

        elif isinstance(obj, GameMap):
            self.__gameMap = obj
            self.__gameMapAdded()

    def __onGameObjectRemoving(self, key: str):
        if key in self.__gameObjectSpace.objects:
            self.__gameObjectSpace.removeObject(key)
        else:
            logger.warning(f"对象{key}不存在 删除操作无效")

    def __onGameObjectClearing(self, _: None):
        self.__gameObjectSpace.clearObjects()

    def startNewTurn(self):
        """
        开始新一轮游戏
        """
        GlobalEvents.GameObjectsClearing(None)
        self.__initGameMap()

    def __initGameMap(self):
        # 地图初始化
        width = random.randint(MAP_MIN_WIDTH // 2, MAP_MAX_WIDTH // 2) * 2 + 1
        height = random.randint(MAP_MIN_HEIGHT // 2, MAP_MAX_HEIGHT // 2) * 2 + 1
        GlobalEvents.GameObjectAdding("GameMap", GameMapData(width, height))

    def __initTanks(self):
        from online.onlineManager import OnlineManager

        # 坦克初始化

        self.__tanks.clear()

        mapX, mapY = self.gameMap.getRandomEmptyMapPos()
        GlobalEvents.GameObjectAdding(
            "P1Tank",
            TankData(
                self.gameMap.getPlotPos(mapX, mapY)[0] + random.uniform(-5, 5),
                self.gameMap.getPlotPos(mapX, mapY)[1] + random.uniform(-5, 5),
                random.uniform(0, math.pi),
                TANK_COLOR.RED.value,
                Operation(pygame.K_w, pygame.K_s, pygame.K_a, pygame.K_d, pygame.K_g),
                WEAPON_TYPE.COMMON_WEAPON,
            ),
        )

        if self.__config.playerNum == 2:
            mapX, mapY = self.gameMap.getRandomEmptyMapPos()
            P2TankData = TankData(
                self.gameMap.getPlotPos(mapX, mapY)[0] + random.uniform(-5, 5),
                self.gameMap.getPlotPos(mapX, mapY)[1] + random.uniform(-5, 5),
                random.uniform(0, math.pi),
                TANK_COLOR.GREEN.value,
                Operation(pygame.K_UP, pygame.K_DOWN, pygame.K_LEFT, pygame.K_RIGHT, pygame.K_KP_0),
                WEAPON_TYPE.COMMON_WEAPON,
            )
            if OnlineManager.isConnected() and OnlineManager.isServer():
                P2TankData.operation = Operation(
                    pygame.K_w,
                    pygame.K_s,
                    pygame.K_a,
                    pygame.K_d,
                    pygame.K_g,
                    KEY_PRESS_TYPE.ONLINE,
                )
            GlobalEvents.GameObjectAdding("P2Tank", P2TankData)
        if self.__config.aiNum == 1:
            mapX, mapY = self.gameMap.getRandomEmptyMapPos()
            GlobalEvents.GameObjectAdding(
                "AITank",
                TankData(
                    self.gameMap.getPlotPos(mapX, mapY)[0] + random.uniform(-5, 5),
                    self.gameMap.getPlotPos(mapX, mapY)[1] + random.uniform(-5, 5),
                    random.uniform(0, math.pi),
                    (164, 164, 164),
                    None,
                    WEAPON_TYPE.COMMON_WEAPON,
                ),
            )

    def process(self, event: Event):
        if self.__gameMenu.isMenuShow:
            self.__gameMenu.process(event)
            if self.__gameMenu.isMenuShow is False:
                return

        if event.type == KEYDOWN:
            if event.key == K_ESCAPE:
                if self.__gameMenu.isMenuShow is False:
                    self.__gameMenu.show()

    def update(self, delta: float):
        from online.onlineManager import OnlineManager

        if self.__gameMenu.isMenuShow is False or OnlineManager.isConnected():
            self.__gameObjectSpace.updateObjects(delta)
            self.__timerManager.updateTimers(delta)
            if self.__ai is not None:
                self.__ai.update(delta)
            self.__trySendSceneData()
            # if self.__sendDataCount > 0:
            #     self.__trySendSceneData()
            #     self.__sendDataCount = 0
            # self.__sendDataCount += 1

        # 更新画面
        self.updateGameMap(delta)
        self.__ui.blit(
            self.__gameUI,
            (0, 0),
        )
        self.updateScoreBoard(delta)
        self.__ui.blit(self.__scoreUI, (0, WINDOW_HEIGHT - self.__scoreUI.get_height()))
        # debug
        if SPACE_DEBUG:
            self.gameObjectSpace.space.debug_draw(self.__debug)

        self.updateGameMenu(delta)

        OnlineManager.tryUpdateData()

    def updateGameMap(self, delta: float):
        if self.__isLoaded is False:
            return
        self.__gameUI.fill(BACKGROUND)
        self.__gameObjectSpace.renderObjects(self.__gameUI)

    def updateScoreBoard(self, delta: float):
        if self.__isLoaded is False or self.__isScoreChanged is False:
            return
            

        self.__scoreUI.fill(BACKGROUND)

        SCORE_PART_WIDTH = 320

        basePoint = ((self.__scoreUI.get_width() - SCORE_PART_WIDTH * len(self.__tanks)) / 2, 36)
        for i, tank in enumerate(self.__tanks):
            self.__scoreUI.blit(tank.surface, (basePoint[0] + i * SCORE_PART_WIDTH, basePoint[1]))
            self.__scoreUI.blit(
                MEDIAN_FONT.render(f"{self.__scores[i]}", FONT_COLOR)[0],
                (basePoint[0] + 100 + i * SCORE_PART_WIDTH, basePoint[1]),
            )

        self.__isScoreChanged = False

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
        if self.gameItemManager is not None:
            self.gameItemManager.cancelGenerate()

    def __trySendSceneData(self):
        from online.onlineManager import OnlineManager

        if OnlineManager.isConnected() and OnlineManager.isServer():
            datas = dict[str, GameObjectData]()
            for key in self.gameObjectSpace.objects:
                # # 排除地图更新数据
                # # 因为地图不每时每刻更新
                # if key == "GameMap":
                #     continue
                # if key.startswith("GameItem_"):
                #     continue
                datas[key] = self.gameObjectSpace.objects[key].getData()
            scores = dict[str, int]()
            for i, tank in enumerate(self.__tanks):
                scores[tank.key] = self.__scores[i]
            GlobalEvents.GameScoreUpdated(scores)
            OnlineManager.sendData(GameUpdateData(scores,datas))

    def __onGameOvered(self, _: None):
        existTankIndex = [i for i, tank in enumerate(self.__tanks) if tank.isExist]
        if len(existTankIndex) == 1:
            self.__scores[existTankIndex[0]] += 1

        self.__isScoreChanged = True

        self.startNewTurn()

    def __onGameLoaded(self, _: None):
        self.__isGameOver = False
        self.__isLoaded = True
        if self.gameItemManager is not None:
            self.gameItemManager.startGenerate()

    def __onTankRemoved(self, obj: GameObject):
        existTankCount = len([tank for tank in self.__tanks if tank.isExist])
        logger.debug(f"{existTankCount} {self.__isGameOver}")
        if not (existTankCount == 0 or existTankCount == 1):
            return
        if self.__isGameOver:
            return
        self.__isGameOver = True
        self.__timerManager.setTimer(self.GameOvered.createTimer(3000, 1, None))
