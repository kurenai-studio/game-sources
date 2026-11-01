import {
  setupSettings,
  settings,
  updateBallTexture,
  updatePaddleTexture,
  updateBallSpeed,
  initializeTheme,
  applyTheme,
} from '../src/settings.js';
import { gameState } from '../src/state.js';
import { createMockScene, MockPhysicsImage, MockImage } from './mockScene.js';

describe('settings modal interactions', () => {
  let scene;
  let game;

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
    document.body.innerHTML = `
      <div id="settingsModal" class="modal"></div>
      <button id="settingsButton"></button>
      <button id="closeModal"></button>
      <input id="soundToggle" type="checkbox" checked />
      <input id="themeDark" type="radio" name="theme" value="dark" />
      <input id="themeLight" type="radio" name="theme" value="light" />
      <button id="resetColors"></button>
      <span id="ballColorValue"></span>
      <span id="paddleColorValue"></span>
      <input id="ballColorPicker" type="color" value="#a9a9a9" />
      <input id="paddleColorPicker" type="color" value="#a9a9a9" />
      <input id="paddleWidthSlider" type="range" value="100" />
      <span id="paddleWidthValue">100</span>
      <input id="ballSpeedSlider" type="range" value="1.0" />
      <span id="ballSpeedValue">1.0</span>
      <button id="pauseButton"></button>
      <div id="gameMessageOverlay"><div class="game-message gm-countdown">3</div></div>
    `;

    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      value: 900,
    });
    Object.defineProperty(window, 'innerHeight', {
      writable: true,
      value: 700,
    });

    localStorage.removeItem('brickBreakerTheme');
    document.documentElement.removeAttribute('data-theme');
    settings.theme = 'light';

    scene = createMockScene();
    game = { scene: { scenes: [scene] } };

    gameState.reset();
    gameState.ball = new MockPhysicsImage(0, 0, 'ball');
    gameState.paddle = {
      setTexture: jest.fn(),
      setDisplaySize: jest.fn(),
      setPosition: jest.fn(),
      body: { setSize: jest.fn() },
      width: 100,
      x: 50,
      y: 0,
    };
    gameState.livesBalls = [new MockImage(0, 0)];
  });

  test('opening modal pauses game and stops countdown', () => {
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      value: 300,
    });
    gameState.countdownInterval = setInterval(() => {}, 1000);
    gameState.paused = false;

    setupSettings(game);
    document.getElementById('settingsButton').click();

    expect(
      document.getElementById('settingsModal').classList.contains('active')
    ).toBe(true);
    expect(gameState.paused).toBe(true);
    expect(scene.physics.world.isPaused).toBe(true);
    expect(gameState.countdownInterval).toBeNull();
    expect(gameState.wasInCountdown).toBe(true);
    expect(document.getElementById('pauseButton').innerHTML).toContain(
      'fa-play'
    );

    // Verify countdown overlay is hidden when opening settings during countdown
    const overlay = document.getElementById('gameMessageOverlay');
    expect(overlay.classList.contains('hidden')).toBe(true);
    expect(overlay.textContent).toBe('');

    document
      .getElementById('settingsModal')
      .dispatchEvent(new MouseEvent('click', { bubbles: true }));
    expect(
      document.getElementById('settingsModal').classList.contains('active')
    ).toBe(false);

    document.getElementById('settingsButton').click();
    document.getElementById('closeModal').click();
    expect(
      document.getElementById('settingsModal').classList.contains('active')
    ).toBe(false);
  });

  test('controls update visual settings and speeds', () => {
    setupSettings(game);

    expect(document.getElementById('paddleWidthSlider').max).toBe(
      String(Math.floor(window.innerWidth / 3))
    );

    const soundToggle = document.getElementById('soundToggle');
    soundToggle.checked = false;
    soundToggle.dispatchEvent(
      new Event('change', { bubbles: true, cancelable: true })
    );
    expect(settings.soundEnabled).toBe(false);
    expect(scene.sound.mute).toBe(true);

    gameState.ball.setTexture = jest.fn();
    gameState.ball.setDisplaySize = jest.fn();
    document.getElementById('ballColorPicker').value = '#ff0000';
    document
      .getElementById('ballColorPicker')
      .dispatchEvent(new Event('input'));
    expect(settings.ballColor).toBe(0xff0000);
    expect(gameState.ball.setTexture).toHaveBeenCalled();

    gameState.paddle.setTexture = jest.fn();
    gameState.paddle.setDisplaySize = jest.fn();
    gameState.paddle.setPosition = jest.fn();
    document.getElementById('paddleColorPicker').value = '#00ff00';
    document
      .getElementById('paddleColorPicker')
      .dispatchEvent(new Event('input'));
    expect(settings.paddleColor).toBe(0x00ff00);
    expect(gameState.paddle.setTexture).toHaveBeenCalled();

    document.getElementById('paddleWidthSlider').value = '150';
    document
      .getElementById('paddleWidthSlider')
      .dispatchEvent(new Event('input'));
    expect(settings.paddleWidth).toBe(150);
    expect(document.getElementById('paddleWidthValue').textContent).toBe('150');
    expect(gameState.paddle.setDisplaySize).toHaveBeenCalled();

    gameState.ball.body.velocity = { x: 0, y: 0 };
    document.getElementById('ballSpeedSlider').value = '1.5';
    document
      .getElementById('ballSpeedSlider')
      .dispatchEvent(new Event('input'));
    expect(settings.ballSpeed).toBeCloseTo(1.5);
    expect(document.getElementById('ballSpeedValue').textContent).toBe('1.5');
    expect(gameState.ball.body.velocity).toEqual({ x: 0, y: 0 });

    gameState.ball.body.velocity = { x: 3, y: 4 };
    gameState.ball.setVelocity = jest.fn();
    document
      .getElementById('ballSpeedSlider')
      .dispatchEvent(new Event('input'));
    expect(gameState.ball.setVelocity).toHaveBeenCalled();
  });

  const chooseTheme = (theme) => {
    const option = document.getElementById(
      theme === 'dark' ? 'themeDark' : 'themeLight'
    );
    option.checked = true;
    option.dispatchEvent(new Event('change', { bubbles: true }));
  };

  test('the theme chooser shows the current look and switches between the two', () => {
    setupSettings(game);

    expect(document.getElementById('themeLight').checked).toBe(true);
    expect(document.getElementById('themeDark').checked).toBe(false);
    expect(settings.theme).toBe('light');

    chooseTheme('dark');
    expect(settings.theme).toBe('dark');
    expect(document.documentElement.dataset.theme).toBe('dark');
    expect(localStorage.getItem('brickBreakerTheme')).toBe('dark');

    chooseTheme('light');
    expect(settings.theme).toBe('light');
    expect(document.documentElement.dataset.theme).toBe('light');
    expect(localStorage.getItem('brickBreakerTheme')).toBe('light');
  });

  test('a theme option that loses its selection does not apply itself', () => {
    setupSettings(game);

    const dark = document.getElementById('themeDark');
    dark.checked = false;
    dark.dispatchEvent(new Event('change', { bubbles: true }));

    expect(settings.theme).toBe('light');
  });

  test('switching looks keeps the canvas clear so the page backdrop shows', () => {
    const setBackgroundColor = jest.fn();
    scene.cameras = { main: { setBackgroundColor } };
    setupSettings(game);

    chooseTheme('dark');

    expect(setBackgroundColor).toHaveBeenLastCalledWith('rgba(0, 0, 0, 0)');
  });

  test('the ball and paddle appearance is published for the HUD and the preview', () => {
    settings.ballColorCustom = false;
    settings.paddleColorCustom = false;
    setupSettings(game);
    const rootStyle = document.documentElement.style;

    expect(rootStyle.getPropertyValue('--ball-color')).toBe('#16181d');
    expect(rootStyle.getPropertyValue('--paddle-width')).toBe(
      `${settings.paddleWidth}px`
    );
    expect(document.getElementById('ballColorValue').textContent).toBe(
      '#16181d'
    );

    const paddleColorPicker = document.getElementById('paddleColorPicker');
    paddleColorPicker.value = '#00ff00';
    paddleColorPicker.dispatchEvent(new Event('input'));
    expect(rootStyle.getPropertyValue('--paddle-color')).toBe('#00ff00');
    expect(document.getElementById('paddleColorValue').textContent).toBe(
      '#00ff00'
    );

    const paddleWidthSlider = document.getElementById('paddleWidthSlider');
    paddleWidthSlider.value = '160';
    paddleWidthSlider.dispatchEvent(new Event('input'));
    expect(rootStyle.getPropertyValue('--paddle-width')).toBe('160px');

    settings.paddleColorCustom = false;
    settings.paddleWidth = 100;
  });

  test('reset colors returns the ball and paddle to the look defaults', () => {
    setupSettings(game);
    gameState.ball.setTexture = jest.fn();

    const ballColorPicker = document.getElementById('ballColorPicker');
    ballColorPicker.value = '#ff0000';
    ballColorPicker.dispatchEvent(new Event('input'));
    expect(settings.ballColorCustom).toBe(true);

    document.getElementById('resetColors').click();

    expect(settings.ballColorCustom).toBe(false);
    expect(settings.ballColor).toBe(0x16181d);
    expect(ballColorPicker.value).toBe('#16181d');
    expect(gameState.ball.setTexture).toHaveBeenCalledTimes(2);
  });

  test('slider tracks are filled up to their value', () => {
    setupSettings(game);
    const paddleWidthSlider = document.getElementById('paddleWidthSlider');
    const ballSpeedSlider = document.getElementById('ballSpeedSlider');
    const fill = (slider) => slider.style.getPropertyValue('--fill');

    // 900px wide: the paddle slider runs 0 to 300, so 100 is a third along.
    expect(fill(paddleWidthSlider)).toBe('33.3%');

    ballSpeedSlider.min = '0.5';
    ballSpeedSlider.max = '2.0';
    ballSpeedSlider.value = '2.0';
    ballSpeedSlider.dispatchEvent(new Event('input'));
    expect(fill(ballSpeedSlider)).toBe('100.0%');

    paddleWidthSlider.min = '20';
    paddleWidthSlider.value = '20';
    paddleWidthSlider.dispatchEvent(new Event('input'));
    expect(fill(paddleWidthSlider)).toBe('0.0%');

    settings.paddleWidth = 100;
    settings.ballSpeed = 1.0;
  });

  test('the settings menu works without the optional controls', () => {
    document.getElementById('themeDark').remove();
    document.getElementById('themeLight').remove();
    document.getElementById('resetColors').remove();
    document.getElementById('ballColorValue').remove();
    document.getElementById('ballColorPicker').value = '#a9a9a9';

    expect(() => setupSettings(game)).not.toThrow();
    expect(document.getElementById('ballColorPicker').value).toBe('#16181d');
  });

  test("theme toggle wipes the previous look's trails while paused", () => {
    setupSettings(game);
    const clear = jest.fn();
    gameState.ballTrailGraphics = { clear };
    gameState.paddleTrailGraphics = { clear };
    gameState.ballTrailPoints = [{ x: 1, y: 2 }];

    applyTheme('dark', game);

    expect(clear).toHaveBeenCalledTimes(2);
    expect(gameState.ballTrailPoints).toEqual([]);
  });

  test('each look brings its own ball and paddle colour until the player picks one', () => {
    settings.ballColorCustom = false;
    settings.paddleColorCustom = false;
    setupSettings(game);

    applyTheme('dark', game);
    expect(settings.ballColor).toBe(0xffffff);
    expect(settings.paddleColor).toBe(0xffffff);
    expect(document.getElementById('ballColorPicker').value).toBe('#ffffff');

    applyTheme('light', game);
    expect(settings.ballColor).toBe(0x16181d);
    expect(document.getElementById('paddleColorPicker').value).toBe('#16181d');

    const ballColorPicker = document.getElementById('ballColorPicker');
    ballColorPicker.value = '#ff0000';
    ballColorPicker.dispatchEvent(new Event('input', { bubbles: true }));

    applyTheme('dark', game);
    expect(settings.ballColor).toBe(0xff0000);
    expect(settings.paddleColor).toBe(0xffffff);

    settings.ballColorCustom = false;
  });

  test('switching looks mid-game lays the remaining bricks out again', async () => {
    setupSettings(game);
    const clear = jest.fn();
    gameState.bricksGroup = { ...scene.physics.add.staticGroup(), clear };
    gameState.bricksCreated = true;
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: jest.fn().mockResolvedValue([{ tag: 'p', text: 'Nathan' }]),
    });

    applyTheme('dark', game);
    await gameState.rebuildingBricks;

    expect(clear).toHaveBeenCalledWith(true, true);
    expect(global.fetch).toHaveBeenCalledWith('assets/resume.json');
    expect(gameState.bricksCreated).toBe(true);
  });

  test('applyTheme without a running game only updates the page', () => {
    expect(() => applyTheme('dark')).not.toThrow();
    expect(document.documentElement.dataset.theme).toBe('dark');
    expect(localStorage.getItem('brickBreakerTheme')).toBe('dark');
  });

  test('initializeTheme defaults to the Glass theme when no preference stored', () => {
    document.documentElement.removeAttribute('data-theme');
    localStorage.removeItem('brickBreakerTheme');
    settings.theme = 'light';

    const resultingTheme = initializeTheme();

    expect(resultingTheme).toBe('dark');
    expect(settings.theme).toBe('dark');
    expect(document.documentElement.dataset.theme).toBe('dark');
  });

  test('initializeTheme restores a stored Paper preference', () => {
    localStorage.setItem('brickBreakerTheme', 'light');

    expect(initializeTheme()).toBe('light');
    expect(document.documentElement.dataset.theme).toBe('light');
  });

  test('setupSettings logs when physics scene is missing', () => {
    const consoleError = jest
      .spyOn(console, 'error')
      .mockImplementation(() => {});
    const gameWithoutScene = { scene: { scenes: [null] } };

    setupSettings(gameWithoutScene);
    document.getElementById('settingsButton').click();

    expect(consoleError).toHaveBeenCalledWith('Scene or physics not available');
    consoleError.mockRestore();
  });

  test('setupSettings tolerates a missing pause button', () => {
    document.getElementById('pauseButton').remove();

    setupSettings(game);
    document.getElementById('settingsButton').click();

    expect(scene.physics.world.isPaused).toBe(true);
    expect(document.getElementById('pauseButton')).toBeNull();
  });

  test('modal click from a child element does not close the settings', () => {
    setupSettings(game);
    document.getElementById('settingsButton').click();

    const modal = document.getElementById('settingsModal');
    const child = document.createElement('div');
    modal.appendChild(child);

    child.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    expect(modal.classList.contains('active')).toBe(true);
  });

  test('sound toggle ignores missing scene sound', () => {
    scene.sound = null;

    setupSettings(game);
    const soundToggle = document.getElementById('soundToggle');
    soundToggle.checked = false;
    soundToggle.dispatchEvent(new Event('change', { bubbles: true }));

    expect(settings.soundEnabled).toBe(false);
    expect(scene.sound).toBeNull();
  });

  test('updateBallTexture refreshes the ball texture', () => {
    const scene = createMockScene();
    scene.textures.exists = jest.fn(() => true);
    scene.textures.remove = jest.fn();
    scene.textures.addCanvas = jest.fn();

    const ball = new MockPhysicsImage(0, 0);
    ball.setTexture = jest.fn();
    ball.setDisplaySize = jest.fn();
    gameState.ball = ball;

    updateBallTexture(scene);

    expect(scene.textures.remove).toHaveBeenCalledWith('ballTexture');
    expect(ball.setTexture).toHaveBeenCalledWith('ballTexture');
  });

  test('updatePaddleTexture rebuilds paddle canvas and body bounds', () => {
    const scene = createMockScene();
    scene.textures.exists = jest.fn((key) => key === 'paddleTexture');
    scene.textures.remove = jest.fn();
    scene.textures.addCanvas = jest.fn();

    const paddle = {
      x: 200,
      y: 400,
      width: 100,
      setTexture: jest.fn(),
      setDisplaySize: jest.fn(),
      setPosition: jest.fn(),
      body: {
        setSize: jest.fn(),
      },
    };

    const originalWidth = settings.paddleWidth;
    settings.paddleWidth = 150;
    gameState.paddle = paddle;

    updatePaddleTexture(scene);

    expect(scene.textures.remove).toHaveBeenCalledWith('paddleTexture');
    expect(paddle.setDisplaySize).toHaveBeenCalledWith(150, 20);
    expect(paddle.body.setSize).toHaveBeenCalledWith(150, 20);

    settings.paddleWidth = originalWidth;
  });

  test('updateBallTexture short-circuits when ball is unavailable', () => {
    gameState.ball = null;
    expect(() => updateBallTexture(scene)).not.toThrow();
  });

  test('updateBallTexture handles missing life balls list', () => {
    const sceneWithoutBM = createMockScene();
    sceneWithoutBM.textures.exists = jest.fn(() => false);
    gameState.ball = new MockPhysicsImage(0, 0);
    gameState.livesBalls = null;

    expect(() => updateBallTexture(sceneWithoutBM)).not.toThrow();
  });

  test('updatePaddleTexture short-circuits when paddle is unavailable', () => {
    gameState.paddle = null;
    expect(() => updatePaddleTexture(scene)).not.toThrow();
  });

  test('updateBallSpeed short-circuits when there is no ball body', () => {
    gameState.ball = null;
    expect(() => updateBallSpeed(scene)).not.toThrow();
  });

  test('updateBallSpeed ignores zero velocity', () => {
    gameState.ball = {
      body: { velocity: { x: 0, y: 0 } },
      setVelocity: jest.fn(),
    };

    updateBallSpeed(scene);
    expect(gameState.ball.setVelocity).not.toHaveBeenCalled();
  });
});
