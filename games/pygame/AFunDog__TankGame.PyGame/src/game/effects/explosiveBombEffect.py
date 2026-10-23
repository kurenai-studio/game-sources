from loguru import logger
from pygame import Surface, draw, gfxdraw,mixer
from pymunk import Body, Circle
from game.events.delegate import Delegate
from game.events.globalEvents import GlobalEvents
from game.gameObject import GameObject, GameObjectData
from online.onlineManager import OnlineManager
from utils.easingFunc import easeLinear


class ExplosiveBombEffectData(GameObjectData):
    def __init__(self, x: int, y: int,rad : int) -> None:
        self.x = x
        self.y = y
        self.rad = rad


EFFECT_TIME_MS = 500


class ExplosiveBombEffect(GameObject):

    def __init__(self, key: str, data: ExplosiveBombEffectData):
        super().__init__(key, data)

        self.body = Body(body_type=Body.KINEMATIC)
        self.body.position = (data.x, data.y)
        self.body.moment = float("inf")
        self.shapes = [Circle(self.body, 100)]
        self.shapes[0].sensor = True

        self.__effectRad = data.rad

        effectSound = mixer.Sound("assets/bomb.mp3")
        effectSound.set_volume(0.2)
        effectSound.play()

    def render(self, screen: Surface):
        if self.isExist:
            gfxdraw.filled_circle(
                screen, round(self.body.position[0]), round(self.body.position[1]), self.__effectRad, (210, 100, 10)
            )
            

    def update(self, delta: float):
        from ..tank import Tank

        self.__effectRad = round(easeLinear(delta * 1000, self.__effectRad, 300, EFFECT_TIME_MS))
        if self.__effectRad >= 200:
            GlobalEvents.GameObjectRemoving(self.key)
            return
        if not( OnlineManager.isConnected() and OnlineManager.isClient()):
            if self.CurrentSpace is not None:
                objs= self.CurrentSpace.getGameObjectsByPosition(self.body.position,self.__effectRad)
                for obj in objs:
                    if isinstance(obj,Tank):
                        GlobalEvents.GameObjectRemoving(obj.key)

    def getData(self) -> GameObjectData:
        return ExplosiveBombEffectData(self.body.position[0], self.body.position[1],self.__effectRad)

    def setData(self, data: GameObjectData):
        assert isinstance(data, ExplosiveBombEffectData)
        self.body.position = (data.x, data.y)
        self.__effectRad = data.rad
