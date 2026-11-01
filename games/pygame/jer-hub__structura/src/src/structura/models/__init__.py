from .array import ArrayModel
from .base import IllegalMove, Model, Move, Step
from .bst import BSTModel
from .linked_list import LinkedListModel
from .stack_queue import QueueModel, StackModel

MODELS: dict[str, type[Model]] = {
    "array": ArrayModel,
    "linked_list": LinkedListModel,
    "stack": StackModel,
    "queue": QueueModel,
    "bst": BSTModel,
}

DISPLAY_NAMES = {
    "array": "Array",
    "linked_list": "Linked List",
    "stack": "Stack",
    "queue": "Queue",
    "bst": "Binary Search Tree",
}


def make(structure: str, values=()) -> Model:
    return MODELS[structure](values)


__all__ = ["ArrayModel", "BSTModel", "DISPLAY_NAMES", "IllegalMove", "LinkedListModel",
           "MODELS", "Model", "Move", "QueueModel", "StackModel", "Step", "make"]
