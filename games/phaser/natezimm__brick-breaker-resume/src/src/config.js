import { preload, create, update } from './game.js';

export function createConfig(Phaser) {
  return {
    type: Phaser.AUTO,
    width: window.innerWidth,
    height: window.innerHeight,
    parent: 'app',
    // The page draws the backdrop behind a clear canvas; see styles/themes.css.
    transparent: true,
    resolution: window.devicePixelRatio,
    dom: {
      createContainer: true,
    },
    physics: {
      default: 'arcade',
      arcade: {
        gravity: { y: 0 },
        debug: false,
      },
    },
    scene: {
      preload,
      create,
      update,
    },
  };
}
