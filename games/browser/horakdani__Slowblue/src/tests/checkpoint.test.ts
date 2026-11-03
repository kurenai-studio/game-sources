import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { ACT_COUNT, CAMPAIGN, CAMPAIGN_ACTS, actAt } from '../src/config/campaign';
import { levelStartSectionIn, type Act } from '../src/config/levels';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { CampaignController, emptyCampaign, sanitizeCampaign } from '../src/meta/Campaign';
import { ProfileStore, sanitizeProfile } from '../src/meta/Profile';
import { resetStorageProbe } from '../src/core/storage';
import { RunState } from '../src/sim/RunState';
import {
  MAX_RESTARTS_PER_ACT,
  RESTART_ON_FAILURE,
  RESTARTS_PER_ACT,
  restartsForMinutes,
} from '../src/sim/Failure';
import { World } from '../src/sim/World';
import { MAIN_FACTION } from '../src/sim/Agent';
import { H, W } from './helpers';

/**
 * Slowblue: a cleared station stays cleared.
 *
 * The campaign used to write itself down once an act, which meant that anything
 * short of finishing an act - a lost swarm, a phone call, a browser tab reclaimed
 * in the background, a home button - handed the player back to the top of it.
 * Fifteen to twenty-five minutes, deleted by something that was very often not
 * even play.
 *
 * Three separate pieces answer that, and this file is where the three are held to
 * the same sentence:
 *
 *   1. `CampaignController.checkpoint` - the save, written at every station
 *      boundary, naming **the next station to start**.
 *   2. `sim/Failure.ts` - one failure rule for every act: the station begins
 *      again, never the act and never the circuit.
 *   3. The restore, which is a seed and a start section and nothing else - no
 *      swarm, no velocities, no simulation state, so no future physics change can
 *      break an existing save.
 *
 * The numbered cases in the spec this was written against are called out on the
 * tests that carry them.
 */

/** Minimal in-memory Storage, so a save and a reload are the real thing. */
class FakeStorage {
  map = new Map<string, string>();
  get length(): number {
    return this.map.size;
  }
  getItem(k: string): string | null {
    return this.map.get(k) ?? null;
  }
  setItem(k: string, v: string): void {
    this.map.set(k, v);
  }
  removeItem(k: string): void {
    this.map.delete(k);
  }
  clear(): void {
    this.map.clear();
  }
  key(i: number): string | null {
    return [...this.map.keys()][i] ?? null;
  }
}

function install(storage: FakeStorage | undefined): void {
  Object.defineProperty(globalThis, 'localStorage', {
    value: storage,
    configurable: true,
    writable: true,
  });
  resetStorageProbe();
}

beforeEach(() => install(new FakeStorage()));
afterEach(() => install(undefined));

function scored(score: number): RunState {
  const run = new RunState();
  run.score = score;
  return run;
}

/**
 * Where a run started from this save would open, worked out exactly the way
 * `main.ts` works it out in `startRun`.
 *
 * Kept as one function so the assertion below is about the *game's* arithmetic
 * rather than about a copy of it that could quietly drift: if `startRun` ever
 * stops resolving the station this way, these tests still pass and are still
 * wrong, and there is one place to look.
 */
function resumeSection(controller: CampaignController): number {
  return Math.max(0, levelStartSectionIn(controller.act, controller.stationIndex));
}

/** A world opened where a saved campaign says the next station begins. */
function openAt(controller: CampaignController, seed = 4242): World {
  const world = new World(W, H, seed, DEFAULT_TUNING, true, controller.act);
  world.reset(seed, resumeSection(controller));
  return world;
}

/** Everything the app would carry across a reload: written down, and read back. */
function reload(store: ProfileStore): CampaignController {
  const disk = JSON.parse(JSON.stringify(store.profile)) as unknown;
  return CampaignController.from(sanitizeProfile(disk).saved);
}

describe('station checkpoints', () => {
  /** Case 1. */
  it('opens a new campaign at the first station of act I', () => {
    const c = new CampaignController();
    expect(c.actIndex).toBe(0);
    expect(c.stationIndex).toBe(0);
    expect(resumeSection(c)).toBe(0);
    expect(openAt(c).levelIndex).toBe(0);
  });

  /** Case 2: clear station one, reload, and the *second* station starts. */
  it('resumes at the next station after one is cleared and the app reopens', () => {
    const store = new ProfileStore(sanitizeProfile(null));
    const c = new CampaignController();
    // The sim raises the banner for the station being entered, so the value that
    // reaches `checkpoint` is already the next one. This is the off-by-one.
    c.checkpoint(scored(640), 1, 27);
    store.saveCampaign(c.state);

    const resumed = reload(store);
    expect(resumed.actIndex).toBe(0);
    expect(resumed.stationIndex).toBe(1);
    expect(openAt(resumed).levelIndex).toBe(1);
    // ...and nothing about the station just cleared is asked for again.
    expect(resumed.stationIndex).not.toBe(0);
  });

  /**
   * Case 3: the interruption case, which is the one the whole feature is for.
   *
   * The player clears station one, gets most of the way through station two, and
   * the app stops - killed by the OS, a crash, a closed tab, a reload. There is no
   * `dirty` flag and nothing is punished: what is on disk is the last station
   * boundary, and that is where they come back.
   */
  it('resumes at the station in progress when the app is killed mid-station', () => {
    const store = new ProfileStore(sanitizeProfile(null));
    const c = new CampaignController();
    c.checkpoint(scored(640), 1, 27);
    store.saveCampaign(c.state);

    // Station two, half flown. Points are earned, ground is made, nothing is
    // written down - a station boundary is the only thing that writes.
    const live = openAt(c);
    for (let i = 0; i < 240; i++) live.step(1 / 60);
    // ...and then the process is gone. Nothing runs on the way out.

    const resumed = reload(store);
    expect(resumed.stationIndex).toBe(1);
    expect(openAt(resumed).levelIndex).toBe(1);
  });

  /** Case 6: an act finished puts the *next* act's first station on disk. */
  it('moves to the first station of the next act when one is finished', () => {
    const store = new ProfileStore(sanitizeProfile(null));
    const c = new CampaignController();
    c.checkpoint(scored(900), 4, 31);
    expect(c.advance(scored(2400), 33)).toBe(true);
    store.saveCampaign(c.state);

    const resumed = reload(store);
    expect(resumed.actIndex).toBe(1);
    expect(resumed.stationIndex).toBe(0);
    expect(openAt(resumed).levelIndex).toBe(0);
    expect(resumed.act.key).toBe(CAMPAIGN[1]!.act.key);
  });

  /** Every station of every act is a place the campaign can be restored to. */
  it('restores any station of any act from a seed and a section alone', () => {
    for (let act = 0; act < ACT_COUNT; act++) {
      const levels = actAt(act).levels.length;
      for (let station = 0; station < levels; station++) {
        const c = CampaignController.from({
          ...emptyCampaign(act),
          position: { act, level: station },
        });
        expect(c.stationIndex, `${c.act.key}/${station}`).toBe(station);
        expect(openAt(c).levelIndex, `${c.act.key}/${station}`).toBe(station);
      }
    }
  });

  /** Case 8: reading the same save twice cannot inflate a campaign. */
  it('does not duplicate points or cargo however often a save is read', () => {
    const store = new ProfileStore(sanitizeProfile(null));
    const c = new CampaignController();
    c.checkpoint(scored(640), 1, 27);
    store.saveCampaign(c.state);
    store.saveCampaign(c.state);
    store.saveCampaign(c.state);

    let seen = reload(store);
    for (let i = 0; i < 5; i++) {
      seen = reload(store);
      store.saveCampaign(seen.state);
    }
    expect(seen.state.banked).toBe(640);
    expect(seen.state.cargo).toBe(27);
    expect(seen.stationIndex).toBe(1);
  });

  /**
   * ...and the same guarantee inside one run, which is where it is actually hard.
   *
   * `RunState.score` is cumulative over a whole run, so a controller that banked
   * it at every boundary would bank station one's points six times over. Each
   * checkpoint contributes the difference and nothing else.
   */
  it('books each station’s points exactly once across an act', () => {
    const c = new CampaignController();
    const run = new RunState();
    const stations = [500, 1150, 1800, 2500, 3300];
    stations.forEach((score, i) => {
      run.score = score;
      c.checkpoint(run, i + 1, 30 + i);
    });
    expect(c.state.banked).toBe(3300);
    // A checkpoint that repeats a station adds nothing at all.
    c.checkpoint(run, 5, 34);
    expect(c.state.banked).toBe(3300);
    // ...and finishing the act folds in only what is left above the mark.
    run.score = 4100;
    c.advance(run, 34);
    expect(c.state.banked).toBe(4100);
  });

  /**
   * Case 9, the half of it the controller owns.
   *
   * `noteRestart` takes a sixth of the live score, so a run that fails just after
   * a checkpoint comes back with a `score` *below* the mark. Banking that
   * difference would un-bank a station already cleared; re-banking the climb back
   * up to the mark would pay for the same ground twice.
   */
  it('never un-banks a cleared station, and never pays for the same ground twice', () => {
    const c = new CampaignController();
    const run = new RunState();
    run.score = 1200;
    c.checkpoint(run, 2, 30);
    expect(c.state.banked).toBe(1200);

    // The station is lost and begins again: the live score is cut.
    run.earned = 900;
    run.noteRestart(RESTART_ON_FAILURE.restartCost);
    run.score = 1000;
    c.checkpoint(run, 2, 30);
    expect(c.state.banked).toBe(1200);

    // ...and clearing it at last pays only for what is above the mark.
    run.score = 1700;
    c.checkpoint(run, 3, 28);
    expect(c.state.banked).toBe(1700);
  });

  /** A resumed run starts its own books; the mark from the last one is not kept. */
  it('starts a resumed run from zero without losing what was banked', () => {
    const store = new ProfileStore(sanitizeProfile(null));
    const c = new CampaignController();
    c.checkpoint(scored(2000), 3, 40);
    store.saveCampaign(c.state);

    const resumed = reload(store);
    resumed.beginRun();
    expect(resumed.state.banked).toBe(2000);
    // The new run opens at zero and its first station is worth what it is worth.
    resumed.checkpoint(scored(700), 4, 38);
    expect(resumed.state.banked).toBe(2700);
  });

  /** Case 10: a save from before any of this existed still opens. */
  it('reads a save with no station, a zero station or a broken one', () => {
    const noLevel = sanitizeCampaign({ position: { act: 2 }, banked: 900, cargo: 40 });
    expect(noLevel.position.level).toBe(0);
    expect(noLevel.banked).toBe(900);

    const zero = sanitizeCampaign({ position: { act: 2, level: 0 }, cargo: 40 });
    expect(zero.position.level).toBe(0);

    // Out of range in both directions, and not a number at all.
    const past = sanitizeCampaign({ position: { act: 2, level: 999 } });
    expect(past.position.level).toBe(actAt(2).levels.length - 1);
    expect(sanitizeCampaign({ position: { act: 1, level: -4 } }).position.level).toBe(0);
    expect(sanitizeCampaign({ position: { act: 1, level: 'two' } }).position.level).toBe(0);
    expect(sanitizeCampaign({ position: { act: 99, level: 99 } }).position.act).toBe(ACT_COUNT - 1);

    // ...and a whole v2 profile, which is what a real one of these looks like.
    const old = sanitizeProfile({
      version: 2,
      unlockedAct: 3,
      saved: { position: { act: 3, level: 0 }, banked: 12400, cargo: 96, actsCleared: 3 },
    });
    const c = CampaignController.from(old.saved);
    expect(c.actIndex).toBe(3);
    expect(c.stationIndex).toBe(0);
    expect(c.state.banked).toBe(12400);
    expect(openAt(c).levelIndex).toBe(0);
  });

  /**
   * Case 7's data half: what the title screen prints is what actually starts.
   *
   * The label is built in `Shell.titleScreen` as `station + 1` of the act's
   * length, and `e2e/campaign.spec.ts` reads it off the real button. What can be
   * asserted here is the thing behind it - that the saved number names a station
   * that exists and is the one a run would open at.
   */
  it('names a station that exists, for every act', () => {
    for (let act = 0; act < ACT_COUNT; act++) {
      const levels = actAt(act).levels.length;
      const c = CampaignController.from({
        ...emptyCampaign(act),
        position: { act, level: levels - 1 },
      });
      const shown = Math.min(levels, c.stationIndex + 1);
      expect(shown).toBe(levels);
      expect(openAt(c).levelIndex).toBe(c.stationIndex);
    }
  });
});

/**
 * Slowblue: an act is one attempt.
 *
 * The station checkpoint makes the inside of an act recoverable from an
 * interruption. On its own that would also make an act grindable - six stations
 * retried independently, in any order, over any number of sittings, which is not
 * a journey flown. The attempt is what stops that, and these are the three things
 * it has to get right: what losing one costs, that losing one cannot *pay*, and
 * that an interruption is not one.
 */
describe('the act attempt', () => {
  it('gives back exactly what the act was entered with', () => {
    const c = new CampaignController();
    // Act I flown and finished: 1 200 points, 44 carried into act II.
    c.checkpoint(scored(800), 3, 40);
    c.advance(scored(1200), 44);
    expect(c.actIndex).toBe(1);

    // Act II, three stations in, one restart spent.
    c.checkpoint(scored(400), 1, 42);
    c.noteRestart();
    c.checkpoint(scored(950), 2, 39);
    expect(c.state.banked).toBe(2150);
    // The act's own budget less the one spent - act II carries three now that it
    // is 21.7 authored minutes. See `restartsForMinutes`.
    expect(c.attemptsLeft).toBe(actAt(1).restarts - 1);

    c.loseAct();
    expect(c.actIndex, 'still act II').toBe(1);
    expect(c.stationIndex).toBe(0);
    expect(c.state.banked, 'act I is untouched').toBe(1200);
    expect(c.state.cargo, 'the life act II was handed').toBe(44);
    expect(c.attemptsLeft, 'a fresh attempt').toBe(actAt(1).restarts);
  });

  /**
   * The arithmetic that makes the rollback compulsory rather than punitive.
   *
   * Without it a lost act would keep the points for stations the player is about
   * to fly again - so the *cheapest* way to a high score would be to clear five
   * stations, die on the sixth, and do it again. The rollback is what makes the
   * second attempt worth what the first was, and no more.
   */
  it('cannot be made profitable by losing it', () => {
    const c = new CampaignController();
    const cleanly = new CampaignController();

    // One clean run of act I: five stations and the act.
    for (let i = 1; i <= 5; i++) cleanly.checkpoint(scored(i * 500), i, 30);
    cleanly.advance(scored(3200), 30);

    // The same act, ground: five stations, lost, then flown clean.
    for (let i = 1; i <= 5; i++) c.checkpoint(scored(i * 500), i, 30);
    c.loseAct();
    c.beginRun();
    for (let i = 1; i <= 5; i++) c.checkpoint(scored(i * 500), i, 30);
    c.advance(scored(3200), 30);

    expect(c.state.banked).toBe(cleanly.state.banked);
    expect(c.state.cargo).toBe(cleanly.state.cargo);
    expect(c.actIndex).toBe(cleanly.actIndex);
  });

  /** An interruption is neither a penalty nor a refund. */
  it('survives a save and a reload without changing what is left', () => {
    const store = new ProfileStore(sanitizeProfile(null));
    const c = new CampaignController();
    c.checkpoint(scored(500), 2, 26);
    c.noteRestart();
    c.noteRestart();
    store.saveCampaign(c.state);
    expect(c.attemptsLeft).toBe(0);

    const resumed = reload(store);
    expect(resumed.attemptsLeft, 'no free lives for closing the app').toBe(0);
    expect(resumed.stationIndex).toBe(2);
    expect(resumed.state.banked).toBe(500);
  });

  /**
   * A save from before the attempt existed has no snapshot, and the only honest
   * reading of it is the state it is in: losing that act rolls back to where the
   * player is standing rather than to a beginning nobody wrote down.
   */
  it('reads a save with no attempt recorded as an act just entered', () => {
    const old = sanitizeCampaign({
      position: { act: 3, level: 2 },
      banked: 12400,
      cargo: 96,
      actsCleared: 3,
    });
    expect(old.actStart).toEqual({ cargo: 96, banked: 12400 });
    expect(old.restarts).toBe(0);

    const c = new CampaignController(old);
    expect(c.attemptsLeft).toBe(actAt(3).restarts);
    c.loseAct();
    expect(c.state.banked).toBe(12400);
    expect(c.state.cargo).toBe(96);
    expect(c.stationIndex).toBe(0);
  });

  /**
   * Slowblue: the budget stopped being a constant the day the acts stopped being the
   * same length.
   *
   * Two restarts was the smallest number that answered both ends of the argument
   * in `sim/Failure.ts`, and it was chosen when every act was about ten authored
   * minutes and a station about 1.7. Act V is 26.5 minutes now with stations of
   * 4.2 to 5.1 - so the budget *per minute of content* had quietly halved without
   * anybody deciding it should. A count that holds still while the thing it counts
   * doubles is an oversight with a constant in front of it.
   */
  it('gives a long act more attempts than a short one, off its own authored length', () => {
    expect(restartsForMinutes(7.5)).toBe(RESTARTS_PER_ACT);
    expect(restartsForMinutes(12)).toBe(RESTARTS_PER_ACT);
    // Twelve is the top of the band the unrebuilt acts sit in, so not one of them
    // moves by a single attempt until it is actually rebuilt.
    expect(restartsForMinutes(19)).toBe(3);
    expect(restartsForMinutes(26.5)).toBe(4);
    // ...and it stops, because a fifth would make a long act something to be
    // ground out, which is the failure two was chosen to prevent.
    expect(restartsForMinutes(80)).toBe(MAX_RESTARTS_PER_ACT);

    for (const info of CAMPAIGN) {
      const act = info.act;
      expect(act.restarts, `${act.key} budget`).toBeGreaterThanOrEqual(RESTARTS_PER_ACT);
      expect(act.restarts, `${act.key} budget`).toBeLessThanOrEqual(MAX_RESTARTS_PER_ACT);
    }
    /*
     * Act I is the only act still on the old budget, and that is the same
     * statement its length makes: it is the metronome, it is frozen at ten
     * authored minutes, and every other act in the campaign has been rebuilt to
     * about twenty-two. The pilot is the only one at the ceiling.
     */
    const short = CAMPAIGN.filter((a) => a.act.restarts === RESTARTS_PER_ACT).map((a) => a.act.key);
    expect(short).toEqual(['water']);
    // Everything else is one step up and nothing is at the ceiling: the rebuilt
    // acts land between 20.6 and 26.5 authored minutes, which is one bracket. The
    // cap is headroom rather than a number anything currently reaches, and that is
    // the right way round - a budget that was already maxed out could only ever
    // get more punishing as the acts grow.
    const most = CAMPAIGN.filter((a) => a.act.restarts === MAX_RESTARTS_PER_ACT);
    expect(most).toEqual([]);
  });

  /** ...and a snapshot that claims more than the campaign has is not believed. */
  it('refuses a snapshot that would pay the player for losing', () => {
    const edited = sanitizeCampaign({
      position: { act: 2, level: 1 },
      banked: 900,
      cargo: 30,
      actStart: { cargo: 900, banked: 99999 },
      restarts: 47,
    });
    expect(edited.actStart.banked).toBe(900);
    expect(edited.actStart.cargo).toBe(30);
    // Clamped to the largest budget *any* act can carry rather than to this act's,
    // because `sanitizeCampaign` runs before an act is resolved and a save is
    // allowed to name any of them. The controller then reads the act's own number,
    // which is why a save claiming forty-seven restarts still leaves nothing.
    expect(edited.restarts).toBe(MAX_RESTARTS_PER_ACT);
    expect(new CampaignController(edited).attemptsLeft).toBe(0);
  });
});

/**
 * Slowblue: one failure rule, and it reaches the water.
 *
 * `tests/descent.test.ts` asserts the table. This asserts the consequence, in the
 * simulation, for the two acts that used to be the exception - and then for every
 * act, so that the rule cannot quietly become true of six of them again.
 */
describe('the failure rule, in every act', () => {
  /** Runs the world until the swarm is gone and the world has noticed. */
  function loseTheSwarm(world: World): void {
    for (const a of world.swarm.agents) if (a.faction === MAIN_FACTION) a.alive = false;
    for (let i = 0; i < 8; i++) world.step(1 / 60);
  }

  /**
   * An act opened at a station, with the campaign's own restart budget on it.
   *
   * The budget is stated here rather than assumed, because `World.restartBudget`
   * is deliberately unbounded until something sets it - it is a campaign rule, not
   * a fact about water, and the headless probes are fixed-time instruments that
   * must not have their runs ended out from under them. `main.ts` sets it at
   * `startRun`; this is that call, in one line, so these tests are measuring the
   * shipped rule rather than a default.
   */
  function openAct(act: Act, station: number, budget = RESTARTS_PER_ACT): World {
    const world = new World(W, H, 31337, DEFAULT_TUNING, true, act);
    world.restartBudget = budget;
    world.reset(31337, Math.max(0, levelStartSectionIn(act, station)));
    return world;
  }

  /** Cases 4 and 5: a death costs the station it happened in. Every act. */
  it('puts the station back rather than ending the run', () => {
    for (const act of CAMPAIGN_ACTS) {
      const station = 1;
      const world = openAct(act, station);
      expect(world.levelIndex, act.key).toBe(station);
      expect(world.failureMode, act.key).toBe('restart');

      loseTheSwarm(world);

      expect(world.run.phase, `${act.key} keeps running`).toBe('running');
      expect(world.run.restarts, `${act.key} restarted`).toBe(1);
      // The station it went wrong in, not the act it is in.
      expect(world.levelIndex, `${act.key} stayed put`).toBe(station);
      expect(world.shoalCount, `${act.key} respawned`).toBeGreaterThan(0);
      expect(world.run.reason, act.key).toBeNull();
    }
  });

  /**
   * ...twice, and then it does not.
   *
   * The count is what keeps an act one performance rather than six separately
   * ground-out ones. It has to bite in every act and it has to bite at the same
   * place in all of them, or "an act is one attempt" is a claim about some acts.
   */
  it('ends the run on the third failure, in every act', () => {
    for (const act of CAMPAIGN_ACTS) {
      const world = openAct(act, 1);
      expect(world.restartsLeft, act.key).toBe(RESTARTS_PER_ACT);

      for (let i = 0; i < RESTARTS_PER_ACT; i++) {
        loseTheSwarm(world);
        expect(world.run.phase, `${act.key} failure ${i + 1}`).toBe('running');
      }
      expect(world.restartsLeft, act.key).toBe(0);

      // One more, and the attempt is over rather than the station.
      loseTheSwarm(world);
      expect(world.run.phase, `${act.key} spent its budget`).toBe('over');
      expect(world.run.reason, act.key).not.toBeNull();
      expect(world.run.restarts, act.key).toBe(RESTARTS_PER_ACT);
    }
  });

  /** ...and the budget is the act attempt's, not the run's. */
  it('does not hand back a restart to a run that resumed from a save', () => {
    const store = new ProfileStore(sanitizeProfile(null));
    const c = new CampaignController();
    c.checkpoint(scored(640), 1, 27);
    c.noteRestart();
    store.saveCampaign(c.state);
    expect(c.attemptsLeft).toBe(RESTARTS_PER_ACT - 1);

    // Killed here, reopened later. The station survives and so does the spending.
    const resumed = reload(store);
    expect(resumed.stationIndex).toBe(1);
    expect(resumed.attemptsLeft).toBe(RESTARTS_PER_ACT - 1);

    const world = openAt(resumed);
    world.restartBudget = resumed.attemptsLeft;
    world.reset(world.seed, resumeSection(resumed));
    expect(world.restartsLeft).toBe(RESTARTS_PER_ACT - 1);
  });

  /** Case 9: the retry price is one formula, one number, charged once. */
  it('charges the restart exactly once, at the same rate everywhere', () => {
    for (const act of CAMPAIGN_ACTS) {
      const world = openAct(act, 1);
      world.run.earned = 600;

      loseTheSwarm(world);

      expect(world.run.restarts, act.key).toBe(1);
      // 1/6 of the live score, once. Not twice, and not a per-act rate.
      expect(world.run.earned, act.key).toBe(500);
      expect(act.failure.restartCost, act.key).toBe(RESTART_ON_FAILURE.restartCost);
    }
  });

  /**
   * The one place the rule stops, and it is the end of it rather than an exception
   * to it: act VII's last stations have no failure state to unify. Making them
   * losable so the table reads evenly would end the campaign on a threat.
   */
  it('leaves the last water in the campaign alone', () => {
    const home = CAMPAIGN_ACTS[ACT_COUNT - 1]!;
    const world = openAct(home, home.levels.length - 1);
    expect(world.failureMode).toBe('none');

    loseTheSwarm(world);

    expect(world.run.phase).toBe('running');
    expect(world.run.restarts).toBe(0);
  });

  /** No act may state its own price. There is one, and it is in `sim/Failure.ts`. */
  it('states the rule in exactly one place', () => {
    const policies = new Set<unknown>(CAMPAIGN_ACTS.map((a: Act) => a.failure));
    expect(policies.size).toBe(1);
    expect([...policies][0]).toBe(RESTART_ON_FAILURE);
  });
});
