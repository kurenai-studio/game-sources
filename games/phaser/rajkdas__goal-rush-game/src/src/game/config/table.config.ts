/**
 * GOAL RUSH — table geometry (physics-based level design, built in code).
 *
 * Every physical element of the playfield is declared here as data. The
 * PlayScene walks these lists and spawns the matching Matter.js bodies, so
 * the layout can be re-designed without touching gameplay code.
 *
 * Coordinate system: 540 × 960 portrait, origin top-left, +y down.
 *
 *  ┌──────────────────────────┐ 0
 *  │   ╭── dome arc ──╮       │   top arc guides the plunge into play
 *  │ G│O│A│L  rollover lanes  │
 *  │   ◉  ◉  ◉   [saucer]┌──┐│   pop bumpers + SPIN saucer (right)
 *  │ ┊spin┊      ◉      └──┘│   virtual spinner in the left orbit
 *  │ ═╦═╦═╦═╦═  drop targets  │
 *  │ ╲funnel╱ → inlane → bat  │   orbit exit funnel-feeds the flipper
 *  │  ▲sling        sling▲    │
 *  │ ╱ flippers ╲__╱ flippers │
 *  │      GOAL  (drain)       │
 *  └──────────────────────────┘ 960
 *
 * LEFT LOOP (the fix for the old stuck-spinner lane): the ball comes down
 * the far-left orbit, spins the (now virtual — a sensor, never a physical
 * blade the ball can rest on) spinner, then the FUNNEL wall steers it into
 * the opened inlane channel and onto the left flipper. A drain-lane became
 * a repeatable scoring loop.
 */

import { FLIPPER } from './game.config';

export interface RectDef {
  /** Center X. */
  x: number;
  /** Center Y. */
  y: number;
  width: number;
  height: number;
  /** Rotation in radians (0 = axis aligned). */
  angle?: number;
  /** Rounded corners radius (Matter chamfer). */
  chamfer?: number;
  label?: string;
}

export interface CircleDef {
  x: number;
  y: number;
  radius: number;
  label?: string;
}

export interface BumperDef extends CircleDef {
  tint: number;
}

export interface LaneDef {
  /** Letter shown (G / O / A / L). */
  letter: string;
  /** Rollover sensor center. */
  x: number;
  y: number;
}

export interface DropTargetDef extends RectDef {
  id: number;
}

export interface FlipperDef {
  /** Pivot point (world). */
  pivot: { x: number; y: number };
  /** Angle (rad) at rest, drooping toward the drain. */
  restAngle: number;
  /** Angle (rad) when held up. */
  upAngle: number;
  side: 'left' | 'right';
}

/** Outer cabinet walls + inner guides (all painted by FieldPainter). */
export const WALLS: RectDef[] = [
  // Left wall (full height of playfield).
  { x: 8, y: 610, width: 16, height: 720, chamfer: 4, label: 'wall' },
  // Right wall (outer edge of the launch lane).
  { x: 532, y: 610, width: 16, height: 720, chamfer: 4, label: 'wall' },
  // Launch lane inner wall.
  { x: 488, y: 632, width: 12, height: 590, chamfer: 6, label: 'wall-lane' },
  // Launch lane floor (the ball rests here between plunges).
  { x: 509, y: 940, width: 44, height: 16, label: 'plunger-floor' },
  // Left orbit guide — the far-left lane the ball descends after the dome
  // (shortened: its bottom clears the funnel below by ~60 px so a ball
  // riding the funnel passes underneath into the inlane channel).
  { x: 70, y: 535, width: 10, height: 130, chamfer: 5, label: 'wall' },
  // ORBIT FUNNEL — seals the bottom of the left orbit from the outer wall
  // to the inlane mouth. A ball coming down the orbit rides its top surface
  // into the inlane channel and onto the left flipper: the old drain-lane is
  // now a repeatable scoring loop (probe: scripts/probe-loop.ts). The tip
  // stops LEFT of the sling post so the drop window into the channel is
  // wider than the ball — no resting cup at the seam.
  { x: 64.5, y: 672, width: 104, height: 10, chamfer: 5, angle: 0.552, label: 'wall' },
  // Left inlane divider: the channel between it and the left sling is the
  // inlane (39 px wide — comfortably wider than the 26 px ball).
  { x: 100, y: 756, width: 10, height: 100, chamfer: 5, label: 'wall' },
  // Left angled feed: catches inlane + playfield balls and rolls them onto
  // the left flipper's batting face (high-left → low-right slope).
  { x: 148, y: 843, width: 112, height: 10, chamfer: 5, angle: 0.303, label: 'wall' },
  // Right inlane divider (channel between it and the launch-lane wall).
  { x: 440, y: 710, width: 10, height: 124, chamfer: 5, label: 'wall' },
  // Right angled feed: high-right → low-LEFT slope, so channel + playfield
  // balls roll OFF at x≈338 straight onto the right flipper's bat.
  { x: 408, y: 842.5, width: 143, height: 10, chamfer: 5, angle: -0.218, label: 'wall' },
  // Small deflector under the right inlane, steering saucer ejects inward.
  { x: 470, y: 560, width: 12, height: 90, chamfer: 6, angle: 0.18, label: 'wall' },
];

/** Dome: top arc built from tangent wall segments (half ellipse). */
export const DOME = {
  cx: 270,
  cy: 258,
  rx: 255,
  ry: 240,
  segments: 22,
  thickness: 14,
} as const;

/** Rounded posts (wall caps, lane guards). */
export const POSTS: CircleDef[] = [
  { x: 100, y: 702, radius: 8, label: 'post' }, // left divider cap
  { x: 440, y: 646, radius: 8, label: 'post' }, // right divider cap
  { x: 70, y: 468, radius: 8, label: 'post' }, // orbit guide top cap
  { x: 146, y: 694, radius: 8, label: 'post' }, // left sling top corner
  { x: 436, y: 700, radius: 8, label: 'post' }, // right sling top corner
];

/** GOAL rollover lanes (spell G-O-A-L → multiplier up). */
export const LANES: LaneDef[] = [
  { letter: 'G', x: 84, y: 152 },
  { letter: 'O', x: 146, y: 152 },
  { letter: 'A', x: 210, y: 152 },
  { letter: 'L', x: 276, y: 152 },
];

/** Vertical wire-guide dividers between the rollover lanes. */
export const LANE_DIVIDERS: RectDef[] = [
  { x: 55, y: 158, width: 8, height: 86, chamfer: 4, label: 'wall' },
  { x: 113, y: 155, width: 8, height: 86, chamfer: 4, label: 'wall' },
  { x: 178, y: 152, width: 8, height: 86, chamfer: 4, label: 'wall' },
  { x: 243, y: 149, width: 8, height: 86, chamfer: 4, label: 'wall' },
  { x: 308, y: 146, width: 8, height: 86, chamfer: 4, label: 'wall' },
];

/** Pop bumpers (soccer-ball styled kickers). */
export const BUMPERS: BumperDef[] = [
  { x: 230, y: 330, radius: 28, tint: 0xff4d9d, label: 'bumper' },
  { x: 160, y: 420, radius: 28, tint: 0x35f08b, label: 'bumper' },
  { x: 300, y: 420, radius: 28, tint: 0xffc93c, label: 'bumper' },
];

/** Slingshots (triangles above the flippers). Vertices are clockwise. */
export interface SlingDef {
  side: 'left' | 'right';
  /** Triangle vertices [top, outer-bottom, inner-bottom]. */
  points: { x: number; y: number }[];
  /** Kick direction (normalized) applied on the active face. */
  kickDir: { x: number; y: number };
  label: string;
}

export const SLINGSHOTS: SlingDef[] = [
  {
    side: 'left',
    // Shifted right vs the original table: the gap between it and the
    // inlane divider (x 105..144) is the left inlane channel, wide enough
    // that the funnel tip + sling post can never cup a resting ball.
    points: [
      { x: 144, y: 704 },
      { x: 144, y: 788 },
      { x: 200, y: 780 },
    ],
    kickDir: { x: 0.72, y: -0.7 },
    label: 'sling-left',
  },
  {
    side: 'right',
    points: [
      { x: 434, y: 712 },
      { x: 434, y: 790 },
      { x: 372, y: 782 },
    ],
    kickDir: { x: -0.72, y: -0.7 },
    label: 'sling-right',
  },
];

/** Drop-target bank — complete it to trigger a GOLDEN SPIN. All four
 *  plates sit on ONE straight line (no vertical stagger): a staggered bank
 *  has step-up seams that can park a rolling ball against them. The shared
 *  9° tilt rolls a landed ball down the line — it rides the bank, drops
 *  every plate and clears the whole thing in one shot. */
export const DROP_TARGETS: DropTargetDef[] = [
  { id: 0, x: 116, y: 554, width: 46, height: 13, angle: 0.16, label: 'drop' },
  { id: 1, x: 166, y: 554, width: 46, height: 13, angle: 0.16, label: 'drop' },
  { id: 2, x: 216, y: 554, width: 46, height: 13, angle: 0.16, label: 'drop' },
  { id: 3, x: 266, y: 554, width: 46, height: 13, angle: 0.16, label: 'drop' },
];

/** Virtual spinner — a SENSOR in the left orbit, never a physical blade.
 *  The old pinned blade let the ball come to rest on it ("stopping the ball
 *  very very long"); the sensor version is pure detection: the ball always
 *  rolls straight through, the blade graphic is animated procedurally. */
export const SPINNER = {
  x: 40,
  y: 430,
  /** Detection window across the lane. */
  sensor: { width: 46, height: 34 },
  /** Per-pass re-trigger lockout (ms). */
  cooldownMs: 350,
} as const;

/** SPIN saucer (sensor hole that captures the ball and spins the reels). */
export const SAUCER = {
  x: 445,
  y: 388,
  radius: 24,
  /** Eject impulse when the slot sequence finishes. */
  eject: { x: -6.5, y: -10.5 },
  /** Lockout so an ejected ball is not instantly re-captured. */
  recaptureMs: 1200,
} as const;

/** Flippers. */
export const FLIPPERS: FlipperDef[] = [
  {
    side: 'left',
    pivot: { x: 178, y: 862 },
    restAngle: 0.52,
    upAngle: -0.55,
  },
  {
    side: 'right',
    pivot: { x: 362, y: 862 },
    // The right flipper's sprite is mirrored, so it points LEFT at angle 0:
    // tip direction = 180° + angle. Rest ≈ pointing down-left, up ≈ up-left.
    restAngle: -0.52,
    upAngle: 0.55,
  },
];

/** Drain sensor (the "goal mouth" — losing the ball concedes). Covers the
 *  playfield width ONLY: a ball bouncing on the plunger floor in the launch
 *  lane must never touch it. */
export const DRAIN = {
  x: 248.5,
  y: 952,
  width: 467,
  height: 30,
} as const;

/** Ball spawn point inside the launch lane. */
export const BALL_SPAWN = { x: 509, y: 898 } as const;

/** HUD bar geometry (bottom strip, drawn over the drain zone).
 * Control-panel layout: [◀ FLIP] CREDITS · JACKPOT · MULT · BALLS [FLIP ▶]
 * — the arrow buttons sit in the strip's ends (rendered by TouchControls),
 * the four stat columns share the middle. */
export const HUD_BAR = {
  x: 90,
  y: 900,
  width: 320,
  height: 56,
  /** Column centers (absolute x), matching Hud.ts. */
  col: { credits: 152, jackpot: 248, mult: 322, balls: 378 },
} as const;

/** On-screen flipper buttons (bottom corners, over the HUD strip ends). */
export const FLIP_BUTTONS = {
  left: { x: 52, y: 928 },
  right: { x: 448, y: 928 },
  width: 64,
  height: 48,
} as const;

/** Flipper body helper: offset from body center to the pivot end. */
export function flipperPivotOffset(side: 'left' | 'right'): { x: number; y: number } {
  // Texture points right with the pivot cap at its left end.
  const inset = FLIPPER.thickness * 0.55;
  return side === 'left'
    ? { x: -FLIPPER.length / 2 + inset, y: 0 }
    : { x: FLIPPER.length / 2 - inset, y: 0 };
}
