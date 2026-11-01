import { gameState } from '../src/state.js';

describe('gameState', () => {
  beforeEach(() => {
    localStorage.clear();
    gameState.reset();
    gameState.highScore = 0;
  });

  test('reset establishes default state', () => {
    expect(gameState.lives).toBe(5);
    expect(gameState.score).toBe(0);
    expect(gameState.paused).toBe(true);
    expect(gameState.bricksGroup).toBeNull();
    expect(gameState.ballTrailPoints).toEqual([]);
    expect(gameState.paddleTrailPoints).toEqual([]);
  });

  test('incrementScore updates score text and high score', () => {
    const setText = jest.fn();
    gameState.scoreText = { setText };
    gameState.incrementScore(15);

    expect(gameState.score).toBe(15);
    expect(setText).toHaveBeenCalledWith(15);
    expect(gameState.highScore).toBe(15);
    expect(localStorage.getItem('brickBreakerHighScore')).toBe('15');
  });

  test('incrementScore works when scoreText is missing', () => {
    gameState.scoreText = null;
    gameState.score = 0;

    gameState.incrementScore(10);

    expect(gameState.score).toBe(10);
  });

  test('updateHighScore skips update when score is lower', () => {
    gameState.highScore = 20;
    gameState.score = 10;
    gameState.updateHighScore();

    expect(gameState.highScore).toBe(20);
    expect(localStorage.getItem('brickBreakerHighScore')).toBeNull();
  });

  test('decrementLives removes balls when available', () => {
    gameState.decrementLives();
    expect(gameState.lives).toBe(4);

    const destroy = jest.fn();
    gameState.livesBalls = [{ destroy }];
    gameState.decrementLives();
    expect(destroy).toHaveBeenCalled();
    expect(gameState.lives).toBe(3);
  });

  test('togglePause flips pause state', () => {
    expect(gameState.paused).toBe(true);
    expect(gameState.togglePause()).toBe(false);
    expect(gameState.paused).toBe(false);
  });
});
