import Phaser from 'phaser';
import { generateTextures } from '../utils/textures';
import { Player } from '../entities/Player';
import { SHIPS, ShipKey } from '../config/ships';
import { GAME_WIDTH, GAME_HEIGHT } from '../config/game';

// Systems
import { EnvironmentController } from '../systems/EnvironmentController';
import { EnemyManager } from '../systems/EnemyManager';
import { BossController } from '../systems/BossController';
import { PowerUpController } from '../systems/PowerUpController';
import { HudController } from '../systems/HudController';
import { CollisionSystem, CollisionCallbacks } from '../systems/CollisionSystem';
import { GameStateMachine } from '../systems/GameStateMachine';

export class GameScene extends Phaser.Scene {
  private selectedShip: ShipKey = 'f35';
  private player!: Player;

  // Game-wide state
  private score = 0;
  private elapsed = 0;

  // Systems
  private environmentCtrl!: EnvironmentController;
  private gameStateMachine!: GameStateMachine;
  private enemyMgr!: EnemyManager;
  private bossCtrl!: BossController;
  private powerUpCtrl!: PowerUpController;
  private hudCtrl!: HudController;
  private collisionSys!: CollisionSystem;

  constructor() {
    super({ key: 'GameScene' });
  }

  init(data: { ship?: ShipKey }): void {
    this.selectedShip = data.ship ?? 'f35';
  }

  /* ---------------------------------------------------------------- */
  /*  CREATE                                                           */
  /* ---------------------------------------------------------------- */
  create(): void {
    // Reset game-wide state
    this.score = 0;
    this.elapsed = 0;

    // Generate textures (idempotent)
    if (!this.textures.exists('f35')) {
      generateTextures(this);
    }

    // Create player
    this.player = new Player(this, 80, GAME_HEIGHT / 2, SHIPS[this.selectedShip]);

    // Create systems
    this.environmentCtrl = new EnvironmentController(this);
    this.enemyMgr = new EnemyManager(this);
    this.bossCtrl = new BossController(this);
    this.powerUpCtrl = new PowerUpController(this, this.player);
    this.hudCtrl = new HudController(this);

    // Game state machine (WON / LOST / PLAYING)
    this.gameStateMachine = new GameStateMachine({
      onWin: () => this.endGame(true),
      onLose: () => this.endGame(false),
    });

    // Wire up collision callbacks
    const collisionCallbacks: CollisionCallbacks = {
      onScore: (pts) => (this.score += pts),
      onExplosion: (x, y) => this.spawnExplosion(x, y),
      onBossKilled: () => this.gameStateMachine.onBossKilled(),
      onPlayerDied: () => this.gameStateMachine.onPlayerDied(),
      onPowerUpCollected: () => {
        // Re-register power-up bullets → obstacles (bullets are now player.bullets)
        this.physics.add.overlap(
          this.player.bullets,
          this.environmentCtrl.obstacles,
          this.onPowerUpBulletHitObstacle as Phaser.Types.Physics.Arcade.ArcadePhysicsCallback,
          undefined,
          this,
        );
      },
    };

    this.collisionSys = new CollisionSystem(
      this,
      this.player,
      this.enemyMgr,
      this.bossCtrl,
      this.environmentCtrl,
      this.powerUpCtrl,
      collisionCallbacks,
    );

    // Initialize all systems
    this.environmentCtrl.create();
    this.enemyMgr.create();
    this.bossCtrl.create();
    this.powerUpCtrl.create();
    this.hudCtrl.create(this.player.currentHp);
    this.collisionSys.create();
  }

  /* ---------------------------------------------------------------- */
  /*  UPDATE                                                           */
  /* ---------------------------------------------------------------- */
  update(time: number, delta: number): void {
    if (this.gameStateMachine.isGameOver()) {
      console.log('[GameScene] update: skipping, game over state=', this.gameStateMachine.state);
      return;
    }

    this.elapsed += delta;

    // Environment (stars + obstacles)
    this.environmentCtrl.update();

    // Player
    this.player.update(time, delta);

    // Enemies
    this.enemyMgr.update(time, delta);

    // Power-up
    this.powerUpCtrl.update(time, delta, this.elapsed);

    // Boss
    this.bossCtrl.update(time, delta, this.elapsed, { x: this.player.x, y: this.player.y });

    // Collisions
    this.collisionSys.update();

    // HUD
    this.hudCtrl.update(this.player.currentHp, this.score, this.elapsed);
  }

  /* ---------------------------------------------------------------- */
  /*  HELPERS                                                          */
  /* ---------------------------------------------------------------- */

  private spawnExplosion(x: number, y: number): void {
    const exp = this.add.image(x, y, 'explosion').setDepth(20);
    this.tweens.add({
      targets: exp,
      scaleX: 2.5,
      scaleY: 2.5,
      alpha: 0,
      duration: 400,
      onComplete: () => exp.destroy(),
    });
  }

  /** Called when power-up bullets hit obstacles (re-registered on power-up collect). */
  private onPowerUpBulletHitObstacle(
    bulletObj: Phaser.Types.Physics.Arcade.GameObjectWithBody,
    _obstacleObj: Phaser.Types.Physics.Arcade.GameObjectWithBody,
  ): void {
    const bullet = bulletObj as Phaser.Physics.Arcade.Sprite;
    bullet.setActive(false).setVisible(false);
    (bullet.body as Phaser.Physics.Arcade.Body).enable = false;
  }

  /* ---- End game ---- */
  private endGame(won: boolean): void {
    console.log('[GameScene] endGame called, won=', won, 'state=', this.gameStateMachine.state);

    console.log('[GameScene] pausing physics...');
    this.physics.pause();
    console.log('[GameScene] physics paused');

    const msg = won ? 'YOU WIN!' : 'GAME OVER';
    const color = won ? '#44ff44' : '#ff4444';

    console.log('[GameScene] adding main text...');
    const mainText = this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 - 30, msg, {
        fontSize: '48px',
        color,
        fontFamily: 'monospace',
        fontStyle: 'bold',
      })
      .setOrigin(0.5)
      .setDepth(200);
    console.log('[GameScene] main text added, x=', mainText.x, 'y=', mainText.y, 'visible=', mainText.visible);

    console.log('[GameScene] adding score text...');
    const scoreText = this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 30, `Score: ${this.score}`, {
        fontSize: '24px',
        color: '#ffffff',
        fontFamily: 'monospace',
      })
      .setOrigin(0.5)
      .setDepth(200);
    console.log('[GameScene] score text added, x=', scoreText.x, 'y=', scoreText.y);

    console.log('[GameScene] adding instructions text...');
    const instrText = this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 70, 'R / tap to restart  •  Q for ship select', {
        fontSize: '16px',
        color: '#aaaaaa',
        fontFamily: 'monospace',
      })
      .setOrigin(0.5)
      .setDepth(200);
    console.log('[GameScene] instructions text added, x=', instrText.x, 'y=', instrText.y);

    // Restart on R key — replay with same ship
    this.input.keyboard?.once('keydown-R', () => {
      this.scene.restart({ ship: this.selectedShip });
    });

    // Return to ship selection on Q key
    this.input.keyboard?.once('keydown-Q', () => {
      this.scene.start('StartScene');
    });

    // Restart on tap / click
    this.input.once('pointerdown', () => {
      this.scene.restart({ ship: this.selectedShip });
    });

    console.log('[GameScene] endGame complete, msg=', msg);
  }
}
