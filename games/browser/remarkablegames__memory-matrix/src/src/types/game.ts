export type Mode = 'classic' | 'timed';

export type Phase = 'menu' | 'showing' | 'input' | 'feedback' | 'gameover';

export type Result = 'correct' | 'wrong';

export type GameOverReason = 'mistake' | 'timeout';

export interface GameState {
  phase: Phase;
  mode: Mode;
  round: number;
  score: number;
  gridSize: number;
  pattern: number[];
  selection: number[];
  result: Result | null;
  timeLeft: number | null;
  reason: GameOverReason | null;
}

export type Action =
  | { type: 'START'; mode: Mode; gridSize: number; pattern: number[] }
  | { type: 'REVEAL_DONE' }
  | { type: 'TOGGLE'; index: number }
  | { type: 'CHECK' }
  | { type: 'ADVANCE'; gridSize: number; pattern: number[] }
  | { type: 'RETRY'; gridSize: number; pattern: number[] }
  | { type: 'GAME_OVER' }
  | { type: 'TICK' }
  | { type: 'MENU' };

export interface Settings {
  best: Record<Mode, number>;
  volume: number;
}
