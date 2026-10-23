// Scratch harness, outside the repo. Read-only use of the game files at /tmp/t (commit 06a43a9).
// For each seed and each clear size (1 to 4 rows): real 7-bag factory, force the current piece to a vertical I,
// pre-fill rows except column 9, drop it, then check the queue, the bag and the saved game after the clear.
import fs from 'node:fs';
import crypto from 'node:crypto';
import { newGame, seededRandom, fillRows, dropVerticalIIntoColumn9, createFakeScheduler, pieceByColor } from '/tmp/t/test/helpers.js';
import { GameManager, createMemoryStorage } from '/tmp/t/public/game/gameManager.js';
import { PlayerAction, GameState } from '/tmp/t/public/game/gameState.js';
import { TetrominoFactory, PieceColors } from '/tmp/t/public/game/tetrominoFactory.js';
const seeds = Number(process.argv[2] || 200);
const out = []; const log = s => out.push(s);
log(`seeds=1..${seeds} clearSizes=1..4 holdBeforeOnEvenSeeds=true node=${process.version}`);
const colors = a => a.map(p => p.color).join(',');
let trials = 0, fails = 0; const failKinds = {};
const bad = (kind, msg) => { fails++; failKinds[kind] = (failKinds[kind] || 0) + 1; if (fails <= 20) log(`FAIL ${kind} ${msg}`); };
for (let seed = 1; seed <= seeds; seed++) for (let lines = 1; lines <= 4; lines++) {
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
  if (trials <= 8) log(`sample ${tag}: queue before ${q.join(',')} after ${qa.join(',')} bagBefore ${bagBefore.join(',')} bagAfter ${bagO} restoredBag ${bagR}`);
}
log(`SUMMARY trials=${trials} failures=${fails} kinds=${JSON.stringify(failKinds)}`);
const text = out.join('\n') + '\n';
fs.writeFileSync('/tmp/l1/raw-clear-after.log', text);
console.log(out.slice(0,1).join(), '\n', out.slice(-8).join('\n'));
console.log(crypto.createHash('sha256').update(text).digest('hex'));
