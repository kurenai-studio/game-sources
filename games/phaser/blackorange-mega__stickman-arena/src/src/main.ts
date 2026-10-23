import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "./config";
import { BootScene } from "./scenes/BootScene";
import { PreloadScene } from "./scenes/PreloadScene";
import { MenuScene } from "./scenes/MenuScene";
import { FightScene } from "./scenes/FightScene";
import { ResultScene } from "./scenes/ResultScene";

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: "game",
  backgroundColor: "#0f1117",
  width: GAME_WIDTH,
  height: GAME_HEIGHT,
  // Scale to fit any screen (web, Android, iOS) while keeping the aspect ratio.
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  physics: {
    default: "arcade",
    arcade: {
      gravity: { x: 0, y: 0 }, // per-fighter gravity is set on each body
      debug: false,
    },
  },
  // BootScene fetches JSON, PreloadScene loads sprites, then the game begins.
  scene: [BootScene, PreloadScene, MenuScene, FightScene, ResultScene],
});

// Dev-only handle for debugging in the browser console (stripped in builds).
if (import.meta.env.DEV) {
  (window as Window & { __game?: Phaser.Game }).__game = game;
}
