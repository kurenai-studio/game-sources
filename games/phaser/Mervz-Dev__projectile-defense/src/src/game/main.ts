import { getScreenSizeRatio } from "../utils/resize";
import { Preload } from "./scenes/Preload";
import { Game as MainGame } from "./scenes/Game";
import { GameOver } from "./scenes/GameOver";
import { AUTO, Game, Scale, Types } from "phaser";
import { ResponsiveDimensionsPlugin } from "./plugins/responsive-dimensions-plugin";

const { width, height } = getScreenSizeRatio();

const config: Types.Core.GameConfig = {
  type: AUTO,
  width,
  height,
  parent: "game-container",
  backgroundColor: "#1c253c",
  scene: [Preload, MainGame, GameOver],
  physics: {
    default: "arcade",
    arcade: {
      gravity: { x: 0, y: 0 },
      debug: false,
    },
  },
  scale: {
    mode: Scale.FIT,
    autoCenter: Scale.CENTER_BOTH,
  },
  input: {
    // Track several fingers so a player can hold "move" while tapping "fire".
    activePointers: 3,
  },
  plugins: {
    scene: [
      {
        key: "ResponsiveDimensionsPlugin",
        plugin: ResponsiveDimensionsPlugin,
        mapping: "responsive",
      },
    ],
  },
};

type Params = {
  name: string;
};

const StartGame = (parent: string, params?: Params) => {
  const game = new Game({ ...config, parent });
  if (params?.name) {
    game.registry.set("name", params.name);
  }

  return game;
};

export default StartGame;
