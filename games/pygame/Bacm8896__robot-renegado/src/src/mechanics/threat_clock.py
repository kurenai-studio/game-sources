"""Reloj de amenaza enemiga (Paso D): la Fortaleza evoluciona con el tiempo. Lógica pura (sin pygame), fácil de probar.

Tres fases por tiempo de partida (UNITS.THREAT_CLOCK["phase_starts"]: 0, 4 y 8 minutos). `update(dt)` avanza el reloj y
devuelve los eventos de fase; los envíos de enemigos (streams) se recogen con `pop_orders()`."""
from collections import deque
from typing import NamedTuple

from src.config import UNITS as U

ROMAN = {1: "I", 2: "II", 3: "III"}


class SpawnOrder(NamedTuple):
    stream: str
    kinds: dict            # {tipo: cantidad}
    target: str            # core | pylon | scrap
    requires: str | None   # None | "factory"

    @property
    def count(self):
        return sum(self.kinds.values())


class ThreatClock:
    def __init__(self, cfg=None):
        self.cfg = cfg or U.THREAT_CLOCK
        self.t = 0.0
        self.phase = 1
        self._timers = {s["id"]: None for s in self.cfg["streams"]}        # None = el stream aún no está activo
        self._orders = []

    # --- estado ---
    @property
    def name(self):
        return ROMAN[self.phase]

    def phase_at(self, t):
        return 1 + sum(1 for start in self.cfg["phase_starts"][1:] if t >= start)

    @property
    def time_to_next(self):
        """Segundos hasta la siguiente fase (None en la última)."""
        starts = self.cfg["phase_starts"]
        return None if self.phase >= len(starts) else max(0.0, starts[self.phase] - self.t)

    @property
    def phase_progress(self):
        """0..1 dentro de la fase actual (1.0 en la última)."""
        starts = self.cfg["phase_starts"]
        if self.phase >= len(starts):
            return 1.0
        lo, hi = starts[self.phase - 1], starts[self.phase]
        return max(0.0, min(1.0, (self.t - lo) / (hi - lo)))

    # --- avance ---
    def update(self, dt):
        """Avanza `dt` s de juego. Devuelve los eventos de este paso: [("phase", n)], uno por cada fase nueva."""
        events = []
        self.t += dt
        target_phase = self.phase_at(self.t)
        while self.phase < target_phase:
            self.phase += 1
            events.append(("phase", self.phase))
        for s in self.cfg["streams"]:
            if self.phase < s["phase"]:
                continue
            timer = self._timers[s["id"]]
            if timer is None:                                              # recién activo: empieza la cuenta
                self._timers[s["id"]] = s["first"]
                continue
            timer -= dt
            while timer <= 0:
                self._orders.append(self._order(s))
                timer += s["interval"]
            self._timers[s["id"]] = timer
        return events

    def _order(self, s):
        kinds = dict(s["kinds"])
        growth = self.cfg["late_growth"]
        extra = int(max(0.0, self.t - growth["after"]) // growth["every"]) if s["phase"] >= 2 else 0
        if extra:                                                          # a más tiempo, marchas más grandes
            first = next(iter(kinds))
            kinds[first] += extra
        return SpawnOrder(s["id"], kinds, s["target"], s.get("requires"))

    def pop_orders(self):
        orders, self._orders = self._orders, []
        return orders

    # --- persistencia ---
    def dump(self):
        return {"t": self.t, "phase": self.phase, "timers": dict(self._timers)}

    @classmethod
    def restore(cls, data, cfg=None):
        clock = cls(cfg)
        clock.t, clock.phase = float(data["t"]), int(data["phase"])
        clock._timers.update(data.get("timers", {}))
        return clock


class SpawnQueue:
    """Cola de envíos pendientes con tope duro de enemigos vivos (UNITS.SIEGE["max_enemies"]). Los temporizadores del reloj, la
    Factoría enemiga y los contraataques encolan; `release` solo entrega las unidades que caben bajo el tope, en orden de llegada,
    así que en la fase III nunca hay más de `cap` a la vez y lo pendiente sale cuando caen bajas."""

    def __init__(self, cap):
        self.cap = int(cap)
        self._items = deque()

    def enqueue(self, kind, target, count=1):
        for _ in range(count):
            self._items.append((kind, target))

    @property
    def pending(self):
        return len(self._items)

    def release(self, active):
        """Unidades (tipo, objetivo) que se pueden instanciar ahora, con `active` enemigos ya vivos."""
        out = []
        room = self.cap - active
        while room > 0 and self._items:
            out.append(self._items.popleft())
            room -= 1
        return out

    def clear(self):
        self._items.clear()
