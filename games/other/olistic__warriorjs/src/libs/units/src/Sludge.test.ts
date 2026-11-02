import { beforeEach, describe, expect, test } from 'vitest';

import MeleeUnit from './MeleeUnit.js';
import Sludge from './Sludge.js';

describe('Sludge', () => {
  let sludge: Sludge;

  beforeEach(() => {
    sludge = new Sludge();
  });

  test('extends MeleeUnit', () => {
    expect(sludge).toBeInstanceOf(MeleeUnit);
  });

  test('has 12 max health', () => {
    expect(sludge.maxHealth).toBe(12);
  });

  test('has attack ability', () => {
    expect(Sludge.declaredAbilities).toHaveProperty('attack');
  });

  test('has feel ability', () => {
    expect(Sludge.declaredAbilities).toHaveProperty('feel');
  });
});
