import { describe, expect, it } from 'vitest';
import { CAMPAIGN, CAMPAIGN_ACTS } from '../src/config/campaign';
import { ACT_HOME, HOME_LEVELS } from '../src/config/homecoming';
import { ACT_RAIN, RAIN_LEVELS } from '../src/config/rain';
import { ACT_WATER, LEVELS, levelStartSectionIn } from '../src/config/levels';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { ALL_ZONES } from '../src/config/zones';
import { mediumFor } from '../src/sim/Medium';
import { SECTION_SPACING } from '../src/sim/ObstacleSystem';
import { World } from '../src/sim/World';
import { motifForIn, motifsForAct } from '../src/render/Motif';
import { SEEDS, makeAimBot, mean, passive, playRun } from './bot';
import { buildCourse, sweepCourse } from './course';
import { H, W } from './helpers';

/**
 * Slowblue: the last two acts, and the campaign as a whole.
 *
 * Acts VI and VII are tested together because they are one movement - the water
 * coming back - and because the claims worth asserting about them are about the
 * *end* of the campaign rather than about either act on its own: the hazards
 * thin out and stop, the last stations cannot be lost, and the final frame is the
 * first frame.
 */

describe('the rain', () => {
  it('builds every authored section and nothing after them', () => {
    const o = buildCourse(ACT_RAIN);
    expect(o.sections.length).toBe(ACT_RAIN.totalSections);
    expect(o.scriptExhausted).toBe(true);
  });

  it('leaves a flyable corridor down the whole act', () => {
    expect(sweepCourse(buildCourse(ACT_RAIN)).blockedAt).toBeNull();
  });

  it('never asks for a ring it has walled off', () => {
    const sweep = sweepCourse(buildCourse(ACT_RAIN));
    expect(sweep.ringsReachable.length).toBeGreaterThan(10);
    for (const ring of sweep.ringsReachable) {
      expect(ring.ok, `level ${ring.level} section ${ring.section}`).toBe(true);
    }
  });

  /**
   * The act's medium arc, which is also its story: saturated air, then running
   * water. `stream` grips harder than the sea and forgets faster, because the
   * whole medium is already going somewhere and what the player adds is a nudge
   * on top of something much larger than the nudge.
   */
  it('turns cloud into running water, and running water grips hardest of all', () => {
    const kinds = RAIN_LEVELS.map((l) => l.medium);
    expect(kinds[0]).toBe('cloud');
    expect(kinds[kinds.length - 1]).toBe('stream');
    const cloud = mediumFor('cloud', DEFAULT_TUNING);
    const stream = mediumFor('stream', DEFAULT_TUNING);
    expect(stream.coupling).toBeGreaterThan(cloud.coupling);
    expect(stream.coupling).toBeGreaterThan(DEFAULT_TUNING.flowCoupling);
    expect(stream.flowHalfLife).toBeLessThan(DEFAULT_TUNING.flowDecayHalfLife);
    // Coming back together costs manoeuvrability, and it costs it more here than
    // anywhere: this is the act about gathering, so gathering has to weigh.
    expect(stream.inertiaPerAgent).toBeGreaterThan(DEFAULT_TUNING.inertiaPerAgent);
  });

  it('meets the anvil again from underneath, in the cloud it was flown in', () => {
    const under = RAIN_LEVELS.find((l) => l.key === 'underanvil')!;
    // Act II's own alphabet, because it is act II's own cloud.
    const CLOUD = new Set(['bank', 'tower', 'pass', 'wisps', 'rotor', 'open']);
    for (const s of under.sections) expect(CLOUD.has(s.kind), s.kind).toBe(true);
  });

  it('falls, carries droplets, and still restarts rather than ending', () => {
    const world = new World(W, H, 7, DEFAULT_TUNING, true, ACT_RAIN);
    expect(world.direction).toBe(1);
    expect(world.act.carrier).toBe('droplets');
    expect(world.act.failure.mode).toBe('restart');
  });
});

describe('the homecoming', () => {
  it('builds every authored section and nothing after them', () => {
    const o = buildCourse(ACT_HOME);
    expect(o.sections.length).toBe(ACT_HOME.totalSections);
    expect(o.scriptExhausted).toBe(true);
  });

  it('leaves a flyable corridor down the whole act', () => {
    expect(sweepCourse(buildCourse(ACT_HOME)).blockedAt).toBeNull();
  });

  it('never asks for a ring it has walled off', () => {
    const sweep = sweepCourse(buildCourse(ACT_HOME));
    for (const ring of sweep.ringsReachable) {
      expect(ring.ok, `level ${ring.level} section ${ring.section}`).toBe(true);
    }
  });

  /**
   * The design's plainest statement about the ending: **the second half of the act
   * cannot be lost.** Not a difficulty setting and nothing the player switched on -
   * the campaign declining to have an opinion any more, three stations from the end.
   */
  it('cannot be lost from the deep sea onward', () => {
    const modes = HOME_LEVELS.map((l) => l.failure ?? ACT_HOME.failure.mode);
    expect(modes.slice(0, 3).every((m) => m === 'restart')).toBe(true);
    expect(modes.slice(3).every((m) => m === 'none')).toBe(true);
  });

  it('reports that mode on the world, station by station', () => {
    const world = new World(W, H, 7, DEFAULT_TUNING, true, ACT_HOME);
    expect(world.failureMode).toBe('restart');
    // Jump the run to the deep sea and the campaign stops being able to take
    // anything away, which is what the player is never told.
    world.reset(7, levelStartSectionIn(ACT_HOME, 3));
    expect(world.failureMode).toBe('none');
  });

  /**
   * The hazards thin out and then stop. Act I ramped from one empty gate to two
   * hunters and a funnel; this runs the other way and ends on nothing at all.
   */
  it('empties itself out, station by station, to nothing', () => {
    const busy = HOME_LEVELS.map(
      (l) => l.sections.filter((s) => s.kind !== 'open').length,
    );
    // Not strictly monotone - the sunlit zone is the busiest and that is the
    // design - but the last three have to fall away and the last is empty.
    expect(busy[busy.length - 1]).toBe(0);
    expect(busy[busy.length - 2]!).toBeLessThan(busy[1]!);
    expect(busy[busy.length - 3]!).toBeLessThan(busy[1]!);
    // ...and the pace runs down into the floor, unbroken.
    const paces = HOME_LEVELS.map((l) => l.pace);
    for (let i = 1; i < paces.length; i++) {
      expect(paces[i]!, `station ${i}`).toBeLessThan(paces[i - 1]!);
    }
  });

  it('has no hunters anywhere: nothing hunts anything on the way home', () => {
    const o = buildCourse(ACT_HOME);
    for (const s of o.sections) expect(s.hunterHints.length, `section ${s.id}`).toBe(0);
  });

  it('cannot lose a run in its second half, however badly it is played', () => {
    // The deep sea, which is where the campaign stops judging. Read off the act
    // rather than written down: it was a literal 18 when act VII was thirty-six
    // sections long, and a section index that outlives the act it indexes into
    // does not fail loudly - it starts the run past the end and passes for the
    // wrong reason.
    const secondHalf = levelStartSectionIn(ACT_HOME, 3);
    for (const seed of SEEDS.slice(0, 5)) {
      const world = new World(W, H, seed, DEFAULT_TUNING, true, ACT_HOME);
      world.reset(seed, secondHalf);
      for (let i = 0; i < 200 * 60 && world.run.phase === 'running'; i++) world.step(1 / 60);
      // Never lost - and if a neglected run ended at all, it ended by *arriving*.
      //
      // That second clause used to be `phase !== 'over'`, which was a proxy that
      // only worked while the act was long enough that nothing could reach the
      // end of it inside the test's window. At eighteen sections a swarm nobody
      // touches drifts to the trench floor in about three minutes, and the
      // proxy started failing on the one outcome the design most wants: §11's
      // "the second half of the act cannot be lost" does not mean it cannot
      // finish. It means the campaign has stopped having an opinion.
      expect(world.run.reason, `seed ${seed}`).toBeNull();
      if (world.run.phase === 'over') expect(world.run.completed, `seed ${seed}`).toBe(true);
    }
  });

});

describe('the circle', () => {
  /**
   * Slowblue: what an act is *handed* may not raise the bar it then holds you to.
   *
   * The campaign carries the swarm between acts, so `startCount` is the previous
   * act's result rather than a constant, and two mechanisms keyed off it were
   * quietly pricing the player's own success. `failureThreshold` set act VII's
   * losing line at 38 for a player arriving with 96 and at 12 for one arriving
   * with 25 - the peak-keying `World.failureThreshold`'s own comment rejects,
   * laundered through an act boundary. And the streak's cohesion clause compared
   * spread against a flat 100 px, which is a *packing* number: a body of ninety-six
   * at a fixed separation is over it however well it is flown, so a well-played
   * campaign arrived at the last three acts with the x3.4 multiplier permanently
   * switched off. Measured before the fix, act VII's second half: best streak 1.9
   * for a bot that collected, 7.4 for one that did nothing.
   *
   * Asserted on the streak rather than on the score, and with one policy at two
   * populations, because that is the mechanism. A score comparison between two
   * different policies measures the bots.
   */
  it('does not charge a bigger swarm more for the same flying', () => {
    const streakAt = (population: number, seed: number): number => {
      const world = new World(W, H, seed, DEFAULT_TUNING, true, ACT_WATER);
      world.startPopulation = population;
      world.reset(seed);
      const bot = makeAimBot();
      for (let i = 0; i < 120 * 60 && world.run.phase === 'running'; i++) {
        bot(world, 1 / 60);
        world.step(1 / 60);
      }
      return world.run.bestStreak;
    };
    for (const seed of SEEDS.slice(0, 3)) {
      const small = streakAt(25, seed);
      const large = streakAt(96, seed);
      expect(large, `seed ${seed}: 96 carried scored streak ${large} against ${small} at 25`)
        .toBeGreaterThanOrEqual(small);
    }
  });

  /**
   * The campaign's one structural claim: it is not a climb, it is a circuit. That
   * is a statement about a list of numbers and can be checked rather than believed.
   */
  /**
   * Slowblue: how long the circuit is, as an assertion rather than as a note.
   *
   * An act's duration is its length over its forced drift and nothing else. That
   * made the campaign 107 minutes for a while, with acts running from 7.6 to
   * 21.1, and the reason was subtle enough to survive four commits: the five new
   * acts were authored to act I's *section count* at half act I's drift, so they
   * came out twice as long without anybody choosing that.
   *
   * The lever was the courses' length rather than their pace - act III's pace is
   * defended by §7 and act IV's by `tools/space.sweep.ts` - and 179 sections
   * became 104. What is asserted here is the consequence, because it is the kind
   * of fact that rots one added section at a time and nothing else would notice.
   *
   * The length used to be `sections * 845`, on the stated grounds that "every act
   * is authored to within a few per cent of the same section spacing". That was
   * true and it is the sentence this pass set out to stop being true: the acts
   * now have rhythms of their own, running from 320 px between two sections of a
   * gravity cluster to 1400 between two decisions in the upper air. So the length
   * is summed from the authored spacings, which is both the honest arithmetic and
   * the only version of this check that can still fail once an act is free to
   * redistribute its own minutes.
   */
  it('runs about ten minutes an act, and about an hour round', () => {
    /*
     * Each section at its own station's pace, and the act's first spacing dropped.
     *
     * Slowblue: this divided the act's summed length by the *unweighted mean* of its
     * six paces, which is only the same number when every station is the same
     * length - and the whole point of the per-act rhythms is that they are not.
     * Act III's stations run 2 700 to 3 120 px at paces 0.36 to 0.46, act V's 2 420
     * to 4 270 at 0.34 to 0.70, and a mean of the paces weights a 2 420 px station
     * exactly as heavily as a 4 270 px one. The two models disagree by up to 45
     * seconds an act.
     *
     * The act's own first spacing goes because it is never applied: every course
     * starts at `FIRST_SECTION_OFFSET`, so the number authored on script index 0 is
     * counted in the length and never walked.
     */
    const minutes = CAMPAIGN_ACTS.map((act) => {
      let seconds = 0;
      act.script.forEach((entry, i) => {
        if (i === 0) return;
        const px = entry.spec.spacing ?? SECTION_SPACING;
        seconds += px / (DEFAULT_TUNING.worldSpeed * act.levels[entry.level]!.pace);
      });
      return seconds / 60;
    });
    /*
     * Slowblue: the circuit has been rebuilt, and this is the only place that would
     * otherwise have called it a bug halfway through.
     *
     * "About ten minutes an act, and about an hour round" was the right rule for a
     * campaign whose problem nobody had measured yet. It was measured
     * (`docs/DESIGN-LENGTH.md`): the hour was not the fault, the *distribution*
     * was - acts I and II asked something every seventeen seconds and act IV every
     * fifty-five - and the answer was roughly twice the content at exactly the
     * same pace, six times over.
     *
     * **Act I is the exception and it is a deliberate one.** It is the metronome
     * the other six are heard against, its numbers are defended digit for digit,
     * and it is the act a player meets first with nothing learned yet. It stays at
     * ten minutes. So the branch below is not a migration record any more; it is
     * the standing shape of the campaign: one reference act and six long ones.
     */
    const METRONOME = new Set(['water']);
    for (let i = 0; i < minutes.length; i++) {
      const key = CAMPAIGN_ACTS[i]!.key;
      // 19..27 rather than one number, because the acts are not the same shape:
      // act IV is thin on purpose and act V carries the campaign's only threat
      // since act II. What the band forbids is an act that was left behind.
      const [floor, ceiling] = METRONOME.has(key) ? [7, 12] : [19, 27];
      expect(minutes[i]!, `${key} is too short`).toBeGreaterThan(floor);
      expect(minutes[i]!, `${key} is too long`).toBeLessThan(ceiling);
    }
    const total = minutes.reduce((a, b) => a + b, 0);
    /*
     * One act of ten and six of about twenty-two. The design memo asked for a
     * first circuit of two to two and a half hours *as played*, and authored
     * minutes are not played minutes: `World.pressure` adds up to 55 % to the
     * forced drift across a station, so a competent hand runs about three quarters
     * of the number below. 144 authored is roughly 108 real, which is the middle
     * of what was asked for.
     */
    expect(total, 'the circuit').toBeGreaterThan(130);
    expect(total, 'the circuit').toBeLessThan(165);
    /*
     * ...and no act is twice another. That ratio is what went wrong before, and it
     * is the shape of the failure rather than any one act's number.
     *
     * It used to sit at 1.57 with act II's 7.5 against act VII's 11.8, and act II
     * was the short one because it was the *densest* - 36 sections at 3.8
     * obstacles a minute - so the eight thousand pixels that would have made it
     * ten minutes were eight thousand pixels of empty crossing added to the act
     * with the least need of them. Rebuilt, it is 21.7 and it got there by adding
     * sections rather than distance.
     *
     * Measured across the six long acts, because act I is a reference rather than
     * a peer: comparing the metronome to the acts it is a metronome *for* would
     * measure the design rather than a defect.
     */
    const settled = minutes.filter((_, i) => !METRONOME.has(CAMPAIGN_ACTS[i]!.key));
    expect(Math.max(...settled) / Math.min(...settled)).toBeLessThan(1.5);
  });

  it('is seven acts, four up and three down', () => {
    expect(CAMPAIGN.length).toBe(7);
    expect(CAMPAIGN_ACTS.filter((a) => a.direction === -1).length).toBe(4);
    expect(CAMPAIGN_ACTS.filter((a) => a.direction === 1).length).toBe(3);
    // ...and every act is six stations, which the shell's numerals assume.
    for (const a of CAMPAIGN_ACTS) expect(a.levels.length, a.key).toBe(6);
  });

  it('gives every act its own carrier, and never repeats one', () => {
    const carriers = CAMPAIGN_ACTS.map((a) => a.carrier);
    expect(new Set(carriers).size).toBe(carriers.length);
  });

  /**
   * Consecutive acts have to agree at the seam. Act N's last station and act N+1's
   * first are the two halves of a handover, so the altitude must be continuous
   * through it - and the campaign's one turn is the only place the sign changes.
   */
  it('runs one continuous altitude through seven acts and turns exactly once', () => {
    const seam: { from: string; to: string; gap: number }[] = [];
    for (let i = 1; i < CAMPAIGN_ACTS.length; i++) {
      const prev = CAMPAIGN_ACTS[i - 1]!;
      const next = CAMPAIGN_ACTS[i]!;
      const last = prev.levels[prev.levels.length - 1]!;
      const first = next.levels[0]!;
      seam.push({ from: last.key, to: first.key, gap: first.depthMeters - last.depthMeters });
    }
    console.log('[campaign seams]', JSON.stringify(seam));
    // Climbing acts hand over going up (depth falling), falling acts going down.
    // Exactly one seam reverses, and it is the one after the Overview.
    const turns = seam.filter((s) => s.gap > 0);
    expect(turns.length).toBe(3);
    expect(seam[3]!.from).toBe('overview');

    // No seam may be a leap: the two halves of a handover are the same place.
    for (const s of seam) {
      expect(Math.abs(s.gap), `${s.from} -> ${s.to}`).toBeLessThan(120000);
    }
  });

  /**
   * The last frame of the campaign and the first frame of it are supposed to be
   * the same picture. The palettes are within a few values of each other, and the
   * motif is the same rock - same vertex count, same wander.
   */
  it('ends where it began, in the same water and on the same rock', () => {
    const first = ALL_ZONES[LEVELS[0]!.zone]!;
    const last = ALL_ZONES[HOME_LEVELS[HOME_LEVELS.length - 1]!.zone]!;
    // The background gradient is identical: this is the same trench.
    expect(last.palette.top).toBe(first.palette.top);
    expect(last.palette.mid).toBe(first.palette.mid);
    expect(last.palette.bottom).toBe(first.palette.bottom);
    // ...but what is in it is lit by what the player brought, so the swarm and
    // the specks are warm where act I's were cold.
    expect(last.palette.shoal).not.toBe(first.palette.shoal);

    const trenchThen = motifForIn('water', 0);
    const trenchNow = motifForIn('home', 5);
    expect(trenchNow.verts).toBe(trenchThen.verts);
    expect(trenchNow.jag).toBe(trenchThen.jag);
    expect(trenchNow.material).toBe(trenchThen.material);
    expect(trenchNow.fringe).toBe(trenchThen.fringe);
  });

  /**
   * The motif tables are positional - motif i dresses level i - and with seven
   * acts that is a fact nobody can hold in their head. `Motif.ts` asserts it under
   * DEV; this asserts it where the test runner will actually see it.
   */
  it('dresses every station of every act with its own motif', () => {
    for (const act of CAMPAIGN_ACTS) {
      const table = motifsForAct(act.key);
      expect(table.length, act.key).toBe(act.levels.length);
      for (let i = 0; i < act.levels.length; i++) {
        expect(table[i]!.key, `${act.key} motif ${i}`).toBe(act.levels[i]!.key);
      }
    }
  });

  /** Forty-two stations, and no two of them look alike. */
  it('gives all forty-two stations a backdrop of their own', () => {
    const kinds = CAMPAIGN_ACTS.flatMap((a) => motifsForAct(a.key).map((m) => m.backdrop));
    expect(kinds.length).toBe(42);
    expect(new Set(kinds).size).toBe(42);
  });

  /** Every zone index a station names has to exist, or it is painted in another act's colours. */
  it('paints every station from a palette that exists', () => {
    for (const act of CAMPAIGN_ACTS) {
      for (const level of act.levels) {
        expect(ALL_ZONES[level.zone], `${act.key}/${level.key}`).toBeDefined();
        expect(ALL_ZONES[level.zone]!.index).toBe(level.zone);
      }
    }
  });

  /**
   * The failure arc, as one table - and it is now one row wide.
   *
   * It used to run `end, end, restart, restart, restart, restart, restart` and was
   * asserted as "it only ever softens". The softening was real and the *start* of
   * it was an accident of build order: the two acts a player meets first, on a
   * phone, before they have learned anything, were the only two that could take
   * twenty minutes away for one mistake. Every act restarts the station now, and
   * the monotonicity check is kept because act VII's own stations still soften
   * below it.
   */
  it('costs a station in every act, and never more than that', () => {
    for (const act of CAMPAIGN_ACTS) {
      expect(act.failure.mode, act.key).toBe('restart');
      // One formula, one number, everywhere - not a per-act price.
      expect(act.failure.restartCost, act.key).toBe(1 / 6);
    }
    // ...and the arc, station by station, which is where the only softening left
    // in the campaign lives.
    const rank = { end: 2, restart: 1, none: 0 } as const;
    const stations = CAMPAIGN_ACTS.flatMap((a) =>
      a.levels.map((l) => rank[l.failure ?? a.failure.mode]),
    );
    for (let i = 1; i < stations.length; i++) {
      expect(stations[i]!, `station ${i}`).toBeLessThanOrEqual(stations[i - 1]!);
    }
    expect(stations[0]).toBe(rank.restart);
    expect(stations[stations.length - 1]).toBe(rank.none);
  });
});

describe('descent playability', () => {
  it('lets a competent player make real ground in both descending acts', () => {
    for (const act of [ACT_RAIN, ACT_HOME]) {
      const steered = SEEDS.map((s) =>
        playRun(s, makeAimBot({ strokeDt: 0.4 }), {}, 300, true, act),
      );
      const idle = SEEDS.map((s) => playRun(s, passive, {}, 300, true, act));
      const summary = {
        act: act.key,
        steered: Number(mean(steered.map((r) => r.progress)).toFixed(1)),
        passive: Number(mean(idle.map((r) => r.progress)).toFixed(1)),
        score: Math.round(mean(steered.map((r) => r.score))),
      };
      console.log('[descent playability]', JSON.stringify(summary));
      expect(summary.steered, act.key).toBeGreaterThan(summary.passive * 1.5 + 0.5);
    }
  });
});
