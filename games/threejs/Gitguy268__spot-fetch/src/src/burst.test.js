import test from 'node:test';
import assert from 'node:assert/strict';
import { LEVEN, newBurst, explode, stepBurst } from './burst.js';

test('een nieuwe wolk is op tot er iets inslaat', () => {
  const b = newBurst(8);
  assert.equal(stepBurst(b, 0.01), false);
  assert.ok(b.p.every((v) => v === 0));
});

test('deeltjes vertrekken vanaf de inslag, gaan omhoog en vallen terug', () => {
  const b = newBurst(8);
  explode(b, 3, 0.03, -5, 1);
  for (let i = 0; i < 8; i++) assert.deepEqual([b.p[i * 3], b.p[i * 3 + 1], b.p[i * 3 + 2]].map((v) => +v.toFixed(2)), [3, 0.03, -5]);
  assert.equal(stepBurst(b, 0.05), true);
  for (let i = 0; i < 8; i++) assert.ok(b.p[i * 3 + 1] > 0.03, 'eerst omhoog');
  const top = Array.from({ length: 8 }, (_, i) => b.p[i * 3 + 1]);
  for (let t = 0; t < 2; t += 0.05) { b.t = 0; stepBurst(b, 0.05); } // ver voorbij de levensduur, om de val te zien
  for (let i = 0; i < 8; i++) assert.ok(b.p[i * 3 + 1] < top[i], 'daarna omlaag');
});

test('een zachte inslag spat minder ver dan een harde, en na de levensduur is de wolk op', () => {
  const vast = () => 0.5;
  const zacht = newBurst(1), hard = newBurst(1);
  explode(zacht, 0, 0, 0, 0.2, vast);
  explode(hard, 0, 0, 0, 1, vast);
  assert.ok(Math.hypot(...hard.v) > Math.hypot(...zacht.v) * 4);
  let stappen = 0;
  while (stepBurst(hard, 1 / 60)) stappen++;
  assert.ok(Math.abs(stappen / 60 - LEVEN) < 0.05);
  assert.equal(stepBurst(hard, 1 / 60), false);
});
