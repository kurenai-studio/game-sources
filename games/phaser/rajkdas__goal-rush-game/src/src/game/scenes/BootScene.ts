/**
 * GOAL RUSH — BootScene.
 *
 * Generates every procedural texture (atlas + field artwork), then hands
 * over to the PlayScene. Keeping asset generation in one place makes the
 * runtime "asset pipeline" explicit and testable.
 */

import * as Phaser from 'phaser';
import { buildAtlas } from '../gfx/TextureFactory';
import { paintField } from '../gfx/FieldPainter';

export class BootScene extends Phaser.Scene {
  constructor() {
    super('Boot');
  }

  create(): void {
    buildAtlas(this);
    paintField(this);
    this.scene.start('Play');
  }
}
