import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

/**
 * The smallest source-map reader that can name an allocation site.
 *
 * The allocation probe in `measure.spec.ts` reports the stack V8 sampled, and
 * everything in a production bundle is on line 2 of one file with a mangled
 * name - `sample @ index-CnLPu3j1.js:2` names nothing, and a list of sites you
 * cannot open is a measurement you cannot act on. `build.sourcemap` is `'hidden'`
 * exactly for this: the `.map` stays on disk and off the wire, so the probe can
 * read it back.
 *
 * Deliberately not a dependency. What this needs is one lookup - generated
 * (line, column) to original (file, line, name) - and the whole of that is a VLQ
 * decoder and a binary search. Pulling `source-map` in for it would put a
 * package in the tree that only the measurement uses.
 */

const B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

/** Segment of one generated line: where it starts, and what it came from. */
interface Segment {
  genCol: number;
  srcIndex: number;
  srcLine: number;
  nameIndex: number;
}

export interface Origin {
  /** Repo-relative source file, e.g. `src/sim/World.ts`. */
  source: string;
  /** 1-based line in that file. */
  line: number;
  /** The name the minifier took away, when the map recorded one. */
  name: string | null;
}

interface RawMap {
  sources: string[];
  names: string[];
  mappings: string;
}

export class SourceMap {
  /** Generated line (0-based) -> segments, ascending by generated column. */
  private readonly lines: Segment[][] = [];
  private readonly sources: string[];
  private readonly names: string[];

  constructor(raw: RawMap) {
    this.sources = raw.sources.map((s) => s.replace(/^(\.\.\/)+/, ''));
    this.names = raw.names;

    // Every field but the generated column carries across segments *and* across
    // lines; the generated column resets at each `;`. Getting that wrong yields a
    // map that decodes without error and points at the wrong file, which is the
    // one failure mode worth being careful about here.
    let srcIndex = 0;
    let srcLine = 0;
    let nameIndex = 0;
    // Decoded and never read: nothing here wants the original *column*, but its
    // delta still has to be consumed in order, or every field after it in the
    // segment is read from the wrong offset.
    let _srcCol = 0;

    for (const group of raw.mappings.split(';')) {
      const segments: Segment[] = [];
      let genCol = 0;
      if (group !== '') {
        for (const segment of group.split(',')) {
          const fields = decodeVlq(segment);
          if (fields.length === 0) continue;
          genCol += fields[0]!;
          if (fields.length >= 4) {
            srcIndex += fields[1]!;
            srcLine += fields[2]!;
            _srcCol += fields[3]!;
            if (fields.length >= 5) nameIndex += fields[4]!;
            segments.push({
              genCol,
              srcIndex,
              srcLine,
              nameIndex: fields.length >= 5 ? nameIndex : -1,
            });
          }
        }
      }
      this.lines.push(segments);
    }
  }

  /**
   * The original position for a generated one, both 0-based as CDP reports them.
   *
   * The segment that owns a column is the last one starting at or before it, so
   * this is a binary search for the right-hand neighbour rather than an exact
   * match: V8 reports the column of the allocating instruction, which is almost
   * never the column a mapping starts at.
   */
  lookup(line: number, column: number): Origin | null {
    const segments = this.lines[line];
    if (segments === undefined || segments.length === 0) return null;
    let lo = 0;
    let hi = segments.length - 1;
    let found = -1;
    while (lo <= hi) {
      const mid = (lo + hi) >> 1;
      if (segments[mid]!.genCol <= column) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    if (found < 0) return null;
    const seg = segments[found]!;
    return {
      source: this.sources[seg.srcIndex] ?? '(unknown)',
      line: seg.srcLine + 1,
      name: seg.nameIndex >= 0 ? (this.names[seg.nameIndex] ?? null) : null,
    };
  }
}

function decodeVlq(segment: string): number[] {
  const out: number[] = [];
  let value = 0;
  let shift = 0;
  for (const ch of segment) {
    const digit = B64.indexOf(ch);
    if (digit < 0) return out;
    value += (digit & 31) << shift;
    if ((digit & 32) !== 0) {
      shift += 5;
      continue;
    }
    // Bit 0 is the sign, and it is a sign bit rather than two's complement:
    // -0 is a legal encoding and means "no change", which is why this is not a
    // shift-and-negate.
    out.push((value & 1) !== 0 ? -(value >> 1) : value >> 1);
    value = 0;
    shift = 0;
  }
  return out;
}

/**
 * Loads the map for the built bundle, keyed by the file name V8 will report.
 *
 * Returns an empty map rather than throwing when `dist` has no maps in it: the
 * probe's job is to produce a number, and it must still produce one against a
 * build made without them. The names simply stay minified.
 */
export function loadBundleMaps(dist = 'dist/assets'): Map<string, SourceMap> {
  const out = new Map<string, SourceMap>();
  let files: string[];
  try {
    files = readdirSync(dist);
  } catch {
    return out;
  }
  for (const file of files) {
    if (!file.endsWith('.js.map')) continue;
    const raw = JSON.parse(readFileSync(join(dist, file), 'utf8')) as RawMap;
    out.set(file.slice(0, -4), new SourceMap(raw));
  }
  return out;
}
