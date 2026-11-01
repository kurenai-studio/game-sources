import { GameStateEnum } from '../types/game-state';

/**
 * GameState class - manages the game state machine.
 * Handles state transitions, score tracking, and timing.
 */
export class GameState {
  /** Current game state */
  private state: GameStateEnum = GameStateEnum.Start;

  /** Distance traveled in current run (score) */
  private score = 0;

  /** Timestamp when current run began */
  private startTime = 0;

  /** Timestamp when game was paused (null if not paused) */
  private pauseTime: number | null = null;

  /**
   * Get the current game state.
   */
  getState(): GameStateEnum {
    return this.state;
  }

  /**
   * Get the current score (distance traveled).
   */
  getScore(): number {
    return this.score;
  }

  /**
   * Check if the game is currently running.
   */
  isRunning(): boolean {
    return this.state === GameStateEnum.Running;
  }

  /**
   * Get the elapsed run time in seconds.
   * Returns 0 if not in Running state.
   */
  getElapsedTime(): number {
    if (this.state !== GameStateEnum.Running) {
      return 0;
    }

    const baseTime = this.pauseTime ?? Date.now();
    return (baseTime - this.startTime) / 1000;
  }

  /**
   * Update the score based on elapsed time and speed.
   * Called per-frame when game is running.
   * @param deltaTime - Time since last update in seconds
   * @param currentSpeed - Current forward speed
   */
  updateScore(deltaTime: number, currentSpeed: number) {
    if (this.state !== GameStateEnum.Running) {
      return;
    }
    this.score += currentSpeed * deltaTime;
  }

  /**
   * Transition from Start to Running state.
   * Initializes score and start time.
   */
  startGame() {
    if (this.state !== GameStateEnum.Start) {
      return;
    }
    this.state = GameStateEnum.Running;
    this.score = 0;
    this.startTime = Date.now();
    this.pauseTime = null;
  }

  /**
   * Transition from Running to Paused state.
   * Records the pause time.
   */
  pauseGame() {
    if (this.state !== GameStateEnum.Running) {
      return;
    }
    this.state = GameStateEnum.Paused;
    this.pauseTime = Date.now();
  }

  /**
   * Transition from Paused to Running state.
   * Resumes from the exact point where paused.
   */
  resumeGame() {
    if (this.state !== GameStateEnum.Paused) {
      return;
    }
    this.state = GameStateEnum.Running;
    if (this.pauseTime !== null) {
      // Adjust start time to account for pause duration
      const pauseDuration = Date.now() - this.pauseTime;
      this.startTime += pauseDuration;
      this.pauseTime = null;
    }
  }

  /**
   * Transition from Running to GameOver state.
   * Freezes game state on collision.
   */
  triggerGameOver() {
    if (this.state !== GameStateEnum.Running) {
      return;
    }
    this.state = GameStateEnum.GameOver;
    this.pauseTime = null;
  }

  /**
   * Transition from GameOver to Running state.
   * Resets all state for a new run.
   */
  restartGame() {
    if (this.state !== GameStateEnum.GameOver) {
      return;
    }
    this.state = GameStateEnum.Running;
    this.score = 0;
    this.startTime = Date.now();
    this.pauseTime = null;
  }
}
