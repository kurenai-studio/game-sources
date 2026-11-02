import { describe, expect, test } from 'vitest';

import { type LevelConfig, type TurnEvent } from '../types.js';
import { buildLevelReport } from './buildLevelReport.js';

function makeEvent(score: number, floorMap: { unit?: unknown }[][] = [[]]): TurnEvent {
  return { warriorStatus: { score }, floorMap } as unknown as TurnEvent;
}

describe('buildLevelReport', () => {
  test('returns failure result when level not passed', () => {
    const result = buildLevelReport({
      levelResult: { passed: false, turns: [] },
      levelConfig: { clue: 'Try walking', timeBonus: 10, aceScore: 30 } as unknown as LevelConfig,
      levelNumber: 2,
      hasNextLevel: true,
      isEpic: false,
      currentScore: 50,
      isShowingClue: false,
    });

    expect(result).toEqual({
      passed: false,
      levelNumber: 2,
      hasNextLevel: true,
      scoreParts: { warrior: 0, timeBonus: 0, clearBonus: 0 },
      totalScore: 0,
      grade: 0,
      isEpic: false,
      previousScore: 50,
      hasClue: true,
      isShowingClue: false,
    });
  });

  test('returns failure result with isShowingClue when clue already requested', () => {
    const result = buildLevelReport({
      levelResult: { passed: false, turns: [] },
      levelConfig: { clue: 'Try walking', timeBonus: 10, aceScore: 30 } as unknown as LevelConfig,
      levelNumber: 2,
      hasNextLevel: true,
      isEpic: false,
      currentScore: 50,
      isShowingClue: true,
    });

    expect(result.hasClue).toBe(true);
    expect(result.isShowingClue).toBe(true);
  });

  test('returns failure result with hasClue false when no clue exists', () => {
    const result = buildLevelReport({
      levelResult: { passed: false, turns: [] },
      levelConfig: { timeBonus: 10, aceScore: 30 } as unknown as LevelConfig,
      levelNumber: 1,
      hasNextLevel: true,
      isEpic: false,
      currentScore: 0,
      isShowingClue: false,
    });

    expect(result.hasClue).toBe(false);
  });

  test('returns success result with calculated scores', () => {
    const result = buildLevelReport({
      levelResult: {
        passed: true,
        turns: [[makeEvent(5), makeEvent(10)], [makeEvent(15)]],
      },
      levelConfig: { timeBonus: 10, aceScore: 30 } as unknown as LevelConfig,
      levelNumber: 3,
      hasNextLevel: true,
      isEpic: false,
      currentScore: 100,
      isShowingClue: false,
    });

    expect(result.passed).toBe(true);
    expect(result.levelNumber).toBe(3);
    expect(result.previousScore).toBe(100);
    expect(result.hasClue).toBe(false);
    expect(result.isShowingClue).toBe(false);
    expect(result.scoreParts.warrior).toBe(15);
    expect(result.totalScore).toBe(
      result.scoreParts.warrior + result.scoreParts.timeBonus + result.scoreParts.clearBonus,
    );
  });

  test('calculates grade as totalScore / aceScore', () => {
    const result = buildLevelReport({
      levelResult: {
        passed: true,
        turns: [[makeEvent(20)]],
      },
      levelConfig: { timeBonus: 0, aceScore: 100 } as unknown as LevelConfig,
      levelNumber: 1,
      hasNextLevel: true,
      isEpic: true,
      currentScore: 0,
      isShowingClue: false,
    });

    expect(result.grade).toBe(result.totalScore / 100);
  });

  test('returns grade 0 when aceScore is missing', () => {
    const result = buildLevelReport({
      levelResult: {
        passed: true,
        turns: [[makeEvent(20)]],
      },
      levelConfig: { timeBonus: 0 } as unknown as LevelConfig,
      levelNumber: 1,
      hasNextLevel: true,
      isEpic: false,
      currentScore: 0,
      isShowingClue: false,
    });

    expect(result.grade).toBe(0);
  });

  test('defaults timeBonus to 0 when undefined', () => {
    const result = buildLevelReport({
      levelResult: {
        passed: true,
        turns: [[makeEvent(10)]],
      },
      levelConfig: { aceScore: 100 } as unknown as LevelConfig,
      levelNumber: 1,
      hasNextLevel: false,
      isEpic: false,
      currentScore: 0,
      isShowingClue: false,
    });

    expect(result.passed).toBe(true);
    expect(result.scoreParts.timeBonus).toBe(0);
  });
});
