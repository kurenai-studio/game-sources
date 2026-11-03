import { describe, expect, it } from 'vitest';
import { CAMPAIGN_ACTS } from '../src/config/campaign';
import { PARTICLE_CARRIERS, carrierFor, isParticle, traceCarrier } from '../src/render/Carriers';
import { FakeContext, expectFinite } from './canvas';

/**
 * Slowblue: the five carriers with no body plan.
 *
 * The campaign's one real secret is that the player was never steering the fish -
 * they were helping the same gold along, and the thing holding it changed seven
 * times. That is a *rendering* claim from end to end, so what is asserted here is
 * that the five particle carriers are genuinely five different things, that none
 * of them can put a bad number into a path, and that the two acts with animals in
 * them are still drawn as animals.
 */

describe('the carriers', () => {
  it('draws every carrier at every speed without a single bad number', () => {
    for (const c of PARTICLE_CARRIERS) {
      for (const speed of [0, 40, 400]) {
        for (const phase of [0, 0.37, 0.99]) {
          const rec = new FakeContext();
          const ctx = rec.as2d;
          ctx.beginPath();
          traceCarrier(ctx, c, 120, 240, 3.2, speed, speed * 0.4, phase, 7.25);
          ctx.fill();
          expectFinite(rec, `${c.key} speed=${speed} phase=${phase}`);
          expect(rec.fills, `${c.key} drew nothing`).toBeGreaterThan(0);
        }
      }
    }
  });

  /**
   * A particle is only ever a streak because something is moving it. At rest the
   * silhouette must not claim a heading the thing does not have - so the only
   * honest test is that the shape *grows along its velocity when there is one*
   * and does not when there is not.
   */
  it('only stretches a particle that is actually being moved', () => {
    /** Longest reach from the centre, whichever way the shape was traced. */
    const reach = (c: (typeof PARTICLE_CARRIERS)[number], vx: number, vy: number): number => {
      const rec = new FakeContext();
      traceCarrier(rec.as2d, c, 100, 100, 4, vx, vy, 0.5, 0);
      const fromPoints = rec.points.map((p) => Math.hypot(p.x - 100, p.y - 100));
      // Ellipses record their x radius rather than a set of points.
      const fromArcs = rec.arcs.map((a) => a.r);
      return Math.max(0, ...fromPoints, ...fromArcs);
    };
    for (const c of PARTICLE_CARRIERS) {
      const still = reach(c, 0, 0);
      const fast = reach(c, 400, 0);
      expect(still, c.key).toBeGreaterThan(0);
      if (c.stretch > 0.4) {
        // Anything the medium really deforms has to show it.
        expect(fast, `${c.key} does not stretch`).toBeGreaterThan(still * 1.2);
      }
      // ...and nothing may be longer at rest than it is under way.
      expect(fast, `${c.key} shrinks with speed`).toBeGreaterThanOrEqual(still * 0.99);
    }
  });

  /**
   * The arc of the whole second half, in one column. A spore tumbles and is
   * round; a grain of meteor dust is ablating at eight kilometres a second and is
   * a streak. Everything between is how much the medium is doing to it.
   */
  it('stretches the burning dust hardest and the gold least', () => {
    const dust = carrierFor('dust');
    const lights = carrierFor('lights');
    const motes = carrierFor('motes');
    expect(dust.stretch).toBeGreaterThan(motes.stretch);
    expect(dust.stretch).toBeGreaterThan(lights.stretch);
    // Vacuum does nothing to anything, so the gold is the roundest in the game.
    expect(lights.stretch).toBeLessThan(motes.stretch);
    expect(lights.stretch).toBeLessThan(carrierFor('droplets').stretch);
  });

  it('gives the biggest halo to the one thing that is its own light source', () => {
    // In vacuum the swarm is not merely lit, it is the only light in the frame.
    const lights = carrierFor('lights');
    for (const c of PARTICLE_CARRIERS) {
      if (c.key === 'lights') continue;
      expect(lights.halo, c.key).toBeGreaterThan(c.halo);
      expect(lights.haloAlpha, c.key).toBeGreaterThanOrEqual(c.haloAlpha);
    }
    // ...and nothing that emits its own light glints, because emission does not
    // care which way you are facing.
    expect(lights.glint).toBe(0);
    expect(carrierFor('dust').glint).toBe(0);
  });

  it('facets only the things that are actually crystal', () => {
    expect(carrierFor('motes').facets).toBeGreaterThan(0);
    expect(carrierFor('droplets').facets).toBeGreaterThan(0);
    // Gold, burning dust and marine snow are not crystal and must not be faceted.
    expect(carrierFor('lights').facets).toBe(0);
    expect(carrierFor('dust').facets).toBe(0);
    expect(carrierFor('plankton').facets).toBe(0);
  });

  it('makes all five of them different from each other', () => {
    const signature = PARTICLE_CARRIERS.map(
      (c) => `${c.size}|${c.stretch}|${c.halo}|${c.facets}|${c.glint}`,
    );
    expect(new Set(signature).size).toBe(PARTICLE_CARRIERS.length);
  });

  /**
   * Two of the seven acts have animals in them and five do not. This is the one
   * assertion that keeps the split honest: a carrier that quietly fell through to
   * the particle path would draw a flock as a cloud of dots, and a carrier that
   * fell the other way would give a spore a spine and a tail.
   */
  it('draws exactly the two animal acts as animals, and the rest as particles', () => {
    const byAct = CAMPAIGN_ACTS.map((a) => ({ key: a.key, particle: isParticle(a.carrier) }));
    expect(byAct.filter((a) => !a.particle).map((a) => a.key)).toEqual(['water', 'air']);
    expect(byAct.filter((a) => a.particle).length).toBe(5);
    // ...and every particle act names a carrier this file actually has.
    for (const act of CAMPAIGN_ACTS) {
      if (!isParticle(act.carrier)) continue;
      expect(carrierFor(act.carrier).key, act.key).toBe(act.carrier);
    }
  });
});
