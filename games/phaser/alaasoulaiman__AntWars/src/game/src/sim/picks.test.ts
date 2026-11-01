// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Lane G8: one table over every pick a run offers or sells (the three nest perks, the sixteen level up powers and the
// five shop lines), each measured through the real builders on the bare ant, against one cap: no single pick steps a
// stat by more than the largest step a trimmed pick already uses (design note, 2026-10-24: small steps in the run's own
// buys too). Only APIs that 0d9b8f8 has too, so the same table runs against the build before the change.
import { describe, expect, it } from 'vitest';
import { BASE_ANT, LINES, PERKS, emptyLines, lineStep, runStats, type AntStats, type LineId, type PerkId } from './economy';
import {
  ECHO_DAMAGE_FACTOR,
  ELEMENT_CHANCE,
  EYE_CRIT_STEP,
  FIRE_BURN_SHARE,
  GLANDS_RATE_STEP,
  JAW_DAMAGE_STEP,
  POWERS,
  SHELL_HP_STEP,
  SPARK_SHARE,
  STANCE_BLOCK_STEP,
  deriveBuild,
  emptyStacks,
  furyFactor,
  type Build,
  type PowerId,
} from './growth';

/** The scale: the largest stat step of the picks the design note of 2026-10-24 trimmed by a third (2/15, Strong Jaw and Hearty Shell). */
const CAP = Math.max(JAW_DAMAGE_STEP, GLANDS_RATE_STEP, SHELL_HP_STEP, EYE_CRIT_STEP, STANCE_BLOCK_STEP);
const EPS = 1e-9;

/** What one shot lands on the predator it is aimed at: the side by side darts, each volley (Fork pairs fly off the aim). */
const shot = (b: Build) => b.darts * b.damage * b.volleys;

interface Step {
  /** Max health, the shot on its target, shots a second and speed: the share each goes up by. */
  hp: number;
  shot: number;
  rate: number;
  speed: number;
  /** Chances and shares, in points: crit chance, damage blocked standing still, a first hit's outright kill. */
  crit: number;
  block: number;
  lucky: number;
}

function stepOf(after: Readonly<Build>, extraShot = 1): Step {
  const before = deriveBuild(BASE_ANT, emptyStacks());
  return {
    hp: after.maxHp / before.maxHp - 1,
    shot: (shot(after) * extraShot) / shot(before) - 1,
    rate: before.fireInterval / after.fireInterval - 1,
    speed: after.speed / before.speed - 1,
    crit: after.critChance - before.critChance,
    block: after.block - before.block,
    lucky: after.lucky - before.lucky,
  };
}

const largest = (s: Step) => Math.max(s.hp, s.shot, s.rate, s.speed, s.crit, s.block, s.lucky);

const perkBuild = (id: PerkId) => deriveBuild(runStats(BASE_ANT, new Set<PerkId>([id]), emptyLines()), emptyStacks());
const lineBuild = (id: LineId) => deriveBuild(runStats(BASE_ANT, new Set<PerkId>(), { ...emptyLines(), [id]: 1 }), emptyStacks());

/** A power on the bare ant. Fire Venom's burn and Spark Venom's arc count at their one in five chance; Fury at 1 health. */
function powerStep(id: PowerId): Step {
  const b = deriveBuild(BASE_ANT, { ...emptyStacks(), [id]: 1 });
  if (id === 'fire') return stepOf(b, 1 + ELEMENT_CHANCE * FIRE_BURN_SHARE);
  if (id === 'spark') return stepOf(b, 1 + ELEMENT_CHANCE * SPARK_SHARE);
  if (id === 'fury') return stepOf(b, furyFactor(1, b.maxHp));
  return stepOf(b);
}

/**
 * Count steps the tuning round kept on the record (growth.ts: "The counts (darts, hops, echoes) and their costs stay";
 * PROGRESS.md: the Extra Dart line, one dart a buy after round 10 at five times the price), and Fury Glands, trimmed
 * by a third already, whose peak is at 1 health. Each is pinned to its value here, so none grows unseen; trimming them
 * is a design call outside this lane. Every other pick must sit at or under the cap.
 */
const KEPT: Readonly<Record<string, number>> = {
  'power fang': 0.5,
  'power echo': 2 * ECHO_DAMAGE_FACTOR - 1,
  'power fury': furyFactor(1, 600) - 1,
  'line darts': 1,
};

const rows: Array<[string, Step]> = [
  ...PERKS.map((p): [string, Step] => [`perk ${p.id}`, stepOf(perkBuild(p.id))]),
  ...POWERS.map((p): [string, Step] => [`power ${p.id}`, powerStep(p.id)]),
  ...LINES.map((l): [string, Step] => [`line ${l.id}`, stepOf(lineBuild(l.id))]),
];

describe('every pick against the cap (lane G8)', () => {
  it('reads the cap off the trimmed picks: 2/15, about 13.3 percent', () => {
    expect(CAP).toBeCloseTo(2 / 15, 12);
    expect(rows.length).toBe(PERKS.length + POWERS.length + LINES.length);
    expect(rows.length).toBe(3 + 16 + 5);
  });

  it.each(rows.filter(([name]) => !(name in KEPT)))('%s steps no stat by more than the cap', (_name, step) => {
    expect(largest(step)).toBeLessThanOrEqual(CAP + EPS);
  });

  it.each(Object.entries(KEPT))('%s is a kept step, pinned at its value', (name, value) => {
    const row = rows.find(([n]) => n === name);
    expect(row).toBeDefined();
    expect(largest((row as [string, Step])[1])).toBeCloseTo(value, 9);
  });

  it('the three perks: Thick Chitin +2/15 health, Twin Stinger the shot +10 percent, Quick Mandibles +10 percent rate', () => {
    const get = (id: PerkId) => (rows.find(([n]) => n === `perk ${id}`) as [string, Step])[1];
    expect(get('chitin').hp).toBeCloseTo(80 / 600, 12);
    expect(get('twin').shot).toBeCloseTo(0.1, 12);
    expect(get('quick').rate).toBeCloseTo(0.1, 12);
  });

  it('every later step of a line or a perk is smaller than its first, so the first is the one to cap', () => {
    for (const l of LINES) {
      for (let k = 2; lineStep(l.id, k) !== null; k++) expect(lineStep(l.id, k) as number).toBeLessThanOrEqual(lineStep(l.id, 1) as number);
    }
    for (const n of [2, 3]) {
      const now = runStats(BASE_ANT, Array<PerkId>(n).fill('chitin'), emptyLines()).maxHp;
      const before = runStats(BASE_ANT, Array<PerkId>(n - 1).fill('chitin'), emptyLines()).maxHp;
      expect(now / before - 1).toBeLessThan(CAP);
    }
  });
});

describe('Twin Stinger is always the shot plus a tenth, whatever else the ant holds (lane G8)', () => {
  const twinGain = (meta: Readonly<AntStats>, lines: Partial<Record<LineId, number>>, stacks: Partial<Record<PowerId, number>>) => {
    const levels = { ...emptyLines(), ...lines };
    const with_ = deriveBuild(runStats(meta, new Set<PerkId>(['twin']), levels), { ...emptyStacks(), ...stacks });
    const without = deriveBuild(runStats(meta, new Set<PerkId>(), levels), { ...emptyStacks(), ...stacks });
    return { gain: shot(with_) / shot(without), darts: with_.darts - without.darts };
  };

  it.each([
    ['the bare ant', {}, {}],
    ['one Front Fang', {}, { fang: 1 }],
    ['two Front Fangs and an echo', {}, { fang: 2, echo: 1 }],
    ['both Extra Darts and a Strong Jaw', { darts: 2, damage: 3 }, { jaw: 1 }],
  ] as const)('with %s: one more dart and the shot x1.1', (_name, lines, stacks) => {
    const t = twinGain(BASE_ANT, lines, stacks);
    expect(t.darts).toBe(1);
    expect(t.gain).toBeCloseTo(1.1, 12);
  });
});
