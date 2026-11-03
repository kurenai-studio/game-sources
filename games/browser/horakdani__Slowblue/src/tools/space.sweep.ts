import { describe, it } from 'vitest';
import {
  makeAimBot,
  makeOrbitBot,
  mean,
  passive,
  perSeed,
  playRun,
  type Policy,
} from '../tests/bot';
import { ACT_ORBIT } from '../src/config/orbit';
import { ACT_REENTRY } from '../src/config/reentry';
import type { Act } from '../src/config/levels';
import type { Tuning } from '../src/config/tuning';

/**
 * Standing health check for acts IV and V. Run it after any change to the
 * potential field, the space medium, or either act's pace:
 *
 *   npm run sweep
 *
 * These two acts are the only ones in the campaign where a stroke does not lay a
 * current, so they are the only ones the water and air sweeps say nothing about.
 * The questions are different in kind from act III's:
 *
 *   1. **How far does the act get flown in a fixed budget?** Act IV has no drive
 *      of its own at all - `migrationSpeed` is zero in vacuum - so every pixel of
 *      forward progress is momentum the player put there and did not take back.
 *      `sect` is the reading: sections cleared in 300 seconds, out of the act's
 *      own total, which the header prints.
 *
 *      It is a *comparison* budget rather than a playthrough: 300 seconds is half
 *      of what either act takes at its own drift, so nothing here ever reports
 *      `done` and nothing here should be read as "the act is finishable".
 *      `tools/finish.sweep.ts` is the tool that asks that, and for act IV the
 *      answer it gives is six seeds in eleven.
 *   2. **What does the act actually pay for?** `orbit` lays a well a long way
 *      ahead and then lets go; `aim` plays it like water, pushing whenever it has
 *      fallen behind. The design said the first would win, and it does not -
 *      `orbitFar`, which is the purest form of letting go, cleared zero sections
 *      in five minutes while `aim` cleared ten — figures from the 36-section cut,
 *      with the gates still mirrored, and neither has been re-taken since. That
 *      is why the act's verb is now *aim ahead of them* rather than *start it,
 *      then let go* (DESIGN-ASCENT §8). The let-go styles stay in this list as
 *      the **control**: the ratio is a standing fact about vacuum, not a target
 *      to be tuned green, and if it ever inverts, something has changed about the
 *      potential field that nobody meant to change.
 *   3. **Does the blend arrive?** Act V starts in the same vacuum and ends in
 *      cloud, so the *same* two bots should swap places across it. A single
 *      policy that wins both halves means the blend is not doing anything.
 */

interface Row {
  name: string;
  seconds: number;
  gates: number;
  rescued: number;
  lost: number;
  score: number;
  /** Mean sections cleared. The act's progress metric; survives a restart. */
  reached: number;
  restarts: number;
  completed: number;
  reasons: string;
}

const STYLES: { name: string; policy: () => Policy }[] = [
  { name: 'passive', policy: () => passive },
  { name: 'orbit', policy: () => makeOrbitBot() },
  { name: 'orbitFar', policy: () => makeOrbitBot({ lead: 460, hold: 1.3 }) },
  { name: 'orbitNear', policy: () => makeOrbitBot({ lead: 150, hold: 0.5 }) },
  { name: 'aim', policy: () => makeAimBot({ strokeDt: 0.4 }) },
  { name: 'flick', policy: () => makeAimBot({ strokeDt: 0.05, reactDistance: 320 }) },
];

function styles(act: Act, overrides: Partial<Tuning> = {}, seconds = 300): Row[] {
  return STYLES.map((s) => {
    const runs = perSeed(s.policy, (seed, policy) =>
      playRun(seed, policy, overrides, seconds, true, act),
    );
    return {
      name: s.name,
      seconds: round(mean(runs.map((r) => r.seconds))),
      gates: round(mean(runs.map((r) => r.gates))),
      rescued: round(mean(runs.map((r) => r.rescued))),
      lost: round(mean(runs.map((r) => r.lost))),
      score: Math.round(mean(runs.map((r) => r.score))),
      reached: round(mean(runs.map((r) => r.progress))),
      restarts: round(mean(runs.map((r) => r.restarts))),
      completed: runs.filter((r) => r.completed).length,
      reasons: runs.map((r) => (r.reason ?? (r.completed ? 'done' : 'cap')).slice(0, 4)).join(','),
    };
  });
}

function print(label: string, act: Act, rows: Row[]): void {
  console.log(`\n=== ${label} (${act.totalSections} sections) ===`);
  console.log(
    ['style'.padEnd(9), 'secs'.padStart(6), 'gates'.padStart(6), 'resc'.padStart(5),
      'lost'.padStart(5), 'score'.padStart(6), 'sect'.padStart(5), 'rest'.padStart(5),
      'done'.padStart(5), 'endings'].join(' '),
  );
  for (const r of rows) {
    console.log(
      [r.name.padEnd(9), r.seconds.toFixed(1).padStart(6), r.gates.toFixed(1).padStart(6),
        r.rescued.toFixed(1).padStart(5), r.lost.toFixed(1).padStart(5),
        String(r.score).padStart(6), r.reached.toFixed(1).padStart(5),
        r.restarts.toFixed(1).padStart(5), String(r.completed).padStart(5), r.reasons].join(' '),
    );
  }
}

function round(v: number): number {
  return Number(v.toFixed(2));
}

/** Sections per minute, which is the only pace number comparable across acts. */
function rate(r: Row): number {
  return r.seconds > 0 ? (r.reached / r.seconds) * 60 : 0;
}

describe('space design health', () => {
  it('current defaults', () => {
    for (const act of [ACT_ORBIT, ACT_REENTRY]) {
      const rows = styles(act);
      print(`${act.key} defaults`, act, rows);
      const best = rows.reduce((a, b) => (b.reached > a.reached ? b : a));
      const orbit = rows.find((r) => r.name === 'orbit')!;
      const aim = rows.find((r) => r.name === 'aim')!;
      const idle = rows.find((r) => r.name === 'passive')!;
      console.log(`\n--- ${act.key.toUpperCase()} HEALTH ---`);
      console.log(`best style            ${best.name} (${best.reached.toFixed(1)} sections)`);
      console.log(`let-go vs push        ${(orbit.reached / Math.max(1, aim.reached)).toFixed(2)}x`);
      console.log(`skill multiplier      ${(best.score / Math.max(1, idle.score)).toFixed(1)}x`);
      console.log(`pace                  ${rate(best).toFixed(1)} sections/min`);
      console.log(
        `act length at pace    ${(act.totalSections / Math.max(0.01, rate(best))).toFixed(1)} min`,
      );
    }
  });

  /**
   * The two numbers that decide whether act IV is an act or a wait: how hard a
   * laid well pulls, and how long it lasts before the swarm is coasting again.
   * Everything else about the act is a consequence of those.
   */
  it('the well grid', () => {
    for (const potentialStrength of [150, 210, 300, 420]) {
      for (const potentialHalfLife of [1.6, 2.6, 4]) {
        const rows = styles(ACT_ORBIT, { potentialStrength, potentialHalfLife }, 240);
        const best = rows.reduce((a, b) => (b.reached > a.reached ? b : a));
        const idle = rows.find((r) => r.name === 'passive')!;
        console.log(
          `pull=${String(potentialStrength).padStart(3)} life=${potentialHalfLife.toFixed(1)}` +
            `  best ${best.name.padEnd(9)} sect ${best.reached.toFixed(1).padStart(5)}` +
            `  ${rate(best).toFixed(1).padStart(5)}/min` +
            `  idle ${idle.reached.toFixed(1).padStart(4)}` +
            `  done ${best.completed}`,
        );
      }
    }
  });

  /**
   * ...and the drift the act is flown against. Act IV's pace is the lowest in the
   * campaign by a long way, which is deliberate - it is the act about stillness -
   * but "lowest" and "too low to finish" are different claims and only one of
   * them is a design.
   */
  it('the drift grid', () => {
    for (const worldSpeed of [54, 62, 68, 80]) {
      const rows = styles(ACT_ORBIT, { worldSpeed }, 240);
      const best = rows.reduce((a, b) => (b.reached > a.reached ? b : a));
      console.log(
        `drift=${worldSpeed}  best ${best.name.padEnd(9)}` +
          ` sect ${best.reached.toFixed(1).padStart(5)}  ${rate(best).toFixed(1).padStart(5)}/min` +
          `  rest ${best.restarts.toFixed(1)}  ${best.reasons}`,
      );
    }
  });
});
