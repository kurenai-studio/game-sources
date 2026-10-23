from typing import Callable, Optional

from loguru import logger
from pygame import (
    K_DOWN,
    K_KP_ENTER,
    K_LEFT,
    K_RETURN,
    K_RIGHT,
    K_UP,
    KEYDOWN,
    Rect,
    Surface,
    transform,
    gfxdraw,
)
from pygame.event import Event
from game.controls.control import Control
from game.defines import FONT_COLOR, MEDIAN_FONT
from utils.easingFunc import easeLinear


class Selection:

    __isEnabled: bool = True
    __content: Callable[[], str] | Control
    __height: float
    __enterAction: Callable[[], None] | None
    __leftAction: Callable[[], None] | None
    __rightAction: Callable[[], None] | None

    @property
    def isEnabled(self):
        return self.__isEnabled
    
    @isEnabled.setter
    def isEnabled(self, value: bool):
        self.__isEnabled = value

    @property
    def content(self):
        if isinstance(self.__content, Control):
            return self.__content
        return self.__content()

    @property
    def height(self):
        return self.__height

    @property
    def enterAction(self):
        return self.__enterAction

    @property
    def leftAction(self):
        return self.__leftAction

    @property
    def rightAction(self):
        return self.__rightAction

    def __init__(
        self,
        content: Callable[[], str] | Control,
        height: float | None = None,
        enterAction: Callable[[], None] | None = None,
        leftAction: Callable[[], None] | None = None,
        rightAction: Callable[[], None] | None = None,
    ):

        self.__content = content
        if height is None:
            assert isinstance(content, Control)
            self.__height = content.ui.get_height()
        else:
            self.__height = height
        self.__enterAction = enterAction
        self.__leftAction = leftAction
        self.__rightAction = rightAction


class SelectionControl(Control):

    __SELECT_SCALE = 1.2

    __SELECTION_SIGN_HEIGHT = 24

    __selectionControlUI: Surface

    __selections: list[Selection]
    __selectIndex: int = 0
    __selectionScale: list[float]

    @property
    def ui(self):
        return self.__selectionControlUI

    @property
    def selections(self):
        return self.__selections
    
    @property
    def selectIndex(self):
        return self.__selectIndex

    def __init__(
        self,
        width: float,
        height: float,
        selections: list[Selection],
    ):
        self.__selections = selections
        self.__selectionScale = [
            1 / SelectionControl.__SELECT_SCALE for _ in range(len(selections))
        ]
        self.__selectionControlUI = Surface((width, height)).convert_alpha()
        self.__selectionControlUI.fill((0, 0, 0, 0))
        self.update(0)

    def process(self, event: Event):
        select = self.__selections[self.__selectIndex]
        # logger.debug(f"{select.content}")
        if isinstance(select.content, Control):
            select.content.process(event)
        if event.type == KEYDOWN:
            if event.key == K_RETURN or event.key == K_KP_ENTER:
                if 0 <= self.__selectIndex <= len(self.__selections):
                    select = self.__selections[self.__selectIndex]
                    if select.enterAction is not None and select.isEnabled:
                        select.enterAction()
            elif event.key == K_LEFT:
                if 0 <= self.__selectIndex <= len(self.__selections):
                    select = self.__selections[self.__selectIndex]
                    if select.leftAction is not None and select.isEnabled:
                        select.leftAction()
            elif event.key == K_RIGHT:
                if 0 <= self.__selectIndex <= len(self.__selections):
                    select = self.__selections[self.__selectIndex]
                    if select.rightAction is not None and select.isEnabled:
                        select.rightAction()
            elif event.key == K_UP:
                self.__selectIndex = (self.__selectIndex - 1 + len(self.__selections)) % len(
                    self.__selections
                )
            elif event.key == K_DOWN:
                self.__selectIndex = (self.__selectIndex + 1) % len(self.__selections)

    def update(self, delta: float):

        nowTop : float = 96
        for i, select in enumerate(self.__selections):

            if self.__selectIndex == i:
                self.__selectionScale[i] = easeLinear(
                    16 * delta, self.__selectionScale[i], 1 + 0.02, 1
                )
            else:
                self.__selectionScale[i] = easeLinear(
                    16 * delta,
                    self.__selectionScale[i],
                    1 / SelectionControl.__SELECT_SCALE - 0.02,
                    1,
                )
            
            # 满足条件就更新画面
            if self.__selectIndex == i or self.__selectionScale[i] >= (
                1 / SelectionControl.__SELECT_SCALE
            ):
                if isinstance(select.content,Control):
                    select.content.update(delta)
                contentSurface = transform.smoothscale_by(
                    (
                        MEDIAN_FONT.render(select.content, FONT_COLOR)[0]
                        if isinstance(select.content, str)
                        else select.content.ui
                    ),
                    min(max(self.__selectionScale[i], 1 / SelectionControl.__SELECT_SCALE), 1),
                )
                basePoint = (
                    (self.__selectionControlUI.get_width() - contentSurface.get_width()) / 2,
                    nowTop,
                )
                self.__selectionControlUI.fill(
                    (0, 0, 0, 0),
                    Rect(
                        0,
                        basePoint[1],
                        self.__selectionControlUI.get_width(),
                        select.height,
                    ),
                )
                if not select.isEnabled:
                    contentSurface.set_alpha(128)
                self.__selectionControlUI.blit(contentSurface, basePoint)

                # 绘制选中三角形

                if self.__selectIndex == i:
                    rightPoint = (basePoint[0] - 16, basePoint[1] + contentSurface.get_height() / 2)
                    upPoint = (
                        rightPoint[0] - 16,
                        rightPoint[1] - SelectionControl.__SELECTION_SIGN_HEIGHT / 2,
                    )
                    downPoint = (
                        rightPoint[0] - 16,
                        rightPoint[1] + SelectionControl.__SELECTION_SIGN_HEIGHT / 2,
                    )
                    gfxdraw.filled_polygon(
                        self.__selectionControlUI, (rightPoint, upPoint, downPoint), FONT_COLOR
                    )
            nowTop += select.height



# TODO 实现能滚动的选择控件
