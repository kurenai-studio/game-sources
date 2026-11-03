/**
 * Slowblue: the game breathes, and it breathes at a rate a person can follow.
 *
 * Everything else in this project is derived from something physical - the water is
 * a field, the light has a direction, a vortex is the curl of a radial profile. This
 * is the one clock that is derived from the *player's* body: 11 seconds, which is
 * 5.45 breaths a minute, the rate paced-breathing research keeps landing on and the
 * rate every guided relaxation in the world uses. It is not a metronome the player
 * has to obey; it is a rate the whole picture and the whole bed move at, so a player
 * who is looking at the screen ends up breathing with it without being asked.
 *
 * Three properties matter and all three are deliberate:
 *
 *   1. **Asymmetric.** The exhale is longer than the inhale (0.42 / 0.58), because a
 *      long exhale is the half that actually settles a nervous system, and because a
 *      symmetric cycle reads as a pulse rather than as breathing.
 *   2. **Zero velocity at the turns.** Each half is a smoothstep, so the swell stops
 *      moving completely at the top and the bottom. A sine never rests, and anything
 *      that never rests is something the eye keeps tracking.
 *   3. **Pure.** `breathAt(t)` has no state, so the simulation stays deterministic
 *      and the renderer, the audio bed and the water can all read the same phase
 *      from their own clock without any of them owning it.
 */

/** Seconds per full breath. 11 s = 5.45 breaths per minute. */
export const BREATH_PERIOD = 11;
/** Fraction of the cycle spent breathing in. The exhale is deliberately longer. */
export const BREATH_INHALE = 0.42;

/** Smoothstep on 0..1, with zero derivative at both ends. */
function ease(u: number): number {
  const x = u < 0 ? 0 : u > 1 ? 1 : u;
  return x * x * (3 - 2 * x);
}

/** 0..1 through the current breath. 0 is the bottom of an exhale. */
export function breathPhase(t: number): number {
  const p = (t / BREATH_PERIOD) % 1;
  return p < 0 ? p + 1 : p;
}

/**
 * 0..1 swell: 0 fully exhaled, 1 fully inhaled, resting at both ends.
 *
 * This is the only number anything outside this file needs. The renderer scales
 * light with it and the audio bed opens its filter with it - both off the same
 * clock, which is what makes the breath one thing arriving in two senses rather
 * than two effects that happen to agree at the start of a session.
 */
export function breathAt(t: number): number {
  const p = breathPhase(t);
  return p < BREATH_INHALE
    ? ease(p / BREATH_INHALE)
    : 1 - ease((p - BREATH_INHALE) / (1 - BREATH_INHALE));
}

/**
 * Signed rate of change, normalised to roughly -1..1. Positive while breathing in.
 * Used for the things that should follow the *direction* of the breath rather than
 * its depth - act III's gravity wave, for one, which turns at the top and the bottom
 * of the breath instead of swelling through it.
 */
export function breathFlow(t: number): number {
  const p = breathPhase(t);
  // d/dp of the smoothstep is 6u(1-u), peaking at 1.5; divide it back out so the
  // caller gets a comparable number on either side of the turn.
  if (p < BREATH_INHALE) {
    const u = p / BREATH_INHALE;
    return (6 * u * (1 - u)) / 1.5;
  }
  const u = (p - BREATH_INHALE) / (1 - BREATH_INHALE);
  return -(6 * u * (1 - u)) / 1.5;
}
