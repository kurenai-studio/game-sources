"""The two utility spells: Sprint and Blink. Long cooldowns, meant for emergencies."""

from __future__ import annotations

from typing import TYPE_CHECKING

from pygame.math import Vector2

from app import config
from app.skills.base import Skill
from app.theme.palette import PALETTE
from app.util.mathx import Color

if TYPE_CHECKING:
    from app.core.world import World


class Sprint(Skill):
    """A burst of movement speed for a few seconds."""

    name = "Sprint"
    icon = "sprint"
    cooldown = config.SPRINT_COOLDOWN
    is_utility = True

    @property
    def color(self) -> Color:
        return PALETTE.sprint

    def cast(self, world: World, target: Vector2) -> None:
        world.player.add_speed_buff("sprint", config.SPRINT_MULTIPLIER, world.stats.sprint_duration)

    def active_fraction(self, world: World) -> float:
        buff = world.player.speed_buffs.get("sprint")
        return buff.remaining / buff.duration if buff else 0.0

    def describe(self, world: World) -> str:
        return (f"+{(config.SPRINT_MULTIPLIER - 1) * 100:.0f}% move speed for "
                f"{world.stats.sprint_duration:g} s.")


class Blink(Skill):
    """Instantly teleport toward the cursor, up to the run's blink range."""

    name = "Blink"
    icon = "blink"
    cooldown = config.BLINK_COOLDOWN
    is_utility = True

    @property
    def color(self) -> Color:
        return PALETTE.blink

    def cast(self, world: World, target: Vector2) -> None:
        world.blink_toward(target, world.stats.blink_range)

    def describe(self, world: World) -> str:
        return (f"Teleport toward the cursor, up to {world.stats.blink_range:g} px. Nothing can hit you "
                f"on the way.")
