import { vi, describe, it, expect, beforeEach } from 'vitest';
import {
  BOSS_HP,
  BOSS_DAMAGE,
  BOSS_FIRE_RATE,
  BOSS_SPEED,
  BOSS_BULLET_SPEED,
  GAME_HEIGHT,
} from '../config/game';

/* ---------- Phaser mock ---------- */

const { MockSprite } = vi.hoisted(() => {
  class MockSprite {
    scene: any;
    x: number;
    y: number;
    active = true;
    body: any = { velocity: { x: 0, y: 0 }, enable: true };

    constructor(scene: any, x: number, y: number, _texture: string) {
      this.scene = scene;
      this.x = x;
      this.y = y;
    }

    setVelocityX(vx: number) { this.body.velocity.x = vx; return this; }
    setVelocityY(vy: number) { this.body.velocity.y = vy; return this; }
    setVelocity(vx: number, vy: number) {
      this.body.velocity.x = vx;
      this.body.velocity.y = vy;
      return this;
    }
    setDepth() { return this; }
    setTint() { return this; }
    clearTint() { return this; }
    setActive(v: boolean) { this.active = v; return this; }
    setVisible() { return this; }
    setPosition(x: number, y: number) { this.x = x; this.y = y; return this; }
    destroy() { this.active = false; }
  }
  return { MockSprite };
});

vi.mock('phaser', () => ({
  default: { Physics: { Arcade: { Sprite: MockSprite, Body: class {} } } },
}));

import { Boss } from './Boss';

/* ---------- Helpers ---------- */

function mockScene() {
  return {
    add: { existing: vi.fn() },
    physics: { add: { existing: vi.fn() } },
    time: { delayedCall: vi.fn() },
  };
}

function mockBullet() {
  return {
    setActive: vi.fn().mockReturnThis(),
    setVisible: vi.fn().mockReturnThis(),
    setPosition: vi.fn().mockReturnThis(),
    setVelocity: vi.fn().mockReturnThis(),
    body: { enable: false } as any,
    active: true,
  };
}

/* ---------- Tests ---------- */

describe('Boss', () => {
  let scene: ReturnType<typeof mockScene>;
  let boss: Boss;

  beforeEach(() => {
    scene = mockScene();
    boss = new Boss(scene as any, 860, 300);
  });

  /* ---- constructor ---- */

  describe('constructor', () => {
    it('should initialise hp and maxHp from config', () => {
      expect(boss.hp).toBe(BOSS_HP);
      expect(boss.maxHp).toBe(BOSS_HP);
    });

    it('should initialise damage from config', () => {
      expect(boss.damage).toBe(BOSS_DAMAGE);
    });

    it('should register with the scene', () => {
      expect(scene.add.existing).toHaveBeenCalledWith(boss);
      expect(scene.physics.add.existing).toHaveBeenCalledWith(boss);
    });

    it('should slide in from the right', () => {
      expect(boss.body!.velocity.x).toBe(-BOSS_SPEED);
    });
  });

  /* ---- takeDamage ---- */

  describe('takeDamage', () => {
    it('should reduce hp by the given amount', () => {
      boss.takeDamage(10);
      expect(boss.hp).toBe(BOSS_HP - 10);
    });

    it('should return false while still alive', () => {
      expect(boss.takeDamage(1)).toBe(false);
    });

    it('should return true when hp reaches zero', () => {
      expect(boss.takeDamage(BOSS_HP)).toBe(true);
    });

    it('should return true when hp goes below zero', () => {
      expect(boss.takeDamage(BOSS_HP + 100)).toBe(true);
    });

    it('should flash red tint and schedule clearTint', () => {
      const tintSpy = vi.spyOn(boss, 'setTint' as any);
      boss.takeDamage(1);
      expect(tintSpy).toHaveBeenCalledWith(0xff0000);
      expect(scene.time.delayedCall).toHaveBeenCalled();
    });
  });

  /* ---- update ---- */

  describe('update', () => {
    it('should not arrive while x > targetX (680)', () => {
      boss.x = 700;
      boss.update(0, 16);
      // Still sliding in — velocity unchanged
      expect(boss.body!.velocity.x).toBe(-BOSS_SPEED);
    });

    it('should arrive when x <= targetX', () => {
      boss.x = 680;
      boss.update(0, 16);
      expect(boss.body!.velocity.x).toBe(0);
      expect(boss.body!.velocity.y).toBe(BOSS_SPEED); // moveDir starts at 1
    });

    it('should bounce off top edge when patrolling', () => {
      // Trigger arrival
      boss.x = 680;
      boss.update(0, 16);

      // Hit the top
      boss.y = 70;
      boss.update(100, 16);
      expect(boss.body!.velocity.y).toBe(BOSS_SPEED);
    });

    it('should bounce off bottom edge when patrolling', () => {
      boss.x = 680;
      boss.update(0, 16);

      boss.y = GAME_HEIGHT - 70;
      boss.update(100, 16);
      expect(boss.body!.velocity.y).toBe(-BOSS_SPEED);
    });
  });

  /* ---- fire ---- */

  describe('fire', () => {
    let bulletGroup: any;
    let bullets: ReturnType<typeof mockBullet>[];

    beforeEach(() => {
      bullets = [mockBullet(), mockBullet(), mockBullet()];
      let idx = 0;
      bulletGroup = { get: vi.fn(() => bullets[idx++]) };
    });

    // lastFired starts at 0 and fireInterval > 0, so time must exceed fireInterval
    const interval = 1000 / BOSS_FIRE_RATE;
    const t1 = interval + 1;

    const target = { x: 400, y: 300 };

    function triggerArrival(b: Boss) {
      b.x = 680;
      b.update(0, 16);
    }

    it('should not fire before arrival', () => {
      boss.x = 800; // still entering
      boss.fire(t1, bulletGroup, target as any);
      expect(bulletGroup.get).not.toHaveBeenCalled();
    });

    it('should fire 1 bullet after arrival at full HP', () => {
      triggerArrival(boss);
      boss.fire(t1, bulletGroup, target as any);
      expect(bulletGroup.get).toHaveBeenCalledTimes(1);
    });

    it('should fire 3 bullets after arrival when below 50% HP', () => {
      triggerArrival(boss);
      boss.hp = Math.floor(BOSS_HP * 0.5);
      boss.fire(t1, bulletGroup, target as any);
      expect(bulletGroup.get).toHaveBeenCalledTimes(3);
    });

    it('should not fire again before fireInterval', () => {
      triggerArrival(boss);
      boss.fire(t1, bulletGroup, target as any);
      boss.fire(t1 + 100, bulletGroup, target as any); // too soon
      expect(bulletGroup.get).toHaveBeenCalledTimes(1); // still only the first shot
    });

    it('should fire again after fireInterval', () => {
      triggerArrival(boss);
      boss.fire(t1, bulletGroup, target as any);
      // Reset bullet supplier
      let idx2 = 0;
      const moreBullets = [mockBullet(), mockBullet(), mockBullet()];
      bulletGroup.get.mockImplementation(() => moreBullets[idx2++]);
      boss.fire(t1 + interval + 1, bulletGroup, target as any);
      expect(bulletGroup.get).toHaveBeenCalledTimes(2); // 1 + 1 at full HP
    });

    it('should aim bullets toward the target', () => {
      triggerArrival(boss);
      boss.fire(t1, bulletGroup, target as any);
      expect(bullets[0].setVelocity).toHaveBeenCalledWith(
        expect.any(Number),
        expect.any(Number),
      );
    });

    it('should activate bullets and enable bodies', () => {
      triggerArrival(boss);
      boss.fire(t1, bulletGroup, target as any);

      // At full HP only the first bullet is used
      const b = bullets[0];
      expect(b.setActive).toHaveBeenCalledWith(true);
      expect(b.setVisible).toHaveBeenCalledWith(true);
      expect(b.body.enable).toBe(true);
    });

    it('should schedule auto-cleanup for each bullet', () => {
      triggerArrival(boss);
      boss.fire(t1, bulletGroup, target as any);
      // 1 bullet = 1 delayedCall invocation at full HP
      const delayCalls = scene.time.delayedCall.mock.calls.filter(
        (c: any[]) => c[0] === 4000,
      );
      expect(delayCalls).toHaveLength(1);
    });

    it('should schedule auto-cleanup for spread bullets', () => {
      triggerArrival(boss);
      boss.hp = Math.floor(BOSS_HP * 0.5);
      boss.fire(t1, bulletGroup, target as any);
      const delayCalls = scene.time.delayedCall.mock.calls.filter(
        (c: any[]) => c[0] === 4000,
      );
      expect(delayCalls).toHaveLength(3);
    });

    it('should handle null bullet from exhausted pool', () => {
      triggerArrival(boss);
      bulletGroup.get.mockReturnValue(null);
      expect(() => boss.fire(t1 + interval + 2, bulletGroup, target as any)).not.toThrow();
    });
  });
});
