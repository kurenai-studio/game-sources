import { vi, describe, it, expect, beforeEach } from 'vitest';
import { ALIEN_SPAWN_INTERVAL } from '../config/game';

/* ---------- Phaser mock ---------- */

vi.mock('phaser', () => ({
  default: {
    Math: { Between: (a: number, b: number) => (a + b) / 2 },
    Physics: {
      Arcade: {
        Group: class {
          constructor() {}
        },
      },
    },
  },
}));

/* ---------- Alien mock ---------- */

const { MockAlien } = vi.hoisted(() => {
  class MockAlien {
    x: number;
    y: number;
    active = true;
    update = vi.fn();
    fire = vi.fn();
    destroy = vi.fn();
    constructor(_scene: any, x: number, y: number) {
      this.x = x;
      this.y = y;
    }
  }
  return { MockAlien };
});

vi.mock('../entities/Alien', () => ({
  Alien: MockAlien,
}));

import { EnemyManager } from './EnemyManager';

function mockScene() {
  return {
    physics: {
      add: {
        group: vi.fn().mockReturnValue({}),
      },
    },
  };
}

describe('EnemyManager', () => {
  let scene: ReturnType<typeof mockScene>;
  let mgr: EnemyManager;

  beforeEach(() => {
    scene = mockScene();
    mgr = new EnemyManager(scene as any);
  });

  describe('create', () => {
    it('should create alienBullets group', () => {
      mgr.create();
      expect(scene.physics.add.group).toHaveBeenCalled();
      expect(mgr.alienBullets).toBeDefined();
    });
  });

  describe('update (spawning)', () => {
    it('should spawn an alien after ALIEN_SPAWN_INTERVAL ms', () => {
      mgr.create();
      // First update: not enough time yet
      mgr.update(0, ALIEN_SPAWN_INTERVAL - 1);
      expect(mgr.aliens.length).toBe(0);

      // Now trigger spawn
      mgr.update(0, 1);
      expect(mgr.aliens.length).toBe(1);
    });

    it('should reset spawn timer after spawning', () => {
      mgr.create();
      mgr.update(0, ALIEN_SPAWN_INTERVAL);
      expect(mgr.aliens.length).toBe(1);
      // Timer reset; next spawn needs another full interval
      mgr.update(0, ALIEN_SPAWN_INTERVAL - 1);
      expect(mgr.aliens.length).toBe(1);
    });
  });

  describe('update (alien lifecycle)', () => {
    it('should call update and fire on active aliens', () => {
      mgr.create();
      mgr.update(0, ALIEN_SPAWN_INTERVAL); // spawn one
      const alien = mgr.aliens[0];
      mgr.update(1000, 16);
      expect(alien.update).toHaveBeenCalled();
      expect(alien.fire).toHaveBeenCalled();
    });

    it('should remove inactive aliens from array', () => {
      mgr.create();
      mgr.update(0, ALIEN_SPAWN_INTERVAL);
      mgr.aliens[0].active = false;
      mgr.update(1000, 16);
      expect(mgr.aliens.length).toBe(0);
    });
  });

  describe('removeAlien', () => {
    it('should remove a specific alien from the array', () => {
      mgr.create();
      mgr.update(0, ALIEN_SPAWN_INTERVAL);
      const alien = mgr.aliens[0];
      mgr.removeAlien(alien);
      expect(mgr.aliens.length).toBe(0);
    });
  });
});
