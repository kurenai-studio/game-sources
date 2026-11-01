/**
 * Difficulty configuration for progressive scaling.
 * Controls how speed and obstacle density increase over time.
 */
export interface DifficultyConfig {
  /** Starting forward speed (world units per second) */
  baseSpeed: number;
  /** Maximum forward speed cap */
  maxSpeed: number;
  /** Seconds between speed increases (per SC-008: 30 seconds) */
  speedIncreaseInterval: number;
  /** Starting obstacle spawn rate (obstacles per second) */
  baseDensity: number;
  /** Maximum obstacle spawn rate */
  maxDensity: number;
  /** Seconds to reach max density (per SC-009: 180 seconds / 3 minutes) */
  densityRampDuration: number;
}
