import Phaser from 'phaser';
import { Player } from '../entities/Player';
import { Alien } from '../entities/Alien';
import { Boss } from '../entities/Boss';
import { EnemyManager } from './EnemyManager';
import { BossController } from './BossController';
import { EnvironmentController } from './EnvironmentController';
import { PowerUpController } from './PowerUpController';

export interface CollisionCallbacks {
  onScore: (points: number) => void;
  onExplosion: (x: number, y: number) => void;
  onBossKilled: () => void;
  onPlayerDied: () => void;
  onPowerUpCollected: () => void;
}

export class CollisionSystem {
  private scene: Phaser.Scene;
  private player: Player;
  private enemyMgr: EnemyManager;
  private bossCtrl: BossController;
  private envCtrl: EnvironmentController;
  private powerUpCtrl: PowerUpController;
  private cb: CollisionCallbacks;

  constructor(
    scene: Phaser.Scene,
    player: Player,
    enemyMgr: EnemyManager,
    bossCtrl: BossController,
    envCtrl: EnvironmentController,
    powerUpCtrl: PowerUpController,
    callbacks: CollisionCallbacks,
  ) {
    this.scene = scene;
    this.player = player;
    this.enemyMgr = enemyMgr;
    this.bossCtrl = bossCtrl;
    this.envCtrl = envCtrl;
    this.powerUpCtrl = powerUpCtrl;
    this.cb = callbacks;
  }

  create(): void {
    const physics = this.scene.physics;

    // Player bullets → obstacles (bullets destroyed)
    physics.add.overlap(
      this.player.bullets,
      this.envCtrl.obstacles,
      this.onBulletHitObstacle as Phaser.Types.Physics.Arcade.ArcadePhysicsCallback,
      undefined,
      this,
    );

    // Alien bullets → player
    physics.add.overlap(
      this.enemyMgr.alienBullets,
      this.player,
      this.onPlayerHitByBullet as Phaser.Types.Physics.Arcade.ArcadePhysicsCallback,
      undefined,
      this,
    );

    // Boss bullets → player
    physics.add.overlap(
      this.bossCtrl.bossBullets,
      this.player,
      this.onPlayerHitByBullet as Phaser.Types.Physics.Arcade.ArcadePhysicsCallback,
      undefined,
      this,
    );

    // Player → obstacles
    physics.add.collider(this.player, this.envCtrl.obstacles);
  }

  /** Call each frame for dynamic overlaps (aliens, boss, power-up). */
  update(): void {
    // Player bullets → aliens (manual since aliens aren't in a group)
    for (const alien of this.enemyMgr.aliens) {
      if (!alien.active) continue;
      this.scene.physics.overlap(
        this.player.bullets,
        alien,
        this.onBulletHitAlien as Phaser.Types.Physics.Arcade.ArcadePhysicsCallback,
        undefined,
        this,
      );
    }

    // Player bullets → boss
    if (this.bossCtrl.boss && this.bossCtrl.boss.active) {
      this.scene.physics.overlap(
        this.player.bullets,
        this.bossCtrl.boss,
        this.onBulletHitBoss as Phaser.Types.Physics.Arcade.ArcadePhysicsCallback,
        undefined,
        this,
      );
    }

    // Player → power-up
    if (this.powerUpCtrl.powerUp && this.powerUpCtrl.powerUp.active) {
      this.scene.physics.overlap(
        this.player,
        this.powerUpCtrl.powerUp,
        this.onPlayerCollectPowerUp as Phaser.Types.Physics.Arcade.ArcadePhysicsCallback,
        undefined,
        this,
      );
    }

    // Power-up bullets → obstacles (if power-up active, bullets are player.bullets)
    // Already covered by player.bullets → obstacles above; no extra needed
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Collision callbacks
  // ─────────────────────────────────────────────────────────────────────────────

  private onBulletHitAlien(
    objA: Phaser.Types.Physics.Arcade.GameObjectWithBody,
    objB: Phaser.Types.Physics.Arcade.GameObjectWithBody,
  ): void {
    let bullet: Phaser.Physics.Arcade.Sprite;
    let alien: Alien;
    if (objA instanceof Alien) {
      alien = objA;
      bullet = objB as Phaser.Physics.Arcade.Sprite;
    } else {
      alien = objB as unknown as Alien;
      bullet = objA as Phaser.Physics.Arcade.Sprite;
    }

    bullet.setActive(false).setVisible(false);
    (bullet.body as Phaser.Physics.Arcade.Body).enable = false;

    if (alien.takeDamage(this.player.stats.damage)) {
      this.cb.onExplosion(alien.x, alien.y);
      alien.destroy();
      this.enemyMgr.removeAlien(alien);
      this.cb.onScore(100);
    }
  }

  private onBulletHitBoss(
    objA: Phaser.Types.Physics.Arcade.GameObjectWithBody,
    objB: Phaser.Types.Physics.Arcade.GameObjectWithBody,
  ): void {
    let bullet: Phaser.Physics.Arcade.Sprite;
    let boss: Boss;
    if (objA instanceof Boss) {
      boss = objA;
      bullet = objB as Phaser.Physics.Arcade.Sprite;
    } else {
      boss = objB as unknown as Boss;
      bullet = objA as Phaser.Physics.Arcade.Sprite;
    }

    bullet.setActive(false).setVisible(false);
    (bullet.body as Phaser.Physics.Arcade.Body).enable = false;

    if (boss.takeDamage(this.player.stats.damage)) {
      console.log('[Collision] Boss killed by bullet!');
      this.cb.onExplosion(boss.x, boss.y);
      boss.destroy();
      this.bossCtrl.onBossKilled();
      this.cb.onScore(2000);
      this.cb.onBossKilled();
    }
  }

  private onPlayerHitByBullet(
    objA: Phaser.Types.Physics.Arcade.GameObjectWithBody,
    objB: Phaser.Types.Physics.Arcade.GameObjectWithBody,
  ): void {
    const bullet = (objA instanceof Player ? objB : objA) as Phaser.Physics.Arcade.Sprite;

    bullet.setActive(false).setVisible(false);
    (bullet.body as Phaser.Physics.Arcade.Body).enable = false;

    this.player.takeDamage(8);
    if (this.player.isDead()) {
      console.log('[Collision] Player died!');
      this.cb.onPlayerDied();
    }
  }

  private onBulletHitObstacle(
    bulletObj: Phaser.Types.Physics.Arcade.GameObjectWithBody,
    _obstacleObj: Phaser.Types.Physics.Arcade.GameObjectWithBody,
  ): void {
    const bullet = bulletObj as Phaser.Physics.Arcade.Sprite;
    bullet.setActive(false).setVisible(false);
    (bullet.body as Phaser.Physics.Arcade.Body).enable = false;
  }

  private onPlayerCollectPowerUp(
    objA: Phaser.Types.Physics.Arcade.GameObjectWithBody,
    objB: Phaser.Types.Physics.Arcade.GameObjectWithBody,
  ): void {
    const pu = (objA instanceof Player ? objB : objA) as Phaser.Physics.Arcade.Sprite;
    pu.destroy();
    this.powerUpCtrl.onCollected();
    this.cb.onPowerUpCollected();
  }
}
