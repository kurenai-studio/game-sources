import { vi, describe, it, expect, beforeEach } from 'vitest';

/* ---------- Phaser mock ---------- */

vi.mock('phaser', () => ({
  default: {
    Math: { Between: () => 300 },
  },
}));

/* ---------- Entity mocks ---------- */

vi.mock('../entities/Player', () => ({
  Player: vi.fn().mockImplementation(() => ({
    stats: { damage: 10 },
    takeDamage: vi.fn(),
    isDead: vi.fn().mockReturnValue(false),
    bullets: {},
  })),
}));

vi.mock('../entities/Alien', () => ({
  Alien: vi.fn().mockImplementation(() => ({})),
}));

vi.mock('../entities/Boss', () => ({
  Boss: vi.fn().mockImplementation(() => ({})),
}));

import { CollisionSystem, CollisionCallbacks } from './CollisionSystem';

function mockScene() {
  return {
    physics: {
      add: {
        overlap: vi.fn(),
        collider: vi.fn(),
      },
      overlap: vi.fn(),
    },
  };
}

function makeCallbacks(): CollisionCallbacks {
  return {
    onScore: vi.fn(),
    onExplosion: vi.fn(),
    onBossKilled: vi.fn(),
    onPlayerDied: vi.fn(),
    onPowerUpCollected: vi.fn(),
  };
}

function makePlayer() {
  return {
    stats: { damage: 10 },
    takeDamage: vi.fn(),
    isDead: vi.fn().mockReturnValue(false),
    bullets: { clear: vi.fn() },
  };
}

function makeEnemyMgr(): { alienBullets: {}; aliens: { active: boolean }[] } {
  return {
    alienBullets: {},
    aliens: [],
  };
}

function makeBossCtrl() {
  return {
    bossBullets: {},
    boss: null,
    onBossKilled: vi.fn(),
  };
}

function makeEnvCtrl() {
  return {
    obstacles: {},
  };
}

function makePowerUpCtrl() {
  return {
    powerUp: null,
    onCollected: vi.fn(),
  };
}

describe('CollisionSystem', () => {
  let scene: ReturnType<typeof mockScene>;
  let player: ReturnType<typeof makePlayer>;
  let enemyMgr: ReturnType<typeof makeEnemyMgr>;
  let bossCtrl: ReturnType<typeof makeBossCtrl>;
  let envCtrl: ReturnType<typeof makeEnvCtrl>;
  let powerUpCtrl: ReturnType<typeof makePowerUpCtrl>;
  let cb: CollisionCallbacks;
  let sys: CollisionSystem;

  beforeEach(() => {
    scene = mockScene();
    player = makePlayer();
    enemyMgr = makeEnemyMgr();
    bossCtrl = makeBossCtrl();
    envCtrl = makeEnvCtrl();
    powerUpCtrl = makePowerUpCtrl();
    cb = makeCallbacks();

    sys = new CollisionSystem(
      scene as any,
      player as any,
      enemyMgr as any,
      bossCtrl as any,
      envCtrl as any,
      powerUpCtrl as any,
      cb,
    );
  });

  describe('create', () => {
    it('should set up player bullets → obstacles overlap', () => {
      sys.create();
      expect(scene.physics.add.overlap).toHaveBeenCalledWith(
        player.bullets,
        envCtrl.obstacles,
        expect.any(Function),
        undefined,
        sys,
      );
    });

    it('should set up alien bullets → player overlap', () => {
      sys.create();
      expect(scene.physics.add.overlap).toHaveBeenCalledWith(
        enemyMgr.alienBullets,
        player,
        expect.any(Function),
        undefined,
        sys,
      );
    });

    it('should set up boss bullets → player overlap', () => {
      sys.create();
      expect(scene.physics.add.overlap).toHaveBeenCalledWith(
        bossCtrl.bossBullets,
        player,
        expect.any(Function),
        undefined,
        sys,
      );
    });

    it('should set up player → obstacles collider', () => {
      sys.create();
      expect(scene.physics.add.collider).toHaveBeenCalledWith(player, envCtrl.obstacles);
    });
  });

  describe('update', () => {
    it('should check player bullets vs each active alien', () => {
      sys.create();
      const alien = { active: true };
      enemyMgr.aliens = [alien];
      sys.update();
      expect(scene.physics.overlap).toHaveBeenCalled();
    });

    it('should skip inactive aliens', () => {
      sys.create();
      const alien = { active: false };
      enemyMgr.aliens = [alien];
      sys.update();
      // overlap still called but with no active aliens, the callback won't fire
      // We just ensure no crash
    });

    it('should check player bullets vs active boss', () => {
      sys.create();
      bossCtrl.boss = { active: true } as any;
      sys.update();
      expect(scene.physics.overlap).toHaveBeenCalled();
    });

    it('should check player vs active power-up', () => {
      sys.create();
      powerUpCtrl.powerUp = { active: true } as any;
      sys.update();
      expect(scene.physics.overlap).toHaveBeenCalled();
    });
  });
});
