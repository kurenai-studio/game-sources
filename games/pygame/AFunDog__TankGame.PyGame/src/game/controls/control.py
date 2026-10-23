from abc import abstractmethod

from pygame import Surface
from pygame.event import Event


class Control():

    @property
    @abstractmethod
    def ui(self) -> Surface: ...

    @abstractmethod
    def process(self, event: Event): ...

    @abstractmethod
    def update(self, delta: float): 
        """
        更新控件
        """
        ...

