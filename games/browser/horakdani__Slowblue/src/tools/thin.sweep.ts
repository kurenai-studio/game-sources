import { describe, it } from 'vitest';
import {
  SEEDS,
  makeAimBot,
  makeWaveBot,
  mean,
  passive,
  perSeed,
  playThin,
  type Policy,
} from '../tests/bot';
import { ACT_THIN } from '../src/config/thinning';
import type { Tuning } from '../src/config/tuning';

/**
 * Standing health check for act III. Run it after any upper-air tuning change:
 *
 *   npm run sweep
 *
 * The act's two claims are different from every act below it, so this sweep asks
 * two questions the water and air sweeps do not.
 *
 *   1. **Can the act be flown at all?** A stroke barely grips up here and a mote
 *      has almost no drive of its own, so the balance between `thinMigrationSpeed`,
 *      the station `pace` values and the forced drift decides whether a competent
 *      hand makes ground or is simply collected by the strand line. The `reached`
 *      column is the one to read: it is how many of the six stations a run got
 *      through, and a healthy act ends its runs on `done` rather than on `swep`.
 *   2. **Is timing worth anything?** Two bots, identical steering, identical
 *      cadence, identical mean stroke length - one of them spends its long strokes
 *      in rising air and its short ones in sinking air, the other pushes the same
 *      regardless. If the first does not get further, the gravity wave is scenery
 *      and act III has no verb of its own.
 */

interface ThinRow {
  name: string;
  seconds: number;
  distance: number;
  gates: number;
  rescued: number;
  lost: number;
  score: number;
  /** Mean sections cleared, out of the act's 36. The act's progress metric. */
  reached: number;
  /** Mean stations begun again rather than runs ended. */
  restarts: number;
  completed: number;
  reasons: string;
}

function thinStyles(overrides: Partial<Tuning> = {}, seconds = 300): ThinRow[] {
  const styles: { name: string; policy: () => Policy }[] = [
    { name: 'passive', policy: () => passive },
    { name: 'timed', policy: () => makeWaveBot({ timed: true }) },
    { name: 'blind', policy: () => makeWaveBot({ timed: false }) },
    { name: 'aimSoft', policy: () => makeAimBot({ strokeDt: 0.4 }) },
    { name: 'flick', policy: () => makeAimBot({ strokeDt: 0.05, reactDistance: 320 }) },
  ];
  return styles.map((s) => {
    const runs = perSeed(s.policy, (seed, policy) => playThin(seed, policy, overrides, seconds));
    return {
      name: s.name,
      seconds: round(mean(runs.map((r) => r.seconds))),
      distance: Math.round(mean(runs.map((r) => r.distance))),
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

function printThin(label: string, rows: ThinRow[]): void {
  console.log(`\n=== ${label} ===`);
  console.log(
    ['style'.padEnd(9), 'secs'.padStart(6), 'height'.padStart(7), 'gates'.padStart(6),
      'resc'.padStart(5), 'lost'.padStart(5), 'score'.padStart(6), 'sect'.padStart(5),
      'rest'.padStart(5), 'done'.padStart(5), 'endings'].join(' '),
  );
  for (const r of rows) {
    console.log(
      [r.name.padEnd(9), r.seconds.toFixed(1).padStart(6), String(r.distance).padStart(7),
        r.gates.toFixed(1).padStart(6), r.rescued.toFixed(1).padStart(5),
        r.lost.toFixed(1).padStart(5), String(r.score).padStart(6),
        r.reached.toFixed(1).padStart(5), r.restarts.toFixed(1).padStart(5),
        String(r.completed).padStart(5), r.reasons].join(' '),
    );
  }
}

function round(v: number): number {
  return Number(v.toFixed(2));
}

describe('upper-air design health', () => {
  it('current defaults', () => {
    const rows = thinStyles();
    printThin('thin defaults', rows);
    const timed = rows.find((r) => r.name === 'timed')!;
    const blind = rows.find((r) => r.name === 'blind')!;
    const passiveRow = rows.find((r) => r.name === 'passive')!;
    console.log('\n--- THIN HEALTH ---');
    console.log(`timing bonus          ${(timed.reached / Math.max(1, blind.reached)).toFixed(2)}x`);
    console.log(`skill multiplier      ${(timed.score / Math.max(1, passiveRow.score)).toFixed(1)}x`);
    console.log(`sections cleared      ${timed.reached.toFixed(1)}/${ACT_THIN.totalSections}`);
    console.log(`run length (timed)    ${timed.seconds.toFixed(0)}s, completed ${timed.completed}/${SEEDS.length}`);
  });

  it('the drive and drift grid', () => {
    // The two numbers that decide whether act III is playable rather than merely
    // atmospheric: how much drive a mote has of its own, and how hard the world
    // pulls away from one. Everything else about the act is a consequence.
    for (const thinMigrationSpeed of [20, 34, 48]) {
      for (const worldSpeed of [54, 62, 68]) {
        const rows = thinStyles({ thinMigrationSpeed, worldSpeed });
        const timed = rows.find((r) => r.name === 'timed')!;
        const blind = rows.find((r) => r.name === 'blind')!;
        console.log(
          `drive=${thinMigrationSpeed} drift=${worldSpeed}` +
            `  timing=${(timed.reached / Math.max(1, blind.reached)).toFixed(2)}` +
            `  timed ${timed.seconds.toFixed(0)}s sect ${timed.reached.toFixed(1)}` +
            `  done ${timed.completed}  ${timed.reasons}`,
        );
      }
    }
  });
});
