import { createConfig } from './src/config.js';
import { setupUIButtons, setupWindowResize } from './src/ui.js';
import { applyTheme, initializeTheme, setupSettings } from './src/settings.js';
import { enableSeamDrag, renderOverlayBricks } from './src/overlay.js';

initializeTheme();
renderOverlayBricks();
enableSeamDrag();

async function initGame() {
  const { default: Phaser } = await import('phaser');
  const config = createConfig(Phaser);
  const game = new Phaser.Game(config);
  setupUIButtons(game);
  setupWindowResize(game);
  setupSettings(game);
}

const startOverlay = document.getElementById('startOverlay');
const startButtons = document.querySelectorAll('[data-theme-choice]');

// How long the chosen look takes to sweep across; matches `--split` in base.css.
const SWEEP_DURATION = 550;

function prefersReducedMotion() {
  return (
    window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false
  );
}

/** Each half of the start screen starts the game in its own look. */
function startGame(theme) {
  applyTheme(theme);

  if (startOverlay) {
    // The chosen look sweeps across the whole screen as the overlay leaves,
    // from wherever a finger may have left the seam.
    startOverlay.classList.remove('is-dragging');
    startOverlay.style.removeProperty('--split');
    startOverlay.dataset.chosen = theme;
    startOverlay.classList.add('hidden');
  }
  startButtons.forEach((button) => {
    button.disabled = true;
  });

  // Booting Phaser ties up the main thread, which would freeze the sweep, so
  // the game starts once the sweep has finished.
  if (startOverlay && !prefersReducedMotion()) {
    window.setTimeout(initGame, SWEEP_DURATION);
  } else {
    initGame();
  }
}

startButtons.forEach((button) => {
  button.addEventListener('click', () => {
    startGame(button.dataset.themeChoice);
  });
});
