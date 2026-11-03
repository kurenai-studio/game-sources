import type { Tuning } from '../src/config/tuning';
import {
  SEEDS,
  makeAimBot,
  makeSplitBot,
  mean,
  passive,
  playRun,
  type Policy,
  type RunResult,
} from '../tests/bot';

/**
 * Slowblue: experiment harness. Every tuning claim in IMPLEMENTATION_NOTES.md is
 * produced here, so "it feels better" is never the justification for a change.
 */

export interface StyleSpec {
  name: string;
  policy: () => Policy;
}

/** The play styles that must all stay viable for the mechanic to have depth. */
export const STYLES: StyleSpec[] = [
  { name: 'passive', policy: () => passive },
  { name: 'earlySoft', policy: () => makeAimBot({ strokeDt: 0.4 }) },
  { name: 'lateSharp', policy: () => makeAimBot({ strokeDt: 0.06, reactDistance: 300 }) },
  { name: 'panicFlick', policy: () => makeAimBot({ strokeDt: 0.03, reactDistance: 150 }) },
  { name: 'greedySoft', policy: () => makeAimBot({ strokeDt: 0.4, greedy: true }) },
  { name: 'splitter', policy: () => makeSplitBot() },
];

export interface StyleSummary {
  name: string;
  seconds: number;
  gates: number;
  lost: number;
  rescued: number;
  spread: number;
  reforms: number;
  score: number;
  /** Score spread across seeds, as a fraction of the mean. High = the ocean matters. */
  variation: number;
  reasons: string;
  capped: number;
}

export function summarise(name: string, runs: RunResult[]): StyleSummary {
  const scores = runs.map((r) => r.score);
  const avg = mean(scores);
  const sd = Math.sqrt(mean(scores.map((s) => (s - avg) ** 2)));
  return {
    name,
    seconds: round(mean(runs.map((r) => r.seconds))),
    gates: round(mean(runs.map((r) => r.gates))),
    lost: round(mean(runs.map((r) => r.lost))),
    rescued: round(mean(runs.map((r) => r.rescued))),
    spread: round(mean(runs.map((r) => r.endSpread))),
    reforms: round(mean(runs.map((r) => r.reforms))),
    score: Math.round(avg),
    variation: avg === 0 ? 0 : round(sd / avg),
    reasons: runs.map((r) => (r.reason ?? 'cap').slice(0, 4)).join(','),
    capped: runs.filter((r) => r.reason === null).length,
  };
}

export function runStyles(
  overrides: Partial<Tuning> = {},
  styles: StyleSpec[] = STYLES,
  seeds: number[] = SEEDS,
): StyleSummary[] {
  return styles.map((s) =>
    // A fresh policy per seed. This used to build one and reuse it, on the
    // reasoning that re-phasing the stroke cadence between runs made results
    // wobble for no design reason - which has it backwards. A shared bot starts
    // each seed wherever the last one left it, so the eleven runs are not
    // independent samples and their mean does not have the error bar it looks
    // like it has; built fresh, the cadence is a constant rather than a nuisance
    // carried in from whichever seed ran first. See `perSeed`.
    summarise(
      s.name,
      seeds.map((seed) => playRun(seed, s.policy(), overrides)),
    ),
  );
}

export function printTable(label: string, rows: StyleSummary[]): void {
  console.log(`\n=== ${label} ===`);
  console.log(
    ['style'.padEnd(11), 'secs'.padStart(6), 'gates'.padStart(6), 'lost'.padStart(6),
      'resc'.padStart(6), 'refm'.padStart(5), 'spread'.padStart(7), 'score'.padStart(6),
      'endings'].join(' '),
  );
  for (const r of rows) {
    console.log(
      [r.name.padEnd(11), r.seconds.toFixed(1).padStart(6), r.gates.toFixed(1).padStart(6),
        r.lost.toFixed(1).padStart(6), r.rescued.toFixed(1).padStart(6),
        r.reforms.toFixed(1).padStart(5), r.spread.toFixed(1).padStart(7),
        String(r.score).padStart(6), r.reasons].join(' '),
    );
  }
}

/**
 * The design question, as one number: how close is the weakest deliberate style to
 * the strongest? 1.0 = several genuinely viable strategies. 0.4 = one dominant
 * strategy and a set of traps, which is the failure mode this prototype must avoid.
 */
export function strategyParity(rows: StyleSummary[]): number {
  const active = rows
    .filter((r) => r.name !== 'passive')
    .map((r) => r.score)
    .sort((a, b) => b - a);
  if (active.length < 2 || active[0]! <= 0) return 0;
  return round(active[active.length - 1]! / active[0]!);
}

/** Score ratio between two named styles. */
export function ratio(rows: StyleSummary[], a: string, b: string): number {
  const ra = rows.find((r) => r.name === a)?.score ?? 0;
  const rb = rows.find((r) => r.name === b)?.score ?? 0;
  return rb === 0 ? 0 : round(ra / rb);
}

function round(v: number): number {
  return Number(v.toFixed(2));
}
