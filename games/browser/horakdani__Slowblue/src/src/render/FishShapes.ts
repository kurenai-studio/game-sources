/**
 * Slowblue: the fish, seen from directly above.
 *
 * Every individual used to be a triangle, which is what you draw when the camera is
 * anywhere. This camera is over the water looking down, so a fish is a spindle with
 * two pectoral fins and a tail behind it - and, crucially, it *swims*: the outline is
 * built around a spine that carries a travelling wave, so the body flexes and the
 * tail sweeps. Nothing is animated by the simulation; the wave is a function of the
 * swarm clock, the individual's phase and its speed, so it costs no state at all.
 *
 * The outline is traced straight into the caller's path, so a whole species is still
 * one `fill()` no matter how many fish are in it.
 */
export interface Species {
  key: string;
  /** Body length multiplier. */
  len: number;
  /** Body width multiplier. */
  wid: number;
  /**
   * Half-width as a fraction of `wid`, sampled nose -> tail base. The first entry
   * is the bluntness of the snout: 0 is a pointed dart, higher is a rounded head.
   */
  profile: readonly [number, number, number, number, number];
  /** Tail length as a fraction of body length. */
  tail: number;
  /** Tail fork half-spread, as a multiple of body half-width. */
  fork: number;
  /** Pectoral fin reach. 0 = no fins. */
  fin: number;
  /** Tail-beat frequency multiplier. */
  beat: number;
  /** How far the body flexes side to side. */
  swim: number;
  /**
   * How much of the travelling wave fits along the body, as a multiple of the
   * default lag.
   *
   * 1 for everything short. A dart is bent one way along its whole length at any
   * instant, which is all a short body has room for. Above 1 a crest reaches the
   * tail while the next one is still forming at the shoulder, so the body carries
   * an S rather than a C - and that, not amplitude, is the difference between a
   * fish swimming and a fish wagging. It costs a long body to show: on a short one
   * the same lag only makes the head and tail disagree, which reads as a kink.
   */
  wave: number;
  /**
   * How much the body's width itself pulses with the beat. 0 for a fish, whose
   * width is fixed while its spine bends; a ray has no spine worth bending and
   * swims by flapping its wings, which from above is exactly a width that breathes.
   */
  flap: number;
  /**
   * Barbel reach, as a multiple of body length. 0 for everything that has none.
   *
   * The only part of any outline in this file that the spine does not carry, and
   * the only one that trails rather than being driven: a catfish's feelers are
   * slack filaments in moving water, and they answer the beat a beat late and
   * on their own. They cost half again what a pair of fins costs and they are the
   * reason the silhouette is recognisable from directly above.
   */
  whisker: number;
  /** Warm/cool shift applied to the shoal colour. See `temper` in Paint.ts. */
  tint: number;
}

/**
 * Species 0 is the shoal the run starts with. The rest arrive in rescue pods and keep
 * their shape after they merge, so a grown shoal is visibly one you assembled.
 * They are deliberately different *silhouettes*, not just different colours - colour
 * alone disappears the moment the zone palette moves.
 */
export const SPECIES: readonly Species[] = [
  {
    key: 'dart',
    len: 1,
    wid: 1,
    profile: [0, 0.5, 0.44, 0.24, 0.07],
    tail: 0.34,
    fork: 0.6,
    fin: 0.3,
    beat: 1,
    swim: 0.45,
    wave: 1,
    flap: 0,
    whisker: 0,
    tint: -0.3,
  },
  {
    key: 'disc',
    len: 0.8,
    wid: 1.65,
    profile: [0.3, 0.78, 0.7, 0.34, 0.09],
    tail: 0.24,
    fork: 0.85,
    fin: 0.55,
    beat: 0.75,
    swim: 0.3,
    wave: 1,
    flap: 0,
    whisker: 0,
    tint: 0.95,
  },
  {
    key: 'needle',
    len: 1.45,
    wid: 0.8,
    profile: [0, 0.32, 0.3, 0.19, 0.05],
    tail: 0.38,
    fork: 0.4,
    fin: 0.16,
    beat: 1.4,
    swim: 0.9,
    wave: 1,
    flap: 0,
    whisker: 0,
    tint: -0.95,
  },
  {
    key: 'fan',
    len: 0.95,
    wid: 1.15,
    profile: [0.12, 0.4, 0.6, 0.4, 0.1],
    tail: 0.46,
    fork: 1.05,
    fin: 0.5,
    beat: 0.68,
    swim: 0.5,
    wave: 1,
    flap: 0,
    whisker: 0,
    tint: 0.45,
  },
  {
    // Wider than it is long, and it has no tail fin at all - just a whip. The one
    // silhouette in the set that is unmistakable at ten pixels.
    key: 'ray',
    len: 0.8,
    wid: 2.4,
    profile: [0.08, 0.95, 0.62, 0.16, 0.04],
    tail: 1.5,
    fork: 0.07,
    fin: 0,
    beat: 0.55,
    swim: 0.22,
    wave: 1,
    flap: 0.34,
    whisker: 0,
    tint: 0.15,
  },
  {
    /*
     * The catfish, and the only one in the set the player will name out loud.
     *
     * Every other silhouette here is an abstraction the eye sorts by proportion -
     * long, squat, forked, winged. This one is a specific animal, and it is built
     * out of the three things that make a catfish a catfish when you are looking
     * straight down at it: a broad blunt head, a body that narrows away from that
     * head and keeps narrowing all the way to a thin wrist in front of the tail,
     * and the feelers. The barbels carry the recognition; the proportions carry
     * it once the barbels are gone, which is what happens on a slow device, so
     * both have to work alone.
     *
     * The longest body in the set and the second narrowest, and it is the *ratio*
     * that does the work. An earlier cut was nearly as long but half again as
     * wide, with the width held to four fifths of the way back, and what that
     * draws is a tadpole: one fat blob and a thread. The profile row here falls
     * 0.92 -> 0.60 -> 0.33 -> 0.15, which is a taper you can see happening rather
     * than a body that ends.
     *
     * Slow, deep and long-waved, in that order. `flex` is measured in half-widths,
     * so a slender fish gets a deeper wave out of the same `swim` than a broad one
     * does; `beat` is the slowest here, because a fish this size sculls and does
     * not dart; and `wave` above 1 is what a body this long is *for* - the crest
     * has room to travel, so the middle is still leaning one way while the tail
     * has already gone the other. Nothing else in the file can show that: the dart
     * is too short to hold two crests and the ray has no spine to put one in.
     *
     * `fork` is not a taste decision. The tail tip and the notch read the wave at
     * different points down the spine, so they swing by different amounts, and if
     * the fork is narrower than the gap between them the notch crosses a tip and
     * the fin turns inside out - which is what draws a torn spike instead of a
     * tail, once a beat, at every size. It is the defect this fish arrived with:
     * a fork of 0.34 against a gap of 0.45. At this wave the gap runs to
     * 0.79 * swim, or 0.54 of a half-width, and 0.74 keeps the notch a seventh of
     * the spread clear of either tip at its worst phase. `tests/fish.test.ts`
     * measures exactly that, so none of the three numbers can be tuned into it
     * again by eye.
     */
    key: 'barbel',
    len: 1.95,
    wid: 1,
    profile: [0.5, 0.82, 0.44, 0.24, 0.11],
    tail: 0.42,
    fork: 0.74,
    fin: 0.16,
    beat: 0.5,
    swim: 0.68,
    wave: 1.25,
    flap: 0,
    whisker: 1.35,
    tint: 0.7,
  },
];

export function speciesAt(index: number): Species {
  return SPECIES[index >= 0 && index < SPECIES.length ? index : 0]!;
}

/** Where each spine sample sits along the body, nose (0) to tail base (1). */
const SPINE = [0, 0.28, 0.55, 0.78, 1] as const;
/** Nose sits this far in front of the origin, tail base this far behind. */
const NOSE = 0.62;
const TAIL_BASE = -0.38;
/**
 * Phase lag down the body, for a species with `wave` of 1. This is what makes the
 * flex a wave and not a wobble, and scaling it per species is what lets one long
 * fish carry an S while the short ones carry a C.
 */
const WAVE_LAG = 2.4;

/** Lateral offset of the spine at `s`, in body half-widths. */
function flex(s: number, beat: number, sp: Species): number {
  // s^1.5: the nose barely moves and the tail does most of it, like a real fish.
  return sp.swim * Math.pow(s, 1.5) * Math.sin(beat - s * WAVE_LAG * sp.wave);
}

/**
 * Half-width multiplier at `s`. Always 1 for a fish. A ray's wings beat, and from
 * directly above a wing beat is a width that swells and narrows - the wave runs out
 * from the middle of the disc, so the two wings are never quite in step.
 */
function beatWidth(s: number, beat: number, sp: Species): number {
  if (sp.flap === 0) return 1;
  return 1 + sp.flap * Math.sin(beat - s * WAVE_LAG * sp.wave * 0.45);
}

/*
 * Frame for the fish being traced right now. Module-level rather than captured in a
 * closure because `traceFish` runs once per fish per frame: a closure per call is
 * thousands of short-lived allocations a second for no benefit. Single-threaded and
 * never re-entered, so a shared frame is safe.
 */
let fx = 0;
let fy = 0;
let fdx = 0;
let fdy = 0;
let fnx = 0;
let fny = 0;
let flen = 0;
let fwid = 0;

function put(along: number, across: number, first = false): void {
  const ax = along * flen;
  const ac = across * fwid;
  const px = fx + fdx * ax + fnx * ac;
  const py = fy + fdy * ax + fny * ac;
  if (first) shape.moveTo(px, py);
  else shape.lineTo(px, py);
}

let shape: CanvasRenderingContext2D;

/**
 * Traces one fish into the current path. `dx,dy` must be a unit heading.
 * Allocation-free: every point is two multiply-adds emitted straight to the context.
 */
export function traceFish(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  dx: number,
  dy: number,
  len: number,
  wid: number,
  sp: Species,
  beat: number,
  fins: boolean,
): void {
  shape = ctx;
  fx = x;
  fy = y;
  fdx = dx;
  fdy = dy;
  fnx = -dy;
  fny = dx;
  flen = len;
  fwid = wid;

  // --- body: down the right flank, round the tail, back up the left ---
  // `profile[0]` is the bluntness of the snout. Zero gives a pointed dart; anything
  // above it gives a rounded head, which is the whole difference between a fish and
  // a rhombus once the body is short and wide.
  const noseFlex = flex(0, beat, sp);
  const noseWide = sp.profile[0]! * beatWidth(0, beat, sp);
  put(NOSE, noseFlex + noseWide, true);
  for (let i = 1; i < SPINE.length; i++) {
    const s = SPINE[i]!;
    put(NOSE - s, flex(s, beat, sp) + sp.profile[i]! * beatWidth(s, beat, sp));
  }
  const tailBase = TAIL_BASE - sp.tail;
  const tipFlex = flex(1.25, beat, sp);
  const notchFlex = flex(1.05, beat, sp);
  put(tailBase, tipFlex + sp.fork);
  put(TAIL_BASE - sp.tail * 0.42, notchFlex);
  put(tailBase, tipFlex - sp.fork);
  for (let i = SPINE.length - 1; i >= 1; i--) {
    const s = SPINE[i]!;
    put(NOSE - s, flex(s, beat, sp) - sp.profile[i]! * beatWidth(s, beat, sp));
  }
  put(NOSE, noseFlex - noseWide);
  ctx.closePath();

  if (!fins) return;
  traceWhiskers(ctx, sp, beat);
  if (sp.fin <= 0) return;
  /*
   * --- pectoral fins, sweeping a little out of phase with the tail ---
   *
   * Wound the same way as the body, which means the left one is emitted
   * backwards. Mirroring a subpath reverses its winding, and `fill()` uses the
   * nonzero rule, so for a long time the left fin was a *hole* wherever it lay
   * over the flank it hangs off - a notch that read as fin definition on a dart,
   * because a dart's fin is nearly all outside its body, and a black wedge bitten
   * out of the head on anything broad enough for the fin to sit inside it.
   * Measured, not guessed: the two subpaths came back with signed areas of
   * +7.43 and -7.43.
   */
  const s = SPINE[1]!;
  const root = flex(s, beat, sp);
  const spread = sp.profile[1]! + sp.fin * (0.85 + 0.3 * Math.sin(beat * 1.3 + 1.1));
  const finA = [NOSE - s, NOSE - s - 0.2, NOSE - s - 0.3];
  const finC = [sp.profile[1]!, spread, sp.profile[2]! * 0.9];
  for (const side of [1, -1] as const) {
    for (let k = 0; k < finA.length; k++) {
      const i = side > 0 ? k : finA.length - 1 - k;
      put(finA[i]!, root + finC[i]! * side, k === 0);
    }
    ctx.closePath();
  }
}

/**
 * The barbels, for the one species that has them.
 *
 * A pair of filaments rooted in the corners of the snout, leaving the head
 * sideways, bowing past the widest part of it and then trailing back beside the
 * flank with clear water between.
 *
 * That gap is the whole thing, and it is the second lesson this shape has taught.
 * The first cut ran them straight out and back, and a straight taper at this size
 * is a spike, not a feeler: the fish read as a dart with two spears through its
 * head. The second cut bent them properly but let the curve lie against the body,
 * and because a barbel is filled in the same colour as the fish it hangs off,
 * every part of it that overlaps the flank is simply invisible - what is left is
 * the two ends poking out, which reads as damage. So the centre line is held
 * outside the profile at every station, and it can be, because this body tapers:
 * where the feeler is widest the flank has already begun to draw in.
 *
 * Four stations, out along one edge and back along the other, with the
 * half-thickness falling to nothing at the tip. Seven points, against five for a
 * fin - it is the most expensive appendage in the file and it is worth it,
 * because it is also the only one that names the animal.
 *
 * They trail. Each station reads the wave further down the spine than the last,
 * so the root carries the snout's sway and the tip is most of a beat behind it. A
 * slack filament in moving water always points at where the head *was*, and that
 * lag is the entire animation: a fin is driven, this is dragged.
 *
 * Drawn under the same gate as the fins, and for the same reason - they are the
 * expensive part of an outline that is nine pixels long. The silhouette is built
 * so that losing them costs recognition and not identity: the head is still far
 * too wide for the body behind it, and `tests/fish.test.ts` measures that with the
 * appendages switched off.
 */
function traceWhiskers(ctx: CanvasRenderingContext2D, sp: Species, beat: number): void {
  if (sp.whisker <= 0) return;
  const w = sp.whisker;
  const head = sp.profile[0]!;
  const cheek = sp.profile[1]!;
  /*
   * Station 0 sits inside the snout, so the feeler is rooted rather than floating.
   * 1, 2 and 3 carry it forward, out, and then back into a hook.
   *
   * Forward, and this is the correction that made the whole thing work. Swept back
   * along the flank, which is where a cruising catfish actually holds them, the
   * two feelers and the head enclose a slot of water on each side, and a slot that
   * thin closes up at the size this is drawn: what it draws is not a fish with
   * feelers, it is a fish wearing a hood. Held forward there is nothing to
   * enclose - the water between feeler and cheek is the same water as everywhere
   * else - and two hooks reaching past the snout is also the pose the animal is
   * recognised in, because it is the pose it feeds in.
   */
  const along = [NOSE - 0.04, NOSE + w * 0.035, NOSE + w * 0.075, NOSE + w * 0.05];
  const across = [head * 0.55, head * 0.95 + w * 0.12, cheek * 0.75 + w * 0.3, cheek * 0.95 + w * 0.42];
  const thick = [0.17, 0.12, 0.07, 0];
  /*
   * The snout is the one part of the spine that never moves sideways - `flex` is
   * zero at s = 0 by construction - so a feeler rooted in it has no sway to
   * inherit. It takes the beat directly instead, and late, and only the far end of
   * it moves much: a filament this slack is answering the water the body has
   * already left, which is why it is still swinging one way while the tail behind
   * it has gone the other.
   */
  const wag = sp.swim * 0.45 * Math.sin(beat - 2.1);
  const drag = [0, wag * 0.25, wag * 0.7, wag];
  /*
   * Out along the inner edge, round the tip - emitted once, its thickness is zero -
   * and back down the outer one. The right feeler is emitted in that order and the
   * left one backwards, which is what keeps both wound the way the body is.
   *
   * Every part of that sentence has been paid for. `fill()` uses the nonzero rule,
   * so a subpath wound against the body is a *hole* wherever the two overlap, and
   * the root of a barbel is by definition inside the head. Walking the outer edge
   * first is correct for a feeler that sweeps back and inverts the moment one
   * sweeps forward instead, because the winding of a there-and-back strip depends
   * on which way *there* points. The forward sweep with the old order bit two
   * black wedges out of the snout - the same defect the fins had, arrived at from
   * the opposite direction.
   */
  const walk = [0, 1, 2, 3, 2, 1, 0];
  const edge = [-1, -1, -1, 0, 1, 1, 1];
  for (const side of [1, -1] as const) {
    for (let k = 0; k < walk.length; k++) {
      const j = side > 0 ? k : walk.length - 1 - k;
      const i = walk[j]!;
      put(along[i]!, drag[i]! + side * (across[i]! + edge[j]! * thick[i]!), k === 0);
    }
    ctx.closePath();
  }
}
