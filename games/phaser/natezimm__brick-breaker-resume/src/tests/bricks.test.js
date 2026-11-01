import {
  createBrick,
  createBricksFromResume,
  handleBrickCollision,
  rebuildBricks,
} from '../src/bricks.js';
import { gameState } from '../src/state.js';
import { createMockScene } from './mockScene.js';

describe('bricks', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    gameState.reset();
    gameState.bricksGroup = null;
    document.body.innerHTML = '';
    document.documentElement.removeAttribute('data-theme');
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      value: 120,
    });
    Object.defineProperty(window, 'innerHeight', {
      writable: true,
      value: 80,
    });
  });

  test('createBrick builds brick visuals and metadata', () => {
    const scene = createMockScene();
    gameState.bricksGroup = scene.physics.add.staticGroup();

    const brick = createBrick(scene, 10, 10, 'Hello', 50, 0xff0000, true);

    const domBrick = brick.getData('domBrick');
    expect(domBrick).toBeDefined();
    expect(domBrick.className).toBe('overlay-brick');
    expect(domBrick.textContent).toBe('Hello');
    expect(brick.getData('isLastInRow')).toBe(true);
    expect(gameState.bricksGroup.items).toContain(brick);
  });

  test('createBricksFromResume lays out and resizes bricks from resume text', async () => {
    const scene = createMockScene();
    gameState.bricksGroup = scene.physics.add.staticGroup();

    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      value: 400,
    });
    Object.defineProperty(window, 'innerHeight', {
      writable: true,
      value: 100,
    });

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: jest.fn().mockResolvedValue([
        { text: 'firstword secondword thirdword' },
        {
          text: 'extra words to overflow rows anotherlongword hugeword largeword',
        },
      ]),
    });

    await createBricksFromResume(scene);

    expect(global.fetch).toHaveBeenCalledWith('assets/resume.json');
    expect(gameState.bricksGroup.items.length).toBeGreaterThan(0);
    expect(gameState.bricksCreated).toBe(true);
    expect(gameState.totalRows).toBeGreaterThan(0);
    const lastBrick =
      gameState.bricksGroup.items[gameState.bricksGroup.items.length - 1];
    expect(lastBrick.getData('isLastInRow')).toBe(true);
  });

  test('handleBrickCollision awards points and cleans up visuals', () => {
    const domBrickRemove = jest.fn();
    const brickData = new Map([
      ['domBrick', { remove: domBrickRemove }],
      ['row', 0],
    ]);
    const brick = {
      getData: (key) => brickData.get(key),
      destroy: jest.fn(),
    };

    gameState.totalRows = 2;
    gameState.scoreText = { setText: jest.fn() };

    handleBrickCollision(createMockScene(), {}, brick);

    expect(domBrickRemove).toHaveBeenCalled();
    expect(brick.destroy).toHaveBeenCalled();
    expect(gameState.score).toBe(20);
    expect(gameState.scoreText.setText).toHaveBeenCalledWith(20);
  });

  test('handleBrickCollision creates brick explosion particles when geometry is available', () => {
    jest.useFakeTimers();
    const domBrickRemove = jest.fn();
    const brickData = new Map([
      [
        'domBrick',
        {
          remove: domBrickRemove,
          style: { backgroundColor: 'rgb(244, 67, 54)' },
          getBoundingClientRect: () => ({
            left: 20,
            top: 30,
            width: 80,
            height: 24,
          }),
        },
      ],
      ['row', 0],
    ]);
    const brick = {
      getData: (key) => brickData.get(key),
      destroy: jest.fn(),
    };

    gameState.totalRows = 1;

    handleBrickCollision(createMockScene(), {}, brick);

    expect(document.querySelectorAll('.brick-particle')).toHaveLength(12);
    jest.runOnlyPendingTimers();
    expect(document.querySelectorAll('.brick-particle')).toHaveLength(0);
    jest.useRealTimers();
  });

  test('createBrick handles empty text', () => {
    const scene = createMockScene();
    gameState.bricksGroup = scene.physics.add.staticGroup();

    const brick = createBrick(scene, 5, 5, '', 50, 0xff0000);

    const domBrick = brick.getData('domBrick');
    expect(domBrick).toBeDefined();
    expect(domBrick.textContent).toBe('');
  });

  test('createBricksFromResume leaves bricks alone when row already touches edge', async () => {
    const scene = createMockScene();
    gameState.bricksGroup = scene.physics.add.staticGroup();

    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      value: 300,
    });
    Object.defineProperty(window, 'innerHeight', {
      writable: true,
      value: 100,
    });

    const oversizedWord = 'a'.repeat(27);
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: jest.fn().mockResolvedValue([{ text: oversizedWord }]),
    });

    await createBricksFromResume(scene);

    const lastBrick = gameState.bricksGroup.items[0];
    expect(gameState.bricksGroup.items).toHaveLength(1);
    expect(lastBrick.getData('isLastInRow')).toBe(true);
  });

  test('createBrick carries layout details onto the brick', () => {
    const scene = createMockScene();
    gameState.bricksGroup = scene.physics.add.staticGroup();

    const brick = createBrick(
      scene,
      96,
      40,
      'PROJECTS',
      80,
      0x16181d,
      false,
      gameState,
      {
        height: 16,
        kind: 'heading',
        font: '600 11.5px Inter, sans-serif',
        rowIndex: 6,
        wordIndex: 42,
      }
    );

    expect(brick.height).toBe(16);
    expect(brick.getData('row')).toBe(6);
    expect(brick.getData('record')).toMatchObject({
      text: 'PROJECTS',
      wordIndex: 42,
      height: 16,
    });
    expect(brick.getData('domBrick').classList.contains('brick--heading')).toBe(
      true
    );
  });

  describe('with a résumé on the wall', () => {
    let scene;

    const mockResume = () => {
      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        json: jest.fn().mockResolvedValue([
          { tag: 'p', text: 'Nathan Zimmerman' },
          { tag: 'p', text: 'Raritan' },
          { tag: 'p', text: 'SKILLS' },
          { tag: 'li', text: 'Angular React' },
        ]),
      });
    };

    const liveBricks = () =>
      gameState.bricksGroup.items.filter((item) => !item.destroyed);

    beforeEach(() => {
      scene = createMockScene();
      const group = scene.physics.add.staticGroup();
      group.clear = jest.fn(() => {
        group.items.forEach((item) => item.destroy());
        group.items.length = 0;
      });
      gameState.bricksGroup = group;
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        value: 900,
      });
      Object.defineProperty(window, 'innerHeight', {
        writable: true,
        value: 700,
      });
      mockResume();
    });

    test('a broken word is remembered and lights the next glow', async () => {
      await createBricksFromResume(scene);
      const brick = liveBricks()[1];

      handleBrickCollision(scene, { body: { velocity: { x: 120 } } }, brick);

      expect(gameState.brokenWords.has(1)).toBe(true);
      expect(gameState.lastHitColor).toBe(brick.getData('record').color);
      expect(document.querySelectorAll('.brick-ring')).toHaveLength(1);
      expect(document.querySelector('.brick-word').textContent).toBe(
        'Zimmerman'
      );
      expect(document.querySelector('.brick-ghost')).toBeNull();
    });

    test('on the Paper page a broken word falls and leaves its impression', async () => {
      document.documentElement.dataset.theme = 'light';
      await createBricksFromResume(scene);
      const container = document.getElementById('gameBrickContainer');
      expect(container.dataset.layout).toBe('typeset');
      expect(container.querySelectorAll('.brick--dot')).toHaveLength(1);

      const brick = liveBricks()[0];
      handleBrickCollision(scene, { body: { velocity: { x: 200 } } }, brick);

      const word = document.querySelector('.brick-word');
      expect(word.textContent).toBe('Nathan');
      expect(word.style.getPropertyValue('--fall-x')).toMatch(/px$/);
      expect(word.style.getPropertyValue('--fall-spin')).toMatch(/deg$/);
      expect(document.querySelectorAll('.brick-ring')).toHaveLength(0);
      expect(container.querySelector('.brick-ghost').textContent).toBe(
        'Nathan'
      );
      expect(brick.getData('domBrick').isConnected).toBe(false);

      // No ball velocity to borrow: the word still falls.
      handleBrickCollision(scene, null, liveBricks()[0]);
      expect(document.querySelectorAll('.brick-word')).toHaveLength(2);
    });

    test('rebuildBricks lays out the remaining words for the new theme', async () => {
      await createBricksFromResume(scene);
      handleBrickCollision(scene, {}, liveBricks()[0]);
      expect(liveBricks()).toHaveLength(5);

      document.documentElement.dataset.theme = 'light';
      const rebuilding = rebuildBricks(scene);
      // While the wall is empty the scene must not read it as a win.
      await Promise.resolve();
      expect(gameState.bricksCreated).toBe(false);
      await rebuilding;

      const container = document.getElementById('gameBrickContainer');
      expect(gameState.bricksGroup.clear).toHaveBeenCalledWith(true, true);
      expect(gameState.bricksCreated).toBe(true);
      expect(gameState.rebuildingBricks).toBeNull();
      expect(container.dataset.layout).toBe('typeset');
      expect(
        liveBricks()
          .map((brick) => brick.getData('record').text)
          .filter(Boolean)
      ).toEqual(['Zimmerman', 'Raritan', 'SKILLS', '•', 'Angular', 'React']);
      expect(container.querySelector('.brick-ghost').textContent).toBe(
        'Nathan'
      );

      document.documentElement.dataset.theme = 'dark';
      await rebuildBricks(scene);
      expect(container.dataset.layout).toBe('wall');
      expect(container.querySelector('.brick-ghost')).toBeNull();
      expect(liveBricks()).toHaveLength(5);
    });

    test('a piece of the rule breaks like any brick and stays broken', async () => {
      document.documentElement.dataset.theme = 'light';
      await createBricksFromResume(scene);
      const container = document.getElementById('gameBrickContainer');
      const pieces = () =>
        liveBricks().filter((brick) => brick.getData('record').kind === 'rule');
      const total = pieces().length;
      expect(total).toBeGreaterThan(1);

      handleBrickCollision(scene, {}, pieces()[0]);

      expect(gameState.brokenWords.has('rule-0')).toBe(true);
      expect(pieces()).toHaveLength(total - 1);
      expect(
        container.querySelectorAll('.brick-ghost.brick--rule')
      ).toHaveLength(1);
      // A rule has no word to drop off the page.
      expect(document.querySelector('.brick-word')).toBeNull();

      // Glass has no rule; coming back to Paper finds the piece still broken.
      document.documentElement.dataset.theme = 'dark';
      await rebuildBricks(scene);
      expect(pieces()).toHaveLength(0);
      document.documentElement.dataset.theme = 'light';
      await rebuildBricks(scene);
      expect(pieces()).toHaveLength(total - 1);
    });

    test('rebuildBricks queues, so the last theme chosen wins', async () => {
      await createBricksFromResume(scene);

      document.documentElement.dataset.theme = 'light';
      const first = rebuildBricks(scene);
      document.documentElement.dataset.theme = 'dark';
      const second = rebuildBricks(scene);
      await Promise.all([first, second]);

      expect(document.getElementById('gameBrickContainer').dataset.layout).toBe(
        'wall'
      );
      expect(gameState.rebuildingBricks).toBeNull();
      expect(liveBricks()).toHaveLength(6);
    });

    test('rebuildBricks does nothing before the first wall exists', async () => {
      await rebuildBricks(scene);
      await rebuildBricks(null);
      gameState.bricksGroup = null;
      await rebuildBricks(scene);

      expect(global.fetch).not.toHaveBeenCalled();
    });

    test('rebuildBricks warns when the résumé cannot be reloaded', async () => {
      await createBricksFromResume(scene);
      const warn = jest.spyOn(console, 'warn').mockImplementation(() => {});
      global.fetch = jest.fn().mockRejectedValue(new Error('offline'));

      await rebuildBricks(scene);

      expect(warn).toHaveBeenCalled();
      expect(gameState.bricksCreated).toBe(false);
      warn.mockRestore();
    });
  });
});
