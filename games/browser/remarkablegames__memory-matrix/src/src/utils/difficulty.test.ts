import {
  FEEDBACK_CORRECT_MS,
  FEEDBACK_WRONG_MS,
  getGridSize,
  getPatternSize,
  getRevealDuration,
  getTimeBonus,
  LOCK_IN_MS,
  MAX_BONUS_MS,
  MAX_GRID,
  MAX_REVEAL_MS,
  MIN_GRID,
  START_TIME_MS,
  TIME_BONUS_BASE_MS,
  WARNING_MS,
} from './difficulty';

describe('getGridSize', () => {
  it('starts at the minimum grid', () => {
    expect(getGridSize(1)).toBe(MIN_GRID);
  });

  it('holds the grid for three rounds before growing', () => {
    expect(getGridSize(2)).toBe(3);
    expect(getGridSize(3)).toBe(3);
    expect(getGridSize(4)).toBe(4);
  });

  it('grows steadily with the round', () => {
    expect(getGridSize(7)).toBe(5);
    expect(getGridSize(10)).toBe(6);
    expect(getGridSize(13)).toBe(7);
  });

  it('caps at the maximum grid', () => {
    expect(getGridSize(99)).toBe(MAX_GRID);
    expect(MAX_GRID).toBe(7);
  });
});

describe('getPatternSize', () => {
  it('asks for round plus two tiles', () => {
    expect(getPatternSize(1)).toBe(3);
    expect(getPatternSize(4)).toBe(6);
  });

  it('stays within forty percent of the grid', () => {
    // round 30: 32 tiles requested, but 7x7 grid caps at 19.
    expect(getPatternSize(30)).toBe(19);
  });

  it('never exceeds the grid capacity', () => {
    const round = 99;
    const cells = getGridSize(round) ** 2;
    expect(getPatternSize(round)).toBeLessThan(cells);
  });
});

describe('getRevealDuration', () => {
  it('scales with the number of tiles', () => {
    expect(getRevealDuration(3)).toBeLessThan(getRevealDuration(8));
  });

  it('caps the reveal window', () => {
    expect(getRevealDuration(50)).toBe(MAX_REVEAL_MS);
    expect(MAX_REVEAL_MS).toBe(2500);
  });
});

describe('getTimeBonus', () => {
  it('pays little on the easy opening rounds', () => {
    expect(getTimeBonus(1)).toBe(TIME_BONUS_BASE_MS);
    expect(TIME_BONUS_BASE_MS).toBe(3_000);
  });

  it('holds flat while the span is unchanged', () => {
    // Rounds 1-3 all ask for 3 tiles on a 3x3 board.
    expect(getTimeBonus(2)).toBe(getTimeBonus(1));
    expect(getTimeBonus(3)).toBe(getTimeBonus(1));

    // Rounds 4-6 all ask for 6 tiles on a 4x4 board.
    expect(getTimeBonus(5)).toBe(getTimeBonus(4));
    expect(getTimeBonus(6)).toBe(getTimeBonus(4));
  });

  it('grows with the span of the pattern', () => {
    expect(getTimeBonus(7)).toBeGreaterThan(getTimeBonus(6));
    expect(getTimeBonus(13)).toBeGreaterThan(getTimeBonus(10));
    expect(getTimeBonus(15)).toBeGreaterThan(getTimeBonus(7));
  });

  it('caps the bonus at the hardest pattern', () => {
    expect(getTimeBonus(99)).toBe(MAX_BONUS_MS);
    expect(MAX_BONUS_MS).toBe(11_000);
  });
});

describe('tuning constants', () => {
  it('uses sensible timing defaults', () => {
    expect(MIN_GRID).toBe(3);
    expect(START_TIME_MS).toBe(60000);
    expect(WARNING_MS).toBe(10000);
    expect(LOCK_IN_MS).toBe(300);
    expect(FEEDBACK_CORRECT_MS).toBeGreaterThan(0);
    expect(FEEDBACK_WRONG_MS).toBeGreaterThan(FEEDBACK_CORRECT_MS);
  });
});
