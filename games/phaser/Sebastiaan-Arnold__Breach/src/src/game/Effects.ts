import Phaser from 'phaser';
import { TILE } from '../config';

const GLOW_KEY = 'soft-glow';
const MAX_MOVING_CASINGS = 60;
/** Dark, desaturated red: blood should read clearly without being lurid. */
const BLOOD = 0x7a1116;
const POOL_GROW = 3.5;

interface Hole { x: number; y: number; r: number }
interface Casing { x: number; y: number; vx: number; vy: number; rot: number; vr: number; shell: boolean }
interface Particle {
  x: number; y: number; vx: number; vy: number; age: number; life: number; color: number; size: number; streak: boolean;
  /** If set, the particle leaves a stain of this radius where it lands. */
  stain?: number;
  /** Dust: a soft puff that grows as it fades. */
  puff?: boolean;
}
interface Stain { x: number; y: number; r: number }
interface Shard { x: number; y: number; a: number }
const GLASS = 0xbfe3ff;
interface Pool { x: number; y: number; age: number; blobs: { dx: number; dy: number; r: number }[] }

/**
 * Small physical details: bullet holes that stay, sparks and cardboard chips, brass casings
 * that skid to a stop, blood, and the brief light of a muzzle flash. Everything except the
 * light sits below the fog, so it is only seen where the operator can see.
 *
 * Anything permanent (holes, stains, casings at rest) is baked once into a decal texture, so a
 * long firefight doesn't make every frame more expensive.
 */
export class Effects {
  private newHoles: Hole[] = [];
  private newStains: Stain[] = [];
  private newShards: Shard[] = [];
  private pools: Pool[] = [];
  private casings: Casing[] = [];
  private particles: Particle[] = [];
  private decals: Phaser.GameObjects.RenderTexture;
  private baker: Phaser.GameObjects.Graphics;
  private gfx: Phaser.GameObjects.Graphics;
  private light: Phaser.GameObjects.Image;
  private flash = 0;
  private flashLen = 0.06;

  constructor(scene: Phaser.Scene, worldW: number, worldH: number, scale: number, decalDepth: number, lightDepth: number) {
    ensureGlowTexture(scene);
    this.decals = scene.add.renderTexture(0, 0, worldW * scale, worldH * scale).setOrigin(0).setScale(1 / scale).setDepth(decalDepth);
    this.baker = scene.make.graphics({}, false).setScale(scale);
    this.gfx = scene.add.graphics().setDepth(decalDepth);
    this.light = scene.add.image(0, 0, GLOW_KEY).setDepth(lightDepth).setBlendMode(Phaser.BlendModes.ADD)
      .setTint(0xffc46b).setVisible(false);
  }

  bulletHole(x: number, y: number, dx: number, dy: number): void {
    this.newHoles.push({ x: x - dx * 0.8, y: y - dy * 0.8, r: 1.4 + Math.random() * 0.8 });
    for (let i = 0; i < 4; i++) {
      const a = Math.atan2(-dy, -dx) + Phaser.Math.FloatBetween(-0.9, 0.9);
      const v = Phaser.Math.FloatBetween(90, 220);
      this.particles.push({ x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, age: 0, life: 0.12, color: 0xffd58a, size: 1.2, streak: true });
    }
    for (let i = 0; i < 3; i++) {
      const a = Math.atan2(-dy, -dx) + Phaser.Math.FloatBetween(-1.2, 1.2);
      const v = Phaser.Math.FloatBetween(20, 60);
      this.particles.push({ x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, age: 0, life: 0.5, color: 0x9ca3af, size: 1.6, streak: false });
    }
  }

  /** A pane shattering: a burst of glass along the shot, and shards left on the floor. */
  glassBreak(x: number, y: number, dx: number, dy: number): void {
    for (let i = 0; i < 16; i++) {
      const a = Math.atan2(dy, dx) + Phaser.Math.FloatBetween(-1.1, 1.1);
      const v = Phaser.Math.FloatBetween(40, 200);
      this.particles.push({ x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, age: 0, life: Phaser.Math.FloatBetween(0.2, 0.5), color: GLASS, size: 1.5, streak: i % 3 === 0 });
    }
    for (let i = 0; i < 14; i++) {
      const d = Phaser.Math.FloatBetween(2, 26), a = Math.atan2(dy, dx) + Phaser.Math.FloatBetween(-1.4, 1.4);
      this.newShards.push({ x: x + Math.cos(a) * d, y: y + Math.sin(a) * d, a: Math.random() * Math.PI });
    }
  }

  cardboardHit(x: number, y: number, dx: number, dy: number): void {
    for (let i = 0; i < 6; i++) {
      const a = Math.atan2(dy, dx) + Phaser.Math.FloatBetween(-0.7, 0.7);
      const v = Phaser.Math.FloatBetween(40, 140);
      this.particles.push({ x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, age: 0, life: 0.35, color: 0xc8a46a, size: 1.8, streak: false });
    }
  }

  /** A hit on a person: a short spray in the bullet's direction that stains the floor. */
  bloodHit(x: number, y: number, dx: number, dy: number): void {
    for (let i = 0; i < 7; i++) {
      const a = Math.atan2(dy, dx) + Phaser.Math.FloatBetween(-0.45, 0.45);
      const v = Phaser.Math.FloatBetween(60, 170);
      this.particles.push({
        x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, age: 0, life: Phaser.Math.FloatBetween(0.12, 0.28),
        color: BLOOD, size: Phaser.Math.FloatBetween(1.4, 2.4), streak: false, stain: Phaser.Math.FloatBetween(0.8, 1.8),
      });
    }
  }

  /** A pool that slowly spreads under someone who is down. */
  bloodPool(x: number, y: number): void {
    const blobs = Array.from({ length: 6 }, () => ({
      dx: Phaser.Math.FloatBetween(-7, 7), dy: Phaser.Math.FloatBetween(-7, 7), r: Phaser.Math.FloatBetween(6, 11),
    }));
    this.pools.push({ x, y, age: 0, blobs });
  }

  /** Ejects a casing to the operator's right. */
  casing(x: number, y: number, facing: number, shell: boolean): void {
    const a = facing + Math.PI / 2 + Phaser.Math.FloatBetween(-0.35, 0.25);
    const v = Phaser.Math.FloatBetween(90, 150);
    this.casings.push({
      x: x + Math.cos(facing) * 6, y: y + Math.sin(facing) * 6,
      vx: Math.cos(a) * v - Math.cos(facing) * 20, vy: Math.sin(a) * v - Math.sin(facing) * 20,
      rot: Math.random() * Math.PI, vr: Phaser.Math.FloatBetween(-20, 20), shell,
    });
    if (this.casings.length > MAX_MOVING_CASINGS) this.casings.shift();
  }

  muzzle(x: number, y: number, heavy: boolean): void {
    this.flash = this.flashLen = 0.06;
    this.light.setPosition(x, y).setScale(heavy ? 1.6 : 1.2).setVisible(true);
  }

  /**
   * A breach charge going off at (x, y): a hard flash, debris both ways, a cloud of dust, and
   * the hole baked into the decals: bare floor and rubble where the wall stood.
   */
  breach(x: number, y: number, tiles: readonly { tx: number; ty: number }[], floor: number, wall: number): void {
    this.flash = this.flashLen = 0.35;
    this.light.setPosition(x, y).setScale(6).setVisible(true);
    for (let i = 0; i < 46; i++) {
      const a = Math.random() * Math.PI * 2, v = Phaser.Math.FloatBetween(80, 340);
      this.particles.push({ x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, age: 0, life: Phaser.Math.FloatBetween(0.3, 0.8), color: i % 3 ? wall : 0xd6d3d1, size: Phaser.Math.FloatBetween(1.6, 3.6), streak: i % 5 === 0 });
    }
    for (let i = 0; i < 26; i++) {
      const a = Math.random() * Math.PI * 2, v = Phaser.Math.FloatBetween(10, 70);
      this.particles.push({ x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, age: 0, life: Phaser.Math.FloatBetween(1.4, 2.6), color: 0x9ca3af, size: Phaser.Math.FloatBetween(8, 16), streak: false, puff: true });
    }
    const b = this.baker;
    b.clear();
    for (const t of tiles) {
      b.fillStyle(floor, 1);
      b.fillRect(t.tx * TILE, t.ty * TILE, TILE, TILE);
    }
    b.fillStyle(0x000000, 0.3);
    b.fillCircle(x, y, 26);
    for (let i = 0; i < 34; i++) {
      const r = Math.random() * 30, a = Math.random() * Math.PI * 2, sz = Phaser.Math.FloatBetween(2, 6);
      b.fillStyle(i % 4 ? wall : 0x6b7280, 0.95);
      b.fillRect(x + Math.cos(a) * r - sz / 2, y + Math.sin(a) * r - sz / 2, sz, sz * Phaser.Math.FloatBetween(0.6, 1.2));
    }
    this.decals.draw(b);
  }

  update(dt: number, solid: (tx: number, ty: number) => boolean): void {
    if (this.flash > 0) {
      this.flash -= dt;
      this.light.setAlpha(Math.max(0, this.flash / this.flashLen) * 0.55);
      if (this.flash <= 0) this.light.setVisible(false);
    }

    for (const c of this.casings) {
      const nx = c.x + c.vx * dt, ny = c.y + c.vy * dt;
      if (solid(Math.floor(nx / TILE), Math.floor(c.y / TILE))) c.vx *= -0.35;
      else c.x = nx;
      if (solid(Math.floor(c.x / TILE), Math.floor(ny / TILE))) c.vy *= -0.35;
      else c.y = ny;
      const drag = Math.exp(-5 * dt);
      c.vx *= drag;
      c.vy *= drag;
      c.rot += c.vr * dt;
      c.vr *= drag;
      if (Math.hypot(c.vx, c.vy) < 4) c.vx = c.vy = 0;
    }

    for (const p of this.pools) p.age += dt;

    this.particles = this.particles.filter((p) => {
      p.age += dt;
      if (p.age < p.life) return true;
      if (p.stain) this.newStains.push({ x: p.x, y: p.y, r: p.stain });
      return false;
    });

    // Bake anything that has come to rest.
    const resting = this.casings.filter((c) => c.vx === 0 && c.vy === 0);
    const settled = this.pools.filter((p) => p.age >= POOL_GROW);
    if (resting.length || settled.length || this.newHoles.length || this.newStains.length || this.newShards.length) {
      const b = this.baker;
      b.clear();
      for (const p of settled) drawPool(b, p);
      for (const st of this.newStains) drawStain(b, st);
      for (const h of this.newHoles) drawHole(b, h);
      for (const s of this.newShards) drawShard(b, s);
      for (const c of resting) drawCasing(b, c);
      this.decals.draw(b);
      this.newHoles = [];
      this.newStains = [];
      this.newShards = [];
      this.pools = this.pools.filter((p) => p.age < POOL_GROW);
      this.casings = this.casings.filter((c) => c.vx !== 0 || c.vy !== 0);
    }

    for (const p of this.particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= Math.exp(-4 * dt);
      p.vy *= Math.exp(-4 * dt);
    }
    this.draw();
  }

  private draw(): void {
    const g = this.gfx;
    g.clear();
    for (const p of this.pools) drawPool(g, p);
    for (const c of this.casings) drawCasing(g, c);
    for (const p of this.particles) {
      const a = 1 - p.age / p.life;
      if (p.puff) {
        g.fillStyle(p.color, a * 0.22);
        g.fillCircle(p.x, p.y, p.size * (1 + p.age));
      } else if (p.streak) {
        g.lineStyle(p.size, p.color, a);
        g.lineBetween(p.x, p.y, p.x - p.vx * 0.02, p.y - p.vy * 0.02);
      } else {
        g.fillStyle(p.color, a);
        g.fillRect(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size);
      }
    }
  }
}

function drawPool(g: Phaser.GameObjects.Graphics, p: Pool): void {
  const k = Phaser.Math.Easing.Cubic.Out(Math.min(1, p.age / POOL_GROW));
  g.fillStyle(BLOOD, 0.9);
  for (const b of p.blobs) g.fillCircle(p.x + b.dx * k, p.y + b.dy * k, Math.max(0.5, b.r * k));
  // A darker core where it is deepest.
  g.fillStyle(0x000000, 0.25);
  g.fillCircle(p.x, p.y, 6 * k);
}

function drawStain(g: Phaser.GameObjects.Graphics, s: Stain): void {
  g.fillStyle(BLOOD, 0.9);
  g.fillCircle(s.x, s.y, s.r);
}

function drawShard(g: Phaser.GameObjects.Graphics, s: Shard): void {
  g.fillStyle(GLASS, 0.55);
  g.fillTriangle(s.x, s.y, s.x + Math.cos(s.a) * 3, s.y + Math.sin(s.a) * 3, s.x + Math.cos(s.a + 2) * 2, s.y + Math.sin(s.a + 2) * 2);
}

function drawHole(g: Phaser.GameObjects.Graphics, h: Hole): void {
  g.fillStyle(0x000000, 0.25);
  g.fillCircle(h.x, h.y, h.r + 1.2);
  g.fillStyle(0x0b0b0b, 0.9);
  g.fillCircle(h.x, h.y, h.r);
}

function drawCasing(g: Phaser.GameObjects.Graphics, c: Casing): void {
  const len = c.shell ? 4.5 : 3, w = c.shell ? 2.2 : 1.4;
  const cos = Math.cos(c.rot), sin = Math.sin(c.rot);
  const hx = (cos * len) / 2, hy = (sin * len) / 2, wx = (-sin * w) / 2, wy = (cos * w) / 2;
  g.fillStyle(c.shell ? 0xb91c1c : 0xc9a227, 1);
  g.fillPoints([
    { x: c.x - hx - wx, y: c.y - hy - wy }, { x: c.x + hx - wx, y: c.y + hy - wy },
    { x: c.x + hx + wx, y: c.y + hy + wy }, { x: c.x - hx + wx, y: c.y - hy + wy },
  ], true);
}

function ensureGlowTexture(scene: Phaser.Scene): void {
  if (scene.textures.exists(GLOW_KEY)) return;
  const size = 128;
  const tex = scene.textures.createCanvas(GLOW_KEY, size, size)!;
  const ctx = tex.getContext();
  const grad = ctx.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
  grad.addColorStop(0, 'rgba(255,255,255,1)');
  grad.addColorStop(0.25, 'rgba(255,255,255,0.45)');
  grad.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, size, size);
  tex.refresh();
}
