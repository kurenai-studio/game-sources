export const ROUND_STATES = Object.freeze({
  IDLE: 'idle',
  COUNTDOWN: 'countdown',
  PLAYING: 'playing',
  ROUND_END: 'round-end',
});

export class GameStateMachine {
  constructor({ countdown = 3, roundDuration = 90 } = {}) {
    this.countdownDuration = countdown;
    this.roundDuration = roundDuration;
    this.state = ROUND_STATES.IDLE;
    this.timeRemaining = 0;
    this.winner = null;
    this.listeners = new Set();
  }

  onChange(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  emit() {
    for (const listener of this.listeners) listener(this.snapshot());
  }

  start() {
    this.winner = null;
    this.state = ROUND_STATES.COUNTDOWN;
    this.timeRemaining = this.countdownDuration;
    this.emit();
  }

  update(dt) {
    if (this.state === ROUND_STATES.COUNTDOWN) {
      this.timeRemaining -= dt;
      if (this.timeRemaining <= 0) {
        this.state = ROUND_STATES.PLAYING;
        this.timeRemaining = this.roundDuration;
        this.emit();
      }
      return;
    }

    if (this.state === ROUND_STATES.PLAYING) {
      this.timeRemaining = Math.max(0, this.timeRemaining - dt);
      if (this.timeRemaining === 0) this.end('mimic');
    }
  }

  mimicHit() {
    if (this.state !== ROUND_STATES.PLAYING) return false;
    this.end('sniper');
    return true;
  }

  end(winner) {
    this.state = ROUND_STATES.ROUND_END;
    this.winner = winner;
    this.emit();
  }

  snapshot() {
    return { state: this.state, timeRemaining: this.timeRemaining, winner: this.winner };
  }
}
