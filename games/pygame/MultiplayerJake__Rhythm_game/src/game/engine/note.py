"""Note model for the rhythm engine."""

from __future__ import annotations

from dataclasses import dataclass

PENDING = "pending"
HOLDING = "holding"
HIT = "hit"
RELEASED = "released"
MISSED = "missed"


@dataclass
class Note:
    lane: int
    time: float              # ms from song start (head)
    end: float | None = None  # ms (tail) for sustain notes
    boost: bool = False       # yellow boost note
    status: str = PENDING

    @property
    def is_sustain(self) -> bool:
        return self.end is not None

    @classmethod
    def from_dict(cls, data: dict) -> "Note":
        return cls(lane=int(data["lane"]),
                   time=float(data["time"]),
                   end=float(data["end"]) if data.get("end") is not None else None,
                   boost=bool(data.get("boost", False)))
