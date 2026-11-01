import Phaser from 'phaser';
import { ShipStats } from '../config/ships';
// Game dimensions available via scene.physics.world.bounds if needed

export class Player extends Phaser.Physics.Arcade.Sprite {
  public stats: ShipStats;
  public currentHp: number;
  public poweredUp = false;
  private baseStats: ShipStats;
  private lastFired = 0;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private wasd!: { W: Phaser.Input.Keyboard.Key; A: Phaser.Input.Keyboard.Key; S: Phaser.Input.Keyboard.Key; D: Phaser.Input.Keyboard.Key };
  public bullets!: Phaser.Physics.Arcade.Group;
  private baseBullets!: Phaser.Physics.Arcade.Group;

  constructor(scene: Phaser.Scene, x: number, y: number, stats: ShipStats) {
    super(scene, x, y, stats.textureKey);
    this.stats = stats;
    this.baseStats = stats;
    this.currentHp = stats.hp;

    scene.add.existing(this);
    scene.physics.add.existing(this);

    this.setCollideWorldBounds(true);
    this.setDepth(10);

    // Scale down a bit so it feels right
    this.setScale(0.8);

    // Rotate to face right (flying left → right)
    this.setAngle(90);

    // Input
    if (scene.input.keyboard) {
      this.cursors = scene.input.keyboard.createCursorKeys();
      this.wasd = {
        W: scene.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.W),
        A: scene.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.A),
        S: scene.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.S),
        D: scene.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.D),
      };
    }

    // Bullet pool — use the ship-specific bullet texture
    this.bullets = scene.physics.add.group({
      defaultKey: stats.bulletTextureKey,
      maxSize: 30,
      runChildUpdate: true,
    });
    this.baseBullets = this.bullets;
  }

  update(time: number, _delta: number): void {
    const speed = this.stats.speed * this.stats.handling;

    // Horizontal movement
    if (this.cursors?.left.isDown || this.wasd?.A.isDown) {
      this.setVelocityX(-speed);
    } else if (this.cursors?.right.isDown || this.wasd?.D.isDown) {
      this.setVelocityX(speed);
    } else {
      this.setVelocityX(0);
    }

    // Vertical movement
    if (this.cursors?.up.isDown || this.wasd?.W.isDown) {
      this.setVelocityY(-speed);
    } else if (this.cursors?.down.isDown || this.wasd?.S.isDown) {
      this.setVelocityY(speed);
    } else {
      this.setVelocityY(0);
    }

    // Auto-fire (or hold space)
    const fireInterval = 1000 / this.stats.fireRate;
    const spaceDown = this.cursors?.space.isDown ?? true;
    if (spaceDown && time > this.lastFired + fireInterval) {
      this.fire(time);
    }
  }

  private fire(time: number): void {
    const bullet = this.bullets.get(this.x + 20, this.y) as Phaser.Physics.Arcade.Sprite | null;
    if (bullet) {
      bullet.setActive(true).setVisible(true);
      (bullet.body as Phaser.Physics.Arcade.Body).enable = true;
      bullet.setPosition(this.x + 20, this.y);
      bullet.setVelocityX(this.stats.bulletSpeed);
      bullet.setVelocityY(0);
      this.lastFired = time;

      // auto-destroy when off screen
      this.scene.time.delayedCall(2000, () => {
        if (bullet.active) {
          bullet.setActive(false).setVisible(false);
          (bullet.body as Phaser.Physics.Arcade.Body).enable = false;
        }
      });
    }
  }

  takeDamage(amount: number): void {
    this.currentHp -= amount;
    // Flash white on hit
    this.setTint(0xff0000);
    this.scene.time.delayedCall(100, () => this.clearTint());
  }

  isDead(): boolean {
    return this.currentHp <= 0;
  }

  /* ---- Power-up ---- */

  activatePowerUp(powerStats: ShipStats): void {
    this.poweredUp = true;
    this.stats = powerStats;
    this.currentHp = powerStats.hp;
    this.setTexture(powerStats.textureKey);

    // Create a separate bullet pool for power-up bullets
    this.bullets = this.scene.physics.add.group({
      defaultKey: powerStats.bulletTextureKey,
      maxSize: 40,
      runChildUpdate: true,
    });
  }

  deactivatePowerUp(): void {
    this.poweredUp = false;
    this.stats = this.baseStats;
    this.currentHp = this.baseStats.hp;
    this.setTexture(this.baseStats.textureKey);

    // Restore original bullet pool
    this.bullets = this.baseBullets;
  }
}
