/**
 * GOAL RUSH — static playfield artwork, painted once at boot.
 *
 * The table is themed as a night-match stadium: dark stands, neon pitch
 * lines, a goal mouth above the drain. Everything is drawn to a single
 * canvas ("field" texture) so the whole background renders as ONE sprite
 * during play — one draw call, zero per-frame cost.
 */

import { PALETTE, TABLE } from '../config/game.config';
import {
  DOME,
  HUD_BAR,
  LANES,
  LANE_DIVIDERS,
  SAUCER,
  SPINNER,
  WALLS,
  type RectDef,
} from '../config/table.config';

function css(color: number): string {
  return `#${color.toString(16).padStart(6, '0')}`;
}

export function paintField(scene: Phaser.Scene): void {
  if (scene.textures.exists('field')) return;

  const W = TABLE.width;
  const H = TABLE.height;
  const canvas = document.createElement('canvas');
  canvas.width = W;
  canvas.height = H;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('2D canvas unavailable');

  // ── Deep background + stands ────────────────────────────────────────────
  ctx.fillStyle = css(PALETTE.bgDeep);
  ctx.fillRect(0, 0, W, H);

  // Crowd glitter in the stands (top band behind the dome).
  const rand = mulberry32(42);
  for (let i = 0; i < 340; i += 1) {
    const x = rand() * W;
    const y = rand() * 210;
    const alpha = 0.05 + rand() * 0.3;
    const hue = rand();
    ctx.fillStyle =
      hue < 0.55
        ? `rgba(53,240,139,${alpha})`
        : hue < 0.8
          ? `rgba(255,201,60,${alpha})`
          : `rgba(255,255,255,${alpha})`;
    ctx.fillRect(x, y, 1.6, 1.6);
  }
  // Stand separator glow line.
  ctx.fillStyle = 'rgba(53,240,139,0.12)';
  ctx.fillRect(0, 208, W, 2);

  // ── G-O-A-L rollover inserts ──────────────────────────────────────────
  // Each lane letter sits in a painted "button" so the unlit inserts read
  // as physical rollovers, not floating text.
  for (const lane of LANES) {
    ctx.save();
    // Dark insert well.
    ctx.fillStyle = 'rgba(8,13,26,0.72)';
    ctx.beginPath();
    ctx.arc(lane.x, lane.y, 21, 0, Math.PI * 2);
    ctx.fill();
    // Steel ring.
    ctx.strokeStyle = 'rgba(184,200,234,0.4)';
    ctx.lineWidth = 2;
    ctx.shadowColor = 'rgba(184,200,234,0.5)';
    ctx.shadowBlur = 5;
    ctx.beginPath();
    ctx.arc(lane.x, lane.y, 21, 0, Math.PI * 2);
    ctx.stroke();
    // Tiny corner ticks pointing at the dividers.
    ctx.shadowBlur = 0;
    ctx.strokeStyle = 'rgba(184,200,234,0.28)';
    ctx.lineWidth = 1.5;
    for (const dx of [-27, 27]) {
      ctx.beginPath();
      ctx.moveTo(lane.x + dx, lane.y - 9);
      ctx.lineTo(lane.x + dx, lane.y + 9);
      ctx.stroke();
    }
    ctx.restore();
  }

  // ── Pitch ────────────────────────────────────────────────────────────────
  // Mow stripes inside the playfield bounds (x 15..482).
  const pitchL = 15;
  const pitchR = 482;
  for (let i = 0; i < 14; i += 1) {
    ctx.fillStyle = i % 2 === 0 ? css(PALETTE.pitchMow) : css(PALETTE.pitch);
    ctx.fillRect(pitchL + (i * (pitchR - pitchL)) / 14, 210, (pitchR - pitchL) / 14 + 1, H - 210);
  }
  // Darken toward the bottom (drain area feels deeper). Kept gentle: a
  // heavy overlay here used to swallow the flippers whole.
  const depth = ctx.createLinearGradient(0, H * 0.68, 0, H);
  depth.addColorStop(0, 'rgba(4,8,16,0)');
  depth.addColorStop(1, 'rgba(4,8,16,0.5)');
  ctx.fillStyle = depth;
  ctx.fillRect(0, H * 0.68, W, H * 0.32);

  ctx.strokeStyle = 'rgba(53,240,139,0.75)';
  ctx.lineWidth = 2.4;
  ctx.save();
  ctx.shadowColor = css(PALETTE.lineGreen);
  ctx.shadowBlur = 6;

  // Touchlines.
  ctx.beginPath();
  ctx.moveTo(pitchL + 3, 640);
  ctx.lineTo(pitchL + 3, 950);
  ctx.moveTo(pitchR - 3, 640);
  ctx.lineTo(pitchR - 3, 950);
  ctx.stroke();

  // Halfway line + center circle around the bumper cluster.
  ctx.beginPath();
  ctx.moveTo(pitchL + 6, 470);
  ctx.lineTo(pitchR - 6, 470);
  ctx.stroke();
  ctx.beginPath();
  ctx.arc(230, 380, 118, 0, Math.PI * 2);
  ctx.stroke();
  ctx.beginPath();
  ctx.arc(230, 380, 4, 0, Math.PI * 2);
  ctx.fillStyle = 'rgba(53,240,139,0.75)';
  ctx.fill();

  // Penalty box + spot around the flipper zone ("shooting area").
  ctx.beginPath();
  ctx.moveTo(pitchL + 3, 640);
  ctx.lineTo(200, 640);
  ctx.lineTo(200, 866);
  ctx.moveTo(pitchR - 3, 640);
  ctx.lineTo(340, 640);
  ctx.lineTo(340, 866);
  ctx.stroke();
  ctx.beginPath();
  ctx.arc(270, 800, 3.4, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();

  // ── SPIN saucer halo ────────────────────────────────────────────────
  // Warm pool of light under the saucer so the hole reads as a target.
  ctx.save();
  const halo = ctx.createRadialGradient(SAUCER.x, SAUCER.y, 6, SAUCER.x, SAUCER.y, 46);
  halo.addColorStop(0, 'rgba(255,201,60,0.20)');
  halo.addColorStop(0.55, 'rgba(255,201,60,0.08)');
  halo.addColorStop(1, 'rgba(255,201,60,0)');
  ctx.fillStyle = halo;
  ctx.fillRect(SAUCER.x - 50, SAUCER.y - 50, 100, 100);
  ctx.restore();

  // ── LEFT LOOP: spinner lane + flow chevrons ─────────────────────────
  // The far-left orbit is the table's signature loop: dome → spinner →
  // funnel → inlane → flipper. Magenta chevrons show the flow direction.
  ctx.save();
  ctx.strokeStyle = 'rgba(255,77,157,0.75)';
  ctx.lineWidth = 2.5;
  ctx.shadowColor = css(PALETTE.magenta);
  ctx.shadowBlur = 6;
  for (const cy of [368, 392, 468, 492]) {
    ctx.beginPath();
    ctx.moveTo(SPINNER.x - 9, cy - 5);
    ctx.lineTo(SPINNER.x, cy + 4);
    ctx.lineTo(SPINNER.x + 9, cy - 5);
    ctx.stroke();
  }
  ctx.restore();
  // Soft pool of light behind the spinner blade.
  ctx.save();
  const spinGlow = ctx.createRadialGradient(SPINNER.x, SPINNER.y, 4, SPINNER.x, SPINNER.y, 40);
  spinGlow.addColorStop(0, 'rgba(255,120,190,0.16)');
  spinGlow.addColorStop(1, 'rgba(255,120,190,0)');
  ctx.fillStyle = spinGlow;
  ctx.fillRect(SPINNER.x - 44, SPINNER.y - 44, 88, 88);
  ctx.restore();

  // ── Inlane channel chevrons (green, feeding the flippers) ──────────
  ctx.save();
  ctx.strokeStyle = 'rgba(53,240,139,0.55)';
  ctx.lineWidth = 2;
  for (const cy of [734, 758, 782]) {
    ctx.beginPath();
    ctx.moveTo(114, cy - 4);
    ctx.lineTo(121.5, cy + 4);
    ctx.lineTo(129, cy - 4);
    ctx.stroke();
  }
  for (const cy of [688, 712, 736]) {
    ctx.beginPath();
    ctx.moveTo(456, cy - 4);
    ctx.lineTo(463.5, cy + 4);
    ctx.lineTo(471, cy - 4);
    ctx.stroke();
  }
  ctx.restore();

  // ── Goal mouth (drain zone) ──────────────────────────────────────────────
  const goalL = 118;
  const goalR = 422;
  const goalY = 878;
  // Net.
  ctx.save();
  ctx.strokeStyle = 'rgba(244,248,255,0.28)';
  ctx.lineWidth = 1;
  for (let x = goalL; x <= goalR; x += 13) {
    ctx.beginPath();
    ctx.moveTo(x, goalY);
    ctx.lineTo(x, 952);
    ctx.stroke();
  }
  for (let y = goalY; y <= 952; y += 13) {
    ctx.beginPath();
    ctx.moveTo(goalL, y);
    ctx.lineTo(goalR, y);
    ctx.stroke();
  }
  // Posts + crossbar.
  ctx.strokeStyle = css(PALETTE.white);
  ctx.lineWidth = 5;
  ctx.shadowColor = css(PALETTE.white);
  ctx.shadowBlur = 8;
  ctx.beginPath();
  ctx.moveTo(goalL, goalY);
  ctx.lineTo(goalL, 950);
  ctx.moveTo(goalR, goalY);
  ctx.lineTo(goalR, 950);
  ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(goalL, goalY);
  ctx.lineTo(goalR, goalY);
  ctx.stroke();
  ctx.restore();

  // ── Dome guide (visual hint of the physics arc) ──────────────────────────
  ctx.save();
  ctx.strokeStyle = 'rgba(53,240,139,0.5)';
  ctx.lineWidth = 3;
  ctx.shadowColor = css(PALETTE.lineGreen);
  ctx.shadowBlur = 10;
  ctx.beginPath();
  ctx.ellipse(DOME.cx, DOME.cy, DOME.rx, DOME.ry, 0, Math.PI, Math.PI * 2);
  ctx.stroke();
  ctx.restore();

  // ─────────────── Cabinet rails + every physics wall ──────────────
  // All WALLS entries are real Matter bodies — paint each one so the ball
  // never appears to bounce off empty space. Data-driven: geometry changes
  // in table.config.ts automatically update the artwork.
  paintWalls(ctx);

  // Wire guides between the G-O-A-L rollover lanes.
  ctx.save();
  ctx.strokeStyle = 'rgba(184,200,234,0.55)';
  ctx.lineWidth = 3;
  ctx.shadowColor = 'rgba(184,200,234,0.6)';
  ctx.shadowBlur = 4;
  ctx.lineCap = 'round';
  for (const d of LANE_DIVIDERS) {
    ctx.beginPath();
    ctx.moveTo(d.x, d.y - d.height / 2 + 3);
    ctx.lineTo(d.x, d.y + d.height / 2 - 3);
    ctx.stroke();
    // Guide caps.
    ctx.fillStyle = 'rgba(213,224,245,0.9)';
    for (const ey of [d.y - d.height / 2 + 3, d.y + d.height / 2 - 3]) {
      ctx.beginPath();
      ctx.arc(d.x, ey, 3.4, 0, Math.PI * 2);
      ctx.fill();
    }
  }
  ctx.restore();

  // ─────────────────────── STADIUM SLOTS topper ─────────────────────────────────
  // Permanent reel display in the upper-right pocket — the slot half of
  // the hybrid stays visible between spins (boot / trophy / ball tease on
  // the payline). Pure art: the ball rolls over it like any playfield art.
  paintSlotsTopper(ctx);

  // ── Launch lane art ──────────────────────────────────────────────────────
  ctx.save();
  ctx.fillStyle = 'rgba(255,77,157,0.9)';
  for (let i = 0; i < 4; i += 1) {
    const y = 850 - i * 46;
    ctx.beginPath();
    ctx.moveTo(502, y);
    ctx.lineTo(509, y - 10);
    ctx.lineTo(516, y);
    ctx.closePath();
    ctx.fill();
  }
  ctx.restore();

  // ── HUD bar backing ──────────────────────────────────────────────────────
  ctx.fillStyle = 'rgba(7,11,20,0.86)';
  roundRectPath(ctx, HUD_BAR.x, HUD_BAR.y, HUD_BAR.width, HUD_BAR.height, 10);
  ctx.fill();
  ctx.strokeStyle = 'rgba(53,240,139,0.5)';
  ctx.lineWidth = 1.5;
  roundRectPath(ctx, HUD_BAR.x, HUD_BAR.y, HUD_BAR.width, HUD_BAR.height, 10);
  ctx.stroke();
  // Faint column separators (CREDITS | JACKPOT | MULT | BALLS).
  ctx.strokeStyle = 'rgba(244,248,255,0.10)';
  ctx.lineWidth = 1;
  for (const sx of [204, 286, 352]) {
    ctx.beginPath();
    ctx.moveTo(sx, HUD_BAR.y + 9);
    ctx.lineTo(sx, HUD_BAR.y + HUD_BAR.height - 9);
    ctx.stroke();
  }

  // ── Glass: vignette + sheen (the "playfield glass" finish) ───────────
  ctx.save();
  const vignette = ctx.createRadialGradient(270, 470, 260, 270, 470, 640);
  vignette.addColorStop(0, 'rgba(2,4,10,0)');
  vignette.addColorStop(0.75, 'rgba(2,4,10,0.10)');
  vignette.addColorStop(1, 'rgba(2,4,10,0.40)');
  ctx.fillStyle = vignette;
  ctx.fillRect(0, 0, W, H);
  ctx.restore();
  ctx.save();
  ctx.globalAlpha = 0.04;
  ctx.fillStyle = '#dfeaff';
  ctx.beginPath();
  ctx.moveTo(120, 0);
  ctx.lineTo(235, 0);
  ctx.lineTo(70, H);
  ctx.lineTo(0, H);
  ctx.lineTo(0, 700);
  ctx.closePath();
  ctx.fill();
  ctx.beginPath();
  ctx.moveTo(300, 0);
  ctx.lineTo(340, 0);
  ctx.lineTo(180, H);
  ctx.lineTo(150, H);
  ctx.closePath();
  ctx.fill();
  ctx.restore();

  scene.textures.addCanvas('field', canvas);
}

/* ── helpers ─────────────────────────────────────────────────────────────── */

/** Paint every WALLS body as a neon rail. Outer cabinet walls get the bold
 *  green rail treatment; inner guides are slimmer steel rails; the launch
 *  lane wall keeps its magenta accent. */
function paintWalls(ctx: CanvasRenderingContext2D): void {
  for (const w of WALLS) {
    const style = wallStyle(w);
    ctx.save();
    ctx.translate(w.x, w.y);
    ctx.rotate(w.angle ?? 0);
    const r = Math.min(w.chamfer ?? 2, w.width / 2, w.height / 2);
    // Rail body.
    ctx.fillStyle = style.body;
    roundRectPath(ctx, -w.width / 2, -w.height / 2, w.width, w.height, r);
    ctx.fill();
    // Neon edge.
    ctx.strokeStyle = style.edge;
    ctx.lineWidth = style.line;
    ctx.shadowColor = style.edge;
    ctx.shadowBlur = style.blur;
    roundRectPath(ctx, -w.width / 2, -w.height / 2, w.width, w.height, r);
    ctx.stroke();
    // Inner highlight.
    ctx.shadowBlur = 0;
    ctx.strokeStyle = 'rgba(244,248,255,0.14)';
    ctx.lineWidth = 1;
    roundRectPath(
      ctx,
      -w.width / 2 + 2,
      -w.height / 2 + 2,
      w.width - 4,
      w.height - 4,
      Math.max(1, r - 2)
    );
    ctx.stroke();
    ctx.restore();
  }
}

function wallStyle(w: RectDef): { body: string; edge: string; line: number; blur: number } {
  if (w.label === 'wall-lane') {
    return { body: '#1a1030', edge: 'rgba(255,77,157,0.85)', line: 2, blur: 7 };
  }
  if (w.label === 'plunger-floor') {
    return { body: '#101a2e', edge: 'rgba(143,163,200,0.5)', line: 1.5, blur: 3 };
  }
  // Tall outer walls = bold cabinet rails.
  if (w.height >= 500) {
    return { body: '#101a2e', edge: css(PALETTE.lineGreen), line: 2.5, blur: 10 };
  }
  // Inner guides + feeds + funnel.
  return { body: '#16233c', edge: 'rgba(53,240,139,0.85)', line: 1.6, blur: 6 };
}

function roundRectPath(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  w: number,
  h: number,
  r: number
): void {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

function mulberry32(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}


/**
 * Permanent "STADIUM SLOTS" mini reel topper, painted into the field art
 * in the unused pocket between the GOAL rollover lanes and the SPIN saucer
 * orbit. Shows a boot-trophy-ball tease on the payline so the slot half of
 * the game is always on the table.
 */
function paintSlotsTopper(ctx: CanvasRenderingContext2D): void {
  const px = 322; // panel left
  const py = 104; // panel top
  const pw = 136;
  const ph = 134;
  const cx = px + pw / 2; // 390

  ctx.save();
  // Panel body.
  const body = ctx.createLinearGradient(0, py, 0, py + ph);
  body.addColorStop(0, '#101a2e');
  body.addColorStop(1, '#070b14');
  ctx.fillStyle = body;
  roundRectPath(ctx, px, py, pw, ph, 14);
  ctx.fill();
  ctx.strokeStyle = 'rgba(255,201,60,0.6)';
  ctx.lineWidth = 2;
  roundRectPath(ctx, px, py, pw, ph, 14);
  ctx.stroke();
  ctx.strokeStyle = 'rgba(255,77,157,0.35)';
  ctx.lineWidth = 1;
  roundRectPath(ctx, px + 5, py + 5, pw - 10, ph - 10, 10);
  ctx.stroke();
  // Corner screws.
  ctx.fillStyle = '#3c4a6b';
  for (const [sx, sy] of [
    [px + 10, py + 10],
    [px + pw - 10, py + 10],
    [px + 10, py + ph - 10],
    [px + pw - 10, py + ph - 10],
  ] as const) {
    ctx.beginPath();
    ctx.arc(sx, sy, 2.2, 0, Math.PI * 2);
    ctx.fill();
  }

  // Title.
  ctx.font = 'bold 13px "Arial Black", Arial, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.lineWidth = 3;
  ctx.strokeStyle = '#0a0f1e';
  ctx.strokeText('STADIUM SLOTS', cx, py + 22);
  ctx.fillStyle = '#ffd76a';
  ctx.fillText('STADIUM SLOTS', cx, py + 22);

  // Reel windows (36 x 64).
  const winY = py + 36; // 140
  const winH = 64;
  const winW = 36;
  const centers = [px + 24 + winW / 2, cx, px + pw - 24 - winW / 2];
  centers.forEach((wx, i) => {
    const left = wx - winW / 2;
    ctx.fillStyle = '#050a14';
    ctx.fillRect(left, winY, winW, winH);
    // Neighbouring symbol strips (top/bottom fades).
    ctx.fillStyle = 'rgba(244,248,255,0.06)';
    ctx.fillRect(left, winY, winW, 12);
    ctx.fillRect(left, winY + winH - 12, winW, 12);
    ctx.strokeStyle = 'rgba(53,70,110,0.9)';
    ctx.lineWidth = 1.5;
    ctx.strokeRect(left, winY, winW, winH);
    // Symbol at the payline.
    drawTopperSymbol(ctx, i, wx, winY + winH / 2);
  });

  // Payline.
  ctx.save();
  ctx.strokeStyle = 'rgba(255,215,106,0.8)';
  ctx.lineWidth = 2;
  ctx.shadowColor = 'rgba(255,215,106,0.9)';
  ctx.shadowBlur = 6;
  ctx.beginPath();
  ctx.moveTo(px + 8, winY + winH / 2);
  ctx.lineTo(px + pw - 8, winY + winH / 2);
  ctx.stroke();
  ctx.restore();

  // Hint.
  ctx.font = 'bold 10px Arial, sans-serif';
  ctx.fillStyle = 'rgba(143,163,200,0.95)';
  ctx.fillText('SHOOT THE SPIN SAUCER', cx, py + ph - 16);
  ctx.restore();
}

/** One topper reel symbol: 0 = boot, 1 = trophy, 2 = ball. */
function drawTopperSymbol(
  ctx: CanvasRenderingContext2D,
  id: number,
  cx: number,
  cy: number
): void {
  ctx.save();
  if (id === 0) {
    // Boot.
    ctx.fillStyle = '#ffc93c';
    ctx.strokeStyle = '#7a5510';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(cx - 7, cy - 12);
    ctx.quadraticCurveTo(cx + 1, cy - 11, cx, cy - 2);
    ctx.lineTo(cx, cy + 4);
    ctx.quadraticCurveTo(cx + 8, cy + 6, cx + 10, cy + 12);
    ctx.quadraticCurveTo(cx + 10.5, cy + 14, cx + 8, cy + 14);
    ctx.lineTo(cx - 8, cy + 14);
    ctx.quadraticCurveTo(cx - 10, cy + 14, cx - 10.5, cy + 11);
    ctx.lineTo(cx - 7, cy - 12);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    // Laces.
    ctx.strokeStyle = '#7a5510';
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    ctx.moveTo(cx - 4, cy - 8);
    ctx.lineTo(cx + 3, cy - 6);
    ctx.stroke();
  } else if (id === 1) {
    // Trophy.
    ctx.fillStyle = '#ffd76a';
    ctx.strokeStyle = '#7a5510';
    ctx.lineWidth = 1.5;
    // Cup bowl.
    ctx.beginPath();
    ctx.moveTo(cx - 9, cy - 12);
    ctx.lineTo(cx + 9, cy - 12);
    ctx.quadraticCurveTo(cx + 8, cy - 1, cx, cy + 1);
    ctx.quadraticCurveTo(cx - 8, cy - 1, cx - 9, cy - 12);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    // Handles.
    ctx.beginPath();
    ctx.arc(cx - 12.5, cy - 7, 4.2, Math.PI * 0.5, Math.PI * 1.5);
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(cx + 12.5, cy - 7, 4.2, -Math.PI * 0.5, Math.PI * 0.5);
    ctx.stroke();
    // Stem + base.
    ctx.beginPath();
    ctx.moveTo(cx - 2, cy + 1);
    ctx.lineTo(cx - 3.5, cy + 9);
    ctx.lineTo(cx + 3.5, cy + 9);
    ctx.lineTo(cx + 2, cy + 1);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.beginPath();
    roundRectPath(ctx, cx - 8, cy + 9, 16, 4, 2);
    ctx.fill();
    ctx.stroke();
    // Star on the cup.
    ctx.fillStyle = '#7a5510';
    ctx.beginPath();
    ctx.arc(cx, cy - 7, 1.8, 0, Math.PI * 2);
    ctx.fill();
  } else {
    // Ball.
    const g = ctx.createRadialGradient(cx - 4, cy - 5, 2, cx, cy, 12);
    g.addColorStop(0, '#ffffff');
    g.addColorStop(0.8, '#dbe4f5');
    g.addColorStop(1, '#9fb0cc');
    ctx.fillStyle = g;
    ctx.strokeStyle = '#1b2b4d';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(cx, cy, 12, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = '#101828';
    ctx.beginPath();
    for (let i = 0; i < 5; i += 1) {
      const a = -Math.PI / 2 + (i * Math.PI * 2) / 5;
      const tx = cx + Math.cos(a) * 4.6;
      const ty = cy + Math.sin(a) * 4.6;
      if (i === 0) ctx.moveTo(tx, ty);
      else ctx.lineTo(tx, ty);
    }
    ctx.closePath();
    ctx.fill();
  }
  ctx.restore();
}
