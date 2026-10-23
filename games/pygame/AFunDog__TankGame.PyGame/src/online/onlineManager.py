import pickle
import queue
import socket
import threading
from typing import Any

from loguru import logger
from pygame.event import Event
from game.events.delegate import Delegate
from game.events.eventDelegate import EventDelegate
from game.events.eventManager import EventManager
from game.events.globalEvents import GlobalEvents
from game.gameObject import GameObjectData
from game.sceneManager import SCENE_TYPE, SceneManager
from online.onlineData import ConfirmOnlineData, EventData, GameUpdateData, OnlineData


class OnlineManager:

    class __Server:
        __server: socket.socket
        __client: socket.socket | None = None
        __thread: threading.Thread

        def __init__(self, host: str, port: int):
            self.__datas = list[OnlineData]()
            self.__isConfirmed = False
            self.__server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.__server.bind((host, port))
            self.__server.listen(1)

            logger.info(f"服务器已启动 {self.__server.getsockname()}")

            def __serverThread():
                try:
                    self.__client, address = self.__server.accept()
                    logger.info(f"客户端已连接：{address}")
                    self.__client.setblocking(False)
                    OnlineManager.ConnectionStarted(None)
                except Exception as e:
                    logger.exception("服务器接收客户端连接失败", e)
                    OnlineManager.close()

            self.__thread = threading.Thread(target=__serverThread)
            self.__thread.start()

        def isConnected(self):
            return self.__client is not None

        def trySendServerData(self):
            if self.__client is None or len(self.__datas) == 0 or self.__isConfirmed is False:
                return
            try:
                bytes = pickle.dumps(self.__datas)
                logger.trace(f"服务器发送数据 {len(bytes)}")
                self.__client.send(bytes)
                self.__isConfirmed = False
            except Exception as e:
                logger.exception("服务器发送数据失败", e)
            self.__datas.clear()

        def tryGetClientData(self):
            if self.__client is None:
                return
            try:
                reBytes = self.__client.recv(1024 * 4)
                if len(reBytes) == 0:
                    return
                datas = pickle.loads(reBytes)
                logger.trace(f"服务器接收数据 {type(datas)} {len(reBytes)}")
                if isinstance(datas, list):
                    for data in datas:
                        if isinstance(data, EventData):
                            event: Event
                            if data.data is not None:
                                event = Event(data.eventType, data.data)
                            else:
                                event = Event(data.eventType)
                            EventManager.raiseEvent(event)
                        if isinstance(data, ConfirmOnlineData):
                            if data.isOk:
                                self.__isConfirmed = True
            except BlockingIOError:
                logger.trace("服务器接收数据失败,无数据")
            except ConnectionAbortedError as e:
                logger.exception("服务器接收数据失败", e)
            except pickle.UnpicklingError as e:
                logger.exception("服务器接收数据失败", e)
            except Exception as e:
                logger.exception(e)
                OnlineManager.close()
                SceneManager.changeScene(SCENE_TYPE.START_SCENE)

        def sendData(self, data: OnlineData):
            try:
                if self.__client is None:
                    raise Exception("客户端不存在")
                self.__datas.append(data)
                # bytes = pickle.dumps(data)
                # logger.info(f"服务器发送数据 {type(data)}")
                # self.__client.send(bytes)
            except Exception as e:
                logger.exception("服务器发送数据失败", e)
                OnlineManager.close()
                SceneManager.changeScene(SCENE_TYPE.START_SCENE)

        def close(self):
            self.__server.close()
            if self.__client is not None:
                self.__client.close()
                self.__client = None
            self.__thread.join(0)

    class __Client:
        __client: socket.socket
        __thread: threading.Thread

        __isConnected: bool = False

        def __init__(self, host: str, port: int):
            self.__client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.__datas = list[OnlineData]()

            def __clientThread(host: str, port: int):
                try:
                    self.__client.connect((host, port))
                    self.__client.setblocking(False)
                    self.sendData(ConfirmOnlineData(True))
                    self.__isConnected = True
                    OnlineManager.ConnectionStarted(None)
                except Exception as e:
                    logger.exception("连接到服务器失败", e)

            self.__thread = threading.Thread(target=__clientThread, args=(host, port))
            self.__thread.start()

        def isConnected(self):
            return self.__isConnected

        def trySendClientData(self):
            if len(self.__datas) == 0:
                return
            try:
                bytes = pickle.dumps(self.__datas)
                
                logger.trace(f"客户端发送数据 {len(bytes)}")
                self.__client.send(bytes)
            except Exception as e:
                logger.exception("客户端发送数据失败", e)
            self.__datas.clear()

        def tryGetServerData(self):
            try:
                reBytes = self.__client.recv(1024 * 16)
                if len(reBytes) == 0:
                    return
                datas = pickle.loads(reBytes)
                logger.trace(f"客户端接收数据 {type(datas)} {len(reBytes)}")
                self.sendData(ConfirmOnlineData(True))
                if isinstance(datas, list):
                    for data in datas:
                        if isinstance(data, EventData):
                            event: Event
                            if data.data is not None:
                                event = Event(data.eventType, data.data)
                            else:
                                event = Event(data.eventType)
                            EventManager.raiseEvent(event)
                        if isinstance(data, GameUpdateData):
                            GlobalEvents.GameScoreUpdated(data.scores)
                            for key in data.data:
                                OnlineManager.GameObjectChanged(key, data.data[key])
            except BlockingIOError:
                logger.trace("客户端接收数据失败,无数据")
            except Exception as e:
                logger.exception("客户端接收数据失败", e)

        def sendData(self, data: OnlineData):
            self.__datas.append(data)

        # try:
        # bytes = pickle.dumps(data)
        # logger.trace(f"发送数据 {type(data)} {len(bytes)}")
        # self.__client.send(bytes)
        # except Exception as e:
        # logger.exception("发送数据失败", e)
        # OnlineManager.close()
        # SceneManager.changeScene(SCENE_TYPE.START_SCENE)

        def close(self):
            self.__client.close()
            self.__thread.join(0)

    __onlineObject: __Server | __Client | None = None
    # __requestGameObjectKeys = set[str]()

    GameObjectChanged = Delegate[str, GameObjectData]("从服务器接收到游戏对象数据被改变")
    ConnectionStarted = Delegate[None]("连接启动")
    ConnectionClosed = EventDelegate[None]("连接关闭")

    def __init__(self) -> None:
        raise NotImplementedError("OnlineManager不允许实例化")

    @staticmethod
    def isServer():
        return isinstance(OnlineManager.__onlineObject, OnlineManager.__Server)

    @staticmethod
    def isClient():
        return isinstance(OnlineManager.__onlineObject, OnlineManager.__Client)

    @staticmethod
    def isConnected():
        return (
            OnlineManager.__onlineObject is not None and OnlineManager.__onlineObject.isConnected()
        )

    @staticmethod
    def tryUpdateData():
        if isinstance(OnlineManager.__onlineObject, OnlineManager.__Client):
            OnlineManager.__onlineObject.tryGetServerData()
            OnlineManager.__onlineObject.trySendClientData()
        if isinstance(OnlineManager.__onlineObject, OnlineManager.__Server):
            OnlineManager.__onlineObject.tryGetClientData()
            OnlineManager.__onlineObject.trySendServerData()

    # @staticmethod
    # def getRequestGameObjectKeys():
    #     return  OnlineManager.__requestGameObjectKeys

    @staticmethod
    def createServer(host: str, port: int):
        OnlineManager.close()
        OnlineManager.__onlineObject = OnlineManager.__Server(host, port)

    @staticmethod
    def connectServer(host: str, port: int):
        OnlineManager.close()
        OnlineManager.__onlineObject = OnlineManager.__Client(host, port)

    @staticmethod
    def sendEvent(eventType: int, data: dict[str, Any]):
        if OnlineManager.__onlineObject is None:
            return
        OnlineManager.__onlineObject.sendData(EventData(eventType, data))

    @staticmethod
    def sendData(data: OnlineData):
        if OnlineManager.__onlineObject is None:
            return
        OnlineManager.__onlineObject.sendData(data)

    @staticmethod
    def close():
        if OnlineManager.__onlineObject is None:
            return
        OnlineManager.__onlineObject.close()
        OnlineManager.__onlineObject = None
        OnlineManager.GameObjectChanged.clear()
        OnlineManager.ConnectionClosed(None)
