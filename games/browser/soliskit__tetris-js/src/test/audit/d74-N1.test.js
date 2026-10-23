// Audit migration, DECISIONS.md rows D74 and D75: the settled N1 reading.
// A fault after a confirmed New Game stops the game safely, the fault is
// recorded and reported, the old save stays withdrawn and its stored text is
// kept (the setting S2 was kept by D75). Ported from the audit scratch script
// d74-N1-run.mjs; the byte-identical original and its checksum live in
// docs/tetris-audit/test-migration-provenance/. Deviations from the original:
// repository-relative imports, node --test assertions instead of console
// output, and checks for the recorded fault report, dangling timers and the
// recovery path added from the audit blueprint's N1 checkpoints.
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { GameManager, createMemoryStorage } from '../../public/game/gameManager.js';
import { PlayerAction, GameState } from '../../public/game/gameState.js';
import { createFakeScheduler } from '../helpers.js';

test('a fault after a confirmed New Game stops safely and keeps the old save text [D74, D75]', () => {
  const storage = createMemoryStorage();
  const real = createFakeScheduler();
  let boom = false;
  const scheduler = {
    setTimeout: (cb, ms) => { if (boom) throw new Error('scheduler fault'); return real.setTimeout(cb, ms); },
    clearTimeout: h => real.clearTimeout(h),
    advance: ms => real.advance(ms),
    get pending() { return real.pending; }
  };
  const game = new GameManager({ scheduler, storage });
  game.handleAction(PlayerAction.newGame);
  game.handleAction(PlayerAction.pause);
  assert.equal(game.state, GameState.paused);
  assert.equal(game.isSessionSaved, true);
  const textBefore = storage.getItem('tetris.savedGameSession');
  assert.ok(textBefore.length > 0);

  let reports = 0;
  game.onFault = () => { reports++; };
  boom = true;
  game.handleAction(PlayerAction.newGame); // asks first on the pause screen
  game.handleAction(PlayerAction.newGame); // confirms; the scheduler fault fires here

  assert.equal(game.state, GameState.gameOver, 'the game stops safely at game over');
  assert.equal(game.faults.length, 1, 'the fault is recorded');
  assert.equal(reports, 1, 'the fault is reported once');
  assert.equal(game.isSessionSaved, false, 'the old save stays withdrawn');
  assert.notEqual(storage.getItem('tetris.isSessionSaved'), 'true', 'the stored save flag stays withdrawn');
  assert.equal(storage.getItem('tetris.savedGameSession'), textBefore, 'the stored save text is kept unchanged');
  assert.equal(scheduler.pending, 0, 'no timer is left dangling');

  boom = false;
  game.handleAction(PlayerAction.newGame);
  assert.equal(game.state, GameState.playing, 'a fresh New Game recovers');
});
