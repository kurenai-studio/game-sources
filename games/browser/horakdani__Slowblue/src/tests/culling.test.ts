import { describe, expect, it } from 'vitest';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { Decor } from '../src/render/Decor';
import { paintFor } from '../src/render/Paint';
import { World } from '../src/sim/World';
import { makeAimBot } from './bot';
import { H, W } from './helpers';

/**
 * Slowblue: nothing leaves the frame by being switched off.
 *
 * Three systems drop what the camera has gone past, and all three keyed that drop
 * to a line that is *on the glass* rather than past it. `behindLine` is 0.9 of a
 * screen behind the camera on a climb - nine tenths of the way down the picture,
 * not off its bottom edge - so rocks and standing currents blinked out in full
 * view, and the decorative layer went in whole bands at a time from halfway up.
 *
 * The fixes are one fix in three places: separate "the simulation is done with
 * this" from "the picture is done with this". These tests are written as
 * invariants rather than against the new margins, because the margins will be
 * tuned again and the invariant will not - *if it was on screen last frame and it
 * is not drawn this frame, it left through an edge.*
 */

/** A competent player, so the camera actually leaves sections behind. */
function driven(world: World, steps: number, each: () => void): number {
  const bot = makeAimBot({ strokeDt: 0.09 });
  let ran = 0;
  for (let i = 0; i < steps && world.run.phase === 'running'; i++) {
    bot(world, 1 / 60);
    world.step(1 / 60);
    each();
    ran++;
  }
  return ran;
}

describe('nothing pops out of the frame', () => {
  it('keeps drawing a rock until it has left the screen', () => {
    const world = new World(W, H, 42, { ...DEFAULT_TUNING }, false);
    // Exactly what `Renderer.drawObstacles` puts on the glass, by identity and extent.
    const drawn = (): Map<string, { top: number; bottom: number }> => {
      const m = new Map<string, { top: number; bottom: number }>();
      for (const list of [world.obstacles.sections, world.obstacles.retired]) {
        for (const s of list) {
          for (let i = 0; i < s.blobs.length; i++) {
            const b = s.blobs[i]!;
            m.set(`${s.id}:${i}`, {
              top: b.y - b.r - world.cameraY,
              bottom: b.y + b.r - world.cameraY,
            });
          }
        }
      }
      return m;
    };

    let prev = drawn();
    let everRetired = false;
    const pops: number[] = [];
    driven(world, 7200, () => {
      if (world.obstacles.retired.length > 0) everRetired = true;
      const now = drawn();
      for (const [key, was] of prev) {
        if (!now.has(key) && was.bottom > 0 && was.top < H) pops.push(Math.round(was.top));
      }
      prev = now;
    });

    // Worthless if the run never got far enough to prune anything.
    expect(everRetired).toBe(true);
    expect(pops).toEqual([]);
  });

  it('keeps drawing a standing current until its whole disc has left', () => {
    const world = new World(W, H, 42, { ...DEFAULT_TUNING }, false);
    // Placed by hand rather than waited for: generated water only builds vortices
    // in the deeper zones, and what is under test is the field's own pruning.
    world.currents.add({
      x: W * 0.5,
      y: world.cameraY - H * 0.6,
      radius: 120,
      strength: 90,
      sectionId: 9999,
      phase: 0,
    });

    const drawn = (): Map<number, { top: number; bottom: number }> => {
      const m = new Map<number, { top: number; bottom: number }>();
      for (const list of [world.currents.vortices, world.currents.retired]) {
        for (const v of list) {
          m.set(v.sectionId, {
            top: v.y - v.radius - world.cameraY,
            bottom: v.y + v.radius - world.cameraY,
          });
        }
      }
      return m;
    };

    let prev = drawn();
    let sawItOnScreen = false;
    const pops: number[] = [];
    driven(world, 7200, () => {
      const now = drawn();
      const mine = now.get(9999);
      if (mine !== undefined && mine.bottom > 0 && mine.top < H) sawItOnScreen = true;
      for (const [key, was] of prev) {
        if (!now.has(key) && was.bottom > 0 && was.top < H) pops.push(Math.round(was.top));
      }
      prev = now;
    });

    expect(sawItOnScreen).toBe(true);
    expect(pops).toEqual([]);
  });

  it('keeps enough decorative water behind the camera for the slow layer', () => {
    /*
     * The decorative layer draws at a parallax rate, and that is the whole bug: an
     * element at world distance D behind the camera shows at screen `D * rate`, so
     * at 0.72 the world the screen can see reaches 1/0.72 of a screen *past* the
     * screen. Pruning bands against the screen height directly - which is what
     * `height * 1.2` did - throws away elements that are still a third of the way
     * down the frame, a whole band of them at once.
     *
     * Asserted as the reason rather than as the formula: whatever the margins
     * become, a layer that moves at 0.72 needs more than one screen of world kept
     * behind the camera. `bands` is private and this reaches past that on purpose -
     * the alternative is production API that exists only for a test.
     */
    const SLOWEST_RATE = 0.72;
    const decor = new Decor();
    // Read fresh each time: `reset` replaces the array rather than emptying it.
    const bands = (): { y: number }[] => (decor as unknown as { bands: { y: number }[] }).bands;
    const paint = paintFor(2);
    const ctx = new Proxy(
      {},
      {
        get: (_t, prop) =>
          prop === 'createRadialGradient' || prop === 'createLinearGradient'
            ? () => ({ addColorStop: () => undefined })
            : () => undefined,
        set: () => true,
      },
    ) as unknown as CanvasRenderingContext2D;

    let cameraY = 0;
    decor.reset(1234, 'kelp', cameraY, -1);
    // Settle: the list has to be full before its trailing edge means anything.
    for (let i = 0; i < 600; i++) {
      cameraY -= 3;
      decor.update(cameraY, H, 1 / 60, 1);
    }

    let worstCoverage = Infinity;
    for (let i = 0; i < 3000; i++) {
      cameraY -= 3;
      decor.update(cameraY, H, 1 / 60, 1);
      // Drawn as well, so a change to `draw` that reads more bands is exercised.
      decor.draw(ctx, paint, W, H, cameraY, i / 60, 0);
      decor.draw(ctx, paint, W, H, cameraY, i / 60, 1);
      let trailing = -Infinity;
      for (const b of bands()) trailing = Math.max(trailing, b.y);
      worstCoverage = Math.min(worstCoverage, trailing - cameraY);
    }

    expect(bands().length).toBeGreaterThan(0);
    expect(worstCoverage).toBeGreaterThan(H / SLOWEST_RATE);
  });
});
