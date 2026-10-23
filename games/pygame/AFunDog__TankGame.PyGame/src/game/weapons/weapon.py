from abc import ABC, abstractmethod

from pygame import Surface

from game.gameObject import GameObject


class Weapon(ABC):
    """
    武器类
    """

    owner: GameObject

    def __init__(self, owner: GameObject):
        self.owner = owner
        ...

    def render(self, screen: Surface):
        """
        在武器可以使用的时候，武器进行附加渲染
        """
        ...

    @abstractmethod
    def fire(self):
        """
        开火方法
        """
        ...

    @abstractmethod
    def canFire(self) -> bool:
        """
        判断是否可以开火
        """
        ...

    @abstractmethod
    def canUse(self) -> bool:
        """
        判断武器是否可以使用
        """
        ...

    def onPicked(self):
        """
        当装备武器时调用
        """
        ...

    def onDropped(self):
        """
        当丢掉武器时调用
        """
        ...
