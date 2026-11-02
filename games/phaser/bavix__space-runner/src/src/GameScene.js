import Phaser from 'phaser';
import { ThemeManager } from './ThemeManager.js';
import { normalizeVector } from './utils/mathHelpers.js';
import { isInCircleSq, isInRingSq, getRadiusSq } from './utils/drawingHelpers.js';
import { CollisionManager } from './utils/CollisionManager.js';
import { UpdateManager } from './utils/UpdateManager.js';
import { MemoryManager } from './utils/MemoryManager.js';
import { PerformanceManager } from './utils/PerformanceManager.js';
import { EventManager, GAME_EVENTS } from './utils/EventManager.js';
import { loadHighScore, saveHighScore } from './utils/storage.js';
import { 
  getColor, 
  getParticleColor, 
  getPowerupColor, 
  colorToHex 
} from './utils/colorHelpers.js';
import { drawPlayer } from './drawing/player.js';
import { drawPixel } from './drawing/pixel.js';
import { 
  PLAYER_SIZE, PLAYER_SPEED, BULLET_SIZE, BULLET_SPEED,
  ASTEROID_SIZE, COMET_SIZE, FAST_ENEMY_SIZE, BIG_ENEMY_SIZE,
  ENERGY_SIZE, POWERUP_SIZE, SPAWN_RATE, ENERGY_SPAWN_RATE,
  POWERUP_SPAWN_RATE, HYPERSPEED_DURATION, HYPERSPEED_MULTIPLIER,
  SHOOT_COOLDOWN, COMBO_TIMEOUT, BOSS_SPAWN_SCORE, TRIPLE_SHOT_DURATION, AUTO_AIM_DURATION,
  MAGNET_DURATION, MAGNET_RADIUS, MAGNET_MAX_PULL_SPEED, MAGNET_MIN_PULL_SPEED,
  SLOW_MOTION_DURATION, SLOW_MOTION_FACTOR, MULTI_KILL_WINDOW,
  POWERUP_PARTICLES_COUNT, POWERUP_TEXT_SIZE, SHIELD_DURATION, INFINITE_DURATION,
  EXPLOSION_PARTICLES_COUNT, BOSS_KILL_PARTICLES_COUNT, BOSS_KILL_PARTICLES_COUNT_2,
  ENERGY_PARTICLES_COUNT, BOSS_HIT_PARTICLES_COUNT, LEVEL_UP_PARTICLES_COUNT,
  DAMAGE_PARTICLES_COUNT, BOSS_SPAWN_PARTICLES_COUNT, FLOATING_TEXT_SIZES,
  COLOR_PATHS, POWERUP_TYPES, PARTICLE_TYPES, OBSTACLE_TYPES
} from './constants/index.js';
import { BOSS_CONFIG } from './bossConfig.js';
import { BOSS_TYPES } from './constants.js';
import { setGameSceneInstance } from './main.js';
import { SoundManager } from './utils/SoundManager.js';
import { ParticleManager } from './managers/ParticleManager.js';
import { ObstacleManager } from './managers/ObstacleManager.js';
import { PowerupManager } from './managers/PowerupManager.js';
import { EnergyManager } from './managers/EnergyManager.js';
import { UIManager } from './managers/UIManager.js';
import { FloatingTextManager } from './managers/FloatingTextManager.js';
import { BulletManager } from './managers/BulletManager.js';
import { StarManager } from './managers/StarManager.js';
import { BossManager } from './managers/BossManager.js';

export class GameScene extends Phaser.Scene {
  constructor() {
    super({ key: 'GameScene' });
  }
  
  create() {
    this.themeManager = new ThemeManager();
    this.isDark = this.themeManager.isDark;
    
    this.soundManager = new SoundManager();
    this.soundManager.init();
    
    this.score = 0;
    this.highScore = loadHighScore();
    this.gameStarted = false;
    this.gameOver = false;
    this.isPaused = false;
    this.isHyperspeed = false;
    this.isTripleShot = false;
    this.isAutoAimActive = false;
    this.isMagnetActive = false;
    this.isSlowMotionActive = false;
    if (this.autoAimText) {
      this.autoAimText.setVisible(false);
    }
    this.autoAimTargets = [];
    this.autoAimTargetsCacheTime = 0;
    this.autoAimGraphics = null;
    this.combo = 0;
    this.multiKillKills = [];
    this.multiKillLastKillTime = 0;
    this.level = 1;
    this.kills = 0;
    this.comboFlash = 0;
    this.scoreFlash = 0;
    this.lives = 3;
    
    this.cachedChildren = {
      particles: null,
      obstacles: null,
      bullets: null,
      bossBullets: null,
      energies: null,
      powerups: null
    };
    this.childrenCacheTime = 0;
    this.childrenCacheInterval = 16;
    
    this.gameWidth = this.scale.width;
    this.gameHeight = this.scale.height;
    this.updateGameSize();
    
    this.baseWidth = 600;
    this.baseHeight = 400;
    this.fontScale = Math.min(this.gameWidth / this.baseWidth, this.gameHeight / this.baseHeight);
    
    this.bgColor = getColor(this.themeManager, COLOR_PATHS.BACKGROUND);
    this.cameras.main.setBackgroundColor(this.bgColor);
    
    this.physics.world.setBounds(0, 0, this.gameWidth, this.gameHeight);
    
    this.player = this.add.graphics();
    this.setupPhysicsBody(this.player, PLAYER_SIZE);
    this.player.x = 50;
    this.player.y = this.gameHeight / 2;
    this.syncPhysicsBody(this.player);
    this.player.setDepth(1000);
    this.playerTrail = [];
    this.playerDirty = true;
    this.lastPlayerState = null;
    
    this.bullets = this.add.group();
    this.obstacles = this.add.group();
    this.energies = this.add.group();
    this.powerups = this.add.group();
    this.particles = this.add.group();
    this.floatingTexts = this.add.group();
    this.bossBullets = this.add.group();
    
    this.gameElementsContainer = this.add.container(0, 0);
    
    // Initialize managers
    this.particleManager = new ParticleManager(this, this.themeManager, this.gameElementsContainer, this.particles);
    this.obstacleManager = new ObstacleManager(this, this.themeManager, this.gameElementsContainer);
    this.powerupManager = new PowerupManager(this, this.themeManager, this.gameElementsContainer);
    this.energyManager = new EnergyManager(this, this.themeManager, this.gameElementsContainer);
    this.uiManager = new UIManager(this, this.themeManager);
    this.uiManager.initialize(this.gameWidth, this.gameHeight, this.fontScale);
    this.floatingTextManager = new FloatingTextManager(this);
    this.bulletManager = new BulletManager(this, this.themeManager, this.gameElementsContainer, this.bullets);
    this.starManager = new StarManager(this, this.themeManager);
    this.starManager.initialize(this.gameWidth, this.gameHeight);
    this.bossManager = new BossManager(
      this, 
      this.themeManager, 
      this.gameElementsContainer,
      (x, y, count, color, type) => this.createParticles(x, y, count, color, type),
      (x, y, text, color, size) => this.createFloatingText(x, y, text, color, size),
      this.bossBullets
    );
    this.collisionManager = new CollisionManager();
    this.updateManager = new UpdateManager();
    this.memoryManager = new MemoryManager();
    this.performanceManager = new PerformanceManager();
    this.eventManager = new EventManager();
    this.frameCount = 0;
    this.gameElementsContainer.setDepth(0);
    this.gameElementsBlurEffect = null;
    
    this.trailGraphics = this.add.graphics();
    this.trailGraphics.setDepth(1);
    this.gameElementsContainer.add(this.trailGraphics);
    this.airRushGraphics = this.add.graphics();
    this.airRushGraphics.setDepth(0.5);
    this.engineFireGraphics = this.add.graphics();
    this.engineFireGraphics.setDepth(0.5);
    this.gameElementsContainer.add(this.engineFireGraphics);
    this.shieldGraphics = this.add.graphics();
    this.shieldGraphics.setDepth(2);
    
    this.autoAimGraphics = this.add.graphics();
    this.autoAimGraphics.setDepth(1.5);
    
    this.magnetGraphics = this.add.graphics();
    this.magnetGraphics.setDepth(1.3);
    this.magnetFieldParticles = [];
    
    // Screen effects graphics
    this.screenFlashGraphics = this.add.graphics();
    this.screenFlashGraphics.setDepth(10000); // Top layer
    this.screenFlashGraphics.setScrollFactor(0); // Fixed to camera
    
    this.isBlurActive = false;
    this.lastBlurUpdate = 0;
    this.blurUpdateInterval = 50;
    
    this.lastUIUpdate = 0;
    this.uiUpdateInterval = 100;
    
    // Screen effects
    this.screenFlashAlpha = 0;
    this.cameraShakeIntensity = 0;
    this.cameraShakeDuration = 0;
    
    this.cachedPlayerRect = { x: 0, y: 0, width: 0, height: 0 };
    this.playerRectDirty = true;
    
    this.progressBarBg = null;
    this.progressBar = null;
    this.progressBarBgDirty = true;
    this.progressBarDirty = true;
    this.lastProgressWidth = 0;
    
    this.TWO_PI = Math.PI * 2;
    
    this.boss = null;
    this.bossPattern = 0;
    
    this.hyperspeedStartTime = 0;
    this.hyperspeedEndTime = 0;
    this.hyperspeedMultiplier = 1;
    this.tripleShotEndTime = 0;
    this.lastShotTime = 0;
    this.lastKillTime = 0;
    this.comboTimeout = null;
    this.lastBossScore = 0;
    this.isShieldActive = false;
    this.shieldEndTime = 0;
    this.bossLastShotTime = 0;
    this.cheats = {
      wallHack: false,
      noBlur: false,
      godMode: false,
      infiniteLives: false,
      infinitePowerups: false,
      oneHitKill: false
    };
    
    this.cheatInput = '';
    this.cheatCodes = {
      'WALLHACK': { key: 'wallHack', name: 'Wall Hack' },
      'NOBLUR': { key: 'noBlur', name: 'No Blur' },
      'GODMODE': { key: 'godMode', name: 'God Mode' },
      'INFINITELIVES': { key: 'infiniteLives', name: 'Infinite Lives' },
      'INFINITEPOWERUPS': { key: 'infinitePowerups', name: 'Infinite Powerups' },
      'ONEHITKILL': { key: 'oneHitKill', name: 'One Hit Kill' }
    };
    
    if (!this.input.keyboard && this.input.keyboardPlugin) {
      this.input.keyboard = this.input.keyboardPlugin;
    }
    
    if (this.input.keyboard) {
      this.input.keyboard.enabled = true;
      this.cursors = this.input.keyboard.createCursorKeys();
      this.spaceKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
      this.pKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.P);
      this.escKey = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.ESC);
      
      this.spaceKeyWasPressed = false;
      
      this.input.keyboard.on('keydown', (event) => {
        // Handle sound toggle with Ctrl+Shift+S or Cmd+Shift+S
        // Check for S key and modifier keys from the event directly
        const isSKey = event.key === 's' || event.key === 'S' || event.keyCode === 83;
        const isCtrlPressed = event.ctrlKey || event.metaKey; // metaKey is Cmd on Mac
        const isShiftPressed = event.shiftKey;
        
        if (isSKey && isCtrlPressed && isShiftPressed) {
          event.preventDefault();
          this.soundManager.setEnabled(!this.soundManager.soundsEnabled);
          if (this.soundManager.soundsEnabled) {
            this.soundManager.ensureAudioContext();
          }
          // Force UI update to show sound state change
          this.lastUIUpdate = 0;
          return;
        }
        
        if (this.isPaused) {
          const keyCode = event.keyCode;
          if (keyCode >= 65 && keyCode <= 90) {
            const char = String.fromCharCode(keyCode);
            this.cheatInput += char.toUpperCase();
            
            const MAX_CHEAT_INPUT_LENGTH = 20;
            if (this.cheatInput.length > MAX_CHEAT_INPUT_LENGTH) {
              this.cheatInput = this.cheatInput.substring(this.cheatInput.length - MAX_CHEAT_INPUT_LENGTH);
            }
            
            for (const code in this.cheatCodes) {
              if (this.cheatInput.endsWith(code)) {
                const cheat = this.cheatCodes[code];
                const cheatKey = cheat.key;
                this.cheats[cheatKey] = !this.cheats[cheatKey];
                this.cheatInput = '';
                
                // Cheat activated/deactivated (console.log removed for production)
                break;
              }
            }
          } else if (keyCode === 8) {
            if (this.cheatInput.length > 0) {
              this.cheatInput = this.cheatInput.substring(0, this.cheatInput.length - 1);
            }
          }
        }
      });
      
      this.input.keyboard.on('keyup', (event) => {
        if (event.keyCode === Phaser.Input.Keyboard.KeyCodes.SPACE) {
          this.spaceKeyWasPressed = false;
        }
      });
      
      const canvas = this.game.canvas;
      if (canvas) {
        canvas.setAttribute('tabindex', '0');
        canvas.style.outline = 'none';
        canvas.focus();
      }
    }
    
    this.initStars();
    
    this.setupPhysicsCollisions();
    
    this.input.on('pointerdown', () => {
      if (!this.gameStarted && !this.gameOver) {
        this.soundManager.ensureAudioContext();
      }
    });
    
    // Handle resize events
    this.scale.on('resize', () => {
      this.updateGameSize();
    });
    
    // Handle window resize (for cases when Phaser scale doesn't fire)
    this.resizeHandler = () => {
      if (this.scale) {
        const newWidth = window.innerWidth;
        const newHeight = window.innerHeight;
        if (this.scale.width !== newWidth || this.scale.height !== newHeight) {
          this.scale.resize(newWidth, newHeight);
          this.updateGameSize();
        }
      }
    };
    
    // Handle visibility change (when window is minimized/restored)
    this.visibilityHandler = () => {
      if (!document.hidden && this.scale) {
        // Window was restored, update size
        setTimeout(() => {
          const newWidth = window.innerWidth;
          const newHeight = window.innerHeight;
          if (this.scale.width !== newWidth || this.scale.height !== newHeight) {
            this.scale.resize(newWidth, newHeight);
            this.updateGameSize();
          }
        }, 100);
      }
    };
    
    // Handle focus (when window regains focus)
    this.focusHandler = () => {
      if (this.scale) {
        setTimeout(() => {
          const newWidth = window.innerWidth;
          const newHeight = window.innerHeight;
          if (this.scale.width !== newWidth || this.scale.height !== newHeight) {
            this.scale.resize(newWidth, newHeight);
            this.updateGameSize();
          }
        }, 100);
      }
    };
    
    window.addEventListener('resize', this.resizeHandler);
    document.addEventListener('visibilitychange', this.visibilityHandler);
    window.addEventListener('focus', this.focusHandler);
    
    setGameSceneInstance(this);
    
    this.themeManager.setupSystemThemeListener(() => {
      this.applyTheme();
    });
  }
  
  setupPhysicsCollisions() {
    this.physics.add.overlap(this.bullets, this.boss, (bullet, boss) => {
      if (!this.isActive(bullet) || !this.isActive(boss) || boss.health <= 0) return;
      
      if (bullet._collisionProcessed) return;
      bullet._collisionProcessed = true;
      
      if (this.cheats.oneHitKill) {
        boss.health = 0;
      } else {
        boss.health--;
      }
      const bossHitColor = getParticleColor(this.themeManager, PARTICLE_TYPES.BOSS);
          this.createParticles(bullet.x, bullet.y, BOSS_HIT_PARTICLES_COUNT, bossHitColor, PARTICLE_TYPES.EXPLOSION);
      
      // Screen shake for boss hit
      this.addScreenShake(0.01, 60);
      
      if (boss.health <= 0) {
        this.soundManager.playSound(this.soundManager.soundTypes.BOSS_KILL);
      } else {
        this.soundManager.playSound(this.soundManager.soundTypes.BOSS_HIT);
      }
      
      if (boss.health <= 0) {
        const bossType = boss.type || BOSS_TYPES.FORTRESS;
        const bossConfig = BOSS_CONFIG[bossType];
        const livesReward = bossConfig.livesReward || 1;
        
        const bossKillColor = getParticleColor(this.themeManager, PARTICLE_TYPES.BOSS_KILL);
        this.createParticles(boss.x, boss.y, BOSS_KILL_PARTICLES_COUNT, bossKillColor, PARTICLE_TYPES.EXPLOSION);
        this.createParticles(boss.x, boss.y, BOSS_KILL_PARTICLES_COUNT_2, bossKillColor, PARTICLE_TYPES.EXPLOSION);
        
        // Strong screen effects for boss kill
        this.addScreenShake(0.025, 300); // Strong shake
        this.addScreenFlash(bossKillColor, 0.3, 300); // Flash with boss color
        const comboMultiplier = this.getComboMultiplier(this.combo);
        const points = Math.floor(60 * comboMultiplier);
        this.createFloatingText(boss.x, boss.y, `+${points}`, bossKillColor, FLOATING_TEXT_SIZES.LARGE);
        this.updateScoreWithHighScore(points, 10, false);
        this.kills++;
        this.lives = Math.min(this.lives + livesReward, 5);
        const lifeRewardColor = getParticleColor(this.themeManager, PARTICLE_TYPES.LIFE);
        this.createFloatingText(boss.x, boss.y - 15, `+${livesReward} LIFE${livesReward > 1 ? 'S' : ''}!`, lifeRewardColor, FLOATING_TEXT_SIZES.MEDIUM);
        this.lastBossScore = this.score + points;
        // Destroy boss properly - this will also clear boss bullets
        this.bossManager.destroyBoss();
        this.boss = null;
        this.bossPattern = 0;
      }
      
      this.removeFromContainer(bullet);
      bullet.destroy();
    });
    
    this.physics.add.overlap(this.player, this.obstacles, (player, obstacle) => {
      if (!this.isActive(player) || !this.isActive(obstacle) || this.isShieldActive || this.cheats.wallHack || this.cheats.godMode) return;
      
      const obstacleHitColor = getParticleColor(this.themeManager, PARTICLE_TYPES.EXPLOSION);
      this.createParticles(obstacle.x, obstacle.y, EXPLOSION_PARTICLES_COUNT, obstacleHitColor, PARTICLE_TYPES.EXPLOSION);
      this.addScreenShake(0.015, 100); // Small shake for obstacle hit
      this.handlePlayerDamage(obstacleHitColor);
      
      this.removeFromContainer(obstacle);
      obstacle.destroy();
    });
    
    this.physics.add.overlap(this.player, this.energies, (player, energy) => {
      if (!this.isActive(player) || !this.isActive(energy)) return;
      
      this.soundManager.playSound(this.soundManager.soundTypes.PICKUP);
      this.updateScoreWithHighScore(10, 0, true);
      const energyColor = getColor(this.themeManager, COLOR_PATHS.ENERGY.MAIN);
      this.createParticles(energy.x, energy.y, ENERGY_PARTICLES_COUNT, energyColor, PARTICLE_TYPES.EXPLOSION);
      this.createFloatingText(energy.x, energy.y, '+10', energyColor, FLOATING_TEXT_SIZES.SMALL);
      
      this.removeFromContainer(energy);
      energy.destroy();
    });
    
    this.physics.add.overlap(this.player, this.powerups, (player, powerup) => {
      if (!this.isActive(player) || !this.isActive(powerup)) return;
      
      this.activatePowerup(powerup);
      
      this.removeFromContainer(powerup);
      powerup.destroy();
    });
    
    this.physics.add.overlap(this.player, this.bossBullets, (player, bullet) => {
      if (!this.isActive(player) || !this.isActive(bullet) || this.isShieldActive || this.cheats.wallHack || this.cheats.godMode) return;
      
      const bossBulletHitColor = getParticleColor(this.themeManager, PARTICLE_TYPES.HYPERSPEED);
      this.createParticles(player.x, player.y, EXPLOSION_PARTICLES_COUNT, bossBulletHitColor, PARTICLE_TYPES.EXPLOSION);
      this.handlePlayerDamage(bossBulletHitColor);
      
      this.removeFromContainer(bullet);
      bullet.destroy();
    });
    
    this.physics.add.overlap(this.player, this.boss, (player, boss) => {
      if (!this.isActive(player) || !this.isActive(boss) || this.isShieldActive || this.cheats.wallHack || this.cheats.godMode) return;
      
      const bossHitColor = getParticleColor(this.themeManager, PARTICLE_TYPES.EXPLOSION);
      this.handlePlayerDamage(bossHitColor);
    });
  }
  
  updateGameSize() {
    const oldWidth = this.gameWidth;
    const oldHeight = this.gameHeight;
    
    if (this.scale) {
      this.gameWidth = this.scale.width;
      this.gameHeight = this.scale.height;
    } else {
      this.gameWidth = window.innerWidth;
      this.gameHeight = window.innerHeight;
    }
    
    if (this.baseWidth && this.baseHeight) {
      this.fontScale = Math.min(this.gameWidth / this.baseWidth, this.gameHeight / this.baseHeight);
    }
    
    if (this.physics && this.physics.world) {
      this.physics.world.setBounds(0, 0, this.gameWidth, this.gameHeight);
    }
    
    if (this.player) {
      this.player.x = Math.min(this.player.x, this.gameWidth - PLAYER_SIZE);
      this.player.y = Math.min(this.player.y, this.gameHeight - PLAYER_SIZE);
      this.player.x = Math.max(this.player.x, PLAYER_SIZE);
      this.player.y = Math.max(this.player.y, PLAYER_SIZE);
      this.syncPhysicsBody(this.player);
    }
    
    if (this.boss && this.isActive(this.boss)) {
      this.boss.x = Math.min(this.boss.x, this.gameWidth);
      this.boss.y = Math.min(this.boss.y, this.gameHeight - (this.boss.size || 50) / 2);
      this.boss.y = Math.max(this.boss.y, (this.boss.size || 50) / 2);
      this.syncPhysicsBody(this.boss);
    }
    
    const obstacles = this.getCachedChildren('obstacles');
    const obstaclesLength = obstacles.length;
    for (let i = 0; i < obstaclesLength; i++) {
      const obstacle = obstacles[i];
      if (this.isActive(obstacle)) {
        if (obstacle.x > this.gameWidth + 100 || obstacle.x < -100 || 
            obstacle.y > this.gameHeight + 100 || obstacle.y < -100) {
          this.removeFromContainer(obstacle);
          obstacle.destroy();
        }
      }
    }
    
    const energies = this.getCachedChildren('energies');
    const energiesLength = energies.length;
    for (let i = 0; i < energiesLength; i++) {
      const energy = energies[i];
      if (this.isActive(energy)) {
        if (energy.x > this.gameWidth + 100 || energy.x < -100 || 
            energy.y > this.gameHeight + 100 || energy.y < -100) {
          this.removeFromContainer(energy);
          energy.destroy();
        }
      }
    }
    
    const powerups = this.getCachedChildren('powerups');
    const powerupsLength = powerups.length;
    for (let i = 0; i < powerupsLength; i++) {
      const powerup = powerups[i];
      if (this.isActive(powerup)) {
        if (powerup.x > this.gameWidth + 100 || powerup.x < -100 || 
            powerup.y > this.gameHeight + 100 || powerup.y < -100) {
          this.removeFromContainer(powerup);
          powerup.destroy();
        }
      }
    }
    
    this.cachedChildren.obstacles = null;
    this.cachedChildren.energies = null;
    this.cachedChildren.powerups = null;
    
    // Update starfield
    if (this.starManager) {
      this.starManager.initialize(this.gameWidth, this.gameHeight);
    }
  }
  
  getFontSize(baseSize) {
    return Math.max(6, Math.round(baseSize * this.fontScale));
  }
  
  applyTheme() {
    this.bgColor = getColor(this.themeManager, COLOR_PATHS.BACKGROUND);
    this.cameras.main.setBackgroundColor(this.bgColor);
    
    this.stars = [];
    this.initStars();
    
    if (this.uiText) {
      this.uiText.setColor(colorToHex(getColor(this.themeManager, COLOR_PATHS.UI.SCORE)));
    }
    if (this.comboText) {
      this.comboText.setColor(colorToHex(getColor(this.themeManager, COLOR_PATHS.UI.COMBO)));
    }
    if (this.powerupText) {
      this.powerupText.setColor(colorToHex(getColor(this.themeManager, COLOR_PATHS.UI.POWERUP)));
    }
    
    this.drawPlayer(this.player);
  }
  
  initStars() {
    if (this.starManager) {
      this.starManager.initialize(this.gameWidth, this.gameHeight);
    }
  }
  
  toggleFullscreen() {
    const container = document.getElementById('game-container');
    if (!document.fullscreenElement) {
      container.requestFullscreen().then(() => {
        setTimeout(() => {
          this.updateGameSize();
          this.scale.resize(this.gameWidth, this.gameHeight);
        }, 100);
      });
    } else {
      document.exitFullscreen().then(() => {
        this.updateGameSize();
        this.scale.resize(this.gameWidth, this.gameHeight);
      });
    }
  }
  
  update() {
    // Sound toggle is now handled in the keydown event listener
    
    if (!this.gameStarted && !this.gameOver) {
      if ((this.cursors && (Phaser.Input.Keyboard.JustDown(this.cursors.up) || 
          Phaser.Input.Keyboard.JustDown(this.cursors.down) || 
          Phaser.Input.Keyboard.JustDown(this.cursors.left) || 
          Phaser.Input.Keyboard.JustDown(this.cursors.right))) || 
          (this.spaceKey && Phaser.Input.Keyboard.JustDown(this.spaceKey)) || 
          (this.pKey && Phaser.Input.Keyboard.JustDown(this.pKey)) || 
          (this.escKey && Phaser.Input.Keyboard.JustDown(this.escKey))) {
        this.soundManager.ensureAudioContext();
        this.gameStarted = true;
      }
      this.drawGame();
      return;
    }
    
    if (this.gameOver) {
      if (this.spaceKey && Phaser.Input.Keyboard.JustDown(this.spaceKey) && !this.spaceKeyWasPressed) {
        this.spaceKeyWasPressed = true;
        this.resetGame();
      }
      this.drawGame();
      return;
    }
    
    if ((this.pKey && Phaser.Input.Keyboard.JustDown(this.pKey)) || (this.escKey && Phaser.Input.Keyboard.JustDown(this.escKey))) {
      this.isPaused = !this.isPaused;
      if (this.isPaused) {
        this.cheatInput = '';
      }
    }
    
    if (this.isPaused) {
      this.drawGame();
      return;
    }
    
    this.frameCount++;
    
    // Record frame time for performance monitoring
    if (this.performanceManager) {
      this.performanceManager.recordFrame(this.time.now);
    }
    
    this.updateGame();
    this.drawGame();
  }
  
  calculateLevel(score) {
    if (score < 0) return 1;
    
    let level = 1;
    let requiredScore = 0;
    
    while (score >= requiredScore) {
      level++;
      requiredScore = this.getScoreForLevel(level);
    }
    
    return level - 1;
  }
  
  getScoreForLevel(level) {
    if (level <= 1) return 0;
    if (level <= 3) {
      return 100 * Math.pow(level - 1, 2.5);
    }
    if (level <= 6) {
      const baseScore = 100 * Math.pow(2, 2.5);
      const additionalLevels = level - 3;
      return baseScore + 500 * Math.pow(additionalLevels, 3);
    }
    if (level <= 10) {
      const baseScore = this.getScoreForLevel(6);
      const additionalLevels = level - 6;
      return baseScore + 1500 * Math.pow(additionalLevels, 3.5);
    }
    if (level <= 15) {
      const baseScore = this.getScoreForLevel(10);
      const additionalLevels = level - 10;
      return baseScore + 5000 * Math.pow(additionalLevels, 4);
    }
    if (level <= 20) {
      const baseScore = this.getScoreForLevel(15);
      const additionalLevels = level - 15;
      return baseScore + 20000 * Math.pow(additionalLevels, 4.5);
    }
    
    const baseScore = this.getScoreForLevel(20);
    const additionalLevels = level - 20;
    return baseScore + 100000 * Math.pow(additionalLevels, 5);
  }
  
  getComboMultiplier(combo) {
    if (combo <= 1) return 1;
    if (combo <= 5) {
      return combo;
    }
    if (combo <= 10) {
      const baseMultiplier = 5;
      const additionalCombo = combo - 5;
      return baseMultiplier + Math.pow(additionalCombo, 2);
    }
    if (combo <= 15) {
      const baseMultiplier = this.getComboMultiplier(10);
      const additionalCombo = combo - 10;
      return baseMultiplier + Math.pow(additionalCombo, 2.5) * 2;
    }
    if (combo <= 20) {
      const baseMultiplier = this.getComboMultiplier(15);
      const additionalCombo = combo - 15;
      return baseMultiplier + Math.pow(additionalCombo, 3) * 3;
    }
    
    const baseMultiplier = this.getComboMultiplier(20);
    const additionalCombo = combo - 20;
    return baseMultiplier + Math.pow(additionalCombo, 3.5) * 5;
  }
  
  getComboTimeout() {
    if (this.combo <= 1) {
      return COMBO_TIMEOUT;
    }
    if (this.combo <= 3) {
      return COMBO_TIMEOUT * 0.9;
    }
    if (this.combo <= 5) {
      return COMBO_TIMEOUT * 0.75;
    }
    if (this.combo <= 7) {
      return COMBO_TIMEOUT * 0.6;
    }
    return COMBO_TIMEOUT * 0.5;
  }
  
  getLevelProgress(score) {
    if (score < 0) return 0;
    
    const currentLevel = this.calculateLevel(score);
    const scoreForCurrentLevel = this.getScoreForLevel(currentLevel);
    const scoreForNextLevel = this.getScoreForLevel(currentLevel + 1);
    const scoreInCurrentLevel = score - scoreForCurrentLevel;
    const scoreNeededForNextLevel = scoreForNextLevel - scoreForCurrentLevel;
    
    if (scoreNeededForNextLevel <= 0) return 1;
    
    return Math.min(1, Math.max(0, scoreInCurrentLevel / scoreNeededForNextLevel));
  }
  
  getPlayerSpeed() {
    const baseSpeed = PLAYER_SPEED;
    const levelMultiplier = 1 + (this.level - 1) * 0.05;
    const maxLevelMultiplier = 1.5;
    const effectiveMultiplier = Math.min(levelMultiplier, maxLevelMultiplier);
    return baseSpeed * effectiveMultiplier * this.hyperspeedMultiplier;
  }
  
  getObstacleSpeedMultiplier() {
    return 1 + (this.level - 1) * 0.15;
  }
  
  getSpawnRateMultiplier() {
    return 1 + (this.level - 1) * 0.08;
  }
  
  updateGame() {
    this.updateHyperspeed();
    this.updateScreenEffects(); // Update screen effects (shake, flash)
    const speed = this.getPlayerSpeed();
    const newLevel = this.calculateLevel(this.score);
    if (newLevel !== this.level) {
      const prevLevel = this.level;
      this.level = newLevel;
      
      if (newLevel > prevLevel && newLevel > 1) {
        this.isHyperspeed = true;
        this.hyperspeedStartTime = this.time.now;
        this.hyperspeedEndTime = this.time.now + HYPERSPEED_DURATION;
        this.hyperspeedMultiplier = HYPERSPEED_MULTIPLIER;
        if (this.bulletManager) {
          this.bulletManager.setHyperspeed(true);
        }
      }
      
      this.soundManager.playSound(this.soundManager.soundTypes.LEVEL_UP);
      const levelColor = getParticleColor(this.themeManager, PARTICLE_TYPES.LEVEL);
      this.createParticles(this.gameWidth / 2, this.gameHeight / 2, LEVEL_UP_PARTICLES_COUNT, levelColor, PARTICLE_TYPES.EXPLOSION);
      this.createFloatingText(this.gameWidth / 2, this.gameHeight / 2, `LEVEL ${newLevel}!`, levelColor, FLOATING_TEXT_SIZES.XLARGE);
      
      // Screen effects for level up
      this.addScreenShake(0.015, 200);
      this.addScreenFlash(levelColor, 0.2, 250);
      
      // Emit level up event
      if (this.eventManager) {
        this.eventManager.emit(GAME_EVENTS.LEVEL_UP, { level: newLevel, prevLevel });
      }
    }
    
    const prevX = this.player.x;
    const prevY = this.player.y;
    
    const currentPlayerState = `${this.isHyperspeed}-${this.cheats.wallHack}`;
    if (currentPlayerState !== this.lastPlayerState) {
      this.playerDirty = true;
      this.lastPlayerState = currentPlayerState;
    }
    
    let newX = this.player.x;
    let newY = this.player.y;
    
    if (this.cursors) {
    if (this.cursors.up.isDown && this.player.y > PLAYER_SIZE) {
      newY -= speed;
    }
    if (this.cursors.down.isDown && this.player.y < this.gameHeight - PLAYER_SIZE) {
      newY += speed;
    }
    if (this.cursors.left.isDown && this.player.x > PLAYER_SIZE) {
      newX -= speed;
    }
    if (this.cursors.right.isDown && this.player.x < this.gameWidth - PLAYER_SIZE) {
      newX += speed;
      }
    }
    
      this.player.x = newX;
      this.player.y = newY;
    this.syncPhysicsBody(this.player);
    
    if (newX !== prevX || newY !== prevY) {
      this.playerDirty = true;
      this.playerRectDirty = true;
    }
    
    const moved = Math.abs(this.player.x - prevX) > 0.01 || Math.abs(this.player.y - prevY) > 0.01;
    if (moved) {
      const lastTrail = this.playerTrail[this.playerTrail.length - 1];
      if (!lastTrail || Math.abs(lastTrail.x - this.player.x) > 1 || Math.abs(lastTrail.y - this.player.y) > 1) {
        this.playerTrail.push({ x: this.player.x, y: this.player.y });
        if (this.playerTrail.length > 10) {
          this.playerTrail.shift();
        }
      }
    }
    
    const currentTime = this.time.now;
    const shootCooldown = this.isHyperspeed ? SHOOT_COOLDOWN / 2 : SHOOT_COOLDOWN;
    if (this.spaceKey && this.spaceKey.isDown && currentTime - this.lastShotTime >= shootCooldown) {
      this.lastShotTime = currentTime;
      const bulletSpeed = BULLET_SPEED * this.hyperspeedMultiplier;
      
      if (this.isTripleShot) {
        this.createBullet(this.player.x + PLAYER_SIZE / 2 + 6, this.player.y - 4, bulletSpeed);
        this.createBullet(this.player.x + PLAYER_SIZE / 2 + 6, this.player.y, bulletSpeed);
        this.createBullet(this.player.x + PLAYER_SIZE / 2 + 6, this.player.y + 4, bulletSpeed);
      } else {
        this.createBullet(this.player.x + PLAYER_SIZE / 2 + 6, this.player.y, bulletSpeed);
      }
      this.soundManager.playSound(this.soundManager.soundTypes.SHOOT);
    }
    
    // Optimized updates with frame skipping and performance adaptation
    const shouldUpdateAutoAim = this.updateManager.shouldUpdate('autoAim', this.frameCount) &&
      (!this.performanceManager || !this.performanceManager.shouldSkipUpdate('autoAim', this.frameCount));
    
    if (shouldUpdateAutoAim) {
      if (this.isAutoAimActive) {
        this.updateAutoAimTargets();
        this.drawAutoAimVisualization();
      } else if (this.autoAimGraphics) {
        this.autoAimGraphics.clear();
      }
    }
    
    const shouldUpdateMagnet = this.updateManager.shouldUpdate('magnet', this.frameCount) &&
      (!this.performanceManager || !this.performanceManager.shouldSkipUpdate('magnet', this.frameCount));
    
    if (shouldUpdateMagnet) {
      if (this.isMagnetActive) {
        this.drawMagnetVisualization();
      } else if (this.magnetGraphics) {
        this.magnetGraphics.clear();
      }
    }
    
    this.updateBoss();
    this.updateBullets();
    this.updateObstacles();
    this.updateEnergies();
    this.updatePowerups();
    this.updateParticles();
    this.updateFloatingTexts();
    
    if (this.updateManager.shouldUpdate('stars', this.frameCount)) {
    this.updateStars();
    }
    
    this.updateTimers();
    this.spawnObstacles();
    this.spawnEnergies();
    this.spawnPowerups();
    
    // Process memory cleanup
    if (this.memoryManager) {
      this.memoryManager.processCleanup(this.time.now);
    }
    
    // Process event queue
    if (this.eventManager) {
      this.eventManager.processQueue();
    }
  }
  
  getPlayerRect() {
    if (this.playerRectDirty) {
      this.cachedPlayerRect.x = this.player.x - PLAYER_SIZE / 2;
      this.cachedPlayerRect.y = this.player.y - PLAYER_SIZE / 2;
      this.cachedPlayerRect.width = PLAYER_SIZE;
      this.cachedPlayerRect.height = PLAYER_SIZE;
      this.playerRectDirty = false;
    }
    return this.cachedPlayerRect;
  }
  
  getCachedChildren(groupName) {
    if (!this.cachedChildren) {
      this.cachedChildren = {
        particles: null,
        obstacles: null,
        bullets: null,
        bossBullets: null,
        energies: null,
        powerups: null
      };
      this.childrenCacheTime = 0;
      if (!this.childrenCacheInterval) {
        this.childrenCacheInterval = 16;
      }
    }
    
    if (!this.time) {
      return [];
    }
    
    const now = this.time.now;
    const cached = this.cachedChildren[groupName];
    if (cached == null || (now - this.childrenCacheTime) > this.childrenCacheInterval) {
      const group = this[groupName];
      if (group) {
        this.cachedChildren[groupName] = group.getChildren();
      } else {
        this.cachedChildren[groupName] = [];
      }
      this.childrenCacheTime = now;
    }
    return this.cachedChildren[groupName] || [];
  }
  
  syncPhysicsBody(gameObject) {
    if (gameObject && gameObject.body) {
      gameObject.body.updateFromGameObject();
      if (gameObject.parentContainer) {
        let worldX = gameObject.x;
        let worldY = gameObject.y;
        
        if (typeof gameObject.getWorldTransform === 'function') {
          const transform = gameObject.getWorldTransform();
          worldX = transform.tx;
          worldY = transform.ty;
        } else {
          let container = gameObject.parentContainer;
          while (container) {
            worldX += container.x || 0;
            worldY += container.y || 0;
            container = container.parentContainer;
          }
        }
        
        gameObject.body.x = worldX;
        gameObject.body.y = worldY;
      } else {
        gameObject.body.x = gameObject.x;
        gameObject.body.y = gameObject.y;
      }
    }
  }
  
  removeFromContainer(gameObject) {
    if (gameObject && gameObject.parentContainer === this.gameElementsContainer) {
      this.gameElementsContainer.remove(gameObject);
    }
  }
  
  setupPhysicsBody(gameObject, size) {
    this.physics.add.existing(gameObject);
    gameObject.body.setSize(size, size);
    gameObject.body.setOffset(-size / 2, -size / 2);
    gameObject.body.setCollideWorldBounds(false);
    gameObject.body.setImmovable(true);
    gameObject.body.setAllowGravity(false);
    gameObject.body.moves = false;
  }
  
  isActive(gameObject) {
    return gameObject && gameObject.active;
  }
  
  isOutOfBounds(obj, margin = 0) {
    return obj.x < -margin || obj.x > this.gameWidth + margin || 
           obj.y < -margin || obj.y > this.gameHeight + margin;
  }
  
  drawActiveObjects(groupName, drawFunction) {
    const objects = this.getCachedChildren(groupName);
    const length = objects.length;
    for (let i = 0; i < length; i++) {
      const obj = objects[i];
      if (this.isActive(obj)) {
        drawFunction(obj);
      }
    }
  }
  
  handlePlayerDamage(damageColor) {
    if (this.cheats.godMode || this.cheats.infiniteLives) {
      return;
    }
    const color = damageColor || getParticleColor(this.themeManager, PARTICLE_TYPES.EXPLOSION);
    this.soundManager.playSound(this.soundManager.soundTypes.DAMAGE);
    this.createParticles(this.player.x, this.player.y, DAMAGE_PARTICLES_COUNT, color, PARTICLE_TYPES.EXPLOSION);
    
    // Screen effects
    this.addScreenShake(0.02, 150); // Strong shake for damage
    this.addScreenFlash(color, 0.4, 200); // Red flash
    
    if (!this.cheats.infiniteLives) {
      this.lives--;
    }
    if (this.lives <= 0) {
      this.gameOver = true;
    } else {
      this.createFloatingText(this.player.x, this.player.y, `-1 LIFE`, color, FLOATING_TEXT_SIZES.LARGE);
    }
  }
  
  addScreenShake(intensity, duration) {
    this.cameraShakeIntensity = Math.max(this.cameraShakeIntensity, intensity);
    this.cameraShakeDuration = Math.max(this.cameraShakeDuration, duration);
  }
  
  addScreenFlash(color, alpha, duration) {
    if (!this.screenFlashGraphics) return;
    this.screenFlashAlpha = Math.max(this.screenFlashAlpha, alpha);
    this.screenFlashColor = color;
    this.screenFlashDuration = duration;
    this.screenFlashStartTime = this.time.now;
  }
  
  updateScreenEffects() {
    // Update camera shake - using container position for shake effect
    if (this.cameraShakeDuration > 0) {
      const shakeX = (Math.random() - 0.5) * this.cameraShakeIntensity * this.gameWidth;
      const shakeY = (Math.random() - 0.5) * this.cameraShakeIntensity * this.gameHeight;
      
      // Apply shake by moving game elements container
      if (this.gameElementsContainer) {
        // Store original position on first shake
        if (this.cameraShakeOriginalX === undefined) {
          this.cameraShakeOriginalX = this.gameElementsContainer.x;
          this.cameraShakeOriginalY = this.gameElementsContainer.y;
        }
        this.gameElementsContainer.setPosition(
          this.cameraShakeOriginalX + shakeX,
          this.cameraShakeOriginalY + shakeY
        );
      }
      
      this.cameraShakeDuration -= this.game.loop.delta;
      if (this.cameraShakeDuration <= 0) {
        this.cameraShakeIntensity = 0;
        // Reset container position
        if (this.gameElementsContainer && this.cameraShakeOriginalX !== undefined) {
          this.gameElementsContainer.setPosition(
            this.cameraShakeOriginalX,
            this.cameraShakeOriginalY
          );
          this.cameraShakeOriginalX = undefined;
          this.cameraShakeOriginalY = undefined;
        }
      }
    }
    
    // Update screen flash
    if (this.screenFlashAlpha > 0 && this.screenFlashGraphics) {
      const elapsed = this.time.now - this.screenFlashStartTime;
      const progress = Math.min(elapsed / this.screenFlashDuration, 1);
      const currentAlpha = this.screenFlashAlpha * (1 - progress);
      
      this.screenFlashGraphics.clear();
      this.screenFlashGraphics.fillStyle(this.screenFlashColor || 0xff0000, currentAlpha);
      this.screenFlashGraphics.fillRect(0, 0, this.gameWidth, this.gameHeight);
      
      if (progress >= 1) {
        this.screenFlashAlpha = 0;
        this.screenFlashGraphics.clear();
      }
    }
    
  }
  
  updateHyperspeed() {
    if (!this.isHyperspeed) {
      this.hyperspeedMultiplier = 1;
      return;
    }
    
    const currentTime = this.time.now;
    const elapsed = currentTime - this.hyperspeedStartTime;
    const remaining = this.hyperspeedEndTime - currentTime;
    const totalDuration = this.hyperspeedEndTime - this.hyperspeedStartTime;
    
    if (remaining <= 0) {
      this.isHyperspeed = false;
      this.hyperspeedMultiplier = 1;
      if (this.bulletManager) {
        this.bulletManager.setHyperspeed(false);
      }
      return;
    }
    
    const ACCELERATION_PHASE = 200;
    const DECELERATION_START = 500;
    
    if (elapsed < ACCELERATION_PHASE) {
      const accelerationProgress = elapsed / ACCELERATION_PHASE;
      this.hyperspeedMultiplier = 1 + (HYPERSPEED_MULTIPLIER - 1) * accelerationProgress;
    } else if (elapsed < DECELERATION_START) {
      this.hyperspeedMultiplier = HYPERSPEED_MULTIPLIER;
    } else {
      const decelerationProgress = (currentTime - (this.hyperspeedStartTime + DECELERATION_START)) / (totalDuration - DECELERATION_START);
      const decelerationProgressClamped = Math.min(1, Math.max(0, decelerationProgress));
      this.hyperspeedMultiplier = HYPERSPEED_MULTIPLIER - (HYPERSPEED_MULTIPLIER - 1) * decelerationProgressClamped;
    }
  }
  
  getRemainingSeconds(isActive, endTime) {
    if (!isActive || !endTime) return 0;
    const remaining = endTime - this.time.now;
    return Math.max(0, Math.ceil(remaining / 1000));
  }
  
  getHyperspeedRemainingSeconds() {
    return this.getRemainingSeconds(this.isHyperspeed, this.hyperspeedEndTime);
  }
  
  getAutoAimRemainingSeconds() {
    return this.getRemainingSeconds(this.isAutoAimActive, this.autoAimEndTime);
  }
  
  getMagnetRemainingSeconds() {
    return this.getRemainingSeconds(this.isMagnetActive, this.magnetEndTime);
  }
  
  getSlowMotionRemainingSeconds() {
    return this.getRemainingSeconds(this.isSlowMotionActive, this.slowMotionEndTime);
  }
  
  
  updateScoreWithHighScore(points, flashDuration = 8, checkHyperspeed = true) {
    const prevScore = this.score;
    this.score += points;
    
    // Emit score update event
    if (this.eventManager) {
      this.eventManager.emit(GAME_EVENTS.SCORE_UPDATE, { 
        score: this.score, 
        prevScore, 
        points,
        highScore: this.highScore
      });
    }
    if (this.score > this.highScore) {
      this.highScore = this.score;
      saveHighScore(this.highScore);
    }
    if (checkHyperspeed) {
      const prevLevel = this.calculateLevel(this.score - points);
      const newLevel = this.calculateLevel(this.score);
      if (newLevel > prevLevel && newLevel > 1) {
        this.isHyperspeed = true;
        this.hyperspeedStartTime = this.time.now;
        this.hyperspeedEndTime = this.time.now + HYPERSPEED_DURATION;
        this.hyperspeedMultiplier = HYPERSPEED_MULTIPLIER;
        if (this.bulletManager) {
          this.bulletManager.setHyperspeed(true);
        }
      }
    }
    this.scoreFlash = flashDuration;
  }
  
  createBossBullet(bossX, bossY, targetX, targetY, bulletSpeed, angle = null) {
    // Boss bullets fly straight left with slight random vertical variation
    // They don't aim at the player - just fly in a general leftward direction
    // If angle is provided, use that instead of random angle
    const bullet = this.add.graphics();
    this.setupPhysicsBody(bullet, BULLET_SIZE);
    bullet.x = bossX;
    bullet.y = bossY;
    
    // Use provided angle or random angle (-0.2 to 0.2 radians)
    const bulletAngle = angle !== null ? angle : (Math.random() - 0.5) * 0.4;
    bullet.baseVx = -bulletSpeed * Math.cos(bulletAngle);
    bullet.baseVy = bulletSpeed * Math.sin(bulletAngle);
    bullet.vx = bullet.baseVx;
    bullet.vy = bullet.baseVy;
    
    bullet.isBossBullet = true;
    this.bossBullets.add(bullet);
    this.gameElementsContainer.add(bullet);
    this.syncPhysicsBody(bullet);
    return bullet;
  }
  
  activatePowerup(powerup) {
    const { x, y, type } = powerup;
    this.soundManager.playSound(this.soundManager.soundTypes.POWERUP);
    
    const powerupConfigs = {
      [POWERUP_TYPES.RAPID]: {
        activate: () => {
          this.isHyperspeed = true;
          this.hyperspeedStartTime = this.time.now;
          this.hyperspeedEndTime = this.time.now + (this.cheats.infinitePowerups ? INFINITE_DURATION : HYPERSPEED_DURATION);
          this.hyperspeedMultiplier = HYPERSPEED_MULTIPLIER;
          if (this.bulletManager) {
            this.bulletManager.setHyperspeed(true);
          }
        },
        particleType: PARTICLE_TYPES.HYPERSPEED,
        text: 'HYPERSPEED!'
      },
      [POWERUP_TYPES.TRIPLE]: {
        activate: () => {
      this.isTripleShot = true;
          this.tripleShotEndTime = this.time.now + (this.cheats.infinitePowerups ? INFINITE_DURATION : TRIPLE_SHOT_DURATION);
        },
        particleType: PARTICLE_TYPES.TRIPLE,
        text: 'TRIPLE!'
      },
      [POWERUP_TYPES.SHIELD]: {
        activate: () => {
      this.isShieldActive = true;
          this.shieldEndTime = this.time.now + (this.cheats.infinitePowerups ? INFINITE_DURATION : SHIELD_DURATION);
        },
        particleType: PARTICLE_TYPES.SHIELD,
        text: 'SHIELD!'
      },
      [POWERUP_TYPES.AUTO_AIM]: {
        activate: () => {
          this.isAutoAimActive = true;
          this.autoAimEndTime = this.time.now + (this.cheats.infinitePowerups ? INFINITE_DURATION : AUTO_AIM_DURATION);
        },
        particleType: PARTICLE_TYPES.AUTO_AIM,
        text: 'AUTO AIM!'
      },
      [POWERUP_TYPES.LIFE]: {
        activate: () => {
          this.lives = this.cheats.infiniteLives ? 5 : Math.min(this.lives + 1, 5);
        },
        particleType: PARTICLE_TYPES.LIFE,
        text: '+1 LIFE!'
      },
      [POWERUP_TYPES.MAGNET]: {
        activate: () => {
          this.isMagnetActive = true;
          this.magnetEndTime = this.time.now + (this.cheats.infinitePowerups ? INFINITE_DURATION : MAGNET_DURATION);
        },
        particleType: PARTICLE_TYPES.MAGNET,
        text: 'MAGNET!'
      },
      [POWERUP_TYPES.SLOW_MOTION]: {
        activate: () => {
          this.isSlowMotionActive = true;
          this.slowMotionEndTime = this.time.now + (this.cheats.infinitePowerups ? INFINITE_DURATION : SLOW_MOTION_DURATION);
        },
        particleType: PARTICLE_TYPES.SLOW_MOTION,
        text: 'SLOW MOTION!'
      }
    };
    
    const config = powerupConfigs[type];
    if (config) {
      config.activate();
      const color = getParticleColor(this.themeManager, config.particleType);
      this.createParticles(x, y, POWERUP_PARTICLES_COUNT, color, PARTICLE_TYPES.EXPLOSION);
      this.createFloatingText(x, y, config.text, color, POWERUP_TEXT_SIZE);
    }
  }
  
  createBullet(x, y, speed) {
    const bullet = this.add.graphics();
    this.setupPhysicsBody(bullet, BULLET_SIZE);
    bullet.x = x;
    bullet.y = y;
    bullet.speed = speed;
    bullet.baseSpeed = speed; // Store original speed for slow motion
    bullet.isBossBullet = false;
    bullet.active = true; // Ensure bullet is active
    bullet.visible = true; // Ensure bullet is visible
    bullet._collisionProcessed = false;
    bullet.vx = speed;
    bullet.vy = 0;
    bullet.hasTarget = false;
    
    if (this.isAutoAimActive) {
      const target = this.findNearestTarget(x, y);
      if (target) {
        bullet.targetX = target.x;
        bullet.targetY = target.y;
        bullet.hasTarget = true;
        
        // Calculate normalized direction vector
        const dx = target.x - x;
        const dy = target.y - y;
        const distanceSq = dx * dx + dy * dy;
        
        if (distanceSq > 0) {
          const invDistance = 1 / Math.sqrt(distanceSq);
          bullet.baseVx = dx * invDistance * speed;
          bullet.baseVy = dy * invDistance * speed;
          bullet.vx = bullet.baseVx;
          bullet.vy = bullet.baseVy;
        }
      }
    }
    
    this.bullets.add(bullet);
    this.gameElementsContainer.add(bullet);
    this.syncPhysicsBody(bullet);
  }
  
  updateAutoAimTargets() {
    const now = this.time.now;
    const CACHE_DURATION = 100; // Update cache every 100ms for better performance
    
    // Skip if cache is still valid
    if (now - this.autoAimTargetsCacheTime < CACHE_DURATION) {
      return;
    }
    
    // Clear previous targets
    this.autoAimTargets = [];
    
    const playerX = this.player.x;
    const playerY = this.player.y;
    const MAX_TARGET_DISTANCE = 800; // Increased range for better targeting
    const MAX_TARGET_DISTANCE_SQ = MAX_TARGET_DISTANCE * MAX_TARGET_DISTANCE;
    
    // Add boss as priority target
    if (this.boss && this.boss.health > 0 && this.boss.x > playerX) {
      const dx = this.boss.x - playerX;
      const dy = this.boss.y - playerY;
      const distanceSq = dx * dx + dy * dy;
      
      if (distanceSq <= MAX_TARGET_DISTANCE_SQ) {
        this.autoAimTargets.push({
          x: this.boss.x,
          y: this.boss.y,
          distanceSq: distanceSq,
          priority: 1, // Boss has highest priority
          type: 'boss',
          size: this.boss.size || 40 // For collision prediction
        });
      }
    }
    
    // Add obstacles (enemies)
    const obstacles = this.getCachedChildren('obstacles');
    const obstaclesLength = obstacles.length;
    
    for (let i = 0; i < obstaclesLength; i++) {
      const obstacle = obstacles[i];
      if (!this.isActive(obstacle)) continue;
      if (obstacle.x <= playerX) continue; // Only targets ahead
      
      const dx = obstacle.x - playerX;
      const dy = obstacle.y - playerY;
      const distanceSq = dx * dx + dy * dy;
      
      if (distanceSq <= MAX_TARGET_DISTANCE_SQ) {
        // Priority based on distance and type
        let priority = 2;
        if (obstacle.type === OBSTACLE_TYPES.FAST_ENEMY) {
          priority = 1.5; // Fast enemies are higher priority
        } else if (obstacle.type === OBSTACLE_TYPES.BIG_ENEMY) {
          priority = 2.5; // Big enemies are lower priority
        }
        
        this.autoAimTargets.push({
          x: obstacle.x,
          y: obstacle.y,
          distanceSq: distanceSq,
          priority: priority,
          type: 'obstacle',
          size: obstacle.size || 15
        });
      }
    }
    
    // Sort by priority first, then by distance
    this.autoAimTargets.sort((a, b) => {
      if (a.priority !== b.priority) {
        return a.priority - b.priority;
      }
      return a.distanceSq - b.distanceSq;
    });
    
    this.autoAimTargetsCacheTime = now;
  }
  
  findNearestTarget(bulletX, bulletY) {
    if (!this.isAutoAimActive || this.autoAimTargets.length === 0) {
      return null;
    }
    
    // Find the best target for the bullet
    // Consider targets that are ahead of the bullet and within reasonable range
    let bestTarget = null;
    let bestScore = Infinity;
    const MAX_BULLET_TARGET_DISTANCE_SQ = 1000000; // 1000^2 - very large range
    
    for (let i = 0; i < this.autoAimTargets.length; i++) {
      const target = this.autoAimTargets[i];
      
      // Only consider targets ahead of bullet
      if (target.x <= bulletX) continue;
      
      const dx = target.x - bulletX;
      const dy = target.y - bulletY;
      const distanceSq = dx * dx + dy * dy;
      
      // Skip if too far
      if (distanceSq > MAX_BULLET_TARGET_DISTANCE_SQ) continue;
      
      // Calculate score: lower is better
      // Score = distance * priority multiplier
      const score = distanceSq * target.priority;
      
      if (score < bestScore) {
        bestScore = score;
        bestTarget = {
          x: target.x,
          y: target.y,
          distanceSq: distanceSq
        };
      }
    }
    
    return bestTarget;
  }
  
  drawAutoAimVisualization() {
    if (!this.isAutoAimActive || !this.autoAimGraphics) {
      return;
    }
    
    this.autoAimGraphics.clear();
    
    if (this.autoAimTargets.length === 0) {
      return;
    }
    
    const autoAimColor = getParticleColor(this.themeManager, PARTICLE_TYPES.AUTO_AIM);
    const autoAimLightColor = getPowerupColor(this.themeManager, 'autoAim', 'light') || autoAimColor;
    const playerX = this.player.x;
    const playerY = this.player.y;
    const time = this.time.now;
    
    // Анимация для эффекта пульсации
    const pulsePhase = (time % 1000) / 1000;
    const pulseAlpha = 0.5 + Math.sin(pulsePhase * Math.PI * 2) * 0.3;
    
    // Рисуем линии-стрелки к целям (максимум 3 ближайшие)
    const maxTargets = Math.min(3, this.autoAimTargets.length);
    for (let i = 0; i < maxTargets; i++) {
      const target = this.autoAimTargets[i];
      if (target.x <= playerX) continue;
      
      const priority = 1 - (i / maxTargets);
      const alpha = 0.6 + priority * 0.4;
      const lineWidth = 1.5 + priority * 0.5;
      
      const dx = target.x - playerX;
      const dy = target.y - playerY;
      // Calculate distance from cached distanceSq or compute it
      const distance = target.distanceSq ? Math.sqrt(target.distanceSq) : Math.sqrt(dx * dx + dy * dy);
      
      // Нормализуем вектор направления
      const invDistance = 1 / distance;
      const dirX = dx * invDistance;
      const dirY = dy * invDistance;
      
      // Рисуем сплошную линию-стрелку от игрока к цели
      this.autoAimGraphics.lineStyle(lineWidth, autoAimColor, alpha);
      this.autoAimGraphics.moveTo(playerX, playerY);
      this.autoAimGraphics.lineTo(target.x, target.y);
      
      // Рисуем стрелку на конце линии (треугольник)
      const arrowSize = 4 + priority * 2;
      const arrowX = target.x - dirX * arrowSize;
      const arrowY = target.y - dirY * arrowSize;
      const perpX = -dirY * arrowSize * 0.6;
      const perpY = dirX * arrowSize * 0.6;
      
      // Draw triangle arrow using fillTriangle
      this.autoAimGraphics.fillStyle(autoAimColor, alpha);
      this.autoAimGraphics.fillTriangle(
        target.x, target.y,
        arrowX + perpX, arrowY + perpY,
        arrowX - perpX, arrowY - perpY
      );
      
      // Рисуем КРЕСТ (перекрестие) на цели вместо круга
      const crossSize = i === 0 ? 8 + Math.sin(pulsePhase * Math.PI * 2) * 2 : 6;
      const crossThickness = 1.5;
      
      // Горизонтальная линия креста
      this.autoAimGraphics.lineStyle(crossThickness, autoAimLightColor, pulseAlpha);
      this.autoAimGraphics.moveTo(target.x - crossSize, target.y);
      this.autoAimGraphics.lineTo(target.x + crossSize, target.y);
      
      // Вертикальная линия креста
      this.autoAimGraphics.moveTo(target.x, target.y - crossSize);
      this.autoAimGraphics.lineTo(target.x, target.y + crossSize);
      
      // Внешний круг для главной цели (опционально)
      if (i === 0) {
        this.autoAimGraphics.lineStyle(1, autoAimColor, pulseAlpha * 0.5);
        this.autoAimGraphics.strokeCircle(target.x, target.y, crossSize + 3);
      }
      
      // Центральная точка
      this.autoAimGraphics.fillStyle(autoAimLightColor, alpha);
      this.autoAimGraphics.fillCircle(target.x, target.y, 1.5);
    }
  }
  
  createParticles(x, y, count, color, type = PARTICLE_TYPES.NORMAL) {
    if (this.particleManager) {
      this.particleManager.createParticles(x, y, count, color, type);
    }
  }
  
  createFloatingText(x, y, text, color, size = 8) {
    if (this.floatingTextManager) {
      this.floatingTextManager.createFloatingText(x, y, text, color, size, this.fontScale);
    }
  }
  
  shouldRedraw(graphics, x, y) {
    if (graphics.lastDrawnX !== undefined && 
        Math.abs(graphics.lastDrawnX - x) < 0.5 && 
        Math.abs(graphics.lastDrawnY - y) < 0.5) {
      return false;
    }
    graphics.clear();
    graphics.lastDrawnX = x;
    graphics.lastDrawnY = y;
    return true;
  }
  
  drawAsteroid(graphics, x, y, size) {
    if (!this.shouldRedraw(graphics, x, y)) return;
    const centerX = 0;
    const centerY = 0;
    const r = Math.floor(size / 2);
    const outerColor = getColor(this.themeManager, COLOR_PATHS.ASTEROID.OUTER);
    const middleColor = getColor(this.themeManager, COLOR_PATHS.ASTEROID.MIDDLE);
    const innerColor = getColor(this.themeManager, COLOR_PATHS.ASTEROID.INNER);
    const highlightColor = getColor(this.themeManager, COLOR_PATHS.ASTEROID.HIGHLIGHT);
    
    const rSq = getRadiusSq(r);
    const rMinus2Sq = getRadiusSq(r - 2);
    const rMinus3Sq = getRadiusSq(r - 3);
    
    graphics.fillStyle(outerColor);
    for (let dy = -r; dy <= r; dy++) {
      for (let dx = -r; dx <= r; dx++) {
        if (isInRingSq(dx, dy, rMinus2Sq, rSq)) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }
    
    graphics.fillStyle(middleColor);
    for (let dy = -r + 2; dy <= r - 2; dy++) {
      for (let dx = -r + 2; dx <= r - 2; dx++) {
        if (isInRingSq(dx, dy, rMinus3Sq, rMinus2Sq)) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }
    
    graphics.fillStyle(innerColor);
    drawPixel(graphics, centerX - 2, centerY - 2, 1);
    drawPixel(graphics, centerX + 2, centerY + 2, 1);
    drawPixel(graphics, centerX + 1, centerY - 1, 1);
    drawPixel(graphics, centerX - 1, centerY + 1, 1);
    drawPixel(graphics, centerX - 2, centerY + 1, 1);
    drawPixel(graphics, centerX + 1, centerY + 2, 1);
    
    graphics.fillStyle(highlightColor);
    drawPixel(graphics, centerX, centerY - 1, 1);
    drawPixel(graphics, centerX - 1, centerY, 1);
  }
  
  drawComet(graphics, x, y, size) {
    if (!this.shouldRedraw(graphics, x, y)) return;
    const centerX = 0;
    const centerY = 0;
    const r = Math.floor(size / 2);
    const mainColor = getColor(this.themeManager, COLOR_PATHS.COMET.MAIN);
    const coreColor = getColor(this.themeManager, COLOR_PATHS.COMET.CORE);
    const trailColor = getColor(this.themeManager, COLOR_PATHS.COMET.TRAIL);
    const trailBrightColor = getColor(this.themeManager, COLOR_PATHS.COMET.TRAIL_BRIGHT);
    
    const rSq = getRadiusSq(r);
    
    graphics.fillStyle(mainColor);
    for (let dy = -r; dy <= r; dy++) {
      for (let dx = -r; dx <= r; dx++) {
        if (isInCircleSq(dx, dy, rSq)) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }
    
    graphics.fillStyle(coreColor);
    drawPixel(graphics, centerX, centerY, 1);
    drawPixel(graphics, centerX - 1, centerY, 1);
    drawPixel(graphics, centerX + 1, centerY, 1);
    drawPixel(graphics, centerX, centerY - 1, 1);
    drawPixel(graphics, centerX, centerY + 1, 1);
    
    graphics.fillStyle(trailColor);
    for (let i = 2; i <= 8; i++) {
      const intensity = 1 - (i - 2) / 6;
      graphics.setAlpha(intensity);
      drawPixel(graphics, centerX - r - i, centerY, 1);
      if (i % 2 === 0) {
        drawPixel(graphics, centerX - r - i, centerY - 1, 1);
        drawPixel(graphics, centerX - r - i, centerY + 1, 1);
      }
      if (i <= 4) {
        drawPixel(graphics, centerX - r - i, centerY - 2, 1);
        drawPixel(graphics, centerX - r - i, centerY + 2, 1);
      }
    }
    graphics.setAlpha(1);
    
    graphics.fillStyle(trailBrightColor);
    drawPixel(graphics, centerX - r - 2, centerY, 1);
    drawPixel(graphics, centerX - r - 3, centerY, 1);
  }
  
  drawFastEnemy(graphics, x, y, size) {
    if (!this.shouldRedraw(graphics, x, y)) return;
    const centerX = 0;
    const centerY = 0;
    const r = Math.floor(size / 2);
    const mainColor = getColor(this.themeManager, COLOR_PATHS.FAST_ENEMY.MAIN);
    const accentColor = getColor(this.themeManager, COLOR_PATHS.FAST_ENEMY.ACCENT);
    const coreColor = getColor(this.themeManager, COLOR_PATHS.FAST_ENEMY.CORE);
    const darkColor = getColor(this.themeManager, COLOR_PATHS.FAST_ENEMY.DARK);
    const eyesColor = getColor(this.themeManager, COLOR_PATHS.FAST_ENEMY.EYES);
    
    const rSq = getRadiusSq(r);
    
    graphics.fillStyle(mainColor);
    for (let dy = -r; dy <= r; dy++) {
      for (let dx = -r; dx <= r; dx++) {
        if (isInCircleSq(dx, dy, rSq)) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }
    
    graphics.fillStyle(accentColor);
    drawPixel(graphics, centerX, centerY, 1);
    drawPixel(graphics, centerX - 1, centerY - 1, 1);
    drawPixel(graphics, centerX + 1, centerY - 1, 1);
    drawPixel(graphics, centerX - 1, centerY + 1, 1);
    drawPixel(graphics, centerX + 1, centerY + 1, 1);
    
    graphics.fillStyle(coreColor);
    drawPixel(graphics, centerX - 1, centerY, 1);
    drawPixel(graphics, centerX + 1, centerY, 1);
    drawPixel(graphics, centerX, centerY - 1, 1);
    drawPixel(graphics, centerX, centerY + 1, 1);
    
    graphics.fillStyle(darkColor);
    drawPixel(graphics, centerX, centerY, 1);
    
    graphics.fillStyle(eyesColor);
    drawPixel(graphics, centerX - 2, centerY, 1);
    drawPixel(graphics, centerX + 2, centerY, 1);
  }
  
  drawBigEnemy(graphics, x, y, size) {
    if (!this.shouldRedraw(graphics, x, y)) return;
    const centerX = 0;
    const centerY = 0;
    const r = Math.floor(size / 2);
    const outerColor = getColor(this.themeManager, COLOR_PATHS.BIG_ENEMY.OUTER);
    const middleColor = getColor(this.themeManager, COLOR_PATHS.BIG_ENEMY.MIDDLE);
    const innerColor = getColor(this.themeManager, COLOR_PATHS.BIG_ENEMY.INNER);
    const darkColor = getColor(this.themeManager, COLOR_PATHS.BIG_ENEMY.DARK);
    const darkestColor = getColor(this.themeManager, COLOR_PATHS.BIG_ENEMY.DARKEST);
    
    const rSq = getRadiusSq(r);
    const rMinus3Sq = getRadiusSq(r - 3);
    const rMinus5Sq = getRadiusSq(r - 5);
    const rMinus7Sq = getRadiusSq(r - 7);
    
    graphics.fillStyle(outerColor);
    for (let dy = -r; dy <= r; dy++) {
      for (let dx = -r; dx <= r; dx++) {
        if (isInRingSq(dx, dy, rMinus3Sq, rSq)) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }
    
    graphics.fillStyle(middleColor);
    for (let dy = -r + 3; dy <= r - 3; dy++) {
      for (let dx = -r + 3; dx <= r - 3; dx++) {
        if (isInRingSq(dx, dy, rMinus5Sq, rMinus3Sq)) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }
    
    graphics.fillStyle(innerColor);
    for (let dy = -r + 5; dy <= r - 5; dy++) {
      for (let dx = -r + 5; dx <= r - 5; dx++) {
        if (isInCircleSq(dx, dy, rMinus5Sq)) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }
    
    graphics.fillStyle(darkColor);
    drawPixel(graphics, centerX - 4, centerY - 4, 1);
    drawPixel(graphics, centerX + 4, centerY - 4, 1);
    drawPixel(graphics, centerX - 4, centerY + 4, 1);
    drawPixel(graphics, centerX + 4, centerY + 4, 1);
    drawPixel(graphics, centerX - 3, centerY - 3, 1);
    drawPixel(graphics, centerX + 3, centerY - 3, 1);
    drawPixel(graphics, centerX - 3, centerY + 3, 1);
    drawPixel(graphics, centerX + 3, centerY + 3, 1);
    drawPixel(graphics, centerX, centerY - 3, 1);
    drawPixel(graphics, centerX, centerY + 3, 1);
    drawPixel(graphics, centerX - 3, centerY, 1);
    drawPixel(graphics, centerX + 3, centerY, 1);
    
    graphics.fillStyle(darkestColor);
    drawPixel(graphics, centerX - 2, centerY - 2, 1);
    drawPixel(graphics, centerX + 2, centerY - 2, 1);
    drawPixel(graphics, centerX - 2, centerY + 2, 1);
    drawPixel(graphics, centerX + 2, centerY + 2, 1);
  }
  
  drawBoss(graphics, x, y, health, maxHealth, pattern, bossType) {
    graphics.clear();
    const centerX = 0;
    const centerY = 0;
    const config = BOSS_CONFIG[bossType] || BOSS_CONFIG[BOSS_TYPES.FORTRESS];
    const r = Math.floor(config.size / 2);
    let colors = this.isDark ? config.color.dark : config.color.light;
    const customBossColors = this.themeManager.getCustomColor(`boss.${bossType}`);
    if (customBossColors) {
      colors = { ...colors, ...customBossColors };
    }
    
    const rSq = getRadiusSq(r);
    const rMinus6Sq = getRadiusSq(r - 6);
    const rMinus10Sq = getRadiusSq(r - 10);
    
    if (bossType === BOSS_TYPES.FORTRESS) {
      graphics.fillStyle(colors.main);
      for (let dy = -r; dy <= r; dy++) {
        for (let dx = -r; dx <= r; dx++) {
          if (isInRingSq(dx, dy, rMinus6Sq, rSq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(colors.accent);
      for (let dy = -r + 6; dy <= r - 6; dy++) {
        for (let dx = -r + 6; dx <= r - 6; dx++) {
          if (isInRingSq(dx, dy, rMinus10Sq, rMinus6Sq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(colors.core);
      for (let dy = -r + 10; dy <= r - 10; dy++) {
        for (let dx = -r + 10; dx <= r - 10; dx++) {
          if (isInCircleSq(dx, dy, rMinus10Sq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      const bossAccent = getColor(this.themeManager, COLOR_PATHS.UI.COMBO, 0xf59e0b);
      graphics.fillStyle(bossAccent);
      drawPixel(graphics, centerX - 8, centerY - 8, 1);
      drawPixel(graphics, centerX + 8, centerY - 8, 1);
      drawPixel(graphics, centerX - 8, centerY + 8, 1);
      drawPixel(graphics, centerX + 8, centerY + 8, 1);
      
    } else if (bossType === BOSS_TYPES.HUNTER) {
      const angle = pattern * 0.3;
      const rMinus3Sq = getRadiusSq(r - 3);
      
      graphics.fillStyle(colors.main);
      for (let dy = -r; dy <= r; dy++) {
        for (let dx = -r; dx <= r; dx++) {
          if (isInRingSq(dx, dy, rMinus3Sq, rSq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(colors.accent);
      const spikeLength = 4;
      for (let i = 0; i < 8; i++) {
        const spikeAngle = (this.TWO_PI * i) / 8 + angle;
        const spikeX = Math.cos(spikeAngle) * (r - 2);
        const spikeY = Math.sin(spikeAngle) * (r - 2);
        for (let j = 0; j < spikeLength; j++) {
          const px = Math.floor(centerX + spikeX * (1 + j * 0.3));
          const py = Math.floor(centerY + spikeY * (1 + j * 0.3));
          drawPixel(graphics, px, py, 1);
        }
      }
      
      graphics.fillStyle(colors.core);
      for (let dy = -r + 3; dy <= r - 3; dy++) {
        for (let dx = -r + 3; dx <= r - 3; dx++) {
          if (isInCircleSq(dx, dy, rMinus3Sq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      const bossCore = getColor(this.themeManager, COLOR_PATHS.UI.COMBO, 0xf59e0b);
      graphics.fillStyle(bossCore);
      drawPixel(graphics, centerX, centerY, 1);
      
    } else if (bossType === BOSS_TYPES.STORM) {
      const flameOffset = Math.sin(pattern * 0.5) * 3;
      const rMinus4Sq = getRadiusSq(r - 4);
      const rMinus6Sq = getRadiusSq(r - 6);
      
      graphics.fillStyle(colors.main);
      for (let dy = -r; dy <= r; dy++) {
        for (let dx = -r; dx <= r; dx++) {
          if (isInRingSq(dx, dy, rMinus4Sq, rSq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(colors.accent);
      for (let dy = -r + 4; dy <= r - 4; dy++) {
        for (let dx = -r + 4; dx <= r - 4; dx++) {
          if (isInRingSq(dx, dy, rMinus6Sq, rMinus4Sq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(colors.core);
      for (let dy = -r + 6; dy <= r - 6; dy++) {
        for (let dx = -r + 6; dx <= r - 6; dx++) {
          if (isInCircleSq(dx, dy, rMinus6Sq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(colors.accent);
      for (let i = -2; i <= 2; i++) {
        const flameX = centerX + i * 2;
        const flameY = centerY + r + 2 + Math.abs(i) + flameOffset;
        drawPixel(graphics, flameX, flameY, 1);
        if (Math.abs(i) < 2) {
          drawPixel(graphics, flameX, flameY + 1, 1);
        }
      }
      
    } else if (bossType === BOSS_TYPES.PHANTOM) {
      const alpha = Math.sin(pattern * 0.2) * 0.3 + 0.7;
      graphics.setAlpha(alpha);
      const rMinus3Sq = getRadiusSq(r - 3);
      const rMinus5Sq = getRadiusSq(r - 5);
      
      graphics.fillStyle(colors.main);
      for (let dy = -r; dy <= r; dy++) {
        for (let dx = -r; dx <= r; dx++) {
          if (isInRingSq(dx, dy, rMinus3Sq, rSq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(colors.accent);
      for (let dy = -r + 3; dy <= r - 3; dy++) {
        for (let dx = -r + 3; dx <= r - 3; dx++) {
          if (isInRingSq(dx, dy, rMinus5Sq, rMinus3Sq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(colors.core);
      for (let dy = -r + 5; dy <= r - 5; dy++) {
        for (let dx = -r + 5; dx <= r - 5; dx++) {
          if (isInCircleSq(dx, dy, rMinus5Sq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(colors.accent);
      const trailCount = 3;
      for (let i = 0; i < trailCount; i++) {
        const trailX = centerX - 4 - i * 2;
        const trailY = centerY + Math.sin(pattern * 0.3 + i) * 2;
        graphics.setAlpha(alpha * (1 - i * 0.3));
        drawPixel(graphics, trailX, trailY, 1);
      }
      
      graphics.setAlpha(1);
    } else if (bossType === BOSS_TYPES.VOID) {
      const pulse = Math.sin(pattern * 0.4) * 0.2 + 0.8;
      graphics.setAlpha(pulse);
      const rMinus4Sq = getRadiusSq(r - 4);
      const rMinus6Sq = getRadiusSq(r - 6);
      
      graphics.fillStyle(colors.main);
      for (let dy = -r; dy <= r; dy++) {
        for (let dx = -r; dx <= r; dx++) {
          if (isInRingSq(dx, dy, rMinus4Sq, rSq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(colors.accent);
      for (let dy = -r + 4; dy <= r - 4; dy++) {
        for (let dx = -r + 4; dx <= r - 4; dx++) {
          if (isInRingSq(dx, dy, rMinus6Sq, rMinus4Sq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(colors.core);
      for (let dy = -r + 6; dy <= r - 6; dy++) {
        for (let dx = -r + 6; dx <= r - 6; dx++) {
          if (isInCircleSq(dx, dy, rMinus6Sq)) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(colors.accent);
      const orbCount = 4;
      for (let i = 0; i < orbCount; i++) {
        const orbAngle = (this.TWO_PI * i) / orbCount + pattern * 0.5;
        const orbDistance = r + 3;
        const orbX = Math.floor(centerX + Math.cos(orbAngle) * orbDistance);
        const orbY = Math.floor(centerY + Math.sin(orbAngle) * orbDistance);
        drawPixel(graphics, orbX, orbY, 1);
        drawPixel(graphics, orbX - 1, orbY, 1);
        drawPixel(graphics, orbX + 1, orbY, 1);
        drawPixel(graphics, orbX, orbY - 1, 1);
        drawPixel(graphics, orbX, orbY + 1, 1);
      }
      
      graphics.fillStyle(colors.main);
      const voidCore = Math.sin(pattern * 0.6) * 2;
      drawPixel(graphics, centerX, centerY + Math.floor(voidCore), 1);
      drawPixel(graphics, centerX - 1, centerY + Math.floor(voidCore), 1);
      drawPixel(graphics, centerX + 1, centerY + Math.floor(voidCore), 1);
      
      graphics.setAlpha(1);
    }
    
    const healthBarWidth = config.size + 10;
    const healthBarHeight = 3;
    const healthPercent = health / maxHealth;
    const barY = centerY - r - 8;
    
    graphics.fillStyle(getColor(this.themeManager, COLOR_PATHS.UI.PROGRESS_BG));
    graphics.fillRect(centerX - healthBarWidth / 2, barY, healthBarWidth, healthBarHeight);
    
    const healthColor = healthPercent > 0.5 ? getColor(this.themeManager, COLOR_PATHS.UI.HEALTH_GOOD) : 
                       healthPercent > 0.25 ? getColor(this.themeManager, COLOR_PATHS.UI.HEALTH_MEDIUM) : 
                       getColor(this.themeManager, COLOR_PATHS.UI.HEALTH_LOW);
    
    graphics.fillStyle(healthColor);
    graphics.fillRect(centerX - healthBarWidth / 2, barY, healthBarWidth * healthPercent, healthBarHeight);
    
    graphics.lineStyle(1, healthColor);
    graphics.strokeRect(centerX - healthBarWidth / 2, barY, healthBarWidth, healthBarHeight);
  }
  
  drawEnergy(graphics, x, y, size) {
    graphics.clear();
    const centerX = 0;
    const centerY = 0;
    const time = this.time.now;
    const pulse = Math.sin(time / 200) * 0.3 + 0.7;
    const rotation = Math.sin(time / 300) * 0.3;
    const mainColor = getColor(this.themeManager, COLOR_PATHS.ENERGY.MAIN);
    const accentColor = getColor(this.themeManager, COLOR_PATHS.ENERGY.ACCENT);
    const coreColor = getColor(this.themeManager, COLOR_PATHS.ENERGY.CORE);
    
    graphics.setAlpha(pulse);
    graphics.rotation = rotation;
    
    graphics.fillStyle(mainColor);
    drawPixel(graphics, centerX, centerY - 3, 1);
    drawPixel(graphics, centerX - 1, centerY - 2, 1);
    drawPixel(graphics, centerX + 1, centerY - 2, 1);
    drawPixel(graphics, centerX - 2, centerY - 1, 1);
    drawPixel(graphics, centerX + 2, centerY - 1, 1);
    drawPixel(graphics, centerX - 3, centerY, 1);
    drawPixel(graphics, centerX, centerY, 1);
    drawPixel(graphics, centerX + 3, centerY, 1);
    drawPixel(graphics, centerX - 2, centerY + 1, 1);
    drawPixel(graphics, centerX + 2, centerY + 1, 1);
    drawPixel(graphics, centerX - 1, centerY + 2, 1);
    drawPixel(graphics, centerX + 1, centerY + 2, 1);
    drawPixel(graphics, centerX, centerY + 3, 1);
    
    graphics.fillStyle(accentColor);
    drawPixel(graphics, centerX, centerY - 1, 1);
    drawPixel(graphics, centerX - 1, centerY, 1);
    drawPixel(graphics, centerX + 1, centerY, 1);
    drawPixel(graphics, centerX, centerY + 1, 1);
    
    graphics.fillStyle(coreColor);
    drawPixel(graphics, centerX, centerY, 1);
    graphics.setAlpha(1);
    graphics.rotation = 0;
  }
  
  drawPowerup(graphics, x, y, type) {
    graphics.clear();
    const centerX = 0;
    const centerY = 0;
    const time = this.time.now;
    const pulse = Math.sin(time / 300) * 0.2 + 0.8;
    const rotation = Math.sin(time / 400) * 0.4;
    const powerupColors = this.themeManager.getColor(`powerup.${type}`);
    
    if (!powerupColors || !powerupColors.main) {
      console.warn(`Powerup colors not found for type: ${type}`);
      return;
    }
    
    graphics.setAlpha(pulse);
    graphics.rotation = rotation;
    
    if (type === POWERUP_TYPES.RAPID) {
      const mainColor = powerupColors.main;
      const accentColor = powerupColors.accent;
      const lightColor = powerupColors.light;
      
      graphics.fillStyle(mainColor);
      drawPixel(graphics, centerX, centerY - 3, 1);
      drawPixel(graphics, centerX - 1, centerY - 2, 1);
      drawPixel(graphics, centerX + 1, centerY - 2, 1);
      drawPixel(graphics, centerX - 2, centerY - 1, 1);
      drawPixel(graphics, centerX + 2, centerY - 1, 1);
      drawPixel(graphics, centerX - 3, centerY, 1);
      drawPixel(graphics, centerX, centerY, 1);
      drawPixel(graphics, centerX + 3, centerY, 1);
      drawPixel(graphics, centerX - 2, centerY + 1, 1);
      drawPixel(graphics, centerX + 2, centerY + 1, 1);
      drawPixel(graphics, centerX - 1, centerY + 2, 1);
      drawPixel(graphics, centerX + 1, centerY + 2, 1);
      drawPixel(graphics, centerX, centerY + 3, 1);
      
      graphics.fillStyle(accentColor);
      drawPixel(graphics, centerX, centerY - 1, 1);
      drawPixel(graphics, centerX - 1, centerY, 1);
      drawPixel(graphics, centerX + 1, centerY, 1);
      drawPixel(graphics, centerX, centerY + 1, 1);
      
      graphics.fillStyle(lightColor);
      drawPixel(graphics, centerX, centerY, 1);
    } else if (type === POWERUP_TYPES.TRIPLE) {
      const mainColor = powerupColors.main;
      const accentColor = powerupColors.accent;
      
      graphics.fillStyle(mainColor);
      for (let i = -1; i <= 1; i++) {
        drawPixel(graphics, centerX + i * 3, centerY - 3, 1);
        drawPixel(graphics, centerX + i * 3, centerY - 2, 1);
        drawPixel(graphics, centerX + i * 3, centerY, 1);
        drawPixel(graphics, centerX + i * 3, centerY + 2, 1);
        drawPixel(graphics, centerX + i * 3, centerY + 3, 1);
      }
      drawPixel(graphics, centerX, centerY - 1, 1);
      drawPixel(graphics, centerX, centerY + 1, 1);
      
      graphics.fillStyle(accentColor);
      drawPixel(graphics, centerX - 3, centerY, 1);
      drawPixel(graphics, centerX, centerY, 1);
      drawPixel(graphics, centerX + 3, centerY, 1);
    } else if (type === POWERUP_TYPES.AUTO_AIM) {
      const mainColor = powerupColors.main;
      const accentColor = powerupColors.accent;
      const lightColor = powerupColors.light;
      
      graphics.fillStyle(mainColor);
      drawPixel(graphics, centerX, centerY - 4, 1);
      drawPixel(graphics, centerX - 1, centerY - 3, 1);
      drawPixel(graphics, centerX + 1, centerY - 3, 1);
      drawPixel(graphics, centerX - 2, centerY - 2, 1);
      drawPixel(graphics, centerX + 2, centerY - 2, 1);
      drawPixel(graphics, centerX - 3, centerY - 1, 1);
      drawPixel(graphics, centerX + 3, centerY - 1, 1);
      drawPixel(graphics, centerX - 2, centerY, 1);
      drawPixel(graphics, centerX + 2, centerY, 1);
      drawPixel(graphics, centerX - 1, centerY + 1, 1);
      drawPixel(graphics, centerX + 1, centerY + 1, 1);
      drawPixel(graphics, centerX, centerY + 2, 1);
      
      graphics.fillStyle(accentColor);
      drawPixel(graphics, centerX - 1, centerY - 2, 1);
      drawPixel(graphics, centerX + 1, centerY - 2, 1);
      drawPixel(graphics, centerX - 2, centerY - 1, 1);
      drawPixel(graphics, centerX + 2, centerY - 1, 1);
      drawPixel(graphics, centerX - 1, centerY, 1);
      drawPixel(graphics, centerX + 1, centerY, 1);
      drawPixel(graphics, centerX, centerY + 1, 1);
      
      graphics.fillStyle(lightColor);
      drawPixel(graphics, centerX, centerY, 1);
    } else if (type === POWERUP_TYPES.SHIELD) {
      const mainColor = powerupColors.main;
      const accentColor = powerupColors.accent;
      const lightColor = powerupColors.light;
      
      graphics.fillStyle(mainColor);
      for (let dy = -4; dy <= 4; dy++) {
        for (let dx = -4; dx <= 4; dx++) {
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist <= 4 && dist > 3) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(accentColor);
      for (let dy = -3; dy <= 3; dy++) {
        for (let dx = -3; dx <= 3; dx++) {
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist <= 3 && dist > 2) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(lightColor);
      drawPixel(graphics, centerX, centerY - 2, 1);
      drawPixel(graphics, centerX, centerY + 2, 1);
      drawPixel(graphics, centerX - 2, centerY, 1);
      drawPixel(graphics, centerX + 2, centerY, 1);
    } else if (type === POWERUP_TYPES.LIFE) {
      const mainColor = powerupColors.main;
      const accentColor = powerupColors.accent;
      const lightColor = powerupColors.light;
      
      graphics.fillStyle(mainColor);
      drawPixel(graphics, centerX, centerY - 4, 1);
      drawPixel(graphics, centerX - 1, centerY - 3, 1);
      drawPixel(graphics, centerX + 1, centerY - 3, 1);
      drawPixel(graphics, centerX - 2, centerY - 2, 1);
      drawPixel(graphics, centerX + 2, centerY - 2, 1);
      drawPixel(graphics, centerX - 2, centerY - 1, 1);
      drawPixel(graphics, centerX + 2, centerY - 1, 1);
      drawPixel(graphics, centerX - 1, centerY, 1);
      drawPixel(graphics, centerX + 1, centerY, 1);
      drawPixel(graphics, centerX - 1, centerY + 1, 1);
      drawPixel(graphics, centerX + 1, centerY + 1, 1);
      drawPixel(graphics, centerX, centerY + 2, 1);
      
      graphics.fillStyle(accentColor);
      drawPixel(graphics, centerX, centerY - 2, 1);
      drawPixel(graphics, centerX - 1, centerY - 1, 1);
      drawPixel(graphics, centerX + 1, centerY - 1, 1);
      drawPixel(graphics, centerX, centerY, 1);
      
      graphics.fillStyle(lightColor);
      drawPixel(graphics, centerX, centerY - 1, 1);
    } else if (type === POWERUP_TYPES.MAGNET) {
      const mainColor = powerupColors.main;
      const accentColor = powerupColors.accent;
      const lightColor = powerupColors.light;
      
      graphics.fillStyle(mainColor);
      for (let dy = -3; dy <= 3; dy++) {
        for (let dx = -3; dx <= 3; dx++) {
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist <= 3 && dist > 2) {
            drawPixel(graphics, centerX + dx, centerY + dy, 1);
          }
        }
      }
      
      graphics.fillStyle(accentColor);
      drawPixel(graphics, centerX - 2, centerY - 1, 1);
      drawPixel(graphics, centerX - 2, centerY, 1);
      drawPixel(graphics, centerX - 2, centerY + 1, 1);
      drawPixel(graphics, centerX + 2, centerY - 1, 1);
      drawPixel(graphics, centerX + 2, centerY, 1);
      drawPixel(graphics, centerX + 2, centerY + 1, 1);
      
      graphics.fillStyle(lightColor);
      drawPixel(graphics, centerX, centerY - 1, 1);
      drawPixel(graphics, centerX, centerY, 1);
      drawPixel(graphics, centerX, centerY + 1, 1);
    } else if (type === POWERUP_TYPES.SLOW_MOTION) {
      const mainColor = powerupColors.main;
      const accentColor = powerupColors.accent;
      const lightColor = powerupColors.light;
      
      graphics.fillStyle(mainColor);
      drawPixel(graphics, centerX, centerY - 3, 1);
      drawPixel(graphics, centerX - 1, centerY - 2, 1);
      drawPixel(graphics, centerX + 1, centerY - 2, 1);
      drawPixel(graphics, centerX - 2, centerY - 1, 1);
      drawPixel(graphics, centerX + 2, centerY - 1, 1);
      drawPixel(graphics, centerX - 2, centerY, 1);
      drawPixel(graphics, centerX + 2, centerY, 1);
      drawPixel(graphics, centerX - 1, centerY + 1, 1);
      drawPixel(graphics, centerX + 1, centerY + 1, 1);
      drawPixel(graphics, centerX, centerY + 2, 1);
      
      graphics.fillStyle(accentColor);
      drawPixel(graphics, centerX - 1, centerY - 1, 1);
      drawPixel(graphics, centerX + 1, centerY - 1, 1);
      drawPixel(graphics, centerX - 1, centerY, 1);
      drawPixel(graphics, centerX + 1, centerY, 1);
      drawPixel(graphics, centerX, centerY + 1, 1);
      
      graphics.fillStyle(lightColor);
      drawPixel(graphics, centerX, centerY, 1);
    }
    graphics.setAlpha(1);
  }
  
  
  updateBoss() {
    if (!this.bossManager.getBoss()) {
      const obstacles = this.getCachedChildren('obstacles');
      if (this.score >= BOSS_SPAWN_SCORE && Math.floor(this.score / BOSS_SPAWN_SCORE) > Math.floor(this.lastBossScore / BOSS_SPAWN_SCORE) && obstacles.length === 0) {
        const bossTypes = Object.values(BOSS_TYPES);
        const randomType = bossTypes[Math.floor(Math.random() * bossTypes.length)];
        
        const boss = this.bossManager.spawnBoss(
          randomType,
          this.level,
          this.gameWidth,
          this.gameHeight,
          this.hyperspeedMultiplier
        );
        
        if (boss) {
          this.boss = boss;
          this.lastBossScore = this.score;
          this.setupPhysicsBody(this.boss, BOSS_CONFIG[randomType].size);
          this.syncPhysicsBody(this.boss);
        }
      }
      return;
    }
    
    // Update boss using manager
    this.bossManager.updateBoss(
      this.gameWidth,
      this.gameHeight,
      this.level,
      this.hyperspeedMultiplier,
      this.isSlowMotionActive ? SLOW_MOTION_FACTOR : 1,
      this.player.x,
      this.player.y,
      (name) => this.getCachedChildren(name),
      (bossX, bossY, targetX, targetY, bulletSpeed) => this.createBossBullet(bossX, bossY, targetX, targetY, bulletSpeed),
      this.time
    );
    
    // Sync boss reference
    this.boss = this.bossManager.getBoss();
    
    // Update boss pattern for drawing
    this.bossPattern = this.bossManager.bossPattern;
    
    // Sync physics
    if (this.boss) {
      this.syncPhysicsBody(this.boss);
      
      // Remove if out of bounds
    const bossType = this.boss.type || BOSS_TYPES.FORTRESS;
    const config = BOSS_CONFIG[bossType];
    const bossSize = config.size;
      
      if (this.boss.x < -bossSize) {
        // Boss left screen - destroy it properly
        this.bossManager.destroyBoss();
        this.boss = null;
        this.bossPattern = 0;
      }
    }
  }
  
  updateBullets() {
    const bulletsToRemove = [];
    const bullets = this.getCachedChildren('bullets');
    const bulletsLength = bullets.length;
    const speedMultiplier = this.isSlowMotionActive ? SLOW_MOTION_FACTOR : 1;
    
    for (let i = 0; i < bulletsLength; i++) {
      const bullet = bullets[i];
      if (!this.isActive(bullet)) continue;
      
      if (bullet.hasTarget && bullet.vx !== undefined && bullet.vy !== undefined) {
        // Store base velocities if not already stored
        if (bullet.baseVx === undefined) {
          bullet.baseVx = bullet.vx;
          bullet.baseVy = bullet.vy;
        }
        
        // Apply slow motion to auto-aim bullets
        bullet.x += bullet.baseVx * speedMultiplier;
        bullet.y += bullet.baseVy * speedMultiplier;
        
        // Recalculate target only if close to current target (optimized)
        if (bullet.targetX !== undefined && bullet.targetY !== undefined) {
          const dx = bullet.targetX - bullet.x;
          const dy = bullet.targetY - bullet.y;
          const distanceSq = dx * dx + dy * dy;
          
          // Only recalculate if target is close (200^2)
          if (distanceSq < 40000) {
            const newTarget = this.findNearestTarget(bullet.x, bullet.y);
            if (newTarget) {
              const newDx = newTarget.x - bullet.x;
              const newDy = newTarget.y - bullet.y;
              const newDistanceSq = newDx * newDx + newDy * newDy;
              if (newDistanceSq > 0) {
                const baseSpeed = Math.sqrt(bullet.baseVx * bullet.baseVx + bullet.baseVy * bullet.baseVy);
                const invDistance = 1 / Math.sqrt(newDistanceSq);
                bullet.baseVx = newDx * invDistance * baseSpeed;
                bullet.baseVy = newDy * invDistance * baseSpeed;
                bullet.vx = bullet.baseVx;
                bullet.vy = bullet.baseVy;
                bullet.targetX = newTarget.x;
                bullet.targetY = newTarget.y;
              }
            }
          }
        }
        this.syncPhysicsBody(bullet);
      } else if (bullet.speed) {
        // Store base speed if not already stored
        if (bullet.baseSpeed === undefined) {
          bullet.baseSpeed = bullet.speed;
        }
        // Apply slow motion to regular bullets
        bullet.x += bullet.baseSpeed * speedMultiplier;
        this.syncPhysicsBody(bullet);
      }
      
      const bulletRect = this.collisionManager.getCollisionRect(bullet, BULLET_SIZE);
      
      let hit = false;
      
      if (this.boss && this.boss.health > 0 && !bullet._collisionProcessed) {
        const bossType = this.boss.type || BOSS_TYPES.FORTRESS;
        const config = BOSS_CONFIG[bossType];
        const bossSize = config.size;
        
        const bossRect = this.collisionManager.getCollisionRect(this.boss, bossSize);
        
        if (this.collisionManager.checkRectCollision(bulletRect, bossRect, this.time.now)) {
          bullet._collisionProcessed = true;
          hit = true;
          
          if (this.cheats.oneHitKill) {
            this.boss.health = 0;
          } else {
            this.boss.health--;
          }
          const bossHitColor = getParticleColor(this.themeManager, PARTICLE_TYPES.BOSS);
          this.createParticles(bullet.x, bullet.y, BOSS_HIT_PARTICLES_COUNT, bossHitColor, PARTICLE_TYPES.EXPLOSION);
          
          const isBossDead = this.boss.health <= 0;
          this.soundManager.playSound(isBossDead ? 
            this.soundManager.soundTypes.BOSS_KILL : 
            this.soundManager.soundTypes.BOSS_HIT);
          
          if (isBossDead) {
            const bossType = this.boss.type || BOSS_TYPES.FORTRESS;
            const bossConfig = BOSS_CONFIG[bossType];
            const livesReward = bossConfig.livesReward || 1;
            
            const bossKillColor = getParticleColor(this.themeManager, PARTICLE_TYPES.BOSS_KILL);
            this.createParticles(this.boss.x, this.boss.y, BOSS_KILL_PARTICLES_COUNT, bossKillColor, PARTICLE_TYPES.EXPLOSION);
            this.createParticles(this.boss.x, this.boss.y, BOSS_KILL_PARTICLES_COUNT_2, bossKillColor, PARTICLE_TYPES.EXPLOSION);
            
            // Strong screen effects for boss kill
            this.addScreenShake(0.025, 300);
            this.addScreenFlash(bossKillColor, 0.3, 300);
            
            const comboMultiplier = this.getComboMultiplier(this.combo);
            const points = Math.floor(100 * comboMultiplier);
            this.createFloatingText(this.boss.x, this.boss.y, `+${points}`, bossKillColor, FLOATING_TEXT_SIZES.LARGE);
            this.updateScoreWithHighScore(points, 10, false);
            this.kills++;
            this.lives = Math.min(this.lives + livesReward, 5);
            const lifeRewardColor = getParticleColor(this.themeManager, PARTICLE_TYPES.LIFE);
            this.createFloatingText(this.boss.x, this.boss.y - 15, `+${livesReward} LIFE${livesReward > 1 ? 'S' : ''}!`, lifeRewardColor, FLOATING_TEXT_SIZES.MEDIUM);
            this.lastBossScore = this.score + points;
            // Destroy boss properly - this will also clear boss bullets
            this.bossManager.destroyBoss();
            this.boss = null;
            this.bossPattern = 0;
          }
          
          bulletsToRemove.push(bullet);
          continue;
        }
      }
      
      if (!hit && !bullet._collisionProcessed) {
        const obstacles = this.getCachedChildren('obstacles');
        const obstaclesLength = obstacles.length;
        
        for (let j = 0; j < obstaclesLength; j++) {
          const obstacle = obstacles[j];
          if (!this.isActive(obstacle)) continue;
          
          const obstacleRect = this.collisionManager.getCollisionRect(obstacle, obstacle.size);
          
          if (this.collisionManager.checkRectCollision(bulletRect, obstacleRect, this.time.now)) {
            bullet._collisionProcessed = true;
            hit = true;
            
            const now = this.time.now;
            const timeSinceLastKill = now - this.lastKillTime;
            
            let newCombo;
            const comboTimeout = this.getComboTimeout();
            if (timeSinceLastKill < comboTimeout) {
              newCombo = Math.min(this.combo + 1, 10);
              this.combo = newCombo;
              this.comboFlash = 15;
            } else {
              newCombo = 1;
              this.combo = 1;
              this.comboFlash = 10;
            }
            
            this.lastKillTime = now;
            
            const timeSinceMultiKill = now - this.multiKillLastKillTime;
            if (timeSinceMultiKill < MULTI_KILL_WINDOW) {
              this.multiKillKills.push(now);
            } else {
              this.multiKillKills = [now];
            }
            this.multiKillLastKillTime = now;
            
            const recentKills = this.multiKillKills.filter(killTime => now - killTime < MULTI_KILL_WINDOW);
            this.multiKillKills = recentKills;
            
            if (recentKills.length >= 3) {
              const multiKillTexts = {
                3: 'DOUBLE KILL!',
                4: 'TRIPLE KILL!',
                5: 'MEGA KILL!',
                6: 'ULTRA KILL!',
                7: 'MONSTER KILL!'
              };
              const killText = multiKillTexts[Math.min(recentKills.length, 7)] || 'MONSTER KILL!';
              const bonusPoints = recentKills.length * 5;
              const multiKillColor = getParticleColor(this.themeManager, PARTICLE_TYPES.EXPLOSION);
              this.createFloatingText(obstacle.x, obstacle.y - 20, killText, multiKillColor, FLOATING_TEXT_SIZES.LARGE);
              this.updateScoreWithHighScore(bonusPoints, 8, false);
            }
            
            if (this.comboTimeout) {
              clearTimeout(this.comboTimeout);
            }
            this.comboTimeout = setTimeout(() => {
              this.combo = 0;
            }, this.getComboTimeout());
            
            // Improved scoring system with level scaling
            const basePoints = {
              [OBSTACLE_TYPES.ASTEROID]: 12,
              [OBSTACLE_TYPES.COMET]: 10,
              [OBSTACLE_TYPES.FAST_ENEMY]: 15,
              [OBSTACLE_TYPES.BIG_ENEMY]: 18
            }[obstacle.type] || 8;
            
            // Level scaling: higher levels give more base points
            const levelBonus = 1 + (this.level - 1) * 0.1;
            const comboMultiplier = this.getComboMultiplier(newCombo);
            const points = Math.floor(basePoints * levelBonus * comboMultiplier);
            const killColor = getParticleColor(this.themeManager, PARTICLE_TYPES.DEFAULT);
            const particleCount = {
              [OBSTACLE_TYPES.BIG_ENEMY]: 25,
              [OBSTACLE_TYPES.FAST_ENEMY]: 20
            }[obstacle.type] || 18;
            this.createParticles(bullet.x, bullet.y, particleCount, killColor, PARTICLE_TYPES.EXPLOSION);
            this.createFloatingText(obstacle.x, obstacle.y, `+${points}`, killColor, FLOATING_TEXT_SIZES.NORMAL);
            this.updateScoreWithHighScore(points, 8, true);
            this.kills++;
            
            // Screen shake for enemy destruction
            const shakeIntensity = obstacle.type === OBSTACLE_TYPES.BIG_ENEMY ? 0.012 : 0.008;
            this.addScreenShake(shakeIntensity, 80);
            
            // Emit obstacle destroy and combo update events
            if (this.eventManager) {
              this.eventManager.emit(GAME_EVENTS.OBSTACLE_DESTROY, { 
                type: obstacle.type, 
                points,
                x: obstacle.x,
                y: obstacle.y
              });
              this.eventManager.emit(GAME_EVENTS.COMBO_UPDATE, { combo: newCombo });
            }
            
            this.soundManager.playSound(newCombo > 1 ? 
              this.soundManager.soundTypes.COMBO : 
              this.soundManager.soundTypes.EXPLOSION);
            
            this.removeFromContainer(obstacle);
            obstacle.destroy();
            bulletsToRemove.push(bullet);
            break;
          }
        }
      }
      
      if (this.isOutOfBounds(bullet, 50)) {
        bulletsToRemove.push(bullet);
      }
    }
    
    for (let i = 0; i < bulletsToRemove.length; i++) {
      const bullet = bulletsToRemove[i];
      this.removeFromContainer(bullet);
      bullet.destroy();
    }
    
    this.cachedChildren.bullets = null;
    
    const bossBullets = this.getCachedChildren('bossBullets');
    const bossBulletsLength = bossBullets.length;
    
    for (let i = 0; i < bossBulletsLength; i++) {
      const bullet = bossBullets[i];
      if (!this.isActive(bullet)) continue;
      
      if (bullet.vx !== undefined && bullet.vy !== undefined) {
        // Store base velocities if not already stored
        if (bullet.baseVx === undefined) {
          bullet.baseVx = bullet.vx;
          bullet.baseVy = bullet.vy;
        }
        // Apply slow motion to boss bullets
        bullet.x += bullet.baseVx * speedMultiplier;
        bullet.y += bullet.baseVy * speedMultiplier;
        this.syncPhysicsBody(bullet);
      }
      
      if (this.isOutOfBounds(bullet, 10)) {
        this.removeFromContainer(bullet);
        bullet.destroy();
      }
    }
    
    this.cachedChildren.bossBullets = null;
  }
  
  updateObstacles() {
    const speedMultiplier = this.isSlowMotionActive ? SLOW_MOTION_FACTOR : 1;
    this.updateMovingObjects('obstacles', 0, (obstacle) => {
      // Store original speed if not already stored
      if (obstacle.baseSpeed === undefined && obstacle.speed !== undefined) {
        obstacle.baseSpeed = obstacle.speed;
      }
      
      // Use improved movement from ObstacleManager
      this.obstacleManager.updateObstacleMovement(
        obstacle, 
        this.gameHeight, 
        this.hyperspeedMultiplier, 
        speedMultiplier
      );
      
      if (obstacle.y < -obstacle.size || obstacle.y > this.gameHeight + obstacle.size) {
        this.removeFromContainer(obstacle);
        obstacle.destroy();
      }
    });
  }
  
  applyMagnetPull(obj) {
    if (!this.isMagnetActive) return;
    
    const dx = this.player.x - obj.x;
    const dy = this.player.y - obj.y;
    const distanceSq = dx * dx + dy * dy;
    const maxDistanceSq = MAGNET_RADIUS * MAGNET_RADIUS;
    
    if (distanceSq > 0 && distanceSq < maxDistanceSq) {
      const distance = Math.sqrt(distanceSq);
      
      // Градиент силы: ближе к игроку = сильнее притяжение
      const normalizedDistance = distance / MAGNET_RADIUS; // 0 (близко) до 1 (далеко)
      const pullStrength = 1 - normalizedDistance; // 1 (близко) до 0 (далеко)
      
      // Плавное ускорение притяжения
      const pullSpeed = MAGNET_MIN_PULL_SPEED + (MAGNET_MAX_PULL_SPEED - MAGNET_MIN_PULL_SPEED) * (pullStrength * pullStrength);
      
      // Применяем притяжение
      const pullX = (dx / distance) * pullSpeed;
      const pullY = (dy / distance) * pullSpeed;
      obj.x += pullX;
      obj.y += pullY;
      this.syncPhysicsBody(obj);
      
      // Сохраняем данные для визуализации
      obj._magnetDistance = distance;
      obj._magnetPullStrength = pullStrength;
    } else {
      obj._magnetDistance = null;
      obj._magnetPullStrength = null;
    }
  }
  
  drawMagnetVisualization() {
    if (!this.isMagnetActive || !this.magnetGraphics) {
      this.magnetGraphics.clear();
      return;
    }
    
    this.magnetGraphics.clear();
    
    const magnetColor = getParticleColor(this.themeManager, PARTICLE_TYPES.MAGNET);
    const magnetLightColor = getPowerupColor(this.themeManager, 'magnet', 'light') || magnetColor;
    const playerX = this.player.x;
    const playerY = this.player.y;
    const time = this.time.now;
    
    // Анимация пульсации магнитного поля
    const pulsePhase = (time % 1200) / 1200;
    const pulseSize = 1 + Math.sin(pulsePhase * Math.PI * 2) * 0.15;
    const currentRadius = MAGNET_RADIUS * pulseSize;
    
    // Рисуем более выраженные концентрические круги магнитного поля
    const rings = 4;
    for (let i = 0; i < rings; i++) {
      const ringAlpha = 0.2 - (i * 0.04);
      const ringRadius = currentRadius * (1 - i * 0.25);
      const ringPhase = (pulsePhase + i * 0.25) % 1;
      const ringAlphaPulse = ringAlpha * (0.7 + Math.sin(ringPhase * Math.PI * 2) * 0.3);
      
      this.magnetGraphics.lineStyle(2, magnetColor, ringAlphaPulse);
      this.magnetGraphics.strokeCircle(playerX, playerY, ringRadius);
    }
    
    // Рисуем спиральные силовые линии магнитного поля
    const spiralLines = 8;
    for (let i = 0; i < spiralLines; i++) {
      const angle = (i / spiralLines) * Math.PI * 2 + pulsePhase * Math.PI * 2;
      const spiralRadius = currentRadius * 0.8;
      const endX = playerX + Math.cos(angle) * spiralRadius;
      const endY = playerY + Math.sin(angle) * spiralRadius;
      
      this.magnetGraphics.lineStyle(1, magnetLightColor, 0.3);
      this.magnetGraphics.moveTo(playerX, playerY);
      this.magnetGraphics.lineTo(endX, endY);
    }
    
    // Рисуем линии притяжения к объектам в радиусе
    const energies = this.getCachedChildren('energies');
    const powerups = this.getCachedChildren('powerups');
    const allAttracted = [...energies, ...powerups].filter(obj => 
      obj._magnetDistance !== null && obj._magnetDistance < MAGNET_RADIUS
    );
    
    // Сортируем по расстоянию для лучшей визуализации
    allAttracted.sort((a, b) => (a._magnetDistance || Infinity) - (b._magnetDistance || Infinity));
    
    // Рисуем изогнутые линии со стрелками к ближайшим объектам (максимум 8)
    const maxLines = Math.min(8, allAttracted.length);
    for (let i = 0; i < maxLines; i++) {
      const obj = allAttracted[i];
      if (!obj._magnetPullStrength) continue;
      
      const alpha = obj._magnetPullStrength * 0.7;
      const lineWidth = 1.5 + obj._magnetPullStrength * 0.5;
      
      const dx = obj.x - playerX;
      const dy = obj.y - playerY;
      const distance = obj._magnetDistance;
      
      // Нормализуем вектор направления
      const invDistance = 1 / distance;
      const dirX = dx * invDistance;
      const dirY = dy * invDistance;
      
      // Рисуем изогнутую пунктирную линию притяжения (кривая Безье)
      const segments = Math.floor(distance / 8);
      const controlOffset = distance * 0.3;
      const controlX = playerX + dirX * (distance * 0.5) - dirY * controlOffset;
      const controlY = playerY + dirY * (distance * 0.5) + dirX * controlOffset;
      
      this.magnetGraphics.lineStyle(lineWidth, magnetLightColor, alpha);
      
      for (let j = 0; j < segments; j += 2) {
        const t1 = j / segments;
        const t2 = (j + 1) / segments;
        
        // Кривая Безье
        const getBezierPoint = (t) => {
          const mt = 1 - t;
          const x = mt * mt * playerX + 2 * mt * t * controlX + t * t * obj.x;
          const y = mt * mt * playerY + 2 * mt * t * controlY + t * t * obj.y;
          return { x, y };
        };
        
        const p1 = getBezierPoint(t1);
        const p2 = getBezierPoint(Math.min(t2, 1));
        
        this.magnetGraphics.moveTo(p1.x, p1.y);
        this.magnetGraphics.lineTo(p2.x, p2.y);
      }
      
      // Рисуем стрелку направления притяжения
      const arrowSize = 5;
      const arrowX = obj.x - dirX * arrowSize;
      const arrowY = obj.y - dirY * arrowSize;
      const perpX = -dirY * arrowSize * 0.7;
      const perpY = dirX * arrowSize * 0.7;
      
      // Draw triangle arrow using fillTriangle
      this.magnetGraphics.fillStyle(magnetLightColor, alpha);
      this.magnetGraphics.fillTriangle(
        obj.x, obj.y,
        arrowX + perpX, arrowY + perpY,
        arrowX - perpX, arrowY - perpY
      );
      
      // Индикатор на объекте - круг с пульсацией
      const indicatorSize = 3 + obj._magnetPullStrength * 2;
      this.magnetGraphics.fillStyle(magnetLightColor, alpha * 0.6);
      this.magnetGraphics.fillCircle(obj.x, obj.y, indicatorSize);
      this.magnetGraphics.lineStyle(1.5, magnetColor, alpha);
      this.magnetGraphics.strokeCircle(obj.x, obj.y, indicatorSize + 1);
    }
    
    // Центральный индикатор на игроке - магнитный символ (два полукруга)
    const centerPulse = 4 + Math.sin(pulsePhase * Math.PI * 2) * 2;
    this.magnetGraphics.fillStyle(magnetColor, 0.9);
    this.magnetGraphics.fillCircle(playerX, playerY, centerPulse);
    this.magnetGraphics.lineStyle(2, magnetLightColor, 0.9);
    this.magnetGraphics.strokeCircle(playerX, playerY, centerPulse + 1);
    
    // Рисуем символ магнита (две дуги) - используем простые линии для совместимости
    const arcRadius = centerPulse * 0.6;
    this.magnetGraphics.lineStyle(2, magnetLightColor, 0.9);
    // Draw arcs as semicircles using multiple line segments
    const segments = 8;
    const leftArcX = playerX - arcRadius * 0.3;
    const rightArcX = playerX + arcRadius * 0.3;
    
    // Left arc (top half)
    for (let i = 0; i < segments; i++) {
      const angle1 = (i / segments) * Math.PI;
      const angle2 = ((i + 1) / segments) * Math.PI;
      const x1 = leftArcX + Math.cos(angle1) * arcRadius;
      const y1 = playerY - Math.sin(angle1) * arcRadius;
      const x2 = leftArcX + Math.cos(angle2) * arcRadius;
      const y2 = playerY - Math.sin(angle2) * arcRadius;
      this.magnetGraphics.moveTo(x1, y1);
      this.magnetGraphics.lineTo(x2, y2);
    }
    
    // Right arc (bottom half)
    for (let i = 0; i < segments; i++) {
      const angle1 = Math.PI + (i / segments) * Math.PI;
      const angle2 = Math.PI + ((i + 1) / segments) * Math.PI;
      const x1 = rightArcX + Math.cos(angle1) * arcRadius;
      const y1 = playerY - Math.sin(angle1) * arcRadius;
      const x2 = rightArcX + Math.cos(angle2) * arcRadius;
      const y2 = playerY - Math.sin(angle2) * arcRadius;
      this.magnetGraphics.moveTo(x1, y1);
      this.magnetGraphics.lineTo(x2, y2);
    }
  }
  
  updateEnergies() {
    this.updateMovingObjects('energies', ENERGY_SIZE, (energy) => {
      this.applyMagnetPull(energy);
      // Update animation
      if (this.energyManager) {
        this.energyManager.updateEnergyAnimation(energy);
      }
    });
  }
  
  updatePowerups() {
    this.updateMovingObjects('powerups', POWERUP_SIZE, (powerup) => {
      this.applyMagnetPull(powerup);
      // Update animation
      if (this.powerupManager) {
        this.powerupManager.updatePowerupAnimation(powerup, this.time.now);
      }
    });
  }
  
  updateMovingObjects(groupName, size, customUpdate) {
    const objects = this.getCachedChildren(groupName);
    const objectsLength = objects.length;
    const speedMultiplier = this.isSlowMotionActive ? SLOW_MOTION_FACTOR : 1;
    
    for (let i = 0; i < objectsLength; i++) {
      const obj = objects[i];
      if (!this.isActive(obj)) continue;
      
      // Handle movement - support both old and new speed system
      const currentSpeed = obj.speed || 0;
      if (currentSpeed > 0) {
        // Store original speed if not already stored
        if (obj.baseSpeed === undefined) {
          obj.baseSpeed = currentSpeed;
        }
        // Use baseSpeed for movement, apply slow motion multiplier
        const effectiveSpeed = obj.baseSpeed * speedMultiplier;
        obj.x -= effectiveSpeed;
        this.syncPhysicsBody(obj);
      }
      
      if (customUpdate) {
        customUpdate(obj);
      }
      
      if (obj.x < -size) {
        this.removeFromContainer(obj);
        obj.destroy();
      }
    }
    
    this.cachedChildren[groupName] = null;
  }
  
  updateParticles() {
    if (this.particleManager) {
      this.particleManager.update();
    }
  }
  
  updateFloatingTexts() {
    if (this.floatingTextManager) {
      this.floatingTextManager.update();
    }
  }
  
  updateStars() {
    if (this.starManager) {
      const speedMultiplier = this.isSlowMotionActive ? SLOW_MOTION_FACTOR : 1;
      const effectiveHyperspeed = this.hyperspeedMultiplier * speedMultiplier;
      this.starManager.update(effectiveHyperspeed, this.time.now);
    }
  }
  
  updateTimers() {
    const currentTime = this.time.now;
    if (this.isHyperspeed && currentTime >= this.hyperspeedEndTime) {
      this.isHyperspeed = false;
      this.hyperspeedMultiplier = 1;
      if (this.bulletManager) {
        this.bulletManager.setHyperspeed(false);
      }
      if (this.hyperspeedText) {
        this.hyperspeedText.setVisible(false);
      }
    }
    if (this.isTripleShot && currentTime >= this.tripleShotEndTime) {
      this.isTripleShot = false;
    }
    if (this.isShieldActive && currentTime >= this.shieldEndTime) {
      this.isShieldActive = false;
    }
    if (this.isAutoAimActive && currentTime >= this.autoAimEndTime) {
      this.isAutoAimActive = false;
      if (this.autoAimText) {
        this.autoAimText.setVisible(false);
      }
      if (this.autoAimGraphics) {
        this.autoAimGraphics.clear();
      }
      this.autoAimTargets = [];
    }
    if (this.isMagnetActive && currentTime >= this.magnetEndTime) {
      this.isMagnetActive = false;
      if (this.magnetText) {
        this.magnetText.setVisible(false);
      }
      if (this.magnetGraphics) {
        this.magnetGraphics.clear();
      }
    }
    if (this.isSlowMotionActive && currentTime >= this.slowMotionEndTime) {
      this.isSlowMotionActive = false;
      if (this.slowMotionText) {
        this.slowMotionText.setVisible(false);
      }
    }
    
    if (this.comboFlash > 0) {
      this.comboFlash--;
    }
    if (this.scoreFlash > 0) {
      this.scoreFlash--;
    }
  }
  
  spawnObstacles() {
    const spawnRate = SPAWN_RATE * this.getSpawnRateMultiplier();
    const obstacles = this.getCachedChildren('obstacles');
    const maxObstacles = Math.min(12 + Math.floor(this.level / 2), 18);
    if (!this.boss && obstacles.length < maxObstacles && Math.random() < spawnRate * this.hyperspeedMultiplier) {
      const rand = Math.random();
      let type, size;
      if (rand < 0.45) {
        type = OBSTACLE_TYPES.ASTEROID;
        size = ASTEROID_SIZE;
      } else if (rand < 0.7) {
        type = OBSTACLE_TYPES.COMET;
        size = COMET_SIZE;
      } else if (rand < 0.85 && this.level >= 3) {
        type = OBSTACLE_TYPES.FAST_ENEMY;
        size = FAST_ENEMY_SIZE;
      } else if (this.level >= 5) {
        type = OBSTACLE_TYPES.BIG_ENEMY;
        size = BIG_ENEMY_SIZE;
      } else {
        type = OBSTACLE_TYPES.ASTEROID;
        size = ASTEROID_SIZE;
      }
      
      const baseSpeed = type === OBSTACLE_TYPES.FAST_ENEMY ? 5 : type === OBSTACLE_TYPES.BIG_ENEMY ? 1.5 : (Math.random() * 2 + 2);
      const obstacleSpeed = baseSpeed * this.getObstacleSpeedMultiplier() * this.hyperspeedMultiplier;
      const obstacleY = Phaser.Math.Between(size, this.gameHeight - size);
      
      const obstacle = this.obstacleManager.createObstacle(
        type, 
        this.gameWidth, 
        obstacleY, 
        size, 
        obstacleSpeed,
        this.gameHeight
      );
      
      this.setupPhysicsBody(obstacle, size);
      this.obstacles.add(obstacle);
      this.syncPhysicsBody(obstacle);
    }
  }
  
  spawnEnergies() {
    const energies = this.getCachedChildren('energies');
    const levelReduction = Math.pow(0.92, this.level - 1);
    const energySpawnRate = ENERGY_SPAWN_RATE * levelReduction;
    if (energies.length < 5 && Math.random() < Math.max(0.001, energySpawnRate)) {
      const energySpeed = 3 * this.hyperspeedMultiplier;
      const energyY = Phaser.Math.Between(ENERGY_SIZE, this.gameHeight - ENERGY_SIZE);
      
      const energy = this.energyManager.createEnergy(
        this.gameWidth,
        energyY,
        energySpeed
      );
      
      this.setupPhysicsBody(energy, ENERGY_SIZE);
      this.energies.add(energy);
      this.syncPhysicsBody(energy);
    }
  }
  
  spawnPowerups() {
    const powerups = this.getCachedChildren('powerups');
    const levelReduction = Math.pow(0.88, this.level - 1);
    const powerupSpawnRate = POWERUP_SPAWN_RATE * levelReduction;
    
    // Improved balance: adjust spawn rates based on current powerups
    const maxPowerups = 3;
    const hasShield = this.isShieldActive;
    const hasHyperspeed = this.isHyperspeed;
    const hasTriple = this.isTripleShot;
    
    if (powerups.length < maxPowerups && Math.random() < Math.max(0.0005, powerupSpawnRate)) {
      const rand = Math.random();
      let type;
      
      // Improved probability distribution
      // Life is rarer, defensive powerups more common when needed
      if (rand < 0.18) {
        type = POWERUP_TYPES.RAPID;
      } else if (rand < 0.32) {
        type = POWERUP_TYPES.TRIPLE;
      } else if (rand < 0.48) {
        type = POWERUP_TYPES.SHIELD;
      } else if (rand < 0.62) {
        type = POWERUP_TYPES.AUTO_AIM;
      } else if (rand < 0.76) {
        type = POWERUP_TYPES.MAGNET;
      } else if (rand < 0.88) {
        type = POWERUP_TYPES.SLOW_MOTION;
      } else {
        type = POWERUP_TYPES.LIFE; // Rarest - 12% chance
      }
      
      const powerupSpeed = 2 * this.hyperspeedMultiplier;
      const powerupY = Phaser.Math.Between(POWERUP_SIZE, this.gameHeight - POWERUP_SIZE);
      
      const powerup = this.powerupManager.createPowerup(
        type,
        this.gameWidth,
        powerupY,
        powerupSpeed
      );
      
      this.setupPhysicsBody(powerup, POWERUP_SIZE);
      this.powerups.add(powerup);
      this.syncPhysicsBody(powerup);
    }
  }
  
  updateBlurEffect() {
    const shouldBlur = this.isHyperspeed && !this.cheats.noBlur;
    
    if (shouldBlur && !this.isBlurActive) {
      if (this.gameElementsContainer && !this.gameElementsBlurEffect) {
        this.gameElementsBlurEffect = this.gameElementsContainer.postFX.addBlur(0, 2, 2, 1, 0xffffff, 4);
      }
      this.isBlurActive = true;
    } else if (!shouldBlur && this.isBlurActive) {
      if (this.gameElementsBlurEffect) {
        this.gameElementsContainer.postFX.remove(this.gameElementsBlurEffect);
        this.gameElementsBlurEffect = null;
      }
      this.isBlurActive = false;
    }
  }
  
  
  
  
  
  
  
  
  
  drawGame() {
    // Stars are updated in updateGame with frame skipping
    
    const now = this.time.now;
    if ((now - this.lastBlurUpdate) >= this.blurUpdateInterval) {
      this.updateBlurEffect();
      this.lastBlurUpdate = now;
    }
    
    if (this.isHyperspeed) {
      if (this.playerTrail.length >= 2) {
      this.trailGraphics.clear();
      const color = getColor(this.themeManager, COLOR_PATHS.PLAYER.HYPERSPEED.MAIN);
      this.trailGraphics.fillStyle(color);
      
      for (let i = 0; i < this.playerTrail.length - 1; i++) {
        const progress = i / (this.playerTrail.length - 1);
        const alpha = Math.max(0, 0.15 * (1 - progress));
        if (alpha <= 0) continue;
        
        this.trailGraphics.setAlpha(alpha);
        this.trailGraphics.fillRect(this.playerTrail[i].x, this.playerTrail[i].y, 1, 1);
      }
      this.trailGraphics.setAlpha(1);
      }
      
      this.drawAirRushEffect();
      this.engineFireGraphics.clear();
    } else {
      this.trailGraphics.clear();
      this.airRushGraphics.clear();
      this.drawEngineFire();
    }
    
    // Particles are now drawn by ParticleManager in update()
    
    const obstacles = this.getCachedChildren('obstacles');
    const obstaclesLength = obstacles.length;
    for (let i = 0; i < obstaclesLength; i++) {
      const obstacle = obstacles[i];
      if (!this.isActive(obstacle)) continue;
      this.obstacleManager.drawObstacle(obstacle);
    }
    
    if (this.isActive(this.boss)) {
      this.drawBoss(this.boss, this.boss.x, this.boss.y, this.boss.health, this.boss.maxHealth, this.bossPattern, this.boss.type);
    }
    
    const bossBullets = this.getCachedChildren('bossBullets');
    const bossBulletsLength = bossBullets.length;
    for (let i = 0; i < bossBulletsLength; i++) {
      const bullet = bossBullets[i];
      if (!this.isActive(bullet)) continue;
      this.bulletManager.drawBullet(bullet, bullet.x, bullet.y, true);
    }
    
    const bullets = this.getCachedChildren('bullets');
    const bulletsLength = bullets.length;
    for (let i = 0; i < bulletsLength; i++) {
      const bullet = bullets[i];
      if (!this.isActive(bullet)) continue;
      this.bulletManager.drawBullet(bullet, bullet.x, bullet.y, false);
    }
    
    const energies = this.getCachedChildren('energies');
    const energiesLength = energies.length;
    for (let i = 0; i < energiesLength; i++) {
      const energy = energies[i];
      if (!this.isActive(energy)) continue;
      this.energyManager.drawEnergy(energy, energy.x, energy.y, energy.size);
    }
    
    const powerups = this.getCachedChildren('powerups');
    const powerupsLength = powerups.length;
    for (let i = 0; i < powerupsLength; i++) {
      const powerup = powerups[i];
      if (!this.isActive(powerup)) continue;
      this.powerupManager.drawPowerup(powerup, powerup.x, powerup.y, powerup.type, this.time.now);
    }
    
    this.drawPlayer(this.player);
    
    if (this.isShieldActive) {
      this.shieldGraphics.clear();
      const shieldSize = PLAYER_SIZE + 8;
      const time = this.time.now;
      const pulse = Math.sin(time / 200) * 0.3 + 0.7;
      
      this.shieldGraphics.setAlpha(pulse * 0.5);
      const shieldColor = getParticleColor(this.themeManager, PARTICLE_TYPES.SHIELD);
      this.shieldGraphics.lineStyle(2, shieldColor);
      this.shieldGraphics.strokeCircle(this.player.x, this.player.y, shieldSize / 2);
      this.shieldGraphics.setAlpha(1);
    } else {
      this.shieldGraphics.clear();
    }
    
    this.drawUI();
  }
  
  drawAirRushEffect() {
    if (!this.isHyperspeed) {
      this.airRushGraphics.clear();
      return;
    }
    
    this.airRushGraphics.clear();
    const playerX = Math.floor(this.player.x);
    const playerY = Math.floor(this.player.y);
    const time = this.time.now;
    const isDark = this.themeManager.isDark;
    
    const coreColor = isDark ? 0xfbbf24 : 0xf59e0b;
    const hotColor = isDark ? 0xfcd34d : 0xf97316;
    const brightColor = isDark ? 0xfef3c7 : 0xfffbeb;
    const outerColor = isDark ? 0xffffff : 0xe0e7ff;
    const darkColor = isDark ? 0x1e293b : 0x312e81;
    
    const pattern = time * 0.05;
    const pulse = Math.sin(time * 0.012) * 0.25 + 0.75;
    
    const trailLength = 25;
    const startX = playerX - 6;
    const maxWidth = 10;
    
    for (let layer = 0; layer < 3; layer++) {
      const layerProgress = layer / 3;
      const layerAlpha = (1 - layerProgress * 0.25) * pulse * 0.5;
      const layerSpeed = 1 + layer * 0.12;
      
      for (let i = -5; i <= 5; i++) {
        const offsetY = i * 1;
        const wavePhase = pattern * layerSpeed + i * 0.2 + layerProgress;
        const waveOffset = Math.sin(wavePhase) * (1.2 + Math.abs(i) * 0.1);
        
        for (let j = 0; j < trailLength; j++) {
          const progress = j / trailLength;
          const distance = j * 2;
          const trailX = Math.floor(startX - distance);
          const trailY = Math.floor(playerY + offsetY + waveOffset * (1 - progress * 0.4));
          
          if (trailX < 0 || trailX > this.gameWidth) continue;
          
          const fadeAlpha = Math.pow(1 - progress, 1.8) * layerAlpha;
          if (fadeAlpha <= 0.05) continue;
          
          const widthFactor = 1 - progress * 0.7;
          const currentWidth = Math.max(1, Math.floor(maxWidth * widthFactor));
          
          let color;
          let size = 1;
          
          if (j < 2) {
            color = brightColor;
            size = 1;
          } else if (j < 6) {
            color = outerColor;
            size = 1;
          } else {
            color = outerColor;
            size = 1;
          }
          
          const distFromCenter = Math.abs(offsetY + waveOffset * (1 - progress * 0.4));
          const widthAlpha = distFromCenter < currentWidth ? 1 : Math.max(0, 1 - (distFromCenter - currentWidth) / 2);
          
          this.airRushGraphics.setAlpha(fadeAlpha * widthAlpha * 0.6);
          this.airRushGraphics.fillStyle(color);
          this.airRushGraphics.fillRect(trailX, trailY, 1, 1);
        }
      }
    }
    
    for (let streak = 0; streak < 4; streak++) {
      const streakOffset = (streak - 1.5) * 2;
      const streakPhase = pattern * 1.5 + streak * 0.5;
      const streakWave = Math.sin(streakPhase) * 1.5;
      
      for (let j = 0; j < 15; j++) {
        const progress = j / 15;
        const distance = j * 2.2;
        const trailX = Math.floor(startX - distance);
        const trailY = Math.floor(playerY + streakOffset + streakWave * (1 - progress * 0.5));
        
        if (trailX < 0 || trailX > this.gameWidth) continue;
        
        const fadeAlpha = (1 - progress) * 0.4 * pulse;
        if (fadeAlpha <= 0.08) continue;
        
        this.airRushGraphics.setAlpha(fadeAlpha);
        this.airRushGraphics.fillStyle(j < 4 ? brightColor : outerColor);
        this.airRushGraphics.fillRect(trailX, trailY, 1, 1);
      }
    }
    
    for (let spark = 0; spark < 6; spark++) {
      const sparkPhase = pattern * 2.5 + spark * 0.8;
      const sparkDistance = 3 + (spark % 2) * 5;
      const sparkX = Math.floor(startX - sparkDistance);
      const sparkOffset = (spark - 3) * 1.5;
      const sparkY = Math.floor(playerY + sparkOffset + Math.sin(sparkPhase) * 1.5);
      
      if (sparkX < 0 || sparkX > this.gameWidth) continue;
      
      const sparkAlpha = (Math.sin(sparkPhase) * 0.4 + 0.6) * 0.5;
      
      this.airRushGraphics.setAlpha(sparkAlpha * pulse);
      this.airRushGraphics.fillStyle(brightColor);
      this.airRushGraphics.fillRect(sparkX, sparkY, 1, 1);
    }
    
    this.airRushGraphics.setAlpha(1);
  }
  
  drawEngineFire() {
    if (this.isHyperspeed) {
      this.engineFireGraphics.clear();
      return;
    }
    
    this.engineFireGraphics.clear();
    const playerX = this.player.x;
    const playerY = this.player.y;
    const time = this.time.now;
    const isDark = this.themeManager.isDark;
    
    const fireOuterColor = isDark ? 0xf59e0b : 0xea580c;
    const fireMiddleColor = isDark ? 0xfbbf24 : 0xf97316;
    const fireCoreColor = isDark ? 0xfef3c7 : 0xfffbeb;
    
    const pattern = time * 0.02;
    const pulse = Math.sin(time * 0.015) * 0.15 + 0.85;
    
    for (let i = -2; i <= 2; i++) {
      const offsetY = i;
      const waveOffset = Math.sin(pattern + i * 0.5) * 0.8;
      
      for (let j = 0; j < 4; j++) {
        const trailX = playerX - 6 - j * 2;
        const trailY = playerY + offsetY + waveOffset;
        const alpha = (1 - j / 4) * 0.6 * pulse;
        const size = 1 + (j > 1 ? 1 : 0);
        
        if (alpha <= 0) continue;
        
        this.engineFireGraphics.setAlpha(alpha);
        if (j < 2) {
          this.engineFireGraphics.fillStyle(fireOuterColor);
        } else {
          this.engineFireGraphics.fillStyle(fireMiddleColor);
        }
        this.engineFireGraphics.fillRect(trailX, trailY, size, size);
      }
    }
    
    this.engineFireGraphics.setAlpha(0.8 * pulse);
    this.engineFireGraphics.fillStyle(fireCoreColor);
    this.engineFireGraphics.fillRect(playerX - 7, playerY - 1, 1, 3);
    this.engineFireGraphics.fillRect(playerX - 8, playerY, 1, 2);
    
    this.engineFireGraphics.setAlpha(1);
  }
  
  drawLives() {
    if (!this.livesGraphics) {
      this.livesGraphics = this.add.graphics();
      this.livesGraphics.setDepth(1000);
    }
    
    this.livesGraphics.clear();
    const livesColor = getColor(this.themeManager, COLOR_PATHS.UI.LIVES);
    let livesColorHex = livesColor;
    if (typeof livesColor === 'string') {
      const hexString = livesColor.startsWith('#') ? livesColor.substring(1) : livesColor;
      livesColorHex = parseInt(hexString, 16);
    }
    const emptyColor = this.themeManager.isDark ? 0x4b5563 : 0x9ca3af;
    
    const heartSize = 6 * this.fontScale;
    const heartSpacing = 8 * this.fontScale;
    const startX = 8 * this.fontScale;
    const startY = 70 * this.fontScale;
    
    for (let i = 0; i < 5; i++) {
      const x = startX + i * heartSpacing;
      const y = startY;
      const isFull = i < this.lives;
      
      this.drawHeart(this.livesGraphics, x, y, heartSize, isFull ? livesColorHex : emptyColor, isFull);
    }
  }
  
  drawSoundIndicator() {
    if (!this.soundIndicatorGraphics) {
      this.soundIndicatorGraphics = this.add.graphics();
      this.soundIndicatorGraphics.setDepth(1000);
    }
    
    if (!this.soundIndicatorText) {
      const textColorHex = getColor(this.themeManager, COLOR_PATHS.UI.SCORE);
      const textColor = colorToHex(textColorHex);
      this.soundIndicatorText = this.add.text(0, 0, '', {
        fontSize: `${this.getFontSize(7)}px`,
        fontFamily: 'Consolas, "Courier New", monospace',
        color: textColor
      });
      this.soundIndicatorText.setDepth(1001);
    }
    
    const isSoundEnabled = this.soundManager && this.soundManager.soundsEnabled;
    const iconSize = 12 * this.fontScale;
    const padding = 8 * this.fontScale;
    const indicatorX = this.gameWidth - iconSize - padding;
    const indicatorY = this.gameHeight - iconSize - padding;
    
    this.soundIndicatorGraphics.clear();
    
    const soundColor = isSoundEnabled 
      ? (this.themeManager.isDark ? 0x10b981 : 0x16a34a)
      : (this.themeManager.isDark ? 0x6b7280 : 0x9ca3af);
    
    this.soundIndicatorGraphics.fillStyle(soundColor);
    
    const pixelSize = Math.max(1, Math.floor(this.fontScale));
    const startX = indicatorX;
    const startY = indicatorY + iconSize / 2;
    
    // Speaker body - trapezoid (left side wider)
    // Top row
    drawPixel(this.soundIndicatorGraphics, startX, startY - 2 * pixelSize, pixelSize);
    drawPixel(this.soundIndicatorGraphics, startX + pixelSize, startY - 2 * pixelSize, pixelSize);
    drawPixel(this.soundIndicatorGraphics, startX + 2 * pixelSize, startY - 2 * pixelSize, pixelSize);
    drawPixel(this.soundIndicatorGraphics, startX + 3 * pixelSize, startY - 2 * pixelSize, pixelSize);
    
    // Middle rows
    drawPixel(this.soundIndicatorGraphics, startX, startY - 1 * pixelSize, pixelSize);
    drawPixel(this.soundIndicatorGraphics, startX + pixelSize, startY - 1 * pixelSize, pixelSize);
    drawPixel(this.soundIndicatorGraphics, startX + 2 * pixelSize, startY - 1 * pixelSize, pixelSize);
    
    drawPixel(this.soundIndicatorGraphics, startX, startY, pixelSize);
    drawPixel(this.soundIndicatorGraphics, startX + pixelSize, startY, pixelSize);
    drawPixel(this.soundIndicatorGraphics, startX + 2 * pixelSize, startY, pixelSize);
    
    drawPixel(this.soundIndicatorGraphics, startX, startY + 1 * pixelSize, pixelSize);
    drawPixel(this.soundIndicatorGraphics, startX + pixelSize, startY + 1 * pixelSize, pixelSize);
    drawPixel(this.soundIndicatorGraphics, startX + 2 * pixelSize, startY + 1 * pixelSize, pixelSize);
    
    // Bottom row
    drawPixel(this.soundIndicatorGraphics, startX, startY + 2 * pixelSize, pixelSize);
    drawPixel(this.soundIndicatorGraphics, startX + pixelSize, startY + 2 * pixelSize, pixelSize);
    drawPixel(this.soundIndicatorGraphics, startX + 2 * pixelSize, startY + 2 * pixelSize, pixelSize);
    drawPixel(this.soundIndicatorGraphics, startX + 3 * pixelSize, startY + 2 * pixelSize, pixelSize);
    
    // Speaker cone - triangle pointing right
    const coneX = startX + 4 * pixelSize;
    drawPixel(this.soundIndicatorGraphics, coneX, startY - 1 * pixelSize, pixelSize);
    drawPixel(this.soundIndicatorGraphics, coneX + pixelSize, startY - 1 * pixelSize, pixelSize);
    drawPixel(this.soundIndicatorGraphics, coneX, startY, pixelSize);
    drawPixel(this.soundIndicatorGraphics, coneX + pixelSize, startY, pixelSize);
    drawPixel(this.soundIndicatorGraphics, coneX + 2 * pixelSize, startY, pixelSize);
    drawPixel(this.soundIndicatorGraphics, coneX, startY + 1 * pixelSize, pixelSize);
    drawPixel(this.soundIndicatorGraphics, coneX + pixelSize, startY + 1 * pixelSize, pixelSize);
    
    const waveX = coneX + 3 * pixelSize;
    
    if (isSoundEnabled) {
      // Sound waves - 3 arcs
      // Wave 1 (small, close)
      drawPixel(this.soundIndicatorGraphics, waveX, startY - 1 * pixelSize, pixelSize);
      drawPixel(this.soundIndicatorGraphics, waveX, startY, pixelSize);
      drawPixel(this.soundIndicatorGraphics, waveX, startY + 1 * pixelSize, pixelSize);
      drawPixel(this.soundIndicatorGraphics, waveX + pixelSize, startY - 2 * pixelSize, pixelSize);
      drawPixel(this.soundIndicatorGraphics, waveX + pixelSize, startY + 2 * pixelSize, pixelSize);
      
      // Wave 2 (medium)
      drawPixel(this.soundIndicatorGraphics, waveX + 2 * pixelSize, startY - 2 * pixelSize, pixelSize);
      drawPixel(this.soundIndicatorGraphics, waveX + 2 * pixelSize, startY, pixelSize);
      drawPixel(this.soundIndicatorGraphics, waveX + 2 * pixelSize, startY + 2 * pixelSize, pixelSize);
      drawPixel(this.soundIndicatorGraphics, waveX + 3 * pixelSize, startY - 3 * pixelSize, pixelSize);
      drawPixel(this.soundIndicatorGraphics, waveX + 3 * pixelSize, startY + 3 * pixelSize, pixelSize);
      
      // Wave 3 (large)
      drawPixel(this.soundIndicatorGraphics, waveX + 4 * pixelSize, startY - 3 * pixelSize, pixelSize);
      drawPixel(this.soundIndicatorGraphics, waveX + 4 * pixelSize, startY, pixelSize);
      drawPixel(this.soundIndicatorGraphics, waveX + 4 * pixelSize, startY + 3 * pixelSize, pixelSize);
      drawPixel(this.soundIndicatorGraphics, waveX + 5 * pixelSize, startY - 4 * pixelSize, pixelSize);
      drawPixel(this.soundIndicatorGraphics, waveX + 5 * pixelSize, startY + 4 * pixelSize, pixelSize);
    } else {
      // Diagonal mute line
      const muteStartX = startX - pixelSize;
      const muteStartY = startY - 3 * pixelSize;
      const muteEndX = waveX + 6 * pixelSize;
      const muteEndY = startY + 3 * pixelSize;
      
      const dx = muteEndX - muteStartX;
      const dy = muteEndY - muteStartY;
      const steps = Math.max(Math.abs(dx), Math.abs(dy));
      
      for (let i = 0; i <= steps; i++) {
        const t = i / steps;
        const x = Math.round(muteStartX + dx * t);
        const y = Math.round(muteStartY + dy * t);
        drawPixel(this.soundIndicatorGraphics, x, y, pixelSize);
        drawPixel(this.soundIndicatorGraphics, x, y - pixelSize, pixelSize);
      }
    }
    
    // Update text
    const statusText = isSoundEnabled ? 'ON' : 'OFF';
    const textColorHex = getColor(this.themeManager, COLOR_PATHS.UI.SCORE);
    const textColor = colorToHex(textColorHex);
    this.soundIndicatorText.setText(statusText);
    this.soundIndicatorText.setPosition(indicatorX - 30 * this.fontScale, indicatorY + 2 * this.fontScale);
    this.soundIndicatorText.setColor(textColor);
    this.soundIndicatorText.setAlpha(isSoundEnabled ? 1 : 0.6);
    this.soundIndicatorText.setVisible(true);
  }
  
  drawHeart(graphics, x, y, size, color, isFull) {
    graphics.fillStyle(color);
    const centerX = x + size / 2;
    const centerY = y + size / 2;
    const scale = Math.max(1, Math.floor(size / 6));
    
    if (isFull) {
      drawPixel(graphics, centerX - 2 * scale, centerY - 1 * scale, scale);
      drawPixel(graphics, centerX - 1 * scale, centerY - 2 * scale, scale);
      drawPixel(graphics, centerX, centerY - 2 * scale, scale);
      drawPixel(graphics, centerX + 1 * scale, centerY - 1 * scale, scale);
      drawPixel(graphics, centerX - 1 * scale, centerY, scale);
      drawPixel(graphics, centerX, centerY, scale);
      drawPixel(graphics, centerX + 1 * scale, centerY, scale);
      drawPixel(graphics, centerX, centerY + 1 * scale, scale);
    } else {
      graphics.setAlpha(0.3);
      graphics.fillStyle(color);
      drawPixel(graphics, centerX - 2 * scale, centerY - 1 * scale, scale);
      drawPixel(graphics, centerX - 1 * scale, centerY - 2 * scale, scale);
      drawPixel(graphics, centerX, centerY - 2 * scale, scale);
      drawPixel(graphics, centerX + 1 * scale, centerY - 1 * scale, scale);
      drawPixel(graphics, centerX - 1 * scale, centerY, scale);
      drawPixel(graphics, centerX, centerY, scale);
      drawPixel(graphics, centerX + 1 * scale, centerY, scale);
      drawPixel(graphics, centerX, centerY + 1 * scale, scale);
      graphics.setAlpha(1);
    }
  }
  
  drawUI() {
    const now = this.time.now;
    const shouldUpdateUI = (now - this.lastUIUpdate) >= this.uiUpdateInterval;
    
    // Use UpdateManager for conditional updates
    const shouldUpdate = shouldUpdateUI || this.gameOver || this.isPaused || !this.gameStarted;
    
    if (!shouldUpdate && this.updateManager && !this.updateManager.shouldUpdate('ui', this.frameCount)) {
      // Only update combo text pulse if needed
      if (this.comboText && this.combo > 1) {
        const comboPulse = this.comboFlash > 0 ? 1 + Math.sin(this.time.now / 100) * 0.3 : 1;
        const baseComboSize = this.getFontSize(8 + (this.combo - 2) * 0.5);
        this.comboText.setFontSize(`${baseComboSize * comboPulse}px`);
      }
      return;
    }
    
    this.lastUIUpdate = now;
    
    const textColorHex = getColor(this.themeManager, COLOR_PATHS.UI.SCORE);
    const textColor = colorToHex(textColorHex);
    const borderColorHex = getColor(this.themeManager, COLOR_PATHS.BORDER);
    const lineColor = colorToHex(borderColorHex);
    
    const comboPulse = this.comboFlash > 0 ? 1 + Math.sin(this.time.now / 100) * 0.3 : 1;
    const scorePulse = this.scoreFlash > 0 ? 1 + Math.sin(this.time.now / 150) * 0.2 : 1;
    
    if (!this.uiText) {
      this.uiText = this.add.text(8 * this.fontScale, 8 * this.fontScale, '', {
        fontSize: `${this.getFontSize(10)}px`,
        fontFamily: 'Consolas, "Courier New", monospace',
        color: textColor
      });
      this.uiText.setDepth(1000);
    }
    
    const scoreText = `SPACE RUNNER\nSCORE: ${this.score}\nHIGH: ${this.highScore}\nLVL: ${this.level}\nKILLS: ${this.kills}`;
    if (this.uiText.text !== scoreText) {
      this.uiText.setText(scoreText);
    }
    const baseScoreSize = this.getFontSize(8);
    const newScoreSize = scorePulse > 1 ? `${baseScoreSize * scorePulse}px` : `${baseScoreSize}px`;
    if (this.uiText.style.fontSize !== newScoreSize) {
      this.uiText.setFontSize(newScoreSize);
    }
    const scoreColor = getColor(this.themeManager, COLOR_PATHS.UI.SCORE);
    const scoreColorHex = colorToHex(scoreColor);
    if (this.uiText.style.color !== scoreColorHex) {
      this.uiText.setColor(scoreColorHex);
    }
    
    this.drawLives();
    
    // Draw sound indicator in top right corner
    this.drawSoundIndicator();
    
    const levelProgress = this.getLevelProgress(this.score);
    const progressBarWidth = 60 * this.fontScale;
    const progressBarHeight = 3 * this.fontScale;
    const progressBarX = 8 * this.fontScale;
    const progressBarY = 82 * this.fontScale;
    
    if (!this.progressBarBg) {
      this.progressBarBg = this.add.graphics();
      this.progressBarBg.setDepth(1000);
    }
      this.progressBarBg.clear();
      this.progressBarBg.fillStyle(getColor(this.themeManager, COLOR_PATHS.UI.PROGRESS_BG));
      this.progressBarBg.fillRect(progressBarX, progressBarY, progressBarWidth, progressBarHeight);
      this.progressBarBg.setVisible(true);
    
    if (!this.progressBar) {
      this.progressBar = this.add.graphics();
      this.progressBar.setDepth(1000);
    }
    const newProgressWidth = progressBarWidth * levelProgress;
      this.progressBar.clear();
      this.progressBar.fillStyle(getColor(this.themeManager, COLOR_PATHS.UI.PROGRESS_FILL));
      this.progressBar.fillRect(progressBarX, progressBarY, newProgressWidth, progressBarHeight);
      this.progressBar.setVisible(true);
    
    let yOffset = 0;
    
    const powerupConfigs = [
      { isActive: this.isHyperspeed, textRef: 'hyperspeedText', endTime: this.hyperspeedEndTime, name: 'HYPERSPEED', color: getParticleColor(this.themeManager, PARTICLE_TYPES.HYPERSPEED) },
      { isActive: this.isAutoAimActive, textRef: 'autoAimText', endTime: this.autoAimEndTime, name: 'AUTO AIM', color: getParticleColor(this.themeManager, PARTICLE_TYPES.AUTO_AIM) },
      { isActive: this.isMagnetActive, textRef: 'magnetText', endTime: this.magnetEndTime, name: 'MAGNET', color: getParticleColor(this.themeManager, PARTICLE_TYPES.MAGNET) },
      { isActive: this.isSlowMotionActive, textRef: 'slowMotionText', endTime: this.slowMotionEndTime, name: 'SLOW MOTION', color: getParticleColor(this.themeManager, PARTICLE_TYPES.SLOW_MOTION) }
    ];
    
    for (const config of powerupConfigs) {
      if (config.isActive) {
        const remainingSeconds = this.getRemainingSeconds(config.isActive, config.endTime);
        if (!this[config.textRef]) {
          this[config.textRef] = this.add.text(8 * this.fontScale, (90 + yOffset) * this.fontScale, '', {
            fontSize: `${this.getFontSize(10)}px`,
            fontFamily: 'Consolas, "Courier New", monospace',
            color: colorToHex(config.color)
          });
          this[config.textRef].setDepth(1000);
        }
        this[config.textRef].setY((90 + yOffset) * this.fontScale);
        this[config.textRef].setText(`${config.name} ${remainingSeconds}s`);
        this[config.textRef].setVisible(true);
        yOffset += 18;
      } else if (this[config.textRef]) {
        this[config.textRef].setVisible(false);
      }
    }
    
    if (this.combo > 1) {
      const activePowerups = [this.isHyperspeed, this.isAutoAimActive, this.isMagnetActive, this.isSlowMotionActive].filter(Boolean).length;
      const comboYOffset = activePowerups * 18;
      const comboY = (90 + comboYOffset) * this.fontScale;
      
      if (!this.comboText) {
        const comboColor = getColor(this.themeManager, COLOR_PATHS.UI.COMBO);
        this.comboText = this.add.text(8 * this.fontScale, comboY, '', {
          fontSize: `${this.getFontSize(8 + (this.combo - 2) * 0.5)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: colorToHex(comboColor)
        });
        this.comboText.setDepth(1000);
      }
      if (this.comboText.y !== comboY) {
        this.comboText.setY(comboY);
      }
      const baseComboSize = this.getFontSize(8 + (this.combo - 2) * 0.5);
      this.comboText.setFontSize(`${baseComboSize * comboPulse}px`);
      this.comboText.setText(`COMBO x${this.combo}!`);
      this.comboText.setVisible(true);
    } else if (this.comboText) {
      this.comboText.setVisible(false);
    }
    
    let powerupY = 22 * this.fontScale;
    
    const rightSideConfigs = [
      { isActive: this.isHyperspeed, textRef: 'hyperspeedText', endTime: this.hyperspeedEndTime, name: 'HYPERSPEED', color: getColor(this.themeManager, COLOR_PATHS.UI.POWERUP), hasTimer: true, depth: 203 },
      { isActive: this.isTripleShot, textRef: 'tripleShotText', endTime: this.tripleShotEndTime, name: 'TRIPLE', color: this.isDark ? 0xec4899 : 0xbe185d, hasTimer: true, depth: 1000 },
      { isActive: this.isShieldActive, textRef: 'shieldText', endTime: this.shieldEndTime, name: 'SHIELD', color: this.isDark ? 0x10b981 : 0x16a34a, hasTimer: true, depth: 1000 },
      { isActive: this.cheats.wallHack, textRef: 'wallHackText', endTime: 0, name: 'WALL HACK', color: this.isDark ? 0x10b981 : 0x16a34a, hasTimer: false, depth: 1000 },
      { isActive: this.cheats.noBlur, textRef: 'noBlurText', endTime: 0, name: 'NO BLUR', color: this.isDark ? 0xf59e0b : 0xea580c, hasTimer: false, depth: 1000 },
      { isActive: this.cheats.godMode, textRef: 'godModeText', endTime: 0, name: 'GOD MODE', color: getColor(this.themeManager, COLOR_PATHS.UI.POWERUP), hasTimer: false, depth: 1000 },
      { isActive: this.cheats.infiniteLives, textRef: 'infiniteLivesText', endTime: 0, name: 'INF LIVES', color: getColor(this.themeManager, COLOR_PATHS.UI.POWERUP), hasTimer: false, depth: 1000 },
      { isActive: this.cheats.infinitePowerups, textRef: 'infinitePowerupsText', endTime: 0, name: 'INF POWERUPS', color: getColor(this.themeManager, COLOR_PATHS.UI.POWERUP), hasTimer: false, depth: 1000 },
      { isActive: this.cheats.oneHitKill, textRef: 'oneHitKillText', endTime: 0, name: 'ONE HIT KILL', color: getColor(this.themeManager, COLOR_PATHS.UI.POWERUP), hasTimer: false, depth: 1000 }
    ];
    
    for (const config of rightSideConfigs) {
      if (config.isActive) {
        if (!this[config.textRef]) {
          this[config.textRef] = this.add.text(this.gameWidth - 110 * this.fontScale, powerupY, '', {
          fontSize: `${this.getFontSize(8)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
            color: colorToHex(config.color)
          });
          this[config.textRef].setDepth(config.depth);
        }
        const text = config.hasTimer ? `${config.name}! ${Math.ceil((config.endTime - this.time.now) / 1000)}s` : `${config.name}!`;
        if (this[config.textRef].text !== text) {
          this[config.textRef].setText(text);
      }
      const newX = this.gameWidth - 110 * this.fontScale;
        if (this[config.textRef].x !== newX || this[config.textRef].y !== powerupY) {
          this[config.textRef].setPosition(newX, powerupY);
      }
        if (!this[config.textRef].visible) {
          this[config.textRef].setVisible(true);
      }
      powerupY += 12 * this.fontScale;
      } else if (this[config.textRef] && this[config.textRef].visible) {
        this[config.textRef].setVisible(false);
      }
    }
    
    if (this.isPaused) {
      if (!this.pauseOverlay) {
        this.pauseOverlay = this.add.graphics();
        const textColorHex = getColor(this.themeManager, COLOR_PATHS.UI.SCORE);
        const textColorStr = colorToHex(textColorHex);
        this.pauseText = this.add.text(this.gameWidth / 2, this.gameHeight / 2 - 20 * this.fontScale, 'PAUSED', {
          fontSize: `${this.getFontSize(14)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: textColorStr
        }).setOrigin(0.5);
        this.pauseSubtext = this.add.text(this.gameWidth / 2, this.gameHeight / 2, 'PRESS P TO RESUME', {
          fontSize: `${this.getFontSize(8)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: textColorStr
        }).setOrigin(0.5);
      }
      this.pauseOverlay.clear();
      this.pauseOverlay.fillStyle(0x000000, 0.8);
      this.pauseOverlay.fillRect(0, 0, this.gameWidth, this.gameHeight);
      
      this.pauseText.setVisible(true);
      this.pauseSubtext.setVisible(true);
      this.drawCheatInput();
    } else if (this.pauseOverlay) {
      this.pauseOverlay.setVisible(false);
      this.pauseText.setVisible(false);
      this.pauseSubtext.setVisible(false);
      if (this.cheatInputText) this.cheatInputText.setVisible(false);
    }
    
    if (!this.gameStarted && !this.gameOver) {
      if (!this.startText) {
        const startTextColor = colorToHex(textColorHex);
        const isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;
        const soundKey = isMac ? 'CMD+SHIFT+S' : 'CTRL+SHIFT+S';
        const centerX = this.gameWidth / 2;
        let currentY = this.gameHeight / 2 - 50 * this.fontScale;
        
        // Title - larger and more prominent
        this.startText = this.add.text(centerX, currentY, 'SPACE RUNNER', {
          fontSize: `${this.getFontSize(16)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: startTextColor,
          fontStyle: 'bold'
        }).setOrigin(0.5);
        this.startText.setDepth(1000);
        currentY += 30 * this.fontScale;
        
        // Main instruction - blinking
        this.startSubtext = this.add.text(centerX, currentY, 'PRESS ANY KEY TO START', {
          fontSize: `${this.getFontSize(10)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: startTextColor
        }).setOrigin(0.5);
        this.startSubtext.setDepth(1000);
        currentY += 25 * this.fontScale;
        
        // Divider line
        if (!this.startDivider1) {
          this.startDivider1 = this.add.graphics();
          this.startDivider1.setDepth(1000);
        }
        const dividerColor = getColor(this.themeManager, COLOR_PATHS.BORDER);
        this.startDivider1.clear();
        this.startDivider1.lineStyle(1, dividerColor, 0.5);
        this.startDivider1.lineBetween(
          centerX - 80 * this.fontScale, currentY,
          centerX + 80 * this.fontScale, currentY
        );
        this.startDivider1.setVisible(true);
        currentY += 15 * this.fontScale;
        
        // Controls section - more compact
        this.startControlsTitle = this.add.text(centerX, currentY, 'CONTROLS', {
          fontSize: `${this.getFontSize(9)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: startTextColor,
          fontStyle: 'bold'
        }).setOrigin(0.5);
        this.startControlsTitle.setDepth(1000);
        currentY += 12 * this.fontScale;
        
        this.startControls1 = this.add.text(centerX, currentY, 'ARROWS: MOVE  |  SPACE: SHOOT', {
          fontSize: `${this.getFontSize(7)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: startTextColor
        }).setOrigin(0.5);
        this.startControls1.setDepth(1000);
        currentY += 10 * this.fontScale;
        
        this.startControls2 = this.add.text(centerX, currentY, `P/ESC: PAUSE  |  ${soundKey}: SOUND`, {
          fontSize: `${this.getFontSize(7)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: startTextColor
        }).setOrigin(0.5);
        this.startControls2.setDepth(1000);
        currentY += 15 * this.fontScale;
        
        // Divider line
        if (!this.startDivider2) {
          this.startDivider2 = this.add.graphics();
          this.startDivider2.setDepth(1000);
        }
        this.startDivider2.clear();
        this.startDivider2.lineStyle(1, dividerColor, 0.5);
        this.startDivider2.lineBetween(
          centerX - 80 * this.fontScale, currentY,
          centerX + 80 * this.fontScale, currentY
        );
        this.startDivider2.setVisible(true);
        currentY += 15 * this.fontScale;
        
        // Gameplay tips - more compact
        this.startTipsTitle = this.add.text(centerX, currentY, 'TIPS', {
          fontSize: `${this.getFontSize(9)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: startTextColor,
          fontStyle: 'bold'
        }).setOrigin(0.5);
        this.startTipsTitle.setDepth(1000);
        currentY += 12 * this.fontScale;
        
        this.startTips1 = this.add.text(centerX, currentY, '• COLLECT ENERGY FOR SCORE', {
          fontSize: `${this.getFontSize(7)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: startTextColor
        }).setOrigin(0.5);
        this.startTips1.setDepth(1000);
        currentY += 10 * this.fontScale;
        
        this.startTips2 = this.add.text(centerX, currentY, '• POWER-UPS GIVE SPECIAL ABILITIES', {
          fontSize: `${this.getFontSize(7)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: startTextColor
        }).setOrigin(0.5);
        this.startTips2.setDepth(1000);
        currentY += 10 * this.fontScale;
        
        this.startTips3 = this.add.text(centerX, currentY, '• DEFEAT BOSSES FOR BONUS LIVES', {
          fontSize: `${this.getFontSize(7)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: startTextColor
        }).setOrigin(0.5);
        this.startTips3.setDepth(1000);
      }
      
      // Animate blinking instruction
      const blink = Math.sin(this.time.now / 500) > 0;
      this.startText.setVisible(true);
      this.startSubtext.setVisible(blink);
      this.startSubtext.setAlpha(blink ? 1 : 0.3);
      
      // Update divider positions dynamically
      if (this.startDivider1 && this.startDivider2 && this.startControlsTitle && this.startControls2) {
        const centerX = this.gameWidth / 2;
        const divider1Y = this.startControlsTitle.y - 8 * this.fontScale;
        const divider2Y = this.startControls2.y + 8 * this.fontScale;
        const dividerColor = getColor(this.themeManager, COLOR_PATHS.BORDER);
        
        this.startDivider1.clear();
        this.startDivider1.lineStyle(1, dividerColor, 0.5);
        this.startDivider1.lineBetween(
          centerX - 80 * this.fontScale, divider1Y,
          centerX + 80 * this.fontScale, divider1Y
        );
        
        this.startDivider2.clear();
        this.startDivider2.lineStyle(1, dividerColor, 0.5);
        this.startDivider2.lineBetween(
          centerX - 80 * this.fontScale, divider2Y,
          centerX + 80 * this.fontScale, divider2Y
        );
      }
      
      this.startControlsTitle.setVisible(true);
      this.startControls1.setVisible(true);
      this.startControls2.setVisible(true);
      this.startTipsTitle.setVisible(true);
      this.startTips1.setVisible(true);
      this.startTips2.setVisible(true);
      this.startTips3.setVisible(true);
    } else {
      if (this.startText) this.startText.setVisible(false);
      if (this.startSubtext) this.startSubtext.setVisible(false);
      if (this.startControlsTitle) this.startControlsTitle.setVisible(false);
      if (this.startControls1) this.startControls1.setVisible(false);
      if (this.startControls2) this.startControls2.setVisible(false);
      if (this.startDivider1) this.startDivider1.setVisible(false);
      if (this.startDivider2) this.startDivider2.setVisible(false);
      if (this.startTipsTitle) this.startTipsTitle.setVisible(false);
      if (this.startTips1) this.startTips1.setVisible(false);
      if (this.startTips2) this.startTips2.setVisible(false);
      if (this.startTips3) this.startTips3.setVisible(false);
    }
    
    if (this.gameOver) {
      if (!this.gameOverOverlay) {
        this.gameOverOverlay = this.add.graphics();
        const gameOverTextColor = colorToHex(textColorHex);
        this.gameOverText = this.add.text(this.gameWidth / 2, this.gameHeight / 2 - 40 * this.fontScale, 'GAME OVER', {
          fontSize: `${this.getFontSize(12)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: gameOverTextColor
        }).setOrigin(0.5);
        this.gameOverScore = this.add.text(this.gameWidth / 2, this.gameHeight / 2 - 20 * this.fontScale, '', {
          fontSize: `${this.getFontSize(8)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: gameOverTextColor
        }).setOrigin(0.5);
        this.gameOverKills = this.add.text(this.gameWidth / 2, this.gameHeight / 2 - 10 * this.fontScale, '', {
          fontSize: `${this.getFontSize(8)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: gameOverTextColor
        }).setOrigin(0.5);
        this.gameOverLevel = this.add.text(this.gameWidth / 2, this.gameHeight / 2, '', {
          fontSize: `${this.getFontSize(8)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: gameOverTextColor
        }).setOrigin(0.5);
      const highScoreColor = getColor(this.themeManager, COLOR_PATHS.UI.COMBO);
      this.gameOverHighScore = this.add.text(this.gameWidth / 2, this.gameHeight / 2 + 12 * this.fontScale, '', {
        fontSize: `${this.getFontSize(9)}px`,
        fontFamily: 'Consolas, "Courier New", monospace',
        color: colorToHex(highScoreColor)
      }).setOrigin(0.5);
        this.gameOverRestart = this.add.text(this.gameWidth / 2, this.gameHeight / 2 + 30 * this.fontScale, 'PRESS SPACE TO RESTART', {
          fontSize: `${this.getFontSize(8)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: gameOverTextColor
        }).setOrigin(0.5);
      }
      this.gameOverOverlay.clear();
      this.gameOverOverlay.fillStyle(0x000000, 0.85);
      this.gameOverOverlay.fillRect(0, 0, this.gameWidth, this.gameHeight);
      
      this.gameOverScore.setText(`FINAL SCORE: ${this.score}`);
      this.gameOverKills.setText(`KILLS: ${this.kills}`);
      this.gameOverLevel.setText(`LEVEL REACHED: ${this.level}`);
      
      if (this.score === this.highScore && this.score > 0) {
        this.gameOverHighScore.setText('NEW HIGH SCORE!');
        this.gameOverHighScore.setVisible(true);
      } else {
        this.gameOverHighScore.setVisible(false);
      }
      
      const blink = Math.sin(this.time.now / 500) > 0;
      this.gameOverRestart.setVisible(blink);
    } else if (this.gameOverOverlay) {
      this.gameOverOverlay.setVisible(false);
      this.gameOverText.setVisible(false);
      this.gameOverScore.setVisible(false);
      this.gameOverKills.setVisible(false);
      this.gameOverLevel.setVisible(false);
      this.gameOverHighScore.setVisible(false);
      this.gameOverRestart.setVisible(false);
    }
    
    if (!this.border) {
      this.border = this.add.graphics();
    }
    this.border.clear();
    this.border.lineStyle(1, getColor(this.themeManager, COLOR_PATHS.BORDER));
    this.border.moveTo(0, 0);
    this.border.lineTo(this.gameWidth, 0);
    this.border.moveTo(0, this.gameHeight - 1);
    this.border.lineTo(this.gameWidth, this.gameHeight - 1);
  }
  
  shutdown() {
    if (this.themeMediaQuery && this.themeMediaQueryListener) {
      this.themeMediaQuery.removeEventListener('change', this.themeMediaQueryListener);
    }
  }
  
  resetGame() {
    // 1. Clear all game objects and groups first
    this.bullets.clear(true, true);
    this.bossBullets.clear(true, true);
    
    // 2. Destroy boss explicitly before clearing managers
    if (this.boss && this.bossManager) {
      this.bossManager.destroyBoss();
      this.boss = null;
    }
    
    // Clear all caches
    this.cachedChildren.particles = null;
    this.cachedChildren.obstacles = null;
    this.cachedChildren.bullets = null;
    this.cachedChildren.bossBullets = null;
    this.cachedChildren.energies = null;
    this.cachedChildren.powerups = null;
    this.childrenCacheTime = 0;
    
    // 3. Clear all managers
    if (this.bossManager) {
      this.bossManager.clear();
    }
    if (this.obstacleManager) {
      this.obstacleManager.clear();
    }
    if (this.energyManager) {
      this.energyManager.clear();
    }
    if (this.powerupManager) {
      this.powerupManager.clear();
    }
    if (this.particleManager) {
      this.particleManager.clear();
    }
    if (this.floatingTextManager) {
      this.floatingTextManager.clear();
    }
    if (this.bulletManager) {
      this.bulletManager.clear();
    }
    
    // 4. Clear utility managers
    if (this.collisionManager) {
      this.collisionManager.clearCache();
    }
    if (this.updateManager) {
      this.updateManager.reset();
    }
    if (this.memoryManager) {
      this.memoryManager.forceCleanup();
    }
    if (this.performanceManager) {
      this.performanceManager.reset();
    }
    
    // 5. Reset player position and state
    this.player.x = 50;
    this.player.y = this.gameHeight / 2;
    this.playerTrail = [];
    this.playerDirty = true;
    
    // 6. Clear graphics
    if (this.airRushGraphics) {
      this.airRushGraphics.clear();
    }
    if (this.engineFireGraphics) {
      this.engineFireGraphics.clear();
    }
    if (this.livesGraphics) {
      this.livesGraphics.clear();
    }
    if (this.autoAimGraphics) {
      this.autoAimGraphics.clear();
    }
    if (this.magnetGraphics) {
      this.magnetGraphics.clear();
    }
    if (this.screenFlashGraphics) {
      this.screenFlashGraphics.clear();
    }
    if (this.progressBarBg) {
      this.progressBarBg.clear();
    }
    if (this.progressBar) {
      this.progressBar.clear();
    }
    
    // 7. Reset game state variables
    this.score = 0;
    this.gameOver = false;
    this.gameStarted = false;
    this.isPaused = false;
    this.frameCount = 0;
    this.level = 1;
    this.kills = 0;
    this.combo = 0;
    this.comboFlash = 0;
    this.scoreFlash = 0;
    this.lives = 3;
    this.lastUIUpdate = 0;
    this.lastProgressWidth = 0;
    
    // 8. Reset powerup states
    this.isHyperspeed = false;
    this.hyperspeedMultiplier = 1;
    this.hyperspeedEndTime = 0;
    if (this.bulletManager) {
      this.bulletManager.setHyperspeed(false);
    }
    this.isTripleShot = false;
    this.tripleShotEndTime = 0;
    this.isAutoAimActive = false;
    this.isMagnetActive = false;
    this.isSlowMotionActive = false;
    this.isShieldActive = false;
    this.shieldEndTime = 0;
    
    // 9. Reset screen effects
    this.cameraShakeIntensity = 0;
    this.cameraShakeDuration = 0;
    this.screenFlashAlpha = 0;
    if (this.gameElementsContainer && this.cameraShakeOriginalX !== undefined) {
      this.gameElementsContainer.setPosition(
        this.cameraShakeOriginalX,
        this.cameraShakeOriginalY
      );
      this.cameraShakeOriginalX = undefined;
      this.cameraShakeOriginalY = undefined;
    }
    
    // 10. Reset boss-related state
    this.boss = null;
    this.bossPattern = 0;
    this.lastBossScore = 0;
    this.bossLastShotTime = 0;
    
    // 11. Reset auto-aim state
    this.autoAimTargets = [];
    this.autoAimTargetsCacheTime = 0;
    if (this.autoAimText) {
      this.autoAimText.setVisible(false);
    }
    if (this.hyperspeedText) {
      this.hyperspeedText.setVisible(false);
    }
    
    // 12. Reset magnet state
    this.magnetFieldParticles = [];
    
    // 13. Reset timers
    this.lastShotTime = 0;
    this.lastKillTime = 0;
    if (this.comboTimeout) {
      clearTimeout(this.comboTimeout);
      this.comboTimeout = null;
    }
    
    // 14. Reset cheats
    this.cheats = {
      wallHack: false,
      noBlur: false,
      godMode: false,
      infiniteLives: false,
      infinitePowerups: false,
      oneHitKill: false
    };
    this.cheatInput = '';
    this.spaceKeyWasPressed = false;
    
    // 15. Reinitialize starfield
    if (this.starManager) {
      this.starManager.clear();
      this.starManager.initialize(this.gameWidth, this.gameHeight);
    }
  }

  getThemeMode() {
    return this.themeManager.getThemeMode();
  }
  
  getColor(path, defaultValue = null) {
    return this.themeManager.getColor(path, defaultValue);
  }
  
  setTheme(mode) {
    if (this.themeManager.setTheme(mode)) {
      this.applyTheme();
    }
  }
  
  setCustomColors(colors) {
    this.themeManager.setCustomColors(colors);
    this.applyTheme();
  }
  
  clearCustomColors() {
    this.themeManager.clearCustomColors();
    this.applyTheme();
  }
  
  saveHighScore() {
    saveHighScore(this.highScore);
  }
  
  
  drawPlayer(graphics) {
    drawPlayer(graphics, this.themeManager, this.isHyperspeed, this.cheats.wallHack);
  }
  
  drawCheatInput() {
    if (!this.isPaused || this.cheatInput.length === 0) {
      if (this.cheatInputText) {
        this.cheatInputText.setVisible(false);
      }
      return;
    }
    
    if (!this.cheatInputText) {
      const textColor = colorToHex(getColor(this.themeManager, COLOR_PATHS.UI.SCORE));
      this.cheatInputText = this.add.text(this.gameWidth / 2, this.gameHeight - 30 * this.fontScale, '', {
        fontSize: `${this.getFontSize(8)}px`,
        fontFamily: 'Consolas, "Courier New", monospace',
        color: textColor
      }).setOrigin(0.5);
    }
    
    this.cheatInputText.setText(this.cheatInput);
    this.cheatInputText.setPosition(this.gameWidth / 2, this.gameHeight - 30 * this.fontScale);
    this.cheatInputText.setVisible(true);
  }
  
  shutdown() {
    // Remove event listeners
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler);
      this.resizeHandler = null;
    }
    if (this.visibilityHandler) {
      document.removeEventListener('visibilitychange', this.visibilityHandler);
      this.visibilityHandler = null;
    }
    if (this.focusHandler) {
      window.removeEventListener('focus', this.focusHandler);
      this.focusHandler = null;
    }
    
    if (this.themeManager) {
      this.themeManager.cleanup();
    }
  }
}
