import { describe, expect, it } from 'vitest';
import { FLOORS, LAST_FLOOR, floorSeed, floorTheme } from '@/game/data/floors';
import { generateDungeon, validateDungeon } from '@/game/systems/dungeon';

describe('depths', () => {
  it('has two depths and the new enemies only live in the second', () => {
    expect(LAST_FLOOR).toBe(2);
    expect(floorTheme(1).roster).not.toContain('ashmoth');
    expect(floorTheme(1).roster).not.toContain('chimewraith');
    // the first `primaries` enemies lead waves, so Depth II waves open with the new ones
    expect(floorTheme(2).roster.slice(0, floorTheme(2).primaries)).toEqual(['ashmoth', 'chimewraith']);
    expect(floorTheme(2).bossSummon).toBe('ashmoth');
    expect(floorTheme(99)).toBe(FLOORS[LAST_FLOOR - 1]);
  });

  it('keeps old seeds on depth one and gives depth two its own valid layout', () => {
    expect(floorSeed('ASH-17', 1)).toBe('ASH-17');
    const first = generateDungeon(floorSeed('ASH-17', 1));
    const second = generateDungeon(floorSeed('ASH-17', 2));
    expect(validateDungeon(second)).toEqual([]);
    expect(second.rooms.map((room) => [room.x, room.y])).not.toEqual(
      first.rooms.map((room) => [room.x, room.y]),
    );
  });

  it('every depth-two layout for 500 seeds is valid', () => {
    for (let index = 0; index < 500; index += 1) {
      expect(validateDungeon(generateDungeon(floorSeed(`SEED-${index}`, 2)))).toEqual([]);
    }
  });
});
