// Everything here is generated at load time: no image files ship with the game.
import * as THREE from 'three/webgpu';
import { mulberry32, clamp, lerp, TAU } from '../core/util.js';

// Tileable value noise with quintic interpolation.
function makeNoise(seed) {
  const rng = mulberry32(seed);
  const tbl = new Float32Array(65536);
  for (let i = 0; i < 65536; i++) tbl[i] = rng();
  return (x, y, period) => {
    const xi = Math.floor(x), yi = Math.floor(y);
    const fx = x - xi, fy = y - yi;
    const u = fx * fx * fx * (fx * (fx * 6 - 15) + 10);
    const v = fy * fy * fy * (fy * (fy * 6 - 15) + 10);
    const x0 = ((xi % period) + period) % period, x1 = (x0 + 1) % period;
    const y0 = ((yi % period) + period) % period, y1 = (y0 + 1) % period;
    const a = tbl[(x0 * 251 + y0 * 257) & 65535], b = tbl[(x1 * 251 + y0 * 257) & 65535];
    const c = tbl[(x0 * 251 + y1 * 257) & 65535], d = tbl[(x1 * 251 + y1 * 257) & 65535];
    return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
  };
}

function fbm(noise, u, v, freq, octaves) {
  let sum = 0, amp = 0.5, norm = 0, f = freq;
  for (let o = 0; o < octaves; o++) {
    sum += noise(u * f, v * f, f) * amp;
    norm += amp; amp *= 0.5; f *= 2;
  }
  return sum / norm;
}

const hex = (h) => { const c = new THREE.Color(h); return [c.r, c.g, c.b]; }; // linear working space

// Height-driven tile: albedo (rgb sRGB, a height) + normal (xy, b rough, a stone mask).
export function makeGroundTextures(biome, size, renderer) {
  const N = size;
  const noise = makeNoise(biome.id.length * 7919 + 13);
  const rng = mulberry32(biome.id.charCodeAt(0) * 131);
  const t = biome.tex;
  const H = new Float32Array(N * N);
  const S = new Float32Array(N * N);   // stone mask
  const P = new Float32Array(N * N);   // patch mask
  const C = new Float32Array(N * N);   // crack depth

  for (let y = 0; y < N; y++) {
    for (let x = 0; x < N; x++) {
      const u = x / N, v = y / N, i = y * N + x;
      const large = fbm(noise, u, v, 6, 4);
      const small = fbm(noise, u + 0.31, v + 0.17, 44, 3);
      const warpU = fbm(noise, u + 0.5, v, 8, 2) * 0.05, warpV = fbm(noise, u, v + 0.5, 8, 2) * 0.05;
      const r1 = 1 - Math.abs(fbm(noise, u + warpU, v + warpV, 10, 3) * 2 - 1);
      const r2 = 1 - Math.abs(fbm(noise, u - warpV + 0.2, v + warpU, 22, 2) * 2 - 1);
      const cr = Math.max(Math.pow(r1, 42), Math.pow(r2, 60) * 0.6) * clamp(t.crack, 0, 1.6);
      C[i] = clamp(cr, 0, 1);
      H[i] = 0.2 + large * 0.5 + small * 0.2 - cr * 0.16;
      if (t.patch) P[i] = clamp((fbm(noise, u + 0.7, v + 0.1, 5, 4) - 0.46) * 7, 0, 1) * t.patch.amount;
    }
  }
  // Scattered pebbles, stamped with wrap-around so the tile stays seamless.
  for (let p = 0; p < t.pebbles; p++) {
    const cx = rng() * N, cy = rng() * N;
    const r = (rng() * rng() * 7 + 1.4) * (N / 1024) * (rng() < 0.03 ? 2.8 : 1);
    const ri = Math.ceil(r);
    const squash = 0.6 + rng() * 0.4, rot = rng() * TAU, cs = Math.cos(rot), sn = Math.sin(rot);
    for (let dy = -ri; dy <= ri; dy++) {
      for (let dx = -ri; dx <= ri; dx++) {
        const ax = (dx * cs + dy * sn), ay = (-dx * sn + dy * cs) / squash;
        const d = (ax * ax + ay * ay) / (r * r);
        if (d > 1) continue;
        const i = (((Math.floor(cy) + dy) % N + N) % N) * N + (((Math.floor(cx) + dx) % N + N) % N);
        const dome = Math.sqrt(1 - d);
        H[i] = Math.max(H[i], H[i] + dome * 0.1);
        S[i] = Math.max(S[i], dome > 0.1 ? 1 : 0);
      }
    }
  }

  const albedo = new Uint8Array(N * N * 4);
  const normal = new Uint8Array(N * N * 4);
  const low = hex(t.low), mid = hex(t.mid), high = hex(t.high), stone = hex(t.stone);
  const patch = t.patch ? hex(t.patch.color) : null;
  const toSRGB = (v) => Math.round(255 * Math.pow(clamp(v, 0, 1), 1 / 2.2));
  for (let y = 0; y < N; y++) {
    for (let x = 0; x < N; x++) {
      const i = y * N + x, o = i * 4;
      const xp = y * N + ((x + 1) % N), xm = y * N + ((x + N - 1) % N);
      const yp = ((y + 1) % N) * N + x, ym = ((y + N - 1) % N) * N + x;
      const k = 11 * (N / 1024);
      const dx = (H[xm] - H[xp]) * k, dy = (H[ym] - H[yp]) * k;
      const nl = 1 / Math.sqrt(dx * dx + dy * dy + 1);
      const h = clamp(H[i] * 1.28 - 0.08, 0, 1);
      const c = h < 0.5 ? h * 2 : (h - 0.5) * 2;
      const a = h < 0.5 ? low : mid, b = h < 0.5 ? mid : high;
      let r = lerp(a[0], b[0], c), g = lerp(a[1], b[1], c), bl = lerp(a[2], b[2], c);
      const grain = 1 + (noise(x * 0.5, y * 0.5, N) - 0.5) * t.grain * 3;
      r *= grain; g *= grain; bl *= grain;
      if (P[i] > 0) { r = lerp(r, patch[0] * grain, P[i]); g = lerp(g, patch[1] * grain, P[i]); bl = lerp(bl, patch[2] * grain, P[i]); }
      if (S[i] > 0) { const q = 0.6 + h * 0.9; r = lerp(r, stone[0] * q, S[i]); g = lerp(g, stone[1] * q, S[i]); bl = lerp(bl, stone[2] * q, S[i]); }
      const crackDark = 1 - C[i] * 0.55;
      albedo[o] = toSRGB(r * crackDark); albedo[o + 1] = toSRGB(g * crackDark); albedo[o + 2] = toSRGB(bl * crackDark);
      albedo[o + 3] = Math.round(C[i] * 255);
      normal[o] = Math.round((dx * nl * 0.5 + 0.5) * 255);
      normal[o + 1] = Math.round((dy * nl * 0.5 + 0.5) * 255);
      normal[o + 2] = Math.round(clamp(0.92 - S[i] * 0.28 - (1 - h) * 0.1, 0, 1) * 255);
      normal[o + 3] = Math.round(S[i] * 255);
    }
  }
  const make = (data, srgb) => {
    const tx = new THREE.DataTexture(data, N, N, THREE.RGBAFormat, THREE.UnsignedByteType);
    tx.wrapS = tx.wrapT = THREE.RepeatWrapping;
    tx.magFilter = THREE.LinearFilter;
    tx.minFilter = THREE.LinearMipmapLinearFilter;
    tx.generateMipmaps = true;
    tx.anisotropy = Math.min(8, renderer.getMaxAnisotropy?.() ?? 8);
    tx.colorSpace = srgb ? THREE.SRGBColorSpace : THREE.NoColorSpace;
    tx.needsUpdate = true;
    return tx;
  };
  return { albedo: make(albedo, true), normal: make(normal, false) };
}

function atlasCanvas(size) {
  const c = document.createElement('canvas');
  c.width = c.height = size;
  return { canvas: c, ctx: c.getContext('2d') };
}

function canvasTexture(canvas) {
  const t = new THREE.CanvasTexture(canvas);
  t.colorSpace = THREE.NoColorSpace;
  t.flipY = false;
  t.generateMipmaps = true;
  t.minFilter = THREE.LinearMipmapLinearFilter;
  t.magFilter = THREE.LinearFilter;
  return t;
}

// Decal shapes, white with density in the red channel. 4x4 cells. See STAMP.
export const STAMP = {
  splat0: 0, splat1: 1, splat2: 2, splat3: 3,
  spray0: 4, spray1: 5, drops: 6,
  scorch: 8, crater: 9, footL: 10, footR: 11,
  casing: 12, ember: 13, frost: 14, dot: 15,
};

export function makeStampAtlas() {
  const size = 2048, cell = size / 4;
  const { canvas, ctx } = atlasCanvas(size);
  const rng = mulberry32(90210);
  const R = (a = 1, b) => (b === undefined ? rng() * a : a + rng() * (b - a));
  ctx.fillStyle = 'rgba(0,0,0,0)';
  ctx.clearRect(0, 0, size, size);

  const grad = (cx, cy, r, inner, outer) => {
    const g = ctx.createRadialGradient(cx, cy, 0, cx, cy, r);
    g.addColorStop(0, inner); g.addColorStop(1, outer);
    return g;
  };
  const blob = (cx, cy, r, jag, shade = 200) => {
    ctx.beginPath();
    const steps = 44, ph = R(TAU), k1 = Math.floor(R(3, 7)), k2 = Math.floor(R(8, 15));
    for (let i = 0; i <= steps; i++) {
      const a = (i / steps) * TAU;
      const d = r * (1 + Math.sin(a * k1 + ph) * jag * 0.5 + Math.sin(a * k2 + ph * 2) * jag * 0.28);
      const x = cx + Math.cos(a) * d, y = cy + Math.sin(a) * d;
      if (i) ctx.lineTo(x, y); else ctx.moveTo(x, y);
    }
    ctx.closePath();
    ctx.fillStyle = grad(cx, cy, r * 1.25, `rgba(${shade + 55},0,0,1)`, `rgba(${shade - 60},0,0,1)`);
    ctx.fill();
  };
  const dropsAround = (cx, cy, rMin, rMax, n, sMin, sMax, a0 = 0, a1 = TAU) => {
    for (let i = 0; i < n; i++) {
      const a = R(a0, a1), d = R(rMin, rMax), s = R(sMin, sMax) * (1 - (d - rMin) / (rMax - rMin + 1) * 0.6);
      const stretch = R(1.2, 2.6);
      ctx.save();
      ctx.translate(cx + Math.cos(a) * d, cy + Math.sin(a) * d);
      ctx.rotate(a);
      ctx.beginPath();
      ctx.ellipse(0, 0, s * stretch, s, 0, 0, TAU);
      ctx.fillStyle = 'rgba(210,0,0,1)';
      ctx.fill();
      ctx.restore();
    }
  };
  const tendrils = (cx, cy, r, n, reach) => {
    for (let i = 0; i < n; i++) {
      const a = R(TAU), l = R(r, reach), w = R(4, 13);
      ctx.save();
      ctx.translate(cx, cy);
      ctx.rotate(a);
      ctx.beginPath();
      ctx.moveTo(r * 0.5, -w);
      ctx.quadraticCurveTo(l * 0.7, -w * 0.35, l, 0);
      ctx.quadraticCurveTo(l * 0.7, w * 0.35, r * 0.5, w);
      ctx.closePath();
      ctx.fillStyle = 'rgba(205,0,0,1)';
      ctx.fill();
      ctx.beginPath();
      ctx.arc(l, 0, w * 0.55, 0, TAU);
      ctx.fill();
      ctx.restore();
    }
  };
  const inCell = (idx, fn) => {
    const cx = (idx % 4) * cell + cell / 2, cy = Math.floor(idx / 4) * cell + cell / 2;
    ctx.save();
    ctx.beginPath(); ctx.rect(cx - cell / 2, cy - cell / 2, cell, cell); ctx.clip();
    fn(cx, cy);
    ctx.restore();
  };

  for (let s = 0; s < 4; s++) {
    inCell(s, (cx, cy) => {
      const r = R(95, 135);
      tendrils(cx, cy, r, 11 + s * 4, 215);
      blob(cx, cy, r, 0.42);
      for (let i = 0; i < 4; i++) blob(cx + R(-r, r), cy + R(-r, r), R(30, 70), 0.5);
      dropsAround(cx, cy, r * 1.1, 238, 60 + s * 14, 2, 9);
    });
  }
  for (let s = 0; s < 2; s++) {
    inCell(STAMP.spray0 + s, (cx, cy) => {
      const ox = cx - 170;
      blob(ox + 40, cy, 44, 0.5);
      dropsAround(ox + 10, cy, 30, 390, 260, 2.5, 13, -0.34, 0.34);
      for (let i = 0; i < 16; i++) {
        const a = R(-0.22, 0.22), l = R(120, 360), w = R(3, 9);
        ctx.strokeStyle = 'rgba(205,0,0,1)'; ctx.lineWidth = w; ctx.lineCap = 'round';
        ctx.beginPath();
        ctx.moveTo(ox + 40, cy);
        ctx.lineTo(ox + 40 + Math.cos(a) * l, cy + Math.sin(a) * l);
        ctx.stroke();
      }
    });
  }
  inCell(STAMP.drops, (cx, cy) => dropsAround(cx, cy, 0, 240, 170, 2, 16));
  inCell(STAMP.scorch, (cx, cy) => {
    ctx.fillStyle = grad(cx, cy, 235, 'rgba(255,0,0,.95)', 'rgba(90,0,0,0)');
    ctx.fillRect(cx - 256, cy - 256, 512, 512);
    // Uneven soot blotches rather than radial spikes, so the edge reads as a burn.
    for (let i = 0; i < 46; i++) {
      const a = R(TAU), d = R(70, 215), r = R(16, 58);
      const x = cx + Math.cos(a) * d, y = cy + Math.sin(a) * d;
      ctx.fillStyle = grad(x, y, r, 'rgba(200,0,0,.28)', 'rgba(200,0,0,0)');
      ctx.fillRect(x - r, y - r, r * 2, r * 2);
    }
  });
  inCell(STAMP.crater, (cx, cy) => {
    ctx.fillStyle = grad(cx, cy, 240, 'rgba(255,0,0,1)', 'rgba(60,0,0,0)');
    ctx.fillRect(cx - 256, cy - 256, 512, 512);
    dropsAround(cx, cy, 110, 240, 120, 3, 12);
  });
  for (let s = 0; s < 2; s++) {
    inCell(STAMP.footL + s, (cx, cy) => {
      const ox = s ? 34 : -34;
      ctx.fillStyle = 'rgba(205,0,0,1)';
      ctx.beginPath(); ctx.ellipse(cx + ox, cy - 62, 62, 92, 0, 0, TAU); ctx.fill();
      ctx.beginPath(); ctx.ellipse(cx + ox, cy + 112, 50, 58, 0, 0, TAU); ctx.fill();
      ctx.globalCompositeOperation = 'destination-out';
      for (let i = 0; i < 6; i++) ctx.fillRect(cx + ox - 80, cy - 120 + i * 30, 160, 9);
      ctx.globalCompositeOperation = 'source-over';
    });
  }
  inCell(STAMP.casing, (cx, cy) => {
    ctx.fillStyle = 'rgba(255,0,0,1)';
    ctx.beginPath(); ctx.roundRect(cx - 110, cy - 42, 220, 84, 20); ctx.fill();
  });
  inCell(STAMP.ember, (cx, cy) => {
    ctx.fillStyle = grad(cx, cy, 230, 'rgba(255,0,0,0.9)', 'rgba(120,0,0,0)');
    ctx.fillRect(cx - 256, cy - 256, 512, 512);
  });
  inCell(STAMP.frost, (cx, cy) => {
    for (let i = 0; i < 14; i++) {
      const a = (i / 14) * TAU + R(0.15);
      ctx.strokeStyle = 'rgba(220,0,0,1)'; ctx.lineWidth = R(3, 9);
      let x = cx, y = cy;
      ctx.beginPath(); ctx.moveTo(x, y);
      for (let k = 0; k < 6; k++) { const b = a + R(-0.4, 0.4); x += Math.cos(b) * R(20, 50); y += Math.sin(b) * R(20, 50); ctx.lineTo(x, y); }
      ctx.stroke();
    }
  });
  inCell(STAMP.dot, (cx, cy) => {
    ctx.fillStyle = grad(cx, cy, 250, 'rgba(255,0,0,1)', 'rgba(255,0,0,0)');
    ctx.fillRect(cx - 256, cy - 256, 512, 512);
  });
  return canvasTexture(canvas);
}

// Particle + icon atlas, 6x6 cells. See SPRITE and bonus `icon` values.
export const SPRITE = {
  dot: 0, smoke: 1, flame: 2, spark: 3, ring: 4, blade: 5, plasma: 6, shard: 7, drop: 8, crosshair: 9, puff: 10, halo: 11,
  iconStart: 12,
};
export const SPRITE_CELLS = 6;

export function makeSpriteAtlas(iconDrawers) {
  const size = 1536, cell = size / SPRITE_CELLS;
  const { canvas, ctx } = atlasCanvas(size);
  const rng = mulberry32(4242);
  const R = (a = 1, b) => (b === undefined ? rng() * a : a + rng() * (b - a));
  const inCell = (idx, fn) => {
    const ox = (idx % SPRITE_CELLS) * cell, oy = Math.floor(idx / SPRITE_CELLS) * cell;
    ctx.save(); ctx.beginPath(); ctx.rect(ox, oy, cell, cell); ctx.clip();
    ctx.translate(ox + cell / 2, oy + cell / 2);
    fn(cell / 2);
    ctx.restore();
  };
  const radial = (r, stops) => {
    const g = ctx.createRadialGradient(0, 0, 0, 0, 0, r);
    for (const [p, c] of stops) g.addColorStop(p, c);
    ctx.fillStyle = g;
    ctx.fillRect(-r, -r, r * 2, r * 2);
  };
  inCell(SPRITE.dot, (r) => radial(r, [[0, '#fff'], [0.25, 'rgba(255,255,255,.75)'], [1, 'rgba(255,255,255,0)']]));
  const smoke = (r, lumps, soft) => {
    for (let i = 0; i < lumps; i++) {
      const a = R(TAU), d = R(r * 0.5), s = R(r * 0.25, r * 0.55);
      ctx.save(); ctx.translate(Math.cos(a) * d, Math.sin(a) * d);
      radial(s, [[0, `rgba(255,255,255,${soft})`], [1, 'rgba(255,255,255,0)']]);
      ctx.restore();
    }
  };
  inCell(SPRITE.smoke, (r) => smoke(r, 26, 0.16));
  inCell(SPRITE.puff, (r) => smoke(r, 14, 0.3));
  inCell(SPRITE.flame, (r) => {
    for (let i = 0; i < 18; i++) {
      const a = R(TAU), d = R(r * 0.34), s = R(r * 0.2, r * 0.42);
      ctx.save(); ctx.translate(Math.cos(a) * d, Math.sin(a) * d);
      radial(s, [[0, 'rgba(255,255,255,.5)'], [1, 'rgba(255,255,255,0)']]);
      ctx.restore();
    }
  });
  inCell(SPRITE.spark, (r) => {
    radial(r, [[0, '#fff'], [0.12, 'rgba(255,255,255,.9)'], [0.34, 'rgba(255,255,255,.14)'], [1, 'rgba(255,255,255,0)']]);
  });
  inCell(SPRITE.ring, (r) => radial(r, [[0.74, 'rgba(255,255,255,0)'], [0.9, '#fff'], [0.97, 'rgba(255,255,255,.2)'], [1, 'rgba(255,255,255,0)']]));
  inCell(SPRITE.halo, (r) => radial(r, [[0, 'rgba(255,255,255,0)'], [0.65, 'rgba(255,255,255,.04)'], [0.9, 'rgba(255,255,255,.9)'], [1, 'rgba(255,255,255,0)']]));
  inCell(SPRITE.blade, (r) => {
    ctx.fillStyle = '#fff';
    ctx.beginPath();
    const teeth = 8;
    for (let i = 0; i < teeth * 2; i++) {
      const a = (i / (teeth * 2)) * TAU, d = i % 2 ? r * 0.56 : r * 0.92;
      ctx.lineTo(Math.cos(a) * d, Math.sin(a) * d);
    }
    ctx.closePath(); ctx.fill();
    ctx.globalCompositeOperation = 'destination-out';
    ctx.beginPath(); ctx.arc(0, 0, r * 0.18, 0, TAU); ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
  });
  inCell(SPRITE.plasma, (r) => radial(r, [[0, '#fff'], [0.32, 'rgba(255,255,255,.95)'], [0.5, 'rgba(255,255,255,.4)'], [1, 'rgba(255,255,255,0)']]));
  inCell(SPRITE.shard, (r) => {
    ctx.fillStyle = '#fff';
    ctx.beginPath(); ctx.moveTo(0, -r * 0.92); ctx.lineTo(r * 0.36, -r * 0.1); ctx.lineTo(r * 0.14, r * 0.8); ctx.lineTo(-r * 0.34, r * 0.25); ctx.closePath(); ctx.fill();
  });
  inCell(SPRITE.drop, (r) => {
    radial(r * 0.72, [[0, '#fff'], [0.72, '#fff'], [1, 'rgba(255,255,255,0)']]);
  });
  inCell(SPRITE.crosshair, (r) => {
    ctx.strokeStyle = '#fff'; ctx.lineWidth = r * 0.06;
    ctx.beginPath(); ctx.arc(0, 0, r * 0.7, 0, TAU); ctx.stroke();
  });
  iconDrawers.forEach((draw, i) => {
    inCell(SPRITE.iconStart + i, (r) => {
      ctx.lineJoin = 'round'; ctx.lineCap = 'round';
      ctx.fillStyle = '#fff'; ctx.strokeStyle = '#fff'; ctx.lineWidth = r * 0.12;
      draw(ctx, r * 0.74);
    });
  });
  return canvasTexture(canvas);
}
