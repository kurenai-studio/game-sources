import { describe, expect, it } from 'vitest';
import { CONTACT_AGENTS, CONTACT_HOLD, RescueSystem } from '../src/sim/RescueSystem';
import { SwarmSimulation } from '../src/sim/SwarmSimulation';
import { MAIN_FACTION } from '../src/sim/Agent';
import { inertTuning, makeContext, place, stepMany } from './helpers';

const HARD_CURRENT = {
  sample: (_x: number, _y: number, out: { x: number; y: number }) => {
    out.x = 1200;
    out.y = 0;
  },
};

function setup(mainAgents: number, mainX = 200, mainY = 400) {
  const swarm = new SwarmSimulation(1);
  const rescue = new RescueSystem();
  const pod = rescue.spawn(swarm, 200, 400, 10);
  const specs = Array.from({ length: mainAgents }, (_, i) => ({
    x: mainX + (i % 4) * 4,
    y: mainY + Math.floor(i / 4) * 4,
  }));
  const main = place(swarm, specs);
  return { swarm, rescue, pod, main };
}

describe('RescueSystem', () => {
  it('merges a pod after sustained contact', () => {
    const { swarm, rescue, pod } = setup(CONTACT_AGENTS + 2);
    let merged: unknown[] = [];
    for (let i = 0; i < 60; i++) merged = merged.concat(rescue.update(1 / 60, swarm));
    expect(pod.merged).toBe(true);
    expect(merged.length).toBe(1);
    for (const m of pod.members) {
      if (!m.alive) continue;
      expect(m.faction).toBe(MAIN_FACTION);
      expect(m.anchorRadius).toBe(0);
      expect(m.anchored).toBe(false);
    }
    expect(swarm.aliveCount(MAIN_FACTION)).toBe(CONTACT_AGENTS + 2 + pod.initialCount);
  });

  it('releases rescued fish into the water and the main shoal', () => {
    const { swarm, rescue, pod } = setup(CONTACT_AGENTS + 2);
    for (let i = 0; i < 60; i++) rescue.update(1 / 60, swarm);
    expect(pod.merged).toBe(true);

    const ctx = makeContext(
      inertTuning({ flowCoupling: 12, maxAccel: 3000, maxSpeed: 700 }),
      HARD_CURRENT,
    );
    stepMany(swarm, ctx, 60);

    expect(
      pod.members.some((m) => Math.hypot(m.x - pod.x, m.y - pod.y) > pod.radius),
    ).toBe(true);
    for (const m of pod.members) expect(m.faction).toBe(MAIN_FACTION);
  });

  it('does not merge with too few individuals present', () => {
    const { swarm, rescue, pod } = setup(CONTACT_AGENTS - 3);
    for (let i = 0; i < 180; i++) rescue.update(1 / 60, swarm);
    expect(pod.merged).toBe(false);
    expect(pod.contact).toBe(0);
  });

  it('needs the contact held, not just touched', () => {
    const { swarm, rescue, pod } = setup(CONTACT_AGENTS + 2);
    const short = Math.floor((CONTACT_HOLD * 60) / 2);
    for (let i = 0; i < short; i++) rescue.update(1 / 60, swarm);
    expect(pod.merged).toBe(false);
    expect(pod.contact).toBeGreaterThan(0);
  });

  it('bleeds contact back off when the shoal leaves', () => {
    const { swarm, rescue, pod, main } = setup(CONTACT_AGENTS + 2);
    for (let i = 0; i < 20; i++) rescue.update(1 / 60, swarm);
    const held = pod.contact;
    for (const a of main) a.x = 5000;
    for (let i = 0; i < 10; i++) rescue.update(1 / 60, swarm);
    expect(pod.contact).toBeLessThan(held);
  });

  it('ignores contact from another pod, only the player shoal counts', () => {
    const swarm = new SwarmSimulation(1);
    const rescue = new RescueSystem();
    const pod = rescue.spawn(swarm, 200, 400, 10);
    rescue.spawn(swarm, 210, 400, 12);
    for (let i = 0; i < 120; i++) rescue.update(1 / 60, swarm);
    expect(pod.merged).toBe(false);
  });

  it('reports an un-merged pod left behind as missed and removes its members', () => {
    const { swarm, rescue, pod } = setup(0);
    const missed = rescue.prune(pod.y - 1);
    expect(missed.map((m) => m.id)).toEqual([pod.id]);
    expect(swarm.aliveCount(pod.id)).toBe(0);
    expect(rescue.pods.length).toBe(0);
  });

  it('does not report a merged pod as missed', () => {
    const { swarm, rescue, pod } = setup(CONTACT_AGENTS + 2);
    for (let i = 0; i < 60; i++) rescue.update(1 / 60, swarm);
    for (let i = 0; i < 60; i++) rescue.update(1 / 60, swarm);
    expect(rescue.prune(pod.y - 1)).toEqual([]);
  });

  it('closes out a pod whose members all died', () => {
    const { swarm, rescue, pod } = setup(0);
    for (const m of pod.members) m.alive = false;
    rescue.update(1 / 60, swarm);
    expect(pod.merged).toBe(true);
  });
});
