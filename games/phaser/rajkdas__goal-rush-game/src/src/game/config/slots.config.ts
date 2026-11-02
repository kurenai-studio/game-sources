/**
 * GOAL RUSH — slot machine math model (PAR sheet as code).
 *
 * Every reel is a physical strip of symbols; a spin picks one stop index
 * uniformly per reel, exactly like a mechanical slot. Symbol probabilities
 * therefore emerge from strip composition — the basis of the PAR sheet in
 * docs/MATH.md. Verify with `bun scripts/rtp-simulation.ts`.
 *
 * FUN-FIRST PAY MODEL (arcade prototype, not a casino game):
 *  - ANY PAIR on the payline pays (reels 1-2, 2-3 or 1-3) — hit frequency
 *    ≈ 43%, so a spin is a moment of celebration, not a dead pause;
 *  - every symbol pays on a pair (no zero-pay pairs);
 *  - triples pay big, three trophies pay the progressive pot.
 */

export type SymbolId =
  | 'ball'
  | 'boot'
  | 'glove'
  | 'jersey'
  | 'card'
  | 'star'
  | 'whistle'
  | 'trophy';

export interface SymbolMeta {
  /** Display name (paytable UI + docs). */
  name: string;
  /** Base frame tint used when rendering the reel icon. */
  color: string;
  /** Pay for 3-of-a-kind on the payline (credits). Trophy = jackpot pot. */
  pay3: number | 'JACKPOT';
  /** Pay when ANY two reels show the pair (anywhere on the payline). */
  pay2: number;
}

export const SYMBOLS: Record<SymbolId, SymbolMeta> = {
  ball: { name: 'Soccer Ball', color: '#f4f8ff', pay3: 250, pay2: 40 },
  boot: { name: 'Golden Boot', color: '#ffc93c', pay3: 400, pay2: 45 },
  glove: { name: 'Keeper Glove', color: '#35f08b', pay3: 550, pay2: 65 },
  jersey: { name: 'Team Jersey', color: '#ff4d9d', pay3: 800, pay2: 95 },
  card: { name: 'Yellow Card', color: '#ffe9a8', pay3: 1000, pay2: 135 },
  star: { name: 'Stadium Star', color: '#b46bff', pay3: 1200, pay2: 170 },
  whistle: { name: 'Ref Whistle', color: '#8fa3c8', pay3: 2000, pay2: 260 },
  trophy: { name: 'Championship Trophy', color: '#ffc93c', pay3: 'JACKPOT', pay2: 450 },
};

export const SYMBOL_ORDER: SymbolId[] = [
  'ball',
  'boot',
  'glove',
  'jersey',
  'card',
  'star',
  'whistle',
  'trophy',
];

/** Symbol counts per reel — the "reel strips" of the base game (64 stops).
 *  More concentrated than a casino strip: ANY pair pays and pairs must land
 *  often enough that a spin is a moment of celebration, not a dead pause
 *  (~51% of spins pay a pair). Pair pays are sized so the most common pairs
 *  (ball/boot) still feel like a real win, not pocket change. */
export const REEL_WEIGHTS_BASE: Array<Record<SymbolId, number>> = [
  // Reel 1
  { ball: 18, boot: 16, glove: 12, jersey: 9, card: 4, star: 3, whistle: 1, trophy: 1 },
  // Reel 2
  { ball: 18, boot: 16, glove: 12, jersey: 9, card: 4, star: 3, whistle: 1, trophy: 1 },
  // Reel 3
  { ball: 18, boot: 16, glove: 12, jersey: 9, card: 4, star: 3, whistle: 1, trophy: 1 },
];

/**
 * Golden Reels — earned by completing the drop-target bank. Trophy (jackpot)
 * counts are multiplied so a golden spin lands the top award roughly 1 time
 * in 13 — a realistic reward for the skill shot while staying rare in the
 * base game (1 in 64³ there). Recalibrated for the concentrated base strips:
 * trophy 1/64 per reel · 47 ⇒ 47/110 per golden reel ⇒ (0.427)³ ≈ 7.8%.
 */
export const TROPHY_GOLDEN_MULTIPLIER = 47;

export function goldenWeights(base: Record<SymbolId, number>): Record<SymbolId, number> {
  return { ...base, trophy: base.trophy * TROPHY_GOLDEN_MULTIPLIER };
}

/** Deterministic PRNG (mulberry32) so generated strips are reproducible. */
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

/**
 * Expand symbol weights into a strip, then shuffle deterministically.
 * Strip ORDER does not change single-line probabilities (a stop index is
 * drawn uniformly), but interleaving looks like a real reel on screen.
 */
export function expandStrip(weights: Record<SymbolId, number>, seed: number): SymbolId[] {
  const strip: SymbolId[] = [];
  for (const id of SYMBOL_ORDER) {
    for (let i = 0; i < weights[id]; i += 1) strip.push(id);
  }
  const rand = mulberry32(seed);
  for (let i = strip.length - 1; i > 0; i -= 1) {
    const j = Math.floor(rand() * (i + 1));
    [strip[i], strip[j]] = [strip[j], strip[i]];
  }
  return strip;
}

/** The three physical reel strips of the base game. */
export const STRIPS_BASE: SymbolId[][] = REEL_WEIGHTS_BASE.map((w, i) => expandStrip(w, 1337 + i));

/** Golden strips (drop-target bank reward). */
export const STRIPS_GOLDEN: SymbolId[][] = REEL_WEIGHTS_BASE.map((w, i) =>
  expandStrip(goldenWeights(w), 7000 + i)
);

/**
 * Nominal spin cost used ONLY for PAR-sheet RTP accounting. In GOAL RUSH,
 * spins are earned through pinball play (saucer capture / target bank), so
 * this figure lets the math be compared against a conventional slot.
 */
export const NOMINAL_SPIN_COST = 10;

/** Spin sources. */
export type SpinKind = 'base' | 'golden';

export interface SpinOutcome {
  /** Stop index per reel. */
  stops: number[];
  /** Symbols on the payline. */
  line: SymbolId[];
  kind: SpinKind;
  /** True when the progressive pot is hit. */
  jackpot: boolean;
  /** Credits won before the pinball multiplier is applied (0 if none). */
  baseWin: number;
  /** Human-readable win label ("" when no win). */
  label: string;
  /** True when the result was a jackpot near-miss (2 trophies on the line). */
  nearMiss: boolean;
  /** True when the pair is the trophy pair (drives the special presentation). */
  trophyPair: boolean;
  /** True when a blank line is flagged by the referee: the G-O-A-L multiplier
   *  is reset. A miss is a risk, not a dead pause (decided in SlotMachine.spin
   *  from OFFSIDE_PROBABILITY; carried on the outcome so the reel presentation
   *  and the table-side penalty agree). */
  offside: boolean;
}

/** Probability that a losing spin (no pair, no near-miss) is flagged
 *  OFFSIDE. Roughly a third of the blank lines become an event. */
export const OFFSIDE_PROBABILITY = 0.35;
