import Phaser from 'phaser';
import Terrain from '../objects/Terrain.js';
import Cannon from '../objects/Cannon.js';
import ParticleEffects from '../objects/ParticleEffects.js';
import Background from '../objects/Background.js';
import Water from '../objects/Water.js';
import PredictionLine from '../objects/PredictionLine.js';
import ProjectileManager from '../systems/ProjectileManager.js';
import WindSystem from '../systems/WindSystem.js';
import WeaponSystem from '../systems/WeaponSystem.js';
import AIController from '../systems/AIController.js';
import MatchManager from '../systems/MatchManager.js';
import PowerUpSystem from '../systems/PowerUpSystem.js';
import AudioManager from '../systems/AudioManager.js';
import { calculateDamage, checkPartHit } from '../utils/combat.js';
import * as Config from '../config.js';

const TERRAIN_TYPE_ORDER = ['earth', 'sand', 'rock', 'earth', 'sand'];

export default class GameScene extends Phaser.Scene {
  constructor() {
    super('GameScene');
    this.difficulty = 'medium';
  }

  setDifficulty(difficulty) {
    this.difficulty = difficulty;
    if (this.aiController) {
      this.aiController.setDifficulty(difficulty);
    }
  }

  create() {
    // Systems
    this.windSystem = new WindSystem();
    this.weaponSystem = new WeaponSystem();
    this.matchManager = this.matchManager || new MatchManager();
    this.aiController = new AIController(this.difficulty);
    this.audioManager = new AudioManager(this);
    this.audioManager.init();

    // Determine terrain type for this round
    const roundIndex = (this.matchManager.round - 1) % TERRAIN_TYPE_ORDER.length;
    const terrainType = TERRAIN_TYPE_ORDER[roundIndex];

    // World objects
    this.background = new Background(this);
    this.terrain = new Terrain(this, terrainType);
    this.water = new Water(this);

    // Apply day/night tint
    const tintIndex = (this.matchManager.round - 1) % Config.ROUND_TINTS.length;
    this.background.applyTint(Config.ROUND_TINTS[tintIndex]);

    const playerX = Math.floor(Config.GAME_WIDTH * Config.PLAYER_X_PERCENT);
    const aiX = Math.floor(Config.GAME_WIDTH * Config.AI_X_PERCENT);

    this.playerCannon = new Cannon(this, playerX, true, this.terrain);
    this.aiCannon = new Cannon(this, aiX, false, this.terrain);

    this.particles = new ParticleEffects(this);
    this.predictionLine = new PredictionLine(this);
    this.projectileManager = new ProjectileManager(this);
    this.powerUpSystem = new PowerUpSystem(this);

    // Input
    this.cursors = this.input.keyboard.createCursorKeys();
    this.spaceKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
    this.key1 = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ONE);
    this.key2 = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.TWO);
    this.key3 = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.THREE);

    // Cooldown
    this.playerCooldown = 0;
    this.roundActive = true;
    this.cameraFollowTarget = null;

    this.emitHudUpdate();
  }

  update(time, delta) {
    if (!this.roundActive) return;

    // Update systems
    this.windSystem.update(delta);
    this.weaponSystem.update(delta);
    this.playerCannon.update();
    this.aiCannon.update();
    this.water.update(delta);
    this.background.update(delta);

    // Player cooldown
    if (this.playerCooldown > 0) {
      this.playerCooldown = Math.max(0, this.playerCooldown - delta);
    }

    // Player input (always active)
    this.handleInput();

    // AI independent firing
    const aiAction = this.aiController.update(
      delta, this.aiCannon, this.playerCannon,
      this.windSystem, this.projectileManager, this.weaponSystem
    );
    if (aiAction) {
      this.projectileManager.fire(
        this.aiCannon, aiAction.weapon,
        this.windSystem.getWind(), 'ai'
      );
      this.audioManager.playFire();
      this.particles.muzzleFlash(
        this.aiCannon.getBarrelTip().x,
        this.aiCannon.getBarrelTip().y
      );
    }

    // Update projectiles
    this.projectileManager.update(
      this.terrain, this.playerCannon, this.aiCannon,
      this.windSystem, {
        onImpact: (x, y, opts) => this.onProjectileImpact(x, y, opts),
        onWaterSplash: (x, y) => this.onWaterSplash(x, y),
      }
    );

    // Update power-ups
    this.powerUpSystem.update(
      delta, this.terrain,
      this.playerCannon, this.aiCannon,
      this.weaponSystem
    );

    // Update prediction line
    const currentWeapon = this.weaponSystem.getCurrent();
    this.predictionLine.update(this.playerCannon, this.windSystem.getWind(), currentWeapon.speedMultiplier);

    // Camera follow
    this.updateCamera();

    // Emit HUD data
    this.emitHudUpdate();
  }

  handleInput() {
    if (this.cursors.up.isDown) {
      this.playerCannon.adjustAngle(Config.ANGLE_STEP);
    } else if (this.cursors.down.isDown) {
      this.playerCannon.adjustAngle(-Config.ANGLE_STEP);
    }

    if (this.cursors.right.isDown) {
      this.playerCannon.adjustPower(Config.POWER_STEP);
    } else if (this.cursors.left.isDown) {
      this.playerCannon.adjustPower(-Config.POWER_STEP);
    }

    // Weapon switching
    if (Phaser.Input.Keyboard.JustDown(this.key1)) {
      this.weaponSystem.select(0);
    } else if (Phaser.Input.Keyboard.JustDown(this.key2)) {
      this.weaponSystem.select(1);
    } else if (Phaser.Input.Keyboard.JustDown(this.key3)) {
      this.weaponSystem.select(2);
    }

    // Fire
    if (Phaser.Input.Keyboard.JustDown(this.spaceKey) && this.playerCooldown <= 0) {
      const weapon = this.weaponSystem.getCurrent();
      this.projectileManager.fire(
        this.playerCannon, weapon,
        this.windSystem.getWind(), 'player'
      );
      this.playerCooldown = Config.PLAYER_COOLDOWN;
      this.audioManager.playFire();
      this.particles.muzzleFlash(
        this.playerCannon.getBarrelTip().x,
        this.playerCannon.getBarrelTip().y
      );
    }
  }

  onProjectileImpact(x, y, options) {
    const ix = Phaser.Math.Clamp(Math.floor(x), 0, Config.GAME_WIDTH - 1);
    const weapon = options.weapon;

    // Effects
    const intensity = weapon.blastRadius / 40; // Normalize to standard
    this.particles.explode(ix, y, intensity);
    this.audioManager.playExplosion();

    // Screen shake proportional to blast
    const shakeIntensity = Config.SHAKE_INTENSITY_BASE * intensity;
    this.cameras.main.shake(Config.SHAKE_DURATION_BASE, shakeIntensity);

    // Crater
    this.terrain.carveWithDepth(ix, weapon.blastRadius, weapon.craterDepth);

    // Determine target
    const target = options.owner === 'player' ? this.aiCannon : this.playerCannon;
    const effectiveDamage = weapon.damage * (this.weaponSystem.damageMultiplier || 1);

    const damage = calculateDamage(
      ix, y, target.x, target.y,
      weapon.blastRadius, effectiveDamage
    );

    if (damage > 0) {
      target.takeDamage(damage);
      this.cameras.main.shake(300, 0.015);

      // Check part damage
      const parts = checkPartHit(ix, y, target, weapon.blastRadius);
      if (parts.barrelHit && !target.barrelDamaged) {
        target.damageBarrel();
      }
      if (parts.wheelHit && !target.wheelDamaged) {
        target.damageWheel();
      }
    }

    // Record AI miss for bracketing
    if (options.owner === 'ai') {
      this.aiController.recordMiss(ix, y);
    }

    // Update positions after terrain change
    this.playerCannon.updatePosition();
    this.aiCannon.updatePosition();

    // Check for kill
    if (target.targetHp <= 0) {
      this.onCannonDestroyed(target, options.owner);
    }
  }

  onWaterSplash(x, y) {
    this.particles.splash(x, y);
    this.audioManager.playSplash();
  }

  onCannonDestroyed(cannon, killerOwner) {
    this.particles.explode(cannon.x, cannon.y, 2);
    this.cameras.main.shake(500, 0.02);
    this.roundActive = false;

    const winner = killerOwner === 'player' ? 'player' : 'ai';
    this.matchManager.recordRoundWin(winner);

    this.time.delayedCall(1500, () => {
      if (this.matchManager.isMatchOver()) {
        const matchData = this.matchManager.getMatchData();
        this.game.events.emit('match-over', matchData);
        this.cleanup();
        this.matchManager = null; // Will be recreated on next game
      } else {
        const roundData = this.matchManager.getRoundData(winner);
        this.game.events.emit('round-over', roundData);
        // Scene will be restarted when player clicks "Next Round"
        this.matchManager.nextRound();
        this.cleanup();
        this.scene.restart();
      }
    });
  }

  updateCamera() {
    // Find nearest active projectile to follow
    const projs = this.projectileManager.projectiles.filter(p => p.alive);
    if (projs.length > 0) {
      const nearest = projs[0];
      const pos = nearest.getPosition();
      const targetX = Phaser.Math.Clamp(
        pos.x - Config.GAME_WIDTH / 2,
        0, 0 // No camera scroll for now (800px viewport = game width)
      );
    }
  }

  emitHudUpdate() {
    const deg = Math.round(this.playerCannon.angle * 180 / Math.PI);
    this.game.events.emit('hud-update', {
      playerHp: this.playerCannon.targetHp,
      aiHp: this.aiCannon.targetHp,
      wind: this.windSystem.getWind(),
      cooldownPct: Math.min(100, ((Config.PLAYER_COOLDOWN - this.playerCooldown) / Config.PLAYER_COOLDOWN) * 100),
      weaponIndex: this.weaponSystem.currentIndex,
      round: this.matchManager ? this.matchManager.round : 1,
      playerScore: this.matchManager ? this.matchManager.playerScore : 0,
      aiScore: this.matchManager ? this.matchManager.aiScore : 0,
      angle: deg,
      power: this.playerCannon.power,
      aiName: this.aiController.name,
    });
  }

  cleanup() {
    this.projectileManager.destroyAll();
    this.powerUpSystem.destroyAll();
    this.predictionLine.destroy();
    this.background.destroy();
    this.water.destroy();
    this.playerCannon.destroy();
    this.aiCannon.destroy();
    this.terrain.destroy();
  }
}
