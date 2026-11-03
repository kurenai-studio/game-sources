import Phaser from 'phaser';
import { COLORS, TILE } from '../config';
import { blocksSight, type ParsedLevel } from '../core/grid';

/** The glass colour as it reads over its dark frame. */
const PANE = 0x8cb9e2;

/**
 * Glass walls and windows. Panes are drawn on their own layer, not baked into the level art,
 * because a shot shatters them: the pane goes, the tile becomes floor and the gap can be walked
 * through.
 *
 * Each pane is a post with an arm towards every neighbour it joins (more glass, a wall or a
 * door), so straight runs read as one line and corners close. A wall that meets a glass front
 * side-on is carried on to the frame instead.
 */
export class Glass {
  private intact = new Set<number>();
  private doors = new Set<number>();
  private gfx: Phaser.GameObjects.Graphics;

  constructor(scene: Phaser.Scene, private level: ParsedLevel, depth: number) {
    level.tiles.forEach((k, i) => {
      if (k === 'glass') this.intact.add(i);
    });
    for (const d of level.doors) this.doors.add(d.ty * level.width + d.tx);
    this.gfx = scene.add.graphics().setDepth(depth);
    this.draw();
  }

  isIntact(tx: number, ty: number): boolean {
    return this.intact.has(ty * this.level.width + tx);
  }

  /** Shatters the pane at (tx, ty). Returns true if there was one. */
  shatter(tx: number, ty: number): boolean {
    const i = ty * this.level.width + tx;
    if (!this.intact.delete(i)) return false;
    this.level.tiles[i] = 'floor';
    this.draw();
    return true;
  }

  private draw(): void {
    const g = this.gfx;
    const { width, height } = this.level;
    const inside = (x: number, y: number) => x >= 0 && y >= 0 && x < width && y < height;
    // More glass, or a door set in it: the pane continues that way.
    const pane = (x: number, y: number) => inside(x, y) && (this.intact.has(y * width + x) || this.doors.has(y * width + x));
    const kind = (x: number, y: number) => this.level.tiles[y * width + x];
    const wall = (x: number, y: number) => !inside(x, y) || blocksSight(kind(x, y));
    const alongX = (x: number, y: number) => pane(x - 1, y) || pane(x + 1, y);
    const alongY = (x: number, y: number) => pane(x, y - 1) || pane(x, y + 1);
    /**
     * Which sides a pane reaches with glass: more glass, a wall it runs into, and at the end of a
     * run a wall round the corner (an L). A wall meeting the middle of a run gets a stub instead.
     */
    const joins = (x: number, y: number, dx: number, dy: number) => {
      if (pane(x + dx, y + dy)) return true;
      if (!wall(x + dx, y + dy)) return false;
      const ax = alongX(x, y), ay = alongY(x, y);
      if (dx !== 0 ? ax || !ay : ay || !ax) return true;
      // Round a corner: only where the run stops here, with open ground beyond it.
      const open = (x: number, y: number) => !pane(x, y) && !wall(x, y);
      return dx !== 0
        ? (pane(x, y - 1) && open(x, y + 1)) || (pane(x, y + 1) && open(x, y - 1))
        : (pane(x - 1, y) && open(x + 1, y)) || (pane(x + 1, y) && open(x - 1, y));
    };
    /** A wall that meets the middle of a run, carried on to the frame so it doesn't stop short. */
    const stub = (x: number, y: number, dx: number, dy: number) => {
      const k = kind(x + dx, y + dy);
      if (!inside(x + dx, y + dy) || !blocksSight(k) || joins(x, y, dx, dy)) return;
      const fill = k === 'wall' ? COLORS.wall : k === 'plywood' ? COLORS.plywood : COLORS.interior;
      const edge = k === 'wall' ? COLORS.wallEdge : k === 'plywood' ? COLORS.plywoodEdge : COLORS.interiorEdge;
      const px = x * TILE, py = y * TILE, reach = (TILE - 8) / 2 + 2;
      // Over the wall's own lit edge on that side, then down to the frame.
      const [rx, ry, rw, rh] = dy !== 0
        ? [px, dy < 0 ? py - 2 : py + TILE - reach, TILE, reach + 2]
        : [dx < 0 ? px - 2 : px + TILE - reach, py, reach + 2, TILE];
      g.fillStyle(fill, 1);
      g.fillRect(rx, ry, rw, rh);
      g.fillStyle(edge, 0.9);
      if (dy !== 0) {
        g.fillRect(rx, ry, 1.5, rh);
        g.fillRect(rx + rw - 1.5, ry, 1.5, rh);
      } else {
        g.fillRect(rx, ry, rw, 1.5);
        g.fillRect(rx, ry + rh - 1.5, rw, 1.5);
      }
    };
    /** A centred square of width `w`, with an arm out to each side the pane joins. */
    const arms = (i: number, w: number) => {
      const x = i % width, y = Math.floor(i / width);
      const px = x * TILE, py = y * TILE, a = (TILE - w) / 2;
      g.fillRect(px + a, py + a, w, w);
      if (joins(x, y, -1, 0)) g.fillRect(px, py + a, a + w, w);
      if (joins(x, y, 1, 0)) g.fillRect(px + a, py + a, TILE - a, w);
      if (joins(x, y, 0, -1)) g.fillRect(px + a, py, w, a + w);
      if (joins(x, y, 0, 1)) g.fillRect(px + a, py + a, w, TILE - a);
    };
    g.clear();
    for (const i of this.intact) {
      const x = i % width, y = Math.floor(i / width);
      for (const [dx, dy] of [[-1, 0], [1, 0], [0, -1], [0, 1]]) stub(x, y, dx, dy);
    }
    // The frame, then the pane inside it: opaque, so where pieces overlap the run stays even.
    g.fillStyle(0x1e293b, 1);
    for (const i of this.intact) arms(i, 8);
    g.fillStyle(PANE, 1);
    for (const i of this.intact) arms(i, 4);
  }
}
