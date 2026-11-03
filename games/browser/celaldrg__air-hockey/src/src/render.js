// Canvas drawing of the neon table, puck, mallets, scores and goal banners.
import {
  WIDTH, LENGTH, HALF, CORNER_RADIUS, GOAL_LEFT, GOAL_RIGHT, PUCK_RADIUS, MALLET_RADIUS,
} from './table.js';
import { GOAL_PAUSE } from './game.js';
import { MARGIN, toCanvas } from './view.js';

export const PLAYER_COLORS = Object.freeze(['#22d3ee', '#f472b6']);
const PUCK_COLOR = '#facc15';
const FLASH_TIME = 0.4;
const FONT = 'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif';

/** Sets a transform so drawing happens in table units. */
function tableSpace(ctx, view, dpr) {
  const k = view.scale * dpr;
  ctx.setTransform(k, 0, 0, k, view.ox * dpr, view.oy * dpr);
}

/** Traces the rounded playing surface. */
function tablePath(ctx) {
  const c = CORNER_RADIUS;
  ctx.beginPath();
  ctx.moveTo(c, 0);
  ctx.arc(WIDTH - c, c, c, -Math.PI / 2, 0);
  ctx.arc(WIDTH - c, LENGTH - c, c, 0, Math.PI / 2);
  ctx.arc(c, LENGTH - c, c, Math.PI / 2, Math.PI);
  ctx.arc(c, c, c, Math.PI, Math.PI * 1.5);
  ctx.closePath();
}

/** Traces the rim with gaps for the two goal mouths. */
function rimPath(ctx) {
  const c = CORNER_RADIUS;
  ctx.beginPath();
  ctx.moveTo(GOAL_RIGHT, 0);
  ctx.arc(WIDTH - c, c, c, -Math.PI / 2, 0);
  ctx.arc(WIDTH - c, LENGTH - c, c, 0, Math.PI / 2);
  ctx.lineTo(GOAL_RIGHT, LENGTH);
  ctx.moveTo(GOAL_LEFT, LENGTH);
  ctx.arc(c, LENGTH - c, c, Math.PI / 2, Math.PI);
  ctx.arc(c, c, c, Math.PI, Math.PI * 1.5);
  ctx.lineTo(GOAL_LEFT, 0);
}

/** Strokes the current path with a neon glow. */
function glowStroke(ctx, color, width, glow, k) {
  ctx.save();
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.shadowColor = color;
  ctx.shadowBlur = glow * k;
  ctx.stroke();
  ctx.restore();
}

/** Outer frame, surface, air holes and markings (static layer). */
function drawTable(ctx, k) {
  const m = MARGIN * 0.75;
  ctx.fillStyle = '#0b1222';
  ctx.beginPath();
  ctx.roundRect(-m, -m, WIDTH + 2 * m, LENGTH + 2 * m, CORNER_RADIUS + m);
  ctx.fill();
  const surface = ctx.createLinearGradient(0, 0, WIDTH, LENGTH);
  surface.addColorStop(0, '#10233b');
  surface.addColorStop(1, '#0c1729');
  tablePath(ctx);
  ctx.fillStyle = surface;
  ctx.fill();
  ctx.save();
  tablePath(ctx);
  ctx.clip();
  ctx.fillStyle = 'rgba(148, 163, 184, 0.1)';
  for (let y = 0.05; y < LENGTH; y += 0.08) {
    for (let x = 0.05; x < WIDTH; x += 0.08) {
      ctx.beginPath();
      ctx.arc(x, y, 0.004, 0, Math.PI * 2);
      ctx.fill();
    }
  }
  drawMarkings(ctx, k);
  ctx.restore();
  drawGoals(ctx, k);
  rimPath(ctx);
  ctx.lineCap = 'round';
  glowStroke(ctx, '#67e8f9', 0.012, 0.035, k);
}

/** Centre line, centre circle and goal creases. */
function drawMarkings(ctx, k) {
  ctx.beginPath();
  ctx.moveTo(0, HALF);
  ctx.lineTo(WIDTH, HALF);
  glowStroke(ctx, 'rgba(226, 232, 240, 0.45)', 0.006, 0.02, k);
  ctx.beginPath();
  ctx.arc(WIDTH / 2, HALF, 0.14, 0, Math.PI * 2);
  glowStroke(ctx, 'rgba(226, 232, 240, 0.4)', 0.006, 0.02, k);
  ctx.beginPath();
  ctx.arc(WIDTH / 2, HALF, 0.018, 0, Math.PI * 2);
  ctx.fillStyle = 'rgba(226, 232, 240, 0.5)';
  ctx.fill();
  [LENGTH, 0].forEach((gy, side) => {
    ctx.beginPath();
    ctx.arc(WIDTH / 2, gy, 0.2, side === 0 ? Math.PI : 0, side === 0 ? 0 : Math.PI);
    glowStroke(ctx, `${PLAYER_COLORS[side]}99`, 0.006, 0.025, k);
  });
}

/** Goal pockets behind each goal line, glowing in the defender's colour. */
function drawGoals(ctx, k) {
  const depth = MARGIN * 0.75;
  [[LENGTH, LENGTH, 0], [-depth, 0, 1]].forEach(([top, line, side]) => {
    ctx.fillStyle = '#020617';
    ctx.fillRect(GOAL_LEFT, top, GOAL_RIGHT - GOAL_LEFT, depth);
    ctx.beginPath();
    ctx.moveTo(GOAL_LEFT, line);
    ctx.lineTo(GOAL_RIGHT, line);
    glowStroke(ctx, PLAYER_COLORS[side], 0.008, 0.04, k);
    [GOAL_LEFT, GOAL_RIGHT].forEach((px) => {
      ctx.beginPath();
      ctx.arc(px, line, 0.012, 0, Math.PI * 2);
      ctx.fillStyle = '#e2e8f0';
      ctx.fill();
    });
  });
}

/**
 * Renders the static table into an offscreen canvas for the current view.
 * @param {import('./view.js').View} view
 * @param {number} dpr
 * @returns {HTMLCanvasElement}
 */
export function buildBackground(view, dpr) {
  const layer = document.createElement('canvas');
  layer.width = Math.round(view.width * dpr);
  layer.height = Math.round(view.height * dpr);
  const ctx = layer.getContext('2d');
  tableSpace(ctx, view, dpr);
  drawTable(ctx, view.scale * dpr);
  return layer;
}

/** Fading trail behind a fast puck. */
function drawTrail(ctx, trail) {
  const n = trail.length;
  trail.forEach((p, i) => {
    const f = (i + 1) / (n + 1);
    ctx.beginPath();
    ctx.arc(p.x, p.y, PUCK_RADIUS * (0.35 + 0.6 * f), 0, Math.PI * 2);
    ctx.fillStyle = `rgba(250, 204, 21, ${(0.32 * f).toFixed(3)})`;
    ctx.fill();
  });
}

/** The puck with a warm glow. */
function drawPuck(ctx, puck, k) {
  ctx.save();
  ctx.shadowColor = PUCK_COLOR;
  ctx.shadowBlur = 0.05 * k;
  ctx.beginPath();
  ctx.arc(puck.x, puck.y, PUCK_RADIUS, 0, Math.PI * 2);
  ctx.fillStyle = PUCK_COLOR;
  ctx.fill();
  ctx.restore();
  ctx.beginPath();
  ctx.arc(puck.x, puck.y, PUCK_RADIUS * 0.55, 0, Math.PI * 2);
  ctx.fillStyle = '#fef9c3';
  ctx.fill();
}

/** A mallet: glowing ring and a raised knob. */
function drawMallet(ctx, m, color, k) {
  const r = MALLET_RADIUS;
  ctx.save();
  ctx.shadowColor = color;
  ctx.shadowBlur = 0.06 * k;
  const body = ctx.createRadialGradient(m.x - r * 0.3, m.y - r * 0.3, r * 0.1, m.x, m.y, r);
  body.addColorStop(0, '#f8fafc');
  body.addColorStop(0.35, color);
  body.addColorStop(1, '#0f172a');
  ctx.beginPath();
  ctx.arc(m.x, m.y, r, 0, Math.PI * 2);
  ctx.fillStyle = body;
  ctx.fill();
  ctx.restore();
  ctx.beginPath();
  ctx.arc(m.x, m.y, r * 0.92, 0, Math.PI * 2);
  ctx.strokeStyle = color;
  ctx.lineWidth = r * 0.12;
  ctx.stroke();
  ctx.beginPath();
  ctx.arc(m.x, m.y, r * 0.42, 0, Math.PI * 2);
  ctx.fillStyle = '#0f172a';
  ctx.fill();
  ctx.strokeStyle = color;
  ctx.lineWidth = r * 0.1;
  ctx.stroke();
}

/** Draws text centred at a table position, optionally upside down. */
function tableText(ctx, view, dpr, text, x, y, opts) {
  const p = toCanvas(view, x, y);
  ctx.save();
  ctx.setTransform(dpr, 0, 0, dpr, p.x * dpr, p.y * dpr);
  if (opts.flip) ctx.rotate(Math.PI);
  ctx.font = `${opts.weight ?? 700} ${Math.max(10, opts.size * view.scale)}px ${FONT}`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillStyle = opts.color;
  if (opts.glow) {
    ctx.shadowColor = opts.glow;
    ctx.shadowBlur = 16 * dpr;
  }
  ctx.fillText(text, 0, 0);
  ctx.restore();
}

/** Both scores beside the centre line; the top one faces its player in two-player mode. */
function drawScores(ctx, view, dpr, state, labels, flipTop) {
  [0, 1].forEach((side) => {
    const dir = side === 0 ? 1 : -1;
    const flip = side === 1 && flipTop;
    const x = WIDTH - 0.13;
    const color = PLAYER_COLORS[side];
    tableText(ctx, view, dpr, String(state.score[side]), x, HALF + dir * 0.1,
      { size: 0.12, color, glow: color, flip });
    tableText(ctx, view, dpr, labels[side], x, HALF + dir * 0.19,
      { size: 0.042, weight: 600, color: 'rgba(226, 232, 240, 0.75)', flip });
  });
}

/** Colour flash and "Goal!" banner(s) during the pause after a goal. */
function drawGoalEffects(ctx, view, dpr, state, goalText, flipTop, reducedMotion) {
  const color = PLAYER_COLORS[state.lastScorer];
  const since = GOAL_PAUSE - state.goalTimer;
  if (!reducedMotion && since < FLASH_TIME) {
    tableSpace(ctx, view, dpr);
    tablePath(ctx);
    ctx.fillStyle = color;
    ctx.globalAlpha = 0.35 * (1 - since / FLASH_TIME);
    ctx.fill();
    ctx.globalAlpha = 1;
  }
  const banner = { size: 0.13, weight: 800, color: '#f8fafc', glow: color };
  if (flipTop) {
    tableText(ctx, view, dpr, goalText, WIDTH / 2, HALF + 0.32, banner);
    tableText(ctx, view, dpr, goalText, WIDTH / 2, HALF - 0.32, { ...banner, flip: true });
  } else {
    tableText(ctx, view, dpr, goalText, WIDTH / 2, HALF + (state.lastScorer === 0 ? -0.32 : 0.32), banner);
  }
}

/**
 * Draws one frame.
 * @param {CanvasRenderingContext2D} ctx
 * @param {HTMLCanvasElement} background From buildBackground for this view.
 * @param {import('./view.js').View} view
 * @param {number} dpr
 * @param {ReturnType<import('./game.js').getState>} state
 * @param {{labels: string[], goalText: string, flipTop: boolean, reducedMotion: boolean}} opts
 */
export function drawFrame(ctx, background, view, dpr, state, opts) {
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
  ctx.drawImage(background, 0, 0);
  drawScores(ctx, view, dpr, state, opts.labels, opts.flipTop);
  const k = view.scale * dpr;
  tableSpace(ctx, view, dpr);
  drawTrail(ctx, state.trail);
  state.mallets.forEach((m, side) => drawMallet(ctx, m, PLAYER_COLORS[side], k));
  drawPuck(ctx, state.puck, k);
  if (state.phase === 'goal') {
    drawGoalEffects(ctx, view, dpr, state, opts.goalText, opts.flipTop, opts.reducedMotion);
  }
}
