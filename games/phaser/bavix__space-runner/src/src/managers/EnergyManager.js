// Energy Manager - Improved energy system
import { ENERGY_SIZE } from '../constants.js';
import { getColor } from '../utils/colorHelpers.js';
import { COLOR_PATHS } from '../constants/colorPaths.js';
import { drawPixel } from '../drawing/pixel.js';

export class EnergyManager {
  constructor(scene, themeManager, gameElementsContainer) {
    this.scene = scene;
    this.themeManager = themeManager;
    this.gameElementsContainer = gameElementsContainer;
    this.energies = scene.add.group();
  }

  createEnergy(x, y, speed) {
    const energy = this.scene.add.graphics();
    energy.x = x;
    energy.y = y;
    energy.size = ENERGY_SIZE;
    energy.speed = speed;
    energy.baseSpeed = speed; // Store original speed for slow motion
    energy.dirty = true;
    energy.lastDrawnX = undefined;
    energy.lastDrawnY = undefined;
    energy.animationPhase = Math.random() * Math.PI * 2;
    energy.animationSpeed = 0.15 + Math.random() * 0.1;
    
    this.energies.add(energy);
    this.gameElementsContainer.add(energy);
    return energy;
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

  drawEnergy(graphics, x, y, size) {
    if (!this.shouldRedraw(graphics, x, y)) {
      // Update animation even if not redrawing
      if (graphics.animationPhase !== undefined) {
        graphics.animationPhase += graphics.animationSpeed || 0.15;
      }
      return;
    }

    const centerX = 0;
    const centerY = 0;
    const r = Math.floor(size / 2);
    
    const mainColor = getColor(this.themeManager, COLOR_PATHS.ENERGY.MAIN);
    const accentColor = getColor(this.themeManager, COLOR_PATHS.ENERGY.ACCENT);
    const coreColor = getColor(this.themeManager, COLOR_PATHS.ENERGY.CORE);
    
    // Animation
    const phase = graphics.animationPhase || 0;
    const pulse = 1 + Math.sin(phase) * 0.2;
    const glow = 0.6 + Math.sin(phase * 1.5) * 0.4;
    const currentR = r * pulse;

    // Outer glow
    graphics.fillStyle(mainColor, glow * 0.4);
    const glowR = currentR + 1;
    const glowRSq = glowR * glowR;
    for (let dy = -glowR; dy <= glowR; dy++) {
      for (let dx = -glowR; dx <= glowR; dx++) {
        const distSq = dx * dx + dy * dy;
        if (distSq <= glowRSq && distSq > currentR * currentR) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }

    // Main body
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

    // Accent ring
    graphics.fillStyle(accentColor);
    const accentR = Math.floor(currentR * 0.7);
    const accentRSq = accentR * accentR;
    for (let dy = -accentR; dy <= accentR; dy++) {
      for (let dx = -accentR; dx <= accentR; dx++) {
        const distSq = dx * dx + dy * dy;
        if (distSq <= accentRSq) {
          drawPixel(graphics, centerX + dx, centerY + dy, 1);
        }
      }
    }

    // Core - smaller for reduced size
    graphics.fillStyle(coreColor);
    drawPixel(graphics, centerX, centerY, 1);
    if (size >= 8) {
      // Only draw extended core for larger sizes
      drawPixel(graphics, centerX - 1, centerY, 1);
      drawPixel(graphics, centerX + 1, centerY, 1);
      drawPixel(graphics, centerX, centerY - 1, 1);
      drawPixel(graphics, centerX, centerY + 1, 1);
    }

    // Update animation phase
    graphics.animationPhase = phase + (graphics.animationSpeed || 0.15);
  }

  updateEnergyAnimation(energy) {
    if (energy.animationPhase !== undefined) {
      energy.animationPhase += energy.animationSpeed || 0.15;
    }
  }

  clear() {
    this.energies.clear(true, true);
  }
}


