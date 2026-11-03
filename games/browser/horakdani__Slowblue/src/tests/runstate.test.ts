import { describe, expect, it } from 'vitest';
import {
  COHESION_LIMIT,
  GATE_POINTS,
  MIN_SHOAL,
  RESCUE_POINTS,
  REFORM_POINTS,
  RunState,
  STREAK_CAP,
  STREAK_STEP,
  STREAK_TOLERANCE,
  failureThreshold,
} from '../src/sim/RunState';

describe('failure threshold', () => {
  it('is relative to the starting shoal, with an absolute floor', () => {
    expect(failureThreshold(100)).toBe(40);
    expect(failureThreshold(10)).toBe(MIN_SHOAL);
  });
});

describe('the streak', () => {
  it('starts at no multiplier', () => {
    const r = new RunState();
    expect(r.streak).toBe(0);
    expect(r.multiplier).toBe(1);
  });

  it('grows on clean gates and stops at the cap', () => {
    const r = new RunState();
    for (let i = 0; i < 20; i++) expect(r.noteGate()).toBe(true);
    expect(r.streak).toBe(20);
    expect(r.bestStreak).toBe(20);
    expect(r.multiplier).toBe(1 + STREAK_CAP * STREAK_STEP);
  });

  it('survives losses inside the tolerance', () => {
    const r = new RunState();
    r.noteGate();
    for (let i = 0; i < STREAK_TOLERANCE; i++) expect(r.noteLoss()).toBe(false);
    expect(r.streak).toBe(1);
    expect(r.noteGate()).toBe(true);
    expect(r.streak).toBe(2);
  });

  it('breaks the moment the tolerance is exceeded', () => {
    const r = new RunState();
    r.noteGate();
    r.noteGate();
    expect(r.streak).toBe(2);
    for (let i = 0; i < STREAK_TOLERANCE; i++) r.noteLoss();
    expect(r.streak).toBe(2);
    expect(r.noteLoss()).toBe(true);
    expect(r.streak).toBe(0);
    expect(r.multiplier).toBe(1);
    // ...but the best is remembered for the results screen.
    expect(r.bestStreak).toBe(2);
  });

  it('does not report a break when there was no streak to break', () => {
    const r = new RunState();
    for (let i = 0; i < 20; i++) expect(r.noteLoss()).toBe(false);
    expect(r.lost).toBe(20);
  });

  it('refuses to advance through a gate the shoal was mauled reaching', () => {
    const r = new RunState();
    r.noteGate();
    r.streak = 3;
    r.damageSinceGate = STREAK_TOLERANCE + 1;
    expect(r.noteGate()).toBe(false);
    expect(r.streak).toBe(0);
    expect(r.damageSinceGate).toBe(0);
  });

  it('ignores stragglers culled off the back, which the player cannot always stop', () => {
    const r = new RunState();
    r.noteGate();
    for (let i = 0; i < 40; i++) expect(r.noteLoss(1, false)).toBe(false);
    expect(r.lost).toBe(40);
    expect(r.damageSinceGate).toBe(0);
    expect(r.noteGate()).toBe(true);
    expect(r.streak).toBe(2);
  });

  it('breaks on a shoal that came apart, even with nothing killed', () => {
    const r = new RunState();
    r.noteGate();
    r.noteSpread(COHESION_LIMIT + 1);
    expect(r.noteGate()).toBe(false);
    expect(r.streak).toBe(0);
    // ...and the window is per gate, so the next clean section starts again.
    r.noteSpread(COHESION_LIMIT - 1);
    expect(r.noteGate()).toBe(true);
  });

  it('keeps only the worst spread seen since the last gate', () => {
    const r = new RunState();
    r.noteSpread(40);
    r.noteSpread(90);
    r.noteSpread(50);
    expect(r.spreadSinceGate).toBe(90);
    r.noteGate();
    expect(r.spreadSinceGate).toBe(0);
  });

  it('clears the damage budget at every gate', () => {
    const r = new RunState();
    for (let i = 0; i < STREAK_TOLERANCE; i++) r.noteLoss();
    r.noteGate();
    expect(r.damageSinceGate).toBe(0);
    for (let i = 0; i < STREAK_TOLERANCE; i++) expect(r.noteLoss()).toBe(false);
  });
});

describe('scoring', () => {
  it('banks gate, rescue and re-form points at the multiplier in force', () => {
    const r = new RunState();
    r.noteGate(); // banked at x1.00 -> 170, and the streak becomes 1
    expect(r.earned).toBe(GATE_POINTS);
    const mult = 1 + STREAK_STEP;
    r.noteRescue(10);
    expect(r.earned).toBe(GATE_POINTS + Math.round(RESCUE_POINTS * 10 * mult));
    r.noteReform();
    expect(r.earned).toBe(
      GATE_POINTS + Math.round(RESCUE_POINTS * 10 * mult) + Math.round(REFORM_POINTS * mult),
    );
  });

  it('is the sum of distance, banked points and the shoal still with you', () => {
    const r = new RunState();
    r.distance = 5000;
    r.earned = 1000;
    r.recomputeScore(80);
    expect(r.score).toBe(500 + 1000 + 160);
  });

  it('is stable when recomputed repeatedly - no drift', () => {
    const r = new RunState();
    r.noteGate();
    r.noteRescue(12);
    r.distance = 1234;
    r.recomputeScore(90);
    const once = r.score;
    for (let i = 0; i < 50; i++) r.recomputeScore(90);
    expect(r.score).toBe(once);
  });

  it('makes a clean run beat a sloppier run that went just as far, and by more the longer it lasts', () => {
    const compare = (gates: number): number => {
      const clean = new RunState();
      const sloppy = new RunState();
      for (let i = 0; i < gates; i++) {
        clean.noteGate();
        sloppy.noteLoss(STREAK_TOLERANCE + 1);
        sloppy.noteGate();
      }
      return clean.earned / sloppy.earned;
    };
    expect(compare(6)).toBeGreaterThan(1.4);
    // The multiplier compounds, so the gap widens with the length of the run.
    expect(compare(12)).toBeGreaterThan(compare(6));
    expect(compare(12)).toBeGreaterThan(2);
  });

  it('resets everything a run owns', () => {
    const r = new RunState();
    r.noteGate();
    r.noteRescue(5);
    r.noteReform();
    r.noteLoss(9);
    r.zone = 3;
    r.fail('depleted');
    r.reset();
    expect(r.phase).toBe('running');
    expect(r.reason).toBeNull();
    expect(r.streak).toBe(0);
    expect(r.bestStreak).toBe(0);
    expect(r.earned).toBe(0);
    expect(r.zone).toBe(0);
    expect(r.damageSinceGate).toBe(0);
    expect(r.sinceStreakChange).toBe(Infinity);
  });

  it('keeps the first failure reason', () => {
    const r = new RunState();
    r.fail('sweptAway');
    r.fail('depleted');
    expect(r.reason).toBe('sweptAway');
  });
});
