import { describe, expect, it } from 'vitest';
import { AmbientFlow } from '../src/sim/AmbientFlow';
import { FlowField } from '../src/sim/FlowField';
import { SwarmSimulation } from '../src/sim/SwarmSimulation';
import { inertTuning, makeContext, place, stepMany, H, W } from './helpers';

function sample(a: AmbientFlow, x: number, y: number, t: number, strength: number) {
  const out = { x: 0, y: 0 };
  a.addTo(x, y, t, strength, out);
  return out;
}

describe('AmbientFlow', () => {
  it('is silent when the ocean is switched off', () => {
    const a = new AmbientFlow(1);
    const out = sample(a, 123, -456, 7, 0);
    expect(out.x).toBe(0);
    expect(out.y).toBe(0);
  });

  it('is deterministic per seed and different across seeds', () => {
    const a = sample(new AmbientFlow(42), 100, -200, 3, 60);
    const b = sample(new AmbientFlow(42), 100, -200, 3, 60);
    const c = sample(new AmbientFlow(43), 100, -200, 3, 60);
    expect(a).toEqual(b);
    expect(a).not.toEqual(c);
  });

  it('stays within roughly the requested peak speed', () => {
    const a = new AmbientFlow(9);
    let peak = 0;
    for (let x = 0; x < W; x += 7) {
      for (let y = -1200; y < 200; y += 11) {
        const v = sample(a, x, y, 4, 60);
        peak = Math.max(peak, Math.hypot(v.x, v.y));
      }
    }
    // Two octaves at weights 0.72 and 0.4 can only sum to ~1.12x in the worst case.
    expect(peak).toBeGreaterThan(30);
    expect(peak).toBeLessThan(60 * 1.15);
  });

  it('never flows into a wall', () => {
    const a = new AmbientFlow(4, W);
    for (const y of [-800, -300, 0, 200]) {
      expect(Math.abs(sample(a, 0, y, 3, 90).x)).toBeLessThan(0.001);
      expect(Math.abs(sample(a, W, y, 3, 90).x)).toBeLessThan(0.001);
    }
    // ...but it still runs along the wall, so the edges are not dead water.
    let alongWall = 0;
    for (let y = -900; y < 100; y += 7) {
      alongWall = Math.max(alongWall, Math.abs(sample(a, 2, y, 3, 90).y));
    }
    expect(alongWall).toBeGreaterThan(20);
  });

  it('is divergence-free in the interior, so tracers never pile into a point', () => {
    const a = new AmbientFlow(5, W);
    const h = 0.5;
    let worst = 0;
    // Interior only: the wall taper deliberately breaks this within 0.16W of an edge.
    for (let x = W * 0.25; x < W * 0.75; x += 13) {
      for (let y = -900; y < 100; y += 29) {
        const dx =
          (sample(a, x + h, y, 2, 80).x - sample(a, x - h, y, 2, 80).x) / (2 * h);
        const dy =
          (sample(a, x, y + h, 2, 80).y - sample(a, x, y - h, 2, 80).y) / (2 * h);
        worst = Math.max(worst, Math.abs(dx + dy));
      }
    }
    expect(worst).toBeLessThan(1e-6);
  });

  it('varies over space and evolves over time', () => {
    const a = new AmbientFlow(3);
    const here = sample(a, 100, -100, 0, 70);
    const elsewhere = sample(a, 100 + 240, -100, 0, 70);
    const later = sample(a, 100, -100, 40, 70);
    expect(Math.hypot(here.x - elsewhere.x, here.y - elsewhere.y)).toBeGreaterThan(5);
    expect(Math.hypot(here.x - later.x, here.y - later.y)).toBeGreaterThan(3);
  });

  it('carries a shoal that is doing nothing', () => {
    const swarm = new SwarmSimulation(1);
    const agents = place(swarm, [{ x: W * 0.5, y: -300 }]);
    const field = new FlowField(W, H);
    const ambient = new AmbientFlow(11);
    let t = 0;
    const ctx = makeContext(inertTuning({ flowCoupling: 3.4 }), field);
    ctx.water = {
      sample: (x, y, out) => {
        field.sample(x, y, out);
        ambient.addTo(x, y, t, 70, out);
      },
    };
    for (let i = 0; i < 120; i++) {
      t += 1 / 60;
      stepMany(swarm, ctx, 1);
    }
    const moved = Math.hypot(agents[0]!.x - W * 0.5, agents[0]!.y + 300);
    expect(moved).toBeGreaterThan(10);
  });
});

describe('non-linear water decay', () => {
  it('clamps water speed to the configured ceiling', () => {
    const f = new FlowField(W, H, 24);
    f.addImpulse(200, 400, 5000, 0, 80);
    f.step(1 / 60, 10, 0, 300, 0);
    const out = { x: 0, y: 0 };
    f.sample(200, 400, out);
    expect(Math.hypot(out.x, out.y)).toBeLessThanOrEqual(300.001);
  });

  it('dissipates a violent current faster than a gentle one', () => {
    const survives = (initial: number, turbulence: number): number => {
      const f = new FlowField(W, H, 24);
      const i = f.index(5, 10);
      f.vx[i] = initial;
      for (let s = 0; s < 30; s++) f.step(1 / 60, 1.05, 0, 9999, turbulence);
      return f.vx[i] / initial;
    };
    const gentle = survives(60, 3);
    const violent = survives(600, 3);
    expect(violent).toBeLessThan(gentle);
    // With turbulence off, the fraction surviving is independent of magnitude.
    expect(survives(60, 0)).toBeCloseTo(survives(600, 0), 5);
  });

  it('matches the plain half-life when turbulence is off', () => {
    const f = new FlowField(W, H, 24);
    const i = f.index(4, 4);
    f.vx[i] = 100;
    for (let s = 0; s < 60; s++) f.step(1 / 60, 1, 0, 9999, 0);
    expect(f.vx[i]).toBeGreaterThan(49);
    expect(f.vx[i]).toBeLessThan(51);
  });
});
