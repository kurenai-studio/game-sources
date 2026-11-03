// High-level effects vocabulary used by game code.
import { Rig } from './rig.js';
import { CrowdLayer } from './crowd.js';
import { ParticleLayer, LAND_BLOOD, LAND_CASING, LAND_ACID, syncBillboards } from './particles.js';
import { STAMP, SPRITE } from './textures.js';
import { rand, irand, pick, TAU, clamp } from '../core/util.js';

export const BLOOD = {
  red: { r: 0.115, g: 0.0025, b: 0.006, spray: [0.34, 0.012, 0.02] },
  dark: { r: 0.06, g: 0.003, b: 0.012, spray: [0.2, 0.012, 0.03] },
  acid: { r: 0.045, g: 0.075, b: 0.006, spray: [0.28, 0.42, 0.05] },
  ichor: { r: 0.008, g: 0.05, b: 0.055, spray: [0.05, 0.3, 0.3] },
};

const GIB_MAX = 220;

export class FX {
  constructor(stage, decals, spriteAtlas, tier) {
    this.stage = stage;
    this.decals = decals;
    const k = tier.particleScale;
    this.glow = new ParticleLayer(stage, spriteAtlas, Math.floor(5000 * k), true);
    this.soft = new ParticleLayer(stage, spriteAtlas, Math.floor(3000 * k), false);
    this.landed = this.landed.bind(this);
    this.buildGibs();
    this.onClink = null;
    this.bloodRed = BLOOD.red;
  }

  buildGibs() {
    const r = new Rig();
    r.blob([0, 0, 0], [0.5, 0.36, 0.42], { color: '#b03024', color2: '#4a0d0a', rough: 0.25, rings: 4, segs: 6 });
    r.blob([0.26, 0.1, 0.1], [0.26, 0.2, 0.22], { color: '#d9c8b0', rough: 0.4, rings: 3, segs: 5 });
    this.gibLayer = new CrowdLayer(this.stage, null, r.build(), GIB_MAX, { fallX: TAU, squash: 1, height: 0, bob: 0, sway: 0, hip: 9, glowPower: 0 });
    this.gibLayer.mesh.castShadow = false;
    this.gibs = [];
    for (let i = 0; i < GIB_MAX; i++) this.gibs.push({ x: 0, y: 0, z: 0, vx: 0, vy: 0, vz: 0, spin: 0, t: 0, s: 0, yaw: 0, b: null, on: false });
    this.gibFree = 0;
  }

  clear() {
    this.glow.clear(); this.soft.clear();
    for (const g of this.gibs) g.on = false;
  }

  landed(kind, x, z, size, r, g, b) {
    const d = this.decals;
    if (kind === LAND_BLOOD) {
      d.stamp(STAMP.drops, x, z, size * 9, size * 9, rand(TAU), r * 0.28, g * 0.28, b * 0.28, 0.85, 0.05);
    } else if (kind === LAND_CASING) {
      d.stamp(STAMP.casing, x, z, 0.22, 0.09, rand(TAU), 0.55, 0.38, 0.1, 1);
      this.onClink?.();
    } else if (kind === LAND_ACID) {
      d.stamp(pick([STAMP.splat0, STAMP.splat2]), x, z, size * 7, size * 7, rand(TAU), 0.045, 0.075, 0.006, 0.8, 0.02);
    }
  }

  // Blood on a hit: a directional spray on the ground, plus droplets that land and stamp later.
  hit(x, z, dx, dz, blood, power) {
    const d = this.decals, a = Math.atan2(dz, dx);
    const size = rand(1.6, 2.8) * (0.7 + power * 0.8);
    d.stamp(pick([STAMP.spray0, STAMP.spray1]), x + dx * size * 0.32, z + dz * size * 0.32, size, size * 0.85, a + rand(-0.35, 0.35), blood.r, blood.g, blood.b, 0.82, 0.14);
    const n = Math.min(10, 2 + Math.floor(power * 4));
    const [r, g, b] = blood.spray;
    for (let i = 0; i < n; i++) {
      const s = rand(4, 13), sp = rand(-0.55, 0.55), c = Math.cos(a + sp), n2 = Math.sin(a + sp);
      this.soft.spawn(x, rand(0.5, 1.1), z, c * s, rand(1.5, 5), n2 * s, 1.5, rand(0.07, 0.17), 0.05, r, g, b, 1, SPRITE.drop, { grav: 18, drag: 1.2, stretch: 0.016, land: LAND_BLOOD });
    }
    this.soft.spawn(x, 0.9, z, dx * 1.5, 0.8, dz * 1.5, 0.3, 0.3, 1.2, r * 0.7, g * 0.7, b * 0.7, 0.5, SPRITE.puff, { drag: 3 });
  }

  // A kill leaves a pool; heavy kills add a burst of gibs.
  death(x, z, dx, dz, blood, scale, gibs) {
    const d = this.decals, size = rand(3.0, 4.6) * scale;
    d.stamp(irand(STAMP.splat0, STAMP.splat3), x, z, size, size, rand(TAU), blood.r, blood.g, blood.b, 0.94, 0.5);
    d.stamp(STAMP.drops, x + dx, z + dz, size * 1.5, size * 1.5, rand(TAU), blood.r * 0.8, blood.g * 0.8, blood.b * 0.8, 0.75);
    this.burst(x, z, blood, 8 + Math.floor(scale * 4), 1);
    for (let i = 0; i < gibs; i++) this.gib(x, z, dx, dz, blood, scale);
  }

  burst(x, z, blood, n, power) {
    const [r, g, b] = blood.spray;
    for (let i = 0; i < n; i++) {
      const a = rand(TAU), s = rand(2, 9) * power;
      this.soft.spawn(x, rand(0.4, 1.2), z, Math.cos(a) * s, rand(2, 7), Math.sin(a) * s, 1.4, rand(0.08, 0.2), 0.06, r, g, b, 1, SPRITE.drop, { grav: 18, drag: 0.9, stretch: 0.014, land: LAND_BLOOD });
    }
  }

  gib(x, z, dx, dz, blood, scale) {
    let g = null;
    for (let i = 0; i < GIB_MAX; i++) {
      const c = this.gibs[(this.gibFree + i) % GIB_MAX];
      if (!c.on) { g = c; this.gibFree = (this.gibFree + i + 1) % GIB_MAX; break; }
    }
    if (!g) return;
    const a = Math.atan2(dz, dx) + rand(-1.1, 1.1), s = rand(3, 11);
    g.on = true; g.x = x; g.y = rand(0.5, 1.1); g.z = z;
    g.vx = Math.cos(a) * s; g.vz = Math.sin(a) * s; g.vy = rand(4, 11);
    g.spin = rand(1, 3); g.t = rand(1); g.s = rand(0.2, 0.42) * clamp(scale, 0.7, 2); g.yaw = rand(TAU); g.b = blood;
  }

  updateGibs(dt) {
    const L = this.gibLayer;
    L.begin();
    for (const g of this.gibs) {
      if (!g.on) continue;
      g.vy -= 26 * dt;
      g.x += g.vx * dt; g.y += g.vy * dt; g.z += g.vz * dt;
      g.t = (g.t + g.spin * dt) % 1;
      if (g.y < 0.08) {
        g.on = false;
        const s = rand(0.8, 1.7), b = g.b;
        this.decals.stamp(pick([STAMP.splat1, STAMP.splat3, STAMP.drops]), g.x, g.z, s * 1.2, s * 1.2, rand(TAU), b.r, b.g, b.b, 0.9, 0.1);
        this.decals.stamp(STAMP.dot, g.x, g.z, g.s * 1.6, g.s * 1.2, rand(TAU), b.r * 0.5, b.g * 0.5, b.b * 0.5, 1);
        continue;
      }
      L.push(g.x, g.y, g.z, g.yaw, 0, g.s, 0, g.t, 1, 1, 1, 0);
    }
    L.end();
  }

  muzzle(x, y, z, dx, dz, col, power, rate = 4) {
    const [r, g, b] = col;
    this.glow.spawn(x, y, z, 0, 0, 0, 0.05, 1 * power, 0.4 * power, r * 3, g * 2.8, b * 2.6, 1, SPRITE.spark);
    this.glow.spawn(x + dx * 0.4, y, z + dz * 0.4, dx * 2, 0, dz * 2, 0.05, 0.3 * power, 0.14, r * 5, g * 4.4, b * 3.6, 1, SPRITE.dot, { stretch: 0.3 });
    // Fast guns fire many puffs a second, so each one has to be fainter or they stack into a glow.
    this.soft.spawn(x, y, z, dx * 3, 0.5, dz * 3, 0.42, 0.24, 0.9 * power, 0.42, 0.4, 0.38, Math.min(0.13, 0.5 / rate), SPRITE.smoke, { drag: 3, spin: rand(-1, 1), rot: rand(TAU) });
    this.stage.flash(x, y + 0.6, z, `rgb(${Math.round(r * 255)},${Math.round(g * 255)},${Math.round(b * 255)})`, 95 * power, 15, 20);
  }

  shell(x, y, z, dx, dz) {
    const s = rand(3, 5);
    this.soft.spawn(x, y, z, -dz * s + dx * rand(-1, 1), rand(3, 5), dx * s + dz * rand(-1, 1), 1.2, 0.1, 0.1, 0.85, 0.62, 0.2, 1, SPRITE.drop, { grav: 20, stretch: 0.02, land: LAND_CASING });
  }

  sparks(x, z, n, r, g, b, speed = 11) {
    for (let i = 0; i < n; i++) {
      const a = rand(TAU), s = rand(0.3, 1) * speed;
      this.glow.spawn(x, rand(0.5, 1.2), z, Math.cos(a) * s, rand(1, 6), Math.sin(a) * s, rand(0.18, 0.5), 0.09, 0.03, r, g, b, 1, SPRITE.dot, { grav: 15, drag: 1.4, stretch: 0.03 });
    }
  }

  explosion(x, z, radius, kind = 'fire') {
    const d = this.decals;
    const hot = kind === 'plasma' ? [0.5, 0.8, 3] : kind === 'acid' ? [0.9, 2.4, 0.4] : [3.4, 1.5, 0.35];
    d.stamp(STAMP.scorch, x, z, radius * 3, radius * 3, rand(TAU), 0.012, 0.01, 0.009, 0.92);
    d.stamp(STAMP.crater, x, z, radius * 1.5, radius * 1.5, rand(TAU), 0.008, 0.007, 0.006, 0.7);
    this.glow.spawn(x, 1.5, z, 0, 0, 0, 0.13, radius * 1.5, radius * 2.3, hot[0] * 1.5, hot[1] * 1.5, hot[2] * 1.5, 1, SPRITE.dot);
    this.glow.spawn(x, 0.14, z, 0, 0, 0, 0.42, radius * 0.6, radius * 3, hot[0] * 0.8, hot[1] * 0.8, hot[2] * 0.8, 1, SPRITE.ring, { flat: true });
    const n = Math.floor(14 + radius * 7);
    for (let i = 0; i < n; i++) {
      const a = rand(TAU), s = rand(0.2, 1) * radius * 3.4;
      this.glow.spawn(x, rand(0.3, 1.6), z, Math.cos(a) * s, rand(0.5, 3.4), Math.sin(a) * s, rand(0.28, 0.62), rand(0.8, 1.7) * Math.min(radius, 3), 0.25, hot[0], hot[1], hot[2], 0.75, SPRITE.flame, { drag: 3.4, spin: rand(-3, 3), rot: rand(TAU) });
    }
    for (let i = 0; i < n * 0.7; i++) {
      const a = rand(TAU), s = rand(0.1, 1) * radius * 1.6;
      this.soft.spawn(x + Math.cos(a), 0.8, z + Math.sin(a), Math.cos(a) * s, rand(1, 3), Math.sin(a) * s, rand(0.9, 2), rand(1, 1.8), rand(2.6, 4.6), 0.1, 0.09, 0.085, 0.42, SPRITE.smoke, { drag: 1.8, rot: rand(TAU), spin: rand(-0.6, 0.6) });
    }
    this.sparks(x, z, Math.floor(16 + radius * 8), hot[0] * 2, hot[1] * 2, hot[2] * 2, radius * 7);
    this.stage.flash(x, 2.4, z, kind === 'plasma' ? '#7fb6ff' : kind === 'acid' ? '#c8ff5a' : '#ff9a4a', 240 * Math.min(radius, 4) / 3, 20, 6);
    this.stage.shake(clamp(radius * 0.11, 0.1, 0.5));
  }

  ring(x, z, radius, r, g, b, life = 0.5) {
    this.glow.spawn(x, 0.16, z, 0, 0, 0, life, 0.5, radius * 2.2, r, g, b, 1, SPRITE.ring, { flat: true });
  }

  // Straight glowing line. Velocity only sets the streak axis; `stretch` turns it into length.
  beam(x0, z0, x1, z1, y, width, r, g, b, life) {
    const dx = x1 - x0, dz = z1 - z0, l = Math.sqrt(dx * dx + dz * dz) || 1;
    const k = Math.ceil(l / 5), ux = dx / l, uz = dz / l, seg = l / k;
    for (let i = 0; i < k; i++) {
      const t = (i + 0.5) / k;
      this.glow.spawn(x0 + dx * t, y, z0 + dz * t, ux * 0.001, 0, uz * 0.001, life, width, width * 0.2, r, g, b, 1, SPRITE.dot, { stretch: seg * 1000 });
    }
  }

  // Jagged lightning between two points, drawn as short streaks.
  arc(x0, z0, x1, z1, r, g, b) {
    const seg = 5;
    let px = x0, pz = z0;
    const nx = -(z1 - z0), nz = x1 - x0;
    for (let i = 1; i <= seg; i++) {
      const t = i / seg, o = i < seg ? rand(-0.11, 0.11) : 0;
      const qx = x0 + (x1 - x0) * t + nx * o, qz = z0 + (z1 - z0) * t + nz * o;
      this.beam(px, pz, qx, qz, 1.1, 0.26, r, g, b, rand(0.07, 0.14));
      px = qx; pz = qz;
    }
  }

  shardBurst(x, z) {
    const a = rand(TAU), s = rand(3, 10);
    this.soft.spawn(x, rand(0.4, 1.2), z, Math.cos(a) * s, rand(3, 8), Math.sin(a) * s, rand(0.5, 1), rand(0.25, 0.5), 0.1, 0.65, 0.85, 1, 1, SPRITE.shard, { grav: 18, spin: rand(-12, 12), rot: rand(TAU) });
  }

  acidDrop(x, z) {
    const a = rand(TAU), s = rand(2, 6);
    this.soft.spawn(x, 0.5, z, Math.cos(a) * s, rand(2, 5), Math.sin(a) * s, 1, 0.16, 0.06, 0.6, 0.9, 0.12, 1, SPRITE.drop, { grav: 16, land: LAND_ACID });
  }

  flames(x, z, n, spread = 0.4) {
    for (let i = 0; i < n; i++) {
      this.glow.spawn(x + rand(-spread, spread), rand(0.2, 1.1), z + rand(-spread, spread), rand(-0.4, 0.4), rand(1.6, 3.6), rand(-0.4, 0.4), rand(0.24, 0.5), rand(0.5, 0.9), 0.12, 2, 0.72, 0.12, 0.6, SPRITE.flame, { spin: rand(-2, 2), rot: rand(TAU) });
    }
  }

  // The tip of a flame stream: a little smoke, the odd ember, and a scorch on the ground.
  flameOut(x, z) {
    if (Math.random() < 0.3) this.soft.spawn(x, 1, z, rand(-0.5, 0.5), rand(0.8, 1.8), rand(-0.5, 0.5), rand(0.5, 1), 0.7, 1.8, 0.09, 0.08, 0.08, 0.3, SPRITE.smoke, { rot: rand(TAU), spin: rand(-1, 1) });
    if (Math.random() < 0.25) this.glow.spawn(x, 1, z, rand(-2, 2), rand(1, 4), rand(-2, 2), rand(0.3, 0.7), 0.08, 0.03, 3, 1, 0.2, 1, SPRITE.dot, { grav: 4, drag: 1 });
    if (Math.random() < 0.08) this.decals.stamp(STAMP.scorch, x, z, 1.6, 1.6, rand(TAU), 0.012, 0.01, 0.009, 0.5);
  }

  update(dt) {
    this.updateGibs(dt);
    this.glow.update(dt, this.landed);
    this.soft.update(dt, this.landed);
    syncBillboards(this.stage.camera);
  }

  commit() { this.glow.commit(); this.soft.commit(); }
}
