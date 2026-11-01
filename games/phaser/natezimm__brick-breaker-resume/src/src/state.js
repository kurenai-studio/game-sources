import { GAME_CONSTANTS } from './constants.js';

/**
 * Mutable runtime state for one Brick Breaker scene.
 *
 * @typedef {Object} GameStateFields
 * @property {number} highScore
 * @property {number} lives
 * @property {number} score
 * @property {number} totalRows
 * @property {boolean} paused
 * @property {boolean} wasInCountdown
 * @property {number} currentCountdown
 * @property {boolean} gameEnded
 * @property {boolean} bricksCreated
 * @property {Set<number>} brokenWords
 * @property {number | null} lastHitColor
 */

function sanitizeHighScore(value) {
  const parsed = parseInt(value, 10);
  if (Number.isNaN(parsed) || parsed < 0 || parsed > Number.MAX_SAFE_INTEGER) {
    return 0;
  }
  return parsed;
}

class GameState {
  constructor() {
    try {
      this.highScore = sanitizeHighScore(
        localStorage.getItem('brickBreakerHighScore')
      );
    } catch {
      this.highScore = 0;
    }
    this.reset();
  }

  reset() {
    this.bricksGroup = null;
    this.paddle = null;
    this.ball = null;
    this.lives = GAME_CONSTANTS.INITIAL_LIVES;
    this.livesBalls = [];
    this.score = GAME_CONSTANTS.INITIAL_SCORE;
    this.scoreText = null;
    this.totalRows = 0;
    this.paused = true;
    this.countdownText = null;
    this.countdownInterval = null;
    this.wasInCountdown = false;
    this.currentCountdown = GAME_CONSTANTS.COUNTDOWN_START;
    this.winText = null;
    this.gameEnded = false;
    this.bricksCreated = false;
    this.ballTrailGraphics = null;
    this.ballTrailPoints = [];
    this.paddleTrailGraphics = null;
    this.paddleTrailPoints = [];
    // Keys of the bricks already broken (a word's position in the résumé), so
    // a theme switch can lay the rest out again without restoring them.
    this.brokenWords = new Set();
    this.rebuildingBricks = null;
    this.lastHitColor = null;
  }

  incrementScore(points) {
    this.score += points;
    if (this.scoreText) {
      if (typeof this.scoreText.updateScoreLabel === 'function') {
        this.scoreText.updateScoreLabel(this.score);
      } else {
        this.scoreText.setText(this.score);
      }
    }
    this.updateHighScore();
  }

  decrementLives() {
    this.lives--;
    const lifeBall = this.livesBalls.pop();
    lifeBall?.destroy();
  }

  setPaused(paused) {
    this.paused = paused;
  }

  updateHighScore() {
    if (this.score > this.highScore) {
      this.highScore = this.score;
      try {
        localStorage.setItem('brickBreakerHighScore', String(this.highScore));
      } catch {
        // Ignore storage failures so scoring still works when localStorage is unavailable.
      }
    }
  }

  togglePause() {
    this.paused = !this.paused;
    return this.paused;
  }
}

export function createGameState() {
  return new GameState();
}

export function attachGameState(scene, state = createGameState()) {
  if (scene) {
    scene.gameState = state;
  }

  return state;
}

export function getGameState(scene) {
  return scene?.gameState ?? gameState;
}

export { GameState };

export const gameState = createGameState();
