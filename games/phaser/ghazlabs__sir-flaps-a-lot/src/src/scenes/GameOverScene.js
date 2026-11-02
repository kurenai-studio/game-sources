import { GAME_COLORS, GAME_HEIGHT, GAME_WIDTH } from "../game.js";

export class GameOverScene extends Phaser.Scene {
  constructor() {
    super("GameOverScene");
  }

  create(data) {
    const score = data?.score ?? 0;
    this.cameras.main.setBackgroundColor(GAME_COLORS.sky);
    const wrapWidth = GAME_WIDTH - 48;

    this.add
      .text(GAME_WIDTH / 2, 170, "Thou Hast Perished!", {
        fontSize: "40px",
        fontStyle: "bold",
        color: "#dc2626",
        align: "center",
        wordWrap: { width: wrapWidth, useAdvancedWrap: true },
      })
      .setOrigin(0.5);

    this.add
      .text(GAME_WIDTH / 2, 280, `Final Glory: ${score}`, {
        fontSize: "32px",
        color: "#f8fafc",
        align: "center",
        wordWrap: { width: wrapWidth, useAdvancedWrap: true },
      })
      .setOrigin(0.5);

    this.add
      .text(
        GAME_WIDTH / 2,
        GAME_HEIGHT / 2 + 70,
        "Tap/SPACE to attempt another flight\nPress M to return to the main hall",
        {
          fontSize: "20px",
          color: "#d4af37",
          align: "center",
          lineSpacing: 10,
          wordWrap: { width: wrapWidth, useAdvancedWrap: true },
        }
      )
      .setOrigin(0.5);

    this.input.once("pointerdown", () => this.scene.start("GameScene"));
    this.input.keyboard.once("keydown-SPACE", () => this.scene.start("GameScene"));
    this.input.keyboard.once("keydown-M", () => this.scene.start("MenuScene"));
  }
}
