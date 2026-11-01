// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests for the dart's start and the point blank hit test (VG3 collateral 1: a still ant under a swarm).
import { describe, expect, it } from 'vitest';
import { DART_SPEED } from '../game/tuning';
import { PREDATORS } from './roster';
import { HIT_GROUP_MS, dartOrigin, firstTouched, groupHit, inView, type Disc } from './hit';

/** What a dart covers before its first overlap test: one 60 Hz physics step, plus a little. */
const REACH = DART_SPEED / 60 + 2;
const DART_R = 5;
const TERMITE_R = PREDATORS.termite.radius;

describe('a dart leaves from the ant', () => {
  it('from the ant centre itself, side by side darts across the aim', () => {
    expect(dartOrigin(500, 700, 0, 0)).toEqual({ x: 500, y: 700 });
    const right = dartOrigin(500, 700, 0, 14);
    expect(right.x).toBeCloseTo(500, 9);
    expect(right.y).toBeCloseTo(714, 9);
    const up = dartOrigin(500, 700, -Math.PI / 2, 14);
    expect(up.x).toBeCloseTo(514, 9);
    expect(up.y).toBeCloseTo(700, 9);
  });
});

describe('the point blank hit test', () => {
  it.each([
    ['a termite sitting on the ant', { x: 0, y: 0, r: TERMITE_R }, 0],
    ['a termite 20 units ahead', { x: 20, y: 0, r: TERMITE_R }, 0],
    ['a termite 3 units ahead and 12 to the side', { x: 3, y: 12, r: TERMITE_R }, 0],
    ['a termite 20 units behind', { x: -20, y: 0, r: TERMITE_R }, -1],
    ['a termite 30 units to the side', { x: 5, y: 30, r: TERMITE_R }, -1],
    ['a termite past the first step', { x: 60, y: 0, r: TERMITE_R }, -1],
  ] as const)('%s', (_name, disc, expected) => {
    expect(firstTouched(0, 0, 1, 0, REACH, DART_R, [disc])).toBe(expected);
  });

  it('the nearest along the path comes first, whatever the order of the list', () => {
    const discs: Disc[] = [{ x: 30, y: 0, r: TERMITE_R }, { x: 8, y: 2, r: TERMITE_R }];
    expect(firstTouched(0, 0, 1, 0, REACH, DART_R, discs)).toBe(1);
  });

  it('the swarm VG3 saw at round 25: every termite within 23 units of a still ant can be hit by a dart aimed at it', () => {
    const swarm: Disc[] = [];
    for (let i = 0; i < 11; i++) {
      const a = (i * 2 * Math.PI) / 11;
      const d = 2 + (i * 18) / 10;
      swarm.push({ x: Math.cos(a) * d, y: Math.sin(a) * d, r: TERMITE_R });
    }
    for (const t of swarm) {
      const len = Math.hypot(t.x, t.y);
      const ux = t.x / len;
      const uy = t.y / len;
      const o = dartOrigin(0, 0, Math.atan2(uy, ux), 0);
      const hit = firstTouched(o.x, o.y, ux, uy, REACH, DART_R, swarm);
      expect(hit).toBeGreaterThanOrEqual(0);
    }
  });

  it('the old launch could not: a dart 22 units out, first tested one step later, never touches a termite inside 18 units', () => {
    const first = 22 + DART_SPEED / 60;
    for (const d of [0, 5, 10, 15, 18]) {
      expect(firstTouched(first, 0, 1, 0, 0, DART_R, [{ x: d, y: 0, r: TERMITE_R }])).toBe(-1);
    }
  });
});

describe('only what the player can see (design note of 2026-10-24)', () => {
  const view = { x: 100, y: 200, width: 720, height: 1558 };
  it.each([
    ['in the middle', 460, 980, 15, true],
    ['its centre just past the right edge, its body still in', 830, 980, 15, true],
    ['wholly past the right edge', 836, 980, 15, false],
    ['wholly past the left edge', 84, 980, 15, false],
    ['touching the left edge', 85, 980, 15, true],
    ['above the top', 460, 184, 15, false],
    ['touching the top', 460, 185, 15, true],
    ['below the bottom', 460, 1774, 15, false],
    ['a big boss half in', 860, 980, 46, true],
  ])('%s: %s', (_name, x, y, r, want) => {
    expect(inView(x as number, y as number, r as number, view)).toBe(want);
  });
});

describe('one number for hits on one target within half a second (design note of 2026-10-24)', () => {
  it('a first hit starts a group; hits within 500 ms add to it; one later starts a new one', () => {
    expect(HIT_GROUP_MS).toBe(500);
    const a = groupHit(null, 150, 1000);
    expect(a).toEqual({ group: { total: 150, lastAt: 1000 }, joined: false });
    const b = groupHit(a.group, 150, 1010);
    expect(b).toEqual({ group: { total: 300, lastAt: 1010 }, joined: true });
    const c = groupHit(b.group, 112.5, 1510);
    expect(c).toEqual({ group: { total: 412.5, lastAt: 1510 }, joined: true });
    const d = groupHit(c.group, 150, 2011);
    expect(d).toEqual({ group: { total: 150, lastAt: 2011 }, joined: false });
  });

  it('three darts of one volley, then a volley every 0.42 s: one number that keeps the running total', () => {
    let g = groupHit(null, 100, 0).group;
    let shown = 1;
    for (const t of [2, 4, 420, 422, 424, 840, 842, 844]) {
      const r = groupHit(g, 100, t);
      g = r.group;
      if (!r.joined) shown += 1;
    }
    expect(shown).toBe(1);
    expect(g.total).toBe(900);
  });
});
