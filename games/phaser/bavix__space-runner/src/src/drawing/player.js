// Player drawing functions
import { drawPixel } from './pixel.js';
import { COLOR_PATHS, PLAYER_STATES } from '../constants/index.js';
import { getPlayerColors } from '../utils/colorHelpers.js';

export function drawPlayer(graphics, themeManager, isHyperspeed, isWallHackActive) {
  graphics.clear();
  
  // Get player colors based on state
  const playerState = isWallHackActive ? PLAYER_STATES.WALLHACK :
                      isHyperspeed ? PLAYER_STATES.HYPERSPEED :
                      PLAYER_STATES.NORMAL;
  
  const playerColors = getPlayerColors(themeManager, playerState);
  const mainColor = playerColors.main;
  const accentColor = playerColors.accent;
  const darkColor = playerColors.dark;
  
  const centerX = 0;
  const centerY = 0;
  
  graphics.fillStyle(mainColor);
  drawPixel(graphics, centerX, centerY - 7, 1);
  drawPixel(graphics, centerX - 1, centerY - 6, 1);
  drawPixel(graphics, centerX + 1, centerY - 6, 1);
  drawPixel(graphics, centerX - 2, centerY - 5, 1);
  drawPixel(graphics, centerX + 2, centerY - 5, 1);
  drawPixel(graphics, centerX - 3, centerY - 4, 1);
  drawPixel(graphics, centerX + 3, centerY - 4, 1);
  drawPixel(graphics, centerX - 3, centerY - 3, 1);
  drawPixel(graphics, centerX + 3, centerY - 3, 1);
  drawPixel(graphics, centerX - 4, centerY - 2, 1);
  drawPixel(graphics, centerX + 4, centerY - 2, 1);
  drawPixel(graphics, centerX - 4, centerY - 1, 1);
  drawPixel(graphics, centerX + 4, centerY - 1, 1);
  drawPixel(graphics, centerX - 5, centerY, 1);
  drawPixel(graphics, centerX - 1, centerY, 1);
  drawPixel(graphics, centerX, centerY, 1);
  drawPixel(graphics, centerX + 1, centerY, 1);
  drawPixel(graphics, centerX + 5, centerY, 1);
  drawPixel(graphics, centerX - 4, centerY + 1, 1);
  drawPixel(graphics, centerX + 4, centerY + 1, 1);
  drawPixel(graphics, centerX - 4, centerY + 2, 1);
  drawPixel(graphics, centerX + 4, centerY + 2, 1);
  drawPixel(graphics, centerX - 3, centerY + 3, 1);
  drawPixel(graphics, centerX + 3, centerY + 3, 1);
  drawPixel(graphics, centerX - 3, centerY + 4, 1);
  drawPixel(graphics, centerX + 3, centerY + 4, 1);
  drawPixel(graphics, centerX - 2, centerY + 5, 1);
  drawPixel(graphics, centerX + 2, centerY + 5, 1);
  drawPixel(graphics, centerX - 1, centerY + 6, 1);
  drawPixel(graphics, centerX + 1, centerY + 6, 1);
  drawPixel(graphics, centerX, centerY + 7, 1);
  
  graphics.fillStyle(accentColor);
  drawPixel(graphics, centerX, centerY - 5, 1);
  drawPixel(graphics, centerX - 1, centerY - 4, 1);
  drawPixel(graphics, centerX + 1, centerY - 4, 1);
  drawPixel(graphics, centerX - 2, centerY - 3, 1);
  drawPixel(graphics, centerX + 2, centerY - 3, 1);
  drawPixel(graphics, centerX - 3, centerY - 2, 1);
  drawPixel(graphics, centerX + 3, centerY - 2, 1);
  drawPixel(graphics, centerX - 2, centerY - 1, 1);
  drawPixel(graphics, centerX + 2, centerY - 1, 1);
  drawPixel(graphics, centerX - 1, centerY, 1);
  drawPixel(graphics, centerX + 1, centerY, 1);
  drawPixel(graphics, centerX - 2, centerY + 1, 1);
  drawPixel(graphics, centerX + 2, centerY + 1, 1);
  drawPixel(graphics, centerX - 3, centerY + 2, 1);
  drawPixel(graphics, centerX + 3, centerY + 2, 1);
  drawPixel(graphics, centerX - 2, centerY + 3, 1);
  drawPixel(graphics, centerX + 2, centerY + 3, 1);
  drawPixel(graphics, centerX - 1, centerY + 4, 1);
  drawPixel(graphics, centerX + 1, centerY + 4, 1);
  drawPixel(graphics, centerX, centerY + 5, 1);
  
  graphics.fillStyle(darkColor);
  drawPixel(graphics, centerX, centerY - 3, 1);
  drawPixel(graphics, centerX - 1, centerY - 2, 1);
  drawPixel(graphics, centerX + 1, centerY - 2, 1);
  drawPixel(graphics, centerX, centerY + 2, 1);
  
  if (isHyperspeed) {
    const isDark = themeManager.isDark;
    const glowColor = isDark ? 0xffffff : 0x000000;
    graphics.fillStyle(glowColor);
    for (let i = -3; i <= 3; i++) {
      drawPixel(graphics, centerX - 6, centerY + i, 1);
      drawPixel(graphics, centerX - 7, centerY + i, 1);
      drawPixel(graphics, centerX - 8, centerY + i, 1);
      drawPixel(graphics, centerX - 9, centerY + i, 1);
      drawPixel(graphics, centerX - 10, centerY + i, 1);
    }
    graphics.fillStyle(isDark ? 0xfbbf24 : 0xf59e0b);
    drawPixel(graphics, centerX - 7, centerY, 1);
    drawPixel(graphics, centerX - 8, centerY, 1);
  } else {
    graphics.fillStyle(accentColor);
    drawPixel(graphics, centerX - 5, centerY - 1, 1);
    drawPixel(graphics, centerX - 5, centerY, 1);
    drawPixel(graphics, centerX - 5, centerY + 1, 1);
    drawPixel(graphics, centerX - 6, centerY, 1);
    const normalGlow = themeManager.getColor(COLOR_PATHS.PLAYER.NORMAL.GLOW);
    graphics.fillStyle(normalGlow);
    drawPixel(graphics, centerX - 5, centerY, 1);
  }
}

