/**
 * Game state values for state machine transitions.
 * Represents the current state of the game session.
 */
export const GameStateEnum = {
  /** Initial state - display start screen */
  Start: 'START',
  /** Game is actively running - player controlling character */
  Running: 'RUNNING',
  /** Game is paused - all updates frozen */
  Paused: 'PAUSED',
  /** Game over - collision detected, awaiting restart */
  GameOver: 'GAME_OVER',
} as const;

export type GameStateEnum = (typeof GameStateEnum)[keyof typeof GameStateEnum];
