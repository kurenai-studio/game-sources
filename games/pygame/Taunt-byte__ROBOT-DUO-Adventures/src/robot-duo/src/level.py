"""A loaded level: tile grid, mechanisms and the rules that tie them together.

Pure logic (no pygame). The renderer reads this object's attributes; it never
mutates anything.

Map legend (one character per 40x40 cell, bottom-left origin of sprites sits on the floor):
    #  solid wall / floor        .  empty
    L  lava                      W  water              ^  spikes
    *  energy crystal
    r  ROBO-X spawn              u  ROBO-B spawn
    x  ROBO-X exit door          b  ROBO-B exit door    (the char marks the bottom cell; doors are 2 cells tall)
Everything else (buttons, doors, bridges, movers, ...) is declared in the JSON "entities" list.
"""
import json
from . import settings as S
from .collision import Box, move_x, move_y, push_out
from .collectibles import Crystal
from .hazards import (Pool, ElectricBarrier, lava_hazard, water_hazard, spike_hazard)
from .platforms import Door, Bridge, MovingPlatform, FadingPlatform
from .puzzle import Button
from .player import Player


class LevelError(ValueError):
    pass


class Level:
    def __init__(self, data, index=0):
        self.index = index
        self.name = data.get("name", "Untitled")
        self.subtitle = data.get("subtitle", "")
        self.theme = data.get("theme", "factory")
        self.par_time = float(data.get("par_time", 90))
        self.required_crystals = int(data.get("required_crystals", 0))

        rows = list(data["map"])
        self.rows = len(rows)
        self.cols = max(len(r) for r in rows)
        self.grid = [r.ljust(self.cols, ".") for r in rows]
        self.pixel_w = self.cols * S.TILE
        self.pixel_h = self.rows * S.TILE

        self.crystals = []
        self.pools = []
        self.hazards = []            # static lethal boxes (lava / water / spikes)
        self.spike_tiles = []
        self.spawns = {}
        self.exits = {}              # kind -> Box
        self._parse_grid()

        self.buttons = {}
        self.doors, self.bridges, self.movers, self.fadings, self.barriers = [], [], [], [], []
        self.signs = []
        self._parse_entities(data.get("entities", []))

        self.signals = {}
        self.time = 0.0
        self.completed = False
        self.crystals_collected = 0
        self.total_crystals = len(self.crystals)
        self._validate()

    # ------------------------------------------------------------------ loading
    @classmethod
    def from_file(cls, path, index=0):
        with open(path, "r", encoding="utf-8") as fh:
            return cls(json.load(fh), index)

    def _parse_grid(self):
        T = S.TILE
        for r, line in enumerate(self.grid):
            run_kind, run_start = None, 0
            for c, ch in enumerate(line + " "):             # trailing sentinel flushes the last run
                kind = "lava" if ch == "L" else "water" if ch == "W" else None
                if kind != run_kind:
                    if run_kind is not None:
                        self.pools.append(Pool(run_kind, run_start, c - 1, r))
                    run_kind, run_start = kind, c
                if ch == "L":
                    self.hazards.append(lava_hazard(c, r))
                elif ch == "W":
                    self.hazards.append(water_hazard(c, r))
                elif ch == "^":
                    self.hazards.append(spike_hazard(c, r))
                    self.spike_tiles.append((c, r))
                elif ch == "*":
                    self.crystals.append(Crystal(c, r))
                elif ch in ("r", "u"):
                    self.spawns["x" if ch == "r" else "b"] = (
                        c * T + (T - S.PLAYER_W) / 2.0, (r + 1) * T - S.PLAYER_H)
                elif ch in ("x", "b"):
                    self.exits[ch] = Box(c * T, (r - 1) * T, T, 2 * T)

    def _parse_entities(self, entities):
        for e in entities:
            t = e["type"]
            trig = e.get("triggers", [])
            mode = e.get("mode", "any")
            if t == "button":
                self.buttons[e["id"]] = Button(e["id"], e["x"], e["y"], e.get("latch", False))
            elif t == "door":
                self.doors.append(Door(e["x"], e["y"], e.get("w", 1), e.get("h", 3), trig, mode))
            elif t == "bridge":
                self.bridges.append(Bridge(e["x"], e["y"], e["w"], trig, mode))
            elif t == "mover":
                self.movers.append(MovingPlatform(e["x"], e["y"], e["w"], e.get("dx", 0), e.get("dy", 0),
                                                  e.get("speed", 90.0), trig, mode, e.get("pause", 0.7)))
            elif t == "fading":
                self.fadings.append(FadingPlatform(e["x"], e["y"], e["w"], e.get("delay", 0.7),
                                                   e.get("respawn", 2.8)))
            elif t == "barrier":
                self.barriers.append(ElectricBarrier(e["x"], e["y"], e.get("w", 1), e.get("h", 3), trig, mode))
            elif t == "sign":
                self.signs.append({"col": e["x"], "row": e["y"], "text": e["text"]})
            else:
                raise LevelError("unknown entity type %r" % t)

    def _validate(self):
        for kind in ("x", "b"):
            if kind not in self.spawns:
                raise LevelError("level %r has no spawn for robot %r" % (self.name, kind))
            if kind not in self.exits:
                raise LevelError("level %r has no exit for robot %r" % (self.name, kind))
        actuators = self.doors + self.bridges + self.movers + self.barriers
        for a in actuators:
            for t in a.triggers:
                if t not in self.buttons:
                    raise LevelError("actuator references unknown button %r" % t)
        if self.required_crystals > self.total_crystals:
            raise LevelError("required crystals exceed crystals on the map")

    def create_players(self):
        return [Player(k, *self.spawns[k]) for k in ("x", "b")]

    # ------------------------------------------------------------------ geometry queries
    def is_solid_tile(self, c, r):
        if c < 0 or c >= self.cols:
            return True                       # invisible side walls
        if r < 0:
            return True
        if r >= self.rows:
            return False                      # open pit below the map
        return self.grid[r][c] == "#"

    def solids_near(self, box, pad=48):
        """All solid boxes (tiles + mechanisms) around `box`."""
        T = S.TILE
        c0 = int((box.left - pad) // T)
        c1 = int((box.right + pad) // T)
        r0 = int((box.top - pad) // T)
        r1 = int((box.bottom + pad) // T)
        out = []
        for r in range(r0, r1 + 1):
            for c in range(c0, c1 + 1):
                if self.is_solid_tile(c, r):
                    out.append(Box(c * T, r * T, T, T))
        area = box.inflated(pad, pad)
        for group in (self.doors, self.bridges, self.movers, self.fadings):
            for m in group:
                for s in m.solids():
                    if s.overlaps(area):
                        out.append(s)
        return out

    def exit_label_ok(self):
        return self.crystals_collected >= self.required_crystals

    # ------------------------------------------------------------------ simulation
    def update_mechanisms(self, dt, players):
        """Step buttons, doors, platforms. Call BEFORE the players move."""
        events = []
        if not self.completed:
            self.time += dt
        for b in self.buttons.values():
            events += b.update(players)
        self.signals = {bid: b.active for bid, b in self.buttons.items()}

        for d in self.doors:
            events += d.update(dt, self.signals, players)
        for br in self.bridges:
            events += br.update(dt, self.signals, players)
        for f in self.fadings:
            events += f.update(dt, players)
        for bar in self.barriers:
            events += bar.update(self.signals)
        for m in self.movers:
            m.update(dt, self.signals)
            self._carry(m, players)
        for c in self.crystals:
            c.update(dt)
        return events

    def _carry(self, mover, players):
        dx, dy = mover.delta
        if dx == 0 and dy == 0:
            return
        for p in players:
            if not p.alive:
                continue
            others = [s for s in self.solids_near(p.box) if s is not mover.box]
            if p.ground_solid is mover.box:             # riding: move with the platform
                move_x(p.box, dx, others)
                move_y(p.box, dy, others)
            elif p.box.overlaps(mover.box):             # got caught by it: push out
                side = push_out(p.box, mover.box)
                if side == "up":
                    p.on_ground, p.ground_solid, p.vy = True, mover.box, 0.0

    def post_update(self, dt, players):
        """Collectibles, hazards, exits and win condition. Call AFTER the players moved.
        Returns a list of event tuples: ('crystal', player), ('death', player, cause), ('complete',)."""
        events = []
        for c in self.crystals:
            if c.collected:
                continue
            for p in players:
                if p.alive and p.box.overlaps(c.box):
                    c.collected = True
                    self.crystals_collected += 1
                    events.append(("crystal", p, c))
                    break

        dangers = list(self.hazards) + [b.hazard for b in self.barriers if b.active]
        for p in players:
            if not p.alive:
                continue
            if p.box.top > self.pixel_h + S.FALL_DEATH_MARGIN:
                p.kill("pit")
                events.append(("death", p, "pit"))
                continue
            for h in dangers:
                if h.kind in p.immune:
                    continue
                if p.box.overlaps(h.box):
                    p.kill(h.kind)
                    events.append(("death", p, h.kind))
                    break

        for p in players:
            ex = self.exits[p.kind]
            p.at_door = p.alive and ex.contains_point(p.box.centerx, p.box.centery)

        if (not self.completed and all(p.alive and p.at_door for p in players)
                and self.exit_label_ok()):
            self.completed = True
            events.append(("complete",))
        return events
