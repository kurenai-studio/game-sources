from enum import Enum
import math
from pygame.event import Event


class KEY_PRESS_TYPE(Enum):
    LOCAL = 0
    ONLINE = 1


class KeyPressedManager:

    __keyPressed = {KEY_PRESS_TYPE.LOCAL: set[int](), KEY_PRESS_TYPE.ONLINE: set[int]()}

    def __init__(self):
        raise NotImplementedError("KeyPressedManager类不允许实例化")

    @staticmethod
    def processKeyPressed(event: Event):
        from pygame import KEYDOWN, KEYUP
        from game.defines import ONLINE_KEYDOWN_EVENT_TYPE, ONLINE_KEYUP_EVENT_TYPE

        if event.type == KEYDOWN:
            KeyPressedManager.__keyPressed[KEY_PRESS_TYPE.LOCAL].add(event.key)
        elif event.type == KEYUP:
            KeyPressedManager.__keyPressed[KEY_PRESS_TYPE.LOCAL].discard(event.key)

        if event.type == ONLINE_KEYDOWN_EVENT_TYPE:
            KeyPressedManager.__keyPressed[KEY_PRESS_TYPE.ONLINE].add(event.key)
        elif event.type == ONLINE_KEYUP_EVENT_TYPE:
            KeyPressedManager.__keyPressed[KEY_PRESS_TYPE.ONLINE].discard(event.key)

    @staticmethod
    def isPressed(key: int, type: KEY_PRESS_TYPE = KEY_PRESS_TYPE.LOCAL):
        return key in KeyPressedManager.__keyPressed[type]
