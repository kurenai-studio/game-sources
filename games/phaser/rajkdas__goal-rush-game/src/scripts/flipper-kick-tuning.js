/**
 * Flipper kick tuning harness — v5.
 *
 * LEFT flipper: pivot (178,862), rest +0.52, up −0.55. Up-swing = θ DECREASING
 * = NEGATIVE angular velocity. The resolver-visible velocity is painted with
 * the correct sign; scenarios A (rest→press) and C (dead bat) drive the tune.
 */
const Matter = require('matter-js');
const { Engine, Bodies, Body, Composite } = Matter;

const STEP = 1000 / 60;
const PIVOT = { x: 178, y: 862 };
const REST = 0.52;
const UP = -0.55;
const HALF = 31.65;
const DIR = 1;
const HALF_THICK = 8.5;
const BALL_R = 13;

const upN = (a) => ({ x: Math.sin(a), y: -Math.cos(a) });

function makeEngine() {
  const engine = Engine.create();
  engine.gravity.y = 0.95;
  engine.positionIterations = 12;
  engine.velocityIterations = 8;
  return engine;
}

const batCenter = (angle) => ({
  x: PIVOT.x + DIR * HALF * Math.cos(angle),
  y: PIVOT.y + DIR * HALF * Math.sin(angle),
});

function faceBallPos(s, a = REST) {
  const A = { x: Math.cos(a), y: Math.sin(a) };
  const N = upN(a);
  return {
    x: PIVOT.x + DIR * s * A.x + N.x * (HALF_THICK + BALL_R + 1),
    y: PIVOT.y + DIR * s * A.y + N.y * (HALF_THICK + BALL_R + 1),
  };
}

function makeWorld(ballAt) {
  const engine = makeEngine();
  const c0 = batCenter(REST);
  const bat = Bodies.rectangle(c0.x, c0.y, 82, 17, {
    isStatic: true,
    angle: REST,
    restitution: 0.05,
    friction: 0.16,
    label: 'bat',
  });
  const pos = ballAt ?? faceBallPos(40);
  const ball = Bodies.circle(pos.x, pos.y, BALL_R, {
    restitution: 0.42,
    friction: 0.028,
    frictionAir: 0.0035,
    density: 0.0028,
    frictionStatic: 0,
    label: 'ball',
  });
  // Feed walls (as in the real table) so the cradle region is closed.
  const feed = Bodies.rectangle(148, 843, 112, 10, {
    isStatic: true,
    angle: 0.303,
    restitution: 0.42,
    friction: 0,
    label: 'feed',
  });
  const post = Bodies.circle(178, 862, 7, { isStatic: true, restitution: 0.55, friction: 0, label: 'post' });
  Composite.add(engine.world, [bat, ball, feed, post]);
  return { engine, bat, ball };
}

function driveBat(bat, angle, signedOmega) {
  const c = batCenter(angle);
  Body.setPosition(bat, c, true);
  Body.setAngle(bat, angle, true);
  if (signedOmega !== 0) {
    Body.setVelocity(bat, {
      x: HALF * signedOmega * DIR * -Math.sin(angle),
      y: HALF * signedOmega * DIR * Math.cos(angle),
    });
    Body.setAngularVelocity(bat, signedOmega);
  }
}

const swingSteps = (rate) => Math.ceil((REST - UP) / rate);
const speed = (b) => Math.hypot(b.velocity.x, b.velocity.y);

/** A) reaction shot: ball on the upper face at radius s, press immediately. */
function scenarioA(rate, omegaAbs, s = 40) {
  const omega = -omegaAbs; // up-swing: negative for the left flipper
  const { engine, bat, ball } = makeWorld(faceBallPos(s));
  const startY = ball.position.y;
  const n = swingSteps(rate);
  let angle = REST;
  let peak = 0;
  for (let i = 0; i < n; i++) {
    angle = Math.max(UP, angle - rate);
    driveBat(bat, angle, omega);
    if (i === n - 1) driveBat(bat, angle, 0);
    Engine.update(engine, STEP);
    peak = Math.max(peak, speed(ball));
    if (ball.position.y > 990) return { res: 'FELL', peak: +peak.toFixed(1) };
  }
  driveBat(bat, angle, 0);
  let minY = ball.position.y;
  for (let i = 0; i < 24; i++) {
    Engine.update(engine, STEP);
    minY = Math.min(minY, ball.position.y);
    if (ball.position.y > 990) break;
  }
  return { res: 'OK', peak: +peak.toFixed(1), vy: +ball.velocity.y.toFixed(1), rise: Math.round(startY - minY) };
}

/** A2) late press: ball already rolling down the face toward the tip. */
function scenarioA2(rate, omegaAbs) {
  const omega = -omegaAbs;
  const { engine, bat, ball } = makeWorld(faceBallPos(55));
  // let it roll 12 steps down the dead face (toward the tip)
  driveBat(bat, REST, 0);
  for (let i = 0; i < 12; i++) Engine.update(engine, STEP);
  const rollSpeed = speed(ball);
  const n = swingSteps(rate);
  let angle = REST;
  let peak = 0;
  for (let i = 0; i < n; i++) {
    angle = Math.max(UP, angle - rate);
    driveBat(bat, angle, omega);
    if (i === n - 1) driveBat(bat, angle, 0);
    Engine.update(engine, STEP);
    peak = Math.max(peak, speed(ball));
    if (ball.position.y > 990) return { res: 'FELL', peak: +peak.toFixed(1), rollSpeed: +rollSpeed.toFixed(1) };
  }
  driveBat(bat, angle, 0);
  let minY = ball.position.y;
  for (let i = 0; i < 24; i++) {
    Engine.update(engine, STEP);
    minY = Math.min(minY, ball.position.y);
    if (ball.position.y > 990) break;
  }
  return { res: 'OK', peak: +peak.toFixed(1), rise: Math.round(960 - minY), rollSpeed: +rollSpeed.toFixed(1) };
}

/** C) dead bat: normal-velocity (upper-face normal) must stay tiny. */
function scenarioC() {
  const { engine, bat, ball } = makeWorld(faceBallPos(40));
  driveBat(bat, REST, 0);
  const N = upN(REST);
  let peakNormal = 0;
  for (let i = 0; i < 90; i++) {
    Engine.update(engine, STEP);
    const vn = ball.velocity.x * N.x + ball.velocity.y * N.y;
    if (ball.position.y < 960) peakNormal = Math.max(peakNormal, Math.abs(vn));
    if (ball.position.y > 990) break;
  }
  return { peakNormal: +peakNormal.toFixed(2), end: { x: Math.round(ball.position.x), y: Math.round(ball.position.y) } };
}

for (const rate of [0.18, 0.24, 0.3]) {
  const steps = swingSteps(rate);
  console.log(`=== placeRate ${rate} rad/step (${steps} steps, ${(steps * 16.7).toFixed(0)} ms swing) ===`);
  for (const omegaAbs of [0, 0.14, 0.2, 0.28, 0.38]) {
    const a = scenarioA(rate, omegaAbs, 40);
    const aT = scenarioA(rate, omegaAbs, 60);
    const aP = scenarioA(rate, omegaAbs, 22);
    const a2 = scenarioA2(rate, omegaAbs);
    console.log(
      `  w=${omegaAbs.toFixed(2)} | A(r40) ${a.res} peak=${a.peak} rise=${a.rise ?? '-'} | A(r60) ${aT.res} peak=${aT.peak} rise=${aT.rise ?? '-'} | A(r22) ${aP.res} peak=${aP.peak} rise=${aP.rise ?? '-'} | A2(rolling) ${a2.res} peak=${a2.peak} rise=${a2.rise ?? '-'}`
    );
  }
}
const c = scenarioC();
console.log(`C(dead): peakNormal=${c.peakNormal} (want < 2.5) end=${JSON.stringify(c.end)}`);
