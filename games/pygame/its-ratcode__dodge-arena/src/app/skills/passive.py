"""Passive skills: they trigger by themselves instead of being cast."""

from __future__ import annotations

from typing import TYPE_CHECKING

from pygame.math import Vector2

from app import config
from app.skills.base import Skill
from app.theme.palette import PALETTE
from app.util.mathx import Color

if TYPE_CHECKING:
    from app.core.world import World


class SecondWind(Skill):
    """Survive one fatal hit, then recharge on a long cooldown (bought as an upgrade)."""

    name = "Second Wind"
    icon = "second_wind"

    def __init__(self, cooldown: float) -> None:
        super().__init__()
        self.cooldown = cooldown        # depends on the upgrade level

    @property
    def color(self) -> Color:
        return PALETTE.second_wind

    def trigger(self) -> None:
        self.remaining = self.cooldown

    def cast(self, world: World, target: Vector2) -> bool:
        return False                    # passive: it can't be cast by hand

    def describe(self, world: World) -> str:
        return (f"Takes a hit that would end your run, then you are untouchable for "
                f"{config.SECOND_WIND_INVULN_TIME:g} s. Your Shield is always used first.")
