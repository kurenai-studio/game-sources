// Shared toon-shading helpers: gradient map, toon materials, inverted-hull
// outlines, and small canvas texture builders.
import * as THREE from 'three';

let _gradientMap = null;

export function toonGradient() {
  if (_gradientMap) return _gradientMap;
  const steps = new Uint8Array([90, 150, 210, 255]);
  const tex = new THREE.DataTexture(steps, steps.length, 1, THREE.RedFormat);
  tex.minFilter = THREE.NearestFilter;
  tex.magFilter = THREE.NearestFilter;
  tex.needsUpdate = true;
  _gradientMap = tex;
  return tex;
}

export function toonMaterial(color, opts = {}) {
  return new THREE.MeshToonMaterial({
    color,
    gradientMap: toonGradient(),
    ...opts
  });
}

// Inverted-hull outline: a slightly scaled BackSide dark-lavender shell.
export function addOutline(mesh, thickness = 0.035, color = 0x5a4a7a) {
  const shell = new THREE.Mesh(
    mesh.geometry,
    new THREE.MeshBasicMaterial({ color, side: THREE.BackSide })
  );
  shell.scale.setScalar(1 + thickness);
  shell.raycast = () => {}; // outlines never intercept interaction rays
  mesh.add(shell);
  return shell;
}

export function canvasTexture(size, draw) {
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext('2d');
  draw(ctx, size);
  const tex = new THREE.CanvasTexture(canvas);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

// Soft radial-gradient puff sprite (clouds, foam, glows).
export function puffTexture(inner = 'rgba(255,255,255,0.95)', outer = 'rgba(255,255,255,0)') {
  return canvasTexture(128, (ctx, s) => {
    const g = ctx.createRadialGradient(s / 2, s / 2, s * 0.05, s / 2, s / 2, s * 0.5);
    g.addColorStop(0, inner);
    g.addColorStop(0.55, inner.replace(/[\d.]+\)$/, '0.45)'));
    g.addColorStop(1, outer);
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, s, s);
  });
}

// Tileable-ish soft noise texture for the cloud sea.
export function noiseTexture(rng) {
  return canvasTexture(256, (ctx, s) => {
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, s, s);
    for (let i = 0; i < 700; i++) {
      const x = rng.float(0, s);
      const y = rng.float(0, s);
      const r = rng.float(8, 34);
      const a = rng.float(0.1, 0.3);
      const tint = rng.pick(['205,180,240', '168,230,207', '255,227,201', '190,220,250']);
      const g = ctx.createRadialGradient(x, y, 0, x, y, r);
      g.addColorStop(0, `rgba(${tint},${a})`);
      g.addColorStop(1, `rgba(${tint},0)`);
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(x, y, r, 0, Math.PI * 2);
      ctx.fill();
    }
  });
}
