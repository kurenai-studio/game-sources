import '@babylonjs/core/Audio/audioSceneComponent';

import { Sound } from '@babylonjs/core/Audio/sound';
import type { Scene } from '@babylonjs/core/scene';

/**
 * SoundManager - Simple sound effect manager for SFX.
 * Handles loading and playing of game sound effects.
 */
export class SoundManager {
  readonly jump: Sound;
  readonly duck: Sound;
  readonly move: Sound;
  readonly collide: Sound;
  readonly click: Sound;

  constructor(scene: Scene) {
    this.jump = new Sound('jump', 'sounds/jump.mp3', scene);
    this.duck = new Sound('duck', 'sounds/duck.mp3', scene);
    this.move = new Sound('move', 'sounds/move.mp3', scene);
    this.collide = new Sound('collide', 'sounds/collide.mp3', scene);
    this.click = new Sound('click', 'sounds/click.mp3', scene);
  }

  dispose() {
    this.jump.dispose();
    this.duck.dispose();
    this.move.dispose();
    this.collide.dispose();
    this.click.dispose();
  }
}
