import { describe, expect, it } from 'vitest';
import { generateDungeon, validateDungeon } from '@/game/systems/dungeon';

describe('dungeon generation', () => {
  it('is deterministic for a fixed seed', () => {
    expect(generateDungeon('ASH-MOTH-1234')).toEqual(generateDungeon('ASH-MOTH-1234'));
  });

  it('satisfies every topology invariant across 10,000 seeds', () => {
    for (let index = 0; index < 10_000; index += 1) {
      const layout = generateDungeon(`PROPERTY-${index}`);
      expect(validateDungeon(layout), layout.seed).toEqual([]);
      expect(layout.rooms.length).toBeGreaterThanOrEqual(5);
      expect(layout.rooms.length).toBeLessThanOrEqual(8);
      expect(layout.rooms.filter((room) => room.kind === 'boss')).toHaveLength(1);
      expect(layout.rooms.filter((room) => room.kind === 'treasure')).toHaveLength(1);
      expect(new Set(layout.rooms.map((room) => `${room.x},${room.y}`)).size).toBe(layout.rooms.length);
    }
  });

  it('honors every supported explicit room count', () => {
    for (let count = 5; count <= 8; count += 1)
      expect(generateDungeon(`COUNT-${count}`, count).rooms).toHaveLength(count);
  });
});
