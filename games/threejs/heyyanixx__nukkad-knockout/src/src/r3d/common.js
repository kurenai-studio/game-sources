import * as THREE from 'three';

// Sim works in "screen px" (960 x 540, floor at y = 0, negative y = up). 100 px = 1 world unit.
export const toX = (x) => (x - 480) / 100;
export const toY = (y) => -y / 100;

let gradient = null;
// 3-band toon ramp (cel shading)
export function toonRamp() {
  if (gradient) return gradient;
  const data = new Uint8Array([70, 70, 70, 255, 160, 160, 160, 255, 255, 255, 255, 255]);
  gradient = new THREE.DataTexture(data, 3, 1, THREE.RGBAFormat);
  gradient.minFilter = gradient.magFilter = THREE.NearestFilter;
  gradient.needsUpdate = true;
  return gradient;
}
export const toon = (color, extra = {}) => new THREE.MeshToonMaterial({ color, gradientMap: toonRamp(), ...extra });
export const OUTLINE = new THREE.MeshBasicMaterial({ color: 0x0a0a0e, side: THREE.BackSide });

export function canvasTex(w, h, draw, opts = {}) {
  const c = document.createElement('canvas'); c.width = w; c.height = h;
  draw(c.getContext('2d'), w, h);
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  if (opts.repeat) { t.wrapS = t.wrapT = THREE.RepeatWrapping; t.repeat.set(opts.repeat[0], opts.repeat[1]); }
  t.anisotropy = 4;
  return t;
}

// soft round dot used by particles and blob shadows
let dot = null;
export function dotTex() {
  if (dot) return dot;
  dot = canvasTex(64, 64, (c, w) => {
    const g = c.createRadialGradient(w / 2, w / 2, 0, w / 2, w / 2, w / 2);
    g.addColorStop(0, 'rgba(255,255,255,1)'); g.addColorStop(0.35, 'rgba(255,255,255,0.75)'); g.addColorStop(1, 'rgba(255,255,255,0)');
    c.fillStyle = g; c.fillRect(0, 0, w, w);
  });
  return dot;
}
let star = null;
export function starTex() {
  if (star) return star;
  star = canvasTex(128, 128, (c, w) => {
    c.translate(w / 2, w / 2);
    const g = c.createRadialGradient(0, 0, 0, 0, 0, w / 2);
    g.addColorStop(0, 'rgba(255,255,255,1)'); g.addColorStop(0.3, 'rgba(255,240,190,0.9)'); g.addColorStop(1, 'rgba(255,200,80,0)');
    c.fillStyle = g; c.beginPath();
    const n = 9;
    for (let i = 0; i < n * 2; i++) { const a = (i / (n * 2)) * Math.PI * 2, r = i % 2 ? w * 0.16 : w * (0.42 + (i % 4 ? 0.06 : 0)); c.lineTo(Math.cos(a) * r, Math.sin(a) * r); }
    c.closePath(); c.fill();
  });
  return star;
}

export const lerp = (a, b, t) => a + (b - a) * t;
export const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
export const ease = (t) => t * t * (3 - 2 * t);
