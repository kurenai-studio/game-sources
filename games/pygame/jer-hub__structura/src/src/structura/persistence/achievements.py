"""Achievements are derived from results each time; nothing about them is stored
except each result's "ever finished clean" flag, which Clean Hands reads."""
from __future__ import annotations

from dataclasses import dataclass

from ..puzzles.schema import Zone
from .store import Result


@dataclass
class Achievement:
    title: str
    detail: str
    earned: bool


def evaluate(zones: list[Zone], results: dict[str, Result]) -> list[Achievement]:
    done = {pid: r for pid, r in results.items() if r.stars > 0}
    out = [
        Achievement("First Repair", "Finish any Puzzle.", bool(done)),
        Achievement("Clean Hands", "Finish a Challenge or Boss Puzzle with no Glitches and no Hints.",
                    any(r.ever_clean for pid, r in done.items()
                        if any(p.id == pid and p.stage != "guided" for z in zones for p in z.puzzles))),
        Achievement("Boss Breaker", "Beat any Boss.",
                    any(p.id in done for z in zones for p in z.puzzles if p.stage == "boss")),
        Achievement("Persistence", "Finish the same Puzzle three times.",
                    any(r.attempts >= 3 for r in done.values())),
    ]
    for z in zones:
        ids = [p.id for p in z.puzzles]
        out.append(Achievement(f"Master of {z.name}", f"Earn 3 Stars on every Puzzle in {z.name}.",
                               bool(ids) and all(results.get(i) and results[i].stars == 3 for i in ids)))
    return out
