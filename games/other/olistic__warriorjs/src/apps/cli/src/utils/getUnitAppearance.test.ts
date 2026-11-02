import { describe, expect, test } from 'vitest';

import getUnitAppearance from './getUnitAppearance.js';

describe('getUnitAppearance', () => {
  test('returns warrior appearance when warrior flag is set', () => {
    expect(getUnitAppearance('Warrior', true)).toEqual({ character: '@', color: 'cyan' });
  });

  test('returns warrior appearance regardless of name when warrior flag is set', () => {
    expect(getUnitAppearance('Sludge', true)).toEqual({ character: '@', color: 'cyan' });
  });

  describe('registered units', () => {
    test('Archer', () => {
      expect(getUnitAppearance('Archer')).toEqual({ character: 'a', color: 'yellow' });
    });

    test('Captive', () => {
      expect(getUnitAppearance('Captive')).toEqual({ character: 'C', color: 'green' });
    });

    test('Sludge', () => {
      expect(getUnitAppearance('Sludge')).toEqual({ character: 's', color: 'red' });
    });

    test('Thick Sludge', () => {
      expect(getUnitAppearance('Thick Sludge')).toEqual({ character: 'S', color: 'redBright' });
    });

    test('Wizard', () => {
      expect(getUnitAppearance('Wizard')).toEqual({ character: 'w', color: 'magenta' });
    });
  });

  describe('fallback for unknown units', () => {
    test('uses lowercase first character', () => {
      expect(getUnitAppearance('Dragon')).toEqual({ character: 'd', color: 'white' });
    });

    test('returns ? for empty name', () => {
      expect(getUnitAppearance('')).toEqual({ character: '?', color: 'white' });
    });
  });
});
