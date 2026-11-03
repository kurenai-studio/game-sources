import { describe, expect, it } from 'vitest';
import { SpatialHash } from '../src/sim/SpatialHash';
import { createAgent, type Agent } from '../src/sim/Agent';

function agent(x: number, y: number, alive = true): Agent {
  const a = createAgent();
  a.x = x;
  a.y = y;
  a.alive = alive;
  return a;
}

describe('SpatialHash', () => {
  it('finds neighbours inside the radius and ignores distant ones', () => {
    const hash = new SpatialHash(40);
    const agents = [agent(100, 100), agent(115, 105), agent(500, 500)];
    hash.build(agents);
    const found = hash.queryRadius(100, 100, 40);
    expect(found.length).toBe(2);
    expect(found).not.toContain(agents[2]);
  });

  it('finds neighbours across cell boundaries', () => {
    const hash = new SpatialHash(40);
    // Deliberately straddling the x = 40k boundary.
    const agents = [agent(39, 100), agent(41, 100)];
    hash.build(agents);
    expect(hash.queryRadius(39, 100, 10).length).toBe(2);
  });

  it('skips dead agents', () => {
    const hash = new SpatialHash(40);
    hash.build([agent(10, 10), agent(12, 12, false)]);
    expect(hash.queryRadius(10, 10, 20).length).toBe(1);
  });

  it('reflects positions after a rebuild', () => {
    const hash = new SpatialHash(40);
    const a = agent(10, 10);
    hash.build([a]);
    expect(hash.queryRadius(10, 10, 5).length).toBe(1);
    a.x = 900;
    a.y = 900;
    hash.build([a]);
    expect(hash.queryRadius(10, 10, 5).length).toBe(0);
    expect(hash.queryRadius(900, 900, 5).length).toBe(1);
  });

  it('handles negative world coordinates', () => {
    const hash = new SpatialHash(40);
    hash.build([agent(-100, -2400), agent(-90, -2410)]);
    expect(hash.queryRadius(-100, -2400, 30).length).toBe(2);
  });

  it('reports occupied cells for the debug overlay', () => {
    const hash = new SpatialHash(40);
    hash.build([agent(10, 10), agent(20, 20), agent(500, 500)]);
    expect(hash.occupiedCells).toBe(2);
    expect(hash.debugCells().reduce((n, c) => n + c.count, 0)).toBe(3);
  });

  it('does not leak agents between rebuilds', () => {
    const hash = new SpatialHash(40);
    const many = Array.from({ length: 50 }, (_, i) => agent(i * 3, 100));
    hash.build(many);
    hash.build([many[0]!]);
    expect(hash.queryRadius(0, 100, 200).length).toBe(1);
  });
});
