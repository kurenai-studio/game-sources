import { describe, expect, it } from 'vitest';
import { DEG, pointInPolygon, rayCircle, raySegment, rotateTowards, wrapAngle } from '../src/core/geometry';
import { moveCircle } from '../src/core/collision';

describe('geometry', () => {
  it('wraps angles into [-PI, PI)', () => {
    expect(wrapAngle(Math.PI * 3)).toBeCloseTo(-Math.PI);
    expect(wrapAngle(-Math.PI / 2)).toBeCloseTo(-Math.PI / 2);
  });

  it('rotates the short way round', () => {
    const a = rotateTowards(170 * DEG, -170 * DEG, 5 * DEG);
    expect(wrapAngle(a)).toBeCloseTo(175 * DEG);
  });

  it('intersects rays with segments', () => {
    const seg = { ax: 10, ay: -5, bx: 10, by: 5 };
    expect(raySegment(0, 0, 1, 0, seg)).toBeCloseTo(10);
    expect(raySegment(0, 0, -1, 0, seg)).toBe(Infinity);
    expect(raySegment(0, 20, 1, 0, seg)).toBe(Infinity);
  });

  it('intersects rays with circles', () => {
    expect(rayCircle(0, 0, 1, 0, 10, 0, 2)).toBeCloseTo(8);
    expect(rayCircle(0, 0, 0, 1, 10, 0, 2)).toBe(Infinity);
    expect(rayCircle(10, 0, 1, 0, 10, 0, 2)).toBe(0);
  });

  it('tests points in polygons', () => {
    const sq = [0, 0, 10, 0, 10, 10, 0, 10];
    expect(pointInPolygon(5, 5, sq)).toBe(true);
    expect(pointInPolygon(15, 5, sq)).toBe(false);
  });
});

describe('collision', () => {
  const solid = (tx: number, ty: number) => tx < 0 || ty < 0 || tx > 4 || ty > 4 || tx === 3;

  it('stops a circle at a wall', () => {
    const p = moveCircle(80, 80, 100, 0, 10, 32, solid);
    expect(p.x).toBeCloseTo(96 - 10);
    expect(p.y).toBeCloseTo(80);
  });

  it('slides along walls', () => {
    const p = moveCircle(80, 80, 20, 20, 10, 32, solid);
    expect(p.x).toBeCloseTo(86);
    expect(p.y).toBeCloseTo(100);
  });
});
