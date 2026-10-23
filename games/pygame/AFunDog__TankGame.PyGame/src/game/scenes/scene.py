from abc import ABC, abstractmethod
from pygame import Surface
from pygame.event import Event

from game.spaces.gameObjectSpace import GameObjectSpace


class Scene(ABC):

    @property
    @abstractmethod
    def ui(self) -> Surface: ...


    @abstractmethod
    def process(self, event: Event):
        """
        处理事件
        """
        ...

    @abstractmethod
    def update(self, delta: float):
        """
        更新场景
        """
        ...

    def render(self, screen: Surface):
        """
        额外渲染画面
        """
        ...

    def onEntered(self):
        """
        当场景进入后触发
        """
        ...

    def onLeaved(self):
        """
        当场景离开后触发
        """
        ...
