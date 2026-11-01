import { Scene } from "phaser";
import { Bullet } from "../sprites/bullet";
import { Enemy } from "../sprites/enemy/enemy";
import { PinkEnemy } from "../sprites/enemy/pink-enemy";
import { BlueEnemy } from "../sprites/enemy/blue-enemy";
import { GreenEnemy } from "../sprites/enemy/green-enemy";
import {
  PLAYER_SPEED,
  SHOOT_COOLDOWN_MS,
  SPAWN_INTERVAL_MIN_MS,
  SPAWN_INTERVAL_START_MS,
  SPAWN_INTERVAL_STEP_MS,
  START_HEALTH,
} from "../../constants/gameplay";

/** Height (at base resolution) reserved for HUD text at the top and bottom. */
const HUD_HEIGHT = 44;

type MoveKeys = {
  W: Phaser.Input.Keyboard.Key;
  S: Phaser.Input.Keyboard.Key;
};

export class Game extends Scene {
  private cursors?: Phaser.Types.Input.Keyboard.CursorKeys;
  private moveKeys?: MoveKeys;

  private player: Phaser.Physics.Arcade.Sprite;

  private bullets: Phaser.Physics.Arcade.Group;
  private enemies: Phaser.Physics.Arcade.Group;

  private scoreText: Phaser.GameObjects.Text;
  private healthText: Phaser.GameObjects.Text;

  // Run state: reset in create() because the scene instance is reused on restart.
  private score = 0;
  private health = START_HEALTH;
  private isGameOver = false;
  private lastShotTime = 0;
  private spawnInterval = SPAWN_INTERVAL_START_MS;

  private isDownPressed = false;
  private isUpPressed = false;
  private isFirePressed = false;

  constructor() {
    super("Game");
  }

  create() {
    this.resetState();

    const { width, height } = this.scale;
    const { scaleFactor, isTouch } = this.responsive;

    // Template gradient darkened with an overlay (works on both WebGL and Canvas).
    this.add
      .image(0, 0, "bg")
      .setOrigin(0)
      .setDisplaySize(width, height)
      .setDepth(-2);
    this.add
      .rectangle(0, 0, width, height, 0x0b1020, 0.82)
      .setOrigin(0)
      .setDepth(-1);

    this.cursors = this.input.keyboard?.createCursorKeys();
    this.moveKeys = this.input.keyboard?.addKeys("W,S") as MoveKeys | undefined;

    this.createHud(isTouch);
    if (isTouch) {
      this.createTouchControls();
    }

    this.player = this.physics.add
      .sprite(64 * scaleFactor, height / 2, "ship")
      .setScale(scaleFactor);
    this.player.setCollideWorldBounds(true);
    const hudHeight = HUD_HEIGHT * scaleFactor;
    (this.player.body as Phaser.Physics.Arcade.Body).setBoundsRectangle(
      new Phaser.Geom.Rectangle(0, hudHeight, width, height - hudHeight * 2)
    );

    // runChildUpdate so Bullet/Enemy update() actually runs each frame.
    this.bullets = this.physics.add.group({
      classType: Bullet,
      runChildUpdate: true,
    });
    this.enemies = this.physics.add.group({
      classType: Enemy,
      runChildUpdate: true,
    });

    // Invisible static strip along the left edge: enemies reaching it hurt the player.
    const leftSensor = this.add
      .rectangle(0, height / 2, 10, height)
      .setVisible(false);
    this.physics.add.existing(leftSensor, true);

    this.physics.add.overlap(this.bullets, this.enemies, (b, e) => {
      const enemy = e as Enemy;
      const bullet = b as Bullet;

      bullet.destroy();
      enemy.takeDamage(bullet.getDamage(), (points) => {
        this.score += points;
        this.updateHud();
      });
    });

    this.physics.add.overlap(leftSensor, this.enemies, (_sensor, e) => {
      if (this.isGameOver) return;

      const enemy = e as Enemy;
      this.health -= enemy.getDamage();
      enemy.destroy();
      this.updateHud();

      if (this.health <= 0) {
        this.endGame();
      }
    });

    this.scheduleNextSpawn();
  }

  update(time: number) {
    if (this.isGameOver) return;

    const movingDown =
      this.cursors?.down.isDown || this.moveKeys?.S.isDown || this.isDownPressed;
    const movingUp =
      this.cursors?.up.isDown || this.moveKeys?.W.isDown || this.isUpPressed;

    if (movingDown) {
      this.player.setVelocityY(PLAYER_SPEED * this.responsive.scaleY);
    } else if (movingUp) {
      this.player.setVelocityY(-PLAYER_SPEED * this.responsive.scaleY);
    } else {
      this.player.setVelocityY(0);
    }

    const firing = this.cursors?.space.isDown || this.isFirePressed;
    if (firing && time > this.lastShotTime + SHOOT_COOLDOWN_MS) {
      this.shoot();
      this.lastShotTime = time;
    }
  }

  private resetState() {
    this.score = 0;
    this.health = START_HEALTH;
    this.isGameOver = false;
    this.lastShotTime = 0;
    this.spawnInterval = SPAWN_INTERVAL_START_MS;
    this.isDownPressed = false;
    this.isUpPressed = false;
    this.isFirePressed = false;
  }

  private createHud(isTouch: boolean) {
    const { width, height } = this.scale;
    const { scaleFactor } = this.responsive;

    this.scoreText = this.add
      .text(12, 12, "", { fontSize: 24 })
      .setScale(scaleFactor)
      .setDepth(100);
    this.healthText = this.add
      .text(200 * scaleFactor, 12, "", { fontSize: 24 })
      .setScale(scaleFactor)
      .setDepth(100);
    this.updateHud();

    if (!isTouch) {
      this.add
        .text(12, height - 36 * scaleFactor, "Space to Shoot ; Up/Down to Move", {
          fontSize: 24,
        })
        .setDepth(100)
        .setScale(scaleFactor);
    }

    const name = this.registry.get("name") as string | undefined;
    if (name) {
      this.add
        .text(width - 12, 12, name, { fontSize: 24 })
        .setOrigin(1, 0)
        .setDepth(100)
        .setScale(scaleFactor);
    }
  }

  private createTouchControls() {
    const { width, height } = this.scale;
    // Never shrink below the 64px art so buttons stay thumb-sized on phones.
    const buttonScale = Math.max(1, this.responsive.scaleFactor);
    const margin = 16;

    const upButton = this.add
      .image(0, 0, "up_button")
      .setScale(buttonScale)
      .setDepth(100)
      .setAlpha(0.7)
      .setInteractive({ useHandCursor: true });
    const downButton = this.add
      .image(0, 0, "down_button")
      .setScale(buttonScale)
      .setDepth(100)
      .setAlpha(0.7)
      .setInteractive({ useHandCursor: true });

    const buttonSize = upButton.displayWidth;
    const gap = 8;
    downButton.setPosition(
      margin + buttonSize / 2,
      height - margin - buttonSize / 2
    );
    upButton.setPosition(
      downButton.x,
      downButton.y - buttonSize - gap
    );

    const fireButton = this.add
      .image(0, 0, "circle_button")
      .setScale(buttonScale * 1.5)
      .setDepth(100)
      .setInteractive({ useHandCursor: true });
    fireButton.setPosition(
      width - margin - fireButton.displayWidth / 2,
      height - margin - fireButton.displayHeight / 2
    );
    const crossHair = this.add
      .image(fireButton.x, fireButton.y, "crosshair")
      .setScale(buttonScale)
      .setDepth(101);

    this.bindHoldButton(upButton, (held) => {
      this.isUpPressed = held;
      upButton.setAlpha(held ? 0.5 : 0.7);
    });
    this.bindHoldButton(downButton, (held) => {
      this.isDownPressed = held;
      downButton.setAlpha(held ? 0.5 : 0.7);
    });
    this.bindHoldButton(fireButton, (held) => {
      this.isFirePressed = held;
      fireButton.setAlpha(held ? 0.7 : 1);
      crossHair.setAlpha(held ? 0.8 : 1);
      if (held) {
        crossHair.setTint(0xff6666);
      } else {
        crossHair.clearTint();
      }
    });
  }

  /** Reports true while the pointer is held on the image, false on release/leave. */
  private bindHoldButton(
    image: Phaser.GameObjects.Image,
    onChange: (held: boolean) => void
  ) {
    image.on("pointerdown", () => onChange(true));
    image.on("pointerup", () => onChange(false));
    image.on("pointerout", () => onChange(false));
  }

  private updateHud() {
    this.scoreText.setText(`Score: ${this.score}`);
    this.healthText.setText(`Health: ${Math.max(0, this.health)}`);
  }

  private shoot() {
    this.sound.play("gun");

    const bullet = new Bullet(
      this,
      this.player.x + this.player.displayWidth / 2,
      this.player.y,
      "missile"
    );
    this.bullets.add(bullet);
    bullet.init();
  }

  private scheduleNextSpawn() {
    this.time.delayedCall(this.spawnInterval, () => {
      if (this.isGameOver) return;

      this.spawnEnemy();
      this.spawnInterval = Math.max(
        SPAWN_INTERVAL_MIN_MS,
        this.spawnInterval - SPAWN_INTERVAL_STEP_MS
      );
      this.scheduleNextSpawn();
    });
  }

  private spawnEnemy() {
    const { width, height } = this.scale;
    const { scaleFactor } = this.responsive;

    // Start just off the right edge so enemies fly in rather than pop in.
    const x = width + 80 * scaleFactor;
    // Keep spawns clear of the HUD strips (tallest alien is ~145px at base size).
    const margin = (HUD_HEIGHT + 72) * scaleFactor;
    const y = Phaser.Math.Between(margin, height - margin);

    const type = Phaser.Math.RND.pick(["pink", "blue", "green"] as const);
    let enemy: Enemy;
    if (type === "pink") {
      enemy = new PinkEnemy(this, x, y);
    } else if (type === "blue") {
      enemy = new BlueEnemy(this, x, y);
    } else {
      enemy = new GreenEnemy(this, x, y);
    }

    // init() must run after add(): the group resets body defaults on add.
    this.enemies.add(enemy);
    enemy.init();
  }

  private endGame() {
    this.isGameOver = true;
    this.player.setVelocityY(0);
    this.physics.world.pause();

    this.scene.launch("GameOver", { score: this.score });
    this.scene.pause();
  }
}
