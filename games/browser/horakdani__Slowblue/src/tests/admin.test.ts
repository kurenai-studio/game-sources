import { describe, expect, it } from 'vitest';
import type { AudioEngine } from '../src/audio/AudioEngine';
import { CAMPAIGN_ACTS } from '../src/config/campaign';
import { ACT_AIR } from '../src/config/ascent';
import { ACT_WATER, levelStartSectionIn } from '../src/config/levels';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { ENDING_SOUNDS } from '../src/debug/AdminPanel';
import { filmForAct } from '../src/render/Films';
import { ObstacleSystem } from '../src/sim/ObstacleSystem';
import { World } from '../src/sim/World';
import { H, W } from './helpers';

/**
 * Slowblue: the admin surface's one claim on the simulation.
 *
 * Everything the panel does to the game goes through a single number - the script
 * index the course starts building from - so this is what has to hold: a run
 * started at section N *is* the run that would have arrived at section N, in the
 * right station, the right medium and the right palette, with the section itself
 * as the first thing in the water. Nothing else about the world may notice.
 */
describe('starting a run mid-script', () => {
  it('opens on the section it was asked for, in both acts', () => {
    for (const act of [ACT_WATER, ACT_AIR]) {
      for (const start of [0, 3, 11, act.totalSections - 1]) {
        const o = new ObstacleSystem(W, 1, true, act);
        o.reset(W, 1, start);
        o.ensureAhead(-1e6);
        expect(o.sections[0]!.id).toBe(start);
        expect(o.sections[o.sections.length - 1]!.id).toBe(act.totalSections - 1);
        expect(o.scriptExhausted).toBe(true);
      }
    }
  });

  it('places the opening section exactly where section zero would have been', () => {
    const from0 = new ObstacleSystem(W, 1, true, ACT_WATER);
    from0.reset(W, 1, 0);
    from0.ensureAhead(-1e6);
    const from7 = new ObstacleSystem(W, 1, true, ACT_WATER);
    from7.reset(W, 1, 7);
    from7.ensureAhead(-1e6);
    expect(from7.sections[0]!.lineY).toBe(from0.sections[0]!.lineY);
  });

  it('lands the world on the right station, in the right medium', () => {
    const world = new World(W, H, 1, DEFAULT_TUNING, true, ACT_WATER);
    for (let level = 0; level < ACT_WATER.levels.length; level++) {
      world.reset(1, levelStartSectionIn(ACT_WATER, level));
      expect(world.levelIndex).toBe(level);
      expect(world.medium.kind).toBe('water');
      expect(world.zone).toBe(ACT_WATER.levels[level]!.zone);
    }
    // ...and the same world plays the other act once it is pointed at it. The
    // admin surface never builds a second World; the act is a property of this one.
    world.setAct(ACT_AIR);
    for (let level = 0; level < ACT_AIR.levels.length; level++) {
      world.reset(1, levelStartSectionIn(ACT_AIR, level));
      expect(world.levelIndex).toBe(level);
      expect(world.medium.kind).toBe('air');
      expect(world.zone).toBe(ACT_AIR.levels[level]!.zone);
    }
  });

  it('clamps a start index that is past the end, rather than building nothing', () => {
    const o = new ObstacleSystem(W, 1, true, ACT_WATER);
    o.reset(W, 1, 9999);
    o.ensureAhead(-1e6);
    expect(o.sections.length).toBe(1);
    expect(o.sections[0]!.id).toBe(ACT_WATER.totalSections - 1);
  });

  it('leaves the shipped entry point alone: a plain reset still starts at zero', () => {
    const world = new World(W, H, 1, DEFAULT_TUNING, true, ACT_WATER);
    world.reset(1, 7);
    world.reset(1);
    expect(world.startSection).toBe(0);
    expect(world.obstacles.sections[0]!.id).toBe(0);
    expect(world.levelIndex).toBe(0);
  });
});

/**
 * Slowblue: §16, and the corner of it that had quietly stopped being true.
 *
 * *Every new sound auditionable.* The panel exists because a sound on a Poisson
 * clock cannot be examined by playing the game - and an ending cue is the extreme
 * case of that: it fires **once per act**, at the end of it, and only if the act
 * was finished. Six of the seven had never been in the panel's list. Four of them
 * were written and shipped without anybody having heard them, which is the exact
 * failure the panel was built to make impossible.
 *
 * The list is hand-maintained, like the renderer's film table and unlike the act
 * switch, and that is the seam this covers. An eighth act with an ending nobody
 * can hear should fail here rather than a year later.
 */
describe('the ending cues', () => {
  /**
   * Fires every entry against a recorder rather than a real engine, so what is
   * asserted is which method the button actually calls - not that a button with
   * the right label exists. A row wired to the wrong cue is exactly the mistake a
   * label check cannot see.
   */
  function fired(): string[] {
    const calls: string[] = [];
    const recorder = new Proxy(
      {},
      {
        get: (_, name: string) => () => {
          calls.push(name);
        },
      },
    ) as AudioEngine;
    for (const s of ENDING_SOUNDS) s.play(recorder, 0);
    return calls;
  }

  it('has one for every act the campaign gives an ending to', () => {
    const filmed = CAMPAIGN_ACTS.filter((a) => filmForAct(a.key) !== null);
    expect(ENDING_SOUNDS.length).toBe(filmed.length);
  });

  it('fires a different cue from each row, in the order the circuit plays them', () => {
    expect(fired()).toEqual([
      'surface',
      'release',
      'airless',
      'overview',
      'nucleus',
      'estuary',
      'circle',
    ]);
  });

  /**
   * All seven are on `objectives`, and the panel's "some track is muted" warning
   * reads the ending list too - so a silent mixer says so rather than letting a
   * fourteen-second cue be judged as "it did not play".
   */
  it('declares the track that can silence it', () => {
    for (const s of ENDING_SOUNDS) expect([s.label, s.track]).toEqual([s.label, 'objectives']);
  });
});
