
import random
from game.gameMap import GameMap
from game.operateable import Operateable


class AI:
    
    def __init__(self,target : Operateable,gameMap : GameMap):
        self.__target = target
        self.__gameMap = gameMap

    def update(self, delta : float):
        self.__target.onForward(delta)
        random.choice([self.__target.onLeft, self.__target.onRight])(delta)