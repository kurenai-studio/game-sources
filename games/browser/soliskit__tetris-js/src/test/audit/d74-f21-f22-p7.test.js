// Audit migration, DECISIONS.md row D74 (read-only reproduction attempts for
// F21, F22, N1 and P7) and row D75 (the kept settings S10 and S11). Ported
// from the audit scratch script d74-F21-F22-P7-run-as-first-written.mjs; the
// byte-identical original and its checksum live in
// docs/tetris-audit/test-migration-provenance/. Deviations from the original:
// repository-relative imports, node --test assertions instead of console
// output, and the score-for-level port (level is now derived from the score,
// so the F22 check sets the writable score field instead of the removed level
// setter).
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { GameManager, createMemoryStorage } from '../../public/game/gameManager.js';
import { PlayerAction, GameState } from '../../public/game/gameState.js';
import { createFakeScheduler, newGame } from '../helpers.js';

// F21 is a Confirmed Defect at injected scope (D74): the safety check accepts
// a directly written board that is missing a row or cell. The todo mark keeps
// CI green while the defect waits for its approved fix; the fix's pull request
// removes the mark. The callback runs in full on every push, so the CI log
// shows the defect record on each run.
test('F21: the invariant check flags a board with a missing row or cell [D74]', { todo: 'F21 (D74): Confirmed Defect, injected scope - the invariant check accepts holed boards; the fix PR removes this mark' }, () => {
  for (const [label, mutate] of [
    ['delete a whole row', g => { delete g.gameBoard[5]; }],
    ['row replaced by a sparse 10-slot array', g => { g.gameBoard[3] = new Array(10); }],
    ['one cell hole in a row', g => { delete g.gameBoard[7][3]; }]
  ]) {
    const { game } = newGame();
    mutate(game);
    assert.notEqual(game.findInvariantViolation(), null, label);
  }
});

// F22 closed as Not Reproduced (D74, D75): the requested gravity delay matched
// the formula within the kept S10 tolerance (a billionth of a millisecond) at
// levels 1 to 2,000.
test('F22: the requested gravity delay matches the formula at levels 1 to 2000 [D74, D75]', () => {
  const { game } = newGame();
  for (let level = 1; level <= 2000; level++) {
    game.score = (level - 1) * 1000;
    const got = game.standardDropInterval * 1000;
    const want = Math.max(250, 700 - 20 * (level - 1));
    assert.ok(Math.abs(got - want) <= 1e-9, `level ${level}: got ${got}, want ${want}`);
  }
});

// P7 closed as Rejected (D74, D75): the kept setting S11 judges a hand-edited
// save only as valid or invalid. The recorded outcome stands as the settled
// reading: the edited save loads, and the granted hold is accepted.
test('P7: a hand-edited save granting one more hold is accepted after loading [D74, D75]', () => {
  const storage = createMemoryStorage();
  const scheduler = createFakeScheduler();
  const { game } = newGame({ scheduler, storage });
  game.handleAction(PlayerAction.hold);
  assert.equal(game.canHoldTetromino, false, 'one hold is used');
  game.togglePause();
  game.saveGameSession();

  const key = 'tetris.savedGameSession';
  const data = JSON.parse(storage.getItem(key));
  assert.equal(data.canHoldTetromino, false, 'the used hold is stored');
  data.canHoldTetromino = true;
  storage.setItem(key, JSON.stringify(data));

  const loaded = new GameManager({ scheduler: createFakeScheduler(), storage });
  loaded.loadGameSession();
  assert.equal(loaded.state, GameState.paused);
  assert.equal(loaded.canHoldTetromino, true, 'the hand-edited value loads');
  loaded.togglePause();
  loaded.handleAction(PlayerAction.hold);
  assert.equal(loaded.canHoldTetromino, false, 'the granted hold is accepted');
  assert.equal(loaded.state, GameState.playing);
});
