// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests that pin the CONCEPT_V2 section 2 round curve.
import { describe, expect, it } from 'vitest';
import {
  BOSS_SPAWN_GAP,
  BREAK_SECONDS,
  BREATHER_COUNT,
  BREATHER_SPAWN_GAP,
  COUNT_BASE,
  breatherAppearance,
  breatherByAppearance,
  MAX_ALIVE,
  SPAWN_GAP_TUNING,
  PREDATOR_SPEED_CAP,
  aliveCap,
  breakStep,
  capPredatorSpeed,
  conceptSpawnGapSeconds,
  enemiesForRound,
  enemyHealth,
  isBreatherRound,
  pickSpeedTier,
  roundPlan,
  spawnGapSeconds,
  LATE_SPAWN_FROM,
  LATE_SPAWN_TUNING,
  speedMix,
  speedBand,
  bossKind,
  isBossRound,
  SLOW_LAST_ROUND,
  FAST_FROM_ROUND,
  MID_BOSS_EVERY,
  MID_BOSS_ROTATION,
  tierSpeedShare,
  uncappedHealth,
} from './curve';

/** Rounds a number to three significant figures, the precision the concept table prints. */
function sig3(n: number): number {
  const p = Math.pow(10, Math.floor(Math.log10(Math.abs(n))) - 2);
  return Math.round(n / p) * p;
}

describe('enemies per round (24 + 3 x max(1, round / 5), early cuts, 0.09 x round squared from 10)', () => {
  it.each([
    [1, 6], [2, 8], [3, 13], [4, 18], [5, 24], [6, 27], [9, 29],
    [10, 33], [15, 44], [18, 53], [20, 60], [30, 105], [40, 168], [50, 249],
    // 0.09 x 121 = 10.89 and 0.09 x 144 = 12.96: these two catch a round in place of the floor on the squared term.
    [11, 34], [12, 36],
  ])('round %i sends %i', (round, expected) => {
    expect(enemiesForRound(round)).toBe(expected);
  });

  it('never drops from one round to the next after the early cuts', () => {
    for (let r = 5; r < 120; r++) expect(enemiesForRound(r + 1)).toBeGreaterThanOrEqual(enemiesForRound(r));
  });
});

describe('alive at once is capped at 20 (design note of 2026-10-24, down from 24 in the concept)', () => {
  it.each([
    [1, 6], [2, 8], [3, 13], [4, 18], [5, 20], [6, 20], [10, 20], [50, 20],
  ])('round %i allows %i alive', (round, expected) => {
    expect(aliveCap(round)).toBe(expected);
  });
  it('the cap constant is 20; the count formula keeps its base of 24, so the round counts do not move', () => {
    expect(MAX_ALIVE).toBe(20);
    expect(COUNT_BASE).toBe(24);
    expect(enemiesForRound(6)).toBe(27);
  });
});

describe('enemy health: 150, plus 100 a round to 950, then plus 10 percent a round', () => {
  it.each([
    [1, 150], [2, 250], [3, 350], [5, 550], [6, 650], [9, 950], [10, 1045],
  ])('round %i is exactly %i', (round, expected) => {
    expect(uncappedHealth(round)).toBe(expected);
    expect(enemyHealth(round)).toBe(expected);
  });

  it.each([
    [15, 1680], [18, 2240], [20, 2710], [30, 7030], [40, 18200], [50, 47300],
  ])('uncapped round %i matches the concept table %i to three figures', (round, expected) => {
    expect(sig3(uncappedHealth(round))).toBe(expected);
  });

  it('growth stops at round 40 (our change): 41, 50 and 100 equal 40', () => {
    const at40 = enemyHealth(40);
    expect(sig3(at40)).toBe(18200);
    expect(enemyHealth(41)).toBe(at40);
    expect(enemyHealth(50)).toBe(at40);
    expect(enemyHealth(100)).toBe(at40);
    expect(enemyHealth(50)).toBeLessThan(uncappedHealth(50));
  });

  it('never drops from one round to the next', () => {
    for (let r = 1; r < 80; r++) expect(enemyHealth(r + 1)).toBeGreaterThanOrEqual(enemyHealth(r));
  });
});

describe('the concept spawn gap: 2.0 s shrinking 5 percent a round with a 0.1 s floor', () => {
  it.each([
    [1, 2.0], [2, 1.9], [3, 1.805],
  ])('round %i is %f s', (round, expected) => {
    expect(conceptSpawnGapSeconds(round)).toBeCloseTo(expected, 9);
  });

  it('every round is the previous times 0.95 until the floor', () => {
    for (let r = 1; r < 100; r++) {
      const next = Math.max(0.1, conceptSpawnGapSeconds(r) * 0.95);
      expect(conceptSpawnGapSeconds(r + 1)).toBeCloseTo(next, 9);
    }
  });

  // The concept table prints 2.0 x 0.95^(round - 1) cut to one decimal; its round 15 row shows 0.975 rounded up to 1.0.
  it.each([
    [1, 2.0], [2, 1.9], [3, 1.8], [5, 1.6], [6, 1.5], [9, 1.3], [10, 1.2],
    [18, 0.8], [20, 0.7], [30, 0.4], [40, 0.2], [50, 0.1],
  ])('round %i shows %f s in the concept table', (round, expected) => {
    expect(Math.floor(conceptSpawnGapSeconds(round) * 10 + 1e-9) / 10).toBeCloseTo(expected, 9);
  });

  it('round 15 is 0.975 s (the table rounds it to 1.0)', () => {
    expect(conceptSpawnGapSeconds(15)).toBeCloseTo(0.975, 3);
  });

  it('the floor holds from round 60 on', () => {
    expect(conceptSpawnGapSeconds(59)).toBeGreaterThan(0.1);
    expect(conceptSpawnGapSeconds(60)).toBe(0.1);
    expect(conceptSpawnGapSeconds(500)).toBe(0.1);
  });
});

describe('the game spawn gap: half the concept gap (design note of 2026-10-24), a quarter from round 6 (design note of 2026-10-25), the 0.1 s floor kept', () => {
  it.each([
    [1, 1.0], [2, 0.95], [3, 0.9025], [6, 0.3868904687], [10, 0.3151247049],
    [11, 0.2993684696], [12, 0.2844000461], [16, 0.2316456151], [20, 0.1886768013],
  ])('round %i is %f s', (round, expected) => {
    expect(spawnGapSeconds(round)).toBeCloseTo(expected, 9);
  });

  // Lane G9, M3: the horde gap by round across the step of 2026-10-25 (faster spawns after round 5).
  it.each([
    [5, 0.81450625, 'half'],
    [6, 0.38689046875, 'a quarter of'],
    [10, 0.3151247049, 'a quarter of'],
    [11, 0.2993684696, 'a quarter of'],
  ])('round %i: the horde gap is %f s (%s the concept gap)', (round, expected) => {
    expect(spawnGapSeconds(round)).toBeCloseTo(expected, 9);
  });

  // Lane N1, design note of 2026-10-29: round 10's escort came 1.5 s apart here; from the ramp it takes the horde gap.
  it('the termite rush at round 5 keeps its own gap, the round 10 boss takes the horde gap (lane N1), the alive cap stays 20', () => {
    expect(roundPlan(5).kind).toBe('breather');
    expect(roundPlan(5).spawnGap).toBe(0.3);
    expect(roundPlan(10).kind).toBe('boss');
    expect(roundPlan(10).spawnGap).toBe(spawnGapSeconds(10));
    expect(roundPlan(6).spawnGap).toBe(spawnGapSeconds(6));
    expect(MAX_ALIVE).toBe(20);
  });

  it('is half the concept gap through round 5 and a quarter from round 6, never under the floor', () => {
    expect(SPAWN_GAP_TUNING).toBe(0.5);
    expect(LATE_SPAWN_FROM).toBe(6);
    expect(LATE_SPAWN_TUNING).toBe(0.5);
    for (let r = 1; r < 120; r++) {
      const share = r >= 6 ? 0.25 : 0.5;
      expect(spawnGapSeconds(r)).toBeCloseTo(Math.max(0.1, conceptSpawnGapSeconds(r) * share), 9);
      expect(spawnGapSeconds(r)).toBeGreaterThanOrEqual(0.1);
    }
  });

  it('the step at round 6 is a halving: round 6 is half what the 18:43 tuning gave it', () => {
    expect(spawnGapSeconds(6)).toBeCloseTo(conceptSpawnGapSeconds(6) * 0.25, 12);
    expect(spawnGapSeconds(6) / spawnGapSeconds(5)).toBeCloseTo(0.95 / 2, 12);
  });

  it('20 spawns come in under 6.3 s at round 12 and under 5.3 s at round 16 (0.8 s to the first, then the gaps)', () => {
    expect(0.8 + 19 * spawnGapSeconds(12)).toBeLessThan(6.3);
    expect(0.8 + 19 * spawnGapSeconds(16)).toBeLessThan(5.3);
  });

  it('the floor now holds from round 33 on', () => {
    expect(spawnGapSeconds(32)).toBeGreaterThan(0.1);
    expect(spawnGapSeconds(33)).toBe(0.1);
    expect(spawnGapSeconds(500)).toBe(0.1);
  });
});

// Design note, 2026-10-29 (lane N1): from the ramp (LATE_SPAWN_FROM, round 6) no round type may spawn slower than the
// horde gap of its number; a boss round's escort was 1.5 s apart, so round 10 read as a slow round, and a later rush
// kept its own slower gap.
/** The round's own gap: the escort's for a boss round, the rush's by its visit, the horde gap for a horde round. */
function ownGap(round: number): number {
  const kind = roundPlan(round).kind;
  if (kind === 'boss') return BOSS_SPAWN_GAP;
  if (kind === 'breather') return breatherByAppearance(breatherAppearance(round)).gap;
  return spawnGapSeconds(round);
}

describe('from the ramp no round spawns slower than the horde gap of its number (lane N1)', () => {
  // [round, kind, the plan's gap now, the gap on 5304e3e]
  it.each([
    [5, 'breather', 0.3, 0.3],
    [6, 'horde', 0.38689046875, 0.38689046875],
    [10, 'boss', 0.315124704862, 1.5],
    [15, 'breather', 0.243837489558, 0.27],
    [20, 'boss', 0.188676801268, 1.5],
    [25, 'boss', 0.145994512169, 1.5],
    [30, 'boss', 0.112967770496, 1.5],
    [35, 'breather', 0.1, 0.243],
    [50, 'boss', 0.1, 1.5],
  ] as const)('round %i (%s) spawns every %f s (it was %f s)', (round, kind, now, before) => {
    const p = roundPlan(round);
    expect(p.kind).toBe(kind);
    expect(p.spawnGap).toBeCloseTo(now, 11);
    // The rule: the round's own gap before the ramp, the faster of it and the horde gap from the ramp on.
    const own = ownGap(round);
    expect(own).toBeCloseTo(before, 11);
    expect(p.spawnGap).toBe(round >= LATE_SPAWN_FROM ? Math.min(own, spawnGapSeconds(round)) : own);
    if (round >= LATE_SPAWN_FROM) expect(p.spawnGap).toBeLessThanOrEqual(spawnGapSeconds(round));
    // The counts, the cap and the health do not move with the gap.
    expect(p.aliveCap).toBe(MAX_ALIVE);
    expect(p.health).toBe(enemyHealth(round));
  });

  it('every round from 6 to 120 spawns at the horde gap of its number or faster; rounds 1 to 5 keep their own', () => {
    for (let r = 1; r <= 120; r++) {
      const p = roundPlan(r);
      if (r < LATE_SPAWN_FROM) expect(p.spawnGap).toBe(ownGap(r));
      else {
        expect(p.spawnGap).toBeLessThanOrEqual(spawnGapSeconds(r));
        expect(p.spawnGap).toBe(Math.min(ownGap(r), spawnGapSeconds(r)));
        expect(p.spawnGap).toBeGreaterThanOrEqual(0.1);
      }
    }
    expect(LATE_SPAWN_FROM).toBe(6);
    // Round 5's rush already beat its horde (0.3 s against 0.81 s): nothing moves there.
    expect(roundPlan(5).spawnGap).toBe(BREATHER_SPAWN_GAP);
    expect(spawnGapSeconds(5)).toBeGreaterThan(BREATHER_SPAWN_GAP);
  });
});

describe('pacing constants', () => {
  it('the countdown between rounds is 15 s (feel round 1, up from 10)', () => expect(BREAK_SECONDS).toBe(15));
});

describe('speed: slow through round 4, mixed from 5 to 12, fast from 13 at 94 percent of the ant (slice 4)', () => {
  it('the cap is 0.94 and nothing passes it', () => {
    expect(PREDATOR_SPEED_CAP).toBe(0.94);
    expect(capPredatorSpeed(1.2)).toBe(0.94);
    expect(capPredatorSpeed(0.5)).toBe(0.5);
    for (const tier of ['walk', 'jog', 'sprint'] as const) expect(tierSpeedShare(tier)).toBeLessThanOrEqual(0.94);
  });

  it('round 1 enemies move at 50 percent and sprinters at the cap', () => {
    expect(tierSpeedShare('walk')).toBe(0.5);
    expect(tierSpeedShare('sprint')).toBe(0.94);
    expect(tierSpeedShare('jog')).toBeGreaterThan(0.5);
    expect(tierSpeedShare('jog')).toBeLessThan(0.94);
  });

  it('shares sum to 1 every round', () => {
    for (let r = 1; r <= 60; r++) {
      const m = speedMix(r);
      expect(m.walk + m.jog + m.sprint).toBeCloseTo(1, 9);
      expect(Math.min(m.walk, m.jog, m.sprint)).toBeGreaterThanOrEqual(0);
    }
  });

  it.each([
    [1, 'slow'], [4, 'slow'], [5, 'mixed'], [8, 'mixed'], [12, 'mixed'], [13, 'fast'], [20, 'fast'], [60, 'fast'],
  ])('round %i is in the %s band', (round, band) => {
    expect(speedBand(round as number)).toBe(band);
  });

  it('the bands, row by row: walkers only to round 4, the mix from 5 to 12, every one sprints from 13', () => {
    for (const r of [1, 2, 3, 4]) expect(speedMix(r)).toEqual({ walk: 1, jog: 0, sprint: 0 });
    const m5 = speedMix(5);
    expect(m5.walk).toBeCloseTo(0.5, 12);
    expect(m5.jog).toBeCloseTo(0.4, 12);
    expect(m5.sprint).toBeCloseTo(0.1, 12);
    const m12 = speedMix(12);
    expect(m12.walk).toBeCloseTo(0.1, 12);
    expect(m12.jog).toBeCloseTo(0.4, 12);
    expect(m12.sprint).toBeCloseTo(0.5, 12);
    for (const r of [13, 14, 18, 40]) expect(speedMix(r)).toEqual({ walk: 0, jog: 0, sprint: 1 });
    expect(SLOW_LAST_ROUND).toBe(4);
    expect(FAST_FROM_ROUND).toBe(13);
  });

  it('the band edges are steps a player can feel: round 4 to 5 brings the first sprinters, 12 to 13 the last walkers go', () => {
    expect(speedMix(4).sprint).toBe(0);
    expect(speedMix(5).sprint).toBeGreaterThan(0);
    expect(speedMix(12).walk).toBeGreaterThan(0);
    expect(speedMix(13).walk).toBe(0);
    // A round 4 army ant always walks at half the ant's speed; a round 13 one always sprints at the cap.
    for (const roll of [0, 0.3, 0.6, 0.999]) {
      expect(tierSpeedShare(pickSpeedTier(4, roll))).toBe(0.5);
      expect(tierSpeedShare(pickSpeedTier(13, roll))).toBe(0.94);
    }
  });

  it('sprinters never thin out and walkers never come back', () => {
    for (let r = 1; r < 40; r++) {
      expect(speedMix(r + 1).sprint).toBeGreaterThanOrEqual(speedMix(r).sprint - 1e-12);
      expect(speedMix(r + 1).walk).toBeLessThanOrEqual(speedMix(r).walk + 1e-12);
    }
  });

  it('a roll picks the tier by the shares', () => {
    expect(pickSpeedTier(1, 0.99)).toBe('walk');
    expect(pickSpeedTier(18, 0.01)).toBe('sprint');
    const m = speedMix(9);
    expect(pickSpeedTier(9, m.walk / 2)).toBe('walk');
    expect(pickSpeedTier(9, m.walk + m.jog / 2)).toBe('jog');
    expect(pickSpeedTier(9, 0.999)).toBe('sprint');
  });
});

describe('a boss every 10th round (slice 4), the Anteater keeps every 25th', () => {
  it.each([
    [10, 'mantis'], [20, 'hornet'], [30, 'mantis'], [40, 'hornet'], [25, 'anteater'], [50, 'anteater'], [60, 'hornet'],
    [70, 'mantis'], [75, 'anteater'], [100, 'anteater'], [5, null], [15, null], [11, null], [35, null], [9, null],
  ])('round %i: %s', (round, kind) => {
    expect(bossKind(round as number)).toBe(kind);
    expect(isBossRound(round as number)).toBe(kind !== null);
  });

  // Lane N1, design note of 2026-10-29: the 30 termites came 1.5 s apart here; now they come at the horde gap of the round.
  it('a 10th round boss comes in place of the breather, with 30 termites at the horde gap of its round, as the Anteater does', () => {
    for (const r of [10, 20, 30, 40]) {
      const p = roundPlan(r);
      expect(p.kind).toBe('boss');
      expect(p.boss).toBe(bossKind(r));
      expect(p.total).toBe(31);
      expect(p.spawnGap).toBe(spawnGapSeconds(r));
    }
    // Round 15 is the second termite rush (lane G9, M4: 48 of them, rush.test.ts).
    expect(roundPlan(15)).toMatchObject({ kind: 'breather', boss: null, total: 48 });
    expect(roundPlan(11).boss).toBeNull();
    expect(MID_BOSS_EVERY).toBe(10);
    expect(MID_BOSS_ROTATION).toEqual(['mantis', 'hornet']);
  });
});

describe('breather rounds and the round plan', () => {
  it.each([[5, true], [10, true], [15, true], [20, true], [1, false], [4, false], [6, false], [9, false], [11, false]])(
    'round %i breather is %s',
    (round, expected) => expect(isBreatherRound(round)).toBe(expected),
  );

  it('a breather sends 40 termites 0.3 s apart (its own rule, untouched by the tuning) with at most 20 alive', () => {
    const p = roundPlan(5);
    expect(p.kind).toBe('breather');
    expect(p.total).toBe(BREATHER_COUNT);
    expect(BREATHER_COUNT).toBe(40);
    expect(p.spawnGap).toBe(0.3);
    expect(p.aliveCap).toBe(20);
  });

  it('round 1 and round 6 read straight off the curve', () => {
    expect(roundPlan(1)).toMatchObject({ round: 1, kind: 'horde', total: 6, aliveCap: 6, health: 150, breakSeconds: 15 });
    expect(roundPlan(1).spawnGap).toBeCloseTo(1.0, 9);
    expect(roundPlan(6)).toMatchObject({ round: 6, kind: 'horde', total: 27, aliveCap: 20, health: 650 });
    expect(roundPlan(6).spawnGap).toBeCloseTo(spawnGapSeconds(6), 9);
  });
});

describe('input guards', () => {
  it.each([0, -1, 1.5, Number.NaN, Number.POSITIVE_INFINITY])('round %s is refused', (bad) => {
    expect(() => enemiesForRound(bad)).toThrow(RangeError);
    expect(() => enemyHealth(bad)).toThrow(RangeError);
    expect(() => spawnGapSeconds(bad)).toThrow(RangeError);
    expect(() => conceptSpawnGapSeconds(bad)).toThrow(RangeError);

    expect(() => roundPlan(bad)).toThrow(RangeError);
  });
});

describe('the countdown between rounds (feel round 1)', () => {
  it('every round plan, hordes and breathers alike, carries the 15 s countdown', () => {
    for (const r of [1, 4, 5, 6, 10, 25, 50]) expect(roundPlan(r).breakSeconds).toBe(15);
  });

  it('reaching zero starts the next round by itself, after the full 15 s at 60 fps', () => {
    const dt = 1 / 60;
    let left = roundPlan(1).breakSeconds;
    let frames = 0;
    let started = false;
    while (!started && frames < 2000) {
      const step = breakStep(left, dt);
      frames += 1;
      if (!step.start) expect(step.left).toBeGreaterThan(0);
      left = step.left;
      started = step.start;
    }
    expect(started).toBe(true);
    expect(left).toBe(0);
    // 15 s is 900 frames; a floating point sum may need one frame more, never one fewer.
    expect(frames).toBeGreaterThanOrEqual(900);
    expect(frames).toBeLessThanOrEqual(901);
  });

  it('counts down in whole steps and never goes under zero; a long last frame still starts the round', () => {
    expect(breakStep(15, 0.125)).toEqual({ left: 14.875, start: false });
    expect(breakStep(0.01, 0.05)).toEqual({ left: 0, start: true });
  });
});
