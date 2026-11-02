/**
 * GOAL RUSH — RTP simulation + PAR-sheet verification.
 *
 * Runs in Bun:  bun scripts/rtp-simulation.ts
 *
 * 1. Computes the EXACT probabilities of every payline outcome from the reel
 *    strip composition (combinatorics — no randomness).
 * 2. Validates them with a 2-million-spin Monte-Carlo per game mode.
 * 3. Writes docs/RTP-RESULTS.md with the numbers referenced by docs/MATH.md.
 */

import { writeFileSync, mkdirSync } from 'node:fs';
import {
  NOMINAL_SPIN_COST,
  REEL_WEIGHTS_BASE,
  STRIPS_BASE,
  STRIPS_GOLDEN,
  SYMBOLS,
  SYMBOL_ORDER,
  TROPHY_GOLDEN_MULTIPLIER,
  type SpinKind,
  type SymbolId,
} from '../src/game/config/slots.config';

/* ── helpers ─────────────────────────────────────────────────────────────── */

function probs(strips: SymbolId[][]): Array<Record<SymbolId, number>> {
  return strips.map((strip) => {
    const counts = {} as Record<SymbolId, number>;
    for (const s of SYMBOL_ORDER) counts[s] = 0;
    for (const s of strip) counts[s] += 1;
    const p = {} as Record<SymbolId, number>;
    for (const s of SYMBOL_ORDER) p[s] = counts[s] / strip.length;
    return p;
  });
}

interface Exact {
  hitFrequency: number;
  rtpExJackpot: number;
  jackpotProb: number;
  evAtPot: (pot: number) => number;
  rows: Array<{ symbol: SymbolId; p3: number; pay3: number; p2: number; pay2: number }>;
}

function exactMath(strips: SymbolId[][]): Exact {
  const [p1, p2, p3] = probs(strips);
  let hitProb = 0;
  let evCents = 0; // credits × probability
  let jackpotProb = 0;
  const rows: Exact['rows'] = [];

  for (const s of SYMBOL_ORDER) {
    const three = p1[s] * p2[s] * p3[s];
    // ANY pair on the payline (not a triple): the three arrangements are
    // mutually exclusive given "not all three equal".
    const pair =
      p1[s] * p2[s] * (1 - p3[s]) +
      p2[s] * p3[s] * (1 - p1[s]) +
      p1[s] * p3[s] * (1 - p2[s]);
    const pay3 = SYMBOLS[s].pay3;
    const pay3Num = pay3 === 'JACKPOT' ? 0 : pay3;
    if (pay3 === 'JACKPOT') jackpotProb = three;
    hitProb += three + pair; // every pair pays in the fun-first model
    evCents += three * pay3Num + pair * SYMBOLS[s].pay2;
    rows.push({ symbol: s, p3: three, pay3: pay3Num, p2: pair, pay2: SYMBOLS[s].pay2 });
  }

  return {
    hitFrequency: hitProb,
    rtpExJackpot: evCents / NOMINAL_SPIN_COST,
    jackpotProb,
    evAtPot: (pot: number) => evCents + jackpotProb * pot,
    rows,
  };
}

/* Deterministic PRNG for reproducible simulations (mulberry32). */
function mulberry32(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

interface SimResult {
  spins: number;
  wins: number;
  creditsWon: number;
  creditsExJackpot: number;
  jackpots: number;
  maxWin: number;
  nearMisses: number;
}

function simulate(strips: SymbolId[][], spins: number, seed: number): SimResult {
  const rand = mulberry32(seed);
  const res: SimResult = {
    spins,
    wins: 0,
    creditsWon: 0,
    creditsExJackpot: 0,
    jackpots: 0,
    maxWin: 0,
    nearMisses: 0,
  };
  for (let i = 0; i < spins; i += 1) {
    const stops = strips.map((strip) => Math.floor(rand() * strip.length));
    const line = stops.map((stop, r) => strips[r][stop]);
    let win = 0;
    if (line[0] === line[1] && line[1] === line[2]) {
      const pay = SYMBOLS[line[0]].pay3;
      if (pay === 'JACKPOT') {
        res.jackpots += 1;
        win = 500; // seed value for RTP accounting
      } else {
        win = pay;
      }
    } else if (line[0] === line[1] || line[1] === line[2] || line[0] === line[2]) {
      const sym = line[0] === line[1] || line[0] === line[2] ? line[0] : line[1];
      win = SYMBOLS[sym].pay2;
      if (sym === 'trophy') res.nearMisses += 1; // one trophy from the pot
    }
    if (win > 0) {
      res.wins += 1;
      res.creditsWon += win;
      if (res.jackpots === 0 || win !== 500) res.creditsExJackpot += win;
      res.maxWin = Math.max(res.maxWin, win);
    }
  }
  return res;
}

/* ── report ──────────────────────────────────────────────────────────────── */

function fmtPct(x: number): string {
  return `${(x * 100).toFixed(4)}%`;
}

function fmtOneIn(x: number): string {
  return x > 0 ? `1 in ${Math.round(1 / x).toLocaleString()}` : '—';
}

function report(kind: SpinKind, strips: SymbolId[][]): string {
  const ex = exactMath(strips);
  const sim = simulate(strips, 2_000_000, kind === 'base' ? 1337 : 7001);
  const simRtpExJp = sim.creditsExJackpot / sim.spins / NOMINAL_SPIN_COST;
  const simHit = sim.wins / sim.spins;
  const evSeed = ex.evAtPot(500) / NOMINAL_SPIN_COST;
  const evThousand = ex.evAtPot(1000) / NOMINAL_SPIN_COST;

  const lines: string[] = [];
  lines.push(`### ${kind === 'base' ? 'Base game' : `Golden spins (trophy ×${TROPHY_GOLDEN_MULTIPLIER})`}\n`);
  lines.push(`Reel strips: ${strips.map((s) => `${s.length} stops`).join(' / ')}\n`);
  lines.push(`| Symbol | P(×3) | Pay ×3 | P(any pair) | Pay pair |`);
  lines.push(`|---|---|---|---|---|`);
  for (const row of ex.rows) {
    lines.push(
      `| ${SYMBOLS[row.symbol].name} | ${fmtPct(row.p3)} | ${
        SYMBOLS[row.symbol].pay3 === 'JACKPOT' ? '**JACKPOT**' : row.pay3
      } | ${fmtPct(row.p2)} | ${row.pay2 || '—'} |`
    );
  }
  lines.push('');
  lines.push(`| Metric | Exact (combinatoric) | Monte-Carlo (2M spins) |`);
  lines.push(`|---|---|---|`);
  lines.push(
    `| Paying-hit frequency | ${fmtPct(ex.hitFrequency)} | ${fmtPct(simHit)} (${sim.wins.toLocaleString()} paying hits) |`
  );
  lines.push(
    `| RTP excl. jackpot (vs ${NOMINAL_SPIN_COST}-credit nominal cost) | ${fmtPct(ex.rtpExJackpot)} | ${fmtPct(simRtpExJp)} |`
  );
  lines.push(
    `| Jackpot probability | ${fmtPct(ex.jackpotProb)} (${fmtOneIn(ex.jackpotProb)}) | ${
      sim.jackpots
    } hits (${fmtOneIn(sim.jackpots / sim.spins)}) |`
  );
  lines.push(`| RTP incl. jackpot at pot = 500 | ${fmtPct(evSeed)} | — |`);
  lines.push(`| RTP incl. jackpot at pot = 1,000 | ${fmtPct(evThousand)} | — |`);
  lines.push(`| Max single simulated win | — | ${sim.maxWin.toLocaleString()} credits |`);
  lines.push(
    `| Near-misses (trophy pair — one away) | — | ${fmtPct(sim.nearMisses / sim.spins)} |\n`
  );
  return lines.join('\n');
}

const header = `# GOAL RUSH — RTP verification results

Generated by \`bun scripts/rtp-simulation.ts\` (deterministic seed; exact
probabilities computed from reel strip composition, cross-checked with a
2,000,000-spin Monte-Carlo per mode). The jackpot contributes the full pot
at the listed value; spins are EARNED through pinball play in GOAL RUSH,
the ${NOMINAL_SPIN_COST}-credit nominal cost exists only so the math can be
compared against a conventional slot PAR sheet.

> Note: in the live game, line wins are multiplied by the pinball multiplier
> (up to ×5), which raises the effective return for skilled play.

`;

const body = `${report('base', STRIPS_BASE)}\n${report('golden', STRIPS_GOLDEN)}`;

const footer = `
## Interpretation

- The **fun-first pay model** (any pair pays, every symbol pays) puts the
  paying-hit frequency near **43%** — roughly one win per 2-3 spins, so the
  slot half of the machine is a constant source of celebration rather than
  a dead pause. Spins are EARNED through pinball play, so the generous RTP
  versus the nominal cost is intentional reward design, not a flaw.
- **Golden spins** are a skill-earned bonus feature (clear the 4-target
  drop bank): trophy counts are multiplied so the jackpot lands roughly
  once per 13 golden spins.
- Two-trophy **near-misses** still pay the trophy pair — the anticipation
  hook for the jackpot chase.
`;

mkdirSync('docs', { recursive: true });
writeFileSync('docs/RTP-RESULTS.md', header + body + footer, 'utf8');

/* Also print a summary to the console. */
console.log(header);
console.log(body);
console.log(footer);
console.log('Wrote docs/RTP-RESULTS.md');
