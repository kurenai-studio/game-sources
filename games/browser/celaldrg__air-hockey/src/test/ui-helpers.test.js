import { test } from 'node:test';
import assert from 'node:assert/strict';
import { t, keys, normalizeLang } from '../src/i18n.js';
import { load, save } from '../src/storage.js';
import { sideForPointer, pointerAim, keyboardMoves, isMoveKey, KEY_SPEED, TOUCH_OFFSET } from '../src/controls.js';
import { fitCanvas, computeView, toTable, toCanvas, VIEW_WIDTH, VIEW_HEIGHT } from '../src/view.js';
import { normalizeSettings } from '../src/settings.js';
import { HALF } from '../src/table.js';

test('English and Turkish have the same non-empty strings', () => {
  const en = keys('en');
  assert.deepEqual([...keys('tr')].sort(), [...en].sort());
  for (const k of en) {
    assert.ok(t('en', k).length > 0, k);
    assert.ok(t('tr', k).length > 0, k);
  }
});

test('placeholders are filled and unknown languages fall back to English', () => {
  assert.equal(t('en', 'playerWins', { n: 2 }), 'Player 2 wins!');
  assert.equal(t('tr', 'finalScore', { a: 7, b: 3 }), 'Sonuç 7 – 3');
  assert.equal(normalizeLang('de'), 'en');
  assert.equal(t('de', 'start'), 'Start');
});

test('storage works without localStorage and with broken JSON', () => {
  const saved = globalThis.localStorage;
  try {
    delete globalThis.localStorage;
    assert.equal(load('x', 5), 5);
    save('x', 1);
    const data = new Map();
    globalThis.localStorage = {
      getItem: (k) => (data.has(k) ? data.get(k) : null),
      setItem: (k, v) => data.set(k, v),
    };
    save('lang', 'tr');
    assert.equal(load('lang', 'en'), 'tr');
    data.set('air-hockey:bad', '{oops');
    assert.equal(load('bad', 'fallback'), 'fallback');
    globalThis.localStorage = { getItem() { throw new Error('blocked'); }, setItem() { throw new Error('full'); } };
    assert.equal(load('lang', 'en'), 'en');
    assert.doesNotThrow(() => save('lang', 'tr'));
  } finally {
    if (saved === undefined) delete globalThis.localStorage;
    else globalThis.localStorage = saved;
  }
});

test('pointers pick their player by half in two-player mode only', () => {
  assert.equal(sideForPointer('pvp', HALF - 0.01), 1);
  assert.equal(sideForPointer('pvp', HALF + 0.01), 0);
  assert.equal(sideForPointer('cpu', 0.1), 0);
});

test('touch aim sits ahead of the finger, away from its player', () => {
  assert.deepEqual(pointerAim(0.5, 1.2, 0, false), { x: 0.5, y: 1.2 });
  assert.equal(pointerAim(0.5, 1.2, 0, true).y, 1.2 - TOUCH_OFFSET);
  assert.equal(pointerAim(0.5, 0.3, 1, true).y, 0.3 + TOUCH_OFFSET);
});

test('keyboard moves: both key sets for you, split in two-player mode', () => {
  assert.ok(isMoveKey('ArrowUp') && isMoveKey('KeyD') && !isMoveKey('KeyP'));
  const [me, other] = keyboardMoves(['KeyW', 'ArrowRight'], 'cpu', 0.5);
  assert.deepEqual(me, { dx: KEY_SPEED * 0.5, dy: -KEY_SPEED * 0.5 });
  assert.deepEqual(other, { dx: 0, dy: 0 });
  const [bottom, top] = keyboardMoves(['KeyA', 'ArrowDown'], 'pvp', 1);
  assert.deepEqual(bottom, { dx: 0, dy: KEY_SPEED });
  assert.deepEqual(top, { dx: -KEY_SPEED, dy: 0 });
});

test('canvas fits its box with the table proportions and maps both ways', () => {
  const size = fitCanvas(375, 580);
  assert.ok(size.width <= 375 && size.height <= 580);
  assert.ok(Math.abs(size.width / size.height - VIEW_WIDTH / VIEW_HEIGHT) < 0.01);
  const view = computeView(size.width, size.height);
  const p = toCanvas(view, 0.3, 1.1);
  const back = toTable(view, p.x, p.y);
  assert.ok(Math.abs(back.x - 0.3) < 1e-9 && Math.abs(back.y - 1.1) < 1e-9);
});

test('settings are validated with sensible defaults', () => {
  assert.deepEqual(normalizeSettings(null), { mode: 'cpu', level: 'medium', goalsToWin: 7 });
  assert.deepEqual(normalizeSettings({ mode: 'pvp', level: 'hard', goalsToWin: 10 }),
    { mode: 'pvp', level: 'hard', goalsToWin: 10 });
  assert.deepEqual(normalizeSettings({ mode: 'x', level: 'god', goalsToWin: 99 }),
    { mode: 'cpu', level: 'medium', goalsToWin: 7 });
});
