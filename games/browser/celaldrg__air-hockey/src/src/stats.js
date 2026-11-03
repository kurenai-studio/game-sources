const LEVEL_NAMES = ['easy', 'medium', 'hard'];

/**
 * @typedef {Record<'easy' | 'medium' | 'hard', {wins: number, losses: number}>} Stats
 */

/**
 * Empty win/loss record for every computer level.
 * @returns {Stats}
 */
export function emptyStats() {
  return Object.fromEntries(LEVEL_NAMES.map((l) => [l, { wins: 0, losses: 0 }]));
}

/** Non-negative integer or 0. */
function count(v) {
  return Number.isInteger(v) && v > 0 ? v : 0;
}

/**
 * Turns untrusted stored data into a valid record (unknown fields dropped).
 * @param {unknown} raw
 * @returns {Stats}
 */
export function normalizeStats(raw) {
  const stats = emptyStats();
  if (!raw || typeof raw !== 'object') return stats;
  for (const l of LEVEL_NAMES) {
    const r = raw[l];
    if (r && typeof r === 'object') stats[l] = { wins: count(r.wins), losses: count(r.losses) };
  }
  return stats;
}

/**
 * Returns a new record with one match against `level` added.
 * @param {Stats} stats
 * @param {'easy' | 'medium' | 'hard'} level
 * @param {boolean} won
 * @returns {Stats}
 */
export function recordResult(stats, level, won) {
  const next = normalizeStats(stats);
  if (!next[level]) return next;
  next[level] = won
    ? { wins: next[level].wins + 1, losses: next[level].losses }
    : { wins: next[level].wins, losses: next[level].losses + 1 };
  return next;
}
