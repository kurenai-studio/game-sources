import { vi, describe, it, expect, beforeEach } from 'vitest';
import { POWERUP_SPAWN_TIME, POWERUP_DURATION } from '../config/game';

/* ---------- Phaser mock ---------- */

vi.mock('phaser', () => ({
  default: {
    Math: { Between: () => 300 },
    Tweens: { TweenManager: class {} },
  },
}));

/* ---------- Player mock ---------- */

vi.mock('../entities/Player', () => ({
  Player: vi.fn().mockImplementation(() => ({
    activatePowerUp: vi.fn(),
    deactivatePowerUp: vi.fn(),
    bullets: { clear: vi.fn() },
  })),
}));

import { PowerUpController } from './PowerUpController';

function mockScene() {
  return {
    physics: {
      add: {
        sprite: vi.fn().mockReturnValue({
          setVelocityX: vi.fn().mockReturnThis(),
          setDepth: vi.fn().mockReturnThis(),
          active: true,
          x: 500,
          destroy: vi.fn(),
        }),
      },
    },
    tweens: {
      add: vi.fn(),
    },
    add: {
      graphics: vi.fn().mockReturnValue({
        clear: vi.fn(),
        fillStyle: vi.fn(),
        fillRect: vi.fn(),
        lineStyle: vi.fn(),
        strokeRect: vi.fn(),
        setDepth: vi.fn().mockReturnThis(),
        destroy: vi.fn(),
      }),
    },
  };
}

function mockPlayer() {
  return {
    activatePowerUp: vi.fn(),
    deactivatePowerUp: vi.fn(),
    bullets: {},
  };
}

describe('PowerUpController', () => {
  let scene: ReturnType<typeof mockScene>;
  let player: ReturnType<typeof mockPlayer>;
  let ctrl: PowerUpController;

  beforeEach(() => {
    scene = mockScene();
    player = mockPlayer();
    ctrl = new PowerUpController(scene as any, player as any);
  });

  describe('create', () => {
    it('should be a no-op (power-up spawns later)', () => {
      ctrl.create();
      // No error, nothing to assert
    });
  });

  describe('update (spawn timing)', () => {
    it('should not spawn power-up before POWERUP_SPAWN_TIME', () => {
      ctrl.create();
      ctrl.update(0, 16, POWERUP_SPAWN_TIME - 1000);
      expect(ctrl.powerUp).toBeNull();
      expect(ctrl.powerUpActive).toBe(false);
    });

    it('should spawn power-up at POWERUP_SPAWN_TIME', () => {
      ctrl.create();
      ctrl.update(0, 16, POWERUP_SPAWN_TIME);
      expect(ctrl.powerUp).not.toBeNull();
      expect(scene.physics.add.sprite).toHaveBeenCalled();
    });
  });

  describe('onCollected', () => {
    it('should set powerUpActive and call player.activatePowerUp', () => {
      ctrl.create();
      ctrl.update(0, 16, POWERUP_SPAWN_TIME); // spawn
      ctrl.onCollected();
      expect(ctrl.powerUpActive).toBe(true);
      expect(ctrl.powerUp).toBeNull(); // sprite destroyed
      expect(player.activatePowerUp).toHaveBeenCalled();
    });

    it('should create powerUpBar', () => {
      ctrl.create();
      ctrl.update(0, 16, POWERUP_SPAWN_TIME);
      ctrl.onCollected();
      expect(scene.add.graphics).toHaveBeenCalled();
    });
  });

  describe('update (timer countdown)', () => {
    it('should decrement powerUpRemaining', () => {
      ctrl.create();
      ctrl.update(0, 16, POWERUP_SPAWN_TIME);
      ctrl.onCollected();
      const before = ctrl.getRemainingRatio();
      ctrl.update(0, 100, POWERUP_SPAWN_TIME + 100);
      const after = ctrl.getRemainingRatio();
      expect(after).toBeLessThan(before);
    });

    it('should deactivate when timer expires', () => {
      ctrl.create();
      ctrl.update(0, 16, POWERUP_SPAWN_TIME);
      ctrl.onCollected();
      // Simulate full duration elapsed
      const result = ctrl.update(0, POWERUP_DURATION + 1, POWERUP_SPAWN_TIME + POWERUP_DURATION + 1);
      expect(result).toBe('deactivated');
      expect(ctrl.powerUpActive).toBe(false);
      expect(player.deactivatePowerUp).toHaveBeenCalled();
    });
  });

  describe('deactivate', () => {
    it('should reset state and destroy bar', () => {
      ctrl.create();
      ctrl.update(0, 16, POWERUP_SPAWN_TIME);
      ctrl.onCollected();
      const bar = (scene.add.graphics as any).mock.results[0].value;
      ctrl.deactivate();
      expect(ctrl.powerUpActive).toBe(false);
      expect(ctrl.getRemainingTime()).toBe(0);
      expect(bar.destroy).toHaveBeenCalled();
    });
  });
});
