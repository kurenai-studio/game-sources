/**
 * Slowblue: act VII - marine snow, and the one voice in the game that falls.
 *
 * Act VII is act I's water met going the other way, and the bed says so by using
 * act I's own voices with the depth running backwards: the bubbles get big, low
 * and slow, the shimmer closes, and the bell sinks. That rhyme is the point of
 * the act and it is why nothing here replaces those layers.
 *
 * But the act has one thing act I never had, and it is on screen in the fifth
 * station: **the whole world is falling the way the player is.** Marine snow -
 * the continuous drift of dead plankton, shells and aggregate that rains out of
 * the sunlit water and takes weeks to reach the bottom. It is the only occasion
 * in the campaign where the swarm is not passing through the world but descending
 * with it, and it needed a sound of its own or the station's whole idea would be
 * carried by the picture alone.
 *
 * ## What a falling sound is
 *
 * Every other event in this game either rises or holds. A bubble's pitch climbs,
 * a crystal sags a semitone and stops, a whale glides a fourth and lands. A flake
 * of marine snow does something none of them do: it is *very* quiet, it is high,
 * it lasts a second and a half, and its pitch falls the whole way down without
 * ever arriving - the envelope runs out before the glide does. Nothing about it
 * resolves. That is what falling for six weeks sounds like, and it is also, not
 * coincidentally, the single most ASMR gesture the engine can make: a small,
 * soft, high, unresolved thing passing near your ear and going away.
 *
 * They arrive off-centre, always, and never twice from the same side in a row -
 * the caller alternates. A sound directly in front of you is a sound in a
 * speaker; a sound slightly to one side and slightly above is a sound in a room
 * you are in.
 *
 * ## The density
 *
 * Densest in the middle of the descent and thin at both ends, which is true -
 * the snow is produced in the sunlit zone and most of it is eaten or dissolved
 * long before the floor. So the act opens with almost none, fills with it around
 * the twilight and deep-sea stations, and arrives at the trench floor with the
 * water nearly empty again. The last station of the campaign is very close to
 * silent, and that is what lets `AudioEngine.circle()` land on it.
 */

import { snapHz } from './Scale';

function clamp01(v: number): number {
  return v < 0 ? 0 : v > 1 ? 1 : v;
}

/** The band a flake passes through, in Hz. */
export const SNOW_MIN_HZ = 1300;
export const SNOW_MAX_HZ = 4200;

export interface Flake {
  /** Where it starts, in Hz. */
  hz: number;
  /** ...and where it is still going when the envelope runs out. */
  glideTo: number;
  /** Seconds. Long for something this quiet: it is passing, not arriving. */
  duration: number;
  /** 0..1, relative to the track's own level. Never above a third. */
  gain: number;
  /** -1..1, and never near the middle. */
  pan: number;
}

/**
 * One flake, passing. `depth01` is 0 at the salt line and 1 on the trench floor;
 * deeper flakes are larger, lower and slower, because what survives the descent
 * is the aggregate that clumped on the way down.
 *
 * `side` is -1 or 1 and is chosen by the caller rather than drawn here, so
 * consecutive flakes can be made to alternate - a stream of them all landing on
 * one side is a leak, not a snowfall.
 */
export function flake(rand: () => number, depth01: number, side: number): Flake {
  const d = clamp01(depth01);
  // Snapped, because a flake is a note. It is a pure sine ringing for one to three
  // seconds, one every couple of seconds, so at any moment two or three of them are
  // sounding together over act VII's drone - and three sines a quarter tone apart
  // do not read as snow, they read as a chord going out of tune. It is the one
  // texture in the game dense enough to overlap itself and slow enough to be heard
  // as pitch while it does. See `Scale.ts`.
  const hz = snapHz(SNOW_MAX_HZ - (SNOW_MAX_HZ - SNOW_MIN_HZ) * (0.35 * d + rand() * 0.65));
  return {
    hz,
    // A fourth to a seventh down, and it does not get there. See the header.
    glideTo: hz / (1.35 + rand() * 0.5),
    duration: (1.1 + rand() * 0.9) * (1 + d * 0.3),
    gain: (0.45 + rand() * 0.55) * (1 - d * 0.2),
    pan: side * (0.45 + rand() * 0.45),
  };
}

/**
 * Flakes per second. A hump: nothing at the top, most of it in the middle
 * water, and almost nothing on the floor.
 */
export function snowRate(depth01: number): number {
  const d = clamp01(depth01);
  // A raised cosine centred at 0.55, which is the twilight-to-deep-sea band.
  const hump = 0.5 - 0.5 * Math.cos(2 * Math.PI * clamp01((d + 0.05) / 1.1));
  return 0.15 + 1.5 * hump;
}
