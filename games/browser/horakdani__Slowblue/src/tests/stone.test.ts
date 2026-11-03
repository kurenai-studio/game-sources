import { describe, expect, it } from 'vitest';
import { expectFinite, FakeContext } from './canvas';
import { AIR_MOTIFS, MOTIFS } from '../src/render/Motif';
import { paintFor } from '../src/render/Paint';
import { Renderer } from '../src/render/Renderer';
import { paintStone } from '../src/render/RockPaint';
import { CREST_STEP, invalidateStoneMasses, ROUGHEN_MAX, stoneMasses } from '../src/render/Stone';
import type { Blob } from '../src/sim/ObstacleSystem';

const VERTS = 16;
const SMALL = 12;
const JAG = 0.03;

function masses(blobs: Blob[]): ReturnType<typeof stoneMasses> {
  return stoneMasses(blobs, VERTS, SMALL, JAG);
}

/** A wall the way `ObstacleSystem.chain` builds one: overlapping beads in a row. */
function wall(from: number, to: number, y: number, r: number): Blob[] {
  const out: Blob[] = [];
  const step = r * 0.6;
  for (let x = from; x <= to; x += step) out.push({ x, y, r });
  return out;
}

describe('stone masses', () => {
  it('merges a chain of beads into one silhouette and keeps separate rocks apart', () => {
    expect(masses(wall(0, 200, 0, 18))).toHaveLength(1);
    expect(masses([...wall(0, 120, 0, 18), ...wall(400, 520, 0, 18)])).toHaveLength(2);
  });

  it('lights only the edge that faces up the course', () => {
    for (const mass of masses([{ x: 100, y: 0, r: 40 }])) {
      const crest = mass.crest;
      expect(crest.length).toBeGreaterThan(8);
      for (let i = 0; i < crest.length; i += 4) {
        // Ahead is -y, so every crest normal must lean that way...
        expect(crest[i + 3]!).toBeLessThan(0);
        // ...and be a unit vector, because the fringe is planted along it.
        expect(Math.hypot(crest[i + 2]!, crest[i + 3]!)).toBeCloseTo(1, 6);
      }
    }
  });

  it('walks the crest in one direction, at roughly one sample per step', () => {
    const mass = masses([{ x: 120, y: 0, r: 60 }])[0]!;
    const crest = mass.crest;
    let prevX = crest[0]!;
    let increasing: boolean | null = null;
    for (let i = 4; i < crest.length; i += 4) {
      const x = crest[i]!;
      const dx = x - prevX;
      if (Math.abs(dx) > 1e-6) {
        const up = dx > 0;
        if (increasing === null) increasing = up;
        // A convex up-facing arc crosses the mass once: a reversal means the walk
        // wrapped round onto a flank, which would light the side of the rock.
        expect(up, `reversal at sample ${i / 4}`).toBe(increasing);
      }
      const gap = Math.hypot(x - prevX, crest[i + 1]! - crest[i - 3]!);
      expect(gap).toBeLessThanOrEqual(CREST_STEP * 1.6);
      prevX = x;
    }
    expect(increasing).not.toBeNull();
  });

  it('errs outward, never inward: no rock is drawn smaller than it collides', () => {
    // The direction of this tolerance is the whole point. A silhouette a few pixels
    // *wider* than its collision circle costs nothing - the shoal simply never touches
    // the drawn edge. A silhouette narrower than it puts invisible stone in open water.
    const blob = { x: 90, y: 40, r: 52 };
    const mass = masses([blob])[0]!;
    for (let i = 0; i < mass.crest.length; i += 4) {
      const d = Math.hypot(mass.crest[i]! - blob.x, mass.crest[i + 1]! - blob.y);
      expect(d).toBeGreaterThan(blob.r * 0.97);
      expect(d).toBeLessThan(blob.r * (1 + JAG * 2) + ROUGHEN_MAX);
    }
  });

  it('lands on the rock the flock collides with after the world is rescaled', () => {
    // What a turn of the device does: `World.resize` multiplies every blob's x and
    // r by the width ratio. The cache is keyed on the blob object and holds world
    // coordinates, so it cannot see that happen - and a silhouette left at the old
    // width is a rock drawn where nothing stops the shoal, plus a wall in what
    // looks like open water. Both halves of the report, from one stale hull.
    const blob: Blob = { x: 600, y: 0, r: 60 };
    const before = masses([blob])[0]!;
    expect(before.centreX).toBeGreaterThan(500);

    const ratio = 820 / 1180;
    blob.x *= ratio;
    blob.r *= ratio;
    // Stale on purpose, and stated here because it is the reason the call below
    // exists: nothing in this module can notice the mutation.
    expect(masses([blob])[0]).toBe(before);

    invalidateStoneMasses();
    const after = masses([blob])[0]!;
    expect(after).not.toBe(before);
    // Inside the new collision circle, by the same outward-only tolerance the test
    // above pins down - the drawn edge may sit a little wide, never adrift.
    const slack = blob.r * JAG * 2 + ROUGHEN_MAX;
    expect(after.minX).toBeGreaterThan(blob.x - blob.r - slack);
    expect(after.maxX).toBeLessThan(blob.x + blob.r + slack);
  });

  it('is dropped by the renderer on a width change, and kept on a dpr change', () => {
    // The wiring, not just the switch: a rotation reaches this cache through
    // `Renderer.resize`, and the quality ladder reaches the same method several
    // times a run without moving a single rock.
    const rec = new FakeContext();
    const canvas = {
      getContext: () => rec.as2d,
      width: 0,
      height: 0,
      style: {} as CSSStyleDeclaration,
    } as unknown as HTMLCanvasElement;
    const renderer = new Renderer(canvas);
    renderer.resize(1180, 820, 2);

    const blob: Blob = { x: 400, y: 0, r: 40 };
    const built = masses([blob])[0]!;
    renderer.resize(1180, 820, 1.6);
    expect(masses([blob])[0], 'a rung of the quality ladder').toBe(built);
    renderer.resize(820, 1180, 2);
    expect(masses([blob])[0], 'a turn of the device').not.toBe(built);
  });

  it('gives an empty mass an empty crest rather than throwing', () => {
    expect(masses([]).length).toBe(0);
    const tiny = masses([{ x: 10, y: 10, r: 0.001 }]);
    expect(tiny.length).toBe(1);
    expect(tiny[0]!.crest.length % 4).toBe(0);
  });
});

describe('stone painting', () => {
  const shapes: [string, Blob[]][] = [
    ['a wall', wall(-20, 180, 300, 18)],
    ['a boulder', [{ x: 200, y: 300, r: 74 }]],
    ['a rock with lobes', [
      { x: 200, y: 300, r: 70 },
      { x: 156, y: 340, r: 35 },
      { x: 246, y: 265, r: 32 },
    ]],
  ];

  it('paints every material of every level without a bad number in it', () => {
    // Both acts' tables: the air's cloud material has its own paint path (no
    // strata, no fractures, a shaded base), and it has to hold up on the same
    // shapes at the same qualities as every stone does.
    for (const motif of [...MOTIFS, ...AIR_MOTIFS]) {
      for (const [what, blobs] of shapes) {
        for (const quality of [0.45, 0.7, 1]) {
          const rec = new FakeContext();
          paintStone(
            {
              ctx: rec.as2d,
              paint: paintFor(motif.index >> 1),
              motif,
              cameraY: 200,
              h: 844,
              time: 3.2,
              quality,
            },
            masses(blobs),
          );
          expectFinite(rec, `${motif.key} on ${what} at q${quality}`);
          expect(rec.fills, `${motif.key} on ${what}`).toBeGreaterThan(0);
        }
      }
    }
  });

  it('lights the crest additively - that is the whole point of it', () => {
    const rec = new FakeContext();
    paintStone(
      {
        ctx: rec.as2d,
        paint: paintFor(0),
        motif: MOTIFS[0]!,
        cameraY: 200,
        h: 844,
        time: 1,
        quality: 1,
      },
      masses(shapes[1]![1]),
    );
    expect(rec.composites.has('lighter')).toBe(true);
  });

  it('skips masses the camera has left behind entirely', () => {
    const rec = new FakeContext();
    paintStone(
      {
        ctx: rec.as2d,
        paint: paintFor(0),
        motif: MOTIFS[2]!,
        cameraY: -4000,
        h: 844,
        time: 1,
        quality: 1,
      },
      masses(shapes[0]![1]),
    );
    expect(rec.fills).toBe(0);
    expect(rec.strokes).toBe(0);
  });
});
