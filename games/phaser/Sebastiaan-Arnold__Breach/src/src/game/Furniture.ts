import Phaser from 'phaser';
import { TILE } from '../config';
import { propSize } from '../levels/props';
import type { PropDef } from '../levels/types';
import { hash, tone } from './paint';

/**
 * Furniture and floor dressing, seen from above. Each piece is drawn as if it stood against a
 * north wall (its back at the top) and turned to the side it actually stands against, so a sofa
 * or a worktop reads the right way round in any room.
 */

type Side = 'n' | 'e' | 's' | 'w';

const WOOD = 0x6e4c2f, WOOD_DARK = 0x3f2c1e, STEEL = 0x2f343b, WHITE = 0xe5e7eb, LINEN = 0xdfe3ea;
const BOOKS = [0x7f1d1d, 0x1e3a8a, 0x365314, 0xa16207, 0x4b5563, 0x9a3412, 0xd6d3d1];

/** Draws in a piece's own frame: x along its back wall, y out into the room. */
class Frame {
  /** Length along the back wall, and depth into the room, in pixels. */
  readonly W: number;
  readonly D: number;

  constructor(private g: Phaser.GameObjects.Graphics, private x: number, private y: number, private pw: number, private ph: number, private side: Side) {
    const across = side === 'n' || side === 's';
    this.W = across ? pw : ph;
    this.D = across ? ph : pw;
  }

  private box(lx: number, ly: number, lw: number, lh: number): [number, number, number, number] {
    const { x, y, pw, ph } = this;
    switch (this.side) {
      case 'n': return [x + lx, y + ly, lw, lh];
      case 's': return [x + pw - lx - lw, y + ph - ly - lh, lw, lh];
      case 'w': return [x + ly, y + lx, lh, lw];
      case 'e': return [x + pw - ly - lh, y + lx, lh, lw];
    }
  }

  rect(lx: number, ly: number, lw: number, lh: number, color: number, alpha = 1, r = 0): void {
    const [bx, by, bw, bh] = this.box(lx, ly, lw, lh);
    this.g.fillStyle(color, alpha);
    const rr = Math.min(r, bw / 2, bh / 2);
    if (rr > 0.5) this.g.fillRoundedRect(bx, by, bw, bh, rr);
    else this.g.fillRect(bx, by, bw, bh);
  }

  ellipse(lx: number, ly: number, lw: number, lh: number, color: number, alpha = 1): void {
    const [bx, by, bw, bh] = this.box(lx - lw / 2, ly - lh / 2, lw, lh);
    this.g.fillStyle(color, alpha);
    this.g.fillEllipse(bx + bw / 2, by + bh / 2, bw, bh);
  }
}

export function drawFurniture(g: Phaser.GameObjects.Graphics, p: PropDef): void {
  const { w, h } = propSize(p);
  const x = p.tx * TILE, y = p.ty * TILE, pw = w * TILE, ph = h * TILE;
  // Pieces that sit per tile (stacks, drums, bins) cast their own shadows.
  if (p.kind === 'crates' || p.kind === 'pallet' || p.kind === 'drums' || p.kind === 'bins') return perTile(g, p, w, h);
  // A bed of plants (a hedge, a planter) is a plant per tile.
  if (p.kind === 'plant') {
    for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) plant(g, x + i * TILE, y + j * TILE, p, i * 7 + j);
    return;
  }
  g.fillStyle(0x000000, 0.3);
  g.fillRoundedRect(x + 4, y + 5, pw - 4, ph - 4, 4);
  // A table has no back; it lies along its long side.
  const side: Side = p.side ?? (p.kind === 'table' || p.kind === 'lowtable' ? (pw >= ph ? 'n' : 'w') : 'n');
  const f = new Frame(g, x, y, pw, ph, side);
  const { W, D } = f;
  const seed = (n: number) => hash(Math.round(p.tx * 4), Math.round(p.ty * 4), n);
  switch (p.kind) {
    case 'bed': {
      const c = p.color ?? 0x51607a;
      f.rect(1, 1, W - 2, D - 2, WOOD_DARK, 1, 3);
      f.rect(3, 3, W - 6, D - 6, LINEN, 1, 2);
      const fold = Math.min(D * 0.32, 30);
      f.rect(3, fold, W - 6, D - fold - 3, c, 1, 2);
      f.rect(3, fold, W - 6, 3, tone(c, 1.3));
      f.rect(3 + (W - 6) * (0.3 + seed(1) * 0.4), fold + 6, 1, D - fold - 14, tone(c, 0.8), 0.6);
      const n = W >= 56 ? 2 : 1, pillow = (W - 6 - (n + 1) * 3) / n;
      for (let i = 0; i < n; i++) f.rect(6 + i * (pillow + 3), 5, pillow, fold - 9, 0xf1f5f9, 1, 3);
      break;
    }
    case 'sofa':
    case 'armchair': {
      const c = p.color ?? 0x3f5a73;
      f.rect(1, 1, W - 2, D - 2, tone(c, 0.7), 1, 4);
      f.rect(1, 1, W - 2, 9, tone(c, 0.82), 1, 4);
      f.rect(1, 1, 7, D - 2, tone(c, 0.88), 1, 3);
      f.rect(W - 8, 1, 7, D - 2, tone(c, 0.88), 1, 3);
      const n = Math.max(1, Math.round((W - 16) / 26)), cw = (W - 16 - (n - 1) * 1.5) / n;
      for (let i = 0; i < n; i++) {
        f.rect(8 + i * (cw + 1.5), 10, cw, D - 12, c, 1, 3);
        f.rect(8 + i * (cw + 1.5), 10, cw, 2, tone(c, 1.2), 0.6);
      }
      break;
    }
    case 'table': {
      const c = p.color ?? WOOD;
      // Chairs tucked in along both long sides, then the top.
      for (let i = 0; i < Math.round(W / TILE); i++) {
        const cx = i * TILE + TILE / 2;
        f.rect(cx - 6, 1, 12, 9, 0x2b2420, 1, 2);
        f.rect(cx - 6, D - 10, 12, 9, 0x2b2420, 1, 2);
      }
      f.rect(2, 7, W - 4, D - 14, c, 1, 3);
      f.rect(2, 7, W - 4, 2, tone(c, 1.25), 0.7);
      for (let i = 0; i < Math.round(W / TILE); i++) {
        if (seed(10 + i) < 0.35) continue;
        f.ellipse(i * TILE + TILE / 2, 12 + (seed(20 + i) > 0.5 ? D - 24 : 0), 7, 7, WHITE, 0.9);
      }
      break;
    }
    case 'lowtable': {
      const c = p.color ?? 0x5a4632;
      f.rect(5, 6, W - 10, D - 12, c, 1, 3);
      f.rect(5, 6, W - 10, 2, tone(c, 1.3), 0.6);
      f.rect(W * 0.3, D * 0.35, 9, 7, 0xcbd5e1, 0.85);
      f.ellipse(W * 0.68, D * 0.5, 4.5, 4.5, 0xd6d3d1);
      break;
    }
    case 'desk': {
      const c = p.color ?? 0x8a6a48, top = Math.round(D * 0.62);
      f.rect(1, 1, W - 2, top, c, 1, 2);
      f.rect(1, top - 1, W - 2, 2, tone(c, 0.75));
      f.rect(W / 2 - 9, 3, 18, 3.5, 0x111827, 1, 1);
      f.rect(W / 2 - 8, 6.5, 16, 1, 0x60a5fa, 0.55);
      f.rect(W / 2 - 7, 10, 14, 4, 0x374151, 1, 1);
      f.rect(4, 5, 8, 10, WHITE, 0.8);
      f.ellipse(W / 2, top + 7, 13, 12, 0x1f2937);
      f.rect(W / 2 - 6, top + 11, 12, 3, 0x111827, 1, 1);
      break;
    }
    case 'kitchen': {
      const c = p.color ?? 0xb9bec6;
      f.rect(0, 0, W, D - 1, 0x3a3f46);
      f.rect(0, 0, W, D - 5, c);
      f.rect(0, D - 7, W, 2, tone(c, 0.78));
      const tiles = Math.round(W / TILE), sink = Math.floor(tiles * 0.3), hob = tiles > 1 ? Math.max(sink + 1, Math.floor(tiles * 0.75)) : -1;
      for (let i = 0; i < tiles; i++) {
        const cx = i * TILE + TILE / 2;
        if (i === sink) {
          f.rect(cx - 10, 4, 20, D - 13, 0x9ca3af, 1, 3);
          f.rect(cx - 8, 6, 16, D - 17, 0x6b7280, 1, 2);
          f.ellipse(cx, 3, 3, 3, 0xd1d5db);
        } else if (i === hob) {
          f.rect(cx - 12, 3, 24, D - 11, 0x111827, 1, 2);
          for (const [ox, oy] of [[-6, 0.33], [6, 0.33], [-6, 0.68], [6, 0.68]]) f.ellipse(cx + ox, (D - 8) * oy + 2, 7, 7, 0x374151);
        } else if (seed(30 + i) < 0.4) {
          f.ellipse(cx + (seed(40 + i) - 0.5) * 10, D * 0.38, 8, 8, seed(50 + i) < 0.5 ? WHITE : 0x9a3412);
        } else if (seed(30 + i) < 0.65) {
          f.rect(cx - 7, 5, 14, 10, 0xa1784a, 1, 1);
        }
      }
      break;
    }
    case 'bath': {
      const c = p.color ?? WHITE;
      f.rect(1, 1, W - 2, D - 2, c, 1, 7);
      f.rect(4, 4, W - 8, D - 8, 0xb6d4e8, 1, 6);
      f.ellipse(W / 2, 3.5, 4, 4, 0x9ca3af);
      break;
    }
    case 'wc': {
      f.rect(W / 2 - 9, 1, 18, 7, WHITE, 1, 2);
      f.ellipse(W / 2, 16, 15, 17, WHITE);
      f.ellipse(W / 2, 17, 9, 10, 0xb6c2cf);
      break;
    }
    case 'wardrobe': {
      const c = p.color ?? 0x4a3423;
      f.rect(1, 1, W - 2, D - 2, c, 1, 2);
      f.rect(1, 1, W - 2, 2, tone(c, 1.35), 0.6);
      f.rect(W / 2 - 0.5, 3, 1, D - 6, 0x000000, 0.35);
      f.ellipse(W / 2 - 3, D - 6, 2.5, 2.5, 0xd6d3d1);
      f.ellipse(W / 2 + 3, D - 6, 2.5, 2.5, 0xd6d3d1);
      break;
    }
    case 'shelf': {
      f.rect(1, 1, W - 2, D - 2, 0x3b2a1d, 1, 1);
      let bx = 3, i = 0;
      while (bx < W - 4) {
        const bw = 2 + Math.floor(seed(60 + i) * 3);
        if (seed(80 + i) > 0.12) f.rect(bx, 3, bw, (D - 6) * (0.55 + seed(70 + i) * 0.35), BOOKS[Math.floor(seed(90 + i) * BOOKS.length)]);
        bx += bw + 0.6;
        i++;
      }
      break;
    }
    case 'tv': {
      f.rect(1, 3, W - 2, D - 12, 0x2b2420, 1, 2);
      f.rect(4, 2, W - 8, 4, 0x0b0f14, 1, 1);
      f.rect(5, 6.5, W - 10, 1, 0x60a5fa, 0.5);
      f.rect(W * 0.2, 10, 10, 5, 0x1f2937, 1, 1);
      break;
    }
    case 'bench': {
      const c = p.color ?? 0x6b5a45;
      f.rect(1, 1, W - 2, D - 2, STEEL, 1, 1);
      f.rect(2, 2, W - 4, D - 6, c);
      f.rect(4, 3, 9, 7, 0x374151, 1, 1);
      f.rect(W * 0.42, 7, 11, 2, 0x9ca3af);
      f.rect(W * 0.62, 12, 9, 2, 0xdc2626);
      f.ellipse(W * 0.75, D * 0.45, 9, 7, 0x000000, 0.22);
      break;
    }
    case 'cabinet': {
      f.rect(1, 1, W - 2, D - 3, 0x8b929c, 1, 1);
      f.rect(1, D - 6, W - 2, 4, 0x4b5563);
      f.rect(W / 2 - 3, D - 5, 6, 1.5, 0xd1d5db);
      break;
    }
    case 'pool': {
      // A snooker table: wooden rim, green baize, six pockets, a few balls.
      f.rect(1, 1, W - 2, D - 2, WOOD_DARK, 1, 3);
      f.rect(4, 4, W - 8, D - 8, p.color ?? 0x166534, 1, 1);
      for (const px of [4, W / 2, W - 4]) for (const py of [4, D - 4]) f.ellipse(px, py, 4, 4, 0x0b0f0b);
      const balls = [0xdc2626, 0xdc2626, 0xf8fafc, 0x111827, 0xeab308, 0x2563eb];
      balls.forEach((c, i) => f.ellipse(8 + seed(100 + i) * (W - 16), 8 + seed(110 + i) * (D - 16), 3, 3, c));
      break;
    }
    case 'counter': {
      const c = p.color ?? 0x5b3f28;
      f.rect(0, 1, W, D - 2, c, 1, 2);
      f.rect(0, 1, W, 3, tone(c, 1.3), 0.7);
      f.rect(W * 0.2, 6, 11, 9, 0x1f2937, 1, 1);
      f.rect(W * 0.2 + 2, 7, 7, 3, 0x22c55e, 0.5);
      break;
    }
  }
}

/** A potted plant: a pot and a spray of leaves. */
function plant(g: Phaser.GameObjects.Graphics, x: number, y: number, p: PropDef, n = 0): void {
  const cx = x + TILE / 2, cy = y + TILE / 2;
  g.fillStyle(0x000000, 0.3);
  g.fillCircle(cx + 3, cy + 4, 10);
  g.fillStyle(p.color ?? 0x7c4a2a, 1);
  g.fillCircle(cx, cy, 9);
  g.fillStyle(0x2f2418, 1);
  g.fillCircle(cx, cy, 7);
  for (let i = 0; i < 7; i++) {
    const a = (i / 7) * Math.PI * 2 + hash(p.tx, p.ty, 3 + n) * 2;
    g.fillStyle(i % 2 ? 0x2f6b2f : 0x3f8a3f, 1);
    g.fillCircle(cx + Math.cos(a) * 7, cy + Math.sin(a) * 7, 5);
  }
  g.fillStyle(0x4d9d4d, 1);
  g.fillCircle(cx, cy, 4);
}

/** Things that stand one to a tile: boxes, pallets, drums, wheelie bins. */
function perTile(g: Phaser.GameObjects.Graphics, p: PropDef, w: number, h: number): void {
  for (let j = 0; j < h; j++) {
    for (let i = 0; i < w; i++) {
      const tx = Math.floor(p.tx) + i, ty = Math.floor(p.ty) + j;
      const x = tx * TILE, y = ty * TILE, r = (n: number) => hash(tx, ty, n);
      if (p.kind === 'crates') {
        const boxes: [number, number, number, number][] = r(1) < 0.5 ? [[3, 3, 26, 26]] : [[2, 3, 15, 14], [16, 15, 14, 14], [17, 2, 12, 11]];
        for (const [bx, by, bw, bh] of boxes) {
          const wooden = r(bx + by) < 0.35;
          const c = wooden ? 0x8b6a45 : tone(0xc8a46a, 0.85 + r(bx * by) * 0.25);
          g.fillStyle(0x000000, 0.3);
          g.fillRect(x + bx + 2, y + by + 3, bw, bh);
          g.fillStyle(c, 1);
          g.fillRect(x + bx, y + by, bw, bh);
          g.fillStyle(wooden ? 0x5b4330 : 0xe7d3a8, wooden ? 0.8 : 0.7);
          if (wooden) {
            g.fillRect(x + bx, y + by + bh / 2 - 1, bw, 2);
            g.fillRect(x + bx + bw / 2 - 1, y + by, 2, bh);
          } else g.fillRect(x + bx + bw / 2 - 1.5, y + by, 3, bh);
        }
      } else if (p.kind === 'pallet') {
        g.fillStyle(0x000000, 0.3);
        g.fillRect(x + 4, y + 5, 27, 27);
        g.fillStyle(0x9a7b55, 1);
        for (let k = 0; k < 5; k++) g.fillRect(x + 2, y + 2 + k * 6, 28, 4);
        const c = p.color ?? 0xd6cbb5;
        g.fillStyle(c, 1);
        g.fillRect(x + 4, y + 4, 24, 24);
        g.fillStyle(0xffffff, 0.18);
        g.fillRect(x + 6, y + 6, 6, 20);
        g.fillStyle(0x000000, 0.12);
        g.fillRect(x + 4, y + 16, 24, 1);
      } else if (p.kind === 'drums') {
        const c = p.color ?? 0x1e40af;
        for (const [ox, oy] of [[9, 9], [23, 9], [9, 23], [23, 23]]) {
          if (r(ox * oy) < 0.15) continue;
          g.fillStyle(0x000000, 0.3);
          g.fillCircle(x + ox + 2, y + oy + 3, 7);
          g.fillStyle(c, 1);
          g.fillCircle(x + ox, y + oy, 7);
          g.lineStyle(1.2, tone(c, 1.5), 0.8);
          g.strokeCircle(x + ox, y + oy, 5);
          g.fillStyle(tone(c, 1.6), 0.9);
          g.fillCircle(x + ox + 2.5, y + oy - 2.5, 1.4);
        }
      } else {
        const c = p.color ?? 0x1f3d2b;
        g.fillStyle(0x000000, 0.3);
        g.fillRoundedRect(x + 6, y + 6, 24, 25, 3);
        g.fillStyle(c, 1);
        g.fillRoundedRect(x + 4, y + 3, 24, 25, 3);
        g.fillStyle(tone(c, 0.75), 1);
        g.fillRoundedRect(x + 4, y + 3, 24, 8, 3);
        g.fillStyle(0x111111, 1);
        g.fillRect(x + 7, y + 2, 18, 2);
      }
    }
  }
}

/** Rugs: under the furniture, over the floor. */
export function drawRug(g: Phaser.GameObjects.Graphics, p: PropDef): void {
  const { w, h } = propSize(p);
  const x = p.tx * TILE, y = p.ty * TILE, pw = w * TILE, ph = h * TILE;
  const c = p.color ?? 0x7f1d1d;
  g.fillStyle(c, 0.92);
  g.fillRect(x + 2, y + 2, pw - 4, ph - 4);
  g.lineStyle(2, tone(c, 1.45), 0.55);
  g.strokeRect(x + 6, y + 6, pw - 12, ph - 12);
  g.lineStyle(1, tone(c, 1.45), 0.35);
  g.strokeRect(x + 10, y + 10, pw - 20, ph - 20);
  g.fillStyle(0x000000, 0.12);
  for (let i = 0; i < 5; i++) g.fillRect(x + 2 + hash(p.tx, p.ty, i) * (pw - 10), y + 2, 1, ph - 4);
}

/** Whatever is lying about: party litter, a bagging table, paperwork, tools. */
export function drawClutter(g: Phaser.GameObjects.Graphics, p: PropDef): void {
  const { w, h } = propSize(p);
  const x = p.tx * TILE, y = p.ty * TILE, pw = w * TILE, ph = h * TILE;
  const n = Math.max(2, Math.round(w * h * 0.35));
  for (let i = 0; i < n; i++) {
    const r = (k: number) => hash(Math.round(p.tx * 7) + i, Math.round(p.ty * 7), k);
    const ix = x + 4 + r(1) * (pw - 12), iy = y + 4 + r(2) * (ph - 12), pick = r(3);
    switch (p.style ?? 'trash') {
      case 'party':
        if (pick < 0.4) dot(g, ix, iy, 2.4, 0xdc2626);
        else if (pick < 0.65) dot(g, ix, iy, 1.9, 0x9ca3af);
        else if (pick < 0.85) box(g, ix, iy, 2.4, 7, 0x14532d);
        else box(g, ix, iy, 6, 5, 0xeab308);
        break;
      case 'drugs':
        if (pick < 0.55) box(g, ix, iy, 3.5, 3.5, 0xf1f5f9);
        else if (pick < 0.8) box(g, ix, iy, 7, 3.5, 0x4d7c0f);
        else box(g, ix, iy, 9, 7, 0x1f2937);
        break;
      case 'office':
        if (pick < 0.7) box(g, ix, iy, 7, 9, 0xe5e7eb, 0.85);
        else box(g, ix, iy, 6, 8, 0x1e3a8a);
        break;
      case 'tools':
        if (pick < 0.35) dot(g, ix, iy, 6, 0x000000, 0.22);
        else if (pick < 0.7) box(g, ix, iy, 9, 1.8, 0x9ca3af);
        else box(g, ix, iy, 6, 5, 0xb91c1c, 0.8);
        break;
      case 'laundry':
        box(g, ix, iy, 9, 7, BOOKS[Math.floor(pick * BOOKS.length)], 0.9);
        break;
      default:
        if (pick < 0.45) box(g, ix, iy, 6, 5, 0xd6d3d1, 0.75);
        else if (pick < 0.75) dot(g, ix, iy, 1.9, 0x9ca3af);
        else box(g, ix, iy, 12, 12, 0xb08a5a);
    }
  }
}

function dot(g: Phaser.GameObjects.Graphics, x: number, y: number, r: number, c: number, a = 1): void {
  g.fillStyle(c, a);
  g.fillCircle(x, y, r);
}

function box(g: Phaser.GameObjects.Graphics, x: number, y: number, w: number, h: number, c: number, a = 1): void {
  g.fillStyle(0x000000, 0.25 * a);
  g.fillRect(x + 1, y + 1.5, w, h);
  g.fillStyle(c, a);
  g.fillRect(x, y, w, h);
}
