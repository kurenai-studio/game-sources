import { describe, expect, it } from 'vitest';
import { ACT_COUNT, CAMPAIGN, CAMPAIGN_ACTS } from '../src/config/campaign';
import { CampaignController, carrierPopulation, emptyCampaign } from '../src/meta/Campaign';
import { ProfileStore, emptyProfile, sanitizeProfile } from '../src/meta/Profile';
import { stationsCleared } from '../src/meta/Circuit';
import { MAX_AGENTS } from '../src/sim/SwarmSimulation';
import { RunState } from '../src/sim/RunState';

/**
 * Slowblue: seven acts as one game.
 *
 * `CampaignController` is headless on purpose - it owns no world and starts
 * nothing - so what is asserted here is the three facts that have to survive the
 * gap between two acts: where you are, what you are carrying, and what it has
 * been worth. `main.ts` is the only thing that turns those into a run.
 */

function finished(score: number): RunState {
  const run = new RunState();
  run.score = score;
  return run;
}

describe('the circuit', () => {
  it('walks all seven acts in order and then closes', () => {
    const c = new CampaignController();
    const seen: string[] = [];
    for (let i = 0; i < ACT_COUNT; i++) {
      seen.push(c.act.key);
      const more = c.advance(finished(100), 40);
      expect(more, `after ${seen[seen.length - 1]}`).toBe(i < ACT_COUNT - 1);
    }
    expect(seen).toEqual(CAMPAIGN_ACTS.map((a) => a.key));
    expect(c.state.completed).toBe(true);
    expect(c.state.actsCleared).toBe(ACT_COUNT);
  });

  it('banks one score for the whole journey', () => {
    const c = new CampaignController();
    c.advance(finished(1200), 30);
    c.advance(finished(800), 44);
    expect(c.state.banked).toBe(2000);
    // ...and the live act is added on top without being banked twice.
    expect(c.total(350)).toBe(2350);
  });

  /**
   * The only mechanical statement the campaign makes of its own premise: the gold
   * does not restart. What an act ends with is what the next one opens with, which
   * is why an optional ring in act I is still worth something in act VI.
   */
  it('carries the life across every act boundary', () => {
    const c = new CampaignController();
    expect(c.population(25)).toBe(25);
    c.advance(finished(0), 61);
    expect(c.state.cargo).toBe(61);
    expect(c.population(25)).toBe(61);
    c.advance(finished(0), 88);
    expect(c.population(25)).toBe(88);
  });

  it('never asks the simulation for more agents than it can draw', () => {
    for (const cargo of [0, 40, 300, 5000]) {
      const pop = carrierPopulation(cargo);
      expect(pop).toBeLessThanOrEqual(MAX_AGENTS);
      expect(pop).toBeGreaterThanOrEqual(18);
    }
    // ...and the truth is kept even when the drawn population is clamped.
    const c = new CampaignController();
    c.advance(finished(0), 400);
    expect(c.state.cargo).toBe(400);
    expect(c.population(25)).toBeLessThan(400);
  });

  /**
   * A lost act costs the act, never the circuit.
   *
   * The campaign goes back to exactly what the act was entered with - first
   * station, entry cargo, entry score - so the act is flown again from a standing
   * start. Everything before it is untouched: the acts already cleared, their
   * score, and the position in the circuit.
   */
  it('loses the act rather than the circuit', () => {
    const c = new CampaignController();
    c.advance(finished(500), 40);
    const wasAt = c.actIndex;
    // Two stations of the new act, cleared and banked.
    c.checkpoint(finished(300), 1, 44);
    c.checkpoint(finished(700), 2, 47);
    expect(c.state.banked).toBe(1200);

    c.loseAct();
    expect(c.actIndex).toBe(wasAt);
    expect(c.state.position.level).toBe(0);
    // Back to what the act was entered with, and nothing of the act survives it:
    // the stations are about to be re-flown, and paying for them twice is exactly
    // what would make dying profitable.
    expect(c.state.banked).toBe(500);
    expect(c.state.cargo).toBe(40);
    expect(c.state.actsCleared).toBe(1);
  });

  it('survives a save and a reload at every act boundary', () => {
    const store = new ProfileStore();
    store.reset();
    const c = new CampaignController();
    c.advance(finished(700), 52);
    store.saveCampaign(c.state);

    const resumed = CampaignController.from(store.profile.saved);
    expect(resumed.actIndex).toBe(c.actIndex);
    expect(resumed.state.cargo).toBe(52);
    expect(resumed.state.banked).toBe(700);
    // Arriving at an act is what unlocks it, so a player who put the phone down
    // does not have to fly the acts below it again.
    expect(store.profile.unlockedAct).toBe(c.actIndex);
    store.reset();
  });

  it('resumes safely from a save that names an act that no longer exists', () => {
    const stale = { ...emptyCampaign(), position: { act: 99, level: 40 }, cargo: 12 };
    const c = CampaignController.from(stale);
    expect(c.actIndex).toBe(ACT_COUNT - 1);
    expect(c.state.position.level).toBeLessThan(c.act.levels.length);
    // ...and from outright junk.
    expect(CampaignController.from(null).actIndex).toBe(0);
    expect(CampaignController.from('nonsense').actIndex).toBe(0);
  });

  it('records a closed circuit separately from a single act', () => {
    const store = new ProfileStore();
    store.reset();
    const before = store.profile.cycles;
    expect(store.recordCampaign(9000, 120)).toBe(true);
    expect(store.profile.cycles).toBe(before + 1);
    expect(store.profile.bestCampaign).toBe(9000);
    expect(store.profile.bestCargo).toBe(120);
    // A closed circuit clears the resume point: there is nothing to continue.
    expect(store.profile.saved).toBeNull();
    store.reset();
  });

  it('reports progress through the circuit, not through an act', () => {
    const c = new CampaignController();
    expect(c.progress).toBe(0);
    for (let i = 0; i < ACT_COUNT - 1; i++) c.advance(finished(0), 30);
    expect(c.progress).toBe(1);
  });
});

/**
 * Slowblue: the station record, which is the only thing the map is drawn from.
 *
 * `unlockedAct` answers "where has this player been" and nothing answers "what
 * have they finished" - which is the question a screen showing what is done and
 * what is left is entirely made of. It is a high-water mark per act, and the two
 * things it has to get right are that it never overstates and that it never
 * throws away what an older save already proved.
 */
describe('the station record', () => {
  const cap = (act: number): number => CAMPAIGN[act]!.act.levels.length;

  it('takes the furthest station reached, never a count of clears', () => {
    const store = new ProfileStore(emptyProfile());
    store.recordStations('air', 3);
    expect(store.profile.stations.air).toBe(3);
    // An act III station that was retried and re-cleared is not new ground.
    store.recordStations('air', 2);
    expect(store.profile.stations.air).toBe(3);
    store.recordStations('air', 5);
    expect(store.profile.stations.air).toBe(5);
    // Nothing may claim more stations than the act has, and an act that is not
    // in the campaign is not written at all.
    store.recordStations('air', 99);
    expect(store.profile.stations.air).toBe(cap(1));
    store.recordStations('nowhere', 4);
    expect(store.profile.stations.nowhere).toBeUndefined();
    store.reset();
    expect(store.profile.stations.air).toBe(0);
  });

  /**
   * The migration, and why it is an inference rather than a reset.
   *
   * `unlockedAct` can only ever be raised by `advance` - the act *finishing* -
   * because act select offers nothing above it. So a version 2 profile that names
   * act V is a profile that finished four acts, and saying so is reading the old
   * field's meaning rather than being generous with it.
   */
  it('reads a version 2 profile as the acts it must have finished', () => {
    const v2 = sanitizeProfile({ version: 2, unlockedAct: 4, bestLevel: 6, runs: 30 });
    expect(v2.stations[CAMPAIGN[0]!.act.key]).toBe(cap(0));
    expect(v2.stations[CAMPAIGN[3]!.act.key]).toBe(cap(3));
    // The act they are *in* starts empty: arriving is not finishing.
    expect(v2.stations[CAMPAIGN[4]!.act.key]).toBe(0);
    expect(v2.stations[CAMPAIGN[6]!.act.key]).toBe(0);
    expect(v2.runs).toBe(30);
  });

  it('reads a closed circuit as every act finished', () => {
    const round = sanitizeProfile({ version: 2, unlockedAct: 6, cycles: 1 });
    for (let act = 0; act < ACT_COUNT; act++) {
      expect(round.stations[CAMPAIGN[act]!.act.key], `act ${act + 1}`).toBe(cap(act));
    }
  });

  /**
   * A version 1 profile never left act I, and `bestLevel` is exactly how many of
   * its stations it cleared. That reading is only safe while `unlockedAct` is
   * zero: from version 2 on the field is a maximum across every act, and act V's
   * six stations are not act I's.
   */
  it('reads a version 1 profile as the act I stations it actually cleared', () => {
    const v1 = sanitizeProfile({ bestScore: 4200, bestLevel: 4 });
    expect(v1.stations[CAMPAIGN[0]!.act.key]).toBe(4);
    expect(v1.stations[CAMPAIGN[1]!.act.key]).toBe(0);
    expect(v1.bestScore).toBe(4200);
  });

  it('refuses a record that has been edited, corrupted or outgrown', () => {
    const p = sanitizeProfile({
      version: 3,
      stations: { water: 99, air: -2, thin: 'six', orbit: 2.9, nowhere: 5 },
    });
    expect(p.stations[CAMPAIGN[0]!.act.key]).toBe(cap(0));
    expect(p.stations[CAMPAIGN[1]!.act.key]).toBe(0);
    expect(p.stations[CAMPAIGN[2]!.act.key]).toBe(0);
    expect(p.stations[CAMPAIGN[3]!.act.key]).toBe(2);
    expect('nowhere' in p.stations).toBe(false);
    // A stored record, however broken, is still a record: it is not read as a
    // version 2 profile and re-inferred from `unlockedAct`.
    expect(stationsCleared(p.stations)).toBe(cap(0) + 2);
  });
});
