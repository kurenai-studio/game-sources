import { describe, expect, it } from 'vitest';
import { expectFinite, FakeContext } from './canvas';
import { drawHunter, drawThreat } from '../src/render/Hunter';
import { paintFor } from '../src/render/Paint';

const SIZE = 17;

function view(rec: FakeContext, quality = 1) {
  return {
    ctx: rec.as2d,
    paint: paintFor(3),
    accent: [255, 244, 194] as [number, number, number],
    time: 2.4,
    quality,
  };
}

/**
 * The body outline in body coordinates, for a hunter heading straight up the screen:
 * `along` is toward the snout, `across` is to its right. Drawn at the quality where
 * neither the cast shadow nor the fins are traced, so the recorded points are the
 * body and nothing else.
 */
function outline(beat = 0, lunge = 0): { along: number; across: number }[] {
  const rec = new FakeContext();
  drawHunter(view(rec, 0.5), 0, 0, 0, -1, SIZE, lunge, beat);
  const stop = rec.firstArc < 0 ? rec.points.length : rec.firstArc;
  return rec.points.slice(0, stop).map((p) => ({ along: -p.y, across: p.x }));
}

describe('the hunter silhouette', () => {
  it('is an animal: a snout in front, a tail behind, and a body between them', () => {
    const pts = outline();
    expect(pts.length).toBeGreaterThan(8);
    const nose = pts.reduce((a, b) => (b.along > a.along ? b : a));
    const tail = pts.reduce((a, b) => (b.along < a.along ? b : a));
    expect(nose.along).toBeGreaterThan(0);
    expect(tail.along).toBeLessThan(0);
    // The snout is on the centre line and it is the narrow end.
    expect(Math.abs(nose.across)).toBeLessThan(SIZE * 0.1);
    // Long, not squat: this reads as a fast open-water fish at a glance.
    const length = nose.along - tail.along;
    const width = 2 * Math.max(...pts.map((p) => Math.abs(p.across)));
    expect(length / width).toBeGreaterThan(1.6);
  });

  it('is widest at the pectorals, in the front half of the body', () => {
    const pts = outline();
    const widest = pts.reduce((a, b) => (Math.abs(b.across) > Math.abs(a.across) ? b : a));
    const nose = Math.max(...pts.map((p) => p.along));
    const tail = Math.min(...pts.map((p) => p.along));
    // Excluding the tail lobes, which are wider still: those are the two extremes.
    const bodyOnly = pts.filter((p) => p.along > tail + (nose - tail) * 0.35);
    const bodyWidest = bodyOnly.reduce((a, b) => (Math.abs(b.across) > Math.abs(a.across) ? b : a));
    expect(bodyWidest.along).toBeGreaterThan((nose + tail) * 0.5);
    expect(Math.abs(widest.across)).toBeGreaterThan(0);
  });

  it('has a lunate tail: one lobe reaches further than the other', () => {
    // Averaged over a whole beat, because the spine wave slides both lobes sideways
    // together - the asymmetry is in the tail's build, not in where it happens to be.
    let upper = 0;
    let lower = 0;
    let upperAlong = 0;
    let lowerAlong = 0;
    const beats = 8;
    for (let i = 0; i < beats; i++) {
      const pts = outline((i / beats) * Math.PI * 2);
      const tail = Math.min(...pts.map((p) => p.along));
      const lobes = pts.filter((p) => p.along < tail + SIZE * 0.25);
      const top = lobes.reduce((a, b) => (b.across > a.across ? b : a));
      const bottom = lobes.reduce((a, b) => (b.across < a.across ? b : a));
      expect(top.across).toBeGreaterThan(0);
      expect(bottom.across).toBeLessThan(0);
      upper += top.across;
      lower += -bottom.across;
      upperAlong += top.along;
      lowerAlong += bottom.along;
    }
    // A symmetric fork is a tuna, or a logo. This one is wider on one side and
    // trails further back on it too, which is the shark's own signature.
    expect(upper / lower).toBeGreaterThan(1.15);
    expect(upperAlong).toBeLessThan(lowerAlong);
  });

  it('swims: the body flexes with the beat, and stiffens when it commits', () => {
    const swing = (lunge: number): number => {
      const at = [0, 1.1, 2.2, 3.3, 4.4, 5.5].map((beat) => {
        const pts = outline(beat, lunge);
        const tail = pts.reduce((a, b) => (b.along < a.along ? b : a));
        return tail.across;
      });
      return Math.max(...at) - Math.min(...at);
    };
    const cruising = swing(0);
    expect(cruising).toBeGreaterThan(1);
    // A strike is a straight line: the last metre is not a swimming stroke.
    expect(swing(1)).toBeLessThan(cruising);
  });
});

describe('drawing a hunter', () => {
  it('never emits a bad coordinate, at any quality or state', () => {
    for (const lunge of [0, 0.4, 1]) {
      for (const quality of [0.45, 0.7, 1]) {
        const rec = new FakeContext();
        drawThreat(view(rec, quality), 190, 400, SIZE, lunge);
        drawHunter(view(rec, quality), 190, 400, 0.6, -0.8, SIZE, lunge, 3.1);
        expectFinite(rec, `hunter lunge ${lunge} q${quality}`);
      }
    }
  });

  it('handles a hunter that is not moving without pointing it nowhere', () => {
    // A stationary hunter has no heading to normalise; the renderer hands it -y.
    const rec = new FakeContext();
    drawHunter(view(rec, 1), 50, 60, 0, -1, SIZE, 0, 0);
    expectFinite(rec, 'stationary hunter');
    expect(rec.fills).toBeGreaterThan(0);
  });

  it('draws two rings that say different things, and keeps them apart', () => {
    const rec = new FakeContext();
    drawThreat(view(rec), 0, 0, SIZE, 0);
    const radii = rec.arcs.map((a) => a.r).sort((a, b) => a - b);
    expect(radii.length).toBeGreaterThanOrEqual(2);
    const strike = radii[0]!;
    const dread = radii[radii.length - 1]!;
    // Where a strike lands, and where the water starts feeling wrong. The first has to
    // be small enough that hugging the edge of the second is a real choice.
    expect(strike).toBeGreaterThan(SIZE * 1.5);
    expect(strike).toBeLessThan(dread * 0.5);
  });

  it('opens its eye as it commits - the one bright point on the animal', () => {
    const eye = (lunge: number): number => {
      const rec = new FakeContext();
      drawHunter(view(rec, 0.5), 0, 0, 0, -1, SIZE, lunge, 0);
      // At this quality the eye is the only arc a hunter draws.
      expect(rec.arcs).toHaveLength(1);
      return rec.arcs[0]!.r;
    };
    expect(eye(1)).toBeGreaterThan(eye(0));
  });
});
