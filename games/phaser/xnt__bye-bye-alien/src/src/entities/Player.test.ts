import { vi, describe, it, expect, beforeEach } from 'vitest';
import { SHIPS, POWERUP_STATS } from '../config/ships';

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
    setScale() { return this; }
    setAngle() { return this; }
    setCollideWorldBounds() { return this; }
    setTexture() { return this; }
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
  default: {
    Physics: { Arcade: { Sprite: MockSprite, Body: class {} } },
    Input: { Keyboard: { KeyCodes: { W: 87, A: 65, S: 83, D: 68 } } },
  },
}));

import { Player } from './Player';

/* ---------- Helpers ---------- */

function createCursorKeys() {
  return {
    left: { isDown: false },
    right: { isDown: false },
    up: { isDown: false },
    down: { isDown: false },
    space: { isDown: false },
  };
}

function createMockScene() {
  const cursors = createCursorKeys();
  const wasdW = { isDown: false };
  const wasdA = { isDown: false };
  const wasdS = { isDown: false };
  const wasdD = { isDown: false };
  const keyMap: Record<number, any> = { 87: wasdW, 65: wasdA, 83: wasdS, 68: wasdD };

  const mockBulletGroup = { get: vi.fn() };

  const scene = {
    add: { existing: vi.fn() },
    physics: { add: { existing: vi.fn(), group: vi.fn(() => mockBulletGroup) } },
    time: { delayedCall: vi.fn() },
    input: {
      keyboard: {
        createCursorKeys: vi.fn(() => cursors),
        addKey: vi.fn((code: number) => keyMap[code] ?? { isDown: false }),
      },
    },
  };

  return { scene, cursors, wasd: { W: wasdW, A: wasdA, S: wasdS, D: wasdD }, mockBulletGroup };
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

describe('Player', () => {
  const stats = SHIPS.f35;
  let helpers: ReturnType<typeof createMockScene>;
  let player: Player;

  beforeEach(() => {
    helpers = createMockScene();
    player = new Player(helpers.scene as any, 80, 300, stats);
  });

  /* ---- constructor ---- */

  describe('constructor', () => {
    it('should store stats', () => {
      expect(player.stats).toBe(stats);
    });

    it('should initialise currentHp from stats', () => {
      expect(player.currentHp).toBe(stats.hp);
    });

    it('should register with the scene', () => {
      expect(helpers.scene.add.existing).toHaveBeenCalledWith(player);
      expect(helpers.scene.physics.add.existing).toHaveBeenCalledWith(player);
    });

    it('should create a bullet pool group with the ship bullet texture', () => {
      expect(helpers.scene.physics.add.group).toHaveBeenCalledWith(
        expect.objectContaining({ defaultKey: stats.bulletTextureKey }),
      );
      expect(player.bullets).toBe(helpers.mockBulletGroup);
    });

    it('should set up keyboard input', () => {
      expect(helpers.scene.input.keyboard.createCursorKeys).toHaveBeenCalled();
      expect(helpers.scene.input.keyboard.addKey).toHaveBeenCalledTimes(4);
    });
  });

  /* ---- takeDamage ---- */

  describe('takeDamage', () => {
    it('should reduce currentHp', () => {
      player.takeDamage(25);
      expect(player.currentHp).toBe(stats.hp - 25);
    });

    it('should flash red tint and schedule clearTint', () => {
      const tintSpy = vi.spyOn(player, 'setTint' as any);
      player.takeDamage(10);
      expect(tintSpy).toHaveBeenCalledWith(0xff0000);
      expect(helpers.scene.time.delayedCall).toHaveBeenCalledWith(100, expect.any(Function));
    });
  });

  /* ---- isDead ---- */

  describe('isDead', () => {
    it('should return false when hp > 0', () => {
      expect(player.isDead()).toBe(false);
    });

    it('should return true when hp reaches 0', () => {
      player.takeDamage(stats.hp);
      expect(player.isDead()).toBe(true);
    });

    it('should return true when hp goes below 0', () => {
      player.takeDamage(stats.hp + 50);
      expect(player.isDead()).toBe(true);
    });
  });

  /* ---- update: movement ---- */

  describe('update — movement', () => {
    const speed = stats.speed * stats.handling;

    it('should move left when left cursor is pressed', () => {
      helpers.cursors.left.isDown = true;
      player.update(0, 16);
      expect(player.body!.velocity.x).toBe(-speed);
    });

    it('should move left when A key is pressed', () => {
      helpers.wasd.A.isDown = true;
      player.update(0, 16);
      expect(player.body!.velocity.x).toBe(-speed);
    });

    it('should move right when right cursor is pressed', () => {
      helpers.cursors.right.isDown = true;
      player.update(0, 16);
      expect(player.body!.velocity.x).toBe(speed);
    });

    it('should move right when D key is pressed', () => {
      helpers.wasd.D.isDown = true;
      player.update(0, 16);
      expect(player.body!.velocity.x).toBe(speed);
    });

    it('should stop horizontal movement when no key pressed', () => {
      player.update(0, 16);
      expect(player.body!.velocity.x).toBe(0);
    });

    it('should move up when up cursor is pressed', () => {
      helpers.cursors.up.isDown = true;
      player.update(0, 16);
      expect(player.body!.velocity.y).toBe(-speed);
    });

    it('should move up when W key is pressed', () => {
      helpers.wasd.W.isDown = true;
      player.update(0, 16);
      expect(player.body!.velocity.y).toBe(-speed);
    });

    it('should move down when down cursor is pressed', () => {
      helpers.cursors.down.isDown = true;
      player.update(0, 16);
      expect(player.body!.velocity.y).toBe(speed);
    });

    it('should move down when S key is pressed', () => {
      helpers.wasd.S.isDown = true;
      player.update(0, 16);
      expect(player.body!.velocity.y).toBe(speed);
    });

    it('should stop vertical movement when no key pressed', () => {
      player.update(0, 16);
      expect(player.body!.velocity.y).toBe(0);
    });
  });

  /* ---- update: firing ---- */

  describe('update — firing', () => {
    it('should fire when space is pressed and fireInterval has elapsed', () => {
      const bullet = mockBullet();
      helpers.mockBulletGroup.get.mockReturnValue(bullet);
      helpers.cursors.space.isDown = true;

      const fireInterval = 1000 / stats.fireRate;
      player.update(fireInterval + 1, 16);

      expect(helpers.mockBulletGroup.get).toHaveBeenCalled();
      expect(bullet.setVelocityX).toHaveBeenCalledWith(stats.bulletSpeed);
      expect(bullet.setVelocityY).toHaveBeenCalledWith(0);
    });

    it('should activate the bullet and enable its physics body', () => {
      const bullet = mockBullet();
      helpers.mockBulletGroup.get.mockReturnValue(bullet);
      helpers.cursors.space.isDown = true;

      player.update(1000, 16);

      expect(bullet.setActive).toHaveBeenCalledWith(true);
      expect(bullet.setVisible).toHaveBeenCalledWith(true);
      expect(bullet.body.enable).toBe(true);
    });

    it('should not fire when space is not pressed', () => {
      helpers.cursors.space.isDown = false;
      player.update(1000, 16);
      expect(helpers.mockBulletGroup.get).not.toHaveBeenCalled();
    });

    it('should not fire before fireInterval elapses', () => {
      const bullet1 = mockBullet();
      helpers.mockBulletGroup.get.mockReturnValue(bullet1);
      helpers.cursors.space.isDown = true;

      // First fire succeeds (sets lastFired = 1000)
      player.update(1000, 16);
      helpers.mockBulletGroup.get.mockClear();

      // Second fire too soon (1050 < 1000 + 200)
      player.update(1050, 16);
      expect(helpers.mockBulletGroup.get).not.toHaveBeenCalled();
    });

    it('should schedule auto-cleanup for the bullet', () => {
      const bullet = mockBullet();
      helpers.mockBulletGroup.get.mockReturnValue(bullet);
      helpers.cursors.space.isDown = true;

      player.update(1000, 16);
      expect(helpers.scene.time.delayedCall).toHaveBeenCalledWith(2000, expect.any(Function));
    });

    it('should handle null bullet from exhausted pool', () => {
      helpers.mockBulletGroup.get.mockReturnValue(null);
      helpers.cursors.space.isDown = true;
      expect(() => player.update(1000, 16)).not.toThrow();
    });
  });

  /* ---- power-up ---- */

  describe('activatePowerUp', () => {
    it('should set poweredUp to true', () => {
      player.activatePowerUp(POWERUP_STATS);
      expect(player.poweredUp).toBe(true);
    });

    it('should swap stats to power-up stats', () => {
      player.activatePowerUp(POWERUP_STATS);
      expect(player.stats).toBe(POWERUP_STATS);
    });

    it('should set HP to power-up HP', () => {
      player.takeDamage(50);
      player.activatePowerUp(POWERUP_STATS);
      expect(player.currentHp).toBe(POWERUP_STATS.hp);
    });

    it('should swap texture', () => {
      const texSpy = vi.spyOn(player, 'setTexture' as any);
      player.activatePowerUp(POWERUP_STATS);
      expect(texSpy).toHaveBeenCalledWith(POWERUP_STATS.textureKey);
    });

    it('should create a new bullet pool with power-up bullet texture', () => {
      player.activatePowerUp(POWERUP_STATS);
      expect(helpers.scene.physics.add.group).toHaveBeenCalledWith(
        expect.objectContaining({ defaultKey: POWERUP_STATS.bulletTextureKey }),
      );
    });
  });

  describe('deactivatePowerUp', () => {
    beforeEach(() => {
      player.activatePowerUp(POWERUP_STATS);
    });

    it('should set poweredUp to false', () => {
      player.deactivatePowerUp();
      expect(player.poweredUp).toBe(false);
    });

    it('should restore base stats', () => {
      player.deactivatePowerUp();
      expect(player.stats).toBe(stats);
    });

    it('should refresh HP to base max', () => {
      player.takeDamage(100);
      player.deactivatePowerUp();
      expect(player.currentHp).toBe(stats.hp);
    });

    it('should restore texture', () => {
      const texSpy = vi.spyOn(player, 'setTexture' as any);
      player.deactivatePowerUp();
      expect(texSpy).toHaveBeenCalledWith(stats.textureKey);
    });

    it('should restore original bullet pool', () => {
      player.deactivatePowerUp();
      expect(player.bullets).toBe(helpers.mockBulletGroup);
    });
  });
});
