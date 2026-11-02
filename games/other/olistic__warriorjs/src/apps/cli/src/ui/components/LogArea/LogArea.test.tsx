import { render } from 'ink-testing-library';
import { describe, expect, test } from 'vitest';

import LogArea from './LogArea.js';

describe('LogArea', () => {
  const turns = [
    [
      {
        action: { type: 'noop', description: '', params: {} },
        actor: { name: 'Warrior', warrior: true },
        floorMap: [],
        warriorStatus: { health: 20, score: 0 },
      },
    ],
    [
      {
        action: {
          type: 'walk',
          description: 'walks {direction}',
          params: { direction: 'forward', blocked: false },
        },
        actor: { name: 'Warrior', warrior: true },
        floorMap: [],
        warriorStatus: { health: 20, score: 0 },
      },
    ],
    [
      {
        action: {
          type: 'attack',
          description: 'attacks {direction}',
          params: { direction: 'forward' },
        },
        actor: { name: 'Warrior', warrior: true },
        floorMap: [],
        warriorStatus: { health: 18, score: 5 },
      },
      {
        action: {
          type: 'damage',
          description: 'takes 5 damage, dies',
          params: {},
        },
        actor: { name: 'Sludge', warrior: false },
        floorMap: [],
        warriorStatus: { health: 18, score: 10 },
      },
    ],
  ];

  test('shows nothing at turn 0 event 0 (initial state)', () => {
    const { lastFrame } = render(
      <LogArea turns={turns} mode="playback" cursor={{ turn: 0, event: 0 }} />,
    );
    const output = lastFrame()!;
    expect(output).not.toContain('Turn');
  });

  test('renders first event of turn 1', () => {
    const { lastFrame } = render(
      <LogArea turns={turns} mode="playback" cursor={{ turn: 1, event: 0 }} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('Turn 1');
    expect(output).toContain('walks forward');
  });

  test('renders first event of turn 2 without second event', () => {
    const { lastFrame } = render(
      <LogArea turns={turns} mode="playback" cursor={{ turn: 2, event: 0 }} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('Turn 1');
    expect(output).toContain('walks forward');
    expect(output).toContain('Turn 2');
    expect(output).toContain('attacks forward');
    expect(output).not.toContain('Sludge');
  });

  test('renders both events of turn 2 at second event', () => {
    const { lastFrame } = render(
      <LogArea turns={turns} mode="playback" cursor={{ turn: 2, event: 1 }} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('Turn 2');
    expect(output).toContain('attacks forward');
    expect(output).toContain('Sludge');
  });

  test('renders in chronological order (oldest first)', () => {
    const { lastFrame } = render(
      <LogArea turns={turns} mode="playback" cursor={{ turn: 2, event: 1 }} />,
    );
    const output = lastFrame()!;
    const turn1Pos = output.indexOf('Turn 1');
    const turn2Pos = output.indexOf('Turn 2');
    expect(turn1Pos).toBeLessThan(turn2Pos);
  });

  test('truncates oldest lines when exceeding maxLines', () => {
    const { lastFrame } = render(
      <LogArea turns={turns} mode="playback" cursor={{ turn: 2, event: 1 }} maxLines={3} />,
    );
    const output = lastFrame()!;
    // Only 3 lines visible: Turn 2 header + 2 events. Turn 1 scrolled off.
    expect(output).toContain('Turn 2');
    expect(output).toContain('attacks forward');
    expect(output).toContain('Sludge');
    expect(output).not.toContain('Turn 1');
  });

  test('review mode shows all lines regardless of cursor position', () => {
    const { lastFrame } = render(
      <LogArea turns={turns} mode="review" cursor={{ turn: 1, event: 0 }} />,
    );
    const output = lastFrame()!;
    // In review mode, all turns are visible even when cursor is on turn 1.
    expect(output).toContain('Turn 1');
    expect(output).toContain('walks forward');
    expect(output).toContain('Turn 2');
    expect(output).toContain('attacks forward');
    expect(output).toContain('Sludge');
  });

  test('review mode at turn 0 highlights nothing', () => {
    const { lastFrame } = render(
      <LogArea turns={turns} mode="review" cursor={{ turn: 0, event: 0 }} />,
    );
    const output = lastFrame()!;
    // All events still visible, but none should be bold (no focused line).
    expect(output).toContain('walks forward');
    expect(output).toContain('attacks forward');
  });

  test('interpolates numeric params without duplication', () => {
    const damageTurns = [
      [
        {
          action: { type: 'noop', description: '', params: {} },
          actor: { name: 'Aldric', warrior: true },
          floorMap: [],
          warriorStatus: { health: 20, score: 0 },
        },
      ],
      [
        {
          action: {
            type: 'takeDamage',
            description: 'takes {amount} damage, {remainingHp} HP left',
            params: { amount: 3, remainingHp: 11 },
          },
          actor: { name: 'Aldric', warrior: true },
          floorMap: [],
          warriorStatus: { health: 11, score: 0 },
        },
      ],
    ];
    const { lastFrame } = render(
      <LogArea turns={damageTurns} mode="playback" cursor={{ turn: 1, event: 0 }} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('3 damage');
    expect(output).toContain('11 HP');
    // Ensure no duplication (the original bug).
    expect(output).not.toContain('3 damage3 damage');
    expect(output).not.toContain('11 HP11 HP');
  });

  test('interpolates recovery params without duplication', () => {
    const recoveryTurns = [
      [
        {
          action: { type: 'noop', description: '', params: {} },
          actor: { name: 'Warrior', warrior: true },
          floorMap: [],
          warriorStatus: { health: 16, score: 0 },
        },
      ],
      [
        {
          action: {
            type: 'recover',
            description: 'recovers {amount} HP, up to {remainingHp} HP',
            params: { amount: 2, remainingHp: 18 },
          },
          actor: { name: 'Warrior', warrior: true },
          floorMap: [],
          warriorStatus: { health: 18, score: 0 },
        },
      ],
    ];
    const { lastFrame } = render(
      <LogArea turns={recoveryTurns} mode="playback" cursor={{ turn: 1, event: 0 }} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('2 HP');
    expect(output).toContain('18 HP');
    expect(output).not.toContain('2 HP2 HP');
    expect(output).not.toContain('18 HP18 HP');
  });

  test('review mode centers window on focused line', () => {
    // Build enough turns so lines exceed maxLines.
    const manyTurns = [
      [
        {
          action: { type: 'noop', description: '', params: {} },
          actor: { name: 'W', warrior: true },
          floorMap: [],
          warriorStatus: { health: 20, score: 0 },
        },
      ],
      ...Array.from({ length: 8 }, (_, i) => [
        {
          action: {
            type: 'walk',
            description: `event ${i + 1}`,
            params: {},
          },
          actor: { name: 'W', warrior: true },
          floorMap: [],
          warriorStatus: { health: 20, score: 0 },
        },
      ]),
    ];
    // Focus on turn 3 with maxLines=3. Window should center around that event.
    const { lastFrame } = render(
      <LogArea turns={manyTurns} mode="review" cursor={{ turn: 3, event: 0 }} maxLines={3} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('event 3');
    // Early turns should be scrolled off.
    expect(output).not.toContain('event 1');
  });
});
