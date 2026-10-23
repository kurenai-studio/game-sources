from abc import ABC
from typing import final

from game.keyPressedManager import KEY_PRESS_TYPE


class Operation:



    def __init__(
        self,
        forwardKey: int,
        backKey: int,
        leftKey: int,
        rightKey: int,
        shootKey: int,
        type: KEY_PRESS_TYPE = KEY_PRESS_TYPE.LOCAL,
    ):
        self.forwardKey = forwardKey
        """前进按键"""
        self.backKey = backKey
        """后退按键"""
        self.leftKey = leftKey
        """左转按键"""
        self.rightKey = rightKey
        """右转按键"""
        self.shootKey = shootKey
        """射击按键"""
        self.type = type
        """按键操作来源类型"""
        pass


class Operateable(ABC):

    __operation: Operation | None = None
    __isFirstShoot: bool = False

    @property
    def operation(self):
        return self.__operation

    @operation.setter
    def operation(self, value: Operation | None):
        # from pygame import KEYDOWN

        self.__operation = value

    def __init__(self, operation: Operation | None):
        # from pygame import KEYDOWN
        self.__operation = operation

    @final
    def operate(self, delta: float):
        from game.keyPressedManager import KeyPressedManager as key

        if self.operation is None:
            return

        if key.isPressed(self.operation.forwardKey, self.operation.type):
            self.onForward(delta)
        if key.isPressed(self.operation.backKey, self.operation.type):
            self.onBack(delta)
        if key.isPressed(self.operation.leftKey, self.operation.type):
            self.onLeft(delta)
        if key.isPressed(self.operation.rightKey, self.operation.type):
            self.onRight(delta)

        if key.isPressed(self.operation.shootKey, self.operation.type):
            self.onShoot(delta, self.__isFirstShoot)
            self.__isFirstShoot = False
        else:
            self.__isFirstShoot = True

    def onForward(self, delta: float):
        """
        当处于前进状态时
        """
        pass

    def onBack(self, delta: float):
        """
        当处于后退状态时
        """
        pass

    def onLeft(self, delta: float):
        """
        当处于左转状态时
        """
        pass

    def onRight(self, delta: float):
        """
        当处于右转状态时
        """
        pass

    def onShoot(self, delta: float, isFirstShoot: bool):
        pass
