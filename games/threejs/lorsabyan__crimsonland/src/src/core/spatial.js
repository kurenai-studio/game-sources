// Uniform grid over the arena. Rebuilt every tick; query results land in `out`.
export class Grid {
  constructor(half, cell, capacity) {
    this.half = half; this.cell = cell;
    this.w = Math.ceil((half * 2) / cell);
    this.head = new Int32Array(this.w * this.w).fill(-1);
    this.next = new Int32Array(capacity);
    this.out = new Int32Array(capacity);
    this.count = 0;
  }
  clear() { this.head.fill(-1); }
  key(v) { const k = Math.floor((v + this.half) / this.cell); return k < 0 ? 0 : k >= this.w ? this.w - 1 : k; }
  insert(id, x, z) {
    const c = this.key(z) * this.w + this.key(x);
    this.next[id] = this.head[c];
    this.head[c] = id;
  }
  // Fills this.out with ids from every cell the circle touches. Returns the count.
  query(x, z, r) {
    const x0 = this.key(x - r), x1 = this.key(x + r), z0 = this.key(z - r), z1 = this.key(z + r);
    let n = 0;
    for (let cz = z0; cz <= z1; cz++) {
      for (let cx = x0; cx <= x1; cx++) {
        for (let id = this.head[cz * this.w + cx]; id !== -1; id = this.next[id]) this.out[n++] = id;
      }
    }
    return (this.count = n);
  }
}
