/**
 * Slowblue: whale song, as a phrase rather than as a sound effect.
 *
 * Everything else in the bed is either a field (the water, the drone) or a single event
 * (a bell, a bubble). A whale is neither: it is the only thing in this game that is an
 * *animal* making a *sentence*, and the two properties that make a recorded whale
 * unmistakable are both structural rather than timbral.
 *
 *   1. **It glides.** A whale moan does not hold a pitch; it slides, usually by a third
 *      to a fifth, over seconds. A held tone with vibrato on it is a synthesiser. The
 *      same tone sliding a fourth downward over four seconds is an animal.
 *   2. **It is a phrase, then silence.** Two to four calls, seconds apart, and then
 *      nothing for a minute or two. What sells it is the *gap* - a whale that answers
 *      itself every ten seconds is a car alarm.
 *
 * The pitches are drawn from the same pentatonic set as the rest of the game, which is
 * not what a real whale does and is the right call anyway: the bed underneath is a fixed
 * open chord, and a call that lands a semitone off it is not evocative, it is out of tune.
 * The glide targets are chosen inside the set too, so even the slide passes through
 * nothing sour.
 *
 * That paragraph was true about the *intervals* and false about everything else for as
 * long as it has been here, which is what made it worth measuring. `STEPS` is a
 * pentatonic and always was - but it was a pentatonic on a root drawn from a continuous
 * range, so the phrase was internally in tune and collectively in a random key. Two to
 * seven seconds of it, at about the level of a bell, over a drone that does not move. A
 * comment that describes the intended behaviour of a line and not its actual behaviour
 * is the most expensive kind of comment there is. The phrase is counted in scale
 * degrees now rather than in semitones off a floating root - see `STEPS` and `hzAt` -
 * and the paragraph above is finally a description of what the file does. Nothing
 * about the animal changes: the root still climbs an octave across the campaign, the
 * calls still glide a fourth or a fifth, and the ear still hears the journey.
 *
 * `depth01` is 1 on the trench floor and 0 at the surface. Deep calls are lower, longer
 * and further away; near the surface they are brighter and closer. That is the same
 * mapping the bubbles use, for the same reason - the ascent should be audible with the
 * palette ignored.
 */

import { ROOT_HZ, degreeOf, scaleSemi } from './Scale';

/**
 * How far above the call root each available pitch is, **in scale degrees**.
 *
 * This was `[0, 3, 5, 7, 10, 12]` - the same six pitches, written as semitones -
 * and the rewrite is not cosmetic. Semitone offsets from a root that is itself free
 * produce a pentatonic in a random key, which is what the header describes; snapping
 * each resulting frequency instead fixes the key and breaks the intervals, because
 * two notes rounded independently do not keep the distance between them. That cost
 * the animal its glide: a fourth drawn off an off-scale root came out as a minor
 * third, and a minor third over four seconds is a wobble, which is precisely the
 * failure the two-step rule below exists to prevent. Counting in degrees is the only
 * form of this that gets both - every pitch is on the scale *and* two degrees apart
 * is always four or five semitones, whichever degree you start from.
 */
const STEPS = [0, 1, 2, 3, 4, 5];
/** The band a moan actually lives in: two octaves from a hum to a call. */
export const WHALE_MIN_HZ = 62;
export const WHALE_MAX_HZ = 420;
/** Seconds between phrases - a minute or two, because the gap is what sells the animal. */
export const WHALE_GAP_MIN = 52;
export const WHALE_GAP_MAX = 155;

export interface WhaleCall {
  /** Where the glide starts, in Hz. */
  hz: number;
  /** ...and where it ends. Always a different pitch: a whale does not hold. */
  glideTo: number;
  /** Seconds. */
  duration: number;
  /** Seconds after the phrase begins. */
  delay: number;
  /** 0..1, relative to the track's own level. */
  gain: number;
  /** -1..1. The animal is somewhere, and it is never in the middle. */
  pan: number;
}

function clamp01(v: number): number {
  return v < 0 ? 0 : v > 1 ? 1 : v;
}

/**
 * The pitch `step` degrees above wherever the animal is sitting.
 *
 * `root` is a free frequency - it has to be, it is a whale getting nearer the
 * surface across the campaign and not a key change - so it is read as a *position*
 * in the scale rather than as a pitch, and the phrase is built from there. The
 * register comes from the animal and the tuning comes from the game.
 */
function hzAt(root: number, step: number): number {
  return ROOT_HZ * Math.pow(2, scaleSemi(degreeOf(root) + step) / 12);
}

/**
 * Builds one phrase. `rand` is a 0..1 source, passed in rather than drawn here so the
 * whole model stays a pure function and can be tested against a fixed sequence.
 */
export function whalePhrase(rand: () => number, depth01 = 0): WhaleCall[] {
  const depth = clamp01(depth01);
  // Deep water gets the low end of the band. The root moves about an octave across the
  // campaign, which is a whale getting nearer the surface rather than a filter opening.
  const root = 78 * Math.pow(2, (1 - depth) * 0.85) * (0.9 + rand() * 0.2);
  const calls: WhaleCall[] = [];
  const count = 1 + Math.floor(rand() * 3.4);
  // One side for the whole phrase, wide: a single animal, not a choir. It drifts a
  // little between calls, because it is swimming.
  const side = rand() < 0.5 ? -1 : 1;
  let at = 0;
  for (let i = 0; i < count; i++) {
    const fromIndex = Math.min(STEPS.length - 1, Math.floor(rand() * STEPS.length));
    let toIndex = Math.min(STEPS.length - 1, Math.floor(rand() * STEPS.length));
    // A call that lands where it started is a held tone, which is the one thing a whale
    // never does - and one drawn a step away is a whole tone, which is a wobble rather
    // than a slide. Measured over the real sampler, adjacent steps of this set were
    // producing 168 -> 188 Hz calls that read as vibrato. Anything closer than two steps
    // is pushed out to two, which in this set is a fourth or a fifth: far enough that the
    // ear hears the *journey* and not the destination.
    if (Math.abs(toIndex - fromIndex) < 2) {
      toIndex = fromIndex <= 1 ? fromIndex + 2 : fromIndex - 2;
    }
    const from = STEPS[fromIndex]!;
    const to = STEPS[toIndex]!;
    // Long, and longer in the deep. Nothing under a second and a half: the point of the
    // voice is that it outlasts everything else in the mix.
    const duration = (2.1 + rand() * 2.6) * (1 + depth * 0.45);
    calls.push({
      hz: hzAt(root, from),
      glideTo: hzAt(root, to),
      duration,
      delay: at,
      // The first call of a phrase is the loudest; the answers are the animal turning away.
      gain: (i === 0 ? 1 : 0.62 + rand() * 0.24) * (1 - depth * 0.25),
      pan: Math.max(-1, Math.min(1, side * (0.55 + rand() * 0.35))),
    });
    // Silence between calls, longer than a musician would leave.
    at += duration * (0.55 + rand() * 0.5) + 0.6 + rand() * 1.9;
  }
  return calls;
}

/** Seconds until the next phrase should begin. */
export function whaleGap(rand: () => number): number {
  return WHALE_GAP_MIN + rand() * (WHALE_GAP_MAX - WHALE_GAP_MIN);
}
