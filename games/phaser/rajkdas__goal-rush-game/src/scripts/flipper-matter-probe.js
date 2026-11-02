/**
 * Experiment: how does Matter 0.20 treat velocity on a STATIC body that is
 * kinematically moved (setPosition every step) versus the current DYNAMIC
 * re-placed design?
 *
 * Q1: Does the resolver use a static body's velocity for the impulse on a
 *     dynamic body (moving-platform effect)?
 * Q2: In the DYNAMIC design (place with updateVelocity=true each step), does
 *     the engine's Verlet integration displace the body beyond the placement
 *     (double-integration wobble)?
 */
const Matter = require('matter-js');
const { Engine, World, Bodies, Body, Composite } = Matter;

function makeEngine() {
  const engine = Engine.create();
  engine.gravity.y = 0.95; // match game
  engine.positionIterations = 12;
  engine.velocityIterations = 8;
  return engine;
}

const STEP = 1000 / 60;

// ─────────────────────────────────────────────────────────────────────────────
// Q1: static bat, velocity set explicitly, ball resting on it. Launch check.
// ─────────────────────────────────────────────────────────────────────────────
function q1() {
  const engine = makeEngine();
  // Bat: horizontal, pivot at left end. Place a ball resting on its face.
  const pivot = { x: 178, y: 862 };
  const bat = Bodies.rectangle(210, 878, 82, 17, {
    isStatic: true,
    angle: 0.52,
    restitution: 0.05,
    friction: 0.16,
    label: 'bat',
  });
  const ball = Bodies.circle(216, 862, 13, {
    restitution: 0.42,
    friction: 0.028,
    frictionAir: 0.0035,
    density: 0.0028,
    label: 'ball',
  });
  Composite.add(engine.world, [bat, ball]);
  // Settle the ball onto the bat.
  for (let i = 0; i < 30; i++) Engine.update(engine, STEP);
  const before = { ...ball.velocity };

  // Now simulate a fast up-swing: rotate the static bat kinematically by
  // 0.27 rad about the pivot over 4 steps, and set its velocity to the
  // "solver" values (angular 0.72/tick + linear at center).
  const angle0 = 0.52;
  let angle = angle0;
  const dir = 1; // left flipper: angle DECREASES when pressed
  for (let s = 0; s < 4; s++) {
    angle -= 0.27; // swing up (left flipper: toward -0.55)
    const cx = pivot.x + 31.65 * Math.cos(angle);
    const cy = pivot.y + 31.65 * Math.sin(angle);
    Body.setPosition(bat, { x: cx, y: cy }, true);
    Body.setAngle(bat, angle, true);
    // Solver override: pretend the bat moves at 0.72 rad/tick.
    const omega = -0.72; // rad per tick (decreasing = negative)
    // v_center = half * omega * (-sin a, cos a)  [dir = +1]
    Body.setVelocity(bat, {
      x: 31.65 * omega * -Math.sin(angle),
      y: 31.65 * omega * Math.cos(angle),
    });
    Body.setAngularVelocity(bat, omega);
    Engine.update(engine, STEP);
    if (s === 0 || s === 3) {
      console.log(
        `Q1 step ${s}: ball v=(${ball.velocity.x.toFixed(2)}, ${ball.velocity.y.toFixed(2)}) pos=(${ball.position.x.toFixed(1)}, ${ball.position.y.toFixed(1)})`
      );
    }
  }
  console.log(
    `Q1 FINAL: ball v=(${ball.velocity.x.toFixed(2)}, ${ball.velocity.y.toFixed(2)}) speed=${Math.hypot(ball.velocity.x, ball.velocity.y).toFixed(2)}  (before: ${before.x.toFixed(2)},${before.y.toFixed(2)})`
  );
  console.log(`Q1: ball launched upward? ${ball.velocity.y < -3 ? 'YES' : 'NO'}`);
}

// ─────────────────────────────────────────────────────────────────────────────
// Q2: DYNAMIC bat re-placed each step with updateVelocity=true (current game
// design). Log where the body actually is right after each Engine.update vs
// where we placed it → exposes the double-integration wobble.
// ─────────────────────────────────────────────────────────────────────────────
function q2() {
  const engine = makeEngine();
  const pivot = { x: 178, y: 862 };
  const bat = Bodies.rectangle(210, 878, 82, 17, {
    restitution: 0.05,
    friction: 0.16,
    density: 0.09,
    frictionAir: 0,
    isSleeping: false,
    label: 'bat',
  });
  Body.set(bat, 'ignoreGravity', true);
  Composite.add(engine.world, [bat]);
  let angle = 0.52;
  const placements = [];
  for (let s = 0; s < 4; s++) {
    angle -= 0.27;
    const cx = pivot.x + 31.65 * Math.cos(angle);
    const cy = pivot.y + 31.65 * Math.sin(angle);
    Body.setPosition(bat, { x: cx, y: cy }, true);
    Body.setAngle(bat, angle, true);
    placements.push({ x: cx, y: cy, angle });
    Engine.update(engine, STEP);
    const dx = bat.position.x - cx;
    const dy = bat.position.y - cy;
    const da = bat.angle - angle;
    console.log(
      `Q2 step ${s}: after update, body is off-placement by (${dx.toFixed(1)}, ${dy.toFixed(1)}) px, ${da.toFixed(3)} rad; velocity=(${bat.velocity.x.toFixed(2)},${bat.velocity.y.toFixed(2)}) av=${bat.angularVelocity.toFixed(3)}`
    );
  }
}

q1();
console.log('──────────────────────────────');
q2();
