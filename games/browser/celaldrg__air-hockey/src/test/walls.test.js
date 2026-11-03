import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  WIDTH, LENGTH, CORNER_RADIUS, GOAL_LEFT, GOAL_RIGHT, PUCK_RADIUS,
} from '../src/table.js';
import {
  STEP, MAX_PUCK_SPEED, WALL_RESTITUTION, capSpeed, collideWalls, goalScorer, stepPuck,
} from '../src/physics.js';
import { angleBetween, puckOnTable } from '../test-utils/helpers.js';

const r = PUCK_RADIUS;
const e = WALL_RESTITUTION;

/** Checks a reflection about inward normal n: same angle, speed scaled by e. */
function assertReflected(before, after, nx, ny) {
  const dot = before.vx * nx + before.vy * ny;
  assert.ok(dot < 0, 'test setup: puck must move into the wall');
  const ex = (before.vx - 2 * dot * nx) * e;
  const ey = (before.vy - 2 * dot * ny) * e;
  assert.ok(Math.abs(after.vx - ex) < 1e-9 && Math.abs(after.vy - ey) < 1e-9,
    `velocity ${after.vx},${after.vy} expected ${ex},${ey}`);
  const inAngle = angleBetween(-before.vx, -before.vy, nx, ny);
  const outAngle = angleBetween(after.vx, after.vy, nx, ny);
  assert.ok(Math.abs(inAngle - outAngle) < 1e-6, 'angle of reflection equals angle of incidence');
  const ratio = Math.hypot(after.vx, after.vy) / Math.hypot(before.vx, before.vy);
  assert.ok(Math.abs(ratio - e) < 1e-9, `speed ratio ${ratio}`);
  assert.ok(puckOnTable(after), 'puck is back on the table');
}

const straightWalls = [
  { name: 'left', puck: { x: r - 0.01, y: 0.8, vx: -2, vy: 1.2 }, n: [1, 0] },
  { name: 'right', puck: { x: WIDTH - r + 0.01, y: 0.5, vx: 1.5, vy: -2 }, n: [-1, 0] },
  { name: 'top left of goal', puck: { x: 0.22, y: r - 0.012, vx: 0.7, vy: -2.5 }, n: [0, 1] },
  { name: 'top right of goal', puck: { x: 0.8, y: r - 0.004, vx: -1.1, vy: -1.9 }, n: [0, 1] },
  { name: 'bottom left of goal', puck: { x: 0.2, y: LENGTH - r + 0.01, vx: -0.4, vy: 3 }, n: [0, -1] },
  { name: 'bottom right of goal', puck: { x: 0.75, y: LENGTH - r + 0.02, vx: 2, vy: 1 }, n: [0, -1] },
];

for (const w of straightWalls) {
  test(`reflection off the ${w.name} wall keeps the angle and applies restitution`, () => {
    const before = { ...w.puck };
    const after = { ...w.puck };
    assert.equal(collideWalls(after), 'wall');
    assertReflected(before, after, w.n[0], w.n[1]);
  });
}

const corners = [
  { name: 'top-left', c: [CORNER_RADIUS, CORNER_RADIUS], out: [-1, -1] },
  { name: 'top-right', c: [WIDTH - CORNER_RADIUS, CORNER_RADIUS], out: [1, -1] },
  { name: 'bottom-left', c: [CORNER_RADIUS, LENGTH - CORNER_RADIUS], out: [-1, 1] },
  { name: 'bottom-right', c: [WIDTH - CORNER_RADIUS, LENGTH - CORNER_RADIUS], out: [1, 1] },
];

for (const k of corners) {
  test(`reflection off the ${k.name} corner arc keeps the angle and applies restitution`, () => {
    const rho = CORNER_RADIUS - r;
    for (const frac of [0.15, 0.5, 0.85]) {
      const a = frac * Math.PI / 2;
      const ux = k.out[0] * Math.cos(a);
      const uy = k.out[1] * Math.sin(a);
      for (const turn of [-0.6, 0, 0.6]) {
        const vx = 2 * (ux * Math.cos(turn) - uy * Math.sin(turn));
        const vy = 2 * (ux * Math.sin(turn) + uy * Math.cos(turn));
        const before = { x: k.c[0] + ux * (rho + 0.006), y: k.c[1] + uy * (rho + 0.006), vx, vy };
        const after = { ...before };
        assert.equal(collideWalls(after), 'wall');
        assertReflected(before, after, -ux, -uy);
      }
    }
  });
}

test('a puck travelling along a wall over many steps never leaves the table', () => {
  const puck = { x: 0.5, y: 0.8, vx: -3, vy: -2.2 };
  for (let i = 0; i < 1200; i += 1) {
    stepPuck(puck, [], STEP);
    if (goalScorer(puck) !== null) break;
    assert.ok(puckOnTable(puck), `step ${i}: ${puck.x},${puck.y}`);
  }
});

test('speed cap limits the speed and keeps the direction', () => {
  const body = { vx: 30, vy: -40 };
  capSpeed(body);
  assert.ok(Math.abs(Math.hypot(body.vx, body.vy) - MAX_PUCK_SPEED) < 1e-12);
  assert.ok(Math.abs(body.vx / body.vy - 30 / -40) < 1e-12);
  const slow = { vx: 1, vy: 1 };
  capSpeed(slow);
  assert.deepEqual(slow, { vx: 1, vy: 1 });
  const puck = { x: 0.5, y: 0.8, vx: 50, vy: 0 };
  stepPuck(puck, [], STEP);
  assert.ok(Math.hypot(puck.vx, puck.vy) <= MAX_PUCK_SPEED + 1e-12);
});

test('goal counts only when the whole puck is past the line', () => {
  assert.equal(goalScorer({ x: 0.5, y: -r + 0.001 }), null);
  assert.equal(goalScorer({ x: 0.5, y: -r - 0.001 }), 0);
  assert.equal(goalScorer({ x: 0.5, y: LENGTH + r - 0.001 }), null);
  assert.equal(goalScorer({ x: 0.5, y: LENGTH + r + 0.001 }), 1);
});

/** Runs the puck alone for up to `seconds`; returns the scorer or null. */
function shoot(puck, seconds = 2) {
  for (let i = 0; i < seconds / STEP; i += 1) {
    stepPuck(puck, [], STEP);
    const s = goalScorer(puck);
    if (s !== null) return s;
    assert.ok(puckOnTable(puck));
  }
  return null;
}

test('shots between the posts score for the right player', () => {
  for (const x of [GOAL_LEFT + r + 0.002, 0.5, GOAL_RIGHT - r - 0.002]) {
    assert.equal(shoot({ x, y: 0.5, vx: 0, vy: -3 }), 0, `top goal at x=${x}`);
    assert.equal(shoot({ x, y: 1.1, vx: 0, vy: 3 }), 1, `bottom goal at x=${x}`);
  }
  assert.equal(shoot({ x: 0.3, y: 0.9, vx: 0.5, vy: -3 }), 0, 'angled shot');
});

test('a puck hitting a post bounces off and does not score', () => {
  for (const postX of [GOAL_LEFT, GOAL_RIGHT]) {
    for (const off of [-0.5, -0.25, 0, 0.25, 0.5]) {
      const x = postX + off * r;
      const top = { x, y: 0.4, vx: 0, vy: -3 };
      assert.equal(shoot(top, 0.3), null, `top post ${postX} offset ${off}`);
      assert.ok(top.vy > 0, 'bounced back from the top post');
      const bottom = { x, y: 1.2, vx: 0, vy: 3 };
      assert.equal(shoot(bottom, 0.3), null, `bottom post ${postX} offset ${off}`);
      assert.ok(bottom.vy < 0, 'bounced back from the bottom post');
    }
  }
});

test('a head-on post hit reports a post collision', () => {
  const puck = { x: GOAL_LEFT + 0.01, y: 0.02, vx: 0, vy: -2 };
  assert.equal(collideWalls(puck), 'post');
  assert.ok(puck.vy > 0);
});
