import { ACT_COUNT, CAMPAIGN, actIndexOf } from '../config/campaign';
import { readJson, removeKey, writeJson } from '../core/storage';
import { clamp } from '../core/math';
import { sanitizeCampaign, type CampaignState } from './Campaign';
import type { RunState } from '../sim/RunState';

const KEY = 'profile';
/**
 * Slowblue: storage version 3 - the circuit, station by station.
 *
 * Version 1 knew about one journey up: a best score, a best depth, and how many
 * of act I's six stations had ever been cleared. Version 2 has to remember a
 * seven-act circuit that can be put down and picked up, which act the player has
 * reached, and what the whole round trip was worth. Version 3 adds the one thing
 * neither of them could answer - *which* of the forty-two stations have been
 * cleared - because a screen that claims to show what is done and what is left
 * cannot be built out of a single "furthest act reached".
 *
 * **Nothing an older profile knew is thrown away.** `sanitizeProfile` is written
 * as an upgrade rather than a reset for a reason worth stating plainly: the
 * numbers in an old save are the record of somebody's actual play, and a release
 * that quietly deletes those is a release that has told its players their time did
 * not count. Unknown fields are ignored, missing ones take their empty value, and
 * anything that cannot be read is clamped rather than rejected.
 */
const VERSION = 3;

export interface Profile {
  version: number;
  bestScore: number;
  bestDepth: number;
  bestGates: number;
  bestShoal: number;
  deepestZone: number;
  /** Most authored levels cleared in one dive, and how often the last one fell. */
  bestLevel: number;
  completions: number;
  runs: number;
  totalRescued: number;
  totalReforms: number;
  totalSeconds: number;
  /** Which one-shot teaching lines the player has already been shown. */
  seenHints: string[];

  // --- v2: the seven-act campaign -----------------------------------------
  /**
   * Highest act index the player has ever reached, and therefore the last one
   * the act-select screen offers. Acts unlock by being arrived at, never by being
   * finished: a player who got most of the way through act IV and put the phone
   * down should not have to fly acts I to III again to see the rest of it.
   */
  unlockedAct: number;
  /** A campaign in progress, or null. Written at every act boundary. */
  saved: CampaignState | null;
  /** Best score for a complete circuit, and the life it came home with. */
  bestCampaign: number;
  bestCargo: number;
  /** Full circuits completed - trench floor to trench floor. */
  cycles: number;

  // --- v3: the circuit, station by station ---------------------------------
  /**
   * How many stations of each act have ever been cleared, by act key.
   *
   * A high-water mark rather than a log: it never falls, it is capped at the act's
   * own length, and it says nothing about *when*. That is exactly what the circuit
   * screen draws, and it is the least the game can store and still answer "what is
   * left" honestly. Keyed by act key rather than by index so that reordering the
   * campaign - which `config/campaign.ts` is explicitly allowed to do - moves a
   * player's record with the act instead of silently reassigning it to another one.
   */
  stations: Record<string, number>;
}

/** Every act at zero. The shape the record always has, whatever was stored. */
function emptyStations(): Record<string, number> {
  const out: Record<string, number> = {};
  for (const info of CAMPAIGN) out[info.act.key] = 0;
  return out;
}

export function emptyProfile(): Profile {
  return {
    version: VERSION,
    bestScore: 0,
    bestDepth: 0,
    bestGates: 0,
    bestShoal: 0,
    deepestZone: 0,
    bestLevel: 0,
    completions: 0,
    runs: 0,
    totalRescued: 0,
    totalReforms: 0,
    totalSeconds: 0,
    seenHints: [],
    unlockedAct: 0,
    saved: null,
    bestCampaign: 0,
    bestCargo: 0,
    cycles: 0,
    stations: emptyStations(),
  };
}

function num(v: unknown, fallback: number): number {
  return typeof v === 'number' && Number.isFinite(v) ? Math.max(0, Math.floor(v)) : fallback;
}

export function sanitizeProfile(input: unknown): Profile {
  const out = emptyProfile();
  if (typeof input !== 'object' || input === null) return out;
  const r = input as Record<string, unknown>;
  out.bestScore = num(r.bestScore, 0);
  out.bestDepth = num(r.bestDepth, 0);
  out.bestGates = num(r.bestGates, 0);
  out.bestShoal = num(r.bestShoal, 0);
  out.deepestZone = num(r.deepestZone, 0);
  out.bestLevel = num(r.bestLevel, 0);
  out.completions = num(r.completions, 0);
  out.runs = num(r.runs, 0);
  out.totalRescued = num(r.totalRescued, 0);
  out.totalReforms = num(r.totalReforms, 0);
  out.totalSeconds = num(r.totalSeconds, 0);
  if (Array.isArray(r.seenHints)) {
    out.seenHints = r.seenHints.filter((h): h is string => typeof h === 'string').slice(0, 32);
  }

  // --- v2 ------------------------------------------------------------------
  // A version 1 profile has none of these, and every one of them takes a value
  // that means "has played, has not started the campaign yet" rather than a value
  // that means "new player": the acts already cleared still show on the title
  // screen, and the first BEGIN opens a fresh circuit at act I, which is where a
  // version 1 player was anyway.
  out.unlockedAct = clamp(num(r.unlockedAct, 0), 0, ACT_COUNT - 1);
  out.bestCampaign = num(r.bestCampaign, 0);
  out.bestCargo = num(r.bestCargo, 0);
  out.cycles = num(r.cycles, 0);
  out.saved = r.saved === null || r.saved === undefined ? null : sanitizeCampaign(r.saved);

  // --- v3 ------------------------------------------------------------------
  out.stations = readStations(r.stations, out);
  out.version = VERSION;
  return out;
}

/**
 * The station record, read or - for a profile written before it existed - inferred.
 *
 * The inference is not a guess dressed up as data. `unlockedAct` can only ever be
 * raised by `CampaignController.advance`, which is the act *finishing*; act select
 * offers nothing above it and so can never push it further. So a version 2 profile
 * that names act V has genuinely completed acts I to IV, and saying so is a
 * statement about what the old field meant rather than an optimistic reading of
 * it. Everything at or above that act starts empty and fills in as it is played.
 *
 * Two special cases, both for the same reason - to hand back what the player
 * actually did rather than the least the format can prove:
 *
 *   - A closed circuit means every act was finished, so `cycles` above zero fills
 *     the whole record.
 *   - A version 1 profile never left act I, and `bestLevel` is precisely how many
 *     of its stations it cleared. That is the field's original meaning, and it is
 *     only safe to read it this way while `unlockedAct` is zero: from version 2 on
 *     it is a maximum across every act, and act V's six stations are not act I's.
 */
function readStations(input: unknown, p: Profile): Record<string, number> {
  const out = emptyStations();
  const stored =
    typeof input === 'object' && input !== null ? (input as Record<string, unknown>) : null;
  for (let i = 0; i < CAMPAIGN.length; i++) {
    const info = CAMPAIGN[i]!;
    const cap = info.act.levels.length;
    if (stored !== null) {
      out[info.act.key] = clamp(num(stored[info.act.key], 0), 0, cap);
    } else if (p.cycles > 0 || i < p.unlockedAct) {
      out[info.act.key] = cap;
    } else if (i === 0 && p.unlockedAct === 0) {
      out[info.act.key] = clamp(p.bestLevel, 0, cap);
    }
  }
  return out;
}

export interface RunResult {
  score: number;
  depth: number;
  gates: number;
  peakShoal: number;
  zone: number;
  rescued: number;
  reforms: number;
  seconds: number;
  /** Campaign: levels cleared, dashed rings held, and whether the dive finished. */
  levelsCleared: number;
  ringsHeld: number;
  completed: boolean;
}

export interface RecordDelta {
  score: boolean;
  depth: boolean;
  gates: boolean;
}

export function runResult(run: RunState, zone: number): RunResult {
  return {
    score: run.score,
    depth: Math.round(run.distance),
    gates: run.gates,
    peakShoal: run.peakCount,
    zone,
    rescued: run.rescued,
    reforms: run.reforms,
    seconds: run.time,
    levelsCleared: run.levelsCleared,
    ringsHeld: run.ringsHeld,
    completed: run.completed,
  };
}

/**
 * What is on the device, sanitised - the read `ProfileStore` does by default.
 *
 * Named rather than inlined so that a caller handed a profile from somewhere else
 * can still reach the one honest reading of the stored one, rather than growing a
 * second, slightly different idea of what a stored profile is.
 */
export function loadProfile(): Profile {
  return sanitizeProfile(readJson<unknown>(KEY, null));
}

/**
 * Slowblue: the only progression that exists.
 *
 * No unlocks, no currency, no levels to grind - the game is one continuous dive and
 * the meta layer's whole job is to remember how deep you got, so the next run has a
 * number to beat. Anything heavier would start competing with the water for attention.
 */
export class ProfileStore {
  profile: Profile;

  constructor(profile: Profile = loadProfile()) {
    this.profile = profile;
  }

  /** Folds a finished run in and reports which records it broke. */
  record(result: RunResult): RecordDelta {
    const p = this.profile;
    const delta: RecordDelta = {
      score: result.score > p.bestScore,
      depth: result.depth > p.bestDepth,
      gates: result.gates > p.bestGates,
    };
    p.bestScore = Math.max(p.bestScore, result.score);
    p.bestDepth = Math.max(p.bestDepth, result.depth);
    p.bestGates = Math.max(p.bestGates, result.gates);
    p.bestShoal = Math.max(p.bestShoal, result.peakShoal);
    p.deepestZone = Math.max(p.deepestZone, result.zone);
    p.bestLevel = Math.max(p.bestLevel, result.levelsCleared);
    if (result.completed) p.completions++;
    p.runs++;
    p.totalRescued += result.rescued;
    p.totalReforms += result.reforms;
    p.totalSeconds += Math.round(result.seconds);
    this.save();
    return delta;
  }

  /**
   * Remembers how far into one act the player has ever got.
   *
   * Called on every run the campaign actually flew, finished or not, because a
   * station cleared is cleared whatever happened in the one after it - four
   * stations of act V and then a swarm lost is four stations of act V. Takes the
   * furthest station rather than a count of clears, so an act that re-ran a
   * station cannot inflate its own record.
   */
  recordStations(actKey: string, reached: number): void {
    const at = actIndexOf(actKey);
    if (at < 0) return;
    const p = this.profile;
    const capped = clamp(Math.floor(reached), 0, CAMPAIGN[at]!.act.levels.length);
    if (capped <= (p.stations[actKey] ?? 0)) return;
    p.stations[actKey] = capped;
    this.save();
  }

  /**
   * Remembers where a campaign got to. Called at every **station** boundary and at
   * every act boundary, so "continue" always means the last station the player was
   * actually in rather than the last act they finished.
   *
   * Writing a whole profile six times an act instead of once is worth stating and
   * is not worth worrying about: it is one `JSON.stringify` of a few dozen numbers
   * against a station that takes minutes to fly, and the alternative - a partial
   * write - would be two sources of truth for one save.
   */
  saveCampaign(state: CampaignState): void {
    const p = this.profile;
    p.saved = { ...state, position: { ...state.position } };
    p.unlockedAct = Math.max(p.unlockedAct, state.position.act);
    this.save();
  }

  /** Forgets the campaign in progress. Unlocks are kept - they are a record. */
  clearCampaign(): void {
    this.profile.saved = null;
    this.save();
  }

  /**
   * Folds in a completed circuit. Separate from `record` because it is a
   * different achievement: `record` is about one act, this is about the round
   * trip, and a player can have an excellent act I inside a poor campaign.
   */
  recordCampaign(score: number, cargo: number): boolean {
    const p = this.profile;
    const best = score > p.bestCampaign;
    p.bestCampaign = Math.max(p.bestCampaign, score);
    p.bestCargo = Math.max(p.bestCargo, Math.round(cargo));
    p.cycles++;
    p.saved = null;
    this.save();
    return best;
  }

  hasSeen(hint: string): boolean {
    return this.profile.seenHints.includes(hint);
  }

  markSeen(hint: string): void {
    if (this.hasSeen(hint)) return;
    this.profile.seenHints.push(hint);
    this.save();
  }

  reset(): void {
    this.profile = emptyProfile();
    removeKey(KEY);
  }

  save(): void {
    writeJson(KEY, this.profile);
  }
}
