// main.mjs — bootstrap: lee window.GAME (artefacto del protocolo) y arranca el motor.
import { startGame } from './engine.mjs';

const GAME = window.GAME;
const overlay = document.getElementById('overlay');

if (overlay && GAME && GAME.platform && GAME.platform.texts) {
  const t = GAME.platform.texts;
  const titleEl = overlay.querySelector('[data-title]');
  const hintEl = overlay.querySelector('[data-hint]');
  if (titleEl) titleEl.textContent = t.title;
  if (hintEl) hintEl.textContent = t.hint;
}

startGame({ GAME, mount: document.body, overlay });
