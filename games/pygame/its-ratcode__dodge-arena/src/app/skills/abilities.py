"""The three abilities: Shield, Wall and Dash."""

from __future__ import annotations

from typing import TYPE_CHECKING

from pygame.math import Vector2

from app import config
from app.entities.wall import Wall
from app.skills.base import Skill
from app.theme.palette import PALETTE
from app.util.mathx import Color

if TYPE_CHECKING:
    from app.core.world import World


class Shield(Skill):
    """A bubble that blocks the next hit (bolt or laser) for a short time."""

    name = "Shield"
    icon = "shield"
    cooldown = config.SHIELD_COOLDOWN

    @property
    def color(self) -> Color:
        return PALETTE.shield

    def cast(self, world: World, target: Vector2) -> None:
        world.player.add_shield(world.stats.shield_duration)

    def active_fraction(self, world: World) -> float:
        p = world.player
        return p.shield_remaining / p.shield_duration if p.shielded else 0.0

    def describe(self, world: World) -> str:
        return (f"Blocks the next bolt or laser within {world.stats.shield_duration:g} s. While it is up, "
                f"the bubble is your hitbox.")


class WallSkill(Skill):
    """Raises a wall in front of the player, across the direction of the cursor."""

    name = "Wall"
    icon = "wall"
    cooldown = config.WALL_COOLDOWN

    def __init__(self) -> None:
        super().__init__()
        self.wall: Wall | None = None       # the last wall raised, for the HUD

    @property
    def color(self) -> Color:
        return PALETTE.wall

    def cast(self, world: World, target: Vector2) -> None:
        aim = world.aim_direction(target)
        center = world.player.pos + aim * config.WALL_DISTANCE
        self.wall = Wall(center, Vector2(-aim.y, aim.x), length=world.stats.wall_length)
        world.walls.append(self.wall)

    def active_fraction(self, world: World) -> float:
        return self.wall.remaining / self.wall.duration if self.wall and self.wall.alive else 0.0

    def describe(self, world: World) -> str:
        return (f"A {world.stats.wall_length:g} px wall in front of you for {config.WALL_DURATION:g} s. "
                f"It destroys bolts; lasers pass through.")


class Dash(Skill):
    """A fast, fixed-distance dash toward the cursor. You can still be hit on the way."""

    name = "Dash"
    icon = "dash"
    cooldown = config.DASH_COOLDOWN

    @property
    def color(self) -> Color:
        return PALETTE.dash

    def cast(self, world: World, target: Vector2) -> None:
        aim = world.aim_direction(target)
        world.player.start_dash(world.player.pos + aim * config.DASH_RANGE, config.DASH_SPEED)

    def active_fraction(self, world: World) -> float:
        return 1.0 if world.player.dashing else 0.0

    def describe(self, world: World) -> str:
        return f"Dash {config.DASH_RANGE} px toward the cursor. A bolt in the way can still hit you."
