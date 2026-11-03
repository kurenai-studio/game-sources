/**
 * Slowblue: act III, the upper air - ice, shear, and the sound the planet makes.
 *
 * The thinning is the quietest act in the campaign and the hardest one to give a
 * bed to, because it is honest about being nearly empty. At 25 km there is about
 * a fiftieth of the air there is at the surface; at 82 km there is effectively
 * none. Anything loud up here is a lie, and the temptation - a pad, a wash, a
 * "space" texture - would make act III sound like act IV, which is the one act it
 * must not sound like. Act IV is silence. Act III is *thinness*, and thinness is
 * something you can only hear if there are a few small things in it.
 *
 * So the act gets three voices and a great deal of nothing between them.
 *
 * ## 1. The crystals, and where their pitch is *not* from
 *
 * The two most beautiful stations in the game are nacreous cloud at 25 km and
 * noctilucent cloud at 82 km, and both are ice: crystals of ten to a hundred
 * micrometres hanging in air too thin to fall through. A crystal that size ringing
 * mechanically would be tens of kilohertz, which is a bat's problem and not a
 * player's - so unlike `Bubbles.ts`, **this mapping is chosen rather than
 * derived**, and it is worth saying so plainly. Minnaert gave the water its
 * pitches for free; nothing gives them to ice.
 *
 * What is kept is the *relationship*, because that is what the ear reads as a
 * material: small is high, short and quiet; large is lower, longer and louder,
 * and the pitch **falls** through the ring instead of rising. That last one is the
 * whole difference between this and a bubble. A bubble's pitch climbs because its
 * radius is shrinking as it goes; a struck plate of ice loses its top partials
 * first and sags. Play the two side by side with the same envelope and one is
 * unmistakably water and the other is unmistakably glass.
 *
 * ## 2. The shear
 *
 * `sim/LayeredFlow.ts` is the act: deep horizontal layers moving at very
 * different speeds, and the skill is choosing which one to be inside. Where two
 * of them slide past each other there is shear, and shear in a stratified fluid
 * is the one thing up here that genuinely does make a sound - it is what a
 * gravity wave breaks into. So a shear is a *very* narrow band of noise that
 * sweeps between two pitches over eight to twenty seconds while travelling across
 * the stereo field, because a layer is going somewhere and the sound of it has to
 * be going there too. It is the slowest single gesture in the game.
 *
 * ## 3. The infrasound
 *
 * The stratosphere is the planet's waveguide: below about 20 Hz, sound from
 * volcanoes, storms and surf travels round the world in it with almost no loss,
 * which is how the 1883 Krakatoa wave was recorded seven times going past. It is
 * the one voice act III has that is *big*, and it is inaudible by definition - so
 * what is synthesised is its lowest audible edge, 26 to 48 Hz, ten to twenty
 * seconds long, with no onset anybody can locate. It is the act's whale: rare,
 * enormous, and from somewhere else entirely.
 */

import { snapHz } from './Scale';

/** The crystal sizes that actually hang up there, in micrometres. */
export const CRYSTAL_MIN_UM = 8;
export const CRYSTAL_MAX_UM = 90;

function clamp01(v: number): number {
  return v < 0 ? 0 : v > 1 ? 1 : v;
}

/** The top and bottom of the band, and both are scale members. See below. */
const CRYSTAL_TOP_HZ = 6272;
const CRYSTAL_BOTTOM_HZ = 1760;

/**
 * Where a crystal rings, in Hz. **Chosen, not derived** - see the file header -
 * and therefore the one voice in the engine with no excuse for being out of tune.
 *
 * The band was 1.6 to 6.4 kHz and is now 1760 to 6272, which is the same band with
 * both ends moved onto the scale: A6 and G8. Inside it every crystal is snapped to
 * the nearest member, which leaves ten pitches over two octaves.
 *
 * This is the file `Scale.ts`'s rule was written for. A crystal is a pure sine that
 * rings for one and a half to nearly three seconds, four of them a minute, in the
 * emptiest act in the campaign - there is nothing for it to hide behind and nothing
 * to mask it, so it is a *note* in every sense the ear has, and it was landing an
 * average of 52 cents off one. `Bubbles.ts` gets to keep its continuum because
 * Minnaert earned it and because a bubble is gone in 40 ms; this mapping was picked
 * out of the air, so the only question about it is which sounds better, and a
 * quarter-tone-flat two-second sine over a fixed drone is not the answer.
 *
 * The relationship the file header cares about is untouched: snapping is monotone,
 * so a big crystal is still lower, longer and louder than a small one.
 */
export function crystalFrequency(sizeUm: number): number {
  const t = clamp01((sizeUm - CRYSTAL_MIN_UM) / (CRYSTAL_MAX_UM - CRYSTAL_MIN_UM));
  // Geometric rather than linear: pitch is logarithmic, and a linear map spends
  // most of its range on an interval nobody can hear as an interval.
  return snapHz(CRYSTAL_TOP_HZ * Math.pow(CRYSTAL_BOTTOM_HZ / CRYSTAL_TOP_HZ, t));
}

/**
 * How long it rings, in seconds. Long - a second and a half to nearly three -
 * because a struck crystal in an atmosphere that cannot damp it has nothing to
 * take the energy away, and because the tails overlapping is what turns four
 * events a minute into a room instead of four blips.
 */
export function crystalDuration(sizeUm: number): number {
  const t = clamp01((sizeUm - CRYSTAL_MIN_UM) / (CRYSTAL_MAX_UM - CRYSTAL_MIN_UM));
  return 1.4 + 1.5 * t;
}

/**
 * The downward glide, as a multiplier on the starting frequency.
 *
 * The opposite of `bubbleRise` and deliberately so: this is the single property
 * that makes the ear file the sound under "glass" instead of "water". Small
 * crystals sag further, because their high partials are the first thing the thin
 * air takes.
 */
export function crystalFall(sizeUm: number): number {
  const t = clamp01((sizeUm - CRYSTAL_MIN_UM) / (CRYSTAL_MAX_UM - CRYSTAL_MIN_UM));
  return 0.9 + 0.075 * t;
}

/** Relative loudness, 0..1. Bigger is louder, and nothing here is ever loud. */
export function crystalLevel(sizeUm: number): number {
  const t = clamp01((sizeUm - CRYSTAL_MIN_UM) / (CRYSTAL_MAX_UM - CRYSTAL_MIN_UM));
  return 0.42 + 0.58 * t;
}

/**
 * Samples a crystal size. `height01` is 0 at the tropopause and 1 at the Karman
 * line, and it biases the draw *small*: there is less and less water up there to
 * make anything out of, so the act audibly rises in pitch and thins out as it
 * climbs. Noctilucent cloud is the highest and finest thing in the sky and it
 * should be the highest and finest thing in the mix.
 */
export function crystalSize(u: number, height01 = 0): number {
  const h = clamp01(height01);
  const lo = CRYSTAL_MIN_UM;
  const hi = CRYSTAL_MAX_UM * (1 - 0.62 * h);
  // Skewed small, so the large ones stay events rather than becoming the texture.
  return lo + (hi - lo) * Math.pow(clamp01(u), 1.5);
}

/** Crystal events per second. Sparse everywhere and sparser as the air runs out. */
export function crystalRate(height01 = 0): number {
  return 0.55 * (1 - 0.55 * clamp01(height01));
}

export interface ShearBand {
  /** Where the band starts, in Hz. */
  fromHz: number;
  /** ...and where it has arrived by the end. Always a long way from `fromHz`. */
  toHz: number;
  /** Seconds. Eight to twenty: the slowest gesture in the game. */
  duration: number;
  /** How narrow the band is. High: this is a layer edge, not a wind. */
  q: number;
  /** 0..1, relative to the track's own level. */
  gain: number;
  /** -1..1, where it enters from. */
  pan: number;
  /** ...and where it has got to by the end. Never the same side. */
  panTo: number;
}

/**
 * One layer sliding past another.
 *
 * `rand` is a 0..1 source, passed in rather than drawn here so the model stays a
 * pure function. Higher up the layers are faster, thinner and further apart, so
 * the band is narrower, higher and sweeps further - which is the act's own ramp
 * (`config/thinning.ts`) heard rather than flown.
 */
export function shearBand(rand: () => number, height01 = 0): ShearBand {
  const h = clamp01(height01);
  const fromHz = 320 + rand() * 520 + h * 420;
  // Up or down, but never nearly-nowhere: a band that lands where it started is
  // a held tone, and a held narrow band of noise is a whistle.
  const up = rand() < 0.5;
  const span = 1.9 + rand() * 1.6;
  const toHz = up ? fromHz * span : fromHz / span;
  const side = rand() < 0.5 ? -1 : 1;
  return {
    fromHz,
    toHz,
    duration: 8 + rand() * 12,
    q: 5.5 + h * 6 + rand() * 3,
    gain: (0.5 + rand() * 0.5) * (1 - 0.3 * h),
    pan: side * (0.55 + rand() * 0.4),
    panTo: -side * (0.35 + rand() * 0.5),
  };
}

/** Seconds until the next shear. Long: two at once is weather, not stratosphere. */
export function shearGap(rand: () => number): number {
  return 17 + rand() * 26;
}

export interface Infrasound {
  /** 26..48 Hz - the audible edge of something that is mostly not audible. */
  hz: number;
  /** Where it has sagged to by the end. A planet-sized sound is never level. */
  glideTo: number;
  /** Seconds. Ten to twenty. */
  duration: number;
  /** 0..1, relative to the track's own level. */
  gain: number;
  /** -1..1. It came a long way and it did not come from the middle. */
  pan: number;
}

/**
 * The waveguide, speaking. One swell, and then a minute or two of nothing.
 *
 * Lower and longer the higher the act climbs, because the guide gets *better*
 * with height - which means what arrives at 82 km has been round more of the
 * planet than what arrives at 11.
 */
export function infrasoundSwell(rand: () => number, height01 = 0): Infrasound {
  const h = clamp01(height01);
  // Snapped, and this is where it costs least and buys most. The swell is the
  // longest single tone in the game - ten to twenty-two seconds - and it sits in
  // the same octave as the drone's own root, so a free frequency here beats
  // audibly against 55 Hz for the whole of it. Down here nobody can name the
  // pitch, which is exactly why the beat is what they hear instead of it.
  //
  // The band was written as 26 to 48 Hz and comes out as 27.5 to 49: A0 at the
  // bottom and the G below the root at the top, which are the two scale members
  // nearest the ends it was reaching for. Both are inside the range the header
  // claims - "the lowest audible edge" - and neither is inside the drone.
  const hz = snapHz(48 - h * 14 - rand() * 8);
  return {
    hz,
    glideTo: hz * (0.82 + rand() * 0.1),
    duration: 10 + rand() * 8 + h * 4,
    gain: 0.6 + rand() * 0.4,
    pan: (rand() * 2 - 1) * 0.6,
  };
}

/** Seconds to the next swell. The gap is most of what makes it enormous. */
export function infrasoundGap(rand: () => number): number {
  return 68 + rand() * 96;
}
