import { describe, expect, it } from 'vitest';
import { chainSpot, CIGAR_SPACING, clusterSpot, R, ROD_STEP, SPACING, wobble } from '../public/game/attach.js';

const cell = (x, y) => ({ x, y });
const distance = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);

// Grow a cluster the way the game does: keep attaching a new cell at the spot
// clusterSpot picks, approaching from a series of different directions.
function growCluster(size, twist) {
  const cells = [cell(0, 0)];
  for (let i = 1; i < size; i++) {
    const angle = i * 2.4; // approach from a different side each time
    const spot = clusterSpot(cells, twist, Math.cos(angle) * 200, Math.sin(angle) * 200);
    cells.push(cell(spot.x, spot.y));
  }
  return cells;
}

describe('wobble', () => {
  it('gives the same value for the same inputs', () => {
    expect(wobble(3, 1)).toBe(wobble(3, 1));
  });

  it('stays between -1 and 1', () => {
    for (let k = 0; k < 50; k++) {
      for (let salt = 0; salt < 5; salt++) {
        expect(Math.abs(wobble(k, salt))).toBeLessThanOrEqual(1);
      }
    }
  });
});

describe('clusterSpot', () => {
  it('returns nothing for an empty cluster', () => {
    expect(clusterSpot([], 0, 10, 10)).toBeNull();
  });

  it('puts the new cell touching a lone cell', () => {
    const only = cell(0, 0);
    const spot = clusterSpot([only], 0, 100, 0);
    expect(distance(spot, only)).toBeCloseTo(SPACING * 0.95);
  });

  it('grows on the side facing the player', () => {
    expect(clusterSpot([cell(0, 0)], 0, 100, 0).x).toBeGreaterThan(0);
    expect(clusterSpot([cell(0, 0)], 0, -100, 0).x).toBeLessThan(0);
    expect(clusterSpot([cell(0, 0)], 0, 0, 100).y).toBeGreaterThan(0);
    expect(clusterSpot([cell(0, 0)], 0, 0, -100).y).toBeLessThan(0);
  });

  it('tucks a new cell into a nook touching two cells instead of sticking out', () => {
    const pair = [cell(0, 0), cell(SPACING * 0.95, 0)];
    const spot = clusterSpot(pair, 0, SPACING / 2, -300);
    expect(distance(spot, pair[0])).toBeLessThan(SPACING * 1.15);
    expect(distance(spot, pair[1])).toBeLessThan(SPACING * 1.15);
  });

  it('never places a cell on top of another as a cluster grows to 8', () => {
    for (const twist of [0, 0.7, 1.9, 3.3, 5.1]) {
      const cells = growCluster(8, twist);
      for (let i = 0; i < cells.length; i++) {
        for (let j = i + 1; j < cells.length; j++) {
          expect(distance(cells[i], cells[j])).toBeGreaterThanOrEqual(R * 1.5);
        }
      }
    }
  });

  it('keeps a grown cluster bunched up rather than strung out', () => {
    const cells = growCluster(8, 0.7);
    // Every cell touches at least one other.
    for (const c of cells) {
      const neighbors = cells.filter((o) => o !== c && distance(o, c) < SPACING * 1.15);
      expect(neighbors.length).toBeGreaterThan(0);
    }
    // And the whole bunch stays compact: well inside eight cells end to end.
    const widest = Math.max(...cells.flatMap((a) => cells.map((b) => distance(a, b))));
    expect(widest).toBeLessThan(7 * SPACING * 0.6);
  });

  it('never picks a spot that is ruled out', () => {
    const notBelow = (x, y) => y <= 0; // e.g. an antifungal disk below
    const cells = growCluster(5, 0.7);
    for (let angle = 0; angle < 6.28; angle += 0.5) {
      const spot = clusterSpot(cells, 0.7, Math.cos(angle) * 200, Math.sin(angle) * 200, notBelow);
      expect(spot.y).toBeLessThanOrEqual(0);
    }
  });

  it('returns null when every spot is ruled out', () => {
    expect(clusterSpot([cell(0, 0)], 0, 10, 10, () => false)).toBeNull();
  });

  it('does not change the cells it is given', () => {
    const cells = [cell(0, 0), cell(SPACING, 0)];
    const before = JSON.stringify(cells);
    clusterSpot(cells, 1.2, 50, 50);
    expect(JSON.stringify(cells)).toBe(before);
  });
});

describe('clusterSpot with a scale (Maizey)', () => {
  it('spaces cells farther apart, and never closer than that', () => {
    const cells = [{ x: 0, y: 0 }];
    for (let i = 0; i < 7; i++) {
      const spot = clusterSpot(cells, 0, 100, 40 * i - 120, () => true, CIGAR_SPACING);
      cells.push({ x: spot.x, y: spot.y });
    }
    expect(distance(cells[1], cells[0])).toBeCloseTo(SPACING * 0.95 * CIGAR_SPACING);
    for (const a of cells) for (const b of cells) if (a !== b) expect(distance(a, b)).toBeGreaterThan(R * 1.5 * CIGAR_SPACING);
  });
});

describe('chainSpot', () => {
  const rod = (x, y, tilt = 0) => ({ x, y, tilt });
  const angleOf = (a, b) => Math.atan2(b.y - a.y, b.x - a.x);

  it('returns nothing for an empty chain', () => {
    expect(chainSpot([], 0, 0)).toBeNull();
  });

  it('puts the next cell past a lone cell\'s end, the way she points, on the end nearer the player', () => {
    const lone = [rod(0, 0, 0)];
    const right = chainSpot(lone, 100, 0);
    expect(distance(right, lone[0])).toBeCloseTo(ROD_STEP);
    expect(right.x).toBeGreaterThan(0);
    expect(Math.abs(right.y)).toBeLessThan(ROD_STEP * 0.4); // a slight kink at most
    expect(right.atStart).toBe(false);
    const left = chainSpot(lone, -100, 0);
    expect(left.x).toBeLessThan(0);
    expect(left.atStart).toBe(true);
  });

  it('grows a chain out in a line, never doubling back or piling up', () => {
    const cells = [rod(0, 0, 0)];
    for (let i = 1; i < 8; i++) {
      const spot = chainSpot(cells, i % 2 ? 500 : -500, 0);
      const cell = rod(spot.x, spot.y, spot.tilt);
      if (spot.atStart) cells.unshift(cell);
      else cells.push(cell);
    }
    for (let i = 1; i < cells.length; i++) {
      expect(distance(cells[i], cells[i - 1])).toBeCloseTo(ROD_STEP);
    }
    // End to end: no two cells closer than a step, and it runs long, not bunched.
    for (const a of cells) for (const b of cells) if (a !== b) expect(distance(a, b)).toBeGreaterThan(ROD_STEP * 0.8);
    expect(distance(cells[0], cells.at(-1))).toBeGreaterThan(ROD_STEP * 5);
    // Each new cell points the way the chain runs.
    const last = cells.at(-1);
    expect(Math.abs(Math.cos(angleOf(cells.at(-2), last) - (last.tilt * Math.PI) / 180))).toBeGreaterThan(0.99);
  });

  it('uses the other end when one is ruled out, and nothing when both are', () => {
    const cells = [rod(0, 0, 0), rod(ROD_STEP, 0, 0)];
    const spot = chainSpot(cells, 500, 0, (x) => x < 0);
    expect(spot.atStart).toBe(true);
    expect(chainSpot(cells, 500, 0, () => false)).toBeNull();
  });

  it('skips an end that would land on another cell', () => {
    // A chain bent back on itself: the far end's next spot is taken.
    const cells = [rod(0, 0, 0), rod(ROD_STEP, 0, 0), rod(ROD_STEP, ROD_STEP, 0), rod(0, ROD_STEP, 180)];
    const spot = chainSpot(cells, 0, 50);
    expect(cells.every((c) => distance(c, spot) > ROD_STEP * 0.8)).toBe(true);
  });
});
