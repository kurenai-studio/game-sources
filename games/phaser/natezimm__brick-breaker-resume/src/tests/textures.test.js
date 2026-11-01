import { GAME_CONSTANTS, TEXTURE_KEYS } from '../src/constants.js';
import {
  createBallCanvas,
  createPaddleCanvas,
  refreshBallTexture,
  refreshPaddleTexture,
  registerGameTextures,
} from '../src/textures.js';
import { createMockScene, MockPhysicsImage } from './mockScene.js';

describe('texture factory', () => {
  const settings = {
    ballColor: 0xff0000,
    paddleColor: 0x00ff00,
    paddleWidth: 140,
  };

  test('creates default paddle and ball canvases', () => {
    const paddleCanvas = createPaddleCanvas();
    const ballCanvas = createBallCanvas();

    expect(paddleCanvas.width).toBe(GAME_CONSTANTS.PADDLE_WIDTH);
    expect(paddleCanvas.height).toBe(GAME_CONSTANTS.PADDLE_HEIGHT);
    expect(ballCanvas.width).toBe(GAME_CONSTANTS.BALL_SIZE);
    expect(ballCanvas.height).toBe(GAME_CONSTANTS.BALL_SIZE);
  });

  test('registerGameTextures replaces existing Phaser textures', () => {
    const scene = createMockScene();
    scene.textures.exists = jest.fn(() => true);

    registerGameTextures(scene, settings);

    expect(scene.textures.remove).toHaveBeenCalledWith(TEXTURE_KEYS.PADDLE);
    expect(scene.textures.remove).toHaveBeenCalledWith(TEXTURE_KEYS.BALL);
    expect(scene.textures.addCanvas).toHaveBeenCalledTimes(2);
  });

  test('refreshBallTexture updates the active ball', () => {
    const scene = createMockScene();
    const ball = new MockPhysicsImage(0, 0);

    refreshBallTexture(scene, { ball }, settings);

    expect(ball.texture).toBe(TEXTURE_KEYS.BALL);
    expect(ball.width).toBe(GAME_CONSTANTS.BALL_SIZE);
  });

  test('refreshPaddleTexture updates active paddle and body size', () => {
    const scene = createMockScene();
    const paddle = new MockPhysicsImage(10, 20);
    const state = { paddle };

    refreshPaddleTexture(scene, state, settings);

    expect(paddle.texture).toBe(TEXTURE_KEYS.PADDLE);
    expect(paddle.width).toBe(settings.paddleWidth);
    expect(paddle.height).toBe(GAME_CONSTANTS.PADDLE_HEIGHT);
    expect(paddle.body.setSize).toHaveBeenCalledWith(
      settings.paddleWidth,
      GAME_CONSTANTS.PADDLE_HEIGHT
    );
  });

  test('refresh helpers short-circuit without scene objects', () => {
    expect(() =>
      refreshBallTexture(null, { ball: new MockPhysicsImage(0, 0) }, settings)
    ).not.toThrow();
    expect(() =>
      refreshBallTexture(createMockScene(), { ball: null }, settings)
    ).not.toThrow();
    expect(() =>
      refreshPaddleTexture(
        null,
        { paddle: new MockPhysicsImage(0, 0) },
        settings
      )
    ).not.toThrow();
    expect(() =>
      refreshPaddleTexture(createMockScene(), { paddle: null }, settings)
    ).not.toThrow();
  });

  test('the Paper theme draws an ink ball and a ruled paddle', () => {
    const context = {
      fillStyle: '',
      beginPath: jest.fn(),
      arc: jest.fn(),
      fill: jest.fn(),
      fillRect: jest.fn(),
    };
    const originalGetContext = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = jest.fn(() => context);
    const scene = createMockScene();

    registerGameTextures(scene, { ...settings, theme: 'light' });
    HTMLCanvasElement.prototype.getContext = originalGetContext;

    // A bar and the hairline beneath it; two discs for the ball and its shadow.
    expect(context.fillRect).toHaveBeenCalledTimes(2);
    expect(context.fillRect).toHaveBeenCalledWith(0, 0, 140, 9);
    expect(context.arc).toHaveBeenCalledTimes(2);
    expect(context.fillStyle).toBe('#ff0000');
  });

  test('the Glass theme draws a lit ball and a glass paddle', () => {
    const scene = createMockScene();

    expect(() =>
      registerGameTextures(scene, { ...settings, theme: 'dark' })
    ).not.toThrow();
    expect(createPaddleCanvas({ look: 'ink', height: 2 }).height).toBe(2);
    expect(createBallCanvas({ look: 'ink', size: 4, radius: 2 }).width).toBe(4);
  });
});
