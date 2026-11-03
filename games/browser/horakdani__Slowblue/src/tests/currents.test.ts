import { describe, expect, it } from 'vitest';
import { CurrentField, type Vortex } from '../src/sim/CurrentField';

function vortex(over: Partial<Vortex> = {}): Vortex {
  return { x: 100, y: 100, radius: 80, strength: 120, sectionId: 1, phase: 0, ...over };
}

function sampleAt(f: CurrentField, x: number, y: number, scale = 1): { x: number; y: number } {
  const out = { x: 0, y: 0 };
  f.addTo(x, y, out, scale);
  return out;
}

describe('CurrentField', () => {
  it('contributes nothing outside its radius, or at the eye', () => {
    const f = new CurrentField();
    f.add(vortex());
    expect(sampleAt(f, 100 + 81, 100)).toEqual({ x: 0, y: 0 });
    expect(sampleAt(f, 100, 100)).toEqual({ x: 0, y: 0 });
  });

  it('is purely tangential, so it spins the water without pulling it in', () => {
    const f = new CurrentField();
    f.add(vortex());
    for (const [dx, dy] of [
      [40, 0],
      [0, 40],
      [-28, 28],
    ]) {
      const v = sampleAt(f, 100 + dx, 100 + dy);
      // Radial component must be zero: v . r_hat == 0.
      const d = Math.hypot(dx, dy);
      expect(Math.abs((v.x * dx + v.y * dy) / d)).toBeLessThan(1e-9);
      expect(Math.hypot(v.x, v.y)).toBeGreaterThan(1);
    }
  });

  it('peaks halfway out and fades to nothing at the rim', () => {
    const f = new CurrentField();
    f.add(vortex());
    const speedAt = (r: number): number => {
      const v = sampleAt(f, 100 + r, 100);
      return Math.hypot(v.x, v.y);
    };
    expect(speedAt(40)).toBeCloseTo(120, 6);
    expect(speedAt(8)).toBeLessThan(speedAt(40));
    expect(speedAt(76)).toBeLessThan(speedAt(40));
    expect(speedAt(79.9)).toBeLessThan(4);
  });

  it('reverses with the sign of its strength', () => {
    const cw = new CurrentField();
    cw.add(vortex({ strength: 120 }));
    const ccw = new CurrentField();
    ccw.add(vortex({ strength: -120 }));
    const a = sampleAt(cw, 140, 100);
    const b = sampleAt(ccw, 140, 100);
    expect(a.y).toBeCloseTo(-b.y, 9);
    expect(Math.abs(a.y)).toBeGreaterThan(1);
  });

  it('is divergence-free in the interior, so tracers never pile up', () => {
    const f = new CurrentField();
    f.add(vortex());
    const h = 0.05;
    for (const [x, y] of [
      [120, 100],
      [100, 130],
      [70, 80],
    ]) {
      const dudx = (sampleAt(f, x + h, y).x - sampleAt(f, x - h, y).x) / (2 * h);
      const dvdy = (sampleAt(f, x, y + h).y - sampleAt(f, x, y - h).y) / (2 * h);
      expect(Math.abs(dudx + dvdy)).toBeLessThan(1e-4);
    }
  });

  it('scales linearly, and a zero scale is a hard off switch', () => {
    const f = new CurrentField();
    f.add(vortex());
    const full = sampleAt(f, 140, 100, 1);
    const half = sampleAt(f, 140, 100, 0.5);
    expect(half.y).toBeCloseTo(full.y * 0.5, 9);
    expect(sampleAt(f, 140, 100, 0)).toEqual({ x: 0, y: 0 });
  });

  it('sums overlapping currents', () => {
    const f = new CurrentField();
    f.add(vortex({ x: 100 }));
    f.add(vortex({ x: 140, strength: -120 }));
    const between = sampleAt(f, 120, 100);
    // Counter-rotating pair: the water between them runs as a jet, not a swirl.
    expect(Math.abs(between.y)).toBeGreaterThan(100);
  });

  it('drops currents the camera has left behind, and only those', () => {
    const f = new CurrentField();
    f.add(vortex({ y: 900 }));
    f.add(vortex({ y: -200 }));
    f.prune(500);
    expect(f.vortices.length).toBe(1);
    expect(f.vortices[0]!.y).toBe(-200);
  });

  it('advances a cosmetic phase without changing the field', () => {
    const f = new CurrentField();
    f.add(vortex());
    const before = sampleAt(f, 140, 100);
    f.step(1);
    expect(f.vortices[0]!.phase).toBeGreaterThan(0);
    expect(sampleAt(f, 140, 100)).toEqual(before);
  });

  it('reports the strongest local intensity', () => {
    const f = new CurrentField();
    f.add(vortex());
    expect(f.intensityAt(140, 100)).toBeCloseTo(120, 6);
    expect(f.intensityAt(400, 400)).toBe(0);
  });
});
