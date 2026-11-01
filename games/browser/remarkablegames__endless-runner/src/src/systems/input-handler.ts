import { INPUT_LOCKOUT_DURATION } from '../config/game-constants';
import type { InputDirection } from '../types/input';

/**
 * Handles raw keyboard input with first-input-wins behavior.
 */
export class InputHandler {
  private readonly pressedKeys = new Set<string>();
  private readonly keyMap: Partial<Record<string, InputDirection>> = {
    ArrowLeft: 'LEFT',
    KeyA: 'LEFT',
    ArrowRight: 'RIGHT',
    KeyD: 'RIGHT',
    ArrowUp: 'UP',
    KeyW: 'UP',
    ArrowDown: 'DOWN',
    KeyS: 'DOWN',
  };
  private readonly pauseKeys = new Set<string>(['KeyP', 'Escape']);
  private queuedInput: InputDirection | null = null;
  private consumedQueuedInput = false;
  private lockoutUntil = 0;
  private pauseRequested = false;
  private restartRequested = false;
  private startRequested = false;

  /**
   * Begin listening for keyboard input.
   */
  initialize() {
    window.addEventListener('keydown', this.handleKeyDown);
    window.addEventListener('keyup', this.handleKeyUp);
  }

  /**
   * Stop listening for keyboard input.
   */
  dispose() {
    window.removeEventListener('keydown', this.handleKeyDown);
    window.removeEventListener('keyup', this.handleKeyUp);
  }

  /**
   * Return the next unconsumed directional input.
   */
  pollInput(): InputDirection | null {
    if (this.queuedInput === null || this.consumedQueuedInput) {
      return null;
    }

    this.consumedQueuedInput = true;
    return this.queuedInput;
  }

  /**
   * Consume a pause toggle request.
   */
  consumePauseRequested(): boolean {
    const requested = this.pauseRequested;
    this.pauseRequested = false;
    return requested;
  }

  /**
   * Consume a restart request.
   */
  consumeRestartRequested(): boolean {
    const requested = this.restartRequested;
    this.restartRequested = false;
    return requested;
  }

  /**
   * Consume a start request.
   */
  consumeStartRequested(): boolean {
    const requested = this.startRequested;
    this.startRequested = false;
    return requested;
  }

  /**
   * Clear queued and pressed input state.
   */
  clearInputs() {
    this.pressedKeys.clear();
    this.queuedInput = null;
    this.consumedQueuedInput = false;
    this.pauseRequested = false;
    this.restartRequested = false;
  }

  /**
   * Handle key presses.
   */
  private readonly handleKeyDown = (event: KeyboardEvent) => {
    if (event.repeat) {
      return;
    }

    this.pressedKeys.add(event.code);

    if (this.pauseKeys.has(event.code)) {
      this.pauseRequested = true;
      return;
    }

    if (event.code === 'KeyR') {
      this.restartRequested = true;
    }

    this.startRequested = true;

    const inputDirection = this.keyMap[event.code];
    if (!inputDirection) {
      return;
    }

    if (this.queuedInput !== null || Date.now() < this.lockoutUntil) {
      return;
    }

    this.queuedInput = inputDirection;
    this.consumedQueuedInput = false;
  };

  /**
   * Release directional input and unlock after a short delay.
   */
  private readonly handleKeyUp = (event: KeyboardEvent) => {
    this.pressedKeys.delete(event.code);

    if (
      this.queuedInput !== null &&
      this.keyMap[event.code] === this.queuedInput
    ) {
      this.queuedInput = null;
      this.consumedQueuedInput = false;
      this.lockoutUntil = Date.now() + INPUT_LOCKOUT_DURATION;
    }
  };
}
