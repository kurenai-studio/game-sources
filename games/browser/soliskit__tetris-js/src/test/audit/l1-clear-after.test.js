// Audit migration, DECISIONS.md row D69 (L1 closed as Not Reproduced): the
// queue, the 7-bag order and the saved game after one to four line clears.
// Ported from the audit scratch harness l1-clear-after-harness.mjs; the
// byte-identical original and its checksum live in
// docs/tetris-audit/test-migration-provenance/. Deviations from the original:
// repository-relative imports, node --test assertions instead of the log
// file, and no "outside the repo" comment lines.
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { GameManager, createMemoryStorage } from '../../public/game/gameManager.js';
import { PlayerAction, GameState } from '../../public/game/gameState.js';
import { TetrominoFactory, PieceColors } from '../../public/game/tetrominoFactory.js';
import { newGame, seededRandom, fillRows, dropVerticalIIntoColumn9, createFakeScheduler, pieceByColor } from '../helpers.js';

const colors = a => a.map(p => p.color).join(',');

test('queue, bag and save restore after one to four line clears, seeds 1 to 200 [D69]', () => {
  const failures = [];
  const bad = (kind, msg) => failures.push(`${kind} ${msg}`);
  let trials = 0;
  for (let seed = 1; seed <= 200; seed++) for (let lines = 1; lines <= 4; lines++) {
    trials++;
    const storage = createMemoryStorage();
    const factory = new TetrominoFactory(seededRandom(seed));
    const { game } = newGame({ storage, factory });
    if (seed % 2 === 0) game.handleAction(PlayerAction.hold);
    game.currentTetromino = pieceByColor(PieceColors.cyan).spawned(game.columns);
    fillRows(game, Array.from({ length: lines }, (_, i) => 19 - i), [9]);
    const q = game.nextTetrominos.map(p => p.color);
    const bagBefore = factory.bag.map(p => p.color);
    const heldBefore = game.heldTetromino?.color ?? null;
    dropVerticalIIntoColumn9(game);
    const tag = `seed ${seed} lines ${lines}`;
    const gains = [0, 100, 300, 500, 800][lines];
    if (game.score !== gains) bad('score', `${tag} score ${game.score}`);
    if (game.state !== GameState.playing) bad('state', `${tag} state ${game.state}`);
    if (game.currentTetromino.color !== q[0]) bad('current', `${tag} current ${game.currentTetromino.color} expected ${q[0]}`);
    const qa = game.nextTetrominos.map(p => p.color);
    if (qa.length !== 3 || qa[0] !== q[1] || qa[1] !== q[2]) bad('queueShift', `${tag} before ${q} after ${qa}`);
    // the new tail piece is the head of the bag before the clear, or a fresh bag's piece when the bag was empty
    if (bagBefore.length > 0 && qa[2] !== bagBefore[0]) bad('bagHead', `${tag} bag ${bagBefore} tail ${qa[2]}`);
    if (bagBefore.length === 0 && factory.bag.length !== 6) bad('bagRefill', `${tag} bag after ${factory.bag.length}`);
    if (game.heldTetromino?.color !== undefined && game.heldTetromino.color !== heldBefore) bad('held', tag);
    if (game.canHoldTetromino !== true) bad('canHold', tag);
    if (game.faults.length) bad('faults', tag);
    if (game.level !== 1) bad('level', `${tag} level ${game.level}`);
    if (!game.isSessionSaved) { bad('notSaved', tag); continue; }
    // restore the save written by the clear into a new manager with a different random source
    const restored = new GameManager({ scheduler: createFakeScheduler(), storage, factory: new TetrominoFactory(seededRandom(seed + 100000)) });
    restored.handleAction(PlayerAction.continueGame);
    if (restored.state !== GameState.paused) bad('restoreState', `${tag} ${restored.state}`);
    if (JSON.stringify(restored.gameBoard) !== JSON.stringify(game.gameBoard)) bad('restoreBoard', tag);
    if (restored.score !== game.score) bad('restoreScore', tag);
    if (restored.level !== game.level) bad('restoreLevel', tag);
    if (colors(restored.nextTetrominos) !== colors(game.nextTetrominos)) bad('restoreQueue', tag);
    if (restored.currentTetromino.color !== game.currentTetromino.color) bad('restoreCurrent', tag);
    if ((restored.heldTetromino?.color ?? null) !== (game.heldTetromino?.color ?? null)) bad('restoreHeld', tag);
    if (restored.canHoldTetromino !== game.canHoldTetromino) bad('restoreCanHold', tag);
    const bagO = colors(factory.bag), bagR = colors(restored.factory.bag);
    if (bagO !== bagR) bad('restoreBag', `${tag} original ${bagO} restored ${bagR}`);
    // play on: the next draws (up to the saved bag length) match between the original and the restored game
    restored.togglePause();
    const draws = factory.bag.length;
    for (let i = 0; i < draws; i++) {
      game.handleAction(PlayerAction.drop); restored.handleAction(PlayerAction.drop);
      if (game.state !== GameState.playing || restored.state !== GameState.playing) break;
      if (game.nextTetrominos.at(-1).color !== restored.nextTetrominos.at(-1).color) { bad('playOn', `${tag} draw ${i}`); break; }
    }
  }
  assert.equal(trials, 800);
  assert.deepEqual(failures, []);
});
