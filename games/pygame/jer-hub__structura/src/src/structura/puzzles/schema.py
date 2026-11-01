"""Zone and Puzzle definitions, loaded from src/structura/content/zones/*.toml.

A Puzzle file states only a starting state and a goal (ADR 0001). Anything that
counts as an answer is worked out by the models in goals.py.
"""
from __future__ import annotations

import tomllib
from dataclasses import dataclass, field
from pathlib import Path

from .. import bundle

PUZZLE_TYPES = ("build", "repair", "trace", "optimize", "sort", "pathfind", "select", "code")
STAGES = ("guided", "challenge", "boss")


@dataclass
class Disruption:
    after: int          # fires once the player has made this many Moves (net of undo)
    do: list[str]       # script lines applied to the structure
    say: str = ""


@dataclass
class Puzzle:
    id: str
    title: str
    type: str
    stage: str
    structure: str
    brief: str
    goal: dict
    initial: list = field(default_factory=list)
    tray: list = field(default_factory=list)
    ops: list[str] = field(default_factory=list)
    strict: bool = False
    hints: list[str] = field(default_factory=list)   # tiers 1 and 2; tier 3 is generated
    code: str = ""                                     # Code Mirror snippet key
    disruptions: list[Disruption] = field(default_factory=list)
    intro: str = ""
    outro: str = ""
    zone_id: str = ""


@dataclass
class LessonBeat:
    say: str
    do: list[str] = field(default_factory=list)
    code: str = ""
    structure: str = ""                                # switch the board to this structure, from `initial`
    initial: list = field(default_factory=list)
    big_o: list[str] = field(default_factory=list)    # operations to compare in the Code Mirror


@dataclass
class Lesson:
    structure: str
    initial: list
    beats: list[LessonBeat]


@dataclass
class Zone:
    id: str
    name: str
    order: int
    structure: str
    color: tuple[int, int, int]
    intro: str
    requires: list[str]
    map_pos: tuple[float, float]
    lesson: Lesson | None
    puzzles: list[Puzzle]
    is_nexus: bool = False


class ContentError(ValueError):
    pass


def _puzzle(raw: dict, zone: dict) -> Puzzle:
    raw = dict(raw)
    raw.setdefault("structure", zone.get("structure"))
    raw["disruptions"] = [Disruption(**d) for d in raw.pop("disruption", [])]
    raw["zone_id"] = zone["id"]
    try:
        p = Puzzle(**raw)
    except TypeError as exc:
        raise ContentError(f"puzzle {raw.get('id')}: {exc}") from exc
    if p.type not in PUZZLE_TYPES:
        raise ContentError(f"{p.id}: unknown Puzzle Type {p.type!r}")
    if p.stage not in STAGES:
        raise ContentError(f"{p.id}: unknown Stage {p.stage!r}")
    return p


def _beat(raw: dict, zone: dict) -> LessonBeat:
    from ..models import MODELS, complexity

    b = LessonBeat(**raw)
    if b.structure and b.structure not in MODELS:
        raise ContentError(f"{zone['id']} Lesson: unknown structure {b.structure!r}")
    unknown = [op for op in b.big_o if op not in complexity.OPERATIONS]
    if unknown:
        raise ContentError(f"{zone['id']} Lesson: unknown Big-O operations {unknown}")
    return b


def load_zone(path: Path) -> Zone:
    with open(path, "rb") as fh:
        data = tomllib.load(fh)
    z = data["zone"]
    lesson = None
    if "lesson" in data:
        l = data["lesson"]
        lesson = Lesson(
            structure=l.get("structure", z["structure"]),
            initial=l.get("initial", []),
            beats=[_beat(b, z) for b in l.get("beat", [])],
        )
    puzzles = [_puzzle(p, z) for p in data.get("puzzle", [])]
    return Zone(
        id=z["id"], name=z["name"], order=z["order"], structure=z["structure"],
        color=tuple(z.get("color", [90, 160, 255])), intro=z.get("intro", ""),
        requires=z.get("requires", []), map_pos=tuple(z.get("map_pos", [0.5, 0.5])),
        lesson=lesson, puzzles=puzzles, is_nexus=z.get("nexus", False),
    )


def content_dir() -> Path:
    return bundle.locate(bundle.ZONES)


def load_all(directory: Path | None = None) -> list[Zone]:
    directory = directory or content_dir()
    zones = [load_zone(p) for p in sorted(directory.glob("*.toml"))]
    ids = [p.id for z in zones for p in z.puzzles]
    dupes = {i for i in ids if ids.count(i) > 1}
    if dupes:
        raise ContentError(f"duplicate puzzle ids: {sorted(dupes)}")
    return sorted(zones, key=lambda z: z.order)
