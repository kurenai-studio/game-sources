import { vi, describe, it, expect, beforeEach } from 'vitest';
import {
  ALIEN_HP,
  ALIEN_DAMAGE,
  ALIEN_FIRE_RATE,
  ALIEN_SPEED,
  ALIEN_BULLET_SPEED,
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

import { Alien } from './Alien';

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
    setVelocityX: vi.fn().mockReturnThis(),
    setVelocityY: vi.fn().mockReturnThis(),
    body: { enable: false } as any,
    active: true,
  };
}

/* ---------- Tests ---------- */

describe('Alien', () => {
  let scene: ReturnType<typeof mockScene>;
  let alien: Alien;

  beforeEach(() => {
    scene = mockScene();
    alien = new Alien(scene as any, 700, 300);
  });

  /* ---- constructor ---- */

  describe('constructor', () => {
    it('should initialise hp from config', () => {
      expect(alien.hp).toBe(ALIEN_HP);
    });

    it('should initialise damage from config', () => {
      expect(alien.damage).toBe(ALIEN_DAMAGE);
    });

    it('should register with the scene', () => {
      expect(scene.add.existing).toHaveBeenCalledWith(alien);
      expect(scene.physics.add.existing).toHaveBeenCalledWith(alien);
    });

    it('should move leftward at ALIEN_SPEED', () => {
      expect(alien.body!.velocity.x).toBe(-ALIEN_SPEED);
    });

    it('should have non-zero vertical drift', () => {
      expect(alien.body!.velocity.y).not.toBe(0);
    });
  });

  /* ---- takeDamage ---- */

  describe('takeDamage', () => {
    it('should reduce hp by the given amount', () => {
      alien.takeDamage(5);
      expect(alien.hp).toBe(ALIEN_HP - 5);
    });

    it('should return false while still alive', () => {
      expect(alien.takeDamage(1)).toBe(false);
    });

    it('should return true when hp reaches zero', () => {
      expect(alien.takeDamage(ALIEN_HP)).toBe(true);
    });

    it('should return true when hp goes below zero', () => {
      expect(alien.takeDamage(ALIEN_HP + 50)).toBe(true);
    });

    it('should flash red tint and schedule clearTint', () => {
      const tintSpy = vi.spyOn(alien, 'setTint' as any);
      alien.takeDamage(1);
      expect(tintSpy).toHaveBeenCalledWith(0xff0000);
      expect(scene.time.delayedCall).toHaveBeenCalled();
    });
  });

  /* ---- update ---- */

  describe('update', () => {
    it('should bounce off top edge (y < 30)', () => {
      alien.y = 20;
      alien.body!.velocity.y = -40;
      alien.update(0, 16);
      expect(alien.body!.velocity.y).toBe(40);
    });

    it('should bounce off bottom edge (y > GAME_HEIGHT - 30)', () => {
      alien.y = GAME_HEIGHT - 10;
      alien.body!.velocity.y = 40;
      alien.update(0, 16);
      expect(alien.body!.velocity.y).toBe(-40);
    });

    it('should not bounce when within bounds', () => {
      alien.y = 300;
      alien.body!.velocity.y = 40;
      alien.update(0, 16);
      expect(alien.body!.velocity.y).toBe(40);
    });

    it('should destroy when past left edge (x < -50)', () => {
      alien.x = -60;
      const destroySpy = vi.spyOn(alien, 'destroy');
      alien.update(0, 16);
      expect(destroySpy).toHaveBeenCalled();
    });

    it('should not destroy when still on screen', () => {
      alien.x = 200;
      const destroySpy = vi.spyOn(alien, 'destroy');
      alien.update(0, 16);
      expect(destroySpy).not.toHaveBeenCalled();
    });
  });

  /* ---- fire ---- */

  describe('fire', () => {
    let bulletGroup: any;
    let bullet: ReturnType<typeof mockBullet>;

    beforeEach(() => {
      bullet = mockBullet();
      bulletGroup = { get: vi.fn(() => bullet) };
    });

    // lastFired starts at 0 and fireInterval > 0, so time must exceed fireInterval
    const interval = 1000 / ALIEN_FIRE_RATE;
    const t1 = interval + 1;

    it('should fire on the first call after fireInterval', () => {
      alien.fire(t1, bulletGroup);
      expect(bulletGroup.get).toHaveBeenCalledTimes(1);
    });

    it('should not fire again before fireInterval elapses', () => {
      alien.fire(t1, bulletGroup);
      alien.fire(t1 + 100, bulletGroup);
      expect(bulletGroup.get).toHaveBeenCalledTimes(1);
    });

    it('should fire again after fireInterval elapses', () => {
      alien.fire(t1, bulletGroup);
      alien.fire(t1 + interval + 1, bulletGroup);
      expect(bulletGroup.get).toHaveBeenCalledTimes(2);
    });

    it('should shoot bullets leftward', () => {
      alien.fire(t1, bulletGroup);
      expect(bullet.setVelocityX).toHaveBeenCalledWith(-ALIEN_BULLET_SPEED);
      expect(bullet.setVelocityY).toHaveBeenCalledWith(0);
    });

    it('should activate the bullet and enable its body', () => {
      alien.fire(t1, bulletGroup);
      expect(bullet.setActive).toHaveBeenCalledWith(true);
      expect(bullet.setVisible).toHaveBeenCalledWith(true);
      expect(bullet.body.enable).toBe(true);
    });

    it('should schedule auto-cleanup', () => {
      alien.fire(t1, bulletGroup);
      expect(scene.time.delayedCall).toHaveBeenCalledWith(3000, expect.any(Function));
    });

    it('should handle null bullet from exhausted pool', () => {
      bulletGroup.get.mockReturnValue(null);
      expect(() => alien.fire(t1, bulletGroup)).not.toThrow();
    });
  });
});
