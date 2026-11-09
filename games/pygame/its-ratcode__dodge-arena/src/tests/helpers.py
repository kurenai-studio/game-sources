"""Small helpers the tests share: placing threats, advancing time and sending input."""

import pygame
from pygame.math import Vector2

from app import config
from app.core.game import Game
from app.core.world import World
from app.entities.bolt import Bolt


def calm(world: World) -> World:
    """Stop everything from spawning, so a test places exactly the threats it wants."""
    world.spawn_timer = world.laser_timer = world.pickup_timer = world.coin_timer = 1e9
    return world


def bolt_at(pos, direction=(1, 0), speed: float = config.BOLT_SPEED_START) -> Bolt:
    """A bolt centred on ``pos``, flying along ``direction``."""
    pos = Vector2(pos)
    bolt = Bolt(pos - Vector2(direction) * 300, pos, speed)
    bolt.shape.center = Vector2(pos)
    return bolt


def step(world: World, seconds: float, dt: float = 1 / 60) -> None:
    for _ in range(round(seconds / dt)):
        world.update(dt)


def frames(game: Game, seconds: float, dt: float = 1 / 60) -> None:
    for _ in range(round(seconds / dt)):
        game.update(dt)


def press(game: Game, key: str) -> None:
    pygame.event.post(pygame.event.Event(pygame.KEYDOWN, key=pygame.key.key_code(key), mod=0, unicode=""))
    game.handle_events()


def click(game: Game, pos, button: int = 1) -> None:
    pygame.event.post(pygame.event.Event(pygame.MOUSEBUTTONDOWN, pos=pos, button=button))
    pygame.event.post(pygame.event.Event(pygame.MOUSEBUTTONUP, pos=pos, button=button))
    game.handle_events()
