import { THEMES, THEME_LOOKS } from './constants.js';
import { getGameState } from './state.js';
import { rebuildBricks } from './bricks.js';
import { refreshBallTexture, refreshPaddleTexture } from './textures.js';

const THEME_STORAGE_KEY = 'brickBreakerTheme';
// The look used until a visitor picks one on the start screen or in settings.
const DEFAULT_THEME = THEMES.DARK;

/**
 * @typedef {Object} GameSettings
 * @property {boolean} soundEnabled
 * @property {number} ballColor
 * @property {number} paddleColor
 * @property {number} paddleWidth
 * @property {number} ballSpeed
 * @property {'light' | 'dark'} theme
 * @property {boolean} ballColorCustom true once the player picks a ball colour
 * @property {boolean} paddleColorCustom true once the player picks a paddle colour
 */

function updateDocumentTheme(theme) {
  if (typeof document === 'undefined' || !document.documentElement) {
    return;
  }

  document.documentElement.dataset.theme = theme;
}

if (typeof document !== 'undefined') {
  updateDocumentTheme(DEFAULT_THEME);
}

/** @type {GameSettings} */
export const settings = {
  soundEnabled: true,
  ballColor: THEME_LOOKS[DEFAULT_THEME].ball,
  paddleColor: THEME_LOOKS[DEFAULT_THEME].paddle,
  paddleWidth: 100,
  ballSpeed: 1.0,
  theme: DEFAULT_THEME,
  ballColorCustom: false,
  paddleColorCustom: false,
};

function toHexInput(color) {
  return `#${color.toString(16).padStart(6, '0')}`;
}

/**
 * Each theme brings its own ball and paddle colour. A colour the player has
 * picked is theirs and survives a theme switch.
 */
function applyLookColors(theme) {
  const look = THEME_LOOKS[theme];
  if (!settings.ballColorCustom) settings.ballColor = look.ball;
  if (!settings.paddleColorCustom) settings.paddleColor = look.paddle;

  syncAppearance();
}

/**
 * Publishes the ball and paddle appearance to the page. The HUD's life pips
 * and the settings preview are drawn from these custom properties, and the
 * colour controls show the same values.
 */
function syncAppearance() {
  if (typeof document === 'undefined') return;

  const ballColor = toHexInput(settings.ballColor);
  const paddleColor = toHexInput(settings.paddleColor);
  const rootStyle = document.documentElement.style;
  rootStyle.setProperty('--ball-color', ballColor);
  rootStyle.setProperty('--paddle-color', paddleColor);
  rootStyle.setProperty('--paddle-width', `${settings.paddleWidth}px`);

  const show = (pickerId, valueId, color) => {
    const picker = document.getElementById(pickerId);
    const value = document.getElementById(valueId);
    if (picker) picker.value = color;
    if (value) value.textContent = color;
  };
  show('ballColorPicker', 'ballColorValue', ballColor);
  show('paddleColorPicker', 'paddleColorValue', paddleColor);
}

/** Fills a slider's track up to its thumb; the track is styled in CSS. */
function paintRange(slider) {
  const min = parseFloat(slider.min) || 0;
  const max = parseFloat(slider.max) || 100;
  const value = parseFloat(slider.value) || 0;
  const filled = max > min ? ((value - min) / (max - min)) * 100 : 0;

  slider.style.setProperty(
    '--fill',
    `${Math.min(100, Math.max(0, filled)).toFixed(1)}%`
  );
}

function sanitizeTheme(theme) {
  if (theme === THEMES.DARK) {
    return THEMES.DARK;
  }
  if (theme === THEMES.LIGHT) {
    return THEMES.LIGHT;
  }
  return DEFAULT_THEME;
}

function readStoredTheme() {
  try {
    return sanitizeTheme(localStorage.getItem(THEME_STORAGE_KEY));
  } catch {
    return DEFAULT_THEME;
  }
}

function writeStoredTheme(theme) {
  try {
    localStorage.setItem(THEME_STORAGE_KEY, theme);
  } catch {
    // Ignore storage failures so private browsing or quota errors do not break play.
  }
}

export function getThemeColors(theme = settings.theme) {
  const normalizedTheme = sanitizeTheme(theme);
  return normalizedTheme === THEMES.DARK
    ? {
        theme: THEMES.DARK,
        background: '#060913',
        hudText: '#ffffff',
        hudTextMuted: '#a9b4c8',
      }
    : {
        theme: THEMES.LIGHT,
        background: '#f6f5f0',
        hudText: '#16181d',
        hudTextMuted: '#5b6170',
      };
}

function setTextFill(text, fill) {
  if (!text) return;
  if (typeof text.setStyle === 'function') {
    text.setStyle({ fill });
    return;
  }
  if (typeof text.setColor === 'function') {
    text.setColor(fill);
    return;
  }
  if (text.style) {
    text.style.fill = fill;
  }
}

export function applyThemeToScene(
  scene,
  theme = settings.theme,
  state = getGameState(scene)
) {
  if (!scene) return;
  const colors = getThemeColors(theme);

  // The page paints the backdrop (aurora or paper); the canvas stays clear
  // so it shows through.
  const camera = scene.cameras?.main;
  if (camera && typeof camera.setBackgroundColor === 'function') {
    camera.setBackgroundColor('rgba(0, 0, 0, 0)');
  }

  // Trails are only redrawn while playing, so wipe the old look's glow now.
  state.ballTrailGraphics?.clear?.();
  state.paddleTrailGraphics?.clear?.();
  state.ballTrailPoints = [];
  state.paddleTrailPoints = [];

  setTextFill(state.countdownText, colors.hudTextMuted);
  setTextFill(state.winText, colors.hudTextMuted);
}

export function initializeTheme() {
  const storedTheme = readStoredTheme();
  settings.theme = storedTheme;

  updateDocumentTheme(storedTheme);
  applyLookColors(storedTheme);

  return storedTheme;
}

export function applyTheme(theme, game) {
  const normalizedTheme = sanitizeTheme(theme);
  settings.theme = normalizedTheme;

  updateDocumentTheme(normalizedTheme);
  applyLookColors(normalizedTheme);

  writeStoredTheme(normalizedTheme);

  const scene = game?.scene?.scenes?.[0];
  if (!scene) return;

  const state = getGameState(scene);
  applyThemeToScene(scene, normalizedTheme, state);
  if (scene.textures) {
    refreshBallTexture(scene, state, settings);
    refreshPaddleTexture(scene, state, settings);
  }
  // The two themes lay the résumé out differently, so the wall is rebuilt.
  rebuildBricks(scene, state);
}

export function setupSettings(game) {
  const modal = document.getElementById('settingsModal');
  const settingsButton = document.getElementById('settingsButton');
  const closeButton = document.getElementById('closeModal');
  const soundToggle = document.getElementById('soundToggle');
  const themeOptions = document.querySelectorAll('input[name="theme"]');
  const resetColorsButton = document.getElementById('resetColors');
  const ballColorPicker = document.getElementById('ballColorPicker');
  const paddleColorPicker = document.getElementById('paddleColorPicker');
  const paddleWidthSlider = document.getElementById('paddleWidthSlider');
  const paddleWidthValue = document.getElementById('paddleWidthValue');
  const ballSpeedSlider = document.getElementById('ballSpeedSlider');
  const ballSpeedValue = document.getElementById('ballSpeedValue');
  const pauseButton = document.getElementById('pauseButton');
  const getScene = () => game.scene.scenes[0];

  applyLookColors(settings.theme);

  // Theme is a choice between two named looks, not an on/off switch.
  themeOptions.forEach((option) => {
    option.checked = option.value === settings.theme;
    option.addEventListener('change', () => {
      if (option.checked) applyTheme(option.value, game);
    });
  });

  if (resetColorsButton) {
    resetColorsButton.addEventListener('click', () => {
      settings.ballColorCustom = false;
      settings.paddleColorCustom = false;
      applyLookColors(settings.theme);
      updateBallTexture(getScene());
      updatePaddleTexture(getScene());
    });
  }

  settingsButton.addEventListener('click', () => {
    modal.classList.add('active');

    const scene = getScene();
    const state = getGameState(scene);

    if (scene && scene.physics) {
      if (state.countdownInterval) {
        clearInterval(state.countdownInterval);
        state.countdownInterval = null;
        state.wasInCountdown = true;

        // Hide the countdown overlay when opening settings
        const overlay = document.getElementById('gameMessageOverlay');
        if (overlay) {
          overlay.classList.add('hidden');
          overlay.textContent = '';
        }
      }

      state.setPaused(true);
      scene.physics.world.isPaused = true;

      if (pauseButton) {
        pauseButton.textContent = '';
        const icon = document.createElement('i');
        icon.className = 'fas fa-play';
        icon.setAttribute('aria-hidden', 'true');
        pauseButton.appendChild(icon);

        pauseButton.setAttribute('aria-label', 'Resume game');
        pauseButton.setAttribute('aria-pressed', 'true');
        pauseButton.title = 'Resume';
      }
    } else {
      console.error('Scene or physics not available');
    }
  });

  const closeModal = () => {
    modal.classList.remove('active');
  };

  closeButton.addEventListener('click', closeModal);

  modal.addEventListener('click', (e) => {
    if (e.target === modal) {
      closeModal();
    }
  });

  soundToggle.addEventListener('change', (e) => {
    settings.soundEnabled = e.target.checked;
    const scene = getScene();
    if (scene && scene.sound) {
      scene.sound.mute = !settings.soundEnabled;
    }
  });

  function isValidHexColor(color) {
    return /^#[0-9A-Fa-f]{6}$/.test(color);
  }

  ballColorPicker.addEventListener('input', (e) => {
    const color = e.target.value;
    if (!isValidHexColor(color)) {
      return;
    }
    settings.ballColor = parseInt(color.replace('#', '0x'));
    settings.ballColorCustom = true;
    syncAppearance();
    updateBallTexture(getScene());
  });

  paddleColorPicker.addEventListener('input', (e) => {
    const color = e.target.value;
    if (!isValidHexColor(color)) {
      return;
    }
    settings.paddleColor = parseInt(color.replace('#', '0x'));
    settings.paddleColorCustom = true;
    syncAppearance();
    updatePaddleTexture(getScene());
  });

  paddleWidthSlider.addEventListener('input', (e) => {
    const newWidth = parseInt(e.target.value, 10);
    const minWidth = parseInt(paddleWidthSlider.min, 10) || 20;
    const maxWidth = parseInt(paddleWidthSlider.max, 10) || 200;
    if (Number.isNaN(newWidth) || newWidth < minWidth || newWidth > maxWidth) {
      return;
    }
    settings.paddleWidth = newWidth;
    paddleWidthValue.textContent = newWidth;
    paintRange(paddleWidthSlider);
    syncAppearance();
    updatePaddleTexture(getScene());
  });

  ballSpeedSlider.addEventListener('input', (e) => {
    const newSpeed = parseFloat(e.target.value);
    const minSpeed = parseFloat(ballSpeedSlider.min) || 0.5;
    const maxSpeed = parseFloat(ballSpeedSlider.max) || 2.0;
    if (Number.isNaN(newSpeed) || newSpeed < minSpeed || newSpeed > maxSpeed) {
      return;
    }
    settings.ballSpeed = newSpeed;
    ballSpeedValue.textContent = newSpeed.toFixed(1);
    paintRange(ballSpeedSlider);
    updateBallSpeed(getScene());
  });

  paddleWidthSlider.max = Math.floor(window.innerWidth / 3);
  paintRange(paddleWidthSlider);
  paintRange(ballSpeedSlider);
}

function updateBallTexture(scene, state = getGameState(scene)) {
  refreshBallTexture(scene, state, settings);
}

function updatePaddleTexture(scene, state = getGameState(scene)) {
  refreshPaddleTexture(scene, state, settings);
}

function updateBallSpeed(scene, state = getGameState(scene)) {
  if (!scene || !state.ball || !state.ball.body) return;

  const currentVelocity = state.ball.body.velocity;
  if (currentVelocity.x !== 0 || currentVelocity.y !== 0) {
    const speed = Math.sqrt(
      currentVelocity.x * currentVelocity.x +
        currentVelocity.y * currentVelocity.y
    );
    const dirX = currentVelocity.x / speed;
    const dirY = currentVelocity.y / speed;

    const baseSpeed = 200;
    const newSpeed = baseSpeed * settings.ballSpeed;
    state.ball.setVelocity(dirX * newSpeed, dirY * newSpeed);
  }
}

export { updateBallTexture, updatePaddleTexture, updateBallSpeed };
