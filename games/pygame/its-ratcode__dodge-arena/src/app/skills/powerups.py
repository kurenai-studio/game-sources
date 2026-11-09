"""Power-ups: one-use spells picked up from the map and cast with the "powerup" key.

To add one: subclass ``PowerUp``, pick an icon and a palette color, implement
``cast``, and add the class to ``POWERUP_POOL``.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from pygame.math import Vector2

from app import config
from app.skills.base import Skill
from app.theme.palette import PALETTE
from app.util.mathx import Color

if TYPE_CHECKING:
    from app.core.world import World


class PowerUp(Skill):
    """No cooldown: it is used once, then the slot empties."""

    cooldown = 0.0
    color_name = "text"                 # palette field, so the pickup can show it before one exists
    summary = ""                        # one line for the held power-up card in the HUD

    @classmethod
    def color_of(cls) -> Color:
        return getattr(PALETTE, cls.color_name)

    @property
    def color(self) -> Color:
        return self.color_of()

    def active_fraction(self, world: World) -> float:
        """For a held power-up the strip shows how long until it expires."""
        return world.powerup_hold / config.POWERUP_HOLD_TIME


class Stasis(PowerUp):
    """Freeze in place: nothing can hit you, but you can't move or cast."""

    name = "Stasis"
    icon = "stasis"
    color_name = "stasis"
    summary = "Frozen, but untouchable."

    def describe(self, world: World) -> str:
        return f"You turn to stone for {config.STASIS_DURATION:g} s: nothing can hit you, but you can't move."

    def cast(self, world: World, target: Vector2) -> None:
        world.player.enter_stasis(config.STASIS_DURATION)


class TimeWarp(PowerUp):
    """Bolts, lasers and their spawn timers slow down. You keep your speed."""

    name = "Time Warp"
    icon = "time_warp"
    color_name = "time_warp"
    summary = "Threats slow down. You don't."

    def describe(self, world: World) -> str:
        return (f"For {config.TIME_WARP_DURATION:g} s threats move at {config.TIME_WARP_FACTOR:.0%} speed. "
                f"You keep yours.")

    def cast(self, world: World, target: Vector2) -> None:
        world.time_warp_remaining = config.TIME_WARP_DURATION


class Warp(PowerUp):
    """A long-range Blink toward the cursor."""

    name = "Warp"
    icon = "warp"
    color_name = "warp"
    summary = "A long Blink to the cursor."

    def describe(self, world: World) -> str:
        return f"Teleport toward the cursor, up to {config.WARP_RANGE} px."

    def cast(self, world: World, target: Vector2) -> None:
        world.blink_toward(target, config.WARP_RANGE)


class Nova(PowerUp):
    """A shockwave that destroys every bolt and laser on screen, even lasers still warning."""

    name = "Nova"
    icon = "nova"
    color_name = "nova"
    summary = "Clears every bolt and laser."

    def cast(self, world: World, target: Vector2) -> None:
        world.nova()


class CoinRush(PowerUp):
    """For a while coins spawn faster, more fit on the field, and each is worth more."""

    name = "Coin Rush"
    icon = "coin_rush"
    color_name = "coin"
    summary = "More coins, worth double."

    def describe(self, world: World) -> str:
        return (f"For {config.COIN_RUSH_DURATION:g} s coins appear much faster and are worth "
                f"x{config.COIN_RUSH_MULT}.")

    def cast(self, world: World, target: Vector2) -> None:
        world.coin_rush_remaining = config.COIN_RUSH_DURATION


POWERUP_POOL: tuple[type[PowerUp], ...] = (Stasis, TimeWarp, Warp, Nova, CoinRush)
