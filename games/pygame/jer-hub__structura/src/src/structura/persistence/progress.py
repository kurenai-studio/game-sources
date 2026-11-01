"""What a Profile has unlocked, derived from its results."""
from __future__ import annotations

from ..puzzles.schema import Zone
from .store import Result


def zone_cleared(zone: Zone, results: dict[str, Result]) -> bool:
    return all(p.id in results for p in zone.puzzles)


def zone_unlocked(zone: Zone, zones: list[Zone], results: dict[str, Result]) -> bool:
    by_id = {z.id: z for z in zones}
    return all(zone_cleared(by_id[r], results) for r in zone.requires if r in by_id)


def puzzle_unlocked(zone: Zone, index: int, results: dict[str, Result]) -> bool:
    """Puzzles open in order: each needs the one before it finished."""
    return index == 0 or zone.puzzles[index - 1].id in results


def zone_stars(zone: Zone, results: dict[str, Result]) -> tuple[int, int]:
    return sum(results[p.id].stars for p in zone.puzzles if p.id in results), 3 * len(zone.puzzles)
