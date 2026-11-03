export interface TilePoint {
  tx: number;
  ty: number;
}

/**
 * A* over the tile grid with 8-way movement. Diagonal steps may not cut wall corners, so a
 * path never squeezes between two walls that only touch at a corner.
 *
 * @param passable whether a tile can be walked through (closed doors count: AI opens them)
 * @param cost optional extra cost for entering a tile, e.g. to prefer open doors
 * @returns the tiles from start (exclusive) to goal (inclusive), or null when unreachable
 */
export function findPath(
  width: number,
  height: number,
  start: TilePoint,
  goal: TilePoint,
  passable: (tx: number, ty: number) => boolean,
  cost: (tx: number, ty: number) => number = () => 0,
  maxNodes = 4000,
): TilePoint[] | null {
  if (!passable(goal.tx, goal.ty)) return null;
  if (start.tx === goal.tx && start.ty === goal.ty) return [];
  const key = (x: number, y: number) => y * width + x;
  const inBounds = (x: number, y: number) => x >= 0 && y >= 0 && x < width && y < height;
  const h = (x: number, y: number) => {
    const dx = Math.abs(x - goal.tx), dy = Math.abs(y - goal.ty);
    return Math.max(dx, dy) + (Math.SQRT2 - 1) * Math.min(dx, dy);
  };

  const g = new Map<number, number>([[key(start.tx, start.ty), 0]]);
  const came = new Map<number, number>();
  const open: { x: number; y: number; f: number }[] = [{ x: start.tx, y: start.ty, f: h(start.tx, start.ty) }];
  const closed = new Set<number>();

  while (open.length && closed.size < maxNodes) {
    // Small open lists: a linear scan is simpler than a heap and fast enough at this scale.
    let bi = 0;
    for (let i = 1; i < open.length; i++) if (open[i].f < open[bi].f) bi = i;
    const cur = open.splice(bi, 1)[0];
    const ck = key(cur.x, cur.y);
    if (closed.has(ck)) continue;
    closed.add(ck);
    if (cur.x === goal.tx && cur.y === goal.ty) {
      const path: TilePoint[] = [];
      let k = ck;
      while (k !== key(start.tx, start.ty)) {
        path.push({ tx: k % width, ty: Math.floor(k / width) });
        k = came.get(k)!;
      }
      return path.reverse();
    }
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        if (!dx && !dy) continue;
        const nx = cur.x + dx, ny = cur.y + dy;
        if (!inBounds(nx, ny) || !passable(nx, ny)) continue;
        if (dx && dy && (!passable(cur.x + dx, cur.y) || !passable(cur.x, cur.y + dy))) continue;
        const nk = key(nx, ny);
        if (closed.has(nk)) continue;
        const ng = g.get(ck)! + (dx && dy ? Math.SQRT2 : 1) + cost(nx, ny);
        if (ng < (g.get(nk) ?? Infinity)) {
          g.set(nk, ng);
          came.set(nk, ck);
          open.push({ x: nx, y: ny, f: ng + h(nx, ny) });
        }
      }
    }
  }
  return null;
}
