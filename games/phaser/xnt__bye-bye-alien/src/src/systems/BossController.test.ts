import { vi, describe, it, expect, beforeEach } from 'vitest';
import { BOSS_SPAWN_TIME } from '../config/game';

/* ---------- Phaser mock ---------- */

vi.mock('phaser', () => ({
  default: {
    Math: { Between: () => 300 },
    Tweens: {
      TweenManager: class {},
    },
  },
}));

/* ---------- Boss mock ---------- */

const { MockBoss } = vi.hoisted(() => {
  class MockBoss {
    x: number;
    y: number;
    active = true;
    hp = 500;
    maxHp = 500;
    update = vi.fn();
    fire = vi.fn();
    destroy = vi.fn();
    constructor(_scene: any, x: number, y: number) {
      this.x = x;
      this.y = y;
    }
  }
  return { MockBoss };
});

vi.mock('../entities/Boss', () => ({
  Boss: MockBoss,
}));

import { BossController } from './BossController';

function mockScene() {
  return {
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
      text: vi.fn().mockReturnValue({
        setOrigin: vi.fn().mockReturnThis(),
        setDepth: vi.fn().mockReturnThis(),
        destroy: vi.fn(),
      }),
    },
    tweens: {
      add: vi.fn(),
    },
    physics: {
      add: {
        group: vi.fn().mockReturnValue({}),
      },
    },
  };
}

describe('BossController', () => {
  let scene: ReturnType<typeof mockScene>;
  let ctrl: BossController;

  beforeEach(() => {
    scene = mockScene();
    ctrl = new BossController(scene as any);
  });

  describe('create', () => {
    it('should create bossBullets group', () => {
      ctrl.create();
      expect(scene.physics.add.group).toHaveBeenCalled();
      expect(ctrl.bossBullets).toBeDefined();
    });
  });

  describe('update (spawn timing)', () => {
    it('should not spawn boss before BOSS_SPAWN_TIME', () => {
      ctrl.create();
      ctrl.update(0, 16, BOSS_SPAWN_TIME - 1000, { x: 100, y: 300 });
      expect(ctrl.boss).toBeNull();
      expect(ctrl.isActive()).toBe(false);
    });

    it('should transition to WARNING at 5s before spawn', () => {
      ctrl.create();
      ctrl.update(0, 16, BOSS_SPAWN_TIME - 5000, { x: 100, y: 300 });
      expect(ctrl.state).toBe('WARNING');
      expect(scene.add.text).toHaveBeenCalled();
    });

    it('should spawn boss at BOSS_SPAWN_TIME (SPAWNED state)', () => {
      ctrl.create();
      // First trigger WARNING
      ctrl.update(0, 16, BOSS_SPAWN_TIME - 5000, { x: 100, y: 300 });
      // Then spawn
      ctrl.update(0, 16, BOSS_SPAWN_TIME, { x: 100, y: 300 });
      expect(ctrl.boss).not.toBeNull();
      expect(ctrl.state).toBe('SPAWNED');
    });

    it('should show warning 5s before spawn', () => {
      ctrl.create();
      ctrl.update(0, 16, BOSS_SPAWN_TIME - 5000, { x: 100, y: 300 });
      expect(scene.add.text).toHaveBeenCalled();
      expect(scene.tweens.add).toHaveBeenCalled();
    });
  });

  describe('update (active boss)', () => {
    it('should call update and fire on active boss (after arrival)', () => {
      ctrl.create();
      // WARNING
      ctrl.update(0, 16, BOSS_SPAWN_TIME - 5000, { x: 100, y: 300 });
      // SPAWN
      ctrl.update(0, 16, BOSS_SPAWN_TIME, { x: 100, y: 300 });
      // Simulate boss.arrived = true
      if (ctrl.boss) (ctrl.boss as any).arrived = true;
      const boss = ctrl.boss!;
      // First update: transitions SPAWNED→ACTIVE (arrived check)
      ctrl.update(1000, 16, BOSS_SPAWN_TIME + 100, { x: 100, y: 300 });
      // Second update: now ACTIVE, calls update + fire
      ctrl.update(1000, 16, BOSS_SPAWN_TIME + 200, { x: 100, y: 300 });
      expect(boss.update).toHaveBeenCalled();
      expect(boss.fire).toHaveBeenCalled();
    });
  });

  describe('onBossKilled', () => {
    it('should null out boss and destroy HP bar', () => {
      ctrl.create();
      // WARNING
      ctrl.update(0, 16, BOSS_SPAWN_TIME - 5000, { x: 100, y: 300 });
      // SPAWN
      ctrl.update(0, 16, BOSS_SPAWN_TIME, { x: 100, y: 300 });
      const bar = (scene.add.graphics as any).mock.results[0].value;
      ctrl.onBossKilled();
      expect(ctrl.boss).toBeNull();
      expect(bar.destroy).toHaveBeenCalled();
    });
  });
});
