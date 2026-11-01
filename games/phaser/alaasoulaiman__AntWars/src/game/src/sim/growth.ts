// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Growth inside a run (CONCEPT_V2 section 3 on top of CONCEPT_V1 sections 6a and 6f): kills give experience, every
// level up offers one of three powers. The experience curve and every power's numbers live here as plain data and
// functions; the Yard and the HUD read them only through this module.
import { PICK_CAP_LEVEL, STILL_CRIT_CHANCE, TWIN_SHOT_GAIN, type AntStats } from './economy';
import type { PredatorKind } from './roster';

/**
 * The concept's in run cap: 11 level ups, so the ant tops out at level 12. Slice 4: the cap lives in economy.ts
 * (PICK_CAP_LEVEL), and past it no pick of any kind comes; the nest shop is the only growth.
 */
export const MAX_LEVEL = PICK_CAP_LEVEL;
/** Experience from level L to L + 1: 10 at level 1 and 8 more each level after (10, 18, 26 ... 90). */
export const XP_FIRST = 10;
export const XP_STEP = 8;

/** Experience each kill gives. Termites come 40 at a time, so they give the least; the Anteater gives a lot. */
export const KILL_XP: Readonly<Record<PredatorKind, number>> = {
  armyAnt: 2, wasp: 3, spider: 3, termite: 1, anteater: 40, beetle: 6, antlion: 5, centipede: 8,
  ember: 2, moth: 2, mantis: 30, hornet: 35,
};

/** A press on a pick card counts only when it began this long after the cards appeared (no accidental pick). */
export const PICK_READ_MS = 300;

function assertLevel(level: number): void {
  if (!Number.isInteger(level) || level < 1 || level > MAX_LEVEL) {
    throw new RangeError(`level must be an integer from 1 to ${MAX_LEVEL}, got ${level}`);
  }
}

/** Experience needed to go from this level to the next; null at the cap, where there is no next level. */
export function xpToNext(level: number): number | null {
  assertLevel(level);
  if (level === MAX_LEVEL) return null;
  return XP_FIRST + XP_STEP * (level - 1);
}

/** Experience from level 1 to the start of this level: 0, 10, 28, 54, 88 ... 550 at level 12. */
export function xpTotalTo(level: number): number {
  assertLevel(level);
  const n = level - 1;
  return XP_FIRST * n + (XP_STEP * n * (n - 1)) / 2;
}

export function xpForKill(kind: PredatorKind): number {
  return KILL_XP[kind];
}

export interface XpState {
  level: number;
  /** Experience inside the current level, from 0 up to xpToNext(level). Always 0 at the cap. */
  xp: number;
}

/** Adds experience: carries the rest into the next level, stops at the cap. ups is how many levels were gained. */
export function addXp(state: Readonly<XpState>, gain: number): XpState & { ups: number } {
  assertLevel(state.level);
  if (!Number.isFinite(gain) || gain < 0) throw new RangeError(`gain must be 0 or more, got ${gain}`);
  let level = state.level;
  let xp = level === MAX_LEVEL ? 0 : state.xp + gain;
  let ups = 0;
  for (let need = xpToNext(level); need !== null && xp >= need; need = xpToNext(level)) {
    xp -= need;
    level += 1;
    ups += 1;
  }
  if (level === MAX_LEVEL) xp = 0;
  return { level, xp, ups };
}

export type PowerId =
  | 'jaw'
  | 'glands'
  | 'shell'
  | 'honeydew'
  | 'eye'
  | 'fang'
  | 'fork'
  | 'echo'
  | 'needle'
  | 'hop'
  | 'lucky'
  | 'fury'
  | 'frost'
  | 'stance'
  | 'fire'
  | 'spark';

export interface PowerSpec {
  id: PowerId;
  name: string;
  /** The plain one line effect on the card. */
  line: string;
  /** How many times one run can take it; null means no cap. */
  max: number | null;
  /** The icon's main colour. */
  color: number;
}

// The numbers behind the lines. Percent steps of one power add up (two Strong Jaws are +40 percent); the costs of
// Front Fang and Echo Sting multiply (two Front Fangs leave 0.75 x 0.75 of the damage), as the concept's price list says.
/**
 * Design note, 2026-10-24: the extra damage should not be so great, so what each power gives is trimmed by a third
 * (two thirds of slice 2's). The counts (darts, hops, echoes) and their costs stay; the elements keep their strength and
 * fire on one hit in five instead.
 */
export const PICK_TRIM = 2 / 3;
export const JAW_DAMAGE_STEP = 0.2 * PICK_TRIM;
export const GLANDS_RATE_STEP = 0.15 * PICK_TRIM;
export const SHELL_HP_STEP = 0.2 * PICK_TRIM;
export const HONEYDEW_HEAL = 0.4 * PICK_TRIM;
export const EYE_CRIT_STEP = 0.1 * PICK_TRIM;
export const FANG_DAMAGE_FACTOR = 0.75;
/** Fork pair k flies at plus and minus k x 25 degrees from the aim. */
export const FORK_ANGLE_DEG = 25;
export const ECHO_DAMAGE_FACTOR = 0.9;
export const ECHO_RATE_FACTOR = 0.85;
/** The gap between a volley and its echo. */
export const ECHO_DELAY_SECONDS = 0.12;
/** A piercing dart keeps this share of its damage after each predator it passes. */
export const NEEDLE_KEEP = 0.67;
export const HOP_COUNT = 2;
export const HOP_KEEP = 0.7;
/** A hop only reaches a predator this close to the one just hit. */
export const HOP_RANGE = 300;
export const LUCKY_CHANCE = 0.125 * PICK_TRIM;
/** Fury Glands: damage up this share per share of health missing (1 before the trim). */
export const FURY_SHARE = PICK_TRIM;
export const FROST_SLOW = 0.6;
export const FROST_SECONDS = 1.5;
export const STANCE_BLOCK_STEP = 0.2 * PICK_TRIM;

// Slice 4: elements on the darts (a play tester's list). Frost Sap is the frost element; Fire Venom and Spark Venom join it.
/**
 * Design note, 2026-10-24: every element effect is a chance, one hit in five (the burn, the slow, the spark), and
 * each combo one kill in five, rolled on the game's one seeded random (sim/rng.ts) so the tests can pin it.
 */
export const ELEMENT_CHANCE = 0.2;

/** Whether an element effect fires on this roll in [0, 1). */
export function elementProc(roll: number): boolean {
  return roll < ELEMENT_CHANCE;
}
/** Fire: a hit sets the foe burning for 30 percent more of the hit, in four ticks over 2 s; a new hit starts it again. */
export const FIRE_BURN_SHARE = 0.3;
export const FIRE_BURN_SECONDS = 2;
export const FIRE_TICK_SECONDS = 0.5;
/** Spark: a hit arcs to the one nearest other foe within this range, for this share of the hit. */
export const SPARK_SHARE = 0.4;
export const SPARK_RANGE = 220;

/** One burn tick for a hit of this much: the burn's 30 percent shared over its four ticks. */
export function burnPerTick(hit: number): number {
  return (hit * FIRE_BURN_SHARE) / (FIRE_BURN_SECONDS / FIRE_TICK_SECONDS);
}

/**
 * The combos a second element unlocks, all on a kill: frost plus spark leaves a shock puddle for 3 s (it hurts and slows
 * what walks in); fire plus frost leaves steam that blinds (foes in it lose the ant: they drift, never bite or shoot);
 * fire plus spark bursts in flame on the foes around the kill.
 */
export type ComboId = 'puddle' | 'steam' | 'burst';
export const COMBO_IDS: ReadonlyArray<ComboId> = ['puddle', 'steam', 'burst'];
export const PUDDLE_SECONDS = 3;
export const PUDDLE_RADIUS = 60;
export const PUDDLE_TICK_SECONDS = 0.25;
/** Each puddle tick takes this share of the ant's dart damage off every foe inside, so a second inside is one dart. */
export const PUDDLE_TICK_SHARE = 0.25;
export const STEAM_SECONDS = 2.5;
export const STEAM_RADIUS = 75;
/** A foe in the steam stays blind this long after it leaves it, drifting at this share of its speed. */
export const BLIND_SECONDS = 1;
export const BLIND_DRIFT = 0.4;
export const BURST_RADIUS = 80;
/** The flame burst takes this share of the ant's dart damage off every foe around the kill. */
export const BURST_SHARE = 0.6;

export const COMBO_NAME: Readonly<Record<ComboId, string>> = { puddle: 'Shock Puddle', steam: 'Blinding Steam', burst: 'Flame Burst' };
/** The plain line a pick card shows when this element would unlock the combo. */
export const COMBO_LINE: Readonly<Record<ComboId, string>> = {
  puddle: '1 in 5 kills leave a shock puddle for 3 s',
  steam: '1 in 5 kills leave steam that blinds foes',
  burst: '1 in 5 kills burst in flame on foes near',
};
/** The two elements of each combo. */
const COMBO_PARTS: Readonly<Record<ComboId, readonly [PowerId, PowerId]>> = {
  puddle: ['frost', 'spark'],
  steam: ['fire', 'frost'],
  burst: ['fire', 'spark'],
};
export const ELEMENTS: ReadonlyArray<PowerId> = ['fire', 'frost', 'spark'];

/** Which combos the run's elements unlock. */
export function combosOf(stacks: Readonly<Record<PowerId, number>>): Record<ComboId, boolean> {
  const has = (id: PowerId) => (stacks[id] ?? 0) > 0;
  return {
    puddle: has('frost') && has('spark'),
    steam: has('fire') && has('frost'),
    burst: has('fire') && has('spark'),
  };
}

/** The combos taking this element would unlock now (the other half already owned), none for a non element or an owned one. */
export function combosUnlockedBy(id: PowerId, stacks: Readonly<Record<PowerId, number>>): ComboId[] {
  if (!ELEMENTS.includes(id) || (stacks[id] ?? 0) > 0) return [];
  return COMBO_IDS.filter((c) => {
    const [a, b] = COMBO_PARTS[c];
    const other = a === id ? b : b === id ? a : null;
    return other !== null && (stacks[other] ?? 0) > 0;
  });
}

/** The pick card's one line: the power's own, or, when it completes a combo, what the combo does. */
export function powerLine(id: PowerId, stacks: Readonly<Record<PowerId, number>>): string {
  const combos = combosUnlockedBy(id, stacks);
  if (combos.length === 0) return powerSpec(id).line;
  const what = combos.map((c) => COMBO_LINE[c]).join('; ');
  return `Combo: ${what}`;
}

/**
 * The ant's look (a play tester's list: the ant changes as it levels and picks upgrades): armour plates at
 * max health tiers, an aura in the colour of each element it carries, and a rim that changes colour at levels 4, 8, 12.
 */
export const PLATE_TIERS: ReadonlyArray<number> = [900, 1500, 2400];
export const ELEMENT_COLOR: Readonly<Record<'fire' | 'frost' | 'spark', number>> = { fire: 0xff6d2e, frost: 0x81d4fa, spark: 0xfff176 };
export interface AntLook {
  /** Armour plate bands, 0 to 3. */
  plates: number;
  /** The aura's colours, one per element carried, in the order fire, frost, spark. */
  aura: number[];
  /** The rim colour by level tier, null below level 4. */
  rim: number | null;
}
export function antLook(level: number, maxHp: number, stacks: Readonly<Record<PowerId, number>>): AntLook {
  const plates = PLATE_TIERS.filter((t) => maxHp >= t).length;
  const aura: number[] = [];
  for (const e of ['fire', 'frost', 'spark'] as const) if ((stacks[e] ?? 0) > 0) aura.push(ELEMENT_COLOR[e]);
  const rim = level >= 12 ? 0xffd34d : level >= 8 ? 0xc9b6ff : level >= 4 ? 0x9effa1 : null;
  return { plates, aura, rim };
}

export const POWERS: ReadonlyArray<PowerSpec> = [
  { id: 'jaw', name: 'Strong Jaw', line: 'Darts hit 13% harder', max: 5, color: 0xff7043 },
  { id: 'glands', name: 'Quick Glands', line: 'Shoot 10% faster', max: 4, color: 0x4fc3f7 },
  { id: 'shell', name: 'Hearty Shell', line: 'Max health up 13%, healed at once', max: 3, color: 0x66bb6a },
  { id: 'honeydew', name: 'Honeydew', line: 'Heal 27% of your max health now', max: null, color: 0xffca28 },
  { id: 'eye', name: 'Keen Eye', line: 'Crit chance up 7% when standing still', max: 3, color: 0xffee58 },
  { id: 'fang', name: 'Front Fang', line: 'One more dart; all darts 25% weaker', max: 2, color: 0xef5350 },
  { id: 'fork', name: 'Fork Darts', line: 'Two extra darts fly out at an angle', max: 2, color: 0xab47bc },
  { id: 'echo', name: 'Echo Sting', line: 'Each shot repeats; 10% weaker, 15% slower', max: 3, color: 0x26c6da },
  { id: 'needle', name: 'Needle Point', line: 'Darts pass through, 33% weaker per foe', max: 1, color: 0xb0bec5 },
  { id: 'hop', name: 'Bounce Venom', line: 'Darts hop to 2 more foes, 30% weaker a hop', max: 1, color: 0x9ccc65 },
  { id: 'lucky', name: 'Lucky Sting', line: 'First hits kill 1 foe in 12 (not the boss)', max: 1, color: 0x2ee59d },
  { id: 'fury', name: 'Fury Glands', line: 'Damage up 2% per 3% of health missing', max: 1, color: 0xff3d3d },
  { id: 'frost', name: 'Frost Sap', line: '1 in 5 hits slow a foe to 60% for 1.5 s', max: 1, color: 0x81d4fa },
  { id: 'stance', name: 'Stone Stance', line: 'Take 13% less damage standing still', max: 2, color: 0xa1887f },
  { id: 'fire', name: 'Fire Venom', line: '1 in 5 hits burn a foe 30% more over 2 s', max: 1, color: 0xff6d2e },
  { id: 'spark', name: 'Spark Venom', line: '1 in 5 hits arc to a foe nearby for 40%', max: 1, color: 0xf9d71c },
];

export type PowerStacks = Readonly<Record<PowerId, number>>;

export const POWER_IDS: ReadonlyArray<PowerId> = POWERS.map((p) => p.id);

export function powerSpec(id: PowerId): PowerSpec {
  const spec = POWERS.find((p) => p.id === id);
  if (!spec) throw new RangeError(`unknown power ${String(id)}`);
  return spec;
}

export function isPowerId(x: unknown): x is PowerId {
  return typeof x === 'string' && POWER_IDS.includes(x as PowerId);
}

export function emptyStacks(): Record<PowerId, number> {
  const s = {} as Record<PowerId, number>;
  for (const id of POWER_IDS) s[id] = 0;
  return s;
}

export function canTake(stacks: PowerStacks, id: PowerId): boolean {
  const max = powerSpec(id).max;
  return max === null || stacks[id] < max;
}

/** One more of a power. Pure: returns new stacks; refuses a power already at its cap. */
export function takePower(stacks: PowerStacks, id: PowerId): Record<PowerId, number> {
  if (!canTake(stacks, id)) throw new RangeError(`${id} is at its cap`);
  return { ...stacks, [id]: stacks[id] + 1 };
}

/** Up to three different powers, none at its cap, drawn with roll() in [0, 1). Honeydew has no cap, so never empty. */
export function drawOffer(stacks: PowerStacks, roll: () => number, count = 3): PowerId[] {
  const pool = POWER_IDS.filter((id) => canTake(stacks, id));
  const out: PowerId[] = [];
  while (out.length < count && pool.length > 0) {
    const i = Math.min(pool.length - 1, Math.max(0, Math.floor(roll() * pool.length)));
    out.push(pool.splice(i, 1)[0]);
  }
  return out;
}

/** The ant in a fight: its stats after the nest perks and the powers, plus what each power switches on. */
export interface Build extends AntStats {
  /** Crit chance while standing still; moving never crits (the shooting rule). */
  critChance: number;
  /** Volleys per shot: 1, plus one echo per Echo Sting. */
  volleys: number;
  /** Angled pairs per volley (Fork Darts). */
  forkPairs: number;
  pierce: boolean;
  /** Hops per dart (Bounce Venom). */
  hops: number;
  /** Chance a dart kills outright (Lucky Sting), 0 without it. */
  lucky: number;
  fury: boolean;
  frost: boolean;
  /** Slice 4: the fire and spark elements. */
  fire: boolean;
  spark: boolean;
  /** Share of damage blocked while standing still (Stone Stance). */
  block: number;
}

/** The build from the stats after the nest perks (economy.ts applyPerk) and the power stacks. Pure. */
export function deriveBuild(perkStats: Readonly<AntStats>, stacks: PowerStacks): Build {
  const darts = perkStats.darts + stacks.fang;
  // Lane G8: Twin Stinger's two darts share the shot's damage plus a tenth, taken over the final darts (Front Fang's
  // too), so the shot with it is always 1.1 times the shot without it, and it never makes a held Front Fang worse.
  const twinShare = perkStats.twin && darts > 1 ? (TWIN_SHOT_GAIN * (darts - 1)) / darts : 1;
  const damage =
    perkStats.damage *
    (1 + JAW_DAMAGE_STEP * stacks.jaw) *
    Math.pow(FANG_DAMAGE_FACTOR, stacks.fang) *
    Math.pow(ECHO_DAMAGE_FACTOR, stacks.echo) *
    twinShare;
  const rate = (1 + GLANDS_RATE_STEP * stacks.glands) * Math.pow(ECHO_RATE_FACTOR, stacks.echo);
  return {
    maxHp: Math.round(perkStats.maxHp * (1 + SHELL_HP_STEP * stacks.shell)),
    damage,
    fireInterval: perkStats.fireInterval / rate,
    darts,
    speed: perkStats.speed,
    critChance: STILL_CRIT_CHANCE + EYE_CRIT_STEP * stacks.eye,
    volleys: 1 + stacks.echo,
    forkPairs: stacks.fork,
    pierce: stacks.needle > 0,
    hops: stacks.hop > 0 ? HOP_COUNT : 0,
    lucky: stacks.lucky > 0 ? LUCKY_CHANCE : 0,
    fury: stacks.fury > 0,
    frost: stacks.frost > 0,
    fire: stacks.fire > 0,
    spark: stacks.spark > 0,
    block: STANCE_BLOCK_STEP * stacks.stance,
  };
}

/**
 * Lucky Sting (CONCEPT_V1 6f: a chance to kill on the first hit): only a predator's first hit rolls, 1 in 8, and never
 * on the boss. roll is a number in [0, 1).
 */
export function luckyHit(build: Readonly<Build>, firstHit: boolean, isBoss: boolean, roll: number): boolean {
  return firstHit && !isBoss && build.lucky > 0 && roll < build.lucky;
}

/** Fury Glands: 1 plus two thirds of the share of health missing, so x1.66 at 1 percent health. */
export function furyFactor(hp: number, maxHp: number): number {
  const missing = maxHp > 0 ? 1 - hp / maxHp : 0;
  return 1 + FURY_SHARE * Math.min(1, Math.max(0, missing));
}

/** Damage the ant takes from a hit: Stone Stance cuts it while standing still. Never below 1 for a real hit. */
export function damageTaken(damage: number, build: Readonly<Build>, moving: boolean): number {
  if (damage <= 0) return 0;
  if (moving || build.block <= 0) return damage;
  return Math.max(1, Math.round(damage * (1 - build.block)));
}

/** Health right after a pick: Hearty Shell heals what it adds, Honeydew heals 40 percent of the max, never past it. */
export function healthAfterPick(id: PowerId, hp: number, oldMax: number, newMax: number): number {
  let next = hp;
  if (newMax > oldMax) next += newMax - oldMax;
  if (id === 'honeydew') next += Math.round(newMax * HONEYDEW_HEAL);
  return Math.min(newMax, next);
}
