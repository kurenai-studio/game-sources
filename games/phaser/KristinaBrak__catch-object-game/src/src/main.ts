import "phaser";
import { GameScene } from "./game-scene";

const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  scale: {
    width: 800,
    height: 600,
  },
  physics: {
    default: "arcade",
    arcade: {
      debug: true,
    },
  },
  render: {
    pixelArt: true,
  },
  parent: "game",
  backgroundColor: "#765478",
  scene: GameScene,
};

const ws = new WebSocket("ws://localhost:32100");
ws.onopen = function () {
  ws.send("getStats");
  const game = new Phaser.Game(config);
  game.scene.start("Game", ws);
};
// game.scene.start("Game");
