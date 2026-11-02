// Powerup Manager - Improved powerup system with visual effects
import { POWERUP_TYPES } from '../constants/gameParams.js';
import { POWERUP_SIZE } from '../constants.js';
import { getPowerupColor } from '../utils/colorHelpers.js';
import { COLOR_PATHS } from '../constants/colorPaths.js';
import { drawPixel } from '../drawing/pixel.js';

export class PowerupManager {
  constructor(scene, themeManager, gameElementsContainer) {
    this.scene = scene;
    this.themeManager = themeManager;
    this.gameElementsContainer = gameElementsContainer;
    this.powerups = scene.add.group();
  }

  createPowerup(type, x, y, speed) {
    const powerup = this.scene.add.graphics();
    powerup.type = type;
    powerup.x = x;
    powerup.y = y;
    powerup.size = POWERUP_SIZE;
    powerup.speed = speed;
    powerup.baseSpeed = speed; // Store original speed for slow motion
    powerup.dirty = true;
    powerup.lastDrawnX = undefined;
    powerup.lastDrawnY = undefined;
    powerup.animationPhase = Math.random() * Math.PI * 2;
    powerup.animationSpeed = 0.1 + Math.random() * 0.05;
    
    this.powerups.add(powerup);
    this.gameElementsContainer.add(powerup);
    return powerup;
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

  drawPowerup(graphics, x, y, type, time) {
    if (!this.shouldRedraw(graphics, x, y)) {
      // Update animation even if not redrawing
      graphics.animationPhase = (graphics.animationPhase || 0) + (graphics.animationSpeed || 0.1);
      return;
    }

    const centerX = 0;
    const centerY = 0;
    const r = Math.floor(POWERUP_SIZE / 2);
    const powerupColors = getPowerupColor(this.themeManager, type);
    const mainColor = powerupColors?.main || 0xffffff;
    const accentColor = powerupColors?.accent || 0xcccccc;
    const lightColor = powerupColors?.light || 0xffffff;

    // Animation phase
    const phase = graphics.animationPhase;
    const pulse = 1 + Math.sin(phase) * 0.15;
    const glow = 0.5 + Math.sin(phase * 1.5) * 0.3;
    const currentR = r * pulse;

    // Draw outer glow - reduced for smaller size
    graphics.fillStyle(mainColor, glow * 0.3);
    const glowR = currentR + 1;
    for (let dy = -glowR; dy <= glowR; dy++) {
      for (let dx = -glowR; dx <= glowR; dx++) {
        const distSq = dx * dx + dy * dy;
        const glowRSq = glowR * glowR;
        if (distSq <= glowRSq && distSq > currentR * currentR) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }

    // Draw main body
    graphics.fillStyle(mainColor);
    const rSq = currentR * currentR;
    for (let dy = -currentR; dy <= currentR; dy++) {
      for (let dx = -currentR; dx <= currentR; dx++) {
        const distSq = dx * dx + dy * dy;
        if (distSq <= rSq) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }

    // Draw accent
    graphics.fillStyle(accentColor);
    const accentR = Math.floor(currentR * 0.6);
    const accentRSq = accentR * accentR;
    for (let dy = -accentR; dy <= accentR; dy++) {
      for (let dx = -accentR; dx <= accentR; dx++) {
        const distSq = dx * dx + dy * dy;
        if (distSq <= accentRSq) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }

    // Draw core - smaller for reduced size
    graphics.fillStyle(lightColor);
    drawPixel(graphics, centerX, centerY, 1);
    if (POWERUP_SIZE >= 10) {
      // Only draw extended core for larger sizes
      drawPixel(graphics, centerX - 1, centerY, 1);
      drawPixel(graphics, centerX + 1, centerY, 1);
      drawPixel(graphics, centerX, centerY - 1, 1);
      drawPixel(graphics, centerX, centerY + 1, 1);
    }

    // Type-specific visual - scaled for smaller size
    const scale = POWERUP_SIZE <= 7 ? 0.7 : 1; // Scale down for smaller powerups
    const offset1 = Math.round(1 * scale);
    const offset2 = Math.round(2 * scale);
    
    if (type === POWERUP_TYPES.RAPID) {
      // Lightning bolt effect
      graphics.fillStyle(lightColor, 0.8);
      drawPixel(graphics, centerX - offset2, centerY - offset1, 1);
      drawPixel(graphics, centerX + offset2, centerY + offset1, 1);
      drawPixel(graphics, centerX, centerY - offset2, 1);
      drawPixel(graphics, centerX, centerY + offset2, 1);
    } else if (type === POWERUP_TYPES.TRIPLE) {
      // Three dots
      graphics.fillStyle(lightColor, 0.8);
      drawPixel(graphics, centerX - offset2, centerY, 1);
      drawPixel(graphics, centerX, centerY, 1);
      drawPixel(graphics, centerX + offset2, centerY, 1);
    } else if (type === POWERUP_TYPES.SHIELD) {
      // Shield outline
      graphics.fillStyle(lightColor, 0.6);
      drawPixel(graphics, centerX - offset2, centerY - offset1, 1);
      drawPixel(graphics, centerX + offset2, centerY - offset1, 1);
      drawPixel(graphics, centerX, centerY - offset2, 1);
      drawPixel(graphics, centerX - offset1, centerY + offset1, 1);
      drawPixel(graphics, centerX + offset1, centerY + offset1, 1);
    } else if (type === POWERUP_TYPES.AUTO_AIM) {
      // Crosshair
      graphics.fillStyle(lightColor, 0.8);
      drawPixel(graphics, centerX - offset2, centerY, 1);
      drawPixel(graphics, centerX + offset2, centerY, 1);
      drawPixel(graphics, centerX, centerY - offset2, 1);
      drawPixel(graphics, centerX, centerY + offset2, 1);
    } else if (type === POWERUP_TYPES.MAGNET) {
      // Magnetic field lines
      graphics.fillStyle(lightColor, 0.7);
      drawPixel(graphics, centerX - offset2, centerY - offset1, 1);
      drawPixel(graphics, centerX - offset1, centerY - offset2, 1);
      drawPixel(graphics, centerX + offset1, centerY - offset2, 1);
      drawPixel(graphics, centerX + offset2, centerY - offset1, 1);
      drawPixel(graphics, centerX - offset2, centerY + offset1, 1);
      drawPixel(graphics, centerX - offset1, centerY + offset2, 1);
      drawPixel(graphics, centerX + offset1, centerY + offset2, 1);
      drawPixel(graphics, centerX + offset2, centerY + offset1, 1);
    } else if (type === POWERUP_TYPES.SLOW_MOTION) {
      // Clock/hourglass
      graphics.fillStyle(lightColor, 0.8);
      drawPixel(graphics, centerX - offset1, centerY - offset2, 1);
      drawPixel(graphics, centerX + offset1, centerY - offset2, 1);
      drawPixel(graphics, centerX, centerY, 1);
      drawPixel(graphics, centerX - offset1, centerY + offset2, 1);
      drawPixel(graphics, centerX + offset1, centerY + offset2, 1);
    } else if (type === POWERUP_TYPES.LIFE) {
      // Heart
      graphics.fillStyle(lightColor, 0.8);
      drawPixel(graphics, centerX - offset1, centerY - offset1, 1);
      drawPixel(graphics, centerX + offset1, centerY - offset1, 1);
      drawPixel(graphics, centerX, centerY, 1);
      drawPixel(graphics, centerX, centerY + offset1, 1);
    }
  }

  updatePowerupAnimation(powerup, time) {
    if (powerup.animationPhase !== undefined) {
      powerup.animationPhase += powerup.animationSpeed || 0.1;
    }
  }

  clear() {
    this.powerups.clear(true, true);
  }
}

