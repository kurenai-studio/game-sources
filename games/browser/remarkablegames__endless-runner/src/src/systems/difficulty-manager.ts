import type { DifficultyConfig } from '../types/difficulty-config';

/**
 * DifficultyManager class - handles progressive difficulty scaling.
 * Interpolates speed and density based on run duration.
 */
export class DifficultyManager {
  private config: DifficultyConfig;
  private runDuration = 0;

  constructor(config: DifficultyConfig) {
    this.config = config;
  }

  /**
   * Update the difficulty manager based on elapsed time.
   * @param deltaTime - Time since last update in seconds
   */
  update(deltaTime: number) {
    this.runDuration += deltaTime;
  }

  /**
   * Get the current speed based on run duration.
   * Linear interpolation from baseSpeed to maxSpeed.
   */
  getCurrentSpeed(): number {
    const progress = Math.min(
      1,
      this.runDuration / this.config.densityRampDuration,
    );
    return (
      this.config.baseSpeed +
      (this.config.maxSpeed - this.config.baseSpeed) * progress
    );
  }

  /**
   * Get the current obstacle density based on run duration.
   * Linear interpolation from baseDensity to maxDensity.
   */
  getCurrentDensity(): number {
    const progress = Math.min(
      1,
      this.runDuration / this.config.densityRampDuration,
    );
    return (
      this.config.baseDensity +
      (this.config.maxDensity - this.config.baseDensity) * progress
    );
  }

  /**
   * Get the run duration in seconds.
   */
  getRunDuration(): number {
    return this.runDuration;
  }

  /**
   * Reset the difficulty manager for a new run.
   */
  reset() {
    this.runDuration = 0;
  }
}
