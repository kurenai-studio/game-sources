import math
from loguru import logger
from pymunk import Body, Poly

from game.defines import BULLET_FILTER
from game.events.timerManager import Timer
from utils.easingFunc import easeLinear
from .commonBullet import BULLET_COLLISION_TYPE
from ..events.eventDelegate import EventDelegate
from pygame import BLEND_RGBA_MULT, Surface, transform, image, mixer
from ..events.globalEvents import GlobalEvents
from ..gameObject import GameObject, GameObjectData
from ..gameSettings import GlobalSettingsManager
from ..operateable import Operateable


class MissileData(GameObjectData):
    def __init__(self, x: float, y: float, angle: float, style: tuple[int, int, int]):
        self.x = x
        self.y = y
        self.angle = angle
        self.style = style


class Missile(GameObject, Operateable):
    """
    遥控导弹
    """

    MISSILE_WIDTH = 24

    BulletDisappeared: EventDelegate[GameObject]

    __isSpeedUp: bool
    __upSpeedRate: float = 0.5

    def __init__(self, key: str, data: MissileData):
        BULLET_DISAPPEAR_TIME_MS = 30 * 1000
        super().__init__(key, data)
        self.__isSpeedUp = False

        def __onButtonDisappeared():
            if self.isExist:
                self.__disappearSound.play()
            GlobalEvents.GameObjectRemoving(self.key)

        self.__bulletDisappearTimer = Timer(__onButtonDisappeared, BULLET_DISAPPEAR_TIME_MS, 1)

        def __vec_func(body: Body, gravity: tuple[float, float], damping: float, dt: float):
            body.velocity = (
                body.rotation_vector
                * GlobalSettingsManager.getGameSettings().missileSpeed
                * (1 + self.__upSpeedRate if self.__isSpeedUp else 1)
            )
            # self.body.apply_force_at_world_point(
            #     self.body.rotation_vector * 1000, self.body.position
            # )
            # body.velocity = body.velocity * 1.02
            body.update_velocity(body, (0, 0), 0.95, dt)

        self.__style = data.style
        o_img = image.load("assets/missile.png").convert_alpha()
        self.surface = transform.smoothscale_by(o_img, Missile.MISSILE_WIDTH / o_img.get_width())
        filterSurface = Surface(self.surface.get_size())
        filterSurface.fill(self.__style)
        self.surface.blit(filterSurface, (0, 0), special_flags=BLEND_RGBA_MULT)

        self.body = Body(body_type=Body.DYNAMIC)
        self.body.position = (data.x, data.y)
        self.body.angle = data.angle
        self.body.moment = float("inf")
        self.body.mass = 1
        self.body.velocity = (
            self.body.rotation_vector * GlobalSettingsManager.getGameSettings().missileSpeed
        )
        self.body.velocity_func = __vec_func

        self.shapes = [
            Poly.create_box(
                self.body, (self.surface.get_width() * 0.6, self.surface.get_height() * 0.6)
            )
        ]
        self.shapes[0].filter = BULLET_FILTER
        self.shapes[0].collision_type = BULLET_COLLISION_TYPE

        # event = EventManager.allocateEventType()

        # 音效
        self.__disappearSound = mixer.Sound("assets/disappear.mp3")
        self.__disappearSound.set_volume(0.1)

    def render(self, screen: Surface):
        # r = np.rad2deg(math.atan2(self.body.velocity[0], self.body.velocity[1])) - 90
        # print(r)
        r_img = transform.rotate(self.surface, math.degrees(-self.body.angle))
        screen.blit(r_img, r_img.get_rect(center=self.body.position))

    def update(self, delta: float):
        # self.__delayEnableCollisionTimer.update(delta)
        self.__bulletDisappearTimer.update(delta)
        self.__isSpeedUp = False

    def onForward(self, delta: float):
        # self.body.apply_force_at_world_point(
        #     self.body.rotation_vector * 3000000 * delta, self.body.position
        # )
        self.__isSpeedUp = True

    def onLeft(self, delta: float):
        self.body.angular_velocity = -500 * delta

    def onRight(self, delta: float):
        self.body.angular_velocity = 500 * delta

    def onShoot(self, delta: float, isFirstShoot: bool):
        if isFirstShoot:
            GlobalEvents.GameObjectRemoving(self.key)
            logger.debug(f"导弹主动销毁 {self}")

    def getData(self) -> GameObjectData:
        return MissileData(
            self.body.position[0], self.body.position[1], self.body.angle, self.__style
        )

    def setData(self, data: GameObjectData):
        assert isinstance(data, MissileData)
        self.body.position = (data.x, data.y)
        self.body.angle = data.angle
        self.__style = data.style
