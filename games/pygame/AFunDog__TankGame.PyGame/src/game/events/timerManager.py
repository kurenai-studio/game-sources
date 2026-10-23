
from typing import Callable, final

@final
class Timer:

    @property
    def isOvered(self):
        return self.__isOvered

    def __init__(self, callBack: Callable[[], None], timeMs: float, loops: int = 0):
        self.callBack = callBack
        self.initTimeMs = timeMs
        self.curTimeMs = timeMs
        self.loops = loops
        self.__isOvered = False

    def reset(self):
        self.curTimeMs = self.initTimeMs

    def cancel(self):
        self.__isOvered = True

    def update(self,delta : float):
        if self.__isOvered:
            return
        self.curTimeMs -= delta * 1000
        if self.curTimeMs <= 0:
            self.callBack()
            self.reset()
            # 如果这里loops一开始为0，则会被减为-1，也就不会被删除，将会一直循环下去
            self.loops -= 1
            if self.loops == 0:
                self.__isOvered = True


@final
class TimerManager:

    @property
    def isPaused(self):
        return self.__isPaused

    def __init__(self):
        self.__timers = set[Timer]()
        self.__isPaused = False

    def setTimer(self,timer : Timer):
        self.__timers.add(timer)

    def removeTimer(self, timer : Timer):
        self.__timers.discard(timer)

    def updateTimers(self,delta : float):
        if self.__isPaused:
            return
        copyTimers = self.__timers.copy()
        for timer in copyTimers:
            timer.update(delta)
            if timer.isOvered:
                self.__timers.discard(timer)
                    