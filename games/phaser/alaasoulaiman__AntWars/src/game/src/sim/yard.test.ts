// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests for the Yard's rocks and holes, the steering round a rock, and the Anteater every 25th round.
import { describe, expect, it } from 'vitest';
import { BOSS_ESCORT, BOSS_SPAWN_GAP, bossKind, enemyHealth, isBreatherRound, roundPlan, spawnGapSeconds, PREDATOR_SPEED_CAP } from './curve';
import { ANTEATER_GULP, ANTEATER_REACH, PREDATORS, anteaterGulp, pickPredator, predatorHealth, predatorSpeedShare } from './roster';
import {
  NEST_AT,
  ROCKS,
  SIDESTEP_SECONDS,
  STALL_SECONDS,
  STALL_SPEED,
  STEER_MARGIN,
  rockContact,
  rockTouching,
  sidestepHeading,
  spawnHoles,
  stallStep,
  steerAround,
  type Circle,
  type Point,
} from './yard';
import { NEST_SHOP_RADIUS, SOFT_EDGE, WORLD_H, WORLD_W } from '../game/tuning';

const dist = (a: Point, b: Point) => Math.hypot(a.x - b.x, a.y - b.y);

describe('the Yard: three rocks and twelve holes', () => {
  it('twelve holes in the edge band, where slice 1 put them', () => {
    const holes = spawnHoles();
    expect(holes.length).toBe(12);
    expect(holes[0].x).toBeCloseTo(259.2, 9);
    expect(holes[0].y).toBeCloseTo(68.2, 9);
    expect(holes[11]).toEqual({ x: WORLD_W - SOFT_EDGE * 0.62, y: WORLD_H * 0.8 });
  });

  it('three rocks, none touching another', () => {
    expect(ROCKS.length).toBe(3);
    for (let i = 0; i < ROCKS.length; i++) {
      for (let j = i + 1; j < ROCKS.length; j++) expect(dist(ROCKS[i], ROCKS[j])).toBeGreaterThan(ROCKS[i].r + ROCKS[j].r + 200);
    }
  });

  it.each(ROCKS.map((r, i) => [i, r] as const))('rock %i keeps clear of the nest loop, the holes and the edge band', (_i, rock) => {
    // The nest loop: an ant circling the nest at 380 units (the long bot's loop) never meets a rock.
    expect(dist(rock, NEST_AT) - rock.r).toBeGreaterThanOrEqual(420);
    expect(dist(rock, NEST_AT) - rock.r).toBeGreaterThan(NEST_SHOP_RADIUS);
    for (const h of spawnHoles()) expect(dist(rock, h) - rock.r).toBeGreaterThanOrEqual(250);
    expect(rock.x - rock.r).toBeGreaterThan(SOFT_EDGE);
    expect(rock.y - rock.r).toBeGreaterThan(SOFT_EDGE);
    expect(rock.x + rock.r).toBeLessThan(WORLD_W - SOFT_EDGE);
    expect(rock.y + rock.r).toBeLessThan(WORLD_H - SOFT_EDGE);
  });

  it('contact means within 2 units of the rock edge', () => {
    const rock = ROCKS[0];
    expect(rockContact(rock.x, rock.y + rock.r + 16, 16)).toBe(true);
    expect(rockContact(rock.x, rock.y + rock.r + 18, 16)).toBe(true);
    expect(rockContact(rock.x, rock.y + rock.r + 19, 16)).toBe(false);
    expect(rockContact(NEST_AT.x, NEST_AT.y, 16)).toBe(false);
  });
});

describe('steering round a rock', () => {
  const rock: Circle = ROCKS[0];
  const clear = (r: number) => rock.r + r + STEER_MARGIN;
  /** How close a ray from p along u passes to the rock's centre, or Infinity when the rock is behind it. */
  const passGap = (p: Point, u: Point) => {
    const cx = rock.x - p.x;
    const cy = rock.y - p.y;
    if (cx * u.x + cy * u.y <= 0) return Infinity;
    return Math.abs(u.x * cy - u.y * cx);
  };

  it('open ground: straight at the target', () => {
    const u = steerAround(NEST_AT.x, NEST_AT.y, NEST_AT.x, NEST_AT.y - 300, 15);
    expect(u.x).toBeCloseTo(0, 9);
    expect(u.y).toBeCloseTo(-1, 9);
  });

  it('a rock dead ahead: the new heading grazes its clearance and still gains on the target', () => {
    const p = { x: rock.x, y: rock.y + 360 };
    const u = steerAround(p.x, p.y, rock.x, rock.y - 360, 15);
    expect(Math.hypot(u.x, u.y)).toBeCloseTo(1, 9);
    expect(passGap(p, u)).toBeCloseTo(clear(15), 6);
    expect(u.y).toBeLessThan(0);
  });

  it('a rock a little to one side: it passes on the other side', () => {
    const u = steerAround(rock.x + 30, rock.y + 360, rock.x + 30, rock.y - 360, 15);
    expect(u.x).toBeGreaterThan(0);
    const w = steerAround(rock.x - 30, rock.y + 360, rock.x - 30, rock.y - 360, 15);
    expect(w.x).toBeLessThan(0);
  });

  it('pressed against the rock with the target behind it: it slides along the edge', () => {
    const u = steerAround(rock.x, rock.y + rock.r + 16, rock.x, rock.y - 400, 16);
    expect(Math.abs(u.y)).toBeLessThan(1e-9);
    expect(Math.abs(u.x)).toBeCloseTo(1, 9);
  });

  it('a rock beyond the target or behind the walker changes nothing', () => {
    expect(steerAround(rock.x, rock.y + 360, rock.x, rock.y + 160, 15)).toMatchObject({ x: expect.closeTo(0, 9), y: expect.closeTo(-1, 9) });
    expect(steerAround(rock.x, rock.y + 160, rock.x, rock.y + 600, 15)).toMatchObject({ x: expect.closeTo(0, 9), y: expect.closeTo(1, 9) });
    expect(steerAround(10, 10, 10, 10, 15)).toEqual({ x: 0, y: 0 });
  });

  it.each([15, 46])('a walker of radius %i from every hole reaches the nest and never enters a rock', (r) => {
    for (const h of spawnHoles()) {
      let p = { x: h.x, y: h.y };
      let minGap = Infinity;
      let steps = 0;
      while (dist(p, NEST_AT) > 60 && steps < 1000) {
        const u = steerAround(p.x, p.y, NEST_AT.x, NEST_AT.y, r);
        p = { x: p.x + u.x * 5, y: p.y + u.y * 5 };
        for (const c of ROCKS) minGap = Math.min(minGap, dist(p, c) - c.r - r);
        steps += 1;
      }
      expect(dist(p, NEST_AT)).toBeLessThanOrEqual(60);
      expect(minGap).toBeGreaterThanOrEqual(0);
      expect(steps).toBeLessThan(400);
    }
  });
});

describe('a walker parked on a rock sidesteps (VG3 note 3)', () => {
  const run = (frames: number, onRock: boolean, speed: number, dt = 1 / 16) => {
    let s = { stalledFor: 0, sidestepLeft: 0 };
    const out: Array<ReturnType<typeof stallStep>> = [];
    for (let i = 0; i < frames; i++) {
      const r = stallStep(s, onRock, speed, dt);
      out.push(r);
      s = { stalledFor: r.stalledFor, sidestepLeft: r.sidestepLeft };
    }
    return out;
  };

  it('2 s pressed on a rock barely moving starts a 1 s sidestep, not a frame sooner', () => {
    expect(STALL_SECONDS).toBe(2);
    expect(SIDESTEP_SECONDS).toBe(1);
    const frames = run(70, true, 3);
    const first = frames.findIndex((f) => f.started);
    expect(first).toBe(31);
    expect(frames.slice(0, first).every((f) => !f.sidestep)).toBe(true);
    const during = frames.slice(first, first + 17).filter((f) => f.sidestep).length;
    expect(during).toBe(17);
    expect(frames[first + 17].sidestep).toBe(false);
  });

  it('a walker that keeps moving along the rock, or stands off it, never sidesteps', () => {
    expect(run(100, true, STALL_SPEED).some((f) => f.sidestep)).toBe(false);
    expect(run(100, false, 0).some((f) => f.sidestep)).toBe(false);
  });

  it('the sidestep runs along the rock edge, either way round', () => {
    const rock = ROCKS[0];
    const p = { x: rock.x + rock.r + 15, y: rock.y };
    const a = sidestepHeading(p.x, p.y, rock, 1);
    const b = sidestepHeading(p.x, p.y, rock, -1);
    expect(Math.hypot(a.x, a.y)).toBeCloseTo(1, 9);
    expect(a.x * 1 + a.y * 0).toBeCloseTo(0, 9);
    expect(b.x).toBeCloseTo(-a.x, 9);
    expect(b.y).toBeCloseTo(-a.y, 9);
    expect(rockTouching(p.x, p.y, 15)).toBe(rock);
    expect(rockTouching(NEST_AT.x, NEST_AT.y, 15)).toBeNull();
  });
});

describe('the Anteater every 25th round', () => {
  it.each([[25, true], [50, true], [75, true], [5, false], [20, false], [24, false], [26, false]])('round %i is the Anteater: %s', (round, expected) => {
    expect(bossKind(round) === 'anteater').toBe(expected);
  });

  // Lane N1, design note of 2026-10-29: the escort came 1.5 s apart (BOSS_SPAWN_GAP); from the ramp it takes the
  // horde gap of its round, 0.146 s at round 25.
  it('round 25 sends the Anteater plus 30 termites, the round 25 health, the horde gap of round 25 and the usual break', () => {
    const p = roundPlan(25);
    expect(p).toMatchObject({ round: 25, kind: 'boss', total: BOSS_ESCORT + 1, aliveCap: 20, health: enemyHealth(25), breakSeconds: 15 });
    expect(BOSS_ESCORT).toBe(30);
    expect(p.spawnGap).toBe(spawnGapSeconds(25));
    expect(p.spawnGap).toBeCloseTo(0.145994512169, 11);
    expect(p.spawnGap).toBeLessThan(BOSS_SPAWN_GAP);
    expect(BOSS_SPAWN_GAP).toBe(1.5);
    expect(isBreatherRound(25)).toBe(true);
    // Slice 4: round 20 is the Brood Hornet's now; round 15 stays a termite rush.
    expect(roundPlan(20)).toMatchObject({ kind: 'boss', boss: 'hornet' });
    expect(roundPlan(15).kind).toBe('breather');
    expect(p.boss).toBe('anteater');
    expect(roundPlan(26)).toMatchObject({ kind: 'horde', total: 84 });
  });

  it('slow, heavy, with a big health bar: 20 army ants of health, 22 percent of the ant speed', () => {
    expect(enemyHealth(25)).toBe(4365);
    expect(predatorHealth('anteater', enemyHealth(25))).toBe(87300);
    expect(predatorHealth('anteater', enemyHealth(50))).toBe(20 * enemyHealth(40));
    for (const roll of [0, 0.5, 0.999]) expect(predatorSpeedShare('anteater', 25, roll)).toBe(0.22);
    expect(PREDATORS.anteater.speedShare).toBeLessThan(PREDATOR_SPEED_CAP);
    expect(PREDATORS.anteater.biteDamage).toBeGreaterThan(PREDATORS.armyAnt.biteDamage);
    expect(PREDATORS.anteater.behaviour).toBe('nestRaid');
  });

  it('never rolls as a normal spawn; its escort is all termites', () => {
    for (let round = 1; round <= 60; round++) {
      for (const roll of [0, 0.1, 0.2, 0.3, 0.5, 0.9, 0.999]) expect(pickPredator(round, roll)).not.toBe('anteater');
    }
    for (const roll of [0, 0.5, 0.999]) expect(pickPredator(25, roll)).toBe('termite');
  });

  it.each([[1000, 250], [250, 250], [100, 100], [0, 0], [-5, 0]])('a gulp from %i nectar takes %i', (stock, eaten) => {
    expect(anteaterGulp(stock)).toBe(eaten);
  });

  it('it eats only once its snout is at the nest', () => {
    expect(ANTEATER_GULP).toBe(250);
    expect(ANTEATER_REACH).toBeLessThan(NEST_SHOP_RADIUS + PREDATORS.anteater.radius);
    expect(ANTEATER_REACH).toBeGreaterThan(PREDATORS.anteater.radius);
  });
});
