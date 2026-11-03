import { BREACH_RANK, CAMPAIGNS, SUPPRESSOR_RANK, type CampaignDef } from '../levels/campaigns';
import type { WeaponId } from './weapons';

/**
 * Campaign progress: rank, best stars per level and which levels are done. Saved in the
 * browser; storage can be unavailable (private windows, blocked site data), so reads and writes
 * fall back gracefully and the game still plays.
 */
export interface Progress {
  rank: number;
  stars: Record<string, number>;
  completed: string[];
  /** Realism mode: one life. Going down ends the career and progress resets to Recruit. */
  realism: boolean;
  /**
   * The mission a realism career is currently deployed on. Set on deploy, cleared when the
   * mission ends; still set on the next load means the tab was closed mid-mission.
   */
  deployed: string | null;
}

export function newProgress(realism = false): Progress {
  return { rank: 0, stars: {}, completed: [], realism, deployed: null };
}

/** Summary of a career that just ended, for the screen that says so. */
export interface CareerRecord {
  rank: number;
  stars: number;
  /** Where it ended. */
  levelId: string;
}

/** Ends a realism career: everything resets to Recruit, still in realism mode. */
export function endCareer(p: Progress, levelId: string): CareerRecord {
  const record: CareerRecord = { rank: p.rank, stars: Object.values(p.stars).reduce((a, b) => a + b, 0), levelId };
  Object.assign(p, newProgress(true));
  return record;
}

/**
 * Called on load: a realism career that was still deployed was abandoned by closing the game
 * mid-mission, which counts as going down. Returns the ended career, if any.
 */
export function settleAbandonedMission(p: Progress): CareerRecord | null {
  if (!p.realism || !p.deployed) return null;
  return endCareer(p, p.deployed);
}

export function isUnlocked(p: Progress, levelId: string, campaigns: readonly CampaignDef[] = CAMPAIGNS): boolean {
  const c = campaigns.find((x) => x.levels.includes(levelId));
  if (!c || p.rank < c.rank) return false;
  const i = c.levels.indexOf(levelId);
  return i === 0 || p.completed.includes(c.levels[i - 1]);
}

export function campaignStars(p: Progress, c: CampaignDef): number {
  return c.levels.reduce((sum, id) => sum + (p.stars[id] ?? 0), 0);
}

/** The pistol is always carried; promotions issue the rest. */
export function unlockedWeapons(p: Progress, campaigns: readonly CampaignDef[] = CAMPAIGNS): WeaponId[] {
  const guns: WeaponId[] = ['pistol'];
  for (const c of campaigns) if (p.rank > c.rank && c.promotion.unlocks) guns.push(c.promotion.unlocks);
  return guns;
}

/** Suppressors are issued with promotion to Lieutenant. */
export function hasSuppressors(p: Progress): boolean {
  return p.rank >= SUPPRESSOR_RANK;
}

/** The breach charge is issued with promotion to Captain. */
export function hasBreachCharge(p: Progress): boolean {
  return p.rank >= BREACH_RANK;
}

/**
 * Records a successful run (keeping the best stars). Returns the campaign whose promotion this
 * just earned: every level completed, enough stars, and still at that campaign's rank.
 */
export function recordSuccess(
  p: Progress,
  levelId: string,
  stars: number,
  campaigns: readonly CampaignDef[] = CAMPAIGNS,
): CampaignDef | null {
  p.deployed = null;
  p.stars[levelId] = Math.max(p.stars[levelId] ?? 0, stars);
  if (!p.completed.includes(levelId)) p.completed.push(levelId);
  const c = campaigns.find((x) => x.levels.includes(levelId));
  if (!c || p.rank !== c.rank) return null;
  const allDone = c.levels.every((id) => p.completed.includes(id));
  if (!allDone || campaignStars(p, c) < c.promotion.minStars) return null;
  p.rank = c.rank + 1;
  return c;
}

/**
 * Each career mode has its own save, so switching between a normal and a realism career never
 * touches the other one.
 */
export type CareerMode = 'normal' | 'realism';
const KEYS: Record<CareerMode, string> = { normal: 'breach.progress.normal', realism: 'breach.progress.realism' };
/** The single save used before careers were split; moved into its matching career on load. */
const LEGACY_KEY = 'breach.progress';

function read(key: string): Partial<Progress> | null {
  try {
    const raw = localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as Partial<Progress>) : null;
  } catch {
    return null;
  }
}

export function loadCareer(mode: CareerMode): Progress {
  const realism = mode === 'realism';
  return { ...newProgress(realism), ...(read(KEYS[mode]) ?? {}), realism };
}

export function saveProgress(p: Progress): void {
  try {
    localStorage.setItem(KEYS[p.realism ? 'realism' : 'normal'], JSON.stringify(p));
  } catch {
    // Not persisted this session; progress still applies until the tab closes.
  }
}

function migrateLegacySave(): void {
  const legacy = read(LEGACY_KEY);
  if (!legacy) return;
  const mode: CareerMode = legacy.realism ? 'realism' : 'normal';
  try {
    if (!localStorage.getItem(KEYS[mode])) saveProgress({ ...newProgress(!!legacy.realism), ...legacy });
    localStorage.removeItem(LEGACY_KEY);
  } catch {
    // Storage unavailable: nothing to migrate.
  }
}

migrateLegacySave();

/**
 * The realism career that most recently ended and why, for the menu to report once. Loading can
 * set it straight away: a realism career abandoned by closing the game mid-mission ends here.
 */
export const endedCareer: { record: CareerRecord | null; reason: 'down' | 'quit' | 'left' } = (() => {
  const realism = loadCareer('realism');
  const record = settleAbandonedMission(realism);
  if (record) saveProgress(realism);
  return { record, reason: 'left' };
})();

/** The career being played. The start menu chooses it; it begins as the normal career. */
export const progress: Progress = loadCareer('normal');

/** Makes `mode` the active career (saving the current one first). */
export function switchCareer(mode: CareerMode): void {
  saveProgress(progress);
  Object.assign(progress, loadCareer(mode));
}
