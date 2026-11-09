"""The run itself: hits and what saves you, walls, lasers, close calls, coins, danger and power-ups."""

import pytest
from pygame.math import Vector2

from app import config
from app.core.world import RunRules, World
from app.entities.bolt import Bolt
from app.entities.coin import Coin
from app.entities.laser import Laser
from app.progression.upgrades import RunStats
from app.skills.powerups import Nova, TimeWarp
from helpers import bolt_at, calm, step


def test_a_bolt_that_touches_you_ends_the_run(world):
    bolt = bolt_at(world.player.pos)
    world.bolts.append(bolt)
    step(world, 1 / 60)
    assert world.over and world.killer is bolt and "death" in world.events


def test_the_shield_blocks_one_hit(world):
    world.cast(0, world.player.pos)
    world.bolts.append(bolt_at(world.player.pos))
    step(world, 1 / 60)
    assert not world.over and not world.bolts, "blocked bolts are destroyed"
    assert not world.player.shielded, "a shield takes one hit"
    world.bolts.append(bolt_at(world.player.pos))
    step(world, 1 / 60)
    assert world.over


def test_second_wind_saves_you_once_then_recharges():
    world = calm(World(RunStats.from_levels({"second_wind": 1})))
    world.bolts.append(bolt_at(world.player.pos))
    step(world, 1 / 60)
    assert not world.over and not world.second_wind.ready
    world.bolts.append(bolt_at(world.player.pos))
    step(world, 0.5)
    assert not world.over, "untouchable for a moment after the save"
    step(world, config.SECOND_WIND_INVULN_TIME)
    world.bolts.append(bolt_at(world.player.pos))
    step(world, 1 / 60)
    assert world.over, "only one save until it recharges"


def test_second_wind_also_covers_hits_in_the_same_moment():
    world = calm(World(RunStats.from_levels({"second_wind": 1})))
    world.bolts += [bolt_at(world.player.pos), bolt_at(world.player.pos, direction=(0, 1))]   # two at once
    step(world, 1 / 60)
    assert not world.over, "a save makes you untouchable at once, not from the next frame"


def test_a_wall_destroys_bolts_coming_at_you(world):
    p = Vector2(world.player.pos)
    world.cast(1, p + (100, 0))                                     # a wall on the right
    world.bolts.append(bolt_at(p + (250, 0), direction=(-1, 0)))    # a bolt flying in from the right
    step(world, 1.0)
    assert not world.over and not world.bolts


def test_a_laser_only_hurts_once_it_fires(world):
    p = Vector2(world.player.pos)
    world.lasers.append(Laser(p + (100, 0), p, warning_time=0.5))
    step(world, 0.4)
    assert not world.over, "the warning is harmless"
    step(world, 0.2)
    assert world.over and isinstance(world.killer, Laser)


def test_lasers_can_be_turned_off():
    world = World(rules=RunRules(lasers=False))
    world.laser_timer = 0
    step(world, 0.5)
    assert not world.lasers and not world.rules.counts_for_best


def test_a_close_call_pays_a_coin(world):
    p = Vector2(world.player.pos)
    # Passes 35 px from your centre: inside the close-call zone, but no hit.
    world.bolts.append(Bolt(p + (-300, 35), p + (300, 35), 600))
    step(world, 1.2)
    assert not world.over
    assert world.close_calls == 1 and world.coins_picked == config.CLOSE_CALL_COINS


def test_walking_over_a_coin_picks_it_up(world):
    world.coins.append(Coin(world.player.pos, value=5))
    step(world, 1 / 60)
    assert world.coins_picked == 5 and not world.coins


def test_danger_climbs_to_its_maximum():
    world = calm(World())
    assert world.danger == 0
    world.survival_time = config.DANGER_RAMP_TIME / 2
    assert 0.4 < world.danger < 0.6
    world.survival_time = config.DANGER_RAMP_TIME * 2
    assert world.danger == 1
    assert World(rules=RunRules(start_danger=0.5)).danger >= 0.5, "starting danger shifts the ramp"


def test_time_warp_slows_threats_but_not_you(world):
    bolt = bolt_at((100, 100), speed=500)
    world.bolts.append(bolt)
    world.powerup_slot.skill = TimeWarp()
    world.use_powerup(world.player.pos)
    start = Vector2(bolt.shape.center)
    step(world, 0.5)
    assert bolt.shape.center.distance_to(start) == pytest.approx(500 * 0.5 * config.TIME_WARP_FACTOR, rel=0.05)


def test_nova_clears_every_threat(world):
    world.bolts += [bolt_at((100, 100)), bolt_at((900, 600))]
    world.lasers.append(Laser((0, 0), (500, 500), warning_time=1.0))
    world.powerup_slot.skill = Nova()
    assert world.use_powerup(world.player.pos)
    assert not world.bolts and not world.lasers and world.powerup_slot.skill is None


def test_the_run_stops_when_it_is_over(world):
    world.bolts.append(bolt_at(world.player.pos))
    step(world, 1 / 60)
    time = world.survival_time
    step(world, 1.0)
    assert world.survival_time == time
