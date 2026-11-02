import { type FloorSpace } from '@warriorjs/core';
import { render } from 'ink-testing-library';
import { describe, expect, test } from 'vitest';

import FloorMap from './FloorMap.js';

describe('FloorMap', () => {
  const e: FloorSpace = {};
  const s: FloorSpace = { stairs: true };
  const w: FloorSpace = { wall: true };
  const warrior: FloorSpace = { unit: { name: 'Aldric', maxHealth: 20, warrior: true } };

  test('renders floor map characters', () => {
    const floorMap: FloorSpace[][] = [
      [w, w, w],
      [w, warrior, w],
      [w, w, w],
    ];
    const { lastFrame } = render(<FloorMap floorMap={floorMap} />);
    const output = lastFrame()!;
    expect(output).toContain('╔');
    expect(output).toContain('@');
    expect(output).toContain('╝');
  });

  test('renders empty spaces and stairs', () => {
    const floorMap = [[e, s]];
    const { lastFrame } = render(<FloorMap floorMap={floorMap} />);
    const output = lastFrame()!;
    expect(output).toContain('>');
  });
});
