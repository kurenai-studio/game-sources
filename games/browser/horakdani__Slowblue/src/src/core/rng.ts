/**
 * Slowblue: mulberry32. Small, fast, and — crucially for a falsification prototype —
 * reproducible, so "same seed" runs are byte-identical given the same inputs.
 */
export class Rng {
  private state: number;

  constructor(public readonly seed: number) {
    this.state = seed >>> 0;
  }

  next(): number {
    this.state = (this.state + 0x6d2b79f5) >>> 0;
    let t = this.state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  range(min: number, max: number): number {
    return min + (max - min) * this.next();
  }

  /** Symmetric noise in [-1, 1]. */
  signed(): number {
    return this.next() * 2 - 1;
  }

  int(minInclusive: number, maxExclusive: number): number {
    return minInclusive + Math.floor(this.next() * (maxExclusive - minInclusive));
  }

  fork(salt: number): Rng {
    return new Rng((this.seed ^ Math.imul(salt + 1, 0x9e3779b1)) >>> 0);
  }
}

/** Turns a user-typed seed string into a usable 32-bit seed. */
export function hashSeed(input: string): number {
  let h = 2166136261;
  for (let i = 0; i < input.length; i++) {
    h ^= input.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}
