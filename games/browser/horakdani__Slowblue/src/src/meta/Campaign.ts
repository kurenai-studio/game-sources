import { ACT_COUNT, actAt } from '../config/campaign';
import type { Act } from '../config/levels';
import { clamp } from '../core/math';
import { MAX_AGENTS } from '../sim/SwarmSimulation';
import { MAX_RESTARTS_PER_ACT } from '../sim/Failure';
import type { RunState } from '../sim/RunState';

/**
 * Slowblue: the thing that makes seven acts one game.
 *
 * Each act is already a complete, self-contained run: a world, a course, a score
 * and an ending. What this adds is the only three facts that have to survive the
 * gap between them.
 *
 *   1. **Where you are.** An act index and a station index, saved at every
 *      *station* boundary, so a campaign can be put down on a phone and picked up
 *      a week later. It used to be saved only at act boundaries, and the reason
 *      given was a good one for a limit that was drawn in the wrong place: a
 *      checkpoint in the *middle* of a station would mean restoring a swarm's
 *      positions and velocities, which is a savegame of a *simulation*, and the
 *      first thing that would do is make every future physics change break every
 *      existing save.
 *
 *      That argument is about mid-station snapshots and it is untouched. A station
 *      *boundary* is not a snapshot: it is an act index, a station index, a
 *      headcount and a number of points, and the station it names is rebuilt from
 *      its own first section by the same code that starts any run. Nothing about
 *      the simulation is stored, so nothing about the simulation can go stale.
 *
 *      Drawing the line at the act instead cost the thing the whole feature is
 *      for. An act is fifteen to twenty-five minutes; a phone call, a browser tab
 *      reclaimed in the background, or a home button is enough to take all of it,
 *      and the player is handed back a save that says "you were in act V" and
 *      makes them fly it from the top. Five stations already cleared, deleted by
 *      something that was not a mistake and was not even play.
 *
 *      So the campaign now checkpoints at every station it clears, and the saved
 *      value is always **the next station to start** rather than the last one
 *      finished - the save is a place to resume, not a receipt.
 *
 *      A checkpoint is not a life. An act is still one attempt: two station
 *      restarts, and the third failure ends it and puts the campaign back to
 *      `actStart` - the first station, the entry cargo, the entry score. What the
 *      checkpoint buys is that an *interruption* is not a failure. Losing the act
 *      is something the player did; a phone call is not.
 *   2. **What you are carrying.** The gold does not restart. The count the player
 *      finished an act with is what the next one opens with - which is the only
 *      mechanical statement the campaign makes of its own premise, and it is why
 *      an optional ring in act I is still worth something in act VI.
 *   3. **What it has been worth.** One score across the whole circuit, banked act
 *      by act, so the number on the final screen is the number for the journey.
 *
 * ## Population scaling, and why the two numbers differ
 *
 * `cargo` is the truth and can run to several hundred. `population` is how many
 * agents are actually simulated, and it is clamped, because `MAX_AGENTS` is a
 * performance ceiling this game has held since the prototype and a phone that
 * drops frames is a phone that cannot be steered. Past the ceiling one drawn
 * individual stands for several carried ones (`carryScale`), the HUD keeps
 * showing the true figure, and the simulation keeps its budget. The alternative -
 * quietly deleting the life the player spent six acts collecting - is the one
 * thing the campaign is not allowed to do.
 */

/** Fewest agents an act ever opens with. Below this a swarm is not a swarm. */
export const MIN_CARRIER = 18;
/**
 * ...and the most. Well under `MAX_AGENTS`, because rescue pods spawn into the
 * same pool during a run and a campaign that arrives at the ceiling on frame one
 * would silently stop being able to hand the player anything.
 */
export const MAX_CARRIER = 96;

/** Where a campaign is. Saved; must stay plain data. */
export interface CampaignPosition {
  /** Index into `CAMPAIGN`. */
  act: number;
  /**
   * Station inside that act, and always **the next one to start** - never the
   * last one cleared. A save written the other way round is a save that replays
   * a station the player has already finished, every time.
   *
   * Zero is therefore both "a fresh act" and what every save written before
   * station checkpoints existed says, which is exactly the right reading of them:
   * those saves resumed their act from the top and they still do.
   */
  level: number;
}

export interface CampaignState {
  position: CampaignPosition;
  /**
   * Points banked at stations already cleared this cycle - in earlier acts and in
   * this one. Folded in exactly once each, whatever happens afterwards; see
   * `bank`.
   */
  banked: number;
  /** True carried life. See the note above. */
  cargo: number;
  /** How many acts of this cycle have been finished. */
  actsCleared: number;
  /** True once the circuit has closed and act VII has handed back to the title. */
  completed: boolean;

  /**
   * What the current act was entered with, and therefore what losing it costs.
   *
   * An act is one attempt. Station checkpoints make the *inside* of that attempt
   * recoverable from an interruption, and this is what makes it still an attempt:
   * when the attempt is lost, the campaign goes back to exactly this - the same
   * carried life, the same banked score, the first station - and the act is flown
   * again from a standing start.
   *
   * It has to be stored rather than recomputed. `banked` grows station by station
   * and `cargo` is overwritten at every checkpoint, so by the third station of an
   * act there is nothing left in the state that remembers what entering it looked
   * like. Without this, losing an act would either keep the points for stations
   * about to be re-flown - which pays for the same ground twice, and makes dying
   * *profitable* - or need a full history of the act to unwind.
   */
  actStart: { cargo: number; banked: number };
  /**
   * Station restarts already spent in this act attempt.
   *
   * Deliberately in the campaign rather than in `RunState`: the budget belongs to
   * the attempt, and an attempt can span any number of runs once an interruption
   * can happen in the middle of one. Kept in the run, closing the app and
   * reopening it would hand back a full budget, and the whole point of the station
   * checkpoint is that an interruption is worth *nothing* - neither a penalty nor
   * a refund.
   */
  restarts: number;
}

/** Agents actually simulated for a given carried mass. */
export function carrierPopulation(cargo: number): number {
  return clamp(Math.round(cargo), MIN_CARRIER, Math.min(MAX_CARRIER, MAX_AGENTS));
}

/** How many carried individuals one drawn individual stands for. Usually 1. */
export function carryScale(cargo: number): number {
  const pop = carrierPopulation(cargo);
  return pop > 0 ? Math.max(1, cargo / pop) : 1;
}

export function emptyCampaign(startAct = 0): CampaignState {
  return {
    position: { act: clamp(Math.round(startAct), 0, ACT_COUNT - 1), level: 0 },
    banked: 0,
    cargo: 0,
    actsCleared: 0,
    completed: false,
    actStart: { cargo: 0, banked: 0 },
    restarts: 0,
  };
}

/**
 * Slowblue: the campaign, as a state machine with four transitions.
 *
 * Deliberately headless and deliberately dumb - it owns no world, starts no run
 * and reads no clock. `main.ts` asks it what to play, plays it, and hands back
 * what happened. That split is what lets the act-select screen, the admin
 * surface, the continuous-cycle mode and a resumed save all be the same three
 * calls in a different order, and it is what makes the whole thing testable
 * without a canvas.
 */
export class CampaignController {
  state: CampaignState;

  /**
   * How much of the *live run's* score has already been folded into `banked`.
   *
   * The one number that makes "points are booked exactly once" true rather than
   * hopeful. `RunState.score` is cumulative over a whole run, so a controller that
   * banked it at every station boundary would bank station one's points six times
   * over by the end of the act. This is the high-water mark those boundaries are
   * measured against: each checkpoint contributes the *difference*, and a second
   * checkpoint at the same score contributes nothing.
   *
   * It belongs to the run rather than to the campaign, so it is deliberately not
   * saved and is cleared by `beginRun`. A resumed campaign opens a fresh
   * `RunState` at zero, and a mark left over from the run that wrote the save
   * would make the first station of the new one look like a loss.
   */
  private credited = 0;

  constructor(state: CampaignState = emptyCampaign()) {
    this.state = state;
  }

  get actIndex(): number {
    return this.state.position.act;
  }

  /** Station the next run should open at. Always the next one to play. */
  get stationIndex(): number {
    return clamp(this.state.position.level, 0, Math.max(0, this.act.levels.length - 1));
  }

  get act(): Act {
    return actAt(this.state.position.act);
  }

  /** True while there is another act after this one. */
  get hasNext(): boolean {
    return this.state.position.act < ACT_COUNT - 1;
  }

  /** 0..1 through the whole circuit, by act. Drives the campaign screen's rail. */
  get progress(): number {
    return ACT_COUNT <= 1 ? 1 : this.state.position.act / (ACT_COUNT - 1);
  }

  /**
   * How many agents the next run should open with.
   *
   * Act I opens on the tuned shoal size, because act I *is* the start - there is
   * nothing to have carried. Everything after it opens on what arrived.
   */
  population(fallback: number): number {
    if (this.state.cargo <= 0) return fallback;
    return carrierPopulation(this.state.cargo);
  }

  /**
   * Restarts left in this act attempt. Drives the HUD and the sim's budget.
   *
   * The budget is the *act's*, not the campaign's: it comes off `Act.restarts`,
   * which is derived from how long the act actually is - see `restartsForMinutes`.
   * A flat two was right while every act was ten minutes and stopped being right
   * the day one of them became twenty-six.
   */
  get attemptsLeft(): number {
    return Math.max(0, this.act.restarts - Math.max(0, Math.round(this.state.restarts)));
  }

  /** Starts a fresh circuit at an act. Used by BEGIN and by the act-select screen. */
  begin(actIndex = 0, cargo = 0): void {
    this.state = emptyCampaign(actIndex);
    this.state.cargo = Math.max(0, Math.round(cargo));
    this.openAct();
    this.credited = 0;
  }

  /**
   * An act begins: take the snapshot losing it will restore, and hand back the
   * full restart budget.
   *
   * One private method for the three ways into an act - a fresh circuit, the seam
   * after the act before it, and the act being flown again after it was lost - so
   * that "what does entering an act mean" is answered in one place and cannot come
   * to mean three slightly different things.
   */
  private openAct(): void {
    this.state.actStart = { cargo: this.state.cargo, banked: this.state.banked };
    this.state.restarts = 0;
  }

  /**
   * A run is about to start from the saved position. Clears the run-local mark.
   *
   * Called by whoever starts the water, immediately before it starts. Everything
   * the *campaign* knows survives; only the accounting for the run that just
   * ended - or was interrupted, or never happened - is let go.
   */
  beginRun(): void {
    this.credited = 0;
  }

  /**
   * A station was cleared. Records where the next one starts, what is being
   * carried into it, and what the ground so far was worth.
   *
   * This is the whole of the checkpoint, and it is deliberately three plain
   * numbers: `station` is the *next* station to play, `carried` is the live
   * headcount, and the score comes out of `bank` below. Nothing about the
   * simulation is touched or stored.
   *
   * Idempotent by construction. Called twice for the same station with the same
   * run it writes the same position, the same cargo and no extra points, so a
   * repeated save - or a save the player triggers again by reloading - can never
   * inflate a campaign.
   */
  checkpoint(run: RunState, station: number, carried: number): void {
    const last = Math.max(0, this.act.levels.length - 1);
    this.state.position = {
      act: this.state.position.act,
      level: clamp(Math.round(station), 0, last),
    };
    this.state.cargo = Math.max(0, Math.round(carried));
    this.bank(run);
  }

  /**
   * Folds the run's unbanked score into the campaign. Exactly once, ever.
   *
   * The delta guard is not defensive tidiness, it is the only thing standing
   * between a station restart and free points: `RunState.noteRestart` takes a
   * sixth of the live score away, so a run that fails just after a checkpoint
   * comes back with a `score` *below* the mark. Banking that difference would
   * un-bank a station the player has already cleared; re-banking the climb back up
   * to the mark would pay for the same ground twice. Neither happens - the mark
   * only ever goes up, and only the ground above it is ever paid for.
   */
  private bank(run: RunState): void {
    const delta = run.score - this.credited;
    if (delta <= 0) return;
    this.state.banked += delta;
    this.credited = run.score;
  }

  /**
   * Folds a finished act in and moves to the next one. Returns false when that
   * was the last act, which is the campaign completing rather than an error.
   *
   * `carried` is what the act ended with. It is taken as given - the acts
   * themselves decide what survives them, and act VII in particular is designed
   * so that almost everything does.
   */
  advance(run: RunState, carried: number): boolean {
    this.bank(run);
    this.state.cargo = Math.max(0, Math.round(carried));
    this.state.actsCleared++;
    // The act's books are closed. Whatever run opens next starts its own.
    this.credited = 0;
    if (!this.hasNext) {
      this.state.completed = true;
      return false;
    }
    this.state.position = { act: this.state.position.act + 1, level: 0 };
    this.openAct();
    return true;
  }

  /**
   * A station was put back. Spends one of the attempt's restarts.
   *
   * Counted from the sim's own `restart` event rather than predicted, so the
   * number the campaign saves is the number of restarts that actually happened -
   * and so a crash immediately after one cannot refund it.
   */
  noteRestart(): void {
    this.state.restarts = Math.max(0, Math.round(this.state.restarts)) + 1;
  }

  /**
   * The act attempt is over. Puts the campaign back exactly as the act was
   * entered: first station, entry cargo, entry score, full budget.
   *
   * This is the whole of "an act is one performance". Everything the attempt
   * earned goes with it - which is not a punishment bolted on, it is the only
   * arithmetic that works: the stations are about to be flown again, and points
   * banked for ground the player is going to re-cover would be paid for twice.
   *
   * The circuit is untouched. A lost act costs the act.
   */
  loseAct(): void {
    this.state.cargo = this.state.actStart.cargo;
    this.state.banked = this.state.actStart.banked;
    this.state.position = { act: this.actIndex, level: 0 };
    this.state.restarts = 0;
    this.credited = 0;
  }

  /** Total campaign score: everything banked plus whatever the live act is worth. */
  total(live: number): number {
    return this.state.banked + live;
  }

  /** Rebuilds a controller from a (possibly stale, possibly hostile) saved blob. */
  static from(input: unknown): CampaignController {
    return new CampaignController(sanitizeCampaign(input));
  }
}

function int(v: unknown, fallback: number): number {
  return typeof v === 'number' && Number.isFinite(v) ? Math.max(0, Math.floor(v)) : fallback;
}

/**
 * A saved campaign, made safe.
 *
 * Acts can be added, renamed and reordered between builds, so a saved position
 * is clamped rather than trusted - a save that names act nine resumes at the last
 * act that exists instead of throwing, and one that names a station past the end
 * of its act starts that act at the top.
 *
 * Every save written before station checkpoints existed has `level: 0` or no
 * `level` at all, and both read as the first station - which is precisely what
 * those saves meant. Nothing has to be migrated and nothing has to be thrown
 * away: an old campaign resumes at the top of the act it was put down in, exactly
 * as it always did, and starts checkpointing per station from its next cleared
 * one.
 */
export function sanitizeCampaign(input: unknown): CampaignState {
  const out = emptyCampaign();
  if (typeof input !== 'object' || input === null) return out;
  const r = input as Record<string, unknown>;
  const pos = (typeof r.position === 'object' && r.position !== null ? r.position : {}) as Record<
    string,
    unknown
  >;
  const act = clamp(int(pos.act, 0), 0, ACT_COUNT - 1);
  const levels = actAt(act).levels.length;
  out.position = { act, level: clamp(int(pos.level, 0), 0, Math.max(0, levels - 1)) };
  out.banked = int(r.banked, 0);
  out.cargo = int(r.cargo, 0);
  out.actsCleared = clamp(int(r.actsCleared, 0), 0, ACT_COUNT);
  out.completed = r.completed === true;
  /*
   * The act-entry snapshot, or this act read as if it had just been entered.
   *
   * A save written before the snapshot existed has no `actStart`, and the honest
   * reading of it is *the state it is in*: losing that act rolls back to where the
   * player is standing rather than to a beginning nobody recorded. That is the
   * generous direction, and it is the only one available - the information to be
   * strict with is not in the file.
   *
   * It is also clamped against `banked` and `cargo`, because an `actStart` above
   * either of them would mean losing an act *awarded* points, and a save can be
   * edited by hand as easily as it can be old.
   */
  const snap = (
    typeof r.actStart === 'object' && r.actStart !== null ? r.actStart : {}
  ) as Record<string, unknown>;
  out.actStart = {
    cargo: clamp(int(snap.cargo, out.cargo), 0, out.cargo),
    banked: clamp(int(snap.banked, out.banked), 0, out.banked),
  };
  // Clamped to the largest budget any act can have rather than to one act's, because
  // this runs before the act is known and a save is allowed to name any of them.
  out.restarts = clamp(int(r.restarts, 0), 0, MAX_RESTARTS_PER_ACT);
  return out;
}
