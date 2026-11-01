// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// The Colony between runs (CONCEPT_V2 section 7 on top of CONCEPT_V1 sections 6b and 6e): the nectar left at a death is
// banked, and the nest screen between runs sells permanent upgrades. The prices climb on the talent cost ladder of
// CONCEPT_V1 6e (one ladder for every upgrade, as a talent roll is one price); the steps are linear, the hero's +8
// attack and +25 health a level from 6b, the rest our first guesses. Pure mode switches the whole meta off.
import type { KeyValueStore } from './best';
import type { AntStats } from './economy';

export type Ladder = 'colony' | 'pure';
export const LADDERS: ReadonlyArray<Ladder> = ['colony', 'pure'];
/** The name the HUD, the title and the death screen show. */
export const LADDER_NAME: Readonly<Record<Ladder, string>> = { colony: 'COLONY', pure: 'PURE' };

export function isLadder(x: unknown): x is Ladder {
  return x === 'colony' || x === 'pure';
}

/**
 * The cost ladder, CONCEPT_V1 6e: the first upgrade costs 200 and each band adds its step to the one before, so the
 * 7th costs 500, the 12th 1,000, the 22nd 3,000, the 36th 10,000, the 46th 20,000, the 61st 50,000, the 81st 150,000,
 * the 96th 300,000 and the 125th 1,000,000. The concept gives 97 to 125 as "+20,000 then +30,000" to 1,000,000; 17
 * steps of 20,000 and 12 of 30,000 are the only split that lands on it.
 */
const COST_FIRST = 200;
const COST_BANDS: ReadonlyArray<{ last: number; step: number }> = [
  { last: 7, step: 50 },
  { last: 12, step: 100 },
  { last: 22, step: 200 },
  { last: 36, step: 500 },
  { last: 46, step: 1000 },
  { last: 61, step: 2000 },
  { last: 81, step: 5000 },
  { last: 96, step: 10000 },
  { last: 113, step: 20000 },
  { last: 125, step: 30000 },
];
/** The ladder ends at its 125th upgrade; the six lines' caps add up to exactly that. */
export const COST_LADDER_LENGTH = 125;

const COSTS: number[] = (() => {
  const out = [COST_FIRST];
  for (let n = 2; n <= COST_LADDER_LENGTH; n++) {
    const band = COST_BANDS.find((b) => n <= b.last);
    out.push(out[out.length - 1] + (band ? band.step : 0));
  }
  return out;
})();

/** The price of the n-th upgrade bought (1 based, any line), or null past the end of the ladder. */
export function upgradeCost(n: number): number | null {
  if (!Number.isInteger(n) || n < 1) throw new RangeError(`n must be an integer of 1 or more, got ${n}`);
  return n <= COST_LADDER_LENGTH ? COSTS[n - 1] : null;
}

export type UpgradeId = 'stinger' | 'diet' | 'plates' | 'legs' | 'venom' | 'sweet';

export interface UpgradeSpec {
  id: UpgradeId;
  name: string;
  /** What one step adds, in its own unit (damage, health, or a share). */
  step: number;
  /** Steps one colony can buy. */
  max: number;
  color: number;
}

/**
 * Design note, 2026-10-24: a buy in the nest should not be a great increase, so every step below is half what slice
 * 3 gave; the prices and the caps are unchanged.
 */
/** Barbed Stinger: +4 dart damage a step (half the hero's +8 attack a level). */
export const STINGER_STEP = 4;
/** Royal Diet: +12.5 max health a step (half the hero's +25 a level), the total rounded to a whole point. */
export const DIET_STEP = 12.5;
/** Plated Back: 1 percent less damage taken a step, 15 percent at the cap. Ours. */
export const PLATES_STEP = 0.01;
/** Long Legs: half a percent faster a step; the predators' cap stays at 94 percent of the base ant. Ours. */
export const LEGS_STEP = 0.005;
/** Rapid Venom: 1 percent faster fire a step. Ours. */
export const VENOM_STEP = 0.01;
/** Sweet Tooth: 2.5 percent more nectar a step (the colony's earnings talent). Ours. */
export const SWEET_STEP = 0.025;

export const UPGRADES: ReadonlyArray<UpgradeSpec> = [
  { id: 'stinger', name: 'Barbed Stinger', step: STINGER_STEP, max: 30, color: 0xff7043 },
  { id: 'diet', name: 'Royal Diet', step: DIET_STEP, max: 30, color: 0x66bb6a },
  { id: 'plates', name: 'Plated Back', step: PLATES_STEP, max: 15, color: 0xa1887f },
  { id: 'legs', name: 'Long Legs', step: LEGS_STEP, max: 10, color: 0x4fc3f7 },
  { id: 'venom', name: 'Rapid Venom', step: VENOM_STEP, max: 20, color: 0xab47bc },
  { id: 'sweet', name: 'Sweet Tooth', step: SWEET_STEP, max: 20, color: 0xffca28 },
];
export const UPGRADE_IDS: ReadonlyArray<UpgradeId> = UPGRADES.map((u) => u.id);

export function upgradeSpec(id: UpgradeId): UpgradeSpec {
  const spec = UPGRADES.find((u) => u.id === id);
  if (!spec) throw new RangeError(`unknown upgrade ${String(id)}`);
  return spec;
}

export type ColonyLevels = Readonly<Record<UpgradeId, number>>;

export function emptyLevels(): Record<UpgradeId, number> {
  const out = {} as Record<UpgradeId, number>;
  for (const id of UPGRADE_IDS) out[id] = 0;
  return out;
}

/** Steps bought on every line together: the next upgrade, of any line, is number totalSteps + 1 on the ladder. */
export function totalSteps(levels: ColonyLevels): number {
  return UPGRADE_IDS.reduce((sum, id) => sum + levels[id], 0);
}

/** The price of the next upgrade, the same on every card; null once every line is full. */
export function nextCost(levels: ColonyLevels): number | null {
  return upgradeCost(totalSteps(levels) + 1);
}

export interface ColonyState {
  /** Nectar in the colony's store, banked at the end of Colony runs. */
  bank: number;
  levels: Record<UpgradeId, number>;
}

export function emptyColony(): ColonyState {
  return { bank: 0, levels: emptyLevels() };
}

export function canBuyUpgrade(state: Readonly<ColonyState>, id: UpgradeId): boolean {
  const cost = nextCost(state.levels);
  return cost !== null && state.levels[id] < upgradeSpec(id).max && state.bank >= cost;
}

/** One step of one line for the ladder's price. Pure: a new state; refuses a full line or a bank that is short. */
export function buyUpgrade(state: Readonly<ColonyState>, id: UpgradeId): ColonyState {
  if (!canBuyUpgrade(state, id)) throw new RangeError(`cannot buy ${id} with ${state.bank} nectar`);
  const cost = nextCost(state.levels) as number;
  return { bank: state.bank - cost, levels: { ...state.levels, [id]: state.levels[id] + 1 } };
}

/** A Colony run that ends banks every whole drop of nectar it still holds. */
export function bankAfterRun(bank: number, nectarLeft: number): number {
  return bank + Math.max(0, Math.floor(nectarLeft));
}

/** The ant a run starts with: the base ant with the colony's upgrades on top. Pure mode passes empty levels. */
export function applyColony(base: Readonly<AntStats>, levels: ColonyLevels): AntStats {
  return {
    maxHp: Math.round(base.maxHp + DIET_STEP * levels.diet),
    damage: base.damage + STINGER_STEP * levels.stinger,
    fireInterval: base.fireInterval / (1 + VENOM_STEP * levels.venom),
    darts: base.darts,
    speed: base.speed * (1 + LEGS_STEP * levels.legs),
  };
}

/** Share of every hit Plated Back takes off. */
export function armorCut(levels: ColonyLevels): number {
  return PLATES_STEP * levels.plates;
}

/**
 * A hit after Plated Back: never below 1 for a real hit. Kept exact (VG4: rounding left a termite's 8 at 8 through
 * step 3), so every step of armour takes something off every hit; health holds the fraction, the HUD rounds up.
 */
export function armoredDamage(damage: number, cut: number): number {
  if (damage <= 0) return 0;
  if (cut <= 0) return damage;
  return Math.max(1, damage * (1 - cut));
}

/** The nectar multiplier Sweet Tooth gives. */
export function nectarBonus(levels: ColonyLevels): number {
  return 1 + SWEET_STEP * levels.sweet;
}

/** The upgrades a run uses: the colony's own in a Colony run, none at all in Pure. */
export function levelsFor(ladder: Ladder, levels: ColonyLevels): ColonyLevels {
  return ladder === 'colony' ? levels : emptyLevels();
}

/** The card's plain line: what the next step changes, from the value now to the value after. */
export function upgradeLine(id: UpgradeId, base: Readonly<AntStats>, levels: ColonyLevels): string {
  const now = levels[id];
  const full = now >= upgradeSpec(id).max;
  const at = (k: number) => ({ ...levels, [id]: k });
  const pct = (x: number) => `${+(x * 100).toFixed(1)}%`;
  const show = (k: number): string => {
    const s = applyColony(base, at(k));
    switch (id) {
      case 'stinger':
        return String(s.damage);
      case 'diet':
        return String(s.maxHp);
      case 'plates':
        return pct(armorCut(at(k)));
      case 'legs':
        return `+${pct(LEGS_STEP * k)}`;
      case 'venom':
        return `+${pct(VENOM_STEP * k)}`;
      case 'sweet':
        return `+${pct(SWEET_STEP * k)}`;
    }
  };
  const label: Record<UpgradeId, string> = {
    stinger: 'Dart damage',
    diet: 'Max health',
    plates: 'Damage taken cut',
    legs: 'Move speed',
    venom: 'Fire rate',
    sweet: 'Nectar',
  };
  // Design note, 2026-10-24: a line at its maximum reads Max and sells nothing.
  return full ? `${label[id]} ${show(now)}, Max` : `${label[id]} ${show(now)} to ${show(now + 1)}`;
}

// Storage: the colony, the chosen ladder and a best round per ladder. Every touch is guarded, junk reads as nothing.
export const COLONY_KEY = 'antwars.colony.v1';
export const LADDER_KEY = 'antwars.ladder.v1';
/** Pure keeps the slice 1 key: every best round saved before the Colony was a Pure run. */
export const BEST_KEYS: Readonly<Record<Ladder, string>> = { pure: 'antwars.bestRound.v1', colony: 'antwars.bestRound.colony.v1' };

const isInt = (x: unknown, lo: number, hi: number): x is number => typeof x === 'number' && Number.isInteger(x) && x >= lo && x <= hi;

/**
 * The colony from its stored text; null when missing, not a record or another version (a fresh colony then). VG4: each
 * field reads on its own, so one bad field (a bank that is not a whole number, a level past its cap) takes its default
 * of 0 and every other upgrade is kept; a name it does not know is passed over.
 */
export function decodeColony(raw: string | null): ColonyState | null {
  if (raw === null) return null;
  let o: unknown;
  try {
    o = JSON.parse(raw);
  } catch {
    return null;
  }
  if (typeof o !== 'object' || o === null || Array.isArray(o)) return null;
  const r = o as Record<string, unknown>;
  if (r.v !== 1) return null;
  const bank = isInt(r.bank, 0, 1e12) ? r.bank : 0;
  const raws = typeof r.levels === 'object' && r.levels !== null && !Array.isArray(r.levels) ? (r.levels as Record<string, unknown>) : {};
  const levels = emptyLevels();
  for (const u of UPGRADES) {
    const n = raws[u.id];
    if (isInt(n, 0, u.max)) levels[u.id] = n;
  }
  return { bank, levels };
}

export function encodeColony(state: Readonly<ColonyState>): string {
  const levels = {} as Record<UpgradeId, number>;
  for (const id of UPGRADE_IDS) levels[id] = state.levels[id];
  return JSON.stringify({ v: 1, bank: state.bank, levels });
}

export function loadColony(store: KeyValueStore | null): ColonyState {
  if (!store) return emptyColony();
  try {
    return decodeColony(store.getItem(COLONY_KEY)) ?? emptyColony();
  } catch {
    return emptyColony();
  }
}

export function saveColony(store: KeyValueStore | null, state: Readonly<ColonyState>): boolean {
  if (!store) return false;
  try {
    store.setItem(COLONY_KEY, encodeColony(state));
    return true;
  } catch {
    return false;
  }
}

/** The ladder last chosen on the title; Colony when none was chosen or it cannot be read. */
export function loadLadder(store: KeyValueStore | null): Ladder {
  if (!store) return 'colony';
  try {
    const raw = store.getItem(LADDER_KEY);
    return isLadder(raw) ? raw : 'colony';
  } catch {
    return 'colony';
  }
}

export function saveLadder(store: KeyValueStore | null, ladder: Ladder): boolean {
  if (!store) return false;
  try {
    store.setItem(LADDER_KEY, ladder);
    return true;
  } catch {
    return false;
  }
}
