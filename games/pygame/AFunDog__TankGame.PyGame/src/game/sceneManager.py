from enum import Enum
from typing import Any

from loguru import logger


from .scenes.scene import Scene


class SCENE_TYPE(Enum):
    START_SCENE = 0
    GAME_SCENE = 1
    CLIENT_GAME_SCENE = 2


class SceneManager:

    __sceneList: dict[SCENE_TYPE, Scene]
    __currentSceneType: SCENE_TYPE

    def __init__(self):
        raise NotImplementedError("SceneManager不允许被实例化")

    @staticmethod
    def init():
        SceneManager.__currentSceneType = SCENE_TYPE.START_SCENE
        SceneManager.__sceneList = {
            SceneManager.__currentSceneType: SceneManager.__sceneTypeToScene(
                SceneManager.__currentSceneType
            )
        }

    @staticmethod
    def getCurrentScene():
        return SceneManager.__sceneList[SceneManager.__currentSceneType]


    @staticmethod
    def changeScene(sceneType: SCENE_TYPE, delOtherScene: bool = True, *args: Any, **kwargs: Any):

        if sceneType not in SceneManager.__sceneList:
            SceneManager.__sceneList[sceneType] = SceneManager.__sceneTypeToScene(
                sceneType, *args, **kwargs
            )
            SceneManager.__sceneList[sceneType].onEntered()
            logger.debug(f"场景进入 {sceneType}")
        if delOtherScene:
            other_scene = [cs for cs in SceneManager.__sceneList if cs != sceneType]
            for scene in other_scene:
                SceneManager.__sceneList[scene].onLeaved()
                SceneManager.__sceneList.pop(scene)
                logger.debug(f"场景退出 {scene}")
        SceneManager.__currentSceneType = sceneType

    @staticmethod
    def __sceneTypeToScene(sceneType: SCENE_TYPE, *args: Any, **kwargs: Any):
        from .scenes.startScene import StartScene
        from .scenes.gameScene import GameScene
        from .scenes.clientGameScene import ClientGameScene

        SCENE_LIST: list[type[Scene]] = [StartScene, GameScene, ClientGameScene]
        return SCENE_LIST[sceneType.value](*args, **kwargs)
