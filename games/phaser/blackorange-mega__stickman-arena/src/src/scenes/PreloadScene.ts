import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "../config";
import { GameContent } from "../ContentLoader";

/**
 * Phase 2 of startup: load every character sprite through Phaser's loader — the
 * native way, inside `preload()`, so the engine waits for it before `create()`.
 * Shows a simple progress bar, then transitions to the menu.
 */
export class PreloadScene extends Phaser.Scene {
  constructor() {
    super("Preload");
  }

  preload(): void {
    const content = this.registry.get("content") as GameContent;

    // A minimal progress bar.
    const barW = 420;
    const x = (GAME_WIDTH - barW) / 2;
    const y = GAME_HEIGHT / 2;
    this.add.rectangle(x, y, barW, 16, 0x333a47).setOrigin(0, 0.5);
    const fill = this.add.rectangle(x, y, 0, 16, 0x4fc3f7).setOrigin(0, 0.5);
    this.add
      .text(GAME_WIDTH / 2, y - 30, "Loading assets…", { fontSize: "18px", color: "#ffffff" })
      .setOrigin(0.5);
    this.load.on(Phaser.Loader.Events.PROGRESS, (p: number) => {
      fill.width = barW * p;
    });

    content.queueSprites(this);
  }

  create(): void {
    this.scene.start("Menu");
  }
}
