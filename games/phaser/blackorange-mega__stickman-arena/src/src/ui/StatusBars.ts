import Phaser from "phaser";
import type { Fighter } from "../Fighter";

/**
 * The top-of-screen HUD for one fighter: name, HP bar, and stamina bar.
 * `align` decides which corner it anchors to and which way the bars drain.
 */
export class StatusBars {
  private hpFill: Phaser.GameObjects.Rectangle;
  private staminaFill: Phaser.GameObjects.Rectangle;
  private readonly barWidth = 360;

  constructor(
    private scene: Phaser.Scene,
    private fighter: Fighter,
    align: "left" | "right"
  ) {
    const margin = 24;
    const x = align === "left" ? margin : scene.scale.width - margin - this.barWidth;
    const topY = 22;
    const originX = align === "left" ? 0 : 1;
    const fillX = align === "left" ? x : x + this.barWidth;

    // Name
    scene.add
      .text(fillX, topY - 4, fighter.def.name, {
        fontSize: "20px",
        color: "#ffffff",
        fontStyle: "bold",
      })
      .setOrigin(originX, 1)
      .setScrollFactor(0)
      .setDepth(900);

    // HP bar (background + fill)
    this.bg(x, topY, this.barWidth, 22);
    this.hpFill = scene.add
      .rectangle(fillX, topY, this.barWidth, 22, 0x2ecc71)
      .setOrigin(originX, 0)
      .setScrollFactor(0)
      .setDepth(901);

    // Stamina bar, thinner, just below
    const staminaY = topY + 28;
    this.bg(x, staminaY, this.barWidth, 12);
    this.staminaFill = scene.add
      .rectangle(fillX, staminaY, this.barWidth, 12, 0xf1c40f)
      .setOrigin(originX, 0)
      .setScrollFactor(0)
      .setDepth(901);
  }

  private bg(x: number, y: number, w: number, h: number): void {
    this.scene.add
      .rectangle(x, y, w, h, 0x000000, 0.55)
      .setOrigin(0, 0)
      .setScrollFactor(0)
      .setDepth(900)
      .setStrokeStyle(2, 0xffffff, 0.25);
  }

  /** Call every frame to reflect the fighter's current HP/stamina. */
  update(): void {
    const hpPct = Phaser.Math.Clamp(this.fighter.hp / this.fighter.stats.maxHp, 0, 1);
    const stPct = Phaser.Math.Clamp(
      this.fighter.stamina / this.fighter.stats.maxStamina,
      0,
      1
    );
    this.hpFill.width = this.barWidth * hpPct;
    this.staminaFill.width = this.barWidth * stPct;

    // Shift HP color from green -> orange -> red as it drops.
    const color = hpPct > 0.5 ? 0x2ecc71 : hpPct > 0.25 ? 0xe67e22 : 0xe74c3c;
    this.hpFill.setFillStyle(color);
  }
}
