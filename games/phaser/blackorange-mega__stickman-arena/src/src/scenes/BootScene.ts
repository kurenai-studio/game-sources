import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "../config";
import { GameContent } from "../ContentLoader";

/**
 * Phase 1 of startup: fetch all JSON content (no Phaser asset loading here),
 * stash it in the registry, then hand off to PreloadScene which loads sprites.
 *
 * Note we do NOT use Phaser's loader in this scene. Kicking off `this.load`
 * during an async create stalls the scene lifecycle, so JSON is fetched with
 * plain `fetch()` and the transition happens from a resolved promise.
 */
export class BootScene extends Phaser.Scene {
  constructor() {
    super("Boot");
  }

  create(): void {
    this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2, "Loading…", {
        fontSize: "28px",
        color: "#ffffff",
      })
      .setOrigin(0.5);

    GameContent.fetchData()
      .then((content) => {
        this.registry.set("content", content);
        this.registry.set("stageIndex", 0);
        this.scene.start("Preload");
      })
      .catch((err) => {
        this.add
          .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 40, `Failed to load content:\n${err}`, {
            fontSize: "16px",
            color: "#ff8080",
            align: "center",
            wordWrap: { width: GAME_WIDTH - 80 },
          })
          .setOrigin(0.5);
      });
  }
}
