import { type TurnEvent } from './Logger.js';
import loadLevel from './loadLevel.js';
import { type LevelConfig } from './types.js';

export interface LevelResult {
  passed: boolean;
  turns: TurnEvent[][];
  initialState: TurnEvent | null;
}

function runLevel(
  levelConfig: LevelConfig,
  playerCode: string,
  language: 'javascript' | 'typescript' = 'javascript',
): LevelResult {
  return loadLevel(levelConfig, playerCode, language).play();
}

export default runLevel;
