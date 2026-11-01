// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Lane G9: the pick sheet holds the Yard still (design note, 2026-10-25: the three cards of a level up pause the
// game). While the three cards are up nothing in the Yard moves or counts
// down, and the sheet waits for the tap with no time limit; on the tap the Yard runs on from where it stopped. The span
// it was held is dropped from the Yard's clock, so a long think costs nothing and gains nothing. The shop platform never
// pauses anything (design note, 2026-10-24: the round runs on while the ant stands on it).
// Lane G9c (design note, 2026-10-25: a break sheet left NEXT ROUND IN counting, so the cards did not pause the game):
// the cards hold everything, the break countdown too, so a round
// never begins under a sheet. While a sheet is up the nest sells nothing (shopSells): a tap on a pick card is the only
// input that counts, and the shop works again on the tap, the countdown running on from the same number.
import type { ShopPhase, ShopState } from './economy';

/**
 * Whether a pick sheet is open: a pick waits and its offer is drawn, in any phase but death. The HUD shows the sheet on
 * this and the Yard holds on it, so the two can never disagree.
 */
export function sheetOpen(pending: number, offerCount: number, phase: ShopPhase): boolean {
  return pending > 0 && offerCount > 0 && phase !== 'dead';
}

/** The Yard's own clock: the scene clock less every span a pick sheet held it. `since` is when the open span began. */
export interface YardClock {
  readonly held: number;
  readonly since: number | null;
}

export function newYardClock(): YardClock {
  return { held: 0, since: null };
}

/** The Yard's time (ms) at the scene clock's `now`. While a sheet is open it stands at the moment the sheet opened. */
export function yardTime(c: YardClock, now: number): number {
  return (c.since ?? now) - c.held;
}

/** One frame of the Yard: whether it runs this frame, and the Yard time it runs (or stands) at. */
export interface YardTick {
  clock: YardClock;
  run: boolean;
  now: number;
}

/**
 * One frame of the Yard's clock at the scene clock's `now`. While the sheet is open the Yard does not run and its time
 * stands still. On the first frame after the tap the held span joins `held`, so the Yard runs on at the time it stopped
 * at, with no catch up of the paused time.
 */
export function yardTick(c: YardClock, now: number, open: boolean): YardTick {
  if (open) {
    const clock = c.since === null ? { held: c.held, since: now } : c;
    return { clock, run: false, now: yardTime(clock, now) };
  }
  const clock = c.since === null ? c : { held: c.held + Math.max(0, now - c.since), since: null };
  return { clock, run: true, now: yardTime(clock, now) };
}

/**
 * Lane G9c: whether a nest buy goes through. Only with the shop open (economy.ts shopState: the break, the ant in the
 * nest) and no pick sheet up; under the cards a buy is refused and changes nothing, so a held break buys no shop time.
 */
export function shopSells(shop: ShopState, open: boolean): boolean {
  return shop === 'open' && !open;
}
