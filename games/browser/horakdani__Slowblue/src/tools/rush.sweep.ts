import { describe, it } from 'vitest';
import { CAMPAIGN_ACTS } from '../src/config/campaign';
import { DEFAULT_TUNING } from '../src/config/tuning';
import type { Act } from '../src/config/levels';
import { MAIN_FACTION } from '../src/sim/Agent';
import { World } from '../src/sim/World';
import { makeAimBot, type Policy } from '../tests/bot';
import { H, W } from '../tests/helpers';

/**
 * Slowblue: how much faster than the world can a player go, and what does it cost?
 *
 *   npm run sweep
 *
 * This exists because of a player report the repo had no instrument for: *"I can
 * descend with the swarm much faster than the background and the obstacles scroll
 * up. There is nothing exciting in that - the top of the course basically never
 * catches up with me, so I can never die."*
 *
 * Every other harness here measures a **careful** hand, and every one of them
 * gates its forward stroke on `behindFraction > 0.5..0.62` - it stops pushing at
 * the camera's anchor. `World.step`'s camera follow then pins the swarm at exactly
 * that anchor for anybody who pushes, so the gate is unconditionally true and the
 * repo has never once measured the hand that keeps going. A gate that is always
 * open is indistinguishable from no gate at all.
 *
 * So this sweep flies each act twice, `careful` against `rush`, and reports the
 * three numbers the report is actually about:
 *
 *   - **speed** is the swarm's own pace along the course against the forced drift
 *     the station authored. 1.00 means the player is exactly the water. Anything
 *     above it is ground the design never priced.
 *   - **over** is the share of steps spent above the medium's stated terminal
 *     (`Medium.drag`; see `sim/Medium.ts`). It is 0 wherever the medium has no
 *     opinion, which is water, air and vacuum.
 *   - **lost** is what pushing costs: carriers gone, from every cause.
 *
 * A rusher that makes far more ground than the careful hand, at no cost and with
 * no failure, is the report restated as arithmetic - which is what this measured
 * before `Medium.drag` existed.
 */

const SEEDS = [1, 2, 3];
const CAP_SECONDS = 300;

interface Row {
  key: string;
  style: string;
  ground: number;
  speed: number;
  over: number;
  lost: number;
  ablated: number;
  restarts: number;
  reason: string;
}

function measure(act: Act, style: string, make: () => Policy): Row {
  let ground = 0;
  let speedSum = 0;
  let drift = 0;
  let over = 0;
  let steps = 0;
  let lost = 0;
  let ablated = 0;
  let restarts = 0;
  const reasons = new Set<string>();
  for (const seed of SEEDS) {
    const world = new World(W, H, seed, { ...DEFAULT_TUNING }, true, act);
    const policy = make();
    const dt = 1 / 60;
    const start = world.swarm.aliveCount(MAIN_FACTION);
    let peak = start;
    for (let i = 0; i < CAP_SECONDS * 60 && world.run.phase === 'running'; i++) {
      policy(world, dt);
      world.step(dt);
      steps++;
      // The honest denominator: how much course the *world* would have covered in
      // the same time. Not `currentWorldSpeed`, which collapses to 0.3 at every
      // compulsory ring and would report a swarm holding still as going four
      // times the pace.
      speedSum += world.driftSpeed * dt;
      if (world.overTerminal > 0) over++;
      peak = Math.max(peak, world.swarm.aliveCount(MAIN_FACTION));
    }
    ground += world.run.distance;
    drift += speedSum;
    speedSum = 0;
    lost += peak - world.swarm.aliveCount(MAIN_FACTION);
    ablated += world.ablated;
    restarts += world.run.restarts;
    reasons.add(world.run.reason ?? 'cap');
  }
  const n = SEEDS.length;
  return {
    key: act.key,
    style,
    ground: ground / n,
    speed: drift > 0 ? ground / drift : 0,
    over: steps > 0 ? over / steps : 0,
    lost: lost / n,
    ablated: ablated / n,
    restarts: restarts / n,
    reason: [...reasons].sort().join('/'),
  };
}

const cols = ['act', 'style', 'ground', 'speed', 'over', 'burnt', 'lost', 'restarts', 'ended'];
const widths = [9, 8, 8, 7, 7, 7, 7, 9, 14];

const line = (cells: (string | number)[]): string =>
  cells.map((c, i) => String(c).padStart(widths[i] ?? 8)).join(' ');

/**
 * One act, when a constant is being chosen. The whole table is two minutes and
 * choosing a number takes half a dozen tries: `SLOWBLUE_ACT=reentry npm run sweep`.
 */
const ONLY = process.env.SLOWBLUE_ACT;

describe('how much faster than the world a player can go', () => {
  it('careful against rush, every act', () => {
    console.log(line(cols));
    for (const act of CAMPAIGN_ACTS) {
      if (ONLY !== undefined && act.key !== ONLY) continue;
      const careful = measure(act, 'careful', () => makeAimBot({ strokeDt: 0.4 }));
      const rush = measure(act, 'rush', () => makeAimBot({ strokeDt: 0.4, rush: true }));
      // The one that decides whether this is a demand or a rail: the same hand as
      // `rush`, with the frame's own warning read and answered.
      const brake = measure(act, 'brake', () => makeAimBot({ strokeDt: 0.4, brake: true }));
      for (const r of [careful, rush, brake]) {
        console.log(
          line([
            r.style === 'careful' ? r.key : '',
            r.style,
            r.ground.toFixed(0),
            r.speed.toFixed(2),
            (r.over * 100).toFixed(0) + '%',
            r.ablated.toFixed(0),
            r.lost.toFixed(0),
            r.restarts.toFixed(1),
            r.reason,
          ]),
        );
      }
      console.log(
        line([
          '',
          'brk/crf',
          (brake.ground / Math.max(1, careful.ground)).toFixed(2),
          (brake.speed / Math.max(0.01, careful.speed)).toFixed(2),
          '',
          '',
          (brake.ablated / Math.max(1, rush.ablated)).toFixed(2),
          '',
          '',
        ]),
      );
    }
  });
});
