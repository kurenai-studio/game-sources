import { describe, expect, it } from 'vitest';
import { expectFinite, FakeContext } from './canvas';
import { paintFor } from '../src/render/Paint';
import {
  RELEASE_CARRY_AT,
  RELEASE_CLEAR_AT,
  RELEASE_LIMB_AT,
  RELEASE_SUNRISE_AT,
  RELEASE_TOTAL,
  Release,
} from '../src/render/Release';
import type { FilmView } from '../src/render/Films';

const W = 390;
const H = 844;

function view(rec: FakeContext, time: number): FilmView {
  return {
    ctx: rec.as2d,
    paint: paintFor(9),
    w: W,
    h: H,
    time,
    x: W * 0.46,
    y: H * 0.55,
    breath: 0.5,
    quality: 1,
  };
}

/** Runs the whole film at 60 Hz and hands back what was drawn. */
function playThrough(quality = 1): FakeContext {
  const rec = new FakeContext();
  const r = new Release();
  r.begin();
  for (let i = 0; i * (1 / 60) <= RELEASE_TOTAL + 1; i++) {
    r.update(1 / 60);
    r.draw({ ...view(rec, i / 60), quality });
  }
  return rec;
}

describe('the release sequence', () => {
  it('does nothing at all until the act is finished', () => {
    const rec = new FakeContext();
    const r = new Release();
    expect(r.active).toBe(false);
    expect(r.phase).toBe('idle');
    expect(r.dusk).toBe(0);
    r.update(10);
    r.draw(view(rec, 0));
    expect(rec.fills + rec.strokes).toBe(0);
    expect(r.phase).toBe('idle');
  });

  it('runs hold, clear, limb, sunrise and carry, in that order', () => {
    const r = new Release();
    r.begin();
    expect(r.phase).toBe('hold');
    r.update(RELEASE_CLEAR_AT + 0.1);
    expect(r.phase).toBe('clear');
    r.update(RELEASE_LIMB_AT - RELEASE_CLEAR_AT);
    expect(r.phase).toBe('limb');
    expect(r.released).toBe(false);
    r.update(RELEASE_SUNRISE_AT - RELEASE_LIMB_AT);
    expect(r.phase).toBe('sunrise');
    expect(r.released).toBe(false);
    r.update(RELEASE_CARRY_AT - RELEASE_SUNRISE_AT);
    expect(r.phase).toBe('carry');
    expect(r.released).toBe(true);
  });

  it('holds on its last frame instead of ending', () => {
    const r = new Release();
    r.begin();
    r.update(RELEASE_TOTAL + 30);
    expect(r.phase).toBe('carry');
    expect(r.night).toBe(1);
    const rec = new FakeContext();
    r.draw(view(rec, RELEASE_TOTAL + 30));
    expect(rec.fills + rec.strokes).toBeGreaterThan(0);
  });

  it('darkens monotonically and never blacks the live world out entirely', () => {
    const r = new Release();
    r.begin();
    let lastDusk = 0;
    for (let t = 0; t < RELEASE_TOTAL + 0.5; t += 0.1) {
      // The first movement is the wind stopping, not the light going: nothing is
      // allowed to have gone dark before the air starts running out.
      if (t < RELEASE_CLEAR_AT * 0.5) expect(r.night).toBe(0);
      expect(r.dusk).toBeGreaterThanOrEqual(lastDusk - 1e-9);
      expect(r.dusk).toBeLessThanOrEqual(0.92 + 1e-9);
      lastDusk = r.dusk;
      r.update(0.1);
    }
    expect(r.night).toBe(1);
  });

  it('draws finite geometry from the first frame to the last', () => {
    expectFinite(playThrough(), 'release full quality');
    expectFinite(playThrough(0.45), 'release low quality');
  });

  it('brings the sun back before the flock lets go', () => {
    // The film's whole argument is that the reward comes first and the handover
    // second: the light returns at the limb, and only then does the flock stop
    // carrying what it carried. A stream that started earlier would be an ending
    // that gave up before it paid out.
    const upToSunrise = new FakeContext();
    const r = new Release();
    r.begin();
    for (let i = 0; i * (1 / 60) <= RELEASE_CARRY_AT - 0.1; i++) {
      r.update(1 / 60);
      r.draw(view(upToSunrise, i / 60));
    }
    const warm = (rec: FakeContext): number =>
      rec.styles.filter((s) => s.startsWith('rgba(255,233,178')).length;
    const sun = (rec: FakeContext): number =>
      rec.styles.filter((s) => s.startsWith('rgba(255,246,214')).length;
    expect(warm(upToSunrise)).toBe(0);
    expect(sun(upToSunrise)).toBeGreaterThan(0);
    expect(warm(playThrough())).toBeGreaterThan(0);
  });
});
