import { useInput } from 'ink';
import { useEffect, useMemo, useReducer, useRef } from 'react';

export interface PlaybackCursor {
  turn: number;
  event: number;
}

export interface PlaybackState {
  cursor: PlaybackCursor;
  totalTurns: number;
  turnEventCounts: number[];
  isPlaying: boolean;
  speed: number;
  mode: 'playback' | 'review';
}

export type PlaybackAction =
  | { type: 'TOGGLE_PLAY_PAUSE' }
  | { type: 'CYCLE_SPEED' }
  | { type: 'CYCLE_SPEED_BACK' }
  | { type: 'SKIP' }
  | { type: 'ADVANCE' }
  | { type: 'STEP_FORWARD' }
  | { type: 'STEP_BACK' }
  | { type: 'RESTART' };

const SPEEDS = [1, 2, 4];

function stepForward(cursor: PlaybackCursor, counts: number[]): PlaybackCursor | null {
  const maxEvent = counts[cursor.turn]! - 1;
  if (cursor.event < maxEvent) {
    return { turn: cursor.turn, event: cursor.event + 1 };
  }
  if (cursor.turn < counts.length - 1) {
    return { turn: cursor.turn + 1, event: 0 };
  }
  return null;
}

function stepBack(cursor: PlaybackCursor, counts: number[]): PlaybackCursor | null {
  if (cursor.event > 0) {
    return { turn: cursor.turn, event: cursor.event - 1 };
  }
  if (cursor.turn > 0) {
    const prevTurn = cursor.turn - 1;
    return { turn: prevTurn, event: counts[prevTurn]! - 1 };
  }
  return null;
}

function lastCursor(counts: number[]): PlaybackCursor {
  const lastTurn = counts.length - 1;
  return { turn: lastTurn, event: counts[lastTurn]! - 1 };
}

export function playbackReducer(state: PlaybackState, action: PlaybackAction): PlaybackState {
  switch (action.type) {
    case 'TOGGLE_PLAY_PAUSE': {
      if (state.mode !== 'playback') return state;
      return { ...state, isPlaying: !state.isPlaying };
    }
    case 'CYCLE_SPEED': {
      if (state.mode !== 'playback') return state;
      const currentIndex = SPEEDS.indexOf(state.speed);
      const nextSpeed = SPEEDS[(currentIndex + 1) % SPEEDS.length]!;
      return { ...state, speed: nextSpeed };
    }
    case 'CYCLE_SPEED_BACK': {
      if (state.mode !== 'playback') return state;
      const currentIndex = SPEEDS.indexOf(state.speed);
      const prevSpeed = SPEEDS[(currentIndex - 1 + SPEEDS.length) % SPEEDS.length]!;
      return { ...state, speed: prevSpeed };
    }
    case 'SKIP': {
      return {
        ...state,
        cursor: lastCursor(state.turnEventCounts),
        isPlaying: false,
        mode: 'review',
      };
    }
    case 'ADVANCE': {
      const next = stepForward(state.cursor, state.turnEventCounts);
      if (!next) {
        return { ...state, isPlaying: false, mode: 'review' };
      }
      return { ...state, cursor: next };
    }
    case 'STEP_FORWARD': {
      if (state.mode !== 'review') return state;
      const next = stepForward(state.cursor, state.turnEventCounts);
      if (!next) return state;
      return { ...state, cursor: next };
    }
    case 'STEP_BACK': {
      if (state.mode !== 'review') return state;
      const prev = stepBack(state.cursor, state.turnEventCounts);
      if (!prev) return state;
      return { ...state, cursor: prev };
    }
    case 'RESTART': {
      return {
        ...state,
        cursor: { turn: 0, event: 0 },
        isPlaying: true,
        mode: 'playback',
        speed: 1,
      };
    }
    default:
      return state;
  }
}

export function nextStepCrossesTurn(cursor: PlaybackCursor, turnEventCounts: number[]): boolean {
  const maxEvent = turnEventCounts[cursor.turn]! - 1;
  return cursor.event >= maxEvent;
}

const INTRA_TURN_DELAY = 500;
const INTER_TURN_DELAY = 600;

export function usePlayback(
  turns: unknown[][],
  onPlaybackComplete: () => void,
  startInReview = false,
): { state: PlaybackState; dispatch: React.Dispatch<PlaybackAction> } {
  const turnEventCounts = useMemo(() => turns.map((t) => t.length), [turns]);
  const totalTurns = turns.length;
  const last = lastCursor(turnEventCounts);

  const [state, dispatch] = useReducer(playbackReducer, {
    cursor: startInReview ? last : { turn: 0, event: 0 },
    totalTurns,
    turnEventCounts,
    isPlaying: !startInReview,
    speed: 1,
    mode: startInReview ? 'review' : 'playback',
  });

  const hasFiredComplete = useRef(startInReview);

  useEffect(() => {
    if (!state.isPlaying) return;
    const crossesTurn = nextStepCrossesTurn(state.cursor, state.turnEventCounts);
    const delay = (crossesTurn ? INTER_TURN_DELAY : INTRA_TURN_DELAY) / state.speed;
    const timer = setTimeout(() => dispatch({ type: 'ADVANCE' }), delay);
    return () => clearTimeout(timer);
  }, [state.isPlaying, state.speed, state.cursor, state.turnEventCounts]);

  useEffect(() => {
    if (state.mode === 'review' && !hasFiredComplete.current) {
      hasFiredComplete.current = true;
      onPlaybackComplete();
    }
  }, [state.mode, onPlaybackComplete]);

  useInput((input, key) => {
    if (state.mode === 'playback') {
      if (input === ' ') dispatch({ type: 'TOGGLE_PLAY_PAUSE' });
      if (key.tab && key.shift) dispatch({ type: 'CYCLE_SPEED_BACK' });
      else if (key.tab) dispatch({ type: 'CYCLE_SPEED' });
      if (input === 's') dispatch({ type: 'SKIP' });
    } else {
      if (key.escape) onPlaybackComplete();
      if (key.leftArrow) dispatch({ type: 'STEP_BACK' });
      if (key.rightArrow) dispatch({ type: 'STEP_FORWARD' });
    }
  });

  return { state, dispatch };
}
