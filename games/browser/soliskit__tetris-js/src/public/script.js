// Browser UI: port of ContentView.swift, GameBoardView.swift,
// TetrominoPreview.swift and ButtonView.swift. All game rules live in ./game.

import { GameManager } from './game/gameManager.js';
import { GameState, PlayerAction } from './game/gameState.js';
import { InputController } from './game/inputController.js';

/** @typedef {import('./game/tetromino.js').Tetromino} Tetromino */
/** @typedef {import('./game/position.js').Position} Position */
/** @typedef {{ context: CanvasRenderingContext2D, width: number, height: number }} CanvasSize */

const internalErrorMessage = 'The game stopped because of an internal error.';
let engineFaultNotice = false;
const gameManager = new GameManager({ onChange: engineChanged, onFault: reportEngineFault });

// The guard finishes the operation and its checks before this callback.
// A fault stays over (or never reaches this callback), so only a completed
// New Game or accepted Continue clears the cause on the default page route.
function engineChanged() {
  if (gameManager.state !== GameState.gameOver) engineFaultNotice = false;
  requestDraw();
}

/** @param {import('./game/gameManager.js').Fault} fault */
function reportEngineFault(fault) {
  // Neither a refused draw request nor a refused console report may suppress
  // the other attempt. The manager separately keeps its existing fault record.
  try {
    engineFaultNotice = true;
    requestDraw();
  } catch {
    // A later draw can still present the retained cause.
  }
  try {
    console.error('Tetris stopped safely:', fault.reason, fault.error ?? '');
  } catch {
    // Reporting must not change the stopped game.
  }
}

// Every id below exists in index.html; test/staticFiles.test.js checks that.
/** @param {string} id */
const element = id => /** @type {HTMLElement} */ (document.getElementById(id));
/** @param {string} id */
const canvasElement = id => /** @type {HTMLCanvasElement} */ (document.getElementById(id));

const boardCanvas = canvasElement('tetris');
const heldCanvas = canvasElement('heldPreview');
const nextCanvases = ['next0', 'next1', 'next2'].map(canvasElement);
const scoreLabel = element('score');
const highScoreLabel = element('highScore');
const menuControls = element('menuControls');
const gameOverMessage = element('gameOverMessage');
const announcer = element('announcer');
const newGameDialog = /** @type {HTMLDialogElement} */ (element('newGameDialog'));
const continueButton = element('continueGameButton');
const keyHint = element('keyHint');
const playPauseButton = element('playPauseButton');
const canvases = [boardCanvas, heldCanvas, ...nextCanvases];

// Each canvas gets its context as soon as the page starts. The first request
// fixes a canvas's color space, so nothing else can get in first and make it
// sRGB. A canvas always has a 2d context unless another kind was requested
// first.
/** @type {Map<HTMLCanvasElement, CanvasRenderingContext2D>} */
const contexts = new Map(canvases.map(canvas => [canvas, /** @type {CanvasRenderingContext2D} */ (canvas.getContext('2d', { colorSpace: 'display-p3' }))]));

// The contexts that really draw in Display P3. A browser without Display P3
// canvases gives sRGB ones, where P3 colors would be clipped, so pieces keep
// their usual colors there.
/** @type {WeakSet<CanvasRenderingContext2D>} */
const p3Contexts = new WeakSet([...contexts.values()].filter(context => context.getImageData(0, 0, 1, 1).colorSpace === 'display-p3'));

// Canvas sizes come from a ResizeObserver instead of measuring every frame.
// Maps each canvas to its size in CSS pixels once sized.
/** @type {Map<HTMLCanvasElement, CanvasSize>} */
const canvasSizes = new Map();

/**
 * @param {HTMLCanvasElement} canvas
 * @returns {CanvasSize} Only called for canvases that have been sized.
 */
const sizeOf = canvas => /** @type {CanvasSize} */ (canvasSizes.get(canvas));

/**
 * @param {HTMLCanvasElement} canvas
 * @param {number} width
 * @param {number} height
 */
function sizeCanvas(canvas, width, height) {
  const ratio = window.devicePixelRatio;
  canvas.width = Math.round(width * ratio);
  canvas.height = Math.round(height * ratio);
  // Resizing resets the context, so the scale is set again here.
  const context = /** @type {CanvasRenderingContext2D} */ (contexts.get(canvas));
  context.setTransform(ratio, 0, 0, ratio, 0, 0);
  canvasSizes.set(canvas, { context, width, height });
}

// The piece colors stay as sRGB hex in the engine, because saved games
// identify pieces by them. Drawing the same values in the wider Display P3
// gamut makes them more vivid on iPhone screens. Maps hex to P3 color.
/** @type {Map<string, string>} */
const vividColors = new Map();

/**
 * @param {CanvasRenderingContext2D} context The context the color is for.
 * @param {string} hex A piece color, #RRGGBB.
 */
function vivid(context, hex) {
  if (!p3Contexts.has(context)) return hex;
  let color = vividColors.get(hex);
  if (!color) {
    const [red, green, blue] = [1, 3, 5].map(start => parseInt(hex.slice(start, start + 2), 16) / 255);
    color = `color(display-p3 ${red} ${green} ${blue})`;
    vividColors.set(hex, color);
  }
  return color;
}

/**
 * @param {CanvasRenderingContext2D} context
 * @param {number} x
 * @param {number} y
 * @param {number} size
 * @param {number} radius
 */
function roundedRect(context, x, y, size, radius) {
  context.beginPath();
  context.roundRect(x, y, size, size, radius);
}

/**
 * @param {CanvasRenderingContext2D} context
 * @param {number} column
 * @param {number} row
 * @param {number} size
 * @param {string} color
 */
function drawBlock(context, column, row, size, color) {
  context.fillStyle = vivid(context, color);
  roundedRect(context, size * column + 0.5, size * row + 0.5, size - 1, 3);
  context.fill();
}

/**
 * @param {CanvasRenderingContext2D} context
 * @param {number} column
 * @param {number} row
 * @param {number} size
 * @param {string} color
 */
function drawGhostBlock(context, column, row, size, color) {
  context.save();
  context.globalAlpha = 0.5;
  context.strokeStyle = vivid(context, color);
  context.lineWidth = 1.5;
  roundedRect(context, size * column + 1, size * row + 1, size - 2, 3);
  context.stroke();
  context.restore();
}

// At game over only the locked blocks show: a new game deals pieces of its
// own, and a piece that had no room to appear would cover the stack.
const showsPieces = () => gameManager.state !== GameState.gameOver;

function drawBoard() {
  const { context, width, height } = sizeOf(boardCanvas);
  const { rows, columns } = gameManager;
  const blockSize = Math.min(width / columns, height / rows);
  context.clearRect(0, 0, width, height);

  context.strokeStyle = 'rgba(255, 255, 255, 0.15)';
  context.lineWidth = 0.5;
  context.beginPath();
  for (let column = 1; column < columns; column++) {
    context.moveTo(blockSize * column, 0);
    context.lineTo(blockSize * column, blockSize * rows);
  }
  for (let row = 1; row < rows; row++) {
    context.moveTo(0, blockSize * row);
    context.lineTo(blockSize * columns, blockSize * row);
  }
  context.stroke();

  for (let row = 0; row < rows; row++) {
    for (let column = 0; column < columns; column++) {
      const cell = gameManager.gameBoard[row][column];
      // A filled cell always has a piece color.
      if (cell.isFilled) drawBlock(context, column, row, blockSize, /** @type {string} */ (cell.color));
    }
  }

  if (!showsPieces()) return;
  const tetromino = gameManager.currentTetromino;
  for (const cell of gameManager.ghostTetromino.cells) {
    drawGhostBlock(context, cell.column, cell.row, blockSize, tetromino.color);
  }
  for (const cell of tetromino.cells) {
    drawBlock(context, cell.column, cell.row, blockSize, tetromino.color);
  }
}

/**
 * @param {HTMLCanvasElement} canvas
 * @param {Tetromino | null} tetromino
 */
function drawPreview(canvas, tetromino) {
  const { context, width, height } = sizeOf(canvas);
  context.clearRect(0, 0, width, height);
  if (!tetromino) return;
  const gridSize = 6;
  const blockSize = Math.min(width / gridSize, height / gridSize);
  const shape = tetromino.shape;
  const xOffset = (width - shape[0].length * blockSize) / 2;
  const yOffset = (height - shape.length * blockSize) / 2;
  context.save();
  context.translate(xOffset, yOffset);
  shape.forEach((blocks, row) => {
    blocks.forEach((filled, column) => {
      if (filled) drawBlock(context, column, row, blockSize, tetromino.color);
    });
  });
  context.restore();
}

// Game Over shows once a game ends, until the next one starts. Not when the
// page opens, where no game has been played yet.
let lastState = gameManager.state;
let gameEnded = false;

function syncControls() {
  const highScore = gameManager.highScore;
  const isSessionSaved = gameManager.isSessionSaved;
  const state = gameManager.state;
  const isGameOver = state === GameState.gameOver;
  const paused = state === GameState.paused;
  if (state !== lastState) gameEnded = isGameOver;
  lastState = state;
  scoreLabel.textContent = `Score: ${gameManager.score}`;
  highScoreLabel.textContent = `High Score: ${highScore}`;
  const message = engineFaultNotice ? internalErrorMessage : gameEnded ? 'Game Over' : '';
  gameOverMessage.hidden = !message;
  gameOverMessage.textContent = message;
  gameOverMessage.classList.toggle('engine-fault', engineFaultNotice);
  // Only update changed text, so repeated checks do not repeat announcements.
  if (announcer.textContent !== message) announcer.textContent = message;
  // New Game also gives up a paused game, once confirmed; Continue only
  // follows game over.
  menuControls.hidden = !isGameOver && !paused;
  const canContinue = isGameOver && isSessionSaved;
  continueButton.hidden = !canContinue;
  keyHint.textContent = paused ? 'Return: New Game    P: Resume' : canContinue ? 'Return: New Game    C: Continue' : 'Return: New Game';
  // The engine asks before New Game gives up a paused game, and this dialog
  // shows the question.
  if (gameManager.isConfirmingNewGame !== newGameDialog.open) {
    if (gameManager.isConfirmingNewGame) newGameDialog.showModal();
    else newGameDialog.close();
  }
  playPauseButton.hidden = isGameOver;
  playPauseButton.innerHTML = paused ? '&#9654;' : '&#10074;&#10074;';
  playPauseButton.setAttribute('aria-label', paused ? 'Resume' : 'Pause');
  setWakeLock(gameManager.state === GameState.playing);
}

// Keeps the screen on while playing, so iOS does not dim and lock it while
// the player thinks. Released at pause and game over, so an idle game never
// keeps the screen awake. If the lock is unsupported or refused (Low Power
// Mode, for example), the game plays on without it.
let wakeLockWanted = false;
/** @type {WakeLockSentinel | null} */
let wakeLock = null;

/** @param {boolean} wanted */
function setWakeLock(wanted) {
  if (wanted === wakeLockWanted || !('wakeLock' in navigator)) return;
  wakeLockWanted = wanted;
  if (wanted) {
    requestWakeLock();
    return;
  }
  // Forgotten before it is let go, so its release does not ask again.
  const lock = wakeLock;
  wakeLock = null;
  lock?.release();
}

function requestWakeLock() {
  navigator.wakeLock.request('screen').then(sentinel => {
    // Play may have stopped, or a newer request won, while this one waited.
    if (!wakeLockWanted || wakeLock) {
      sentinel.release();
      return;
    }
    wakeLock = sentinel;
    // The system can take the lock back during play (when the battery runs
    // low, for example), so ask for it again.
    sentinel.addEventListener('release', () => {
      if (wakeLock !== sentinel) return;
      wakeLock = null;
      requestWakeLock();
    });
  }, () => {});
}

let lastSnapshot = '';

// What each canvas showed when it was last drawn, so frames where nothing
// moved skip drawing. The engine counts every change to the locked blocks in
// boardVersion, and makes a new position object whenever the piece moves, so
// comparing these is enough. Game over hides the pieces without changing
// them, so that is noted too.
/** @type {{ piece?: Tetromino, position?: Position, rotationState?: number, boardVersion?: number, showsPieces?: boolean }} */
let drawnBoard = {};
/** @type {Map<HTMLCanvasElement, Tetromino | null>} */
const drawnPreviews = new Map();

function boardChanged() {
  const piece = gameManager.currentTetromino;
  return piece !== drawnBoard.piece
    || piece.position !== drawnBoard.position
    || piece.rotationState !== drawnBoard.rotationState
    || gameManager.boardVersion !== drawnBoard.boardVersion
    || showsPieces() !== drawnBoard.showsPieces;
}

function drawIfChanged() {
  if (canvasSizes.has(boardCanvas) && boardChanged()) {
    drawBoard();
    const piece = gameManager.currentTetromino;
    drawnBoard = {
      piece,
      position: piece.position,
      rotationState: piece.rotationState,
      boardVersion: gameManager.boardVersion,
      showsPieces: showsPieces()
    };
  }
  const pieces = showsPieces();
  /** @type {Array<[HTMLCanvasElement, Tetromino | null]>} */
  const previews = [[heldCanvas, pieces ? gameManager.heldTetromino : null]];
  nextCanvases.forEach((canvas, index) => previews.push([canvas, pieces ? gameManager.nextTetrominos[index] : null]));
  for (const [canvas, tetromino] of previews) {
    if (!canvasSizes.has(canvas)) continue;
    if (drawnPreviews.has(canvas) && drawnPreviews.get(canvas) === tetromino) continue;
    drawPreview(canvas, tetromino);
    drawnPreviews.set(canvas, tetromino);
  }
  const snapshot = `${gameManager.state}|${gameManager.score}|${gameManager.isSessionSaved}|${gameManager.isConfirmingNewGame}|${engineFaultNotice}`;
  if (snapshot !== lastSnapshot) {
    lastSnapshot = snapshot;
    syncControls();
  }
}

function redrawAll() {
  drawnBoard = {};
  drawnPreviews.clear();
  drawIfChanged();
}

// An error while drawing is reported once and everything is redrawn on the
// next frame, so drawing always recovers.
let renderErrorReported = false;

/** @param {() => void} draw */
function drawSafely(draw) {
  try {
    draw();
  } catch (error) {
    drawnBoard = {};
    drawnPreviews.clear();
    lastSnapshot = '';
    if (!renderErrorReported) console.error('Tetris drawing error, retrying next frame:', error);
    renderErrorReported = true;
    requestDraw();
  }
}

// Draws only when something may have changed: the engine reports every
// action and timer, and the page asks after storage changes and drawing
// errors. In between the page sleeps instead of waking up every frame.
let drawRequested = false;

function requestDraw() {
  if (drawRequested) return;
  drawRequested = true;
  try {
    requestAnimationFrame(() => {
      drawRequested = false;
      drawSafely(drawIfChanged);
    });
  } catch (error) {
    drawRequested = false;
    throw error;
  }
}

// Resizing a canvas clears it, so redraw in the same frame to avoid a flash.
const resizeObserver = new ResizeObserver(entries => {
  for (const entry of entries) {
    const { inlineSize, blockSize } = entry.contentBoxSize[0];
    sizeCanvas(/** @type {HTMLCanvasElement} */ (entry.target), inlineSize, blockSize);
  }
  drawSafely(redrawAll);
});
canvases.forEach(canvas => resizeObserver.observe(canvas));

// Moving the window to a screen with a different pixel density does not
// resize anything in CSS pixels, so rebuild the canvases for the new density.
function watchPixelRatio() {
  matchMedia(`(resolution: ${window.devicePixelRatio}dppx)`).addEventListener('change', () => {
    for (const [canvas, { width, height }] of canvasSizes) sizeCanvas(canvas, width, height);
    drawSafely(redrawAll);
    watchPixelRatio();
  }, { once: true });
}
watchPixelRatio();

// Touch and mouse gestures, ported from the DragGesture in ContentView.swift:
// drag sideways to move by whole cells, drag down to soft drop, tap to rotate.
// The piece always stays on the grid and in step with the finger, and a
// gesture only ever controls the piece that was falling when it started.

// Fingers wobble a few pixels during a tap, so allow that before a touch
// counts as a drag.
const TAP_SLOP_PX = 10;

const drag = {
  /** @type {number | null} */
  pointerId: null,
  /** @type {Tetromino | null} The piece this gesture controls. */
  piece: null,
  startX: 0,
  startY: 0,
  moved: false,
  cellOffset: 0,
  rowOffset: 0,
  blocked: 0
};

function resetDragState() {
  drag.pointerId = null;
  drag.piece = null;
  drag.moved = false;
  drag.cellOffset = 0;
  drag.rowOffset = 0;
  drag.blocked = 0;
}

function cellWidth() {
  return sizeOf(boardCanvas).width / gameManager.columns;
}

// Returns whether the piece actually moved one column in that direction.
/**
 * @param {Tetromino} piece
 * @param {number} step 1 for right, -1 for left.
 */
function tryMove(piece, step) {
  const column = piece.position.column;
  gameManager.handleAction(step > 0 ? PlayerAction.moveRight : PlayerAction.moveLeft);
  return piece.position.column !== column;
}

boardCanvas.addEventListener('pointerdown', event => {
  resetDragState();
  drag.pointerId = event.pointerId;
  drag.piece = gameManager.currentTetromino;
  drag.startX = event.clientX;
  drag.startY = event.clientY;
  boardCanvas.setPointerCapture(event.pointerId);
});

boardCanvas.addEventListener('pointermove', event => {
  if (event.pointerId !== drag.pointerId || !canvasSizes.has(boardCanvas)) return;
  // The piece locked or was held mid gesture: ignore the rest of this drag
  // rather than moving or dropping the next piece.
  if (gameManager.currentTetromino !== drag.piece) return;
  const piece = gameManager.currentTetromino;
  const dx = event.clientX - drag.startX;
  const dy = event.clientY - drag.startY;
  if (!drag.moved && Math.hypot(dx, dy) <= TAP_SLOP_PX) return;
  drag.moved = true;
  const width = cellWidth();

  let offset = (event.clientX - drag.startX) / width;
  if (drag.blocked !== 0 && Math.sign(offset - drag.cellOffset) === drag.blocked) {
    // Still pushing against a wall or block. Slide in if a gap has opened,
    // and keep the anchor under the finger so pushing does not bank moves
    // and moving back responds after half a cell.
    if (tryMove(piece, drag.blocked)) {
      drag.cellOffset += drag.blocked;
      drag.blocked = 0;
    }
    drag.startX = event.clientX - drag.cellOffset * width;
    offset = drag.cellOffset;
  }

  // One cell of movement per cell dragged, starting at half a cell.
  const targetOffset = Math.round(offset);
  while (drag.cellOffset !== targetOffset) {
    const step = Math.sign(targetOffset - drag.cellOffset);
    if (!tryMove(piece, step)) {
      drag.blocked = step;
      drag.startX = event.clientX - drag.cellOffset * width;
      break;
    }
    drag.cellOffset += step;
    drag.blocked = 0;
  }

  const newRowOffset = Math.max(0, Math.trunc(dy / width));
  while (drag.rowOffset < newRowOffset && gameManager.currentTetromino === drag.piece) {
    gameManager.softDrop();
    drag.rowOffset += 1;
  }
});

/** @param {PointerEvent} event */
function endDrag(event) {
  if (event.pointerId !== drag.pointerId) return;
  const isTap = !drag.moved && event.type === 'pointerup' && gameManager.currentTetromino === drag.piece;
  if (isTap) gameManager.handleAction(PlayerAction.rotate);
  resetDragState();
}

boardCanvas.addEventListener('pointerup', endDrag);
boardCanvas.addEventListener('pointercancel', endDrag);

heldCanvas.addEventListener('click', () => gameManager.handleAction(PlayerAction.hold));
// The hold box is a button to keyboards and screen readers too. A click
// leaves focus where it was, so only the keyboard gives the hold box focus,
// and only then do Enter and Space hold instead of their game actions.
// (Checking :focus-visible would not do: any key press makes it match.)
// Hold only works while playing, so otherwise they keep their game actions.
heldCanvas.addEventListener('mousedown', event => event.preventDefault());
heldCanvas.addEventListener('keydown', event => {
  if ((event.key !== 'Enter' && event.key !== ' ') || gameManager.state !== GameState.playing) return;
  event.preventDefault();
  event.stopPropagation();
  gameManager.handleAction(PlayerAction.hold);
});
element('newGameButton').addEventListener('click', () => gameManager.handleAction(PlayerAction.newGame));
// The New Game question. Every answer goes straight to the engine, and the
// dialog closes once the engine stops asking, so the very next key already
// finds the question answered; the dialog's close event comes too late for
// that. Cancel, a tap on the dimmed page around the dialog, and the browser's
// close requests (such as Android's back gesture) answer no, and so does
// Escape, through the input controller. Listening for clicks on the dialog
// also keeps Safari from taking quick taps there as a double tap to zoom.
const cancelNewGameButton = element('cancelNewGameButton');
const confirmNewGameButton = element('confirmNewGameButton');
confirmNewGameButton.addEventListener('click', () => gameManager.handleAction(PlayerAction.newGame));
cancelNewGameButton.addEventListener('click', () => gameManager.cancelNewGame());
// In the order they appear.
const questionButtons = [cancelNewGameButton, confirmNewGameButton];
// The selected button is the focused one, so Tab and clicks stay in step with
// a controller and the arrow keys, which move the focus; A presses it, as
// Enter does. With none selected, a move selects Cancel, the safe answer.
new InputController(gameManager, {
  move: step => {
    const index = questionButtons.indexOf(/** @type {HTMLElement} */ (document.activeElement));
    questionButtons[Math.max(0, Math.min(questionButtons.length - 1, index + step))].focus();
  },
  press: () => questionButtons.find(button => button === document.activeElement)?.click()
});
newGameDialog.addEventListener('click', event => {
  if (event.target === newGameDialog) gameManager.cancelNewGame();
});
newGameDialog.addEventListener('cancel', event => {
  event.preventDefault();
  gameManager.cancelNewGame();
});
continueButton.addEventListener('click', () => gameManager.handleAction(PlayerAction.continueGame));
playPauseButton.addEventListener('click', () => gameManager.togglePause());

// Matches the scenePhase handler: pause when the page is hidden.
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') return;
  resetDragState();
  if (gameManager.state === GameState.playing) gameManager.handleAction(PlayerAction.pause);
});

// Another tab saving or ending a game changes whether this one can continue,
// and a high score set there changes the one shown here.
window.addEventListener('storage', () => {
  gameManager.storageChanged();
  lastSnapshot = '';
  requestDraw();
});

requestDraw();

// Safari ignores user-scalable=no in the browser, and zooms in on two quick
// taps even with touch-action none, which players do to turn pieces. Zoomed
// in, the board fills the screen and the rest of the game is cut off. So the
// page blocks Safari's zoom gestures itself, unless Safari has zoomed in
// anyway: then they are let through, so the player can always zoom back out.
// Safari keeps the zoom when the page reloads, so it is checked at the start
// too. Every supported browser has a visual viewport.
const viewport = /** @type {VisualViewport} */ (window.visualViewport);
const zoomedIn = () => viewport.scale > 1;
const watchZoom = () => document.documentElement.classList.toggle('zoomed', zoomedIn());
viewport.addEventListener('resize', watchZoom);
watchZoom();

// Cancelling Safari's pinch gestures stops pinch zoom.
for (const type of ['gesturestart', 'gesturechange']) {
  document.addEventListener(type, event => {
    if (!zoomedIn()) event.preventDefault();
  });
}

// Safari also zooms on a double tap that lands on something it does not take
// to be clickable, and touch-action cannot stop that. Only click and mouse
// button listeners count, not the pointer listeners the board reads taps
// with, so the board listens for clicks too: Safari then handles quick taps
// there as clicks, which never zoom. The click does nothing. Safari sends no
// pointer events with it, so a tap still turns the piece only once.
boardCanvas.addEventListener('click', () => {});

// Installable app: cache the game so it also works offline.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('sw.js').catch(() => {});
}
