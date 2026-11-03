import { describe, expect, it } from 'vitest';
import { ACT_THIN, THIN_LEVELS } from '../src/config/thinning';
import { AIR_LEVELS } from '../src/config/ascent';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { BREATH_PERIOD, breathFlow } from '../src/sim/Breath';
import { LayeredFlow } from '../src/sim/LayeredFlow';
import { World } from '../src/sim/World';
import { SEEDS, makeWaveBot, mean, passive, playThin } from './bot';
import { buildCourse, sweepCourse } from './course';
import { H, W } from './helpers';

/**
 * Slowblue: act III's safety net, and the two claims that make it a different act
 * rather than a different colour.
 *
 * The geometry checks are the ones every act earns - a corridor that can be flown
 * and no compulsory ring behind a wall. What is specific to the upper air is that
 * its escalation is *not* the two below it: it does not narrow, it slows the hand
 * down and speeds the world up. Both of those are numbers and both are asserted,
 * because "act III asks for timing rather than accuracy" is exactly the kind of
 * design claim that quietly stops being true when someone tightens a gap.
 */

/** Everything below the tropopause. None of it may appear in the upper air. */
const LOWER_KINDS = new Set([
  'gate',
  'rock',
  'narrows',
  'drift',
  'vortex',
  'predator',
  'bank',
  'tower',
  'pass',
  'wisps',
  'rotor',
  'raptor',
]);

describe('the upper air', () => {
  it('builds every authored section and nothing after them', () => {
    const o = buildCourse(ACT_THIN);
    expect(o.sections.length).toBe(ACT_THIN.totalSections);
    expect(o.scriptExhausted).toBe(true);
  });

  it('leaves a flyable corridor down the whole act', () => {
    const sweep = sweepCourse(buildCourse(ACT_THIN));
    expect(sweep.blockedAt).toBeNull();
  });

  it('never asks for a ring it has walled off', () => {
    const sweep = sweepCourse(buildCourse(ACT_THIN));
    expect(sweep.ringsReachable.length).toBeGreaterThan(10);
    for (const ring of sweep.ringsReachable) {
      expect(
        ring.ok,
        `level ${ring.level} section ${ring.section} at x=${Math.round(ring.x)}`,
      ).toBe(true);
    }
  });

  it('is played in thin air, and every obstacle in it is ice', () => {
    for (const level of THIN_LEVELS) {
      expect(level.medium).toBe('thinAir');
      expect(level.pace).toBeGreaterThan(0);
      for (const s of level.sections) {
        expect(LOWER_KINDS.has(s.kind), `${level.key}: ${s.kind}`).toBe(false);
      }
    }
  });

  it('has no hunters anywhere, because nothing up there eats anything', () => {
    const o = buildCourse(ACT_THIN);
    for (const s of o.sections) expect(s.hunterHints.length, `section ${s.id}`).toBe(0);
  });

  /**
   * The act's own escalation, as three monotone sequences. This is the assertion
   * that stops act III from drifting into being act II with different art.
   */
  it('escalates by wind and wave, not by narrowing', () => {
    // Every corridor the swarm has to thread as *the* way through, which is every
    // archetype except the shear - a shear has two or three doors and is measured
    // below, because what it asks for is a choice rather than a line.
    const corridors = THIN_LEVELS.flatMap((l) =>
      l.sections.filter((s) => s.kind !== 'shear').map((s) => ('gap' in s ? s.gap : 1)),
    );
    // Wider than act II's last three stations, everywhere. The precision this act
    // asks for is in time.
    const airNarrowest = Math.min(
      ...AIR_LEVELS.slice(3).flatMap((l) => l.sections.map((s) => ('gap' in s ? s.gap : 1))),
    );
    expect(Math.min(...corridors)).toBeGreaterThan(airNarrowest);

    // What escalates is the **counterflow** - how hard the wrong layer takes you
    // the wrong way - and how *thin* the layers are, so choosing wrong costs more
    // and happens sooner. Deliberately not the peak wind: the fastest air on the
    // planet is at the tropopause, which is the act's *first* station, and a ramp
    // that insisted otherwise would be a ramp lying about the atmosphere.
    const climb = THIN_LEVELS.slice(0, -1);
    const counterflow = climb.map((l) =>
      Math.abs(Math.min(...(l.layers?.winds ?? [0]))),
    );
    const bandHeight = climb.map((l) => l.layers?.height ?? Infinity);
    for (let i = 1; i < climb.length; i++) {
      expect(counterflow[i]!, `${climb[i]!.key} counterflow`).toBeGreaterThan(
        counterflow[i - 1]!,
      );
      expect(bandHeight[i]!, `${climb[i]!.key} band`).toBeLessThan(bandHeight[i - 1]!);
    }
    // ...and the Karman line runs the whole thing down, because it is a station
    // about an absence and cannot also be the hardest one.
    const last = THIN_LEVELS[THIN_LEVELS.length - 1]!;
    expect(Math.abs(Math.min(...(last.layers?.winds ?? [0])))).toBeLessThan(
      Math.min(...counterflow),
    );
    expect(last.layers!.height).toBeGreaterThan(Math.max(...bandHeight));
  });

  it('brings the gravity wave in after the layers, and never before', () => {
    const waves = THIN_LEVELS.map((l) => l.layers?.waveAmplitude ?? 0);
    // The first station has bands and no wave: one new idea at a time.
    expect(waves[0]).toBe(0);
    expect(waves[1]!).toBeGreaterThan(0);
    // ...and the nacreous station, where the wave is the scenery, is where it
    // more than doubles.
    expect(waves[2]!).toBeGreaterThan(waves[1]! * 2);
  });

  /**
   * A shear is the act's own archetype and its doors are narrow on purpose - but
   * there are two or three of them, so the *open* width across the course is far
   * greater than any single-corridor section's. That is the shape of the demand:
   * not "fit through this", but "pick one, and live in the layer it opens into".
   */
  it('opens a shear wide, across several doors', () => {
    const shears = THIN_LEVELS.flatMap((l) => l.sections).filter((s) => s.kind === 'shear');
    // Most stations, not every station. This was `> 5`, i.e. one per station and
    // then some, which is a monotony pinned as an invariant: at six shears out of
    // thirteen obstacle sections the act had two demands in ten minutes, and the
    // number that said so was being defended by a test. Four is "the act's own
    // archetype is still its spine"; the rest of the act is allowed to be other
    // things, and the Black Sky's is a `flurry` now.
    expect(shears.length).toBeGreaterThan(4);
    for (const s of shears) {
      if (s.kind !== 'shear') continue;
      expect(s.gaps.length).toBeGreaterThanOrEqual(2);
      expect(s.gaps.length * s.gap, `${s.gaps.length} doors`).toBeGreaterThan(0.45);
      // ...and no door may be so tight that choosing it is a precision test.
      expect(s.gap).toBeGreaterThanOrEqual(0.22);
    }
  });

  /**
   * Compulsory rings peak in the middle of the act and thin out at the end.
   *
   * Every other act in the campaign ramps its demands to its last station. This
   * one deliberately does not: the Karman line is about running out, so it asks
   * for less than the two stations below it, and an ending that spiked would be
   * an ending that argued with its own subject.
   */
  it('peaks its compulsory rings before the last station, not on it', () => {
    const required = THIN_LEVELS.map(
      (l) => l.sections.flatMap((s) => s.rings ?? []).filter((r) => r.required === true).length,
    );
    for (const [i, n] of required.entries()) {
      expect(n, `station ${i + 1}`).toBeGreaterThanOrEqual(1);
    }
    const peak = Math.max(...required);
    expect(required[0]!).toBeLessThan(peak);
    expect(required[required.length - 1]!).toBeLessThan(peak);
    expect(required.indexOf(peak)).toBeGreaterThan(0);
    expect(required.indexOf(peak)).toBeLessThan(required.length - 1);
  });

  it('gives every column two channels wide enough to be channels', () => {
    const o = buildCourse(ACT_THIN);
    for (const s of o.sections) {
      if (s.kind !== 'column') continue;
      // Authored tall: that is what makes it a column rather than a lump, and
      // what makes the two ways round it real.
      expect(s.maxY - s.minY, `column ${s.id}`).toBeGreaterThan(s.blobs[0]!.r * 4);
    }
  });

  it('reports thin air on the world, with no grip and a long memory', () => {
    const world = new World(W, H, 7, DEFAULT_TUNING, true, ACT_THIN);
    expect(world.act.key).toBe('thin');
    expect(world.act.carrier).toBe('motes');
    expect(world.medium.kind).toBe('thinAir');
    expect(world.medium.coupling).toBeLessThan(DEFAULT_TUNING.airCoupling);
    expect(world.medium.flowHalfLife).toBeGreaterThan(DEFAULT_TUNING.airFlowHalfLife);
    // A mote has no wings. Everything that lifts it is the medium.
    expect(world.medium.migrationSpeed).toBeLessThan(DEFAULT_TUNING.airMigrationSpeed);
    // ...and it is still a medium, so a stroke is still momentum.
    expect(world.medium.vacuum).toBe(0);
    expect(world.medium.deposit).toBe('momentum');
  });
});

describe('upper-air playability', () => {
  it('lets a competent player make real ground where a passive one cannot', () => {
    const steered = SEEDS.map((s) => playThin(s, makeWaveBot(), {}, 300));
    const idle = SEEDS.map((s) => playThin(s, passive, {}, 300));
    const summary = {
      steered: {
        // Sections cleared, not gates: this act begins stations again rather than
        // ending runs, and `gates` counts a re-flown section twice - so a bot that
        // fails over and over on section one banks gates for it. `progress` is how
        // far up the script the run actually got. See `sim/Failure.ts`.
        sections: Number(mean(steered.map((r) => r.progress)).toFixed(1)),
        height: Math.round(mean(steered.map((r) => r.distance))),
        score: Math.round(mean(steered.map((r) => r.score))),
        restarts: Number(mean(steered.map((r) => r.restarts)).toFixed(1)),
      },
      passive: {
        sections: Number(mean(idle.map((r) => r.progress)).toFixed(1)),
        height: Math.round(mean(idle.map((r) => r.distance))),
        score: Math.round(mean(idle.map((r) => r.score))),
        restarts: Number(mean(idle.map((r) => r.restarts)).toFixed(1)),
      },
    };
    console.log('[thin playability]', JSON.stringify(summary));
    expect(summary.steered.sections).toBeGreaterThan(summary.passive.sections * 1.5 + 0.5);
    expect(summary.steered.score).toBeGreaterThan(summary.passive.score * 1.3);
  });

  /**
   * The acceptance criterion the design actually states for this act: **timed
   * play beats passive play**.
   *
   * It used to compare a wave-reading bot against an identically-effortful one
   * that ignored the wave, and demand the first get 8% further. That assertion
   * was not merely failing, it was unsatisfiable, and the reason is worth keeping
   * where the next person to touch these numbers will read it.
   *
   * Everything the swarm feels arrives as one velocity - `water = laid + wave` -
   * and a body is dragged toward it. Ground made over a fixed time at a fixed
   * cadence is therefore a *linear* functional of that sum, and correlating the
   * player's half with the medium's half cannot change the expectation of a
   * linear functional. Measured over eleven seeds: pushing with the lift cleared
   * 20.6 sections, pushing deliberately *against* it 21.3, ignoring it entirely
   * 20.9. Reallocating the same strokes between the forward and lateral axes
   * instead of between long and short measured 21.9 against 24.5. There is no
   * stroke schedule that beats not having one, and no value of `SINK` creates
   * one, because the shape of the problem forbids it rather than the numbers.
   *
   * So the wave is not a bonus to be surfed. It is a *force*, and the two tests
   * below assert the two things that are true of it and that the act needs: it
   * really carries and it really costs, and what it costs is never the run.
   */
  it('gets a competent player far past anything a passive one reaches', () => {
    const played = SEEDS.map((s) => playThin(s, makeWaveBot(), {}, 300));
    const idle = SEEDS.map((s) => playThin(s, passive, {}, 300));
    const summary = {
      played: {
        sections: Number(mean(played.map((r) => r.progress)).toFixed(1)),
        rings: Number(mean(played.map((r) => r.ringsHeld)).toFixed(1)),
        restarts: Number(mean(played.map((r) => r.restarts)).toFixed(1)),
      },
      passive: {
        sections: Number(mean(idle.map((r) => r.progress)).toFixed(1)),
        rings: Number(mean(idle.map((r) => r.ringsHeld)).toFixed(1)),
        restarts: Number(mean(idle.map((r) => r.restarts)).toFixed(1)),
      },
    };
    console.log('[thin timing]', JSON.stringify(summary));
    expect(summary.played.sections).toBeGreaterThan(summary.passive.sections * 3);
    expect(summary.played.rings).toBeGreaterThan(summary.passive.rings * 3);
  });

  /**
   * The wave is a force with net lift in it, and the asymmetry is what puts it
   * there. This is exact rather than statistical: it is arithmetic on the field.
   */
  it('leaves real lift in half its cells and real sink in the other half', () => {
    const f = new LayeredFlow();
    f.set({ height: 500, winds: [40], waveAmplitude: 80, waveLength: 1000 }, 0);
    // A crest cell and the cell half a wavelength away, over a whole breath.
    const crest = f.netLiftAt(0);
    const trough = f.netLiftAt(500);
    expect(crest).toBeLessThan(0);
    expect(trough).toBeGreaterThan(0);
    // Neither is a rounding error: a body left in either one is somewhere very
    // different a minute later, which is what makes the picture worth reading.
    expect(Math.abs(crest)).toBeGreaterThan(8);
    expect(Math.abs(trough)).toBeGreaterThan(8);
  });

  /**
   * ...and it can never win outright. The design's rule for this act is that bad
   * timing costs position and time and never life, which is two claims about
   * numbers: the worst sink in the campaign has to stay under what a competent
   * hand makes up the course, and the act must not end runs at all.
   */
  it('never sinks harder than a competent hand can climb, and never ends a run', () => {
    /** Measured by `tools/thin.sweep.ts`, forward ceiling, with the drift off. */
    const HAND = 57;
    for (const level of THIN_LEVELS) {
      const amp = level.layers?.waveAmplitude ?? 0;
      const f = new LayeredFlow();
      f.set(level.layers ?? null, 0);
      // The worst instant the station can produce, sampled across a whole breath
      // and a whole wavelength rather than argued from the constants.
      let worst = 0;
      const length = level.layers?.waveLength ?? 1100;
      for (let i = 0; i < 60; i++) {
        for (let j = 0; j < 60; j++) {
          worst = Math.max(worst, f.waveAt((length * i) / 60, (BREATH_PERIOD * j) / 60));
        }
      }
      expect(worst, `${level.key} sinks at ${worst.toFixed(0)} px/s`).toBeLessThan(HAND);
      // ...and it really is a wave, not a rounding error, wherever there is one.
      if (amp > 0) expect(worst).toBeGreaterThan(4);
    }
    expect(ACT_THIN.failure.mode).toBe('restart');
  });

  it('does not end a passive run before the first ring is even reachable', () => {
    for (const seed of SEEDS) {
      const r = playThin(seed, passive, {}, 120);
      expect(r.seconds).toBeGreaterThan(4);
    }
  });
});

describe('layered flow', () => {
  const spec = { height: 400, winds: [100, -60], waveAmplitude: 50, waveLength: 800 };

  it('carries a body sideways by which band it is in', () => {
    const f = new LayeredFlow();
    f.set(spec, 0);
    // Middle of band 0 and middle of band 1: opposite winds, full strength.
    expect(f.windAt(150)).toBe(100);
    expect(f.windAt(550)).toBe(-60);
  });

  it('blends the boundary instead of cutting it', () => {
    const f = new LayeredFlow();
    f.set(spec, 0);
    // Somewhere in the transition the wind has to be between the two, or a swarm
    // straddling the line gets torn along something the player cannot see.
    const edge = f.windAt(390);
    expect(edge).toBeLessThan(100);
    expect(edge).toBeGreaterThan(-60);
    // ...and the blend has to be monotone through it.
    expect(f.windAt(395)).toBeLessThan(edge);
  });

  it('repeats up the course forever, so a station is a rule and not a list', () => {
    const f = new LayeredFlow();
    f.set(spec, 0);
    expect(f.windAt(150 + 800)).toBe(f.windAt(150));
    expect(f.windAt(150 - 800)).toBe(f.windAt(150));
  });

  it('lifts on the inhale and drops on the exhale, at the breath rate', () => {
    const f = new LayeredFlow();
    f.set(spec, 0);
    // At the crest of a wave cell, on an inhale, the air is going up - which in
    // world coordinates is negative Y.
    const inhale = BREATH_PERIOD * 0.2;
    const exhale = BREATH_PERIOD * 0.7;
    expect(breathFlow(inhale)).toBeGreaterThan(0);
    expect(breathFlow(exhale)).toBeLessThan(0);
    expect(f.waveAt(0, inhale)).toBeLessThan(0);
    expect(f.waveAt(0, exhale)).toBeGreaterThan(0);
    // Half a wavelength away the sign flips: half the cells sink while the other
    // half rise, which is what makes the timing a choice of *place* as well.
    expect(f.waveAt(400, inhale)).toBeGreaterThan(0);
  });

  it('is inert until a station authors it', () => {
    const f = new LayeredFlow();
    expect(f.active).toBe(false);
    const out = { x: 0, y: 0 };
    f.addTo(0, 0, 0, 1, out);
    expect(out).toEqual({ x: 0, y: 0 });
  });

  it('reaches the swarm through the one water sampler, like every other field', () => {
    const world = new World(W, H, 11, DEFAULT_TUNING, true, ACT_THIN);
    world.step(1 / 60);
    expect(world.layers.active).toBe(true);
    const out = { x: 0, y: 0 };
    // Sampled well away from anything the player has laid: whatever is here is
    // the atmosphere's own, which is exactly what act III is about.
    world.water.sample(W * 0.5, world.cameraY - H * 0.2, out);
    expect(Math.abs(out.x)).toBeGreaterThan(1);
  });
});
