import { Bodies, Composite, Engine, Body, Constraint } from 'matter-js';
import { FLIPPERS as FLIPPER_DEFS } from '../src/game/config/table.config';
import { BALL as BALL_CFG, PHYSICS, FLIPPER } from '../src/game/config/game.config';

const engine = Engine.create();
engine.gravity.y = PHYSICS.gravityY;
engine.positionIterations = PHYSICS.positionIterations;
engine.velocityIterations = PHYSICS.velocityIterations;
const world = engine.world;

Composite.add(world, Bodies.rectangle(150.5, 842.5, 104, 10, {
  isStatic: true, angle: 0.303, friction: 0, restitution: 0.42, chamfer: { radius: 5 },
}));

const bats: Body[] = [];
const meta: Array<{ rest: number; up: number; pressed: boolean }> = [];
for (const f of FLIPPER_DEFS) {
  const half = FLIPPER.length / 2 - FLIPPER.thickness * 0.55;
  const dir = f.side === 'left' ? 1 : -1;
  const cx = f.pivot.x + dir * half * Math.cos(f.restAngle);
  const cy = f.pivot.y + dir * half * Math.sin(f.restAngle);
  const bat = Bodies.rectangle(cx, cy, FLIPPER.length, FLIPPER.thickness, {
    density: FLIPPER.density, friction: FLIPPER.friction, frictionAir: 0.02,
    restitution: 0.05, chamfer: { radius: FLIPPER.thickness / 2 }, angle: f.restAngle,
  });
  Composite.add(world, Constraint.create({
    pointA: { x: f.pivot.x, y: f.pivot.y }, bodyB: bat,
    pointB: { x: dir * -half, y: 0 }, stiffness: 1, length: 0,
  }));
  Composite.add(world, bat);
  bats.push(bat);
  meta.push({ rest: f.restAngle, up: f.upAngle, pressed: false });
  console.log(`bat inertia=${bat.inertia.toFixed(0)} mass=${bat.mass.toFixed(1)}`);
}

const ball = Bodies.circle(150, 790, BALL_CFG.radius, {
  density: BALL_CFG.density, restitution: BALL_CFG.restitution, friction: BALL_CFG.friction,
  frictionAir: BALL_CFG.frictionAir, frictionStatic: 0,
});
Composite.add(world, ball);

// PD torque gains
const KP = 3000;
const KD = 220;
const MAX_TORQUE = 250000;

let flipStart = -1;
let flipDone = -1;
for (let i = 0; i < 60 * 5; i += 1) {
  if (i === 60 * 2) {
    meta[0].pressed = true; // press left flipper at t=2s
    flipStart = i;
  }
  if (i === 60 * 2 + 30) meta[0].pressed = false;

  for (let b = 0; b < bats.length; b += 1) {
    const bat = bats[b];
    const target = meta[b].pressed ? meta[b].up : meta[b].rest;
    const err = target - bat.angle;
    let torque = err * KP - bat.angularVelocity * KD;
    torque = Math.max(-MAX_TORQUE, Math.min(MAX_TORQUE, torque));
    bat.torque = torque;
    if (flipStart > 0 && flipDone < 0 && Math.abs(bats[0].angle - meta[0].up) < 0.05) {
      flipDone = i;
      console.log(`flip reached up-angle in ${((i - flipStart) / 60 * 1000).toFixed(0)} ms`);
    }
  }
  Engine.update(engine, 1000 / 60);
  if (i % 60 === 0) {
    const sp = Math.hypot(ball.velocity.x, ball.velocity.y);
    console.log(`t=${(i / 60).toFixed(0)}s ball=(${ball.position.x.toFixed(1)}, ${ball.position.y.toFixed(1)}) speed=${sp.toFixed(2)} bat0angle=${bats[0].angle.toFixed(3)}`);
  }
}
