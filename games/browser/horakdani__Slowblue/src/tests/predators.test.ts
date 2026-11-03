import { describe, expect, it } from 'vitest';
import { BITE_COOLDOWN, PredatorSystem, SPAWN_GRACE } from '../src/sim/PredatorSystem';
import { SwarmSimulation } from '../src/sim/SwarmSimulation';
import type { WaterSampler } from '../src/sim/SwarmSimulation';
import { MAIN_FACTION } from '../src/sim/Agent';
import { inertTuning, makeContext, place, stepMany, W } from './helpers';

const STILL: WaterSampler = {
  sample: (_x, _y, out) => {
    out.x = 0;
    out.y = 0;
  },
};

function pushing(vx: number, vy: number): WaterSampler {
  return {
    sample: (_x, _y, out) => {
      out.x = vx;
      out.y = vy;
    },
  };
}

function run(
  p: PredatorSystem,
  swarm: SwarmSimulation,
  steps: number,
  water: WaterSampler = STILL,
  speed = 132,
  coupling = 1.15,
): number {
  let taken = 0;
  for (let i = 0; i < steps; i++) {
    taken += p.update(1 / 60, swarm, water, W, speed, coupling).length;
  }
  return taken;
}

describe('PredatorSystem', () => {
  it('closes on the nearest individual', () => {
    const swarm = new SwarmSimulation(1);
    place(swarm, [{ x: 100, y: 0 }]);
    const p = new PredatorSystem();
    const hunter = p.spawn(100, 260, 16, 1, 0);
    const before = hunter.y;
    run(p, swarm, 30);
    expect(hunter.y).toBeLessThan(before - 20);
  });

  it('takes an individual on contact, then has to wait before the next', () => {
    const swarm = new SwarmSimulation(2);
    const agents = place(swarm, [
      { x: 100, y: 0 },
      { x: 108, y: 4 },
      { x: 96, y: -6 },
    ]);
    const p = new PredatorSystem();
    p.spawn(100, 40, 16, 1, 0);
    // The spawn grace has to pass before the first strike lands.
    expect(run(p, swarm, Math.floor(SPAWN_GRACE * 60) - 6)).toBe(0);
    expect(run(p, swarm, 20)).toBe(1);
    expect(agents.filter((a) => a.alive).length).toBe(2);
    // Not long enough for the cooldown to clear, so still exactly one.
    expect(run(p, swarm, Math.floor(BITE_COOLDOWN * 60) - 25)).toBe(0);
    expect(run(p, swarm, 40)).toBeGreaterThan(0);
  });

  it('ignores un-rescued pods: it only hunts the player', () => {
    const swarm = new SwarmSimulation(3);
    swarm.spawnPod(7, 100, 0, 6);
    const p = new PredatorSystem();
    const hunter = p.spawn(100, 40, 16, 1, 0);
    const taken = run(p, swarm, 120);
    expect(taken).toBe(0);
    expect(swarm.aliveCount(7)).toBe(6);
    // With nothing to chase it patrols instead of parking on the pod.
    expect(hunter.idle).toBeGreaterThan(1);
  });

  it('is heavy: water moves it, but far less than it moves a fish', () => {
    const swarm = new SwarmSimulation(4);
    const p = new PredatorSystem();
    const hunter = p.spawn(W * 0.5, 0, 16, 1, 0);
    run(p, swarm, 60, pushing(200, 0));
    const hunterDrift = hunter.x - W * 0.5;

    const fishSwarm = new SwarmSimulation(4);
    const fish = place(fishSwarm, [{ x: W * 0.5, y: 0 }])[0]!;
    const ctx = makeContext(inertTuning({ flowCoupling: 3.4 }), pushing(200, 0));
    stepMany(fishSwarm, ctx, 60);
    const fishDrift = fish.x - W * 0.5;

    expect(hunterDrift).toBeGreaterThan(5);
    expect(hunterDrift).toBeLessThan(fishDrift * 0.7);
  });

  it('stays inside the walls', () => {
    const swarm = new SwarmSimulation(5);
    const p = new PredatorSystem();
    const hunter = p.spawn(20, 0, 16, 1, 0);
    run(p, swarm, 240, pushing(-400, 0));
    expect(hunter.x).toBeGreaterThan(-1);
    expect(hunter.x).toBeLessThan(W + 1);
  });

  it('is deterministic for a given seed and input', () => {
    const trace = (): number[] => {
      const swarm = new SwarmSimulation(9);
      place(swarm, [{ x: 200, y: -80 }]);
      const p = new PredatorSystem();
      const h = p.spawn(100, 200, 16, 1, 0.4);
      run(p, swarm, 90);
      return [h.x, h.y, h.vx, h.vy];
    };
    expect(trace()).toEqual(trace());
  });

  it('drops hunters the camera has left behind', () => {
    const p = new PredatorSystem();
    p.spawn(100, 900, 16, 1, 0);
    p.spawn(100, -300, 16, 2, 0);
    p.prune(500);
    expect(p.predators.length).toBe(1);
    expect(p.predators[0]!.sectionId).toBe(2);
  });
});

describe('the shoal flees a hunter', () => {
  it('breaks away from a threat instead of swimming through it', () => {
    const swarm = new SwarmSimulation(11);
    const agent = place(swarm, [{ x: 100, y: 0 }])[0]!;
    const ctx = {
      ...makeContext(inertTuning({ predatorFear: 5, cruiseSpeed: 120 })),
      threats: [{ x: 100, y: 40, size: 16 }],
    };
    stepMany(swarm, ctx, 45);
    // Pushed directly away from the hunter, which is at +Y.
    expect(agent.y).toBeLessThan(-20);
  });

  it('does not react to a hunter outside its flee radius', () => {
    const swarm = new SwarmSimulation(12);
    const agent = place(swarm, [{ x: 100, y: 0 }])[0]!;
    const ctx = {
      ...makeContext(inertTuning({ predatorFear: 5 })),
      threats: [{ x: 100, y: 16 * 5.5 + 5, size: 16 }],
    };
    stepMany(swarm, ctx, 45);
    expect(Math.abs(agent.y)).toBeLessThan(0.001);
  });

  it('scales the panic with the fear tuning', () => {
    const displacement = (fear: number): number => {
      const swarm = new SwarmSimulation(13);
      const agent = place(swarm, [{ x: 100, y: 0 }])[0]!;
      const ctx = {
        ...makeContext(inertTuning({ predatorFear: fear })),
        threats: [{ x: 100, y: 40, size: 16 }],
      };
      stepMany(swarm, ctx, 30);
      return -agent.y;
    };
    expect(displacement(10)).toBeGreaterThan(displacement(2));
    expect(displacement(0)).toBeCloseTo(0, 6);
  });

  it('leaves the main shoal alone when there are no threats at all', () => {
    const swarm = new SwarmSimulation(14);
    const agent = place(swarm, [{ x: 100, y: 0 }])[0]!;
    stepMany(swarm, makeContext(inertTuning({ predatorFear: 5 })), 30);
    expect(agent.faction).toBe(MAIN_FACTION);
    expect(Math.abs(agent.y)).toBeLessThan(0.001);
  });
});
