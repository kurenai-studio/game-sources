import { getLevelScore } from '@warriorjs/scoring';

import { type LevelConfig, type LevelReport, type TurnEvent } from '../types.js';

interface BuildLevelReportParams {
  levelResult: { passed: boolean; turns: TurnEvent[][] };
  levelConfig: LevelConfig;
  levelNumber: number;
  hasNextLevel: boolean;
  isEpic: boolean;
  currentScore: number;
  isShowingClue: boolean;
}

export function buildLevelReport({
  levelResult,
  levelConfig,
  levelNumber,
  hasNextLevel,
  isEpic,
  currentScore,
  isShowingClue,
}: BuildLevelReportParams): LevelReport {
  if (!levelResult.passed) {
    return {
      passed: false,
      levelNumber,
      hasNextLevel,
      scoreParts: { warrior: 0, timeBonus: 0, clearBonus: 0 },
      totalScore: 0,
      grade: 0,
      isEpic,
      previousScore: currentScore,
      hasClue: !!levelConfig.clue,
      isShowingClue,
    };
  }

  const scoreParts = getLevelScore(levelResult, { timeBonus: levelConfig.timeBonus ?? 0 })!;
  const totalScore = scoreParts.warrior + scoreParts.timeBonus + scoreParts.clearBonus;
  const grade = levelConfig.aceScore ? totalScore / levelConfig.aceScore : 0;

  return {
    passed: true,
    levelNumber,
    hasNextLevel,
    scoreParts,
    totalScore,
    grade,
    isEpic,
    previousScore: currentScore,
    hasClue: false,
    isShowingClue: false,
  };
}
