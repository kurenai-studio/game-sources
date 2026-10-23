import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "../config";

interface ResultData {
  win: boolean;
  /** Stage number reached, for the defeat screen. */
  stage?: number;
}

/** Shown after a fight ends: victory (campaign complete) or defeat. */
export class ResultScene extends Phaser.Scene {
  constructor() {
    super("Result");
  }

  create(data: ResultData): void {
    this.cameras.main.setBackgroundColor(data.win ? "#102718" : "#241010");

    this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 - 60, data.win ? "YOU WIN!" : "DEFEATED", {
        fontSize: "72px",
        color: data.win ? "#69f0ae" : "#ff5252",
        fontStyle: "bold",
      })
      .setOrigin(0.5);

    const subtitle = data.win
      ? "You cleared every stage. Champion of the Arena!"
      : `You fell at stage ${data.stage ?? "?"}. Try again.`;
    this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 10, subtitle, {
        fontSize: "22px",
        color: "#eceff1",
        align: "center",
        wordWrap: { width: GAME_WIDTH - 120 },
      })
      .setOrigin(0.5);

    const prompt = this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 90, "TAP / PRESS TO RETURN TO MENU", {
        fontSize: "20px",
        color: "#ffffff",
      })
      .setOrigin(0.5);
    this.tweens.add({ targets: prompt, alpha: 0.3, duration: 700, yoyo: true, repeat: -1 });

    const back = () => this.scene.start("Menu");
    // Small delay so the player doesn't skip it with a leftover tap.
    this.time.delayedCall(600, () => {
      this.input.once("pointerdown", back);
      this.input.keyboard?.once("keydown", back);
    });
  }
}
