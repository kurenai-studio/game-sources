import { type LevelContext, type LevelReplay, type LevelReport } from '../types.js';

export function makeLevelReplay(overrides: Partial<LevelReplay> = {}): LevelReplay {
  return {
    turns: [
      [
        {
          action: {
            type: 'walk',
            description: 'walks {direction}',
            params: { direction: 'forward', blocked: false },
          },
          actor: { name: 'Aldric', warrior: true },
          floorMap: [[{ unit: { name: 'Aldric', maxHealth: 20, warrior: true } }]],
          warriorStatus: { health: 20, score: 0 },
        },
      ],
    ],
    initialState: {
      action: { type: 'init', description: '', params: {} },
      actor: null,
      floorMap: [[{ unit: { name: 'Aldric', maxHealth: 20, warrior: true } }]],
      warriorStatus: { health: 20, score: 0 },
    },
    ...overrides,
  };
}

export function makeLevelContext(overrides: Partial<LevelContext> = {}): LevelContext {
  return {
    warriorName: 'Aldric',
    towerName: 'The Narrow Path',
    levelNumber: 1,
    totalScore: 10,
    maxHealth: 20,
    ...overrides,
  };
}

export function makeLevelReport(overrides: Partial<LevelReport> = {}): LevelReport {
  return {
    passed: true,
    levelNumber: 1,
    hasNextLevel: true,
    scoreParts: { warrior: 10, timeBonus: 5, clearBonus: 0 },
    totalScore: 15,
    grade: 0.75,
    isEpic: false,
    previousScore: 0,
    hasClue: false,
    isShowingClue: false,
    ...overrides,
  };
}
