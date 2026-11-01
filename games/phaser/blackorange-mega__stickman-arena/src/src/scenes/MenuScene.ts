import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "../config";
import { GameContent } from "../ContentLoader";

/** Title screen + a quick controls reminder. Tap / press to begin. */
export class MenuScene extends Phaser.Scene {
  constructor() {
    super("Menu");
  }

  create(): void {
    const content = this.registry.get("content") as GameContent;
    this.cameras.main.setBackgroundColor("#0f1117");

    this.add
      .text(GAME_WIDTH / 2, 120, "STICKMAN ARENA", {
        fontSize: "64px",
        color: "#4fc3f7",
        fontStyle: "bold",
      })
      .setOrigin(0.5);

    this.add
      .text(GAME_WIDTH / 2, 185, `${content.campaign.stages.length} stages · defeat them all`, {
        fontSize: "20px",
        color: "#b0bec5",
      })
      .setOrigin(0.5);

    // Show the player character preview.
    const player = content.getCharacter(content.campaign.player);
    this.add
      .image(GAME_WIDTH / 2, 330, GameContent.textureKey(player))
      .setTint(
        player.tint
          ? Phaser.Display.Color.HexStringToColor(player.tint).color
          : 0xffffff
      )
      .setScale(1.1);

    const isTouch = this.sys.game.device.input.touch;
    const controls = isTouch
      ? "On-screen buttons:  ◀ ▶ move · GRD guard · JUMP · A light · B heavy · SP special"
      : "Keyboard:  A/D move · W/Space jump · S/↓ guard · J light · K heavy · L special";

    this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT - 110, controls, {
        fontSize: "16px",
        color: "#90a4ae",
        align: "center",
        wordWrap: { width: GAME_WIDTH - 80 },
      })
      .setOrigin(0.5);

    const prompt = this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT - 60, "TAP / PRESS ANY KEY TO START", {
        fontSize: "24px",
        color: "#ffffff",
        fontStyle: "bold",
      })
      .setOrigin(0.5);
    this.tweens.add({ targets: prompt, alpha: 0.3, duration: 700, yoyo: true, repeat: -1 });

    const start = () => {
      this.registry.set("stageIndex", 0);
      this.scene.start("Fight");
    };
    this.input.once("pointerdown", start);
    this.input.keyboard?.once("keydown", start);
  }
}
