from pygame.event import Event
from game.controls.control import Control
from pygame import K_ESCAPE, KEYDOWN, Surface
from pygame import Surface

from game.defines import MENU_BACKGROUND, MENU_ENV_BACKGROUND
from utils.easingFunc import easeLinear



class FloatMenu(Control):

    __targetUI: Surface
    __floatMenuUI: Surface
    __content: Control
    __envMask : Surface

    __isMenuShow: bool = False
    __menuBottom: float = -10
    __envMaskAlpha: int = 0

    @property
    def ui(self) -> Surface:
        return self.__floatMenuUI
    
    @property
    def isMenuShow(self):
        return self.__isMenuShow

    def __init__(self, targetUI: Surface, width: float, height: float, content: Control):
        self.__targetUI = targetUI
        self.__content = content

        self.__floatMenuUI = Surface((width, height))
        self.__floatMenuUI.fill(MENU_BACKGROUND)
        self.__envMask = Surface(targetUI.get_size()).convert_alpha()
        self.__envMask.fill(MENU_ENV_BACKGROUND)


    def process(self, event: Event):
        self.__content.process(event)
        if event.type == KEYDOWN:
            if event.key == K_ESCAPE:
                self.hide()

    def update(self, delta: float):
        self.__content.update(delta)

        if self.__isMenuShow:
            self.__menuBottom = easeLinear(
                8 * delta,
                self.__menuBottom,
                (self.__targetUI.get_height() + self.ui.get_height()) / 2,
                1,
            )
            self.__envMaskAlpha = int(easeLinear(8 * delta, self.__envMaskAlpha, 255, 1))
        else:
            self.__menuBottom = easeLinear(
                8 * delta,
                self.__menuBottom,
                -10,
                1,
            )
            self.__envMaskAlpha = int(easeLinear(8 * delta, self.__envMaskAlpha, -0.3, 1))

        if self.__menuBottom <= 0:
            return
    
        self.__floatMenuUI.fill(MENU_BACKGROUND)
        self.__envMask.set_alpha(self.__envMaskAlpha)
        self.__targetUI.blit(self.__envMask, (0, 0))

        self.__floatMenuUI.blit(
            self.__content.ui,
            (
                (self.__floatMenuUI.get_width() - self.__content.ui.get_width()) / 2,
                (self.__floatMenuUI.get_height() - self.__content.ui.get_height()) / 2,
            ),
        )
        self.__targetUI.blit(
            self.__floatMenuUI,
            (
                (self.__targetUI.get_width() - self.__floatMenuUI.get_width()) / 2,
                self.__menuBottom - self.__floatMenuUI.get_height(),
            ),
        )


    def show(self):
        self.__isMenuShow = True

    def hide(self):
        self.__isMenuShow = False