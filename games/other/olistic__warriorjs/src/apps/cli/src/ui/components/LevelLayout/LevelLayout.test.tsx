import { Text } from 'ink';
import { render } from 'ink-testing-library';
import { describe, expect, test } from 'vitest';

import { type TurnEvent } from '../../../types.js';
import LevelLayout from './LevelLayout.js';

function makeEvent(overrides: Partial<TurnEvent> = {}): TurnEvent {
  return {
    action: { type: 'test', description: 'test', params: {} },
    actor: null,
    floorMap: [
      [{ wall: true }, { unit: { name: 'Aldric', maxHealth: 20, warrior: true } }, { wall: true }],
    ],
    warriorStatus: { health: 20, score: 0 },
    ...overrides,
  };
}

describe('LevelLayout', () => {
  test('renders header, floor map, divider, and children', () => {
    const replay = { turns: [[makeEvent()]], initialState: makeEvent() };
    const context = {
      warriorName: 'Aldric',
      towerName: 'The Narrow Path',
      levelNumber: 3,
      totalScore: 42,
      maxHealth: 20,
    };
    const { lastFrame } = render(
      <LevelLayout replay={replay} context={context}>
        <Text>child content</Text>
      </LevelLayout>,
    );
    const output = lastFrame()!;
    expect(output).toContain('Aldric');
    expect(output).toContain('The Narrow Path');
    expect(output).toContain('3');
    expect(output).toContain('@');
    expect(output).toContain('child content');
    expect(output).toContain('─');
  });

  test('renders without floor map when turns are empty', () => {
    const replay = { turns: [] as TurnEvent[][], initialState: makeEvent() };
    const context = {
      warriorName: 'Aldric',
      towerName: 'The Narrow Path',
      levelNumber: 1,
      totalScore: 0,
      maxHealth: 20,
    };
    const { lastFrame } = render(
      <LevelLayout replay={replay} context={context}>
        <Text>content</Text>
      </LevelLayout>,
    );
    const output = lastFrame()!;
    expect(output).toContain('content');
    expect(output).not.toContain('@');
  });
});
