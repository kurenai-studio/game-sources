import { describe, it } from 'vitest';
import { SEEDS, makeAimBot, mean, perSeed, playRun, type Policy } from '../tests/bot';
import { CAMPAIGN_ACTS } from '../src/config/campaign';
import { DEFAULT_TUNING } from '../src/config/tuning';
import type { Act } from '../src/config/levels';

/**
 * Slowblue: can a competent hand actually *finish* an act?
 *
 *   npm run sweep
 *
 * Every other sweep in this directory measures an act by how far a bot gets in a
 * fixed 300 seconds, and that was the right question while the acts were being
 * balanced against each other: a common budget is what makes `thin` and `orbit`
 * comparable at all. It is the wrong question for the one thing a player
 * actually does, which is play an act to its end - and it had quietly stopped
 * being *askable*, because the acts were re-cut to about ten minutes each
 * (DESIGN-ASCENT §18) and 300 seconds is half of that. Not one run in any sweep
 * in this repo has ever reported `completed`. The suite could not have told the
 * difference between an act that is finishable and an act that is not.
 *
 * So this one gives each act its own clock. The budget is the act's arithmetic
 * duration - its length in pixels over its forced drift, which is exactly how
 * long it takes a hand that never falls behind - times a headroom factor for the
 * time a real run loses to restarts and to being pushed off the line. An act
 * that cannot be finished inside that is not hard. It is longer than it is
 * flyable, which is a balance fact and belongs in a table rather than in
 * somebody's afternoon.
 *
 * Read `done` first: it is out of eleven seeds. `sect` says how far the ones
 * that did not finish got, and `rest` says how much of the budget went on
 * re-flying a station rather than on flying the act.
 *
 * ## Two rows that are not failures, and must not be tuned
 *
 * **`water` and `air` used to report almost no `done`, and that was the bot.**
 * They were the two acts that `END_ON_FAILURE` when this table was taken
 * (DESIGN-ASCENT §12): a scripted hand that fell behind did not restart the
 * station, the run ended, and every one of those rows said `swep`. §19 has since
 * put every act on the same restart rule, so those two rows now behave like the
 * other five and `rest` is where to read them - a high restart count is the same
 * scripted hand falling behind just as often, spending the budget instead of the
 * run. `makeAimBot` was never good enough to fly forty-two sections of act I
 * unstranded, and act I's balance is defended by the rescue-ratio probe in
 * `tests/playability.test.ts` rather than by a bot finishing it. Act I is frozen.
 * Nothing in this table is evidence about it.
 *
 * **`orbit` reports `6/11`, and it used to report `0/11`.** This header said the
 * zero was expected and spent a paragraph defending the decision not to touch act
 * IV on the strength of it: not the length, not the pace, not the stroke schedule,
 * and every available lever a permanent change made on an instrument whose known
 * weakness is this act. All of that reasoning was sound and all of it was about
 * the wrong thing. `ObstacleSystem.debrisArc` negated its bow term, so every
 * orbital gate in the act was built as the mirror of the shape its five written
 * descriptions describe - tips *after* the opening rather than before it, and less
 * of the course blocked the deeper the bow. Act IV's one escalation axis ran
 * backwards. Flipping the sign took it to 3/11 on its own; the Umbra's `strait`
 * being symmetric about the field, the Well's ramp stepping 0.08 rather than 0.02,
 * and its compulsory rings moving off the eye of an attractor took it to 6/11 and
 * 14.5/18, score 3252 to 10 642.
 *
 * Six in eleven is a scripted hand scraping through rather than an act that has
 * become easy, so the sentence that follows all of it is unchanged: **act IV's
 * completion is still a human playthrough.**
 *
 * What orbit's row is good for is `sect`: 14.5 is the regression signal now. If a
 * change to the potential field or to act IV's content moves it down, something
 * got worse, and this is the only place that would say so.
 *
 * One `it` per act rather than one for the campaign, and that is not cosmetic:
 * these runs are the longest in the repo - a seed that never finishes burns the
 * whole budget - and vitest holds a test's console output until the test ends.
 * Seven acts in one case is an hour with nothing on screen, which is a tool
 * nobody will run twice. There is also no `passive` row here: a passive run
 * never completes, so it costs the full budget every time to tell us something
 * the other four sweeps already measure.
 */

/**
 * Mean pixels between section lines, measured across all seven acts. The same
 * number `tools/descent.sweep.ts` uses, and quoted rather than imported for the
 * same reason the films copy their gradients: these two tools ask different
 * questions and neither should silently move the other's answer.
 */
const SPACING = 845;

/**
 * How much longer than the arithmetic minimum a run is allowed to take.
 *
 * A hand that never falls behind finishes in exactly `span / drift`; every real
 * run is slower than that, because a restart costs the station again and every
 * pixel lost to a hazard has to be made back against the drift. Eight tenths on
 * top is enough room for two or three restarts in a ten-minute act, and it is
 * also about as long as anybody would sit through one leg of seven.
 */
const HEADROOM = 1.8;

/** Seconds a hand that never falls behind needs for this act. */
function arithmetic(act: Act): number {
  const pace = mean(act.levels.map((l) => l.pace));
  return (act.totalSections * SPACING) / (DEFAULT_TUNING.worldSpeed * pace);
}

interface Row {
  name: string;
  done: number;
  seconds: number;
  reached: number;
  restarts: number;
  score: number;
  reasons: string;
}

const STYLES: { name: string; policy: () => Policy }[] = [
  { name: 'careful', policy: () => makeAimBot({ strokeDt: 0.4 }) },
  { name: 'flick', policy: () => makeAimBot({ strokeDt: 0.05, reactDistance: 320 }) },
];

function run(act: Act, budget: number): Row[] {
  return STYLES.map((s) => {
    const runs = perSeed(s.policy, (seed, policy) =>
      playRun(seed, policy, {}, budget, true, act),
    );
    const done = runs.filter((r) => r.completed);
    return {
      name: s.name,
      done: done.length,
      // Seconds of the runs that *finished*, which is the number a player would
      // recognise. Averaging the ones that ran out of budget in with them would
      // report the cap rather than the act.
      seconds: done.length > 0 ? Number(mean(done.map((r) => r.seconds)).toFixed(1)) : 0,
      reached: Number(mean(runs.map((r) => r.progress)).toFixed(1)),
      restarts: Number(mean(runs.map((r) => r.restarts)).toFixed(2)),
      score: Math.round(mean(runs.map((r) => r.score))),
      reasons: runs.map((r) => (r.completed ? 'done' : (r.reason ?? 'cap')).slice(0, 4)).join(','),
    };
  });
}

describe('can an act be finished', () => {
  for (const act of CAMPAIGN_ACTS) {
    it(`${act.key}, at its own length`, () => {
      const floor = arithmetic(act);
      const budget = Math.round(floor * HEADROOM);
      const rows = run(act, budget);
      console.log(
        `\n=== ${act.key} (${act.totalSections} sections, ` +
          `${(floor / 60).toFixed(1)} min at the drift, ${(budget / 60).toFixed(1)} min budget) ===`,
      );
      console.log(
        ['style'.padEnd(8), 'done'.padStart(5), 'secs'.padStart(7), 'sect'.padStart(7),
          'rest'.padStart(5), 'score'.padStart(6), 'endings'].join(' '),
      );
      for (const r of rows) {
        console.log(
          [r.name.padEnd(8), `${String(r.done)}/${String(SEEDS.length)}`.padStart(5),
            r.seconds.toFixed(1).padStart(7),
            `${r.reached.toFixed(1)}/${String(act.totalSections)}`.padStart(7),
            r.restarts.toFixed(2).padStart(5), String(r.score).padStart(6), r.reasons].join(' '),
        );
      }
    });
  }
});
