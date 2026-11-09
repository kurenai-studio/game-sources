"""The Skill base class: a cooldown plus a cast."""

from __future__ import annotations

from typing import TYPE_CHECKING

from pygame.math import Vector2

from app.theme.palette import PALETTE
from app.util.mathx import Color

if TYPE_CHECKING:                       # type hints only: avoids a circular import at runtime
    from app.core.world import World


class Skill:
    """Base class for everything the player can cast.

    A subclass sets ``name`` and ``cooldown``, picks its ``color`` from the
    palette and implements ``cast(world, target)``, where ``target`` is the
    cursor position. Returning ``False`` from ``cast`` cancels it without
    starting the cooldown.
    """

    name = "Skill"
    icon = "none"                       # name of a vector icon in app.render.icons
    cooldown = 1.0                      # s
    is_utility = False                  # utility spells sit in their own group on the bar

    def __init__(self) -> None:
        self.remaining = 0.0            # s left on the cooldown
        self.ready_flash = 0.0          # 1 -> 0 right after the cooldown ends (HUD pulse)

    @property
    def color(self) -> Color:
        """Read at draw time so palette changes apply immediately."""
        return PALETTE.text

    @property
    def ready(self) -> bool:
        return self.remaining <= 0

    @property
    def cooldown_fraction(self) -> float:
        """1 right after casting -> 0 when ready."""
        return self.remaining / self.cooldown if self.cooldown > 0 else 0.0

    def update(self, dt: float) -> None:
        was_cooling = self.remaining > 0
        self.remaining = max(0.0, self.remaining - dt)
        self.ready_flash = max(0.0, self.ready_flash - dt * 2.5)
        if was_cooling and self.remaining == 0:
            self.ready_flash = 1.0

    def active_fraction(self, world: World) -> float:
        """How much of the skill's effect is left (1 -> 0), or 0 if nothing is active."""
        return 0.0

    def describe(self, world: World) -> str:
        """What it does, with this run's real numbers (upgrades included), for the HUD tooltip."""
        return getattr(self, "summary", "")

    def try_cast(self, world: World, target: Vector2) -> bool:
        """Cast if ready, aimed at ``target`` (the cursor position)."""
        if not self.ready or self.cast(world, target) is False:
            return False
        self.remaining = self.cooldown
        return True

    def cast(self, world: World, target: Vector2) -> bool | None:
        raise NotImplementedError
