/**
 * Slowblue: the water sound, derived from bubbles rather than from noise.
 *
 * The bed's water used to be brown noise under a 300 Hz lowpass. That is a correct
 * description of forty metres of ocean and a poor one of anything a person finds calming:
 * broadband low noise is a *rumble*, and a rumble is pressure. What actually settles
 * someone is the sound of small volumes of air leaving water - a spring, an aquarium, a
 * kettle before it boils - and that sound is not noise at all. It is a stream of
 * individual, pitched, very short events.
 *
 * So a bubble here is a bubble: **Minnaert resonance**. A spherical air bubble in water
 * rings at
 *
 *     f0 = (1 / 2*pi*r) * sqrt(3*gamma*P / rho)  ~=  3.26 / r     (r in metres, f0 in Hz)
 *
 * which for the millimetre sizes that actually come off a rock is 360 Hz to 5 kHz. The
 * consequence worth having is that **nothing here picks a pitch**: pick a radius - which
 * is a physical thing a level can have an opinion about - and the pitch, the length and
 * the loudness all follow. Deep water gets bigger, slower, lower bubbles; the shallows
 * get small bright ones. That is the same argument the rest of this project makes about
 * vortices and light: derive it, and it cannot look or sound wrong later.
 *
 * The two numbers that are *not* derived are the decay and the upward sweep. A real
 * bubble's damping is a three-term model (thermal, radiative, viscous) and its pitch rise
 * comes from the radius shrinking as it detaches; both are tuned here to the shape those
 * models have rather than computed, because the audible difference is small and this is a
 * phone. They are marked where they appear.
 */

/** Radii that actually come off rock and weed, in millimetres. */
export const BUBBLE_MIN_MM = 1.6;
export const BUBBLE_MAX_MM = 9.5;

/**
 * Minnaert's formula. `radiusMm` in millimetres, result in Hz.
 *
 * 3.26 / r with r in metres is 3260 / r with r in millimetres, which is where the
 * constant comes from - it is not a tuned number.
 */
export function bubbleFrequency(radiusMm: number): number {
  const r = Math.max(0.2, radiusMm);
  return 3260 / r;
}

/**
 * How long the bubble rings, in seconds. **Tuned, not derived** - see the file header.
 *
 * The shape is right and it is the shape that matters: a big bubble is low *and* long,
 * a small one is high and gone. Clamped at both ends so no bubble is either a click or a
 * tone.
 */
export function bubbleDuration(radiusMm: number): number {
  const f0 = bubbleFrequency(radiusMm);
  const d = 0.11 * Math.sqrt(400 / f0);
  return Math.min(0.2, Math.max(0.022, d));
}

/**
 * The upward sweep, as a multiplier on the starting frequency. **Tuned.**
 *
 * A bubble's pitch rises as it goes, because the radius that set the pitch is shrinking.
 * Small bubbles rise further, which is most of why a gurgle sounds like it is going
 * somewhere rather than just repeating.
 */
export function bubbleRise(radiusMm: number): number {
  const small = 1 - (radiusMm - BUBBLE_MIN_MM) / (BUBBLE_MAX_MM - BUBBLE_MIN_MM);
  return 1.1 + 0.24 * Math.min(1, Math.max(0, small));
}

/**
 * Relative loudness, 0..~1.4. A bigger bubble moves more water, so it is louder as well
 * as lower - which is what stops the stream from sounding like a row of identical blips.
 */
export function bubbleLevel(radiusMm: number): number {
  const t = (radiusMm - BUBBLE_MIN_MM) / (BUBBLE_MAX_MM - BUBBLE_MIN_MM);
  return 0.55 + 0.85 * Math.min(1, Math.max(0, t));
}

/**
 * Samples a radius for the next bubble.
 *
 * `depth01` is 1 on the trench floor and 0 at the surface, and it biases the *size*:
 * deep water gets the big low ones, the shallows get small bright ones. `u` is a uniform
 * 0..1 - passed in rather than drawn here so the mapping stays a pure function.
 *
 * The exponent skews the draw toward the larger end of whatever band the depth selects,
 * because a stream dominated by its small bubbles reads as fizz, and fizz is not calm.
 */
export function bubbleRadius(u: number, depth01 = 0): number {
  const d = Math.min(1, Math.max(0, depth01));
  const lo = BUBBLE_MIN_MM + d * 1.6;
  const hi = BUBBLE_MAX_MM * (0.72 + 0.28 * d);
  const x = Math.min(1, Math.max(0, u));
  return lo + (hi - lo) * Math.pow(x, 0.7);
}
