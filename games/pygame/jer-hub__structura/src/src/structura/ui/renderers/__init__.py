"""Structure renderers. Every renderer registered here runs through the
renderer contract suite (tests/test_renderer_contract.py)."""
from __future__ import annotations

import pygame

from .array import ArrayRenderer
from .base import Renderer, Target
from .bst import BSTRenderer
from .linked_list import LinkedListRenderer
from .queue import QueueRenderer
from .stack import StackRenderer

__all__ = ["RENDERERS", "Renderer", "Target", "make_renderer"]

RENDERERS: dict[str, type[Renderer]] = {
    "array": ArrayRenderer,
    "linked_list": LinkedListRenderer,
    "stack": StackRenderer,
    "queue": QueueRenderer,
    "bst": BSTRenderer,
}


def make_renderer(structure: str, rect: pygame.Rect, speed: float = 1.0) -> Renderer:
    if structure not in RENDERERS:
        raise NotImplementedError(f"no renderer for {structure} yet")
    renderer = RENDERERS[structure](rect)
    renderer.speed = speed
    return renderer
