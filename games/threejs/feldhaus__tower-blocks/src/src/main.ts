import { Game } from './game';

const game = new Game();

function onResize(): void {
  game.resize(window.innerWidth, window.innerHeight);
}

function onTouchStart(event: TouchEvent): void {
  event.preventDefault();
  game.action();
}

function onMouseDown(event: MouseEvent): void {
  event.preventDefault();
  game.action();
}

function onKeyDown(event: KeyboardEvent): void {
  if (event.code === 'Space') {
    game.action();
  }
}

function onLoad(): void {
  game.prepare(window.innerWidth, window.innerHeight, window.devicePixelRatio);
  game.start();

  window.addEventListener('resize', onResize, false);
  window.addEventListener('orientationchange', onResize, false);
  window.addEventListener('touchstart', onTouchStart, { passive: false });
  window.addEventListener('mousedown', onMouseDown, false);
  window.addEventListener('keydown', onKeyDown, false);
}

window.addEventListener('load', onLoad, false);
