// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Lane N1, M2 (design note, 2026-10-29: a small see through tab shows the damage, the speed and the upgrades, so the
// player knows what the ant has and can plan what to get next): what the ant has right
// now, as typed rows for the HUD's stats tab. Every number comes through the builders the game uses for its own ant, in
// the order GameScene applies them (colony.ts applyColony on levelsFor, economy.ts runStats, growth.ts deriveBuild);
// nothing here retypes a step.
import { UPGRADES, applyColony, armorCut, emptyLevels, levelsFor, nectarBonus, type ColonyLevels, type Ladder, type UpgradeId } from './colony';
import { BASE_ANT, CRIT_MULTIPLIER, LINES, PERKS, capHit, fireIntervalSeconds, lineTotal, perkCount, runStats, stepText, type LineLevels, type PerkId } from './economy';
import { POWERS, deriveBuild, furyFactor, type Build, type PowerStacks } from './growth';

/** The run as the HUD reads it from the Yard's snapshot. */
export interface StatsInput {
  ladder: Ladder;
  /** The colony's steps as stored: a Colony run uses them, a Pure run (a Daily run too) none (colony.ts levelsFor). */
  colony: ColonyLevels;
  /** Nest perks bought this run, a perk once per buy. */
  owned: readonly PerkId[];
  lines: LineLevels;
  stacks: PowerStacks;
  hp: number;
}

export type StatGroup = 'stat' | 'power' | 'perk' | 'line' | 'colony';
export type UpgradeGroup = Exclude<StatGroup, 'stat'>;

export interface StatRow {
  group: StatGroup;
  /** The stat's key (damage, crit, rate, speed, health, taken) or the upgrade's own id. */
  id: string;
  label: string;
  value: string;
  /** A short second line; empty when there is nothing to add. */
  note: string;
  /** An upgrade's count (the power's stacks, the perk's or the line's buys, the colony's steps); a stat row has none. */
  count?: number;
}

/** The numbers behind the rows. */
export interface StatsNumbers {
  /** One dart, before a crit and before Fury Glands. */
  dart: number;
  /** What one shot lands on the predator it is aimed at: the side by side darts, each volley (as picks.test.ts reads it). */
  shot: number;
  darts: number;
  volleys: number;
  /** Darts a volley that fly off the aim in pairs (Fork Darts; GameScene fireVolley sends one each side a pair). */
  angled: number;
  /** Crit chance standing still; moving never crits. */
  crit: number;
  /** Shots a second standing still and moving. */
  rateStill: number;
  rateMoving: number;
  /** Speed as a share of the base ant's. */
  speed: number;
  hp: number;
  maxHp: number;
  /** The share of a hit Stone Stance takes off standing still, and Plated Back always. */
  block: number;
  armor: number;
  /** The most one hit can take (economy.ts capHit: a fifth of the max health). */
  hitCap: number;
  /** Fury Glands' factor at this health; 1 without it. */
  fury: number;
}

export interface StatsSheet {
  build: Build;
  numbers: StatsNumbers;
  rows: StatRow[];
}

/** The tab's headings for the upgrades, in the order it lists them. */
export const GROUP_TITLES: ReadonlyArray<readonly [UpgradeGroup, string]> = [
  ['power', 'POWERS'],
  ['perk', 'NEST PERKS'],
  ['line', 'SHOP THIS RUN'],
  ['colony', 'COLONY'],
];

/** A number as the tab writes it: at most `digits` decimals, no trailing zeros, thousands with commas. */
export function formatNumber(n: number, digits = 1): string {
  const v = Math.abs(n) < 0.5 * Math.pow(10, -digits) ? 0 : n;
  const [whole, frac = ''] = v.toFixed(digits).split('.');
  const neg = whole.startsWith('-');
  const grouped = (neg ? whole.slice(1) : whole).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  const tail = frac.replace(/0+$/, '');
  return `${neg ? '-' : ''}${grouped}${tail ? `.${tail}` : ''}`;
}

/** A share as a percent: 0.1333 is "13.3%". */
export function formatPercent(share: number, digits = 1): string {
  return `${formatNumber(share * 100, digits)}%`;
}

/** What one colony upgrade gives on its own at its level, read through the same builders. */
function colonyNote(id: UpgradeId, levels: ColonyLevels): string {
  const only: ColonyLevels = { ...emptyLevels(), [id]: levels[id] };
  const s = applyColony(BASE_ANT, only);
  switch (id) {
    case 'stinger':
      return `+${formatNumber(s.damage - BASE_ANT.damage)} dart damage`;
    case 'diet':
      return `+${formatNumber(s.maxHp - BASE_ANT.maxHp)} max health`;
    case 'plates':
      return `${formatPercent(armorCut(only))} less damage taken`;
    case 'legs':
      return `+${formatPercent(s.speed / BASE_ANT.speed - 1)} speed`;
    case 'venom':
      return `+${formatPercent(BASE_ANT.fireInterval / s.fireInterval - 1)} fire rate`;
    case 'sweet':
      return `+${formatPercent(nectarBonus(only) - 1)} nectar`;
  }
}

/**
 * The stats tab's sheet for the run as it stands: the six stat rows (damage, crit, fire rate, speed, health, damage
 * taken), then every upgrade owned with its count: the level up powers, the nest perks, the shop lines bought this run
 * with their total step, and the Colony's steps on a Colony run.
 */
export function statsSheet(input: Readonly<StatsInput>): StatsSheet {
  // The ant as GameScene builds it: the base ant with the run's colony steps (metaBase), then the nest's buys (runStats),
  // then the powers (deriveBuild).
  const levels = levelsFor(input.ladder, input.colony);
  const meta = applyColony(BASE_ANT, levels);
  const build = deriveBuild(runStats(meta, input.owned, input.lines), input.stacks);
  const n: StatsNumbers = {
    dart: build.damage,
    shot: build.darts * build.damage * build.volleys,
    darts: build.darts,
    volleys: build.volleys,
    angled: 2 * build.forkPairs,
    crit: build.critChance,
    rateStill: 1 / fireIntervalSeconds(build, false),
    rateMoving: 1 / fireIntervalSeconds(build, true),
    speed: build.speed / BASE_ANT.speed,
    hp: input.hp,
    maxHp: build.maxHp,
    block: build.block,
    armor: armorCut(levels),
    hitCap: capHit(Number.POSITIVE_INFINITY, build.maxHp),
    fury: build.fury ? furyFactor(input.hp, build.maxHp) : 1,
  };

  // Each note says only what the plain ant does not have, so a fresh run's tab stays short.
  const shotNotes: string[] = [];
  if (n.darts > 1) shotNotes.push(`${n.darts} darts a shot`);
  if (n.volleys > 1) shotNotes.push(`${n.volleys} volleys`);
  if (n.angled > 0) shotNotes.push(`+${n.angled} angled darts`);
  if (n.fury > 1) shotNotes.push(`Fury x${formatNumber(n.fury, 2)} now`);
  const speedNotes: string[] = [];
  const legs = meta.speed / BASE_ANT.speed - 1;
  if (legs > 0) speedNotes.push(`Long Legs +${formatPercent(legs)}`);
  // runStats reads the Speed line as a percent of the run's base ant.
  const bought = lineTotal('speed', input.lines.speed) / 100;
  if (bought > 0) speedNotes.push(`Speed buys +${formatPercent(bought)}`);
  const cuts: string[] = [];
  if (n.block > 0) cuts.push(`${formatPercent(n.block)} less standing still`);
  if (n.armor > 0) cuts.push(`${formatPercent(n.armor)} less always`);

  const rows: StatRow[] = [
    { group: 'stat', id: 'damage', label: 'Damage', value: `${formatNumber(n.dart)} a dart, ${formatNumber(n.shot)} a shot`, note: shotNotes.join(', ') },
    { group: 'stat', id: 'crit', label: 'Crit', value: `${formatPercent(n.crit)} standing still`, note: `x${CRIT_MULTIPLIER} damage, not while moving` },
    {
      group: 'stat',
      id: 'rate',
      label: 'Fire rate',
      value: `${formatNumber(n.rateStill, 2)} still, ${formatNumber(n.rateMoving, 2)} moving`,
      note: n.volleys > 1 ? `shots a second, ${n.volleys} volleys each` : 'shots a second',
    },
    { group: 'stat', id: 'speed', label: 'Speed', value: formatPercent(n.speed), note: speedNotes.join(', ') },
    { group: 'stat', id: 'health', label: 'Health', value: `${formatNumber(Math.ceil(n.hp), 0)} / ${formatNumber(n.maxHp, 0)}`, note: '' },
    { group: 'stat', id: 'taken', label: 'Damage taken', value: cuts.length > 0 ? cuts.join(', ') : 'full', note: `no hit takes more than ${formatNumber(n.hitCap, 0)}` },
  ];
  for (const p of POWERS) {
    const k = input.stacks[p.id] ?? 0;
    if (k > 0) rows.push({ group: 'power', id: p.id, label: p.name, value: p.max === null ? `x${k}` : `${k}/${p.max}`, note: p.line, count: k });
  }
  for (const p of PERKS) {
    const k = perkCount(input.owned, p.id);
    if (k > 0) rows.push({ group: 'perk', id: p.id, label: p.name, value: p.max > 1 ? `${k}/${p.max}` : 'owned', note: p.blurb, count: k });
  }
  for (const l of LINES) {
    const k = input.lines[l.id];
    if (k > 0) {
      // The card's own words for the total ("+28.5 damage"), its number kept: "Dart Damage +28.5 over 2 buys".
      rows.push({ group: 'line', id: l.id, label: l.name, value: stepText(l.id, lineTotal(l.id, k)).split(' ')[0], note: `over ${k} ${k === 1 ? 'buy' : 'buys'}`, count: k });
    }
  }
  for (const u of UPGRADES) {
    const k = levels[u.id];
    if (k > 0) rows.push({ group: 'colony', id: u.id, label: u.name, value: `${k}/${u.max}`, note: colonyNote(u.id, levels), count: k });
  }
  return { build, numbers: n, rows };
}

/**
 * One upgrade as the tab lists it: "Strong Jaw 3/5", "Honeydew x2", "Twin Stinger", "Thick Chitin 2/3", "Dart Damage
 * +28.5 over 2 buys", "Barbed Stinger 2/30" (a colony row keeps what it gives in its note; the nest screen shows it, and
 * a long run's list stays short); a stat row as its label and value.
 */
export function rowText(row: Readonly<StatRow>): string {
  switch (row.group) {
    case 'perk':
      return row.value === 'owned' ? row.label : `${row.label} ${row.value}`;
    case 'line':
      return `${row.label} ${row.value} ${row.note}`;
    default:
      return `${row.label} ${row.value}`;
  }
}
