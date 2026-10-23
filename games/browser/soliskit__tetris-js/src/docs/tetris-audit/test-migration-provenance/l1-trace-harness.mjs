// Scratch harness, outside the repo. Read-only use of the game files at /tmp/t (commit 06a43a9).
import fs from 'node:fs';
import crypto from 'node:crypto';
import { newGame, seededRandom } from '/tmp/t/test/helpers.js';
import { PlayerAction, GameState } from '/tmp/t/public/game/gameState.js';
import { TetrominoFactory } from '/tmp/t/public/game/tetrominoFactory.js';
const seed = Number(process.argv[2]);
const lockTarget = Number(process.argv[3]);
const maxGames = 5000, maxSteps = 2000;
const out = [];
const log = s => out.push(s);
log(`seed=${seed} lockTarget=${lockTarget} maxGames=${maxGames} maxSteps=${maxSteps} node=${process.version}`);
const random = seededRandom(seed);
const actions = [PlayerAction.moveLeft, PlayerAction.moveRight, PlayerAction.rotate, PlayerAction.hold];
const validGains = new Set([0, 100, 300, 500, 800]);
let locks = 0, clears = 0, games = 0, violations = 0, faults = 0;
const gainCounts = {};
for (let round = 0; round < maxGames && locks < lockTarget; round++) {
  const { game, scheduler } = newGame({ factory: new TetrominoFactory(random) });
  games++;
  const orig = game.lockAndSpawnNext.bind(game);
  game.lockAndSpawnNext = () => {
    const before = game.score, lvl = game.level;
    orig();
    locks++;
    const gain = game.score - before;
    gainCounts[gain] = (gainCounts[gain] || 0) + 1;
    if (gain > 0) clears++;
    log(`lock ${locks} game ${round} gain ${gain} score ${game.score} level ${game.level} (was ${lvl}) state ${game.state}`);
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
    if (!ok) { violations++; log(`VIOLATION game ${round} step ${step}`); }
  }
  faults += game.faults.length;
}
log(`SUMMARY games=${games} locks=${locks} lineClears=${clears} gainCounts=${JSON.stringify(gainCounts)} invariantViolations=${violations} monitorFaults=${faults}`);
const text = out.join('\n') + '\n';
const name = `/tmp/l1/raw-seed${seed}.log`;
fs.writeFileSync(name, text);
console.log(out[0]); console.log(out[out.length-1]);
console.log(name, crypto.createHash('sha256').update(text).digest('hex'));
