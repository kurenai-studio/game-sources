import { describe, expect, it } from 'vitest';
import { ACT_ORBIT, ORBIT_LEVELS } from '../src/config/orbit';
import { THIN_LEVELS } from '../src/config/thinning';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { World } from '../src/sim/World';
import { SEEDS, makeAimBot, makeOrbitBot, mean, passive, playRun, type Policy } from './bot';
import { buildCourse, sweepCourse } from './course';
import { H, W } from './helpers';

/**
 * Slowblue: act IV's safety net.
 *
 * The geometry checks are the ones every act earns. What is specific to orbit is
 * that it is the first act whose *input* is different, the first that cannot end
 * a campaign, and the first with no medium at all - so the three things asserted
 * hardest here are that a stroke lays potential rather than momentum, that
 * nothing damps anything, and that no path through the act can lose a run.
 */

/** Everything below the Karman line. None of it may appear in orbit. */
const LOWER_KINDS = new Set([
  'gate', 'rock', 'narrows', 'drift', 'vortex', 'predator',
  'bank', 'tower', 'pass', 'wisps', 'rotor', 'raptor',
  'veil', 'column', 'throat', 'flurry', 'eddy', 'shear',
]);

function orbitWorld(seed = 7): World {
  return new World(W, H, seed, DEFAULT_TUNING, true, ACT_ORBIT);
}

describe('orbit', () => {
  it('builds every authored section and nothing after them', () => {
    const o = buildCourse(ACT_ORBIT);
    expect(o.sections.length).toBe(ACT_ORBIT.totalSections);
    expect(o.scriptExhausted).toBe(true);
  });

  it('leaves a flyable corridor down the whole act', () => {
    const sweep = sweepCourse(buildCourse(ACT_ORBIT));
    expect(sweep.blockedAt).toBeNull();
  });

  it('never asks for a ring it has walled off', () => {
    const sweep = sweepCourse(buildCourse(ACT_ORBIT));
    expect(sweep.ringsReachable.length).toBeGreaterThan(10);
    for (const ring of sweep.ringsReachable) {
      expect(
        ring.ok,
        `level ${ring.level} section ${ring.section} at x=${Math.round(ring.x)}`,
      ).toBe(true);
    }
  });

  it('is played in vacuum, and every obstacle in it is wreckage', () => {
    for (const level of ORBIT_LEVELS) {
      expect(level.medium).toBe('space');
      // Vacuum has no turbulence and no standing currents in it. Both of those
      // are properties of a medium and there is no medium.
      expect(level.roughness).toBe(0);
      expect(level.swirl).toBe(0);
      for (const s of level.sections) {
        expect(LOWER_KINDS.has(s.kind), `${level.key}: ${s.kind}`).toBe(false);
      }
    }
  });

  it('has no hunters anywhere, because nothing in orbit hunts', () => {
    const o = buildCourse(ACT_ORBIT);
    for (const s of o.sections) expect(s.hunterHints.length, `section ${s.id}`).toBe(0);
  });

  /**
   * The one number act IV is built on. `vacuum` at 1 means a stroke lays the
   * whole of itself as potential and none of it as momentum, nothing drags a
   * body toward anything, and nothing self-propels.
   */
  it('reports vacuum on the world: no grip, no drive, no drag', () => {
    const world = orbitWorld();
    expect(world.act.key).toBe('orbit');
    expect(world.act.carrier).toBe('lights');
    expect(world.medium.kind).toBe('space');
    expect(world.medium.vacuum).toBe(1);
    expect(world.medium.deposit).toBe('potential');
    expect(world.medium.coupling).toBe(0);
    expect(world.medium.migrationSpeed).toBe(0);
    expect(world.medium.migrationForce).toBe(0);
  });

  it('turns a stroke into gravity rather than into current', () => {
    const world = orbitWorld();
    const before = world.potential.wells.length;
    world.injectStroke(W * 0.4, -200, W * 0.6, -300, 0.25);
    expect(world.potential.wells.length).toBeGreaterThan(before);
    // ...and none of it went into the water. In vacuum there is nothing to push.
    const out = { x: 0, y: 0 };
    world.field.sample(W * 0.5, -250, out);
    expect(Math.hypot(out.x, out.y)).toBe(0);
  });

  /**
   * The act's own archetype, as a field rather than as geometry. A `node` is a
   * standing gravity well the level author placed, and it is the same object the
   * player's hand lays - which is the cleanest statement available that up here
   * the medium and the input are one thing.
   */
  it('places standing gravity that never decays and cannot be scribbled away', () => {
    const o = buildCourse(ACT_ORBIT);
    const nodes = o.sections.filter((s) => s.kind === 'node');
    // Three, in an eighteen-section act: one in the first station that helps,
    // one at the ramp's peak that does not, and one the last hard station is
    // built around. The count was five when the act was twice as long and the
    // number was never the point - what is asserted is below.
    expect(nodes.length).toBeGreaterThanOrEqual(3);
    for (const s of nodes) expect(s.wellHints.length, `section ${s.id}`).toBe(1);

    const world = orbitWorld();
    world.potential.add(0, 0, 100, 200, true);
    const standing = world.potential.wells.filter((w) => w.standing === true);
    expect(standing.length).toBe(1);
    // Ten seconds of decay at the tuned half-life would leave a laid well at
    // about a fifteenth. A standing one does not move.
    world.potential.step(10, DEFAULT_TUNING.potentialHalfLife);
    expect(world.potential.wells.filter((w) => w.standing === true).length).toBe(1);
    expect(standing[0]!.life).toBe(1);
    // ...and filling the field with laid wells never evicts it.
    for (let i = 0; i < 60; i++) world.potential.add(i, i, 10, 50);
    expect(world.potential.wells.filter((w) => w.standing === true).length).toBe(1);
  });

  /**
   * Both signs are used, and that matters: a well that only ever pulls is a
   * gathering tool, and the act needs at least one thing the swarm has to be
   * aimed *away* from before there is any cost to aiming badly.
   */
  it('uses gravity in both directions', () => {
    const wells = buildCourse(ACT_ORBIT).sections.flatMap((s) => s.wellHints);
    expect(wells.some((w) => w.strength > 0)).toBe(true);
    expect(wells.some((w) => w.strength < 0)).toBe(true);
  });

  /**
   * The orbital gate. Its two halves sweep *back* down the course from the
   * opening, so the hole cannot be reached in a straight line from where the
   * swarm meets the section - which is the whole reason act IV needs no tutorial
   * for its new input. Asserted on the built geometry rather than on the spec,
   * because it is a claim about what the player meets.
   */
  it('bows every orbital gate away from a straight line in', () => {
    const o = buildCourse(ACT_ORBIT);
    const arcs = o.sections.filter((s) => s.kind === 'arc');
    /*
     * At least one in every climbing station, and none at all in the Overview.
     *
     * Slowblue: this was `toBe(ORBIT_LEVELS.length - 1)` - *exactly* one a station,
     * on the argument that the bow is what escalates so the gate carrying it
     * appears once and never twice. That was true of an act of eighteen sections,
     * where one arc a station was a third of the station's demands. The act is
     * fifty-six sections now and one arc a station would make the act's signature
     * shape a tenth of it: the claim would have been holding the *count* while
     * quietly making the thing it counts rare.
     *
     * What it was actually protecting is the ramp, and the ramp has a test of its
     * own next door - `escalates on commitment rather than on width` walks the
     * stations and requires each one's widest bow to beat the last one's, which is
     * a stronger statement than any number of arcs and is the one that would fail
     * if the escalation were ever flattened. Measured on the rebuilt act: 0.10,
     * 0.18, 0.22, 0.34, 0.42, and nothing in the Overview.
     */
    const perStation = ORBIT_LEVELS.map((l) => l.sections.filter((s) => s.kind === 'arc').length);
    for (let i = 0; i < ORBIT_LEVELS.length - 1; i++) {
      expect(perStation[i], `${ORBIT_LEVELS[i]!.key} has no orbital gate`).toBeGreaterThan(0);
    }
    expect(perStation[perStation.length - 1], 'the Overview has a gate in it').toBe(0);
    const dir = ACT_ORBIT.direction;
    /** Course coordinate: larger is further ahead. `World.u()`'s convention. */
    const u = (worldY: number): number => dir * worldY;
    for (const s of arcs) {
      // The wall's ends are further back down the course than its mouth is.
      const nearMouth = s.blobs.filter((b) => Math.abs(b.x - W * 0.5) < W * 0.5);
      expect(nearMouth.length).toBeGreaterThan(3);
      const spread = s.maxY - s.minY;
      expect(spread, `arc ${s.id} is flat`).toBeGreaterThan(W * 0.08);
      /*
       * ...and bowed the right way, which `spread` cannot see.
       *
       * Slowblue: this assertion was `spread` alone, and `spread` is sign-blind - it
       * is `maxY - minY` and is the same number for a shape and for its mirror.
       * That is how `debrisArc` shipped with its bow inverted, which put every
       * arc's wing tips *further along* the course than its opening and ran act
       * IV's one escalation axis backwards for the whole life of the act. A
       * geometric claim about which part arrives first has to be asserted in
       * course coordinates or it is not being asserted at all.
       */
      const byX = [...s.blobs].sort((a, b) => a.x - b.x);
      const deepest = Math.max(...s.blobs.map((b) => u(b.y)));
      for (const tip of [byX[0]!, byX[byX.length - 1]!]) {
        expect(
          deepest - u(tip.y),
          `arc ${s.id} tip at x=${Math.round(tip.x)} is not met before the opening`,
        ).toBeGreaterThan(W * 0.05);
      }
    }
  });

  /**
   * Act IV does not narrow. Like act III it escalates on something else - here on
   * how *early* the player has to have committed, which is the bow - and a ramp
   * that quietly tightened the gaps instead would be a ramp arguing with the act.
   */
  it('escalates on commitment rather than on width', () => {
    const climb = ORBIT_LEVELS.slice(0, -1);
    const bows = climb.map((l) =>
      Math.max(...l.sections.map((s) => (s.kind === 'arc' ? s.bow : 0))),
    );
    for (let i = 1; i < bows.length; i++) {
      expect(bows[i]!, `${climb[i]!.key} bow`).toBeGreaterThan(bows[i - 1]!);
    }
    // ...and the corridors stay at least as wide as act III's.
    const orbitNarrowest = Math.min(
      ...ORBIT_LEVELS.flatMap((l) =>
        l.sections.filter((s) => s.kind !== 'flare').map((s) => ('gap' in s ? s.gap ?? 1 : 1)),
      ),
    );
    const thinNarrowest = Math.min(
      ...THIN_LEVELS.flatMap((l) =>
        l.sections.filter((s) => s.kind !== 'shear').map((s) => ('gap' in s ? s.gap : 1)),
      ),
    );
    expect(orbitNarrowest).toBeGreaterThanOrEqual(thinNarrowest);
  });

  /**
   * The Overview is the emotional peak and asks for the least. Every other act ramps
   * to its last station; this one runs down into it, because the camera is about
   * to turn and a station with anything to do in it could not carry that.
   */
  it('runs itself down into the Overview instead of peaking on it', () => {
    const last = ORBIT_LEVELS[ORBIT_LEVELS.length - 1]!;
    expect(last.key).toBe('overview');
    expect(last.pace).toBeLessThan(Math.min(...ORBIT_LEVELS.slice(0, -1).map((l) => l.pace)));
    // No standing gravity, and no wall of any kind.
    //
    // This compared the station's widest `bow` against the act's, which is a test
    // that passes whether the station has a shallow arc in it or no arc at all -
    // `Math.max` of an empty set of arcs is 0 and 0 is less than everything. The
    // claim is the stronger one: the emotional peak of the campaign has nothing in
    // it to be flown around.
    expect(last.sections.some((s) => s.kind === 'node')).toBe(false);
    expect(last.sections.some((s) => s.kind === 'arc'), 'the Overview carries a wall').toBe(
      false,
    );
    // ...and it asks for nothing: an act whose failure policy is `restart` cannot
    // afford a compulsory ring on the one station it is all for.
    for (const s of last.sections) {
      for (const r of s.rings ?? []) expect(r.required ?? false, 'the Overview demands').toBe(false);
    }
    // ...and it ends on open vacuum with nothing in it.
    expect(last.sections[last.sections.length - 1]!.kind).toBe('open');
  });
});

describe('orbit playability', () => {
  /**
   * What a mistake does here, and the one claim about it this probe can carry.
   *
   * §12 stated it as **acts IV onward cannot cause a campaign game over** and this
   * test asserted exactly that: played badly, played passively, or not played at
   * all, the run does not end. §19 has narrowed it - an act carries two station
   * restarts and the third failure ends the attempt - so the unqualified sentence
   * is no longer true of the shipped game.
   *
   * What is still true, and is what this act's water has to guarantee, is the
   * mechanism underneath it: **a mistake here sets a station back. It does not end
   * a run.** The probe runs with the budget unbounded (`World.restartBudget`'s
   * default) precisely so that it measures that and nothing else - a fixed-time
   * instrument whose runs can be ended early is measuring the budget instead of
   * the act. The count itself is asserted per act, in the campaign, by
   * `tests/checkpoint.test.ts`.
   */
  it('sets a station back on a mistake rather than ending the run', () => {
    for (const seed of SEEDS.slice(0, 5)) {
      for (const policy of [passive, makeAimBot({ strokeDt: 0.03, reactDistance: 150 })]) {
        const r = playRun(seed, policy, {}, 200, true, ACT_ORBIT);
        expect(r.reason, `seed ${seed}`).toBeNull();
      }
    }
  });

  it('sets a station back instead, so bad play still costs something', () => {
    const idle = SEEDS.slice(0, 5).map((s) => playRun(s, passive, {}, 200, true, ACT_ORBIT));
    // A swarm nobody steers is left behind over and over: no ending, real cost.
    expect(mean(idle.map((r) => r.restarts))).toBeGreaterThan(1);
    expect(mean(idle.map((r) => r.progress))).toBeLessThan(6);
  });

  it('lets a competent player make real ground where a passive one cannot', () => {
    const steered = SEEDS.map((s) =>
      playRun(s, makeAimBot({ strokeDt: 0.4 }), {}, 300, true, ACT_ORBIT),
    );
    const idle = SEEDS.map((s) => playRun(s, passive, {}, 300, true, ACT_ORBIT));
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
    console.log('[orbit playability]', JSON.stringify(summary));
    expect(summary.steered.sections).toBeGreaterThan(summary.passive.sections * 1.5 + 0.5);
    expect(summary.steered.score).toBeGreaterThan(summary.passive.score * 1.3);
  });

  /**
   * Slowblue: the act's verb, pinned to what the act actually pays for.
   *
   * Act IV's stated verb used to be *start it, then let go*, and it was wrong -
   * measurably, and monotonically. `makeOrbitBot` exists to play that sentence
   * as well as it can be played: read the swarm's velocity, lay a well a long
   * way outside its own radius, then wait. Over eleven seeds it clears a
   * fraction of what a bot that simply aims close and often does, and the more
   * patience it is given the worse it gets - at a 460 px lead it makes no ground
   * at all in five minutes.
   *
   * The design took the measurement rather than tuning the number toward the
   * sentence: the verb is now *aim ahead of them* (DESIGN-ASCENT §8). This test
   * is what stops the two drifting apart again. It is deliberately an *ordering*
   * rather than a value - the numbers move whenever `potentialStrength` does,
   * and what must not move is which way round they are, because that is the
   * claim printed on the act-select screen.
   *
   * Short runs and a wide margin: `tools/space.sweep.ts` is where the precise
   * table lives, and this only has to catch an inversion.
   */
  it('pays for aiming ahead rather than for letting go', () => {
    const play = (policy: Policy): number =>
      mean(SEEDS.slice(0, 5).map((s) => playRun(s, policy, {}, 120, true, ACT_ORBIT).progress));
    const aiming = play(makeAimBot({ strokeDt: 0.4 }));
    // The purest form of the verb this act used to claim: a long lead, and hands
    // off between strokes.
    const lettingGo = play(makeOrbitBot({ lead: 460, hold: 1.3 }));
    console.log('[orbit verb]', JSON.stringify({ aiming, lettingGo }));
    expect(aiming).toBeGreaterThan(lettingGo + 1);
  });

  /**
   * Momentum is conserved for the first time in the campaign, and that is the
   * whole feel of the act: a swarm that has been sent somewhere keeps going, and
   * the only thing that changes its mind is a well.
   */
  it('keeps a swarm moving after the hand has stopped', () => {
    const world = orbitWorld();
    const c0 = world.swarm.centroid();
    world.injectStroke(c0.x, c0.y, c0.x, c0.y - 200, 0.3);
    for (let i = 0; i < 120; i++) world.step(1 / 60);
    const moving = world.swarm.agents.filter((a) => a.alive);
    const speed = mean(moving.map((a) => Math.hypot(a.vx, a.vy)));
    // Two seconds after one stroke, in a medium with no drag, the swarm is still
    // travelling. In water the same interval would have taken almost all of it.
    expect(speed).toBeGreaterThan(8);
  });
});
