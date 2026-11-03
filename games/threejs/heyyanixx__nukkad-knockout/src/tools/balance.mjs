// Balance check: every fighter vs every fighter, NORMAL CPU vs NORMAL CPU (seeded, repeatable).
// Run: node tools/balance.mjs [seeds]
import { Game, rng } from '../src/game.js'; import { CPU } from '../src/ai.js'; import { ROSTER } from '../src/roster.js';
export function balance(seeds = 8, level = 'normal', roster = ROSTER) {
  const wins = {}; roster.forEach((c) => (wins[c.id] = [0, 0])); let secs = 0, games = 0;
  for (const a of roster) for (const b of roster) {
    if (a === b) continue;
    for (let s = 1; s <= seeds; s++) {
      const g = new Game({ p1: a, p2: b, seed: s * 31 + a.id.length * 7 + b.id.length, stage: ['tapri', 'terrace', 'platform'][s % 3] });
      const ai = [new CPU(level, rng(s * 977 + 3)), new CPU(level, rng(s * 131 + 17))]; let n = 0;
      while (g.phase !== 'over' && n < 60 * 60 * 8) { g.step([ai[0].think(g.f[0], g.f[1], g), ai[1].think(g.f[1], g.f[0], g)]); n++; }
      secs += n / 60; games++;
      const w = g.winner; if (w === 0) wins[a.id][0]++; else if (w === 1) wins[b.id][0]++;
      wins[a.id][1]++; wins[b.id][1]++;
    }
  }
  const rate = {}; for (const [k, [w, n]] of Object.entries(wins)) rate[k] = w / n;
  return { rate, avgSec: secs / games, games };
}
if (import.meta.url === `file://${process.argv[1]}`) {
  const r = balance(+process.argv[2] || 8);
  for (const [k, v] of Object.entries(r.rate)) console.log(k.padEnd(10), (100 * v).toFixed(0) + '%');
  console.log('games', r.games, 'avg match sec', r.avgSec.toFixed(0));
}
