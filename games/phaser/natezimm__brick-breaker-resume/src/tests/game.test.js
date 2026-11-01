import { preload, create, update, _setAudioLoaded } from '../src/game.js';
import { AUDIO_KEYS, GAME_CONSTANTS } from '../src/constants.js';
import { attachGameState, gameState, getGameState } from '../src/state.js';
import { settings } from '../src/settings.js';
import { createMockScene } from './mockScene.js';
import { createBricksFromResume, handleBrickCollision } from '../src/bricks.js';
import {
  createLivesDisplay,
  createScoreText,
  startCountdown,
  createCountdownText,
  showGameOver,
  showWinMessage,
  togglePause,
} from '../src/ui.js';

jest.mock('../src/bricks.js', () => ({
  createBricksFromResume: jest.fn(() => Promise.resolve()),
  handleBrickCollision: jest.fn(),
}));

jest.mock('../src/ui.js', () => ({
  createLivesDisplay: jest.fn(),
  createScoreText: jest.fn(),
  startCountdown: jest.fn(),
  createCountdownText: jest.fn(),
  showGameOver: jest.fn(),
  showWinMessage: jest.fn(),
  togglePause: jest.fn(),
  hideGameMessage: jest.fn(),
  setupUIButtons: jest.fn(),
  setupWindowResize: jest.fn(),
}));

describe('game scene', () => {
  beforeAll(() => {
    const originalGetContext = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = function (type) {
      const ctx = originalGetContext.call(this, type) || {};
      [
        'roundRect',
        'stroke',
        'moveTo',
        'lineTo',
        'beginPath',
        'fill',
        'arc',
        'createRadialGradient',
        'createLinearGradient',
        'addColorStop',
      ].forEach((method) => {
        ctx[method] =
          ctx[method] || jest.fn(() => ({ addColorStop: jest.fn() }));
      });
      return ctx;
    };
  });

  beforeEach(() => {
    jest.clearAllMocks();
    gameState.reset();
    settings.soundEnabled = true;
    _setAudioLoaded(true); // Simulate audio being loaded for tests
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      value: 800,
    });
    Object.defineProperty(window, 'innerHeight', {
      writable: true,
      value: 600,
    });
  });

  afterEach(() => {
    _setAudioLoaded(false); // Reset audio state after each test
  });

  test('preload is a no-op (audio loads lazily on user interaction)', () => {
    const load = { audio: jest.fn() };
    preload.call({ load });

    expect(load.audio).not.toHaveBeenCalled();
  });

  test('create configures scene, physics, and controls', async () => {
    jest.useFakeTimers();
    const scene = createMockScene();

    create.call(scene);
    await Promise.resolve();
    const state = getGameState(scene);

    expect(createLivesDisplay).toHaveBeenCalledWith(scene, state);
    expect(createScoreText).toHaveBeenCalledWith(scene, state);
    expect(createBricksFromResume).toHaveBeenCalledWith(scene, state);
    expect(createCountdownText).toHaveBeenCalledWith(scene, state);
    expect(startCountdown).toHaveBeenCalledWith(scene, state);
    expect(state.paddle).toBeDefined();
    expect(state.ball).toBeDefined();
    expect(scene.colliders.length).toBe(2);
    expect(scene.physics.world.on).toHaveBeenCalled();

    state.paused = false;
    const moveHandler = scene.input.events['pointermove'];
    moveHandler({ x: 1000 });
    expect(state.paddle.x).toBeLessThanOrEqual(
      window.innerWidth - state.paddle.width / 2
    );

    const pausedPosition = state.paddle.x;
    state.paused = true;
    moveHandler({ x: 200 });
    expect(state.paddle.x).toBe(pausedPosition);
    state.paused = false;

    scene.physics.world.emit('worldbounds', state.ball.body, false, false);

    scene.colliders[0]();
    expect(scene.sound.play).toHaveBeenCalledWith(AUDIO_KEYS.BALL_HIT);

    settings.soundEnabled = false;
    scene.sound.play.mockClear();
    scene.colliders[0]();
    expect(scene.sound.play).not.toHaveBeenCalled();
    settings.soundEnabled = true;

    scene.colliders[1]('ball', 'brick');
    expect(handleBrickCollision).toHaveBeenCalledWith(
      scene,
      'ball',
      'brick',
      state
    );
    expect(scene.sound.play).toHaveBeenCalledWith(AUDIO_KEYS.BRICK_HIT);

    const keyboardHandler = scene.input.events['keydown-P'];
    keyboardHandler();
    expect(togglePause).toHaveBeenCalledWith(scene, state);

    state.ball.setPosition = jest.fn();
    state.ball.setVelocity = jest.fn();
    state.ball.setRotation = jest.fn();
    scene.physics.world.emit('worldbounds', state.ball.body, false, true);
    const expectedX =
      GAME_CONSTANTS.BALL_INITIAL_VELOCITY.x * settings.ballSpeed;
    const expectedY =
      GAME_CONSTANTS.BALL_INITIAL_VELOCITY.y * settings.ballSpeed;
    expect(state.ball.setVelocity).not.toHaveBeenCalledWith(
      expectedX,
      expectedY
    );
    jest.advanceTimersByTime(GAME_CONSTANTS.LIFE_LOST_RESTART_DELAY - 1);
    expect(state.ball.setVelocity).not.toHaveBeenCalledWith(
      expectedX,
      expectedY
    );
    jest.advanceTimersByTime(1);
    expect(state.ball.setVelocity).toHaveBeenCalledWith(expectedX, expectedY);

    const expectedCallsBeforeFalseBranch =
      state.ball.setVelocity.mock.calls.filter(
        ([x, y]) => x === expectedX && y === expectedY
      ).length;

    jest.clearAllTimers();
    state.lives = 3;
    scene.physics.world.emit('worldbounds', state.ball.body, false, true);
    state.lives = 0;
    jest.runOnlyPendingTimers();

    const expectedCallsAfterFalseBranch =
      state.ball.setVelocity.mock.calls.filter(
        ([x, y]) => x === expectedX && y === expectedY
      ).length;

    expect(expectedCallsAfterFalseBranch).toBe(expectedCallsBeforeFalseBranch);

    state.lives = 1;
    state.ball.destroy = jest.fn();
    scene.sound.play.mockClear();
    scene.physics.world.emit('worldbounds', state.ball.body, false, true);
    expect(showGameOver).toHaveBeenCalledWith(scene, state);
    expect(state.ball.destroy).toHaveBeenCalled();
    expect(scene.sound.play).toHaveBeenCalledWith(AUDIO_KEYS.GAME_OVER);

    jest.useRealTimers();
  });

  test('update triggers win flow when bricks are cleared', () => {
    const scene = createMockScene();
    attachGameState(scene, gameState);

    update.call(scene);
    expect(showWinMessage).not.toHaveBeenCalled();

    gameState.bricksCreated = true;
    gameState.bricksGroup = { countActive: () => 0 };
    gameState.lives = 2;
    gameState.winText = null;
    gameState.ball = { setVelocity: jest.fn(), setRotation: jest.fn() };
    gameState.bricksByRow = new Map();

    update.call(scene);

    expect(showWinMessage).toHaveBeenCalledWith(scene, gameState);
    expect(gameState.ball.setVelocity).toHaveBeenCalledWith(0, 0);
    expect(scene.sound.play).toHaveBeenCalledWith(AUDIO_KEYS.WIN_GAME);
    expect(gameState.paused).toBe(true);
  });

  test('update draws ball and paddle trails while playing', () => {
    const scene = createMockScene();
    attachGameState(scene, gameState);

    gameState.paused = false;
    gameState.ball = scene.physics.add
      .image(100, 200, 'ball')
      .setDisplaySize(20, 20);
    gameState.paddle = scene.physics.add
      .image(300, 545, 'paddle')
      .setDisplaySize(120, 20);

    update.call(scene);

    expect(scene.add.graphics).toHaveBeenCalledTimes(2);
    expect(gameState.ballTrailGraphics.fillCircle).toHaveBeenCalled();
    expect(gameState.paddleTrailGraphics.fillRoundedRect).toHaveBeenCalled();
  });

  describe('trails for each look', () => {
    const play = (scene) => {
      attachGameState(scene, gameState);
      gameState.paused = false;
      gameState.ball = scene.physics.add
        .image(100, 200, 'ball')
        .setDisplaySize(20, 20);
      gameState.paddle = scene.physics.add
        .image(300, 545, 'paddle')
        .setDisplaySize(120, 20);
    };

    afterEach(() => {
      settings.theme = 'dark';
    });

    test('Glass glows in the colour of the last brick broken', () => {
      settings.theme = 'dark';
      const scene = createMockScene();
      play(scene);
      gameState.lastHitColor = 0x4caf50;

      update.call(scene);

      const colors = gameState.ballTrailGraphics.fillStyle.mock.calls.map(
        ([color]) => color
      );
      expect(new Set(colors)).toEqual(new Set([0x4caf50]));
      // One trail point plus the stacked halo and under-paddle glow.
      expect(gameState.ballTrailGraphics.fillCircle).toHaveBeenCalledTimes(6);
      expect(
        gameState.paddleTrailGraphics.fillRoundedRect
      ).toHaveBeenCalledTimes(4);
    });

    test('Paper leaves a plain ink smear with no glow', () => {
      settings.theme = 'light';
      settings.ballColor = 0x16181d;
      const scene = createMockScene();
      play(scene);
      gameState.lastHitColor = 0x4caf50;

      update.call(scene);

      expect(gameState.ballTrailGraphics.fillCircle).toHaveBeenCalledTimes(1);
      expect(gameState.ballTrailGraphics.fillStyle).toHaveBeenCalledWith(
        0x16181d,
        expect.any(Number)
      );
      expect(
        gameState.paddleTrailGraphics.fillRoundedRect
      ).toHaveBeenCalledTimes(1);
    });

    test('trails switch blend mode with the look and survive a bare renderer', () => {
      const scene = createMockScene();
      play(scene);
      const setBlendMode = jest.fn();
      gameState.ballTrailGraphics = {
        clear: jest.fn(),
        fillStyle: jest.fn(),
        fillCircle: jest.fn(),
        setBlendMode,
      };
      gameState.paddleTrailGraphics = {
        clear: jest.fn(),
        fillStyle: jest.fn(),
        fillRect: jest.fn(),
      };

      settings.theme = 'dark';
      update.call(scene);
      expect(setBlendMode).toHaveBeenLastCalledWith(1);
      expect(gameState.paddleTrailGraphics.fillRect).toHaveBeenCalledTimes(1);

      settings.theme = 'light';
      update.call(scene);
      expect(setBlendMode).toHaveBeenLastCalledWith(0);
    });
  });
});
