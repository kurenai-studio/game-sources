import { test } from 'node:test';
import assert from 'node:assert/strict';
import { WIDTH, LENGTH, HALF, CORNER_RADIUS } from '../src/table.js';
import { STEP, stepPuck } from '../src/physics.js';
import { DEFENCE_LINE, predictCrossing, createAI, aiTarget } from '../src/ai.js';
import { createGame, update, setTarget } from '../src/game.js';
import { createRng } from '../src/rng.js';

/** Simulates a lone puck and returns the x where its centre crosses lineY. */
function simulatedCrossing(puck, lineY, dir) {
  for (let i = 0; i < 4 / STEP; i += 1) {
    const before = { ...puck };
    stepPuck(puck, [], STEP);
    if ((puck.y - lineY) * dir <= 0) {
      const f = (before.y - lineY) / (before.y - puck.y);
      return before.x + (puck.x - before.x) * f;
    }
  }
  return null;
}

test('defence prediction matches the simulated crossing for 200 seeded shots (0-2 wall bounces)', () => {
  const rng = createRng(31);
  const seen = [0, 0, 0];
  let shots = 0;
  while (shots < 200) {
    const toTop = shots % 2 === 0;
    // Shots are generated in the defender's local frame and mirrored for the bottom side.
    const x = 0.1 + rng() * 0.8;
    const y = 0.9 + rng() * 0.5;
    const aimX = -1.7 + rng() * 4.4;
    const dy = DEFENCE_LINE - y;
    const len = Math.hypot(aimX - x, dy);
    const local = { x, y, vx: ((aimX - x) / len) * 3.4, vy: (dy / len) * 3.4 };
    const p = predictCrossing(local.x, local.y, local.vx, local.vy, DEFENCE_LINE);
    if (!p || p.bounces > 2) continue;
    shots += 1;
    seen[p.bounces] += 1;
    const world = toTop ? { ...local } : { x, y: LENGTH - y, vx: local.vx, vy: -local.vy };
    const lineY = toTop ? DEFENCE_LINE : LENGTH - DEFENCE_LINE;
    const simX = simulatedCrossing(world, lineY, toTop ? 1 : -1);
    assert.notEqual(simX, null, `shot ${shots} never reached the line`);
    assert.ok(Math.abs(simX - p.x) < 0.01, `shot ${shots}: predicted ${p.x}, simulated ${simX}`);
  }
  assert.ok(seen.every((n) => n >= 20), `bounce mix ${seen.join('/')}`);
});

test('the defence line stays outside the corner arcs that the prediction ignores', () => {
  assert.ok(DEFENCE_LINE > CORNER_RADIUS, `DEFENCE_LINE ${DEFENCE_LINE} must exceed CORNER_RADIUS ${CORNER_RADIUS}`);
});

test('prediction returns null for a puck moving away from the line', () => {
  assert.equal(predictCrossing(0.5, 1, 0.3, 2, DEFENCE_LINE), null);
  assert.equal(predictCrossing(0.5, 1, 1, 0, DEFENCE_LINE), null);
});

test('the computer moves to the predicted crossing point to defend', () => {
  const ai = createAI('hard', createRng(5));
  const puck = { x: 0.3, y: 1.0, vx: 0.8, vy: -3 };
  const t = aiTarget(ai, 1, puck, { x: 0.5, y: 0.2, vx: 0, vy: 0 }, STEP);
  const p = predictCrossing(puck.x, puck.y, puck.vx, puck.vy, DEFENCE_LINE);
  assert.ok(Math.abs(t.x - p.x) <= ai.params.error + 1e-12);
  assert.equal(t.y, DEFENCE_LINE);
  const bottom = createAI('hard', createRng(5));
  const mirrored = aiTarget(bottom, 0, { ...puck, y: LENGTH - puck.y, vy: -puck.vy }, { x: 0.5, y: LENGTH - 0.2, vx: 0, vy: 0 }, STEP);
  assert.ok(Math.abs(mirrored.x - t.x) < 1e-12 && Math.abs(mirrored.y - (LENGTH - DEFENCE_LINE)) < 1e-12);
});

test('the computer attacks a slow puck in its half', () => {
  const game = createGame({ mode: 'ai', controllers: ['easy', 'medium'], seed: 3, serve: 1 });
  let hit = false;
  for (let i = 0; i < 300 && !hit; i += 1) {
    hit = update(game, 1 / 60).some((e) => e.type === 'hit');
  }
  assert.ok(hit, 'the top computer served the puck');
  assert.ok(game.puck.vy > 0, 'toward the bottom goal');
});

/** Plays one match between two computer levels and returns the final score. */
function playMatch(controllers, seed) {
  const game = createGame({ mode: 'ai', controllers, goalsToWin: 7, seed });
  while (game.phase !== 'over' && game.time < 1800) update(game, 1 / 60);
  return game.score;
}

test('the hard computer beats the easy one in at least 8 of 10 matches to 7', (t) => {
  const results = [];
  let hardWins = 0;
  for (let i = 0; i < 10; i += 1) {
    const hardSide = i % 2;
    const controllers = hardSide === 0 ? ['hard', 'easy'] : ['easy', 'hard'];
    const score = playMatch(controllers, 100 + i);
    const hard = score[hardSide];
    const easy = score[1 - hardSide];
    if (hard === 7) hardWins += 1;
    results.push(`${hard}-${easy}`);
  }
  const message = `hard won ${hardWins}/10 (hard-easy scores: ${results.join(', ')})`;
  t.diagnostic(message);
  assert.ok(hardWins >= 8, message);
});

/**
 * A scripted, human-like bottom player: it re-plans only every 0.22 s, guards
 * loosely in front of its goal and, when the puck is slow in its half, walks
 * behind it and pushes it toward a roughly aimed spot near the far goal.
 */
function scriptedHuman(game, rng, state, dt) {
  state.timer -= dt;
  if (state.timer > 0) return;
  state.timer = 0.22;
  const { puck } = game;
  const mallet = game.players[0].mallet;
  if (puck.y > HALF && Math.hypot(puck.vx, puck.vy) < 2.5) {
    if (state.aimX === null) state.aimX = WIDTH / 2 + (rng() * 2 - 1) * 0.3;
    const len = Math.hypot(state.aimX - puck.x, puck.y);
    const ux = (state.aimX - puck.x) / len;
    const uy = -puck.y / len;
    const behind = (mallet.x - puck.x) * ux + (mallet.y - puck.y) * uy < -0.08;
    if (behind) setTarget(game, 0, puck.x + ux * 0.25, puck.y + uy * 0.25);
    else setTarget(game, 0, puck.x - ux * 0.16 + (mallet.x < puck.x ? -0.1 : 0.1), puck.y - uy * 0.16);
    return;
  }
  state.aimX = null;
  setTarget(game, 0, WIDTH / 2 + (puck.x - WIDTH / 2) * 0.6 + (rng() * 2 - 1) * 0.1, LENGTH - 0.2);
}

/** Plays the scripted human against a computer level; returns [human, computer]. */
function playHuman(level, seed) {
  const game = createGame({ mode: 'ai', controllers: ['human', level], goalsToWin: 7, seed });
  const rng = createRng(seed + 1000);
  const state = { timer: 0, aimX: null };
  while (game.phase !== 'over' && game.time < 900) {
    scriptedHuman(game, rng, state, 1 / 60);
    update(game, 1 / 60);
  }
  return game.score;
}

test('levels feel distinct against a scripted human-like player', (t) => {
  const summary = {};
  for (const level of ['easy', 'medium', 'hard']) {
    const scores = [];
    for (let i = 0; i < 20; i += 1) scores.push(playHuman(level, 500 + i));
    summary[level] = {
      humanWins: scores.filter((s) => s[0] === 7).length,
      humanGoals: scores.reduce((sum, s) => sum + s[0], 0),
      text: scores.map((s) => s.join('-')).join(', '),
    };
    t.diagnostic(`human vs ${level}: won ${summary[level].humanWins}/20 (${summary[level].text})`);
  }
  assert.ok(summary.easy.humanWins >= 12, 'the human-like player usually beats easy');
  assert.ok(summary.medium.humanWins >= 3, 'medium is beatable by the human-like player');
  assert.ok(summary.medium.humanWins < summary.easy.humanWins, 'medium is harder than easy');
  assert.ok(summary.hard.humanGoals < summary.medium.humanGoals, 'hard is harder than medium');
});

test('hard against medium always reaches a result and hard wins most', (t) => {
  const results = [];
  let hardWins = 0;
  for (let i = 0; i < 6; i += 1) {
    const hardSide = i % 2;
    const score = playMatch(hardSide === 0 ? ['hard', 'medium'] : ['medium', 'hard'], 5000 + i);
    assert.ok(Math.max(...score) === 7, `match ${i} finished before the time cap (${score.join('-')})`);
    if (score[hardSide] === 7) hardWins += 1;
    results.push(`${score[hardSide]}-${score[1 - hardSide]}`);
  }
  t.diagnostic(`hard-medium scores: ${results.join(', ')}`);
  assert.ok(hardWins >= 4, `hard won ${hardWins}/6`);
});
