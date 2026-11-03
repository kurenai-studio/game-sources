/**
 * Slowblue: act IV, orbit - the three sounds there are when there is no medium.
 *
 * §13 is explicit and it is the tightest constraint in the project: in space
 * there is no conventional external sound, only breath, heartbeat and a very fine
 * internal resonance. `AudioEngine.overview()` already obeys it for four seconds
 * at the end of the act. This module is that rule held for the whole of it.
 *
 * The obvious way to score four hundred kilometres up is a wash of pad, and it is
 * wrong for a reason that is not taste: **a pad is a room**, and the subject of
 * act IV is that there is no room. Anything with a tail on it says "you are
 * inside something". So the act's bed is not outside the player at all. It is
 * inside them, which is both what §13 asks for and the most intimate thing this
 * game does - the mix moves from a body of water, to a body of air, to a body.
 *
 * ## The breath
 *
 * The one voice that is not scheduled. It runs off the game's own eleven-second
 * breath clock (`sim/Breath.ts`), the same one the picture breathes on, so a
 * player breathing with the game hears their own breath come back to them a beat
 * later. Two soft bands rather than one - a low body around 240 Hz and a
 * near-field band up at 1.9 kHz, which is where the air actually is in a breath
 * heard from inside a helmet - and the high one is *quieter on the inhale*,
 * because an in-breath through the nose is dark and an out-breath through the
 * mouth is bright. That asymmetry is the whole reason it reads as breath and not
 * as a filter sweep.
 *
 * ## The heartbeat
 *
 * A lub-dub at somewhere between 46 and 58 beats a minute - a resting rate, and
 * the *lower* end of one, because the act slows the player rather than the other
 * way round. It is two sine thumps 0.14 s apart, the second quieter and shorter,
 * both under 50 Hz. There is no click on either, so on most phone speakers it
 * cannot be heard at all and on headphones it is felt in the chest. That is the
 * correct outcome: a heartbeat that is *audible* is a horror cue.
 *
 * The rate falls across the act, which is the only bit of dramaturgy in this file
 * and is earned - by the Overview the player has stopped doing anything.
 *
 * ## The whistlers
 *
 * The one external voice, and the only sound in space that is real. Lightning in
 * the troposphere radiates VLF; the wave follows a field line out through the
 * magnetosphere and back, and because the higher frequencies travel faster it
 * arrives spread out - as a descending whistle, several seconds long, falling
 * from a few kilohertz to a few hundred hertz. Every crewed spacecraft that has
 * ever put a receiver on that band has heard them. They come in showers, they are
 * unmistakably not synthetic, and they are the one thing that can be in this act
 * without contradicting it: not a sound in space, a *radio* sound, which is what
 * space actually has.
 *
 * The descent is `1/sqrt(f)` in shape - that is the real dispersion relation, and
 * it is why a whistler sags fast at the top and crawls at the bottom instead of
 * gliding evenly. Nothing else in the game has that curve.
 */

function clamp01(v: number): number {
  return v < 0 ? 0 : v > 1 ? 1 : v;
}

/** Beats per minute at the start of the act, and at the Overview. */
export const HEART_BPM_START = 58;
export const HEART_BPM_END = 46;

/** The resting rate, slowing across the act. */
export function heartRate(arc01: number): number {
  const t = clamp01(arc01);
  return HEART_BPM_START + (HEART_BPM_END - HEART_BPM_START) * t;
}

export interface HeartThump {
  hz: number;
  /** Seconds. */
  duration: number;
  /** Seconds after the beat begins. */
  delay: number;
  /** 0..1, relative to the track's own level. */
  gain: number;
}

/**
 * One beat: lub, then dub.
 *
 * The two thumps are the two valve closures and they are genuinely different
 * sounds - the first is longer, lower and louder, the second is the shorter snap
 * of the semilunar valves. 0.14 s apart, which is systole and is why a heartbeat
 * is heard as one event with a shape rather than as two beats.
 */
export function heartBeat(): HeartThump[] {
  return [
    { hz: 38, duration: 0.2, delay: 0, gain: 1 },
    { hz: 46, duration: 0.14, delay: 0.14, gain: 0.62 },
  ];
}

/**
 * The breath, as two bands. `swell01` is 1 fully inhaled.
 *
 * Returns the level and corner of each band. The caller holds two continuous
 * voices and pushes these at them every frame - there is nothing to schedule,
 * because a breath is not an event.
 */
export interface BreathVoice {
  /** The body of it, low and always there. */
  bodyHz: number;
  bodyGain: number;
  /** The air in it, near-field, and brighter going out than coming in. */
  airHz: number;
  airGain: number;
}

export function breathVoice(swell01: number): BreathVoice {
  const s = clamp01(swell01);
  // Both halves of the cycle are audible - a breath that disappears at the turn
  // is a gate - so neither gain ever reaches zero.
  const moving = 0.35 + 0.65 * Math.sin(Math.PI * s);
  return {
    bodyHz: 210 + 90 * s,
    bodyGain: 0.55 + 0.45 * moving,
    airHz: 1500 + 900 * (1 - s),
    // The out-breath is the bright one. See the file header.
    airGain: moving * (0.3 + 0.7 * (1 - s)),
  };
}

export interface Whistler {
  /** Where the descent starts, in Hz. Always the top of the band. */
  fromHz: number;
  /** ...and where it ends, a couple of octaves down. */
  toHz: number;
  /** Seconds. One and a half to three: dispersion over a field line. */
  duration: number;
  /** Seconds after the shower begins. */
  delay: number;
  /** 0..1, relative to the track's own level. */
  gain: number;
  /** -1..1. */
  pan: number;
}

/**
 * One shower: two to five whistlers, seconds apart, from one storm.
 *
 * They share a side, because they came down the same field line, and they get
 * quieter and slower through the shower as the storm walks away underneath.
 */
export function whistlerShower(rand: () => number): Whistler[] {
  const count = 2 + Math.floor(rand() * 4);
  const side = rand() < 0.5 ? -1 : 1;
  const out: Whistler[] = [];
  let at = 0;
  for (let i = 0; i < count; i++) {
    const fromHz = 3400 + rand() * 2600;
    out.push({
      fromHz,
      toHz: fromHz / (5 + rand() * 4),
      duration: 1.5 + rand() * 1.5 + i * 0.15,
      delay: at,
      gain: (1 - i * 0.16) * (0.7 + rand() * 0.3),
      pan: side * (0.4 + rand() * 0.5),
    });
    at += 0.9 + rand() * 2.4;
  }
  return out;
}

/** Seconds to the next shower. Rare: a whistler you waited for is a whistler. */
export function whistlerGap(rand: () => number): number {
  return 52 + rand() * 84;
}
