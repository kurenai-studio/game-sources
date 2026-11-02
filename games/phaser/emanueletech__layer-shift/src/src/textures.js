// Procedural textures drawn once on canvases: no image files in the game.
import { CW, CH, W, H, C, hex } from './theme.js';

function canvasTex(scene, key, w, h, draw) {
  if (scene.textures.exists(key)) return;
  const t = scene.textures.createCanvas(key, w, h);
  draw(t.getContext(), w, h);
  t.refresh();
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

// A printed filament cell: glossy extrusion with visible layer lines.
function cell(ctx, w, h, top, bottom, shine = 0.55) {
  const g = ctx.createLinearGradient(0, 0, 0, h);
  g.addColorStop(0, top);
  g.addColorStop(1, bottom);
  roundRect(ctx, 0.5, 0.5, w - 1, h - 1, 3);
  ctx.fillStyle = g;
  ctx.fill();
  ctx.fillStyle = `rgba(255,255,255,${shine})`;
  ctx.fillRect(3, 2, w - 6, 1.5);
  ctx.fillStyle = 'rgba(0,0,0,0.18)';
  ctx.fillRect(1, h / 2, w - 2, 1);
  ctx.fillStyle = 'rgba(0,0,0,0.28)';
  ctx.fillRect(2, h - 2, w - 4, 1);
}

export function makeTextures(scene) {
  canvasTex(scene, 'cell', CW, CH, (ctx, w, h) => cell(ctx, w, h, '#5cff95', '#13a84a'));
  canvasTex(scene, 'cellBad', CW, CH, (ctx, w, h) => cell(ctx, w, h, '#ff8a95', '#c42a3a', 0.4));
  canvasTex(scene, 'cellBp', 14, 9, (ctx, w, h) => { roundRect(ctx, 0.5, 0.5, w - 1, h - 1, 2); ctx.fillStyle = '#cfe3ff'; ctx.fill(); });
  canvasTex(scene, 'cellBpDone', 14, 9, (ctx, w, h) => cell(ctx, w, h, '#5cff95', '#13a84a', 0.4));
  canvasTex(scene, 'cellBpMiss', 14, 9, (ctx, w, h) => cell(ctx, w, h, '#ff8a95', '#c42a3a', 0.3));

  // Ghost layer (the one you are aligning): translucent with a bright rim.
  canvasTex(scene, 'ghost', CW, CH, (ctx, w, h) => {
    roundRect(ctx, 1, 1, w - 2, h - 2, 3);
    ctx.fillStyle = 'rgba(92,255,149,0.28)';
    ctx.fill();
    ctx.lineWidth = 1.5;
    ctx.strokeStyle = 'rgba(160,255,200,0.95)';
    ctx.stroke();
  });
  // Guide marker on the bed for the target row (calibration level only).
  canvasTex(scene, 'guide', CW, CH, (ctx, w, h) => {
    ctx.setLineDash([3, 3]);
    ctx.lineWidth = 1;
    ctx.strokeStyle = 'rgba(207,227,255,0.55)';
    roundRect(ctx, 1.5, 1.5, w - 3, h - 3, 3);
    ctx.stroke();
  });

  // Background: deep night gradient with a soft vignette.
  canvasTex(scene, 'bg', W, H, (ctx, w, h) => {
    const g = ctx.createLinearGradient(0, 0, 0, h);
    g.addColorStop(0, '#0e1626');
    g.addColorStop(1, '#05070b');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = 'rgba(80,110,160,0.07)';
    ctx.lineWidth = 1;
    for (let x = 0; x <= w; x += 24) { ctx.beginPath(); ctx.moveTo(x + 0.5, 0); ctx.lineTo(x + 0.5, h); ctx.stroke(); }
    for (let y = 0; y <= h; y += 24) { ctx.beginPath(); ctx.moveTo(0, y + 0.5); ctx.lineTo(w, y + 0.5); ctx.stroke(); }
    const v = ctx.createRadialGradient(w * 0.45, h * 0.45, h * 0.2, w * 0.5, h * 0.5, w * 0.75);
    v.addColorStop(0, 'rgba(0,0,0,0)');
    v.addColorStop(1, 'rgba(0,0,0,0.75)');
    ctx.fillStyle = v;
    ctx.fillRect(0, 0, w, h);
  });

  // Textured PEI build plate: warm gold with speckles.
  canvasTex(scene, 'pei', 360, 12, (ctx, w, h) => {
    const g = ctx.createLinearGradient(0, 0, 0, h);
    g.addColorStop(0, '#d9a441');
    g.addColorStop(1, '#8a5b17');
    roundRect(ctx, 0, 0, w, h, 3);
    ctx.fillStyle = g;
    ctx.fill();
    for (let i = 0; i < 500; i++) {
      ctx.fillStyle = Math.random() < 0.5 ? 'rgba(255,240,200,0.35)' : 'rgba(60,30,0,0.35)';
      ctx.fillRect(Math.random() * w, Math.random() * h, 1, 1);
    }
    ctx.fillStyle = 'rgba(255,255,255,0.35)';
    ctx.fillRect(4, 1, w - 8, 1);
  });

  // Soft round glow and tiny spark for particles / lights.
  canvasTex(scene, 'glow', 64, 64, (ctx, w, h) => {
    const g = ctx.createRadialGradient(32, 32, 0, 32, 32, 32);
    g.addColorStop(0, 'rgba(255,255,255,1)');
    g.addColorStop(0.35, 'rgba(255,255,255,0.35)');
    g.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, w, h);
  });
  canvasTex(scene, 'spark', 6, 6, (ctx) => {
    ctx.fillStyle = '#fff';
    ctx.beginPath(); ctx.arc(3, 3, 3, 0, Math.PI * 2); ctx.fill();
  });

  // Print head: shroud with a cooling fan, heat block and brass nozzle. Tip is at the bottom centre.
  canvasTex(scene, 'head', 72, 70, (ctx) => {
    const g = ctx.createLinearGradient(0, 0, 0, 46);
    g.addColorStop(0, '#5d6b82');
    g.addColorStop(1, '#2b3445');
    roundRect(ctx, 2, 2, 68, 44, 8);
    ctx.fillStyle = g;
    ctx.fill();
    ctx.strokeStyle = 'rgba(255,255,255,0.18)';
    ctx.lineWidth = 1;
    ctx.stroke();
    ctx.fillStyle = 'rgba(255,255,255,0.25)';
    ctx.fillRect(10, 6, 52, 2);
    // fan grille
    ctx.fillStyle = '#151b26';
    ctx.beginPath(); ctx.arc(36, 25, 14, 0, Math.PI * 2); ctx.fill();
    // heat block
    const hb = ctx.createLinearGradient(0, 46, 0, 58);
    hb.addColorStop(0, '#c9ced8'); hb.addColorStop(1, '#7c8494');
    ctx.fillStyle = hb;
    ctx.fillRect(26, 46, 20, 10);
    // brass nozzle
    ctx.fillStyle = '#e0a93a';
    ctx.beginPath(); ctx.moveTo(29, 56); ctx.lineTo(43, 56); ctx.lineTo(37.5, 70); ctx.lineTo(34.5, 70); ctx.closePath(); ctx.fill();
  });
  canvasTex(scene, 'fan', 26, 26, (ctx) => {
    ctx.translate(13, 13);
    ctx.fillStyle = '#6f7d95';
    for (let i = 0; i < 5; i++) {
      ctx.rotate((Math.PI * 2) / 5);
      ctx.beginPath(); ctx.ellipse(0, -6, 3, 6, 0.5, 0, Math.PI * 2); ctx.fill();
    }
    ctx.fillStyle = '#9aa6ba';
    ctx.beginPath(); ctx.arc(0, 0, 3, 0, Math.PI * 2); ctx.fill();
  });
}

export { roundRect, hex };
