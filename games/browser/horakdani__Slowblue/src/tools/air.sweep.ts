import { describe, it } from 'vitest';
import {
  SEEDS,
  makeAimBot,
  makeSplitBot,
  mean,
  passive,
  perSeed,
  playAir,
  type Policy,
} from '../tests/bot';
import type { Tuning } from '../src/config/tuning';

/**
 * Standing health check for act II. Run it alongside the water sweep after any
 * air tuning change:
 *
 *   npm run sweep
 *
 * **The instruments are act I's, unchanged.** That is the whole acceptance rule
 * of the rewrite: act II used to need its own scripted players, because it had
 * its own verb - one bot that hunted thermals and one that pumped height by hand.
 * With the thermals gone the air is the water with the density taken out, so the
 * policies that measure the water measure it, with nothing added and nothing told
 * about the medium. If these rows look like the water's rows with different
 * numbers in them, the two acts are one game.
 *
 * What it must show:
 *   - **H1**: steering beats flailing beats doing nothing, by a wide margin, the
 *     same way it does below the surface.
 *   - the whole act flown in a sitting, with every run ending for a reason (or
 *     completing - the harness cap must stay rare).
 *   - the deliberate rescue line collects far more than the safe line without
 *     running away with the score, exactly as act I demands.
 */

interface AirRow {
  name: string;
  seconds: number;
  distance: number;
  gates: number;
  rescued: number;
  lost: number;
  spread: number;
  score: number;
  completed: number;
  reasons: string;
}

function airStyles(overrides: Partial<Tuning> = {}): AirRow[] {
  const styles: { name: string; policy: () => Policy }[] = [
    { name: 'passive', policy: () => passive },
    { name: 'earlySoft', policy: () => makeAimBot({ strokeDt: 0.4 }) },
    { name: 'greedy', policy: () => makeAimBot({ strokeDt: 0.4, greedy: true }) },
    { name: 'splitter', policy: () => makeSplitBot() },
    { name: 'lateSharp', policy: () => makeAimBot({ strokeDt: 0.2, reactDistance: 300 }) },
    { name: 'flick', policy: () => makeAimBot({ strokeDt: 0.05, reactDistance: 320 }) },
  ];
  return styles.map((s) => {
    const runs = perSeed(s.policy, (seed, policy) => playAir(seed, policy, overrides));
    return {
      name: s.name,
      seconds: round(mean(runs.map((r) => r.seconds))),
      distance: Math.round(mean(runs.map((r) => r.distance))),
      gates: round(mean(runs.map((r) => r.gates))),
      rescued: round(mean(runs.map((r) => r.rescued))),
      lost: round(mean(runs.map((r) => r.lost))),
      spread: round(mean(runs.map((r) => r.endSpread))),
      score: Math.round(mean(runs.map((r) => r.score))),
      completed: runs.filter((r) => r.completed).length,
      reasons: runs.map((r) => (r.reason ?? (r.completed ? 'done' : 'cap')).slice(0, 4)).join(','),
    };
  });
}

function printAir(label: string, rows: AirRow[]): void {
  console.log(`\n=== ${label} ===`);
  console.log(
    ['style'.padEnd(10), 'secs'.padStart(6), 'height'.padStart(7), 'gates'.padStart(6),
      'resc'.padStart(5), 'lost'.padStart(5), 'sprd'.padStart(5), 'score'.padStart(6),
      'done'.padStart(5), 'endings'].join(' '),
  );
  for (const r of rows) {
    console.log(
      [r.name.padEnd(10), r.seconds.toFixed(1).padStart(6), String(r.distance).padStart(7),
        r.gates.toFixed(1).padStart(6), r.rescued.toFixed(1).padStart(5),
        r.lost.toFixed(1).padStart(5), r.spread.toFixed(1).padStart(5),
        String(r.score).padStart(6), String(r.completed).padStart(5), r.reasons].join(' '),
    );
  }
}

function round(v: number): number {
  return Number(v.toFixed(2));
}

describe('air design health', () => {
  it('current defaults', () => {
    const rows = airStyles();
    printAir('air defaults', rows);
    const soft = rows.find((r) => r.name === 'earlySoft')!;
    const greedy = rows.find((r) => r.name === 'greedy')!;
    const flick = rows.find((r) => r.name === 'flick')!;
    const passiveRow = rows.find((r) => r.name === 'passive')!;
    console.log('\n--- AIR HEALTH ---');
    console.log(`skill multiplier      ${(soft.score / Math.max(1, passiveRow.score)).toFixed(1)}x`);
    console.log(`over best handicap    ${(soft.score / Math.max(1, flick.score)).toFixed(2)}x`);
    console.log(`rescue ratio          ${(greedy.rescued / Math.max(1, soft.rescued)).toFixed(2)}x`);
    console.log(`greedy score ratio    ${(greedy.score / Math.max(1, soft.score)).toFixed(2)}`);
    console.log(`run length (steering) ${soft.seconds.toFixed(0)}s, completed ${soft.completed}/${SEEDS.length}`);
  });

  it('the medium grid', () => {
    // The two numbers that make air *air* rather than thin water: how hard it
    // grips, and how long a laid gust survives. Both were set by taste and both
    // have to be checked against a scripted hand, because "it feels lighter" and
    // "it is unsteerable" produce the same sentence from a designer.
    for (const airCoupling of [1.8, 2.5, 3.4]) {
      for (const airFlowHalfLife of [1.05, 1.7, 2.4]) {
        const rows = airStyles({ airCoupling, airFlowHalfLife });
        const soft = rows.find((r) => r.name === 'earlySoft')!;
        const flick = rows.find((r) => r.name === 'flick')!;
        console.log(
          `grip=${airCoupling} life=${airFlowHalfLife}` +
            `  skill=${(soft.score / Math.max(1, flick.score)).toFixed(2)}` +
            `  soft ${soft.seconds.toFixed(0)}s/${soft.distance}px done ${soft.completed}` +
            `  lost ${soft.lost.toFixed(1)}`,
        );
      }
    }
  });
});
