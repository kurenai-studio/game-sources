import * as THREE from 'three';
import { makeRng } from '../utils/Noise.js';

// Two small, shared cutout silhouettes. Generated once, kept on the GPU;
// thousands of trees reuse these rather than adding branch draw calls.
export function makeCanopyAtlas() {
  const canvas = document.createElement('canvas');
  canvas.width = 512; canvas.height = 512;
  const g = canvas.getContext('2d');
  const rng = makeRng(0x7392);
  g.lineCap = 'round';
  const line = (x, y, ex, ey, width, color) => {
    g.strokeStyle = color; g.lineWidth = width;
    g.beginPath(); g.moveTo(x, y); g.lineTo(ex, ey); g.stroke();
  };
  line(128, 502, 128, 10, 3, '#706247');
  for (let row = 0; row < 42; row++) {
    const t = row / 42;
    const y = 30 + t * 420;
    const span = 7 + Math.pow(t, 0.8) * 107;
    for (const side of [-1, 1]) {
      const len = span * (0.70 + rng() * 0.3);
      const ey = y + 12 + t * 19 + rng() * 9;
      line(128, y, 128 + side * len, ey, 1.6, '#54503a');
      for (let k = 0; k < 36; k++) {
        const u = k / 36;
        const x = 128 + side * len * u;
        const by = y + (ey - y) * u;
        const tuft = 5 + (1 - u) * 10;
        const tone = Math.floor(44 + rng() * 49);
        const c = `rgb(${Math.floor(tone * 0.75)},${tone},${Math.floor(tone * 0.68)})`;
        for (let n = 0; n < 4; n++) {
          line(x, by, x + side * (3 + rng() * tuft), by - 3 - rng() * tuft, 1.1 + rng(), c);
        }
      }
    }
  }
  // Open broadleaf canopy: clusters with visible gaps, twigs and a broken edge.
  for (let b = 0; b < 16; b++) {
    const a = rng() * Math.PI * 2;
    const r = Math.sqrt(rng());
    const x = 384 + Math.cos(a) * r * 105;
    const y = 200 + Math.sin(a) * r * 150;
    line(384, 470, x, y, 2.3, '#6a6048');
    for (let k = 0; k < 230; k++) {
      const angle = rng() * Math.PI * 2;
      const radius = Math.sqrt(rng()) * 45;
      const lx = x + Math.cos(angle) * radius;
      const ly = y + Math.sin(angle) * radius * 0.85;
      if (lx < 262 || lx > 506 || ly < 12) continue;
      const tone = 36 + Math.floor(rng() * 63);
      g.fillStyle = `rgb(${Math.floor(tone * 0.86)},${tone},${Math.floor(tone * 0.58)})`;
      g.beginPath(); g.ellipse(lx, ly, 2 + rng() * 4, 1.5 + rng() * 2, rng() * 3, 0, Math.PI * 2); g.fill();
    }
  }
  const tex = new THREE.CanvasTexture(canvas);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = 4;
  return tex;
}
