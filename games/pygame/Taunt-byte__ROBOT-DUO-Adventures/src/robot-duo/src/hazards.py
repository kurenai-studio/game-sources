"""Things that kill robots: lava, water, spikes and electric barriers."""
from . import settings as S
from .collision import Box
from .puzzle import Actuator


class Pool:
    """A horizontal run of lava or water tiles (merged for rendering)."""

    def __init__(self, kind, col0, col1, row):
        self.kind = kind                      # 'lava' | 'water'
        self.col0, self.col1, self.row = col0, col1, row
        self.rect = (col0 * S.TILE, row * S.TILE, (col1 - col0 + 1) * S.TILE, S.TILE)


class Hazard:
    """A lethal box. `kind` decides who survives it (see Player.immune)."""

    def __init__(self, kind, box):
        self.kind = kind
        self.box = box


def lava_hazard(col, row):
    # surface sits 10px into the tile; narrowed slightly so edge-grazing jumps are forgiven
    return Hazard("lava", Box(col * S.TILE + 3, row * S.TILE + 10, S.TILE - 6, S.TILE - 10))


def water_hazard(col, row):
    return Hazard("water", Box(col * S.TILE + 3, row * S.TILE + 10, S.TILE - 6, S.TILE - 10))


def spike_hazard(col, row):
    return Hazard("spikes", Box(col * S.TILE + 7, row * S.TILE + 16, S.TILE - 14, S.TILE - 16))


class ElectricBarrier(Actuator):
    """Lethal field that is switched OFF while its buttons are active."""

    def __init__(self, col, row, w, h, triggers, mode="any"):
        self.init_actuator(triggers, mode)
        self.rect_box = Box(col * S.TILE, row * S.TILE, w * S.TILE, h * S.TILE)
        self.vertical = h >= w
        self.active = True

    def update(self, signals):
        was = self.active
        self.active = not self.powered(signals)
        if was and not self.active:
            return ["door_open"]
        if not was and self.active:
            return ["door_close"]
        return []

    @property
    def hazard(self):
        # slightly inset so brushing the emitter frame is safe
        b = self.rect_box
        return Hazard("electric", Box(b.x + 8, b.y + 2, b.w - 16, b.h - 4) if self.vertical
                      else Box(b.x + 2, b.y + 8, b.w - 4, b.h - 16))
