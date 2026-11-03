import test from 'node:test';
import assert from 'node:assert/strict';
import { throwFromDrag } from './throw.js';

const H = 800;
// Rechte veeg van (x0, y0) naar (x1, y1) in ms milliseconden.
const veeg = (x0, y0, x1, y1, ms, n = 12) =>
  Array.from({ length: n + 1 }, (_, i) => ({ x: x0 + ((x1 - x0) * i) / n, y: y0 + ((y1 - y0) * i) / n, t: (ms * i) / n }));

test('snellere veeg geeft een hardere worp, binnen de grenzen', () => {
  const traag = throwFromDrag(veeg(400, 700, 400, 500, 300), H);
  const snel = throwFromDrag(veeg(400, 700, 400, 300, 150), H);
  assert.ok(snel.speed > traag.speed);
  assert.ok(throwFromDrag(veeg(400, 780, 400, 0, 20), H).speed <= 30);
});

test('geen worp bij loslaten zonder vaart of bij omlaag slepen', () => {
  assert.equal(throwFromDrag(veeg(400, 700, 400, 690, 400), H), null);
  assert.equal(throwFromDrag(veeg(400, 300, 400, 700, 150), H), null);
  assert.equal(throwFromDrag([], H), null);
});

test('richting volgt de veeg en hoger loslaten geeft een steilere worp', () => {
  assert.ok(throwFromDrag(veeg(400, 700, 600, 400, 150), H).yaw > 0.2);
  assert.ok(throwFromDrag(veeg(400, 700, 200, 400, 150), H).yaw < -0.2);
  const laag = throwFromDrag(veeg(400, 780, 400, 600, 100), H);
  const hoog = throwFromDrag(veeg(400, 780, 400, 150, 250), H);
  assert.ok(hoog.elev > laag.elev);
});

test('een bocht in het sleeppad geeft zijspin, een rechte veeg niet', () => {
  const recht = throwFromDrag(veeg(400, 700, 400, 300, 200), H);
  assert.ok(Math.abs(recht.zijspin) < 1);
  // eerst recht omhoog, dan afbuigen naar rechts
  const haak = [...veeg(400, 700, 400, 500, 150), ...veeg(400, 500, 520, 380, 100).map((p) => ({ ...p, t: p.t + 150 }))];
  assert.ok(throwFromDrag(haak, H).zijspin > 20);
});
