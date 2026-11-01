import { daysBetween } from "./dates.js";

export type Streak = { current: number; best: number };

/** A missed day is forgiven at most once in any seven days. */
const GRACE_DAYS = 7;

/**
 * Consecutive UTC days with a solved daily challenge. One missed day is bridged, but only once per
 * seven days: a second gap inside that window ends the run. `current` counts only while the run is
 * still alive on `today` (the last solve was today, yesterday, or the bridged day before).
 */
export function computeStreak(solved: readonly string[], today: string): Streak {
  const days = [...new Set(solved)].sort();
  let run = 0;
  let best = 0;
  let lastGrace: string | null = null;
  let last: string | null = null;
  for (const day of days) {
    if (last === null) {
      run = 1;
    } else {
      const gap = daysBetween(last, day);
      const graceFree = lastGrace === null || daysBetween(lastGrace, day) >= GRACE_DAYS;
      if (gap === 1) {
        run += 1;
      } else if (gap === 2 && graceFree) {
        run += 1;
        lastGrace = day;
      } else {
        run = 1;
      }
    }
    best = Math.max(best, run);
    last = day;
  }
  if (last === null) return { current: 0, best: 0 };
  const sinceLast = daysBetween(last, today);
  const graceFree = lastGrace === null || daysBetween(lastGrace, today) >= GRACE_DAYS;
  const alive = sinceLast <= 1 || (sinceLast === 2 && graceFree);
  return { current: alive ? run : 0, best };
}
