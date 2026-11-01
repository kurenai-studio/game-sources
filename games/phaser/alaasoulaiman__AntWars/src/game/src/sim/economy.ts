// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// The ant's stats, the shooting rule (CONCEPT_V2 section 4) and the nest shop (section 3), as plain functions.
// Slice 4: the whole in run economy (the repeatable lines, their shrinking steps, the shared climbing price, the pick
// cap, the cap on one hit, the ledger of nectar earned and spent, and the tuning model) lives here too.
import { upgradeCost } from './colony';
import { enemiesForRound, enemyHealth, roundPlan } from './curve';

export interface AntStats {
  maxHp: number;
  /** Damage of one dart. */
  damage: number;
  /** Seconds between two shots while standing still. */
  fireInterval: number;
  /** Darts per shot. */
  darts: number;
  /** Base move speed in world units a second; every predator's speed is a share of this. */
  speed: number;
  /** Lane G8: Twin Stinger is owned, so the build shares the shot's damage over its darts (growth.ts deriveBuild). */
  twin?: boolean;
}

/** The weak starting ant everyone gets (Pure ladder): V1's level 1 hero, 600 HP and 150 a hit, with the Stinger. */
export const BASE_ANT: Readonly<AntStats> = { maxHp: 600, damage: 150, fireInterval: 0.42, darts: 1, speed: 250 };

/** Section 4: the ant fires while moving at 50 percent fire rate; standing still gives the full rate and crits. */
export const MOVING_FIRE_RATE = 0.5;
export const STILL_CRIT_CHANCE = 0.1;
export const CRIT_MULTIPLIER = 2;

export function fireIntervalSeconds(stats: Readonly<AntStats>, moving: boolean): number {
  return moving ? stats.fireInterval / MOVING_FIRE_RATE : stats.fireInterval;
}

export function critChance(moving: boolean): number {
  return moving ? 0 : STILL_CRIT_CHANCE;
}

/** Nectar (the run's points): 10 a hit, the predator's kill value, plus a bonus for a kill up close. */
export const NECTAR_PER_HIT = 10;
export const CLOSE_KILL_RANGE = 150;
export const CLOSE_KILL_BONUS = 50;

export function killNectar(baseNectar: number, distance: number): number {
  return baseNectar + (distance <= CLOSE_KILL_RANGE ? CLOSE_KILL_BONUS : 0);
}

/**
 * Nectar after the multipliers (Sweet Tooth, the double nectar blessing), kept exact: VG4 found a hit of 10 at Sweet
 * Tooth step 1 rounded to 11, ten percent where the card says five. The run holds fractions; the HUD shows whole drops.
 */
export function nectarGain(base: number, multiplier: number): number {
  return base * multiplier;
}

export type PerkId = 'chitin' | 'twin' | 'quick';
export interface PerkSpec {
  id: PerkId;
  name: string;
  price: number;
  blurb: string;
  /** Lane G8: buys one run can make (Thick Chitin stacks; the other two are one time). */
  max: number;
}

/**
 * The three nest perks of slice 1, prices as section 3 gives them. Chosen because each changes the feel at once:
 * Thick Chitin is the better armour, Twin Stinger doubles the darts on screen, Quick Mandibles speeds the rhythm.
 * Lane G8 (design note, 2026-10-24: small steps in the run's own buys too): no perk steps a stat by more than the
 * largest step a trimmed pick uses (2/15, Strong Jaw and Hearty Shell in growth.ts). Thick Chitin is +2/15 max health a
 * buy, up to three buys (x2.5 in one buy before); Quick Mandibles +10 percent fire rate (+30 before); Twin Stinger keeps
 * its second dart, and the two darts share the shot's damage plus a tenth (the shot +10 percent, +100 before).
 */
export const PERKS: ReadonlyArray<PerkSpec> = [
  // The blurb shares its row with the price (OWNED is the widest), so it stays as short as slice 1's; the card's name
  // counts Thick Chitin's buys (HudScene).
  { id: 'chitin', name: 'Thick Chitin', price: 2500, blurb: 'Max health +13%', max: 3 },
  { id: 'twin', name: 'Twin Stinger', price: 2000, blurb: 'Two darts, +10%', max: 1 },
  { id: 'quick', name: 'Quick Mandibles', price: 3000, blurb: 'Fire rate +10%', max: 1 },
];

/** Thick Chitin's step a buy, the same as Hearty Shell's (0.2 x 2/3); buys add up, as the powers' percent steps do. */
export const CHITIN_HP_STEP = 2 / 15;
export const QUICK_RATE_FACTOR = 1.1;
/** Twin Stinger: the shot's damage over all its darts is this times the shot without the second dart. */
export const TWIN_SHOT_GAIN = 1.1;

export function perkSpec(id: PerkId): PerkSpec {
  const spec = PERKS.find((p) => p.id === id);
  if (!spec) throw new RangeError(`unknown perk ${String(id)}`);
  return spec;
}

/** How many times the run bought this perk: the owned list holds a perk once per buy. */
export function perkCount(owned: Iterable<PerkId>, id: PerkId): number {
  let n = 0;
  for (const p of owned) if (p === id) n += 1;
  return n;
}

/** The ant's stats after one buy of a perk. Pure: returns a new object. */
export function applyPerk(stats: Readonly<AntStats>, id: PerkId): AntStats {
  switch (id) {
    case 'chitin':
      return { ...stats, maxHp: Math.round(stats.maxHp * (1 + CHITIN_HP_STEP)) };
    case 'twin':
      return { ...stats, darts: stats.darts + 1, twin: true };
    case 'quick':
      return { ...stats, fireInterval: stats.fireInterval / QUICK_RATE_FACTOR };
  }
}

export function canBuy(nectar: number, owned: Iterable<PerkId>, id: PerkId): boolean {
  const spec = perkSpec(id);
  return perkCount(owned, id) < spec.max && nectar >= spec.price;
}

export interface Purchase {
  nectar: number;
  owned: PerkId[];
}

/** Spends the nectar for one buy of a perk; refuses a perk at its max or one the nectar does not cover. */
export function buyPerk(nectar: number, owned: Iterable<PerkId>, id: PerkId): Purchase {
  if (!canBuy(nectar, owned, id)) throw new RangeError(`cannot buy ${id} with ${nectar} nectar`);
  return { nectar: nectar - perkSpec(id).price, owned: [...owned, id] };
}

/** The run's phases as the shop sees them (the same as the Yard's director; 'title' is the Continue screen). */
export type ShopPhase = 'title' | 'intro' | 'active' | 'break' | 'dead';
/** open: the cards show and buy. locked: a round is on and the ant walked back into the nest, so a plain line says when it opens. closed: nothing shows. */
export type ShopState = 'open' | 'locked' | 'closed';

/**
 * The one rule for the nest shop: it opens only in the break between rounds, with the ant standing in the nest. During
 * a round it never sells, and the plain line shows only for an ant that has been out of the nest this round and came
 * back. An ant the round found standing in the nest (its spawn at round 1, or the shop when the countdown ran out)
 * sees nothing until it leaves and returns.
 */
export function shopState(phase: ShopPhase, inNest: boolean, leftNestThisRound: boolean): ShopState {
  if (!inNest) return 'closed';
  if (phase === 'break') return 'open';
  if (phase === 'active' && leftNestThisRound) return 'locked';
  return 'closed';
}

/** Whether the ant has been out of the nest during this round. The director starts it at false at every round start. */
export function trackLeftNest(left: boolean, phase: ShopPhase, inNest: boolean): boolean {
  return left || (phase === 'active' && !inNest);
}

// Slice 4: the in run economy (design note, 2026-10-24). The nest shop between rounds sells repeatable lines
// whose steps shrink with every buy, on one price that climbs the concept's talent ladder with every line bought, so
// nectar never piles up with nothing to spend it on. Past the pick cap the shop is the only growth.

/**
 * Design note, 2026-10-24: damage taken is capped, and with so many enemies to get through a run is easy to survive
 * and easy to lose at the same time. No single hit takes more than a fifth of the max health;
 * the cap comes first, then Stone Stance and Plated Back cut what is left, so armour still counts against a big hit.
 */
export const HIT_CAP_SHARE = 0.2;

/** A hit after the cap: at most a fifth of the max health (rounded down, at least 1), never more than the hit itself. */
export function capHit(raw: number, maxHp: number): number {
  if (raw <= 0) return 0;
  return Math.min(raw, Math.max(1, Math.floor(maxHp * HIT_CAP_SHARE)));
}

/** The level up picks stop at this level, and from then on no pick of any kind comes (the shop is the only growth). */
export const PICK_CAP_LEVEL = 12;

/** Whether a pick may still come: a level up, Royal Jelly's pick or a boss's pick, all only below the cap. */
export function picksOpen(level: number): boolean {
  return level < PICK_CAP_LEVEL;
}

export type LineId = 'damage' | 'rate' | 'health' | 'speed' | 'darts';
export interface LineSpec {
  id: LineId;
  name: string;
  /** The first buy's step, in the line's unit. */
  first: number;
  /** Each step is about this share of the one before, and always at least 1 less, until the floor. */
  decay: number;
  /** The smallest step; the line keeps selling at it. */
  floor: number;
  /** The unit after the number on the card: "+30 damage". */
  unit: string;
  /** Buys one run can make on the line (every line has one since the design note of 2026-10-24). */
  max: number | null;
  /** The line opens in the break after this round is cleared (0: from the first break). */
  opensAfter: number;
  /** The line's price is the shared ladder price times this. */
  priceFactor: number;
  /** Every step of the line is scaled by this (the design note of 2026-10-24 halved the shop's steps; a dart is one dart). */
  scale: number;
}

/** Design note, 2026-10-24: a buy should not be a great increase, so the shop's steps are halved. */
export const SHOP_STEP_SCALE = 0.5;
/**
 * Design note, 2026-10-24: every line has a maximum, fire rate above all, so nothing climbs forever. Dart Damage stops at 20
 * buys (+128.5), Fire Rate at 12 (+47 percent), Max Health at 20 (+350.5); Speed keeps 8 and Extra Dart 2.
 */
export const DAMAGE_MAX = 20;
export const RATE_MAX = 12;
export const HEALTH_MAX = 20;

/**
 * The five lines. Damage adds to every dart and health to the max before the powers multiply; fire rate and speed are
 * percent of the run's base. The extra dart comes later in a run, at five times the price. First guesses for the playtest.
 */
export const LINES: ReadonlyArray<LineSpec> = [
  { id: 'damage', name: 'Dart Damage', first: 30, decay: 0.9, floor: 4, unit: 'damage', max: DAMAGE_MAX, opensAfter: 0, priceFactor: 1, scale: SHOP_STEP_SCALE },
  { id: 'rate', name: 'Fire Rate', first: 15, decay: 0.88, floor: 1, unit: '% fire rate', max: RATE_MAX, opensAfter: 0, priceFactor: 1, scale: SHOP_STEP_SCALE },
  { id: 'health', name: 'Max Health', first: 80, decay: 0.9, floor: 10, unit: 'health', max: HEALTH_MAX, opensAfter: 0, priceFactor: 1, scale: SHOP_STEP_SCALE },
  { id: 'speed', name: 'Speed', first: 4, decay: 0.75, floor: 1, unit: '% speed', max: 8, opensAfter: 0, priceFactor: 1, scale: SHOP_STEP_SCALE },
  { id: 'darts', name: 'Extra Dart', first: 1, decay: 1, floor: 1, unit: 'dart', max: 2, opensAfter: 10, priceFactor: 5, scale: 1 },
];
export const LINE_IDS: ReadonlyArray<LineId> = LINES.map((l) => l.id);
export type LineLevels = Readonly<Record<LineId, number>>;

export function lineSpec(id: LineId): LineSpec {
  const spec = LINES.find((l) => l.id === id);
  if (!spec) throw new RangeError(`unknown line ${String(id)}`);
  return spec;
}

export function isLineId(x: unknown): x is LineId {
  return typeof x === 'string' && LINE_IDS.includes(x as LineId);
}

export function emptyLines(): Record<LineId, number> {
  return { damage: 0, rate: 0, health: 0, speed: 0, darts: 0 };
}

/**
 * The step of the k-th buy of a line (1 based): about decay times the one before, rounded, always at least 1 less, never
 * under the floor, then times the line's scale (a half since the design note of 2026-10-24); null past the line's cap. So each buy
 * gives less than the last until the floor.
 */
export function lineStep(id: LineId, k: number): number | null {
  if (!Number.isInteger(k) || k < 1) throw new RangeError(`k must be an integer of 1 or more, got ${k}`);
  const spec = lineSpec(id);
  if (spec.max !== null && k > spec.max) return null;
  let step = spec.first;
  for (let i = 2; i <= k; i++) {
    const shaped = Math.round(spec.first * Math.pow(spec.decay, i - 1));
    step = Math.max(spec.floor, Math.min(step - 1, shaped));
  }
  return step * spec.scale;
}

/** What the first n buys of a line add up to. */
export function lineTotal(id: LineId, n: number): number {
  let total = 0;
  for (let k = 1; k <= n; k++) total += lineStep(id, k) ?? 0;
  return total;
}

/** Line buys of any line so far: the shared price reads it. */
export function lineBuys(levels: LineLevels): number {
  let n = 0;
  for (const id of LINE_IDS) n += levels[id];
  return n;
}

/** The talent ladder's last price holds past its end (its 125th step), so the shop never runs out of things to sell. */
const LADDER_TOP = upgradeCost(125) as number;

/** The price of the next buy of this line: the ladder price of the next line buy of any line, times the line's factor. */
export function linePrice(id: LineId, levels: LineLevels): number {
  const n = lineBuys(levels) + 1;
  return (upgradeCost(n) ?? LADDER_TOP) * lineSpec(id).priceFactor;
}

/** The line is for sale in the break after this round (the extra dart opens after round 10). */
export function lineOpen(id: LineId, roundCleared: number): boolean {
  return roundCleared >= lineSpec(id).opensAfter;
}

export function canBuyLine(nectar: number, levels: LineLevels, id: LineId, roundCleared: number): boolean {
  if (!lineOpen(id, roundCleared)) return false;
  if (lineStep(id, levels[id] + 1) === null) return false;
  return nectar >= linePrice(id, levels);
}

export interface LinePurchase {
  nectar: number;
  levels: Record<LineId, number>;
  price: number;
}

/** Spends the nectar for the next step of a line; refuses a closed line, a capped one or one the nectar does not cover. */
export function buyLine(nectar: number, levels: LineLevels, id: LineId, roundCleared: number): LinePurchase {
  if (!canBuyLine(nectar, levels, id, roundCleared)) throw new RangeError(`cannot buy ${id} with ${nectar} nectar`);
  const price = linePrice(id, levels);
  return { nectar: nectar - price, levels: { ...levels, [id]: levels[id] + 1 }, price };
}

/**
 * The ant after the run's nest buys, in one order whatever order they were bought in: the lines add to the meta ant
 * (damage and health flat, fire rate and speed as percent of it, darts one each), then the perks (each Thick Chitin
 * buy adds 2/15 to the health's multiplier, Twin Stinger adds a dart that shares the shot, Quick Mandibles speeds the
 * fire). The powers go on top in growth.ts, where Twin Stinger's share of the shot is taken over the final darts.
 */
export function runStats(meta: Readonly<AntStats>, owned: Iterable<PerkId>, levels: LineLevels): AntStats {
  let s: AntStats = {
    maxHp: meta.maxHp + lineTotal('health', levels.health),
    damage: meta.damage + lineTotal('damage', levels.damage),
    fireInterval: meta.fireInterval / (1 + lineTotal('rate', levels.rate) / 100),
    darts: meta.darts + lineTotal('darts', levels.darts),
    speed: meta.speed * (1 + lineTotal('speed', levels.speed) / 100),
  };
  const chitin = perkCount(owned, 'chitin');
  if (chitin > 0) s = { ...s, maxHp: Math.round(s.maxHp * (1 + CHITIN_HP_STEP * chitin)) };
  if (perkCount(owned, 'twin') > 0) s = { ...s, darts: s.darts + 1, twin: true };
  if (perkCount(owned, 'quick') > 0) s = { ...s, fireInterval: s.fireInterval / QUICK_RATE_FACTOR };
  return s;
}

/** One step as the card writes it: "+30 damage", "+15% fire rate", "+1 dart". */
export function stepText(id: LineId, n: number): string {
  const unit = lineSpec(id).unit;
  return unit.startsWith('%') ? `+${n}${unit}` : `+${n} ${unit}${unit === 'dart' && n !== 1 ? 's' : ''}`;
}

/** The card's plain line: this buy's step and the one after ("+30 damage, next +27"), or why it does not sell. */
export function lineCard(id: LineId, levels: LineLevels, roundCleared: number): string {
  const spec = lineSpec(id);
  if (!lineOpen(id, roundCleared)) return `Opens after round ${spec.opensAfter}`;
  const now = lineStep(id, levels[id] + 1);
  if (now === null) return 'Max';
  const next = lineStep(id, levels[id] + 2);
  if (next === null) return `${stepText(id, now)}, the last one`;
  const nextNumber = stepText(id, next).split(' ')[0].replace(/%.*$/, '%');
  return `${stepText(id, now)}, next ${nextNumber}`;
}

/** What one run's economy did: nectar earned in the run and nectar spent in its nest shop (perks and lines). */
export interface Ledger {
  earned: number;
  spent: number;
}

export function emptyLedger(): Ledger {
  return { earned: 0, spent: 0 };
}

/** The share of the nectar earned that was spent, 0 to 1; null before any was earned (missing data stays missing). */
export function spentShare(ledger: Readonly<Ledger>): number | null {
  return ledger.earned > 0 ? ledger.spent / ledger.earned : null;
}

/**
 * A plain model of a run for the tuning check (not the game): every predator of the round killed, its hits at the
 * model's dart damage, its bead and a close kill one time in three; in each break a buyer takes the lines in turn
 * (damage, fire rate, health, speed) while the nectar covers the next price. MODEL_POWER_ESTIMATE stands for the picks
 * (1.6 until the design note of 2026-10-24 trimmed the picks by a third: 1 + 0.6 x 2/3).
 */
export const MODEL_POWER_ESTIMATE = 1.4;
/** The model's average bead and health share of a horde predator (the roster's mix), and its close kill share. */
export const MODEL_BEAD = 70;
export const MODEL_HP_SHARE = 1.3;
export const MODEL_CLOSE_SHARE = 1 / 3;

export interface ProjectedRound {
  round: number;
  earned: number;
  spent: number;
  held: number;
  buys: number;
}

export function projectRun(toRound: number): ProjectedRound[] {
  const out: ProjectedRound[] = [];
  let levels: Record<LineId, number> = emptyLines();
  let nectar = 0;
  let earned = 0;
  let spent = 0;
  const order: LineId[] = ['damage', 'rate', 'health', 'speed'];
  let turn = 0;
  for (let r = 1; r <= toRound; r++) {
    const plan = roundPlan(r);
    const dart = (BASE_ANT.damage + lineTotal('damage', levels.damage)) * MODEL_POWER_ESTIMATE;
    let gain: number;
    if (plan.kind === 'horde') {
      const hits = Math.max(1, Math.ceil((enemyHealth(r) * MODEL_HP_SHARE) / dart));
      gain = enemiesForRound(r) * (NECTAR_PER_HIT * hits + MODEL_BEAD + CLOSE_KILL_BONUS * MODEL_CLOSE_SHARE);
    } else {
      // A breather or a boss round: termites at one hit each, plus a boss's big bead.
      const termites = plan.kind === 'breather' ? plan.total : plan.total - 1;
      gain = termites * (NECTAR_PER_HIT + 20 + CLOSE_KILL_BONUS * MODEL_CLOSE_SHARE) + (plan.kind === 'breather' ? 0 : 1000);
    }
    gain = Math.round(gain);
    nectar += gain;
    earned += gain;
    for (let guard = 0; guard < 500; guard++) {
      const open = order.filter((id) => canBuyLine(nectar, levels, id, r));
      if (open.length === 0) break;
      const id = order[turn % order.length];
      turn += 1;
      if (!open.includes(id)) continue;
      const p = buyLine(nectar, levels, id, r);
      spent += p.price;
      nectar = p.nectar;
      levels = p.levels;
    }
    out.push({ round: r, earned, spent, held: nectar, buys: lineBuys(levels) });
  }
  return out;
}
