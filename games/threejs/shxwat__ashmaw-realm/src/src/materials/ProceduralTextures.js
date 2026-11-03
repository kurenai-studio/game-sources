/**
 * Texture forge.
 *
 * The realm ships with zero image files: every albedo / normal / roughness map
 * here is synthesised at boot from *periodic* value noise, so it tiles
 * seamlessly and costs nothing to download. One pass writes colour, height and
 * roughness together; the normal map is Sobel-derived from that same height
 * buffer, which keeps detail perfectly registered between channels.
 */
import * as THREE from 'three';

/* ── periodic value noise (tileable, unlike simplex) ──────────────────── */

function hash2i(x, y, per, seed) {
  x = ((x % per) + per) % per;
  y = ((y % per) + per) % per;
  let h = Math.imul(x, 374761393) ^ Math.imul(y, 668265263) ^ Math.imul(seed, 1274126177);
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) >>> 0) / 4294967296;
}

function vnoise(x, y, per, seed) {
  const x0 = Math.floor(x), y0 = Math.floor(y);
  const fx = x - x0, fy = y - y0;
  const sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy);
  const a = hash2i(x0,     y0,     per, seed);
  const b = hash2i(x0 + 1, y0,     per, seed);
  const c = hash2i(x0,     y0 + 1, per, seed);
  const d = hash2i(x0 + 1, y0 + 1, per, seed);
  return (a + (b - a) * sx) * (1 - sy) + (c + (d - c) * sx) * sy;
}

/** Tileable fbm: each octave doubles both frequency and lattice period. */
function pfbm(x, y, per, oct = 5, seed = 0, gain = 0.5) {
  let amp = 1, sum = 0, norm = 0, f = 1;
  for (let o = 0; o < oct; o++) {
    sum  += amp * vnoise(x * f, y * f, per * f, seed + o * 131);
    norm += amp;
    amp  *= gain;
    f    *= 2;
  }
  return sum / norm;
}

/** Tileable Worley/voronoi F1 — cobbles, scales, cooled lava crust. */
function pworley(x, y, per, seed = 0) {
  const xi = Math.floor(x), yi = Math.floor(y);
  let f1 = 8;
  for (let j = -1; j <= 1; j++) {
    for (let i = -1; i <= 1; i++) {
      const cx = xi + i, cy = yi + j;
      const ox = hash2i(cx, cy, per, seed);
      const oy = hash2i(cx, cy, per, seed + 977);
      const d = Math.hypot(cx + ox - x, cy + oy - y);
      if (d < f1) f1 = d;
    }
  }
  return f1;
}

const clamp01 = (v) => (v < 0 ? 0 : v > 1 ? 1 : v);

/* ── generator ───────────────────────────────────────────────────────── */

/**
 * @param sample (u, v, n) → [r, g, b, height, roughness]  — all 0..1
 *        `n` bundles the noise helpers so callers stay declarative.
 */
function forge(name, { size = 256, repeat = 1, sample, normalStrength = 1.6, anisotropy = 8 }) {
  const px = size * size;
  const col = new Uint8ClampedArray(px * 4);
  const hgt = new Float32Array(px);
  const rgh = new Uint8ClampedArray(px * 4);

  const n = { fbm: pfbm, worley: pworley, noise: vnoise };

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const i = y * size + x;
      const [r, g, b, h, ro] = sample(x / size, y / size, n);
      col[i * 4]     = r * 255;
      col[i * 4 + 1] = g * 255;
      col[i * 4 + 2] = b * 255;
      col[i * 4 + 3] = 255;
      hgt[i] = h;
      const rv = clamp01(ro) * 255;
      rgh[i * 4] = rgh[i * 4 + 1] = rgh[i * 4 + 2] = rv;
      rgh[i * 4 + 3] = 255;
    }
  }

  // Sobel → tangent-space normal, wrapping at the edges so it stays tileable.
  const nrm = new Uint8ClampedArray(px * 4);
  const at = (x, y) => hgt[(((y % size) + size) % size) * size + (((x % size) + size) % size)];
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const dx = (at(x - 1, y - 1) + 2 * at(x - 1, y) + at(x - 1, y + 1))
               - (at(x + 1, y - 1) + 2 * at(x + 1, y) + at(x + 1, y + 1));
      const dy = (at(x - 1, y - 1) + 2 * at(x, y - 1) + at(x + 1, y - 1))
               - (at(x - 1, y + 1) + 2 * at(x, y + 1) + at(x + 1, y + 1));
      let nx = dx * normalStrength * 4, ny = dy * normalStrength * 4, nz = 1;
      const len = Math.hypot(nx, ny, nz);
      const i = (y * size + x) * 4;
      nrm[i]     = (nx / len * 0.5 + 0.5) * 255;
      nrm[i + 1] = (ny / len * 0.5 + 0.5) * 255;
      nrm[i + 2] = (nz / len * 0.5 + 0.5) * 255;
      nrm[i + 3] = 255;
    }
  }

  const mk = (data, srgb) => {
    const t = new THREE.DataTexture(data, size, size, THREE.RGBAFormat);
    t.colorSpace = srgb ? THREE.SRGBColorSpace : THREE.NoColorSpace;
    t.wrapS = t.wrapT = THREE.RepeatWrapping;
    t.repeat.set(repeat, repeat);
    t.generateMipmaps = true;
    t.minFilter = THREE.LinearMipmapLinearFilter;
    t.magFilter = THREE.LinearFilter;
    t.anisotropy = anisotropy;
    t.needsUpdate = true;
    t.name = name;
    return t;
  };

  return { map: mk(col, true), normalMap: mk(nrm, false), roughnessMap: mk(rgh, false) };
}

/* ── canvas sprites (radial gradients beat noise for soft billboards) ─── */

function canvas2d(size) {
  const c = document.createElement('canvas');
  c.width = c.height = size;
  return [c, c.getContext('2d')];
}

function spriteTexture(canvas, { srgb = true } = {}) {
  const t = new THREE.CanvasTexture(canvas);
  t.colorSpace = srgb ? THREE.SRGBColorSpace : THREE.NoColorSpace;
  t.wrapS = t.wrapT = THREE.ClampToEdgeWrapping;
  t.minFilter = THREE.LinearMipmapLinearFilter;
  t.generateMipmaps = true;
  t.needsUpdate = true;
  return t;
}

function glowSprite(size = 128, inner = 'rgba(255,255,255,1)', mid = 'rgba(255,170,70,.55)') {
  const [c, g] = canvas2d(size);
  const grd = g.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
  grd.addColorStop(0.0, inner);
  grd.addColorStop(0.28, mid);
  grd.addColorStop(1.0, 'rgba(255,80,20,0)');
  g.fillStyle = grd;
  g.fillRect(0, 0, size, size);
  return spriteTexture(c);
}

/**
 * Lumpy smoke puff, alpha only.
 *
 * Built from fbm value noise rather than a cluster of radial gradients. The
 * previous version drew 26 soft blobs and then carved them with a *circular*
 * destination-out vignette running from 0.18r to 0.5r — which threw away
 * whatever irregularity the blobs had and guaranteed a smooth round falloff.
 * Combined with the equally circular mask in the plume shader, every particle
 * in the column was the same soft grey disc, and a few hundred soft grey discs
 * stacked up look like bubbles, not like a convecting ash column.
 *
 * Here the radial mask is *displaced by the noise itself*, so the sprite's
 * silhouette is ragged and its interior has structure at several scales.
 */
function smokeSprite(size = 192, seed = 3) {
  const [c, g] = canvas2d(size);
  const img = g.createImageData(size, size);
  const d = img.data;

  let s = seed >>> 0;
  const rnd = () => ((s = (s * 16807) % 2147483647) / 2147483647);

  // Small hash-based value-noise lattice.
  const P = new Float32Array(256 * 256);
  for (let i = 0; i < P.length; i++) P[i] = rnd();
  const lat = (x, y) => P[((y & 255) << 8) | (x & 255)];
  const smooth = (t) => t * t * (3 - 2 * t);
  const vnoise = (x, y) => {
    const xi = Math.floor(x), yi = Math.floor(y);
    const xf = smooth(x - xi), yf = smooth(y - yi);
    const a = lat(xi, yi), b = lat(xi + 1, yi);
    const e = lat(xi, yi + 1), f = lat(xi + 1, yi + 1);
    return (a + (b - a) * xf) + ((e + (f - e) * xf) - (a + (b - a) * xf)) * yf;
  };
  const fbm2 = (x, y) => {
    let v = 0, amp = 0.5, fx = x, fy = y;
    for (let o = 0; o < 5; o++) { v += vnoise(fx, fy) * amp; amp *= 0.5; fx *= 2.03; fy *= 2.01; }
    return v;
  };

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const nx = (x / size) * 2 - 1;
      const ny = (y / size) * 2 - 1;
      const r = Math.sqrt(nx * nx + ny * ny);

      const n = fbm2(x / size * 4.2 + 11.3, y / size * 4.2 + 7.1);   // ~0..1
      // Noise-displaced edge: the boundary of the puff is where the mask
      // crosses zero, and that boundary moves with the noise. Displacement is
      // kept moderate — push it much past this and the particle stops being a
      // lump of smoke and becomes a spiky fleck, which is just a different
      // kind of wrong.
      const edge = 0.72 + (n - 0.5) * 0.46;
      let a = 1 - smooth(Math.min(1, Math.max(0, (r - (edge - 0.52)) / 0.52)));
      // Interior density variation so the puff isn't uniform where it is opaque.
      a *= 0.72 + n * 0.55;
      // Guarantee a clean transparent border so quads never show their edges.
      a *= 1 - smooth(Math.min(1, Math.max(0, (r - 0.86) / 0.14)));

      const i = (y * size + x) * 4;
      d[i] = 255; d[i + 1] = 255; d[i + 2] = 255;
      d[i + 3] = Math.max(0, Math.min(255, Math.round(a * 255)));
    }
  }
  g.putImageData(img, 0, 0);
  return spriteTexture(c);
}

function leafSprite(size = 64) {
  const [c, g] = canvas2d(size);
  g.translate(size / 2, size / 2);
  g.beginPath();
  g.moveTo(0, -size * 0.42);
  g.bezierCurveTo(size * 0.34, -size * 0.16, size * 0.26, size * 0.3, 0, size * 0.44);
  g.bezierCurveTo(-size * 0.26, size * 0.3, -size * 0.34, -size * 0.16, 0, -size * 0.42);
  const grd = g.createLinearGradient(0, -size / 2, 0, size / 2);
  grd.addColorStop(0, '#8a6a2c');
  grd.addColorStop(0.5, '#5e4a20');
  grd.addColorStop(1, '#3a3018');
  g.fillStyle = grd; g.fill();
  g.strokeStyle = 'rgba(20,16,8,.55)'; g.lineWidth = 1;
  g.beginPath(); g.moveTo(0, -size * 0.4); g.lineTo(0, size * 0.42); g.stroke();
  return spriteTexture(c);
}

/** Lens dirt: smeared arcs + dust motes, multiplied into bloom for that anamorphic grime. */
function lensDirt(size = 512) {
  const [c, g] = canvas2d(size);
  g.fillStyle = '#000'; g.fillRect(0, 0, size, size);
  let s = 91;
  const rnd = () => (s = (s * 48271) % 2147483647) / 2147483647;
  g.globalCompositeOperation = 'lighter';
  for (let i = 0; i < 130; i++) {
    const x = rnd() * size, y = rnd() * size, r = 2 + rnd() * 26;
    const grd = g.createRadialGradient(x, y, 0, x, y, r);
    const a = 0.05 + rnd() * 0.4;
    grd.addColorStop(0, `rgba(255,240,220,${a})`);
    grd.addColorStop(1, 'rgba(255,240,220,0)');
    g.fillStyle = grd; g.beginPath(); g.arc(x, y, r, 0, Math.PI * 2); g.fill();
  }
  for (let i = 0; i < 16; i++) {
    g.save();
    g.translate(rnd() * size, rnd() * size);
    g.rotate(rnd() * Math.PI);
    g.scale(1, 0.08 + rnd() * 0.2);
    const r = 30 + rnd() * 130;
    const grd = g.createRadialGradient(0, 0, 0, 0, 0, r);
    grd.addColorStop(0, `rgba(230,235,255,${0.07 + rnd() * 0.16})`);
    grd.addColorStop(1, 'rgba(230,235,255,0)');
    g.fillStyle = grd; g.beginPath(); g.arc(0, 0, r, 0, Math.PI * 2); g.fill();
    g.restore();
  }
  const t = spriteTexture(c, { srgb: false });
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  return t;
}

/* ── the library ─────────────────────────────────────────────────────── */

export function buildTextures() {
  const T = {};

  // Weathered granite blocks — castle, bridges, temple, statues.
  T.stone = forge('stone', {
    size: 256, repeat: 1, normalStrength: 2.0,
    sample: (u, v, n) => {
      const brick = Math.max(
        smooth(0.06, 0.16, Math.abs(((v * 6) % 1) - 0.5)),
        0,
      );
      const row = Math.floor(v * 6);
      const off = row % 2 ? 0.5 : 0;
      const mortarV = 1 - smooth(0.0, 0.055, Math.abs(((v * 6) % 1) - 0.5) * -1 + 0.5);
      const mortarU = 1 - smooth(0.0, 0.05, Math.min(((u * 4 + off) % 1), 1 - ((u * 4 + off) % 1)));
      const mortar = Math.max(mortarU, 1 - brick);
      const grain = n.fbm(u * 9, v * 9, 9, 5, 11);
      const spots = n.worley(u * 12, v * 12, 12, 7);
      let base = 0.52 + grain * 0.20 + spots * 0.08;
      base *= 1 - mortar * 0.35;
      const moss = Math.max(0, n.fbm(u * 4 + 3, v * 4, 4, 4, 31) - 0.55) * 1.6;
      const r = base * 1.02 - moss * 0.10;
      const g = base * 1.00 - moss * 0.02;
      const b = base * 0.94 - moss * 0.06;
      const h = (grain * 0.55 + (1 - spots) * 0.2) * (1 - mortar) + mortar * 0.05;
      return [r, g, b, h, 0.62 + grain * 0.26 - moss * 0.1];
    },
  });

  // Volcanic basalt — terrain rock, cliffs, boulders, crater walls.
  T.rock = forge('rock', {
    size: 512, repeat: 1, normalStrength: 3.2,
    sample: (u, v, n) => {
      // Primary columnar basalt jointing & angular rock facets
      const w1 = n.worley(u * 12, v * 12, 12, 3);
      const w2 = n.worley(u * 28, v * 28, 28, 19);
      const f1 = n.fbm(u * 16, v * 16, 16, 6, 5);
      const f2 = n.fbm(u * 45, v * 45, 45, 4, 37);

      const crack = 1 - smooth(0.0, 0.12, w1);
      const microFacet = 1 - smooth(0.0, 0.18, w2);

      // Base volcanic slate/charcoal dark stone
      let base = 0.26 + f1 * 0.18 + f2 * 0.08;
      base *= 1 - crack * 0.45;

      // Geological mineral staining: iron oxide rust & sulfur fumarole deposits
      const rust = Math.max(0, n.fbm(u * 4, v * 4 + 7, 4, 4, 71) - 0.48) * 1.8;
      const sulfur = Math.max(0, n.fbm(u * 8 + 12, v * 8, 8, 4, 93) - 0.55) * 2.1;

      // Obsidian glass reflectivity (very smooth low roughness on sharp facets)
      const obsidianFacet = Math.pow(w1, 3.0);
      const roughness = clamp01(0.85 - obsidianFacet * 0.45 + f2 * 0.12);

      const r = base * 0.95 + rust * 0.24 + sulfur * 0.20;
      const g = base * 0.90 + rust * 0.08 + sulfur * 0.22;
      const b = base * 0.88 + rust * 0.02 + sulfur * 0.05;

      const h = f1 * 0.45 + (1 - w1) * 0.38 + microFacet * 0.17;
      return [r, g, b, h, roughness];
    },
  });

  // Volcanic tephra / fine fissured ash beds with thermal heat potential.
  T.ash = forge('ash', {
    size: 512, repeat: 1, normalStrength: 1.8,
    sample: (u, v, n) => {
      const f = n.fbm(u * 14, v * 14, 14, 6, 17);
      const g = n.fbm(u * 40, v * 40, 40, 4, 23);
      const w = n.worley(u * 9, v * 9, 9, 89);
      const crack = 1 - smooth(0.0, 0.08, w);

      const base = 0.22 + f * 0.14 + g * 0.06 - crack * 0.08;
      const roughness = 0.92 - g * 0.15;
      return [base * 1.02, base * 0.96, base * 0.94, f * 0.6 + g * 0.25 + (1 - w) * 0.15, roughness];
    },
  });

  // Dry cracked earth / dirt roads.
  T.dirt = forge('dirt', {
    size: 256, repeat: 1, normalStrength: 1.3,
    sample: (u, v, n) => {
      const f = n.fbm(u * 8, v * 8, 8, 5, 41);
      const w = n.worley(u * 5, v * 5, 5, 43);
      const base = 0.42 + f * 0.18;
      const crack = 1 - smooth(0.0, 0.07, w);
      return [
        base * 1.18 - crack * 0.05, base * 0.94 - crack * 0.04, base * 0.70 - crack * 0.03,
        f * 0.6 + w * 0.3, 0.86 + f * 0.1,
      ];
    },
  });

  // Bark — strong vertical anisotropy.
  T.bark = forge('bark', {
    size: 256, repeat: 1, normalStrength: 2.6,
    sample: (u, v, n) => {
      const stretch = n.fbm(u * 14, v * 2.2, 14, 5, 61);
      const grooves = n.fbm(u * 26, v * 3.4, 26, 3, 67);
      const base = 0.32 + stretch * 0.16 + grooves * 0.06;
      return [base * 1.22, base * 0.94, base * 0.72, stretch * 0.7 + grooves * 0.3, 0.82 + stretch * 0.15];
    },
  });

  // Timber planks for cottages and bridges.
  T.wood = forge('wood', {
    size: 256, repeat: 1, normalStrength: 1.8,
    sample: (u, v, n) => {
      const plank = Math.floor(v * 8);
      const seam = 1 - smooth(0.0, 0.045, Math.min((v * 8) % 1, 1 - ((v * 8) % 1)));
      const grain = n.fbm(u * 22 + plank * 7, v * 3, 22, 4, 83);
      const shade = 0.5 + hash2i(plank, 3, 8, 97) * 0.5;
      const base = (0.38 + grain * 0.18) * shade;
      return [
        base * 1.28 - seam * 0.06, base * 0.92 - seam * 0.05, base * 0.62 - seam * 0.04,
        grain * 0.6 - seam * 0.4 + 0.4, 0.72 + grain * 0.2,
      ];
    },
  });

  // Thatch roofing — matted straw.
  T.thatch = forge('thatch', {
    size: 256, repeat: 1, normalStrength: 2.2,
    sample: (u, v, n) => {
      const straw = n.fbm(u * 4, v * 40, 40, 4, 103);
      const clump = n.fbm(u * 7, v * 7, 7, 4, 107);
      const base = 0.40 + straw * 0.18 + clump * 0.08;
      return [base * 1.35, base * 1.05, base * 0.58, straw * 0.75 + clump * 0.25, 0.9 - straw * 0.1];
    },
  });

  // Fired clay roof tiles.
  T.tile = forge('tile', {
    size: 256, repeat: 1, normalStrength: 2.2,
    sample: (u, v, n) => {
      const wave = Math.abs(Math.sin(u * Math.PI * 10));
      const row = Math.floor(v * 12);
      const seam = 1 - smooth(0, 0.06, Math.min((v * 12) % 1, 1 - ((v * 12) % 1)));
      const g = n.fbm(u * 10, v * 10, 10, 4, 113);
      const base = (0.34 + g * 0.14) * (0.62 + wave * 0.5);
      return [
        base * 1.5 - seam * 0.05, base * 0.72, base * 0.55,
        wave * 0.55 + g * 0.3 - seam * 0.35, 0.7 + g * 0.2,
      ];
    },
  });

  // Lime plaster with exposed daub.
  T.plaster = forge('plaster', {
    size: 256, repeat: 1, normalStrength: 1.1,
    sample: (u, v, n) => {
      const f = n.fbm(u * 12, v * 12, 12, 5, 127);
      const patch = Math.max(0, n.fbm(u * 3, v * 3, 3, 3, 131) - 0.52) * 2.2;
      const base = 0.64 + f * 0.14 - patch * 0.20;
      return [base * 1.06, base * 0.99, base * 0.88, f * 0.5 + patch * 0.4, 0.7 + f * 0.2];
    },
  });

  // Dragon hide: overlapping volcanic obsidian keeled scales & armor scutes.
  T.scale = forge('scale', {
    // normalStrength 3.8 (was) plus the material's own normalScale multiplier
    // on top compounded into wildly over-perturbed normals — every scale
    // facet caught light at a near-random angle, which is exactly what
    // "sparkly chainmail" is: specular aliasing from a normal map several
    // times stronger than it needs to be.
    size: 512, repeat: 1, normalStrength: 1.5,
    sample: (u, v, n) => {
      // Hexagonal offset grid of overlapping keeled scales
      const su = u * 48, sv = v * 32;
      const row = Math.floor(sv);
      const off = row % 2 ? 0.5 : 0;
      const cu = (su + off) % 1, cv = sv % 1;
      const d = Math.hypot((cu - 0.5) * 1.1, (cv - 0.5) * 1.6);

      const scaleMask = 1 - smooth(0.28, 0.54, d);
      const keel = Math.pow(Math.max(0, 1.0 - Math.abs(cu - 0.5) * 3.4), 2.2) * scaleMask;

      const fbmFine = n.fbm(u * 55, v * 55, 55, 4, 149);
      const fbmMacro = n.fbm(u * 6, v * 6, 6, 4, 151);

      // Deep volcanic obsidian charcoal color
      let base = 0.14 + fbmMacro * 0.10 + fbmFine * 0.04;
      base *= 0.6 + scaleMask * 0.45;

      const interScaleGaps = 1.0 - scaleMask;
      const heatGlow = Math.max(0, fbmMacro - 0.55) * 2.2 * interScaleGaps;

      // Obsidian glass reflectivity: glassy smooth on scale facets, rougher between scales
      const roughness = clamp01(0.72 - scaleMask * 0.42 - keel * 0.18 + fbmFine * 0.1);

      const r = base * 0.85 + heatGlow * 0.38;
      const g = base * 0.72 + heatGlow * 0.10;
      const b = base * 0.78 + heatGlow * 0.03;

      const h = scaleMask * 0.55 + keel * 0.35 + fbmFine * 0.10;
      return [r, g, b, h, roughness];
    },
  });

  // Banner cloth — a coarse weave.
  T.cloth = forge('cloth', {
    size: 256, repeat: 1, normalStrength: 1.2,
    sample: (u, v, n) => {
      const weave = (Math.sin(u * Math.PI * 90) * Math.sin(v * Math.PI * 90)) * 0.5 + 0.5;
      const f = n.fbm(u * 8, v * 8, 8, 4, 163);
      const wear = Math.max(0, n.fbm(u * 5 + 2, v * 5, 5, 4, 167) - 0.56) * 2.0;
      const base = 0.46 + weave * 0.10 + f * 0.10;
      return [base * 1.6 - wear * 0.3, base * 0.55, base * 0.42, weave * 0.5 + f * 0.5, 0.78];
    },
  });

  // Rippling water normal (colour channel unused).
  T.waterNormal = forge('waterNormal', {
    size: 256, repeat: 1, normalStrength: 1.0,
    sample: (u, v, n) => {
      const a = n.fbm(u * 6, v * 6, 6, 4, 181);
      const b = n.fbm(u * 14 + 3, v * 14, 14, 3, 191);
      return [0.2, 0.3, 0.4, a * 0.7 + b * 0.3, 0.05];
    },
  }).normalMap;

  T.glow  = glowSprite(128);
  T.flame = glowSprite(128, 'rgba(255,255,245,1)', 'rgba(255,150,50,.7)');
  T.smoke = smokeSprite(192);
  T.leaf  = leafSprite(64);
  T.dirtLens = lensDirt(512);

  return T;
}

function smooth(e0, e1, x) {
  const t = clamp01((x - e0) / (e1 - e0 || 1e-6));
  return t * t * (3 - 2 * t);
}

/** Small scanned-rock upgrade, with the procedural surface as an offline fallback. */
export async function loadScannedRock(T) {
  const loader = new THREE.TextureLoader();
  const base = new URL('../../assets/materials/', import.meta.url);
  const slots = [['map', 'rock-color.webp'], ['normalMap', 'rock-normal.webp'], ['roughnessMap', 'rock-roughness.webp']];
  const results = await Promise.allSettled(slots.map(async ([slot, file]) => {
    const texture = await loader.loadAsync(new URL(file, base).href);
    texture.colorSpace = slot === 'map' ? THREE.SRGBColorSpace : THREE.NoColorSpace;
    texture.wrapS = texture.wrapT = THREE.RepeatWrapping;
    texture.anisotropy = 4;
    texture.name = `scanned-rock-${slot}`;
    return [slot, texture];
  }));
  for (const result of results) {
    if (result.status !== 'fulfilled') continue;
    const [slot, texture] = result.value;
    T.rock[slot].dispose();
    T.rock[slot] = texture;
  }
}
