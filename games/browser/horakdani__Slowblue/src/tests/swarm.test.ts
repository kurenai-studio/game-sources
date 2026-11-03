import { describe, expect, it } from 'vitest';
import { SwarmSimulation } from '../src/sim/SwarmSimulation';
import { FlowField } from '../src/sim/FlowField';
import { dist, inertTuning, makeContext, place, stepMany, H, W } from './helpers';

describe('boids forces', () => {
  it('separation pushes crowded individuals apart', () => {
    const swarm = new SwarmSimulation(1);
    const agents = place(swarm, [
      { x: 200, y: 400 },
      { x: 204, y: 400 },
    ]);
    const ctx = makeContext(inertTuning({ separation: 3.4, separationRadius: 14 }));
    const before = dist(agents[0]!, agents[1]!);
    stepMany(swarm, ctx, 30);
    expect(dist(agents[0]!, agents[1]!)).toBeGreaterThan(before);
  });

  it('cohesion pulls separated individuals together', () => {
    const swarm = new SwarmSimulation(1);
    const agents = place(swarm, [
      { x: 200, y: 400 },
      { x: 236, y: 400 },
    ]);
    const ctx = makeContext(inertTuning({ cohesion: 1.4, perceptionRadius: 60 }));
    const before = dist(agents[0]!, agents[1]!);
    stepMany(swarm, ctx, 30);
    expect(dist(agents[0]!, agents[1]!)).toBeLessThan(before);
  });

  it('alignment converges headings', () => {
    const swarm = new SwarmSimulation(1);
    const agents = place(swarm, [
      { x: 200, y: 400, vx: 100, vy: 0 },
      { x: 220, y: 400, vx: -100, vy: 0 },
    ]);
    const ctx = makeContext(inertTuning({ alignment: 2, perceptionRadius: 60 }));
    const before = Math.abs(agents[0]!.vx - agents[1]!.vx);
    stepMany(swarm, ctx, 40);
    expect(Math.abs(agents[0]!.vx - agents[1]!.vx)).toBeLessThan(before);
  });

  it('ignores agents beyond the perception radius', () => {
    const swarm = new SwarmSimulation(1);
    const agents = place(swarm, [
      { x: 80, y: 400 },
      { x: 300, y: 400 },
    ]);
    const ctx = makeContext(inertTuning({ cohesion: 4, perceptionRadius: 40 }));
    const before = dist(agents[0]!, agents[1]!);
    stepMany(swarm, ctx, 30);
    expect(dist(agents[0]!, agents[1]!)).toBeCloseTo(before, 3);
  });

  it('does not align or cohere across factions', () => {
    const swarm = new SwarmSimulation(1);
    const main = place(swarm, [{ x: 200, y: 400 }]);
    const pod = swarm.spawnPod(1, 236, 400, 1);
    // Zero the spawn velocities: only forces may move these two.
    for (const a of [main[0]!, pod[0]!]) {
      a.vx = 0;
      a.vy = 0;
    }
    const ctx = makeContext(inertTuning({ cohesion: 4, perceptionRadius: 80 }));
    const before = dist(main[0]!, pod[0]!);
    stepMany(swarm, ctx, 20);
    // Only separation-free cohesion is enabled, and it must not cross factions.
    expect(dist(main[0]!, pod[0]!)).toBeCloseTo(before, 1);
  });
});

describe('water coupling', () => {
  it('drags a still agent along the local flow', () => {
    const swarm = new SwarmSimulation(1);
    const agents = place(swarm, [{ x: 200, y: 400 }]);
    const field = new FlowField(W, H);
    field.addImpulse(200, 400, 220, 0, 90);
    const ctx = makeContext(inertTuning({ flowCoupling: 3.4 }), field);
    stepMany(swarm, ctx, 10);
    expect(agents[0]!.vx).toBeGreaterThan(40);
    expect(agents[0]!.x).toBeGreaterThan(200);
  });

  it('bends a whole shoal coherently rather than per-individual', () => {
    const swarm = new SwarmSimulation(4);
    swarm.spawnShoal(60, W * 0.5, 400, 40);
    const field = new FlowField(W, H);
    const ctx = makeContext(
      inertTuning({ flowCoupling: 3.4, alignment: 1.5, cohesion: 1.1, separation: 3.4 }),
      field,
    );
    for (let i = 0; i < 40; i++) {
      field.addImpulse(W * 0.5, 400, 260, 0, 110);
      swarm.step(1 / 60, ctx);
      field.step(1 / 60, 1.05, 3.2);
    }
    let sameSign = 0;
    let n = 0;
    for (const a of swarm.agents) {
      if (!a.alive) continue;
      n++;
      if (a.vx > 0) sameSign++;
    }
    // "Silk" means the shoal moves as one: near-unanimous drift direction.
    expect(sameSign / n).toBeGreaterThan(0.95);
  });

  it('brakes when the flow opposes the current velocity', () => {
    const swarm = new SwarmSimulation(1);
    const agents = place(swarm, [{ x: 200, y: 400, vx: 0, vy: -200 }]);
    const field = new FlowField(W, H);
    field.addImpulse(200, 400, 0, 260, 120);
    const ctx = makeContext(inertTuning({ flowCoupling: 3.4 }), field);
    stepMany(swarm, ctx, 15);
    expect(agents[0]!.vy).toBeGreaterThan(-200);
  });

  it('cannot sweep captive fish out of their rescue ring', () => {
    const swarm = new SwarmSimulation(8);
    const cx = 200;
    const cy = 400;
    const radius = 62;
    const pod = swarm.spawnPod(1, cx, cy, 10, 1, radius);
    const current = {
      sample: (_x: number, _y: number, out: { x: number; y: number }) => {
        out.x = 1200;
        out.y = -600;
      },
    };
    const ctx = makeContext(
      inertTuning({ flowCoupling: 12, maxAccel: 3000, maxSpeed: 700 }),
      current,
    );
    stepMany(swarm, ctx, 240);

    for (const fish of pod) {
      expect(fish.anchored).toBe(true);
      expect(Math.hypot(fish.x - cx, fish.y - cy)).toBeLessThanOrEqual(radius);
    }
  });
});

describe('limits and metrics', () => {
  it('never exceeds max speed', () => {
    const swarm = new SwarmSimulation(2);
    swarm.spawnShoal(40, W * 0.5, 400, 30);
    const field = new FlowField(W, H);
    const t = inertTuning({ flowCoupling: 8, maxSpeed: 200 });
    const ctx = makeContext(t, field);
    for (let i = 0; i < 60; i++) {
      field.addImpulse(W * 0.5, 400, 3000, 3000, 200);
      swarm.step(1 / 60, ctx);
    }
    for (const a of swarm.agents) {
      if (!a.alive) continue;
      expect(Math.hypot(a.vx, a.vy)).toBeLessThanOrEqual(t.maxSpeed * a.variation + 0.001);
    }
  });

  it('reports centroid and spread', () => {
    const swarm = new SwarmSimulation(3);
    place(swarm, [
      { x: 100, y: 0 },
      { x: 300, y: 0 },
    ]);
    const c = swarm.centroid();
    expect(c.count).toBe(2);
    expect(c.x).toBeCloseTo(200, 6);
    expect(swarm.spread()).toBeCloseTo(100, 6);
  });

  it('keeps individuals inside the lateral walls', () => {
    const swarm = new SwarmSimulation(5);
    const agents = place(swarm, [{ x: 4, y: 400, vx: -300, vy: 0 }]);
    const ctx = makeContext(inertTuning());
    stepMany(swarm, ctx, 120);
    expect(agents[0]!.x).toBeGreaterThan(0);
  });

  it('is deterministic for a given seed', () => {
    const run = (): number[] => {
      const swarm = new SwarmSimulation(99);
      swarm.spawnShoal(40, W * 0.5, 400, 30);
      const field = new FlowField(W, H);
      const ctx = makeContext(inertTuning({ alignment: 1.5, cohesion: 1.1, separation: 3.4, noise: 55, flowCoupling: 3.4 }), field);
      for (let i = 0; i < 90; i++) {
        if (i === 10) field.addImpulse(120, 380, 300, -100, 90);
        swarm.step(1 / 60, ctx);
        field.step(1 / 60, 1.05, 3.2);
      }
      return swarm.agents.filter((a) => a.alive).flatMap((a) => [a.x, a.y, a.vx, a.vy]);
    };
    expect(run()).toEqual(run());
  });
});
