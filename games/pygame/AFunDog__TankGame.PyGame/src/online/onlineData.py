from abc import ABC
from typing import Any, Sequence

from game.gameObject import GameObjectData


class OnlineData(ABC): ...


# class CheckData:
#     from_ : int
#     isCheck : bool
#     def __init__(self,from_ : int):
#         self.from_ = from_
#         self.isCheck = False


class EventData(OnlineData):
    eventType: int
    data: dict[str, Any] | None = None

    def __init__(self, eventType: int, data: dict[str, Any] | None = None):
        self.eventType = eventType
        self.data = data


class GameUpdateData(OnlineData):
    def __init__(self,scores : dict[str,int], data: dict[str, GameObjectData]):
        self.scores = scores
        self.data = data

class RequestGameObjectData(OnlineData):
    def __init__(self, keys: Sequence[str]):
        self.keys = keys

class ConfirmOnlineData(OnlineData):
    """
    只是用来确认数据是否接收到
    """
    def __init__(self,isOk : bool) -> None:
        self.isOk = isOk