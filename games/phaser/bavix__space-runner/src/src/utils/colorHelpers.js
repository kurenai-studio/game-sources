// Helper functions for safe color access
import { COLOR_PATHS } from '../constants/colorPaths.js';
import { PLAYER_STATES } from '../constants/gameParams.js';

/**
 * Safe color getter with validation
 * @param {ThemeManager} themeManager - Theme manager instance
 * @param {string} path - Color path constant from COLOR_PATHS
 * @param {number} defaultValue - Default color value if path not found
 * @returns {number} Color value
 */
export function getColor(themeManager, path, defaultValue = null) {
  if (!themeManager) {
    console.warn('ThemeManager not provided to getColor');
    return defaultValue;
  }
  
  return themeManager.getColor(path, defaultValue);
}


/**
 * Get player color object based on state
 * Returns full color object { main, accent, dark, glow? }
 */
export function getPlayerColors(themeManager, state) {
  const stateMap = {
    [PLAYER_STATES.WALLHACK]: COLOR_PATHS.PLAYER.WALLHACK.BASE,
    [PLAYER_STATES.HYPERSPEED]: COLOR_PATHS.PLAYER.HYPERSPEED.BASE,
    [PLAYER_STATES.NORMAL]: COLOR_PATHS.PLAYER.NORMAL.BASE
  };
  
  const basePath = stateMap[state] || COLOR_PATHS.PLAYER.NORMAL.BASE;
  return themeManager.getColor(basePath);
}

/**
 * Get powerup color object or single property
 */
export function getPowerupColor(themeManager, type, property = null) {
  const pathMap = {
    rapid: COLOR_PATHS.POWERUP.RAPID,
    triple: COLOR_PATHS.POWERUP.TRIPLE,
    shield: COLOR_PATHS.POWERUP.SHIELD,
    life: COLOR_PATHS.POWERUP.LIFE,
    autoAim: COLOR_PATHS.POWERUP.AUTO_AIM,
    magnet: COLOR_PATHS.POWERUP.MAGNET,
    slowMotion: COLOR_PATHS.POWERUP.SLOW_MOTION
  };
  
  const powerupPaths = pathMap[type];
  if (!powerupPaths) {
    console.warn(`Unknown powerup type: ${type}`);
    return null;
  }
  
  // If property is specified, return single color value
  if (property) {
    const propertyKey = property === 'main' ? 'MAIN' : 
                        property === 'accent' ? 'ACCENT' : 
                        property === 'light' ? 'LIGHT' : 'MAIN';
    const path = powerupPaths[propertyKey] || powerupPaths.MAIN;
    return getColor(themeManager, path);
  }
  
  // Otherwise return full color object
  return themeManager.getColor(powerupPaths.BASE);
}

/**
 * Get particle color
 */
export function getParticleColor(themeManager, type) {
  const pathMap = {
    normal: COLOR_PATHS.PARTICLES.DEFAULT,
    explosion: COLOR_PATHS.PARTICLES.EXPLOSION,
    level: COLOR_PATHS.PARTICLES.LEVEL,
    hyperspeed: COLOR_PATHS.PARTICLES.HYPERSPEED,
    triple: COLOR_PATHS.PARTICLES.TRIPLE,
    shield: COLOR_PATHS.PARTICLES.SHIELD,
    life: COLOR_PATHS.PARTICLES.LIFE,
    autoAim: COLOR_PATHS.PARTICLES.AUTO_AIM,
    magnet: COLOR_PATHS.PARTICLES.MAGNET,
    slowMotion: COLOR_PATHS.PARTICLES.SLOW_MOTION,
    boss: COLOR_PATHS.PARTICLES.BOSS,
    bossKill: COLOR_PATHS.PARTICLES.BOSS_KILL
  };
  
  const path = pathMap[type] || COLOR_PATHS.PARTICLES.DEFAULT;
  return getColor(themeManager, path);
}

/**
 * Format color to hex string for CSS/Text
 */
export function colorToHex(color) {
  if (typeof color === 'number') {
    return `#${color.toString(16).padStart(6, '0')}`;
  }
  return color;
}

