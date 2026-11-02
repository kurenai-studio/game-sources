// Color path constants - prevents typos and provides autocomplete
// All color paths used in the game

export const COLOR_PATHS = {
  // Background and text
  BACKGROUND: 'background',
  TEXT: 'text',
  TEXT_SECONDARY: 'textSecondary',
  BORDER: 'border',
  
  // Player colors
  PLAYER: {
    NORMAL: {
      BASE: 'player.normal',
      MAIN: 'player.normal.main',
      ACCENT: 'player.normal.accent',
      DARK: 'player.normal.dark',
      GLOW: 'player.normal.glow'
    },
    HYPERSPEED: {
      BASE: 'player.hyperspeed',
      MAIN: 'player.hyperspeed.main',
      ACCENT: 'player.hyperspeed.accent',
      DARK: 'player.hyperspeed.dark',
      GLOW: 'player.hyperspeed.glow'
    },
    WALLHACK: {
      BASE: 'player.wallhack',
      MAIN: 'player.wallhack.main',
      ACCENT: 'player.wallhack.accent',
      DARK: 'player.wallhack.dark'
    }
  },
  
  // Bullets
  BULLET: {
    MAIN: 'bullet.main',
    ACCENT: 'bullet.accent',
    GLOW: 'bullet.glow'
  },
  BOSS_BULLET: {
    MAIN: 'bossBullet.main',
    ACCENT: 'bossBullet.accent',
    GLOW: 'bossBullet.glow'
  },
  
  // Obstacles
  ASTEROID: {
    OUTER: 'asteroid.outer',
    MIDDLE: 'asteroid.middle',
    INNER: 'asteroid.inner',
    HIGHLIGHT: 'asteroid.highlight'
  },
  COMET: {
    MAIN: 'comet.main',
    CORE: 'comet.core',
    TRAIL: 'comet.trail',
    TRAIL_BRIGHT: 'comet.trailBright'
  },
  FAST_ENEMY: {
    MAIN: 'fastEnemy.main',
    ACCENT: 'fastEnemy.accent',
    CORE: 'fastEnemy.core',
    DARK: 'fastEnemy.dark',
    EYES: 'fastEnemy.eyes'
  },
  BIG_ENEMY: {
    OUTER: 'bigEnemy.outer',
    MIDDLE: 'bigEnemy.middle',
    INNER: 'bigEnemy.inner',
    DARK: 'bigEnemy.dark',
    DARKEST: 'bigEnemy.darkest'
  },
  
  // Energy and powerups
  ENERGY: {
    MAIN: 'energy.main',
    ACCENT: 'energy.accent',
    CORE: 'energy.core'
  },
  POWERUP: {
    RAPID: {
      BASE: 'powerup.rapid',
      MAIN: 'powerup.rapid.main',
      ACCENT: 'powerup.rapid.accent',
      LIGHT: 'powerup.rapid.light'
    },
    TRIPLE: {
      BASE: 'powerup.triple',
      MAIN: 'powerup.triple.main',
      ACCENT: 'powerup.triple.accent'
    },
    SHIELD: {
      BASE: 'powerup.shield',
      MAIN: 'powerup.shield.main',
      ACCENT: 'powerup.shield.accent',
      LIGHT: 'powerup.shield.light'
    },
    LIFE: {
      BASE: 'powerup.life',
      MAIN: 'powerup.life.main',
      ACCENT: 'powerup.life.accent',
      LIGHT: 'powerup.life.light'
    },
    AUTO_AIM: {
      BASE: 'powerup.autoAim',
      MAIN: 'powerup.autoAim.main',
      ACCENT: 'powerup.autoAim.accent',
      LIGHT: 'powerup.autoAim.light'
    },
    MAGNET: {
      BASE: 'powerup.magnet',
      MAIN: 'powerup.magnet.main',
      ACCENT: 'powerup.magnet.accent',
      LIGHT: 'powerup.magnet.light'
    },
    SLOW_MOTION: {
      BASE: 'powerup.slowMotion',
      MAIN: 'powerup.slowMotion.main',
      ACCENT: 'powerup.slowMotion.accent',
      LIGHT: 'powerup.slowMotion.light'
    }
  },
  
  // Particles
  PARTICLES: {
    DEFAULT: 'particles.default',
    EXPLOSION: 'particles.explosion',
    LEVEL: 'particles.level',
    HYPERSPEED: 'particles.hyperspeed',
    TRIPLE: 'particles.triple',
    SHIELD: 'particles.shield',
    LIFE: 'particles.life',
    AUTO_AIM: 'particles.autoAim',
    MAGNET: 'particles.magnet',
    SLOW_MOTION: 'particles.slowMotion',
    BOSS: 'particles.boss',
    BOSS_KILL: 'particles.bossKill'
  },
  
  // UI
  UI: {
    SCORE: 'ui.score',
    LIVES: 'ui.lives',
    COMBO: 'ui.combo',
    POWERUP: 'ui.powerup',
    PROGRESS_BG: 'ui.progressBg',
    PROGRESS_FILL: 'ui.progressFill',
    HEALTH_GOOD: 'ui.healthGood',
    HEALTH_MEDIUM: 'ui.healthMedium',
    HEALTH_LOW: 'ui.healthLow'
  },
  
  // Stars
  STARS: 'stars'
};


