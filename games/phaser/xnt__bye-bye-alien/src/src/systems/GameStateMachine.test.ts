import { vi, describe, it, expect, beforeEach } from 'vitest';
import { GameStateMachine } from './GameStateMachine';

function makeCallbacks() {
  return {
    onWin: vi.fn(),
    onLose: vi.fn(),
  };
}

describe('GameStateMachine', () => {
  let sm: GameStateMachine;
  let cb: ReturnType<typeof makeCallbacks>;

  beforeEach(() => {
    cb = makeCallbacks();
    sm = new GameStateMachine(cb);
  });

  it('starts in PLAYING state', () => {
    expect(sm.state).toBe('PLAYING');
    expect(sm.isPlaying()).toBe(true);
    expect(sm.isGameOver()).toBe(false);
  });

  describe('onBossKilled', () => {
    it('transitions PLAYING → WON and calls onWin', () => {
      sm.onBossKilled();
      expect(sm.state).toBe('WON');
      expect(cb.onWin).toHaveBeenCalledTimes(1);
      expect(cb.onLose).not.toHaveBeenCalled();
    });

    it('is idempotent: second call does nothing', () => {
      sm.onBossKilled();
      sm.onBossKilled();
      expect(sm.state).toBe('WON');
      expect(cb.onWin).toHaveBeenCalledTimes(1); // not called again
    });

    it('does not transition from LOST', () => {
      sm.onPlayerDied(); // LOST
      sm.onBossKilled(); // should be ignored
      expect(sm.state).toBe('LOST');
      expect(cb.onWin).not.toHaveBeenCalled();
    });
  });

  describe('onPlayerDied', () => {
    it('transitions PLAYING → LOST and calls onLose', () => {
      sm.onPlayerDied();
      expect(sm.state).toBe('LOST');
      expect(cb.onLose).toHaveBeenCalledTimes(1);
      expect(cb.onWin).not.toHaveBeenCalled();
    });

    it('is idempotent: second call does nothing', () => {
      sm.onPlayerDied();
      sm.onPlayerDied();
      expect(sm.state).toBe('LOST');
      expect(cb.onLose).toHaveBeenCalledTimes(1);
    });

    it('does not transition from WON', () => {
      sm.onBossKilled(); // WON
      sm.onPlayerDied(); // should be ignored
      expect(sm.state).toBe('WON');
      expect(cb.onLose).not.toHaveBeenCalled();
    });
  });

  describe('query helpers', () => {
    it('isGameOver is true for WON or LOST', () => {
      expect(sm.isGameOver()).toBe(false);
      sm.onBossKilled();
      expect(sm.isGameOver()).toBe(true);
    });

    it('isWon / isLost match state', () => {
      sm.onBossKilled();
      expect(sm.isWon()).toBe(true);
      expect(sm.isLost()).toBe(false);

      // fresh instance for LOST case
      const sm2 = new GameStateMachine(makeCallbacks());
      sm2.onPlayerDied();
      expect(sm2.isWon()).toBe(false);
      expect(sm2.isLost()).toBe(true);
    });
  });
});
