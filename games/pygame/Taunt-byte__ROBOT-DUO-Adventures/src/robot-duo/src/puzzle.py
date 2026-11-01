"""Switch logic. Buttons produce named signals; actuators (doors, bridges, movers,
barriers) listen to a list of button ids.

A button is "active" while a robot stands on it, or - for latching buttons -
forever after the first press. Actuators combine their triggers with
mode "any" (one is enough) or "all" (every trigger must be active).
"""
from . import settings as S
from .collision import Box


class Button:
    def __init__(self, button_id, col, row, latch=False):
        self.id = button_id
        self.col, self.row = col, row
        self.latch = latch
        # Sensor sits on the floor tile below the cell; robot feet overlap it when standing on the button.
        self.sensor = Box(col * S.TILE + 3, (row + 1) * S.TILE - 12, S.TILE - 6, 12)
        self.pressed = False     # a robot is on it right now
        self.active = False      # signal value (pressed, or latched)

    def update(self, players):
        """Returns a list of events: 'switch_on' / 'switch_off'."""
        was_active = self.active
        self.pressed = any(p.alive and p.box.overlaps(self.sensor) for p in players)
        self.active = self.pressed or (self.latch and self.active)
        if self.active and not was_active:
            return ["switch_on"]
        if was_active and not self.active:
            return ["switch_off"]
        return []


class Actuator:
    """Mixin for anything that reacts to buttons."""

    def init_actuator(self, triggers, mode="any"):
        self.triggers = list(triggers or [])
        self.mode = mode

    def powered(self, signals):
        if not self.triggers:
            return False
        values = [bool(signals.get(t, False)) for t in self.triggers]
        return all(values) if self.mode == "all" else any(values)
