import { clamp } from '../core/math';

/**
 * Slowblue: grid-based transient velocity field. Deliberately *not* a fluid solver -
 * no pressure projection, no advection of the field itself. What we need is:
 * a gesture deposits momentum, momentum spreads a little, momentum fades.
 * That is enough to make a stroke read as water and to keep it cheap on a phone.
 *
 * The grid is anchored in world space via `originY` and scrolls in whole cells as
 * the camera advances (`shiftTo`), so a current stays with the water, not the screen.
 */
export class FlowField {
  readonly cell: number;
  readonly cols: number;
  readonly rows: number;
  readonly vx: Float32Array;
  readonly vy: Float32Array;
  private readonly tx: Float32Array;
  private readonly ty: Float32Array;
  /** World Y of the grid's top edge. Always a multiple of `cell`. */
  originY = 0;

  constructor(width: number, height: number, cell = 24, marginCells = 3) {
    this.cell = cell;
    this.cols = Math.max(2, Math.ceil(width / cell) + 1);
    this.rows = Math.max(2, Math.ceil(height / cell) + 1 + marginCells * 2);
    const n = this.cols * this.rows;
    this.vx = new Float32Array(n);
    this.vy = new Float32Array(n);
    this.tx = new Float32Array(n);
    this.ty = new Float32Array(n);
  }

  get height(): number {
    return this.rows * this.cell;
  }

  clear(): void {
    this.vx.fill(0);
    this.vy.fill(0);
  }

  index(cx: number, cy: number): number {
    return cy * this.cols + cx;
  }

  /**
   * Deposits a Gaussian blob of velocity. `radius` is the visual reach; sigma is
   * half of it so the edge is soft but the blob does not look wider than the finger.
   */
  addImpulse(x: number, y: number, fx: number, fy: number, radius: number): void {
    const { cell, cols, rows } = this;
    const gy = (y - this.originY) / cell - 0.5;
    const gx = x / cell - 0.5;
    const r = radius / cell;
    const sigma = Math.max(0.35, r * 0.5);
    const inv2s2 = 1 / (2 * sigma * sigma);
    const x0 = Math.max(0, Math.floor(gx - r));
    const x1 = Math.min(cols - 1, Math.ceil(gx + r));
    const y0 = Math.max(0, Math.floor(gy - r));
    const y1 = Math.min(rows - 1, Math.ceil(gy + r));
    for (let cy = y0; cy <= y1; cy++) {
      const dy = cy - gy;
      for (let cx = x0; cx <= x1; cx++) {
        const dx = cx - gx;
        const d2 = dx * dx + dy * dy;
        if (d2 > r * r) continue;
        const w = Math.exp(-d2 * inv2s2);
        const i = cy * cols + cx;
        this.vx[i] += fx * w;
        this.vy[i] += fy * w;
      }
    }
  }

  /** Bilinear sample at a world position. Writes into `out` to avoid allocation. */
  sample(x: number, y: number, out: { x: number; y: number }): void {
    const { cell, cols, rows } = this;
    const gx = clamp(x / cell - 0.5, 0, cols - 1);
    const gy = clamp((y - this.originY) / cell - 0.5, 0, rows - 1);
    const ix = Math.floor(gx);
    const iy = Math.floor(gy);
    const jx = Math.min(ix + 1, cols - 1);
    const jy = Math.min(iy + 1, rows - 1);
    const tx = gx - ix;
    const ty = gy - iy;
    const i00 = iy * cols + ix;
    const i10 = iy * cols + jx;
    const i01 = jy * cols + ix;
    const i11 = jy * cols + jx;
    const w00 = (1 - tx) * (1 - ty);
    const w10 = tx * (1 - ty);
    const w01 = (1 - tx) * ty;
    const w11 = tx * ty;
    out.x = this.vx[i00] * w00 + this.vx[i10] * w10 + this.vx[i01] * w01 + this.vx[i11] * w11;
    out.y = this.vy[i00] * w00 + this.vy[i10] * w10 + this.vy[i01] * w01 + this.vy[i11] * w11;
  }

  /**
   * Speed clamp + decay + one Jacobi diffusion pass.
   *
   * Slowblue: the decay is deliberately *non-linear* in speed. A linear half-life makes
   * every gesture behave the same way, which collapsed the design into a single
   * dominant strategy (measured). With `turbulence > 0` a violent current dissipates
   * quickly while a gentle one persists, so a flick becomes a short precise tool and
   * a slow drag becomes a durable one - two different instruments, one rule.
   */
  step(dt: number, halfLife: number, diffusion: number, maxSpeed = Infinity, turbulence = 0): void {
    const baseRate = Math.LN2 / Math.max(0.01, halfLife);
    const { vx, vy, tx, ty, cols, rows } = this;
    const n = cols * rows;
    if (turbulence <= 0 && maxSpeed === Infinity) {
      const decay = Math.exp(-baseRate * dt);
      for (let i = 0; i < n; i++) {
        vx[i] *= decay;
        vy[i] *= decay;
      }
    } else {
      for (let i = 0; i < n; i++) {
        const x = vx[i];
        const y = vy[i];
        if (x === 0 && y === 0) continue;
        let speed = Math.hypot(x, y);
        let cx = x;
        let cy = y;
        if (speed > maxSpeed) {
          const s = maxSpeed / speed;
          cx = x * s;
          cy = y * s;
          speed = maxSpeed;
        }
        const decay = Math.exp(-(baseRate + (turbulence * speed) / 1000) * dt);
        vx[i] = cx * decay;
        vy[i] = cy * decay;
      }
    }
    const k = Math.min(0.5, diffusion * dt);
    if (k <= 0) return;
    for (let cy = 0; cy < rows; cy++) {
      const up = cy > 0 ? -cols : 0;
      const dn = cy < rows - 1 ? cols : 0;
      for (let cx = 0; cx < cols; cx++) {
        const i = cy * cols + cx;
        const lf = cx > 0 ? -1 : 0;
        const rt = cx < cols - 1 ? 1 : 0;
        const ax = (vx[i + up] + vx[i + dn] + vx[i + lf] + vx[i + rt]) * 0.25;
        const ay = (vy[i + up] + vy[i + dn] + vy[i + lf] + vy[i + rt]) * 0.25;
        tx[i] = vx[i] + (ax - vx[i]) * k;
        ty[i] = vy[i] + (ay - vy[i]) * k;
      }
    }
    vx.set(tx);
    vy.set(ty);
  }

  /**
   * Scrolls the grid so its top edge sits at (or just above) `desiredOriginY`.
   * Rows that enter the grid are cleared: water we have never seen is still water.
   */
  shiftTo(desiredOriginY: number): void {
    const { cell, cols, rows, vx, vy } = this;
    const snapped = Math.floor(desiredOriginY / cell) * cell;
    let delta = Math.round((snapped - this.originY) / cell);
    if (delta === 0) return;
    if (Math.abs(delta) >= rows) {
      this.clear();
      this.originY = snapped;
      return;
    }
    if (delta > 0) {
      // Grid moved down in world space: content shifts up in the array.
      vx.copyWithin(0, delta * cols);
      vy.copyWithin(0, delta * cols);
      vx.fill(0, (rows - delta) * cols);
      vy.fill(0, (rows - delta) * cols);
    } else {
      delta = -delta;
      vx.copyWithin(delta * cols, 0, (rows - delta) * cols);
      vy.copyWithin(delta * cols, 0, (rows - delta) * cols);
      vx.fill(0, 0, delta * cols);
      vy.fill(0, 0, delta * cols);
    }
    this.originY = snapped;
  }

  /** Mean speed over the grid - cheap health metric for the debug panel. */
  meanSpeed(): number {
    const n = this.cols * this.rows;
    let s = 0;
    for (let i = 0; i < n; i++) s += Math.hypot(this.vx[i], this.vy[i]);
    return s / n;
  }
}
