"""Danger: how hard the run is right now, from 0.0 (start) to 1.0 (maximum)."""

from app import config
from app.util.mathx import clamp


def danger_level(elapsed: float) -> float:
    """Danger rises linearly with time survived and caps at 1.0."""
    return clamp(elapsed / config.DANGER_RAMP_TIME, 0.0, 1.0)


def ramp(start: float, end: float, danger: float) -> float:
    """Interpolate a ``*_START`` / ``*_END`` config pair by the current danger."""
    return start + (end - start) * danger
