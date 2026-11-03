import type { BedKey } from './Beds';

/**
 * Slowblue: the rescue, per act - the one moment the game rewards you.
 *
 * A dashed ring is the campaign's oldest mechanic and its only payoff: hold
 * enough of what you are carrying inside it and what was caged joins you. It had
 * one sound for all forty-two stations - two notes, a bright band, three bowls -
 * which is act I's sound, and act I's sound is a shoal of fish being let out into
 * forty metres of water. It played unchanged in vacuum, in a plasma sheath and in
 * a rainstorm.
 *
 * ## What a rescue is made of
 *
 * Two things, and separating them is the whole design here.
 *
 *   1. **An interval**, in the same minor pentatonic everything else in the game
 *      is in, so nothing can land sour against the bed and nothing can resolve.
 *      That is what makes it read as *reward* rather than as feedback.
 *   2. **The medium's own material, converging.** Six wingbeats, nine raindrops,
 *      four ice crystals - the act's own grain voice, dealt from wide apart and
 *      collapsing toward where the ring was. That is what makes act VI's rescue
 *      sound like rain gathering and act II's like a flock closing up, out of the
 *      same code and without a sample anywhere.
 *
 * The convergence is the part worth defending. Everything else in this engine
 * that plays more than one grain at once - a gurgle, a flock beat, a shower of
 * whistlers - spreads them *outward*, because that is what a body of something
 * coming apart does. The rescue is the only place they come together, and a
 * stereo field closing is the most legible "this is now one thing" a mix can say.
 *
 * ## Two rules the table obeys
 *
 *   * **Act I does not move.** The `deep` entry below reproduces the old code
 *     exactly - the same degrees, delays, gains, pans and bands, digit for digit.
 *     Everything else is written against it.
 *   * **Act IV has no material and gets none.** §13 allows breath, heartbeat and
 *     a fine internal resonance up there; a burst of noise announcing a rescue
 *     would be the loudest lie in the campaign. Its reward is the ring of silence
 *     briefly becoming a chord, and nothing is struck, because nothing up there
 *     can be hit.
 */

/** Which of the bed's own voices converges. `null` where the medium has none. */
export type RescueGrain =
  | 'bubble'
  | 'wing'
  | 'crystal'
  | 'drop'
  | 'riffle'
  | 'flake'
  | 'spark'
  | null;

export interface RescueNote {
  /** Index into the game's pentatonic `SCALE`. */
  degree: number;
  /** Seconds. */
  duration: number;
  /** Peak gain. */
  gain: number;
  /** Seconds after the rescue. */
  delay: number;
  /** Multiplier on the event's own stereo position. */
  pan: number;
  /** Played only for a big pod. See `AudioEngine.rescue`. */
  big?: boolean;
}

/** The wide filtered swell under the notes. `null` where the act allows no noise. */
export interface RescueBand {
  hz: number;
  /** Where it sweeps to. **Downward in exactly two acts** - see the table. */
  to: number;
  q: number;
  gain: number;
  duration: number;
  pan: number;
  /** Reverb send. How far away the reward is, which is a per-act judgement. */
  wet: number;
}

export interface RescueGrains {
  voice: RescueGrain;
  /** How many converge. */
  count: number;
  /** How wide they start, -1..1. They finish on the ring. */
  spread: number;
  /** Seconds the convergence takes. */
  span: number;
  /** Peak gain of one grain. */
  gain: number;
}

export interface RescueVoice {
  /** Register multiplier on the notes. 1 is act I's. */
  octave: number;
  /** Seconds of swell on a note. Act IV's is a second and a half. */
  attack: number;
  /** Reverb send, 0..1. */
  wet: number;
  /** The rescue itself: what a pod joining you sounds like. */
  notes: RescueNote[];
  band: RescueBand | null;
  grains: RescueGrains | null;
  /**
   * ...and the *required* ring, which fires on the same frame and is the larger
   * half of the sound. Struck bowls in seven acts and long pure tones in the one
   * where nothing can be struck.
   */
  ring: {
    struck: boolean;
    notes: RescueNote[];
    band: RescueBand | null;
  };
  /**
   * The held shimmer while a ring is being filled, as semitones above the root.
   *
   * The one continuous voice the player *plays*, so it belongs to the act too: it
   * is a fifth up in the sea and two octaves higher and narrower in the upper air.
   * `AudioEngine.setRingHold` slides between `from` and `to` as the ring fills.
   */
  hold: { from: number; to: number; octave: number };
}

/**
 * Act I's, and the shape every other entry is a variation on. Quoted rather than
 * copied so the two acts that keep the sea's own reward cannot drift from it.
 */
const DEEP: RescueVoice = {
  octave: 1,
  attack: 0.06,
  wet: 0.7,
  notes: [
    { degree: 2, duration: 1.6, gain: 0.03, delay: 0, pan: 0.5 },
    { degree: 4, duration: 1.9, gain: 0.026, delay: 0.11, pan: 0.7 },
    { degree: 7, duration: 2.4, gain: 0.02, delay: 0.22, pan: 0.6, big: true },
  ],
  band: { hz: 1100, to: 2200, q: 2, gain: 0.014, duration: 0.9, pan: 0.85, wet: 0.8 },
  grains: null,
  ring: {
    struck: true,
    notes: [
      { degree: 2, duration: 0, gain: 0.055, delay: 0, pan: 0.35 },
      { degree: 5, duration: 0, gain: 0.04, delay: 0.16, pan: 0.65 },
      { degree: 7, duration: 0, gain: 0.03, delay: 0.33, pan: 0.9 },
    ],
    band: { hz: 900, to: 2600, q: 1.4, gain: 0.016, duration: 1.4, pan: 0.8, wet: 0.9 },
  },
  hold: { from: 3, to: 7, octave: 1 },
};

export const RESCUES: Record<BedKey, RescueVoice> = {
  /** Act I, to the digit. */
  deep: DEEP,

  /**
   * Act II. The flock closing up.
   *
   * Higher and shorter than the sea's - air is the thinner medium in every other
   * respect and it is here too - and the material is six wingbeats arriving from
   * both edges and finishing over the ring. A hundred birds converging is the one
   * sound this act has that the sea cannot make.
   */
  flight: {
    octave: 1,
    attack: 0.05,
    wet: 0.75,
    notes: [
      { degree: 3, duration: 1.3, gain: 0.028, delay: 0, pan: 0.55 },
      { degree: 6, duration: 1.6, gain: 0.024, delay: 0.09, pan: 0.75 },
      { degree: 9, duration: 2.1, gain: 0.019, delay: 0.19, pan: 0.6, big: true },
    ],
    band: { hz: 1600, to: 3400, q: 1.6, gain: 0.012, duration: 0.8, pan: 0.9, wet: 0.85 },
    grains: { voice: 'wing', count: 6, spread: 0.9, span: 0.5, gain: 0.05 },
    ring: {
      struck: true,
      notes: [
        { degree: 3, duration: 0, gain: 0.05, delay: 0, pan: 0.4 },
        { degree: 6, duration: 0, gain: 0.038, delay: 0.14, pan: 0.7 },
        { degree: 9, duration: 0, gain: 0.028, delay: 0.28, pan: 0.9 },
      ],
      band: { hz: 1400, to: 3600, q: 1.2, gain: 0.014, duration: 1.2, pan: 0.85, wet: 0.9 },
    },
    hold: { from: 5, to: 9, octave: 1.5 },
  },

  /**
   * Act III. Four crystals struck in an ascending arpeggio and almost nothing
   * else - the emptiest reward in the game, in the emptiest act. Two octaves up,
   * so it sits above a bed that has no root in it, and its band is the narrowest
   * here because at 25 km there is not enough air to carry a wide one.
   */
  thin: {
    octave: 2,
    attack: 0.09,
    wet: 0.9,
    notes: [
      { degree: 2, duration: 2.4, gain: 0.02, delay: 0, pan: 0.5 },
      { degree: 5, duration: 2.8, gain: 0.017, delay: 0.16, pan: 0.75 },
      { degree: 8, duration: 3.4, gain: 0.013, delay: 0.34, pan: 0.55, big: true },
    ],
    band: { hz: 3800, to: 5200, q: 4.5, gain: 0.006, duration: 1.2, pan: 0.95, wet: 0.95 },
    grains: { voice: 'crystal', count: 4, spread: 0.95, span: 0.7, gain: 0.014 },
    ring: {
      struck: true,
      notes: [
        { degree: 4, duration: 0, gain: 0.036, delay: 0, pan: 0.45 },
        { degree: 7, duration: 0, gain: 0.028, delay: 0.24, pan: 0.8 },
        { degree: 10, duration: 0, gain: 0.021, delay: 0.5, pan: 0.6 },
      ],
      band: { hz: 3200, to: 6000, q: 3.4, gain: 0.008, duration: 1.8, pan: 0.9, wet: 0.95 },
    },
    hold: { from: 7, to: 12, octave: 2 },
  },

  /**
   * Act IV. The ring of silence, briefly becoming a chord.
   *
   * No band, no grains and nothing struck - §13 leaves breath, heartbeat and a
   * fine internal resonance, and a rescue cue made of any material at all would
   * contradict the one act whose subject is that there is no material. So the
   * reward is three sine partials entering a long way apart with second-long
   * swells, and one fifth underneath so quiet it is felt rather than placed. It
   * is the quietest reward in the campaign and the only one with no onset.
   */
  orbit: {
    octave: 2,
    attack: 0.9,
    wet: 1,
    notes: [
      { degree: 4, duration: 3.6, gain: 0.016, delay: 0, pan: 0.6 },
      { degree: 7, duration: 4.2, gain: 0.013, delay: 0.5, pan: 0.85 },
      { degree: 10, duration: 5, gain: 0.009, delay: 1.1, pan: 0.4, big: true },
    ],
    band: null,
    grains: null,
    ring: {
      struck: false,
      notes: [
        { degree: 2, duration: 6, gain: 0.02, delay: 0, pan: 0.5 },
        { degree: 7, duration: 7, gain: 0.015, delay: 0.9, pan: 0.85 },
        { degree: 10, duration: 8, gain: 0.01, delay: 2, pan: 0.3 },
      ],
      band: null,
    },
    hold: { from: 7, to: 12, octave: 3 },
  },

  /**
   * Act V. The heat clearing, for a second and a half.
   *
   * The one act built entirely on downward filter sweeps - the sheath, the
   * shocks, the nucleus cue all close - so its reward is the only thing in it
   * that **opens**, 300 Hz to 1.8 kHz. Low, warm notes under it, because relief
   * inside a loud act has to arrive from underneath rather than over the top, and
   * five sparks converging, which is the fire itself briefly on your side.
   */
  fire: {
    octave: 0.5,
    attack: 0.12,
    wet: 0.65,
    notes: [
      { degree: 1, duration: 2.2, gain: 0.036, delay: 0, pan: 0.45 },
      { degree: 4, duration: 2.6, gain: 0.03, delay: 0.13, pan: 0.7 },
      { degree: 6, duration: 3.2, gain: 0.023, delay: 0.28, pan: 0.55, big: true },
    ],
    band: { hz: 300, to: 1800, q: 0.8, gain: 0.02, duration: 1.5, pan: 0.75, wet: 0.6 },
    grains: { voice: 'spark', count: 5, spread: 0.9, span: 0.45, gain: 0.012 },
    ring: {
      struck: true,
      notes: [
        { degree: 1, duration: 0, gain: 0.055, delay: 0, pan: 0.4 },
        { degree: 4, duration: 0, gain: 0.042, delay: 0.2, pan: 0.7 },
        { degree: 8, duration: 0, gain: 0.03, delay: 0.42, pan: 0.85 },
      ],
      band: { hz: 260, to: 2200, q: 0.7, gain: 0.022, duration: 2.2, pan: 0.8, wet: 0.65 },
    },
    hold: { from: 2, to: 6, octave: 0.75 },
  },

  /**
   * Act VI. The one act where a ring means *you again*, and the only rescue that
   * sounds like water arriving rather than water leaving.
   *
   * Nine drops from the full width of the field, collapsing onto the ring inside
   * a third of a second, over a band that falls instead of rising - rain does not
   * open upward, it lands. It is the most literal thing in this table and the one
   * most likely to be the reason somebody keeps playing act VI.
   */
  rain: {
    octave: 1,
    attack: 0.05,
    wet: 0.7,
    notes: [
      { degree: 2, duration: 1.5, gain: 0.03, delay: 0, pan: 0.5 },
      { degree: 5, duration: 1.8, gain: 0.026, delay: 0.1, pan: 0.72 },
      { degree: 9, duration: 2.3, gain: 0.019, delay: 0.24, pan: 0.55, big: true },
    ],
    band: { hz: 2400, to: 800, q: 1.1, gain: 0.015, duration: 1.1, pan: 0.9, wet: 0.8 },
    grains: { voice: 'drop', count: 9, spread: 0.95, span: 0.32, gain: 0.016 },
    ring: {
      struck: true,
      notes: [
        { degree: 2, duration: 0, gain: 0.05, delay: 0, pan: 0.4 },
        { degree: 5, duration: 0, gain: 0.04, delay: 0.15, pan: 0.7 },
        { degree: 9, duration: 0, gain: 0.03, delay: 0.31, pan: 0.9 },
      ],
      band: { hz: 3000, to: 900, q: 1, gain: 0.017, duration: 1.6, pan: 0.85, wet: 0.85 },
    },
    hold: { from: 3, to: 8, octave: 1.25 },
  },

  /**
   * The brook. The fastest reward in the game, because the medium is.
   *
   * Ten small bubbles inside a fifth of a second and notes shorter than anywhere
   * else - a stream does not hold anything, and a slow cue over running water
   * reads as two pieces of music rather than one.
   */
  brook: {
    octave: 1.5,
    attack: 0.04,
    wet: 0.6,
    notes: [
      { degree: 3, duration: 1.1, gain: 0.026, delay: 0, pan: 0.5 },
      { degree: 5, duration: 1.3, gain: 0.022, delay: 0.07, pan: 0.72 },
      { degree: 8, duration: 1.7, gain: 0.017, delay: 0.15, pan: 0.55, big: true },
    ],
    band: { hz: 700, to: 2600, q: 1.3, gain: 0.013, duration: 0.7, pan: 0.85, wet: 0.55 },
    grains: { voice: 'riffle', count: 10, spread: 0.85, span: 0.2, gain: 0.012 },
    ring: {
      struck: true,
      notes: [
        { degree: 3, duration: 0, gain: 0.046, delay: 0, pan: 0.4 },
        { degree: 5, duration: 0, gain: 0.036, delay: 0.11, pan: 0.68 },
        { degree: 8, duration: 0, gain: 0.028, delay: 0.23, pan: 0.88 },
      ],
      band: { hz: 900, to: 3000, q: 1.1, gain: 0.015, duration: 1, pan: 0.8, wet: 0.6 },
    },
    hold: { from: 5, to: 10, octave: 1.5 },
  },

  /**
   * Act VII. The only rescue in the game that **falls**.
   *
   * Every other entry here climbs, because every other act is about gathering
   * something up. This one is about letting it settle: the degrees descend, the
   * band closes from 1.8 kHz to 400, and the material is five flakes of marine
   * snow drifting in. It is the same gesture as act I's, played backwards and an
   * octave down, which is what the whole act is.
   */
  homecoming: {
    octave: 0.5,
    attack: 0.14,
    wet: 0.8,
    notes: [
      { degree: 7, duration: 2.6, gain: 0.032, delay: 0, pan: 0.5 },
      { degree: 4, duration: 3.1, gain: 0.027, delay: 0.18, pan: 0.72 },
      { degree: 1, duration: 3.8, gain: 0.022, delay: 0.4, pan: 0.55, big: true },
    ],
    band: { hz: 1800, to: 400, q: 0.9, gain: 0.014, duration: 1.6, pan: 0.8, wet: 0.9 },
    grains: { voice: 'flake', count: 5, spread: 0.9, span: 0.9, gain: 0.012 },
    ring: {
      struck: true,
      notes: [
        { degree: 7, duration: 0, gain: 0.05, delay: 0, pan: 0.4 },
        { degree: 4, duration: 0, gain: 0.04, delay: 0.22, pan: 0.7 },
        { degree: 0, duration: 0, gain: 0.032, delay: 0.5, pan: 0.85 },
      ],
      band: { hz: 2200, to: 350, q: 0.8, gain: 0.016, duration: 2.4, pan: 0.85, wet: 0.95 },
    },
    hold: { from: 2, to: 5, octave: 0.75 },
  },
};

export function rescueVoice(bed: BedKey): RescueVoice {
  return RESCUES[bed] ?? DEEP;
}

/**
 * Where one converging grain comes from, -1..1.
 *
 * Alternating sides, each starting further out than the last, and every one
 * finishing on the ring - so what the ear follows is a field closing rather than
 * a burst opening. `u` is the grain's position in the run, 0..1.
 */
export function grainPan(index: number, count: number, spread: number, ringPan: number): number {
  const u = count <= 1 ? 1 : index / (count - 1);
  const side = index % 2 === 0 ? -1 : 1;
  // Widest first: the last grains in are already almost home.
  const from = side * spread * (1 - u * 0.15);
  const at = from + (ringPan - from) * u * u;
  return Math.max(-1, Math.min(1, at));
}
