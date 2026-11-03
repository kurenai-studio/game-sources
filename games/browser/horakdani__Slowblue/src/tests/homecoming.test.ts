import { describe, expect, it } from 'vitest';
import { drawBackdrop } from '../src/render/Backdrop';
import { HOME_MOTIFS, motifsForAct } from '../src/render/Motif';
import { paintFor } from '../src/render/Paint';
import { HOME_LEVELS } from '../src/config/homecoming';
import { FakeContext, expectFinite } from './canvas';

/**
 * Slowblue: act VII's six backdrops, held to the contract the climb's are.
 *
 * `tests/sky.test.ts` did this for act II and act III when they were the new
 * acts, and nothing was ever written for the four that came after - so the
 * campaign's last six pictures were covered by exactly one thing, the e2e pass
 * that photographs a station and asks whether the frame is flat. That pass shot
 * this act clean while the sunlit zone's light shafts each ended at a hard line
 * across their own width, because a shaft is a seventh of the frame and both
 * sweep instruments want the whole of it to agree.
 *
 * What is asserted here is what a recording context honestly can: that every
 * station draws, at every point of itself and on every quality rung; that none of
 * them leaves a composite mode behind; that a crossfade can take them to nothing.
 * The two act-specific ones below are the act's own sentences, which is the part
 * a screenshot cannot check.
 */

function view(
  rec: FakeContext,
  zone: number,
  progress: number,
  quality = 1,
  cameraY = 4200,
): Parameters<typeof drawBackdrop>[2] {
  return {
    ctx: rec.as2d,
    paint: paintFor(zone),
    w: 390,
    h: 844,
    // Act VII falls, so its camera runs the other way from the climb's.
    cameraY,
    time: 12.5,
    breath: 0.62,
    progress,
    alpha: 1,
    quality,
  };
}

const HOME = HOME_MOTIFS.map((motif, i) => ({ motif, zone: HOME_LEVELS[i]!.zone }));

describe('the homecoming', () => {
  it('draws every station of the descent without a single bad number', () => {
    for (const { motif, zone } of HOME) {
      for (const progress of [0, 0.5, 1]) {
        for (const quality of [0.45, 1]) {
          const rec = new FakeContext();
          drawBackdrop(motif.backdrop, motif, view(rec, zone, progress, quality));
          expectFinite(rec, `${motif.key} p=${progress} q=${quality}`);
          expect(rec.fills + rec.strokes, `${motif.key} drew nothing`).toBeGreaterThan(0);
        }
      }
    }
  });

  it('leaves the composite mode where it found it', () => {
    // Every one of these six ends on `lighter` somewhere in the middle of itself:
    // the surface, the bioluminescence, the vents and the gold are all additive.
    // A backdrop that returns with it still set tints the swarm and the HUD.
    for (const { motif, zone } of HOME) {
      const rec = new FakeContext();
      drawBackdrop(motif.backdrop, motif, view(rec, zone, 0.5));
      expect(rec.globalCompositeOperation, motif.key).toBe('source-over');
    }
  });

  it('respects alpha, so a station crossfade can reach zero', () => {
    for (const { motif, zone } of HOME) {
      const rec = new FakeContext();
      drawBackdrop(motif.backdrop, motif, { ...view(rec, zone, 0.5), alpha: 0 });
      expect(rec.fills + rec.strokes, motif.key).toBe(0);
    }
  });

  it('gives every station of the descent a backdrop of its own', () => {
    const kinds = new Set(HOME.map((h) => h.motif.backdrop));
    expect(kinds.size).toBe(HOME.length);
    expect(motifsForAct('home')).toBe(HOME_MOTIFS);
  });

  /**
   * The salt line's two populations, told apart by what they do when the camera
   * descends - which is the only thing that separates them on the screen.
   *
   * Marine snow is what is *left* of life nearer the surface and it falls at the
   * swarm's own pace, so it barely moves on the glass: that is the whole reason
   * act VII is a descent rather than act I upside down, and `falling`'s own
   * comment says a flake that travels on the glass is a bug. Plankton is life,
   * and life holds the depth it lives at, so the swarm goes past it - which is
   * what the station's comment promised and what nothing in the frame did until
   * this test's fix. One goes with you, the other does not, and a picture that
   * has only one of them is missing the point of the station.
   */
  it('drops its snow with the swarm and leaves its plankton where it lives', () => {
    const home = HOME[0]!;
    const shot = (cameraY: number): { x: number; y: number; r: number }[] => {
      const rec = new FakeContext();
      drawBackdrop(home.motif.backdrop, home.motif, view(rec, home.zone, 0.4, 1, cameraY));
      return rec.arcs;
    };
    const before = shot(4200);
    const after = shot(4200 + 120);
    expect(before.length, 'the salt line drew no bodies at all').toBeGreaterThan(40);
    expect(after.length).toBe(before.length);

    // Drawn in order: the two planes of plankton, then the snow. Their counts are
    // the ones `brackish` passes, kept here rather than imported for the same
    // reason the banner's line positions are.
    const drift = 30 + 14;
    const moved = (from: number, to: number): number[] => {
      const out: number[] = [];
      for (let i = from; i < to; i++) {
        const d = before[i]!.y - after[i]!.y;
        // A body that wrapped round the frame this step says nothing about rate.
        if (d > -1 && d < 200) out.push(d);
      }
      return out;
    };
    const plankton = moved(0, drift);
    const snow = moved(drift, before.length);
    expect(plankton.length, 'no plankton').toBeGreaterThan(20);
    expect(snow.length, 'no snow').toBeGreaterThan(10);
    const mean = (xs: number[]): number => xs.reduce((a, b) => a + b, 0) / xs.length;
    // The swarm sank 120 px. The plankton stayed in the water it was in, so all
    // of that is displacement on the glass; the snow came with it, so almost none
    // of it is.
    expect(mean(plankton)).toBeGreaterThan(110);
    expect(mean(snow)).toBeLessThan(40);
  });

  /**
   * The sunlit zone's shafts, asked whether they have a bottom.
   *
   * They are the last daylight in the campaign and they are supposed to shorten
   * as the station goes on - that is the light running out, drawn as it runs out.
   * What they may not do is *stop*: a fill whose gradient runs across it does not
   * vary at all down its own length, so a rectangle ending anywhere in the frame
   * switches the shaft off in one pixel. That is what shipped, at 5.0 to 7.2
   * units on the row the arithmetic names, and it is the same defect as act VI's
   * canopy and act II's anvil.
   *
   * A radial gradient in a squashed frame cannot do it: it reaches zero at its own
   * radius in every direction, and the box that carries it is exactly that radius.
   * So the check is the ratio - the fill's half-extent over the gradient's radius -
   * and it has to be one.
   */
  it('gives the sunlit zone shafts no bottom to switch off at', () => {
    const sunlit = HOME[1]!;
    const shoot = (progress: number): FakeContext => {
      const rec = new FakeContext();
      drawBackdrop(sunlit.motif.backdrop, sunlit.motif, view(rec, sunlit.zone, progress));
      return rec;
    };

    for (const progress of [0, 0.5, 1]) {
      const rec = shoot(progress);
      // Five shafts, five radials. The wash over them is the only linear gradient
      // in the station and it is the one fill here allowed to reach the frame's
      // own edge, because the frame's edge is not an edge in the picture.
      expect(rec.radials.length, `p=${progress}`).toBe(5);
      // The shaft rects follow the wash, one each, in the order they were drawn.
      const shafts = rec.rects.slice(1);
      expect(shafts.length).toBe(5);
      for (let i = 0; i < 5; i++) {
        const g = rec.radials[i]!;
        const box = shafts[i]!;
        const where = `shaft ${i} at p=${progress}`;
        // The light dies at the circle's own edge...
        const last = rec.gradientStops[i + 1]!.at(-1)!;
        expect(last.offset, where).toBe(1);
        expect(Number(/,\s*([\d.]+)\)$/.exec(last.colour)?.[1]), where).toBe(0);
        // ...and the box that carries it is that circle and no bigger, on both
        // axes and on all four sides. Anything larger has a lit edge in it.
        expect(box.w, where).toBeCloseTo(g.r1 * 2, 6);
        expect(box.h, where).toBeCloseTo(g.r1 * 2, 6);
        expect(box.x + box.w / 2, where).toBeCloseTo(g.x1, 6);
        expect(box.y + box.h / 2, where).toBeCloseTo(g.y1, 6);
      }
    }

    // ...and the light still runs out on the station's own schedule, which is the
    // half of this that a shape assertion could quietly delete: the shaft is a
    // unit circle in a squashed frame, so its length is the y it was scaled by.
    const early = shoot(0).scales.map((s) => s.y);
    const late = shoot(1).scales.map((s) => s.y);
    expect(early.length).toBe(5);
    for (let i = 0; i < 5; i++) expect(late[i]!, `shaft ${i}`).toBeLessThan(early[i]! * 0.55);
  });
});
