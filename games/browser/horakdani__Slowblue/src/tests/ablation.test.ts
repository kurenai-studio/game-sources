import { describe, expect, it } from 'vitest';
import { CAMPAIGN_ACTS } from '../src/config/campaign';
import { ACT_REENTRY } from '../src/config/reentry';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { MAIN_FACTION } from '../src/sim/Agent';
import { mediumFor } from '../src/sim/Medium';
import { World } from '../src/sim/World';
import { makeAimBot, type Policy } from './bot';
import { H, W } from './helpers';

/**
 * Slowblue: what it costs to outrun the medium, and the report it answers.
 *
 * *"I can descend with the swarm much faster than the background and the obstacles
 * scroll up. There is nothing exciting in that - the top of the course basically
 * never catches up with me, so I can never die."*
 *
 * Both halves were true, and the second followed from the first. `World.step`
 * advances the camera at the station's forced drift and then takes the greater of
 * that and the swarm's own position, so a hand that pushes drags the world along
 * with it; `behindFraction` pins at the anchor, 0.620, against a strand line of
 * 0.94; and the only failure of position in the game was therefore unreachable for
 * anybody who pushed. Measured before the fix, on act V: a rushing hand made 2.29
 * times the world's own travel, took twice the careful hand's ground, and lost
 * **zero** carriers and **zero** stations doing it.
 *
 * The answer is not the camera - see `Medium.drag` for the three reasons, one of
 * which is that this repo already ran that experiment and lost it. It is the
 * medium: past `Tuning.terminalFactor` times the station's own drift, the air
 * takes the swarm apart from the front. See `World.updateAblation`.
 *
 * These are the four claims that has to keep true.
 */

const TERMINAL = DEFAULT_TUNING.terminalFactor;

/** Runs an act with a policy and reports what the medium took. */
function fly(
  policy: Policy,
  seconds = 120,
  seed = 3,
): { ablated: number; restarts: number; ground: number; peakHeat: number } {
  const world = new World(W, H, seed, { ...DEFAULT_TUNING }, true, ACT_REENTRY);
  // Section 30 is the aurora, which is the first station flown in plasma proper.
  // Starting at the act's own first section would spend the whole probe in the
  // deorbit, where the medium is vacuum and going fast is *correctly* free - the
  // sweep does exactly that over 300 s and takes four minutes to say it.
  world.reset(seed, 30);
  let peakHeat = 0;
  for (let i = 0; i < seconds * 60 && world.run.phase === 'running'; i++) {
    policy(world, 1 / 60);
    world.step(1 / 60);
    peakHeat = Math.max(peakHeat, world.ablating);
  }
  return {
    ablated: world.ablated,
    restarts: world.run.restarts,
    ground: world.run.distance,
    peakHeat,
  };
}

describe('the medium has a speed', () => {
  it('has an opinion in exactly the three media a body falls through', () => {
    /*
     * The scoping claim, and the whole reason act I cannot move.
     *
     * `space` is zero because there is nothing there to outrun - which is why act
     * V's deorbit is the one station in the act where speed is free, and that is
     * the correct reading of vacuum. `air` and `thinAir` are zero because acts II
     * and III are climbs and a climb charges for speed by being a climb: measured,
     * a hand that pushes act I forever makes 0.98 of a careful hand's ground.
     * `water` is zero because act I is defended digit for digit and because act
     * VII's last three stations are pure water, cannot be lost at all, and are the
     * campaign dilating to a stop.
     */
    const opinionated = (
      ['water', 'air', 'thinAir', 'space', 'plasma', 'cloud', 'stream'] as const
    ).filter((k) => mediumFor(k, DEFAULT_TUNING).drag > 0);
    expect(opinionated).toEqual(['plasma', 'cloud', 'stream']);
    // ...and the plasma objects hardest, because it is the one where a body
    // outrunning the air actually catches fire.
    expect(mediumFor('plasma', DEFAULT_TUNING).drag).toBeGreaterThan(
      mediumFor('cloud', DEFAULT_TUNING).drag,
    );
  });

  it('leaves every act that climbs exactly as it was', () => {
    // Acts I to IV go up. Nothing about them can be charged for speed, because
    // nothing they are made of has an opinion about it - and act I's canary in
    // `tests/playability.test.ts` holds a reference score to sixteen places.
    const CLIMBS = new Set(['water', 'air', 'thin', 'orbit']);
    for (const act of CAMPAIGN_ACTS) {
      if (!CLIMBS.has(act.key)) continue;
      const world = new World(W, H, 2, { ...DEFAULT_TUNING }, true, act);
      const policy = makeAimBot({ strokeDt: 0.4, rush: true });
      for (let i = 0; i < 60 * 60 && world.run.phase === 'running'; i++) {
        policy(world, 1 / 60);
        world.step(1 / 60);
        expect(world.overTerminal, `${act.key} charged for speed`).toBe(0);
      }
      expect(world.ablated, `${act.key} ablated`).toBe(0);
    }
  });

  it('charges for going faster than the station s own drift, and not for the ring', () => {
    const world = new World(W, H, 5, { ...DEFAULT_TUNING }, true, ACT_REENTRY);
    // Into the plasma, where the medium has an opinion. The deorbit is vacuum and
    // is deliberately free.
    world.reset(5, 30);
    const policy = makeAimBot({ strokeDt: 0.4, rush: true });
    let overWithRingEase = 0;
    for (let i = 0; i < 90 * 60 && world.run.phase === 'running'; i++) {
      policy(world, 1 / 60);
      world.step(1 / 60);
      // The terminal is measured against `driftSpeed`, which is the pace the
      // station *means*. Measured against `currentWorldSpeed` it would collapse
      // to 0.3 at every compulsory ring and burn the player for the one thing the
      // game has just slowed down to let them do.
      expect(world.driftSpeed).toBeGreaterThanOrEqual(world.currentWorldSpeed - 1e-9);
      if (world.ringEase < 0.9 && world.overTerminal > 0) overWithRingEase++;
      if (world.overTerminal > 0) {
        expect(world.courseSpeed).toBeGreaterThan(world.driftSpeed * TERMINAL);
      }
    }
    expect(world.ablated, 'a hand that never stops pushing paid nothing').toBeGreaterThan(3);
    console.log('[ablation] over-terminal steps while a ring was easing:', overWithRingEase);
  });

  it('lets the heat go again, so the pressure is one a hand can get out from under', () => {
    const world = new World(W, H, 4, { ...DEFAULT_TUNING }, true, ACT_REENTRY);
    world.reset(4, 30);
    const rush = makeAimBot({ strokeDt: 0.4, rush: true });
    let hot = 0;
    for (let i = 0; i < 60 * 60 && world.run.phase === 'running'; i++) {
      rush(world, 1 / 60);
      world.step(1 / 60);
      hot = Math.max(hot, world.heat);
      if (world.ablating > 0.5) break;
    }
    expect(hot, 'never got hot at all').toBeGreaterThan(0);
    // ...and now stop. The heat has to fall on its own, or this is a countdown
    // rather than a demand.
    const before = world.heat;
    for (let i = 0; i < 4 * 60 && world.run.phase === 'running'; i++) world.step(1 / 60);
    expect(world.ablating).toBe(0);
    expect(world.heat).toBeLessThan(before + 1e-9);
  });

  it('takes the carrier furthest out in front, because that is the one meeting the air', () => {
    const world = new World(W, H, 6, { ...DEFAULT_TUNING }, true, ACT_REENTRY);
    world.reset(6, 30);
    const rush = makeAimBot({ strokeDt: 0.4, rush: true });
    let checked = 0;
    for (let i = 0; i < 120 * 60 && world.run.phase === 'running' && checked < 3; i++) {
      rush(world, 1 / 60);
      const before = world.ablated;
      // The leading edge of the body, in course coordinates, before the step.
      const leaders = world.swarm.agents
        .filter((a) => a.alive && a.faction === MAIN_FACTION)
        .map((a) => world.u(a.y))
        .sort((p, q) => q - p);
      world.step(1 / 60);
      if (world.ablated === before || leaders.length < 8) continue;
      const after = world.swarm.agents
        .filter((a) => a.alive && a.faction === MAIN_FACTION)
        .map((a) => world.u(a.y))
        .sort((p, q) => q - p);
      // Whoever went, the body's leading edge came back - the medium took from
      // the front. A tolerance of one step of travel, because the survivors moved
      // during the same step.
      expect(after[0]!).toBeLessThanOrEqual(leaders[0]! + 12);
      checked++;
    }
    expect(checked, 'nothing ever ablated').toBeGreaterThan(0);
  });
});

describe('the frame closes in from both edges', () => {
  /**
   * Slowblue: the warning that had never been drawn on a falling act.
   *
   * `Renderer.drawHud` painted the "you are losing" gradient off a raw screen
   * fraction - `viewY(centroid.y) / h > 0.78` - at the bottom edge. On a climb
   * behind *is* the bottom, so the two agreed and nobody noticed. On a fall behind
   * is the top, and the camera holds the swarm at 0.38 of the frame, so the
   * threshold was unreachable by construction: measured with a passive hand, act I
   * paints it on 19.9 % of frames and act V on 0.00 %.
   *
   * All three falling acts have therefore been shipping with no warning of the one
   * failure they had. This is the invariant the fix reads instead, in both
   * directions, so a regression in `behindFraction`'s sign takes the test with it.
   */
  it('reads the trailing edge as behind, whichever way the act runs', () => {
    const down = new World(W, H, 1, { ...DEFAULT_TUNING }, true, ACT_REENTRY);
    expect(down.direction).toBe(1);
    // Falling: the trailing edge is the TOP of the frame.
    expect(down.behindFraction(H * 0.02)).toBeGreaterThan(0.78);
    expect(down.behindFraction(H * 0.98)).toBeLessThan(0.22);

    const up = new World(W, H, 1, { ...DEFAULT_TUNING }, true, CAMPAIGN_ACTS[0]!);
    expect(up.direction).toBe(-1);
    // Climbing: it is the bottom, which is what the old raw fraction assumed.
    expect(up.behindFraction(H * 0.98)).toBeGreaterThan(0.78);
    expect(up.behindFraction(H * 0.02)).toBeLessThan(0.22);
  });
});

describe('and braking is the answer to it', () => {
  /**
   * The claim the whole change stands on, and the one that decides whether this is
   * a demand or a rail: **a hand that pushes hard and reads the frame beats both a
   * hand that never pushes and a hand that never stops.**
   *
   * `careful` is the repo's model of good play and never goes fast enough to be
   * charged much. `rush` pushes forward every tenth of a second forever. `brake`
   * is `rush` until `World.ablating` says the medium has started taking the swarm,
   * and then strokes *against* the course until it stops - which is act V's stated
   * verb, written as a policy.
   *
   * Measured here, 120 s from the aurora: careful made 4 514 px and burnt 0; rush
   * made 12 722 and burnt 67; brake made **10 418 and burnt 4**. Reading the frame
   * buys 2.3 times the careful hand's ground for four carriers, where not reading
   * it buys 2.8 times for sixty-seven.
   *
   * And over the whole act, 300 s on `tools/rush.sweep.ts`, three seeds: careful
   * 11 985 px and 29 burnt; rush 17 086 and **671 burnt with 33.3 station
   * restarts**; brake 13 710 and 9 burnt. The longer the run, the worse blind
   * pushing gets, because the ablation compounds into the 40 % floor.
   *
   * Going fast is worth it, and it is worth it only if you look.
   */
  it('pays a hand that pushes and reads the frame better than one that does neither', () => {
    const careful = fly(makeAimBot({ strokeDt: 0.4 }));
    const rush = fly(makeAimBot({ strokeDt: 0.4, rush: true }));
    const brake = fly(makeAimBot({ strokeDt: 0.4, brake: true }));
    console.log(
      '[braking]',
      JSON.stringify({
        careful: { ground: Math.round(careful.ground), burnt: careful.ablated },
        rush: { ground: Math.round(rush.ground), burnt: rush.ablated },
        brake: { ground: Math.round(brake.ground), burnt: brake.ablated },
      }),
    );
    // Speed is genuinely available: a hand that pushes makes far more ground than
    // the repo's model of good play, which is the half of this the player was
    // right about and which nothing here takes away.
    expect(brake.ground).toBeGreaterThan(careful.ground * 1.5);
    // Pushing *blind* is what costs. An order of magnitude between the two hands
    // that fly at the same speed and differ only in whether they look.
    expect(rush.ablated).toBeGreaterThan(brake.ablated * 5);
    // ...and braking is not a rail: it keeps most of what the blind hand takes.
    expect(brake.ground).toBeGreaterThan(rush.ground * 0.7);
  });
});
