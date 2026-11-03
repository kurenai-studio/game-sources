import { test } from 'node:test';
import assert from 'node:assert/strict';
import { HALF, LENGTH, homePosition } from '../src/table.js';
import { STEP, createMallet } from '../src/physics.js';
import {
  GOAL_PAUSE, createGame, createDemoGame, getState, moveTargetBy, restartMatch, setPaused, setTarget, update,
} from '../src/game.js';
import { createRng } from '../src/rng.js';
import { malletInHalf, puckOnTable } from '../test-utils/helpers.js';

/** Parks a person's mallet near the side wall so a test shot is not blocked. */
function park(g, side) {
  const y = side === 1 ? 0.2 : LENGTH - 0.2;
  g.players[side].mallet = createMallet(0.1, y);
  g.players[side].target = { x: 0.1, y };
}

test('createGame uses safe defaults and validates options', () => {
  const s = getState(createGame());
  assert.equal(s.mode, 'cpu');
  assert.equal(s.level, 'medium');
  assert.equal(s.goalsToWin, 7);
  assert.deepEqual(s.controllers, ['human', 'medium']);
  assert.deepEqual(s.score, [0, 0]);
  assert.equal(s.phase, 'play');
  assert.ok(s.puck.y > HALF, 'you serve first against the computer');
  const odd = getState(createGame({ mode: 'x', level: 'insane', goalsToWin: 3 }));
  assert.equal(odd.level, 'medium');
  assert.equal(odd.goalsToWin, 7);
  for (const g of [5, 7, 10]) assert.equal(getState(createGame({ goalsToWin: g })).goalsToWin, g);
  assert.deepEqual(getState(createGame({ mode: 'pvp' })).controllers, ['human', 'human']);
  assert.deepEqual(getState(createGame({ level: 'hard' })).controllers, ['human', 'hard']);
});

test('the same seed gives the same match whatever the frame rate', () => {
  const a = createGame({ mode: 'ai', controllers: ['hard', 'medium'], seed: 42 });
  const b = createGame({ mode: 'ai', controllers: ['hard', 'medium'], seed: 42 });
  for (let i = 0; i < 300; i += 1) update(a, 4 * STEP);
  for (let i = 0; i < 1200; i += 1) update(b, STEP + 1e-12);
  assert.ok(Math.abs(a.time - b.time) < 1e-6);
  assert.deepEqual(getState(a), getState(b));
});

test('a long frame is capped so the game does not jump ahead', () => {
  const g = createGame({ seed: 1 });
  update(g, 10);
  assert.ok(g.time <= 0.25 + 1e-9);
});

test('targets are clamped to the player half; keyboard nudges move them', () => {
  const g = createGame({ mode: 'pvp' });
  setTarget(g, 0, 0.5, 0.1);
  assert.ok(malletInHalf(g.players[0].target, 0));
  setTarget(g, 1, -3, 9);
  assert.ok(malletInHalf(g.players[1].target, 1));
  setTarget(g, 0, 0.5, 1.3);
  moveTargetBy(g, 0, 0.1, -0.05);
  assert.ok(Math.abs(g.players[0].target.x - 0.6) < 1e-12 && Math.abs(g.players[0].target.y - 1.25) < 1e-12);
  for (let i = 0; i < 120; i += 1) update(g, STEP);
  assert.ok(Math.hypot(g.players[0].mallet.x - 0.6, g.players[0].mallet.y - 1.25) < 1e-9, 'mallet reached the target');
});

test('mallets follow random targets but stay in their halves during play', () => {
  const g = createGame({ mode: 'pvp', seed: 8 });
  const rng = createRng(8);
  for (let i = 0; i < 3000; i += 1) {
    if (i % 20 === 0) {
      setTarget(g, 0, rng() * 1.4 - 0.2, rng() * 2 - 0.2);
      setTarget(g, 1, rng() * 1.4 - 0.2, rng() * 2 - 0.2);
    }
    update(g, STEP);
    const s = getState(g);
    assert.ok(malletInHalf(s.mallets[0], 0) && malletInHalf(s.mallets[1], 1));
    if (s.phase === 'play') assert.ok(puckOnTable(s.puck) || s.puck.y < 0 || s.puck.y > LENGTH);
  }
});

test('a goal scores, pauses, then serves to the player who conceded', () => {
  const g = createGame({ mode: 'pvp', seed: 2 });
  park(g, 1);
  g.puck = { x: 0.5, y: 0.3, vx: 0, vy: -3.5 };
  let events = [];
  for (let i = 0; i < 60 && !events.some((e) => e.type === 'goal'); i += 1) events = update(g, STEP);
  assert.deepEqual(events.find((e) => e.type === 'goal'), { type: 'goal', scorer: 0 });
  let s = getState(g);
  assert.deepEqual(s.score, [1, 0]);
  assert.equal(s.phase, 'goal');
  for (let i = 0; i < GOAL_PAUSE / STEP + 2; i += 1) update(g, STEP);
  s = getState(g);
  assert.equal(s.phase, 'play');
  assert.ok(s.puck.y < HALF, 'puck placed on the top (conceding) side');
  assert.equal(Math.hypot(s.puck.vx, s.puck.vy), 0);
  assert.ok(Math.hypot(s.mallets[1].x - homePosition(1).x, s.mallets[1].y - homePosition(1).y) < 0.1);

  g.puck = { x: 0.5, y: 1.3, vx: 0, vy: 3.5 };
  park(g, 0);
  for (let i = 0; i < 60 && g.phase === 'play'; i += 1) update(g, STEP);
  assert.deepEqual(getState(g).score, [1, 1]);
  for (let i = 0; i < GOAL_PAUSE / STEP + 2; i += 1) update(g, STEP);
  assert.ok(getState(g).puck.y > HALF, 'puck placed on the bottom (conceding) side');
});

test('the match ends at the goal target and stops updating', () => {
  const g = createGame({ mode: 'pvp', goalsToWin: 5 });
  g.score = [4, 2];
  park(g, 1);
  g.puck = { x: 0.5, y: 0.3, vx: 0, vy: -3.5 };
  const events = [];
  for (let i = 0; i < 60; i += 1) events.push(...update(g, STEP));
  assert.ok(events.some((e) => e.type === 'over' && e.winner === 0));
  const s = getState(g);
  assert.equal(s.phase, 'over');
  assert.equal(s.winner, 0);
  assert.deepEqual(update(g, 1), []);
  restartMatch(g);
  assert.deepEqual(getState(g).score, [0, 0]);
  assert.equal(getState(g).phase, 'play');
  assert.equal(getState(g).winner, null);
});

test('pause freezes the game', () => {
  const g = createGame({ seed: 4 });
  g.puck.vy = -2;
  setPaused(g, true);
  const before = JSON.stringify(getState(g).puck);
  update(g, 0.1);
  assert.equal(JSON.stringify(getState(g).puck), before);
  setPaused(g, false);
  update(g, 0.1);
  assert.notEqual(JSON.stringify(getState(g).puck), before);
});

test('the demo frame is a frozen 3-2 match with a fast puck heading for the computer goal', () => {
  const g = createDemoGame();
  const s = getState(g);
  assert.deepEqual(s.score, [3, 2]);
  assert.equal(s.mode, 'cpu');
  assert.ok(s.frozen);
  assert.ok(s.puck.vy < 0 && Math.hypot(s.puck.vx, s.puck.vy) > 3);
  assert.ok(s.trail.length >= 8);
  assert.ok(puckOnTable(s.puck));
  assert.ok(malletInHalf(s.mallets[0], 0) && malletInHalf(s.mallets[1], 1));
  update(g, 1);
  assert.deepEqual(getState(g), s);
});

test('a fast puck leaves a trail that fades when it slows', () => {
  const g = createGame({ mode: 'pvp' });
  g.puck = { x: 0.5, y: 0.8, vx: 3, vy: 0.2 };
  update(g, 0.1);
  assert.ok(getState(g).trail.length > 5);
  g.puck.vx = 0;
  g.puck.vy = 0;
  update(g, 0.2);
  assert.equal(getState(g).trail.length, 0);
});

test('seeded random numbers are deterministic and in [0, 1)', () => {
  const a = createRng(5);
  const b = createRng(5);
  for (let i = 0; i < 1000; i += 1) {
    const v = a();
    assert.equal(v, b());
    assert.ok(v >= 0 && v < 1);
  }
  assert.notEqual(createRng(6)(), createRng(5)());
});
