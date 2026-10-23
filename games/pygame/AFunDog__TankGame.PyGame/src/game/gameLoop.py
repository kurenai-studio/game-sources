import os
import sys
from loguru import logger
import pygame
from pygame import Surface, transform




# from game.defines import WINDOW_HEIGHT, WINDOW_WIDTH


from .events.eventManager import EventManager
from .keyPressedManager import KeyPressedManager
from .sceneManager import SceneManager

from pymunk.pygame_util import DrawOptions


FPS = 60


class GameLoop:

    isRunning: bool = False
    """游戏是否在运行中"""

    delta: float = 0
    """帧间隔"""

    fps: float = 0
    """FPS"""

    screen: Surface
    """绘制屏幕"""

    __debugOptions: DrawOptions

    def __init__(self):
        raise NotImplementedError("GameLoop是静态类不允许实例化")

    @staticmethod
    def __initGame():
        logger.info("初始化游戏")

        # 初始化 pygame
        pygame.init()
        pygame.mixer.init()

        # 初始化游戏屏幕
        from game.defines import WINDOW_HEIGHT, WINDOW_WIDTH,WINDOW_TITLE
        GameLoop.screen = pygame.display.set_mode(
            (WINDOW_WIDTH, WINDOW_HEIGHT), pygame.DOUBLEBUF | pygame.HWSURFACE
        )
        # 初始化场景
        SceneManager.init()

        pygame.display.set_caption(WINDOW_TITLE)
        pygame.display.set_icon(pygame.image.load("assets/icon.png"))

        GameLoop.__debugOptions = DrawOptions(GameLoop.screen)

        logger.success("游戏初始化完毕")


    @staticmethod
    def run():
        """
        开始游戏循环
        """

        if GameLoop.isRunning:
            return
        GameLoop.isRunning = True

        # 配置基础环境

        # 开始初始化
        GameLoop.__initGame()

        # 初始化游戏时钟
        clock = pygame.time.Clock()
        # pygame.time.set_timer(pygame.USEREVENT, 1000)
        preTicks = 0
        from game.defines import BACKGROUND, FONT_COLOR, MEDIAN_FONT, SMALL_FONT

        while GameLoop.isRunning:

            GameLoop.fps = clock.get_fps()
            # delta 统一以s为单位的小数
            GameLoop.delta = (pygame.time.get_ticks() - preTicks) / 1000
            preTicks = pygame.time.get_ticks()

            GameLoop.__handleEvent()
            if not GameLoop.isRunning:
                break

            # OnlineManager.checkConnection()
            EventManager.updateTimer(GameLoop.delta)
            SceneManager.getCurrentScene().update(GameLoop.delta)

            GameLoop.screen.fill(BACKGROUND)

            sceneUI = SceneManager.getCurrentScene().ui
            GameLoop.screen.blit(sceneUI, sceneUI.get_rect(center=GameLoop.screen.get_rect().center))
            SceneManager.getCurrentScene().render(GameLoop.screen)

            # if (gameObjectManager := SceneManager.getCurrentScene().gameObjectManager) is not None:
            #     gameObjectManager.space.debug_draw(GameLoop.__debugOptions)



            # debug
            # FPS
            SMALL_FONT.render_to(GameLoop.screen, (0, 0), f"FPS: {GameLoop.fps:.2f}", FONT_COLOR)
            # delta
            SMALL_FONT.render_to(
                GameLoop.screen, (0, 24), f"delta: {GameLoop.delta * 1000:.1f}ms", FONT_COLOR
            )

            pygame.display.update()

            clock.tick(FPS)

        GameLoop.__onGameQuit()
        pygame.quit()
        logger.info("游戏退出")

    @staticmethod
    def __handleEvent():
        events = pygame.event.get()
        for event in events:
            # logger.debug(f"接收事件 {event.type}")
            EventManager.handleEvent(event)
            KeyPressedManager.processKeyPressed(event)
            SceneManager.getCurrentScene().process(event)
            match event.type:
                case pygame.QUIT:
                    GameLoop.isRunning = False
                case _:
                    # 处理剩余的事件
                    ...

    @staticmethod
    def __onGameQuit():
        from online.onlineManager import OnlineManager

        OnlineManager.close()
