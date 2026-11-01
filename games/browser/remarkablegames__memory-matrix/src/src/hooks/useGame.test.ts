import { act, renderHook } from '@testing-library/react';
import {
  FEEDBACK_CORRECT_MS,
  FEEDBACK_WRONG_MS,
  getRevealDuration,
  getTimeBonus,
  LOCK_IN_MS,
  START_TIME_MS,
  TICK_MS,
} from 'src/utils/difficulty';
import {
  deselect,
  error,
  notification,
  select,
  success,
  warning,
} from 'websfx';

import { gameReducer, INITIAL_STATE, useGame } from './useGame';

vi.mock('websfx');
vi.mock('src/utils/pattern', () => ({
  createPattern: vi.fn(() => [0, 1, 2]),
}));

const REVEAL = getRevealDuration(3);

function startRun(mode: 'classic' | 'timed') {
  const { result } = renderHook(() => useGame());
  act(() => {
    result.current.start(mode);
  });
  return result;
}

describe('gameReducer', () => {
  it('starts a showing round with score zero', () => {
    const state = gameReducer(INITIAL_STATE, {
      type: 'START',
      mode: 'classic',
      gridSize: 3,
      pattern: [0, 1, 2],
    });

    expect(state).toMatchObject({
      phase: 'showing',
      mode: 'classic',
      round: 1,
      score: 0,
      gridSize: 3,
      pattern: [0, 1, 2],
      selection: [],
      result: null,
      timeLeft: null,
      reason: null,
    });
  });

  it('arms the clock when starting timed mode', () => {
    const state = gameReducer(INITIAL_STATE, {
      type: 'START',
      mode: 'timed',
      gridSize: 3,
      pattern: [0, 1, 2],
    });

    expect(state.timeLeft).toBe(START_TIME_MS);
  });

  it('reveals into the input phase', () => {
    const showing = gameReducer(INITIAL_STATE, {
      type: 'START',
      mode: 'classic',
      gridSize: 3,
      pattern: [0, 1, 2],
    });

    expect(gameReducer(showing, { type: 'REVEAL_DONE' }).phase).toBe('input');
  });

  it('ignores reveal outside the showing phase', () => {
    expect(gameReducer(INITIAL_STATE, { type: 'REVEAL_DONE' })).toBe(
      INITIAL_STATE,
    );
  });

  it('toggles cells on and off during input', () => {
    const showing = gameReducer(INITIAL_STATE, {
      type: 'START',
      mode: 'classic',
      gridSize: 3,
      pattern: [0, 1, 2],
    });
    const input = gameReducer(showing, { type: 'REVEAL_DONE' });
    const picked = gameReducer(input, { type: 'TOGGLE', index: 4 });

    expect(picked.selection).toEqual([4]);

    const unpicked = gameReducer(picked, { type: 'TOGGLE', index: 4 });
    expect(unpicked.selection).toEqual([]);
  });

  it('ignores toggles outside input', () => {
    expect(gameReducer(INITIAL_STATE, { type: 'TOGGLE', index: 0 })).toBe(
      INITIAL_STATE,
    );
  });

  it('marks an exact selection correct', () => {
    const input = gameReducer(
      gameReducer(INITIAL_STATE, {
        type: 'START',
        mode: 'classic',
        gridSize: 3,
        pattern: [0, 1, 2],
      }),
      { type: 'REVEAL_DONE' },
    );
    const selected = { ...input, selection: [0, 1, 2] };

    const checked = gameReducer(selected, { type: 'CHECK' });

    expect(checked.phase).toBe('feedback');
    expect(checked.result).toBe('correct');
  });

  it('marks wrong cells as a failed pattern', () => {
    const input = gameReducer(
      gameReducer(INITIAL_STATE, {
        type: 'START',
        mode: 'classic',
        gridSize: 3,
        pattern: [0, 1, 2],
      }),
      { type: 'REVEAL_DONE' },
    );
    const selected = { ...input, selection: [0, 1, 3] };

    expect(gameReducer(selected, { type: 'CHECK' }).result).toBe('wrong');
  });

  it('marks a short selection as a failed pattern', () => {
    const input = gameReducer(
      gameReducer(INITIAL_STATE, {
        type: 'START',
        mode: 'classic',
        gridSize: 3,
        pattern: [0, 1, 2],
      }),
      { type: 'REVEAL_DONE' },
    );
    const selected = { ...input, selection: [0] };

    expect(gameReducer(selected, { type: 'CHECK' }).result).toBe('wrong');
  });

  it('ignores checks outside input', () => {
    expect(gameReducer(INITIAL_STATE, { type: 'CHECK' })).toBe(INITIAL_STATE);
  });

  it('scores the cleared round and moves on', () => {
    const feedback = {
      ...INITIAL_STATE,
      phase: 'feedback' as const,
      round: 1,
      score: 0,
      result: 'correct' as const,
    };

    const advanced = gameReducer(feedback, {
      type: 'ADVANCE',
      gridSize: 3,
      pattern: [3, 4, 5],
    });

    expect(advanced).toMatchObject({
      phase: 'showing',
      round: 2,
      score: 1,
      pattern: [3, 4, 5],
      selection: [],
      result: null,
    });
  });

  it('grants a time bonus when advancing in timed mode', () => {
    const feedback = {
      ...INITIAL_STATE,
      phase: 'feedback' as const,
      mode: 'timed' as const,
      round: 1,
      result: 'correct' as const,
      timeLeft: 20_000,
    };

    const advanced = gameReducer(feedback, {
      type: 'ADVANCE',
      gridSize: 3,
      pattern: [0, 1, 2],
    });

    expect(advanced.timeLeft).toBe(20_000 + getTimeBonus(1));
  });

  it('ignores advance outside feedback', () => {
    expect(
      gameReducer(INITIAL_STATE, {
        type: 'ADVANCE',
        gridSize: 3,
        pattern: [0, 1, 2],
      }),
    ).toBe(INITIAL_STATE);
  });

  it('retries the same round after a timed miss', () => {
    const feedback = {
      ...INITIAL_STATE,
      phase: 'feedback' as const,
      mode: 'timed' as const,
      round: 3,
      score: 2,
      result: 'wrong' as const,
      timeLeft: 30_000,
      selection: [1, 2],
    };

    const retried = gameReducer(feedback, {
      type: 'RETRY',
      gridSize: 4,
      pattern: [5, 6, 7],
    });

    expect(retried).toMatchObject({
      phase: 'showing',
      round: 3,
      score: 2,
      gridSize: 4,
      pattern: [5, 6, 7],
      selection: [],
      result: null,
      timeLeft: 30_000,
    });
  });

  it('ignores retry outside feedback', () => {
    expect(
      gameReducer(INITIAL_STATE, { type: 'RETRY', gridSize: 3, pattern: [] }),
    ).toBe(INITIAL_STATE);
  });

  it('ends the run on a classic mistake', () => {
    const feedback = {
      ...INITIAL_STATE,
      phase: 'feedback' as const,
      result: 'wrong' as const,
    };

    const over = gameReducer(feedback, { type: 'GAME_OVER' });

    expect(over.phase).toBe('gameover');
    expect(over.reason).toBe('mistake');
  });

  it('ignores game over outside feedback', () => {
    expect(gameReducer(INITIAL_STATE, { type: 'GAME_OVER' })).toBe(
      INITIAL_STATE,
    );
  });

  it('ticks the clock down', () => {
    const timed = {
      ...INITIAL_STATE,
      mode: 'timed' as const,
      timeLeft: 5_000,
    };

    expect(gameReducer(timed, { type: 'TICK' }).timeLeft).toBe(5_000 - TICK_MS);
  });

  it('ends the run when the clock hits zero', () => {
    const timed = { ...INITIAL_STATE, timeLeft: TICK_MS };

    const over = gameReducer(timed, { type: 'TICK' });

    expect(over.timeLeft).toBe(0);
    expect(over.phase).toBe('gameover');
    expect(over.reason).toBe('timeout');
  });

  it('ignores ticks without a clock', () => {
    expect(gameReducer(INITIAL_STATE, { type: 'TICK' })).toBe(INITIAL_STATE);
  });

  it('resets to the menu', () => {
    const playing = gameReducer(INITIAL_STATE, {
      type: 'START',
      mode: 'timed',
      gridSize: 3,
      pattern: [0, 1, 2],
    });

    expect(gameReducer(playing, { type: 'MENU' })).toBe(INITIAL_STATE);
  });
});

describe('useGame', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('boots to the menu', () => {
    const { result } = renderHook(() => useGame());

    expect(result.current.state.phase).toBe('menu');
  });

  it('starts a run and plays the reveal cue', () => {
    const result = startRun('classic');

    expect(result.current.state).toMatchObject({
      phase: 'showing',
      mode: 'classic',
      round: 1,
      gridSize: 3,
      pattern: [0, 1, 2],
    });
    expect(notification).toHaveBeenCalledOnce();
  });

  it('opens the input phase when the reveal window ends', () => {
    const result = startRun('classic');

    act(() => {
      vi.advanceTimersByTime(REVEAL);
    });

    expect(result.current.state.phase).toBe('input');
  });

  it('plays a cue for each pick and unpick', () => {
    const result = startRun('classic');
    act(() => {
      vi.advanceTimersByTime(REVEAL);
    });

    act(() => {
      result.current.toggle(0);
      result.current.toggle(1);
    });
    expect(select).toHaveBeenCalledTimes(2);
    expect(deselect).not.toHaveBeenCalled();

    act(() => {
      result.current.toggle(0);
    });
    expect(deselect).toHaveBeenCalledOnce();
    expect(result.current.state.selection).toEqual([1]);
  });

  it('auto-checks once the target count is reached', () => {
    const result = startRun('classic');
    act(() => {
      vi.advanceTimersByTime(REVEAL);
    });

    act(() => {
      result.current.toggle(0);
      result.current.toggle(1);
      result.current.toggle(2);
    });
    expect(result.current.state.phase).toBe('input');

    act(() => {
      vi.advanceTimersByTime(LOCK_IN_MS);
    });

    expect(result.current.state.phase).toBe('feedback');
    expect(result.current.state.result).toBe('correct');
    expect(success).toHaveBeenCalledOnce();
  });

  it('cancels the pending check when a cell is unpicked', () => {
    const result = startRun('classic');
    act(() => {
      vi.advanceTimersByTime(REVEAL);
    });

    act(() => {
      result.current.toggle(0);
      result.current.toggle(1);
      result.current.toggle(2);
    });
    act(() => {
      vi.advanceTimersByTime(LOCK_IN_MS - 100);
    });
    act(() => {
      result.current.toggle(2);
    });
    act(() => {
      vi.advanceTimersByTime(LOCK_IN_MS);
    });

    expect(result.current.state.phase).toBe('input');
    expect(result.current.state.selection).toEqual([0, 1]);
  });

  it('advances to the next round after a correct pattern', () => {
    const result = startRun('classic');
    act(() => {
      vi.advanceTimersByTime(REVEAL);
    });
    act(() => {
      result.current.toggle(0);
      result.current.toggle(1);
      result.current.toggle(2);
    });
    act(() => {
      vi.advanceTimersByTime(LOCK_IN_MS);
    });

    act(() => {
      vi.advanceTimersByTime(FEEDBACK_CORRECT_MS);
    });

    expect(result.current.state).toMatchObject({
      phase: 'showing',
      round: 2,
      score: 1,
    });
    expect(notification).toHaveBeenCalledTimes(2);
  });

  it('ends a classic run on a wrong pattern', () => {
    const result = startRun('classic');
    act(() => {
      vi.advanceTimersByTime(REVEAL);
    });

    act(() => {
      result.current.toggle(0);
      result.current.toggle(1);
      result.current.toggle(3);
    });
    act(() => {
      vi.advanceTimersByTime(LOCK_IN_MS);
    });
    expect(result.current.state.result).toBe('wrong');
    expect(error).toHaveBeenCalledOnce();

    act(() => {
      vi.advanceTimersByTime(FEEDBACK_WRONG_MS);
    });

    expect(result.current.state.phase).toBe('gameover');
    expect(result.current.state.reason).toBe('mistake');
    expect(result.current.state.score).toBe(0);
  });

  it('retries the same round after a miss in timed mode', () => {
    const result = startRun('timed');
    act(() => {
      vi.advanceTimersByTime(REVEAL);
    });

    act(() => {
      result.current.toggle(0);
      result.current.toggle(1);
      result.current.toggle(3);
    });
    act(() => {
      vi.advanceTimersByTime(LOCK_IN_MS);
    });

    act(() => {
      vi.advanceTimersByTime(FEEDBACK_WRONG_MS);
    });

    expect(result.current.state).toMatchObject({
      phase: 'showing',
      round: 1,
      score: 0,
      mode: 'timed',
    });
    expect(result.current.state.timeLeft).toBeLessThan(START_TIME_MS);
  });

  it('counts the clock down in timed mode', () => {
    const result = startRun('timed');

    act(() => {
      vi.advanceTimersByTime(TICK_MS * 3);
    });

    expect(result.current.state.timeLeft).toBe(START_TIME_MS - TICK_MS * 3);
  });

  it('adds a bonus when a timed round is cleared', () => {
    const result = startRun('timed');
    act(() => {
      vi.advanceTimersByTime(REVEAL);
    });
    act(() => {
      result.current.toggle(0);
      result.current.toggle(1);
      result.current.toggle(2);
    });
    act(() => {
      vi.advanceTimersByTime(LOCK_IN_MS);
    });

    const before = result.current.state.timeLeft;
    act(() => {
      vi.advanceTimersByTime(FEEDBACK_CORRECT_MS);
    });

    expect(result.current.state.timeLeft).toBe(
      (before ?? 0) - FEEDBACK_CORRECT_MS + getTimeBonus(1),
    );
  });

  it('ends the run when the clock expires', () => {
    const result = startRun('timed');

    act(() => {
      vi.advanceTimersByTime(START_TIME_MS);
    });

    expect(result.current.state.phase).toBe('gameover');
    expect(result.current.state.reason).toBe('timeout');
    expect(result.current.state.timeLeft).toBe(0);
    expect(error).toHaveBeenCalled();
  });

  it('warns when the clock drops under ten seconds', () => {
    startRun('timed');
    const untilWarning = START_TIME_MS - 10_000 - TICK_MS;

    act(() => {
      vi.advanceTimersByTime(untilWarning);
    });
    expect(warning).not.toHaveBeenCalled();

    act(() => {
      vi.advanceTimersByTime(TICK_MS);
    });
    expect(warning).toHaveBeenCalledOnce();

    act(() => {
      vi.advanceTimersByTime(TICK_MS * 5);
    });
    expect(warning).toHaveBeenCalledOnce();
  });

  it('does not run a clock in classic mode', () => {
    const result = startRun('classic');

    act(() => {
      vi.advanceTimersByTime(30_000);
    });

    expect(result.current.state.timeLeft).toBeNull();
    expect(result.current.state.phase).toBe('input');
  });

  it('returns to the menu', () => {
    const result = startRun('classic');

    act(() => {
      result.current.toMenu();
    });

    expect(result.current.state.phase).toBe('menu');
  });

  it('restarts from game over', () => {
    const result = startRun('classic');
    act(() => {
      vi.advanceTimersByTime(REVEAL);
    });
    act(() => {
      result.current.toggle(0);
      result.current.toggle(1);
      result.current.toggle(3);
    });
    act(() => {
      vi.advanceTimersByTime(LOCK_IN_MS);
    });
    act(() => {
      vi.advanceTimersByTime(FEEDBACK_WRONG_MS);
    });
    expect(result.current.state.phase).toBe('gameover');

    act(() => {
      result.current.again();
    });

    expect(result.current.state).toMatchObject({
      phase: 'showing',
      round: 1,
      score: 0,
    });
  });
});
