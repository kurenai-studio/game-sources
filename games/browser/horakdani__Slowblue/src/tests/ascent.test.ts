import { describe, expect, it } from 'vitest';
import { ACT_AIR, AIR_LEVELS } from '../src/config/ascent';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { World } from '../src/sim/World';
import { buildCourse, sweepCourse } from './course';
import { H, W } from './helpers';

/**
 * Slowblue: act II's safety net - the same geometry checks act I earns, plus the
 * authoring rules the air adds. DESIGN-ASCENT §10 requires the corridor sweep to
 * hold in any medium; the rest of this file holds the four rules written at the
 * top of `config/ascent.ts`, which is where the act's design actually lives.
 */

/** The water's six archetypes. Not one of them may appear above the waterline. */
const WATER_KINDS = new Set(['gate', 'rock', 'narrows', 'drift', 'vortex', 'predator']);

describe('the air act', () => {
  /**
   * The act's own rule about its two 'hold a line' shapes: `pass` is that demand
   * compressed into 240 px and `street` is it stretched over six or seven hundred,
   * so only one of the two is allowed to be narrow. The file states it in as many
   * words and nothing checked it - a street's gap folds into the same `narrowest`
   * reduction as everything else, where it can never bind.
   */
  it('never narrows a corridor to the width of a slot', () => {
    for (const l of AIR_LEVELS) {
      for (const s of l.sections) {
        if (s.kind !== 'street') continue;
        expect(s.gap, `${l.key} street`).toBeGreaterThanOrEqual(0.42);
      }
    }
  });

  it('builds every authored section and nothing after them', () => {
    const o = buildCourse(ACT_AIR);
    expect(o.sections.length).toBe(ACT_AIR.totalSections);
    expect(o.scriptExhausted).toBe(true);
  });

  it('leaves a flyable corridor down the whole act', () => {
    const sweep = sweepCourse(buildCourse(ACT_AIR));
    expect(sweep.blockedAt).toBeNull();
  });

  it('never asks for a ring it has walled off', () => {
    const sweep = sweepCourse(buildCourse(ACT_AIR));
    // Every compulsory ring must be touchable from the line the flock is already
    // on when it arrives. A dashed ring behind a cloud is an unwinnable run.
    expect(sweep.ringsReachable.length).toBeGreaterThan(10);
    for (const ring of sweep.ringsReachable) {
      expect(ring.ok, `level ${ring.level} section ${ring.section} at x=${Math.round(ring.x)}`).toBe(
        true,
      );
    }
  });

  it('is played in air, and every obstacle in it is cloud', () => {
    for (const level of AIR_LEVELS) {
      expect(level.medium).toBe('air');
      // Rule 3: the drift is a clock in both acts now. An act with no forced
      // drift and no gravity has no reason to move at all.
      expect(level.pace).toBeGreaterThan(0);
      for (const s of level.sections) {
        expect(WATER_KINDS.has(s.kind), `${level.key}: ${s.kind}`).toBe(false);
      }
    }
  });

  it('asks for rings, and asks for more of them the higher it goes', () => {
    const required = AIR_LEVELS.map(
      (l) => l.sections.flatMap((s) => s.rings ?? []).filter((r) => r.required === true).length,
    );
    // Rule 2. Act II used to have no compulsory ring anywhere in it, which left
    // an act with nothing to do but avoid things.
    for (const [i, n] of required.entries()) {
      expect(n, `station ${i + 1}`).toBeGreaterThanOrEqual(1);
    }
    expect(required[0]!).toBeLessThan(required[AIR_LEVELS.length - 1]!);
  });

  it('narrows its gaps and quickens its pace station by station', () => {
    // Rule 3, as two monotone sequences. This is the only difficulty ramp the act
    // has - there is no pressure ramp inside a station, exactly as in act I.
    const narrowest = AIR_LEVELS.map((l) =>
      Math.min(
        ...l.sections.map((s) => ('gap' in s ? s.gap : 1)),
      ),
    );
    expect(narrowest[0]!).toBeGreaterThan(0.55);
    expect(narrowest[AIR_LEVELS.length - 1]!).toBeLessThan(0.3);
    for (let i = 1; i < AIR_LEVELS.length; i++) {
      expect(narrowest[i]!, `station ${i + 1} gap`).toBeLessThanOrEqual(narrowest[i - 1]!);
      expect(AIR_LEVELS[i]!.pace, `station ${i + 1} pace`).toBeGreaterThan(AIR_LEVELS[i - 1]!.pace);
    }
  });

  it('closes all but the last station on a breath', () => {
    // Rule 4. The last one closes on empty air with no ring in it at all, because
    // the ending needs somewhere to happen.
    for (const level of AIR_LEVELS) {
      const last = level.sections[level.sections.length - 1]!;
      expect(last.kind, level.key).toBe('open');
    }
  });

  /**
   * Slowblue: a street's corridor has to be the widest water on its own line.
   *
   * The two lines of a street run *along* the course, so unlike every other
   * archetype in the game they do not reach the edges of the field for most of
   * their length. That leaves open water outside them - dead water, because the
   * mouth's converging shoulders mean nothing can ever get into it - and dead
   * water is fine right up until it is *wider* than the corridor. At that point
   * anything that steers by looking for the widest gap on a line aims at a pocket
   * it can never enter, which is not a hard failure but a silent one: the flock
   * spends the whole street leaning against a wall.
   *
   * The arithmetic is small enough to author against. The corridor is `gap` of
   * the width and the larger pocket is `(1 - gap) / 2 + |centre - 0.5|`, so the
   * corridor wins while `gap > (1 - gap) / 2 + offset`. At dead centre that is a
   * gap over a third; off centre it costs a third of the offset again. The three
   * streets act II authors clear it by 0.07, 0.19 and 0.19 of the width.
   *
   * Asserted on the built geometry rather than on the arithmetic, because the
   * arithmetic is what would be wrong if the shape ever changed.
   */
  it('never leaves more open water outside a street than inside it', () => {
    const o = buildCourse(ACT_AIR);
    let checked = 0;
    for (const [i, s] of o.sections.entries()) {
      const spec = ACT_AIR.script[i]!.spec;
      if (spec.kind !== 'street') continue;
      checked++;
      // Mid-corridor: past the mouth's shoulders, inside the straight run.
      const y = s.lineY + (s.entryY - s.lineY) * 0.3;
      // Every run of open water on that line, as [start, width].
      const runs: { start: number; width: number }[] = [];
      let start: number | null = null;
      for (let x = 0; x <= W; x += 2) {
        const open = o.hit(x, y, 1) === null;
        if (open && start === null) start = x;
        if ((!open || x >= W) && start !== null) {
          runs.push({ start, width: x - start });
          start = null;
        }
      }
      const widest = runs.reduce((a, b) => (b.width > a.width ? b : a));
      const centre = spec.centre * W;
      expect(runs.length, `street ${s.id} is not a corridor`).toBeGreaterThan(1);
      // The widest water on the line is the authored corridor, not a pocket.
      expect(
        widest.start <= centre && centre <= widest.start + widest.width,
        `street ${s.id}: widest water is at ${Math.round(widest.start)}..` +
          `${Math.round(widest.start + widest.width)}, corridor is at ${Math.round(centre)}`,
      ).toBe(true);
    }
    expect(checked, 'act II authors no streets').toBeGreaterThan(2);
  });

  it('gives every cloud a splittable body only where it means to', () => {
    const o = buildCourse(ACT_AIR);
    for (const s of o.sections) {
      if (s.kind !== 'tower') continue;
      // A tower is authored tall: that is the whole difference between it and the
      // rock it replaces, and it is what makes the two channels channels.
      expect(s.maxY - s.minY, `tower ${s.id}`).toBeGreaterThan(s.blobs[0]!.r * 2.6);
    }
  });

  it('reports the act on the world so the shell can tell them apart', () => {
    const air = new World(W, H, 7, DEFAULT_TUNING, true, ACT_AIR);
    const water = new World(W, H, 7);
    expect(air.act.key).toBe('air');
    expect(water.act.key).toBe('water');
    expect(air.medium.kind).toBe('air');
    expect(water.medium.kind).toBe('water');
  });
});
