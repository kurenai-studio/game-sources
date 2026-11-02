/**
 * GOAL RUSH — global game configuration.
 *
 * All tuning constants live here so the table can be re-balanced without
 * touching scene code. Speeds are expressed in Matter.js "per-tick" units
 * (px or rad per 60 Hz physics step ≈ value * 60 per second) because that is
 * what the engine consumes directly — see docs/ARCHITECTURE.md.
 */

/** Logical playfield resolution (portrait, 9:16). The canvas scales to fit. */
export const TABLE = {
  width: 540,
  height: 960,
} as const;

/** Physics engine tuning. */
export const PHYSICS = {
  /** Fixed physics timestep (ms) — physics runs at true 60 Hz regardless of
   *  the display refresh rate (see PlayScene fixed-step accumulator). */
  fixedStepMs: 1000 / 60,
  /** Max sub-steps per frame + accumulator clamp — prevents the spiral of
   *  death after tab switches while keeping headless/CI runs real-time. */
  maxSubSteps: 45,
  accumulatorClampMs: 750,
  /** Gravity along the table slope (scaled down from earth — pinball feel). */
  gravityY: 0.95,
  positionIterations: 12,
  velocityIterations: 8,
  /** Hard cap on ball speed (px/tick) — prevents tunneling through walls
   *  (tunnel threshold ≈ ball Ø 26 + wall 12 px). */
  maxBallSpeed: 26,
  /** Default surface response for static geometry (waxed playfield — walls
   *  are frictionless so the ball keeps its energy). */
  wallRestitution: 0.42,
  wallFriction: 0,
} as const;

/** Ball body. */
export const BALL = {
  radius: 13,
  density: 0.0028,
  restitution: 0.42,
  friction: 0.028,
  /** Per-step air drag (compounds!): 0.0035 ≈ -0.2/s velocity decay —
   *  lively but settles, like a real steel ball on a waxed table. */
  frictionAir: 0.0035,
  frictionStatic: 0,
  /** Ball-save window (ms) after each launch. Short by design: a drain
   *  through the flipper gap must COST a ball once the ball is genuinely in
   *  play — the save only forgives the unlucky first bounces right after
   *  kick-off (a 9 s window used to swallow most real drains and the ball
   *  counter never went down). One save per ball life, max. */
  saveWindowMs: 3000,
} as const;

/** Matter collision categories. The flippers are kinematically driven, so
 *  they must NEVER be pushed by static geometry (the solver used to wedge
 *  the bat off its pivot where the feed rails pass near it): they collide
 *  with the ball and nothing else. */
export const COLLISION = {
  /** Default category of every wall / post / bumper / sling (Matter default). */
  world: 0x0001,
  /** The ball — its own category so flippers can target it alone. */
  ball: 0x0002,
  /** Flipper bats. */
  flipper: 0x0004,
} as const;

/** Flipper mechanics (kinematic drive — see Flipper.ts).
 *
 *  Two independent knobs (rad per 60 Hz step):
 *  - `upRate`/`downRate` — how fast the bat is PLACED each physics step.
 *    The up-swing spans ~5 steps (~84 ms) like a real flipper: smooth to the
 *    eye, and the per-step face sweep (0.24 · 63 px tip radius ≈ 15 px) stays
 *    below the ball Ø (26 px), so the bat can never jump OVER the ball — the
 *    old 0.72/step swing covered 45 px/step and regularly skipped contact
 *    entirely ("flipper sometimes fails").
 *  - `solverUp`/`solverDown` — the velocity the collision resolver is allowed
 *    to see (painted via positionPrev). Tuned on a Matter harness so a clean
 *    face hit launches the ball at 12 (pivot side, control) to 26 px/step
 *    (tip, full power) — the same band the old table delivered on its GOOD
 *    hits, but now on every hit.
 */
export const FLIPPER = {
  length: 82,
  thickness: 17,
  density: 0.09,
  friction: 0.16,
  /** Placement rates (rad per step). */
  upRate: 0.24,
  downRate: 0.3,
  /** Resolver-visible angular velocity (rad per step). */
  solverUp: 0.28,
  solverDown: 0.3,
} as const;

/** Plunger (spring launcher). Tuned so a FULL-POWER plunge carries the
 *  ball over the dome apex and down the left orbit — the satisfying opening
 *  loop through the spinner. Weaker plunges drop into the G-O-A-L lanes. */
export const PLUNGER = {
  minSpeed: 13,
  maxSpeed: 25.5,
  chargeMs: 950,
} as const;

/** Pop bumper kick. */
export const BUMPER = {
  kick: 12.5,
  cooldownMs: 90,
} as const;

/** Slingshot kick. */
export const SLINGSHOT = {
  kick: 11,
  cooldownMs: 110,
} as const;

/** Scoring / economy. All awards are credits; table awards are multiplied
 *  by the current G-O-A-L multiplier (slot wins apply it inside the reels). */
export const SCORING = {
  bumper: 100,
  slingshot: 75,
  spinnerPass: 60,
  dropTarget: 150,
  laneLetter: 50,
  goalLanesComplete: 400,
  saucer: 250,
  bankComplete: 500,
  /** Hit all three pop bumpers inside the window → HAT-TRICK bonus. */
  hatTrickBonus: 1000,
  hatTrickWindowMs: 3500,
  /** Spinner passes (per ball) needed to earn a free base spin. */
  freeSpinPasses: 5,
  /** Credit milestones that award an extra ball. */
  extraBallThresholds: [2500, 6000, 12000],
  maxBalls: 6,
  maxMultiplier: 5,
  /** Combo: bumper/sling hits chained inside this window escalate bonus. */
  comboWindowMs: 1600,
  comboBonus: 10,
  ballsPerGame: 3,
  startCredits: 0,
} as const;

/** Progressive jackpot pot. */
export const JACKPOT = {
  seed: 500,
  /** Contributions added to the pot by table events. */
  contributions: {
    bumper: 2,
    slingshot: 1,
    spinnerPass: 2,
    dropTarget: 3,
    laneLetter: 1,
    goalLanesComplete: 10,
    saucer: 5,
  },
  /** localStorage keys (pot + best score persist across sessions). */
  potKey: 'goalrush.pot',
  bestKey: 'goalrush.best',
} as const;

/** Neon-arcade palette (shared look & feel across table, HUD, FX). */
export const PALETTE = {
  bgDeep: 0x070b14,
  bgPanel: 0x0d1526,
  pitch: 0x0a3520,
  pitchMow: 0x0c3d26,
  lineGreen: 0x35f08b,
  gold: 0xffc93c,
  goldSoft: 0xffe9a8,
  magenta: 0xff4d9d,
  red: 0xff3355,
  white: 0xf4f8ff,
  dim: 0x8fa3c8,
  steel: 0x27324b,
  violet: 0xb46bff,
} as const;

/** CSS variants of the palette for Phaser.Text styles. */
export const PALETTE_CSS = {
  bgDeep: '#070b14',
  lineGreen: '#35f08b',
  gold: '#ffc93c',
  goldSoft: '#ffe9a8',
  /** Brighter gold for money figures that must read at a glance. */
  jackpot: '#ffd76a',
  magenta: '#ff4d9d',
  red: '#ff3355',
  white: '#f4f8ff',
  dim: '#8fa3c8',
  steel: '#27324b',
  violet: '#b46bff',
  /** Unlit G-O-A-L rollover inserts — pale ice-blue, clearly readable. */
  laneIdle: '#b8c8ea',
} as const;
