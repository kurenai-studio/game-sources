import { describe, expect, it } from 'vitest';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { World } from '../src/sim/World';
import { ACT_WATER } from '../src/config/levels';
import { sampleAllocations } from './allocation';
import { makeAimBot } from './bot';
import { H, W } from './helpers';

/**
 * Criterion 3's zero-GC clause, as a guard rather than a claim.
 *
 * The number this defends was measured, not chosen. Warm, with a bot flying the
 * course, the simulation half of the per-frame path costs 20 B/frame on an open
 * station and 65 B/frame with every hunter in the act alive and a shoal of a
 * hundred and ninety. Four kilobytes a second at the worst of it: a minor GC
 * every several minutes. That is the zero this criterion can actually mean on a
 * garbage-collected runtime, and it is now a number rather than a hope.
 *
 * Idle, with nobody flying, the same path measures 0 and 15 B/frame - and 12 of
 * that 15 is `node:inspector`'s own message handling, the instrument reading
 * itself. The difference between those two pairs is the player, and the higher
 * pair is the honest one.
 *
 * Warm is the load-bearing word and the reason this file exists in the shape it
 * does. Sampled cold, the same code reported 124 B/frame and blamed `Math.hypot`
 * for two thirds of it; the bytes were V8 compiling the loop, not the loop
 * running. See `sampleAllocations` for what that cost to find out.
 *
 * The budget sits far above the measurement on purpose. A sampling profiler
 * estimates, the shoal size varies with what the bot manages to rescue, and a
 * guard tight enough to notice ten bytes would fail on its own arithmetic and be
 * switched off inside a week. What this catches is a regression of *kind* - a
 * `.map()`, a `.filter()` or an object literal per agent per frame - and at fifty
 * agents that is thousands of bytes, not tens.
 */
const PER_FRAME_BUDGET = 400;
/** 600 frames = ten seconds of play at 60 Hz, as in the e2e probe. */
const FRAMES = 600;
/** Where the number stops moving. See `sampleAllocations`. */
const WARMUP_FRAMES = 4000;

/**
 * One frame of everything the simulation does per frame, with a player in it.
 *
 * The bot is not decoration and it is not here for realism alone. `World.step`
 * returns almost immediately once a run is over, so a sample taken across the end
 * of one measures a stopped game and passes for the best possible reason - which
 * is exactly how the browser probe in `e2e/measure.spec.ts` was silently
 * measuring `ringMissed` four seconds into a ten-second window. A run that has to
 * stay alive for the whole sample needs someone flying it, and the campaign's own
 * stand-in player is already written.
 *
 * `takeEvents` is in here rather than left out because it is part of the
 * per-frame path in `main.ts`, and because draining is exactly the kind of thing
 * that gets written to allocate - it is the frame's only queue.
 */
function simFrame(world: World): () => void {
  const bot = makeAimBot({ strokeDt: 0.09, greedy: true });
  return () => {
    bot(world, 1 / 60);
    world.step(1 / 60);
    world.takeEvents();
  };
}

describe('allocation', () => {
  it('holds the simulation step inside the per-frame budget', async () => {
    const world = new World(W, H, 12345, DEFAULT_TUNING, true, ACT_WATER);
    const frame = simFrame(world);
    // Let the shoal spread and the first sections build: an empty course is not
    // the frame worth measuring.
    for (let i = 0; i < 240; i++) frame();

    const { perFrame, sites } = await sampleAllocations(frame, FRAMES, WARMUP_FRAMES);
    console.log('[allocation sim]', JSON.stringify({ frames: FRAMES, perFrameBytes: perFrame }));
    for (const [site, bytes] of sites) {
      console.log(`[allocation sim site] ${site} = ${Math.round(bytes / FRAMES)} B/frame`);
    }

    expect(world.run.phase).toBe('running');
    expect(perFrame).toBeLessThan(PER_FRAME_BUDGET);
  }, 60_000);

  /**
   * The same step with the act's content actually in it. Hunters and standing
   * currents are the systems that own per-frame lists, so a pool that stopped
   * being a pool shows up here and nowhere else.
   */
  it('holds the budget with the act loaded and hunting', async () => {
    const world = new World(W, H, 4242, DEFAULT_TUNING, true, ACT_WATER);
    const frame = simFrame(world);
    for (let i = 0; i < 240; i++) frame();
    world.obstacles.ensureAhead(-100_000);
    for (const s of world.obstacles.sections) {
      for (const h of s.hunterHints) world.predators.spawn(h.x, h.y, h.size, s.id, 0);
      for (const v of s.vortexHints) world.currents.add({ ...v, sectionId: s.id, phase: 0 });
    }
    // Every hunter in the act at once eats a starting shoal inside the sample, and
    // the bot cannot outfly all of them. A large shoal is a state the game reaches
    // through rescues, and it is also strictly more work per frame - which is what
    // "busiest" is supposed to mean here.
    const c = world.swarm.centroid();
    world.swarm.spawnShoal(140, c.x, c.y, 90);
    expect(world.predators.predators.length).toBeGreaterThan(2);
    expect(world.currents.vortices.length).toBeGreaterThan(2);

    const { perFrame, sites } = await sampleAllocations(frame, FRAMES, WARMUP_FRAMES);
    console.log('[allocation deep]', JSON.stringify({ frames: FRAMES, perFrameBytes: perFrame }));
    for (const [site, bytes] of sites) {
      console.log(`[allocation deep site] ${site} = ${Math.round(bytes / FRAMES)} B/frame`);
    }

    expect(world.run.phase).toBe('running');
    expect(perFrame).toBeLessThan(PER_FRAME_BUDGET);
  }, 60_000);
});
