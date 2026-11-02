import { render } from 'ink-testing-library';
import React, { act } from 'react';
import { beforeEach, describe, expect, test, vi } from 'vitest';

import { type GameContext } from '../../Game.js';
import type Profile from '../../Profile.js';
import {
  type LevelCompleteChoice,
  type LevelConfig,
  type LevelReport,
  type PlaySessionState,
} from '../../types.js';

vi.mock('@warriorjs/core', () => ({
  getLevelConfig: vi.fn(),
  runLevel: vi.fn(),
}));

vi.mock('../../utils/buildLevelReport.js', () => ({
  buildLevelReport: vi.fn(),
}));

// Re-import after mocks are set up
const { getLevelConfig, runLevel } = await import('@warriorjs/core');
const { buildLevelReport } = await import('../../utils/buildLevelReport.js');
const { usePlaySession } = await import('./usePlaySession.js');

const mockedGetLevelConfig = vi.mocked(getLevelConfig);
const mockedRunLevel = vi.mocked(runLevel);
const mockedBuildLevelReport = vi.mocked(buildLevelReport);

// --- Helpers ---

function createMockProfile(overrides: Partial<Record<string, unknown>> = {}): Profile {
  return {
    tower: {
      name: 'The Narrow Path',
      hasLevel: vi.fn().mockReturnValue(true),
      levels: [1, 2, 3],
    },
    warriorName: 'Aldric',
    epic: false,
    levelNumber: 1,
    language: 'javascript',
    score: 100,
    currentEpicScore: 0,
    currentEpicGrades: [],
    isEpic: vi.fn().mockReturnValue(false),
    readPlayerCode: vi.fn().mockReturnValue('warrior.walk();'),
    isShowingClue: vi.fn().mockReturnValue(false),
    tallyPoints: vi.fn(),
    updateEpicScore: vi.fn(),
    requestClue: vi.fn(),
    getReadmeFilePath: vi.fn().mockReturnValue('/path/to/README.md'),
    calculateAverageGrade: vi.fn().mockReturnValue(0.8),
    makeProfileDirectory: vi.fn(),
    updateLastPlayedAt: vi.fn(),
    ...overrides,
  } as unknown as Profile;
}

function createMockContext(overrides: Partial<GameContext> = {}): GameContext {
  return {
    version: 'v1.0.0',
    runDirectoryPath: '/tmp/warriorjs',
    practiceLevel: undefined,
    silencePlay: false,
    towers: [],
    profile: null,
    profiles: [],
    needsProfileSetup: false,
    onCreateProfile: vi.fn(),
    onIsExistingProfile: vi.fn(),
    onPrepareNextLevel: vi.fn(),
    onPrepareEpicMode: vi.fn(),
    onGenerateProfileFiles: vi.fn(),
    onProfileSelected: vi.fn(),
    ...overrides,
  };
}

const defaultLevelConfig = {
  number: 1,
  clue: 'Try walking',
  timeBonus: 10,
  aceScore: 30,
  floor: { warrior: { maxHealth: 20 } },
} as unknown as LevelConfig;

const defaultLevelResult = {
  passed: true,
  turns: [
    [
      {
        message: 'walks forward',
        unit: { name: 'Warrior', color: '#fff' },
        floorMap: [[{ character: '@', unit: { color: '#fff' } }]],
        warriorStatus: { health: 20, score: 10 },
      },
    ],
  ],
  initialState: {
    message: '',
    unit: null,
    floorMap: [[{ character: '@', unit: { color: '#fff' } }]],
    warriorStatus: { health: 20, score: 0 },
  },
};

const defaultLevelReport: LevelReport = {
  passed: true,
  levelNumber: 1,
  hasNextLevel: true,
  scoreParts: { warrior: 10, timeBonus: 5, clearBonus: 0 },
  totalScore: 15,
  grade: 0.5,
  isEpic: false,
  previousScore: 100,
  hasClue: true,
  isShowingClue: false,
};

interface HookRef {
  state: PlaySessionState;
  handlePlayComplete: () => void;
  handleLevelCompleteChoice: (v: LevelCompleteChoice) => void;
}

function renderHook(params: {
  context: GameContext;
  profile: Profile;
  initialLevel: number;
  exit: () => void;
}) {
  const ref = React.createRef<HookRef>();

  function TestComponent() {
    const hook = usePlaySession(params);
    (ref as React.MutableRefObject<HookRef>).current = hook;
    return null;
  }

  const instance = render(React.createElement(TestComponent));
  return { ref: ref as React.RefObject<HookRef>, ...instance };
}

// --- Tests ---

describe('usePlaySession', () => {
  let exit: ReturnType<typeof vi.fn<() => void>>;
  let context: GameContext;
  let mockProfile: Profile;

  beforeEach(() => {
    vi.clearAllMocks();

    exit = vi.fn();
    context = createMockContext();
    mockProfile = createMockProfile();

    mockedGetLevelConfig.mockReturnValue(defaultLevelConfig as ReturnType<typeof getLevelConfig>);
    mockedRunLevel.mockReturnValue(defaultLevelResult as unknown as ReturnType<typeof runLevel>);
    mockedBuildLevelReport.mockReturnValue({ ...defaultLevelReport });
  });

  describe('playLevel (via mount)', () => {
    test('calls updateLastPlayedAt when starting a level', () => {
      renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      expect(mockProfile.updateLastPlayedAt).toHaveBeenCalled();
    });

    test('sets state to playing on mount', () => {
      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      expect(ref.current!.state).toEqual(expect.objectContaining({ type: 'playing' }));
      expect(mockedGetLevelConfig).toHaveBeenCalledWith(mockProfile.tower, 1, 'Aldric', false);
      expect(mockedRunLevel).toHaveBeenCalled();
    });

    test('sets error state when playerCode is null', () => {
      const noCodeProfile = createMockProfile({
        readPlayerCode: vi.fn().mockReturnValue(null),
      });

      const { ref } = renderHook({
        context,
        profile: noCodeProfile,
        initialLevel: 1,
        exit,
      });

      expect(ref.current!.state).toEqual({
        type: 'error',
        message: 'No player code found. Check your profile directory.',
      });
    });

    test('sets error state when getLevelConfig throws', () => {
      mockedGetLevelConfig.mockImplementation(() => {
        throw new Error('Config not found');
      });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      expect(ref.current!.state).toEqual({
        type: 'error',
        message: 'Config not found',
      });
    });

    test('sets error state when runLevel throws', () => {
      mockedRunLevel.mockImplementation(() => {
        throw new Error('Syntax error in player code');
      });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      expect(ref.current!.state).toEqual({
        type: 'error',
        message: 'Syntax error in player code',
      });
    });

    test('handles non-Error thrown values', () => {
      mockedRunLevel.mockImplementation(() => {
        // biome-ignore lint/style/useThrowOnlyError: testing non-Error throw handling
        throw 'string error';
      });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      expect(ref.current!.state).toEqual({
        type: 'error',
        message: 'string error',
      });
    });

    test('defaults language to javascript when profile language is falsy', () => {
      const noLangProfile = createMockProfile({ language: '' });

      renderHook({
        context,
        profile: noLangProfile,
        initialLevel: 1,
        exit,
      });

      expect(mockedRunLevel).toHaveBeenCalledWith(
        defaultLevelConfig,
        'warrior.walk();',
        'javascript',
      );
    });

    test('skips playing state when silencePlay is true', () => {
      context = createMockContext({ silencePlay: true });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      // Should go directly to levelComplete (evaluateLevel), not playing.
      expect(mockedBuildLevelReport).toHaveBeenCalled();
      expect(ref.current!.state).toEqual(expect.objectContaining({ type: 'levelComplete' }));
    });

    test('uses currentEpicScore for epic profiles in levelRun', () => {
      const epicProfile = createMockProfile({
        isEpic: vi.fn().mockReturnValue(true),
        currentEpicScore: 42,
      });

      const { ref } = renderHook({
        context,
        profile: epicProfile,
        initialLevel: 1,
        exit,
      });

      expect(ref.current!.state).toEqual(expect.objectContaining({ type: 'playing' }));
      const playingState = ref.current!.state as {
        type: 'playing';
        context: { totalScore: number };
      };
      expect(playingState.context.totalScore).toBe(42);
    });

    test('uses profile.score for non-epic profiles in levelRun', () => {
      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      const playingState = ref.current!.state as {
        type: 'playing';
        context: { totalScore: number };
      };
      expect(playingState.context.totalScore).toBe(100);
    });
  });

  describe('evaluateLevel (via handlePlayComplete)', () => {
    test('tallies points when result is passed', () => {
      mockedBuildLevelReport.mockReturnValue({
        ...defaultLevelReport,
        passed: true,
        totalScore: 15,
        grade: 0.5,
      });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      act(() => {
        ref.current!.handlePlayComplete();
      });

      expect(mockProfile.tallyPoints).toHaveBeenCalledWith(1, 15, 0.5);
    });

    test('does not tally points when result failed', () => {
      mockedBuildLevelReport.mockReturnValue({
        ...defaultLevelReport,
        passed: false,
      });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      act(() => {
        ref.current!.handlePlayComplete();
      });

      expect(mockProfile.tallyPoints).not.toHaveBeenCalled();
    });

    test('epic auto-advance: plays next level instead of showing result', () => {
      mockedBuildLevelReport.mockReturnValue({
        ...defaultLevelReport,
        passed: true,
        isEpic: true,
        hasNextLevel: true,
      });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      mockedGetLevelConfig.mockClear();

      act(() => {
        ref.current!.handlePlayComplete();
      });

      // Should have called getLevelConfig for level 2.
      expect(mockedGetLevelConfig).toHaveBeenCalledWith(mockProfile.tower, 2, 'Aldric', false);
    });

    test('epic auto-advance does not happen when practiceLevel is set', () => {
      context = createMockContext({ practiceLevel: 1 });
      mockedBuildLevelReport.mockReturnValue({
        ...defaultLevelReport,
        passed: true,
        isEpic: true,
        hasNextLevel: true,
      });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      act(() => {
        ref.current!.handlePlayComplete();
      });

      // Should show levelComplete instead of auto-advancing.
      expect(ref.current!.state).toEqual(
        expect.objectContaining({
          type: 'levelComplete',
          action: { type: 'prompt' },
        }),
      );
    });

    test('epic tower complete: updates epic score and shows towerComplete', () => {
      mockedBuildLevelReport.mockReturnValue({
        ...defaultLevelReport,
        passed: true,
        isEpic: true,
        hasNextLevel: false,
      });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 3,
        exit,
      });

      act(() => {
        ref.current!.handlePlayComplete();
      });

      expect(mockProfile.updateEpicScore).toHaveBeenCalled();
      expect(ref.current!.state).toEqual({ type: 'towerComplete' });
    });

    test('epic tower complete does not happen when practiceLevel is set', () => {
      context = createMockContext({ practiceLevel: 3 });
      mockedBuildLevelReport.mockReturnValue({
        ...defaultLevelReport,
        passed: true,
        isEpic: true,
        hasNextLevel: false,
      });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 3,
        exit,
      });

      act(() => {
        ref.current!.handlePlayComplete();
      });

      // Should show levelComplete instead of towerComplete.
      expect(ref.current!.state).toEqual(
        expect.objectContaining({
          type: 'levelComplete',
          action: { type: 'prompt' },
        }),
      );
    });

    test('shows levelComplete state for normal passed result', () => {
      mockedBuildLevelReport.mockReturnValue({
        ...defaultLevelReport,
        passed: true,
        isEpic: false,
      });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      act(() => {
        ref.current!.handlePlayComplete();
      });

      expect(ref.current!.state).toEqual(
        expect.objectContaining({
          type: 'levelComplete',
          action: { type: 'prompt' },
        }),
      );
    });

    test('shows levelComplete state for failed result', () => {
      mockedBuildLevelReport.mockReturnValue({
        ...defaultLevelReport,
        passed: false,
      });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      act(() => {
        ref.current!.handlePlayComplete();
      });

      expect(ref.current!.state).toEqual(
        expect.objectContaining({
          type: 'levelComplete',
          action: { type: 'prompt' },
        }),
      );
    });

    test('passes isShowingClue false when level passed', () => {
      context = createMockContext({ silencePlay: true });

      mockedRunLevel.mockReturnValue({
        ...defaultLevelResult,
        passed: true,
      } as unknown as ReturnType<typeof runLevel>);

      renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      expect(mockedBuildLevelReport).toHaveBeenCalledWith(
        expect.objectContaining({ isShowingClue: false }),
      );
    });

    test('passes profile isShowingClue when level failed', () => {
      context = createMockContext({ silencePlay: true });

      mockedRunLevel.mockReturnValue({
        ...defaultLevelResult,
        passed: false,
      } as unknown as ReturnType<typeof runLevel>);
      (mockProfile.isShowingClue as ReturnType<typeof vi.fn>).mockReturnValue(true);

      renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      expect(mockedBuildLevelReport).toHaveBeenCalledWith(
        expect.objectContaining({ isShowingClue: true }),
      );
    });

    test('uses currentEpicScore for epic profiles in buildLevelReport', () => {
      const epicProfile = createMockProfile({
        isEpic: vi.fn().mockReturnValue(true),
        currentEpicScore: 200,
      });

      context = createMockContext({ silencePlay: true });

      renderHook({
        context,
        profile: epicProfile,
        initialLevel: 1,
        exit,
      });

      expect(mockedBuildLevelReport).toHaveBeenCalledWith(
        expect.objectContaining({
          isEpic: true,
          currentScore: 200,
        }),
      );
    });
  });

  describe('handlePlayComplete', () => {
    test('processes pending result when present', () => {
      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      // State is 'playing' after mount, pending result is stored.
      act(() => {
        ref.current!.handlePlayComplete();
      });

      expect(mockedBuildLevelReport).toHaveBeenCalled();
    });

    test('returns to levelComplete state after review', () => {
      mockedBuildLevelReport.mockReturnValue({
        ...defaultLevelReport,
        passed: true,
        isEpic: false,
      });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      // Complete playback to get to levelComplete.
      act(() => {
        ref.current!.handlePlayComplete();
      });

      // Select review to set reviewReturnRef.
      act(() => {
        ref.current!.handleLevelCompleteChoice('review');
      });

      // handlePlayComplete should now return to levelComplete.
      act(() => {
        ref.current!.handlePlayComplete();
      });

      expect(ref.current!.state).toEqual(
        expect.objectContaining({
          type: 'levelComplete',
          action: { type: 'prompt' },
        }),
      );
    });

    test('calls exit when no pending result or review return', () => {
      // Use silencePlay so playLevel goes directly to evaluateLevel (no pending).
      context = createMockContext({ silencePlay: true });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      // State is levelComplete after mount (silencePlay skipped playing),
      // so handlePlayComplete with no pending and no review should exit.
      act(() => {
        ref.current!.handlePlayComplete();
      });

      expect(exit).toHaveBeenCalled();
    });
  });

  describe('handleLevelCompleteChoice', () => {
    test('returns early when currentReportRef is null', () => {
      // Use silencePlay to make evaluateLevel run immediately on mount.
      // When the result is towerComplete, currentReportRef won't be set.
      mockedBuildLevelReport.mockReturnValue({
        ...defaultLevelReport,
        passed: true,
        isEpic: true,
        hasNextLevel: false,
      });
      context = createMockContext({ silencePlay: true });

      const { ref } = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      // State is towerComplete; currentReportRef was not set.
      const stateBeforeSelect = ref.current!.state;

      act(() => {
        ref.current!.handleLevelCompleteChoice('review');
      });

      // State should be unchanged (no-op).
      expect(ref.current!.state).toEqual(stateBeforeSelect);
    });

    // Helper to get the hook into a state where currentReportRef is set.
    function setupWithResultScreen() {
      mockedBuildLevelReport.mockReturnValue({
        ...defaultLevelReport,
        passed: true,
        isEpic: false,
      });

      const hookResult = renderHook({
        context,
        profile: mockProfile,
        initialLevel: 1,
        exit,
      });

      // Complete playback to trigger evaluateLevel, which sets currentReportRef.
      act(() => {
        hookResult.ref.current!.handlePlayComplete();
      });

      return hookResult;
    }

    test('review: sets playing state with reviewMode', () => {
      const { ref } = setupWithResultScreen();

      act(() => {
        ref.current!.handleLevelCompleteChoice('review');
      });

      expect(ref.current!.state).toEqual(
        expect.objectContaining({
          type: 'playing',
          reviewMode: true,
        }),
      );
    });

    test('next-level: calls onPrepareNextLevel and shows next-level action', () => {
      const { ref } = setupWithResultScreen();

      act(() => {
        ref.current!.handleLevelCompleteChoice('next-level');
      });

      expect(context.onPrepareNextLevel).toHaveBeenCalled();
      expect(ref.current!.state).toEqual(
        expect.objectContaining({
          type: 'levelComplete',
          action: {
            type: 'next-level',
            readmePath: '/path/to/README.md',
          },
        }),
      );
    });

    test('clue: calls requestClue, onGenerateProfileFiles, and shows clue action', () => {
      const { ref } = setupWithResultScreen();

      act(() => {
        ref.current!.handleLevelCompleteChoice('clue');
      });

      expect(mockProfile.requestClue).toHaveBeenCalled();
      expect(context.onGenerateProfileFiles).toHaveBeenCalled();
      expect(ref.current!.state).toEqual(
        expect.objectContaining({
          type: 'levelComplete',
          action: {
            type: 'clue',
            readmePath: '/path/to/README.md',
          },
        }),
      );
    });

    test('stay: shows levelComplete state with stay action', () => {
      const { ref } = setupWithResultScreen();

      act(() => {
        ref.current!.handleLevelCompleteChoice('stay');
      });

      expect(ref.current!.state).toEqual(
        expect.objectContaining({
          type: 'levelComplete',
          action: { type: 'stay' },
        }),
      );
    });

    test('epic-mode: calls onPrepareEpicMode and shows epic-mode action', () => {
      const { ref } = setupWithResultScreen();

      act(() => {
        ref.current!.handleLevelCompleteChoice('epic-mode');
      });

      expect(context.onPrepareEpicMode).toHaveBeenCalled();
      expect(ref.current!.state).toEqual(
        expect.objectContaining({
          type: 'levelComplete',
          action: { type: 'epic-mode' },
        }),
      );
    });

    test('try-again: replays the same level', () => {
      const { ref } = setupWithResultScreen();

      mockedGetLevelConfig.mockClear();
      mockedRunLevel.mockClear();

      act(() => {
        ref.current!.handleLevelCompleteChoice('try-again');
      });

      // Should call playLevel with the same level number from levelReport.
      expect(mockedGetLevelConfig).toHaveBeenCalledWith(
        mockProfile.tower,
        defaultLevelReport.levelNumber,
        'Aldric',
        false,
      );
      expect(mockedRunLevel).toHaveBeenCalled();
    });
  });
});
