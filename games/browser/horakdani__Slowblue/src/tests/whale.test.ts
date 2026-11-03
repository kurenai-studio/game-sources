import { describe, expect, it } from 'vitest';
import {
  WHALE_GAP_MAX,
  WHALE_GAP_MIN,
  WHALE_MAX_HZ,
  WHALE_MIN_HZ,
  whaleGap,
  whalePhrase,
} from '../src/audio/Whale';
import { AUDIO_TRACK_KEYS, defaultSettings, sanitizeSettings } from '../src/config/settings';
import { STRINGS } from '../src/i18n/strings';

/** A deterministic stand-in for `Math.random`, so a phrase can be asserted exactly. */
function seq(values: number[]): () => number {
  let i = 0;
  return () => values[i++ % values.length]!;
}

/**
 * What makes a synthesised whale a whale is structural, not timbral, so that is what is
 * pinned here: it glides rather than holds, it is a phrase with silence in it, and it
 * never lands outside the band a moan actually lives in.
 */
describe('whale song', () => {
  it('always glides: no call ends where it started', () => {
    for (let s = 0; s < 400; s++) {
      const rand = seq([s / 400, (s * 7) % 401 / 401, (s * 13) % 397 / 397, (s * 3) % 389 / 389]);
      for (const call of whalePhrase(rand, (s % 5) / 4)) {
        expect(call.glideTo).not.toBeCloseTo(call.hz, 6);
        // ...and the interval is an interval, not a wobble: at least four semitones, at
        // most an octave. Under about three it reads as vibrato rather than as a slide.
        const semis = Math.abs(12 * Math.log2(call.glideTo / call.hz));
        expect(semis).toBeGreaterThan(3.9);
        expect(semis).toBeLessThanOrEqual(12.1);
      }
    }
  });

  it('stays inside the band a moan lives in, at every depth', () => {
    for (let s = 0; s < 300; s++) {
      const rand = seq([(s % 97) / 97, (s * 11) % 89 / 89, (s * 5) % 83 / 83, (s * 17) % 79 / 79]);
      for (const depth of [0, 0.5, 1]) {
        for (const call of whalePhrase(rand, depth)) {
          for (const hz of [call.hz, call.glideTo]) {
            expect(hz).toBeGreaterThanOrEqual(WHALE_MIN_HZ);
            expect(hz).toBeLessThanOrEqual(WHALE_MAX_HZ);
          }
        }
      }
    }
  });

  it('is a phrase with silence in it, not a stream', () => {
    const rand = seq([0.9, 0.1, 0.8, 0.3, 0.6, 0.5, 0.2, 0.7, 0.4]);
    const phrase = whalePhrase(rand, 0.3);
    expect(phrase.length).toBeGreaterThanOrEqual(1);
    expect(phrase.length).toBeLessThanOrEqual(4);
    // Delays are ordered, and each gap is long enough that the calls do not run together.
    for (let i = 1; i < phrase.length; i++) {
      const prev = phrase[i - 1]!;
      const here = phrase[i]!;
      expect(here.delay).toBeGreaterThan(prev.delay);
      expect(here.delay - prev.delay).toBeGreaterThan(0.6);
    }
    // Nothing shorter than a second and a half: the voice has to outlast the mix.
    for (const c of phrase) expect(c.duration).toBeGreaterThan(1.5);
  });

  it('is one animal, off to one side, and never in the middle', () => {
    for (let s = 0; s < 200; s++) {
      const rand = seq([(s % 71) / 71, (s * 9) % 67 / 67, (s * 3) % 61 / 61]);
      const phrase = whalePhrase(rand, 0.4);
      const sides = new Set(phrase.map((c) => Math.sign(c.pan)));
      expect(sides.size).toBe(1);
      for (const c of phrase) {
        expect(Math.abs(c.pan)).toBeGreaterThan(0.5);
        expect(Math.abs(c.pan)).toBeLessThanOrEqual(1);
        expect(c.gain).toBeGreaterThan(0);
        expect(c.gain).toBeLessThanOrEqual(1);
      }
    }
  });

  it('is lower and longer in the deep than at the surface', () => {
    const draw = [0.5, 0.2, 0.8, 0.4, 0.6, 0.3, 0.7, 0.1];
    const deep = whalePhrase(seq(draw), 1);
    const shallow = whalePhrase(seq(draw), 0);
    expect(deep[0]!.hz).toBeLessThan(shallow[0]!.hz * 0.7);
    expect(deep[0]!.duration).toBeGreaterThan(shallow[0]!.duration);
  });

  it('is deterministic given the same draw', () => {
    const draw = [0.31, 0.72, 0.11, 0.94, 0.53, 0.27];
    expect(whalePhrase(seq(draw), 0.5)).toEqual(whalePhrase(seq(draw), 0.5));
  });

  /**
   * The gap *is* the sound. A whale that answers itself every ten seconds is a car alarm;
   * the reason a recording of one is affecting is that you wait for it.
   */
  it('makes the player wait, and the whole draw stays inside the band', () => {
    expect(whaleGap(() => 0)).toBe(WHALE_GAP_MIN);
    expect(whaleGap(() => 1)).toBeCloseTo(WHALE_GAP_MAX, 6);
    expect(WHALE_GAP_MIN).toBeGreaterThan(30);
    expect(WHALE_GAP_MAX).toBeGreaterThan(WHALE_GAP_MIN);
  });

  it('is its own mixer track, mutable and nameable', () => {
    expect(AUDIO_TRACK_KEYS).toContain('whale');
    expect(defaultSettings().audio.whale).toEqual({ enabled: true, volume: 1 });
    // Muting it is the one thing a mixer track has to be able to do.
    expect(sanitizeSettings({ audio: { whale: { enabled: false } } }).audio.whale.enabled).toBe(
      false,
    );
    // ...and a settings blob written before the track existed still gets it, on.
    expect(sanitizeSettings({ muted: false }).audio.whale.enabled).toBe(true);
    expect(STRINGS.audioWhale.length).toBeGreaterThan(0);
  });
});
