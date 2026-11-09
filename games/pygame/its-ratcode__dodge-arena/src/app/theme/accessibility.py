"""Accessibility flags, read at draw time like the palette.

The Game copies them from the settings; drawing code only asks the questions
below, so it never needs to know about settings.
"""

from dataclasses import dataclass


@dataclass
class AccessibilityFlags:
    outlines: bool = False              # bright outlines around bolts and lasers
    reduce_flashing: bool = False       # no blinking or pulsing (photosensitivity)
    reduced_motion: bool = False        # no bobbing, wobbling, sliding or gliding


A11Y = AccessibilityFlags()


def blink_hidden(time_left: float, rate: float) -> bool:
    """True on the "off" beats of a blink (``rate`` beats per second).
    With reduced flashing nothing ever blinks."""
    return not A11Y.reduce_flashing and int(time_left * rate) % 2 == 0


def wobble(value: float) -> float:
    """A decorative movement amount, switched off by reduced motion."""
    return 0.0 if A11Y.reduced_motion else value
