import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

import { GameManager, createMemoryStorage } from '../public/game/gameManager.js';
import { GameState, PlayerAction } from '../public/game/gameState.js';
import { parseSession, serializeSession } from '../public/game/session.js';
import { PieceColors, TetrominoFactory } from '../public/game/tetrominoFactory.js';
import { createFakeScheduler, newGame, pieceByColor, seededRandom, sequenceFactory } from './helpers.js';

const SIZE = { rows: 20, columns: 10 };

// A realistic save: a few locked blocks, a held piece and a moved piece.
function validSave() {
  const { game } = newGame({ factory: sequenceFactory([PieceColors.purple, PieceColors.yellow, PieceColors.green, PieceColors.red, PieceColors.orange]) });
  game.handleAction(PlayerAction.hold);
  game.handleAction(PlayerAction.moveLeft);
  game.gameBoard[19][0] = { isFilled: true, color: PieceColors.cyan };
  game.gameBoard[19][1] = { isFilled: true, color: PieceColors.red };
  game.score = 1300;
  return { game, data: JSON.parse(serializeSession(game)) };
}

test('a saved game reads back exactly [SAF-1] [STA-4]', () => {
  const { game, data } = validSave();
  const session = parseSession(JSON.stringify(data), SIZE);
  assert.deepEqual(session.gameBoard, game.gameBoard);
  assert.equal(session.score, 1300);
  assert.deepEqual(session.currentTetromino, game.currentTetromino);
  assert.deepEqual(session.nextTetrominos.map(piece => piece.color), game.nextTetrominos.map(piece => piece.color));
  assert.deepEqual(session.heldTetromino, game.heldTetromino);
  assert.equal(session.canHoldTetromino, false);
});

test('the pieces left in the bag are saved by color and read back [SAF-1] [STA-4] [PCE-5]', () => {
  const { game } = newGame({ factory: new TetrominoFactory(seededRandom(3)) });
  const data = JSON.parse(serializeSession(game));
  // A new game deals the current piece and three upcoming ones from a full bag.
  assert.equal(data.bag.length, 3);
  assert.deepEqual(data.bag, game.factory.bag.map(piece => piece.color));
  assert.deepEqual(parseSession(JSON.stringify(data), SIZE).bag, game.factory.bag);
});

test('a piece source without a bag saves an empty one [SAF-1] [STA-4]', () => {
  const { data } = validSave();
  assert.deepEqual(data.bag, []);
  assert.deepEqual(parseSession(JSON.stringify(data), SIZE).bag, []);
});

test('a save without the remaining bag is refused [SAF-1] [STA-6]', () => {
  const { data } = validSave();
  delete data.bag;
  assert.equal(parseSession(JSON.stringify(data), SIZE), null);
});

test('a save without a held piece is valid [SAF-1]', () => {
  const { data } = validSave();
  data.heldTetromino = null;
  assert.equal(parseSession(JSON.stringify(data), SIZE).heldTetromino, null);
});

test('saves leave out the derived level and refuse a stored level [SAF-1] [SCO-2] [STA-6]', () => {
  const { data } = validSave();
  assert.equal('level' in data, false);
  for (const level of [1, 99, null, false]) {
    data.level = level;
    assert.equal(parseSession(JSON.stringify(data), SIZE), null);
  }
});

test('pieces are rebuilt from the built in shapes, not the stored ones [SAF-1] [PCE-2]', () => {
  const { data } = validSave();
  data.currentTetromino.rotations = [[[true, true, true, true], [true, true, true, true]]];
  data.currentTetromino.wallKickData = [];
  const session = parseSession(JSON.stringify(data), SIZE);
  assert.equal(session.currentTetromino.cells.length, 4);
  assert.deepEqual(session.currentTetromino.rotations, pieceByColor(data.currentTetromino.color).rotations);
  assert.deepEqual(session.currentTetromino.wallKickData, pieceByColor(data.currentTetromino.color).wallKickData);
});

test('waiting pieces come back ready to spawn [SAF-1]', () => {
  const { data } = validSave();
  data.nextTetrominos[0].position = { row: 15, column: 8 };
  data.nextTetrominos[0].rotationState = 2;
  const next = parseSession(JSON.stringify(data), SIZE).nextTetrominos[0];
  assert.equal(next.rotationState, 0);
  assert.equal(next.position.row, 0);
});

// Every way a save can be broken. Each must be rejected as a whole.
const corruptions = {
  'text that is not JSON': () => '{"gameBoard": [',
  'nothing saved': () => null,
  'JSON null': () => 'null',
  'a list instead of an object': () => '[]',
  'a number': () => '42',
  'no board': data => { delete data.gameBoard; },
  'a board with 19 rows': data => { data.gameBoard.pop(); },
  'a board row with 11 cells': data => { data.gameBoard[3].push({ isFilled: false, color: null }); },
  'a board row that is not a list': data => { data.gameBoard[3] = 'row'; },
  'a cell that is not an object': data => { data.gameBoard[3][3] = 1; },
  'a cell without isFilled': data => { data.gameBoard[3][3] = { color: null }; },
  'a filled cell with an unknown color': data => { data.gameBoard[19][0].color = '#123456'; },
  'a filled cell without a color': data => { data.gameBoard[19][0].color = null; },
  'an empty cell with a color': data => { data.gameBoard[5][5] = { isFilled: false, color: PieceColors.red }; },
  'a full row that should have been cleared': data => {
    data.gameBoard[18] = data.gameBoard[18].map(() => ({ isFilled: true, color: PieceColors.blue }));
  },
  'a negative score': data => { data.score = -100; },
  'a fractional score': data => { data.score = 150.5; },
  'a score that is not a multiple of 100': data => { data.score = 150; },
  'a score stored as text': data => { data.score = '1300'; },
  'a score too large to be exact': data => { data.score = 2 ** 60; },
  'no current piece': data => { delete data.currentTetromino; },
  'a current piece of an unknown type': data => { data.currentTetromino.color = '#000000'; },
  'a current piece without a position': data => { delete data.currentTetromino.position; },
  'a current piece at a fractional column': data => { data.currentTetromino.position.column = 2.5; },
  'a current piece with rotation 4': data => { data.currentTetromino.rotationState = 4; },
  'a current piece with rotation -1': data => { data.currentTetromino.rotationState = -1; },
  'a current piece with rotation 1.5': data => { data.currentTetromino.rotationState = 1.5; },
  'a current piece with a rotation one past its last': data => {
    data.currentTetromino.rotationState = pieceByColor(data.currentTetromino.color).rotations.length;
  },
  'a current piece outside the board': data => { data.currentTetromino.position = { row: 0, column: -3 }; },
  'a current piece inside locked blocks': data => {
    const { row, column } = data.currentTetromino.position;
    for (let r = row; r < row + 3; r++) for (let c = column; c < column + 3; c++) {
      if (r !== 19 || c > 3) data.gameBoard[r][c] = { isFilled: true, color: PieceColors.blue };
    }
  },
  'no upcoming pieces': data => { delete data.nextTetrominos; },
  'two upcoming pieces': data => { data.nextTetrominos.pop(); },
  'an upcoming piece of an unknown type': data => { data.nextTetrominos[1].color = 'red'; },
  'an upcoming piece that is not an object': data => { data.nextTetrominos[1] = 7; },
  'a held piece of an unknown type': data => { data.heldTetromino.color = '#ffffff'; },
  'a held piece that is a string': data => { data.heldTetromino = 'T'; },
  'a missing held piece field': data => { delete data.heldTetromino; },
  'can hold stored as text': data => { data.canHoldTetromino = 'false'; },
  'a bag that is text': data => { data.bag = 'IOT'; },
  'a bag that is null': data => { data.bag = null; },
  'a bag with an unknown piece': data => { data.bag = [PieceColors.cyan, '#123456']; },
  'a bag with a piece stored as an object': data => { data.bag = [{ color: PieceColors.cyan }]; },
  'a bag with the same piece twice': data => { data.bag = [PieceColors.red, PieceColors.cyan, PieceColors.red]; }
};

for (const [name, corrupt] of Object.entries(corruptions)) {
  test(`a save with ${name} is rejected [SAF-1]`, () => {
    const { data } = validSave();
    const replacement = corrupt(data);
    const text = replacement === undefined ? JSON.stringify(data) : replacement;
    assert.equal(parseSession(text, SIZE), null);
  });
}

// The current fixture continues through the player's storage route.
// The older fixture remains unchanged as evidence that its layout is refused.
const savedGameFormats = [
  ['the current format', 'saved-game-current.json', saved => !('level' in saved)]
];

for (const [format, file, isThatFormat] of savedGameFormats) {
  test(`a saved game in ${format}, as a released version stored it, still continues [STA-6] [STA-4]`, () => {
    const text = fs.readFileSync(new URL(`./fixtures/${file}`, import.meta.url), 'utf8');
    const saved = JSON.parse(text);
    assert.ok(isThatFormat(saved), `${file} is in ${format}`);
    const storage = createMemoryStorage();
    storage.setItem('tetris.savedGameSession', text);
    storage.setItem('tetris.isSessionSaved', 'true');
    const game = new GameManager({ storage, scheduler: createFakeScheduler() });
    assert.equal(game.isSessionSaved, true, 'Continue is offered');
    game.handleAction(PlayerAction.continueGame);
    assert.equal(game.state, GameState.paused);
    assert.equal(game.score, saved.score);
    assert.deepEqual(game.gameBoard, saved.gameBoard);
    assert.equal(game.currentTetromino.color, saved.currentTetromino.color);
    assert.equal(game.currentTetromino.rotationState, saved.currentTetromino.rotationState);
    assert.deepEqual({ ...game.currentTetromino.position }, saved.currentTetromino.position);
    assert.deepEqual(game.nextTetrominos.map(piece => piece.color), saved.nextTetrominos.map(piece => piece.color));
    assert.equal(game.heldTetromino?.color, saved.heldTetromino.color);
    assert.equal(game.canHoldTetromino, saved.canHoldTetromino);
    assert.deepEqual(game.factory.bag.map(piece => piece.color), saved.bag);
  });
}

for (const format of ['a stored level', 'a missing bag', 'a malformed current save']) {
  test(`Continue refuses ${format} without deleting the save or changing the high score [STA-6] [SAF-1] [SCO-3]`, () => {
    const file = format === 'a stored level' ? 'saved-game-with-level.json' : 'saved-game-current.json';
    let text = fs.readFileSync(new URL(`./fixtures/${file}`, import.meta.url), 'utf8');
    if (format === 'a missing bag') {
      const saved = JSON.parse(text);
      delete saved.bag;
      text = JSON.stringify(saved);
    } else if (format === 'a malformed current save') {
      text = '{not json';
    }
    const storage = createMemoryStorage();
    storage.setItem('tetris.savedGameSession', text);
    storage.setItem('tetris.isSessionSaved', 'true');
    storage.setItem('tetris.highScore', '5000');
    const game = new GameManager({ storage, scheduler: createFakeScheduler() });
    const before = { board: game.gameBoard, piece: game.currentTetromino, bag: [...game.factory.bag] };
    game.handleAction(PlayerAction.continueGame);
    assert.equal(game.state, GameState.gameOver);
    assert.equal(game.isSessionSaved, false);
    assert.equal(storage.getItem('tetris.isSessionSaved'), 'false');
    assert.equal(storage.getItem('tetris.savedGameSession'), text);
    assert.equal(storage.getItem('tetris.highScore'), '5000');
    assert.equal(game.gameBoard, before.board);
    assert.equal(game.currentTetromino, before.piece);
    assert.deepEqual(game.factory.bag, before.bag);
    assert.equal(game.score, 0);
  });
}

for (const source of ['unreadable save', 'missing save', 'unavailable save']) {
  test(`Continue with an ${source} does not write to storage [SAF-2] [STA-4]`, () => {
    const storage = createMemoryStorage();
    if (source !== 'unavailable save') storage.setItem('tetris.isSessionSaved', 'true');
    const read = storage.getItem;
    storage.getItem = key => {
      if (source === 'unreadable save' && key === 'tetris.savedGameSession') throw new Error('SecurityError');
      return read(key);
    };
    const writes = [];
    storage.setItem = (key, value) => { writes.push([key, value]); };
    const game = new GameManager({ storage, scheduler: createFakeScheduler() });
    game.handleAction(PlayerAction.continueGame);
    assert.equal(game.state, GameState.gameOver);
    assert.deepEqual(writes, []);
  });
}

test('Continue leaves a valid save alone when its availability flag is false [STA-4] [SAF-2]', () => {
  const storage = createMemoryStorage();
  const text = fs.readFileSync(new URL('./fixtures/saved-game-current.json', import.meta.url), 'utf8');
  storage.setItem('tetris.savedGameSession', text);
  storage.setItem('tetris.isSessionSaved', 'false');
  const read = storage.getItem;
  const reads = [];
  const writes = [];
  storage.getItem = key => { reads.push(key); return read(key); };
  storage.setItem = (key, value) => { writes.push([key, value]); };
  const game = new GameManager({ storage, scheduler: createFakeScheduler() });
  const before = { board: game.gameBoard, piece: game.currentTetromino, bag: [...game.factory.bag] };
  game.handleAction(PlayerAction.continueGame);
  assert.equal(game.state, GameState.gameOver);
  assert.equal(game.gameBoard, before.board);
  assert.equal(game.currentTetromino, before.piece);
  assert.deepEqual(game.factory.bag, before.bag);
  assert.deepEqual(reads, ['tetris.isSessionSaved']);
  assert.deepEqual(writes, []);
  assert.equal(read('tetris.savedGameSession'), text);
});

test('refusing an old save attempts withdrawal even when the write fails [STA-6] [SAF-2]', () => {
  const storage = createMemoryStorage();
  const text = fs.readFileSync(new URL('./fixtures/saved-game-with-level.json', import.meta.url), 'utf8');
  storage.setItem('tetris.savedGameSession', text);
  storage.setItem('tetris.isSessionSaved', 'true');
  const writes = [];
  storage.setItem = (key, value) => {
    writes.push([key, value]);
    throw new Error('QuotaExceededError');
  };
  const game = new GameManager({ storage, scheduler: createFakeScheduler() });
  game.handleAction(PlayerAction.continueGame);
  assert.equal(game.state, GameState.gameOver);
  assert.deepEqual(writes, [['tetris.isSessionSaved', 'false']]);
  assert.equal(storage.getItem('tetris.savedGameSession'), text);
  assert.equal(storage.getItem('tetris.isSessionSaved'), 'true');
});

test('a saved game stored under the names used before the game had names of its own is not read [STA-6] [APP-6]', () => {
  const storage = createMemoryStorage();
  storage.setItem('savedGameSession', fs.readFileSync(new URL('./fixtures/saved-game-current.json', import.meta.url), 'utf8'));
  storage.setItem('isSessionSaved', 'true');
  const game = new GameManager({ storage, scheduler: createFakeScheduler() });
  assert.equal(game.isSessionSaved, false, 'Continue is not offered');
  game.handleAction(PlayerAction.continueGame);
  assert.equal(game.state, GameState.gameOver);
});
