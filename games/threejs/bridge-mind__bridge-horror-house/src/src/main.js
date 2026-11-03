import { Game } from './Game.js';

const canvas = document.getElementById('game');
const game = new Game(canvas);

const title = document.getElementById('title-screen');
title.addEventListener('click', () => {
  title.classList.add('hidden');
  game.start();
}, { once: true });
