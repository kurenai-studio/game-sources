import { describe, expect, test } from 'vitest';

import { nextStepCrossesTurn, type PlaybackState, playbackReducer } from './usePlayback.js';

describe('playbackReducer', () => {
  // 10 turns: turn 0 has 1 event, turns 1-9 each have 2 events
  const turnEventCounts = [1, 2, 2, 2, 2, 2, 2, 2, 2, 2];
  const initial: PlaybackState = {
    cursor: { turn: 0, event: 0 },
    totalTurns: 10,
    turnEventCounts,
    isPlaying: true,
    speed: 1,
    mode: 'playback',
  };

  test('toggles pause/resume during playback', () => {
    const paused = playbackReducer(initial, { type: 'TOGGLE_PLAY_PAUSE' });
    expect(paused.isPlaying).toBe(false);
    const resumed = playbackReducer(paused, { type: 'TOGGLE_PLAY_PAUSE' });
    expect(resumed.isPlaying).toBe(true);
  });

  test('cycles speed forward: 1 -> 2 -> 4 -> 1', () => {
    const s2 = playbackReducer(initial, { type: 'CYCLE_SPEED' });
    expect(s2.speed).toBe(2);
    const s4 = playbackReducer(s2, { type: 'CYCLE_SPEED' });
    expect(s4.speed).toBe(4);
    const s1 = playbackReducer(s4, { type: 'CYCLE_SPEED' });
    expect(s1.speed).toBe(1);
  });

  test('cycles speed backward: 1 -> 4 -> 2 -> 1', () => {
    const s4 = playbackReducer(initial, { type: 'CYCLE_SPEED_BACK' });
    expect(s4.speed).toBe(4);
    const s2 = playbackReducer(s4, { type: 'CYCLE_SPEED_BACK' });
    expect(s2.speed).toBe(2);
    const s1 = playbackReducer(s2, { type: 'CYCLE_SPEED_BACK' });
    expect(s1.speed).toBe(1);
  });

  test('skip goes to last event of last turn and enters review mode', () => {
    const skipped = playbackReducer(initial, { type: 'SKIP' });
    expect(skipped.cursor).toEqual({ turn: 9, event: 1 });
    expect(skipped.isPlaying).toBe(false);
    expect(skipped.mode).toBe('review');
  });

  test('advance steps to next event within same turn', () => {
    const atTurn1 = { ...initial, cursor: { turn: 1, event: 0 } };
    const next = playbackReducer(atTurn1, { type: 'ADVANCE' });
    expect(next.cursor).toEqual({ turn: 1, event: 1 });
  });

  test('advance overflows to next turn', () => {
    const atLastEvent = { ...initial, cursor: { turn: 1, event: 1 } };
    const next = playbackReducer(atLastEvent, { type: 'ADVANCE' });
    expect(next.cursor).toEqual({ turn: 2, event: 0 });
  });

  test('advance at last event of last turn transitions to review mode', () => {
    const atEnd = { ...initial, cursor: { turn: 9, event: 1 } };
    const result = playbackReducer(atEnd, { type: 'ADVANCE' });
    expect(result.mode).toBe('review');
    expect(result.isPlaying).toBe(false);
    expect(result.cursor).toEqual({ turn: 9, event: 1 });
  });

  test('step_forward in review mode advances one event', () => {
    const review: PlaybackState = {
      ...initial,
      mode: 'review',
      isPlaying: false,
      cursor: { turn: 5, event: 0 },
    };
    const next = playbackReducer(review, { type: 'STEP_FORWARD' });
    expect(next.cursor).toEqual({ turn: 5, event: 1 });
  });

  test('step_forward overflows to next turn in review mode', () => {
    const review: PlaybackState = {
      ...initial,
      mode: 'review',
      isPlaying: false,
      cursor: { turn: 5, event: 1 },
    };
    const next = playbackReducer(review, { type: 'STEP_FORWARD' });
    expect(next.cursor).toEqual({ turn: 6, event: 0 });
  });

  test('step_forward at last event of last turn is no-op', () => {
    const review: PlaybackState = {
      ...initial,
      mode: 'review',
      isPlaying: false,
      cursor: { turn: 9, event: 1 },
    };
    const next = playbackReducer(review, { type: 'STEP_FORWARD' });
    expect(next.cursor).toEqual({ turn: 9, event: 1 });
  });

  test('step_back decrements event within same turn', () => {
    const review: PlaybackState = {
      ...initial,
      mode: 'review',
      isPlaying: false,
      cursor: { turn: 5, event: 1 },
    };
    const prev = playbackReducer(review, { type: 'STEP_BACK' });
    expect(prev.cursor).toEqual({ turn: 5, event: 0 });
  });

  test('step_back underflows to previous turn last event', () => {
    const review: PlaybackState = {
      ...initial,
      mode: 'review',
      isPlaying: false,
      cursor: { turn: 5, event: 0 },
    };
    const prev = playbackReducer(review, { type: 'STEP_BACK' });
    expect(prev.cursor).toEqual({ turn: 4, event: 1 });
  });

  test('step_back at turn 0 event 0 is no-op', () => {
    const review: PlaybackState = {
      ...initial,
      mode: 'review',
      isPlaying: false,
      cursor: { turn: 0, event: 0 },
    };
    const prev = playbackReducer(review, { type: 'STEP_BACK' });
    expect(prev.cursor).toEqual({ turn: 0, event: 0 });
  });

  test('restart goes back to playback mode from turn 0 event 0', () => {
    const review: PlaybackState = {
      ...initial,
      mode: 'review',
      isPlaying: false,
      cursor: { turn: 9, event: 1 },
    };
    const restarted = playbackReducer(review, { type: 'RESTART' });
    expect(restarted.cursor).toEqual({ turn: 0, event: 0 });
    expect(restarted.isPlaying).toBe(true);
    expect(restarted.mode).toBe('playback');
    expect(restarted.speed).toBe(1);
  });

  test('toggle_play_pause is ignored in review mode', () => {
    const review: PlaybackState = { ...initial, mode: 'review', isPlaying: false };
    const result = playbackReducer(review, { type: 'TOGGLE_PLAY_PAUSE' });
    expect(result.isPlaying).toBe(false);
  });

  test('cycle_speed is ignored in review mode', () => {
    const review: PlaybackState = { ...initial, mode: 'review', isPlaying: false };
    const result = playbackReducer(review, { type: 'CYCLE_SPEED' });
    expect(result.speed).toBe(review.speed);
  });

  test('startInReview initializes at last event of last turn in review mode', () => {
    const startInReview: PlaybackState = {
      cursor: { turn: 9, event: 1 },
      totalTurns: 10,
      turnEventCounts,
      isPlaying: false,
      speed: 1,
      mode: 'review',
    };
    const stepped = playbackReducer(startInReview, { type: 'STEP_BACK' });
    expect(stepped.cursor).toEqual({ turn: 9, event: 0 });
    const restarted = playbackReducer(startInReview, { type: 'RESTART' });
    expect(restarted.cursor).toEqual({ turn: 0, event: 0 });
    expect(restarted.isPlaying).toBe(true);
    expect(restarted.mode).toBe('playback');
  });
});

describe('nextStepCrossesTurn', () => {
  const counts = [1, 2, 3];

  test('returns true when at last event of a turn', () => {
    expect(nextStepCrossesTurn({ turn: 0, event: 0 }, counts)).toBe(true);
    expect(nextStepCrossesTurn({ turn: 1, event: 1 }, counts)).toBe(true);
    expect(nextStepCrossesTurn({ turn: 2, event: 2 }, counts)).toBe(true);
  });

  test('returns false when not at last event of a turn', () => {
    expect(nextStepCrossesTurn({ turn: 1, event: 0 }, counts)).toBe(false);
    expect(nextStepCrossesTurn({ turn: 2, event: 0 }, counts)).toBe(false);
    expect(nextStepCrossesTurn({ turn: 2, event: 1 }, counts)).toBe(false);
  });
});
