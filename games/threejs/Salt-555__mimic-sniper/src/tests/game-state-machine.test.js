import { describe, expect, it } from 'vitest';
import { GameStateMachine, ROUND_STATES } from '../src/core/GameStateMachine.js';

describe('GameStateMachine', () => {
  it('runs countdown, starts play, and awards the mimic on timeout', () => {
    const machine = new GameStateMachine({ countdown: 1, roundDuration: 10 });

    machine.start();
    expect(machine.state).toBe(ROUND_STATES.COUNTDOWN);

    machine.update(1);
    expect(machine.state).toBe(ROUND_STATES.PLAYING);

    machine.update(10);
    expect(machine.state).toBe(ROUND_STATES.ROUND_END);
    expect(machine.winner).toBe('mimic');
  });

  it('awards the sniper when a live mimic is hit', () => {
    const machine = new GameStateMachine({ countdown: 0, roundDuration: 10 });
    machine.start();
    machine.update(0);

    expect(machine.mimicHit()).toBe(true);
    expect(machine.winner).toBe('sniper');
    expect(machine.state).toBe(ROUND_STATES.ROUND_END);
  });
});
