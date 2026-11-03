/* eslint-disable no-undef */
import Game from './game';

const game = new Game(window.innerWidth, window.innerHeight);

const onResize = (): void => {
  game.resize(window.innerWidth, window.innerHeight);
};

const onMove = (event: TouchEvent | MouseEvent): void => {
  event.preventDefault();

  if ('touches' in event) {
    game.move(event.touches[0].clientX, event.touches[0].clientY);
  } else {
    game.move(event.clientX, event.clientY);
  }
};

const onLoad = (): void => {
  document.body.appendChild(game.view);
  game.resize(window.innerWidth, window.innerHeight);

  function animate() {
    requestAnimationFrame(animate);
    game.update();
  }
  requestAnimationFrame(animate);

  window.addEventListener('resize', onResize, false);
  window.addEventListener('orientationchange', onResize, false);
  window.addEventListener('touchmove', onMove, false);
  window.addEventListener('mousemove', onMove, false);
};

window.addEventListener('load', onLoad, false);
