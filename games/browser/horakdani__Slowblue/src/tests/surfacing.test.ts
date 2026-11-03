import { describe, expect, it } from 'vitest';
import { expectFinite, FakeContext } from './canvas';
import { paintFor } from '../src/render/Paint';
import {
  SURFACE_BREACH_AT,
  SURFACE_SKY_AT,
  SURFACE_TOTAL,
  Surfacing,
} from '../src/render/Surfacing';
import type { FilmView } from '../src/render/Films';

const W = 390;
const H = 844;

function view(rec: FakeContext, time: number): FilmView {
  return {
    ctx: rec.as2d,
    paint: paintFor(3),
    w: W,
    h: H,
    time,
    x: W * 0.42,
    y: H * 0.6,
    breath: 0.5,
    quality: 1,
  };
}

/** Runs the whole sequence at 60 Hz and hands back what was drawn. */
function playThrough(quality = 1): FakeContext {
  const rec = new FakeContext();
  const s = new Surfacing();
  s.begin();
  for (let i = 0; i * (1 / 60) <= SURFACE_TOTAL + 1; i++) {
    s.update(1 / 60);
    s.draw({ ...view(rec, i / 60), quality });
  }
  return rec;
}

describe('the surfacing sequence', () => {
  it('does nothing at all until the campaign is finished', () => {
    const rec = new FakeContext();
    const s = new Surfacing();
    expect(s.active).toBe(false);
    expect(s.phase).toBe('idle');
    s.update(10);
    s.draw(view(rec, 0));
    expect(rec.fills + rec.strokes).toBe(0);
    expect(s.phase).toBe('idle');
  });

  it('runs lift, ascent, breach and sky, in that order', () => {
    const s = new Surfacing();
    s.begin();
    expect(s.phase).toBe('lift');
    s.update(SURFACE_BREACH_AT - 0.2);
    expect(s.phase).toBe('ascent');
    s.update(0.3);
    expect(s.phase).toBe('breach');
    s.update(SURFACE_SKY_AT - SURFACE_BREACH_AT);
    expect(s.phase).toBe('sky');
  });

  it('keeps the air out of the water: no sky before the breach', () => {
    const s = new Surfacing();
    s.begin();
    for (let t = 0; t < SURFACE_SKY_AT; t += 0.1) {
      expect(s.sky, `at ${t.toFixed(1)}s`).toBe(0);
      s.update(0.1);
    }
    s.update(1);
    expect(s.sky).toBe(1);
  });

  it('holds on its last frame instead of ending on a cut', () => {
    const s = new Surfacing();
    s.begin();
    s.update(SURFACE_TOTAL + 30);
    expect(s.phase).toBe('sky');
    expect(s.sky).toBe(1);
    expect(s.active).toBe(true);
  });

  it('cannot be restarted mid-flight, and resets clean', () => {
    const s = new Surfacing();
    s.begin();
    s.update(2);
    s.begin();
    expect(s.phase).toBe('ascent');
    s.reset();
    expect(s.active).toBe(false);
    expect(s.sky).toBe(0);
  });

  it('draws nothing but finite geometry, from the first frame to the last', () => {
    // A NaN coordinate is invisible on a canvas and fatal to a sequence nobody sees
    // until they have finished the game.
    expectFinite(playThrough(), 'surfacing');
    expectFinite(playThrough(0.45), 'surfacing (low quality)');
  });

  it('spends most of its work above water once it is above water', () => {
    const rec = playThrough();
    expect(rec.fills).toBeGreaterThan(20);
    expect(rec.strokes).toBeGreaterThan(50);
    // The sky is opaque, so it is a fill; the swell and the glitter are strokes.
    expect(rec.composites.has('lighter')).toBe(true);
  });
});
