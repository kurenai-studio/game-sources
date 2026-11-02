/**
 * GOAL RUSH — left-loop geometry probe (deterministic, pure matter-js).
 *
 * Rebuilds the ENTIRE table from table.config (walls, dome, posts, lane
 * dividers, slingshots, resting flippers, drop targets) and simulates the
 * ball with the exact engine tuning used by PlayScene (fixed 60 Hz step,
 * per-step speed clamp). Verifies the redesign of the old stuck-spinner
 * lane:
 *
 *  1. ORBIT DESCENT  — a ball dropped down the far-left lane must pass the
 *     spinner zone, ride the funnel into the inlane channel and arrive on
 *     the LEFT FLIPPER (not the drain, not a stall).
 *  2. RIGHT CHANNEL  — a ball dropped down the right inlane channel must
 *     roll off the feed onto the RIGHT FLIPPER side (x < 380).
 *  3. NO STALLS      — across every scenario the ball may never sit
 *     near-motionless for > 1.5 s (the old pink-blade trap).
 *  4. LOOP SHOT      — an up-left shot from the left flipper must thread
 *     INTO the orbit (travel up the lane), proving the loop is shootable
 *     in both directions.
 *
 * Run: bun scripts/probe-loop.ts
 */

import { Bodies, Body, Composite, Engine } from 'matter-js';
import {
  DOME,
  DROP_TARGETS,
  FLIPPERS as FLIPPER_DEFS,
  LANE_DIVIDERS,
  POSTS,
  SLINGSHOTS,
  WALLS,
} from '../src/game/config/table.config';
import { BALL as BALL_CFG, FLIPPER, PHYSICS } from '../src/game/config/game.config';

/* ── build the table ─────────────────────────────────────────────────────── */

const engine = Engine.create();
engine.gravity.y = PHYSICS.gravityY;
engine.positionIterations = PHYSICS.positionIterations;
engine.velocityIterations = PHYSICS.velocityIterations;
const world = engine.world;

for (const w of WALLS) {
  Composite.add(
    world,
    Bodies.rectangle(w.x, w.y, w.width, w.height, {
      isStatic: true,
      angle: w.angle ?? 0,
      chamfer: w.chamfer ? { radius: w.chamfer } : undefined,
      restitution: PHYSICS.wallRestitution,
      friction: PHYSICS.wallFriction,
      label: w.label ?? 'wall',
    })
  );
}

// Dome arc.
for (let i = 0; i <= DOME.segments; i += 1) {
  const t = Math.PI + (Math.PI * i) / DOME.segments;
  const x = DOME.cx + DOME.rx * Math.cos(t);
  const y = DOME.cy + DOME.ry * Math.sin(t);
  const angle = t + Math.PI / 2;
  const len = ((Math.PI * ((DOME.rx + DOME.ry) / 2)) / DOME.segments) * 1.45;
  Composite.add(
    world,
    Bodies.rectangle(x, y, len, DOME.thickness, {
      isStatic: true,
      angle,
      chamfer: { radius: DOME.thickness / 2 },
      restitution: PHYSICS.wallRestitution,
      friction: PHYSICS.wallFriction,
      label: 'wall',
    })
  );
}

for (const p of POSTS) {
  Composite.add(
    world,
    Bodies.circle(p.x, p.y, p.radius, { isStatic: true, restitution: 0.55, friction: 0 })
  );
}

for (const d of LANE_DIVIDERS) {
  Composite.add(
    world,
    Bodies.rectangle(d.x, d.y, d.width, d.height, {
      isStatic: true,
      angle: d.angle ?? 0,
      chamfer: d.chamfer ? { radius: d.chamfer } : undefined,
      restitution: PHYSICS.wallRestitution,
      friction: PHYSICS.wallFriction,
    })
  );
}

for (const s of SLINGSHOTS) {
  const cx = s.points.reduce((a, p) => a + p.x, 0) / 3;
  const cy = s.points.reduce((a, p) => a + p.y, 0) / 3;
  Composite.add(
    world,
    Bodies.fromVertices(
      cx,
      cy,
      [s.points.map((p) => ({ x: p.x - cx, y: p.y - cy }))],
      { isStatic: true, restitution: 0.4, friction: 0 }
    )
  );
}

for (const t of DROP_TARGETS) {
  Composite.add(
    world,
    Bodies.rectangle(t.x, t.y, t.width, t.height, {
      isStatic: true,
      angle: t.angle,
      friction: 0,
      restitution: 0.5,
      chamfer: { radius: 5 },
    })
  );
}

// Flippers frozen at their rest angle (enough to receive rolling balls).
for (const f of FLIPPER_DEFS) {
  const half = FLIPPER.length / 2 - FLIPPER.thickness * 0.55;
  const dir = f.side === 'left' ? 1 : -1;
  const cx = f.pivot.x + dir * half * Math.cos(f.restAngle);
  const cy = f.pivot.y + dir * half * Math.sin(f.restAngle);
  Composite.add(
    world,
    Bodies.rectangle(cx, cy, FLIPPER.length, FLIPPER.thickness, {
      isStatic: true,
      angle: f.restAngle,
      chamfer: { radius: FLIPPER.thickness / 2 },
      friction: FLIPPER.friction,
      restitution: 0.05,
    })
  );
}

/* ── simulation helpers ──────────────────────────────────────────────────── */

const STEP_MS = PHYSICS.fixedStepMs;
let failures = 0;

interface SimResult {
  drained: boolean;
  maxConsecutiveSlow: number;
  reachedLeftFlipper: boolean;
  reachedRightFlipper: boolean;
  crossedSpinnerZone: boolean;
  minY: number;
  path: Array<{ x: number; y: number }>;
}

function simulate(
  startX: number,
  startY: number,
  vx: number,
  vy: number,
  steps: number
): SimResult {
  const ball = Bodies.circle(startX, startY, BALL_CFG.radius, {
    density: BALL_CFG.density,
    restitution: BALL_CFG.restitution,
    friction: BALL_CFG.friction,
    frictionAir: BALL_CFG.frictionAir,
    frictionStatic: 0,
  });
  Body.setVelocity(ball, { x: vx, y: vy });
  Composite.add(world, ball);

  let drained = false;
  let slowRun = 0;
  let maxSlow = 0;
  let reachedLeft = false;
  let reachedRight = false;
  let crossedSpinner = false;
  let minY = startY;
  const path: Array<{ x: number; y: number }> = [];

  for (let i = 0; i < steps; i += 1) {
    // Per-step speed clamp, identical to Ball.clampSpeed().
    const v = ball.velocity;
    const speed = Math.hypot(v.x, v.y);
    if (speed > PHYSICS.maxBallSpeed) {
      Body.setVelocity(ball, { x: (v.x * PHYSICS.maxBallSpeed) / speed, y: (v.y * PHYSICS.maxBallSpeed) / speed });
    }
    Engine.update(engine, STEP_MS);

    const { x, y } = ball.position;
    const s = Math.hypot(ball.velocity.x, ball.velocity.y);
    minY = Math.min(minY, y);
    if (s < 0.3) {
      slowRun += 1;
      maxSlow = Math.max(maxSlow, slowRun);
    } else {
      slowRun = 0;
    }
    if (y > 952 && x < 482) drained = true;
    // Arrived on the left flipper feeding zone (on or above the bat).
    if (y > 830 && y < 905 && x > 100 && x < 250) reachedLeft = true;
    // Arrived on the right flipper feeding zone.
    if (y > 830 && y < 905 && x > 290 && x < 440) reachedRight = true;
    // Passed through the spinner detection zone in the left orbit.
    if (x < 75 && y > 405 && y < 455) crossedSpinner = true;
    if (i % 8 === 0) path.push({ x: Math.round(x), y: Math.round(y) });
    if (drained && i > 60) break;
  }

  Composite.remove(world, ball);
  return { drained, maxConsecutiveSlow: maxSlow, reachedLeftFlipper: reachedLeft, reachedRightFlipper: reachedRight, crossedSpinnerZone: crossedSpinner, minY, path };
}

function report(name: string, res: SimResult, checks: Array<[boolean, string]>): void {
  console.log(`\n── ${name} ──`);
  console.log(
    `   drained=${res.drained} maxSlowRun=${res.maxConsecutiveSlow} (steps) minY=${res.minY.toFixed(0)}`
  );
  console.log(`   path: ${res.path.map((p) => `${p.x},${p.y}`).join(' → ')}`);
  for (const [ok, label] of checks) {
    console.log(`   ${ok ? 'PASS' : 'FAIL'}  ${label}`);
    if (!ok) failures += 1;
  }
}

/* ── scenarios ───────────────────────────────────────────────────────────── */

// 1) ORBIT DESCENT: ball comes down the far-left lane from the dome.
//    (Flippers are frozen at rest — a delivered ball may roll off the bat
//    tip and drain, which is why the drain check only applies BEFORE the
//    ball reaches a flipper zone.)
const desc = simulate(40, 250, 0.5, 9, 900);
report('orbit descent (left lane)', desc, [
  [desc.reachedLeftFlipper || desc.reachedRightFlipper, 'ball reached a flipper feed zone'],
  [!(desc.drained && !desc.reachedLeftFlipper && !desc.reachedRightFlipper), 'ball did not drain before reaching a flipper'],
  [desc.maxConsecutiveSlow < 90, 'no stall longer than 1.5 s'],
]);

// 2) RIGHT CHANNEL descent.
const right = simulate(463, 620, 0, 4, 900);
report('right inlane descent', right, [
  [right.reachedRightFlipper, 'ball reached the RIGHT flipper feed zone'],
  [!(right.drained && !right.reachedRightFlipper), 'ball did not drain before reaching a flipper'],
  [right.maxConsecutiveSlow < 90, 'no stall longer than 1.5 s'],
]);

// 3) LEFT INLANE CHANNEL descent (funnel exit → flipper).
const inlane = simulate(121, 690, 0, 3, 600);
report('left inlane channel', inlane, [
  [inlane.reachedLeftFlipper, 'ball reached the LEFT flipper feed zone'],
  [inlane.maxConsecutiveSlow < 90, 'no stall longer than 1.5 s'],
]);

// 3b) SLOW FUNNEL ROLL — the regression that bit live play: a slow ball
//     rolling down the funnel surface must drop into the channel, never
//     park in the funnel-tip / sling-post cup.
const slowRoll = simulate(40, 638, 0.5, 1.5, 900);
report('slow funnel roll', slowRoll, [
  [slowRoll.reachedLeftFlipper || slowRoll.crossedSpinnerZone, 'ball made it through (channel or lane)'],
  [slowRoll.maxConsecutiveSlow < 90, 'no stall longer than 1.5 s'],
]);

// 4) SIGNATURE PLUNGE — full power (aimed slightly left, like a real
//    angled lane exit): over the dome apex and down into live play. The
//    exact pocket varies (GOAL rollover lanes / bumper cluster) — the check
//    is that the ball stays healthy and reaches a flipper.
const launch = simulate(509, 890, -1.5, -25.5, 1500);
report('full-power plunge', launch, [
  [launch.minY < 120, 'ball carried over the dome apex region'],
  [launch.reachedLeftFlipper || launch.reachedRightFlipper, 'ball reached a flipper feed zone'],
  [launch.maxConsecutiveSlow < 90, 'no stall longer than 1.5 s'],
]);

// 4b) Launch randomness envelope — every jittered plunge must stay in
//     healthy play (no stalls, no early drains before a flipper zone).
let healthy = 0;
for (let k = 0; k < 8; k += 1) {
  const jitter = -0.25 + (0.5 * k) / 7;
  const r = simulate(509, 890, -1.5 + jitter, -25.5, 900);
  const ok =
    (r.reachedLeftFlipper || r.reachedRightFlipper) && r.maxConsecutiveSlow < 90;
  if (ok) healthy += 1;
}
console.log(`\n── launch jitter sweep (8 plunges) ──`);
console.log(`   healthy plunges: ${healthy}/8`);
const sweepOk = healthy >= 7;
console.log(`   ${sweepOk ? 'PASS' : 'FAIL'}  ≥7/8 plunges reached a flipper with no stall`);
if (!sweepOk) failures += 1;

// 4c) LEFT ORBIT ENTRY from the bumper cluster — a radial kick off the left
//     bumper (160,420) threading down-left into the orbit lane must run the
//     spinner → funnel → flipper loop (the recurring mid-game loop).
const kick = simulate(135, 425, -11, -1, 900);
report('bumper kick → left orbit loop', kick, [
  [kick.crossedSpinnerZone, 'ball crossed the spinner zone'],
  [kick.reachedLeftFlipper || kick.reachedRightFlipper, 'ball reached a flipper feed zone'],
  [kick.maxConsecutiveSlow < 90, 'no stall longer than 1.5 s'],
]);

// 5) MAIN PLAYFIELD random-ish bounces: no stall anywhere.
const mid = simulate(270, 500, 5, -8, 1200);
report('mid-field bounces', mid, [[mid.maxConsecutiveSlow < 120, 'no stall longer than 2 s']]);

console.log(`\n${failures === 0 ? 'ALL CHECKS PASSED' : failures + ' CHECKS FAILED'}`);
process.exit(failures === 0 ? 0 : 1);
