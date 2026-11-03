import { describe, expect, it } from 'vitest';
import {
  BEARING,
  BIRDS,
  beatAmount,
  beatPhase,
  bearing,
  birdAt,
  steerBearing,
  traceBird,
} from '../src/render/Flock';
import { FakeContext, expectFinite } from './canvas';

/**
 * The flock's silhouette, asserted the way `tests/fish.test.ts` asserts the
 * shoal's: trace into a recording context and measure the outline that comes out.
 * Three claims are worth pinning down, because all three are load-bearing for the
 * act rather than cosmetic - a bird is mostly wing, a wingbeat is a span that
 * foreshortens, and the beat follows the breath.
 */

function trace(bird = BIRDS[0]!, beat = 0, amount = 1): FakeContext {
  const rec = new FakeContext();
  traceBird(rec.as2d, 100, 100, 0, -1, 12, 3, bird, beat, amount, true);
  return rec;
}

/** Half the outline's extent across the heading. Heading is -Y, so that is X. */
function halfSpan(rec: FakeContext): number {
  let max = 0;
  for (const p of rec.points) max = Math.max(max, Math.abs(p.x - 100));
  return max;
}

describe('the flock', () => {
  it('draws a bird that is wider than it is long', () => {
    const rec = trace();
    expectFinite(rec, 'bird');
    let minY = Infinity;
    let maxY = -Infinity;
    for (const p of rec.points) {
      minY = Math.min(minY, p.y);
      maxY = Math.max(maxY, p.y);
    }
    // The whole point of the silhouette: span beats body length. A bird that is
    // longer than it is wide is a fish with a pointed tail.
    expect(halfSpan(rec) * 2).toBeGreaterThan(maxY - minY);
  });

  it('foreshortens the span on the upstroke, and sweeps the tips back', () => {
    // The ray's observation generalised: a wingbeat seen from above is a span
    // that draws in. The extreme is at 3pi/2 - see below for why it is there and
    // not at pi.
    const level = halfSpan(trace(BIRDS[0]!, 0, 1));
    const folded = halfSpan(trace(BIRDS[0]!, Math.PI * 1.5, 1));
    expect(folded).toBeLessThan(level * 0.92);
    // ...and the body itself never disappears with the span.
    expect(folded).toBeGreaterThan(level * 0.4);
  });

  it('keeps the wing working through the downstroke and folds it on the recovery', () => {
    // The two claims this file is built on, and they pull in opposite directions.
    //
    // *Nothing may be frozen.* The first version drove the beat from the fold
    // alone, so the wing was pixel-identical across an entire half of the cycle:
    // four still frames, a fold, four still frames. On screen that is a switch,
    // not an animal, and it is the same mistake `FishShapes` exists to avoid.
    //
    // *And it must still be asymmetric*, because a wingbeat is a pull and a
    // recovery rather than an oscillation. So the span has to move a little
    // everywhere and a lot on the upstroke.
    const bird = BIRDS[0]!;
    const span = (beat: number): number => halfSpan(trace(bird, beat, 1));
    const down = [0.2, 0.8, Math.PI / 2, 2.3, 3].map(span);
    const up = [3.4, 4, Math.PI * 1.5, 5.2, 6].map(span);
    const range = (xs: number[]): number => Math.max(...xs) - Math.min(...xs);
    // Something happens on the downstroke...
    expect(range(down)).toBeGreaterThan(0.3);
    // ...and most of it happens on the upstroke.
    expect(range(up)).toBeGreaterThan(range(down) * 2.5);
    expect(Math.min(...up)).toBeLessThan(Math.max(...down) * 0.85);
    // ...but the wing never collapses to a dart. At two thirds of a span the bird
    // stops being a bird once a beat, which was measured by drawing it.
    expect(Math.min(...up)).toBeGreaterThan(Math.max(...down) * 0.6);
  });

  it('surges forward on the downstroke and settles back on the recovery', () => {
    // Thrust, made visible. The nose reaches furthest up the heading in the
    // middle of the power stroke and least in the middle of the recovery, which
    // is a fraction of a body length and most of what makes the beat read as
    // effort rather than as a shape changing size.
    const nose = (beat: number): number => {
      let min = Infinity;
      for (const p of trace(BIRDS[0]!, beat, 1).points) min = Math.min(min, p.y);
      return min;
    };
    // Heading is -Y, so "further forward" is a smaller y.
    expect(nose(Math.PI / 2)).toBeLessThan(nose(0));
    expect(nose(Math.PI * 1.5)).toBeGreaterThan(nose(0));
  });

  it('banks into a turn: both wings shorten together and the tail fans', () => {
    const rec = (roll: number): FakeContext => {
      const r = new FakeContext();
      traceBird(r.as2d, 100, 100, 0, -1, 12, 3, BIRDS[0]!, 0, 1, true, roll);
      return r;
    };
    // A roll is about the body's own axis, so it foreshortens the whole span -
    // it is not one wing dipping, and drawing it that way is what makes a flock
    // being steered read as flying rather than as sliding.
    expect(halfSpan(rec(1))).toBeLessThan(halfSpan(rec(0)) * 0.75);
    // ...and the tail spreads, because that is how a bird actually turns. Measured
    // on the rearmost tenth of the outline only: the swept wingtips also sit
    // behind the body, and they are the thing that just got *shorter*.
    const tail = (r: FakeContext): number => {
      let back = -Infinity;
      for (const p of r.points) back = Math.max(back, p.y);
      let max = 0;
      for (const p of r.points) if (p.y > back - 1.5) max = Math.max(max, Math.abs(p.x - 100));
      return max;
    };
    expect(tail(rec(1))).toBeGreaterThan(tail(rec(0)));
  });

  it('never stops beating, however far into the exhale it is', () => {
    // "Flap as they fly" is a hard requirement, not a preference: a flock that
    // holds still for half of every breath reads as a field of paper darts. The
    // breath is felt in how *hard* they beat, never in whether they do.
    for (const b of BIRDS) {
      expect(b.glide, `${b.key} glide`).toBeGreaterThan(0.4);
      expect(b.flap * b.glide, `${b.key} floor`).toBeGreaterThan(0.13);
    }
  });

  it('holds the wings out when the beat is not running', () => {
    // amount = 0 is a bird gliding: the span must not depend on the phase at all,
    // or a "gliding" flock would still be visibly flapping.
    const a = halfSpan(trace(BIRDS[0]!, 0, 0));
    const b = halfSpan(trace(BIRDS[0]!, Math.PI, 0));
    expect(a).toBeCloseTo(b, 6);
  });

  it('beats on the inhale and glides on the exhale', () => {
    // The act's entrainment claim, as one function. `breath` is 1 fully inhaled.
    const bird = BIRDS[0]!;
    expect(beatAmount(1, bird.glide)).toBeCloseTo(1, 6);
    expect(beatAmount(0, bird.glide)).toBeCloseTo(bird.glide, 6);
    expect(beatAmount(0.5, bird.glide)).toBeGreaterThan(beatAmount(0.2, bird.glide));
    // Clamped, because the breath is pushed in from outside this module.
    expect(beatAmount(-3, 0.2)).toBeCloseTo(0.2, 6);
    expect(beatAmount(9, 0.2)).toBeCloseTo(1, 6);
  });

  it('gives a soarer more hold on the exhale than a small bird', () => {
    const albatross = BIRDS.find((b) => b.key === 'albatross')!;
    const petrel = BIRDS.find((b) => b.key === 'petrel')!;
    // A bird that stops dead looks dead; what a big wing does on the rest half is
    // hold, not freeze.
    expect(beatAmount(0, albatross.glide)).toBeGreaterThan(beatAmount(0, petrel.glide));
    // ...and the small one is the one that actually flutters.
    expect(petrel.flap).toBeGreaterThan(albatross.flap);
    expect(petrel.beat).toBeGreaterThan(albatross.beat);
  });

  it('makes every silhouette distinct in span, sweep or tail', () => {
    // Colour alone disappears the moment the palette moves, so the set has to
    // separate on shape - the same rule the fish species are held to. Sweep is
    // the tip's leading edge and taper is how fast the chord runs out; between
    // them and the span they are the whole planform.
    for (let i = 0; i < BIRDS.length; i++) {
      for (let j = i + 1; j < BIRDS.length; j++) {
        const a = BIRDS[i]!;
        const b = BIRDS[j]!;
        const taper = (x: (typeof BIRDS)[number]): number => x.chord[4] / x.chord[0];
        const differs =
          Math.abs(a.span - b.span) > 0.5 ||
          Math.abs(a.lead[4] - b.lead[4]) > 0.08 ||
          Math.abs(taper(a) - taper(b)) > 0.1 ||
          Math.abs(a.notch - b.notch) > 0.15;
        expect(differs, `${a.key} vs ${b.key}`).toBe(true);
      }
    }
  });

  it('keeps a wing a wing: the chord only ever narrows toward the tip', () => {
    // A planform that swells outboard is a paddle, not a wing, and it is the one
    // way this table can be edited into something that stops reading as a bird.
    for (const b of BIRDS) {
      for (let i = 1; i < b.chord.length; i++) {
        expect(b.chord[i]!, `${b.key} station ${i}`).toBeLessThanOrEqual(b.chord[i - 1]!);
        expect(b.lead[i]!, `${b.key} sweep ${i}`).toBeGreaterThanOrEqual(b.lead[i - 1]!);
      }
      expect(b.lead[0]).toBe(0);
    }
  });

  it('carries no predator, forked seabirds and fanned soarers', () => {
    // The threat in this act is a different animal in a different file
    // (`Raptor.ts`). A bird of prey has to be recognisable *as* one before it
    // does anything, and the way to guarantee that is to keep its shape out of
    // the flock entirely - so nothing here may be as swept as a stooping falcon.
    for (const b of BIRDS) expect(b.lead[4], b.key).toBeLessThan(0.8);
    // A fork is notch < 1, a fan is notch > 1. Both must exist in the set.
    expect(BIRDS.some((b) => b.notch < 1)).toBe(true);
    expect(BIRDS.some((b) => b.notch > 1)).toBe(true);
    // ...and one wing in the set is slotted, which is the soarer's field mark.
    expect(BIRDS.some((b) => b.fingers > 0)).toBe(true);
  });

  it('never jumps: the drawn span moves smoothly frame to frame', () => {
    // The bug this exists to prevent, in the terms the player reported it in:
    // "the wings vibrate". Phase is `clock * rate` and the clock is unbounded, so
    // a rate that depends on anything per-frame - the agent's instantaneous
    // speed, say - rewrites the whole accumulated phase every frame. Twenty
    // seconds in, that was worth about three radians a frame, and a flock whose
    // silhouette is *driven* by phase strobed rather than flew.
    //
    // So this walks two hundred real frames deep into a run and asserts the thing
    // an eye actually objects to: no visible discontinuity in the shape.
    for (const bird of BIRDS) {
      let prev = -1;
      let biggest = 0;
      let lo = Infinity;
      let hi = -Infinity;
      for (let i = 0; i < 200; i++) {
        const clock = 21 + i / 60;
        const span = halfSpan(trace(bird, beatPhase(clock, bird, 1.03, 0.7), 1));
        if (prev >= 0) biggest = Math.max(biggest, Math.abs(span - prev));
        prev = span;
        lo = Math.min(lo, span);
        hi = Math.max(hi, span);
      }
      // Measured against the beat's own swing rather than against a pixel count,
      // so it means the same thing for a swift and for an albatross: no single
      // frame may cover more than a quarter of the whole stroke. A smooth beat
      // spends a dozen frames crossing that range; the bug crossed all of it,
      // in a random direction, sixty times a second.
      expect(hi - lo, `${bird.key} has a visible beat at all`).toBeGreaterThan(0.5);
      expect(biggest, `${bird.key} frame-to-frame span jump`).toBeLessThan((hi - lo) * 0.25);
    }
  });

  it('advances the beat at a rate that cannot depend on the frame', () => {
    // The same claim one level down, where it is a statement about the function
    // rather than about the picture: equal clock steps give equal phase steps,
    // for ever, so nothing per-frame can be smuggled into the rate later.
    const bird = BIRDS[0]!;
    const step = (t: number): number => beatPhase(t + 1 / 60, bird, 1, 0.5) - beatPhase(t, bird, 1, 0.5);
    expect(step(0)).toBeCloseTo(step(600), 9);
    expect(step(0)).toBeGreaterThan(0);
    // ...and a bigger individual beats more slowly, which is the one thing the
    // rate is allowed to know about, because a body size does not change.
    expect(beatPhase(10, bird, 1.08, 0)).toBeLessThan(beatPhase(10, bird, 0.92, 0));
  });

  it('does not spin a bird that is holding station', () => {
    // Reported as the birds inside a ring jittering left and right, and it is the
    // same class of bug as the vibrating wings: an individual held on a point
    // reaches its anchor and then sits there with a velocity that is almost
    // entirely the simulation's wander term. Its direction is noise. Aiming a
    // silhouette two and a half times wider than it is long at noise spins it on
    // the spot - so below a walking pace the heading has to come from somewhere
    // that cannot jitter.
    //
    // The noise here is deliberately worse than the real thing: the wander term
    // is worth a few px/s, and this shakes the velocity across its whole range
    // every frame.
    let prev = 0;
    let biggest = 0;
    for (let i = 0; i < 240; i++) {
      const clock = 12 + i / 60;
      // Deterministic garbage, standing in for a stationary agent's velocity.
      const vx = Math.sin(i * 12.9898) * 5;
      const vy = Math.cos(i * 78.233) * 5;
      bearing(vx, vy, clock, 1.4);
      const angle = Math.atan2(BEARING.y, BEARING.x);
      if (i > 0) {
        let d = Math.abs(angle - prev);
        if (d > Math.PI) d = Math.PI * 2 - d;
        biggest = Math.max(biggest, d);
      }
      prev = angle;
    }
    // A held bird may wheel, slowly. It may not snap: a hundredth of a radian in
    // a sixtieth of a second is already a leisurely turn.
    expect(biggest).toBeLessThan(0.02);
  });

  it('gives a caged bird yaw inertia: fast, flipping velocity cannot snap the pose', () => {
    // The report `bearing` alone could not fix: a bird boxed in a rescue ring is
    // *above* the hold blend - the boids terms drive it at schooling pace inside
    // a cage a few body-lengths wide - so its velocity direction is fast, real,
    // and reverses every few frames, and the blended target reversed with it.
    // The drawn heading is state now, and this asserts the whole point of that:
    // however violently the target thrashes, no frame may turn the body by more
    // than the yaw clamp, which is an order of magnitude under the swing.
    const dt = 1 / 60;
    let angle = steerBearing(Number.NaN, 0, -80, 0, 0.3, dt);
    let biggest = 0;
    for (let i = 1; i < 240; i++) {
      // Deterministic thrash: full-pace velocity slamming side to side.
      const flip = Math.sin(i * 1.3) > 0 ? 1 : -1;
      const next = steerBearing(angle, flip * 80, -20, i * dt, 0.3, dt);
      biggest = Math.max(biggest, Math.abs(next - angle));
      angle = next;
    }
    expect(biggest).toBeLessThan(0.06);
  });

  it('still comes round to the true course, and then holds it exactly', () => {
    // ...and the inertia must not cost a travelling bird its heading: give the
    // steer a steady course and it converges, then tracks with no residual sway.
    const dt = 1 / 60;
    let angle = steerBearing(Number.NaN, 0, -60, 0, 0, dt);
    for (let i = 0; i < 600; i++) angle = steerBearing(angle, 60, 0, i * dt, 0, dt);
    expect(BEARING.x).toBeCloseTo(1, 2);
    expect(Math.abs(BEARING.y)).toBeLessThan(0.05);
  });

  it('turns the short way across the seam, snaps only when fresh, freezes when paused', () => {
    // The seam: a heading just short of +pi asked to reach just past -pi must
    // cross the wrap, not lap the compass the long way round.
    const dt = 1 / 60;
    const prev = Math.PI - 0.05;
    const next = steerBearing(prev, -100, -5.2, 1, 0, dt);
    expect(next).toBeGreaterThan(prev);
    expect(next - prev).toBeLessThan(0.1);
    // A bird with no history faces its target at once - a fresh spawn must not
    // slew in from wherever the slot's last occupant pointed...
    const snap = steerBearing(Number.NaN, 120, 0, 0, 0, dt);
    expect(snap).toBeCloseTo(0, 6);
    // ...and dt = 0 is a paused flock holding its pose, bit for bit.
    expect(steerBearing(1.2, 300, 40, 5, 0.7, 0)).toBe(1.2);
    expect(BEARING.x).toBeCloseTo(Math.cos(1.2), 6);
    expect(BEARING.y).toBeCloseTo(Math.sin(1.2), 6);
  });

  it('still flies where it is going once it is actually travelling', () => {
    // ...and the fix must not cost a moving bird its heading. At cruise the
    // bearing is the velocity, to a rounding error.
    const drive = bearing(90, -140, 3.2, 0.6);
    expect(drive).toBe(1);
    const len = Math.hypot(90, -140);
    expect(BEARING.x).toBeCloseTo(90 / len, 6);
    expect(BEARING.y).toBeCloseTo(-140 / len, 6);
    // ...and it crosses over smoothly rather than snapping at a threshold.
    expect(bearing(0, -1, 0, 0)).toBe(0);
    expect(bearing(0, -25, 0, 0)).toBeGreaterThan(0);
    expect(bearing(0, -25, 0, 0)).toBeLessThan(1);
  });

  it('traces cleanly at any heading, phase and quality', () => {
    for (const bird of BIRDS) {
      for (const q of [true, false]) {
        for (let i = 0; i < 12; i++) {
          const ang = (i / 12) * Math.PI * 2;
          const rec = new FakeContext();
          traceBird(
            rec.as2d,
            50,
            60,
            Math.cos(ang),
            Math.sin(ang),
            10,
            3,
            bird,
            i * 0.7,
            beatAmount(i / 12, bird.glide),
            q,
          );
          expectFinite(rec, `${bird.key} at ${ang.toFixed(2)}`);
          expect(rec.points.length).toBeGreaterThan(8);
        }
      }
    }
  });

  it('clamps an out-of-range species to the act\'s own bird', () => {
    expect(birdAt(-1).key).toBe(BIRDS[0]!.key);
    expect(birdAt(99).key).toBe(BIRDS[0]!.key);
    expect(birdAt(2).key).toBe(BIRDS[2]!.key);
  });
});
