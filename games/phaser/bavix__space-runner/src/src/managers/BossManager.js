// Boss Manager - Improved boss behavior and patterns
import { BOSS_CONFIG } from '../bossConfig.js';
import { BOSS_TYPES } from '../constants.js';
import { getParticleColor, getColor } from '../utils/colorHelpers.js';
import { PARTICLE_TYPES } from '../constants/gameParams.js';
import { BOSS_SPAWN_PARTICLES_COUNT, FLOATING_TEXT_SIZES } from '../constants.js';
import { getDistance, getDistanceSq, normalizeVector } from '../utils/mathHelpers.js';
import { drawPixel } from '../drawing/pixel.js';
import { COLOR_PATHS } from '../constants/colorPaths.js';

export class BossManager {
  constructor(scene, themeManager, gameElementsContainer, createParticles, createFloatingText, bossBulletsGroup) {
    this.scene = scene;
    this.themeManager = themeManager;
    this.gameElementsContainer = gameElementsContainer;
    this.createParticles = createParticles;
    this.createFloatingText = createFloatingText;
    this.bossBullets = bossBulletsGroup;
    this.boss = null;
    this.bossPattern = 0;
    this.bossLastShotTime = 0;
  }

  spawnBoss(bossType, level, gameWidth, gameHeight, hyperspeedMultiplier) {
    const config = BOSS_CONFIG[bossType];
    if (!config) return null;

    const bossHealth = config.health(level);
    const isDark = this.themeManager.isDark;
    const colors = isDark ? config.color.dark : config.color.light;
    
    const boss = this.scene.add.graphics();
    const bossSize = config.size;
    boss.x = gameWidth;
    boss.y = gameHeight / 2;
    boss.health = bossHealth;
    boss.maxHealth = bossHealth;
    boss.type = bossType;
    
    const bossSpeedMultiplier = 1 + (level - 1) * 0.1;
    boss.speed = config.speed * bossSpeedMultiplier * hyperspeedMultiplier;
    boss.chaseSpeed = config.chaseSpeed * bossSpeedMultiplier * hyperspeedMultiplier;
    boss.oscillationAmplitude = config.oscillationAmplitude;
    boss.canShoot = config.canShoot;
    boss.shootCooldown = config.shootCooldown || 0;
    boss.bulletSpeed = config.bulletSpeed || 0;
    
    this.gameElementsContainer.add(boss);
    this.boss = boss;
    this.bossPattern = 0;
    this.bossLastShotTime = 0;
    
    this.createParticles(boss.x, boss.y, BOSS_SPAWN_PARTICLES_COUNT, colors.main, PARTICLE_TYPES.EXPLOSION);
    this.createFloatingText(boss.x, boss.y, `${config.name} BOSS!`, colors.main, FLOATING_TEXT_SIZES.XXLARGE);
    
    return boss;
  }

  updateBoss(gameWidth, gameHeight, level, hyperspeedMultiplier, slowMotionFactor, playerX, playerY, getCachedChildren, createBossBullet, time) {
    if (!this.boss) return;

    const bossType = this.boss.type || BOSS_TYPES.FORTRESS;
    const config = BOSS_CONFIG[bossType];
    if (!config) return;

    this.bossPattern += 0.08;
    const bossSize = config.size;
    
    const bossSpeedMultiplier = 1 + (level - 1) * 0.1;
    const horizontalSpeed = config.speed * bossSpeedMultiplier * hyperspeedMultiplier * slowMotionFactor;
    this.boss.x -= horizontalSpeed;

    const bossX = this.boss.x;
    const bossY = this.boss.y;
    const distance = getDistance(bossX, bossY, playerX, playerY);
    const dx = playerX - bossX;
    const dy = playerY - bossY;
    
    let targetY = this.boss.y;
    
    // Handle different boss types with their specific behaviors
    if (bossType === BOSS_TYPES.FORTRESS) {
      const oscillation = Math.sin(this.bossPattern) * config.oscillationAmplitude;
      if (distance > 0) {
        const normalized = normalizeVector(dx, dy, distance);
        targetY = gameHeight / 2 + oscillation + normalized.y * config.chaseSpeed * 20;
      } else {
        targetY = gameHeight / 2 + oscillation;
      }
    } else if (bossType === BOSS_TYPES.HUNTER) {
      const oscillation = Math.sin(this.bossPattern) * config.oscillationAmplitude;
      const fastOscillation = Math.sin(this.bossPattern * 2.8) * 35;
      const baseOscillation = oscillation + fastOscillation;
      
      const bullets = getCachedChildren('bullets');
      const bulletsLength = bullets.length;
      let dodgeOffset = 0;
      
      for (let i = 0; i < bulletsLength; i++) {
        const bullet = bullets[i];
        if (!bullet || !bullet.active) continue;
        
        const bulletX = bullet.x;
        const bulletY = bullet.y;
        const bulletDistanceSq = getDistanceSq(bossX, bossY, bulletX, bulletY);
        
        if (bulletDistanceSq < 16900 && bulletX > bossX - 80) { // 130^2
          const bulletDy = bulletY - bossY;
          if (Math.abs(bulletDy) < 55) {
            dodgeOffset += bulletDy > 0 ? -2.5 : 2.5;
          }
        }
      }
      
      if (distance > 0) {
        const normalized = normalizeVector(dx, dy, distance);
        targetY = gameHeight / 2 + baseOscillation + normalized.y * config.chaseSpeed * 18 + dodgeOffset;
      } else {
        targetY = gameHeight / 2 + baseOscillation + dodgeOffset;
      }
      
      if (config.canShoot && time.now - this.bossLastShotTime >= config.shootCooldown) {
        this.bossLastShotTime = time.now;
        createBossBullet(
          this.boss.x - bossSize / 2,
          this.boss.y,
          playerX,
          playerY,
          config.bulletSpeed
        );
      }
    } else if (bossType === BOSS_TYPES.STORM) {
      if (distance > 0) {
        const normalized = normalizeVector(dx, dy, distance);
        const oscillation = Math.sin(this.bossPattern * 1.6) * config.oscillationAmplitude;
        targetY = gameHeight / 2 + oscillation + normalized.y * config.chaseSpeed * 35;
      } else {
        targetY = gameHeight / 2 + Math.sin(this.bossPattern * 1.6) * config.oscillationAmplitude;
      }
    } else if (bossType === BOSS_TYPES.PHANTOM) {
      const oscillation = Math.sin(this.bossPattern) * config.oscillationAmplitude;
      const phaseOscillation = Math.sin(this.bossPattern * 1.8) * 25;
      const baseOscillation = oscillation + phaseOscillation;
      
      if (distance > 0) {
        const normalized = normalizeVector(dx, dy, distance);
        targetY = gameHeight / 2 + baseOscillation + normalized.y * config.chaseSpeed * 25;
      } else {
        targetY = gameHeight / 2 + baseOscillation;
      }
      
      if (config.canShoot && time.now - this.bossLastShotTime >= config.shootCooldown) {
        this.bossLastShotTime = time.now;
        createBossBullet(
          this.boss.x - bossSize / 2,
          this.boss.y,
          playerX,
          playerY,
          config.bulletSpeed
        );
      }
    } else if (bossType === BOSS_TYPES.VOID) {
      const oscillation = Math.sin(this.bossPattern) * config.oscillationAmplitude;
      const fastOscillation = Math.sin(this.bossPattern * 2.2) * 30;
      const baseOscillation = oscillation + fastOscillation;
      
      if (distance > 0) {
        const normalized = normalizeVector(dx, dy, distance);
        targetY = gameHeight / 2 + baseOscillation + normalized.y * config.chaseSpeed * 22;
      } else {
        targetY = gameHeight / 2 + baseOscillation;
      }
      
      if (config.canShoot && time.now - this.bossLastShotTime >= config.shootCooldown) {
        this.bossLastShotTime = time.now;
        const bulletCount = 3;
        const spreadAngle = 0.3;
        for (let i = 0; i < bulletCount; i++) {
          // Bullets spread leftward with controlled angles, not aiming at player
          const angleOffset = (i - (bulletCount - 1) / 2) * spreadAngle;
          createBossBullet(
            this.boss.x - bossSize / 2,
            this.boss.y,
            0, // targetX not used
            0, // targetY not used
            config.bulletSpeed,
            angleOffset // Use spread angle directly
          );
        }
      }
    }
    
    // Smooth movement
    const currentY = this.boss.y;
    const smoothFactors = {
      [BOSS_TYPES.STORM]: 0.28,
      [BOSS_TYPES.PHANTOM]: 0.12,
      [BOSS_TYPES.VOID]: 0.18
    };
    const smoothFactor = smoothFactors[bossType] || 0.15;
    const newY = currentY + (targetY - currentY) * smoothFactor;
    
    const minY = bossSize / 2;
    const maxY = gameHeight - bossSize / 2;
    this.boss.y = Math.max(minY, Math.min(maxY, newY));

    // Remove if out of bounds
    if (this.boss.x < -bossSize * 2) {
      this.destroyBoss();
    }
  }

  drawBoss(boss, x, y, health, maxHealth, pattern, bossType) {
    const config = BOSS_CONFIG[bossType];
    if (!config) return;

    const isDark = this.themeManager.isDark;
    const colors = isDark ? config.color.dark : config.color.light;
    const bossSize = config.size;
    const r = Math.floor(bossSize / 2);
    const centerX = 0;
    const centerY = 0;

    // Drawing logic for each boss type (same as in GameScene)
    // This is a simplified version - full drawing logic should be moved here
    // For now, we'll keep the drawing in GameScene but prepare the structure
  }

  getBoss() {
    return this.boss;
  }

  destroyBoss() {
    if (this.boss) {
      // Remove from container and destroy
      if (this.gameElementsContainer && this.boss.parentContainer === this.gameElementsContainer) {
        this.gameElementsContainer.remove(this.boss);
      }
      if (this.boss.destroy) {
        this.boss.destroy();
      }
      this.boss = null;
      this.bossPattern = 0;
      this.bossLastShotTime = 0;
      // Clear all boss bullets when boss is destroyed
      if (this.bossBullets) {
        this.bossBullets.clear(true, true);
      }
    }
  }

  clear() {
    this.destroyBoss();
  }
}
