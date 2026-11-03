import { describe, expect, it } from 'vitest';
import { expectFinite, FakeContext } from './canvas';
import { paintFor } from '../src/render/Paint';
import { drawWhirl, orbitOmega, shearAt } from '../src/render/Whirl';
import { CurrentField } from '../src/sim/CurrentField';

const RADIUS = 130;
const STRENGTH = 110;

describe('what a vortex is drawn from', () => {
  it('turns the water at exactly the speed the simulation moves it', () => {
    // The whole point of the redraw: the marker is derived from the field, so it can
    // never disagree with what the shoal is about to feel.
    const field = new CurrentField();
    field.add({ x: 0, y: 0, radius: RADIUS, strength: STRENGTH, sectionId: 0, phase: 0 });
    const out = { x: 0, y: 0 };
    for (const d of [10, 40, 65, 100, 129]) {
      out.x = 0;
      out.y = 0;
      field.addTo(d, 0, out);
      const tangential = Math.hypot(out.x, out.y);
      // omega * r is the tangential speed at that radius.
      expect(orbitOmega(d, RADIUS, STRENGTH) * d).toBeCloseTo(tangential, 6);
    }
  });

  it('is calm at the eye, calm at the rim, and fastest half way out', () => {
    expect(orbitOmega(0, RADIUS, STRENGTH)).toBe(0);
    expect(orbitOmega(RADIUS, RADIUS, STRENGTH)).toBe(0);
    expect(orbitOmega(RADIUS + 20, RADIUS, STRENGTH)).toBe(0);
    const speeds = [0.2, 0.35, 0.5, 0.65, 0.8].map((u) => orbitOmega(u * RADIUS, RADIUS, STRENGTH) * u * RADIUS);
    const peak = Math.max(...speeds);
    expect(speeds[2]).toBeCloseTo(peak, 6);
  });

  it('shears: inner water laps outer water, which is what winds the filaments up', () => {
    expect(shearAt(0)).toBe(0);
    expect(shearAt(1)).toBe(0);
    let previous = Infinity;
    for (let u = 0.1; u < 1; u += 0.05) {
      const s = shearAt(u);
      expect(s, `shear at ${u.toFixed(2)}`).toBeLessThan(previous);
      previous = s;
    }
  });
});

describe('drawing a vortex', () => {
  function draw(quality: number, strength: number, time: number): FakeContext {
    const rec = new FakeContext();
    drawWhirl(
      {
        ctx: rec.as2d,
        paint: paintFor(2),
        accent: [143, 228, 220],
        time,
        quality,
      },
      190,
      420,
      RADIUS,
      strength,
      time * 0.8,
    );
    return rec;
  }

  it('never emits a bad coordinate, in either spin and at any strength', () => {
    for (const strength of [-190, -78, 40, 125]) {
      for (const t of [0, 0.7, 4.3, 61]) {
        expectFinite(draw(1, strength, t), `whirl ${strength} at ${t}s`);
      }
    }
    expectFinite(draw(0.45, 92, 3), 'whirl (low quality)');
  });

  it('spins the other way when the section says so', () => {
    const cw = draw(1, 110, 2);
    const ccw = draw(1, -110, 2);
    expect(cw.numbers).not.toEqual(ccw.numbers);
  });

  it('stays cheap: a current is a couple of dozen draw calls, not a couple of hundred', () => {
    const rec = draw(1, 125, 3);
    expect(rec.fills + rec.strokes).toBeLessThan(24);
    expect(rec.fills + rec.strokes).toBeGreaterThan(6);
  });
});
