import { DEFAULT_TUNING, cloneTuning, type Tuning } from '../src/config/tuning';
import type { SwarmSimulation } from '../src/sim/SwarmSimulation';
import { FlowField } from '../src/sim/FlowField';
import { ObstacleSystem } from '../src/sim/ObstacleSystem';
import type { SwarmContext, WaterSampler } from '../src/sim/SwarmSimulation';
import { MAIN_FACTION, type Agent } from '../src/sim/Agent';

export const W = 390;
export const H = 844;

/** A tuning with every force off, so a test can enable exactly one. */
export function inertTuning(overrides: Partial<Tuning> = {}): Tuning {
  const t = cloneTuning(DEFAULT_TUNING);
  t.alignment = 0;
  t.cohesion = 0;
  t.separation = 0;
  t.migrationForce = 0;
  t.flowCoupling = 0;
  t.obstacleAvoidance = 0;
  t.noise = 0;
  t.cruiseSpeed = 120;
  return Object.assign(t, overrides);
}

export function makeContext(
  tuning: Tuning,
  field: WaterSampler = new FlowField(W, H),
  obstacles = new ObstacleSystem(W, 1),
): SwarmContext {
  // Tests drive the player's field only; the ocean's own current is exercised
  // separately in tests/ambient.test.ts so a boids assertion is never fighting it.
  return {
    water: field,
    obstacles,
    tuning,
    width: W,
    migrationX: 0,
    migrationSpeed: tuning.migrationSpeed,
    migrationY: -1,
    massFactor: 1,
  };
}

export function place(swarm: SwarmSimulation, specs: { x: number; y: number; vx?: number; vy?: number }[]): Agent[] {
  swarm.spawnShoal(specs.length, 0, 0, 1);
  const out: Agent[] = [];
  let i = 0;
  for (const a of swarm.agents) {
    if (!a.alive || a.faction !== MAIN_FACTION) continue;
    const s = specs[i++];
    if (s === undefined) break;
    a.x = s.x;
    a.y = s.y;
    a.px = s.x;
    a.py = s.y;
    a.vx = s.vx ?? 0;
    a.vy = s.vy ?? 0;
    a.variation = 1;
    a.phase = 0;
    out.push(a);
  }
  return out;
}

export function dist(a: Agent, b: Agent): number {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

export function stepMany(
  swarm: SwarmSimulation,
  ctx: SwarmContext,
  steps: number,
  dt = 1 / 60,
): void {
  for (let i = 0; i < steps; i++) swarm.step(dt, ctx);
}
