from typing import Any, Callable

from loguru import logger

from .timerManager import Timer


class Delegate[*Args]:
    """
    委托类

    模仿 C# 的事件系统的类
    被 Call 时会立刻调用绑定的函数
    """

    @property
    def info(self):
        return self.__info

    @info.setter
    def info(self, value):
        self.__info = value
        self.__handlers = set[Callable[[*Args], None]]()

    def __init__(self, info: str):
        self.info = info

    def __iadd__(self, handler: Callable[[*Args], None]):
        self.__handlers.add(handler)
        return self

    def __isub__(self, handler: Callable[[*Args], None]):
        self.__handlers.discard(handler)
        return self

    def __call__(self, *args: *Args):
        logger.trace(f"委托被调用 : {self.info}")
        copyTemp = self.__handlers.copy()
        for handler in copyTemp:
            handler(*args)

    def createTimer(self, timeMs: float, loops: int = 0, *args: *Args) -> Timer:
        return Timer(lambda: self(*args), timeMs, loops)

    def clear(self):
        self.__handlers.clear()
