export const GAME_CONSTANTS = {
  INITIAL_LIVES: 5,
  INITIAL_SCORE: 0,
  PADDLE_WIDTH: 100,
  PADDLE_HEIGHT: 20,
  BALL_SIZE: 20,
  BALL_RADIUS: 10,
  BALL_INITIAL_VELOCITY: { x: 200, y: -200 },
  LIFE_LOST_RESTART_DELAY: 2000,
  BRICK_HEIGHT: 24,
  BRICK_PADDING: 4,
  BASE_BRICK_WIDTH: 10,
  MARGIN_TOP: 10,
  COUNTDOWN_START: 3,
  COUNTDOWN_INTERVAL: 1000,
  MAX_BRICK_HEIGHT_RATIO: 0.75,
  TRAIL_LENGTH: 7,
};

export const COLORS = {
  BACKGROUND: '#FFFFFF',
  PADDLE: 0xa9a9a9,
  BALL: 0xa9a9a9,
  TEXT: '#000000',
  TEXT_LIGHT: '#A9A9A9',
  GAME_OVER: '#f00',
  BRICK_COLORS: [0xf44336, 0xffc107, 0x4caf50, 0x2196f3],
  INK: 0x16181d,
};

export const THEMES = Object.freeze({
  LIGHT: 'light',
  DARK: 'dark',
});

/**
 * Each theme is a complete look: `dark` is Glass (a justified wall of
 * glowing bricks), `light` is Paper (the résumé typeset as a printed page).
 */
export const THEME_LOOKS = Object.freeze({
  [THEMES.DARK]: Object.freeze({
    layout: 'wall',
    ball: 0xffffff,
    paddle: 0xffffff,
    accent: 0x3b9dff,
  }),
  [THEMES.LIGHT]: Object.freeze({
    layout: 'typeset',
    ball: COLORS.INK,
    paddle: COLORS.INK,
    accent: COLORS.INK,
  }),
});

export const AUDIO_KEYS = {
  BALL_HIT: 'ballHit',
  BRICK_HIT: 'brickHit',
  LOSE_LIFE: 'loseLife',
  WIN_GAME: 'winGame',
  GAME_OVER: 'gameOver',
};

export const TEXTURE_KEYS = {
  PADDLE: 'paddleTexture',
  BALL: 'ballTexture',
};
