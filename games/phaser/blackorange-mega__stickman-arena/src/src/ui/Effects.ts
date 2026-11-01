import Phaser from "phaser";
import type { AttackKind } from "../Fighter";

/**
 * Transient combat visuals: attack swings, hit sparks, and floating damage
 * numbers. Kept separate from the fighters so the game logic stays readable.
 * Every effect cleans itself up when its tween finishes.
 */
export class Effects {
  constructor(private scene: Phaser.Scene) {}

  /** A slashing arc in front of a fighter as they attack. */
  swing(x: number, y: number, facing: 1 | -1, kind: AttackKind): void {
    const color =
      kind === "special" ? 0xff5252 : kind === "heavy" ? 0xffa726 : 0xffffff;

    const arc = this.scene.add
      .arc(x + facing * 42, y - 96, 54, -68, 68, false)
      .setStrokeStyle(6, color, 0.95)
      .setClosePath(false)
      .setRotation(facing === -1 ? Math.PI : 0)
      .setDepth(1400)
      .setScale(0.6);

    this.scene.tweens.add({
      targets: arc,
      scale: 1.15,
      alpha: { from: 0.95, to: 0 },
      duration: 220,
      ease: "Quad.easeOut",
      onComplete: () => arc.destroy(),
    });
  }

  /** A burst where a hit connects. Blocked hits get a cooler, smaller spark. */
  spark(x: number, y: number, guarded: boolean): void {
    const color = guarded ? 0x66ccff : 0xfff176;
    const burst = this.scene.add
      .circle(x, y, guarded ? 12 : 16, color, 0.9)
      .setDepth(1400);
    this.scene.tweens.add({
      targets: burst,
      scale: guarded ? 1.6 : 2.2,
      alpha: 0,
      duration: 200,
      ease: "Quad.easeOut",
      onComplete: () => burst.destroy(),
    });
  }

  /** A rising, fading damage number (or "BLOCK") above the target. */
  damageNumber(x: number, y: number, amount: number, guarded: boolean): void {
    const label = guarded ? `BLOCK -${amount}` : `-${amount}`;
    const text = this.scene.add
      .text(x, y, label, {
        fontSize: guarded ? "18px" : "28px",
        color: guarded ? "#90caf9" : "#ff5252",
        fontStyle: "bold",
        stroke: "#000000",
        strokeThickness: 4,
      })
      .setOrigin(0.5)
      .setDepth(1500);

    this.scene.tweens.add({
      targets: text,
      y: y - 52,
      alpha: { from: 1, to: 0 },
      duration: 700,
      ease: "Quad.easeOut",
      onComplete: () => text.destroy(),
    });
  }
}
