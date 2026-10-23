import Phaser from 'phaser';
import GameScene from './scenes/GameScene.js';
import { GAME_WIDTH, GAME_HEIGHT, GRAVITY } from './config.js';

let gameInstance = null;

export function createGame(parent) {
  if (gameInstance) {
    gameInstance.destroy(true);
    gameInstance = null;
  }

  const config = {
    type: Phaser.AUTO,
    width: GAME_WIDTH,
    height: GAME_HEIGHT,
    parent,
    backgroundColor: '#87CEEB',
    physics: {
      default: 'matter',
      matter: {
        gravity: { y: GRAVITY },
        debug: false,
      },
    },
    scene: [GameScene],
    audio: {
      noAudio: false,
    },
  };

  gameInstance = new Phaser.Game(config);
  window.game = gameInstance;
  return gameInstance;
}

export function destroyGame() {
  if (gameInstance) {
    gameInstance.destroy(true);
    gameInstance = null;
    window.game = null;
  }
}

export function getGame() {
  return gameInstance;
}
