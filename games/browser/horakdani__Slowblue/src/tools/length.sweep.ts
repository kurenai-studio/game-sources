import { describe, it } from 'vitest';
import { CAMPAIGN_ACTS } from '../src/config/campaign';
import { DEFAULT_TUNING } from '../src/config/tuning';
import type { Act } from '../src/config/levels';
import { World } from '../src/sim/World';
import { makeAimBot } from '../tests/bot';
import { H, W } from '../tests/helpers';

/**
 * Slowblue: how hard is an act, on a scale that survives the act getting longer?
 *
 *   npm run sweep
 *
 * `tools/finish.sweep.ts` asks whether a competent scripted hand can finish an
 * act inside its own clock, and its `done` column is the number this repo has
 * reached for whenever an act was rebuilt. **That column stops meaning anything
 * past about thirty sections, and the campaign is being doubled**, so it was
 * about to start reporting every rebuilt act as broken.
 *
 * That is not a guess. Measured here, on the shipped campaign, with the careful
 * bot and no changes to any of it:
 *
 * | act | sections | finished | restarts | per section |
 * | --- | ---: | ---: | ---: | ---: |
 * | VI · rain | 24 | 5/5 | 2.0 | 0.083 |
 * | I · water | 42 | 1/5 | 50.6 | 1.20 |
 * | II · air | 36 | 0/5 | 145.4 | 4.04 |
 *
 * Act II is the act this repo is proudest of and the bot cannot fly it at all.
 * `finish.sweep.ts` says as much in its own header - "`makeAimBot` was never good
 * enough to fly forty-two sections of act I unstranded" - and then the pass
 * criterion written for act V's rebuild asked for 8 of 11 completions anyway. A
 * criterion no good version of the change could have met.
 *
 * So this table reports **restarts per section**, which is a rate rather than a
 * total, and which therefore compares an act to acts of other lengths and to
 * earlier versions of itself. It is not a difficulty score - the bot is not a
 * player - it is a *position*: the shipped campaign spans 0.08 to 4.0, and a
 * rebuilt act should land inside that span, above the act it replaces and well
 * below act I. Anything under about 0.05 is an act nothing can go wrong in, which
 * is what act V measured before the rebuild (0.042) and is the reason the whole
 * back half of the circuit felt like nothing was being asked.
 *
 * The `vs authored` column is the honest length: **how long a run takes against
 * the act's own arithmetic duration.** Under 1.0 means the bot out-runs the forced
 * drift, which a competent hand does and which is why `secs` in the other sweep
 * is always short of the act's stated minutes. Over 1.0 is time spent re-flying.
 * Act V ran 0.65 before the rebuild, 1.05 after the first pass and 1.53 after the
 * second, and those three numbers are the replay cost stated in a unit that does
 * not move when the act does.
 *
 * `taken` is carriers lost to a predator, and it exists because **the three
 * columns to its left are all blind to the one axis act V's second pass added.**
 * The bot does not see a hunter: it does not avoid one, it does not notice the
 * swarm shrinking, and a carrier eaten costs it no restart. Act V measured 19.3
 * restarts a run with no hunters in it and 19.7 with five, which reads as "no
 * change" and is not one. See the comment on the column itself.
 */

const SEEDS = [1, 2, 3, 4, 5, 6, 7];
/**
 * How long a run is given, in simulated seconds.
 *
 * Slowblue: this was a flat 1800, and a flat budget is the same mistake the `done`
 * column of `finish.sweep.ts` makes - it stops measuring the act the moment the
 * act is long enough to hit it. Act V's second pass came in at 25.7 authored
 * minutes, which is 1542 s before a single restart, and duly measured **0 of 7
 * finished and a *lower* restart rate than the version before it** - not because
 * it had got easier but because 1800 s of budget over a longer act means the bot
 * gives up earlier in it, having fallen behind fewer times.
 *
 * So the budget is the act's own length plus room to re-fly a good part of it,
 * floored at the old 1800 so that nothing already measured moves.
 */
const capFor = (act: Act): number => Math.max(1800, arithmetic(act) * 2.5);

interface Row {
  key: string;
  sections: number;
  done: number;
  restarts: number;
  perSection: number;
  arithmetic: number;
  seconds: number;
  taken: number;
}

/** Seconds a hand that never falls behind needs: the authored length over the drift. */
function arithmetic(act: Act): number {
  let seconds = 0;
  act.script.forEach((entry, i) => {
    // The first spacing is never walked: every course starts at its own offset.
    if (i === 0) return;
    const px = entry.spec.spacing ?? 820;
    seconds += px / (DEFAULT_TUNING.worldSpeed * act.levels[entry.level]!.pace);
  });
  return seconds;
}

function measure(act: Act): Row {
  let restarts = 0;
  let done = 0;
  let seconds = 0;
  let taken = 0;
  const cap = capFor(act);
  for (const seed of SEEDS) {
    const world = new World(W, H, seed, { ...DEFAULT_TUNING }, true, act);
    const policy = makeAimBot({ strokeDt: 0.4 });
    const dt = 1 / 60;
    for (let i = 0; i < cap * 60 && world.run.phase === 'running'; i++) {
      policy(world, dt);
      world.step(dt);
    }
    restarts += world.run.restarts;
    /*
     * Slowblue: what the restart columns cannot see.
     *
     * `makeAimBot` steers at obstacles and at rings and is completely blind to
     * predators - it does not avoid one, it does not notice the swarm getting
     * smaller, and a carrier taken by a hunter costs it no restart at all. So an
     * act that gains a threat measures as *unchanged* on everything above, which
     * is exactly what act V's second pass did: 19.3 restarts a run before it had
     * any hunters and 19.7 after five of them were added.
     *
     * The bites are the difficulty that was added. They are the swarm's whole
     * economy - the 40 % floor is the campaign's one real failure condition and a
     * smaller swarm is a worse one at everything else - and until this column
     * existed the instrument reported "no change" for a change the player would
     * feel on the first pass.
     */
    taken += world.events.filter((e) => e.type === 'bite').length;
    if (world.run.completed) {
      done++;
      seconds += world.run.time;
    }
  }
  const n = SEEDS.length;
  return {
    key: act.key,
    sections: act.totalSections,
    done,
    restarts: restarts / n,
    perSection: restarts / n / act.totalSections,
    arithmetic: arithmetic(act),
    // Only the runs that finished, for the same reason `finish.sweep.ts` averages
    // only those: a run that hit the cap reports the cap rather than the act.
    seconds: done > 0 ? seconds / done : 0,
    taken: taken / n,
  };
}

describe('how hard an act is, per section', () => {
  for (const act of CAMPAIGN_ACTS) {
    it(`${act.key}, as a rate`, () => {
      const r = measure(act);
      console.log(
        `\n=== ${r.key} (${String(r.sections)} sections, ${(r.arithmetic / 60).toFixed(1)} min authored) ===`,
      );
      console.log(
        [
          'done'.padStart(5),
          'restarts'.padStart(9),
          '/section'.padStart(9),
          'secs'.padStart(7),
          'vs authored'.padStart(12),
          'taken'.padStart(7),
        ].join(' '),
      );
      console.log(
        [
          `${String(r.done)}/${String(SEEDS.length)}`.padStart(5),
          r.restarts.toFixed(1).padStart(9),
          r.perSection.toFixed(3).padStart(9),
          (r.seconds > 0 ? r.seconds.toFixed(0) : '-').padStart(7),
          (r.seconds > 0 ? (r.seconds / r.arithmetic).toFixed(2) : '-').padStart(12),
          r.taken.toFixed(0).padStart(7),
        ].join(' '),
      );
    });
  }
});
