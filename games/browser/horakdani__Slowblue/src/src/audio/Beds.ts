import type { BedTrackKey } from '../config/settings';
import type { MediumKind } from '../config/tuning';

/**
 * Slowblue: eight beds, and the table that says what each act is made of.
 *
 * For a long time the game had two: water and air. Everything past the anvil fell
 * through to the water's branch, which meant act III was flown to a stream of
 * bubbles at 25 km, act IV had a whale in vacuum, and the rain and the trench
 * sounded like each other because they *were* each other. The picture had seven
 * acts and the mix had one and a half.
 *
 * This file is the fix, and it is deliberately a table rather than code. Three
 * things live here and nothing else does:
 *
 *   1. **Which bed an act plays**, resolved from the act and the medium together
 *      (`bedFor`) - not from the medium alone, because two acts share the water
 *      and mean opposite things by it, and two acts share the brook and mean the
 *      same thing by it.
 *   2. **What each bed's six layers are called**, because the mixer the player
 *      opens mid-station has to say *rain* in the rain and *heartbeat* in orbit.
 *      The slots are shared (see `config/settings.ts`); only the names and the
 *      voices behind them change.
 *   3. **How the three continuous layers are voiced** - the chord, the high layer
 *      and the bell. These are the parts of the bed that never stop, so they
 *      cannot be swapped at an act boundary; the engine holds one of each and
 *      *retargets* it over about four seconds, which is why an act change is a
 *      dissolve and not a cut.
 *
 * The scheduled layers - bubbles, wings, crystals, drops, whistlers, all of it -
 * are not here. They live in a module each (`Bubbles`, `Wings`, `Crystals`,
 * `Void`, `Plasma`, `Raindrops`, `Riffle`, `Snow`), because every one of them is
 * a physical model with its own arguments and its own test file, and flattening
 * eight of those into a table would lose exactly the reasoning that makes them
 * sound like the thing they are.
 *
 * ## Why eight and not seven
 *
 * The campaign has seven acts. The brook is the eighth bed because it is the
 * *seam*: act VI ends in running water and act VII begins in it, and the one
 * rule the campaign list obeys (`config/campaign.ts`) is that consecutive acts
 * agree at the seam. A bed that stopped at the act line would put a hard cut in
 * the one handover the whole circuit is pointing at.
 */

export const BED_KEYS = [
  /** Act I. Forty metres of ocean, rising. */
  'deep',
  /** Act II. Air, and a flock in it. */
  'flight',
  /** Act III. Ice, shear, and the planet's own waveguide. */
  'thin',
  /** Act IV. Breath, heartbeat, and radio. */
  'orbit',
  /** Act V. The one act allowed to be loud, cooling. */
  'fire',
  /** Act VI. Rain, which is bubbles. */
  'rain',
  /** Acts VI-VII. Running water, which is also bubbles. */
  'brook',
  /** Act VII. Act I's water, sinking. */
  'homecoming',
] as const;

export type BedKey = (typeof BED_KEYS)[number];

export interface BedLayer {
  /** Which mixer slot it is levelled and muted on. */
  track: BedTrackKey;
  /** What the mixer calls it while this bed is playing. */
  name: string;
}

/**
 * The chord, per bed.
 *
 * Every bed has one and no bed has a different one - it is the same open fifth,
 * with no third in it, that act I has always had. What changes is the register,
 * how far up it is voiced, how open the filter is and how far the voices are
 * pulled apart. That is enough: a chord voiced as [1, 1.5, 2, 3] under a 520 Hz
 * lowpass is forty metres of water, and the same chord voiced [2, 3, 4, 6] under
 * a 1400 Hz one, with eighteen cents of spread on it, is the upper stratosphere.
 */
export interface DroneVoicing {
  /** Multipliers on the 55 Hz root, low to high. */
  partials: [number, number, number, number];
  /** The pad's lowpass corner in Hz, at mid-breath. */
  cutoff: number;
  /** Peak pad gain. */
  gain: number;
  /**
   * Cents of detune between the voices.
   *
   * The one expressive number in the set. Four cents is a chord; twenty-two is
   * four things nearly agreeing, which is what heat sounds like - so act V opens
   * wide and comes back into tune as the fire goes out.
   */
  spread: number;
}

/** The layer above the body: filtered noise, held, and moving very slowly. */
export interface ShimmerVoicing {
  hz: number;
  q: number;
  gain: number;
  /** Playback rate of the shared noise buffer. Higher is thinner. */
  rate: number;
}

/** The bell. `strike` 0 leaves the fundamental alone - see act IV. */
export interface BellVoicing {
  /** Seconds between bells. */
  gap: [number, number];
  /** Multiplier on the bell's register. */
  octave: number;
  /** How much struck partial there is, 0..1. */
  strike: number;
  /** Seconds the fundamental rings. */
  hold: number;
}

export interface BedSpec {
  key: BedKey;
  /** What the mixer heading calls this bed. */
  name: string;
  /** Its layers, in mixer order. A bed only lists the slots it actually fills. */
  layers: BedLayer[];
  drone: DroneVoicing;
  shimmer: ShimmerVoicing;
  bell: BellVoicing;
}

function layer(track: BedTrackKey, name: string): BedLayer {
  return { track, name };
}

/** The chord and the bell act I has always had. Four beds quote it. */
const WATER_DRONE: DroneVoicing = { partials: [1, 1.5, 2, 3], cutoff: 520, gain: 0.055, spread: 6 };

export const BEDS: Record<BedKey, BedSpec> = {
  /**
   * Act I, unchanged to the digit. It is the bed every other one in this table
   * was written against, and the only thing that happened to it here is that its
   * five layers acquired names in a mixer the player can open mid-dive.
   */
  deep: {
    key: 'deep',
    name: 'The Deep',
    layers: [
      layer('ocean', 'Bubbles'),
      layer('drone', 'Deep drone'),
      layer('shimmer', 'Surface shimmer'),
      layer('ambience', 'Distant bells'),
      layer('whale', 'Whale song'),
    ],
    drone: WATER_DRONE,
    shimmer: { hz: 1500, q: 1.6, gain: 0.05, rate: 1.7 },
    bell: { gap: [21, 44], octave: 1, strike: 1, hold: 5.5 },
  },

  /**
   * Act II. The same room with wings in it, and the first bed to separate the
   * medium's own voice from the life being carried through it: the gusts moved
   * off the flock's track, so somebody who wants only the wind can have it.
   */
  flight: {
    key: 'flight',
    name: 'Flight',
    layers: [
      layer('ocean', 'Wingbeats'),
      layer('motion', 'Gusts'),
      layer('drone', 'Deep drone'),
      layer('shimmer', 'High wind'),
      layer('ambience', 'Distant bells'),
      layer('whale', 'Distant thunder'),
    ],
    drone: { partials: [1, 1.5, 2, 3], cutoff: 640, gain: 0.05, spread: 8 },
    shimmer: { hz: 2100, q: 2.1, gain: 0.042, rate: 2.1 },
    bell: { gap: [21, 44], octave: 1, strike: 1, hold: 5.5 },
  },

  /**
   * Act III. Nearly empty on purpose: four crystals a minute, a shear every half
   * minute, and a chord with no root in it because there is not enough air up
   * here to carry a low note. It is the quietest bed in the game and it is
   * supposed to be the one people describe as beautiful.
   */
  thin: {
    key: 'thin',
    name: 'The Thinning',
    layers: [
      layer('ocean', 'Ice crystals'),
      layer('motion', 'Layer shear'),
      layer('drone', 'Thin drone'),
      layer('shimmer', 'Nacreous halo'),
      layer('ambience', 'Glass bells'),
      layer('whale', 'Infrasound'),
    ],
    // No root: the fifth is the lowest voice, and the stack runs up to the
    // twelfth. High, open and airless.
    drone: { partials: [1.5, 3, 4, 6], cutoff: 1400, gain: 0.036, spread: 18 },
    shimmer: { hz: 3200, q: 3.4, gain: 0.03, rate: 2.8 },
    bell: { gap: [26, 52], octave: 2, strike: 1.4, hold: 4.2 },
  },

  /**
   * Act IV. §13's three sounds and nothing else. The chord is two octaves down
   * and almost closed - it is not a pad, it is what is left of one - because the
   * subject of the act is that there is no room for a room to be in.
   */
  orbit: {
    key: 'orbit',
    name: 'Orbit',
    layers: [
      layer('ocean', 'Breath'),
      layer('motion', 'Heartbeat'),
      layer('drone', 'Sub drone'),
      layer('shimmer', 'The ring of silence'),
      layer('ambience', 'Pure bell'),
      layer('whale', 'Whistlers'),
    ],
    drone: { partials: [0.5, 0.75, 1, 1.5], cutoff: 210, gain: 0.045, spread: 3 },
    // Very high, very narrow, very quiet: the ringing you notice in a silent room.
    shimmer: { hz: 5400, q: 9, gain: 0.012, rate: 3.4 },
    bell: { gap: [38, 74], octave: 2, strike: 0, hold: 9 },
  },

  /**
   * Act V. The only broadband layer in the game, and it breathes and then goes
   * out. The chord opens twenty-two cents wide - four voices nearly agreeing,
   * which is what heat sounds like - and `AudioEngine` walks that back to six as
   * the arc runs, so the fire cooling is audible in the tuning.
   */
  fire: {
    key: 'fire',
    name: 'The Fallback',
    layers: [
      layer('ocean', 'The sheath'),
      layer('motion', 'Shock waves'),
      layer('drone', 'Hot drone'),
      layer('shimmer', 'Ablation sparks'),
      layer('ambience', 'Low bells'),
      layer('whale', 'Sonic boom'),
    ],
    drone: { partials: [1, 1.5, 2, 3], cutoff: 380, gain: 0.058, spread: 22 },
    shimmer: { hz: 4200, q: 2.6, gain: 0.02, rate: 3 },
    bell: { gap: [24, 46], octave: 0.5, strike: 0.7, hold: 6.5 },
  },

  /**
   * Act VI. Fifteen drops a second and not one hiss: the sheet swings the
   * density instead of a fader, which is what makes rain restful and what a
   * noise layer can never do.
   */
  rain: {
    key: 'rain',
    name: 'The Rain',
    layers: [
      layer('ocean', 'Raindrops'),
      layer('motion', 'The shower'),
      layer('drone', 'Warm drone'),
      layer('shimmer', 'Leaf patter'),
      layer('ambience', 'Distant bells'),
      layer('whale', 'Thunder'),
    ],
    drone: { partials: [1, 1.5, 2, 3], cutoff: 700, gain: 0.05, spread: 7 },
    // The shimmer slot is the patter's, so the held layer under it is almost
    // nothing - just enough to keep the drops from sitting on silence.
    shimmer: { hz: 2600, q: 2.2, gain: 0.012, rate: 2.4 },
    bell: { gap: [20, 40], octave: 1, strike: 1, hold: 5.5 },
  },

  /**
   * The seam. Act VI's last two stations and act VII's first, and the densest
   * layer in the campaign: twenty small bubbles a second, which is what a
   * shallow rocky stream actually is.
   */
  brook: {
    key: 'brook',
    name: 'The Brook',
    layers: [
      layer('ocean', 'The riffle'),
      layer('motion', 'The current'),
      layer('drone', 'Close drone'),
      layer('shimmer', 'Ripples'),
      layer('ambience', 'Wooden bells'),
      layer('whale', 'Stones on the bed'),
    ],
    drone: { partials: [1, 1.5, 2, 3], cutoff: 820, gain: 0.045, spread: 5 },
    shimmer: { hz: 3600, q: 2.8, gain: 0.022, rate: 2.6 },
    bell: { gap: [22, 42], octave: 1, strike: 0.5, hold: 3.6 },
  },

  /**
   * Act VII. The same instrument as act I, played downward - and the only bed in
   * the game that resolves: `AudioEngine` adds the root an octave under the
   * chord across the last station, which is the one thing act I never does.
   *
   * The two layers act I does not have are both about the direction. Marine snow
   * falls, and the whale is *near*: same voice, less room, more often, because
   * the animal that was a long way off in the first act is answering in the last.
   */
  homecoming: {
    key: 'homecoming',
    name: 'The Homecoming',
    layers: [
      // The same voice as act I's and named for the direction, because that is
      // the only thing about it that is different and it is the whole act.
      layer('ocean', 'Sinking bubbles'),
      layer('motion', 'Marine snow'),
      layer('drone', 'Sinking drone'),
      layer('shimmer', 'The fading light'),
      layer('ambience', 'Low bells'),
      layer('whale', 'The near whale'),
    ],
    drone: WATER_DRONE,
    shimmer: { hz: 1300, q: 1.5, gain: 0.045, rate: 1.5 },
    bell: { gap: [18, 38], octave: 0.5, strike: 0.8, hold: 7 },
  },
};

export const BED_LIST: BedSpec[] = BED_KEYS.map((k) => BEDS[k]);

/**
 * Which bed an act's station plays.
 *
 * Both arguments are needed and neither is enough on its own:
 *
 *   * **The medium is not enough**, because acts I and VII are both flown in
 *     water and are opposites - one rises out of the dark and one sinks into it.
 *     Keying on the medium alone is what made the last act of the campaign sound
 *     like the first one played back, which is a joke the circuit does not need
 *     help making.
 *   * **The act is not enough**, because act VI's last two stations and act
 *     VII's first are the same running water, authored either side of an act
 *     line. A bed that stopped at the line would cut the one handover the whole
 *     circuit is pointing at.
 *
 * Total by construction: every `MediumKind` has an answer, so a station cannot
 * be authored into silence by forgetting to name a bed.
 */
export function bedFor(actKey: string, medium: MediumKind): BedKey {
  switch (medium) {
    case 'air':
      return 'flight';
    case 'thinAir':
      return 'thin';
    case 'space':
      return 'orbit';
    case 'plasma':
      return 'fire';
    /*
     * Cloud is two different rooms and needs the act to tell them apart, exactly
     * as water does two cases down.
     *
     * Act V's last two stations are `cloud` - the meteor dust and the nucleus -
     * and they are what a meteor cools into, not weather the swarm is inside. On
     * the medium alone the `fire` bed was taken away halfway through the meteor
     * dust, at which point `sheathLevel` is still 0.49, so the act's one piece of
     * long-form dramaturgy - a sheath that runs down to nothing over four minutes
     * - was cut off at half strength and finished by a four-second crossfade. The
     * same mapping then played fifteen raindrops a second and a mixer layer named
     * *Leaf patter* at minus twelve thousand metres, inside a cooling meteor.
     */
    case 'cloud':
      return actKey === 'reentry' ? 'fire' : 'rain';
    case 'stream':
      return 'brook';
    default:
      return actKey === 'home' ? 'homecoming' : 'deep';
  }
}

/** The layers of one bed, or the deep's if the key is somehow unknown. */
export function bedSpec(key: BedKey): BedSpec {
  return BEDS[key] ?? BEDS.deep;
}
