"""Casting: cooldowns, Ability Haste, Blink and Dash distances, and the tooltip texts."""

import pytest
from pygame.math import Vector2

from app import config
from app.core.world import World
from app.progression.upgrades import RunStats
from helpers import calm, step

SHIELD, WALL, DASH, SPRINT, BLINK = range(5)          # loadout order = the ability bar


def test_casting_starts_the_cooldown(world):
    assert world.cast(SHIELD, world.player.pos)
    skill = world.loadout[SHIELD].skill
    assert skill.remaining == skill.cooldown == config.SHIELD_COOLDOWN
    assert not world.cast(SHIELD, world.player.pos), "not ready yet"
    assert world.events[-1] == "denied"
    step(world, config.SHIELD_COOLDOWN)
    assert skill.ready


def test_haste_shortens_abilities_but_not_utility_spells():
    world = World(RunStats.from_levels({"haste": 5}))
    assert world.loadout[SHIELD].skill.cooldown == pytest.approx(config.SHIELD_COOLDOWN * 0.7)
    assert world.loadout[SPRINT].skill.cooldown == config.SPRINT_COOLDOWN
    assert type(world.loadout[SHIELD].skill).cooldown == config.SHIELD_COOLDOWN, "the class default is untouched"


def test_blink_goes_as_far_as_the_cursor_up_to_its_range(world):
    start = Vector2(world.player.pos)
    world.cast(BLINK, start + (100, 0))
    assert world.player.pos.distance_to(start) == pytest.approx(100)

    world = calm(World())
    start = Vector2(world.player.pos)
    world.cast(BLINK, start + (1000, 0))
    assert world.player.pos.distance_to(start) == pytest.approx(config.BLINK_RANGE)


def test_dash_travels_its_full_range(world):
    start = Vector2(world.player.pos)
    world.cast(DASH, start + (0, 1000))
    step(world, 0.5)
    assert not world.player.dashing
    assert world.player.pos.distance_to(start) == pytest.approx(config.DASH_RANGE, abs=1)


def test_you_cannot_cast_while_frozen(world):
    world.player.enter_stasis(1.0)
    assert not world.cast(SHIELD, world.player.pos)
    step(world, 1.1)
    assert world.cast(SHIELD, world.player.pos)


def test_tooltips_use_your_upgraded_numbers():
    world = World(RunStats.from_levels({"shield": 1, "blink": 1}))
    assert "1.8 s" in world.loadout[SHIELD].skill.describe(world)
    assert f"{config.BLINK_RANGE + 30} px" in world.loadout[BLINK].skill.describe(world)
