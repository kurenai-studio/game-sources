import test from 'node:test';
import assert from 'node:assert/strict';
import { ChimePuzzle, CHIMES, MURAL_ORDER } from '../src/sim/puzzle.js';
import { layerPlan, MUSIC_LAYERS } from '../src/sim/audio.js';

test('chime definitions are unique pentatonic notes with colors and symbols', () => {
  assert.equal(CHIMES.length, 5);
  const notes = new Set(CHIMES.map((c) => c.note));
  const symbols = new Set(CHIMES.map((c) => c.symbol));
  assert.equal(notes.size, 5);
  assert.equal(symbols.size, 5);
  for (const c of CHIMES) assert.match(c.color, /^#[0-9a-f]{6}$/);
  assert.deepEqual([...MURAL_ORDER].sort(), [0, 1, 2, 3, 4]);
});

test('correct full order opens the portal', () => {
  const p = new ChimePuzzle();
  MURAL_ORDER.forEach((idx, i) => {
    const r = p.play(idx);
    assert.equal(r.type, 'correct');
    assert.equal(r.progress, i + 1);
    assert.equal(p.unlocked, i + 1);
    assert.equal(r.complete, i === MURAL_ORDER.length - 1);
  });
  assert.equal(p.portalOpen, true);
  assert.equal(p.unlocked, 5);
});

test('wrong note resets progress', () => {
  const p = new ChimePuzzle();
  p.play(MURAL_ORDER[0]);
  p.play(MURAL_ORDER[1]);
  assert.equal(p.unlocked, 2);
  const wrongIdx = (MURAL_ORDER[2] + 1) % 5;
  const r = p.play(wrongIdx);
  assert.equal(r.type, 'wrong');
  assert.equal(p.unlocked, 0);
  assert.equal(p.portalOpen, false);
  // sequence must start over from the beginning
  const r2 = p.play(MURAL_ORDER[1]);
  assert.equal(r2.type, 'wrong');
  const r3 = p.play(MURAL_ORDER[0]);
  assert.equal(r3.type, 'correct');
});

test('playing a duplicate note mid-sequence counts as wrong and resets', () => {
  const p = new ChimePuzzle();
  p.play(MURAL_ORDER[0]);
  const r = p.play(MURAL_ORDER[0]); // duplicate, not the next expected
  assert.equal(r.type, 'wrong');
  assert.equal(p.unlocked, 0);
});

test('partial sequences do not open the portal', () => {
  const p = new ChimePuzzle();
  for (let i = 0; i < MURAL_ORDER.length - 1; i++) p.play(MURAL_ORDER[i]);
  assert.equal(p.portalOpen, false);
  assert.equal(p.unlocked, 4);
});

test('after the portal opens, further plays are replays and keep state', () => {
  const p = new ChimePuzzle();
  for (const idx of MURAL_ORDER) p.play(idx);
  const r = p.play(0);
  assert.equal(r.type, 'replay');
  assert.equal(p.portalOpen, true);
  assert.equal(p.unlocked, 5);
});

test('music layers grow one per unlocked chime', () => {
  assert.deepEqual(layerPlan(0), ['pad']);
  assert.equal(layerPlan(1).length, 2);
  assert.equal(layerPlan(3).length, 4);
  assert.equal(layerPlan(5).length, MUSIC_LAYERS.length);
  assert.equal(layerPlan(99).length, MUSIC_LAYERS.length); // capped
  assert.deepEqual(layerPlan(-2), ['pad']); // never below the pad
});
