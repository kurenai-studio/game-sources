function hashString(input: string): number {
  let hash = 0x811c9dc5;
  for (let index = 0; index < input.length; index += 1) {
    hash ^= input.charCodeAt(index);
    hash = Math.imul(hash, 0x01000193);
  }
  return hash >>> 0;
}

export class SeededRng {
  readonly seed: string;
  private state: number;

  constructor(seed: string) {
    this.seed = seed || 'MOURNWELL';
    this.state = hashString(this.seed) || 0x6d2b79f5;
  }

  next(): number {
    this.state = (this.state + 0x6d2b79f5) >>> 0;
    let value = this.state;
    value = Math.imul(value ^ (value >>> 15), value | 1);
    value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
  }

  int(min: number, max: number): number {
    if (max < min) throw new RangeError('max must be greater than or equal to min');
    return Math.floor(this.next() * (max - min + 1)) + min;
  }

  float(min: number, max: number): number {
    return min + this.next() * (max - min);
  }

  bool(chance = 0.5): boolean {
    return this.next() < chance;
  }

  pick<T>(items: readonly T[]): T {
    if (items.length === 0) throw new RangeError('Cannot pick from an empty collection');
    const item = items[this.int(0, items.length - 1)];
    if (item === undefined) throw new Error('Seeded selection failed');
    return item;
  }

  shuffle<T>(items: readonly T[]): T[] {
    const copy = [...items];
    for (let index = copy.length - 1; index > 0; index -= 1) {
      const swapIndex = this.int(0, index);
      [copy[index], copy[swapIndex]] = [copy[swapIndex] as T, copy[index] as T];
    }
    return copy;
  }

  fork(label: string): SeededRng {
    return new SeededRng(`${this.seed}::${label}`);
  }
}

export function createReadableSeed(): string {
  const words = ['ASH', 'BELL', 'MOTH', 'WICK', 'SILT', 'VEIL', 'BONE', 'HUSH'];
  const bytes = new Uint32Array(2);
  globalThis.crypto.getRandomValues(bytes);
  const left = words[(bytes[0] ?? 0) % words.length] ?? 'ASH';
  const right = words[(bytes[1] ?? 0) % words.length] ?? 'BELL';
  const number = String((((bytes[0] ?? 0) ^ (bytes[1] ?? 0)) >>> 0) % 10000).padStart(4, '0');
  return `${left}-${right}-${number}`;
}
