import { validateLevel } from "../../packages/level-contract/dist/index.js";
import { canonical, levelFromRows, rng } from "./board.mjs";
import { FAMILIES } from "./families.mjs";
import { measure } from "./metrics.mjs";

const FEATURES = ["par", "turns", "excess", "decoy", "walls", "deadEnds"];

/** Greedy farthest-first pick, so a shortlist is varied and not ten look-alikes. */
function diverse(candidates, count) {
  if (candidates.length <= count) return candidates;
  const span = FEATURES.map((f) => {
    const values = candidates.map((c) => c.metrics[f]);
    return Math.max(1, Math.max(...values) - Math.min(...values));
  });
  const distance = (a, b) =>
    FEATURES.reduce((sum, f, i) => sum + Math.abs(a.metrics[f] - b.metrics[f]) / span[i], 0);
  const picked = [candidates[0]];
  while (picked.length < count) {
    let best = null;
    let bestDistance = -1;
    for (const c of candidates) {
      if (picked.includes(c)) continue;
      const d = Math.min(...picked.map((p) => distance(c, p)));
      if (d > bestDistance) {
        best = c;
        bestDistance = d;
      }
    }
    picked.push(best);
  }
  return picked;
}

/** Samples a family and returns up to `count` varied candidates that meet its measured profile. */
export function search(name, { count = 6, seed = 1, tries } = {}) {
  const family = FAMILIES[name];
  if (!family) throw new Error(`Unknown family "${name}"`);
  tries ??= family.tries ?? 8000;
  const r = rng(seed);
  const seen = new Map();
  for (let i = 0; i < tries; i += 1) {
    const built = family.build(r);
    if (!built) continue;
    const level = levelFromRows(built.rows, { commands: built.commands });
    if (!validateLevel(level).ok) continue;
    const metrics = measure(level);
    if (!metrics || !family.accept(metrics, built.meta)) continue;
    const key = canonical(built.rows) + built.commands.join();
    if (!seen.has(key))
      seen.set(key, { family: name, rows: built.rows, commands: built.commands, metrics });
  }
  const all = [...seen.values()];
  return { found: all.length, candidates: diverse(all, count) };
}
