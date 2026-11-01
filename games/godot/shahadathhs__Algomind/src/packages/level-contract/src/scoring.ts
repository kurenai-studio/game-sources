import type { Difficulty } from "./types.js";

/**
 * The rules that turn a verified result into stars and points. A rule set is versioned data: the
 * API stores each version, and a change creates a new version instead of editing an old one.
 */
export type PointsRules = {
  version: number;
  /** Points for any verified clear, by the level's difficulty. */
  base: Record<Difficulty, number>;
  /** Bonus when the program uses at most par slots. */
  parFull: number;
  /** Bonus when it uses more than par but at most `nearSlots` more. */
  parNear: number;
  nearSlots: number;
  /** Smaller bonus when the run takes at most par's steps. */
  stepsBonus: number;
  /** Added once to a level's score, for the first verified clear. */
  firstClear: number;
};

export const DEFAULT_POINTS_RULES: PointsRules = {
  version: 1,
  base: { easy: 10, medium: 20, hard: 30 },
  parFull: 10,
  parNear: 5,
  nearSlots: 2,
  stepsBonus: 5,
  firstClear: 10,
};

export type ScoreInput = {
  difficulty: Difficulty;
  /** The level version's par: the solver's slots and steps. */
  par: { commands: number; steps: number };
  /** What the verified program used. */
  slots: number;
  steps: number;
};

export type Score = {
  /** 3 at par or better, 2 within `nearSlots` of par, otherwise 1. */
  stars: 1 | 2 | 3;
  /** Base plus the par and steps bonuses. The first-clear bonus is not in it. */
  points: number;
  /** `points` plus the first-clear bonus: what a level is worth to a player who has cleared it. */
  levelScore: number;
};

/** Scores one verified clear. Pure: the same rules and input always give the same score. */
export function scoreResult(rules: PointsRules, input: ScoreInput): Score {
  const over = input.slots - input.par.commands;
  const stars = over <= 0 ? 3 : over <= rules.nearSlots ? 2 : 1;
  const parBonus = over <= 0 ? rules.parFull : over <= rules.nearSlots ? rules.parNear : 0;
  const stepsBonus = input.steps <= input.par.steps ? rules.stepsBonus : 0;
  const points = rules.base[input.difficulty] + parBonus + stepsBonus;
  return { stars, points, levelScore: points + rules.firstClear };
}
