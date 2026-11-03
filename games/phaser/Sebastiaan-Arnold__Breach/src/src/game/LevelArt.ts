import Phaser from 'phaser';
import { COLORS, FONT, TILE } from '../config';
import { blocksSight, isOutdoor, type ParsedLevel, type TileKind } from '../core/grid';
import type { FloorLabel } from '../levels/academy/range';
import { isFloorDressing, isFurniture, propSize, propTiles } from '../levels/props';
import type { PropDef } from '../levels/types';
import { drawClutter, drawFurniture, drawRug } from './Furniture';
import { hash, tone } from './paint';

const PLANK_H = 8;
const PLANK_LEN = 96;
const AO_WALL = [0.34, 0.2, 0.1, 0.04];
const AO_LOW = [0.2, 0.1, 0.04];

/**
 * Draws a level's static art (floors, walls, furniture, shadows, labels) once into a render
 * texture at the game's render scale, so it stays sharp when the camera is zoomed in.
 */
export function drawLevelArt(
  scene: Phaser.Scene,
  level: ParsedLevel,
  labels: readonly FloorLabel[],
  rails: readonly { x0: number; x1: number; y: number }[],
  props: readonly PropDef[],
  depth: number,
  scale: number,
): Phaser.GameObjects.RenderTexture {
  const { width, height } = level;
  const kindAt = (x: number, y: number): TileKind =>
    x < 0 || y < 0 || x >= width || y >= height ? 'wall' : level.tiles[y * width + x];
  const darkAt = (x: number, y: number) => level.dark[y * width + x] ?? false;
  const g = scene.make.graphics({}, false);
  /** Draws a highlight on each side of tile (x, y) whose neighbour is `exposed`. */
  const edges = (x: number, y: number, exposed: (k: TileKind) => boolean, color: number, w: number) => {
    const px = x * TILE, py = y * TILE;
    g.fillStyle(color, 0.9);
    if (exposed(kindAt(x, y - 1))) g.fillRect(px, py, TILE, w);
    if (exposed(kindAt(x, y + 1))) g.fillRect(px, py + TILE - w, TILE, w);
    if (exposed(kindAt(x - 1, y))) g.fillRect(px, py, w, TILE);
    if (exposed(kindAt(x + 1, y))) g.fillRect(px + TILE - w, py, w, TILE);
  };

  // Floors: wooden planks, ceramic tiles, pavement or grass.
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      if (blocksSight(kindAt(x, y))) continue;
      const material = level.material[y * width + x];
      if (material !== 'wood' && material !== 'deck') {
        drawFloor(g, material, x, y, darkAt(x, y));
        continue;
      }
      // Planks: floorboards indoors, weathered timber decking outside.
      const base = material === 'deck' ? COLORS.deck : darkAt(x, y) ? COLORS.floorDark : COLORS.floor;
      for (let r = 0; r < TILE / PLANK_H; r++) {
        const row = y * (TILE / PLANK_H) + r;
        const offset = Math.floor(hash(row, 7) * PLANK_LEN);
        const py = y * TILE + r * PLANK_H;
        let sx = x * TILE;
        while (sx < (x + 1) * TILE) {
          const plank = Math.floor((sx + offset) / PLANK_LEN);
          const end = Math.min((x + 1) * TILE, (plank + 1) * PLANK_LEN - offset);
          g.fillStyle(tone(base, 0.86 + hash(row, plank) * 0.26), 1);
          g.fillRect(sx, py, end - sx, PLANK_H);
          g.fillStyle(0xffffff, 0.025);
          g.fillRect(sx, py + 3 + Math.floor(hash(plank, row) * 3), end - sx, 1);
          if (end < (x + 1) * TILE) {
            g.fillStyle(0x000000, 0.35);
            g.fillRect(end - 0.5, py, 1, PLANK_H);
          }
          sx = end;
        }
        g.fillStyle(0x000000, 0.28);
        g.fillRect(x * TILE, py, TILE, 0.75);
      }
    }
  }

  // Rugs lie on the floor, under the furniture and its shadows.
  for (const p of props) if (p.kind === 'rug') drawRug(g, p);
  // Furniture tiles that a furniture prop draws itself.
  const dressed = new Set(props.filter(isFurniture).flatMap(propTiles).map((t) => t.ty * width + t.tx));

  // Soft contact shadows where floor meets walls and low furniture.
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      if (kindAt(x, y) !== 'floor') continue;
      const px = x * TILE, py = y * TILE;
      const sides: [number, number, 'n' | 's' | 'w' | 'e'][] = [[0, -1, 'n'], [0, 1, 's'], [-1, 0, 'w'], [1, 0, 'e']];
      for (const [dx, dy, side] of sides) {
        const k = kindAt(x + dx, y + dy);
        const ramp = blocksSight(k) ? AO_WALL : k === 'furniture' || k === 'barrier' ? AO_LOW : null;
        if (!ramp) continue;
        ramp.forEach((a, i) => {
          g.fillStyle(0x000000, a);
          if (side === 'n') g.fillRect(px, py + i * 2, TILE, 2);
          else if (side === 's') g.fillRect(px, py + TILE - (i + 1) * 2, TILE, 2);
          else if (side === 'w') g.fillRect(px + i * 2, py, 2, TILE);
          else g.fillRect(px + TILE - (i + 1) * 2, py, 2, TILE);
        });
      }
    }
  }

  // Furniture and the firing-line counter, with drop shadows.
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const kind = kindAt(x, y);
      const px = x * TILE, py = y * TILE;
      if (kind === 'furniture' && !dressed.has(y * width + x)) {
        g.fillStyle(0x000000, 0.3);
        g.fillRect(px + 3, py + 4, TILE, TILE);
      } else if (kind === 'barrier') {
        g.fillStyle(0x000000, 0.3);
        g.fillRect(px + 9, py + 3, TILE - 12, TILE);
      } else if (kind === 'water') {
        // Coping round the edge of a pool or a quay.
        edges(x, y, (k) => k !== 'water', COLORS.stone, 3);
      }
    }
  }
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const kind = kindAt(x, y);
      const px = x * TILE, py = y * TILE;
      if (kind === 'furniture' && !dressed.has(y * width + x)) {
        g.fillStyle(tone(COLORS.furniture, 0.95 + hash(x, y, 3) * 0.1), 1);
        g.fillRect(px, py, TILE, TILE);
        g.fillStyle(0xffffff, 0.04);
        for (let i = 4; i < TILE; i += 6) g.fillRect(px, py + i, TILE, 1);
        edges(x, y, (k) => k !== 'furniture', COLORS.furnitureEdge, 1.5);
      } else if (kind === 'barrier' && isOutdoor(level.material[y * width + x])) {
        // Outdoors a barrier is a low stone wall, a balustrade or a rail: a post with an arm
        // towards each neighbour it joins, so runs and corners read as one line.
        const joins = (k: TileKind) => k === 'barrier' || k === 'glass' || blocksSight(k);
        const t = 10, c = (TILE - t) / 2;
        g.fillStyle(tone(COLORS.stone, 0.92 + hash(x, y, 4) * 0.1), 1);
        g.fillRect(px + c, py + c, t, t);
        if (joins(kindAt(x - 1, y))) g.fillRect(px, py + c, c + t, t);
        if (joins(kindAt(x + 1, y))) g.fillRect(px + c, py + c, TILE - c, t);
        if (joins(kindAt(x, y - 1))) g.fillRect(px + c, py, t, c + t);
        if (joins(kindAt(x, y + 1))) g.fillRect(px + c, py + c, t, TILE - c);
        g.fillStyle(0xffffff, 0.16);
        g.fillRect(px + c, py + c, t, 2);
      } else if (kind === 'barrier') {
        g.fillStyle(COLORS.barrier, 1);
        g.fillRect(px + 6, py, TILE - 12, TILE);
        g.fillStyle(0xffffff, 0.08);
        g.fillRect(px + 6, py, 2, TILE);
        g.fillStyle(COLORS.barrierStripe, 0.75);
        g.fillRect(px + 15, py + (y % 2 ? 0 : 6), 2, TILE - 6);
      }
    }
  }

  for (const p of props) if (isFurniture(p)) drawFurniture(g, p);

  // Walls: textured concrete and plywood with a lit top edge.
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const kind = kindAt(x, y);
      if (!blocksSight(kind)) continue;
      const px = x * TILE, py = y * TILE;
      if (kind === 'wall') {
        g.fillStyle(tone(COLORS.wall, 0.96 + hash(x, y, 1) * 0.08), 1);
        g.fillRect(px, py, TILE, TILE);
        for (let i = 0; i < 7; i++) {
          g.fillStyle(hash(x, y, 20 + i) > 0.5 ? 0xffffff : 0x000000, 0.06);
          g.fillRect(px + hash(x, y, 30 + i) * (TILE - 3), py + hash(x, y, 40 + i) * (TILE - 3), 2 + hash(x, y, 50 + i) * 3, 2);
        }
      } else if (kind === 'plywood') {
        g.fillStyle(COLORS.plywood, 1);
        g.fillRect(px, py, TILE, TILE);
        const along = kindAt(x - 1, y) === 'plywood' || kindAt(x + 1, y) === 'plywood';
        g.fillStyle(0x000000, 0.12);
        for (let i = 7; i < TILE; i += 8) {
          if (along) g.fillRect(px, py + i, TILE, 1);
          else g.fillRect(px + i, py, 1, TILE);
        }
      } else {
        // Plaster interior wall: smooth, light, with a faint skirting line.
        g.fillStyle(tone(COLORS.interior, 0.98 + hash(x, y, 2) * 0.04), 1);
        g.fillRect(px, py, TILE, TILE);
      }
      const edge = kind === 'wall' ? COLORS.wallEdge : kind === 'plywood' ? COLORS.plywoodEdge : COLORS.interiorEdge;
      edges(x, y, (k) => !blocksSight(k), edge, 1.5);
    }
  }

  // Door sills, so doorways read even when the door is open.
  for (const d of level.doors) {
    const px = d.tx * TILE, py = d.ty * TILE;
    g.fillStyle(0x000000, 0.3);
    if (d.orientation === 'h') g.fillRect(px, py + TILE / 2 - 4, TILE, 8);
    else g.fillRect(px + TILE / 2 - 4, py, 8, TILE);
  }

  // Clutter lies on the floor, so vehicles and containers parked over it hide it.
  for (const p of props) if (p.kind === 'clutter') drawClutter(g, p);
  for (const p of props) if (!isFurniture(p) && !isFloorDressing(p)) drawProp(g, p);

  for (const r of rails) {
    g.fillStyle(0x000000, 0.35);
    g.fillRect(r.x0, r.y - 2, r.x1 - r.x0, 4);
    g.fillStyle(0x8a8f96, 0.6);
    g.fillRect(r.x0, r.y - 1, r.x1 - r.x0, 1.5);
  }

  const rt = scene.add.renderTexture(0, 0, width * TILE * scale, height * TILE * scale)
    .setOrigin(0).setScale(1 / scale).setDepth(depth);
  g.setScale(scale);
  rt.draw(g);
  g.destroy();

  for (const l of labels) {
    const t = scene.make.text({
      x: l.tx * TILE * scale, y: l.ty * TILE * scale, text: l.text,
      style: { fontFamily: FONT, fontSize: `${(l.size ?? 16) * scale}px`, fontStyle: 'bold', color: '#e8d6b3' },
    }, false).setAlpha(0.2);
    rt.draw(t);
    t.destroy();
  }
  return rt;
}

function drawFloor(g: Phaser.GameObjects.Graphics, material: string, x: number, y: number, dark: boolean): void {
  const px = x * TILE, py = y * TILE;
  const f = dark ? 0.6 : 1;
  if (material === 'tile') {
    // 16 px ceramic tiles with grout lines.
    for (let ty = 0; ty < 2; ty++) {
      for (let tx = 0; tx < 2; tx++) {
        g.fillStyle(tone(COLORS.tile, f * (0.95 + hash(x * 2 + tx, y * 2 + ty, 5) * 0.08)), 1);
        g.fillRect(px + tx * 16, py + ty * 16, 16, 16);
      }
    }
    g.fillStyle(0x000000, 0.22);
    g.fillRect(px, py, TILE, 1);
    g.fillRect(px, py + 16, TILE, 1);
    g.fillRect(px, py, 1, TILE);
    g.fillRect(px + 16, py, 1, TILE);
  } else if (material === 'water') {
    g.fillStyle(tone(COLORS.water, 0.94 + hash(x, y, 8) * 0.1), 1);
    g.fillRect(px, py, TILE, TILE);
    for (let i = 0; i < 3; i++) {
      g.fillStyle(0xffffff, 0.06);
      g.fillRect(px + hash(x, y, 140 + i) * 22, py + 6 + i * 9, 6 + hash(x, y, 150 + i) * 8, 1);
    }
  } else if (material === 'concrete' || material === 'screed') {
    g.fillStyle(tone(material === 'screed' ? COLORS.screed : COLORS.concrete, f * (0.97 + hash(x, y, 6) * 0.06)), 1);
    g.fillRect(px, py, TILE, TILE);
    for (let i = 0; i < 6; i++) {
      g.fillStyle(hash(x, y, 60 + i) > 0.5 ? 0xffffff : 0x000000, 0.05);
      g.fillRect(px + hash(x, y, 70 + i) * 30, py + hash(x, y, 80 + i) * 30, 2, 2);
    }
    // Expansion joints every two tiles.
    g.fillStyle(0x000000, 0.2);
    if (x % 2 === 0) g.fillRect(px, py, 1, TILE);
    if (y % 2 === 0) g.fillRect(px, py, TILE, 1);
  } else {
    g.fillStyle(tone(COLORS.grass, f * (0.92 + hash(x, y, 7) * 0.12)), 1);
    g.fillRect(px, py, TILE, TILE);
    for (let i = 0; i < 14; i++) {
      g.fillStyle(hash(x, y, 90 + i) > 0.5 ? 0x9ccf7a : 0x0d1f0a, 0.12);
      g.fillRect(px + hash(x, y, 110 + i) * 31, py + hash(x, y, 130 + i) * 30, 1, 2);
    }
  }
}

/** Set dressing: the van at the drop-off, cars and shipping containers. */
function drawProp(g: Phaser.GameObjects.Graphics, p: PropDef): void {
  if (p.kind === 'car') return drawCar(g, p);
  if (p.kind === 'container') return drawContainer(g, p);
  if (p.kind === 'rack') return drawRack(g, p);
  if (p.kind === 'truck') return drawTruck(g, p);
  const { w: tw, h: th } = propSize(p);
  const x = p.tx * TILE, y = p.ty * TILE, w = tw * TILE, h = th * TILE;
  g.fillStyle(0x000000, 0.35);
  g.fillRoundedRect(x + 4, y + 5, w, h, 8);
  g.fillStyle(0x1e293b, 1);
  g.fillRoundedRect(x, y, w, h, 8);
  g.fillStyle(0x334155, 1);
  g.fillRoundedRect(x + 8, y + 6, w - 40, h - 12, 4);
  // Windscreen at the front (east), light bar on the roof.
  g.fillStyle(0x93c5fd, 0.55);
  g.fillRoundedRect(x + w - 30, y + 6, 14, h - 12, 3);
  g.fillStyle(0xdc2626, 1);
  g.fillRect(x + w - 46, y + h / 2 - 9, 6, 8);
  g.fillStyle(0x2563eb, 1);
  g.fillRect(x + w - 46, y + h / 2 + 1, 6, 8);
  g.fillStyle(0xf8fafc, 0.85);
  g.fillRect(x + 16, y + h / 2 - 1, w - 70, 2);
}

/** A car seen from above, two tiles by four, nose to the east (or south when vertical). */
function drawCar(g: Phaser.GameObjects.Graphics, p: PropDef): void {
  const x = p.tx * TILE, y = p.ty * TILE;
  const size = propSize(p);
  const w = size.w * TILE, h = size.h * TILE;
  const color = p.color ?? 0x64748b;
  const inset = 5;
  g.fillStyle(0x000000, 0.35);
  g.fillRoundedRect(x + inset + 3, y + inset + 4, w - inset * 2, h - inset * 2, 10);
  g.fillStyle(color, 1);
  g.fillRoundedRect(x + inset, y + inset, w - inset * 2, h - inset * 2, 10);
  // Roof and glass.
  g.fillStyle(tone(color, 0.8), 1);
  if (p.vertical) {
    g.fillRoundedRect(x + 12, y + h * 0.3, w - 24, h * 0.38, 6);
    g.fillStyle(0x93c5fd, 0.45);
    g.fillRect(x + 12, y + h * 0.26, w - 24, 6);
    g.fillRect(x + 12, y + h * 0.68, w - 24, 5);
  } else {
    g.fillRoundedRect(x + w * 0.3, y + 12, w * 0.38, h - 24, 6);
    g.fillStyle(0x93c5fd, 0.45);
    g.fillRect(x + w * 0.68, y + 12, 6, h - 24);
    g.fillRect(x + w * 0.26, y + 12, 5, h - 24);
  }
}

/** A shipping container: corrugated steel, two tiles wide. */
function drawContainer(g: Phaser.GameObjects.Graphics, p: PropDef): void {
  const x = p.tx * TILE, y = p.ty * TILE;
  const size = propSize(p);
  const w = size.w * TILE, h = size.h * TILE;
  const color = p.color ?? 0x7c2d12;
  g.fillStyle(0x000000, 0.35);
  g.fillRect(x + 4, y + 5, w, h);
  g.fillStyle(color, 1);
  g.fillRect(x, y, w, h);
  g.fillStyle(0x000000, 0.18);
  if (p.vertical) for (let i = 4; i < h; i += 6) g.fillRect(x, y + i, w, 2);
  else for (let i = 4; i < w; i += 6) g.fillRect(x + i, y, 2, h);
  g.lineStyle(1.5, tone(color, 1.4), 0.8);
  g.strokeRect(x + 0.75, y + 0.75, w - 1.5, h - 1.5);
}

/** Warehouse racking: a steel frame with boxes and pallets on it. */
function drawRack(g: Phaser.GameObjects.Graphics, p: PropDef): void {
  const { w, h } = propSize(p);
  const x = p.tx * TILE, y = p.ty * TILE, pw = w * TILE, ph = h * TILE;
  g.fillStyle(0x000000, 0.35);
  g.fillRect(x + 3, y + 4, pw, ph);
  g.fillStyle(0x334155, 1);
  g.fillRect(x, y, pw, ph);
  // Boxes in bays along the rack.
  const along = pw >= ph;
  const bays = Math.round((along ? pw : ph) / TILE);
  for (let i = 0; i < bays; i++) {
    const bx = along ? x + i * TILE + 3 : x + 3, by = along ? y + 3 : y + i * TILE + 3;
    const bw = along ? TILE - 6 : pw - 6, bh = along ? ph - 6 : TILE - 6;
    g.fillStyle(tone(0xb08a5a, 0.8 + hash(p.tx + i, p.ty, 11) * 0.35), 1);
    g.fillRect(bx, by, bw, bh);
    g.fillStyle(0x000000, 0.15);
    g.fillRect(bx, by + bh / 2 - 0.5, bw, 1);
  }
  g.lineStyle(2, 0xf59e0b, 0.85);
  g.strokeRect(x + 1, y + 1, pw - 2, ph - 2);
}

/** An articulated lorry: cab and trailer, cab at the east end (south when vertical). */
function drawTruck(g: Phaser.GameObjects.Graphics, p: PropDef): void {
  const { w, h } = propSize(p);
  const x = p.tx * TILE, y = p.ty * TILE, pw = w * TILE, ph = h * TILE;
  const color = p.color ?? 0xe5e7eb;
  g.fillStyle(0x000000, 0.35);
  g.fillRect(x + 4, y + 5, pw, ph);
  if (p.vertical) {
    g.fillStyle(color, 1);
    g.fillRect(x + 2, y, pw - 4, ph - 2.2 * TILE);
    g.fillStyle(0x1e3a8a, 1);
    g.fillRoundedRect(x + 4, y + ph - 2 * TILE, pw - 8, 2 * TILE, 6);
    g.fillStyle(0x93c5fd, 0.5);
    g.fillRect(x + 10, y + ph - 0.7 * TILE, pw - 20, 8);
  } else {
    g.fillStyle(color, 1);
    g.fillRect(x, y + 2, pw - 2.2 * TILE, ph - 4);
    g.fillStyle(0x1e3a8a, 1);
    g.fillRoundedRect(x + pw - 2 * TILE, y + 4, 2 * TILE, ph - 8, 6);
    g.fillStyle(0x93c5fd, 0.5);
    g.fillRect(x + pw - 0.7 * TILE, y + 10, 8, ph - 20);
  }
  g.fillStyle(0x000000, 0.12);
  if (p.vertical) for (let i = 8; i < ph - 2.2 * TILE; i += 12) g.fillRect(x + 2, y + i, pw - 4, 2);
  else for (let i = 8; i < pw - 2.2 * TILE; i += 12) g.fillRect(x + i, y + 2, 2, ph - 4);
}
