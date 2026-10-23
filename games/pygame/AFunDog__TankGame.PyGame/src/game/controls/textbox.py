from loguru import logger
from pygame import (
    K_0,
    K_1,
    K_2,
    K_3,
    K_4,
    K_5,
    K_6,
    K_7,
    K_8,
    K_9,
    K_BACKSPACE,
    K_ESCAPE,
    K_KP0,
    K_KP1,
    K_KP2,
    K_KP3,
    K_KP4,
    K_KP5,
    K_KP6,
    K_KP7,
    K_KP8,
    K_KP9,
    K_LESS,
    K_PERIOD,
    KEYDOWN,
    K_a,
    Surface,
)
from pygame.event import Event
from game.controls.control import Control
from game.defines import FONT_COLOR, MEDIAN_FONT


class TextBox(Control):

    __ui: Surface
    __label: str | None
    __text: str

    @property
    def ui(self):
        return self.__ui

    @property
    def label(self):
        return self.__label

    @label.setter
    def label(self, value: str | None):
        self.__label = value
        self.__updateUI()

    @property
    def text(self):
        return self.__text

    @text.setter
    def text(self, value: str):
        self.__text = value
        self.__updateUI()

    def __init__(self, label: str | None = None, text: str = ""):
        self.__label = label
        self.__text = text
        self.__updateUI()

    def process(self, event: Event):
        if event.type == KEYDOWN:
            if event.key == K_BACKSPACE:
                self.text = self.__text[:-1]
            elif event.key in [

                *[K_0 + i for i in range(10)],
                K_KP0,
                *[K_KP1 + i for i in range(9)],
                K_PERIOD,
                *[K_a + i for i in range(26)],
            ]:
                self.text += event.unicode

    def __updateUI(self):
        content: str
        if self.__label is None:
            content = self.__text
        else:
            content = f"{self.__label}: {self.__text}"

        self.__ui = MEDIAN_FONT.render(content, FONT_COLOR)[0]

    def update(self, delta: float): ...

