/**
 * GOAL RUSH — slot RNG + payline evaluation.
 *
 * Randomness comes from the Web Crypto API when available (uniform, no
 * modulo bias) with a Math.random fallback. Each reel stop is drawn
 * uniformly over the physical strip, mirroring a mechanical slot machine.
 */

import { SYMBOLS, type SpinOutcome, type SpinKind, type SymbolId } from '../config/slots.config';

/** Cryptographically-strong uniform integer in [0, max). */
export function randomInt(max: number): number {
  if (typeof crypto !== 'undefined' && crypto.getRandomValues) {
    // Rejection sampling avoids modulo bias.
    const limit = Math.floor(0xffffffff / max) * max;
    const buf = new Uint32Array(1);
    for (;;) {
      crypto.getRandomValues(buf);
      if (buf[0] < limit) return buf[0] % max;
    }
  }
  return Math.floor(Math.random() * max);
}

/** Pick a stop index on a strip. */
export function pickStop(strip: SymbolId[]): number {
  return randomInt(strip.length);
}

/**
 * Evaluate a spin: 3-of-a-kind pays the pay3 value, otherwise ANY pair on
 * the payline (reels 1-2, 2-3 or 1-3) pays pay2. Two trophies on the line
 * is a paying pair AND a flagged near-miss (one trophy from the pot).
 */
export function evaluate(stops: number[], strips: SymbolId[][], kind: SpinKind): SpinOutcome {
  const line = stops.map((stop, i) => strips[i][stop]);
  let jackpot = false;
  let baseWin = 0;
  let label = '';
  let trophyPair = false;

  const [a, b, c] = line;
  if (a === b && b === c) {
    const pay = SYMBOLS[a].pay3;
    if (pay === 'JACKPOT') {
      jackpot = true;
      label = 'PROGRESSIVE JACKPOT';
    } else {
      baseWin = pay;
      label = `THREE ${SYMBOLS[a].name.toUpperCase()}S`;
    }
  } else if (a === b || b === c || a === c) {
    // Any pair pays — the matched symbol is the repeated one.
    const sym = a === b || a === c ? a : b;
    baseWin = SYMBOLS[sym].pay2;
    trophyPair = sym === 'trophy';
    label = trophyPair ? 'TROPHY PAIR — ONE AWAY!' : `PAIR OF ${SYMBOLS[sym].name.toUpperCase()}S`;
  }

  const trophies = line.filter((s) => s === 'trophy').length;
  return {
    stops,
    line,
    kind,
    jackpot,
    baseWin,
    label,
    nearMiss: trophies === 2 && !jackpot,
    trophyPair,
    offside: false,
  };
}
