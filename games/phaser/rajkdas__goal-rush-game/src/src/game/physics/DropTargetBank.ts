/**
 * GOAL RUSH — Drop-target bank.
 *
 * Four standing golden plates. Each hit drops that plate out of play
 * (collision mask zeroed — cheaper and safer than removing/re-adding
 * bodies). Clearing the whole bank triggers the GOLDEN SPIN bonus and the
 * bank resets.
 */

import * as Phaser from 'phaser';
import { PALETTE, PALETTE_CSS } from '../config/game.config';
import type { DropTargetDef } from '../config/table.config';

interface TargetUnit {
  def: DropTargetDef;
  image: Phaser.GameObjects.Image;
  body: MatterJS.BodyType;
  down: boolean;
}

export class DropTargetBank {
  private units: TargetUnit[] = [];
  private resetTimer: Phaser.Time.TimerEvent | null = null;
  /** Flash overlay shown while the bank is "hot" (about to be cleared). */
  private bankLabel: Phaser.GameObjects.Text;

  constructor(
    private scene: Phaser.Scene,
    defs: DropTargetDef[],
    private onTargetHit: (index: number, remaining: number) => void,
    private onBankComplete: () => void
  ) {
    this.bankLabel = scene.add
      .text(190, 506, 'GOLDEN BANK', {
        fontFamily: '"Arial Black", sans-serif',
        fontSize: '20px',
        color: PALETTE_CSS.jackpot,
        stroke: '#3a2a05',
        strokeThickness: 4,
        shadow: { offsetX: 0, offsetY: 2, color: '#04060c', blur: 6, stroke: true, fill: true },
        resolution: 2,
      })
      .setOrigin(0.5)
      .setDepth(4);
    scene.add
      .text(190, 530, 'CLEAR ALL 4 → GOLDEN SPIN', {
        fontFamily: 'sans-serif',
        fontSize: '11px',
        color: PALETTE_CSS.dim,
        resolution: 2,
      })
      .setOrigin(0.5)
      .setDepth(4);

    for (const def of defs) {
      const image = scene.add
        .image(def.x, def.y, 'atlas', 'drop-target')
        .setDepth(4)
        .setRotation(def.angle ?? 0);
      const body = scene.matter.add.rectangle(def.x, def.y, def.width, def.height, {
        isStatic: true,
        angle: def.angle ?? 0,
        restitution: 0.5,
        friction: 0,
        label: 'drop',
        chamfer: { radius: 5 },
      }) as MatterJS.BodyType;
      this.units.push({ def, image, body, down: false });
    }
  }

  /** A ball touched target `index`. Returns true if it was standing. */
  hit(index: number): boolean {
    const unit = this.units[index];
    if (!unit || unit.down) return false;
    unit.down = true;
    unit.body.collisionFilter.mask = 0; // drop out of play

    this.scene.tweens.add({
      targets: unit.image,
      y: unit.image.y + 10,
      alpha: 0.25,
      duration: 180,
      ease: 'Quad.easeIn',
    });

    const remaining = this.units.filter((u) => !u.down).length;
    this.onTargetHit(index, remaining);

    if (remaining === 0) {
      this.onBankComplete();
      this.resetTimer = this.scene.time.addEvent({
        delay: 1700,
        callback: this.reset,
        callbackScope: this,
      });
    }
    return true;
  }

  /** Which standing target (if any) owns this body label/id. */
  indexFromBody(body: MatterJS.BodyType): number {
    return this.units.findIndex((u) => u.body.id === body.id && !u.down);
  }

  reset(): void {
    this.resetTimer?.remove();
    this.resetTimer = null;
    for (const unit of this.units) {
      unit.down = false;
      unit.body.collisionFilter.mask = 0xffffffff;
      this.scene.tweens.add({
        targets: unit.image,
        y: unit.def.y,
        alpha: 1,
        duration: 260,
        ease: 'Back.easeOut',
      });
    }
    this.bankLabel.setColor(PALETTE_CSS.jackpot);
  }

  /** Pulse the label when one target remains (near-miss tension). */
  markHot(): void {
    this.bankLabel.setColor(PALETTE_CSS.magenta);
    this.scene.tweens.add({
      targets: this.bankLabel,
      alpha: 0.35,
      yoyo: true,
      repeat: 3,
      duration: 130,
    });
  }

  destroy(): void {
    this.resetTimer?.remove();
  }
}
