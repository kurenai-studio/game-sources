import Phaser from 'phaser';
import { COLORS, TILE, VISION } from '../config';

const FALLOFF_KEY = 'fog-falloff';
const FALLOFF_SIZE = 256;
/**
 * The fog is drawn at half world resolution and smoothly upscaled: edges come out slightly soft
 * instead of hard and stepped, and it stays cheap on integrated GPUs.
 */
const RES = 0.5;

export interface FogLight {
  x: number;
  y: number;
  /** Vision range in px; the falloff reaches its maximum there. */
  range: number;
  /** 0..1: how much vision fades towards the edge of its range. */
  falloff: number;
  /** Alpha of the warm tint inside the vision cone. */
  warmth: number;
}

/**
 * Three layers of knowledge:
 *  - visible: inside the current vision polygons, lit and fading towards the edge of range
 *  - remembered: seen before, drawn dim; live entities are hidden there by their own check
 *  - unknown: never seen, pure black, not even walls
 *
 * `memory` accumulates every vision polygon ever drawn. Each frame `shade` is rebuilt: black,
 * memory cut out of it and filled back in at the remembered shade, then the current vision
 * (faded towards its range) cut out.
 *
 * Outdoors is always lit: streets, gardens and yards (and the outside of buildings) are never
 * fogged. Who is out there still depends on line of sight, which the scene handles.
 */
export class Fog {
  private memory: Phaser.GameObjects.RenderTexture;
  private vision: Phaser.GameObjects.RenderTexture;
  private shade: Phaser.GameObjects.RenderTexture;
  private brush: Phaser.GameObjects.Graphics;
  private falloff: Phaser.GameObjects.Image;
  private glow: Phaser.GameObjects.Graphics;
  private lit: Phaser.GameObjects.RenderTexture | null = null;

  /** @param litTiles tiles that are always lit (the exterior) */
  constructor(scene: Phaser.Scene, width: number, height: number, glowDepth: number, fogDepth: number, litTiles: readonly { tx: number; ty: number }[] = []) {
    ensureFalloffTexture(scene);
    const w = Math.ceil(width * RES), h = Math.ceil(height * RES);
    this.memory = scene.make.renderTexture({ x: 0, y: 0, width: w, height: h }, false).setOrigin(0);
    this.vision = scene.make.renderTexture({ x: 0, y: 0, width: w, height: h }, false).setOrigin(0);
    this.shade = scene.add.renderTexture(0, 0, w, h).setOrigin(0).setScale(1 / RES).setDepth(fogDepth);
    this.shade.texture.setFilter(Phaser.Textures.FilterMode.LINEAR);
    this.brush = scene.make.graphics({}, false).setScale(RES);
    this.falloff = scene.make.image({ key: FALLOFF_KEY }, false);
    this.glow = scene.add.graphics().setDepth(glowDepth);
    if (litTiles.length) {
      this.lit = scene.make.renderTexture({ x: 0, y: 0, width: w, height: h }, false).setOrigin(0);
      const g = scene.make.graphics({}, false).setScale(RES);
      g.fillStyle(0x000000, 1);
      for (const t of litTiles) g.fillRect(t.tx * TILE, t.ty * TILE, TILE, TILE);
      this.lit.draw(g);
      g.destroy();
    }
  }

  /**
   * @param polys current vision polygons (flat point arrays)
   * @param wallTiles wall tiles struck by vision rays this frame, so walls get remembered too
   */
  update(polys: readonly number[][], wallTiles: readonly { tx: number; ty: number }[], light: FogLight): void {
    // Black, so `memory` can be drawn straight back in as the remembered shade.
    const b = this.brush;
    b.clear();
    b.fillStyle(0x000000, 1);
    for (const p of polys) fillPoly(b, p);
    for (const t of wallTiles) b.fillRect(t.tx * TILE, t.ty * TILE, TILE, TILE);

    this.memory.draw(b);

    // Current vision, fading out towards the edge of its range.
    this.vision.clear();
    this.vision.draw(b);
    this.falloff.setPosition(light.x * RES, light.y * RES).setScale((light.range * 2 * RES) / FALLOFF_SIZE).setAlpha(light.falloff);
    this.vision.erase(this.falloff);

    const s = this.shade;
    s.clear();
    s.fill(COLORS.void, 1);
    s.erase(this.memory);
    // Drawing one render texture into another uses the source object's own alpha.
    this.memory.setAlpha(VISION.rememberedShade);
    s.draw(this.memory);
    this.memory.setAlpha(1);
    s.erase(this.vision);
    if (this.lit) s.erase(this.lit);

    const g = this.glow;
    g.clear();
    g.fillStyle(COLORS.visionWarm, light.warmth);
    if (polys[0]) fillPoly(g, polys[0]);
  }
}

/** A radial ramp: transparent in the middle, opaque at the rim. */
function ensureFalloffTexture(scene: Phaser.Scene): void {
  if (scene.textures.exists(FALLOFF_KEY)) return;
  const tex = scene.textures.createCanvas(FALLOFF_KEY, FALLOFF_SIZE, FALLOFF_SIZE)!;
  const ctx = tex.getContext();
  const r = FALLOFF_SIZE / 2;
  const grad = ctx.createRadialGradient(r, r, 0, r, r, r);
  grad.addColorStop(0, 'rgba(0,0,0,0)');
  grad.addColorStop(0.35, 'rgba(0,0,0,0)');
  grad.addColorStop(0.75, 'rgba(0,0,0,0.55)');
  grad.addColorStop(1, 'rgba(0,0,0,1)');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, FALLOFF_SIZE, FALLOFF_SIZE);
  tex.refresh();
}

function fillPoly(g: Phaser.GameObjects.Graphics, p: readonly number[]): void {
  if (p.length < 6) return;
  g.beginPath();
  g.moveTo(p[0], p[1]);
  for (let i = 2; i < p.length; i += 2) g.lineTo(p[i], p[i + 1]);
  g.closePath();
  g.fillPath();
}
