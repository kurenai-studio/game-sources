/**
 * Moves a circle through a tile grid, sliding along walls. Axis-separated so the operator slides
 * smoothly along walls instead of sticking to them.
 */
export function moveCircle(
  x: number,
  y: number,
  dx: number,
  dy: number,
  radius: number,
  tileSize: number,
  solid: (tx: number, ty: number) => boolean,
): { x: number; y: number } {
  // Substep so a long frame can never tunnel through a wall.
  const steps = Math.max(1, Math.ceil(Math.max(Math.abs(dx), Math.abs(dy)) / (radius * 0.5)));
  let p = { x, y };
  for (let i = 0; i < steps; i++) {
    p = resolve(p.x + dx / steps, p.y, radius, tileSize, solid);
    p = resolve(p.x, p.y + dy / steps, radius, tileSize, solid);
  }
  return p;
}

function resolve(
  x: number,
  y: number,
  r: number,
  ts: number,
  solid: (tx: number, ty: number) => boolean,
): { x: number; y: number } {
  for (let pass = 0; pass < 3; pass++) {
    let moved = false;
    const x0 = Math.floor((x - r) / ts), x1 = Math.floor((x + r) / ts);
    const y0 = Math.floor((y - r) / ts), y1 = Math.floor((y + r) / ts);
    for (let ty = y0; ty <= y1; ty++) {
      for (let tx = x0; tx <= x1; tx++) {
        if (!solid(tx, ty)) continue;
        const rx = tx * ts, ry = ty * ts;
        const nx = Math.max(rx, Math.min(x, rx + ts));
        const ny = Math.max(ry, Math.min(y, ry + ts));
        let ddx = x - nx, ddy = y - ny;
        const d2 = ddx * ddx + ddy * ddy;
        if (d2 >= r * r) continue;
        if (d2 === 0) {
          // Centre inside the tile: push out along the shallowest axis.
          const left = x - rx, right = rx + ts - x, top = y - ry, bottom = ry + ts - y;
          const m = Math.min(left, right, top, bottom);
          if (m === left) x = rx - r;
          else if (m === right) x = rx + ts + r;
          else if (m === top) y = ry - r;
          else y = ry + ts + r;
        } else {
          const d = Math.sqrt(d2);
          ddx /= d;
          ddy /= d;
          x = nx + ddx * r;
          y = ny + ddy * r;
        }
        moved = true;
      }
    }
    if (!moved) break;
  }
  return { x, y };
}
