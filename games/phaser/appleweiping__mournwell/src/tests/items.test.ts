import { describe, expect, it } from 'vitest';
import { BASE_STATS, addItem, deriveStats } from '@/game/data/items';

describe('relic stat engine', () => {
  it('returns exact base attributes for an empty inventory', () => {
    expect(deriveStats({})).toEqual(BASE_STATS);
  });

  it('recomputes additive and multiplicative stacks without drift', () => {
    const inventory = {
      'iron-lament': 2,
      quickwick: 2,
      longglass: 3,
      'mudrunner-soles': 20,
      'blackwax-knot': 2,
      'briar-eye': 7,
      'compass-moth': 6,
    };
    const first = deriveStats(inventory);
    const second = deriveStats(inventory);
    expect(first).toEqual(second);
    expect(first.damage).toBe(28);
    expect(first.fireInterval).toBe(201);
    expect(first.range).toBe(575);
    expect(first.shotSpeed).toBe(605);
    expect(first.moveSpeed).toBe(340);
    expect(first.maxHp).toBe(140);
    expect(first.pierce).toBe(3);
    expect(first.homing).toBe(0.36);
  });

  it('changes casting mode at one and two Twin Rune stacks', () => {
    expect(deriveStats({ 'twin-rune': 1 })).toMatchObject({ projectiles: 3, spread: 0.2, damage: 11.16 });
    expect(deriveStats({ 'twin-rune': 2 })).toMatchObject({ projectiles: 5, spread: 0.31, damage: 7.56 });
  });

  it('adds items immutably and rejects unknown content IDs', () => {
    const original = { quickwick: 1 };
    const next = addItem(original, 'quickwick');
    expect(original).toEqual({ quickwick: 1 });
    expect(next).toEqual({ quickwick: 2 });
    expect(() => addItem({}, 'not-a-real-relic')).toThrow('Unknown item');
  });
});
