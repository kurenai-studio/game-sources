/**
 * Slowblue: act VI, the rain - and the fact that rain is bubbles.
 *
 * This is the ASMR act, so it is the one most at risk of being a recording of
 * rain with the game behind it. It is not, and the reason it does not need to be
 * is a piece of physics almost nobody knows:
 *
 * **The sound of a raindrop is not the impact. It is the bubble.**
 *
 * A drop hitting water makes a very quiet, very short splash - and then the
 * cavity it opened pinches off and traps a small bubble of air, and *that* rings.
 * It is Minnaert resonance, the same formula act I's bed is built on
 * (`Bubbles.ts`), and it is where the "plink" comes from. Franz established it in
 * the fifties and it is why rain on a puddle is pitched and rain on a road is
 * not. So act VI's water and act I's water come out of the same equation, which
 * is the campaign's own circle stated in the one place nobody would look for it,
 * and they still sound nothing like each other - because the bubble a raindrop
 * entrains is a tenth of the size of one coming off a rock at forty metres.
 *
 *     act I:   1.6 - 9.5 mm  ->   340 -  2000 Hz, sparse, big, slow
 *     act VI:  0.3 - 1.4 mm  ->  2300 - 10900 Hz, dense, small, bright
 *
 * Same voice, same code path, two ends of one range that do not touch - the
 * largest drop is smaller than the smallest thing act I can produce - and one of
 * them is the bottom of the sea and the other is rain on a pond.
 *
 * ## The shower
 *
 * Rain does not fall at a rate. It comes in sheets - the density swings by a
 * factor of three or four over half a minute as a cell walks past - and that
 * swing is most of what makes real rain restful, because it means the texture is
 * always changing without anything ever *happening*. `sheetAt` is three
 * incommensurable sines summed, so the pattern takes about eleven minutes to
 * repeat and never lands on a beat.
 *
 * ## The patter
 *
 * The other half of rain, and the dry half: drops on leaves rather than on water.
 * No bubble, no pitch, just a very short band of noise up where a leaf is stiff -
 * so `patterGrain` is broader, higher, drier and shorter than a drop, and the two
 * layers together are a canopy in a downpour. It is on `shimmer` rather than with
 * the drops, so a player who wants only the water on water can have it.
 */

/** The bubble a falling drop actually entrains, in millimetres. */
export const DROP_MIN_MM = 0.3;
export const DROP_MAX_MM = 1.4;

function clamp01(v: number): number {
  return v < 0 ? 0 : v > 1 ? 1 : v;
}

/**
 * Minnaert again: 3260 / r, r in millimetres. Not a tuned number - see
 * `Bubbles.ts`, where the same constant is derived.
 */
export function dropFrequency(radiusMm: number): number {
  return 3260 / Math.max(0.12, radiusMm);
}

/**
 * How long it rings. Milliseconds - 12 to 45 - because a small bubble damps fast,
 * and because anything longer turns rain into a wind chime.
 */
export function dropDuration(radiusMm: number): number {
  const t = clamp01((radiusMm - DROP_MIN_MM) / (DROP_MAX_MM - DROP_MIN_MM));
  return 0.012 + 0.033 * t;
}

/** The upward sweep, as a multiplier. Same mechanism as a bubble, less of it. */
export function dropRise(radiusMm: number): number {
  const t = clamp01((radiusMm - DROP_MIN_MM) / (DROP_MAX_MM - DROP_MIN_MM));
  return 1.22 - 0.14 * t;
}

/** Relative loudness, 0..1. Bigger bubble, more water moved. */
export function dropLevel(radiusMm: number): number {
  const t = clamp01((radiusMm - DROP_MIN_MM) / (DROP_MAX_MM - DROP_MIN_MM));
  return 0.4 + 0.6 * t;
}

/**
 * The splash the bubble comes out of: a tiny, broad, unpitched band above the
 * ring, a fifth of its level. On its own it is nothing; underneath the ring it is
 * the difference between a drop and a bell.
 */
export function dropImpactHz(radiusMm: number): number {
  return dropFrequency(radiusMm) * 1.9;
}

/**
 * Samples a bubble radius. `sheet01` is how hard it is raining right now: a
 * heavier sheet has bigger drops in it, and bigger drops entrain bigger bubbles,
 * so the rain audibly *deepens* in the squalls rather than just getting busier.
 */
export function dropRadius(u: number, sheet01 = 0.5): number {
  const s = clamp01(sheet01);
  const lo = DROP_MIN_MM;
  const hi = DROP_MIN_MM + (DROP_MAX_MM - DROP_MIN_MM) * (0.45 + 0.55 * s);
  return lo + (hi - lo) * Math.pow(clamp01(u), 0.8);
}

/**
 * How hard it is raining at time `t`, 0..1.
 *
 * Three sines whose periods share no factor - 23, 37 and 61 seconds - so the
 * sheet never repeats inside a station and there is no swell the ear can predict.
 * Biased upward, because a cell passing is a rise from steady rain rather than a
 * gap between two of them.
 */
export function sheetAt(t: number): number {
  const a = Math.sin((2 * Math.PI * t) / 23);
  const b = Math.sin((2 * Math.PI * t) / 37 + 1.1);
  const c = Math.sin((2 * Math.PI * t) / 61 + 2.3);
  return clamp01(0.5 + 0.24 * a + 0.18 * b + 0.14 * c);
}

/**
 * Drop events per second. `breath01` is 1 fully inhaled.
 *
 * Nine to twenty-two: below about eight a second rain is a leaking gutter, and
 * the ear starts counting; above about twenty-five the individual rings stop
 * being resolvable and the whole thing collapses into the hiss this engine will
 * not have. The breath moves it the same way act I's water moves - busier on the
 * out-breath - so the rain agrees with the player.
 */
export function dropRate(sheet01: number, breath01: number): number {
  const s = clamp01(sheet01);
  const exhaling = 0.85 + 0.3 * (1 - clamp01(breath01));
  return (10 + 11 * s) * exhaling;
}

export interface PatterGrain {
  /** Where the band sits, in Hz. Dry and high: this one is not water. */
  hz: number;
  /** Seconds. */
  duration: number;
  /** How broad. Low Q - a leaf is not a resonator. */
  q: number;
  /** 0..1, relative to the track's own level. */
  gain: number;
  /** -1..1. */
  pan: number;
}

/** One drop on a leaf. */
export function patterGrain(rand: () => number, sheet01 = 0.5): PatterGrain {
  const s = clamp01(sheet01);
  const hz = 2400 + rand() * 3800;
  return {
    hz,
    duration: 0.022 + rand() * 0.035,
    q: 1.1 + rand() * 1.4,
    gain: (0.35 + rand() * 0.5) * (0.5 + 0.5 * s),
    pan: (rand() * 2 - 1) * 0.9,
  };
}

/** Patter events per second. Denser than the drops and much quieter. */
export function patterRate(sheet01: number): number {
  return 11 + 14 * clamp01(sheet01);
}
