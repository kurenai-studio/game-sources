import { test } from 'node:test';
import assert from 'node:assert/strict';
import { WIDTH, LENGTH, clampMallet } from '../src/table.js';
import {
  STEP, HIT_RADIUS, MALLET_RESTITUTION, FRICTION, createMallet, moveMallet, stepPuck, sweptHitTime,
} from '../src/physics.js';
import { createRng } from '../src/rng.js';
import { malletInHalf } from '../test-utils/helpers.js';

const k = Math.exp(-FRICTION * STEP);

test('swept hit time finds the first contact and ignores receding circles', () => {
  assert.equal(sweptHitTime(0.05, 0, 1, 0, 0.1), 0, 'already overlapping');
  assert.ok(Math.abs(sweptHitTime(-0.5, 0, 1, 0, 0.1) - 0.4) < 1e-12);
  assert.equal(sweptHitTime(0.5, 0, 1, 0, 0.1), null, 'moving apart');
  assert.equal(sweptHitTime(-0.5, 0.2, 1, 0, 0.1), null, 'passes beside');
  assert.equal(sweptHitTime(-2, 0, 1, 0, 0.1), null, 'too far for this step');
});

test('a stationary mallet reflects the puck along the collision normal', () => {
  for (const deg of [0, 25, -40, 70, 180, 250]) {
    const a = (deg * Math.PI) / 180;
    const nx = Math.cos(a);
    const ny = Math.sin(a);
    const m = createMallet(0.5, 1.2);
    // Puck approaching along -n with a tangential part, contact halfway through the step.
    const vx = -2 * nx + 0.6 * -ny;
    const vy = -2 * ny + 0.6 * nx;
    const puck = {
      x: m.x + nx * HIT_RADIUS - vx * k * STEP * 0.5,
      y: m.y + ny * HIT_RADIUS - vy * k * STEP * 0.5,
      vx, vy,
    };
    const events = stepPuck(puck, [m], STEP);
    assert.equal(events[0].type, 'hit');
    const vn = vx * k * nx + vy * k * ny;
    const ex = vx * k - (1 + MALLET_RESTITUTION) * vn * nx;
    const ey = vy * k - (1 + MALLET_RESTITUTION) * vn * ny;
    assert.ok(Math.abs(puck.vx - ex) < 1e-9 && Math.abs(puck.vy - ey) < 1e-9, `angle ${deg}`);
    const outN = puck.vx * nx + puck.vy * ny;
    assert.ok(Math.abs(outN + MALLET_RESTITUTION * vn) < 1e-9, 'normal part reversed');
    assert.ok(Math.hypot(puck.x - m.x, puck.y - m.y) >= HIT_RADIUS - 1e-12, 'no overlap after the hit');
  }
});

test('a head-on hit on a stationary mallet sends the puck straight back', () => {
  const m = createMallet(0.5, 1.2);
  const puck = { x: 0.5, y: 1.2 - HIT_RADIUS - 0.005, vx: 0, vy: 2 };
  for (let i = 0; i < 10 && puck.vy > 0; i += 1) stepPuck(puck, [m], STEP);
  assert.equal(puck.vx, 0);
  assert.ok(puck.vy < 0);
});

test('a moving mallet speeds the puck up', () => {
  const m = createMallet(0.5, 1.25);
  const puck = { x: 0.5, y: 1.0, vx: 0, vy: 0 };
  let hit = false;
  for (let i = 0; i < 60 && !hit; i += 1) {
    moveMallet(m, 0.5, 0.86, 3, 0, STEP);
    hit = stepPuck(puck, [m], STEP).some((ev) => ev.type === 'hit');
  }
  assert.ok(hit);
  const speed = Math.hypot(puck.vx, puck.vy);
  assert.ok(speed > 3, `puck speed ${speed} should exceed the mallet speed`);
  assert.ok(puck.vy < 0, 'pushed away from the mallet');

  const still = createMallet(0.5, 1.25);
  const slow = { x: 0.5, y: 1.0, vx: 0, vy: 1 };
  for (let i = 0; i < 60 && slow.vy > 0; i += 1) stepPuck(slow, [still], STEP);
  assert.ok(Math.hypot(slow.vx, slow.vy) < 1, 'a still mallet only returns what it gets');
});

test('no tunnelling: 1,000 seeded fast swipes through the puck always hit it', () => {
  const rng = createRng(2024);
  const speed = 30;
  assert.ok(speed * STEP > 2 * HIT_RADIUS, 'the mallet jumps further than the contact zone in one step');
  let swipes = 0;
  while (swipes < 1000) {
    const px = 0.3 + rng() * 0.4;
    const py = 1.05 + rng() * 0.3;
    const a = rng() * Math.PI * 2;
    const ux = Math.cos(a);
    const uy = Math.sin(a);
    const off = (rng() - 0.5) * HIT_RADIUS;
    const sx = px - ux * 0.32 - uy * off;
    const sy = py - uy * 0.32 + ux * off;
    const tx = px + ux * 0.32 - uy * off;
    const ty = py + uy * 0.32 + ux * off;
    const s = clampMallet(sx, sy, 0);
    const t = clampMallet(tx, ty, 0);
    if (s.x !== sx || s.y !== sy || t.x !== tx || t.y !== ty) continue;
    swipes += 1;
    const m = createMallet(sx, sy);
    const puck = { x: px, y: py, vx: 0, vy: 0 };
    let hits = 0;
    for (let i = 0; i < 6; i += 1) {
      moveMallet(m, tx, ty, speed, 0, STEP);
      hits += stepPuck(puck, [m], STEP).filter((ev) => ev.type === 'hit').length;
      assert.ok(Math.hypot(puck.x - m.x, puck.y - m.y) >= HIT_RADIUS - 1e-9, 'puck never left inside the mallet');
    }
    assert.ok(hits > 0 && Math.hypot(puck.vx, puck.vy) > 1, `swipe ${swipes} missed the puck`);
  }
});

test('mallets never leave their half or the table', () => {
  const rng = createRng(77);
  for (const side of [0, 1]) {
    const m = createMallet(0.5, side === 1 ? 0.2 : LENGTH - 0.2);
    for (let i = 0; i < 20000; i += 1) {
      const tx = -0.5 + rng() * (WIDTH + 1);
      const ty = -0.5 + rng() * (LENGTH + 1);
      moveMallet(m, tx, ty, 1 + rng() * 40, side, STEP);
      assert.ok(malletInHalf(m, side), `side ${side} step ${i}: ${m.x},${m.y}`);
    }
  }
});

test('mallet velocity comes from its movement and respects the speed limit', () => {
  const m = createMallet(0.5, 1.3);
  moveMallet(m, 0.9, 1.3, 2, 0, STEP);
  assert.ok(Math.abs(m.vx - 2) < 1e-9 && Math.abs(m.vy) < 1e-12);
  assert.ok(Math.abs(m.x - (0.5 + 2 * STEP)) < 1e-12);
});
