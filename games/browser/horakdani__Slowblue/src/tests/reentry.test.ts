import { describe, expect, it } from 'vitest';
import { ACT_REENTRY, REENTRY_LEVELS } from '../src/config/reentry';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { SECTION_SPACING } from '../src/sim/ObstacleSystem';
import { mediumFor } from '../src/sim/Medium';
import { World } from '../src/sim/World';
import { SEEDS, makeAimBot, mean, passive, playRun } from './bot';
import { buildCourse, sweepCourse } from './course';
import { H, W } from './helpers';

/**
 * Slowblue: act V's safety net, and the two claims nothing else in the campaign makes.
 *
 * It is the **first act that falls**, so everything the direction abstraction was
 * built for is exercised here for the first time by real authored content rather
 * than by act I's levels played backwards. And it is the act where **the input
 * changes under the player's hand** - gravity gives way to wind continuously,
 * with no frame on which it happened - which is a claim about a curve and is
 * therefore checked as one.
 */

/** An authored spacing, or the campaign default the level file leaves implicit. */
const spacingOf = (s: { spacing?: number }): number => s.spacing ?? SECTION_SPACING;

describe('the fallback', () => {
  /**
   * The act's three written rules, none of which had a test.
   *
   * The contraction is the act's rhythm and its whole statement about the medium;
   * the pair grammar is what makes it the one act that pays for width; and "never
   * two compulsory rings on one line" is a rule the file records having already
   * broken once, at the plasma's plume, where 56 % of the swarm was being asked
   * for in two places at the fastest pace in the act.
   */
  it('keeps the contraction, and its own ring grammar', () => {
    const totals = REENTRY_LEVELS.map((l) =>
      l.sections.reduce((t, s) => t + (s.spacing ?? SECTION_SPACING), 0),
    );
    /*
     * Slowblue: these were [3970, 3590, 3250, 2420, 2870, 4270] - 20 370 px and 10.9
     * minutes - until act V became the pilot for the campaign's length. The act is
     * twice as long now and the *shape* is what this line is actually guarding:
     * a contraction from the deorbit to the plasma and a release at the nucleus,
     * with the plasma flat on the floor. That shape is asserted underneath rather
     * than left implied by six literals, so a future rebuild has to break the
     * rhythm to fail this rather than merely lengthen it.
     *
     * See `docs/DESIGN-LENGTH.md` for why 20.1 minutes rather than 10.9, and
     * `src/config/reentry.ts` for what went into them.
     */
    expect(totals).toEqual([5860, 7730, 8725, 10640, 11615, 8620]);
    const longest = REENTRY_LEVELS.map((l) => Math.max(...l.sections.map(spacingOf)));
    // Each station's widest gap is narrower than the last one's, down to the
    // plasma - the contraction, read across the act.
    for (let i = 1; i <= 3; i++) {
      expect(
        longest[i]!,
        `${REENTRY_LEVELS[i]!.key} opens wider than the station before it`,
      ).toBeLessThan(longest[i - 1]!);
    }
    // ...and the two stations after it open again. The release.
    expect(longest[5]!).toBeGreaterThan(longest[4]!);

    /*
     * The plasma is the floor, and the floor is measured in **seconds**.
     *
     * It used to be measurable in pixels: the plasma's 560 px were the shortest
     * gaps in act V and nothing was under them. The couplets broke that - the
     * night side's is 400 px - and the first version of this assertion duly
     * failed, which turned out to be the assertion being wrong rather than the
     * act. Spacing is not comparable across stations that run at different paces,
     * and act V's run from 0.34 to 0.70. Four hundred pixels at the night side's
     * drift is 14.7 seconds; five hundred and sixty at the plasma's is 11.8. The
     * peak is still the peak, and the couplets are tight in the one unit the
     * player does not experience.
     */
    const seconds = REENTRY_LEVELS.map((l) =>
      Math.min(...l.sections.map((s) => spacingOf(s) / (DEFAULT_TUNING.worldSpeed * l.pace))),
    );
    expect(Math.min(...seconds), 'the plasma is the tightest station in time').toBe(seconds[3]);
    for (const l of REENTRY_LEVELS) {
      for (const s of l.sections) {
        const rings = s.rings ?? [];
        const required = rings.filter((r) => r.required === true);
        expect(required.length, `${l.key}/${s.kind} required rings`).toBeLessThanOrEqual(1);
        /*
         * Two rings on one line are 0.25 to 0.35 of the width apart: closer and an
         * ordinary body covers both without having been asked for anything, wider
         * and no body covers both at all.
         *
         * Not on a splittable mass. Two rings either side of a `plume` or a `tower`
         * share a `dy` and are two thirds of the width apart, and they mean the
         * opposite thing - one body cannot hold both, which is the point of them.
         */
        if (s.kind === 'plume' || s.kind === 'tower' || s.kind === 'hulk') continue;
        for (let i = 0; i < rings.length; i++) {
          for (let j = i + 1; j < rings.length; j++) {
            if (rings[i]!.dy !== rings[j]!.dy) continue;
            const apart = Math.abs(rings[i]!.x - rings[j]!.x);
            expect(apart, `${l.key}/${s.kind} pair`).toBeGreaterThanOrEqual(0.25);
            expect(apart, `${l.key}/${s.kind} pair`).toBeLessThanOrEqual(0.35);
          }
        }
      }
    }
  });

  /**
   * Slowblue: the rule the rebuild was taught by a measurement.
   *
   * Built with its rest moved to the middle of each station and a compulsory ring
   * on each station's last section, this act measured 35.6 restarts a run against
   * the old one's 1.2 - every one of them `sweptAway`. A station's pressure ramp
   * peaks at its own end, a compulsory ring asks the swarm to stop and hold still,
   * and the two demands are opposite. The old four-section stations never
   * collided them because they all happened to end on empty medium; at twice the
   * length that accident stopped covering for us.
   *
   * So: the last thing in a station is a rest, and the last *demand* in a station
   * is not a gate. Both halves, because measured one at a time they are worth
   * 15.4 and 42.6 restarts and together they are worth 6.8.
   */
  it('never ends a station on a gate, and always lands it', () => {
    for (const level of REENTRY_LEVELS) {
      const last = level.sections[level.sections.length - 1]!;
      const demands = level.sections.filter((s) => s.kind !== 'open');
      const lastDemand = demands[demands.length - 1]!;
      const gate = (s: { rings?: { required?: boolean }[] }): boolean =>
        (s.rings ?? []).some((r) => r.required === true);
      expect(gate(lastDemand), `${level.key} ends its demands on a compulsory ring`).toBe(false);
      // The plasma keeps half of its old exception: no rest in its *middle*, which
      // is fourteen demands in a row. It lands like everything else, because the
      // version that did not measured two completions in seven worse.
      if (level.key === 'plasma') {
        expect(level.sections.slice(0, -1).every((s) => s.kind !== 'open')).toBe(true);
      }
      expect(last.kind, `${level.key} does not land`).toBe('open');
    }
  });

  it('builds every authored section and nothing after them', () => {
    const o = buildCourse(ACT_REENTRY);
    expect(o.sections.length).toBe(ACT_REENTRY.totalSections);
    expect(o.scriptExhausted).toBe(true);
  });

  it('leaves a flyable corridor down the whole act', () => {
    const sweep = sweepCourse(buildCourse(ACT_REENTRY));
    expect(sweep.blockedAt).toBeNull();
  });

  it('never asks for a ring it has walled off', () => {
    const sweep = sweepCourse(buildCourse(ACT_REENTRY));
    expect(sweep.ringsReachable.length).toBeGreaterThan(10);
    for (const ring of sweep.ringsReachable) {
      expect(
        ring.ok,
        `level ${ring.level} section ${ring.section} at x=${Math.round(ring.x)}`,
      ).toBe(true);
    }
  });

  it('is the first act that falls, and its course is built that way round', () => {
    expect(ACT_REENTRY.direction).toBe(1);
    const o = buildCourse(ACT_REENTRY);
    // Falling, "further along" is *larger* Y, so every section line is beyond the
    // one before it in the other direction from every act so far.
    for (let i = 1; i < o.sections.length; i++) {
      expect(o.sections[i]!.lineY, `section ${i}`).toBeGreaterThan(o.sections[i - 1]!.lineY);
    }
    // ...and `entryY`/`exitY` are the other way round from a climb: the swarm
    // meets the *smallest* Y of a section first.
    for (const s of o.sections) {
      expect(s.entryY).toBeLessThanOrEqual(s.exitY);
    }
  });

  /**
   * The act's whole subject, as a curve.
   *
   * `vacuum` is how much of the medium is not there: 1 in orbit, 0 in weather. Act
   * V is the handover, and the design's rule is that it must be *continuous* -
   * there is no frame on which the input swapped, because the air does not arrive,
   * it thickens. So the value has to fall monotonically across the act and it has
   * to reach both ends.
   */
  it('takes the vacuum out of the medium continuously, from 1 to 0', () => {
    const world = new World(W, H, 7, DEFAULT_TUNING, true, ACT_REENTRY);
    const samples: number[] = [];
    for (let level = 0; level < REENTRY_LEVELS.length; level++) {
      const spec = REENTRY_LEVELS[level]!;
      const from = mediumFor(spec.medium ?? 'water', DEFAULT_TUNING);
      const to = mediumFor(spec.mediumTo ?? spec.medium ?? 'water', DEFAULT_TUNING);
      // Five points across each station, which is what `World.levelProgress` feeds
      // `blendMedium` in a real run.
      for (let i = 0; i < 5; i++) {
        const t = i / 4;
        samples.push(from.vacuum + (to.vacuum - from.vacuum) * t);
      }
    }
    expect(samples[0]).toBe(1);
    expect(samples[samples.length - 1]).toBe(0);
    for (let i = 1; i < samples.length; i++) {
      expect(samples[i]!, `sample ${i}`).toBeLessThanOrEqual(samples[i - 1]!);
      // No step bigger than a third: the handover is a slope, never a switch.
      expect(samples[i - 1]! - samples[i]!, `step at ${i}`).toBeLessThan(0.34);
    }
    expect(world.medium.vacuum).toBe(1);
  });

  it('gives the hand back its grip on the way down', () => {
    // Coupling is the medium answering a stroke, and act V is the act where it
    // comes back. Zero in orbit, and the sea's own order of magnitude by the end.
    const kinds = REENTRY_LEVELS.map((l) => mediumFor(l.medium ?? 'water', DEFAULT_TUNING));
    expect(kinds[0]!.coupling).toBe(0);
    expect(kinds[kinds.length - 1]!.coupling).toBeGreaterThan(DEFAULT_TUNING.airCoupling);
    for (let i = 1; i < kinds.length; i++) {
      expect(kinds[i]!.coupling, `station ${i}`).toBeGreaterThanOrEqual(kinds[i - 1]!.coupling);
    }
  });

  /**
   * The act is a transformation, so it is the one place in the campaign where two
   * alphabets are allowed in the same act - orbit's at the top, the air's at the
   * bottom, and its own three in between. What must *not* happen is the two
   * meeting: no station may hold both vacuum debris and weather.
   */
  it('hands one vocabulary over to the next without ever mixing them', () => {
    const DEBRIS = new Set(['arc', 'hulk', 'strait', 'shrapnel', 'node', 'flare']);
    const WEATHER = new Set(['bank', 'tower', 'pass', 'wisps', 'rotor', 'raptor']);
    let lastDebris = -1;
    let firstWeather = REENTRY_LEVELS.length;
    REENTRY_LEVELS.forEach((l, i) => {
      const kinds = l.sections.map((s) => s.kind);
      if (kinds.some((k) => DEBRIS.has(k))) lastDebris = Math.max(lastDebris, i);
      if (kinds.some((k) => WEATHER.has(k))) firstWeather = Math.min(firstWeather, i);
      // Never both in one station.
      expect(
        kinds.some((k) => DEBRIS.has(k)) && kinds.some((k) => WEATHER.has(k)),
        `${l.key} mixes vacuum and weather`,
      ).toBe(false);
    });
    // Debris runs out before weather begins, and both actually appear.
    expect(lastDebris).toBeGreaterThanOrEqual(0);
    expect(firstWeather).toBeLessThan(REENTRY_LEVELS.length);
    expect(lastDebris).toBeLessThan(firstWeather);
  });

  it('peaks in the middle, because the difficulty peak is not the finale', () => {
    const paces = REENTRY_LEVELS.map((l) => l.pace);
    const peak = Math.max(...paces);
    const at = paces.indexOf(peak);
    expect(at).toBeGreaterThan(0);
    expect(at).toBeLessThan(paces.length - 1);
    // ...and the plasma is where it peaks, which is the station that is about
    // arriving hard rather than the one that is about having arrived.
    expect(REENTRY_LEVELS[at]!.key).toBe('plasma');
  });

  it('reports the right world: falling, dust, and no ending', () => {
    const world = new World(W, H, 7, DEFAULT_TUNING, true, ACT_REENTRY);
    expect(world.act.key).toBe('reentry');
    expect(world.act.carrier).toBe('dust');
    expect(world.direction).toBe(1);
    expect(world.act.failure.mode).toBe('restart');
  });
});

describe('fallback playability', () => {
  /**
   * A mistake sets a station back here; it does not end a run. That is the act's
   * own guarantee and it is all this probe asserts.
   *
   * It used to be written as "cannot end a run, however badly it is played", which
   * was §12's unqualified promise for acts IV onward. §19 narrowed it: an act
   * carries two station restarts and the third failure ends the attempt. The count
   * is asserted per act by `tests/checkpoint.test.ts`; here the budget is left
   * unbounded (`World.restartBudget`'s default) so that a fixed-time instrument
   * keeps measuring the act rather than the budget.
   */
  it('sets a station back on a mistake rather than ending the run', () => {
    for (const seed of SEEDS.slice(0, 5)) {
      for (const policy of [passive, makeAimBot({ strokeDt: 0.03, reactDistance: 150 })]) {
        const r = playRun(seed, policy, {}, 200, true, ACT_REENTRY);
        expect(r.reason, `seed ${seed}`).toBeNull();
      }
    }
  });

  it('lets a competent player make real ground where a passive one cannot', () => {
    const steered = SEEDS.map((s) =>
      playRun(s, makeAimBot({ strokeDt: 0.4 }), {}, 300, true, ACT_REENTRY),
    );
    const idle = SEEDS.map((s) => playRun(s, passive, {}, 300, true, ACT_REENTRY));
    const summary = {
      steered: {
        sections: Number(mean(steered.map((r) => r.progress)).toFixed(1)),
        score: Math.round(mean(steered.map((r) => r.score))),
        restarts: Number(mean(steered.map((r) => r.restarts)).toFixed(1)),
      },
      passive: {
        sections: Number(mean(idle.map((r) => r.progress)).toFixed(1)),
        score: Math.round(mean(idle.map((r) => r.score))),
        restarts: Number(mean(idle.map((r) => r.restarts)).toFixed(1)),
      },
    };
    console.log('[reentry playability]', JSON.stringify(summary));
    expect(summary.steered.sections).toBeGreaterThan(summary.passive.sections * 1.5 + 0.5);
    expect(summary.steered.score).toBeGreaterThan(summary.passive.score * 1.3);
  });
});
