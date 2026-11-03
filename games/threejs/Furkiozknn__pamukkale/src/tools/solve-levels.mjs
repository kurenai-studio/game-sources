// Offline level checker and solver for Pamukkale.
// It reads the SIM and LEVELS blocks straight from ../index.html, so the bot and the player
// always use the same water rules. Usage: node tools/solve-levels.mjs [levelNumber ...]
// Prints one JSON line per level: the placements (tool, x, y) that fill every pool, or FAILED.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const html = readFileSync(join(here, '..', 'index.html'), 'utf8');
const block = (a, b) => html.slice(html.indexOf(a) + a.length, html.indexOf(b));
const PSim = new Function(`${block('/* SIM-BEGIN */', '/* SIM-END */')}\nreturn PSim;`)();
// LEVELS_FILE lets a draft table be checked before it is pasted into index.html
const levelsSource = process.env.LEVELS_FILE
  ? readFileSync(process.env.LEVELS_FILE, 'utf8')
  : block('/* LEVELS-BEGIN */', '/* LEVELS-END */');
const LEVELS = new Function(`${levelsSource}\nreturn LEVELS;`)();
LEVELS.forEach((def, k) => {
  if (def.rows.length !== def.n || def.rows.some(r => r.length !== def.n)) throw new Error(`level ${k + 1}: rows do not match n=${def.n}`);
});

const BEAM = 40;
const TOOLS = ['stone', 'dam', 'split'];

function simulate(def, placements) {
  const st = PSim.create(def);
  for (const [tool, x, y] of placements) PSim.place(st, tool, y * def.n + x);
  const s = PSim.run(st);
  return { done: s.done, fill: s.fill, tick: st.tick, wasted: st.wasted, emitted: st.emitted };
}

function key(placements) {
  return placements.map(p => p.join(':')).sort().join('|');
}

function solve(def) {
  const budget = def.tools;
  const naive = simulate(def, []);
  if (naive.done) return { placements: [], tick: naive.tick, wasted: naive.wasted, emitted: naive.emitted, naive: true };
  const cellsFree = (placements) => {
    const taken = new Set(placements.map(p => p[1] + ',' + p[2]));
    const spring = def.spring[0] + ',' + def.spring[1];
    return (x, y) => !taken.has(x + ',' + y) && (x + ',' + y) !== spring;
  };
  let beam = [{ placements: [], score: 0 }];
  const total = TOOLS.reduce((a, t) => a + (budget[t] || 0), 0);
  for (let depth = 1; depth <= total; depth++) {
    const seen = new Set();
    const next = [];
    let best = null;
    for (const node of beam) {
      const used = { stone: 0, dam: 0, split: 0 };
      for (const [t] of node.placements) used[t]++;
      const free = cellsFree(node.placements);
      for (const tool of TOOLS) {
        if (used[tool] >= (budget[tool] || 0)) continue;
        for (let y = 0; y < def.n; y++) for (let x = 0; x < def.n; x++) {
          if (!free(x, y)) continue;
          const placements = [...node.placements, [tool, x, y]];
          const k = key(placements);
          if (seen.has(k)) continue;
          seen.add(k);
          const r = simulate(def, placements);
          if (r.done) {
            if (!best || r.tick < best.tick) best = { placements, tick: r.tick, wasted: r.wasted, emitted: r.emitted };
            continue;
          }
          const score = r.fill - 0.2 * (r.emitted ? r.wasted / r.emitted : 0);
          next.push({ placements, score });
        }
      }
    }
    if (best) return best;
    next.sort((a, b) => b.score - a.score);
    beam = next.slice(0, BEAM);
    if (!beam.length) break;
  }
  return null;
}

const want = process.argv.slice(2).map(Number);
for (let k = 0; k < LEVELS.length; k++) {
  if (want.length && !want.includes(k + 1)) continue;
  const t0 = Date.now();
  const r = solve(LEVELS[k]);
  const out = r
    ? { level: k + 1, sol: r.placements, tick: r.tick, wastedPct: +(100 * r.wasted / r.emitted).toFixed(1), ms: Date.now() - t0 }
    : { level: k + 1, result: 'FAILED', ms: Date.now() - t0 };
  console.log(JSON.stringify(out));
}
