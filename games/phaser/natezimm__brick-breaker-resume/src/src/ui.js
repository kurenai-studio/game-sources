import { getGameState } from './state.js';
import { settings } from './settings.js';
import { GAME_CONSTANTS } from './constants.js';

/*
 * The HUD (lives, controls, score) is DOM, styled per look in
 * styles/components.css. These helpers keep it in step with the scene state.
 */

const SCORE_BUMP_CLASS = 'is-bumped';

function formatScore(score) {
  return Number(score).toLocaleString('en-US');
}

function describeLives(container, count) {
  container.setAttribute(
    'aria-label',
    `${count} ${count === 1 ? 'life' : 'lives'} left`
  );
}

function getLivesTrack(container) {
  let track = container.querySelector('.hud-pips');
  if (!track) {
    track = document.createElement('span');
    track.className = 'hud-pips';
    container.appendChild(track);
  }
  return track;
}

/**
 * Draws one pip per life. Each entry in `state.livesBalls` can be destroyed
 * like a game object; a lost life stays in its slot as an empty ring so the
 * row shows how many are gone.
 */
export function createLivesDisplay(scene, state = getGameState(scene)) {
  state.livesBalls = [];

  const container = document.getElementById('hudLives');
  const track = container ? getLivesTrack(container) : null;
  if (track) track.textContent = '';

  for (let i = 0; i < state.lives; i++) {
    const pip = document.createElement('span');
    pip.className = 'hud-pip';
    track?.appendChild(pip);

    state.livesBalls.push({
      element: pip,
      destroy() {
        pip.classList.add('is-lost');
        if (container) describeLives(container, state.livesBalls.length);
      },
    });
  }

  if (container) describeLives(container, state.livesBalls.length);
}

/**
 * Binds the score readout. `state.scoreText` keeps the small interface the
 * state and settings modules already call, backed by DOM instead of canvas.
 */
export function createScoreText(scene, state = getGameState(scene)) {
  if (state.scoreText) state.scoreText.destroy();

  const group = document.getElementById('hudScore');
  const value = document.getElementById('hudScoreValue');
  const best = document.getElementById('hudBestValue');
  let shown = null;

  const render = (score = state.score) => {
    const points = Number(score) || 0;
    const highScore = Math.max(state.highScore, points);

    if (value) {
      value.textContent = formatScore(points);
      if (shown !== null && points !== shown) {
        // Restart the bump animation on every change.
        value.classList.remove(SCORE_BUMP_CLASS);
        void value.offsetWidth;
        value.classList.add(SCORE_BUMP_CLASS);
      }
    }
    if (best) best.textContent = formatScore(highScore);
    group?.classList.toggle('is-best', points > 0 && points >= highScore);
    shown = points;
  };

  state.scoreText = {
    setText: render,
    updateScoreLabel: render,
    destroy() {
      value?.classList.remove(SCORE_BUMP_CLASS);
    },
  };
  render();
}

export function hideGameMessage() {
  const overlay = document.getElementById('gameMessageOverlay');
  if (overlay) {
    overlay.classList.add('hidden');
    overlay.textContent = '';
  }
}

export function startCountdown(scene, state = getGameState(scene)) {
  let countdown = state.currentCountdown;

  state.countdownInterval = setInterval(() => {
    countdown--;
    state.currentCountdown = countdown;

    if (countdown > 0) {
      updateCountdownDisplay(countdown);
    } else {
      hideGameMessage();
      state.ball.setVelocity(
        GAME_CONSTANTS.BALL_INITIAL_VELOCITY.x * settings.ballSpeed,
        GAME_CONSTANTS.BALL_INITIAL_VELOCITY.y * settings.ballSpeed
      );
      state.setPaused(false);
      clearInterval(state.countdownInterval);
      state.countdownInterval = null;
      state.currentCountdown = GAME_CONSTANTS.COUNTDOWN_START;
    }
  }, GAME_CONSTANTS.COUNTDOWN_INTERVAL);
}

function updateCountdownDisplay(value) {
  const overlay = document.getElementById('gameMessageOverlay');
  if (overlay) {
    overlay.classList.remove('hidden');
    overlay.textContent = '';

    const messageDiv = document.createElement('div');
    messageDiv.className = 'game-message gm-countdown';
    messageDiv.textContent =
      Number.isInteger(value) && value > 0 && value <= 9 ? value : '';
    overlay.appendChild(messageDiv);
  }
}

export function createCountdownText(scene, state = getGameState(scene)) {
  updateCountdownDisplay(state.currentCountdown);
}

export function showGameOver() {
  const overlay = document.getElementById('gameMessageOverlay');
  if (overlay) {
    overlay.classList.remove('hidden');
    overlay.textContent = '';

    const messageDiv = document.createElement('div');
    messageDiv.className = 'game-message gm-gameover';

    const gameOverText = document.createElement('div');
    gameOverText.textContent = 'GAME OVER';

    const subText = document.createElement('div');
    subText.className = 'sub-text';
    subText.textContent = 'Refresh to Try Again';

    messageDiv.appendChild(gameOverText);
    messageDiv.appendChild(subText);
    overlay.appendChild(messageDiv);
  }
}

export function showWinMessage(scene, state = getGameState(scene)) {
  state.gameEnded = true;
  const overlay = document.getElementById('gameMessageOverlay');
  if (overlay) {
    overlay.classList.remove('hidden');
    overlay.textContent = '';

    const container = document.createElement('div');
    container.className = 'gm-win-container';

    const victoryText = document.createElement('div');
    victoryText.className = 'game-message gm-win';
    victoryText.textContent = 'VICTORY!';

    const subText = document.createElement('div');
    subText.className = 'game-message gm-win-sub';
    subText.textContent = 'ALL BRICKS DESTROYED';

    container.appendChild(victoryText);
    container.appendChild(subText);
    overlay.appendChild(container);

    const colors = [
      '#ff0055',
      '#00ddff',
      '#00ffaa',
      '#ff9900',
      '#ffd300',
      '#ff00cc',
    ];

    for (let i = 0; i < 100; i++) {
      const confetti = document.createElement('div');
      confetti.classList.add('confetti-piece');
      confetti.style.left = Math.random() * 100 + '%';
      confetti.style.animation = `fall ${Math.random() * 3 + 2}s linear infinite`;
      confetti.style.animationDelay = Math.random() * 5 + 's';
      confetti.style.backgroundColor =
        colors[Math.floor(Math.random() * colors.length)];

      const size = Math.random() * 10 + 5;
      confetti.style.width = size + 'px';
      confetti.style.height = size + 'px';
      if (Math.random() > 0.5) confetti.style.borderRadius = '50%';

      overlay.appendChild(confetti);
    }
  }
}

export function togglePause(scene, state = getGameState(scene)) {
  const paused = state.togglePause();
  scene.physics.world.isPaused = paused;

  const pauseButton = document.getElementById('pauseButton');
  if (pauseButton) {
    pauseButton.textContent = '';
    const icon = document.createElement('i');
    icon.className = paused ? 'fas fa-play' : 'fas fa-pause';
    icon.setAttribute('aria-hidden', 'true');
    pauseButton.appendChild(icon);

    pauseButton.setAttribute(
      'aria-label',
      paused ? 'Resume game' : 'Pause game'
    );
    pauseButton.setAttribute('aria-pressed', paused ? 'true' : 'false');
    pauseButton.title = paused ? 'Resume' : 'Pause';
  }

  if (!paused && state.wasInCountdown) {
    state.wasInCountdown = false;
    createCountdownText(scene, state);
    startCountdown(scene, state);
  }
}

export function setupUIButtons(game) {
  const pauseButton = document.getElementById('pauseButton');
  if (pauseButton) {
    pauseButton.addEventListener('click', () => {
      const scene = game.scene.scenes[0];
      togglePause(scene, getGameState(scene));
    });
  }

  const highScoreButton = document.getElementById('highScoreButton');
  const highScoreModal = document.getElementById('highScoreModal');
  const closeHighScoreButton = document.getElementById('closeHighScoreModal');
  const highScoreValue = document.getElementById('highScoreValue');

  if (highScoreButton && highScoreModal) {
    highScoreButton.addEventListener('click', () => {
      highScoreModal.classList.add('active');
      if (highScoreValue) {
        highScoreValue.textContent = getGameState(
          game.scene.scenes[0]
        ).highScore;
      }

      const scene = game.scene.scenes[0];
      const state = getGameState(scene);
      if (scene && !state.paused) {
        togglePause(scene, state);
      }
    });
  }

  if (closeHighScoreButton && highScoreModal) {
    closeHighScoreButton.addEventListener('click', () => {
      highScoreModal.classList.remove('active');
    });
  }

  if (highScoreModal) {
    highScoreModal.addEventListener('click', (e) => {
      if (e.target === highScoreModal) {
        highScoreModal.classList.remove('active');
      }
    });
  }
}

export function setupWindowResize(game) {
  window.addEventListener('resize', () => {
    const width = window.innerWidth;
    const height = window.innerHeight;

    game.scale.resize(width, height);

    const scene = game.scene.scenes[0];
    const state = getGameState(scene);
    if (scene) {
      scene.physics.world.setBounds(0, 0, width, height);

      // The HUD is laid out by CSS; only the paddle needs moving.
      if (state.paddle) {
        state.paddle.y = height - 55;

        state.paddle.x = Math.max(
          state.paddle.width / 2,
          Math.min(state.paddle.x, width - state.paddle.width / 2)
        );
      }
    }
  });
}
