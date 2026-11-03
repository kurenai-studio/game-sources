import { createRng } from './rng.js';
import { WIDTH, HALF, clampMallet, homePosition } from './table.js';
import { STEP, createMallet, moveMallet, stepPuck, goalScorer } from './physics.js';
import { AI_LEVELS, createAI, aiTarget } from './ai.js';

export const LEVELS = Object.freeze(['easy', 'medium', 'hard']);
export const GOAL_OPTIONS = Object.freeze([5, 7, 10]);
/** Mallet speed limit for a person (units per second). */
export const HUMAN_SPEED = 7;
/** Seconds the play stays frozen after a goal (banner time). */
export const GOAL_PAUSE = 1.2;
const TRAIL_LENGTH = 12;
const TRAIL_SPEED = 1.5;
const MAX_FRAME = 0.25;

/**
 * @typedef {'human' | 'easy' | 'medium' | 'hard'} Controller
 * @typedef {{
 *   mode?: 'cpu' | 'pvp' | 'ai', level?: 'easy' | 'medium' | 'hard',
 *   goalsToWin?: number, seed?: number, controllers?: [Controller, Controller],
 *   serve?: 0 | 1,
 * }} GameOptions
 */

/** Puck at rest on the given player's side. */
function servePuck(side) {
  return { x: WIDTH / 2, y: side === 1 ? HALF - 0.3 : HALF + 0.3, vx: 0, vy: 0 };
}

/** Builds a player record for a side and its controller. */
function createPlayer(side, controller, rng) {
  const home = homePosition(side);
  return {
    side,
    controller,
    ai: controller === 'human' ? null : createAI(controller, rng),
    speed: controller === 'human' ? HUMAN_SPEED : AI_LEVELS[controller].speed,
    mallet: createMallet(home.x, home.y),
    target: { ...home },
  };
}

/** Puts mallets home and the puck on the side of `serveSide`. */
function resetPositions(game, serveSide) {
  game.puck = servePuck(serveSide);
  game.trail = [];
  for (const p of game.players) {
    const home = homePosition(p.side);
    p.mallet = createMallet(home.x, home.y);
    p.target = { ...home };
  }
}

/**
 * Creates a new match.
 * mode 'cpu': you (bottom, player 0) against the computer at `level`;
 * mode 'pvp': two people; mode 'ai': both sides from `controllers` (tests).
 * @param {GameOptions} [opts]
 */
export function createGame(opts = {}) {
  const mode = opts.mode === 'pvp' || opts.mode === 'ai' ? opts.mode : 'cpu';
  const level = LEVELS.includes(opts.level) ? opts.level : 'medium';
  const goalsToWin = GOAL_OPTIONS.includes(opts.goalsToWin) ? opts.goalsToWin : 7;
  const rng = createRng(opts.seed ?? 1);
  const controllers = mode === 'ai' && opts.controllers ? opts.controllers
    : mode === 'pvp' ? ['human', 'human'] : ['human', level];
  const game = {
    mode,
    level,
    goalsToWin,
    rng,
    players: controllers.map((c, side) => createPlayer(side, c, rng)),
    score: [0, 0],
    phase: 'play',
    paused: false,
    frozen: false,
    goalTimer: 0,
    lastScorer: null,
    winner: null,
    accumulator: 0,
    time: 0,
    puck: null,
    trail: [],
  };
  const serve = opts.serve ?? (mode === 'cpu' ? 0 : rng() < 0.5 ? 0 : 1);
  resetPositions(game, serve);
  return game;
}

/**
 * Restarts the match with the same settings.
 * @param {ReturnType<typeof createGame>} game
 */
export function restartMatch(game) {
  game.score = [0, 0];
  game.phase = 'play';
  game.paused = false;
  game.frozen = false;
  game.goalTimer = 0;
  game.lastScorer = null;
  game.winner = null;
  game.accumulator = 0;
  resetPositions(game, game.mode === 'cpu' ? 0 : game.rng() < 0.5 ? 0 : 1);
}

/**
 * Sets where a person's mallet should go (world units, clamped to its half).
 * @param {ReturnType<typeof createGame>} game
 * @param {0 | 1} side
 * @param {number} x
 * @param {number} y
 */
export function setTarget(game, side, x, y) {
  game.players[side].target = clampMallet(x, y, side);
}

/**
 * Moves a person's target by an offset (keyboard control).
 * @param {ReturnType<typeof createGame>} game
 * @param {0 | 1} side
 * @param {number} dx
 * @param {number} dy
 */
export function moveTargetBy(game, side, dx, dy) {
  const t = game.players[side].target;
  setTarget(game, side, t.x + dx, t.y + dy);
}

/**
 * Pauses or resumes the match.
 * @param {ReturnType<typeof createGame>} game
 * @param {boolean} paused
 */
export function setPaused(game, paused) {
  game.paused = paused;
}

/** Records the puck position for the trail drawn behind a fast puck. */
function updateTrail(game) {
  const { puck, trail } = game;
  if (Math.hypot(puck.vx, puck.vy) > TRAIL_SPEED) trail.push({ x: puck.x, y: puck.y });
  else if (trail.length) trail.shift();
  if (trail.length > TRAIL_LENGTH) trail.shift();
}

/** Handles a goal by `scorer`; returns the events it causes. */
function scoreGoal(game, scorer) {
  game.score[scorer] += 1;
  game.lastScorer = scorer;
  const events = [{ type: 'goal', scorer }];
  if (game.score[scorer] >= game.goalsToWin) {
    game.phase = 'over';
    game.winner = scorer;
    events.push({ type: 'over', winner: scorer });
  } else {
    game.phase = 'goal';
    game.goalTimer = GOAL_PAUSE;
  }
  return events;
}

/** One fixed physics step. */
function stepGame(game) {
  game.time += STEP;
  if (game.phase === 'goal') {
    game.goalTimer -= STEP;
    if (game.goalTimer <= 0) {
      resetPositions(game, 1 - game.lastScorer);
      game.phase = 'play';
    }
    return [];
  }
  for (const p of game.players) {
    const t = p.ai ? aiTarget(p.ai, p.side, game.puck, p.mallet, STEP) : p.target;
    moveMallet(p.mallet, t.x, t.y, p.speed, p.side, STEP);
  }
  const events = stepPuck(game.puck, game.players.map((p) => p.mallet), STEP);
  updateTrail(game);
  const scorer = goalScorer(game.puck);
  return scorer === null ? events : events.concat(scoreGoal(game, scorer));
}

/**
 * Advances the match by `dt` seconds of real time using fixed steps through an
 * accumulator, so the result does not depend on the frame rate.
 * @param {ReturnType<typeof createGame>} game
 * @param {number} dt Seconds since the last frame.
 * @returns {Array<{type: string}>} Events: hit, wall, post, goal, over.
 */
export function update(game, dt) {
  if (game.frozen || game.paused || game.phase === 'over') return [];
  game.accumulator += Math.min(Math.max(dt, 0), MAX_FRAME);
  const events = [];
  while (game.accumulator >= STEP) {
    game.accumulator -= STEP;
    for (const e of stepGame(game)) events.push(e);
    if (game.phase === 'over') break;
  }
  return events;
}

/**
 * Plain snapshot of what a UI needs to draw.
 * @param {ReturnType<typeof createGame>} game
 */
export function getState(game) {
  return {
    mode: game.mode,
    level: game.level,
    goalsToWin: game.goalsToWin,
    phase: game.phase,
    paused: game.paused,
    frozen: game.frozen,
    score: [...game.score],
    lastScorer: game.lastScorer,
    winner: game.winner,
    goalTimer: game.goalTimer,
    puck: { ...game.puck },
    trail: game.trail.map((p) => ({ ...p })),
    mallets: game.players.map((p) => ({ x: p.mallet.x, y: p.mallet.y, vx: p.mallet.vx, vy: p.mallet.vy })),
    controllers: game.players.map((p) => p.controller),
  };
}

/**
 * Builds the frozen mid-match frame used for the README screenshot: 3-2, the
 * puck flying fast toward the computer's goal with its trail.
 * @returns {ReturnType<typeof createGame>}
 */
export function createDemoGame() {
  const game = createGame({ mode: 'cpu', level: 'medium', seed: 7 });
  game.score = [3, 2];
  game.puck = { x: 0.43, y: 0.62, vx: 0.55, vy: -3.4 };
  game.trail = [];
  for (let i = TRAIL_LENGTH; i >= 1; i -= 1) {
    game.trail.push({ x: game.puck.x - game.puck.vx * STEP * i * 1.5, y: game.puck.y - game.puck.vy * STEP * i * 1.5 });
  }
  game.players[0].mallet = createMallet(0.36, 1.12);
  game.players[0].target = { x: 0.36, y: 1.12 };
  game.players[1].mallet = createMallet(0.62, 0.2);
  game.frozen = true;
  return game;
}

