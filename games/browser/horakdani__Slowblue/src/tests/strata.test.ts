import { describe, expect, it } from 'vitest';
import type { BackdropKind } from '../src/render/Motif';
import { MOTIFS } from '../src/render/Motif';
import { paintFor } from '../src/render/Paint';
import { drawStrata, hasStrata, plannedStations, type Plane, type StrataView } from '../src/render/Strata';
import { H, W } from './helpers';

/**
 * Slowblue: the plane doctrine, as tests rather than as comments.
 *
 * `Strata.ts` is a table now, and a table is a thing forty-two entries get added
 * to by someone who has not read the paragraph above it. Everything asserted here
 * was learned by building the picture and getting it wrong:
 *
 *   - two masses on screen at once is a corridor, and the trench floor already
 *     lost its canyon walls for exactly that,
 *   - a mass whose top never shows is a wall whatever the file calls it,
 *   - `lighter` turns a second colour into haze the same hue as the water,
 *   - and the band the shoal swims in belongs to the shoal.
 */

/** Records what was drawn, in enough detail to test the shapes rather than the calls. */
class Recorder {
  fillStyle = '';
  strokeStyle = '';
  lineWidth = 1;
  lineCap = 'butt';
  globalCompositeOperation = 'source-over';
  /** Every composite op this frame was asked to paint in. */
  readonly ops = new Set<string>();
  /** One entry per fill() or stroke(): the alpha, and the path's extent. */
  readonly painted: {
    alpha: number;
    top: number;
    bottom: number;
    left: number;
    right: number;
    kind: 'fill' | 'stroke';
  }[] = [];
  /** Every coordinate handed to a path command, in order. Used for the still test. */
  readonly points: number[] = [];
  private top = Infinity;
  private bottom = -Infinity;
  private left = Infinity;
  private right = -Infinity;

  beginPath(): void {
    this.top = Infinity;
    this.bottom = -Infinity;
    this.left = Infinity;
    this.right = -Infinity;
  }
  private at(...xy: number[]): void {
    for (let i = 0; i + 1 < xy.length; i += 2) {
      this.points.push(xy[i]!, xy[i + 1]!);
      this.top = Math.min(this.top, xy[i + 1]!);
      this.bottom = Math.max(this.bottom, xy[i + 1]!);
      this.left = Math.min(this.left, xy[i]!);
      this.right = Math.max(this.right, xy[i]!);
    }
  }
  moveTo(x: number, y: number): void {
    this.at(x, y);
  }
  lineTo(x: number, y: number): void {
    this.at(x, y);
  }
  bezierCurveTo(a: number, b: number, c: number, d: number, e: number, f: number): void {
    this.at(a, b, c, d, e, f);
  }
  closePath(): void {}
  private record(kind: 'fill' | 'stroke', style: string): void {
    this.ops.add(this.globalCompositeOperation);
    const alpha = Number(style.slice(style.lastIndexOf(',') + 1, -1));
    this.painted.push({
      alpha,
      top: this.top,
      bottom: this.bottom,
      left: this.left,
      right: this.right,
      kind,
    });
  }
  fill(): void {
    this.record('fill', this.fillStyle);
  }
  stroke(): void {
    this.record('stroke', this.strokeStyle);
  }
  get ctx(): CanvasRenderingContext2D {
    return this as unknown as CanvasRenderingContext2D;
  }
}

function view(rec: Recorder, over: Partial<StrataView> = {}): StrataView {
  return {
    ctx: rec.ctx,
    paint: paintFor(2),
    w: W,
    h: H,
    cameraY: 0,
    time: 0,
    progress: 0.5,
    alpha: 1,
    quality: 1,
    ...over,
  };
}

/** One frame of one plane, at a camera position and a point through the station. */
function frame(kind: BackdropKind, plane: Plane, over: Partial<StrataView> = {}): Recorder {
  const rec = new Recorder();
  drawStrata(kind, view(rec, over), plane);
  return rec;
}

const STATIONS = plannedStations();
/** Camera positions across several stations' worth of travel, both directions. */
const SWEEP = Array.from({ length: 240 }, (_, i) => (i - 120) * 220);

describe('the plane table', () => {
  it('covers act I', () => {
    for (const motif of MOTIFS) expect([motif.key, hasStrata(motif.backdrop)]).toEqual([motif.key, true]);
  });

  it('never puts two masses on screen at once', () => {
    // A mass at a frame edge is a landmark. One down each edge at the same time is
    // a corridor, and the player steers around it and loses width they always had.
    for (const kind of STATIONS) {
      for (const cameraY of SWEEP) {
        const masses = frame(kind, 'far', { cameraY }).painted.filter((p) => p.kind === 'fill');
        expect([kind, cameraY, masses.length]).toEqual([kind, cameraY, Math.min(masses.length, 1)]);
      }
    }
  });

  it('never draws a mass taller than the frame', () => {
    // The one that started this: at 2.2 screens tall, no camera position showed a
    // summit, so every frame held one long near-vertical boundary running off both
    // edges. A thing you can see the ends of is a thing; this one you cannot.
    for (const kind of STATIONS) {
      for (const cameraY of SWEEP) {
        for (const p of frame(kind, 'far', { cameraY }).painted) {
          expect([kind, p.bottom - p.top < H]).toEqual([kind, true]);
        }
      }
    }
  });

  it('paints every plane with source-over', () => {
    for (const kind of STATIONS) {
      for (const plane of ['far', 'mid'] as const) {
        const rec = frame(kind, plane, { progress: 1 });
        expect([kind, plane, [...rec.ops]]).toEqual([kind, plane, rec.ops.size > 0 ? ['source-over'] : []]);
      }
    }
  });

  it('keeps the mid plane under a tenth of the contrast the shoal gets', () => {
    // The band down the middle of the frame is where the shoal lives, and the shoal
    // is the one thing in this game that is always allowed to be crisp.
    for (const kind of STATIONS) {
      for (const progress of [0, 0.5, 1]) {
        for (const p of frame(kind, 'mid', { progress }).painted) {
          expect([kind, progress, p.alpha <= 0.09]).toEqual([kind, progress, true]);
        }
      }
    }
  });

  it('stays inside the frame budget', () => {
    // ~0.5ms a frame for the whole pass is what the prototype measured, and what
    // costs that is filled area, so the count of large fills is the thing to hold.
    for (const kind of STATIONS) {
      let paths = 0;
      for (const plane of ['far', 'mid'] as const) {
        paths += frame(kind, plane, { progress: 1, cameraY: -1700 }).painted.length;
      }
      expect([kind, paths <= 24]).toEqual([kind, true]);
    }
  });

  it('lets the trench floor vents leave the frame', () => {
    // A light source that is a *place* in the water goes past like every other
    // place. Pointed at the frame edge instead, this fan sat in the two bottom
    // corners for the whole station and read as a rendering fault.
    const counts = SWEEP.map((cameraY) => frame('walls', 'mid', { cameraY }).painted.length);
    expect(counts.some((n) => n === 0)).toBe(true);
    expect(counts.some((n) => n > 0)).toBe(true);
  });

  it('keeps a vent plume clear of both frame edges', () => {
    // The play field is the full canvas width, and a lit wedge cut off by its edge
    // is the shape the trench floor lost its canyon walls for. A shaft from a sun
    // is allowed past the edge - it is a light level, not an object - so this is
    // asserted of the one station whose light is a thing in the water.
    for (const cameraY of SWEEP) {
      for (const progress of [0, 1]) {
        for (const p of frame('walls', 'mid', { cameraY, progress }).painted) {
          expect([cameraY, p.left > 0, p.right < W]).toEqual([cameraY, true, true]);
        }
      }
    }
  });

  it('draws nothing at all while a station is fading out', () => {
    for (const kind of STATIONS) {
      for (const plane of ['far', 'mid'] as const) {
        expect(frame(kind, plane, { alpha: 0 }).painted).toEqual([]);
      }
    }
  });
});
