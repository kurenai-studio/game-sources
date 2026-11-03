import { test } from 'node:test';
import assert from 'node:assert/strict';
import { WIDTH, LENGTH, HALF } from '../src/table.js';
import { STEP, MAX_PUCK_SPEED, createMallet, moveMallet, stepPuck, goalScorer } from '../src/physics.js';
import { createRng } from '../src/rng.js';
import { puckOnTable } from '../test-utils/helpers.js';

/** Random puck somewhere in the middle of the table with a random velocity. */
function randomPuck(rng) {
  const a = rng() * Math.PI * 2;
  const s = rng() * MAX_PUCK_SPEED;
  return { x: 0.15 + rng() * 0.7, y: 0.3 + rng() * 1.0, vx: Math.cos(a) * s, vy: Math.sin(a) * s };
}

test('1,000 seeded random 20-second simulations: the puck only leaves through a goal', () => {
  let goals = 0;
  let hits = 0;
  for (let run = 0; run < 1000; run += 1) {
    const rng = createRng(9000 + run);
    let puck = randomPuck(rng);
    const mallets = [createMallet(0.5, LENGTH - 0.2), createMallet(0.5, 0.2)];
    const targets = [{ x: 0.5, y: 1.4 }, { x: 0.5, y: 0.2 }];
    const speeds = [2 + rng() * 6, 2 + rng() * 6];
    for (let i = 0; i < 20 / STEP; i += 1) {
      if (i % 30 === 0) {
        targets[0] = { x: rng() * WIDTH, y: HALF + rng() * HALF };
        targets[1] = { x: rng() * WIDTH, y: rng() * HALF };
      }
      mallets.forEach((m, side) => moveMallet(m, targets[side].x, targets[side].y, speeds[side], side, STEP));
      hits += stepPuck(puck, mallets, STEP).filter((e) => e.type === 'hit').length;
      if (goalScorer(puck) !== null) {
        goals += 1;
        puck = randomPuck(rng);
        continue;
      }
      if (!puckOnTable(puck)) {
        assert.fail(`run ${run} step ${i}: puck left the table at ${puck.x}, ${puck.y}`);
      }
    }
  }
  assert.ok(goals > 100 && hits > 1000, `the simulations were lively (${goals} goals, ${hits} hits)`);
});
