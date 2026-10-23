// Port of Support/GameControllerManager.swift using browser keyboard events
// and the Gamepad API. Keeps the same bindings and DAS/ARR timings.
//
// Keyboard: A/D move, W rotate, Z rotate counterclockwise, S soft drop,
// Space hard drop, H hold, P or Esc pause, Enter new game, C continue. Arrow
// keys are aliases for WASD.
// Gamepad (standard mapping): stick or directional pad moves and soft drops,
// A or pad up drop, B or right shoulder rotate, left shoulder rotate
// counterclockwise, X hold, Y continue, Menu/Start pause or new game,
// View/Select new game. While the pause screen asks to confirm New Game,
// left and right move between its buttons, A presses the selected one and B
// cancels.

import { GameState, PlayerAction } from './gameState.js';

/** @typedef {import('./gameState.js').PlayerActionValue} PlayerActionValue */
/** @typedef {import('./gameManager.js').GameManager} GameManager */
/** @typedef {Pick<GameManager, 'state' | 'isConfirmingNewGame' | 'handleAction' | 'togglePause' | 'softDrop' | 'cancelNewGame'>} Controllable */
/**
 * The New Game question's buttons, which the page shows: move selects the
 * button before (-1) or after (1) the selected one, and press presses the
 * selected one.
 * @typedef {{ move(step: -1 | 1): void, press(): void }} QuestionButtons
 */

const DAS_DELAY_MS = 167;
const ARR_INTERVAL_MS = 33;
const SOFT_DROP_INTERVAL_MS = 50;

/** @type {Record<string, string>} */
const KEY_ALIASES = {
  ArrowLeft: 'KeyA',
  ArrowRight: 'KeyD',
  ArrowUp: 'KeyW',
  ArrowDown: 'KeyS',
  NumpadEnter: 'Enter'
};

/** @type {Record<string, PlayerActionValue>} */
const KEY_ACTIONS = {
  KeyW: PlayerAction.rotate,
  KeyZ: PlayerAction.rotateCounterclockwise,
  Space: PlayerAction.drop,
  KeyH: PlayerAction.hold,
  Enter: PlayerAction.newGame,
  KeyC: PlayerAction.continueGame
};

// Standard gamepad mapping button indices.
const PAD_BUTTONS = { a: 0, b: 1, x: 2, y: 3, lb: 4, rb: 5, view: 8, menu: 9, up: 12, down: 13, left: 14, right: 15 };
/** @type {Array<[string, PlayerActionValue]>} */
const PAD_ACTIONS = [
  ['y', PlayerAction.continueGame],
  ['b', PlayerAction.rotate],
  ['rb', PlayerAction.rotate],
  ['lb', PlayerAction.rotateCounterclockwise],
  ['x', PlayerAction.hold],
  ['a', PlayerAction.drop],
  ['up', PlayerAction.drop]
];

export class InputController {
  /**
   * @param {Controllable} gameManager
   * @param {QuestionButtons} questionButtons
   */
  constructor(gameManager, questionButtons) {
    this.gameManager = gameManager;
    this.questionButtons = questionButtons;
    /** @type {PlayerActionValue | null} The move being auto repeated. */
    this.movement = null;
    /** @type {number | undefined} */
    this.movementTimer = undefined;
    /** @type {number | undefined} */
    this.softDropTimer = undefined;
    /** @type {Set<string>} */
    this.heldKeys = new Set();
    /** @type {Set<string>} */
    this.heldButtons = new Set();
    /** @type {PlayerActionValue | null} Held on the stick or directional pad. */
    this.padDirection = null;
    /** Whether the stick or directional pad is held down. */
    this.padDown = false;

    window.addEventListener('keydown', event => this.handleKey(event, true));
    window.addEventListener('keyup', event => this.handleKey(event, false));
    window.addEventListener('blur', () => this.releaseAllInput());
    window.addEventListener('gamepaddisconnected', () => this.releaseAllInput());
    window.addEventListener('gamepadconnected', () => this.startPolling());
    /** Whether a poll is scheduled for the next animation frame. */
    this.polling = false;
    // Browsers usually report a gamepad only once a button is pressed, but
    // check once in case one is already available.
    this.startPolling();
  }

  // Polls every frame while a gamepad is connected, then stops, so the page
  // does not wake up every frame for nothing. An error keeps polling.
  startPolling() {
    if (this.polling) return;
    this.polling = true;
    const poll = () => {
      let connected = true;
      try {
        connected = this.pollGamepads();
      } catch (error) {
        console.error('Tetris gamepad error:', error);
      }
      if (connected) requestAnimationFrame(poll);
      else this.polling = false;
    };
    requestAnimationFrame(poll);
  }

  /**
   * @param {KeyboardEvent} event
   * @param {boolean} pressed
   */
  handleKey(event, pressed) {
    const key = KEY_ALIASES[event.code] ?? event.code;
    const modifierHeld = event.metaKey || event.ctrlKey || event.altKey;
    // A key pressed with a modifier is left to the browser and never counts
    // as held: macOS sends no keyup for a key let go while Cmd is down, so
    // it would stay held forever.
    if (pressed && modifierHeld) return;
    if (pressed) this.heldKeys.add(key);
    else this.heldKeys.delete(key);

    // While the pause screen asks to confirm New Game, keys belong to its
    // dialog and press its buttons, except a held key repeating: the Enter
    // that asked must not go on to answer. Escape answers no here rather
    // than leaving the dialog to the browser, so the game hears of it at once,
    // and the left and right arrows move between the buttons, as on a
    // controller.
    if (this.gameManager.isConfirmingNewGame) {
      if (event.repeat) {
        event.preventDefault();
      } else if (pressed && key === 'Escape') {
        event.preventDefault();
        this.gameManager.cancelNewGame();
      } else if (pressed && (event.code === 'ArrowLeft' || event.code === 'ArrowRight')) {
        event.preventDefault();
        this.questionButtons.move(event.code === 'ArrowLeft' ? -1 : 1);
      }
      return;
    }

    const handled = key === 'KeyA' || key === 'KeyD' || key === 'KeyS' || key === 'KeyP' || key === 'Escape' || key in KEY_ACTIONS;
    if (!handled) return;
    event.preventDefault();
    if (pressed && event.repeat) return;

    if (key === 'KeyA' || key === 'KeyD') {
      if (pressed) {
        this.startMoving(key === 'KeyA' ? PlayerAction.moveLeft : PlayerAction.moveRight);
      } else {
        this.resumeHeldMovement();
      }
    } else if (key === 'KeyS') {
      // One row at once, then the steady soft drop while held.
      if (pressed) this.gameManager.softDrop();
      this.updateSoftDrop();
    } else if (pressed && (key === 'KeyP' || key === 'Escape')) {
      this.gameManager.togglePause();
    } else if (pressed) {
      this.gameManager.handleAction(KEY_ACTIONS[key]);
    }
  }

  /** @returns {boolean} Whether a gamepad is connected. */
  pollGamepads() {
    if (!navigator.getGamepads) return false; // no gamepad support in this browser
    const gamepad = navigator.getGamepads().find(pad => pad?.connected);
    if (!gamepad) return false;
    const pressed = new Set(
      Object.entries(PAD_BUTTONS)
        .filter(([, index]) => gamepad.buttons[index]?.pressed)
        .map(([name]) => name)
    );
    // Browser axes are +1 down, GameController's are +1 up, so flip y.
    this.processInput(pressed, gamepad.axes[0] ?? 0, -(gamepad.axes[1] ?? 0));
    return true;
  }

  /**
   * @param {Set<string>} pressed Names of the buttons held down.
   * @param {number} xAxis Stick, -1 left to 1 right.
   * @param {number} yAxis Stick, -1 down to 1 up.
   */
  processInput(pressed, xAxis, yAxis) {
    const newPresses = new Set([...pressed].filter(button => !this.heldButtons.has(button)));
    this.heldButtons = pressed;
    const direction = xAxis < -0.5 || pressed.has('left') ? PlayerAction.moveLeft
      : xAxis > 0.5 || pressed.has('right') ? PlayerAction.moveRight
        : null;

    // While the pause screen asks to confirm New Game, left and right on the
    // stick or directional pad move between its buttons, once per push, A
    // presses the selected one and B cancels; nothing else acts. The pad's
    // direction is still tracked, so a push held as the question closes does
    // not then move a piece.
    if (this.gameManager.isConfirmingNewGame) {
      if (newPresses.has('a')) this.questionButtons.press();
      else if (newPresses.has('b')) this.gameManager.cancelNewGame();
      else if (direction && direction !== this.padDirection) this.questionButtons.move(direction === PlayerAction.moveLeft ? -1 : 1);
      this.padDirection = direction;
      return;
    }

    // Menu and View change what the game is doing, so they act alone: a
    // button pressed at the same moment would act on the new state, such as
    // A hard dropping the first piece of the game Menu just started. Moving
    // and soft dropping follow what is held, so they carry on below.
    if (newPresses.has('menu')) {
      if (this.gameManager.state === GameState.gameOver) {
        this.gameManager.handleAction(PlayerAction.newGame);
      } else {
        this.gameManager.togglePause();
      }
    } else if (newPresses.has('view')) {
      this.gameManager.handleAction(PlayerAction.newGame);
    } else {
      // Each action once, even when two of its buttons are pressed together:
      // A and pad up at once must not hard drop two pieces.
      const actions = new Set(PAD_ACTIONS.filter(([button]) => newPresses.has(button)).map(([, action]) => action));
      for (const action of actions) this.gameManager.handleAction(action);
    }

    this.padDown = yAxis < -0.5 || pressed.has('down');
    this.updateSoftDrop();

    // Polling runs every frame, so only react to stick and pad changes;
    // otherwise a centered stick would cancel keyboard movement.
    if (direction === this.padDirection) return;
    this.padDirection = direction;
    if (direction) {
      this.startMoving(direction);
    } else {
      this.resumeHeldMovement();
    }
  }

  // After a direction is let go, keeps moving in a direction still held on
  // the keyboard, the stick or the directional pad, or stops.
  resumeHeldMovement() {
    const held = this.heldKeys.has('KeyA') ? PlayerAction.moveLeft
      : this.heldKeys.has('KeyD') ? PlayerAction.moveRight
        : this.padDirection;
    if (held) {
      this.startMoving(held);
    } else {
      this.stopMoving();
    }
  }

  /** @param {PlayerActionValue} action */
  startMoving(action) {
    if (this.movement === action) return;
    this.movement = action;
    clearTimeout(this.movementTimer);
    this.gameManager.handleAction(action);
    const repeat = () => {
      if (this.gameManager.state !== GameState.playing) {
        this.stopMoving();
        return;
      }
      this.gameManager.handleAction(action);
      this.movementTimer = setTimeout(repeat, ARR_INTERVAL_MS);
    };
    this.movementTimer = setTimeout(repeat, DAS_DELAY_MS);
  }

  stopMoving() {
    clearTimeout(this.movementTimer);
    this.movementTimer = undefined;
    this.movement = null;
  }

  // Soft drops while the soft drop key, the stick or the directional pad is
  // held down, so a resting stick does not cancel the key.
  updateSoftDrop() {
    if (this.heldKeys.has('KeyS') || this.padDown) {
      this.startSoftDrop();
    } else {
      this.stopSoftDrop();
    }
  }

  startSoftDrop() {
    if (this.softDropTimer !== undefined) return;
    this.softDropTimer = setInterval(() => {
      if (this.gameManager.state !== GameState.playing) {
        this.stopSoftDrop();
        return;
      }
      this.gameManager.softDrop();
    }, SOFT_DROP_INTERVAL_MS);
  }

  stopSoftDrop() {
    clearInterval(this.softDropTimer);
    this.softDropTimer = undefined;
  }

  releaseAllInput() {
    this.stopMoving();
    this.stopSoftDrop();
    this.heldButtons = new Set();
    this.padDirection = null;
    this.padDown = false;
    this.heldKeys.clear();
  }
}
