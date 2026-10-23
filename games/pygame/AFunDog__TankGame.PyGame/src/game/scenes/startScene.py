import cProfile
from email.mime import base
from mimetypes import suffix_map
from select import select
from time import sleep
from typing import Any, Callable
from loguru import logger
from pygame import (
    K_DOWN,
    K_ESCAPE,
    K_KP_ENTER,
    K_RETURN,
    K_SPACE,
    K_UP,
    KEYDOWN,
    KSCAN_KP_ENTER,
    Rect,
    Surface,
    gfxdraw,
)
import pygame
from pygame.freetype import Font
from pygame.event import Event
from pymunk import Space
from pygame import image, transform
from game.controls.floatMenu import FloatMenu
from game.controls.selectionControl import Selection, SelectionControl
from game.controls.textbox import TextBox
from game.defines import (
    BACKGROUND,
    FLOATMENU_HEIGHT,
    FLOATMENU_WIDTH,
    FONT_COLOR,
    LARGE_TITLE_FONT,
    SELECTION_HEIGHT,
    WINDOW_HEIGHT,
    WINDOW_WIDTH,
)
from game.events.eventManager import EventManager

from game.gameSettings import GlobalSettingsManager

from game.scenes.gameScene import GameSceneConfig
from game.scenes.scene import Scene
from game.spaces.gameObjectSpace import GAMEOBJECT_SPACE_TYPE, GameObjectSpace
from online.onlineManager import OnlineManager


class StartScene(Scene):

    __ui: Surface
    __background: Surface
    __title: Surface
    # __settingMenu: Surface

    __selectionContorl: SelectionControl

    __SELECT_HEIGHT = 72

    @property
    def ui(self) -> Surface:
        return self.__ui

    def __init__(self):

        def __onLocalGameEnter():
            self.__startGameMenu.show()
            # SceneManager.changeScene(SCENE_TYPE.GAME_SCENE)

        def __onCreateServerEnter():
            self.__createServerMenu.show()

        def __onConnectServerEnter():
            self.__connectServerMenu.show()

        def __onSettingEnter():
            self.__settingMenu.show()

        def __onExitGameEnter():
            EventManager.raiseEventType(pygame.QUIT)

        selections = [
            Selection(lambda: "本地游戏", SELECTION_HEIGHT, __onLocalGameEnter),
            Selection(lambda: "创建服务器", SELECTION_HEIGHT, __onCreateServerEnter),
            Selection(lambda: "连接服务器", SELECTION_HEIGHT, __onConnectServerEnter),
            Selection(lambda: "设置", SELECTION_HEIGHT, __onSettingEnter),
            Selection(lambda: "退出游戏", SELECTION_HEIGHT, __onExitGameEnter),
        ]
        self.__ui = Surface((WINDOW_WIDTH, WINDOW_HEIGHT))

        img = image.load("assets/background.png").convert_alpha()
        self.__background = transform.smoothscale_by(
            img, (self.__ui.get_width() + 108) / img.get_width()
        )
        self.__title = LARGE_TITLE_FONT.render("坦 克 动 荡", FONT_COLOR)[0]
        self.__selectionContorl = SelectionControl(
            self.__ui.get_width(),
            StartScene.__SELECT_HEIGHT * len(selections) + 108,
            selections,
        )

        self.__initStartGameMenu()
        self.__initSettingMenu()
        self.__initCreaterServerMenu()
        self.__initConnectServerMenu()

        logger.success("主菜单场景初始化完成")

    def __initStartGameMenu(self):
        from game.sceneManager import SCENE_TYPE, SceneManager

        self.__startGameMenu = FloatMenu(
            self.__ui,
            FLOATMENU_WIDTH,
            FLOATMENU_HEIGHT,
            SelectionControl(
                FLOATMENU_WIDTH,
                FLOATMENU_HEIGHT,
                [
                    Selection(
                        lambda: "玩家 vs 玩家",
                        SELECTION_HEIGHT,
                        lambda: SceneManager.changeScene(
                            SCENE_TYPE.GAME_SCENE, True, GameSceneConfig(2, 0)
                        ),
                    ),
                    Selection(
                        lambda: "玩家 vs AI",
                        SELECTION_HEIGHT,
                        lambda: SceneManager.changeScene(
                            SCENE_TYPE.GAME_SCENE, True, GameSceneConfig(1, 1)
                        ),
                    ),
                    Selection(
                        lambda: "玩家 vs 玩家 vs AI",
                        SELECTION_HEIGHT,
                        lambda: SceneManager.changeScene(
                            SCENE_TYPE.GAME_SCENE, True, GameSceneConfig(2, 1)
                        ),
                    ),
                ],
            ),
        )

    def __initSettingMenu(self):

        def __downTankSpeed():
            GlobalSettingsManager.getGameSettings().tankSpeed = max(
                100, GlobalSettingsManager.getGameSettings().tankSpeed - 50
            )

        def __upTankSpeed():
            GlobalSettingsManager.getGameSettings().tankSpeed = min(
                2000, GlobalSettingsManager.getGameSettings().tankSpeed + 50
            )

        def __downBulletSpeed():
            GlobalSettingsManager.getGameSettings().commonBulletSpeed = max(
                50, GlobalSettingsManager.getGameSettings().commonBulletSpeed - 50
            )

        def __upBulletSpeed():
            GlobalSettingsManager.getGameSettings().commonBulletSpeed = min(
                1000, GlobalSettingsManager.getGameSettings().commonBulletSpeed + 50
            )

        def __downGhostBulletSpeed():
            GlobalSettingsManager.getGameSettings().ghostBulletSpeed = max(
                50, GlobalSettingsManager.getGameSettings().ghostBulletSpeed - 50
            )

        def __upGhostBulletSpeed():
            GlobalSettingsManager.getGameSettings().ghostBulletSpeed = min(
                1000, GlobalSettingsManager.getGameSettings().ghostBulletSpeed + 50
            )

        def __downGhostSpeedIncreaseRate():
            GlobalSettingsManager.getGameSettings().ghostSpeedIncreaseRate = max(
                0, GlobalSettingsManager.getGameSettings().ghostSpeedIncreaseRate - 0.002
            )

        def __upGhostSpeedIncreaseRate():
            GlobalSettingsManager.getGameSettings().ghostSpeedIncreaseRate = min(
                1, GlobalSettingsManager.getGameSettings().ghostSpeedIncreaseRate + 0.002
            )

        def __downMissileSpeed():
            GlobalSettingsManager.getGameSettings().missileSpeed = max(
                50, GlobalSettingsManager.getGameSettings().missileSpeed - 50
            )

        def __upMissileSpeed():
            GlobalSettingsManager.getGameSettings().missileSpeed = min(
                1000, GlobalSettingsManager.getGameSettings().missileSpeed + 50
            )

        self.__settingMenu = FloatMenu(
            self.__ui,
            FLOATMENU_WIDTH,
            FLOATMENU_HEIGHT,
            SelectionControl(
                FLOATMENU_WIDTH,
                FLOATMENU_HEIGHT,
                [
                    Selection(lambda: "坦克速度与子弹速度并不等价", SELECTION_HEIGHT, lambda: None),
                    Selection(
                        lambda: "坦克移动速度 {}".format(
                            GlobalSettingsManager.getGameSettings().tankSpeed
                        ),
                        SELECTION_HEIGHT,
                        lambda: None,
                        __downTankSpeed,
                        __upTankSpeed,
                    ),
                    Selection(
                        lambda: "子弹速度 {}".format(
                            GlobalSettingsManager.getGameSettings().commonBulletSpeed
                        ),
                        SELECTION_HEIGHT,
                        lambda: None,
                        __downBulletSpeed,
                        __upBulletSpeed,
                    ),
                    Selection(
                        lambda: "幽灵子弹速度 {}".format(
                            GlobalSettingsManager.getGameSettings().ghostBulletSpeed
                        ),
                        SELECTION_HEIGHT,
                        lambda: None,
                        __downGhostBulletSpeed,
                        __upGhostBulletSpeed,
                    ),
                    Selection(
                        lambda: "幽灵子弹速度增长率 {0:.2f}".format(
                            GlobalSettingsManager.getGameSettings().ghostSpeedIncreaseRate * 100
                        ),
                        SELECTION_HEIGHT,
                        lambda: None,
                        __downGhostSpeedIncreaseRate,
                        __upGhostSpeedIncreaseRate,
                    ),
                    Selection(
                        lambda: "导弹速度 {}".format(
                            GlobalSettingsManager.getGameSettings().missileSpeed
                        ),
                        SELECTION_HEIGHT,
                        lambda: None,
                        __downMissileSpeed,
                        __upMissileSpeed,
                    ),
                ],
            ),
        )

    def __initCreaterServerMenu(self):
        portTextBox = TextBox("port", "8900")


        def __createServer():
            try:
                host = "0.0.0.0"
                port = int(portTextBox.text)
                OnlineManager.createServer(host, port)
            except Exception as e:
                logger.exception(e)
                return

        self.__createServerMenu = FloatMenu(
            self.__ui,
            FLOATMENU_WIDTH,
            FLOATMENU_HEIGHT,
            SelectionControl(
                1280,
                960,
                [
                    Selection(portTextBox, SELECTION_HEIGHT),
                    Selection(lambda: "创建服务器", SELECTION_HEIGHT, __createServer),
                ],
            ),
        )

    def __initConnectServerMenu(self):
        hostTextBox = TextBox("host")
        portTextBox = TextBox("port", "8900")

        def __connectServer():

            def __onConnected(_ :None):
                from ..sceneManager import SceneManager,SCENE_TYPE
                OnlineManager.ConnectionStarted -= __onConnected
                SceneManager.changeScene(SCENE_TYPE.CLIENT_GAME_SCENE, False)

            try:
                host = hostTextBox.text
                port = int(portTextBox.text)
                OnlineManager.ConnectionStarted += __onConnected
                OnlineManager.connectServer(host, port)
            except Exception as e:
                logger.exception(e)

            

        self.__connectServerMenu = FloatMenu(
            self.ui,
            FLOATMENU_WIDTH,
            FLOATMENU_HEIGHT,
            SelectionControl(
                FLOATMENU_WIDTH,
                FLOATMENU_HEIGHT,
                [
                    Selection(hostTextBox, SELECTION_HEIGHT),
                    Selection(portTextBox, SELECTION_HEIGHT),
                    Selection(lambda: "连接服务器", SELECTION_HEIGHT, __connectServer),
                ],
            ),
        )

    def process(self, event: Event):
        if self.__startGameMenu.isMenuShow:
            self.__startGameMenu.process(event)
            return
        if self.__settingMenu.isMenuShow:
            self.__settingMenu.process(event)
            return
        if self.__createServerMenu.isMenuShow:
            self.__createServerMenu.process(event)
            return
        if self.__connectServerMenu.isMenuShow:
            self.__connectServerMenu.process(event)
            return
        self.__selectionContorl.process(event)

    def update(self, delta: float):
        self.__ui.fill(BACKGROUND)
        self.__ui.blit(
            self.__background, self.__background.get_rect(center=self.__ui.get_rect().center)
        )

        self.__ui.blit(self.__title, ((self.ui.get_width() - self.__title.get_width()) / 2, 48))
        self.__updateSelection(delta)
        self.__updateMenus(delta)

    def __updateSelection(self, delta: float):
        self.__selectionContorl.update(delta)

        self.__ui.blit(
            self.__selectionContorl.ui,
            (
                (self.__ui.get_width() - self.__selectionContorl.ui.get_width()) / 2,
                self.__title.get_height() + 108,
            ),
        )

    def __updateMenus(self, delta: float):
        self.__startGameMenu.update(delta)
        self.__settingMenu.update(delta)
        self.__createServerMenu.update(delta)
        self.__connectServerMenu.update(delta)
