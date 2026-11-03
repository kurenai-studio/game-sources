export type RunPhase = 'running' | 'over';
/** `ringMissed` is the campaign's own ending: a dashed ring was left behind. */
export type FailReason = 'depleted' | 'sweptAway' | 'ringMissed' | null;

/**
 * Absolute floor: below this many individuals the shoal is no longer a shoal.
 *
 * Slowblue: with a 25-strong start this floor, not the fraction, is what ends a run - 40%
 * of 25 is 10, so the number below decides it. Twelve keeps the two endings both
 * reachable: measured at 25 fish, dropping the floor to 6 made `depleted` unreachable
 * for every scripted style, because a shoal that thin is also light enough to survive
 * everything that thinned it.
 */
export const MIN_SHOAL = 12;
/**
 * ...and a shoal that has lost this much of what it started with is finished too.
 *
 * Slowblue: without this, attrition had no teeth. A smaller shoal is *lighter*, so it
 * turns better - losing individuals made the game easier, and the "the shoal fell
 * apart" ending was unreachable in practice (measured: every scripted style died
 * only by being left behind). Keyed to the starting shoal, so rescued fish are pure
 * buffer: growth buys robustness instead of raising the bar you have to clear.
 */
export const MIN_SHOAL_FRACTION = 0.4;

/** Individuals you may lose between two gates and still keep the streak. */
export const STREAK_TOLERANCE = 4;
/**
 * Widest the shoal may get between two gates and still keep the streak.
 *
 * Slowblue: this is the number that finally made the multiplier mean something. Breaking
 * the streak on damage alone did not separate skill at all - measured, a careful run
 * and a panicky one lose almost the same count, because most attrition is stragglers
 * culled off the back rather than rock strikes, and the panicky bot scored 2136
 * against the careful bot's 2194. What actually distinguishes them is *shape*: mean
 * spread 64 against 115. Cohesion is the skill the whole game is about, so cohesion
 * is what the multiplier is now priced on.
 */
export const COHESION_LIMIT = 100;
/** Streak length at which the multiplier stops growing. */
export const STREAK_CAP = 8;
/** Multiplier gained per streak step. Cap x step = +2.40 at the ceiling. */
export const STREAK_STEP = 0.3;

/**
 * What each verb is worth, before the streak multiplier.
 *
 * Slowblue: `RESCUE_POINTS` came down from 25 in the rebalance. Once every section
 * counted (see `ObstacleSystem.prune`), a bot that detoured for every pod scored
 * 1.56x the bot that ignored them - past the 1.45 ceiling the design sets for
 * "growth is a trade, not the answer". Rescue is now worth less per head and a
 * cleared section worth more, which prices detours against progress instead of
 * on top of it.
 */
export const GATE_POINTS = 170;
export const RESCUE_POINTS = 16;
export const REFORM_POINTS = 250;
/** Banked once, for flying the whole campaign. */
export const COMPLETION_POINTS = 2000;
/** A level finished intact. Paid per level, so a long run is worth its length. */
export const LEVEL_POINTS = 400;

export function failureThreshold(startCount: number): number {
  return Math.max(MIN_SHOAL, Math.round(startCount * MIN_SHOAL_FRACTION));
}

export class RunState {
  phase: RunPhase = 'running';
  reason: FailReason = null;
  /** Seconds of simulated time in this run. */
  time = 0;
  distance = 0;
  gates = 0;
  rescued = 0;
  lost = 0;
  missedPods = 0;
  /** Times the shoal was split around an obstacle and brought back together. */
  reforms = 0;
  score = 0;
  peakCount = 0;
  /** Seconds the shoal has been behind the camera's kill line. */
  strandedFor = 0;
  /** Deepest zone index reached this run. */
  zone = 0;
  /** Deepest authored level reached this run. */
  level = 0;
  /**
   * Highest section id ever cleared this run - the campaign's true progress
   * measure, and the only one that survives a station restart honestly.
   *
   * `distance` is px and freezes when a station begins again (the swarm really is
   * back where it started, so it has not gone higher). `gates` counts every
   * section cleared and therefore *rewards* restarting, since a re-flown section
   * is counted twice. This counts how far up the script the player has actually
   * got, which is neither.
   */
  furthestSection = -1;
  /** Stations begun again rather than runs ended. See `sim/Failure.ts`. */
  restarts = 0;
  /** Levels finished, and whether the last one of the campaign was among them. */
  levelsCleared = 0;
  completed = false;
  /** Required rings absorbed. The campaign's real measure of a clean run. */
  ringsHeld = 0;

  /**
   * Slowblue: the streak is the only thing in the game that rewards *how* you got there.
   *
   * Score used to be a pure sum of things that happened to you, so a sloppy run
   * through six gates beat a clean run through five. A gate advances the streak only
   * if the shoal reached it intact - under `STREAK_TOLERANCE` avoidable deaths and
   * never wider than `COHESION_LIMIT` - and the multiplier compounds from there. One
   * careless rock, or one moment of letting the shoal come apart, resets it.
   */
  streak = 0;
  bestStreak = 0;
  /** Individuals lost since the last gate; compared against the tolerance. */
  damageSinceGate = 0;
  /** Worst shoal spread seen since the last gate; compared against the limit. */
  spreadSinceGate = 0;
  /** Multiplied points banked so far. Distance and headcount are added live. */
  earned = 0;
  /** Seconds since the streak last changed - the HUD fades the badge out on this. */
  sinceStreakChange = Infinity;

  reset(): void {
    this.phase = 'running';
    this.reason = null;
    this.time = 0;
    this.distance = 0;
    this.gates = 0;
    this.rescued = 0;
    this.lost = 0;
    this.missedPods = 0;
    this.reforms = 0;
    this.score = 0;
    this.peakCount = 0;
    this.strandedFor = 0;
    this.zone = 0;
    this.level = 0;
    this.furthestSection = -1;
    this.restarts = 0;
    this.levelsCleared = 0;
    this.completed = false;
    this.ringsHeld = 0;
    this.streak = 0;
    this.bestStreak = 0;
    this.damageSinceGate = 0;
    this.spreadSinceGate = 0;
    this.earned = 0;
    this.sinceStreakChange = Infinity;
  }

  /** 1.0 .. 3.4 */
  get multiplier(): number {
    return 1 + Math.min(this.streak, STREAK_CAP) * STREAK_STEP;
  }

  /**
   * Individuals gone. Returns true if this broke a live streak.
   *
   * `damaging` is false for stragglers quietly culled off the back of the screen.
   * Slowblue: with every loss counting, the streak was unreachable - a competent run
   * bleeds ~10 individuals per section, almost all of them stragglers, so the
   * multiplier reset at every gate and the whole mechanic was dead weight. Only
   * things the player can actually avoid - rock and teeth - break it.
   */
  noteLoss(n = 1, damaging = true): boolean {
    this.lost += n;
    if (!damaging) return false;
    this.damageSinceGate += n;
    if (this.damageSinceGate <= STREAK_TOLERANCE || this.streak === 0) return false;
    this.streak = 0;
    this.sinceStreakChange = 0;
    return true;
  }

  /** Feeds the cohesion half of the streak test. Called every step. */
  noteSpread(spread: number): void {
    if (spread > this.spreadSinceGate) this.spreadSinceGate = spread;
  }

  /**
   * A station begins again. Costs the given fraction of everything banked, and
   * every per-station streak, but never the run.
   *
   * The clock is deliberately untouched: time is most of what a restart costs,
   * and stopping it would make the setback free for anyone not chasing a score.
   */
  noteRestart(cost: number): void {
    this.restarts++;
    this.earned = Math.round(this.earned * (1 - cost));
    this.streak = 0;
    this.damageSinceGate = 0;
    this.spreadSinceGate = 0;
    this.strandedFor = 0;
    this.sinceStreakChange = 0;
  }

  /**
   * A section cleared. Returns true if the streak advanced.
   *
   * `count` is how many individuals the body currently has, and it widens the
   * cohesion limit with the square root of it. `Infinity` switches the cohesion
   * clause off entirely, which is what the stations that cannot be lost pass.
   *
   * Slowblue: `COHESION_LIMIT` was a flat 100 px and this is the second half of the
   * "growth must not raise the bar" rule that `MIN_SHOAL_FRACTION` states above
   * and `World.failureThreshold` states again. Spread scales with the square root
   * of population at a fixed separation - it is a packing fact, not a skill one -
   * so a body of ninety-six sits over 100 px however perfectly it is flown, and
   * the multiplier it can never advance is worth up to x3.4. Measured over eleven
   * seeds from act VII's second half: a bot that took every ring scored 6 498 with
   * a best streak of 1.9, against 12 554 and 7.4 for one that touched nothing.
   * Ignoring the only content in the act was worth 1.93x, and the mechanism was a
   * constant with no population term in it.
   *
   * The default of 0 keeps every direct caller - all twenty in
   * `tests/runstate.test.ts` - on the original 100.
   */
  noteGate(count = 0): boolean {
    this.gates++;
    // sqrt, because that is how a fixed-separation body's radius grows: 25 fish
    // at 100 px, 100 at 200, and no credit at all below the starting shoal.
    const limit = COHESION_LIMIT * Math.max(1, Math.sqrt(count / 25));
    const clean =
      this.damageSinceGate <= STREAK_TOLERANCE && this.spreadSinceGate <= limit;
    this.damageSinceGate = 0;
    this.spreadSinceGate = 0;
    this.earned += Math.round(GATE_POINTS * this.multiplier);
    if (!clean) {
      if (this.streak > 0) this.sinceStreakChange = 0;
      this.streak = 0;
      return false;
    }
    this.streak++;
    this.bestStreak = Math.max(this.bestStreak, this.streak);
    this.sinceStreakChange = 0;
    return true;
  }

  noteRescue(count: number): void {
    this.rescued += count;
    this.earned += Math.round(RESCUE_POINTS * count * this.multiplier);
  }

  noteReform(): void {
    this.reforms++;
    this.earned += Math.round(REFORM_POINTS * this.multiplier);
  }

  /** A required ring absorbed. */
  noteRing(): void {
    this.ringsHeld++;
  }

  /** A level's last section cleared. */
  noteLevel(index: number): void {
    this.levelsCleared++;
    this.level = Math.max(this.level, index + 1);
    this.earned += Math.round(LEVEL_POINTS * this.multiplier);
  }

  /**
   * Score is deliberately dumb: distance + what you banked + who is still with you.
   * `earned` already carries the streak multiplier, so this stays a pure function of
   * state and can be recomputed every step without drifting.
   */
  recomputeScore(count: number): void {
    this.score = Math.floor(this.distance * 0.1) + this.earned + count * 2;
  }

  fail(reason: Exclude<FailReason, null>): void {
    if (this.phase === 'over') return;
    this.phase = 'over';
    this.reason = reason;
  }

  /** The campaign was flown to its end. Same phase, no reason: a run that stopped. */
  complete(): void {
    if (this.phase === 'over') return;
    this.phase = 'over';
    this.reason = null;
    this.completed = true;
    this.earned += Math.round(COMPLETION_POINTS * this.multiplier);
  }
}
