"""Upgrades, run stats and the profile: prices, refunds, best times and the balance rules."""

import json

import pytest

from app import config
from app.core.storage import SaveFile
from app.progression.profile import Profile, survival_bonus
from app.progression.upgrades import UPGRADE_BY_ID, UPGRADES, RunStats, effect_text, second_wind_cooldown


@pytest.fixture
def profile(save_path):
    return Profile(SaveFile(save_path))


# --- Upgrades ---------------------------------------------------------------------------------
def test_each_level_costs_more_than_the_last():
    for u in UPGRADES:
        prices = [u.cost(level) for level in range(u.max_level)]
        assert prices == sorted(prices) and len(set(prices)) == len(prices), u.id


def test_run_stats_follow_the_levels():
    s = RunStats.from_levels({"boots": 2, "shield": 1, "wall": 4, "blink": 3, "magnet": 1})
    assert s.player_speed == pytest.approx(config.PLAYER_SPEED * 1.10)
    assert s.shield_duration == pytest.approx(config.SHIELD_DURATION + 0.3)
    assert s.wall_length == config.WALL_LENGTH + 100
    assert s.blink_range == config.BLINK_RANGE + 90
    assert s.magnet_radius == 40
    assert RunStats.from_levels({}) == RunStats(), "no upgrades = the base numbers"


def test_cooldowns_never_drop_below_the_floor():
    assert RunStats.from_levels({"haste": 50}).cooldown_mult == config.MIN_COOLDOWN_MULT


def test_second_wind_recharge_per_level():
    step = UPGRADE_BY_ID["second_wind"].step
    assert second_wind_cooldown(0) is None
    assert [second_wind_cooldown(lv) for lv in (1, 2, 3)] == [config.SECOND_WIND_COOLDOWN - i * step
                                                              for i in range(3)]


def test_effect_text():
    assert effect_text(UPGRADE_BY_ID["boots"], 3) == "+15% move speed"
    assert effect_text(UPGRADE_BY_ID["boots"], 0) == "Not owned"


# --- Balance rules (found by the autopilot tests; keep them true when tuning) ----------------
def test_blink_is_the_long_escape():
    assert config.BLINK_RANGE > config.DASH_RANGE, "the emergency spell must reach further than Dash"
    maxed = RunStats.from_levels({"blink": UPGRADE_BY_ID["blink"].max_level}).blink_range
    assert maxed < config.WARP_RANGE, "the Warp power-up stays the longest jump"


def test_utility_spells_recharge_slower_than_abilities():
    assert min(config.SPRINT_COOLDOWN, config.BLINK_COOLDOWN) > max(
        config.SHIELD_COOLDOWN, config.WALL_COOLDOWN, config.DASH_COOLDOWN)


# --- Profile ------------------------------------------------------------------------------------
def test_buying_and_selling_refunds_exactly(profile):
    profile.coins = 100
    assert profile.buy("boots") and profile.buy("boots")
    assert profile.level("boots") == 2 and profile.coins == 100 - 15 - 22
    assert profile.sell("boots") == 22 and profile.sell("boots") == 15
    assert profile.coins == 100 and profile.sell("boots") is None


def test_you_cannot_buy_without_coins_or_past_the_max(profile):
    assert not profile.buy("boots")
    profile.coins = 10_000
    for _ in range(UPGRADE_BY_ID["shield"].max_level):
        assert profile.buy("shield")
    assert profile.cost("shield") is None and not profile.buy("shield")


def test_sell_all(profile):
    profile.coins = 10_000
    for uid in ("boots", "boots", "magnet", "second_wind"):
        profile.buy(uid)
    assert profile.sell_all() == 15 + 22 + 10 + 120
    assert profile.coins == 10_000 and not any(profile.levels.values())


def test_a_run_banks_its_coins_and_a_best_time(save_path, profile):
    result = profile.record_run(42.0, picked_up=7)
    assert result.bonus == survival_bonus(42.0) == 8 and result.coins == 15 and result.new_best
    assert profile.coins == 15 and profile.best_time == 42.0
    assert not profile.record_run(30.0, picked_up=0).new_best
    reloaded = Profile(SaveFile(save_path))
    assert reloaded.coins == 15 + survival_bonus(30.0) and reloaded.best_time == 42.0


def test_runs_with_assists_never_set_a_best_time(profile):
    result = profile.record_run(99.0, picked_up=3, counts_for_best=False)
    assert not result.new_best and not result.counted
    assert profile.best_time == 0 and profile.coins == 3 + survival_bonus(99.0), "coins still count"


def test_a_hand_edited_profile_is_cleaned_up(save_path):
    save_path.write_text(json.dumps({"progress": {
        "coins": -5, "best_time": True, "upgrades": {"boots": 99, "shield": -1, "wall": "2", "nope": 3},
    }}), encoding="utf-8")
    profile = Profile(SaveFile(save_path))
    assert profile.coins == 0 and profile.best_time == 0
    assert profile.level("boots") == UPGRADE_BY_ID["boots"].max_level, "too high is clamped"
    assert profile.level("shield") == 0 and profile.level("wall") == 0
