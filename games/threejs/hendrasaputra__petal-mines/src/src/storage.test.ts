import { describe, expect, it } from 'vitest';
import { createGame, reveal, toggleFlag } from './engine';
import { readSession, writeSession, type Session } from './storage';

const known = ['classic-1', 'layered-1', 'connected-1'];
function session(): Session {
  const game = createGame({ width: 6, height: 6, mines: 6, floors: 2, seed: 'saved-petal' });
  reveal(game, 0, 14);
  const hidden = game.cells[0].findIndex(cell => !cell.revealed);
  toggleFlag(game, 0, hidden);
  return { game, active: 1, elapsed: 93, exploded: true, action: 'inspect', levelId: 'layered-1', completed: ['classic-1'] };
}

describe('versioned browser sessions', () => {
  it('round trips board, flags, navigation, time and campaign progress', () => {
    const original = session();
    const raw = writeSession(original);
    expect(JSON.parse(raw).version).toBe(2);
    expect(readSession(raw, known)).toEqual(original);
  });

  it('migrates the original versionless save without losing its board or elapsed time', () => {
    const { game, active, elapsed } = session();
    expect(readSession(JSON.stringify({ game, active, elapsed }), known)).toEqual({
      game, active, elapsed, exploded: false, action: 'reveal', levelId: null, completed: [],
    });
  });

  it.each([null, '', '{', 'null', '[]', 'true', '123', '{}'])('rejects missing or corrupt envelope %s', raw => {
    expect(readSession(raw, known)).toBeNull();
  });

  it('rejects unknown versions without pretending they are legacy saves', () => {
    for (const version of [0, 1, 3, '2', null]) {
      expect(readSession(JSON.stringify({ ...session(), version }), known)).toBeNull();
    }
  });

  it('rejects a corrupted puzzle through the engine validator', () => {
    const saved = session();
    saved.game.cells[0][0].adjacent = 999;
    expect(readSession(writeSession(saved), known)).toBeNull();
  });

  it('bounds navigation and elapsed seconds and filters unknown completed levels', () => {
    const saved = { ...session(), active: 500, elapsed: 1e20, levelId: 'removed-level',
      completed: ['classic-1', 'classic-1', 'removed-level', false, 'connected-1'] };
    const restored = readSession(JSON.stringify(saved), known)!;
    expect(restored.active).toBe(1);
    expect(restored.elapsed).toBe(604800);
    expect(restored.levelId).toBeNull();
    expect(restored.completed).toEqual(['classic-1', 'connected-1']);
  });

  it('normalizes malformed metadata while preserving a valid puzzle', () => {
    const restored = readSession(JSON.stringify({ ...session(), active: 0.5, elapsed: '12',
      exploded: 'true', action: 'delete', levelId: {}, completed: 'classic-1' }), known)!;
    expect(restored).toMatchObject({ active: 0, elapsed: 0, exploded: false, action: 'reveal', levelId: null, completed: [] });
    const negative = readSession(JSON.stringify({ ...session(), active: -2, elapsed: -10 }), known)!;
    expect(negative).toMatchObject({ active: 0, elapsed: 0 });
    expect(readSession(JSON.stringify({ ...session(), elapsed: 9.9 }), known)!.elapsed).toBe(9);
  });
});
