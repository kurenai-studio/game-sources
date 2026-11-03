// Canvas textures for murals, rune glyphs, and waterfall ribbons.
import * as THREE from 'three';
import { canvasTexture } from './toon.js';

export function drawSymbol(ctx, symbol, cx, cy, r, color) {
  ctx.save();
  ctx.translate(cx, cy);
  ctx.strokeStyle = color;
  ctx.fillStyle = color;
  ctx.lineWidth = Math.max(3, r * 0.14);
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  switch (symbol) {
    case 'moon': {
      ctx.beginPath();
      ctx.arc(0, 0, r, Math.PI * 0.35, Math.PI * 1.65);
      ctx.arc(r * 0.42, 0, r * 0.72, Math.PI * 1.55, Math.PI * 0.45, true);
      ctx.closePath();
      ctx.fill();
      break;
    }
    case 'star': {
      ctx.beginPath();
      for (let i = 0; i < 10; i++) {
        const a = -Math.PI / 2 + (i * Math.PI) / 5;
        const rr = i % 2 === 0 ? r : r * 0.45;
        ctx[i === 0 ? 'moveTo' : 'lineTo'](Math.cos(a) * rr, Math.sin(a) * rr);
      }
      ctx.closePath();
      ctx.fill();
      break;
    }
    case 'sun': {
      ctx.beginPath();
      ctx.arc(0, 0, r * 0.5, 0, Math.PI * 2);
      ctx.fill();
      for (let i = 0; i < 8; i++) {
        const a = (i * Math.PI) / 4;
        ctx.beginPath();
        ctx.moveTo(Math.cos(a) * r * 0.68, Math.sin(a) * r * 0.68);
        ctx.lineTo(Math.cos(a) * r, Math.sin(a) * r);
        ctx.stroke();
      }
      break;
    }
    case 'wave': {
      ctx.beginPath();
      ctx.moveTo(-r, r * 0.1);
      ctx.bezierCurveTo(-r * 0.5, -r * 0.8, -r * 0.1, r * 0.7, r * 0.25, -r * 0.05);
      ctx.bezierCurveTo(r * 0.5, -r * 0.55, r * 0.75, -r * 0.3, r, -r * 0.45);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(-r * 0.85, r * 0.55);
      ctx.bezierCurveTo(-r * 0.4, r * 0.1, r * 0.05, r * 0.8, r * 0.6, r * 0.35);
      ctx.stroke();
      break;
    }
    case 'leaf': {
      ctx.beginPath();
      ctx.moveTo(0, -r);
      ctx.bezierCurveTo(r * 0.9, -r * 0.3, r * 0.6, r * 0.6, 0, r);
      ctx.bezierCurveTo(-r * 0.6, r * 0.6, -r * 0.9, -r * 0.3, 0, -r);
      ctx.fill();
      ctx.strokeStyle = 'rgba(90,74,122,0.55)';
      ctx.lineWidth = Math.max(2, r * 0.08);
      ctx.beginPath();
      ctx.moveTo(0, -r * 0.7);
      ctx.lineTo(0, r * 0.85);
      ctx.stroke();
      break;
    }
  }
  ctx.restore();
}

// Mural panel: parchment-like panel with a painted symbol in the chime color.
export function muralTexture(symbol, color) {
  return canvasTexture(256, (ctx, s) => {
    ctx.fillStyle = '#f7ead2';
    ctx.fillRect(0, 0, s, s);
    // weathered edges
    ctx.strokeStyle = 'rgba(90,74,122,0.35)';
    ctx.lineWidth = 10;
    ctx.strokeRect(8, 8, s - 16, s - 16);
    // faint wash
    const g = ctx.createRadialGradient(s / 2, s / 2, 10, s / 2, s / 2, s * 0.7);
    g.addColorStop(0, 'rgba(255,255,255,0.35)');
    g.addColorStop(1, 'rgba(205,180,240,0.18)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, s, s);
    drawSymbol(ctx, symbol, s / 2, s / 2, s * 0.26, color);
  });
}

// Floating rune stone face: soft dark stone with a glowing glyph.
export function runeTexture(symbol, color) {
  return canvasTexture(256, (ctx, s) => {
    ctx.fillStyle = '#7a6a9a';
    ctx.fillRect(0, 0, s, s);
    const g = ctx.createRadialGradient(s / 2, s / 2, 8, s / 2, s / 2, s * 0.65);
    g.addColorStop(0, 'rgba(255,255,255,0.14)');
    g.addColorStop(1, 'rgba(40,30,70,0.4)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, s, s);
    ctx.shadowColor = color;
    ctx.shadowBlur = 26;
    drawSymbol(ctx, symbol, s / 2, s / 2, s * 0.24, color);
    ctx.shadowBlur = 0;
  });
}

// Scrolling waterfall ribbon: soft wide noise bands + foam speckles,
// fading in at the top and dissolving toward the bottom.
export function waterfallTexture() {
  const tex = canvasTexture(256, (ctx, s) => {
    ctx.clearRect(0, 0, s, s);
    // soft wide vertical bands (deterministic pseudo-random widths)
    let x = 0;
    let k = 0;
    while (x < s) {
      const w = 12 + ((k * 37) % 24);
      const a = 0.3 + ((k * 53) % 45) / 100;
      const g = ctx.createLinearGradient(x, 0, x + w, 0);
      g.addColorStop(0, 'rgba(228,246,255,0)');
      g.addColorStop(0.5, `rgba(228,246,255,${a})`);
      g.addColorStop(1, 'rgba(228,246,255,0)');
      ctx.fillStyle = g;
      ctx.fillRect(x, 0, w, s);
      x += w + 3;
      k += 1;
    }
    // foam speckles drifting in the fall
    for (let i = 0; i < 300; i++) {
      const px = (i * 97) % s;
      const py = (i * 61 + ((i * 13) % 40)) % s;
      const r = 1 + (i % 3);
      ctx.fillStyle = `rgba(255,255,255,${0.1 + (i % 5) * 0.05})`;
      ctx.beginPath();
      ctx.arc(px, py, r, 0, Math.PI * 2);
      ctx.fill();
    }
    // fade in at the top, dissolve toward the bottom
    const v = ctx.createLinearGradient(0, 0, 0, s);
    v.addColorStop(0, 'rgba(0,0,0,0)');
    v.addColorStop(0.12, 'rgba(0,0,0,1)');
    v.addColorStop(0.65, 'rgba(0,0,0,1)');
    v.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.globalCompositeOperation = 'destination-in';
    ctx.fillStyle = v;
    ctx.fillRect(0, 0, s, s);
  });
  tex.wrapS = THREE.RepeatWrapping;
  tex.wrapT = THREE.RepeatWrapping;
  return tex;
}
