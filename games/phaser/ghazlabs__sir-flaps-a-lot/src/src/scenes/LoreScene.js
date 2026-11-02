import { GAME_COLORS, GAME_HEIGHT, GAME_WIDTH } from "../game.js";

export class LoreScene extends Phaser.Scene {
  constructor() {
    super("LoreScene");
  }

  create() {
    this.cameras.main.setBackgroundColor(GAME_COLORS.sky);
    const wrapWidth = GAME_WIDTH - 48;

    this.add
      .text(GAME_WIDTH / 2, 110, "Chronicles of Sir Flaps-a-Lot", {
        fontSize: "30px",
        fontStyle: "bold",
        color: "#f8fafc",
        align: "center",
        wordWrap: { width: wrapWidth, useAdvancedWrap: true },
      })
      .setOrigin(0.5);

    const loreLines = [
      "In a kingdom of towers and terrible drafts,",
      "one noble geometric knight took to the skies.",
      "His quest: outflap fate, dodge the cursed gates,",
      "and bring honor to polygons everywhere.",
    ];

    this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 - 22, loreLines.join("\n"), {
        fontSize: "21px",
        color: "#e2e8f0",
        align: "center",
        lineSpacing: 10,
        wordWrap: { width: wrapWidth, useAdvancedWrap: true },
      })
      .setOrigin(0.5);

    this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT - 120, "Tap or press SPACE to begin thy quest", {
        fontSize: "19px",
        color: "#d4af37",
        align: "center",
        wordWrap: { width: wrapWidth, useAdvancedWrap: true },
      })
      .setOrigin(0.5);

    this.input.once("pointerdown", () => this.scene.start("MenuScene"));
    this.input.keyboard.once("keydown-SPACE", () => this.scene.start("MenuScene"));
  }
}
