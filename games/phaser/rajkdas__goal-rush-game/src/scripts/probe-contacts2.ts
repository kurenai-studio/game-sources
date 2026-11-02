import { Bodies, Composite, Engine, Body, Events, Constraint } from 'matter-js';
import {
  DOME, FLIPPERS as FLIPPER_DEFS, LANE_DIVIDERS, POSTS, SLINGSHOTS, WALLS, BUMPERS,
} from '../src/game/config/table.config';
import { BALL as BALL_CFG, PHYSICS, FLIPPER } from '../src/game/config/game.config';

const engine = Engine.create();
engine.gravity.y = PHYSICS.gravityY;
engine.positionIterations = PHYSICS.positionIterations;
engine.velocityIterations = PHYSICS.velocityIterations;
const world = engine.world;
const staticOpts = { isStatic: true, restitution: PHYSICS.wallRestitution, friction: PHYSICS.wallFriction };

let id = 0;
const labelOf = new Map<number, string>();
const add = (body: Body, label: string): void => {
  labelOf.set(body.id, label);
  Composite.add(world, body);
};

for (const w of WALLS) add(Bodies.rectangle(w.x, w.y, w.width, w.height, { ...staticOpts, angle: w.angle ?? 0, chamfer: w.chamfer ? { radius: w.chamfer } : undefined }), `wall@${w.x},${w.y}`);
for (let i = 0; i <= DOME.segments; i += 1) {
  const t = Math.PI + (Math.PI * i) / DOME.segments;
  add(Bodies.rectangle(DOME.cx + DOME.rx * Math.cos(t), DOME.cy + DOME.ry * Math.sin(t), ((Math.PI * ((DOME.rx + DOME.ry) / 2)) / DOME.segments) * 1.45, DOME.thickness, { ...staticOpts, angle: t + Math.PI / 2, chamfer: { radius: DOME.thickness / 2 } }), 'dome');
}
for (const p of POSTS) add(Bodies.circle(p.x, p.y, p.radius, { ...staticOpts, restitution: 0.55 }), `post@${p.x},${p.y}`);
for (const d of LANE_DIVIDERS) add(Bodies.rectangle(d.x, d.y, d.width, d.height, { ...staticOpts, angle: d.angle ?? 0, chamfer: d.chamfer ? { radius: d.chamfer } : undefined }), `divider@${d.x}`);
for (const b of BUMPERS) add(Bodies.circle(b.x, b.y, b.radius, { ...staticOpts, restitution: 0.6 }), 'bumper');
for (const s of SLINGSHOTS) {
  const cx = s.points.reduce((a, p) => a + p.x, 0) / 3;
  const cy = s.points.reduce((a, p) => a + p.y, 0) / 3;
  add(Bodies.fromVertices(cx, cy, s.points.map((p) => ({ x: p.x - cx, y: p.y - cy })), { ...staticOpts }), s.label);
}
const bats: Body[] = [];
const batsRest = new Map<number, number>();
for (const f of FLIPPER_DEFS) {
  const half = FLIPPER.length / 2 - FLIPPER.thickness * 0.55;
  const dir = f.side === 'left' ? 1 : -1;
  const cx = f.pivot.x + dir * half * Math.cos(f.restAngle);
  const cy = f.pivot.y + dir * half * Math.sin(f.restAngle);
  const bat = Bodies.rectangle(cx, cy, FLIPPER.length, FLIPPER.thickness, {
    density: FLIPPER.density, friction: FLIPPER.friction, frictionAir: 0.02, restitution: 0.05, chamfer: { radius: FLIPPER.thickness / 2 }, angle: f.restAngle,
  });
  add(bat, `flipper-${f.side}`);
  const pin = Constraint.create({
    pointA: { x: f.pivot.x, y: f.pivot.y }, bodyB: bat,
    pointB: { x: dir * -half, y: 0 }, stiffness: 1, length: 0,
  });
  Composite.add(world, pin);
  bats.push(bat);
  batsRest.set(bat.id, f.restAngle);
}

const ball = Bodies.circle(150, 790, BALL_CFG.radius, {
  density: BALL_CFG.density, restitution: BALL_CFG.restitution, friction: BALL_CFG.friction,
  frictionAir: BALL_CFG.frictionAir, frictionStatic: 0,
});
add(ball, 'ball');

let parkedContacts: string[] = [];
Events.on(engine, 'collisionActive', (evt) => {
  const list: string[] = [];
  for (const pair of evt.pairs) {
    const a = pair.bodyA;
    const b = pair.bodyB;
    if (a === ball) list.push(labelOf.get(b.id) ?? `body${b.id}`);
    if (b === ball) list.push(labelOf.get(a.id) ?? `body${a.id}`);
  }
  if (list.length) parkedContacts = list;
});

for (let i = 0; i < 60 * 6; i += 1) {
  for (const bat of bats) {
    const rest = batsRest.get(bat.id) ?? 0;
    const diff = rest - bat.angle;
    if (Math.abs(diff) < 0.012) Body.setAngularVelocity(bat, 0);
    else {
      const towardUp = Math.sign(diff) === 1;
      const maxAV = towardUp ? 0.32 : 0.72;
      Body.setAngularVelocity(bat, Math.max(-maxAV, Math.min(maxAV, diff * 0.26)));
    }
  }
  Engine.update(engine, 1000 / 60);
  if (i % 30 === 0) {
    const sp = Math.hypot(ball.velocity.x, ball.velocity.y);
    console.log(`t=${(i / 60).toFixed(1)}s pos=(${ball.position.x.toFixed(1)}, ${ball.position.y.toFixed(1)}) speed=${sp.toFixed(2)} touching=[${parkedContacts.join(', ')}]`);
  }
}
