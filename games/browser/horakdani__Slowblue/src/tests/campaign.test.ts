import { describe, expect, it } from 'vitest';
import { LEVELS } from '../src/config/levels';
import { SEEDS, makeAimBot, mean, passive, playCampaign } from './bot';

/**
 * Slowblue: the campaign probe.
 *
 * `tests/levels.test.ts` proves the geometry has a line through it. This proves a
 * player can be *on* that line while the water is moving, the ocean is pushing and
 * the dashed rings are demanding to be held - which is a different claim, and the
 * only one that matters. A level that a competent stand-in player cannot clear is
 * not a hard level, it is a broken one.
 */
describe('campaign playability', () => {
  const competent = (): ReturnType<typeof makeAimBot> => makeAimBot({ strokeDt: 0.35 });

  it('lets a competent player clear the first level on every seed', () => {
    const runs = SEEDS.map((s) => playCampaign(s, competent(), 240));
    console.log(
      '[campaign level 1]',
      JSON.stringify(
        runs.map((r) => ({
          cleared: r.levelsCleared,
          rings: r.ringsHeld,
          reason: r.reason,
          seconds: r.seconds,
        })),
      ),
    );
    for (const r of runs) expect(r.levelsCleared, `reason ${r.reason}`).toBeGreaterThanOrEqual(1);
  });

  it('gets a competent player well past the first level', () => {
    const runs = SEEDS.map((s) => playCampaign(s, competent()));
    const cleared = mean(runs.map((r) => r.levelsCleared));
    const rings = mean(runs.map((r) => r.ringsHeld));
    console.log(
      '[campaign depth]',
      JSON.stringify({
        levelsCleared: Number(cleared.toFixed(2)),
        ringsHeld: Number(rings.toFixed(1)),
        reasons: runs.map((r) => r.reason),
        completed: runs.filter((r) => r.completed).length,
      }),
    );
    expect(cleared).toBeGreaterThan(1.5);
    expect(rings).toBeGreaterThan(3);
  });

  /**
   * A refused ring used to end the run and send the player back to the top of the
   * campaign. It now costs the station, exactly as it does in every other act -
   * see `sim/Failure.ts`. What has to stay true is that refusing one is still a
   * *failure*: the player who dodges every dashed ring must be stopped by that,
   * over and over, and must not get up the act on the strength of it.
   *
   * The measured counterpart is worth keeping: a bot that merely *ignores* rings
   * still collects most of them, because they sit on the line the section already
   * asks for. That is the design working, and it is why this test needs a bot that
   * actively dodges.
   */
  it('costs the station when a dashed ring is left behind, over and over', () => {
    const runs = SEEDS.map((s) =>
      playCampaign(s, makeAimBot({ strokeDt: 0.35, dodgeRings: true }), 120),
    );
    console.log(
      '[ring refused]',
      JSON.stringify(
        runs.map((r) => ({ reason: r.reason, s: r.seconds, rings: r.ringsHeld, re: r.restarts })),
      ),
    );
    for (const r of runs) {
      // The campaign is never lost, and the station is never got past.
      expect(r.reason).toBeNull();
      expect(r.restarts).toBeGreaterThan(0);
      expect(r.levelsCleared).toBe(0);
    }
  });

  it('does not end a passive run before the first ring is even reachable', () => {
    // The opening section is empty water with one wide ring in the middle of it:
    // failing it must take a while, so the first thing a new player meets is the
    // game teaching, not the game ending.
    for (const seed of SEEDS) {
      const r = playCampaign(seed, passive, 60);
      expect(r.seconds).toBeGreaterThan(4);
    }
  });

  it('keeps the campaign to a length a phone session can hold', () => {
    const sections = LEVELS.reduce((n, l) => n + l.sections.length, 0);
    expect(sections).toBeGreaterThan(30);
    expect(sections).toBeLessThan(60);
  });
});
