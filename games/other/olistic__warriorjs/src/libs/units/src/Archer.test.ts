import { beforeEach, describe, expect, test } from 'vitest';

import Archer from './Archer.js';
import RangedUnit from './RangedUnit.js';

describe('Archer', () => {
  let archer: Archer;

  beforeEach(() => {
    archer = new Archer();
  });

  test('extends RangedUnit', () => {
    expect(archer).toBeInstanceOf(RangedUnit);
  });

  test('has 7 max health', () => {
    expect(archer.maxHealth).toBe(7);
  });

  test('has shoot ability', () => {
    expect(Archer.declaredAbilities).toHaveProperty('shoot');
  });

  test('has look ability', () => {
    expect(Archer.declaredAbilities).toHaveProperty('look');
  });
});
