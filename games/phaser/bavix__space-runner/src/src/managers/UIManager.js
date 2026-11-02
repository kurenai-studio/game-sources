// UI Manager - Improved UI system with better animations and feedback
import { getColor, colorToHex } from '../utils/colorHelpers.js';
import { COLOR_PATHS } from '../constants/colorPaths.js';
import { drawPixel } from '../drawing/pixel.js';

export class UIManager {
  constructor(scene, themeManager) {
    this.scene = scene;
    this.themeManager = themeManager;
    this.fontScale = 1;
    this.uiText = null;
    this.comboText = null;
    this.livesGraphics = null;
    this.progressBarBg = null;
    this.progressBar = null;
    this.powerupTexts = {};
    this.cheatTexts = {};
  }

  initialize(gameWidth, gameHeight, fontScale) {
    this.gameWidth = gameWidth;
    this.gameHeight = gameHeight;
    this.fontScale = fontScale;
    
    const textColorHex = getColor(this.themeManager, COLOR_PATHS.UI.SCORE);
    const textColor = colorToHex(textColorHex);
    
    // Main UI text
    if (!this.uiText) {
      this.uiText = this.scene.add.text(8 * this.fontScale, 8 * this.fontScale, '', {
        fontSize: `${this.getFontSize(10)}px`,
        fontFamily: 'Consolas, "Courier New", monospace',
        color: textColor
      });
      this.uiText.setDepth(1000);
    }
    
    // Combo text
    if (!this.comboText) {
      this.comboText = this.scene.add.text(
        this.gameWidth / 2,
        30 * this.fontScale,
        '',
        {
          fontSize: `${this.getFontSize(8)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: textColor
        }
      );
      this.comboText.setOrigin(0.5);
      this.comboText.setDepth(1000);
    }
    
    // Lives graphics
    if (!this.livesGraphics) {
      this.livesGraphics = this.scene.add.graphics();
      this.livesGraphics.setDepth(1000);
    }
    
    // Progress bar
    if (!this.progressBarBg) {
      this.progressBarBg = this.scene.add.graphics();
      this.progressBarBg.setDepth(1000);
    }
    if (!this.progressBar) {
      this.progressBar = this.scene.add.graphics();
      this.progressBar.setDepth(1000);
    }
  }

  getFontSize(size) {
    return Math.max(8, Math.floor(size * this.fontScale));
  }

  updateUI(score, highScore, combo, level, lives, levelProgress, 
           activePowerups, cheats, time, comboFlash, scoreFlash) {
    const textColorHex = getColor(this.themeManager, COLOR_PATHS.UI.SCORE);
    const textColor = colorToHex(textColorHex);
    const borderColorHex = getColor(this.themeManager, COLOR_PATHS.BORDER);
    const lineColor = colorToHex(borderColorHex);
    
    // Score pulse animation
    const scorePulse = scoreFlash > 0 ? 1 + Math.sin(time / 150) * 0.2 : 1;
    const baseScoreSize = this.getFontSize(10);
    
    // Update main UI text
    const scoreText = scoreFlash > 0 
      ? `SCORE: ${score.toLocaleString()} (HIGH: ${highScore.toLocaleString()})`
      : `SCORE: ${score.toLocaleString()}`;
    
    this.uiText.setText(scoreText);
    this.uiText.setFontSize(`${baseScoreSize * scorePulse}px`);
    this.uiText.setColor(textColor);
    
    // Combo text with pulse
    if (combo > 1) {
      const comboPulse = comboFlash > 0 ? 1 + Math.sin(time / 100) * 0.3 : 1;
      const baseComboSize = this.getFontSize(8 + (combo - 2) * 0.5);
      this.comboText.setText(`x${combo} COMBO!`);
      this.comboText.setFontSize(`${baseComboSize * comboPulse}px`);
      this.comboText.setColor(textColor);
      this.comboText.setVisible(true);
    } else {
      this.comboText.setVisible(false);
    }
    
    // Level progress bar
    this.updateProgressBar(levelProgress, level);
    
    // Lives
    this.updateLives(lives);
    
    // Powerup timers
    this.updatePowerupTimers(activePowerups, time);
    
    // Cheat indicators
    this.updateCheatIndicators(cheats);
  }

  updateProgressBar(progress, level) {
    const barWidth = 200 * this.fontScale;
    const barHeight = 4 * this.fontScale;
    const barX = this.gameWidth - barWidth - 8 * this.fontScale;
    const barY = 8 * this.fontScale;
    
    const bgColor = getColor(this.themeManager, COLOR_PATHS.UI.PROGRESS_BG);
    const fillColor = getColor(this.themeManager, COLOR_PATHS.UI.PROGRESS_FILL);
    
    // Background
    this.progressBarBg.clear();
    this.progressBarBg.fillStyle(bgColor, 0.5);
    this.progressBarBg.fillRect(barX, barY, barWidth, barHeight);
    
    // Progress fill
    this.progressBar.clear();
    this.progressBar.fillStyle(fillColor);
    const fillWidth = barWidth * Math.max(0, Math.min(1, progress));
    this.progressBar.fillRect(barX, barY, fillWidth, barHeight);
    
    // Level text
    if (!this.levelText) {
      const textColor = colorToHex(getColor(this.themeManager, COLOR_PATHS.UI.SCORE));
      this.levelText = this.scene.add.text(
        barX + barWidth / 2,
        barY + barHeight + 4 * this.fontScale,
        '',
        {
          fontSize: `${this.getFontSize(8)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: textColor
        }
      );
      this.levelText.setOrigin(0.5);
      this.levelText.setDepth(1000);
    }
    this.levelText.setText(`LEVEL ${level}`);
  }

  updateLives(lives) {
    this.livesGraphics.clear();
    
    const maxLives = 5;
    const heartSize = 8 * this.fontScale;
    const heartSpacing = 12 * this.fontScale;
    const startX = 8 * this.fontScale;
    const startY = this.gameHeight - heartSize - 8 * this.fontScale;
    
    const lifeColor = getColor(this.themeManager, COLOR_PATHS.UI.LIVES);
    
    for (let i = 0; i < maxLives; i++) {
      const x = startX + i * heartSpacing;
      const isFull = i < lives;
      this.drawHeart(this.livesGraphics, x, startY, heartSize, lifeColor, isFull);
    }
  }

  drawHeart(graphics, x, y, size, color, isFull) {
    const centerX = x;
    const centerY = y;
    const scale = size / 8;
    
    if (isFull) {
      graphics.setAlpha(1);
      graphics.fillStyle(color);
    } else {
      graphics.setAlpha(0.3);
      graphics.fillStyle(color);
    }
    
    // Heart shape
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

  updatePowerupTimers(activePowerups, time) {
    // This will be handled by GameScene's existing powerup timer system
    // Just ensure texts are visible/hidden
    for (const [key, powerup] of Object.entries(activePowerups)) {
      if (powerup.text && powerup.isActive) {
        if (!this.powerupTexts[key]) {
          const textColor = colorToHex(getColor(this.themeManager, COLOR_PATHS.UI.POWERUP));
          this.powerupTexts[key] = this.scene.add.text(0, 0, '', {
            fontSize: `${this.getFontSize(8)}px`,
            fontFamily: 'Consolas, "Courier New", monospace',
            color: textColor
          });
          this.powerupTexts[key].setDepth(1000);
        }
        const remaining = Math.ceil((powerup.endTime - time) / 1000);
        this.powerupTexts[key].setText(`${powerup.name}: ${remaining}s`);
        this.powerupTexts[key].setVisible(true);
      } else if (this.powerupTexts[key]) {
        this.powerupTexts[key].setVisible(false);
      }
    }
  }

  updateCheatIndicators(cheats) {
    // Update cheat indicators if needed
    const activeCheats = Object.entries(cheats)
      .filter(([_, active]) => active)
      .map(([key, _]) => key);
    
    if (activeCheats.length > 0 && !this.cheatIndicator) {
      const textColor = colorToHex(getColor(this.themeManager, COLOR_PATHS.UI.SCORE));
      this.cheatIndicator = this.scene.add.text(
        this.gameWidth - 8 * this.fontScale,
        this.gameHeight - 8 * this.fontScale,
        'CHEATS ACTIVE',
        {
          fontSize: `${this.getFontSize(7)}px`,
          fontFamily: 'Consolas, "Courier New", monospace',
          color: textColor
        }
      );
      this.cheatIndicator.setOrigin(1, 1);
      this.cheatIndicator.setDepth(1000);
    }
    
    if (this.cheatIndicator) {
      this.cheatIndicator.setVisible(activeCheats.length > 0);
    }
  }

  clear() {
    if (this.uiText) {
      this.uiText.destroy();
      this.uiText = null;
    }
    if (this.comboText) {
      this.comboText.destroy();
      this.comboText = null;
    }
    if (this.livesGraphics) {
      this.livesGraphics.destroy();
      this.livesGraphics = null;
    }
    if (this.progressBarBg) {
      this.progressBarBg.destroy();
      this.progressBarBg = null;
    }
    if (this.progressBar) {
      this.progressBar.destroy();
      this.progressBar = null;
    }
    if (this.levelText) {
      this.levelText.destroy();
      this.levelText = null;
    }
    for (const text of Object.values(this.powerupTexts)) {
      if (text) text.destroy();
    }
    this.powerupTexts = {};
    if (this.cheatIndicator) {
      this.cheatIndicator.destroy();
      this.cheatIndicator = null;
    }
  }
}





