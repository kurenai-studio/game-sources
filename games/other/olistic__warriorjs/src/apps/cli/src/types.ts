import { type LevelConfig, type TurnEvent } from '@warriorjs/core';

export type {
  FloorSpace,
  GameAction,
  LevelConfig,
  LevelResult,
  TurnEvent,
  UnitRef,
} from '@warriorjs/core';

import type Profile from './Profile.js';

export interface LevelReplay {
  turns: TurnEvent[][];
  initialState: TurnEvent;
}

export interface LevelContext {
  warriorName: string;
  towerName: string;
  levelNumber: number;
  totalScore: number;
  maxHealth: number;
}

export interface LevelReport {
  passed: boolean;
  levelNumber: number;
  hasNextLevel: boolean;
  scoreParts: { warrior: number; timeBonus: number; clearBonus: number };
  totalScore: number;
  grade: number;
  isEpic: boolean;
  previousScore: number;
  hasClue: boolean;
  isShowingClue: boolean;
}

export interface LevelOutcome {
  profile: Profile;
  levelConfig: LevelConfig;
  levelResult: { passed: boolean; turns: TurnEvent[][]; initialState: TurnEvent };
}

export interface CompletedLevel {
  replay: LevelReplay;
  context: LevelContext;
  report: LevelReport;
}

export type LevelCompleteChoice =
  | 'review'
  | 'stay'
  | 'next-level'
  | 'epic-mode'
  | 'clue'
  | 'try-again';

export type LevelCompleteAction =
  | { type: 'prompt' }
  | { type: 'stay' }
  | { type: 'next-level'; readmePath: string }
  | { type: 'epic-mode' }
  | { type: 'clue'; readmePath: string };

export type SessionPhase =
  | { phase: 'playing'; replay: LevelReplay; context: LevelContext; outcome: LevelOutcome }
  | { phase: 'reviewing'; replay: LevelReplay; context: LevelContext; returnTo: CompletedLevel }
  | { phase: 'levelComplete'; completedLevel: CompletedLevel; action: LevelCompleteAction }
  | { phase: 'towerComplete' }
  | { phase: 'error'; message: string };

export type PlaySessionState =
  | {
      type: 'playing';
      replay: LevelReplay;
      context: LevelContext;
      reviewMode?: boolean;
    }
  | {
      type: 'levelComplete';
      replay: LevelReplay;
      context: LevelContext;
      report: LevelReport;
      action: LevelCompleteAction;
    }
  | { type: 'towerComplete' }
  | { type: 'error'; message: string };

export type GameMenuStep =
  | { type: 'start' }
  | { type: 'wizard'; initialStep: 'new' | 'choose-profile' };
