

from abc import abstractmethod


class GameSettings:

    __tankSpeed : float = 200
    __commonBulletSpeed : float = 200
    __ghostBulletSpeed : float = 200
    __ghostSpeedIncreaseRate : float = 3
    __missileSpeed : float = 200

    @property
    def tankSpeed(self) -> float:
        return self.__tankSpeed
    @tankSpeed.setter
    def tankSpeed(self, value: float):
        self.__tankSpeed = value

    @property
    def commonBulletSpeed(self) -> float:
        return self.__commonBulletSpeed
    @commonBulletSpeed.setter
    def commonBulletSpeed(self, value: float):
        self.__commonBulletSpeed = value

    @property
    def ghostBulletSpeed(self):
        return self.__ghostBulletSpeed
    @ghostBulletSpeed.setter
    def ghostBulletSpeed(self,value : float):
        self.__ghostBulletSpeed = value

    @property
    def ghostSpeedIncreaseRate(self):
        return self.__ghostSpeedIncreaseRate

    @ghostSpeedIncreaseRate.setter
    def ghostSpeedIncreaseRate(self, value : float):
        self.__ghostSpeedIncreaseRate = value

    @property
    def missileSpeed(self):
        return self.__missileSpeed
    @missileSpeed.setter
    def missileSpeed(self, value : float):
        self.__missileSpeed = value

    def __init__(self):
        ...

    def loadFromLocal(self,file : str):
        ...


class GlobalSettingsManager:

    __gameSettings : GameSettings = GameSettings()


    def __init__(self):
        raise NotImplementedError("SettingsManager类不允许实例化")
    
    @abstractmethod
    def getGameSettings():
        return GlobalSettingsManager.__gameSettings
    
    
    
    