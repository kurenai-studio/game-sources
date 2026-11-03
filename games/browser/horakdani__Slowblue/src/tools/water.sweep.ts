import { describe, it } from 'vitest';
import { printTable, ratio, runStyles } from './experiment';
import { makeAimBot, makeSplitBot, mean, perSeed, playRun, type Policy } from '../tests/bot';

/**
 * Standing health check for the whole design. Run it after any tuning change:
 *
 *   npm run sweep
 *
 * What it must show:
 *   - steering beats flailing beats doing nothing, by a wide margin
 *   - run lengths in the 30-90s window, every run ending for a reason
 *   - deliberate rescue play out-collects incidental drift, without dominating score
 *   - splitting the shoal is an executable, scoring verb
 *   - seed-to-seed variation high enough that the ocean matters
 */
describe('design health', () => {
  it('current defaults', () => {
    const rows = runStyles();
    printTable('defaults', rows);
    const soft = rows.find((r) => r.name === 'earlySoft')!;
    const greedy = rows.find((r) => r.name === 'greedySoft')!;
    const split = rows.find((r) => r.name === 'splitter')!;
    const passiveRow = rows.find((r) => r.name === 'passive')!;
    console.log('\n--- HEALTH ---');
    console.log(`skill multiplier      ${(soft.score / passiveRow.score).toFixed(1)}x`);
    console.log(`run length (steering) ${soft.seconds.toFixed(0)}s   capped ${soft.capped}/5`);
    console.log(`rescue ratio          ${(greedy.rescued / Math.max(1, soft.rescued)).toFixed(2)}x`);
    console.log(`greedy score ratio    ${ratio(rows, 'greedySoft', 'earlySoft').toFixed(2)}`);
    console.log(`split score ratio     ${ratio(rows, 'splitter', 'earlySoft').toFixed(2)}`);
    console.log(`reforms per split run ${split.reforms.toFixed(2)}`);
    console.log(`seed variation        ${soft.variation.toFixed(2)}`);
  });

  it('reform window', () => {
    // Kept as a focused probe because the reform rate is the most fragile number
    // in the design: it is the only one that depends on two events in sequence.
    for (const label of ['splitter', 'greedy'] as const) {
      const make = (): Policy =>
        label === 'splitter' ? makeSplitBot() : makeAimBot({ strokeDt: 0.4, greedy: true });
      const runs = perSeed(make, (seed, policy) => playRun(seed, policy));
      console.log(
        `${label.padEnd(9)} reforms`,
        runs.map((r) => r.reforms).join(','),
        'mean',
        mean(runs.map((r) => r.reforms)).toFixed(2),
        'secs',
        mean(runs.map((r) => r.seconds)).toFixed(0),
      );
    }
  });
});
