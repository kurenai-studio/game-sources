import { createHash } from "node:crypto";

const DAY_MS = 86_400_000;

function key(seed: string): string {
  return createHash("sha256").update(seed).digest("hex");
}

/** The pool in a fixed shuffled order for one cycle. */
function cycleOrder(pool: readonly string[], cycle: number): string[] {
  return [...pool]
    .sort()
    .map((slug) => ({ slug, rank: key(`${cycle}:${slug}`) }))
    .sort((a, b) => (a.rank < b.rank ? -1 : 1))
    .map((item) => item.slug);
}

/**
 * The fallback pick for a day with no scheduled challenge: a deterministic rotation over the pool,
 * so a day is never empty while the pool has levels. Days are counted in cycles as long as the
 * pool; each cycle is a shuffle of the whole pool, so every level comes once per cycle and none
 * repeats inside it, and a cycle never starts with the level the last one ended on. The same date
 * and pool always give the same level.
 */
export function pickFromPool(date: string, pool: readonly string[]): string | null {
  if (pool.length === 0) return null;
  const size = pool.length;
  const day = Math.floor(Date.parse(`${date}T00:00:00Z`) / DAY_MS);
  const cycle = Math.floor(day / size);
  const order = cycleOrder(pool, cycle);
  // Two levels simply alternate; with three or more, a swap at the start of a cycle never moves
  // the last level, so the previous cycle's last is known without replaying every earlier cycle.
  if (size === 2) return [...pool].sort()[((day % 2) + 2) % 2] ?? null;
  if (size > 2) {
    const previousLast = cycleOrder(pool, cycle - 1)[size - 1];
    if (order[0] === previousLast) [order[0], order[1]] = [order[1]!, order[0]!];
  }
  return order[day - cycle * size] ?? null;
}
