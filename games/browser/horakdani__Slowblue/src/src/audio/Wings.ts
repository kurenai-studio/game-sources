/**
 * Slowblue: the air's sound, derived from wings rather than from a filter sweep.
 *
 * `Bubbles.ts` established the rule this file obeys: **nothing here picks a
 * frequency**. There, you picked a bubble radius and Minnaert resonance gave you
 * the pitch, the length and the loudness. Here you pick a **wing span**, and
 * every audible property follows from it through relations that are about birds
 * rather than about synthesis.
 *
 * The chain, in four steps, each of which is a real relation:
 *
 *   1. **Beat rate from span.** Geometrically similar flapping animals sit on a
 *      tight allometric line - the same one Pennycuick's flight model produces.
 *      `4.0 / span^0.9` fits the birds this act is made of: a 1.2 m gull at
 *      3.4 beats/s, a 0.24 m tern-sized bird at 14. Big wings beat slowly, and
 *      that is why the sound of a flock *slows down* as the campaign climbs.
 *   2. **Tip speed.** The tip covers roughly two spans per cycle, so
 *      `U = 2 * span * rate`. Substituting step 1 gives `8 * span^0.1` - nearly
 *      independent of size, which is a real convergence and not a coincidence:
 *      it is why a sparrow and an albatross make a recognisably similar noise.
 *   3. **The boundary layer.** A wing's audible hiss is trailing-edge noise, and
 *      trailing-edge noise is scaled by the boundary layer, not by the wing.
 *      `delta ~ 0.03 * chord`, and `chord = span / ASPECT` for the long, narrow
 *      wings every bird in this act has.
 *   4. **Strouhal.** `f = St * U / delta`. That lands a gull at ~200 Hz and a
 *      small seabird at ~860 Hz, which is where wing noise actually sits.
 *
 * Two consequences are worth stating because they are what make this worth doing.
 * The whoosh pitch works out to a fixed multiple of the beat rate, so a flock is
 * *in tune with its own rhythm* without anything tuning it. And a wing is
 * broadband where a bubble was a resonator - so the water's sound was a stream of
 * sine bursts and the air's is a stream of filtered noise. The medium changed,
 * and the synthesis had to change with it; that is the whole point.
 *
 * Tuned rather than derived: `ASPECT`, the 0.03 boundary-layer fraction, the
 * Strouhal constant (real values run 0.1-0.2 depending on what you measure it
 * against) and the burst duration. They are marked where they appear.
 */

/** Wing spans, in metres, of the birds that carry this act. */
export const WING_MIN_M = 0.22;
export const WING_MAX_M = 1.35;

/** Span / chord. High, because every bird here is a soarer. **Tuned.** */
const ASPECT = 9;
/** Boundary-layer thickness as a fraction of the chord. **Tuned.** */
const BOUNDARY = 0.03;
/** Strouhal number for trailing-edge noise. **Tuned** within the real 0.1-0.2. */
const STROUHAL = 0.1;

/**
 * Wingbeats per second for a given span. Allometric, and the reason the flock
 * audibly slows down as the act climbs into bigger, higher birds.
 */
export function wingbeatRate(spanM: number): number {
  const s = Math.max(0.05, spanM);
  return 4.0 / Math.pow(s, 0.9);
}

/** Wingtip speed in m/s: the tip covers about two spans per full cycle. */
export function wingTipSpeed(spanM: number): number {
  return 2 * Math.max(0.05, spanM) * wingbeatRate(spanM);
}

/**
 * Centre frequency of one wingbeat's noise burst, in Hz. Trailing-edge noise
 * through Strouhal on the boundary layer - see the file header. ~200 Hz for the
 * biggest wing in the act, ~900 Hz for the smallest.
 */
export function wingFrequency(spanM: number): number {
  const s = Math.max(0.05, spanM);
  const delta = BOUNDARY * (s / ASPECT);
  return (STROUHAL * wingTipSpeed(s)) / delta;
}

/**
 * How long one beat is audible, in seconds. **Tuned** to the fast middle of the
 * downstroke rather than to the whole cycle: a wing is only loud while it is
 * accelerating air, which is a quarter of its own period, not half.
 */
export function wingDuration(spanM: number): number {
  const d = 0.25 / wingbeatRate(spanM);
  return Math.min(0.16, Math.max(0.02, d));
}

/**
 * How wide the noise band is, as a Q. Big slow wings are a broad soft rush; small
 * fast ones are tighter and more whistle-like, because a thinner boundary layer
 * sheds over a narrower range. **Tuned**, but the direction is not arbitrary.
 */
export function wingQ(spanM: number): number {
  const t = norm(spanM);
  return 0.8 + 1.6 * (1 - t);
}

/**
 * Relative loudness, ~0.5..1.4. A bigger wing displaces more air, exactly as a
 * bigger bubble moved more water - and for the same reason: it stops a flock from
 * sounding like one sample repeated.
 */
export function wingLevel(spanM: number): number {
  return 0.5 + 0.9 * norm(spanM);
}

/**
 * Samples a wing span for the next beat.
 *
 * `altitude01` is 0 just above the waves and 1 at the tropopause, and it biases
 * the *size*: the spray is full of small quick seabirds, and the only things
 * still flying at the top of the storm have enormous wings. This is the exact
 * mirror of `bubbleRadius`'s depth bias, and it does the same job - the ascent is
 * audible in the air with the picture ignored. `u` is a uniform 0..1, passed in
 * so the mapping stays a pure function.
 */
export function wingSpan(u: number, altitude01 = 0): number {
  const a = clamp01(altitude01);
  const lo = WING_MIN_M + a * 0.34;
  const hi = WING_MAX_M * (0.52 + 0.48 * a);
  // Skewed toward the larger end of whatever band the altitude selects, because a
  // stream dominated by its smallest wings reads as flutter, and flutter is busy.
  return lo + (hi - lo) * Math.pow(clamp01(u), 0.7);
}

/** 0..1 where the span sits in the act's range. */
function norm(spanM: number): number {
  return clamp01((spanM - WING_MIN_M) / (WING_MAX_M - WING_MIN_M));
}

function clamp01(v: number): number {
  return v < 0 ? 0 : v > 1 ? 1 : v;
}
