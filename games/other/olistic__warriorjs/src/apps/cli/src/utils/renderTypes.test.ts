import { describe, expect, test, vi } from 'vitest';

vi.mock('@warriorjs/core', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@warriorjs/core')>();
  return { ...actual, getLevel: vi.fn() };
});

import { getLevel } from '@warriorjs/core';

import renderTypes from './renderTypes.js';

const profile: any = { language: 'typescript' };

function setup(abilities: any[]) {
  (getLevel as any).mockReturnValue({ warriorAbilities: abilities });
  return {} as any; // levelConfig — not inspected since getLevel is mocked
}

describe('renderTypes', () => {
  test('renders types with a single action', () => {
    const levelConfig = setup([
      {
        name: 'walk',
        description: 'Walks forward',
        meta: {
          params: [{ name: 'direction', type: 'Direction', optional: true }],
          returns: 'void',
        },
        isAction: true,
      },
    ]);
    expect(renderTypes(profile, levelConfig)).toBe(
      [
        '// @generated — Auto-generated each level. Do not edit.',
        '',
        '/** A direction relative to where the warrior is facing. */',
        "export type Direction = 'forward' | 'right' | 'backward' | 'left';",
        '',
        '/** Your warrior. */',
        'export interface Warrior {',
        '  /** Walks forward */',
        '  walk(direction?: Direction): void;',
        '}',
        '',
      ].join('\n'),
    );
  });

  test('renders types with actions before senses, both sorted alphabetically', () => {
    const levelConfig = setup([
      {
        name: 'feel',
        description: 'Feels the space ahead',
        meta: {
          params: [{ name: 'direction', type: 'Direction', optional: true }],
          returns: 'Space',
        },
        isAction: false,
      },
      {
        name: 'health',
        description: 'Returns current health',
        meta: { params: [], returns: 'number' },
        isAction: false,
      },
      {
        name: 'walk',
        description: 'Walks forward',
        meta: {
          params: [{ name: 'direction', type: 'Direction', optional: true }],
          returns: 'void',
        },
        isAction: true,
      },
    ]);
    expect(renderTypes(profile, levelConfig)).toBe(
      [
        '// @generated — Auto-generated each level. Do not edit.',
        '',
        '/** A direction relative to where the warrior is facing. */',
        "export type Direction = 'forward' | 'right' | 'backward' | 'left';",
        '',
        '/** A unit on the floor. */',
        'export interface Unit {',
        '  /** Determines if the unit is bound. */',
        '  isBound(): boolean;',
        '  /** Determines if the unit is an enemy. */',
        '  isEnemy(): boolean;',
        '  /** Determines if the unit is under the given effect. */',
        '  isUnderEffect(name: string): boolean;',
        '}',
        '',
        '/** A space on the floor. */',
        'export interface Space {',
        '  /** Returns the relative location of this space as the offset `[forward, right]`. */',
        '  getLocation(): [number, number];',
        '  /** Returns the unit located at this space, or `null` if there is none. */',
        '  getUnit(): Unit | null;',
        '  /** Determines if nothing (except maybe stairs) is at this space. */',
        '  isEmpty(): boolean;',
        '  /** Determines if the stairs are at this space. */',
        '  isStairs(): boolean;',
        '  /** Determines if there is a unit at this space. */',
        '  isUnit(): boolean;',
        '  /** Determines if this space is the edge of the level. */',
        '  isWall(): boolean;',
        '}',
        '',
        '/** Your warrior. */',
        'export interface Warrior {',
        '  /** Walks forward */',
        '  walk(direction?: Direction): void;',
        '  /** Feels the space ahead */',
        '  feel(direction?: Direction): Space;',
        '  /** Returns current health */',
        '  health(): number;',
        '}',
        '',
      ].join('\n'),
    );
  });

  test('omits Space and Unit interfaces when no abilities use Space', () => {
    const levelConfig = setup([
      {
        name: 'walk',
        description: 'Walks forward',
        meta: {
          params: [{ name: 'direction', type: 'Direction', optional: true }],
          returns: 'void',
        },
        isAction: true,
      },
      {
        name: 'health',
        description: 'Returns current health',
        meta: { params: [], returns: 'number' },
        isAction: false,
      },
    ]);
    expect(renderTypes(profile, levelConfig)).toBe(
      [
        '// @generated — Auto-generated each level. Do not edit.',
        '',
        '/** A direction relative to where the warrior is facing. */',
        "export type Direction = 'forward' | 'right' | 'backward' | 'left';",
        '',
        '/** Your warrior. */',
        'export interface Warrior {',
        '  /** Walks forward */',
        '  walk(direction?: Direction): void;',
        '  /** Returns current health */',
        '  health(): number;',
        '}',
        '',
      ].join('\n'),
    );
  });

  test('handles rest parameters', () => {
    const levelConfig = setup([
      {
        name: 'multi',
        description: 'Does something with rest params',
        meta: { params: [{ name: 'targets', type: 'any', rest: true }], returns: 'void' },
        isAction: true,
      },
    ]);
    expect(renderTypes(profile, levelConfig)).toBe(
      [
        '// @generated — Auto-generated each level. Do not edit.',
        '',
        '/** A direction relative to where the warrior is facing. */',
        "export type Direction = 'forward' | 'right' | 'backward' | 'left';",
        '',
        '/** Your warrior. */',
        'export interface Warrior {',
        '  /** Does something with rest params */',
        '  multi(...targets: any[]): void;',
        '}',
        '',
      ].join('\n'),
    );
  });

  test('handles empty abilities', () => {
    const levelConfig = setup([]);
    expect(renderTypes(profile, levelConfig)).toBe(
      [
        '// @generated — Auto-generated each level. Do not edit.',
        '',
        '/** A direction relative to where the warrior is facing. */',
        "export type Direction = 'forward' | 'right' | 'backward' | 'left';",
        '',
        '/** Your warrior. */',
        'export interface Warrior {}',
        '',
      ].join('\n'),
    );
  });
});
