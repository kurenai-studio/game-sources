import { describe, it } from 'vitest';
import { makeAimBot, passive, SEEDS } from '../tests/bot';
import { firstAt, openingOf, timeline, WINDOW_S, type MarkKind } from '../tests/opening';

/**
 * Slowblue: what the first ninety seconds actually shows, and when.
 *
 * The measurement is `tests/opening.ts`; this file is the report, and its job is
 * to put the window next to the act it is cut from. Ninety seconds is not a
 * design unit - a station is - so a gap inside the window can only be judged
 * once it is known whether the act is like that the whole way through.
 *
 *   npm run sweep
 *
 * ## Why a bot, and which one
 *
 * The pacing a *competent* player gets is the fair reading. A confused player
 * sees less of the game and dies sooner, and a probe built on one would be
 * measuring the bot rather than the opening. `makeAimBot` is the repo's stand-in
 * competent player and the instrument every balance number here was taken with,
 * so the opening is read with the same hand as everything else.
 *
 * The passive run is measured beside it for one reason: it is the only way to
 * see what the game does with someone who has not worked out what to touch yet,
 * and "understandable with no tutorial" is a claim about exactly that player.
 */

/** Long enough for the aim bot to fly the whole of act I on a good seed. */
const ACT_S = 900;

describe('the first ninety seconds', () => {
  it('what a competent player is shown, and when', () => {
    const seeds = SEEDS.slice(0, 5);
    const runs = seeds.map((s) => openingOf(s, makeAimBot({ strokeDt: 0.4, detour: true })));

    console.log(`\n--- TIMELINE (seed ${seeds[0]}) ---`);
    console.log(timeline(runs[0]!));

    console.log('\n--- FIRST APPEARANCE, seconds, per seed ---');
    const all: MarkKind[] = [];
    for (const r of runs) for (const m of r.marks) if (!all.includes(m.kind)) all.push(m.kind);
    for (const kind of all) {
      const at = runs.map((r) => firstAt(r, kind));
      const shown = at.filter((x): x is number => x !== null);
      const meanAt = shown.reduce((a, b) => a + b, 0) / Math.max(1, shown.length);
      console.log(
        `${kind.padEnd(18)} ${at.map((x) => (x === null ? '    -' : x.toFixed(1).padStart(5))).join(' ')}   mean ${meanAt.toFixed(1)}  seen ${shown.length}/${runs.length}`,
      );
    }

    console.log('\n--- PACE ---');
    for (let i = 0; i < runs.length; i++) {
      const r = runs[i]!;
      console.log(
        `seed ${String(seeds[i]).padStart(5)}  marks ${String(r.marks.length).padStart(2)}  quietest ${r.quietest.toFixed(1)}s @${r.quietestAt.toFixed(1)}  empty ${r.emptyPct.toFixed(1)}%  emptiest ${r.emptiest.toFixed(1)}s @${r.emptiestAt.toFixed(1)}  sections ${r.sections}  station ${r.station + 1}  ran ${r.seconds}s  ${r.reason ?? 'still going'}`,
      );
    }
  });

  /**
   * The window read against the act it is cut from.
   *
   * This is also the only place the two archetypes that never reach the window
   * get a number. `LEVELS` introduces the standing current at station 3 and the
   * hunter at station 6, on purpose and in that order - "what else is in the
   * water: nothing -> current -> hunters" - and the cost of that order is how
   * many minutes in they land.
   */
  it('the whole act, so the window can be read against it', () => {
    const o = openingOf(SEEDS[0]!, makeAimBot({ strokeDt: 0.4, detour: true }), ACT_S);
    console.log(`\n--- ACT I, seed ${SEEDS[0]} ---`);
    console.log(timeline(o));
    console.log(
      `ran ${o.seconds}s  ${o.reason ?? 'still going'}  sections ${o.sections}  station ${o.station + 1}/6  shoal ${o.count}  empty ${o.emptyPct}%  emptiest ${o.emptiest}s @${o.emptiestAt}`,
    );
    console.log(`stations handed over at ${o.stations.join(', ')}s`);
    console.log(`the window is the first ${((WINDOW_S / o.seconds) * 100).toFixed(0)}% of it`);
  });

  it('what a player who has not touched it yet is shown', () => {
    // The idle hint is drawn by the renderer and is not visible from here; what
    // is visible is everything the *water* does on its own, which is the half of
    // the teaching that does not depend on anyone reading anything.
    for (const seed of SEEDS.slice(0, 3)) {
      const o = openingOf(seed, passive);
      console.log(
        `seed ${String(seed).padStart(5)}  ran ${o.seconds}s  ${o.reason ?? 'still going'}  marks ${o.marks.length}  [${o.marks.map((m) => `${m.kind}@${m.at.toFixed(1)}`).join(' ')}]`,
      );
    }
  });
});
