import * as ui from '../src/ui.js';
import { gameState } from '../src/state.js';
import { settings } from '../src/settings.js';
import { createMockScene } from './mockScene.js';
import { GAME_CONSTANTS } from '../src/constants.js';

function captureResizeHandler() {
  const originalAddEventListener = window.addEventListener;
  let handler;
  window.addEventListener = jest.fn((event, callback) => {
    if (event === 'resize') {
      handler = callback;
    }
  });
  return {
    get handler() {
      return handler;
    },
    restore() {
      window.addEventListener = originalAddEventListener;
    },
  };
}

describe('ui helpers', () => {
  let scene;

  beforeEach(() => {
    jest.useRealTimers();
    document.body.innerHTML = `
      <div id="hudLives"></div>
      <div id="hudScore">
        <span id="hudBestValue"></span>
        <span id="hudScoreValue"></span>
      </div>
      <button id="pauseButton"></button>
      <button id="highScoreButton"></button>
      <div id="highScoreModal" class="modal"></div>
      <button id="closeHighScoreModal"></button>
      <span id="highScoreValue"></span>
    `;
    gameState.reset();
    scene = createMockScene();
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      value: 800,
    });
    Object.defineProperty(window, 'innerHeight', {
      writable: true,
      value: 600,
    });
  });

  test('createLivesDisplay draws one pip per life in the HUD', () => {
    gameState.lives = 3;

    ui.createLivesDisplay(scene);

    const container = document.getElementById('hudLives');
    expect(gameState.livesBalls).toHaveLength(3);
    expect(container.querySelectorAll('.hud-pip')).toHaveLength(3);
    expect(container.getAttribute('aria-label')).toBe('3 lives left');

    // Drawing again replaces the row instead of adding to it.
    gameState.lives = 2;
    ui.createLivesDisplay(scene);
    expect(container.querySelectorAll('.hud-pip')).toHaveLength(2);
    expect(container.querySelectorAll('.hud-pips')).toHaveLength(1);
  });

  test('a lost life stays in its slot as an empty ring', () => {
    gameState.lives = 2;
    ui.createLivesDisplay(scene);
    const container = document.getElementById('hudLives');

    gameState.decrementLives();

    const pips = container.querySelectorAll('.hud-pip');
    expect(pips).toHaveLength(2);
    expect(pips[0].classList.contains('is-lost')).toBe(false);
    expect(pips[1].classList.contains('is-lost')).toBe(true);
    expect(container.getAttribute('aria-label')).toBe('1 life left');
    expect(gameState.lives).toBe(1);
  });

  test('createLivesDisplay reuses an existing pip track', () => {
    document.getElementById('hudLives').innerHTML =
      '<span class="hud-label">Lives</span><span class="hud-pips"><i>old</i></span>';
    gameState.lives = 1;

    ui.createLivesDisplay(scene);

    const track = document.querySelector('#hudLives .hud-pips');
    expect(track.children).toHaveLength(1);
    expect(document.querySelector('#hudLives .hud-label')).not.toBeNull();
  });

  test('lives still count down when the HUD is not on the page', () => {
    document.getElementById('hudLives').remove();
    gameState.lives = 2;

    ui.createLivesDisplay(scene);
    expect(gameState.livesBalls).toHaveLength(2);

    expect(() => gameState.decrementLives()).not.toThrow();
    expect(gameState.livesBalls).toHaveLength(1);
  });

  test('the score readout follows the score and the best score', () => {
    gameState.highScore = 500;
    ui.createScoreText(scene);

    const value = document.getElementById('hudScoreValue');
    const best = document.getElementById('hudBestValue');
    const group = document.getElementById('hudScore');
    expect(value.textContent).toBe('0');
    expect(best.textContent).toBe('500');
    expect(group.classList.contains('is-best')).toBe(false);
    expect(value.classList.contains('is-bumped')).toBe(false);

    gameState.incrementScore(1240);

    expect(value.textContent).toBe('1,240');
    expect(best.textContent).toBe('1,240');
    expect(group.classList.contains('is-best')).toBe(true);
    expect(value.classList.contains('is-bumped')).toBe(true);
  });

  test('createScoreText rebinds cleanly and tolerates a missing HUD', () => {
    ui.createScoreText(scene);
    gameState.incrementScore(10);
    const value = document.getElementById('hudScoreValue');
    expect(value.classList.contains('is-bumped')).toBe(true);

    gameState.score = 0;
    ui.createScoreText(scene);
    expect(value.classList.contains('is-bumped')).toBe(false);
    expect(value.textContent).toBe('0');

    document.getElementById('hudScore').remove();
    ui.createScoreText(scene);
    expect(() => gameState.incrementScore(20)).not.toThrow();
    expect(() => gameState.scoreText.setText('not a number')).not.toThrow();
    expect(gameState.score).toBe(20);
  });

  test('startCountdown counts down then launches the ball', () => {
    jest.useFakeTimers();
    gameState.ball = { setVelocity: jest.fn() };
    gameState.countdownText = { setText: jest.fn(), destroy: jest.fn() };
    gameState.currentCountdown = GAME_CONSTANTS.COUNTDOWN_START;

    ui.startCountdown(scene);

    jest.advanceTimersByTime(
      GAME_CONSTANTS.COUNTDOWN_INTERVAL * GAME_CONSTANTS.COUNTDOWN_START
    );

    expect(gameState.ball.setVelocity).toHaveBeenCalledWith(
      GAME_CONSTANTS.BALL_INITIAL_VELOCITY.x * settings.ballSpeed,
      GAME_CONSTANTS.BALL_INITIAL_VELOCITY.y * settings.ballSpeed
    );
    expect(gameState.paused).toBe(false);
    expect(gameState.countdownInterval).toBeNull();
    expect(gameState.currentCountdown).toBe(GAME_CONSTANTS.COUNTDOWN_START);
  });

  test('createCountdownText renders countdown indicator', () => {
    document.body.innerHTML =
      '<div id="gameMessageOverlay" class="hidden"></div>';
    gameState.currentCountdown = 3;
    ui.createCountdownText(scene);

    const overlay = document.getElementById('gameMessageOverlay');
    expect(overlay.innerHTML).toContain('3');
    expect(overlay.classList.contains('hidden')).toBe(false);
  });

  test('showGameOver and showWinMessage render messages', () => {
    document.body.innerHTML =
      '<div id="gameMessageOverlay" class="hidden"></div>';

    ui.showGameOver(scene);
    expect(document.getElementById('gameMessageOverlay').innerHTML).toContain(
      'GAME OVER'
    );

    ui.showWinMessage(scene);
    expect(document.getElementById('gameMessageOverlay').innerHTML).toContain(
      'VICTORY!'
    );
  });

  test('togglePause toggles physics pause and restarts countdown when resuming', () => {
    jest.useFakeTimers();
    const pauseButton = document.getElementById('pauseButton');
    gameState.ball = { setVelocity: jest.fn() };
    gameState.countdownText = {
      setText: jest.fn(),
      destroy: jest.fn(),
      active: false,
    };

    gameState.wasInCountdown = true;
    ui.togglePause(scene);
    expect(scene.physics.world.isPaused).toBe(false);
    expect(pauseButton.innerHTML).toContain('fa-pause');
    expect(gameState.countdownInterval).not.toBeNull();

    ui.togglePause(scene);
    expect(scene.physics.world.isPaused).toBe(true);
    expect(pauseButton.innerHTML).toContain('fa-play');

    jest.runOnlyPendingTimers();
    jest.clearAllTimers();
    jest.useRealTimers();
  });

  test('togglePause skips DOM updates when pause button is missing and countdown is already active', () => {
    document.getElementById('pauseButton').remove();

    gameState.ball = { setVelocity: jest.fn() };
    gameState.countdownText = { active: true, setText: jest.fn() };
    gameState.wasInCountdown = true;
    gameState.paused = true;

    const createCountdownTextSpy = jest.spyOn(ui, 'createCountdownText');

    jest.useFakeTimers();
    ui.togglePause(scene);
    jest.useRealTimers();
    jest.clearAllTimers();

    expect(scene.physics.world.isPaused).toBe(false);
    expect(createCountdownTextSpy).not.toHaveBeenCalled();
    expect(gameState.countdownInterval).not.toBeNull();

    clearInterval(gameState.countdownInterval);
    gameState.countdownInterval = null;
    createCountdownTextSpy.mockRestore();
  });

  test('setupUIButtons wires pause and high score controls', () => {
    const game = { scene: { scenes: [scene] } };

    ui.setupUIButtons(game);

    gameState.paused = true;
    document.getElementById('pauseButton').click();
    expect(gameState.paused).toBe(false);

    gameState.highScore = 42;
    gameState.paused = false;
    document.getElementById('highScoreButton').click();
    expect(
      document.getElementById('highScoreModal').classList.contains('active')
    ).toBe(true);
    expect(document.getElementById('highScoreValue').textContent).toBe('42');

    document.getElementById('highScoreModal').click();
    expect(
      document.getElementById('highScoreModal').classList.contains('active')
    ).toBe(false);

    document.getElementById('highScoreModal').classList.add('active');
    document.getElementById('closeHighScoreModal').click();
    expect(
      document.getElementById('highScoreModal').classList.contains('active')
    ).toBe(false);
  });

  test('setupUIButtons tolerates missing pause button and high score modal', () => {
    document.getElementById('pauseButton').remove();
    document.getElementById('highScoreModal').remove();
    document.getElementById('closeHighScoreModal').remove();

    const game = { scene: { scenes: [scene] } };

    expect(() => ui.setupUIButtons(game)).not.toThrow();

    document.getElementById('highScoreButton').click();
    expect(document.getElementById('highScoreModal')).toBeNull();
  });

  test('setupUIButtons handles missing close button and high score value while paused', () => {
    document.getElementById('closeHighScoreModal').remove();
    document.getElementById('highScoreValue').remove();

    const game = { scene: { scenes: [scene] } };
    gameState.paused = true;

    const togglePauseSpy = jest.spyOn(ui, 'togglePause');

    ui.setupUIButtons(game);
    document.getElementById('highScoreButton').click();

    expect(
      document.getElementById('highScoreModal').classList.contains('active')
    ).toBe(true);
    expect(togglePauseSpy).not.toHaveBeenCalled();

    togglePauseSpy.mockRestore();
  });

  test('setupUIButtons ignores inside-modal clicks so the overlay stays open', () => {
    const game = { scene: { scenes: [scene] } };

    ui.setupUIButtons(game);
    const modal = document.getElementById('highScoreModal');
    modal.classList.add('active');
    const child = document.createElement('span');
    modal.appendChild(child);

    child.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    expect(modal.classList.contains('active')).toBe(true);
  });

  test('setupWindowResize resizes the game and keeps the paddle on screen', () => {
    const game = {
      scale: { resize: jest.fn() },
      scene: { scenes: [scene] },
    };
    gameState.paddle = { width: 200, x: 500, y: 0 };

    const interceptor = captureResizeHandler();
    ui.setupWindowResize(game);
    const resizeHandler = interceptor.handler;
    interceptor.restore();

    expect(resizeHandler).toBeDefined();

    window.innerWidth = 300;
    window.innerHeight = 400;
    resizeHandler();

    expect(game.scale.resize).toHaveBeenCalledWith(300, 400);
    expect(scene.physics.world.setBounds).toHaveBeenCalledWith(0, 0, 300, 400);
    expect(gameState.paddle.y).toBe(345);
    expect(gameState.paddle.x).toBe(200);

    window.innerWidth = 1000;
    window.innerHeight = 800;
    gameState.paddle.x = 50;
    resizeHandler();

    expect(gameState.paddle.y).toBe(745);
    expect(gameState.paddle.x).toBe(100);
  });

  test('setupWindowResize ignores missing UI components', () => {
    const game = {
      scale: { resize: jest.fn() },
      scene: { scenes: [scene] },
    };
    gameState.scoreText = null;
    gameState.livesBalls = null;
    gameState.countdownText = null;
    gameState.paddle = null;

    const interceptor = captureResizeHandler();
    ui.setupWindowResize(game);
    const resizeHandler = interceptor.handler;
    interceptor.restore();

    expect(resizeHandler).toBeDefined();

    window.innerWidth = 500;
    window.innerHeight = 400;
    resizeHandler();

    expect(game.scale.resize).toHaveBeenCalledWith(500, 400);
    expect(scene.physics.world.setBounds).toHaveBeenCalledWith(0, 0, 500, 400);
  });

  test('setupWindowResize does nothing when scene is unavailable', () => {
    const game = {
      scale: { resize: jest.fn() },
      scene: { scenes: [null] },
    };

    const interceptor = captureResizeHandler();
    ui.setupWindowResize(game);
    const resizeHandler = interceptor.handler;
    interceptor.restore();

    expect(resizeHandler).toBeDefined();

    window.innerWidth = 420;
    window.innerHeight = 310;
    resizeHandler();

    expect(game.scale.resize).toHaveBeenCalledWith(420, 310);
  });
});
