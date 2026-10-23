// Audit migration, DECISIONS.md row D69 (L1 closed as Not Reproduced): a
// bounded random play trace monitoring the score invariant. The original
// trace's 3,738-lock runs had no seed in the original finding and cannot be
// replayed; the audit's replacement runs used seeds 20261017 and 2024, and
// this test runs a bounded, deterministic share of each so CI stays fast.
// Ported from the audit scratch harness l1-trace-harness.mjs; the
// byte-identical original and its checksum live in
// docs/tetris-audit/test-migration-provenance/. Deviations from the original:
// repository-relative imports, node --test assertions instead of the log
// file, the bounded lock cap (the original ran to 3,738 locks), and no
// "outside the repo" comment lines.
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { PlayerAction, GameState } from '../../public/game/gameState.js';
import { TetrominoFactory } from '../../public/game/tetrominoFactory.js';
import { newGame, seededRandom } from '../helpers.js';

const validGains = new Set([0, 100, 300, 500, 800]);

function runTrace(seed, lockTarget) {
  const maxGames = 5000, maxSteps = 2000;
  const random = seededRandom(seed);
  const actions = [PlayerAction.moveLeft, PlayerAction.moveRight, PlayerAction.rotate, PlayerAction.hold];
  let locks = 0, clears = 0, games = 0, violations = 0, faults = 0;
  const gainCounts = {};
  for (let round = 0; round < maxGames && locks < lockTarget; round++) {
    const { game, scheduler } = newGame({ factory: new TetrominoFactory(random) });
    games++;
    const orig = game.lockAndSpawnNext.bind(game);
    game.lockAndSpawnNext = () => {
      const before = game.score;
      orig();
      locks++;
      const gain = game.score - before;
      gainCounts[gain] = (gainCounts[gain] || 0) + 1;
      if (gain > 0) clears++;
    };
    for (let step = 0; step < maxSteps && game.state !== GameState.gameOver && locks < lockTarget; step++) {
      const before = game.score;
      const roll = random();
      if (roll < 0.5) game.handleAction(actions[Math.floor(random() * actions.length)]);
      else if (roll < 0.53) game.handleAction(PlayerAction.drop);
      else if (roll < 0.6) game.softDrop();
      else if (roll < 0.61) { game.togglePause(); game.togglePause(); }
      else scheduler.advance(Math.floor(random() * 400));
      const ok = validGains.has(game.score - before) && game.level === Math.floor(game.score / 1000) + 1
        && game.gameBoard.length === 20 && game.gameBoard.every(r => r.length === 10) && game.nextTetrominos.length === 3
        && (game.state !== GameState.playing || (game.currentTetromino.fits(game.gameBoard) && game.ghostTetromino.fits(game.gameBoard)));
      if (!ok) violations++;
    }
    faults += game.faults.length;
  }
  return { games, locks, clears, gainCounts, violations, faults };
}

for (const seed of [20261017, 2024]) {
  test(`bounded random trace keeps the score invariant, seed ${seed}, 500 locks [D69]`, () => {
    const result = runTrace(seed, 500);
    assert.equal(result.locks, 500, 'the bounded run reaches its lock cap');
    assert.equal(result.violations, 0, `invariant violations in ${JSON.stringify(result.gainCounts)}`);
    assert.equal(result.faults, 0, 'monitor faults');
  });
}
