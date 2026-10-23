import { describe, expect, it } from 'vitest';
import { WORLD, clamp, createFallingObject, createGameState, createRng, formatTime, getDifficulty, movePlayer, nextSpawnIntervalSeconds, rectsOverlap, resolveCollisions, updateEntities } from '../src/gameLogic.js';

describe('game logic', () => {
  it('clamps values inside bounds', () => {
    expect(clamp(10, 0, 20)).toBe(10);
    expect(clamp(-5, 0, 20)).toBe(0);
    expect(clamp(25, 0, 20)).toBe(20);
  });

  it('keeps player inside the world', () => {
    const state = createGameState();
    const left = movePlayer({ ...state.player, x: 0 }, -1, 10);
    const right = movePlayer({ ...state.player, x: WORLD.width - state.player.width }, 1, 10);
    expect(left.x).toBe(0);
    expect(right.x).toBe(WORLD.width - state.player.width);
  });

  it('detects rectangle overlaps', () => {
    expect(rectsOverlap({ x: 0, y: 0, width: 10, height: 10 }, { x: 9, y: 9, width: 10, height: 10 })).toBe(true);
    expect(rectsOverlap({ x: 0, y: 0, width: 10, height: 10 }, { x: 11, y: 11, width: 10, height: 10 })).toBe(false);
  });

  it('resolves star and meteor collisions', () => {
    const state = createGameState();
    state.entities = [
      { id: 1, type: 'star', x: state.player.x, y: state.player.y, width: 20, height: 20, speed: 1, rotation: 0, spin: 0 },
      { id: 2, type: 'meteor', x: state.player.x, y: state.player.y, width: 20, height: 20, speed: 1, rotation: 0, spin: 0 },
      { id: 3, type: 'star', x: 10, y: 10, width: 20, height: 20, speed: 1, rotation: 0, spin: 0 }
    ];
    const result = resolveCollisions(state);
    expect(result.score).toBe(10);
    expect(result.lives).toBe(2);
    expect(result.entities).toHaveLength(1);
    expect(result.entities[0].id).toBe(3);
  });

  it('filters entities that fall out of bounds', () => {
    const entities = [
      { id: 1, type: 'star', x: 0, y: 0, width: 20, height: 20, speed: 100, rotation: 0, spin: 0 },
      { id: 2, type: 'meteor', x: 0, y: WORLD.height + 30, width: 20, height: 20, speed: 100, rotation: 0, spin: 0 }
    ];
    expect(updateEntities(entities, 1)).toHaveLength(1);
  });

  it('creates deterministic objects with seeded rng', () => {
    expect(createFallingObject(createRng(42), 1.5, 1)).toEqual(createFallingObject(createRng(42), 1.5, 1));
  });

  it('ramps difficulty and spawn interval safely', () => {
    expect(getDifficulty(0, 0)).toBe(1);
    expect(getDifficulty(1000, 120000)).toBeLessThanOrEqual(4.5);
    expect(nextSpawnIntervalSeconds(1)).toBeGreaterThan(nextSpawnIntervalSeconds(4));
  });

  it('formats time for the HUD', () => {
    expect(formatTime(1234)).toBe('1.2s');
  });
});
