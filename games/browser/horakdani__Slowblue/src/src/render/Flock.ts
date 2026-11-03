/**
 * Slowblue: the birds, seen from directly above.
 *
 * `FishShapes.ts` works because it stopped drawing an icon of a fish and started
 * drawing the thing itself: a spine carrying a travelling wave, a profile sampled
 * down the body, fins that sweep. The shoal reads as a hundred animals at eleven
 * pixels each because every one of those numbers describes an actual fish.
 *
 * The first flock did not do that. It had a span, one sweep angle and two
 * quadratics, which is a description of an *arrowhead* - and that is what a
 * hundred of them looked like, a field of cursor glyphs pointing up the screen.
 * Colour and tint could not save it, because the problem was never colour.
 *
 * So this file is `FishShapes` for birds, and the piece of anatomy it is built
 * around is the one that carries the whole silhouette: **the planform**. A wing
 * seen from above is two curves - where its leading edge is, and how much chord
 * hangs behind that edge - both sampled from root to tip. Sample those five times
 * and the difference between a shearwater, an albatross, a buzzard and a swift
 * falls straight out of the numbers, in exactly the way the fish's `profile`
 * array gives you a dart, a disc and a ray.
 *
 * ## What a wingbeat looks like from above, and why it is not a sine
 *
 * You cannot see a wing go up and down. What you see is the wing **extended for
 * the whole downstroke and folded through the whole upstroke**, and that
 * asymmetry is the entire animation. A bird does not oscillate; it pulls, then
 * recovers. So the cycle is driven by `max(0, -sin(beat))` rather than by a
 * cosine: the wing is out and still for half of every beat and draws in only on
 * the recovery, which is exactly what a flock overhead looks like and is nothing
 * like what a sine gives you.
 *
 * Four things follow from that one number (`fold` in `wingFrame`):
 *
 *   - the **span foreshortens** - the tips draw in toward the body;
 *   - the **hand sweeps back** - the outer wing trails, because the wrist folds
 *     and the tip travels an arc, so the outer half moves further than the inner;
 *   - the **chord narrows at the tip** - a hand rotating out of plane presents
 *     less of itself;
 *   - the **body surges** - thrust arrives on the downstroke, so the whole animal
 *     creeps forward against its own path and settles back on the recovery. It is
 *     a fraction of a body length and it is most of what makes the beat read as
 *     *work* rather than as a shape changing size.
 *
 * The first of those is the ray's observation from act I, generalised. All four
 * are functions of one phase, so the animation costs no state and a whole species
 * is still one `fill()`.
 *
 * ## Banking
 *
 * The other half of looking alive is what a bird does when it turns, and from
 * directly above that is unmistakable: it **rolls**, so both wings foreshorten
 * together and the tail fans. `roll` is read off the steered heading's own yaw
 * rate - see `steerBearing` - which is clamped by construction, so the bank can
 * never flicker: a flock being steered around a cloud visibly *banks into the
 * turn* instead of sliding sideways like a sprite, and a bird milling inside a
 * ring carries nothing but the gentle lean of its own wheeling.
 *
 * ## One colour per bird
 *
 * A bird is a **silhouette**. There is no second fill, no dark primaries, no tip
 * of a different colour - the first version had all three, and pale wings ending
 * in slate read as a decal rather than as an animal. The contrast that used to
 * come from the tips now comes from the palette: below the anvil the sky is the
 * bright thing and the flock is dark against it, and above the anvil that
 * inverts, because at 25 km the sky is black and the birds are the only thing the
 * sun is still on. See `AIR_ZONES` in `config/zones.ts`.
 *
 * ## The breath is in the wings
 *
 * The flock **beats hard on the inhale and eases on the exhale**. This is the
 * single most visible place the 11-second breath touches the game, and it is
 * diegetic rather than decorative: flapping is the work of flying and easing off
 * is the rest between. Paired with `Wings.ts`, which quiets the wingbeat stream
 * on the same half of the cycle, the picture and the sound agree about something
 * the player is doing with their own body.
 *
 * `glide` is how much of the beat *survives* the exhale, and every value in the
 * table is high: a flock that stops beating is a flock of paper darts, and the
 * breath is supposed to be felt in the effort rather than seen as a switch.
 */

import { TAU, clamp } from '../core/math';

/** Stations sampled from wing root (0) to tip (1). Five, like the fish's spine. */
const STATIONS = [0, 0.3, 0.58, 0.82, 1] as const;

export interface Bird {
  key: string;
  /** Body length multiplier. */
  len: number;
  /** Body half-width multiplier. All `across` values below are in these units. */
  wid: number;
  /**
   * Wing half-span, in body half-widths. The silhouette's first fact, and the
   * one most easily drawn too small.
   *
   * A bird seen from above is far wider than it is long - a shearwater is 90 cm
   * across and 35 cm from bill to tail, a buzzard 120 against 52 - so the numbers
   * here put the full span at about **two and a half times the total length** for
   * every species in the table. The first set was half that, which is why the
   * flock read as crosses however good the planform was.
   */
  span: number;
  /**
   * How far behind the shoulder the leading edge sits at each station, as a
   * fraction of body length. The wing's *sweep*, sampled.
   *
   * Read the rows and you can see the **wrist** in them: the first three numbers
   * are almost flat, because the arm of a bird's wing goes out nearly square to
   * the body, and then the last two run away, because the hand is swept. That
   * kink is the single most recognisable thing about a bird's outline from above,
   * and a smoothly-swept wing without it reads as a paper aeroplane.
   */
  lead: readonly [number, number, number, number, number];
  /**
   * Chord at each station, as a fraction of body length: how much wing hangs
   * behind the leading edge. This is the number that separates a broad soarer
   * from a thin one, and it does more work than the span does.
   *
   * It **holds** through the arm and only tapers over the hand, for the same
   * anatomical reason: the inner wing is a slab of secondaries of near-constant
   * length, and everything that narrows is out past the wrist.
   */
  chord: readonly [number, number, number, number, number];
  /** Slotted primaries on the outer trailing edge. 0 is a sealed wing. */
  fingers: number;
  /** Body surge per beat, as a fraction of body length. Thrust, made visible. */
  surge: number;
  /** How far the head projects ahead of the shoulders, and its half-width. */
  head: number;
  headWide: number;
  /** Tail length as a fraction of body length. */
  tail: number;
  /**
   * Tail half-spread at the corners, in body half-widths.
   *
   * Kept deliberately narrow across the whole set. A wide fork is correct on a
   * tern and wrong here, because at flock size two long tail prongs behind two
   * swept wings stop reading as a bird and start reading as a four-pointed star -
   * measured by looking at twenty-five of them on a phone-sized frame.
   */
  fork: number;
  /**
   * Where the tail's centre sits, as a fraction of `tail`. Under 1 is a forked
   * tail (a tern, a swift); over 1 is a fan (a soaring raptor). One number, and
   * it is most of what tells two birds apart at ten pixels.
   */
  notch: number;
  /** Wingbeat rate multiplier. Big wings beat slowly - see `Wings.ts`. */
  beat: number;
  /**
   * How much the span foreshortens at the top of the upstroke, 0..1.
   *
   * Small, and it was twice this to begin with. At 0.6 the wing lost two thirds
   * of its span on the recovery and the bird turned into an arrowhead once a
   * beat - which is a legible *animation* and a terrible *animal*. Seen from
   * directly above a real upstroke costs about a quarter of the span; the rest of
   * what the eye reads as a beat is the hand sweeping back, which is why that
   * term is now the larger of the two.
   */
  flap: number;
  /**
   * Fraction of the beat that survives on the exhale, 0..1. Never near zero: a
   * bird that stops beating looks dead, and what a big wing does on the rest half
   * is *ease*, not freeze.
   */
  glide: number;
  /** Warm/cool shift applied to the flock colour. See `temper` in Paint.ts. */
  tint: number;
}

/**
 * Bird 0 is the flock the act starts with. The rest arrive in rings and keep
 * their shape after they merge, exactly as the fish species do - so a grown flock
 * is visibly one the player assembled.
 *
 * They are different *planforms* first, tail shape second and tint a distant
 * third, because colour is the first thing a bright sky takes away from you. Read
 * the `chord` rows against each other and the set is legible on the page: 0.30
 * falling to 0.09 is a seabird's stiff blade, 0.20 barely moving at all is an
 * albatross, 0.52 falling to 0.24 with four fingers on the end is a buzzard
 * circling, and 0.24 collapsing to 0.05 is a swift.
 *
 * None of them is a predator. Act II's threat is a different animal drawn by a
 * different file (`Raptor.ts`) - a bird of prey has to be recognisable *as* one
 * before it does anything, and the way to guarantee that is to keep its shape out
 * of the flock entirely.
 */
export const BIRDS: readonly Bird[] = [
  {
    // Shearwater: the act's own bird. Long, narrow, stiff-winged, built to hold a
    // line in moving air for an hour without a beat - which is also the thing the
    // player is learning to do.
    key: 'shear',
    len: 1,
    wid: 1,
    span: 10.5,
    lead: [0, 0.015, 0.06, 0.15, 0.26],
    chord: [0.48, 0.46, 0.36, 0.23, 0.13],
    fingers: 0,
    surge: 0.05,
    head: 0.15,
    headWide: 0.5,
    tail: 0.3,
    fork: 0.62,
    notch: 0.78,
    beat: 1.0,
    flap: 0.26,
    glide: 0.55,
    tint: -0.3,
  },
  {
    // Storm petrel: the smallest thing up here, and the busiest. Short broad wings
    // held with a kink, a square tail, and a beat you can see from the ground.
    key: 'petrel',
    len: 0.8,
    wid: 1.12,
    span: 8.6,
    lead: [0, 0.015, 0.055, 0.13, 0.22],
    chord: [0.55, 0.53, 0.43, 0.27, 0.14],
    fingers: 0,
    surge: 0.07,
    head: 0.12,
    headWide: 0.62,
    tail: 0.26,
    fork: 0.75,
    notch: 0.92,
    beat: 1.45,
    flap: 0.33,
    glide: 0.5,
    tint: 0.95,
  },
  {
    // Albatross: the longest, thinnest wing in nature, and almost no beat at all.
    // The chord row hardly moves from root to tip - that constant narrow blade is
    // the entire animal, and it is why one of these among fifty shearwaters is
    // recognisable without a single pixel of colour.
    key: 'albatross',
    len: 1.28,
    wid: 0.84,
    span: 14,
    lead: [0, 0.008, 0.03, 0.075, 0.13],
    chord: [0.44, 0.43, 0.4, 0.31, 0.18],
    fingers: 0,
    surge: 0.03,
    head: 0.22,
    headWide: 0.44,
    tail: 0.24,
    fork: 0.4,
    notch: 1.05,
    beat: 0.6,
    flap: 0.22,
    glide: 0.68,
    tint: -0.95,
  },
  {
    // Buzzard: broad, deeply fingered, tail spread into a fan. The soarer's
    // silhouette - the one shape in the set that is as wide at the wrist as it is
    // at the shoulder, which is what circling in rising air asks of a wing.
    key: 'buzzard',
    len: 0.95,
    wid: 1.22,
    span: 9.2,
    lead: [0, 0.02, 0.07, 0.16, 0.27],
    chord: [0.66, 0.65, 0.56, 0.4, 0.24],
    fingers: 3,
    surge: 0.05,
    head: 0.12,
    headWide: 0.58,
    tail: 0.36,
    fork: 0.95,
    notch: 1.3,
    beat: 0.85,
    flap: 0.24,
    glide: 0.6,
    tint: 0.45,
  },
  {
    // Swift: two scythes and almost nothing else. It has the steepest sweep and
    // the thinnest tip in the set, and its tail is a deep fork - the only bird
    // here that reads as a shape rather than as a bird, which is correct, because
    // that is exactly how a swift reads against a real sky.
    key: 'swift',
    len: 1.02,
    wid: 0.88,
    span: 11.5,
    lead: [0, 0.045, 0.16, 0.34, 0.5],
    chord: [0.42, 0.38, 0.25, 0.13, 0.07],
    fingers: 0,
    surge: 0.06,
    head: 0.13,
    headWide: 0.5,
    tail: 0.34,
    fork: 0.55,
    notch: 0.56,
    beat: 1.3,
    flap: 0.3,
    glide: 0.52,
    tint: 0.15,
  },
];

export function birdAt(index: number): Bird {
  return BIRDS[index >= 0 && index < BIRDS.length ? index : 0]!;
}

/**
 * The body frame, and the three numbers that decide whether this is a bird or a
 * dagger.
 *
 * The first version had the wing root occupying about a fifth of the animal's
 * length with the neck in front of it and a long spike behind, so the silhouette
 * was a **cross**: a stick with a short bar across it. Measure a real bird from
 * above and the proportions are nothing like that - the wing meets the body over
 * roughly *half* its length, and the head and the tail get about a quarter each.
 *
 * So the trailing edge of the wing root lands exactly on `TAIL_BASE`, which is
 * what a bird's secondaries actually do: they run back to where the tail starts,
 * and there is no bare body between the two.
 */
const NOSE = 0.42;
const TAIL_BASE = -0.24;
/** Where the wing's leading edge meets the body, behind the nose. */
const SHOULDER = 0.18;

/**
 * How much of the wingbeat is running right now, 0..1.
 *
 * `breath01` is 1 fully inhaled. On the inhale the flock beats at full
 * amplitude; on the exhale it falls back to the species' own `glide` floor. The
 * curve is the breath's, so the two turns are the smooth stops `Breath.ts` was
 * written to have - a flock that snapped between beating and gliding would be a
 * flock with a switch in it.
 */
export function beatAmount(breath01: number, glide: number): number {
  const b = breath01 < 0 ? 0 : breath01 > 1 ? 1 : breath01;
  return glide + (1 - glide) * b;
}

/**
 * The wingbeat phase for one individual at one instant.
 *
 * **Nothing in here may depend on anything that changes per frame**, and that is
 * the whole reason this is a named function with a test on it rather than a line
 * inside the renderer.
 *
 * The phase is `clock * rate`, and `clock` is unbounded. A rate that moves at all
 * therefore rewrites the *entire accumulated phase*, retroactively, every time it
 * moves. The renderer used to fold the agent's instantaneous speed into the rate
 * - which is a perfectly reasonable-looking way to say "it beats faster when it
 * is working harder" - and twenty seconds into a run the ordinary frame-to-frame
 * wobble in that speed was worth about three radians of phase per frame. The
 * flock did not beat, it *vibrated*.
 *
 * Effort is still readable, but through amplitude, which is bounded and cannot
 * accumulate. `tests/flock.test.ts` pins the consequence directly: the drawn span
 * may not jump between two consecutive frames.
 */
export function beatPhase(clock: number, b: Bird, variation: number, seed: number): number {
  // `variation` is a narrow 0.92-1.08 and has to be widened before it reads as a
  // tempo at all: a flock where every bird beats at one rate has a metronome in
  // it. Constant per individual, so it is safe to multiply a clock by - and it is
  // **inverted**, because a bigger wing beats more slowly. That is the same
  // allometric line `Wings.ts` picks its frequencies off, so the flock's sound and
  // its picture disagree about nothing.
  const tempo = clamp(1 - (variation - 1) * 4, 0.7, 1.35);
  return clock * TAU * b.beat * tempo + seed * 2;
}

/**
 * Where an individual *wants* to face, written into `BEARING` as a unit vector.
 * Returns `drive`, 0..1: how much of that target came from genuine travel.
 *
 * **A slow bird must not be pointed at its own velocity.** An individual held on
 * a point - one waiting inside a ring, or any bird the flock has stalled -
 * reaches its anchor and then sits there with a velocity that is almost entirely
 * the simulation's wander term. Its *magnitude* is meaningless and its
 * *direction* is noise, so below a walking pace the target is a slow
 * deterministic wheel instead. That is not a fudge: a bird cannot hover, and
 * what one holding station actually does is circle. The velocity is blended in
 * as the individual starts to genuinely travel, so there is no threshold
 * anything snaps across.
 *
 * This is the **target**, not the pose. The blend silences a slow bird's noise,
 * but a bird can be fast and still incoherent - one boxed in a rescue ring
 * schools at full pace inside a cage a few body-lengths wide, so its velocity
 * direction is fast, real, and reverses every few frames. Nothing draws this
 * vector raw: the drawn heading is `steerBearing`, below.
 *
 * A shared out-param rather than a returned pair, for the reason everything else
 * in this file is: it runs once per bird per frame and must not allocate.
 */
export const BEARING = { x: 0, y: -1 };

/** Below this speed (px/s) an individual is holding station, not travelling. */
const HOLD_SPEED = 8;
const TRAVEL_SPEED = 42;

export function bearing(vx: number, vy: number, clock: number, phase: number): number {
  const speed = Math.hypot(vx, vy);
  const drive = clamp((speed - HOLD_SPEED) / (TRAVEL_SPEED - HOLD_SPEED), 0, 1);
  const rest = -Math.PI / 2 + Math.sin(clock * 0.33 + phase * 1.7) * 0.5;
  let dx = Math.cos(rest);
  let dy = Math.sin(rest);
  if (drive > 0) {
    dx += (vx / speed - dx) * drive;
    dy += (vy / speed - dy) * drive;
    const len = Math.hypot(dx, dy) || 1;
    dx /= len;
    dy /= len;
  }
  BEARING.x = dx;
  BEARING.y = dy;
  return drive;
}

/*
 * How fast a heading may actually change, in rad/s of renderer time. A holding
 * bird wheels, a travelling bird carves, a fleeing bird whips round - but none
 * of them teleports, and these numbers are the whole guarantee. `TURN_RUSH`
 * raises the ceiling with real speed, so a raptor scattering the flock still
 * reads as panic rather than as birds turning through treacle.
 */
const TURN_HOLD = 0.8;
/** Added on top of `TURN_HOLD` at full drive. */
const TURN_TRAVEL = 1.4;
/** Extra rad/s per px/s beyond `TRAVEL_SPEED`. */
const TURN_RUSH = 0.005;
/** How quickly the heading closes on its target (1/s): the low-pass that eats noise. */
const TURN_CHASE = 6;

/**
 * The drawn heading: a persistent angle steered toward `bearing`'s target,
 * never faster than a bird can turn.
 *
 * Decision 51 pointed a slow bird at a wheel instead of at its own noise, and
 * that was half the fix: the blend runs out at `TRAVEL_SPEED`, and the birds the
 * report was actually about are *faster* than that. An individual caged in a
 * rescue ring reverses course every few frames at full schooling pace, a
 * drifting flock cruises just over the blend's ceiling - and in both cases the
 * widest silhouette in the game snapped to every swing of a raw velocity. The
 * fix is the one thing a stateless function cannot provide: **yaw inertia.**
 * The heading is per-bird state, chased toward the target and clamped to a turn
 * rate, so a caged bird wheels inside its ring and a drifting flock weaves
 * instead of twitching.
 *
 * `prev` is the angle this returned last frame, or NaN for a bird with no
 * history - a fresh spawn faces its target at once rather than slewing in from
 * wherever the slot's last occupant pointed. `dt = 0` returns `prev` untouched:
 * a paused flock holds its pose. The unit vector lands in `BEARING`; the caller
 * keeps the angle.
 *
 * The step this takes per frame is bounded by construction, which is what lets
 * the renderer read `roll` straight off it: a bank derived from a clamped yaw
 * rate cannot flicker, where one derived from a per-step displacement did.
 */
export function steerBearing(
  prev: number,
  vx: number,
  vy: number,
  clock: number,
  phase: number,
  dt: number,
): number {
  const drive = bearing(vx, vy, clock, phase);
  const target = Math.atan2(BEARING.y, BEARING.x);
  if (!Number.isFinite(prev)) return target;
  // The short way round, so the seam at +-pi is not a lap of the compass.
  let d = target - prev;
  d -= TAU * Math.round(d / TAU);
  const speed = Math.hypot(vx, vy);
  const rate = TURN_HOLD + TURN_TRAVEL * drive + Math.max(0, speed - TRAVEL_SPEED) * TURN_RUSH;
  const limit = rate * dt;
  const step = clamp(d * Math.min(1, TURN_CHASE * dt), -limit, limit);
  const angle = prev + step;
  BEARING.x = Math.cos(angle);
  BEARING.y = Math.sin(angle);
  return angle;
}

/*
 * Frame for the bird being traced right now. Module-level for the same reason
 * `FishShapes` does it: this runs once per bird per frame, and a closure per call
 * is thousands of short-lived allocations a second. Single-threaded, never
 * re-entered.
 */
let fx = 0;
let fy = 0;
let fdx = 0;
let fdy = 0;
let fnx = 0;
let fny = 0;
let flen = 0;
let fwid = 0;
let shape: CanvasRenderingContext2D;

function put(along: number, across: number, first = false): void {
  const ax = along * flen;
  const ac = across * fwid;
  const px = fx + fdx * ax + fnx * ac;
  const py = fy + fdy * ax + fny * ac;
  if (first) shape.moveTo(px, py);
  else shape.lineTo(px, py);
}

/** A quadratic segment in the same frame: one control point, one destination. */
function putQ(cAlong: number, cAcross: number, along: number, across: number): void {
  const cax = cAlong * flen;
  const cac = cAcross * fwid;
  const ax = along * flen;
  const ac = across * fwid;
  shape.quadraticCurveTo(
    fx + fdx * cax + fnx * cac,
    fy + fdy * cax + fny * cac,
    fx + fdx * ax + fnx * ac,
    fy + fdy * ax + fny * ac,
  );
}

/*
 * The wing as the tracers see it.
 *
 * `wAcross`/`wLead`/`wTrail` are the five stations - span position and the two
 * `along` coordinates - and `wOut` is the whole outline walked once, root along
 * the leading edge, round the tip, back along the trailing edge to the root, as
 * `along, across` pairs.
 *
 * The outline is a point list rather than a run of curves for one reason: the
 * left wing is the right wing walked **backwards**, and a quadratic reversed is a
 * different curve unless you also swap its control point. Points reverse for
 * free, so the two wings are guaranteed identical and the fingered trailing edge
 * costs nothing extra to mirror. Both are module-level out-params for the usual
 * reason: this runs per bird per frame and must not allocate.
 */
const wAcross = [0, 0, 0, 0, 0];
const wLead = [0, 0, 0, 0, 0];
const wTrail = [0, 0, 0, 0, 0];
const wOut = new Float64Array(48);
let wCount = 0;

function emit(along: number, across: number): void {
  wOut[wCount * 2] = along;
  wOut[wCount * 2 + 1] = across;
  wCount++;
}

/**
 * A wingbeat has **two** motions in it, and getting either one alone is what
 * makes a drawn bird look like a mechanism.
 *
 * `sweepAt` is the continuous one: the tips lead on the downstroke and trail on
 * the upstroke, tracing a fore-and-aft arc that never stops moving. A wing that
 * only foreshortens is a rubber band; a wing that only sweeps is a windscreen
 * wiper. Both, together, are a bird.
 *
 * `foldAt` is the asymmetric one, and it is why this file is not a sine. A
 * wingbeat is a pull and a recovery, not an oscillation: the wrist stays locked
 * through the **downstroke**, which is the half that does the work, and breaks
 * through the **upstroke** to get the wing back up cheaply. So the fold is
 * essentially nothing across one half of the cycle and peaks in the middle of
 * the other - `max(0, -sin)`, smoothstepped so it leaves zero without a corner.
 *
 * The first version of this had only the fold, and the flock came out visibly
 * *frozen* for half of every beat: four identical frames, then a fold, then four
 * identical frames again. It is the exact shape of the mistake `FishShapes` was
 * written to avoid - a wave with no travel in it is a shape with a switch on it.
 */
function sweepAt(beat: number): number {
  return Math.sin(beat);
}

function foldAt(beat: number): number {
  const t = Math.max(0, -Math.sin(beat));
  return t * t * (3 - 2 * t);
}

/** The forward creep the downstroke buys, in body lengths. See `Bird.surge`. */
export function surgeAt(b: Bird, beat: number, amount: number): number {
  return b.surge * amount * Math.sin(beat);
}

/**
 * Where every station of the wing is, at this instant of the beat, and the
 * outline that follows from it.
 *
 * `roll` 0..1 is how hard the bird is banking. Both wings foreshorten together
 * when it does, because a roll is about the body's own axis - which is why a
 * banking bird seen from above is unmistakable, and why a flock that banks into
 * its turns stops looking like sprites being slid around.
 */
function wingFrame(b: Bird, beat: number, amount: number, roll: number, fingers: number): void {
  const sweep = sweepAt(beat) * amount;
  // 0 with the wing out, 1 at the top of the upstroke.
  const work = b.flap * amount * foldAt(beat);
  const bank = 1 - 0.42 * roll;
  const shoulder = NOSE - SHOULDER;
  for (let i = 0; i < STATIONS.length; i++) {
    const u = STATIONS[i]!;
    // Span: it collapses as the wrist folds - the ray's observation - stretches a
    // little at full power, and shortens again when the whole animal rolls into a
    // turn. The small continuous term matters more than its size suggests: it is
    // what keeps the downstroke from being four identical frames.
    wAcross[i] = b.span * u * (1 - work) * (1 + 0.07 * sweep * u) * bank;
    // The hand's fore-and-aft arc, quadratic in u because the tip travels
    // furthest: forward at full power, trailing as the wrist breaks.
    const back = b.lead[i]! - 0.22 * u * u * sweep + work * 1.5 * u * u * (1 + b.span * 0.03);
    // The outer chord narrows as the hand rotates out of plane.
    const chord = b.chord[i]! * (1 - work * 0.4 * u);
    // The arm bows forward of the straight shoulder-to-tip line. Every soaring
    // wing does this, and its absence is what made the first flock read as an
    // arrowhead - so it is baked into the station rather than left to a curve.
    const bow = 0.055 * Math.sin(u * Math.PI) * (1 - b.lead[4]!);
    wLead[i] = shoulder - back + bow;
    wTrail[i] = shoulder - back - chord;
  }
  // The root is the body, not a point on a curve: both edges start on the flank.
  wAcross[0] = 1;

  wCount = 0;
  for (let i = 0; i < STATIONS.length; i++) emit(wLead[i]!, wAcross[i]!);
  // The tip is squared off: a wing ends in feathers, not at a point.
  emit(wTrail[4]!, wAcross[4]!);
  for (let i = STATIONS.length - 2; i >= 0; i--) {
    // Slotted primaries: each is a notch cut forward into the trailing edge, and
    // the gaps between them are what a broad wing uses instead of a longer one.
    // Only on the outer two panels, where the gaps are actually visible.
    if (fingers > 0 && i >= 2) {
      const steps = i === 3 ? Math.min(2, fingers) : Math.max(1, fingers - 2);
      for (let k = 0; k < steps; k++) {
        const t = (k + 1) / (steps + 1);
        const along = wTrail[i + 1]! + (wTrail[i]! - wTrail[i + 1]!) * t;
        const across = wAcross[i + 1]! + (wAcross[i]! - wAcross[i + 1]!) * t;
        emit(along + b.chord[i]! * 0.34, across);
        emit(along, across);
      }
    }
    emit(wTrail[i]!, wAcross[i]!);
  }
}

/**
 * Traces one bird into the current path. `dx,dy` must be a unit heading.
 * `beat` is the wingbeat phase in radians; `amount` is `beatAmount` above;
 * `detail` adds the slotted primaries of a fingered wing; `roll` 0..1 is how
 * hard it is banking.
 *
 * This is the **whole** bird - there is no second pass over it in another
 * colour. Allocation-free: every point is two multiply-adds emitted straight to
 * the context, so a whole species is one fill however many birds are in it.
 */
export function traceBird(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  dx: number,
  dy: number,
  len: number,
  wid: number,
  b: Bird,
  beat: number,
  amount: number,
  detail: boolean,
  roll = 0,
): void {
  shape = ctx;
  // The downstroke's thrust, as a shift along the heading. Small - a twentieth
  // of a body length - and it is most of what makes a beat read as effort.
  const push = surgeAt(b, beat, amount) * len;
  fx = x + dx * push;
  fy = y + dy * push;
  fdx = dx;
  fdy = dy;
  fnx = -dy;
  fny = dx;
  flen = len;
  fwid = wid;

  wingFrame(b, beat, amount, roll, detail ? b.fingers : 0);
  // A banking bird fans its tail: that is how it turns, and it is the second
  // cue the eye reads a turn from after the wings shortening. It also opens a
  // little on the power stroke and closes on the recovery, which is the one part
  // of the animal behind the wings that has any business moving.
  const fork = b.fork * (1 + 0.34 * roll + 0.16 * sweepAt(beat) * amount);
  const tailTip = TAIL_BASE - b.tail;

  // --- the head, out along the right wing, and back down the body ---
  put(NOSE + b.head, 0, true);
  // A round head on a neck, not a point. It is the one part of the outline that
  // never moves through a beat, which is what the eye locks on to.
  putQ(NOSE + b.head * 0.7, b.headWide * 0.95, NOSE - 0.04, b.headWide);
  putQ(wLead[0]! + 0.08, 1, wLead[0]!, 1);
  for (let i = 1; i < wCount; i++) put(wOut[i * 2]!, wOut[i * 2 + 1]!);
  // Back along the flank to the tail.
  putQ(wTrail[0]! - 0.12, 0.88, TAIL_BASE, 0.5);
  // --- tail: right corner, centre, left corner ---
  put(tailTip, fork);
  put(TAIL_BASE - b.tail * b.notch, 0);
  put(tailTip, -fork);
  // --- the left wing: the same outline walked backwards, so the two are exact ---
  put(TAIL_BASE, -0.5);
  putQ(wTrail[0]! - 0.12, -0.88, wOut[(wCount - 1) * 2]!, -wOut[(wCount - 1) * 2 + 1]!);
  for (let i = wCount - 2; i >= 0; i--) put(wOut[i * 2]!, -wOut[i * 2 + 1]!);
  putQ(wLead[0]! + 0.08, -1, NOSE - 0.04, -b.headWide);
  putQ(NOSE + b.head * 0.7, -b.headWide * 0.95, NOSE + b.head, 0);
  ctx.closePath();
}
