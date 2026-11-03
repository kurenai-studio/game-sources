import { describe, expect, it } from 'vitest';
import { DEG, pointInPolygon } from '../src/core/geometry';
import { buildWallSegments, castRay, visibilityPolygon } from '../src/core/visibility';
import { parseLevel, blocksSight } from '../src/core/grid';

describe('visibility', () => {
  // 5x3 room with a pillar in the middle:
  //   #####
  //   #.#.#   <- (2,1) is the pillar
  //   #####
  const rows = ['#####', '#.#.#', '#####'];
  const level = parseLevel(rows);
  const blocks = (x: number, y: number) => blocksSight(level.tiles[y * level.width + x]);
  const segs = buildWallSegments(level.width, level.height, 32, blocks);

  it('merges wall edges into few segments', () => {
    // Two 1x1 cells: four edges each.
    expect(segs.length).toBe(8);
  });

  it('stops rays at walls', () => {
    // From the centre of cell (1,1) looking east, the pillar face is at x=64.
    expect(castRay(48, 48, 1, 0, 1000, segs)).toBeCloseTo(16);
  });

  it('keeps the cone inside the room', () => {
    const { polygon, hits } = visibilityPolygon(48, 48, 0, 50 * DEG, 500, segs, 2 * DEG);
    expect(polygon[0]).toBe(48);
    expect(hits.every((h) => h.blocked)).toBe(true);
    for (let i = 0; i < polygon.length; i += 2) {
      expect(polygon[i]).toBeGreaterThanOrEqual(32 - 1e-6);
      expect(polygon[i]).toBeLessThanOrEqual(64 + 1e-6);
    }
    expect(pointInPolygon(60, 48, polygon)).toBe(true);
    expect(pointInPolygon(112, 48, polygon)).toBe(false);
  });

  it('builds a full circle for peripheral vision', () => {
    const { polygon } = visibilityPolygon(48, 48, 0, Math.PI, 10, segs, 10 * DEG);
    expect(pointInPolygon(40, 48, polygon)).toBe(true);
    expect(pointInPolygon(56, 48, polygon)).toBe(true);
  });
});
