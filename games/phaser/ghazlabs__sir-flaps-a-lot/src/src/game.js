import Phaser from "phaser";
import { LoreScene } from "./scenes/LoreScene.js";
import { MenuScene } from "./scenes/MenuScene.js";
import { GameScene } from "./scenes/GameScene.js";
import { GameOverScene } from "./scenes/GameOverScene.js";

export const GAME_WIDTH = 480;
export const GAME_HEIGHT = 720;

export const GAME_COLORS = {
  sky: 0x1e3a5f,
  stoneDark: 0x334155,
  stoneLight: 0x64748b,
  gold: 0xd4af37,
  cream: 0xf8fafc,
  danger: 0xdc2626,
};

export const GAME_BALANCE = {
  gravityY: 1080,
  flapVelocity: -440,
  obstacleSpeed: 172,
  obstacleSpeedRamp: 1.25,
  firstObstacleDelayMs: 320,
  obstacleSpawnMs: 1450,
  obstacleWidth: 82,
  initialGapHeight: 246,
  minimumGapHeight: 182,
  gapShrinkEveryScore: 12,
};

new Phaser.Game({
  type: Phaser.AUTO,
  width: GAME_WIDTH,
  height: GAME_HEIGHT,
  parent: "game-root",
  backgroundColor: GAME_COLORS.sky,
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: GAME_WIDTH,
    height: GAME_HEIGHT,
  },
  physics: {
    default: "arcade",
    arcade: {
      gravity: { y: GAME_BALANCE.gravityY },
      debug: false,
    },
  },
  scene: [LoreScene, MenuScene, GameScene, GameOverScene],
});
