import { describe, expect, it } from 'vitest';
import { makeAimBot, passive, SEEDS } from './bot';
import { firstAt, openingOf, WINDOW_S } from './opening';

/**
 * Slowblue: the shape of the first ninety seconds, defended.
 *
 * `tools/onboarding.sweep.ts` measured it; this is what stops the measurement
 * quietly stopping being true. Every budget here is a number that file printed,
 * rounded outward far enough that it cannot fail for a reason unrelated to what
 * it says - the point is not to pin the opening to the second, it is that a
 * content edit three stations away cannot make the opening slower, emptier or
 * quieter without something going red.
 *
 * The order the act teaches in is *not* defended here, and deliberately not:
 * `LEVELS` introduces the standing current at station 3 and the hunter at
 * station 6, neither of which the window reaches, and that is the design's own
 * curve rather than a defect the window revealed. What is defended is only what
 * the opening has to do to be understood with nothing read: state its ask at
 * once, answer it soon, and keep something in front of the player.
 */

/** A competent hand, the same one every balance number in this repo was taken with. */
const HAND = (): ReturnType<typeof makeAimBot> => makeAimBot({ strokeDt: 0.4, detour: true });

describe('the first ninety seconds', () => {
  it('states its one ask immediately, and answers it inside a quarter of a minute', () => {
    for (const seed of SEEDS.slice(0, 2)) {
      const o = openingOf(seed, HAND());

      // The dashed ring is the only thing in this game that can end a run by
      // being ignored, so it is the first thing on the glass - measured at 0.3 s,
      // which is the shoal clearing its own spawn, not a delay.
      const ask = firstAt(o, 'ring-required');
      expect(ask).not.toBeNull();
      expect(ask!).toBeLessThan(1);

      // ...and it is answered by playing rather than by reading: fish join, a
      // section is cleared, and the multiplier moves, all inside fifteen seconds.
      for (const kind of ['rescue', 'gate', 'multiplier'] as const) {
        const at = firstAt(o, kind);
        expect(at, kind).not.toBeNull();
        expect(at!, kind).toBeLessThan(15);
      }

      // The first rock arrives after the ring has been taken, never before it.
      // That ordering is the whole of act I's opening lesson and it is the one
      // piece of authored order this file does hold.
      expect(firstAt(o, 'obstacle-gate')!).toBeGreaterThan(firstAt(o, 'rescue')!);
      expect(firstAt(o, 'obstacle-gate')!).toBeLessThan(20);
    }
  });

  it('changes the water once inside the window, and keeps something on the glass', () => {
    for (const seed of SEEDS.slice(0, 2)) {
      const o = openingOf(seed, HAND());

      // A station hands over inside the ninety seconds - measured at 65-71 s -
      // so the one thing a store editor cannot be told, that this is a journey
      // rather than a level, gets shown to them instead.
      const handover = firstAt(o, 'level');
      expect(handover).not.toBeNull();
      expect(handover!).toBeLessThan(WINDOW_S - 5);
      expect(firstAt(o, 'zone')!).toBeLessThan(WINDOW_S);

      // Every station in act I ends with a `BREATH`, and the one in the window
      // is 7.5-8.2 s of water with nothing asked of it. That is a rest and it is
      // meant to be there; twelve seconds of it would be an empty game.
      expect(o.emptiest).toBeLessThan(12);
      expect(o.emptyPct).toBeLessThan(20);

      // Fifteen first-of-their-kind things in ninety seconds. The floor is not a
      // target to hit, it is what says the alphabet has not shrunk.
      expect(o.marks.length).toBeGreaterThanOrEqual(13);
    }
  });

  it('teaches a player who has not touched anything yet', () => {
    // The half of the teaching that does not depend on anyone reading: the ocean
    // already moves, so a shoal nobody is steering still drifts into its first
    // ring, still clears its first section, and still sees the multiplier move -
    // before the medium finally leaves it behind. The idle hint is on top of all
    // of this and is measured on the glass in `e2e/runtime.spec.ts`.
    const o = openingOf(SEEDS[0]!, passive);
    expect(firstAt(o, 'rescue')!).toBeLessThan(20);
    expect(firstAt(o, 'gate')!).toBeLessThan(20);
    // And it takes half a minute for the water to take it back, so the lesson has
    // time to land first. What happens at that moment is no longer an ending: an
    // act is one attempt with restarts inside it, so the station begins again
    // instead of the run stopping. The fact being defended did not move with it -
    // what catches a player who does nothing is the medium, on its own schedule,
    // and not a rock. Measured at 33.7 s, and no rock is met inside the window.
    const taken = firstAt(o, 'restart');
    expect(taken).not.toBeNull();
    expect(taken!).toBeGreaterThan(20);
    expect(firstAt(o, 'obstacle-rock')).toBeNull();
  });
});
