import { describe, expect, it } from 'vitest';
import { expectFinite, FakeContext } from './canvas';
import { drawEmber, drawEmberThreat } from '../src/render/Ember';
import { paintFor } from '../src/render/Paint';
import { CAMPAIGN, CAMPAIGN_ACTS } from '../src/config/campaign';
import { ACT_REENTRY } from '../src/config/reentry';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { World } from '../src/sim/World';
import { makeAimBot } from './bot';
import { H, W } from './helpers';

/**
 * Slowblue: act V's threat, and the campaign claim it exists to fix.
 *
 * The measurement that started the length rebuild found three things, and the
 * third was the one nothing could be blamed on authoring: **all six hunters in
 * the campaign were in acts I and II.** The only thing in this world with any
 * intent disappeared a quarter of the way round and never came back, so from act
 * III on every hazard was geometry standing still, waiting to be flown past. That
 * is most of why the back half stopped escalating with sixty sections still to go.
 *
 * The ember is the answer and it could not be a `hunters: []` entry on an
 * existing shape, for a reason worth keeping a test honest about: the renderer
 * picked its silhouette off the *medium*, so act V would have been given the
 * water's shark at two hundred kilometres. The form is a property of the predator
 * now. See `render/Ember.ts`, `sim/PredatorSystem.ts` and `SectionSpec.ember`.
 */

const SIZE = 17;

function view(rec: FakeContext, quality = 1) {
  return {
    ctx: rec.as2d,
    paint: paintFor(3),
    accent: [255, 214, 150] as [number, number, number],
    time: 2.4,
    quality,
  };
}

/**
 * The shard outline in world coordinates, for an ember heading straight down.
 *
 * Quality 0.3 is under the wake's threshold as well as the detail one, and the
 * shock cap and the hot point are both arcs, so what is left in `points` is the
 * shard and nothing else. Unlike the hunter's and the raptor's outlines this
 * cannot slice at `firstArc` - the cap is drawn *before* the body, because it is
 * the air in front of it.
 */
function outline(beat = 0, lunge = 0): { x: number; y: number }[] {
  const rec = new FakeContext();
  drawEmber(view(rec, 0.3), 0, 0, 0, 1, SIZE, lunge, beat);
  return rec.points;
}

describe('the ember silhouette', () => {
  it('is a shard: hard-edged, off-centre, and not an animal', () => {
    const pts = outline();
    expect(pts.length).toBeGreaterThan(6);
    const r = pts.map((p) => Math.hypot(p.x, p.y));
    // Every vertex is out at roughly the same order of distance - a chunk, not a
    // body with a long axis and a tail.
    expect(Math.max(...r) / Math.min(...r)).toBeLessThan(2.4);
    // ...and it is not symmetric about anything. A torn panel that came out
    // mirror-imaged would read as a manufactured object rather than as wreckage.
    const cx = pts.reduce((t, p) => t + p.x, 0) / pts.length;
    const cy = pts.reduce((t, p) => t + p.y, 0) / pts.length;
    expect(Math.hypot(cx, cy)).toBeGreaterThan(SIZE * 0.02);
  });

  it('tumbles, and the tumble has nothing to do with where it is going', () => {
    // Two instants of the beat with the same heading. A shark and a raptor hold
    // their heading; this does not, because nothing is steering it.
    const a = outline(0);
    const b = outline(9);
    let moved = 0;
    for (let i = 0; i < Math.min(a.length, b.length); i++) {
      if (Math.hypot(a[i]!.x - b[i]!.x, a[i]!.y - b[i]!.y) > 1) moved++;
    }
    expect(moved).toBeGreaterThan(a.length * 0.6);
  });

  it('never emits a bad coordinate, at any quality or state', () => {
    for (const quality of [0.2, 0.45, 0.6, 1]) {
      for (const lunge of [0, 0.5, 1]) {
        for (const [dx, dy] of [
          [0, 1],
          [1, 0],
          [-0.6, 0.8],
        ] as const) {
          const rec = new FakeContext();
          drawEmber(view(rec, quality), 120, 90, dx, dy, SIZE, lunge, 3.1);
          drawEmberThreat(view(rec, quality), 120, 90, SIZE, lunge);
          expectFinite(rec, `ember q=${String(quality)} l=${String(lunge)}`);
        }
      }
    }
  });

  it('draws the strike distance, like the other two threats do', () => {
    const rec = new FakeContext();
    drawEmberThreat(view(rec), 100, 100, SIZE, 0.4);
    // Two circles: the heat wash and the dashed strike arc. The range of the
    // thing that takes your carriers is information the player is owed, and act V
    // does not get to be the act that hides it.
    expect(rec.arcs.length).toBeGreaterThanOrEqual(2);
    const radii = rec.arcs.map((a) => a.r).sort((p, q) => p - q);
    expect(radii[0]).toBeLessThan(SIZE * 3);
    expect(radii[radii.length - 1]).toBeGreaterThan(SIZE * 4);
  });
});

describe('the threat that returns', () => {
  it('puts a hunter back in the campaign after act II', () => {
    const withThreat = CAMPAIGN.filter((a) =>
      a.act.script.some((e) => 'hunters' in e.spec && e.spec.hunters.length > 0),
    ).map((a) => a.number);
    // Acts I, II and now V. The gap between the second and the third is the whole
    // point: it is the first thing that hunts the swarm in thirty stations.
    expect(withThreat).toContain(5);
    expect(Math.max(...withThreat)).toBeGreaterThan(2);
  });

  it('gives every predator in the campaign the silhouette its section asked for', () => {
    // The rule this replaced was `medium.kind === 'air' ? raptor : shark`, which
    // held for exactly as long as the campaign had two threats and every act had
    // one medium. Act V blends three media inside one act.
    const FORM: Record<string, string> = {
      predator: 'shark',
      raptor: 'raptor',
      ember: 'ember',
    };
    for (const act of CAMPAIGN_ACTS) {
      const world = new World(W, H, 3, DEFAULT_TUNING, true, act);
      for (const entry of act.script) {
        if (!('hunters' in entry.spec)) continue;
        expect(FORM[entry.spec.kind], `${act.key}/${entry.spec.kind}`).toBeDefined();
      }
      // ...and nothing else in the act carries hunters at all.
      expect(world.predators.predators.length).toBe(0);
    }
  });

  it('releases act V s fragments behind the swarm, burning, in a falling act', () => {
    const world = new World(W, H, 4, DEFAULT_TUNING, true, ACT_REENTRY);
    const policy = makeAimBot({ strokeDt: 0.4 });
    const forms = new Set<string>();
    // Each fragment is judged once, on the frame it first exists. Counting every
    // frame would measure how long an ember spends *ahead* after it has
    // overtaken, which is the opposite of what this is about.
    const met = new Set<object>();
    let behind = 0;
    let ahead = 0;
    for (let i = 0; i < 60 * 60 * 8 && world.run.phase === 'running'; i++) {
      policy(world, 1 / 60);
      world.step(1 / 60);
      const centroid = world.swarm.centroid(0);
      for (const p of world.predators.predators) {
        forms.add(p.form);
        if (met.has(p) || centroid.count === 0) continue;
        met.add(p);
        // Falling, so "behind" is a smaller Y. Every ember in the act is a stoop
        // and a stoop that arrived in front of the swarm would be the exact bug
        // `World.releaseStoops` was written to fix.
        if (p.y < centroid.y) behind++;
        else ahead++;
      }
    }
    expect(forms.has('ember'), 'no ember was ever released').toBe(true);
    expect(forms.has('shark'), 'act V drew the water s hunter').toBe(false);
    expect(forms.has('raptor'), 'act V drew the air s hunter').toBe(false);
    expect(behind).toBeGreaterThan(0);
    expect(ahead, 'a fragment arrived in front of the swarm').toBe(0);
  });

  /**
   * Slowblue: the two things the first build of the ember got wrong, and both were
   * found by measuring lifetimes rather than by reading the code.
   *
   * On three seeds of act V, fragments lived 1, 22, 38, 60, 658, 5557 and 11 629
   * frames. The one-frame ones were spawned *behind the cull line*: the release
   * offset was a flat 170 px measured on a climbing act, and a falling act has
   * only 0.23 of a screen between the swarm and that line, which is 147 px on a
   * short viewport. The 11 629-frame one - three and a quarter minutes - was a
   * stoop that caught up and then simply stayed, because a stoop only leaves after
   * a couple of seconds with nothing in sense range and a swarm is a large thing
   * to lose.
   *
   * A hazard that exists for one frame and a hazard that never goes away are the
   * same defect: neither is an *event*. Both are fixed, and this is the instrument
   * that found them.
   */
  it('gives every fragment a life between a few seconds and half a minute', () => {
    const lives: number[] = [];
    for (const seed of [1, 2, 3]) {
      const world = new World(W, H, seed, DEFAULT_TUNING, true, ACT_REENTRY);
      const policy = makeAimBot({ strokeDt: 0.4 });
      const frames = new Map<object, number>();
      for (let i = 0; i < 60 * 60 * 10 && world.run.phase === 'running'; i++) {
        policy(world, 1 / 60);
        world.step(1 / 60);
        for (const p of world.predators.predators) frames.set(p, (frames.get(p) ?? 0) + 1);
      }
      for (const [p, n] of frames) {
        // A fragment cut short by a station restart is not evidence about
        // ablation; only the ones still alive at the end of their own burn are.
        if (!world.predators.predators.includes(p as never)) lives.push(n / 60);
      }
    }
    expect(lives.length, 'no fragment was ever released').toBeGreaterThan(4);
    const full = lives.filter((s) => s > 5);
    expect(full.length, 'every fragment died young - check the release offset').toBeGreaterThan(2);
    // 24 s is (size - 3) / (size / 30) for the sizes act V authors. Nothing may
    // outlive its own burn.
    expect(Math.max(...lives), 'a fragment outlived its ablation').toBeLessThan(26);
  });

  it('gets less dangerous exactly as fast as it gets smaller', () => {
    // `BITE_REACH` is a multiple of `size`, so ablation is not a timer bolted on
    // beside the hazard - it *is* the hazard, shrinking. Nothing else in the
    // campaign changes size while it is alive, which is why this is worth a test.
    const world = new World(W, H, 5, DEFAULT_TUNING, true, ACT_REENTRY);
    const policy = makeAimBot({ strokeDt: 0.4 });
    let first: { p: object; size: number } | null = null;
    let shrunk = 0;
    for (let i = 0; i < 60 * 60 * 10 && world.run.phase === 'running'; i++) {
      policy(world, 1 / 60);
      world.step(1 / 60);
      const p = world.predators.predators[0];
      if (p === undefined) continue;
      if (first === null || first.p !== p) first = { p, size: p.size };
      else if (p.size < first.size - 1) shrunk++;
    }
    expect(shrunk, 'no fragment ever ablated').toBeGreaterThan(60);
  });
});
