/**
 * GOAL RUSH — runtime texture atlas factory.
 *
 * Every sprite in the game is drawn procedurally with the Canvas 2D API at
 * boot and packed into ONE atlas texture ("atlas"), demonstrating classic
 * spritesheet memory management: a single GPU texture source, many named
 * frames. No binary art assets, no licensing, tiny payload.
 */

import type Phaser from 'phaser';

interface FrameDef {
  name: string;
  width: number;
  height: number;
  draw: (ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number) => void;
}

const ATLAS_WIDTH = 512;

/* ── drawing helpers ─────────────────────────────────────────────────────── */

function roundRect(
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

/** Neon stroke: draws the path with a colored glow. */
function neonStroke(
  ctx: CanvasRenderingContext2D,
  color: string,
  blur: number,
  width: number
): void {
  ctx.save();
  ctx.shadowColor = color;
  ctx.shadowBlur = blur;
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.stroke();
  ctx.stroke();
  ctx.restore();
}

/** Soccer ball pattern: pentagon in the middle + edge patches. */
function soccerBall(
  ctx: CanvasRenderingContext2D,
  cx: number,
  cy: number,
  r: number,
  lineColor: string
): void {
  ctx.save();
  // Shaded sphere.
  const grad = ctx.createRadialGradient(cx - r * 0.35, cy - r * 0.4, r * 0.15, cx, cy, r);
  grad.addColorStop(0, '#ffffff');
  grad.addColorStop(0.75, '#dbe4f5');
  grad.addColorStop(1, '#9fb0cc');
  ctx.fillStyle = grad;
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.fill();
  // Center pentagon.
  ctx.fillStyle = '#101828';
  ctx.beginPath();
  for (let i = 0; i < 5; i += 1) {
    const a = -Math.PI / 2 + (i * Math.PI * 2) / 5;
    const px = cx + Math.cos(a) * r * 0.42;
    const py = cy + Math.sin(a) * r * 0.42;
    if (i === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  }
  ctx.closePath();
  ctx.fill();
  // Spokes from pentagon to edge patches.
  ctx.strokeStyle = '#101828';
  ctx.lineWidth = Math.max(1, r * 0.09);
  for (let i = 0; i < 5; i += 1) {
    const a = -Math.PI / 2 + (i * Math.PI * 2) / 5;
    ctx.beginPath();
    ctx.moveTo(cx + Math.cos(a) * r * 0.42, cy + Math.sin(a) * r * 0.42);
    ctx.lineTo(cx + Math.cos(a) * r * 0.95, cy + Math.sin(a) * r * 0.95);
    ctx.stroke();
  }
  ctx.strokeStyle = lineColor;
  ctx.lineWidth = Math.max(1, r * 0.08);
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.stroke();
  ctx.restore();
}

/* ── frame definitions ───────────────────────────────────────────────────── */

const FRAMES: FrameDef[] = [
  {
    name: 'ball',
    width: 30,
    height: 30,
    draw: (ctx, x, y) => soccerBall(ctx, x + 15, y + 15, 13, '#1b2b4d'),
  },
  {
    name: 'ball-glow',
    width: 48,
    height: 48,
    draw: (ctx, x, y) => {
      const g = ctx.createRadialGradient(x + 24, y + 24, 2, x + 24, y + 24, 24);
      g.addColorStop(0, 'rgba(255,255,255,0.9)');
      g.addColorStop(0.4, 'rgba(120,255,180,0.35)');
      g.addColorStop(1, 'rgba(120,255,180,0)');
      ctx.fillStyle = g;
      ctx.fillRect(x, y, 48, 48);
    },
  },
  {
    name: 'spark',
    width: 16,
    height: 16,
    draw: (ctx, x, y) => {
      const g = ctx.createRadialGradient(x + 8, y + 8, 0, x + 8, y + 8, 8);
      g.addColorStop(0, 'rgba(255,255,255,1)');
      g.addColorStop(0.5, 'rgba(255,220,120,0.7)');
      g.addColorStop(1, 'rgba(255,220,120,0)');
      ctx.fillStyle = g;
      ctx.fillRect(x, y, 16, 16);
    },
  },
  {
    name: 'confetti',
    width: 10,
    height: 10,
    draw: (ctx, x, y) => {
      ctx.fillStyle = '#ffc93c';
      ctx.fillRect(x + 1, y + 1, 8, 8);
      ctx.fillStyle = '#ff4d9d';
      ctx.fillRect(x + 1, y + 1, 4, 8);
    },
  },
  {
    // 112×36: the 92×16 bat is inset by 8 px on every side so the baked neon
    // glow has room to breathe (the old 96×20 frame clipped it). The pivot
    // cap stays at the same offset from the frame centre, so the physics
    // anchoring in Flipper.ts is unchanged.
    name: 'flipper',
    width: 112,
    height: 36,
    draw: (ctx, x, y) => {
      ctx.save();
      ctx.translate(x, y);
      // Baked light pool behind the whole bat.
      const halo = ctx.createRadialGradient(56, 18, 4, 56, 18, 54);
      halo.addColorStop(0, 'rgba(140,255,190,0.30)');
      halo.addColorStop(0.55, 'rgba(140,255,190,0.10)');
      halo.addColorStop(1, 'rgba(140,255,190,0)');
      ctx.fillStyle = halo;
      ctx.fillRect(0, 0, 112, 36);
      // Body: bright cream rubber — the classic pinball flipper look and
      // maximum contrast against the darkened bottom of the pitch.
      const g = ctx.createLinearGradient(0, 10, 0, 26);
      g.addColorStop(0, '#ffffff');
      g.addColorStop(0.5, '#fff6c8');
      g.addColorStop(1, '#ffd76a');
      ctx.fillStyle = g;
      roundRect(ctx, 10, 10, 92, 16, 8);
      ctx.fill();
      // Dark outline for a crisp silhouette.
      ctx.strokeStyle = '#2a1240';
      ctx.lineWidth = 2;
      roundRect(ctx, 10, 10, 92, 16, 8);
      ctx.stroke();
      // Magenta batting face (top edge) — the kicking surface, impossible
      // to miss.
      ctx.beginPath();
      ctx.moveTo(19, 12);
      ctx.lineTo(99, 12);
      neonStroke(ctx, '#ff4d9d', 8, 3.2);
      // Green trailing edge (bottom).
      ctx.globalAlpha = 0.85;
      ctx.beginPath();
      ctx.moveTo(22, 24);
      ctx.lineTo(97, 24);
      neonStroke(ctx, '#35f08b', 6, 2.2);
      ctx.globalAlpha = 1;
      // Tiny soccer-pentagon mark mid-bat (theme echo).
      ctx.fillStyle = 'rgba(16,24,40,0.5)';
      ctx.beginPath();
      for (let i = 0; i < 5; i += 1) {
        const a = -Math.PI / 2 + (i * Math.PI * 2) / 5;
        const px = 58 + Math.cos(a) * 4.2;
        const py = 18 + Math.sin(a) * 4.2;
        if (i === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
      }
      ctx.closePath();
      ctx.fill();
      // Pivot cap: gold hub with a highlight.
      ctx.beginPath();
      ctx.arc(18, 18, 6.5, 0, Math.PI * 2);
      ctx.fillStyle = '#ffc93c';
      ctx.fill();
      ctx.lineWidth = 2;
      ctx.strokeStyle = '#0a0f1e';
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(16, 16, 1.8, 0, Math.PI * 2);
      ctx.fillStyle = '#fff8e0';
      ctx.fill();
      ctx.restore();
    },
  },
  {
    // Wide soft bar of light laid UNDER each flipper (ADD-blended at
    // runtime, alpha-animated: gentle breathing at rest, flare on press).
    name: 'flipper-glow',
    width: 120,
    height: 56,
    draw: (ctx, x, y) => {
      ctx.save();
      ctx.translate(x + 60, y + 28);
      ctx.scale(1, 0.5);
      const g = ctx.createRadialGradient(0, 0, 2, 0, 0, 58);
      g.addColorStop(0, 'rgba(255,255,255,0.55)');
      g.addColorStop(0.35, 'rgba(140,255,190,0.32)');
      g.addColorStop(1, 'rgba(140,255,190,0)');
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(0, 0, 58, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    },
  },
  {
    name: 'bumper',
    width: 64,
    height: 64,
    draw: (ctx, x, y) => {
      // Mostly white so per-instance tint reads correctly.
      ctx.save();
      ctx.translate(x, y);
      // Glow halo.
      const halo = ctx.createRadialGradient(32, 32, 18, 32, 32, 32);
      halo.addColorStop(0, 'rgba(255,255,255,0.35)');
      halo.addColorStop(1, 'rgba(255,255,255,0)');
      ctx.fillStyle = halo;
      ctx.fillRect(0, 0, 64, 64);
      // Skirt.
      ctx.fillStyle = '#1a2338';
      ctx.beginPath();
      ctx.arc(32, 32, 27, 0, Math.PI * 2);
      ctx.fill();
      // Cap (white for tinting).
      const g = ctx.createRadialGradient(24, 24, 4, 32, 32, 24);
      g.addColorStop(0, '#ffffff');
      g.addColorStop(1, '#c6d2ea');
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(32, 32, 22, 0, Math.PI * 2);
      ctx.fill();
      // Pentagon mark.
      ctx.fillStyle = '#0d1526';
      ctx.beginPath();
      for (let i = 0; i < 5; i += 1) {
        const a = -Math.PI / 2 + (i * Math.PI * 2) / 5;
        const px = 32 + Math.cos(a) * 10;
        const py = 32 + Math.sin(a) * 10;
        if (i === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
      }
      ctx.closePath();
      ctx.fill();
      ctx.restore();
    },
  },
  {
    name: 'bumper-flash',
    width: 64,
    height: 64,
    draw: (ctx, x, y) => {
      const g = ctx.createRadialGradient(x + 32, y + 32, 4, x + 32, y + 32, 32);
      g.addColorStop(0, 'rgba(255,255,255,0.95)');
      g.addColorStop(0.6, 'rgba(255,240,180,0.4)');
      g.addColorStop(1, 'rgba(255,240,180,0)');
      ctx.fillStyle = g;
      ctx.fillRect(x, y, 64, 64);
    },
  },
  {
    name: 'post',
    width: 20,
    height: 20,
    draw: (ctx, x, y) => {
      const g = ctx.createRadialGradient(x + 7, y + 7, 1, x + 10, y + 10, 10);
      g.addColorStop(0, '#f4f8ff');
      g.addColorStop(1, '#7f8fb0');
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(x + 10, y + 10, 8, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = '#0a0f1e';
      ctx.lineWidth = 2;
      ctx.stroke();
    },
  },
  {
    name: 'drop-target',
    width: 52,
    height: 18,
    draw: (ctx, x, y) => {
      ctx.save();
      ctx.translate(x, y);
      const g = ctx.createLinearGradient(0, 0, 0, 18);
      g.addColorStop(0, '#ffe9a8');
      g.addColorStop(1, '#c8922a');
      ctx.fillStyle = g;
      roundRect(ctx, 1, 2, 50, 14, 5);
      ctx.fill();
      ctx.beginPath();
      ctx.moveTo(26, 4);
      ctx.lineTo(28.5, 9);
      ctx.lineTo(33.5, 9);
      ctx.lineTo(29.5, 12.5);
      ctx.lineTo(31, 17);
      ctx.lineTo(26, 14);
      ctx.lineTo(21, 17);
      ctx.lineTo(22.5, 12.5);
      ctx.lineTo(18.5, 9);
      ctx.lineTo(23.5, 9);
      ctx.closePath();
      ctx.fillStyle = '#7a5510';
      ctx.fill();
      ctx.restore();
    },
  },
  {
    name: 'spinner-blade',
    width: 12,
    height: 48,
    draw: (ctx, x, y) => {
      ctx.save();
      ctx.translate(x, y);
      const g = ctx.createLinearGradient(0, 0, 12, 0);
      g.addColorStop(0, '#ff4d9d');
      g.addColorStop(0.5, '#ffd1e6');
      g.addColorStop(1, '#ff4d9d');
      ctx.fillStyle = g;
      roundRect(ctx, 2, 2, 8, 44, 4);
      ctx.fill();
      ctx.restore();
    },
  },
  {
    name: 'gate',
    width: 36,
    height: 8,
    draw: (ctx, x, y) => {
      ctx.save();
      ctx.translate(x, y);
      const g = ctx.createLinearGradient(0, 0, 36, 0);
      g.addColorStop(0, '#8fa3c8');
      g.addColorStop(1, '#d5e0f5');
      ctx.fillStyle = g;
      roundRect(ctx, 2, 2, 32, 4, 2);
      ctx.fill();
      ctx.restore();
    },
  },
  {
    name: 'saucer-ring',
    width: 64,
    height: 64,
    draw: (ctx, x, y) => {
      ctx.save();
      ctx.translate(x, y);
      ctx.beginPath();
      ctx.arc(32, 32, 26, 0, Math.PI * 2);
      neonStroke(ctx, '#ffc93c', 10, 3);
      // Inner dark hole.
      ctx.fillStyle = '#060a13';
      ctx.beginPath();
      ctx.arc(32, 32, 22, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    },
  },
  {
    name: 'plunger-cap',
    width: 34,
    height: 14,
    draw: (ctx, x, y) => {
      ctx.save();
      ctx.translate(x, y);
      const g = ctx.createLinearGradient(0, 0, 0, 14);
      g.addColorStop(0, '#ff4d9d');
      g.addColorStop(1, '#8f1e4f');
      ctx.fillStyle = g;
      roundRect(ctx, 1, 1, 32, 12, 6);
      ctx.fill();
      ctx.restore();
    },
  },
  {
    name: 'ball-mini',
    width: 18,
    height: 18,
    draw: (ctx, x, y) => soccerBall(ctx, x + 9, y + 9, 8, '#1b2b4d'),
  },
  {
    name: 'chip',
    width: 20,
    height: 20,
    draw: (ctx, x, y) => {
      ctx.save();
      ctx.translate(x, y);
      const g = ctx.createRadialGradient(7, 7, 1, 10, 10, 10);
      g.addColorStop(0, '#ffe9a8');
      g.addColorStop(1, '#c8922a');
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(10, 10, 9, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = '#7a5510';
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.arc(10, 10, 6, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
    },
  },
];

/* ── reel symbol frames (64×64, dark platter + neon icon) ────────────────── */

function symbolPlatter(ctx: CanvasRenderingContext2D, x: number, y: number, rim: string): void {
  ctx.save();
  ctx.translate(x, y);
  const g = ctx.createRadialGradient(26, 24, 4, 32, 32, 34);
  g.addColorStop(0, '#182238');
  g.addColorStop(1, '#0b111f');
  ctx.fillStyle = g;
  ctx.beginPath();
  ctx.arc(32, 32, 29, 0, Math.PI * 2);
  ctx.fill();
  ctx.beginPath();
  ctx.arc(32, 32, 29, 0, Math.PI * 2);
  neonStroke(ctx, rim, 7, 2);
  ctx.restore();
}

const SYMBOL_FRAMES: FrameDef[] = [
  {
    name: 'sym-ball',
    width: 64,
    height: 64,
    draw: (ctx, x, y) => {
      symbolPlatter(ctx, x, y, '#f4f8ff');
      soccerBall(ctx, x + 32, y + 32, 18, '#35f08b');
    },
  },
  {
    name: 'sym-boot',
    width: 64,
    height: 64,
    draw: (ctx, x, y) => {
      symbolPlatter(ctx, x, y, '#ffc93c');
      ctx.save();
      ctx.translate(x, y);
      ctx.translate(32, 32);
      ctx.rotate(-0.5);
      // Stylized golden boot.
      const g = ctx.createLinearGradient(-16, -14, 10, 18);
      g.addColorStop(0, '#ffe9a8');
      g.addColorStop(1, '#d09a2e');
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.moveTo(-14, -14);
      ctx.quadraticCurveTo(-4, -16, 0, -8);
      ctx.lineTo(2, 8);
      ctx.quadraticCurveTo(12, 10, 18, 14);
      ctx.quadraticCurveTo(19, 20, 12, 20);
      ctx.lineTo(-12, 20);
      ctx.quadraticCurveTo(-17, 20, -16, 14);
      ctx.closePath();
      ctx.fill();
      ctx.strokeStyle = '#7a5510';
      ctx.lineWidth = 1.5;
      ctx.stroke();
      // Studs.
      ctx.fillStyle = '#7a5510';
      for (const sx of [-9, -2, 5, 12]) {
        ctx.beginPath();
        ctx.arc(sx, 18, 1.8, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.restore();
    },
  },
  {
    name: 'sym-glove',
    width: 64,
    height: 64,
    draw: (ctx, x, y) => {
      symbolPlatter(ctx, x, y, '#35f08b');
      ctx.save();
      ctx.translate(x, y);
      ctx.translate(32, 34);
      const g = ctx.createLinearGradient(0, -16, 0, 16);
      g.addColorStop(0, '#7dffb9');
      g.addColorStop(1, '#1e9e5c');
      ctx.fillStyle = g;
      // Palm.
      roundRect(ctx, -12, -4, 24, 18, 6);
      ctx.fill();
      // Fingers.
      for (let i = 0; i < 4; i += 1) {
        roundRect(ctx, -11 + i * 6, -16, 5, 14, 2.5);
        ctx.fill();
      }
      // Thumb.
      roundRect(ctx, 10, -6, 6, 12, 3);
      ctx.fill();
      ctx.strokeStyle = '#0b4d2b';
      ctx.lineWidth = 1.4;
      roundRect(ctx, -12, -4, 24, 18, 6);
      ctx.stroke();
      ctx.restore();
    },
  },
  {
    name: 'sym-jersey',
    width: 64,
    height: 64,
    draw: (ctx, x, y) => {
      symbolPlatter(ctx, x, y, '#ff4d9d');
      ctx.save();
      ctx.translate(x, y);
      ctx.translate(32, 33);
      const g = ctx.createLinearGradient(0, -16, 0, 16);
      g.addColorStop(0, '#ff8ac2');
      g.addColorStop(1, '#c22568');
      ctx.fillStyle = g;
      ctx.beginPath();
      // Body + sleeves silhouette.
      ctx.moveTo(-8, -15);
      ctx.lineTo(8, -15);
      ctx.lineTo(17, -9);
      ctx.lineTo(13, -1);
      ctx.lineTo(10, -4);
      ctx.lineTo(10, 15);
      ctx.quadraticCurveTo(0, 17, -10, 15);
      ctx.lineTo(-10, -4);
      ctx.lineTo(-13, -1);
      ctx.lineTo(-17, -9);
      ctx.closePath();
      ctx.fill();
      ctx.strokeStyle = '#5e0f34';
      ctx.lineWidth = 1.4;
      ctx.stroke();
      // Number 10.
      ctx.fillStyle = '#ffffff';
      ctx.font = 'bold 13px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('10', 0, 5);
      ctx.restore();
    },
  },
  {
    name: 'sym-card',
    width: 64,
    height: 64,
    draw: (ctx, x, y) => {
      symbolPlatter(ctx, x, y, '#ffe9a8');
      ctx.save();
      ctx.translate(x, y);
      ctx.translate(32, 32);
      ctx.rotate(-0.35);
      const g = ctx.createLinearGradient(-11, -15, 11, 15);
      g.addColorStop(0, '#ffe9a8');
      g.addColorStop(1, '#e8b83c');
      ctx.fillStyle = g;
      roundRect(ctx, -11, -15, 22, 30, 3);
      ctx.fill();
      ctx.strokeStyle = '#8a6a14';
      ctx.lineWidth = 1.4;
      ctx.stroke();
      ctx.restore();
    },
  },
  {
    name: 'sym-star',
    width: 64,
    height: 64,
    draw: (ctx, x, y) => {
      symbolPlatter(ctx, x, y, '#b46bff');
      ctx.save();
      ctx.translate(x, y);
      ctx.translate(32, 32);
      ctx.beginPath();
      for (let i = 0; i < 10; i += 1) {
        const r = i % 2 === 0 ? 19 : 8.5;
        const a = -Math.PI / 2 + (i * Math.PI) / 5;
        const px = Math.cos(a) * r;
        const py = Math.sin(a) * r;
        if (i === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
      }
      ctx.closePath();
      const g = ctx.createLinearGradient(0, -19, 0, 19);
      g.addColorStop(0, '#ddc2ff');
      g.addColorStop(1, '#8a3ee8');
      ctx.fillStyle = g;
      ctx.fill();
      ctx.restore();
    },
  },
  {
    name: 'sym-whistle',
    width: 64,
    height: 64,
    draw: (ctx, x, y) => {
      symbolPlatter(ctx, x, y, '#8fa3c8');
      ctx.save();
      ctx.translate(x, y);
      ctx.translate(32, 33);
      ctx.rotate(-0.4);
      const g = ctx.createLinearGradient(-16, -8, 16, 10);
      g.addColorStop(0, '#e7edf8');
      g.addColorStop(1, '#7f8fb0');
      ctx.fillStyle = g;
      // Barrel.
      roundRect(ctx, -18, -5, 26, 11, 5);
      ctx.fill();
      // Chamber.
      ctx.beginPath();
      ctx.arc(8, 2, 11, 0, Math.PI * 2);
      ctx.fill();
      // Mouthpiece hole.
      ctx.fillStyle = '#101828';
      roundRect(ctx, -16, -2.5, 8, 6, 3);
      ctx.fill();
      ctx.beginPath();
      ctx.arc(8, 2, 4, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    },
  },
  {
    name: 'sym-trophy',
    width: 64,
    height: 64,
    draw: (ctx, x, y) => {
      symbolPlatter(ctx, x, y, '#ffc93c');
      ctx.save();
      ctx.translate(x, y);
      ctx.translate(32, 31);
      const g = ctx.createLinearGradient(0, -16, 0, 18);
      g.addColorStop(0, '#ffe9a8');
      g.addColorStop(1, '#c8922a');
      ctx.fillStyle = g;
      // Cup.
      ctx.beginPath();
      ctx.moveTo(-11, -16);
      ctx.lineTo(11, -16);
      ctx.quadraticCurveTo(10, -2, 4, 2);
      ctx.lineTo(4, 8);
      ctx.lineTo(-4, 8);
      ctx.lineTo(-4, 2);
      ctx.quadraticCurveTo(-10, -2, -11, -16);
      ctx.closePath();
      ctx.fill();
      // Handles.
      ctx.strokeStyle = g;
      ctx.lineWidth = 2.5;
      ctx.beginPath();
      ctx.arc(-13, -11, 4.5, Math.PI * 0.4, Math.PI * 1.5);
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(13, -11, 4.5, -Math.PI * 0.5, Math.PI * 0.6);
      ctx.stroke();
      // Stem + base.
      ctx.fillStyle = g;
      roundRect(ctx, -2.5, 7, 5, 6, 1.5);
      ctx.fill();
      roundRect(ctx, -9, 13, 18, 5, 2);
      ctx.fill();
      // Star sparkle.
      ctx.fillStyle = '#fff8e0';
      ctx.beginPath();
      ctx.arc(0, -9, 2.2, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    },
  },
];

/* ── factory ─────────────────────────────────────────────────────────────── */

/**
 * Draws every frame onto a single canvas and registers it as the "atlas"
 * texture with named frames. Idempotent — skips if the atlas exists.
 */
export function buildAtlas(scene: Phaser.Scene): void {
  if (scene.textures.exists('atlas')) return;

  const all = [...FRAMES, ...SYMBOL_FRAMES];

  // Simple shelf packing.
  let cx = 0;
  let cy = 0;
  let rowHeight = 0;
  const placed = all.map((frame) => {
    if (cx + frame.width > ATLAS_WIDTH) {
      cx = 0;
      cy += rowHeight + 2;
      rowHeight = 0;
    }
    const rect = { x: cx, y: cy, w: frame.width, h: frame.height };
    cx += frame.width + 2;
    rowHeight = Math.max(rowHeight, frame.height);
    return { frame, rect };
  });
  const atlasHeight = Math.ceil(cy + rowHeight + 2);

  const canvas = document.createElement('canvas');
  canvas.width = ATLAS_WIDTH;
  canvas.height = atlasHeight;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('2D canvas unavailable — cannot build atlas');

  for (const { frame, rect } of placed) {
    frame.draw(ctx, rect.x, rect.y, rect.w, rect.h);
  }

  const texture = scene.textures.addCanvas('atlas', canvas);
  if (!texture) throw new Error('Could not register the atlas texture');
  for (const { frame, rect } of placed) {
    texture.add(frame.name, 0, rect.x, rect.y, rect.w, rect.h);
  }
}

/** Atlas frame name for a slot symbol id. */
export function symbolFrame(id: string): string {
  return `sym-${id}`;
}
