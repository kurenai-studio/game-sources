import { type FloorSpace } from '@warriorjs/core';
import { render } from 'ink-testing-library';
import { describe, expect, test, vi } from 'vitest';

import PlayScreen from './PlayScreen.js';

describe('PlayScreen', () => {
  const e: FloorSpace = {};
  const w: FloorSpace = { wall: true };
  const warrior: FloorSpace = { unit: { name: 'Aldric', maxHealth: 20, warrior: true } };

  const replay = {
    initialState: {
      action: { type: 'noop', description: '', params: {} },
      actor: null,
      floorMap: [
        [w, w, w],
        [w, warrior, w],
        [w, w, w],
      ],
      warriorStatus: { health: 20, score: 0 },
    },
    turns: [
      [
        {
          action: {
            type: 'walk',
            description: 'walks {direction}',
            params: { direction: 'forward', blocked: false },
          },
          actor: { name: 'Aldric', warrior: true },
          floorMap: [
            [w, w, w],
            [w, e, w],
            [w, w, w],
          ],
          warriorStatus: { health: 20, score: 0 },
        },
      ],
    ],
  };

  const context = {
    warriorName: 'Aldric',
    towerName: 'The Narrow Path',
    levelNumber: 1,
    totalScore: 0,
    maxHealth: 20,
  };

  test('renders initial state on turn zero', () => {
    const { lastFrame } = render(
      <PlayScreen replay={replay} context={context} onPlaybackComplete={vi.fn()} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('WarriorJS');
    expect(output).toContain('Aldric');
    expect(output).toContain('@');
    expect(output).toContain('❤');
    expect(output).toContain('Turn 0/1');
  });

  test('passes turn event counts to usePlayback', () => {
    const multiEventReplay = {
      initialState: replay.initialState,
      turns: [
        [
          {
            action: {
              type: 'attack',
              description: 'attacks {direction}',
              params: { direction: 'forward' },
            },
            actor: { name: 'Aldric', warrior: true },
            floorMap: [
              [w, w, w],
              [w, warrior, w],
              [w, w, w],
            ],
            warriorStatus: { health: 20, score: 5 },
          },
          {
            action: {
              type: 'damage',
              description: 'takes 3 damage',
              params: {},
            },
            actor: { name: 'Sludge', warrior: false },
            floorMap: [
              [w, w, w],
              [w, warrior, w],
              [w, w, w],
            ],
            warriorStatus: { health: 17, score: 5 },
          },
        ],
      ],
    };

    const { lastFrame } = render(
      <PlayScreen replay={multiEventReplay} context={context} onPlaybackComplete={vi.fn()} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('@');
    expect(output).toContain('Turn 0/1');
  });
});
