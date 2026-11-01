import { useEffect, useReducer } from 'react';
import type { Action, GameState, Mode } from 'src/types/game';
import {
  FEEDBACK_CORRECT_MS,
  FEEDBACK_WRONG_MS,
  getGridSize,
  getPatternSize,
  getRevealDuration,
  getTimeBonus,
  LOCK_IN_MS,
  MIN_GRID,
  START_TIME_MS,
  TICK_MS,
  WARNING_MS,
} from 'src/utils/difficulty';
import { createPattern } from 'src/utils/pattern';
import {
  deselect,
  error,
  notification,
  select,
  success,
  warning,
} from 'websfx';

import { useTimer } from './useTimer';

export const INITIAL_STATE: GameState = {
  phase: 'menu',
  mode: 'classic',
  round: 1,
  score: 0,
  gridSize: MIN_GRID,
  pattern: [],
  selection: [],
  result: null,
  timeLeft: null,
  reason: null,
};

/**
 * Pure game state machine.
 *
 * @param state - Current game state.
 * @param action - Transition to apply.
 * @returns The next game state.
 */
export function gameReducer(state: GameState, action: Action): GameState {
  switch (action.type) {
    case 'START':
      return {
        ...state,
        phase: 'showing',
        mode: action.mode,
        round: 1,
        score: 0,
        gridSize: action.gridSize,
        pattern: action.pattern,
        selection: [],
        result: null,
        timeLeft: action.mode === 'timed' ? START_TIME_MS : null,
        reason: null,
      };
    case 'REVEAL_DONE':
      if (state.phase !== 'showing') {
        return state;
      }
      return { ...state, phase: 'input', selection: [] };
    case 'TOGGLE': {
      if (state.phase !== 'input') {
        return state;
      }
      const picked = state.selection.includes(action.index);
      return {
        ...state,
        selection: picked
          ? state.selection.filter((index) => index !== action.index)
          : [...state.selection, action.index],
      };
    }
    case 'CHECK': {
      if (state.phase !== 'input') {
        return state;
      }
      const correct =
        state.selection.length === state.pattern.length &&
        state.selection.every((index) => state.pattern.includes(index));
      return {
        ...state,
        phase: 'feedback',
        result: correct ? 'correct' : 'wrong',
      };
    }
    case 'ADVANCE': {
      if (state.phase !== 'feedback') {
        return state;
      }
      const bonus = state.mode === 'timed' ? getTimeBonus(state.round) : 0;
      return {
        ...state,
        phase: 'showing',
        round: state.round + 1,
        score: state.round,
        gridSize: action.gridSize,
        pattern: action.pattern,
        selection: [],
        result: null,
        timeLeft: state.timeLeft === null ? null : state.timeLeft + bonus,
        reason: null,
      };
    }
    case 'RETRY': {
      if (state.phase !== 'feedback') {
        return state;
      }
      return {
        ...state,
        phase: 'showing',
        gridSize: action.gridSize,
        pattern: action.pattern,
        selection: [],
        result: null,
        reason: null,
      };
    }
    case 'GAME_OVER':
      if (state.phase !== 'feedback') {
        return state;
      }
      return { ...state, phase: 'gameover', reason: 'mistake', result: null };
    case 'TICK': {
      if (state.timeLeft === null) {
        return state;
      }
      const timeLeft = Math.max(state.timeLeft - TICK_MS, 0);
      if (timeLeft === 0) {
        return {
          ...state,
          timeLeft: 0,
          phase: 'gameover',
          reason: 'timeout',
          result: null,
        };
      }
      return { ...state, timeLeft };
    }
    case 'MENU':
      return INITIAL_STATE;
  }
}

/**
 * Runs a Memory Matrix game: reveal, recall input, feedback, and both
 * Classic and Timed modes.
 *
 * @returns Game state plus the actions that drive it.
 */
export function useGame() {
  const [state, dispatch] = useReducer(gameReducer, INITIAL_STATE);

  const clockRunning =
    state.mode === 'timed' &&
    state.phase !== 'menu' &&
    state.phase !== 'gameover';
  useTimer(clockRunning, dispatch);

  // Hide the pattern when the reveal window ends.
  useEffect(() => {
    if (state.phase !== 'showing') {
      return;
    }
    const id = setTimeout(() => {
      dispatch({ type: 'REVEAL_DONE' });
    }, getRevealDuration(state.pattern.length));
    return () => {
      clearTimeout(id);
    };
  }, [state.phase, state.pattern]);

  // Auto-check once the selection matches the target count.
  useEffect(() => {
    if (state.phase !== 'input') {
      return;
    }
    if (state.selection.length !== state.pattern.length) {
      return;
    }
    const id = setTimeout(() => {
      dispatch({ type: 'CHECK' });
    }, LOCK_IN_MS);
    return () => {
      clearTimeout(id);
    };
  }, [state.phase, state.selection, state.pattern]);

  // Route feedback into the next round, a retry, or game over.
  useEffect(() => {
    if (state.phase !== 'feedback' || state.result === null) {
      return;
    }

    if (state.result === 'correct') {
      const nextRound = state.round + 1;
      const gridSize = getGridSize(nextRound);
      const pattern = createPattern(gridSize ** 2, getPatternSize(nextRound));
      const id = setTimeout(() => {
        dispatch({ type: 'ADVANCE', gridSize, pattern });
      }, FEEDBACK_CORRECT_MS);
      return () => {
        clearTimeout(id);
      };
    }

    if (state.mode === 'classic') {
      const id = setTimeout(() => {
        dispatch({ type: 'GAME_OVER' });
      }, FEEDBACK_WRONG_MS);
      return () => {
        clearTimeout(id);
      };
    }

    const gridSize = state.gridSize;
    const pattern = createPattern(gridSize ** 2, getPatternSize(state.round));
    const id = setTimeout(() => {
      dispatch({ type: 'RETRY', gridSize, pattern });
    }, FEEDBACK_WRONG_MS);
    return () => {
      clearTimeout(id);
    };
  }, [state.phase, state.result, state.mode, state.round, state.gridSize]);

  // Sound cues for each phase transition.
  useEffect(() => {
    if (state.phase === 'showing') {
      notification();
    }
  }, [state.phase]);

  useEffect(() => {
    if (state.phase === 'feedback') {
      if (state.result === 'correct') {
        success();
      } else {
        error();
      }
    }
  }, [state.phase, state.result]);

  useEffect(() => {
    if (state.phase === 'gameover' && state.reason === 'timeout') {
      error();
    }
  }, [state.phase, state.reason]);

  // Single warning when the clock crosses the ten-second mark.
  useEffect(() => {
    if (state.timeLeft === null) {
      return;
    }
    if (state.timeLeft <= WARNING_MS && state.timeLeft > WARNING_MS - TICK_MS) {
      warning();
    }
  }, [state.timeLeft]);

  function start(mode: Mode): void {
    const gridSize = getGridSize(1);
    const pattern = createPattern(gridSize ** 2, getPatternSize(1));
    dispatch({ type: 'START', mode, gridSize, pattern });
  }

  function toggle(index: number): void {
    if (state.selection.includes(index)) {
      deselect();
    } else {
      select();
    }
    dispatch({ type: 'TOGGLE', index });
  }

  function again(): void {
    start(state.mode);
  }

  function toMenu(): void {
    dispatch({ type: 'MENU' });
  }

  return { state, start, toggle, again, toMenu };
}
