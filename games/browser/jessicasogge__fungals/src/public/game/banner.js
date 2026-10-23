// Shared end-of-level pop-up for game.js and mold.js.
// Main button advances, restarts, or retries; "Start over" returns to level 1.
import { goTo } from './loading.js';

export function levelBanner(level) {
  let nextLevel = level;
  function goToLevel(n) {
    const url = new URL(window.location.href);
    url.searchParams.set('level', n);
    goTo(url.toString());
  }
  document.querySelector('.play-again').addEventListener('click', () => goToLevel(nextLevel));
  document.querySelector('.start-over').addEventListener('click', () => goToLevel(1));

  return {
    // Show the pop-up; its main button says `button` and goes to level `next`.
    show(title, message, button, { next = level, startOver = false } = {}) {
      nextLevel = next;
      const banner = document.querySelector('.win-banner');
      banner.querySelector('h2').textContent = title;
      banner.querySelector('.win-message').textContent = message;
      banner.querySelector('.play-again').textContent = button;
      banner.querySelector('.start-over').hidden = !startOver;
      banner.removeAttribute('hidden');
      banner.querySelector('.play-again').focus();
    },
  };
}
