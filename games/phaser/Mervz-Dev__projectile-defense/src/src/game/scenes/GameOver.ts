import { Scene } from "phaser";
import { getHighScore, setHighScore } from "../../utils/high-score";

type GameOverData = {
  score?: number;
};

/**
 * Launched on top of the paused Game scene so the final frame stays visible.
 */
export class GameOver extends Scene {
  private score = 0;

  constructor() {
    super("GameOver");
  }

  init(data: GameOverData) {
    this.score = data.score ?? 0;
  }

  create() {
    const { width, height } = this.scale;
    const centerX = width / 2;
    const centerY = height / 2;
    const uiScale = this.responsive.scaleFactor;

    const previousBest = getHighScore();
    const isNewBest = this.score > previousBest;
    if (isNewBest) {
      setHighScore(this.score);
    }
    const best = Math.max(previousBest, this.score);

    this.add.rectangle(centerX, centerY, width, height, 0x000000, 0.6);

    this.add
      .text(centerX, centerY - 90 * uiScale, "GAME OVER", {
        fontSize: "48px",
        color: "#ff4444",
        fontStyle: "bold",
      })
      .setOrigin(0.5)
      .setScale(uiScale);

    const name = this.registry.get("name") as string | undefined;
    const scoreLine = name
      ? `${name}  -  Score: ${this.score}`
      : `Score: ${this.score}`;

    this.add
      .text(centerX, centerY - 30 * uiScale, scoreLine, {
        fontSize: "24px",
        color: "#ffffff",
      })
      .setOrigin(0.5)
      .setScale(uiScale);

    this.add
      .text(centerX, centerY + 5 * uiScale, `Best: ${best}`, {
        fontSize: "24px",
        color: "#ffdd55",
      })
      .setOrigin(0.5)
      .setScale(uiScale);

    if (isNewBest) {
      this.add
        .text(centerX, centerY + 38 * uiScale, "New best!", {
          fontSize: "20px",
          color: "#00ff88",
          fontStyle: "bold",
        })
        .setOrigin(0.5)
        .setScale(uiScale);
    }

    const restartButton = this.add
      .text(centerX, centerY + 90 * uiScale, "Restart", {
        fontSize: "24px",
        color: "#00ff00",
        backgroundColor: "#000000",
        padding: { x: 10, y: 5 },
      })
      .setOrigin(0.5)
      .setScale(uiScale)
      .setInteractive({ useHandCursor: true });

    restartButton.on("pointerover", () => {
      restartButton.setStyle({ color: "#ffff00" });
    });
    restartButton.on("pointerout", () => {
      restartButton.setStyle({ color: "#00ff00" });
    });
    restartButton.on("pointerdown", () => this.restart());

    this.input.keyboard?.once("keydown-SPACE", () => this.restart());
    this.input.keyboard?.once("keydown-ENTER", () => this.restart());
  }

  private restart() {
    // Stops this scene and restarts the (paused) Game scene from scratch.
    this.scene.start("Game");
  }
}
