import {
  advanceLevel,
  applyGravity,
  areAdjacent,
  checkEndConditions,
  clearMatches,
  createEmptyGrid,
  createGameState,
  createGrid,
  findMatches,
  getLevelMoveLimit,
  getLevelTargetScore,
  hasValidMoves,
  swapTiles,
  updateTimer,
  useMove,
  wouldCreateMatch,
} from './game';

describe('areAdjacent', () => {
  it('returns true for horizontally adjacent tiles', () => {
    expect(areAdjacent({ col: 0, row: 0 }, { col: 1, row: 0 })).toBe(true);
  });

  it('returns true for vertically adjacent tiles', () => {
    expect(areAdjacent({ col: 0, row: 0 }, { col: 0, row: 1 })).toBe(true);
  });

  it('returns false for diagonal tiles', () => {
    expect(areAdjacent({ col: 0, row: 0 }, { col: 1, row: 1 })).toBe(false);
  });

  it('returns false for distant tiles', () => {
    expect(areAdjacent({ col: 0, row: 0 }, { col: 2, row: 0 })).toBe(false);
  });
});

describe('createEmptyGrid', () => {
  it('creates a grid filled with -1', () => {
    const grid = createEmptyGrid(3, 4);
    expect(grid).toHaveLength(3);
    expect(grid[0]).toHaveLength(4);
    expect(grid.every((row) => row.every((value) => value === -1))).toBe(true);
  });
});

describe('createGrid', () => {
  it('creates a grid with no initial matches', () => {
    const grid = createGrid(8, 8);
    expect(findMatches(grid)).toHaveLength(0);
  });
});

describe('findMatches', () => {
  it('finds a horizontal match of three', () => {
    const grid = [
      [0, 0, 0, 1, 2],
      [1, 2, 3, 4, 5],
    ];
    const matches = findMatches(grid);
    expect(matches).toHaveLength(3);
    expect(matches).toEqual(
      expect.arrayContaining([
        { col: 0, row: 0 },
        { col: 1, row: 0 },
        { col: 2, row: 0 },
      ]),
    );
  });

  it('finds a vertical match of three', () => {
    const grid = [
      [0, 1],
      [0, 2],
      [0, 3],
      [4, 5],
    ];
    const matches = findMatches(grid);
    expect(matches).toHaveLength(3);
    expect(matches).toEqual(
      expect.arrayContaining([
        { col: 0, row: 0 },
        { col: 0, row: 1 },
        { col: 0, row: 2 },
      ]),
    );
  });

  it('finds overlapping horizontal and vertical matches', () => {
    const grid = [
      [1, 1, 1],
      [1, 2, 3],
      [1, 4, 5],
    ];
    const matches = findMatches(grid);
    expect(matches).toHaveLength(5);
  });

  it('ignores empty tiles', () => {
    const grid = [
      [-1, -1, -1],
      [0, 1, 2],
    ];
    expect(findMatches(grid)).toHaveLength(0);
  });
});

describe('clearMatches', () => {
  it('removes matched tiles and returns a score', () => {
    const grid = [
      [0, 0, 0, 1],
      [1, 2, 3, 4],
    ];
    const matches = findMatches(grid);
    const result = clearMatches(grid, matches);
    expect(grid[0]).toEqual([-1, -1, -1, 1]);
    expect(result.score).toBeGreaterThan(0);
    expect(result.matchedPositions).toHaveLength(3);
  });

  it('applies a combo multiplier for matches of four or more', () => {
    const grid = [
      [0, 0, 0, 0],
      [1, 2, 3, 4],
    ];
    const matches = findMatches(grid);
    const result = clearMatches(grid, matches);
    expect(result.matchedPositions).toHaveLength(4);
    expect(result.score).toBeGreaterThan(40);
  });
});

describe('applyGravity', () => {
  it('drops tiles down and refills the top rows', () => {
    const grid = [
      [0, 1],
      [-1, 2],
      [-1, 3],
    ];
    applyGravity(grid);
    expect(grid[2][0]).toBe(0);
    expect(grid[1][0]).not.toBe(-1);
    expect(grid[0][0]).not.toBe(-1);
  });

  it('returns movements for falling and newly spawned tiles', () => {
    const grid = [
      [0, 1],
      [-1, 2],
      [-1, 3],
    ];
    const movements = applyGravity(grid);
    expect(movements.length).toBeGreaterThan(0);
    expect(movements.some((m) => m.isNew)).toBe(true);
    expect(movements.some((m) => !m.isNew)).toBe(true);
  });
});

describe('swapTiles', () => {
  it('swaps two tiles', () => {
    const grid = [
      [0, 1],
      [2, 3],
    ];
    swapTiles(grid, { col: 0, row: 0 }, { col: 1, row: 1 });
    expect(grid[0][0]).toBe(3);
    expect(grid[1][1]).toBe(0);
  });
});

describe('wouldCreateMatch', () => {
  it('detects a horizontal match created by a swap', () => {
    const grid = [
      [2, 0, 2],
      [0, 1, 0],
      [3, 4, 5],
    ];
    expect(wouldCreateMatch(grid, { col: 1, row: 0 }, { col: 1, row: 1 })).toBe(
      true,
    );
  });

  it('detects a vertical match created by a swap', () => {
    const grid = [
      [0, 2, 3],
      [4, 0, 5],
      [0, 6, 7],
    ];
    expect(wouldCreateMatch(grid, { col: 0, row: 1 }, { col: 1, row: 1 })).toBe(
      true,
    );
  });

  it('returns false for a swap that creates no match', () => {
    const grid = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
    ];
    expect(wouldCreateMatch(grid, { col: 0, row: 0 }, { col: 1, row: 0 })).toBe(
      false,
    );
  });
});

describe('hasValidMoves', () => {
  it('returns true when a horizontal valid move exists', () => {
    const grid = [
      [2, 0, 2],
      [0, 1, 0],
      [3, 4, 5],
    ];
    expect(hasValidMoves(grid)).toBe(true);
  });

  it('returns true when a vertical valid move exists', () => {
    const grid = [
      [0, 2, 3],
      [4, 0, 5],
      [0, 6, 7],
    ];
    expect(hasValidMoves(grid)).toBe(true);
  });

  it('returns false when no valid moves exist', () => {
    const grid = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
    ];
    expect(hasValidMoves(grid)).toBe(false);
  });
});

describe('createGameState', () => {
  it('creates a state for level mode', () => {
    const state = createGameState('levels');
    expect(state.mode).toBe('levels');
    expect(state.level).toBe(1);
    expect(state.movesLeft).toBe(20);
    expect(state.targetScore).toBe(1000);
    expect(state.timeLeft).toBeNull();
  });

  it('creates a state for time mode', () => {
    const state = createGameState('time');
    expect(state.mode).toBe('time');
    expect(state.timeLeft).toBe(60);
    expect(state.movesLeft).toBeNull();
    expect(state.targetScore).toBeNull();
  });

  it('creates a state for endless mode', () => {
    const state = createGameState('endless');
    expect(state.mode).toBe('endless');
    expect(state.movesLeft).toBeNull();
    expect(state.timeLeft).toBeNull();
    expect(state.targetScore).toBeNull();
  });
});

describe('updateTimer', () => {
  it('decreases time left', () => {
    const state = createGameState('time');
    updateTimer(state, 5);
    expect(state.timeLeft).toBe(55);
  });

  it('ends the game when time runs out', () => {
    const state = createGameState('time');
    updateTimer(state, 70);
    expect(state.gameOver).toBe(true);
    expect(state.won).toBe(false);
    expect(state.timeLeft).toBe(0);
  });

  it('does nothing when game is over', () => {
    const state = createGameState('time');
    state.gameOver = true;
    updateTimer(state, 10);
    expect(state.timeLeft).toBe(60);
  });

  it('does nothing in modes without a timer', () => {
    const state = createGameState('levels');
    updateTimer(state, 10);
    expect(state.timeLeft).toBeNull();
  });
});

describe('checkEndConditions', () => {
  it('signals level completion in level mode when target score is reached', () => {
    const state = createGameState('levels');
    state.score = 1500;
    checkEndConditions(state);
    expect(state.gameOver).toBe(false);
    expect(state.won).toBe(true);
  });

  it('ends the game in time mode when target score is reached', () => {
    const state = createGameState('time');
    state.targetScore = 1000;
    state.score = 1500;
    checkEndConditions(state);
    expect(state.gameOver).toBe(true);
    expect(state.won).toBe(true);
  });

  it('marks the game as lost when moves run out without target', () => {
    const state = createGameState('levels');
    state.movesLeft = 0;
    checkEndConditions(state);
    expect(state.gameOver).toBe(true);
    expect(state.won).toBe(false);
  });

  it('does nothing when game is already over', () => {
    const state = createGameState('levels');
    state.gameOver = true;
    state.won = false;
    checkEndConditions(state);
    expect(state.won).toBe(false);
  });

  it('does nothing when moves remain and target is not met', () => {
    const state = createGameState('levels');
    state.movesLeft = 5;
    state.score = 100;
    checkEndConditions(state);
    expect(state.gameOver).toBe(false);
  });
});

describe('getLevelTargetScore', () => {
  it('increases the target by a fixed increment per level', () => {
    expect(getLevelTargetScore(1)).toBe(1000);
    expect(getLevelTargetScore(2)).toBe(1500);
    expect(getLevelTargetScore(3)).toBe(2000);
  });
});

describe('getLevelMoveLimit', () => {
  it('decreases moves per level down to a minimum', () => {
    expect(getLevelMoveLimit(1)).toBe(20);
    expect(getLevelMoveLimit(2)).toBe(19);
    expect(getLevelMoveLimit(11)).toBe(10);
  });
});

describe('advanceLevel', () => {
  it('resets the board, score, moves, and target for the next level', () => {
    const state = createGameState('levels');
    state.score = 1000;
    advanceLevel(state);
    expect(state.level).toBe(2);
    expect(state.score).toBe(0);
    expect(state.movesLeft).toBe(19);
    expect(state.targetScore).toBe(1500);
    expect(state.won).toBe(false);
    expect(state.gameOver).toBe(false);
  });

  it('does nothing outside of level mode', () => {
    const state = createGameState('time');
    state.level = 5;
    advanceLevel(state);
    expect(state.level).toBe(5);
  });
});

describe('useMove', () => {
  it('decrements moves left', () => {
    const state = createGameState('levels');
    useMove(state);
    expect(state.movesLeft).toBe(19);
  });

  it('does nothing when moves are unlimited', () => {
    const state = createGameState('endless');
    useMove(state);
    expect(state.movesLeft).toBeNull();
  });
});

describe('clearMatches', () => {
  it('applies a cascade combo multiplier', () => {
    const grid = [
      [0, 0, 0, 1],
      [2, 3, 4, 5],
    ];
    const matches = findMatches(grid);
    const base = clearMatches(grid, matches);
    const grid2 = [
      [0, 0, 0, 1],
      [2, 3, 4, 5],
    ];
    const combo = clearMatches(grid2, findMatches(grid2), 2);
    expect(combo.score).toBe(base.score * 2);
  });
});
