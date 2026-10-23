// Port of GameManager.swift. Swift Tasks become setTimeout handles; the
// scheduler, storage and piece factory are injectable so the engine can run
// in Node tests without a browser.
//
// Fault containment: every way into the engine (player actions, soft drop
// and timers) runs through guard(). If an operation throws, or leaves the
// game breaking one of its invariants, the engine stops in a safe state
// (game over, no timers), reports the fault and keeps the last good save.

import { below, position } from './position.js';
import { GameState, PlayerAction, UPCOMING_COUNT, createBoard } from './gameState.js';
import { parseSession, serializeSession } from './session.js';
import { isValidFallingPiece, isValidPieceList } from './tetromino.js';
import { TetrominoFactory } from './tetrominoFactory.js';

/** @typedef {import('./gameState.js').Board} Board */
/** @typedef {import('./gameState.js').GameStateValue} GameStateValue */
/** @typedef {import('./gameState.js').PlayerActionValue} PlayerActionValue */
/** @typedef {import('./tetromino.js').Tetromino} Tetromino */
/** @typedef {{ getItem(key: string): string | null, setItem(key: string, value: string): void }} KeyValueStorage */
/** @typedef {{ setTimeout(callback: () => void, ms: number): unknown, clearTimeout(handle: unknown): void }} Scheduler */
/** @typedef {{ generate(): Tetromino, bag?: Tetromino[], resetBag?(pieces?: Tetromino[]): void }} PieceSource */
/** @typedef {{ reason: string, error?: unknown }} Fault */
/**
 * @typedef {object} GameManagerOptions
 * @property {KeyValueStorage} [storage] Defaults to localStorage, or memory when unavailable.
 * @property {Scheduler} [scheduler] Defaults to the browser timers.
 * @property {PieceSource} [factory] Defaults to a 7 bag.
 * @property {(fault: Fault) => void} [onFault] Defaults to console.error.
 * @property {() => void} [onChange] Called after every action and timer, so the page knows to draw.
 */

// Stored under names of the game's own: GitHub Pages serves every project of
// an account from one origin, and they all share its localStorage.
const HIGH_SCORE_KEY = 'tetris.highScore';
const IS_SESSION_SAVED_KEY = 'tetris.isSessionSaved';
const SAVED_SESSION_KEY = 'tetris.savedGameSession';
/** @type {Record<number, number>} */
const LINE_SCORES = { 1: 100, 2: 300, 3: 500, 4: 800 };
const MAX_FAULTS_KEPT = 20;

export function createMemoryStorage() {
  /** @type {Map<string, string>} */
  const values = new Map();
  return {
    /** @param {string} key */
    getItem: key => values.get(key) ?? null,
    /** @param {string} key @param {unknown} value */
    setItem: (key, value) => { values.set(key, String(value)); },
    /** @param {string} key */
    removeItem: key => { values.delete(key); }
  };
}

/** @returns {KeyValueStorage} */
function defaultStorage() {
  try {
    if (globalThis.localStorage) return globalThis.localStorage;
  } catch {
    // Access can throw in private mode or sandboxed frames.
  }
  return createMemoryStorage();
}

/** @type {Scheduler} */
const defaultScheduler = {
  setTimeout: (callback, ms) => globalThis.setTimeout(callback, ms),
  clearTimeout: handle => globalThis.clearTimeout(/** @type {number} */ (handle))
};

/** @param {Fault} fault */
function reportToConsole(fault) {
  console.error('Tetris stopped safely:', fault.reason, fault.error ?? '');
}

export class GameManager {
  /** @param {GameManagerOptions} [options] */
  constructor({
    storage = defaultStorage(),
    scheduler = defaultScheduler,
    factory = new TetrominoFactory(),
    onFault = reportToConsole,
    onChange = () => {}
  } = {}) {
    this.storage = storage;
    this.scheduler = scheduler;
    this.factory = factory;
    this.onFault = onFault;
    this.onChange = onChange;
    /** @type {boolean | undefined} The saved game flag as last read from storage, until it may have changed. */
    this.storedIsSessionSaved = undefined;
    /** @type {Fault[]} */
    this.faults = [];
    this.rows = 20;
    this.columns = 10;
    /** @type {unknown} Timer handle, null when no gravity is scheduled. */
    this.gameLoopTask = null;
    /** @type {unknown} Timer handle, null when no lock delay is running. */
    this.lockDelayTask = null;
    this.lockDelayResetCount = 0;
    this.lowestRowReached = 0;
    this.maxLockDelayResets = 15;
    this.lockDelayInterval = 0.5;
    this.canHoldTetromino = true;
    /** @type {Tetromino | null} */
    this.heldTetromino = null;
    /** @type {GameStateValue} */
    this.state = GameState.gameOver;
    /** Whether the pause screen is asking the player to confirm New Game, which gives up the game. */
    this.isConfirmingNewGame = false;
    /** Counts every change to the locked blocks, so the page knows when to redraw them. */
    this.boardVersion = 0;
    this.score = 0;
    this.currentTetromino = this.factory.generate().spawned(this.columns);
    this.nextTetrominos = this.generateUpcoming();
    this.gameBoard = createBoard(this.rows, this.columns);
  }

  get level() {
    return Math.floor(this.score / 1000) + 1;
  }

  generateUpcoming() {
    return Array.from({ length: UPCOMING_COUNT }, () => this.factory.generate());
  }

  // Storage (@AppStorage equivalents). Reads and writes can throw when
  // storage is blocked or full; the game keeps working either way.

  /**
   * @param {string} key
   * @returns {string | null}
   */
  readItem(key) {
    try {
      return this.storage.getItem(key);
    } catch {
      // Unreadable storage counts as empty.
    }
    return null;
  }

  get highScore() {
    const value = Number(this.readItem(HIGH_SCORE_KEY));
    return Number.isSafeInteger(value) ? Math.max(value, 0) : 0;
  }

  /** @param {number} value */
  set highScore(value) {
    try {
      this.storage.setItem(HIGH_SCORE_KEY, String(value));
    } catch {
      // Not saved.
    }
  }

  // Kept in memory, because the page checks it on every frame. A write, or
  // a change made in another tab, makes the next check read storage again.
  get isSessionSaved() {
    this.storedIsSessionSaved ??= this.readItem(IS_SESSION_SAVED_KEY) === 'true';
    return this.storedIsSessionSaved;
  }

  /** @param {boolean} value */
  set isSessionSaved(value) {
    this.storageChanged();
    try {
      this.storage.setItem(IS_SESSION_SAVED_KEY, String(value));
    } catch {
      // Not saved.
    }
  }

  // Called when another tab changes storage, so stale values are not used.
  storageChanged() {
    this.storedIsSessionSaved = undefined;
  }

  get standardDropInterval() {
    return Math.max(0.25, 0.7 - 0.02 * (this.level - 1));
  }

  resetGameSession() {
    this.state = GameState.paused;
    this.gameBoard = createBoard(this.rows, this.columns);
    this.boardVersion += 1;
    this.score = 0;
    // A full bag, so the game's first seven pieces are all different.
    this.factory.resetBag?.();
    this.currentTetromino = this.factory.generate().spawned(this.columns);
    this.nextTetrominos = this.generateUpcoming();
    this.heldTetromino = null;
    this.canHoldTetromino = true;
    this.resetLockDelayForNewPiece();
    this.isSessionSaved = false;
  }

  // Loads a valid saved game. A refused save stays stored, but Continue
  // attempts to mark it unavailable. A missing or unreadable save is left alone.
  loadGameSession() {
    if (!this.isSessionSaved) return;
    const text = this.readItem(SAVED_SESSION_KEY);
    // A failed read or a missing save does not change storage.
    if (text === null) return;
    const session = parseSession(text, { rows: this.rows, columns: this.columns });
    if (!session) {
      this.isSessionSaved = false;
      return;
    }
    this.state = GameState.paused;
    this.gameBoard = session.gameBoard;
    this.boardVersion += 1;
    this.score = session.score;
    this.currentTetromino = session.currentTetromino;
    this.nextTetrominos = session.nextTetrominos;
    this.heldTetromino = session.heldTetromino;
    this.canHoldTetromino = session.canHoldTetromino;
    this.factory.resetBag?.(session.bag);
    this.resetLockDelayForNewPiece();
  }

  saveGameSession() {
    try {
      this.storage.setItem(SAVED_SESSION_KEY, serializeSession(this));
      this.isSessionSaved = true;
    } catch {
      this.isSessionSaved = false;
    }
  }

  generateNextTetromino() {
    // Never undefined: the queue always holds three pieces (checked by SAF-4).
    const next = /** @type {Tetromino} */ (this.nextTetrominos.shift());
    this.currentTetromino = next.spawned(this.columns);
    this.nextTetrominos.push(this.factory.generate());
    this.canHoldTetromino = true;
    this.resetLockDelayForNewPiece();

    if (!this.currentTetromino.fits(this.gameBoard)) {
      this.state = GameState.gameOver;
      this.isSessionSaved = false;
      this.stopGameLoop();
    } else {
      this.landIfResting();
    }
  }

  dropTetromino() {
    if (this.state !== GameState.playing) return;
    if (!this.isOnSurface) {
      // No lock delay can be running: it only runs while the piece rests on
      // something (checked by the invariant monitor).
      this.currentTetromino.position = below(this.currentTetromino.position);
      this.noteLowestRow();
    }
    this.landIfResting();
    if (this.state === GameState.playing) {
      this.startGameLoop();
    }
  }

  get isOnSurface() {
    return !this.currentTetromino.fits(this.gameBoard, below(this.currentTetromino.position));
  }

  startLockDelay() {
    this.scheduler.clearTimeout(this.lockDelayTask);
    // Only runs while playing: leaving play cancels it (checked by SAF-4).
    this.lockDelayTask = this.schedule(() => {
      this.lockAndSpawnNext();
      if (this.state === GameState.playing) this.startGameLoop();
    }, this.lockDelayInterval * 1000);
  }

  // The lock delay runs from the moment the piece comes to rest, however it
  // got there: falling, moving, turning, appearing, or play resuming.
  landIfResting() {
    if (this.isOnSurface) this.pieceLanded();
  }

  pieceLanded() {
    if (this.lockDelayTask !== null) return;
    if (this.lockDelayResetCount >= this.maxLockDelayResets) {
      this.lockAndSpawnNext();
    } else {
      this.startLockDelay();
    }
  }

  resetLockDelay() {
    this.noteLowestRow();
    if (this.lockDelayTask === null) {
      this.landIfResting();
    } else if (!this.isOnSurface) {
      this.cancelLockDelay();
      this.lockDelayResetCount += 1;
    } else if (this.lockDelayResetCount < this.maxLockDelayResets) {
      this.lockDelayResetCount += 1;
      this.startLockDelay();
    }
  }

  noteLowestRow() {
    if (this.currentTetromino.position.row <= this.lowestRowReached) return;
    this.lowestRowReached = this.currentTetromino.position.row;
    this.lockDelayResetCount = 0;
  }

  resetLockDelayForNewPiece() {
    this.cancelLockDelay();
    this.lockDelayResetCount = 0;
    this.lowestRowReached = this.currentTetromino.position.row;
  }

  cancelLockDelay() {
    this.scheduler.clearTimeout(this.lockDelayTask);
    this.lockDelayTask = null;
  }

  lockAndSpawnNext() {
    this.lockTetrominoInPlace();
    const clearedLines = this.clearFullRows();
    this.generateNextTetromino();
    if (clearedLines && this.state === GameState.playing) {
      this.saveGameSession();
    }
  }

  // The piece always fits on the board (checked by the invariant monitor).
  lockTetrominoInPlace() {
    for (const cell of this.currentTetromino.cells) {
      this.gameBoard[cell.row][cell.column] = { isFilled: true, color: this.currentTetromino.color };
    }
    this.boardVersion += 1;
  }

  clearFullRows() {
    /** @type {number[]} */
    const completedLineIndices = [];
    this.gameBoard.forEach((row, index) => {
      if (row.every(cell => cell.isFilled)) completedLineIndices.push(index);
    });
    if (completedLineIndices.length === 0) return false;
    // Remove from the bottom up so earlier removals do not shift later ones.
    for (const index of completedLineIndices.reverse()) {
      this.gameBoard.splice(index, 1);
    }
    const newLines = createBoard(completedLineIndices.length, this.columns);
    this.gameBoard.unshift(...newLines);
    this.boardVersion += 1;
    this.score += LINE_SCORES[completedLineIndices.length];
    this.highScore = Math.max(this.highScore, this.score);
    return true;
  }

  get ghostTetromino() {
    const ghost = this.currentTetromino.copy();
    ghost.position = position(ghost.position.row + ghost.dropDistance(this.gameBoard), ghost.position.column);
    return ghost;
  }

  startGameLoop() {
    this.stopGameLoop();
    const interval = this.standardDropInterval;
    // Only runs while playing: leaving play stops it (checked by SAF-4).
    this.gameLoopTask = this.schedule(() => {
      this.gameLoopTask = null;
      this.dropTetromino();
    }, interval * 1000);
  }

  stopGameLoop() {
    this.scheduler.clearTimeout(this.gameLoopTask);
    this.gameLoopTask = null;
  }

  // Fault containment

  // Timers run their callback through the guard, like player actions.
  /**
   * @param {() => void} callback
   * @param {number} ms
   * @returns {unknown} The timer handle.
   */
  schedule(callback, ms) {
    return this.scheduler.setTimeout(() => this.guard(callback), ms);
  }

  // Runs one operation, catching errors and checking the invariants after
  // it, then reports that the game may have changed.
  /** @param {() => void} operation */
  guard(operation) {
    this.runChecked(operation);
    this.onChange();
  }

  /** @param {() => void} operation */
  runChecked(operation) {
    /** @type {string | null} */
    let violation;
    try {
      operation();
      // Inside the try too: state broken in a way the check does not expect
      // can make the check itself throw.
      violation = this.findInvariantViolation();
    } catch (error) {
      this.failSafe('unexpected error', error);
      return;
    }
    if (violation) this.failSafe(violation);
  }

  // Returns a description of the first broken invariant, or null.
  /** @returns {string | null} */
  findInvariantViolation() {
    const board = this.gameBoard;
    if (!Array.isArray(board) || board.length !== this.rows || !board.every(row => Array.isArray(row) && row.length === this.columns)) {
      return 'board is not 20 by 10';
    }
    const upcoming = this.nextTetrominos;
    if (upcoming.length !== UPCOMING_COUNT) return 'upcoming pieces missing';
    if (!isValidPieceList(upcoming)) return 'upcoming piece is not a valid piece';
    if (!Number.isSafeInteger(this.score) || this.score < 0 || this.score % 100 !== 0) return 'score is invalid';
    if (this.state !== GameState.gameOver && !isValidFallingPiece(this.currentTetromino, board)) return 'piece is invalid or overlaps the board';
    if (this.state === GameState.playing) {
      if (this.gameLoopTask === null) return 'gravity stopped while playing';
      if (this.lockDelayTask !== null && !this.isOnSurface) return 'lock delay running off the surface';
      if (this.lockDelayTask === null && this.isOnSurface) return 'piece resting with no lock delay';
    } else if (this.gameLoopTask !== null || this.lockDelayTask !== null) {
      return 'timers running while not playing';
    }
    return null;
  }

  // Safe state: game over with every timer stopped. Storage is left alone,
  // so the last good save can still be continued.
  /**
   * @param {string} reason
   * @param {unknown} [error]
   */
  failSafe(reason, error) {
    this.state = GameState.gameOver;
    this.stopGameLoop();
    this.cancelLockDelay();
    const fault = { reason, error };
    // Keeping the record and reporting are tried apart, so neither can stop
    // the other, and the catches are empty, so nothing in them can throw.
    try {
      this.faults.push(fault);
      if (this.faults.length > MAX_FAULTS_KEPT) this.faults.shift();
    } catch {
      // Keeping the record must never make things worse.
    }
    try {
      this.onFault(fault);
    } catch {
      // Reporting must never make things worse.
    }
  }

  // Player input

  /** @param {PlayerActionValue} action */
  handleAction(action) {
    this.guard(() => this.performAction(action));
  }

  /** @param {PlayerActionValue} action */
  performAction(action) {
    // New Game on the pause screen asks first, and a second New Game
    // confirms; any other action in between cancels the question.
    const newGameConfirmed = this.isConfirmingNewGame;
    this.isConfirmingNewGame = false;
    switch (action) {
      case PlayerAction.newGame:
        // From game over, or while paused to give up that game, once the
        // player confirms, so one stray press cannot end a game.
        if (this.state === GameState.playing) return;
        if (this.state === GameState.paused && !newGameConfirmed) {
          this.isConfirmingNewGame = true;
          return;
        }
        this.resetGameSession();
        this.state = GameState.playing;
        this.startGameLoop();
        break;
      case PlayerAction.continueGame:
        if (this.state !== GameState.gameOver) return;
        this.loadGameSession();
        break;
      case PlayerAction.pause:
        if (this.state !== GameState.playing) return;
        this.state = GameState.paused;
        this.stopGameLoop();
        if (this.lockDelayTask !== null) {
          this.lockDelayResetCount += 1;
        }
        this.cancelLockDelay();
        this.saveGameSession();
        break;
      case PlayerAction.resume:
        if (this.state !== GameState.paused) return;
        this.state = GameState.playing;
        this.landIfResting();
        if (this.state === GameState.playing) this.startGameLoop();
        break;
      case PlayerAction.moveLeft:
        this.moveTetromino(-1);
        break;
      case PlayerAction.moveRight:
        this.moveTetromino(1);
        break;
      case PlayerAction.hold:
        this.holdTetromino();
        break;
      case PlayerAction.rotate:
        this.rotateTetromino();
        break;
      case PlayerAction.rotateCounterclockwise:
        this.rotateTetromino(true);
        break;
      case PlayerAction.drop:
        this.hardDrop();
        break;
    }
  }

  togglePause() {
    this.handleAction(this.state === GameState.playing ? PlayerAction.pause : PlayerAction.resume);
  }

  softDrop() {
    this.isConfirmingNewGame = false;
    this.guard(() => this.dropTetromino());
  }

  // Answers no to the pause screen's New Game question: the game stays paused.
  cancelNewGame() {
    this.guard(() => {
      this.isConfirmingNewGame = false;
    });
  }

  hardDrop() {
    if (this.state !== GameState.playing) return;
    // Locking brings in the next piece, which resets the lock delay.
    this.currentTetromino.position = this.ghostTetromino.position;
    this.lockAndSpawnNext();
    if (this.state === GameState.playing) {
      this.startGameLoop();
    }
  }

  /** @param {number} deltaX */
  moveTetromino(deltaX) {
    if (this.state !== GameState.playing) return;
    const newPosition = position(this.currentTetromino.position.row, this.currentTetromino.position.column + deltaX);
    if (this.currentTetromino.fits(this.gameBoard, newPosition)) {
      this.currentTetromino.position = newPosition;
      this.resetLockDelay();
    }
  }

  holdTetromino() {
    if (this.state !== GameState.playing || !this.canHoldTetromino) return;
    this.stopGameLoop();
    this.cancelLockDelay();
    const pieceToHold = this.currentTetromino.spawned(this.columns);
    if (this.heldTetromino) {
      const incoming = this.heldTetromino.spawned(this.columns);
      if (!incoming.fits(this.gameBoard)) {
        this.state = GameState.gameOver;
        this.isSessionSaved = false;
        return;
      }
      this.currentTetromino = incoming;
      this.resetLockDelayForNewPiece();
      this.landIfResting();
    } else {
      this.generateNextTetromino();
    }
    this.heldTetromino = pieceToHold;
    this.canHoldTetromino = false;
    if (this.state === GameState.playing) this.startGameLoop();
  }

  /** @param {boolean} [counterclockwise] */
  rotateTetromino(counterclockwise = false) {
    if (this.state !== GameState.playing) return;
    const previousState = this.currentTetromino.rotationState;
    this.currentTetromino.rotate(this.gameBoard, counterclockwise);
    if (this.currentTetromino.rotationState !== previousState) {
      this.resetLockDelay();
    }
  }
}
