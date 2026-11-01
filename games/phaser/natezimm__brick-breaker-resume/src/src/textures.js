import { COLORS, GAME_CONSTANTS, TEXTURE_KEYS, THEMES } from './constants.js';

/** `glass` belongs to the Glass theme, `ink` to Paper. */
const LOOKS = Object.freeze({ GLASS: 'glass', INK: 'ink' });

function lookFor(theme) {
  return theme === THEMES.LIGHT ? LOOKS.INK : LOOKS.GLASS;
}

function toCssHex(color) {
  return `#${color.toString(16).padStart(6, '0')}`;
}

function toRgb(color) {
  return {
    r: (color >> 16) & 255,
    g: (color >> 8) & 255,
    b: color & 255,
  };
}

function rgba(color, alpha) {
  const { r, g, b } = toRgb(color);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function fillRoundedRect(context, x, y, width, height, radius) {
  context.beginPath();
  context.roundRect(x, y, width, height, radius);
  context.fill();
}

function strokeRoundedRect(context, x, y, width, height, radius) {
  context.beginPath();
  context.roundRect(x, y, width, height, radius);
  context.stroke();
}

function fillCircle(context, x, y, radius) {
  context.beginPath();
  context.arc(x, y, radius, 0, Math.PI * 2);
  context.fill();
}

/** A lit glass pill: translucent body, bright rim, sheen across the top. */
function drawGlassPaddle(context, width, height, color) {
  const inset = 1;
  const bodyWidth = Math.max(1, width - inset * 2);
  const bodyHeight = Math.max(1, height - inset * 2);
  const radius = bodyHeight / 2;

  context.fillStyle = rgba(color, 0.2);
  fillRoundedRect(context, inset, inset, bodyWidth, bodyHeight, radius);

  const sheen = context.createLinearGradient(0, inset, 0, inset + bodyHeight);
  sheen.addColorStop(0, 'rgba(255, 255, 255, 0.5)');
  sheen.addColorStop(0.45, 'rgba(255, 255, 255, 0.08)');
  sheen.addColorStop(1, 'rgba(255, 255, 255, 0)');
  context.fillStyle = sheen;
  fillRoundedRect(context, inset, inset, bodyWidth, bodyHeight, radius);

  context.strokeStyle = rgba(color, 0.92);
  context.lineWidth = 1.25;
  strokeRoundedRect(
    context,
    inset + 0.5,
    inset + 0.5,
    bodyWidth - 1,
    bodyHeight - 1,
    Math.max(1, radius - 0.5)
  );
}

/** A printer's rule: a heavy bar with a hairline beneath it. */
function drawInkPaddle(context, width, height, color) {
  const barHeight = Math.max(2, Math.round(height * 0.45));

  context.fillStyle = toCssHex(color);
  context.fillRect(0, 0, width, barHeight);
  context.fillRect(0, barHeight + 3, width, 1.5);
}

export function createPaddleCanvas({
  width = GAME_CONSTANTS.PADDLE_WIDTH,
  height = GAME_CONSTANTS.PADDLE_HEIGHT,
  color = COLORS.PADDLE,
  look = LOOKS.GLASS,
} = {}) {
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;

  const context = canvas.getContext('2d');
  if (look === LOOKS.INK) {
    drawInkPaddle(context, width, height, color);
  } else {
    drawGlassPaddle(context, width, height, color);
  }

  return canvas;
}

/** A white-hot core that takes on the chosen colour toward its edge. */
function drawGlassBall(context, center, radius, color) {
  context.fillStyle = toCssHex(color);
  fillCircle(context, center, center, radius);

  const core = context.createRadialGradient(
    center,
    center,
    radius * 0.1,
    center,
    center,
    radius
  );
  core.addColorStop(0, 'rgba(255, 255, 255, 1)');
  core.addColorStop(0.55, 'rgba(255, 255, 255, 0.85)');
  core.addColorStop(1, 'rgba(255, 255, 255, 0.1)');
  context.fillStyle = core;
  fillCircle(context, center, center, radius);
}

/** A flat dot of ink with a faint offset shadow on the paper. */
function drawInkBall(context, center, radius, color) {
  const inkRadius = radius - 1.5;

  context.fillStyle = 'rgba(0, 0, 0, 0.14)';
  fillCircle(context, center + 1, center + 1.5, inkRadius);

  context.fillStyle = toCssHex(color);
  fillCircle(context, center, center, inkRadius);
}

export function createBallCanvas({
  size = GAME_CONSTANTS.BALL_SIZE,
  radius = GAME_CONSTANTS.BALL_RADIUS,
  color = COLORS.BALL,
  look = LOOKS.GLASS,
} = {}) {
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;

  const context = canvas.getContext('2d');
  const center = size / 2;
  const visualRadius = Math.max(2, Math.min(radius, center) - 1);

  if (look === LOOKS.INK) {
    drawInkBall(context, center, visualRadius, color);
  } else {
    drawGlassBall(context, center, visualRadius, color);
  }

  return canvas;
}

function replaceTexture(scene, textureKey, canvas) {
  if (scene.textures.exists(textureKey)) {
    scene.textures.remove(textureKey);
  }

  scene.textures.addCanvas(textureKey, canvas);
}

function paddleCanvasFor(settings) {
  return createPaddleCanvas({
    width: settings.paddleWidth,
    height: GAME_CONSTANTS.PADDLE_HEIGHT,
    color: settings.paddleColor,
    look: lookFor(settings.theme),
  });
}

function ballCanvasFor(settings) {
  return createBallCanvas({
    size: GAME_CONSTANTS.BALL_SIZE,
    radius: GAME_CONSTANTS.BALL_RADIUS,
    color: settings.ballColor,
    look: lookFor(settings.theme),
  });
}

export function registerGameTextures(scene, settings) {
  replaceTexture(scene, TEXTURE_KEYS.PADDLE, paddleCanvasFor(settings));
  replaceTexture(scene, TEXTURE_KEYS.BALL, ballCanvasFor(settings));
}

export function refreshBallTexture(scene, state, settings) {
  if (!scene || !state?.ball) return;

  replaceTexture(scene, TEXTURE_KEYS.BALL, ballCanvasFor(settings));

  state.ball.setTexture(TEXTURE_KEYS.BALL);
  state.ball.setDisplaySize(GAME_CONSTANTS.BALL_SIZE, GAME_CONSTANTS.BALL_SIZE);
}

export function refreshPaddleTexture(scene, state, settings) {
  if (!scene || !state?.paddle) return;

  replaceTexture(scene, TEXTURE_KEYS.PADDLE, paddleCanvasFor(settings));

  const { x, y } = state.paddle;
  state.paddle.setTexture(TEXTURE_KEYS.PADDLE);
  state.paddle.setDisplaySize(
    settings.paddleWidth,
    GAME_CONSTANTS.PADDLE_HEIGHT
  );
  state.paddle.setPosition(x, y);
  state.paddle.body.setSize(settings.paddleWidth, GAME_CONSTANTS.PADDLE_HEIGHT);
}
