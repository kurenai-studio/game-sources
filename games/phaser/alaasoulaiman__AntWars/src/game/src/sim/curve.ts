// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// The round curve of CONCEPT_V2 section 2 as plain functions. The game reads the curve only through this module.

/**
 * At most this many predators live at once; the rest queue and spawn as you kill. Design note, 2026-10-24, after a
 * play test of the live build: 20, down from the concept's 24, with the spawns 50 percent faster (SPAWN_GAP_TUNING), so
 * standing still and mowing the crowd down no longer wins.
 */
export const MAX_ALIVE = 20;
/** The base of the concept's count formula (24 + 3 x max(1, round / 5) ...): the round counts do not move with the cap. */
export const COUNT_BASE = 24;
/** The countdown between rounds, in seconds (the first feel round: 15, up from 10). It never pauses, not for the shop either. */
export const BREAK_SECONDS = 15;

/** Health: 150 at round 1, plus 100 a round to 950 at round 9, then plus 10 percent a round. */
export const HEALTH_START = 150;
export const HEALTH_STEP = 100;
export const HEALTH_LINEAR_LAST_ROUND = 9;
export const HEALTH_GROWTH = 1.1;
/** Our change: health growth stops at round 40, past it only the count and the spawn rate climb. */
export const HEALTH_CAP_ROUND = 40;

/** Spawn gap: the concept's 2.0 s at round 1, times 0.95 each round, never under 0.1 s. */
export const SPAWN_GAP_START = 2.0;
export const SPAWN_GAP_SHRINK = 0.95;
export const SPAWN_GAP_FLOOR = 0.1;
/**
 * Design note, 2026-10-24: predators spawn 50 percent faster, so every horde round's gap is half the concept's,
 * the 0.1 s floor kept. The termite rush and the boss rounds have gaps of their own (0.3 s and 1.5 s), held to the horde
 * ramp from LATE_SPAWN_FROM on (lane N1, rampGap).
 */
export const SPAWN_GAP_TUNING = 0.5;
/**
 * Design note, 2026-10-24: after a play test this halving came at round 11, so the later hordes spawn really fast.
 * Design note, 2026-10-25: it moves to round 6, because standing still won too easily too early. From round 6 every
 * horde round's gap halves again (a quarter of the concept's), the 0.1 s floor kept. Rounds 1 to 5 are as before.
 * Design note, 2026-10-29 (lane N1): from this round on no round type may spawn slower than the horde ramp of its
 * number; the boss escort sat at 1.5 s and round 10 read as a slow round. A boss round's escort and a termite rush
 * take the horde gap whenever it is the faster (rampGap). Before it every round keeps its own gap (the first rush,
 * round 5, its 0.3 s). The 20 alive cap is unchanged.
 */
export const LATE_SPAWN_FROM = 6;
export const LATE_SPAWN_TUNING = 0.5;

/** Our change: no predator moves faster than 94 percent of the ant's base speed, so a running ant always gains ground. */
export const PREDATOR_SPEED_CAP = 0.94;

/** Every 5th round is a breather: a termite rush of 40, fast and weak. */
export const BREATHER_EVERY = 5;
export const BREATHER_COUNT = 40;
/**
 * The first rush's own gap: termites pour in faster than the horde of round 5 (0.81 s); a first guess, tune it in the
 * playtest. Lane N1: from round 6 the round plan takes the faster of a rush's own gap and the horde gap.
 */
export const BREATHER_SPAWN_GAP = 0.3;
/**
 * Design note, 2026-10-25 (lane G9, M4): the termite rush gets harder each time it comes back; its first visit stays
 * easy and each later visit, in the higher rounds, scales up. A rush is counted by its appearance, not its round:
 * round 5 is the first, round 15 the second, then 35, 45, 55, 65, 85 and 95 (the boss
 * rounds keep their place). The first rush is exactly as before. Each later one brings 8 more termites (cap 100), comes a
 * tenth faster (the gap times 0.9, floor 0.15 s) and bites 15 percent more of the first rush's bite of 8 (cap double);
 * the shots to drop one rise slowly: 1 for the first two rushes, 2 for the third to fifth, 3 from the sixth, never more.
 *   appearance   1     2      3      4       5       6       7       8
 *   termites     40    48     56     64      72      80      88      96
 *   gap (s)      0.3   0.27   0.243  0.2187  0.1968  0.1771  0.1594  0.15 (the floor)
 *   bite         x1    x1.15  x1.3   x1.45   x1.6    x1.75   x1.9    x2 (the cap)
 *   shots        1     1      2      2       2       3       3       3
 * The 20 alive cap still holds the crowd, so a later rush is longer and denser, never a wall.
 * Lane N1: the gap row is the rush's own gap; the round plan takes the faster of it and the horde gap of
 * the round (rampGap). The horde is the faster at every visit after the first: round 15 comes 0.2438 s apart (0.27 on
 * its own), and from round 35 every rush comes at the horde's 0.1 s floor.
 */
export const BREATHER_COUNT_STEP = 8;
export const BREATHER_COUNT_CAP = 100;
export const BREATHER_GAP_SHRINK = 0.9;
export const BREATHER_GAP_FLOOR = 0.15;
export const BREATHER_BITE_STEP = 0.15;
export const BREATHER_BITE_CAP = 2;
export const BREATHER_HITS_CAP = 3;

/** Every 25th round is the Anteater's (CONCEPT_V2 section 5), in place of that round's breather. */
export const BOSS_EVERY = 25;
/**
 * Slice 4 (a play tester's list): a boss every 10th round as well, in place of that round's breather, two of them taking
 * turns: the Scythe Mantis at 10, 30, 70, the Brood Hornet at 20, 40, 60. Where the two rules meet (50, 100) the
 * Anteater keeps its round.
 */
export const MID_BOSS_EVERY = 10;
export type BossKind = 'anteater' | 'mantis' | 'hornet';
export const MID_BOSS_ROTATION: ReadonlyArray<BossKind> = ['mantis', 'hornet'];
/**
 * The Anteater comes first, then a trickle of termites so the round never goes quiet. BOSS_SPAWN_GAP is the escort's own
 * gap, the slowest it may come. Design note, 2026-10-29 (lane N1): at 1.5 s the escort made round 10 a slow round;
 * every boss round comes after the ramp begins, so the round plan gives its escort the horde gap of the round
 * (rampGap): 0.3151 s at round 10, 0.1887 s at 20, 0.146 s at 25, the 0.1 s floor from 33 on (all 1.5 s before).
 */
export const BOSS_ESCORT = 30;
export const BOSS_SPAWN_GAP = 1.5;

/** A gentle solo start: the first five rounds are cut to these percentages of the full count. */
const EARLY_CUT_PERCENT: Readonly<Record<number, number>> = { 1: 25, 2: 30, 3: 50, 4: 70, 5: 90 };

function assertRound(round: number): void {
  if (!Number.isInteger(round) || round < 1) {
    throw new RangeError(`round must be an integer of 1 or more, got ${round}`);
  }
}

/**
 * Enemies this round: 24 + int(3 x max(1, round / 5)), the second term times 0.15 x round from round 10
 * (so 24 + 0.09 x round squared), cut to 25, 30, 50, 70 and 90 percent on rounds 1 to 5.
 * Integer arithmetic keeps round 10 at exactly 33 (floating point could land on 8.999).
 */
export function enemiesForRound(round: number): number {
  assertRound(round);
  let extra: number;
  if (round < 5) extra = 3;
  else if (round < 10) extra = Math.floor((3 * round) / 5);
  else extra = Math.floor((9 * round * round) / 100);
  const full = COUNT_BASE + extra;
  const cut = EARLY_CUT_PERCENT[round];
  return cut === undefined ? full : Math.floor((full * cut) / 100);
}

/** How many may be alive at once this round. */
export function aliveCap(round: number): number {
  return Math.min(MAX_ALIVE, enemiesForRound(round));
}

/** The health curve with no cap: the concept table's column, 47,300 at round 50. */
export function uncappedHealth(round: number): number {
  assertRound(round);
  if (round <= HEALTH_LINEAR_LAST_ROUND) return HEALTH_START + HEALTH_STEP * (round - 1);
  const at9 = HEALTH_START + HEALTH_STEP * (HEALTH_LINEAR_LAST_ROUND - 1);
  return Math.round(at9 * Math.pow(HEALTH_GROWTH, round - HEALTH_LINEAR_LAST_ROUND));
}

/** The health the game uses: the same curve, frozen from round 40 on. */
export function enemyHealth(round: number): number {
  assertRound(round);
  return uncappedHealth(Math.min(round, HEALTH_CAP_ROUND));
}

/** The concept table's spawn gap column: 2.0 s at round 1, times 0.95 a round, never under 0.1 s. */
export function conceptSpawnGapSeconds(round: number): number {
  assertRound(round);
  return Math.max(SPAWN_GAP_FLOOR, SPAWN_GAP_START * Math.pow(SPAWN_GAP_SHRINK, round - 1));
}

/** Seconds between two spawns in a horde round: half the concept's gap, a quarter from round 6, never under the 0.1 s floor. */
export function spawnGapSeconds(round: number): number {
  assertRound(round);
  const late = round >= LATE_SPAWN_FROM ? LATE_SPAWN_TUNING : 1;
  return Math.max(SPAWN_GAP_FLOOR, SPAWN_GAP_START * Math.pow(SPAWN_GAP_SHRINK, round - 1) * SPAWN_GAP_TUNING * late);
}

/**
 * Lane N1: a round's own gap (a boss round's escort, a termite rush) held to the horde ramp. Before
 * LATE_SPAWN_FROM the own gap stands; from it the round never spawns slower than the horde gap of its number.
 */
export function rampGap(round: number, own: number): number {
  assertRound(round);
  return round >= LATE_SPAWN_FROM ? Math.min(own, spawnGapSeconds(round)) : own;
}

export type SpeedTier = 'walk' | 'jog' | 'sprint';
export interface SpeedMix {
  walk: number;
  jog: number;
  sprint: number;
}

/** Speed of each tier as a share of the ant's base speed. Round 1 moves at 50 percent; sprinters sit at the cap. */
const TIER_SPEED: Readonly<Record<SpeedTier, number>> = { walk: 0.5, jog: 0.72, sprint: PREDATOR_SPEED_CAP };

export function tierSpeedShare(tier: SpeedTier): number {
  return capPredatorSpeed(TIER_SPEED[tier]);
}

/** Clamps a speed share (of the ant's base speed) to the 94 percent cap. */
export function capPredatorSpeed(share: number): number {
  return Math.min(share, PREDATOR_SPEED_CAP);
}

/**
 * Slice 4 (design note, 2026-10-24: the enemies are slow at first, then fast): the pace in three bands.
 * Slow through round 4, every walker at half the ant's speed; mixed from 5 to 12, walkers, joggers and sprinters with
 * more sprinters each round; fast from 13, every one at the 94 percent cap. The tier rolls only for the predators that
 * use it (army ants, ember ants); the termite rush and the others keep their own speeds.
 */
export type SpeedBand = 'slow' | 'mixed' | 'fast';
export const SLOW_LAST_ROUND = 4;
export const FAST_FROM_ROUND = 13;
/** The mixed band's first round (5) and last round (12) mixes; the rounds between are a straight line. */
const MIXED_FIRST: Readonly<SpeedMix> = { walk: 0.5, jog: 0.4, sprint: 0.1 };
const MIXED_LAST: Readonly<SpeedMix> = { walk: 0.1, jog: 0.4, sprint: 0.5 };

export function speedBand(round: number): SpeedBand {
  assertRound(round);
  if (round <= SLOW_LAST_ROUND) return 'slow';
  if (round < FAST_FROM_ROUND) return 'mixed';
  return 'fast';
}

export function speedMix(round: number): SpeedMix {
  const band = speedBand(round);
  if (band === 'slow') return { walk: 1, jog: 0, sprint: 0 };
  if (band === 'fast') return { walk: 0, jog: 0, sprint: 1 };
  const t = (round - (SLOW_LAST_ROUND + 1)) / (FAST_FROM_ROUND - 1 - (SLOW_LAST_ROUND + 1));
  const walk = MIXED_FIRST.walk + (MIXED_LAST.walk - MIXED_FIRST.walk) * t;
  const sprint = MIXED_FIRST.sprint + (MIXED_LAST.sprint - MIXED_FIRST.sprint) * t;
  return { walk, jog: Math.max(0, 1 - walk - sprint), sprint };
}

/** Picks a tier for one spawn from a roll in [0, 1). */
export function pickSpeedTier(round: number, roll: number): SpeedTier {
  const m = speedMix(round);
  if (roll < m.walk) return 'walk';
  if (roll < m.walk + m.jog) return 'jog';
  return 'sprint';
}

/** Every 5th round from round 5 is a breather round. */
export function isBreatherRound(round: number): boolean {
  assertRound(round);
  return round % BREATHER_EVERY === 0;
}

/** The boss of this round: the Anteater every 25th round, else the rotation every 10th round, else none. */
export function bossKind(round: number): BossKind | null {
  assertRound(round);
  if (round % BOSS_EVERY === 0) return 'anteater';
  if (round % MID_BOSS_EVERY === 0) return MID_BOSS_ROTATION[(round / MID_BOSS_EVERY - 1) % MID_BOSS_ROTATION.length];
  return null;
}

/** Every 10th and every 25th round: a boss round, in place of the breather. */
export function isBossRound(round: number): boolean {
  return bossKind(round) !== null;
}

/** Lane G9, M4: the termite rushes up to this round (1 at round 5, 2 at round 15); the boss rounds between do not count. */
export function breatherAppearance(round: number): number {
  assertRound(round);
  let n = 0;
  for (let r = BREATHER_EVERY; r <= round; r += BREATHER_EVERY) if (!isBossRound(r)) n += 1;
  return n;
}

/** One termite rush: how many, how far apart, their bite as a share of the first rush's, the ant's shots one takes. */
export interface BreatherSpec {
  count: number;
  gap: number;
  bite: number;
  hits: number;
}

/** Lane G9, M4: the termite rush by its appearance (the table at BREATHER_COUNT_STEP): the first as before, every part capped. */
export function breatherByAppearance(appearance: number): BreatherSpec {
  if (!Number.isInteger(appearance) || appearance < 1) {
    throw new RangeError(`appearance must be an integer from 1, got ${appearance}`);
  }
  const k = appearance - 1;
  return {
    count: Math.min(BREATHER_COUNT_CAP, BREATHER_COUNT + BREATHER_COUNT_STEP * k),
    gap: Math.max(BREATHER_GAP_FLOOR, BREATHER_SPAWN_GAP * Math.pow(BREATHER_GAP_SHRINK, k)),
    bite: Math.min(BREATHER_BITE_CAP, 1 + BREATHER_BITE_STEP * k),
    hits: Math.min(BREATHER_HITS_CAP, appearance <= 2 ? 1 : appearance <= 5 ? 2 : 3),
  };
}

export type RoundKind = 'horde' | 'breather' | 'boss';
export interface RoundPlan {
  round: number;
  kind: RoundKind;
  /** Predators this round in total. */
  total: number;
  /** At most this many alive at once. */
  aliveCap: number;
  /** Health of a round's base predator (the army ant); elites scale off it in roster.ts. */
  health: number;
  /** Seconds between two spawns. */
  spawnGap: number;
  /** Lane G9, M4: a termite rush's bite as a share of the first rush's, and the ant's shots one of its termites takes. */
  termiteBite: number;
  termiteHits: number;
  /** Seconds of rest after the round is cleared. */
  breakSeconds: number;
  /** The boss that opens a boss round, null in any other round. */
  boss: BossKind | null;
}

/** Everything the round director needs for one round. */
export function roundPlan(round: number): RoundPlan {
  assertRound(round);
  const boss = isBossRound(round);
  const breather = !boss && isBreatherRound(round);
  const rush = breather ? breatherByAppearance(breatherAppearance(round)) : null;
  const total = boss ? BOSS_ESCORT + 1 : rush ? rush.count : enemiesForRound(round);
  return {
    round,
    kind: boss ? 'boss' : breather ? 'breather' : 'horde',
    total,
    aliveCap: Math.min(MAX_ALIVE, total),
    health: enemyHealth(round),
    spawnGap: boss ? rampGap(round, BOSS_SPAWN_GAP) : rush ? rampGap(round, rush.gap) : spawnGapSeconds(round),
    termiteBite: rush ? rush.bite : 1,
    termiteHits: rush ? rush.hits : 1,
    breakSeconds: BREAK_SECONDS,
    boss: bossKind(round),
  };
}

export interface BreakStep {
  /** Seconds left on the countdown, never under 0. */
  left: number;
  /** True on the frame the countdown reaches zero: the next round starts by itself. */
  start: boolean;
}

/**
 * One frame of the countdown between rounds. Standing in the nest or an open shop does not stop it; only an open pick
 * sheet holds it, with the whole Yard (sim/pause.ts: no frame of the Yard runs while the cards are up).
 */
export function breakStep(left: number, dt: number): BreakStep {
  const next = Math.max(0, left - dt);
  return { left: next, start: next <= 0 };
}
