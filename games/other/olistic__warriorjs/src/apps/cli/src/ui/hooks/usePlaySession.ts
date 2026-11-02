import { getLevelConfig, runLevel } from '@warriorjs/core';
import { useCallback, useState } from 'react';

import { type GameContext } from '../../Game.js';
import type Profile from '../../Profile.js';
import {
  type LevelCompleteAction,
  type LevelCompleteChoice,
  type LevelContext,
  type LevelOutcome,
  type LevelReplay,
  type PlaySessionState,
  type SessionPhase,
} from '../../types.js';
import { buildLevelReport } from '../../utils/buildLevelReport.js';

interface UsePlaySessionParams {
  context: GameContext;
  profile: Profile;
  initialLevel: number;
  exit: () => void;
}

interface UsePlaySessionReturn {
  state: PlaySessionState;
  handlePlayComplete: () => void;
  handleLevelCompleteChoice: (value: LevelCompleteChoice) => void;
}

function runPlayerLevel(
  profile: Profile,
  levelNumber: number,
): {
  replay: LevelReplay;
  context: LevelContext;
  outcome: LevelOutcome;
} {
  const { tower, warriorName, epic } = profile;

  const levelConfig = getLevelConfig(tower, levelNumber, warriorName, epic);
  if (!levelConfig) {
    throw new Error(`Level ${levelNumber} not found.`);
  }

  const playerCode = profile.readPlayerCode();
  if (!playerCode) {
    throw new Error('No player code found. Check your profile directory.');
  }

  const language = profile.language || 'javascript';
  const rawResult = runLevel(levelConfig, playerCode, language);
  if (!rawResult.initialState) {
    throw new Error('Level produced no initial state.');
  }

  const replay: LevelReplay = {
    turns: rawResult.turns,
    initialState: rawResult.initialState,
  };

  const context: LevelContext = {
    warriorName,
    towerName: tower.name,
    levelNumber,
    totalScore: profile.isEpic() ? profile.currentEpicScore : profile.score,
    maxHealth: levelConfig.floor.warrior.maxHealth,
  };

  const outcome: LevelOutcome = {
    profile,
    levelConfig,
    levelResult: {
      passed: rawResult.passed,
      turns: rawResult.turns,
      initialState: rawResult.initialState,
    },
  };

  return { replay, context, outcome };
}

function evaluateLevel(
  pending: LevelOutcome,
  replay: LevelReplay,
  context: LevelContext,
  gameContext: GameContext,
): SessionPhase {
  const { profile, levelConfig, levelResult } = pending;
  const levelNumber = levelConfig.number;

  const report = buildLevelReport({
    levelResult,
    levelConfig,
    levelNumber,
    hasNextLevel: profile.tower.hasLevel(levelNumber + 1),
    isEpic: profile.isEpic(),
    currentScore: profile.isEpic() ? profile.currentEpicScore : profile.score,
    isShowingClue: levelResult.passed ? false : profile.isShowingClue(),
  });

  if (report.passed) {
    profile.tallyPoints(levelNumber, report.totalScore, report.grade);
  }

  if (report.passed && report.isEpic && report.hasNextLevel && !gameContext.practiceLevel) {
    return startLevel(profile, levelNumber + 1, gameContext);
  }

  if (report.passed && report.isEpic && !report.hasNextLevel && !gameContext.practiceLevel) {
    profile.updateEpicScore();
    return { phase: 'towerComplete' };
  }

  return {
    phase: 'levelComplete',
    completedLevel: { replay, context, report },
    action: { type: 'prompt' },
  };
}

function startLevel(profile: Profile, levelNumber: number, gameContext: GameContext): SessionPhase {
  try {
    profile.updateLastPlayedAt();
    const { replay, context, outcome } = runPlayerLevel(profile, levelNumber);

    if (gameContext.silencePlay) {
      return evaluateLevel(outcome, replay, context, gameContext);
    }

    return { phase: 'playing', replay, context, outcome };
  } catch (err: unknown) {
    return { phase: 'error', message: err instanceof Error ? err.message : String(err) };
  }
}

function toPlaySessionState(session: SessionPhase): PlaySessionState {
  switch (session.phase) {
    case 'playing':
      return { type: 'playing', replay: session.replay, context: session.context };
    case 'reviewing':
      return {
        type: 'playing',
        replay: session.replay,
        context: session.context,
        reviewMode: true,
      };
    case 'levelComplete':
      return {
        type: 'levelComplete',
        replay: session.completedLevel.replay,
        context: session.completedLevel.context,
        report: session.completedLevel.report,
        action: session.action,
      };
    case 'towerComplete':
      return { type: 'towerComplete' };
    case 'error':
      return { type: 'error', message: session.message };
  }
}

export function usePlaySession({
  context: gameContext,
  profile,
  initialLevel,
  exit,
}: UsePlaySessionParams): UsePlaySessionReturn {
  const [session, setSession] = useState<SessionPhase>(() =>
    startLevel(profile, initialLevel, gameContext),
  );

  const handlePlayComplete = useCallback(() => {
    setSession((prev) => {
      if (prev.phase === 'playing') {
        return evaluateLevel(prev.outcome, prev.replay, prev.context, gameContext);
      }
      if (prev.phase === 'reviewing') {
        return {
          phase: 'levelComplete',
          completedLevel: prev.returnTo,
          action: { type: 'prompt' },
        };
      }
      exit();
      return prev;
    });
  }, [gameContext, exit]);

  const handleLevelCompleteChoice = useCallback(
    (value: LevelCompleteChoice) => {
      if (value === 'next-level') {
        gameContext.onPrepareNextLevel();
      } else if (value === 'epic-mode') {
        gameContext.onPrepareEpicMode();
      } else if (value === 'clue') {
        profile.requestClue();
        gameContext.onGenerateProfileFiles();
      }

      setSession((prev) => {
        if (prev.phase !== 'levelComplete') {
          return prev;
        }

        const { completedLevel } = prev;
        const { replay, context, report } = completedLevel;

        switch (value) {
          case 'review':
            return { phase: 'reviewing', replay, context, returnTo: completedLevel };
          case 'try-again':
            return startLevel(profile, report.levelNumber, gameContext);
          case 'stay':
            return { ...prev, action: { type: 'stay' } };
          case 'next-level':
            return {
              ...prev,
              action: {
                type: 'next-level',
                readmePath: profile.getReadmeFilePath(),
              } as LevelCompleteAction,
            };
          case 'epic-mode':
            return { ...prev, action: { type: 'epic-mode' } };
          case 'clue':
            return {
              ...prev,
              action: {
                type: 'clue',
                readmePath: profile.getReadmeFilePath(),
              } as LevelCompleteAction,
            };
        }
      });
    },
    [profile, gameContext],
  );

  const state = toPlaySessionState(session);

  return { state, handlePlayComplete, handleLevelCompleteChoice };
}
