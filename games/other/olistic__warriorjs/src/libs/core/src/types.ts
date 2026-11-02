import { type AbsoluteDirection } from '@warriorjs/spatial';

import { type AbilityEntry } from './Ability.js';
import { type EffectEntry } from './Effect.js';
import { type UnitClass } from './Unit.js';

export type Size = { width: number; height: number };

export type LocationConfig = { x: number; y: number };

export type PositionConfig = LocationConfig & { facing: AbsoluteDirection };

export interface UnitConfig {
  unit: UnitClass;
  position: PositionConfig;
  effects?: Record<string, EffectEntry>;
}

export interface WarriorConfig {
  name?: string;
  maxHealth: number;
  position: PositionConfig;
  abilities?: Record<string, AbilityEntry>;
}

export interface LevelConfig {
  number: number;
  description: string;
  tip: string;
  clue: string;
  timeBonus: number;
  aceScore: number;
  floor: {
    size: Size;
    stairs: LocationConfig;
    warrior: WarriorConfig & { name: string };
    units?: UnitConfig[];
  };
}

export interface WarriorDefinition {
  maxHealth: number;
}

export interface WarriorOverrides {
  position: PositionConfig;
  abilities?: Record<string, AbilityEntry>;
  maxHealth?: number;
}

export interface LevelDefinition {
  description: string;
  tip: string;
  clue?: string;
  timeBonus: number;
  aceScore: number;
  floor: {
    size: Size;
    stairs: LocationConfig;
    warrior: WarriorOverrides;
    units: UnitConfig[];
  };
}

export interface TowerDefinition {
  name: string;
  description: string;
  warrior: WarriorDefinition;
  levels: LevelDefinition[];
}
