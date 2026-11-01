// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
import * as Phaser from 'phaser';
import { makeTextures } from './textures';

/** Draws every sprite once, then hands over to the Yard. */
export class BootScene extends Phaser.Scene {
  constructor() {
    super('boot');
  }

  create(): void {
    makeTextures(this);
    this.scene.start('game');
  }
}
