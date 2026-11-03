import { describe, expect, it } from 'vitest';
import { LEVELS, makeAct, type Level } from '../src/config/levels';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { MAIN_FACTION } from '../src/sim/Agent';
import { END_ON_FAILURE } from '../src/sim/Failure';
import { World } from '../src/sim/World';
import { H, W } from './helpers';

/**
 * Slowblue: the course runs both ways, and this is what proves it.
 *
 * Three acts of the campaign fall rather than climb, and the failure mode of
 * getting that wrong is not a visible bug - it is a course that deletes itself in
 * front of the player, or a section that can never be cleared, on one act, in one
 * direction, silently. So the spine is tested against a *mirror*: act I's own
 * levels, played downward. Same authored content, same numbers, opposite sign.
 *
 * If the direction abstraction is right, the mirrored act behaves exactly as the
 * original does - it builds course ahead of the camera, credits sections as they
 * are crossed, prunes what is behind, and strands a swarm that falls off the
 * back. If any one of `World.u`, `anchorFraction`, `behindFraction`,
 * `behindLine`, `buildLine` or `Section.entryY` has a sign wrong, at least one of
 * these fails.
 */

/** Act I's stations, played downward. Deliberately the same objects. */
const DESCENDING_LEVELS: Level[] = LEVELS.map((l) => ({ ...l }));
/**
 * `END_ON_FAILURE` is named here and nowhere else in the campaign, and it is what
 * makes the strand test below a test of the *sign* rather than of the save system.
 *
 * Every real act restarts the station it went wrong in (`sim/Failure.ts`), which
 * is a fine thing for a player and a useless one for this file: a mirror that
 * fails to notice a stranded swarm and a mirror that notices and quietly puts the
 * station back look identical from outside - both keep running. Ending is the one
 * outcome the mirror cannot produce by accident.
 */
const ACT_DOWN = makeAct('mirror', DESCENDING_LEVELS, {
  direction: 1,
  failure: END_ON_FAILURE,
});

function run(world: World, seconds: number, drive = true): void {
  const dt = 1 / 60;
  for (let i = 0; i < seconds * 60 && world.run.phase === 'running'; i++) {
    if (drive) {
      const c = world.swarm.centroid(MAIN_FACTION);
      // One stroke a tenth of a second, straight along the course. The point is
      // the bookkeeping, not the steering, so the policy is as dumb as it can be.
      if (i % 6 === 0 && c.count > 0) {
        world.injectStroke(c.x, c.y, c.x, c.y + world.direction * 90, 0.35);
      }
    }
    world.step(dt);
  }
}

describe('course direction', () => {
  it('reports the direction it was built with', () => {
    expect(new World(W, H, 5).direction).toBe(-1);
    expect(new World(W, H, 5, DEFAULT_TUNING, true, ACT_DOWN).direction).toBe(1);
  });

  it('measures progress as positive in both directions', () => {
    // `u` is the course coordinate: larger is further ahead, whichever way that is.
    const up = new World(W, H, 5);
    const down = new World(W, H, 5, DEFAULT_TUNING, true, ACT_DOWN);
    expect(up.u(-1000)).toBeGreaterThan(up.u(0));
    expect(down.u(1000)).toBeGreaterThan(down.u(0));
  });

  it('builds course ahead of the camera, on the side the act runs toward', () => {
    const down = new World(W, H, 5, DEFAULT_TUNING, true, ACT_DOWN);
    expect(down.obstacles.sections.length).toBeGreaterThan(0);
    // Everything built has to be *ahead*, i.e. at larger Y for a falling act.
    for (const s of down.obstacles.sections) expect(s.lineY).toBeGreaterThan(down.cameraY);
    // ...and the spacing walks the same way.
    const lines = down.obstacles.sections.map((s) => s.lineY);
    for (let i = 1; i < lines.length; i++) expect(lines[i]!).toBeGreaterThan(lines[i - 1]!);
  });

  it('puts the entry edge of a section on the side the swarm arrives from', () => {
    const up = new World(W, H, 5);
    const down = new World(W, H, 5, DEFAULT_TUNING, true, ACT_DOWN);
    for (const s of up.obstacles.sections) {
      expect(s.entryY).toBe(s.maxY);
      expect(s.exitY).toBe(s.minY);
    }
    for (const s of down.obstacles.sections) {
      expect(s.entryY).toBe(s.minY);
      expect(s.exitY).toBe(s.maxY);
    }
  });

  it('anchors the camera so the swarm sits the same way round in the frame', () => {
    const up = new World(W, H, 5);
    const down = new World(W, H, 5, DEFAULT_TUNING, true, ACT_DOWN);
    // Climbing, the swarm sits low - most of the frame is what is coming. Falling,
    // it sits high, for exactly the same reason.
    expect(up.worldToScreenY(0) / H).toBeCloseTo(0.62, 2);
    expect(down.worldToScreenY(0) / H).toBeCloseTo(0.38, 2);
  });

  it('makes ground, clears sections and banks score on a falling course', () => {
    const down = new World(W, H, 4242, DEFAULT_TUNING, true, ACT_DOWN);
    run(down, 45);
    expect(down.run.distance).toBeGreaterThan(600);
    expect(down.run.gates).toBeGreaterThan(0);
    expect(down.run.score).toBeGreaterThan(0);
    // The centroid really went the other way.
    expect(down.swarm.centroid(MAIN_FACTION).y).toBeGreaterThan(400);
  });

  it('prunes what is behind and never what is ahead', () => {
    const down = new World(W, H, 909, DEFAULT_TUNING, true, ACT_DOWN);
    run(down, 30);
    for (const s of down.obstacles.sections) {
      // Nothing in the live list may be more than a screen behind the camera.
      expect(s.lineY).toBeGreaterThan(down.cameraY - H);
    }
    // ...and the course has actually advanced, so pruning was exercised.
    expect(down.obstacles.sections[0]!.id).toBeGreaterThan(0);
  });

  it('lets a falling course leave through the top, not vanish inside it', () => {
    // The mirror of `world.test.ts`'s "swim off the bottom". A section is dropped
    // from the picture only once the last edge of it - `maxY` falling, radius
    // included - is past the trailing edge, which up here is the top of the frame.
    const down = new World(W, H, 909, DEFAULT_TUNING, true, ACT_DOWN);
    const drawn = (): Map<number, { maxY: number }> => {
      const out = new Map<number, { maxY: number }>();
      for (const s of down.obstacles.retired) out.set(s.id, s);
      for (const s of down.obstacles.sections) out.set(s.id, s);
      return out;
    };
    let before = drawn();
    let left = 0;
    for (let i = 0; i < 60 * 30 && down.run.phase === 'running'; i++) {
      const c = down.swarm.centroid(MAIN_FACTION);
      if (i % 6 === 0 && c.count > 0) {
        down.injectStroke(c.x, c.y, c.x, c.y + down.direction * 90, 0.35);
      }
      down.step(1 / 60);
      const now = drawn();
      for (const [id, s] of before) {
        if (now.has(id)) continue;
        left++;
        expect(s.maxY - down.cameraY, `section ${id}`).toBeLessThan(0);
      }
      before = now;
    }
    expect(left).toBeGreaterThan(2);
  });

  it('strands a swarm that falls off the back of a falling course', () => {
    // No input at all: the drift takes the frame, the swarm is left behind, and
    // the ending that fires has to be the same one it would be on the climb.
    const down = new World(W, H, 77, DEFAULT_TUNING, true, ACT_DOWN);
    run(down, 90, false);
    expect(down.run.phase).toBe('over');
    expect(down.run.reason).not.toBeNull();
  });

  it('keeps act I on the climb, to the digit', () => {
    // The mirror exists to test the abstraction, never to change the original.
    const up = new World(W, H, 4242);
    run(up, 45);
    expect(up.direction).toBe(-1);
    expect(up.swarm.centroid(MAIN_FACTION).y).toBeLessThan(-400);
    expect(up.run.distance).toBeGreaterThan(600);
  });
});
