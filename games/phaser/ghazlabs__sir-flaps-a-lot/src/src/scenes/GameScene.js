import { GAME_BALANCE, GAME_COLORS, GAME_HEIGHT, GAME_WIDTH } from "../game.js";

export class GameScene extends Phaser.Scene {
  constructor() {
    super("GameScene");
  }

  create() {
    this.cameras.main.setBackgroundColor(GAME_COLORS.sky);

    this.score = 0;
    this.currentGapHeight = GAME_BALANCE.initialGapHeight;
    this.currentObstacleSpeed = GAME_BALANCE.obstacleSpeed;
    this.scrollables = [];

    this.obstacles = this.physics.add.group({ allowGravity: false, immovable: true });
    this.scoreTriggers = this.physics.add.group({ allowGravity: false, immovable: true });
    this.createPlayer();
    this.createUi();
    this.bindInput();

    this.obstacleTimer = this.time.addEvent({
      delay: GAME_BALANCE.obstacleSpawnMs,
      loop: true,
      callback: () => this.spawnObstaclePair(),
    });
    this.firstObstacleEvent = this.time.delayedCall(
      GAME_BALANCE.firstObstacleDelayMs,
      () => this.spawnObstaclePair(),
      undefined,
      this
    );

    this.physics.add.overlap(this.player, this.obstacles, () => this.endGame(), undefined, this);
    this.physics.add.overlap(this.player, this.scoreTriggers, (_, trigger) => {
      if (trigger.scored) return;
      trigger.scored = true;
      this.incrementScore();
      trigger.destroy();
    });
  }

  createPlayer() {
    if (!this.textures.exists("sir-flaps")) {
      const playerShape = this.add.graphics();
      const shieldX = 34;
      const shieldY = 30;
      const points = [
        new Phaser.Geom.Point(shieldX, 0),
        new Phaser.Geom.Point(shieldX * 2, shieldY),
        new Phaser.Geom.Point(shieldX * 1.7, shieldY * 1.9),
        new Phaser.Geom.Point(shieldX, shieldY * 2.2),
        new Phaser.Geom.Point(shieldX * 0.3, shieldY * 1.9),
        new Phaser.Geom.Point(0, shieldY),
      ];

      playerShape.fillStyle(GAME_COLORS.stoneLight, 1);
      playerShape.fillPoints(points, true);
      playerShape.lineStyle(4, GAME_COLORS.gold, 1);
      playerShape.strokePoints(points, true);
      playerShape.generateTexture("sir-flaps", 68, 72);
      playerShape.destroy();
    }

    this.player = this.physics.add.sprite(120, GAME_HEIGHT / 2, "sir-flaps");
    this.player.setCollideWorldBounds(false);
    this.player.body.setSize(56, 62).setOffset(6, 6);
    this.player.setMaxVelocity(500, 700);
    this.player.setDepth(3);
  }

  createUi() {
    this.scoreText = this.add.text(20, 20, "Thy Score: 0", {
      fontSize: "34px",
      color: "#f8fafc",
      fontStyle: "bold",
    });
  }

  bindInput() {
    this.input.on("pointerdown", () => this.flap());
    this.spaceKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
  }

  flap() {
    if (!this.player?.active) return;
    this.player.setVelocityY(GAME_BALANCE.flapVelocity);
    this.player.setAngle(-15);
  }

  spawnObstaclePair() {
    const gapCenter = Phaser.Math.Between(180, GAME_HEIGHT - 180);
    const gapTop = gapCenter - this.currentGapHeight / 2;
    const gapBottom = gapCenter + this.currentGapHeight / 2;
    const pillarX = GAME_WIDTH + GAME_BALANCE.obstacleWidth / 2 + 8;

    this.spawnObstacleSegment(pillarX, gapTop / 2, GAME_BALANCE.obstacleWidth, gapTop);

    this.spawnObstacleSegment(
      pillarX,
      gapBottom + (GAME_HEIGHT - gapBottom) / 2,
      GAME_BALANCE.obstacleWidth,
      GAME_HEIGHT - gapBottom
    );

    const scoreTrigger = this.add.rectangle(pillarX, GAME_HEIGHT / 2, 6, GAME_HEIGHT, 0xffffff, 0);
    this.physics.add.existing(scoreTrigger, false);
    scoreTrigger.body.allowGravity = false;
    scoreTrigger.body.setImmovable(true);
    scoreTrigger.body.moves = false;
    scoreTrigger.scored = false;
    scoreTrigger.scrollSpeed = this.currentObstacleSpeed;
    this.scoreTriggers.add(scoreTrigger);
    this.scrollables.push(scoreTrigger);
  }

  spawnObstacleSegment(x, y, width, height) {
    const pillar = this.add.rectangle(x, y, width, height, 0x475569, 1);
    pillar.setStrokeStyle(4, GAME_COLORS.gold, 1);
    pillar.setDepth(1);

    this.physics.add.existing(pillar, false);
    pillar.body.allowGravity = false;
    pillar.body.setImmovable(true);
    pillar.body.moves = false;
    pillar.scrollSpeed = this.currentObstacleSpeed;

    this.obstacles.add(pillar);
    this.scrollables.push(pillar);
  }

  update(_, delta) {
    if (!this.player?.active) return;

    if (Phaser.Input.Keyboard.JustDown(this.spaceKey)) {
      this.flap();
    }

    this.player.setAngle(Phaser.Math.Clamp(this.player.body.velocity.y * 0.08, -20, 65));

    if (this.player.y > GAME_HEIGHT + 40 || this.player.y < -40) {
      this.endGame();
      return;
    }

    const deltaSeconds = delta / 1000;
    this.scrollables.forEach((item) => {
      if (!item?.active) return;
      item.x -= item.scrollSpeed * deltaSeconds;
      if (item.body) {
        item.body.updateFromGameObject();
      }
    });

    this.obstacles.getChildren().forEach((obstacle) => {
      if (!obstacle.body) return;

      if (obstacle.x < -120) {
        Phaser.Utils.Array.Remove(this.scrollables, obstacle);
        obstacle.destroy();
        return;
      }
    });

    this.scoreTriggers.getChildren().forEach((trigger) => {
      if (!trigger.body) return;
      if (trigger.x < -120) {
        Phaser.Utils.Array.Remove(this.scrollables, trigger);
        trigger.destroy();
      }
    });
  }

  incrementScore() {
    this.score += 1;
    this.scoreText.setText(`Thy Score: ${this.score}`);

    this.currentObstacleSpeed =
      GAME_BALANCE.obstacleSpeed + this.score * GAME_BALANCE.obstacleSpeedRamp;

    if (
      this.score > 0 &&
      this.score % GAME_BALANCE.gapShrinkEveryScore === 0 &&
      this.currentGapHeight > GAME_BALANCE.minimumGapHeight
    ) {
      this.currentGapHeight = Math.max(this.currentGapHeight - 10, GAME_BALANCE.minimumGapHeight);
    }
  }

  endGame() {
    if (!this.player?.active) return;

    this.input.off("pointerdown");
    if (this.obstacleTimer) {
      this.obstacleTimer.remove(false);
    }
    if (this.firstObstacleEvent) {
      this.firstObstacleEvent.remove(false);
    }
    this.scrollables.length = 0;

    this.physics.pause();
    this.player.setTint(GAME_COLORS.danger);

    this.time.delayedCall(550, () => {
      this.scene.start("GameOverScene", { score: this.score });
    });
  }
}
