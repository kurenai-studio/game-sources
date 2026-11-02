/**
 * GOAL RUSH — physics probe (raw Matter, no Phaser).
 * Rebuilds the exact table bodies from table.config and drops a ball into
 * the flipper zone. If the ball parks on the feed wall here, the bug is in
 * the geometry; if it drains, the bug is in Phaser integration.
 *
 * Run: bun scripts/physics-probe.ts
 */

import { Bodies, Composite, Engine, World, Body, Constraint } from 'matter-js';
import {
  DOME,
  FLIPPERS as FLIPPER_DEFS,
  LANE_DIVIDERS,
  POSTS,
  SLINGSHOTS,
  WALLS,
  BALL_SPAWN,
  DRAIN,
  BUMPERS,
} from '../src/game/config/table.config';
import { BALL as BALL_CFG, PHYSICS, FLIPPER } from '../src/game/config/game.config';

const engine = Engine.create();
engine.gravity.y = PHYSICS.gravityY;
engine.positionIterations = PHYSICS.positionIterations;
engine.velocityIterations = PHYSICS.velocityIterations;
const world = engine.world;

const staticOpts = {
  isStatic: true,
  restitution: PHYSICS.wallRestitution,
  friction: PHYSICS.wallFriction,
};

for (const w of WALLS) {
  Composite.add(
    world,
    Bodies.rectangle(w.x, w.y, w.width, w.height, {
      ...staticOpts,
      angle: w.angle ?? 0,
      chamfer: w.chamfer ? { radius: w.chamfer } : undefined,
    })
  );
}

for (let i = 0; i <= DOME.segments; i += 1) {
  const t = Math.PI + (Math.PI * i) / DOME.segments;
  const x = DOME.cx + DOME.rx * Math.cos(t);
  const y = DOME.cy + DOME.ry * Math.sin(t);
  const len = ((Math.PI * ((DOME.rx + DOME.ry) / 2)) / DOME.segments) * 1.45;
  Composite.add(
    world,
    Bodies.rectangle(x, y, len, DOME.thickness, {
      ...staticOpts,
      angle: t + Math.PI / 2,
      chamfer: { radius: DOME.thickness / 2 },
    })
  );
}

for (const p of POSTS) {
  Composite.add(world, Bodies.circle(p.x, p.y, p.radius, { ...staticOpts, restitution: 0.55 }));
}

for (const d of LANE_DIVIDERS) {
  Composite.add(
    world,
    Bodies.rectangle(d.x, d.y, d.width, d.height, {
      ...staticOpts,
      angle: d.angle ?? 0,
      chamfer: d.chamfer ? { radius: d.chamfer } : undefined,
    })
  );
}

for (const b of BUMPERS) {
  Composite.add(world, Bodies.circle(b.x, b.y, b.radius, { ...staticOpts, restitution: 0.6 }));
}

for (const s of SLINGSHOTS) {
  const cx = s.points.reduce((a, p) => a + p.x, 0) / 3;
  const cy = s.points.reduce((a, p) => a + p.y, 0) / 3;
  const verts = s.points.map((p) => ({ x: p.x - cx, y: p.y - cy }));
  Composite.add(world, Bodies.fromVertices(cx, cy, verts, { ...staticOpts }));
}

// Flippers with pin constraints (no controller — bats stay at rest angle).
const flipperBodies: Body[] = [];
for (const f of FLIPPER_DEFS) {
  const half = FLIPPER.length / 2 - FLIPPER.thickness * 0.55;
  const dir = f.side === 'left' ? 1 : -1;
  const cx = f.pivot.x + dir * half * Math.cos(f.restAngle);
  const cy = f.pivot.y + dir * half * Math.sin(f.restAngle);
  const body = Bodies.rectangle(cx, cy, FLIPPER.length, FLIPPER.thickness, {
    density: FLIPPER.density,
    friction: FLIPPER.friction,
    frictionAir: 0.02,
    restitution: 0.05,
    chamfer: { radius: FLIPPER.thickness / 2 },
    angle: f.restAngle,
  });
  const pivotOffset = { x: dir * -half, y: 0 };
  Composite.add(
    world,
    Constraint.create({
      pointA: { x: f.pivot.x, y: f.pivot.y },
      bodyB: body,
      pointB: pivotOffset,
      stiffness: 1,
      length: 0,
    })
  );
  Composite.add(world, body);
  flipperBodies.push(body);
}

// The ball — dropped into the flipper zone like a real inlane delivery.
const ball = Bodies.circle(150, 790, BALL_CFG.radius, {
  density: BALL_CFG.density,
  restitution: BALL_CFG.restitution,
  friction: BALL_CFG.friction,
  frictionAir: BALL_CFG.frictionAir,
  frictionStatic: 0,
});
Composite.add(world, ball);

let drained = false;
let steps = 0;
for (let i = 0; i < 60 * 12; i += 1) {
  // Simulate the flipper dead-zone controller (holds rest angle).
  for (const body of flipperBodies) {
    const target = 0; // rest handled by initial angle; keep velocity zeroed
    if (Math.abs(target - body.angle) < 0.012) Body.setAngularVelocity(body, 0);
  }
  Engine.update(engine, 1000 / 60);
  steps += 1;
  if (i % 60 === 0) {
    const v = ball.velocity;
    const sp = Math.hypot(v.x, v.y);
    console.log(
      `t=${(i / 60).toFixed(0)}s pos=(${ball.position.x.toFixed(1)}, ${ball.position.y.toFixed(1)}) speed=${sp.toFixed(2)}`
    );
    if (sp < 0.45 && ball.position.y > 700 && ball.position.y < 900) {
      console.log('  ^^ PARKED in flipper zone!');
    }
  }
  if (ball.position.y > DRAIN.y && !drained) {
    drained = true;
    console.log(`DRAINED at t=${(steps / 60).toFixed(2)}s, x=${ball.position.x.toFixed(0)}`);
    break;
  }
}
if (!drained) console.log('never drained in 12 s');
