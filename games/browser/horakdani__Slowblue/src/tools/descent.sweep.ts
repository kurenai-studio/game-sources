import { describe, it } from 'vitest';
import { makeAimBot, mean, passive, perSeed, playRun, type Policy } from '../tests/bot';
import { ACT_HOME } from '../src/config/homecoming';
import { ACT_RAIN } from '../src/config/rain';
import { CAMPAIGN_ACTS } from '../src/config/campaign';
import { DEFAULT_TUNING, type Tuning } from '../src/config/tuning';
import type { Act } from '../src/config/levels';

/**
 * Standing health check for acts VI and VII, and for the length of the whole
 * circuit. Run it after any change to the descending acts' pace or content:
 *
 *   npm run sweep
 *
 * Two questions, and the second one is about the campaign rather than about
 * either act.
 *
 *   1. **Does skill still pay on the way down?** The descending acts soften -
 *      act VI restarts a station rather than ending a run, and act VII's second
 *      half cannot be lost at all - and the risk the design takes with that is
 *      that "cannot be lost" quietly becomes "does not matter". A competent hand
 *      has to arrive with more life and more score than a passive one, or the
 *      resolution is a cutscene the player is holding a finger on.
 *   2. **How long is the circuit?** This is arithmetic rather than a bot
 *      reading, and it is the number that turned out to matter most: every act
 *      is authored to roughly the same physical length, so an act's duration is
 *      just its length over its forced drift - and the drift is half as fast in
 *      the five new acts as in the two shipped ones. `npm run sweep` prints the
 *      table because a campaign that reads as two hours on paper is a design
 *      decision somebody should make on purpose.
 */

interface Row {
  name: string;
  seconds: number;
  gates: number;
  rescued: number;
  lost: number;
  endCount: number;
  score: number;
  reached: number;
  restarts: number;
  completed: number;
}

const STYLES: { name: string; policy: () => Policy }[] = [
  { name: 'passive', policy: () => passive },
  { name: 'careful', policy: () => makeAimBot({ strokeDt: 0.4 }) },
  { name: 'greedy', policy: () => makeAimBot({ strokeDt: 0.4, detour: true }) },
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
      endCount: round(mean(runs.map((r) => r.endCount))),
      score: Math.round(mean(runs.map((r) => r.score))),
      reached: round(mean(runs.map((r) => r.progress))),
      restarts: round(mean(runs.map((r) => r.restarts))),
      completed: runs.filter((r) => r.completed).length,
    };
  });
}

function print(label: string, rows: Row[]): void {
  console.log(`\n=== ${label} ===`);
  console.log(
    ['style'.padEnd(8), 'secs'.padStart(6), 'gates'.padStart(6), 'resc'.padStart(5),
      'lost'.padStart(5), 'kept'.padStart(5), 'score'.padStart(6), 'sect'.padStart(5),
      'rest'.padStart(5), 'done'.padStart(5)].join(' '),
  );
  for (const r of rows) {
    console.log(
      [r.name.padEnd(8), r.seconds.toFixed(1).padStart(6), r.gates.toFixed(1).padStart(6),
        r.rescued.toFixed(1).padStart(5), r.lost.toFixed(1).padStart(5),
        r.endCount.toFixed(1).padStart(5), String(r.score).padStart(6),
        r.reached.toFixed(1).padStart(5), r.restarts.toFixed(1).padStart(5),
        String(r.completed).padStart(5)].join(' '),
    );
  }
}

function round(v: number): number {
  return Number(v.toFixed(2));
}

describe('descent design health', () => {
  it('current defaults', () => {
    for (const act of [ACT_RAIN, ACT_HOME]) {
      const rows = styles(act);
      print(`${act.key} defaults`, rows);
      const careful = rows.find((r) => r.name === 'careful')!;
      const idle = rows.find((r) => r.name === 'passive')!;
      console.log(`\n--- ${act.key.toUpperCase()} HEALTH ---`);
      console.log(`skill multiplier      ${(careful.score / Math.max(1, idle.score)).toFixed(1)}x`);
      console.log(`life kept             ${careful.endCount.toFixed(1)} vs ${idle.endCount.toFixed(1)} passive`);
      console.log(`sections cleared      ${careful.reached.toFixed(1)}/${act.totalSections}`);
      console.log(`restarts              ${careful.restarts.toFixed(1)}`);
    }
  });

  /**
   * The circuit's length, as arithmetic rather than as a bot reading.
   *
   * An act's course has a fixed physical length in pixels, and the camera crosses
   * it at `worldSpeed x pace`. Nothing else is involved, so this is exactly how
   * long the act takes a player who never falls behind - a *floor* on its
   * duration, not an estimate.
   */
  it('how long the circuit is', () => {
    console.log(
      `\n=== circuit length (worldSpeed ${DEFAULT_TUNING.worldSpeed}) ===`,
    );
    console.log(
      ['act'.padEnd(9), 'sect'.padStart(5), 'span px'.padStart(9), 'pace'.padStart(6),
        'drift'.padStart(7), 'minutes'.padStart(8)].join(' '),
    );
    let total = 0;
    for (const act of CAMPAIGN_ACTS) {
      const paces = act.levels.map((l) => l.pace);
      const pace = mean(paces);
      const drift = DEFAULT_TUNING.worldSpeed * pace;
      // Every act is authored to about the same section spacing; the span is that
      // spacing times the section count.
      const span = act.totalSections * SPACING;
      const minutes = span / drift / 60;
      total += minutes;
      console.log(
        [act.key.padEnd(9), String(act.totalSections).padStart(5),
          String(Math.round(span)).padStart(9), pace.toFixed(2).padStart(6),
          drift.toFixed(1).padStart(7), minutes.toFixed(1).padStart(8)].join(' '),
      );
    }
    console.log(`\ntotal circuit         ${total.toFixed(0)} minutes`);
  });
});

/**
 * Mean pixels between section lines, measured across all seven acts. They are
 * authored to within 4% of each other, which is what makes the table above a
 * comparison of *pace* rather than of content.
 */
const SPACING = 845;
