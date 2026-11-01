import { createEngine, createScene } from './core';
import { Game } from './game';

const canvas = document.querySelector('canvas');

if (!canvas) {
  throw new Error('Game canvas not found');
}

const engine = createEngine(canvas);
const scene = createScene(engine);
const game = new Game(engine, scene);

game.start();

document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    game.pauseOnBlur();
  }
});

document.addEventListener('beforeunload', () => {
  game.dispose();
});
