from abc import ABC
from ast import Call
from typing import Any, Callable
from loguru import logger
from pygame.event import Event

from game.events.delegate import Delegate
from game.events.timerManager import Timer
from online.onlineData import EventData
from .eventManager import EventManager


class EventDelegate[*Args](Delegate[*Args]):
    """
    事件委托类

    基于委托和事件的类
    与委托类不同的是
    该类在被 Call 时会向事件队列里发送 Event
    接收到 Event 后才会调用绑定函数
    而不是立即调用绑定的函数
    """

    @property
    def eventType(self):
        return self.__eventType

    def __init__(self, info: str, sendToOnline: bool = False):
        super().__init__(info)
        self.__eventType = EventManager.allocateEventType()
        self.__sendToOnline = sendToOnline
        EventManager.addHandler(self.__eventType, self.__onEventHandled)

    @logger.catch
    def __onEventHandled(self, event: Event):
        logger.debug(f"触发事件 {self.__eventType} : {self.info} {event.args}")
        super().__call__(*event.args)  # type: ignore

    def __call__(self, *args: *Args):
        from online.onlineManager import OnlineManager

        EventManager.raiseEvent(Event(self.__eventType, args=args))
        if self.__sendToOnline and OnlineManager.isConnected() and OnlineManager.isServer():
            OnlineManager.sendData(self.getEventData(*args))


    # def setTimer(self, timeMs: int, loops: int = 0, *args: *Args):
    #     EventManager.setTimer(Event(self.__eventType, args=args), timeMs, loops)
    #     logger.debug(f"事件委托 设置定时器 {self.info} 间隔{timeMs}毫秒 循环{loops}次")

    # def cancelTimer(self):
    #     EventManager.cancelTimer(self.__eventType)
    #     logger.debug(f"事件委托 取消定时器 {self.info}")

    def clear(self):
        # self.cancelTimer()
        return super().clear()

    def getEventData(self, *args: *Args):
        return EventData(self.__eventType, {"args": args})

