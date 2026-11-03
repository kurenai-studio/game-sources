/**
 * Slowblue: the one set of pitches the game is allowed to play, and the rule for
 * which sounds have to obey it.
 *
 * These two constants used to live at the top of `AudioEngine.ts`, where only the
 * *authored* cues could reach them - the bell, the gate, the rescue notes. Every
 * voice whose pitch comes from a physical quantity instead of from a degree
 * number was written in Hz and answered to nothing. Measured across all eight
 * beds (`tests/tuning.test.ts`), that was **1445 voices ringing for longer than
 * half a second each, 745 of them more than 25 cents off anything the game plays,
 * 31 cents out on average and 99 at worst** - a quarter tone, held for two seconds,
 * over a drone that never moves. That is not a texture decision; it is the
 * definition of sour, and it was the loudest thing §2 was still asking for.
 *
 * ## The rule
 *
 * **A pitched voice longer than half a second is a note and must be on the scale.
 * Anything shorter is texture and must not be.**
 *
 * The line is not arbitrary. Under about 200 ms the ear does not extract a stable
 * pitch from a decaying sine at all - it hears an *event*, and its brightness,
 * which is why `Bubbles.ts` can derive a bubble's pitch from Minnaert and be
 * right to. Past a second the same sine is unmistakably a note, it overlaps the
 * next one, and two of them a quarter tone apart beat against each other and
 * against the drone. So the water keeps its physics and the ice, the snow and the
 * bell get tuned, and the boundary between them is a duration rather than a taste.
 *
 * Quantising the *texture* would be the worse mistake in the other direction:
 * fifteen raindrops a second snapped onto five pitch classes is a music box, not
 * rain, and act I's water would stop being water.
 */

/**
 * A minor pentatonic on A, spread over three octaves. Nothing the game plays can
 * land on a sour interval, and nothing it plays can resolve either - there is no
 * leading tone in the set, which is why it never sounds like a tune that ended.
 */
export const SCALE = [0, 3, 5, 7, 10, 12, 15, 17, 19, 22, 24];

/** A1. The bed lives an octave and a half below anything the events play. */
export const ROOT_HZ = 55;

/**
 * The five pitch classes `SCALE` is made of. Held separately because snapping a
 * free frequency needs the set to repeat forever in both directions, and an
 * eleven-entry array stops at two octaves.
 */
const CLASSES = [0, 3, 5, 7, 10];

/**
 * The semitone offset of a scale degree, for any integer including negative ones.
 *
 * `SCALE` is exactly this function tabulated for 0..10, and the table is kept
 * because the cues index it and clamp against its length. What the table cannot
 * do is go *below* the root, which is what the bell's darkening needs - see
 * `AudioEngine.bowl`.
 */
export function scaleSemi(degree: number): number {
  const i = Math.round(degree);
  return CLASSES[((i % 5) + 5) % 5]! + 12 * Math.floor(i / 5);
}

/** The frequency of a scale degree, four octaves up from the root: where cues live. */
export function degreeHz(degree: number, octave = 1): number {
  return ROOT_HZ * 4 * octave * Math.pow(2, scaleSemi(degree) / 12);
}

/**
 * The nearest member of the scale, in any octave.
 *
 * Deliberately a *snap* rather than a re-derivation. Every caller has already
 * chosen its pitch from something physical - a crystal's size, a flake's depth,
 * the speed of the finger - and that choice decides the register, the ordering
 * and the relationship to whatever else the act is doing. All this takes away is
 * the last few cents, which carry no information and are the only part of the
 * number the ear objects to. Snapping is also monotone, so "bigger is lower"
 * survives it; a caller that depended on strict monotonicity would not, and none
 * does.
 */
export function snapHz(hz: number): number {
  if (!(hz > 0)) return hz;
  return ROOT_HZ * Math.pow(2, scaleSemi(degreeOf(hz)) / 12);
}

/**
 * Which degree a frequency is nearest, as an index `scaleSemi` understands.
 *
 * The one that does the work; `snapHz` is this with the answer converted back into
 * a pitch. Written this way round rather than the other because a *position* is
 * the more useful of the two and cannot be recovered from a frequency without
 * doing this again: `Whale.ts` needs to find where the animal is sitting and then
 * step through a phrase from there, and stepping in frequency and snapping each
 * result is not the same operation - it rounds every note independently, so a
 * fourth drawn off an off-scale root comes out as a minor third. Which is how the
 * whale briefly acquired a vibrato.
 *
 * No allocation: `AudioEngine.tick` runs every frame and this is reachable from it.
 */
export function degreeOf(hz: number): number {
  if (!(hz > 0)) return 0;
  const semi = 12 * Math.log2(hz / ROOT_HZ);
  const octave = Math.floor(semi / 12);
  const within = semi - octave * 12;
  let bestIndex = 0;
  let bestDistance = Infinity;
  for (let i = 0; i < CLASSES.length; i++) {
    const d = Math.abs(within - CLASSES[i]!);
    if (d < bestDistance) {
      bestDistance = d;
      bestIndex = i;
    }
  }
  // The wrap: 11.2 semitones into an octave is nearer the *next* octave's root than
  // it is to this one's minor seventh, and a loop over five classes cannot see that.
  if (12 - within < bestDistance) return 5 * (octave + 1);
  return 5 * octave + bestIndex;
}

/**
 * How far a frequency sits from the nearest scale member, in cents. Signed, and
 * zero for anything that is not a frequency.
 *
 * The measuring instrument for the rule at the top of this file, and the reason
 * the claim above is a number rather than an opinion.
 */
export function centsOff(hz: number): number {
  if (!(hz > 0)) return 0;
  const snapped = snapHz(hz);
  return 1200 * Math.log2(hz / snapped);
}
