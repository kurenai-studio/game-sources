/**
 * GOAL RUSH — central game state + event bus.
 *
 * Single source of truth for the economy (credits, progressive pot, balls,
 * multiplier). The Phaser HUD and slot machine talk through this emitter,
 * and a thin CustomEvent bridge mirrors the two lifecycle events the React
 * shell cares about (game started / game over) — keeping both worlds
 * decoupled.
 */

import * as Phaser from 'phaser';
import { JACKPOT, SCORING } from '../config/game.config';

/** Events emitted on the bus (Phaser-side listeners). */
export interface GameEvents extends Phaser.Events.EventEmitter {
  on(
    event: 'credits',
    fn: (credits: number, delta: number) => void,
    context?: unknown
  ): this;
  on(event: 'pot', fn: (pot: number) => void, context?: unknown): this;
  on(event: 'balls', fn: (balls: number) => void, context?: unknown): this;
  on(event: 'multiplier', fn: (mult: number) => void, context?: unknown): this;
  on(event: 'gamestarted', fn: () => void, context?: unknown): this;
  on(event: 'gameover', fn: () => void, context?: unknown): this;
}

export interface GameOverBridgeDetail {
  credits: number;
  spins: number;
  best: number;
}

export class GameState {
  readonly bus: GameEvents = new Phaser.Events.EventEmitter() as GameEvents;

  credits = 0;
  pot: number = JACKPOT.seed;
  balls = 0;
  multiplier = 1;
  spins = 0;
  best: number = 0;
  running = false;

  constructor() {
    if (typeof window !== 'undefined') {
      try {
        const pot = Number(window.localStorage.getItem(JACKPOT.potKey));
        if (Number.isFinite(pot) && pot >= JACKPOT.seed) this.pot = Math.floor(pot);
        const best = Number(window.localStorage.getItem(JACKPOT.bestKey));
        if (Number.isFinite(best) && best > 0) this.best = Math.floor(best);
      } catch {
        /* private mode / SSR — keep defaults */
      }
    }
  }

  /** Start a fresh game. */
  startGame(): void {
    this.credits = SCORING.startCredits;
    this.balls = SCORING.ballsPerGame;
    this.multiplier = 1;
    this.spins = 0;
    this.running = true;
    this.bus.emit('credits', this.credits, 0);
    this.bus.emit('balls', this.balls);
    this.bus.emit('multiplier', this.multiplier);
    this.bus.emit('gamestarted');
    window.dispatchEvent(new CustomEvent('goalrush:gamestarted'));
  }

  /** Add (or remove, negative delta) credits. */
  addCredits(delta: number): void {
    this.credits = Math.max(0, this.credits + delta);
    this.bus.emit('credits', this.credits, delta);
  }

  /** Grow the progressive pot from a table event. */
  contributePot(amount: number): void {
    this.pot = Math.floor(this.pot + amount);
    this.bus.emit('pot', this.pot);
    this.persistPot();
  }

  /** Pay the pot to the player and re-seed it. */
  claimJackpot(): number {
    const won = this.pot;
    this.pot = JACKPOT.seed;
    this.bus.emit('pot', this.pot);
    this.persistPot();
    this.addCredits(won);
    return won;
  }

  /** Register a consumed slot spin. */
  registerSpin(): void {
    this.spins += 1;
  }

  setMultiplier(mult: number): void {
    this.multiplier = Phaser.Math.Clamp(mult, 1, SCORING.maxMultiplier);
    this.bus.emit('multiplier', this.multiplier);
  }

  /** Consume a ball. Returns the remaining count. */
  loseBall(): number {
    this.balls = Math.max(0, this.balls - 1);
    this.bus.emit('balls', this.balls);
    return this.balls;
  }

  /** Award an extra ball (milestone bonus), capped at maxBalls.
   *  Returns true when the ball was actually granted. */
  addBall(maxBalls: number): boolean {
    if (this.balls >= maxBalls) return false;
    this.balls += 1;
    this.bus.emit('balls', this.balls);
    return true;
  }

  /** Finish the game, persist best, notify React. */
  gameOver(): void {
    if (!this.running) return;
    this.running = false;
    if (this.credits > this.best) {
      this.best = this.credits;
      try {
        window.localStorage.setItem(JACKPOT.bestKey, String(this.best));
      } catch {
        /* ignore */
      }
    }
    this.bus.emit('gameover');
    window.dispatchEvent(
      new CustomEvent<GameOverBridgeDetail>('goalrush:gameover', {
        detail: { credits: this.credits, spins: this.spins, best: this.best },
      })
    );
  }

  private persistPot(): void {
    try {
      window.localStorage.setItem(JACKPOT.potKey, String(this.pot));
    } catch {
      /* ignore */
    }
  }
}
