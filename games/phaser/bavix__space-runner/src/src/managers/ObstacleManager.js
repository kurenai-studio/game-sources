// Obstacle Manager - Improved enemy AI and patterns
import { OBSTACLE_TYPES } from '../constants/gameParams.js';
import { getColor } from '../utils/colorHelpers.js';
import { COLOR_PATHS } from '../constants/colorPaths.js';
import { drawPixel } from '../drawing/pixel.js';

export class ObstacleManager {
  constructor(scene, themeManager, gameElementsContainer) {
    this.scene = scene;
    this.themeManager = themeManager;
    this.gameElementsContainer = gameElementsContainer;
    this.obstacles = scene.add.group();
    this.drawFunctions = {
      [OBSTACLE_TYPES.ASTEROID]: this.drawAsteroid.bind(this),
      [OBSTACLE_TYPES.COMET]: this.drawComet.bind(this),
      [OBSTACLE_TYPES.FAST_ENEMY]: this.drawFastEnemy.bind(this),
      [OBSTACLE_TYPES.BIG_ENEMY]: this.drawBigEnemy.bind(this)
    };
  }

  createObstacle(type, x, y, size, speed, gameHeight) {
    const obstacle = this.scene.add.graphics();
    obstacle.type = type;
    obstacle.x = x;
    obstacle.y = y;
    obstacle.size = size;
    obstacle.speed = speed;
    obstacle.baseSpeed = speed; // Store original speed for slow motion
    obstacle.dirty = true;
    obstacle.lastDrawnX = undefined;
    obstacle.lastDrawnY = undefined;
    
    // Comet-specific properties - improved movement
    if (type === OBSTACLE_TYPES.COMET) {
      const angle = (Math.random() - 0.5) * 0.3;
      obstacle.baseVy = Math.sin(angle) * speed * 0.4;
      obstacle.oscillationPhase = Math.random() * Math.PI * 2;
      obstacle.oscillationSpeed = 0.05 + Math.random() * 0.05;
    }
    
    // Fast enemy - add slight tracking behavior
    if (type === OBSTACLE_TYPES.FAST_ENEMY) {
      obstacle.trackingPhase = Math.random() * Math.PI * 2;
      obstacle.trackingSpeed = 0.03 + Math.random() * 0.02;
    }
    
    // Big enemy - slower but more predictable
    if (type === OBSTACLE_TYPES.BIG_ENEMY) {
      obstacle.movementPhase = Math.random() * Math.PI * 2;
      obstacle.movementSpeed = 0.02 + Math.random() * 0.02;
    }
    
    this.obstacles.add(obstacle);
    this.gameElementsContainer.add(obstacle);
    return obstacle;
  }
  
  updateObstacleMovement(obstacle, gameHeight, hyperspeedMultiplier, slowMotionFactor) {
    if (obstacle.type === OBSTACLE_TYPES.COMET && obstacle.baseVy !== undefined) {
      // Improved comet movement with oscillation
      obstacle.oscillationPhase += obstacle.oscillationSpeed || 0.05;
      const oscillation = Math.sin(obstacle.oscillationPhase) * 0.5;
      obstacle.y += (obstacle.baseVy + oscillation) * hyperspeedMultiplier * slowMotionFactor;
      
      const minY = obstacle.size;
      const maxY = gameHeight - obstacle.size;
      if (obstacle.y < minY || obstacle.y > maxY) {
        obstacle.baseVy = -obstacle.baseVy;
        obstacle.y = Math.max(minY, Math.min(maxY, obstacle.y));
      }
    } else if (obstacle.type === OBSTACLE_TYPES.FAST_ENEMY) {
      // Fast enemy slight vertical movement
      obstacle.trackingPhase += obstacle.trackingSpeed || 0.03;
      const verticalOffset = Math.sin(obstacle.trackingPhase) * 1.5;
      obstacle.y += verticalOffset * hyperspeedMultiplier * slowMotionFactor;
      
      const minY = obstacle.size;
      const maxY = gameHeight - obstacle.size;
      obstacle.y = Math.max(minY, Math.min(maxY, obstacle.y));
    } else if (obstacle.type === OBSTACLE_TYPES.BIG_ENEMY) {
      // Big enemy slow drift
      obstacle.movementPhase += obstacle.movementSpeed || 0.02;
      const drift = Math.sin(obstacle.movementPhase) * 0.8;
      obstacle.y += drift * hyperspeedMultiplier * slowMotionFactor;
      
      const minY = obstacle.size;
      const maxY = gameHeight - obstacle.size;
      obstacle.y = Math.max(minY, Math.min(maxY, obstacle.y));
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
    
    graphics.fillStyle(outerColor);
    for (let dy = -r; dy <= r; dy++) {
      for (let dx = -r; dx <= r; dx++) {
        const distSq = dx * dx + dy * dy;
        const rSq = r * r;
        const rMinus2Sq = (r - 2) * (r - 2);
        if (distSq <= rSq && distSq > rMinus2Sq) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }
    
    graphics.fillStyle(middleColor);
    const rMinus2 = r - 2;
    const rMinus3 = r - 3;
    for (let dy = -rMinus2; dy <= rMinus2; dy++) {
      for (let dx = -rMinus2; dx <= rMinus2; dx++) {
        const distSq = dx * dx + dy * dy;
        const rMinus2Sq = rMinus2 * rMinus2;
        const rMinus3Sq = rMinus3 * rMinus3;
        if (distSq <= rMinus2Sq && distSq > rMinus3Sq) {
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
    
    graphics.fillStyle(mainColor);
    const rSq = r * r;
    for (let dy = -r; dy <= r; dy++) {
      for (let dx = -r; dx <= r; dx++) {
        const distSq = dx * dx + dy * dy;
        if (distSq <= rSq) {
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
    
    graphics.fillStyle(mainColor);
    const rSq = r * r;
    for (let dy = -r; dy <= r; dy++) {
      for (let dx = -r; dx <= r; dx++) {
        const distSq = dx * dx + dy * dy;
        if (distSq <= rSq) {
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
    
    graphics.fillStyle(outerColor);
    const rSq = r * r;
    const rMinus3Sq = (r - 3) * (r - 3);
    for (let dy = -r; dy <= r; dy++) {
      for (let dx = -r; dx <= r; dx++) {
        const distSq = dx * dx + dy * dy;
        if (distSq <= rSq && distSq > rMinus3Sq) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }
    
    graphics.fillStyle(middleColor);
    const rMinus3 = r - 3;
    const rMinus5Sq = (r - 5) * (r - 5);
    for (let dy = -rMinus3; dy <= rMinus3; dy++) {
      for (let dx = -rMinus3; dx <= rMinus3; dx++) {
        const distSq = dx * dx + dy * dy;
        if (distSq <= rMinus3Sq && distSq > rMinus5Sq) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }
    
    graphics.fillStyle(innerColor);
    drawPixel(graphics, centerX - 2, centerY - 2, 1);
    drawPixel(graphics, centerX + 2, centerY + 2, 1);
    drawPixel(graphics, centerX - 1, centerY - 1, 1);
    drawPixel(graphics, centerX + 1, centerY + 1, 1);
    drawPixel(graphics, centerX, centerY - 2, 1);
    drawPixel(graphics, centerX, centerY + 2, 1);
    
    graphics.fillStyle(darkColor);
    drawPixel(graphics, centerX, centerY, 1);
    drawPixel(graphics, centerX - 1, centerY, 1);
    drawPixel(graphics, centerX + 1, centerY, 1);
    
    graphics.fillStyle(darkestColor);
    drawPixel(graphics, centerX, centerY, 1);
  }

  drawObstacle(obstacle) {
    const drawFunc = this.drawFunctions[obstacle.type];
    if (drawFunc) {
      drawFunc(obstacle, obstacle.x, obstacle.y, obstacle.size);
    }
  }

  clear() {
    this.obstacles.clear(true, true);
  }
}

