/**
 * Slowblue: the brook - act VI's last two stations and act VII's first.
 *
 * The third medium built on Minnaert resonance, and the one where the physics is
 * least expected and most exact. A mountain stream makes almost no sound by
 * moving; what you hear is **air**, dragged under at every break in the surface
 * and let go in thousands of very small bubbles. Take the bubbles out of a
 * recording of a brook and what is left is nearly silence. That is why a smooth
 * fast river is quiet and a shallow rocky one is loud: the noise is a count of
 * how many times the water has folded over on itself.
 *
 * So the riffle is the same voice as act I's water, at the far end of the range:
 *
 *     act I    1.6 - 9.5 mm   340 - 2000 Hz   ~2/s     the deep sea
 *     act VI   0.3 - 1.4 mm  2300 -10900 Hz  ~15/s     rain on water
 *     brook    0.5 - 3.2 mm  1000 - 6500 Hz  ~19/s     running water
 *
 * Three media, one equation, and no two of them mistakable for each other -
 * which is worth more than three separate sound designs would have been, because
 * it means the campaign's water is *one* substance behaving differently rather
 * than three impressions of water.
 *
 * ## The stones
 *
 * The brook's far voice, and the only percussive thing left in the game. A
 * cobble rolled a few centimetres along the bed by the current: low, short,
 * woody, almost dry, and once every half minute or so. It is the sound that says
 * the water has a floor - which is precisely what act VII's first station is
 * about, the last of the river arriving somewhere it can put things down.
 */

import { snapHz } from './Scale';

/** The bubbles a riffle actually entrains, in millimetres. */
export const RIFFLE_MIN_MM = 0.5;
export const RIFFLE_MAX_MM = 3.2;

function clamp01(v: number): number {
  return v < 0 ? 0 : v > 1 ? 1 : v;
}

/** Minnaert. See `Bubbles.ts` - the constant is derived there. */
export function riffleFrequency(radiusMm: number): number {
  return 3260 / Math.max(0.2, radiusMm);
}

/** Seconds. Short, and shorter than the sea's, because these are small. */
export function riffleDuration(radiusMm: number): number {
  const t = clamp01((radiusMm - RIFFLE_MIN_MM) / (RIFFLE_MAX_MM - RIFFLE_MIN_MM));
  return 0.018 + 0.052 * t;
}

/** The upward sweep. A small bubble in fast water rises a long way. */
export function riffleRise(radiusMm: number): number {
  const t = clamp01((radiusMm - RIFFLE_MIN_MM) / (RIFFLE_MAX_MM - RIFFLE_MIN_MM));
  return 1.3 - 0.16 * t;
}

/** Relative loudness, 0..1. */
export function riffleLevel(radiusMm: number): number {
  const t = clamp01((radiusMm - RIFFLE_MIN_MM) / (RIFFLE_MAX_MM - RIFFLE_MIN_MM));
  return 0.42 + 0.58 * t;
}

/**
 * Samples a radius. `flow01` is how fast the water is going here - 1 in the
 * brook proper, falling toward the estuary where the stream slows, spreads and
 * stops folding over. Faster water entrains *smaller* bubbles and more of them,
 * so the brook is bright and the mouth is not.
 */
export function riffleRadius(u: number, flow01 = 1): number {
  const f = clamp01(flow01);
  const lo = RIFFLE_MIN_MM;
  const hi = RIFFLE_MAX_MM * (1 - 0.42 * f);
  return lo + (hi - lo) * Math.pow(clamp01(u), 0.85);
}

/**
 * Bubble events per second. `breath01` is 1 fully inhaled.
 *
 * Fifteen to twenty-two in the brook - the densest layer in the game and the one
 * place the density is the point, because a stream is defined by how many things
 * are happening in it at once. It thins by nearly half at the mouth, which is
 * the whole geography of the handover in one number.
 */
export function riffleRate(flow01: number, breath01: number): number {
  const f = clamp01(flow01);
  const exhaling = 0.88 + 0.24 * (1 - clamp01(breath01));
  return (11 + 11 * f) * exhaling;
}

export interface Stone {
  /** Where the knock sits, in Hz. Low and woody. */
  hz: number;
  /** ...and where it falls to. A stone that stops has been stopped by something. */
  glideTo: number;
  /** Seconds. */
  duration: number;
  /** 0..1, relative to the track's own level. */
  gain: number;
  /** -1..1. */
  pan: number;
}

/** One cobble, moved. */
export function stoneKnock(rand: () => number): Stone {
  // Snapped, and it is the one voice in the engine that genuinely sits on the line
  // `Scale.ts` draws: a quarter to a half second, which is where texture becomes a
  // note. Two things push it over. It is *low* - 90 to 220 Hz, right in the octave
  // the drone occupies, where a mistuned interval beats slowly instead of merely
  // sounding wrong - and it is *rare*, one every twenty to sixty seconds, so nothing
  // masks it and there is no stream for it to disappear into. The noise body over it
  // is what makes a stone a stone; the sine underneath is a pitch whether it was
  // meant to be one or not.
  const hz = snapHz(90 + rand() * 130);
  return {
    hz,
    glideTo: hz * (0.72 + rand() * 0.14),
    duration: 0.26 + rand() * 0.3,
    gain: 0.5 + rand() * 0.5,
    pan: (rand() * 2 - 1) * 0.75,
  };
}

/** Seconds to the next stone. Rare enough that each one is a small event. */
export function stoneGap(rand: () => number): number {
  return 22 + rand() * 40;
}
