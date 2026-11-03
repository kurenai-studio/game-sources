import { describe, expect, it } from 'vitest';
import { parseLevel } from '../src/core/grid';
import { findPath } from '../src/core/pathfinding';
import { LEVELS } from '../src/levels';
import { isFloorDressing, isFurniture, propSize, propTiles } from '../src/levels/props';

describe('level data', () => {
  for (const def of LEVELS) {
    const lvl = parseLevel(def.map);
    const walkable = (tx: number, ty: number) => lvl.tiles[Math.floor(ty) * lvl.width + Math.floor(tx)] === 'floor';

    it(`${def.id}: rows are equal width and entries start on walkable floor`, () => {
      expect(def.map.every((r) => r.length === lvl.width)).toBe(true);
      for (const e of def.entries) for (const p of e.approach) expect(walkable(p.tx, p.ty)).toBe(true);
    });

    it(`${def.id}: furniture props stand on furniture tiles, rugs and clutter on open ground`, () => {
      const at = (t: { tx: number; ty: number }) => lvl.tiles[t.ty * lvl.width + t.tx];
      for (const p of def.props ?? []) {
        const { w, h } = propSize(p);
        const tiles = [];
        for (let ty = Math.floor(p.ty); ty < Math.ceil(p.ty + h); ty++) for (let tx = Math.floor(p.tx); tx < Math.ceil(p.tx + w); tx++) tiles.push({ tx, ty });
        if (isFurniture(p)) for (const t of tiles) expect(at(t), `${p.kind} at ${t.tx},${t.ty}`).toBe('furniture');
        if (isFloorDressing(p)) for (const t of tiles) expect(['floor', 'furniture'], `${p.kind} at ${t.tx},${t.ty}`).toContain(at(t));
      }
    });

    it(`${def.id}: intro walks stay clear of walls, doors and props`, () => {
      const blocked = new Set((def.props ?? []).flatMap(propTiles).map((t) => `${t.tx},${t.ty}`));
      const doors = new Set(lvl.doors.map((d) => `${d.tx},${d.ty}`));
      const clear = (x: number, y: number) => {
        const key = `${Math.floor(x)},${Math.floor(y)}`;
        return walkable(x, y) && !blocked.has(key) && !doors.has(key);
      };
      // The operator is about a third of a tile across: check the route and either side of it.
      const r = 0.3;
      for (const e of def.entries) {
        for (let i = 1; i < e.approach.length; i++) {
          const a = e.approach[i - 1], b = e.approach[i];
          const steps = Math.ceil(Math.hypot(b.tx - a.tx, b.ty - a.ty) * 8);
          for (let k = 0; k <= steps; k++) {
            const x = a.tx + ((b.tx - a.tx) * k) / steps, y = a.ty + ((b.ty - a.ty) * k) / steps;
            for (const [ox, oy] of [[0, 0], [r, r], [-r, r], [r, -r], [-r, -r]]) {
              expect(clear(x + ox, y + oy), `${e.id} at ${x.toFixed(1)},${y.toFixed(1)}`).toBe(true);
            }
          }
        }
      }
    });

    if (def.mission) {
      it(`${def.id}: every spawn slot and patrol point is on floor and reachable from each entry`, () => {
        const m = def.mission!;
        const points = [
          ...m.hostileSlots, ...m.civilianSlots, ...m.hostileSlots.flatMap((h) => h.route ?? []),
          ...(m.hostage ? [m.hostage] : []), ...(m.evidence ? [m.evidence] : []), ...(m.alarmPanels ?? []),
        ];
        const solid = new Set((def.props ?? []).flatMap(propTiles).map((t) => t.ty * lvl.width + t.tx));
        const passable = (x: number, y: number) => lvl.tiles[y * lvl.width + x] === 'floor' && !solid.has(y * lvl.width + x);
        const reach = (a: { tx: number; ty: number }, b: { tx: number; ty: number }) =>
          findPath(lvl.width, lvl.height, { tx: Math.floor(a.tx), ty: Math.floor(a.ty) }, { tx: Math.floor(b.tx), ty: Math.floor(b.ty) }, passable) !== null;
        for (const p of points) expect(walkable(p.tx, p.ty) && !solid.has(Math.floor(p.ty) * lvl.width + Math.floor(p.tx)), `${p.tx},${p.ty}`).toBe(true);
        // Overwatch: everyone can make for the car, and nobody can get up to the roof.
        const getaway = m.overwatch?.getaway;
        if (getaway) {
          expect(walkable(getaway.tx, getaway.ty)).toBe(true);
          for (const p of points) expect(reach(p, getaway)).toBe(true);
          for (const e of def.entries) expect(reach(e.approach.at(-1)!, getaway)).toBe(false);
          return;
        }
        for (const e of def.entries) for (const p of points) expect(reach(e.approach.at(-1)!, p)).toBe(true);
      });
    }
  }
});
