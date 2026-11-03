import {
  WIDTH, LENGTH, HALF, GOAL_LEFT, GOAL_RIGHT,
  PUCK_RADIUS, MALLET_RADIUS, clamp, clampMallet,
} from './table.js';
import { HIT_RADIUS } from './physics.js';

// The computer thinks in a local frame where it defends the goal on y = 0 and
// owns the top half. For the bottom player the y axis is mirrored.

/**
 * Mallet line the computer guards, in local table units. predictCrossing only
 * reflects off the straight side walls, so this line must stay outside the
 * corner-arc zone (DEFENCE_LINE > CORNER_RADIUS); a test enforces it.
 */
export const DEFENCE_LINE = 0.16;
const ORBIT_STEP = 0.9;

/**
 * Per-level tuning: decision interval (s), mallet speed (units/s), prediction
 * error (units), puck speed below which it attacks, chance of a bank shot.
 */
export const AI_LEVELS = Object.freeze({
  easy: Object.freeze({ reaction: 0.4, speed: 1.6, error: 0.2, attackBelow: 0.9, bank: 0.15 }),
  medium: Object.freeze({ reaction: 0.25, speed: 2.4, error: 0.13, attackBelow: 1.3, bank: 0.3 }),
  hard: Object.freeze({ reaction: 0.12, speed: 3.4, error: 0.07, attackBelow: 1.7, bank: 0.35 }),
});

/**
 * Predicts where the puck centre crosses the horizontal line y = lineY,
 * following straight-line motion with reflections off the side walls.
 * @param {number} x
 * @param {number} y
 * @param {number} vx
 * @param {number} vy
 * @param {number} lineY
 * @returns {{x: number, bounces: number} | null} null if it moves away.
 */
export function predictCrossing(x, y, vx, vy, lineY) {
  const dy = lineY - y;
  if (vy === 0 || dy / vy <= 0) return null;
  const lo = PUCK_RADIUS;
  const span = WIDTH - 2 * PUCK_RADIUS;
  const u = x + (vx * dy) / vy - lo;
  const period = 2 * span;
  const m = ((u % period) + period) % period;
  const folded = m <= span ? lo + m : lo + period - m;
  const bounces = u >= 0 ? Math.floor(u / span) : Math.floor(-u / span) + 1;
  return { x: folded, bounces };
}

/**
 * Creates a computer opponent.
 * @param {'easy' | 'medium' | 'hard'} level
 * @param {() => number} rng Seeded random source.
 */
export function createAI(level, rng) {
  return {
    level,
    params: AI_LEVELS[level] || AI_LEVELS.medium,
    rng,
    timer: 0,
    target: { x: WIDTH / 2, y: DEFENCE_LINE },
    aim: null,
    orbitDir: 0,
  };
}

/** Converts a world body to the side's local frame (and back: it is an involution). */
function local(side, b) {
  return side === 1 ? { x: b.x, y: b.y, vx: b.vx, vy: b.vy }
    : { x: b.x, y: LENGTH - b.y, vx: b.vx, vy: -b.vy };
}

/** Random offset in [-size, size]. */
function noise(ai, size) {
  return (ai.rng() * 2 - 1) * size;
}

/** Distance from point p to segment a-b. */
function segmentDistance(p, a, b) {
  const abx = b.x - a.x;
  const aby = b.y - a.y;
  const len2 = abx * abx + aby * aby;
  const t = len2 > 0 ? clamp(((p.x - a.x) * abx + (p.y - a.y) * aby) / len2, 0, 1) : 0;
  return Math.hypot(a.x + abx * t - p.x, a.y + aby * t - p.y);
}

/** Picks an aim point in the opponent goal: direct or off a side wall. */
function chooseAim(ai, puck) {
  const goalX = WIDTH / 2 + noise(ai, Math.min(ai.params.error, (GOAL_RIGHT - GOAL_LEFT) / 3));
  if (ai.rng() >= ai.params.bank) return { x: goalX, y: LENGTH };
  const wallX = puck.x < WIDTH / 2 ? PUCK_RADIUS : WIDTH - PUCK_RADIUS;
  return { x: 2 * wallX - goalX, y: LENGTH };
}

/** Unit vector from a to b (straight down the table if they coincide). */
function unit(a, b) {
  const x = b.x - a.x;
  const y = b.y - a.y;
  const l = Math.hypot(x, y);
  return l > 1e-9 ? { x: x / l, y: y / l } : { x: 0, y: 1 };
}

/**
 * Target that lines the mallet up behind the puck and then strikes through
 * it. When the puck lies against the computer's own rim and the mallet cannot
 * get fully behind it, it strikes from the closest reachable spot instead.
 */
function attackTarget(ai, puck, mallet) {
  if (!ai.aim) ai.aim = chooseAim(ai, puck);
  const gap = HIT_RADIUS + 0.04;
  let d = unit(puck, ai.aim);
  const ideal = { x: puck.x - d.x * gap, y: puck.y - d.y * gap };
  const behind = clampMallet(ideal.x, ideal.y, 1);
  if (Math.hypot(behind.x - ideal.x, behind.y - ideal.y) > 0.01) d = unit(behind, puck);
  if (Math.hypot(mallet.x - behind.x, mallet.y - behind.y) < 0.04) {
    return { x: puck.x + d.x * 0.3, y: puck.y + d.y * 0.3 };
  }
  const clearance = Math.min(HIT_RADIUS + 0.01, Math.hypot(behind.x - puck.x, behind.y - puck.y) - 0.01);
  if (segmentDistance(puck, mallet, behind) < clearance) return orbitTarget(ai, puck, mallet, behind);
  ai.orbitDir = 0;
  return behind;
}

/**
 * Waypoint that circles the puck toward the strike position without touching
 * it. The direction is kept while circling and flipped when a wall blocks it.
 */
function orbitTarget(ai, puck, mallet, behind) {
  const from = Math.atan2(mallet.y - puck.y, mallet.x - puck.x);
  const to = Math.atan2(behind.y - puck.y, behind.x - puck.x);
  let diff = to - from;
  while (diff > Math.PI) diff -= 2 * Math.PI;
  while (diff < -Math.PI) diff += 2 * Math.PI;
  if (!ai.orbitDir) ai.orbitDir = Math.sign(diff) || 1;
  const radius = HIT_RADIUS + 0.05;
  for (let i = 0; i < 2; i += 1) {
    const a = from + ai.orbitDir * ORBIT_STEP;
    const wanted = { x: puck.x + Math.cos(a) * radius, y: puck.y + Math.sin(a) * radius };
    const p = clampMallet(wanted.x, wanted.y, 1);
    if (Math.hypot(p.x - wanted.x, p.y - wanted.y) < 0.01) return p;
    ai.orbitDir = -ai.orbitDir;
  }
  return behind;
}

/** Chooses a new local-frame target from what the computer sees right now. */
function decide(ai, puck, mallet) {
  const speed = Math.hypot(puck.vx, puck.vy);
  if (puck.y < HALF && speed < ai.params.attackBelow) return attackTarget(ai, puck, mallet);
  ai.aim = null;
  ai.orbitDir = 0;
  if (puck.vy < -0.05) {
    if (puck.y < DEFENCE_LINE) {
      return { x: clamp(puck.x, GOAL_LEFT, GOAL_RIGHT), y: MALLET_RADIUS };
    }
    const hit = predictCrossing(puck.x, puck.y, puck.vx, puck.vy, DEFENCE_LINE);
    return { x: hit.x + noise(ai, ai.params.error), y: DEFENCE_LINE };
  }
  return { x: WIDTH / 2 + (puck.x - WIDTH / 2) * 0.35, y: DEFENCE_LINE + 0.04 };
}

/**
 * Returns the world-space target for a computer mallet. It re-plans every
 * `reaction` seconds and holds its target in between (its reaction delay).
 * @param {ReturnType<typeof createAI>} ai
 * @param {0 | 1} side Which player the computer controls.
 * @param {{x: number, y: number, vx: number, vy: number}} puck World puck.
 * @param {{x: number, y: number, vx: number, vy: number}} mallet World mallet.
 * @param {number} dt Seconds since the previous call.
 * @returns {{x: number, y: number}}
 */
export function aiTarget(ai, side, puck, mallet, dt) {
  ai.timer -= dt;
  if (ai.timer <= 0) {
    ai.timer += ai.params.reaction;
    if (ai.timer <= 0) ai.timer = ai.params.reaction;
    ai.target = decide(ai, local(side, puck), local(side, mallet));
  }
  const t = local(side, { x: ai.target.x, y: ai.target.y, vx: 0, vy: 0 });
  return { x: t.x, y: t.y };
}
