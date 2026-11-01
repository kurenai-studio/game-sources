"""Achievements are worked out from results every time; each rule, earned and not."""
from structura.persistence.achievements import evaluate
from structura.persistence.store import Result
from structura.puzzles.schema import Puzzle, Zone


def puzzle(pid, stage):
    return Puzzle(id=pid, title=pid, type="sort", stage=stage, structure="array",
                  brief="", goal={"kind": "sorted"}, initial=[2, 1], ops=["swap"])


def zone(zid, name, *puzzles):
    return Zone(id=zid, name=name, order=1, structure="array", color=(1, 2, 3), intro="",
                requires=[], map_pos=(0.5, 0.5), lesson=None, puzzles=list(puzzles))


ZONE = zone("z", "Test Zone", puzzle("g", "guided"), puzzle("c", "challenge"), puzzle("b", "boss"))


def result(pid, stars=2, glitches=1, hints=1, attempts=1, ever_clean=None):
    """`ever_clean` defaults to whether this best attempt was itself clean."""
    if ever_clean is None:
        ever_clean = glitches == 0 and hints == 0
    return pid, Result(pid, stars, moves=4, glitches=glitches, hints=hints, attempts=attempts,
                       completed_at="2026-10-15T00:00:00+00:00", ever_clean=ever_clean)


def earned(*results) -> dict[str, bool]:
    return {a.title: a.earned for a in evaluate([ZONE], dict(results))}


def test_a_fresh_profile_has_earned_nothing():
    assert not any(earned().values())


def test_first_repair_needs_any_finished_puzzle():
    assert earned(result("g"))["First Repair"]


def test_clean_hands_needs_a_challenge_or_boss_with_no_glitches_and_no_hints():
    assert not earned(result("g", glitches=0, hints=0))["Clean Hands"], "Guided Puzzles don't count"
    assert not earned(result("c", glitches=1, hints=0))["Clean Hands"]
    assert not earned(result("c", glitches=0, hints=1))["Clean Hands"]
    assert earned(result("c", glitches=0, hints=0))["Clean Hands"]
    assert earned(result("b", glitches=0, hints=0))["Clean Hands"]


def test_clean_hands_counts_a_clean_run_even_when_the_best_attempt_was_messy():
    assert earned(result("c", glitches=1, hints=0, ever_clean=True))["Clean Hands"]
    assert not earned(result("g", glitches=1, hints=0, ever_clean=True))["Clean Hands"], "still not Guided"


def test_boss_breaker_needs_a_boss():
    assert not earned(result("g"), result("c"))["Boss Breaker"]
    assert earned(result("b"))["Boss Breaker"]


def test_persistence_needs_the_same_puzzle_finished_three_times():
    assert not earned(result("g", attempts=2), result("c", attempts=2))["Persistence"]
    assert earned(result("g", attempts=3))["Persistence"]


def test_master_needs_three_stars_on_every_puzzle_in_the_zone():
    three = [result(p.id, stars=3) for p in ZONE.puzzles]
    assert not earned(*three[:-1])["Master of Test Zone"]
    assert not earned(*three[:-1], result("b", stars=2))["Master of Test Zone"]
    assert earned(*three)["Master of Test Zone"]


def test_each_zone_adds_its_own_master_achievement():
    other = zone("y", "Other Zone", puzzle("o", "guided"))
    titles = [a.title for a in evaluate([ZONE, other], {})]
    assert "Master of Test Zone" in titles and "Master of Other Zone" in titles


def test_descriptions_say_what_each_rule_needs():
    detail = {a.title: a.detail for a in evaluate([ZONE], {})}
    assert detail["Clean Hands"] == "Finish a Challenge or Boss Puzzle with no Glitches and no Hints."
    assert detail["Persistence"] == "Finish the same Puzzle three times."
