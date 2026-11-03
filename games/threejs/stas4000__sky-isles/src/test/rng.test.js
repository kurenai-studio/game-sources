import test from 'node:test';
import assert from 'node:assert/strict';
import { Rng, mulberry32 } from '../src/sim/rng.js';

test('mulberry32 is deterministic for the same seed', () => {
  const a = mulberry32(1234);
  const b = mulberry32(1234);
  for (let i = 0; i < 100; i++) assert.equal(a(), b());
});

test('different seeds produce different sequences', () => {
  const a = mulberry32(1);
  const b = mulberry32(2);
  let same = 0;
  for (let i = 0; i < 50; i++) if (a() === b()) same++;
  assert.ok(same < 5);
});

test('Rng helpers stay in range', () => {
  const rng = new Rng(99);
  for (let i = 0; i < 500; i++) {
    const f = rng.float(3, 7);
    assert.ok(f >= 3 && f < 7);
    const n = rng.int(2, 5);
    assert.ok(n >= 2 && n < 5 && Number.isInteger(n));
    assert.ok([-1, 1].includes(rng.sign()));
    assert.ok(rng.float() >= 0 && rng.float() < 1);
  }
});

test('Rng pick returns items from the list deterministically', () => {
  const list = ['a', 'b', 'c', 'd'];
  const a = new Rng(42);
  const b = new Rng(42);
  for (let i = 0; i < 20; i++) {
    const v = a.pick(list);
    assert.ok(list.includes(v));
    assert.equal(v, b.pick(list));
  }
});
