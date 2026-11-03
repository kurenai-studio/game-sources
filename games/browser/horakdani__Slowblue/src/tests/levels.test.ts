import { describe, expect, it } from 'vitest';
import {
  ACT_WATER,
  LEVELS,
  LEVEL_SCRIPT,
  TOTAL_SECTIONS,
  levelAt,
  stationDepthLabel,
  type Level,
} from '../src/config/levels';
import { ACT_HOME } from '../src/config/homecoming';
import { ACT_ORBIT } from '../src/config/orbit';
import { ACT_RAIN } from '../src/config/rain';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { World } from '../src/sim/World';
import { buildCourse, sweepCourse } from './course';
import { H, W } from './helpers';

/**
 * Slowblue: the campaign's safety net. The corridor sweep itself lives in
 * `tests/course.ts` now, because the ascent runs the same check over every
 * act's course; this file remains act I's suite.
 */

describe('authored levels', () => {
  it('builds every authored section and nothing after them', () => {
    const o = buildCourse();
    expect(o.sections.length).toBe(TOTAL_SECTIONS);
    expect(o.scriptExhausted).toBe(true);
    expect(o.sections.map((s) => s.level)).toEqual(LEVEL_SCRIPT.map((e) => e.level));
  });

  it('paints each level in its own zone and never skips a level', () => {
    const o = buildCourse();
    for (const s of o.sections) expect(s.zone).toBe(levelAt(s.level).zone);
    const seen = [...new Set(o.sections.map((s) => s.level))];
    expect(seen).toEqual(LEVELS.map((_, i) => i));
  });

  it('leaves a flyable corridor down the entire campaign', () => {
    const sweep = sweepCourse(buildCourse());
    expect(sweep.blockedAt).toBeNull();
  });

  it('puts every required ring on a line the shoal can actually be on', () => {
    const o = buildCourse();
    const sweep = sweepCourse(o);
    const required = o.sections.flatMap((s) => s.podHints.filter((p) => p.required === true));
    // Every required ring must have been visited by the sweep, and be reachable.
    expect(sweep.ringsReachable.length).toBe(required.length);
    const bad = sweep.ringsReachable.filter((r) => !r.ok);
    expect(bad, JSON.stringify(bad)).toEqual([]);
  });

  it('never buries a required ring inside rock', () => {
    const o = buildCourse();
    for (const s of o.sections) {
      for (const p of s.podHints) {
        if (p.required !== true) continue;
        expect(o.hit(p.x, p.y, 1), `section ${s.id}`).toBeNull();
        // ...and the ring is not a sliver of water: most of it has to be swimmable.
        const r = DEFAULT_TUNING.rescueRadius * (p.scale ?? 1);
        let open = 0;
        const samples = 24;
        for (let i = 0; i < samples; i++) {
          const a = (i / samples) * Math.PI * 2;
          if (o.hit(p.x + Math.cos(a) * r * 0.6, p.y + Math.sin(a) * r * 0.6, 1) === null) open++;
        }
        expect(open / samples, `section ${s.id}`).toBeGreaterThan(0.75);
      }
    }
  });

  it('asks for more of the player as the levels go on', () => {
    // The curve is a design claim, so it is a test: gaps close, required rings
    // multiply, and the pace never runs away from either.
    const narrowest = LEVELS.map((l) => {
      let min = 1;
      for (const s of l.sections) if ('gap' in s) min = Math.min(min, s.gap);
      return min;
    });
    const requiredRings = LEVELS.map(
      (l) => l.sections.flatMap((s) => s.rings ?? []).filter((r) => r.required === true).length,
    );
    for (let i = 1; i < LEVELS.length; i++) {
      expect(narrowest[i]!).toBeLessThanOrEqual(narrowest[i - 1]!);
      expect(LEVELS[i]!.pace).toBeGreaterThanOrEqual(LEVELS[i - 1]!.pace);
    }
    expect(requiredRings[0]).toBeGreaterThan(0);
    expect(requiredRings[LEVELS.length - 1]!).toBeGreaterThan(requiredRings[0]!);
    // ...and the whole game stays inside one and a half times the base pace.
    expect(Math.max(...LEVELS.map((l) => l.pace))).toBeLessThanOrEqual(1.2);
  });

  it('opens with a level that is nothing but water and one ring', () => {
    const first = LEVELS[0]!.sections[0]!;
    expect(first.kind).toBe('open');
    expect(first.rings?.[0]?.required).toBe(true);
  });

  it('climbs through six named stations and ends at the surface', () => {
    expect(LEVELS).toHaveLength(6);
    for (let i = 1; i < LEVELS.length; i++) {
      expect(LEVELS[i]!.depthMeters).toBeLessThan(LEVELS[i - 1]!.depthMeters);
      expect(LEVELS[i]!.zone).toBeGreaterThanOrEqual(LEVELS[i - 1]!.zone);
    }
    expect(LEVELS[0]!.depthMeters).toBe(6000);
    expect(LEVELS.at(-1)?.key).toBe('surface');
    expect(LEVELS.at(-1)?.depthMeters).toBe(0);
  });

  it('starts a fresh run in level 0 with the first ring already in the water', () => {
    const world = new World(W, H, 4242);
    expect(world.levelIndex).toBe(0);
    expect(world.run.completed).toBe(false);
    expect(world.rescue.pods.some((p) => p.required)).toBe(true);
  });
});

/**
 * Slowblue: the one line of text on the frame that names the place.
 *
 * Worth its own describe because it was wrong in two of the seven acts and could
 * not be caught while the string was built inside a draw call. See
 * `stationDepthLabel`.
 */
describe('where a station says it is', () => {
  // The expectations are built from `toLocaleString` rather than typed out, so the
  // digit grouping is the runtime's and not a comma that only looks the same.
  const label = (levels: readonly Level[], i: number): string => stationDepthLabel(levels, i);
  const n = (v: number): string => v.toLocaleString('en-US');

  it('writes a depth as a depth and an altitude as an altitude', () => {
    expect(label(ACT_WATER.levels, 0)).toBe(`${n(6000)} M`);
    expect(label(ACT_ORBIT.levels, 5)).toBe(`▲ ${n(460000)} M`);
  });

  it('writes the range only where arriving at the surface is the subject', () => {
    // Act I ends by breaking the waterline, and this is the station it does it on.
    expect(label(ACT_WATER.levels, ACT_WATER.levels.length - 1)).toBe('200 → 0 M');
    // Act VI arrives at the same waterline from *above*, so the range is written
    // from an altitude - not from a bare minus sign, which is what it printed.
    expect(label(ACT_RAIN.levels, ACT_RAIN.levels.length - 1)).toBe('▲ 400 → 0 M');
  });

  it('never claims an act ends at the surface when it ends six kilometres down', () => {
    const last = ACT_HOME.levels.length - 1;
    expect(ACT_HOME.levels[last]!.depthMeters).toBe(6000);
    expect(label(ACT_HOME.levels, last)).toBe(`${n(6000)} M`);
    expect(label(ACT_HOME.levels, last)).not.toContain('→');
  });

  it('says the same thing about the trench at both ends of the circuit', () => {
    // The campaign's first station and its last are the same place.
    expect(label(ACT_HOME.levels, ACT_HOME.levels.length - 1)).toBe(label(ACT_WATER.levels, 0));
  });
});
