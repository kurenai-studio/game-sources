import { render } from 'ink-testing-library';
import { describe, expect, test, vi } from 'vitest';

import { type GameContext } from '../../../Game.js';
import type Profile from '../../../Profile.js';
import {
  getLastContentFrame,
  makeLevelContext,
  makeLevelReplay,
  makeLevelReport,
  waitForRender,
} from '../../../testing/index.js';
import { type PlaySessionState } from '../../../types.js';
import { usePlaySession } from '../../hooks/usePlaySession.js';
import PlaySession from './PlaySession.js';

vi.mock('../../hooks/usePlaySession.js', () => ({
  usePlaySession: vi.fn(),
}));

const mockUsePlaySession = vi.mocked(usePlaySession);

const mockContext = {} as GameContext;
const mockProfile = {
  calculateAverageGrade: vi.fn(() => 0.9),
  currentEpicGrades: { '1': 1.0, '2': 0.8 } as Record<string, number>,
} as unknown as Profile;

describe('PlaySession', () => {
  test('renders PlayScreen when state is playing', () => {
    mockUsePlaySession.mockReturnValue({
      state: {
        type: 'playing',
        replay: makeLevelReplay(),
        context: makeLevelContext(),
      },
      handlePlayComplete: vi.fn(),
      handleLevelCompleteChoice: vi.fn(),
    });

    const { lastFrame } = render(
      <PlaySession context={mockContext} profile={mockProfile} initialLevel={1} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('Aldric');
    expect(output).toContain('@');
  });

  test('renders LevelCompleteScreen when state is levelComplete with prompt action', () => {
    mockUsePlaySession.mockReturnValue({
      state: {
        type: 'levelComplete',
        replay: makeLevelReplay(),
        context: makeLevelContext(),
        report: makeLevelReport({ passed: true, hasNextLevel: true }),
        action: { type: 'prompt' },
      },
      handlePlayComplete: vi.fn(),
      handleLevelCompleteChoice: vi.fn(),
    });

    const { lastFrame } = render(
      <PlaySession context={mockContext} profile={mockProfile} initialLevel={1} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('Success');
    expect(output).toContain('Next level');
  });

  test('renders TowerCompleteScreen when state is towerComplete', () => {
    mockUsePlaySession.mockReturnValue({
      state: { type: 'towerComplete' },
      handlePlayComplete: vi.fn(),
      handleLevelCompleteChoice: vi.fn(),
    });

    const { lastFrame } = render(
      <PlaySession context={mockContext} profile={mockProfile} initialLevel={1} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('average grade');
    expect(output).toContain('Level 1');
    expect(output).toContain('Level 2');
  });

  test('renders error message when state is error', () => {
    mockUsePlaySession.mockReturnValue({
      state: { type: 'error', message: 'Something went wrong' },
      handlePlayComplete: vi.fn(),
      handleLevelCompleteChoice: vi.fn(),
    });

    const { lastFrame } = render(
      <PlaySession context={mockContext} profile={mockProfile} initialLevel={1} />,
    );
    expect(lastFrame()!).toContain('Something went wrong');
  });

  test('renders nothing when state is null', () => {
    mockUsePlaySession.mockReturnValue({
      state: null as unknown as PlaySessionState,
      handlePlayComplete: vi.fn(),
      handleLevelCompleteChoice: vi.fn(),
    });

    const { lastFrame } = render(
      <PlaySession context={mockContext} profile={mockProfile} initialLevel={1} />,
    );
    expect(lastFrame()!).toBe('');
  });

  test('renders LevelCompleteScreen for terminal actions', async () => {
    mockUsePlaySession.mockReturnValue({
      state: {
        type: 'levelComplete',
        replay: makeLevelReplay(),
        context: makeLevelContext(),
        report: makeLevelReport(),
        action: { type: 'next-level', readmePath: 'path/to/README' },
      },
      handlePlayComplete: vi.fn(),
      handleLevelCompleteChoice: vi.fn(),
    });

    const { frames } = render(
      <PlaySession context={mockContext} profile={mockProfile} initialLevel={1} />,
    );
    await waitForRender();
    const output = getLastContentFrame(frames);
    expect(output).toContain('path/to/README');
    expect(output).toContain('instructions');
  });
});
