// Bullet Manager - Optimized bullet system with object pooling
import { BULLET_SIZE, BULLET_SPEED } from '../constants.js';
import { getColor } from '../utils/colorHelpers.js';
import { COLOR_PATHS } from '../constants/colorPaths.js';
import { drawPixel } from '../drawing/pixel.js';

export class BulletManager {
  constructor(scene, themeManager, gameElementsContainer, bulletsGroup = null) {
    this.scene = scene;
    this.themeManager = themeManager;
    this.gameElementsContainer = gameElementsContainer;
    this.bullets = bulletsGroup || scene.add.group();
    this.bulletPool = [];
    this.maxPoolSize = 30;
    this.isHyperspeed = false; // Track hyperspeed state
  }

  createBullet(x, y, speed, isBossBullet = false) {
    const bullet = this.getBulletFromPool() || this.createNewBullet();
    
    bullet.x = x;
    bullet.y = y;
    bullet.speed = speed;
    bullet.isBossBullet = isBossBullet;
    bullet.active = true; // Ensure bullet is active
    bullet.visible = true; // Ensure bullet is visible
    bullet.dirty = true;
    bullet.lastDrawnX = undefined;
    bullet.lastDrawnY = undefined;
    bullet.lastHyperspeed = undefined; // Reset hyperspeed state
    
    // For auto-aim bullets
    if (bullet.vx !== undefined && bullet.vy !== undefined) {
      bullet.vx = bullet.vx;
      bullet.vy = bullet.vy;
    }
    
    this.bullets.add(bullet);
    this.gameElementsContainer.add(bullet);
    return bullet;
  }

  getBulletFromPool() {
    if (this.bulletPool.length > 0) {
      return this.bulletPool.pop();
    }
    return null;
  }

  createNewBullet() {
    const bullet = this.scene.add.graphics();
    bullet.pooled = false;
    return bullet;
  }

  drawBullet(graphics, x, y, isBossBullet) {
    if (!this.shouldRedraw(graphics, x, y)) return;

    const centerX = 0;
    const centerY = 0;
    
    // Special hyperspeed visualization for player bullets (not boss bullets)
    if (this.isHyperspeed && !isBossBullet) {
      const isDark = this.themeManager.isDark;
      const hyperspeedGlowColor = isDark ? 0xffffff : 0x000000;
      const hyperspeedMainColor = isDark ? 0xfbbf24 : 0xf59e0b;
      
      graphics.fillStyle(hyperspeedGlowColor);
      drawPixel(graphics, centerX, centerY - 2, 1);
      drawPixel(graphics, centerX - 2, centerY, 1);
      drawPixel(graphics, centerX + 2, centerY, 1);
      drawPixel(graphics, centerX, centerY + 2, 1);
      drawPixel(graphics, centerX - 1, centerY - 1, 1);
      drawPixel(graphics, centerX + 1, centerY - 1, 1);
      drawPixel(graphics, centerX - 1, centerY + 1, 1);
      drawPixel(graphics, centerX + 1, centerY + 1, 1);
      
      graphics.fillStyle(hyperspeedMainColor);
      drawPixel(graphics, centerX, centerY - 1, 1);
      drawPixel(graphics, centerX - 1, centerY, 1);
      drawPixel(graphics, centerX, centerY, 1);
      drawPixel(graphics, centerX + 1, centerY, 1);
      drawPixel(graphics, centerX, centerY + 1, 1);
      
      graphics.fillStyle(isDark ? 0xfffbeb : 0x78350f);
      drawPixel(graphics, centerX, centerY, 1);
      return;
    }
    
    // Normal bullet visualization
    const bulletColors = isBossBullet 
      ? {
          main: getColor(this.themeManager, COLOR_PATHS.BOSS_BULLET.MAIN),
          accent: getColor(this.themeManager, COLOR_PATHS.BOSS_BULLET.ACCENT),
          glow: getColor(this.themeManager, COLOR_PATHS.BOSS_BULLET.GLOW)
        }
      : {
          main: getColor(this.themeManager, COLOR_PATHS.BULLET.MAIN),
          accent: getColor(this.themeManager, COLOR_PATHS.BULLET.ACCENT),
          glow: getColor(this.themeManager, COLOR_PATHS.BULLET.GLOW)
        };

    // Glow
    graphics.fillStyle(bulletColors.glow, 0.5);
    drawPixel(graphics, centerX - 1, centerY, 1);
    drawPixel(graphics, centerX + 1, centerY, 1);
    drawPixel(graphics, centerX, centerY - 1, 1);
    drawPixel(graphics, centerX, centerY + 1, 1);

    // Main body
    graphics.fillStyle(bulletColors.main);
    drawPixel(graphics, centerX, centerY, 1);
    drawPixel(graphics, centerX - 1, centerY, 1);
    drawPixel(graphics, centerX + 1, centerY, 1);

    // Accent
    graphics.fillStyle(bulletColors.accent);
    drawPixel(graphics, centerX, centerY, 1);
  }
  
  setHyperspeed(isHyperspeed) {
    this.isHyperspeed = isHyperspeed;
  }

  shouldRedraw(graphics, x, y) {
    // Always redraw if hyperspeed state changed
    if (graphics.lastHyperspeed !== undefined && graphics.lastHyperspeed !== this.isHyperspeed) {
      graphics.clear();
      graphics.lastDrawnX = undefined;
      graphics.lastDrawnY = undefined;
    }
    
    if (graphics.lastDrawnX !== undefined && 
        Math.abs(graphics.lastDrawnX - x) < 0.5 && 
        Math.abs(graphics.lastDrawnY - y) < 0.5 &&
        graphics.lastHyperspeed === this.isHyperspeed) {
      return false;
    }
    graphics.clear();
    graphics.lastDrawnX = x;
    graphics.lastDrawnY = y;
    graphics.lastHyperspeed = this.isHyperspeed;
    return true;
  }

  returnBulletToPool(bullet) {
    if (this.bulletPool.length < this.maxPoolSize) {
      bullet.clear();
      bullet.active = false;
      bullet.vx = undefined;
      bullet.vy = undefined;
      bullet.lastDrawnX = undefined;
      bullet.lastDrawnY = undefined;
      bullet.lastHyperspeed = undefined;
      this.bulletPool.push(bullet);
    } else {
      bullet.destroy();
    }
  }

  clear() {
    const children = this.bullets.getChildren();
    for (const bullet of children) {
      this.returnBulletToPool(bullet);
    }
    this.bullets.clear(true, true);
  }
}


