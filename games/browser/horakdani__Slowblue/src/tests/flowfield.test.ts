import { describe, expect, it } from 'vitest';
import { FlowField } from '../src/sim/FlowField';

const W = 390;
const H = 844;

describe('FlowField', () => {
  it('deposits momentum at the impulse centre and falls off with distance', () => {
    const f = new FlowField(W, H, 24);
    f.addImpulse(200, 400, 300, 0, 80);
    const at = { x: 0, y: 0 };
    const near = { x: 0, y: 0 };
    const far = { x: 0, y: 0 };
    f.sample(200, 400, at);
    f.sample(240, 400, near);
    f.sample(200, 700, far);
    expect(at.x).toBeGreaterThan(200);
    expect(at.y).toBeCloseTo(0, 5);
    expect(near.x).toBeGreaterThan(0);
    expect(near.x).toBeLessThan(at.x);
    expect(far.x).toBeCloseTo(0, 4);
  });

  it('never injects velocity outside the impulse radius', () => {
    const f = new FlowField(W, H, 24);
    f.addImpulse(200, 400, 500, 500, 60);
    const out = { x: 0, y: 0 };
    f.sample(200, 400 + 200, out);
    expect(Math.hypot(out.x, out.y)).toBe(0);
  });

  it('decays with the configured half-life', () => {
    const f = new FlowField(W, H, 24);
    f.addImpulse(200, 400, 400, 0, 90);
    const before = { x: 0, y: 0 };
    f.sample(200, 400, before);
    // 1s of decay at a 1s half-life, without diffusion muddying the result.
    for (let i = 0; i < 60; i++) f.step(1 / 60, 1, 0);
    const after = { x: 0, y: 0 };
    f.sample(200, 400, after);
    expect(after.x / before.x).toBeGreaterThan(0.45);
    expect(after.x / before.x).toBeLessThan(0.55);
  });

  it('diffuses momentum into neighbouring cells', () => {
    const f = new FlowField(W, H, 24);
    const i = f.index(5, 10);
    f.vx[i] = 100;
    for (let s = 0; s < 30; s++) f.step(1 / 60, 1000, 6);
    expect(f.vx[f.index(6, 10)]).toBeGreaterThan(1);
    expect(f.vx[f.index(5, 11)]).toBeGreaterThan(1);
    expect(f.vx[i]).toBeLessThan(100);
  });

  it('bilinearly interpolates between cell centres', () => {
    const f = new FlowField(W, H, 24);
    f.vx[f.index(2, 3)] = 100;
    f.vx[f.index(3, 3)] = 200;
    const a = { x: 0, y: 0 };
    const b = { x: 0, y: 0 };
    const mid = { x: 0, y: 0 };
    f.sample(24 * 2.5, 24 * 3.5, a);
    f.sample(24 * 3.5, 24 * 3.5, b);
    f.sample(24 * 3.0, 24 * 3.5, mid);
    expect(a.x).toBeCloseTo(100, 3);
    expect(b.x).toBeCloseTo(200, 3);
    expect(mid.x).toBeCloseTo(150, 3);
  });

  it('clamps samples taken outside the grid instead of returning garbage', () => {
    const f = new FlowField(W, H, 24);
    const out = { x: 0, y: 0 };
    f.sample(-9999, -9999, out);
    expect(Number.isFinite(out.x)).toBe(true);
    f.sample(9999, 9999, out);
    expect(Number.isFinite(out.y)).toBe(true);
  });

  it('scrolls in whole cells so a current stays with the water', () => {
    const f = new FlowField(W, H, 24);
    f.addImpulse(200, 100, 400, 0, 50);
    const before = { x: 0, y: 0 };
    f.sample(200, 100, before);
    f.shiftTo(-240);
    expect(f.originY).toBe(-240);
    const after = { x: 0, y: 0 };
    f.sample(200, 100, after);
    expect(after.x).toBeCloseTo(before.x, 3);
  });

  it('clears rows that scroll into view', () => {
    const f = new FlowField(W, H, 24);
    f.addImpulse(200, 100, 400, 0, 50);
    f.shiftTo(-24 * 8);
    // Freshly revealed water, well ahead of anything the player has touched.
    const out = { x: 0, y: 0 };
    f.sample(200, -24 * 7, out);
    expect(Math.hypot(out.x, out.y)).toBe(0);
  });

  it('drops everything when the scroll exceeds the grid height', () => {
    const f = new FlowField(W, H, 24);
    f.addImpulse(200, 100, 400, 0, 50);
    f.shiftTo(-100000);
    expect(f.meanSpeed()).toBe(0);
  });
});
