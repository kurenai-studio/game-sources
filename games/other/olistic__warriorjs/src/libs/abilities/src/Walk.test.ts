import { Action } from '@warriorjs/core';
import { FORWARD, RIGHT } from '@warriorjs/spatial';
import { beforeEach, describe, expect, test, vi } from 'vitest';

import Walk from './Walk.js';

describe('Walk', () => {
  let walk: Walk;
  let unit: any;

  beforeEach(() => {
    unit = {
      move: vi.fn(),
      emit: vi.fn(),
    };
    walk = new Walk(unit);
  });

  test('is an action', () => {
    expect(walk).toBeInstanceOf(Action);
  });

  test('has a description', () => {
    expect(walk.description).toBe(
      `Moves one space in the given direction (\`'${FORWARD}'\` by default).`,
    );
  });

  test('has meta for type generation', () => {
    expect(walk.meta).toEqual({
      params: [{ name: 'direction', type: 'Direction', optional: true }],
      returns: 'void',
    });
  });

  describe('performing', () => {
    test('walks forward by default', () => {
      unit.getSpaceAt = vi.fn(() => ({ isEmpty: () => true }));
      walk.perform();
      expect(unit.getSpaceAt).toHaveBeenCalledWith(FORWARD);
    });

    test('allows to specify direction', () => {
      unit.getSpaceAt = vi.fn(() => ({ isEmpty: () => true }));
      walk.perform(RIGHT);
      expect(unit.getSpaceAt).toHaveBeenCalledWith(RIGHT);
    });

    test('emits unit ref when bumping into a unit', () => {
      unit.getSpaceAt = () => ({
        isEmpty: () => false,
        getUnit: () => ({ name: 'Sludge', isWarrior: () => false }),
        toString: () => 'Sludge',
      });
      walk.perform();
      expect(unit.emit).toHaveBeenCalledWith({
        type: 'walk',
        description: 'walks {direction} and bumps into {obstacle}',
        params: {
          direction: FORWARD,
          obstacle: { type: 'unit', name: 'Sludge', warrior: false },
          blocked: true,
        },
      });
      expect(unit.move).not.toHaveBeenCalled();
    });

    test('emits string when bumping into a wall', () => {
      unit.getSpaceAt = () => ({
        isEmpty: () => false,
        getUnit: () => undefined,
        toString: () => 'wall',
      });
      walk.perform();
      expect(unit.emit).toHaveBeenCalledWith({
        type: 'walk',
        description: 'walks {direction} and bumps into {obstacle}',
        params: { direction: FORWARD, obstacle: 'wall', blocked: true },
      });
      expect(unit.move).not.toHaveBeenCalled();
    });

    test('moves in specified direction if space is empty', () => {
      unit.getSpaceAt = () => ({ isEmpty: () => true });
      walk.perform(RIGHT);
      expect(unit.emit).toHaveBeenCalledWith({
        type: 'walk',
        description: 'walks {direction}',
        params: { direction: RIGHT, blocked: false },
      });
      expect(unit.move).toHaveBeenCalledWith(RIGHT);
    });
  });
});
