// Seeded deterministic RNG (mulberry32) — pure module, no three imports.

export function mulberry32(seed) {
  let a = seed >>> 0;
  return function next() {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export class Rng {
  constructor(seed = 1337) {
    this.seed = seed >>> 0;
    this._next = mulberry32(this.seed);
  }

  float(min = 0, max = 1) {
    return min + (max - min) * this._next();
  }

  int(min, max) {
    // inclusive min, exclusive max
    return Math.floor(this.float(min, max));
  }

  pick(list) {
    return list[Math.min(list.length - 1, Math.floor(this._next() * list.length))];
  }

  sign() {
    return this._next() < 0.5 ? -1 : 1;
  }

  chance(p) {
    return this._next() < p;
  }
}
