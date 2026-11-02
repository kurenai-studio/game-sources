import { Bodies, Composite, Engine, Body } from 'matter-js';
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

interface BatState { body: Body; rest: number; up: number; angle: number; pivot: { x: number; y: number }; dir: 1 | -1; pressed: boolean }
const bats: BatState[] = [];
for (const f of FLIPPER_DEFS) {
  const half = FLIPPER.length / 2 - FLIPPER.thickness * 0.55;
  const dir = (f.side === 'left' ? 1 : -1) as 1 | -1;
  const cx = f.pivot.x + dir * half * Math.cos(f.restAngle);
  const cy = f.pivot.y + dir * half * Math.sin(f.restAngle);
  const body = Bodies.rectangle(cx, cy, FLIPPER.length, FLIPPER.thickness, {
    density: FLIPPER.density, friction: FLIPPER.friction, frictionAir: 0,
    restitution: 0.05, chamfer: { radius: FLIPPER.thickness / 2 }, angle: f.restAngle,
  });
  Composite.add(world, body);
  bats.push({ body, rest: f.restAngle, up: f.upAngle, angle: f.restAngle, pivot: f.pivot, dir, pressed: false });
}

const ball = Bodies.circle(150, 790, BALL_CFG.radius, {
  density: BALL_CFG.density, restitution: BALL_CFG.restitution, friction: BALL_CFG.friction,
  frictionAir: BALL_CFG.frictionAir, frictionStatic: 0,
});
Composite.add(world, ball);

const UP_RATE = 0.72;   // rad per step
const DOWN_RATE = 0.32;

let flipStart = -1;
let flipDone = -1;

const driveBat = (b: BatState): void => {
  const target = b.pressed ? b.up : b.rest;
  const rate = b.pressed ? UP_RATE : DOWN_RATE;
  const diff = target - b.angle;
  const step = Math.max(-rate, Math.min(rate, diff));
  b.angle += step;
  const half = FLIPPER.length / 2 - FLIPPER.thickness * 0.55;
  const cx = b.pivot.x + b.dir * half * Math.cos(b.angle);
  const cy = b.pivot.y + b.dir * half * Math.sin(b.angle);
  Body.setPosition(b.body, { x: cx, y: cy });
  Body.setAngle(b.body, b.angle);
};

for (let i = 0; i < 60 * 5; i += 1) {
  if (i === 60 * 2) { bats[0].pressed = true; flipStart = i; }
  if (i === 60 * 2 + 40) bats[0].pressed = false;

  for (const b of bats) driveBat(b);
  if (flipStart > 0 && flipDone < 0 && Math.abs(bats[0].angle - bats[0].up) < 0.05) {
    flipDone = i;
    console.log(`flip up in ${((i - flipStart) / 60 * 1000).toFixed(0)} ms`);
  }
  Engine.update(engine, 1000 / 60);
  if (i % 60 === 0) {
    const sp = Math.hypot(ball.velocity.x, ball.velocity.y);
    console.log(`t=${(i / 60).toFixed(0)}s ball=(${ball.position.x.toFixed(1)}, ${ball.position.y.toFixed(1)}) speed=${sp.toFixed(2)} bat=${bats[0].angle.toFixed(3)}`);
  }
}
console.log('final ball speed:', Math.hypot(ball.velocity.x, ball.velocity.y).toFixed(2));
