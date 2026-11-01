// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests for the slice 3 predators (CONCEPT_V2 section 5): beetles from round 12, antlions from 15, centipedes from
// 20, each with its own numbers, and the Queen's Blessing from round 15 (slice 1 built it; pinned here).
import { describe, expect, it } from 'vitest';
import { PREDATOR_SPEED_CAP, enemyHealth } from './curve';
import {
  ANTLION_PITS,
  BEETLE_TURN_DEG,
  BLESSING_FROM_ROUND,
  BLESSING_SECONDS,
  CENTIPEDE_MAX_ALIVE,
  CENTIPEDE_SEGMENTS,
  CENTIPEDE_SPACING,
  CENTIPEDE_TURN_DEG,
  PIT_PULL_CORE,
  PIT_PULL_EDGE,
  PIT_PULL_RADIUS,
  EMBER_BURST_PREDATOR_SHARE,
  EMBER_BURST_RADIUS,
  EMBER_FUSE_RANGE,
  EMBER_FUSE_SECONDS,
  HORNET_BROOD_SECONDS,
  MANTIS_SWEEP_DAMAGE,
  MANTIS_WINDUP_SECONDS,
  MOTH_JINK_MAX,
  MOTH_JINK_MIN,
  PREDATORS,
  SHELL_FACTOR,
  broodCall,
  emberBurstOnAnt,
  hornetFan,
  inBurst,
  inSweep,
  isBossKind,
  mothHeading,
  blessingCanDrop,
  firstHordeRound,
  pickPredator,
  pitPull,
  placeSegments,
  predatorHealth,
  predatorSpeedShare,
  shellFactor,
  spawnKind,
  turnToward,
  wrapAngle,
} from './roster';
import { NEST_AT, ROCKS, spawnHoles } from './yard';
import { NEST_SHOP_RADIUS } from '../game/tuning';

const deg = (d: number) => (d * Math.PI) / 180;

describe('the three new predators have their own numbers', () => {
  it.each([
    ['beetle', 12, 'tank', 5, 0.4, 90, 24, 120],
    ['antlion', 15, 'pitTrap', 3, 0, 80, 22, 110],
    ['centipede', 20, 'snake', 4, 0.94, 55, 16, 150],
  ] as const)('%s: from round %i, %s, %f x health, speed %f, bite %i, radius %i, nectar %i', (kind, from, behaviour, hp, speed, bite, radius, nectar) => {
    const s = PREDATORS[kind];
    expect([s.fromRound, s.behaviour, s.hpShare, s.speedShare, s.biteDamage, s.radius, s.nectar]).toEqual([from, behaviour, hp, speed, bite, radius, nectar]);
  });

  it('health off the round curve: a round 12 beetle 6,320, a round 16 antlion 5,553, a round 21 centipede 11,928', () => {
    expect(enemyHealth(12)).toBe(1264);
    expect(predatorHealth('beetle', enemyHealth(12))).toBe(6320);
    expect(enemyHealth(16)).toBe(1851);
    expect(predatorHealth('antlion', enemyHealth(16))).toBe(5553);
    expect(enemyHealth(21)).toBe(2982);
    expect(predatorHealth('centipede', enemyHealth(21))).toBe(11928);
  });

  it('none passes the speed cap; the beetle is slow and the antlion stays put', () => {
    for (const kind of ['beetle', 'antlion', 'centipede'] as const) {
      for (const round of [12, 20, 40]) expect(predatorSpeedShare(kind, round, 0.5)).toBeLessThanOrEqual(PREDATOR_SPEED_CAP);
    }
    expect(predatorSpeedShare('beetle', 12, 0.5)).toBe(0.4);
    expect(predatorSpeedShare('antlion', 16, 0.5)).toBe(0);
    expect(predatorSpeedShare('centipede', 21, 0.5)).toBe(PREDATOR_SPEED_CAP);
  });

  it('the first round each really shows: 12, then 16 and 21 (15 and 20 are termite rushes)', () => {
    expect(firstHordeRound('beetle')).toBe(12);
    expect(firstHordeRound('antlion')).toBe(16);
    expect(firstHordeRound('centipede')).toBe(21);
    expect(firstHordeRound('wasp')).toBe(6);
  });

  it.each([
    [11, ['armyAnt', 'ember', 'moth', 'spider', 'wasp']],
    [12, ['armyAnt', 'beetle', 'ember', 'moth', 'spider', 'wasp']],
    [16, ['antlion', 'armyAnt', 'beetle', 'ember', 'moth', 'spider', 'wasp']],
    [19, ['antlion', 'armyAnt', 'beetle', 'ember', 'moth', 'spider', 'wasp']],
    [21, ['antlion', 'armyAnt', 'beetle', 'centipede', 'ember', 'moth', 'spider', 'wasp']],
  ])('round %i spawns %j', (round, kinds) => {
    const seen = new Set<string>();
    for (let i = 0; i < 1000; i++) seen.add(pickPredator(round as number, i / 1000));
    expect([...seen].sort()).toEqual(kinds);
  });

  it('the shares: beetles 10, antlions 6, centipedes 6 percent of a horde round', () => {
    const count = (round: number, kind: string) => {
      let n = 0;
      for (let i = 0; i < 10000; i++) if (pickPredator(round, (i + 0.5) / 10000) === kind) n += 1;
      return n;
    };
    expect(count(21, 'beetle')).toBe(1000);
    expect(count(21, 'antlion')).toBe(600);
    expect(count(21, 'centipede')).toBe(600);
    // Slice 4: ember ants and dusk moths take 7 percent each, out of the army ants' share.
    expect(count(21, 'ember')).toBe(700);
    expect(count(21, 'moth')).toBe(700);
    expect(count(21, 'armyAnt')).toBe(3400);
    expect(count(20, 'centipede')).toBe(0);
  });
});

describe('the beetle: a shell that halves darts from the front', () => {
  it.each([
    // heading, dart flying toward, factor
    [0, 180, SHELL_FACTOR],
    [0, 180 + 59, SHELL_FACTOR],
    [0, 180 - 59, SHELL_FACTOR],
    [0, 180 + 61, 1],
    [0, 90, 1],
    [0, 0, 1],
    [90, 270, SHELL_FACTOR],
    [90, 90, 1],
    [-135, 45, SHELL_FACTOR],
  ])('a beetle heading %i degrees, a dart flying toward %i degrees: x%f', (heading, dartDir, factor) => {
    expect(shellFactor(deg(heading), Math.cos(deg(dartDir)) * 950, Math.sin(deg(dartDir)) * 950)).toBe(factor);
  });
  it('a dart with no speed counts as full damage', () => {
    expect(shellFactor(0, 0, 0)).toBe(1);
  });
  it('the shell takes exactly half (VG4: the table above reads the constant, so this pins the number itself)', () => {
    expect(SHELL_FACTOR).toBe(0.5);
    expect(shellFactor(0, -950, 0)).toBe(0.5);
  });
  it('turns 90 degrees a second at most: a full about turn takes 2 s', () => {
    let h = 0;
    for (let i = 0; i < 60; i++) h = turnToward(h, Math.PI, deg(BEETLE_TURN_DEG) / 60);
    expect(h).toBeCloseTo(deg(90), 9);
    for (let i = 0; i < 60; i++) h = turnToward(h, Math.PI, deg(BEETLE_TURN_DEG) / 60);
    expect(Math.abs(h)).toBeCloseTo(Math.PI, 9);
  });
});

describe('turning and angles', () => {
  it.each([
    [0, 0], [Math.PI, Math.PI], [-Math.PI, Math.PI], [3 * Math.PI, Math.PI], [deg(270), deg(-90)], [deg(-270), deg(90)],
  ])('wrapAngle(%f) = %f', (a, w) => {
    expect(wrapAngle(a)).toBeCloseTo(w, 9);
  });
  it('turns the short way round, never past the target', () => {
    expect(turnToward(deg(170), deg(-170), deg(5))).toBeCloseTo(deg(175), 9);
    expect(turnToward(deg(-170), deg(170), deg(5))).toBeCloseTo(deg(-175), 9);
    expect(turnToward(0, deg(3), deg(5))).toBeCloseTo(deg(3), 9);
    expect(turnToward(0, deg(-30), deg(5))).toBeCloseTo(deg(-5), 9);
  });
});

describe('the antlion: a pit that pulls the ant in', () => {
  it.each([
    [300, 0], [240, 0], [239, PIT_PULL_EDGE + 100 * (1 / 240)], [180, 85], [120, 110], [60, 135], [24, 150], [12, 0], [0, 0],
  ])('at %i units from the middle the pull is %f a second', (d, pull) => {
    expect(pitPull(d)).toBeCloseTo(pull, 6);
  });
  it('the pull is always slower than the ant: a running ant climbs out at 90 units a second or more', () => {
    for (let d = 0; d < 300; d += 0.5) expect(250 - pitPull(d)).toBeGreaterThanOrEqual(90);
    expect(PIT_PULL_CORE).toBeLessThan(250);
  });
  it('two pits, never pulling inside the nest shop, clear of the rocks and the holes', () => {
    expect(ANTLION_PITS.length).toBe(2);
    for (const p of ANTLION_PITS) {
      expect(Math.hypot(p.x - NEST_AT.x, p.y - NEST_AT.y) - PIT_PULL_RADIUS).toBeGreaterThan(NEST_SHOP_RADIUS + 100);
      for (const r of ROCKS) expect(Math.hypot(p.x - r.x, p.y - r.y)).toBeGreaterThan(r.r + 240);
      for (const h of spawnHoles()) expect(Math.hypot(p.x - h.x, p.y - h.y)).toBeGreaterThan(300);
    }
  });
  it('one antlion per pit, at most two centipedes: the rest come as army ants', () => {
    expect(spawnKind('antlion', 0, 2)).toBe('antlion');
    expect(spawnKind('antlion', 2, 0)).toBe('armyAnt');
    expect(spawnKind('centipede', CENTIPEDE_MAX_ALIVE - 1, 0)).toBe('centipede');
    expect(spawnKind('centipede', CENTIPEDE_MAX_ALIVE, 2)).toBe('armyAnt');
    expect(spawnKind('beetle', 9, 0)).toBe('beetle');
  });
});

describe('the centipede: long, fast in a straight line, slow to turn', () => {
  it('turns 70 degrees a second, slower than the beetle', () => {
    expect(CENTIPEDE_TURN_DEG).toBe(70);
    expect(CENTIPEDE_TURN_DEG).toBeLessThan(BEETLE_TURN_DEG);
    let h = 0;
    for (let i = 0; i < 60; i++) h = turnToward(h, deg(180), deg(CENTIPEDE_TURN_DEG) / 60);
    expect(h).toBeCloseTo(deg(70), 9);
  });
  it('its segments sit every 22 units back along the path the head took', () => {
    // A straight trail along x, newest first: the head at 200, then a point every 4 units back to 0.
    const trail: number[] = [];
    for (let x = 200; x >= 0; x -= 4) trail.push(x, 50);
    const segs = placeSegments(trail, CENTIPEDE_SEGMENTS, CENTIPEDE_SPACING);
    expect(segs.map((s) => +s.x.toFixed(6))).toEqual([178, 156, 134, 112, 90, 68, 46]);
    for (const s of segs) expect(s.y).toBe(50);
  });
  it('round a corner the body follows the path, not a straight line', () => {
    // The head went up from (0, 0) to (0, 30), then right to (40, 30); newest first.
    const trail = [40, 30, 0, 30, 0, 0];
    const segs = placeSegments(trail, 3, 22);
    expect(segs[0]).toEqual({ x: 18, y: 30 });
    expect(segs[1].x).toBeCloseTo(0, 9);
    expect(segs[1].y).toBeCloseTo(26, 9);
    expect(segs[2].x).toBeCloseTo(0, 9);
    expect(segs[2].y).toBeCloseTo(4, 9);
  });
  it('a short trail stacks the last segments on its oldest point; an empty one has none', () => {
    expect(placeSegments([10, 0, 0, 0], 3, 22)).toEqual([{ x: 0, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 0 }]);
    expect(placeSegments([], 3, 22)).toEqual([]);
  });
});

describe("the Queen's Blessing (CONCEPT_V2 section 5: random from round 15, 30 seconds)", () => {
  it.each([[1, false], [14, false], [15, true], [16, true], [40, true]])('round %i can drop a crown: %s', (round, can) => {
    expect(blessingCanDrop(round)).toBe(can);
  });
  it('lasts 30 seconds from round 15', () => {
    expect(BLESSING_FROM_ROUND).toBe(15);
    expect(BLESSING_SECONDS).toBe(30);
  });
});

describe('slice 4: the ember ant, the dusk moth and the two 10th round bosses', () => {
  it('their numbers: health shares, speeds, bites and nectar', () => {
    expect(PREDATORS.ember).toMatchObject({ fromRound: 7, behaviour: 'burst', hpShare: 0.7, speedShare: 'tier', biteDamage: 0, nectar: 60 });
    expect(PREDATORS.moth).toMatchObject({ fromRound: 9, behaviour: 'flutter', hpShare: 0.5, speedShare: 0.85, biteDamage: 35, nectar: 60 });
    expect(PREDATORS.mantis).toMatchObject({ behaviour: 'sweep', hpShare: 14, speedShare: 0.45, radius: 36, nectar: 800 });
    expect(PREDATORS.hornet).toMatchObject({ behaviour: 'brood', hpShare: 12, speedShare: 0.6, shotDamage: 45, shotEvery: 2.6, nectar: 900 });
    expect(predatorHealth('mantis', enemyHealth(10))).toBe(14630);
    expect(predatorHealth('hornet', enemyHealth(20))).toBe(32520);
    expect(firstHordeRound('ember')).toBe(7);
    expect(firstHordeRound('moth')).toBe(9);
  });

  it('every new kind keeps under the cap: the ember rolls the round band, the others have their own share', () => {
    for (const k of ['ember', 'moth', 'mantis', 'hornet'] as const) {
      for (const r of [7, 10, 13, 20, 40]) for (const roll of [0, 0.5, 0.999]) expect(predatorSpeedShare(k, r, roll)).toBeLessThanOrEqual(0.94);
    }
    expect(predatorSpeedShare('ember', 4, 0.9)).toBe(0.5);
    expect(predatorSpeedShare('ember', 13, 0.1)).toBe(0.94);
  });

  it('the ember burst: 90 units, 110 to the ant only when its fuse ran out, never when it was shot', () => {
    expect(EMBER_FUSE_RANGE).toBe(46);
    expect(EMBER_FUSE_SECONDS).toBe(0.55);
    expect(inBurst(90)).toBe(true);
    expect(inBurst(90.01)).toBe(false);
    expect(emberBurstOnAnt(true, 40)).toBe(110);
    expect(emberBurstOnAnt(true, 91)).toBe(0);
    expect(emberBurstOnAnt(false, 10)).toBe(0);
    expect(EMBER_BURST_PREDATOR_SHARE).toBe(0.6);
    // A running ant (250 a second) gets 137 units away in the 0.55 s fuse: out of the burst.
    expect(250 * EMBER_FUSE_SECONDS + EMBER_FUSE_RANGE).toBeGreaterThan(EMBER_BURST_RADIUS);
  });

  it('the moth jinks up to 75 degrees off the ant, and goes straight in from 60 units', () => {
    const toAnt = 0.4;
    for (const roll of [0, 0.25, 0.5, 0.75, 0.999]) {
      const h = mothHeading(toAnt, roll, 300);
      expect(Math.abs(wrapAngle(h - toAnt))).toBeLessThanOrEqual((75 * Math.PI) / 180 + 1e-9);
    }
    expect(mothHeading(toAnt, 0, 300)).toBeCloseTo(toAnt - (75 * Math.PI) / 180, 9);
    expect(mothHeading(toAnt, 0, 60)).toBeCloseTo(toAnt, 12);
    expect(MOTH_JINK_MIN).toBeLessThan(MOTH_JINK_MAX);
  });

  it('the mantis sweep: 150 units, 60 degrees either side of its heading', () => {
    expect(inSweep(100, 0, 0)).toBe(true);
    expect(inSweep(150, 0, 0)).toBe(true);
    expect(inSweep(151, 0, 0)).toBe(false);
    expect(inSweep(Math.cos(1.0) * 100, Math.sin(1.0) * 100, 0)).toBe(true);
    expect(inSweep(Math.cos(1.1) * 100, Math.sin(1.1) * 100, 0)).toBe(false);
    expect(inSweep(-100, 0, 0)).toBe(false);
    expect(inSweep(0, 0, 2)).toBe(true);
    expect(MANTIS_WINDUP_SECONDS).toBe(0.7);
    expect(MANTIS_SWEEP_DAMAGE).toBe(160);
  });

  it('the hornet: a fan of three stings 15 degrees apart, and two wasps a call, never past the alive cap', () => {
    const fan = hornetFan(1);
    expect(fan.length).toBe(3);
    expect(fan[1]).toBe(1);
    expect(fan[2] - fan[1]).toBeCloseTo((15 * Math.PI) / 180, 12);
    expect(broodCall(10, 20)).toBe(2);
    expect(broodCall(19, 20)).toBe(1);
    expect(broodCall(20, 20)).toBe(0);
    expect(HORNET_BROOD_SECONDS).toBe(6);
    // Eight calls at most: no endless wasps to farm for nectar.
    expect(broodCall(0, 20, 7)).toBe(2);
    expect(broodCall(0, 20, 8)).toBe(0);
    expect(broodCall(0, 20, 50)).toBe(0);
  });

  it('the three bosses are bosses (no one hit kill, no Lucky Sting, no crowd push); the rest are not', () => {
    for (const k of ['anteater', 'mantis', 'hornet'] as const) expect(isBossKind(k)).toBe(true);
    for (const k of ['armyAnt', 'ember', 'moth', 'beetle', 'centipede'] as const) expect(isBossKind(k)).toBe(false);
  });
});
