import { createPattern } from './pattern';

describe('createPattern', () => {
  it('returns the requested number of cells', () => {
    const pattern = createPattern(9, 3);

    expect(pattern).toHaveLength(3);
  });

  it('returns unique cell indices within the grid', () => {
    const pattern = createPattern(49, 19);

    expect(new Set(pattern).size).toBe(19);
    for (const index of pattern) {
      expect(index).toBeGreaterThanOrEqual(0);
      expect(index).toBeLessThan(49);
    }
  });

  it('returns cells in ascending order for stable rendering', () => {
    const pattern = createPattern(9, 5);

    expect([...pattern].sort((a, b) => a - b)).toEqual(pattern);
  });

  it('uses the injected random source', () => {
    const random = vi.fn().mockReturnValue(0);

    const pattern = createPattern(9, 3, random);

    expect(random).toHaveBeenCalled();
    expect(pattern).toEqual([0, 1, 2]);
  });

  it('clamps the pattern size to the number of cells', () => {
    const pattern = createPattern(4, 99);

    expect(pattern).toHaveLength(4);
  });

  it('returns an empty pattern for an empty grid', () => {
    expect(createPattern(0, 3)).toEqual([]);
  });

  it('returns an empty pattern for a non-positive size', () => {
    expect(createPattern(9, -1)).toEqual([]);
  });
});
