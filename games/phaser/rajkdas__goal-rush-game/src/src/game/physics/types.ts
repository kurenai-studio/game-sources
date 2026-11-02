/**
 * GOAL RUSH — shared physics type aliases.
 */

import type Phaser from 'phaser';

/** The ball as seen by helper classes (decoupled from PlayScene). */
export interface BallRef {
  /** Matter image of the ball. */
  readonly image: Phaser.Physics.Matter.Image;
  /** False while captured by the saucer or between balls. */
  active: boolean;
  /** Convenience accessors used by helpers. */
  readonly x: number;
  readonly y: number;
  setVelocity(x: number, y: number): void;
}

/** Callback signature for "the ball touched a scoring element". */
export type ScoreCallback = (kind: string, meta?: unknown) => void;
