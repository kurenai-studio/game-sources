import { describe, expect, it } from 'vitest';
import { RESCUES, grainPan, rescueVoice } from '../src/audio/Rescues';
import { BED_KEYS, type BedKey } from '../src/audio/Beds';

/**
 * The rescue is the only reward the game has, and it had one sound for all
 * forty-two stations. What is worth pinning here is not how any one act's version
 * sounds - that is a judgement - but the four structural claims the table makes:
 * they all differ, they all stay in the scale, act I did not move, and act IV
 * still obeys §13.
 */
describe('the rescue table', () => {
  it('covers every bed', () => {
    for (const key of BED_KEYS) {
      const voice = rescueVoice(key);
      expect(voice.notes.length, key).toBeGreaterThanOrEqual(2);
      expect(voice.ring.notes.length, key).toBeGreaterThanOrEqual(3);
    }
    // An unknown bed still gets a reward rather than silence.
    expect(rescueVoice('nonsense' as BedKey)).toBe(RESCUES.deep);
  });

  /**
   * The requirement, as an assertion: no two acts may reward you with the same
   * sound. Compared on everything the ear actually gets - the intervals, the
   * register, the timing, the band and the material.
   */
  it('gives no two acts the same reward', () => {
    const seen = new Map<string, BedKey>();
    for (const key of BED_KEYS) {
      const v = rescueVoice(key);
      const print = JSON.stringify([v.octave, v.notes, v.band, v.grains, v.ring, v.hold]);
      expect(seen.has(print), `${key} rewards like ${seen.get(print)}`).toBe(false);
      seen.set(print, key);
      // The intervals differ act to act as well, not just the dressing.
      const degrees = v.notes.map((n) => n.degree).join(',');
      const others = BED_KEYS.filter((k) => k !== key).map((k) =>
        rescueVoice(k).notes.map((n) => n.degree).join(','),
      );
      expect(others.filter((d) => d === degrees).length, `${key} shares its interval`).toBe(0);
    }
    // ...and so does the held shimmer, which is the sound the player makes most.
    const holds = BED_KEYS.map((k) => JSON.stringify(rescueVoice(k).hold));
    expect(new Set(holds).size).toBe(BED_KEYS.length);
  });

  /**
   * Act I is the reference. Every number below was in `AudioEngine.rescue` and
   * `AudioEngine.ring` before this table existed, and this is where they stay.
   */
  it('leaves act I exactly where it was', () => {
    const v = RESCUES.deep;
    expect(v.octave).toBe(1);
    expect(v.attack).toBe(0.06);
    expect(v.wet).toBe(0.7);
    expect(v.notes).toEqual([
      { degree: 2, duration: 1.6, gain: 0.03, delay: 0, pan: 0.5 },
      { degree: 4, duration: 1.9, gain: 0.026, delay: 0.11, pan: 0.7 },
      { degree: 7, duration: 2.4, gain: 0.02, delay: 0.22, pan: 0.6, big: true },
    ]);
    expect(v.band).toEqual({
      hz: 1100,
      to: 2200,
      q: 2,
      gain: 0.014,
      duration: 0.9,
      pan: 0.85,
      wet: 0.8,
    });
    expect(v.grains).toBeNull();
    expect(v.ring.struck).toBe(true);
    expect(v.ring.notes.map((n) => [n.degree, n.gain, n.delay, n.pan])).toEqual([
      [2, 0.055, 0, 0.35],
      [5, 0.04, 0.16, 0.65],
      [7, 0.03, 0.33, 0.9],
    ]);
    expect(v.ring.band).toEqual({
      hz: 900,
      to: 2600,
      q: 1.4,
      gain: 0.016,
      duration: 1.4,
      pan: 0.8,
      wet: 0.9,
    });
    expect(v.hold).toEqual({ from: 3, to: 7, octave: 1 });
  });

  /**
   * §13: breath, heartbeat and a fine internal resonance, and nothing else. A
   * band of noise or a struck bowl announcing a rescue would be the loudest lie
   * in the campaign, so act IV has neither.
   */
  it('lets act IV keep its silence', () => {
    const v = RESCUES.orbit;
    expect(v.band).toBeNull();
    expect(v.ring.band).toBeNull();
    expect(v.grains).toBeNull();
    expect(v.ring.struck).toBe(false);
    // Nothing with an onset anybody can locate: the swell is most of a second.
    expect(v.attack).toBeGreaterThan(0.5);
    // ...and it is the quietest reward in the game.
    const loudest = (key: BedKey): number =>
      Math.max(...rescueVoice(key).notes.map((n) => n.gain));
    for (const key of BED_KEYS) {
      if (key === 'orbit') continue;
      expect(loudest('orbit')).toBeLessThan(loudest(key));
    }
  });

  /**
   * Two acts land instead of opening, and both are true about their subject: rain
   * does not open upward, and act VII is about letting something settle. The
   * other six climb, which is what a reward normally is.
   */
  it('opens upward everywhere except the rain and the way home', () => {
    const falls = BED_KEYS.filter((k) => {
      const band = rescueVoice(k).band;
      return band !== null && band.to < band.hz;
    });
    expect(falls.sort()).toEqual(['homecoming', 'rain']);
    // Act VII's interval falls too, and it is the only one that does.
    const descends = (key: BedKey): boolean => {
      const d = rescueVoice(key).notes.map((n) => n.degree);
      return d.every((v, i) => i === 0 || v < d[i - 1]!);
    };
    expect(BED_KEYS.filter(descends)).toEqual(['homecoming']);
  });

  it('keeps every degree inside the scale, and every gain inside the mix', () => {
    for (const key of BED_KEYS) {
      const v = rescueVoice(key);
      for (const note of [...v.notes, ...v.ring.notes]) {
        // `SCALE` has eleven entries; anything past it is silently clamped, which
        // is a table entry that does not do what it says.
        expect(note.degree, key).toBeGreaterThanOrEqual(0);
        expect(note.degree, key).toBeLessThanOrEqual(10);
        expect(note.gain, key).toBeGreaterThan(0);
        expect(note.gain, key).toBeLessThan(0.08);
        expect(note.delay, key).toBeGreaterThanOrEqual(0);
        expect(Math.abs(note.pan), key).toBeLessThanOrEqual(1);
      }
      // The notes arrive in order and none of them is a chord stacked at zero.
      const delays = v.notes.map((n) => n.delay);
      expect([...delays].sort((a, b) => a - b), key).toEqual(delays);
      if (v.grains !== null) {
        expect(v.grains.count, key).toBeGreaterThan(2);
        expect(v.grains.span, key).toBeGreaterThan(0);
        expect(v.grains.spread, key).toBeGreaterThan(0.5);
      }
    }
  });
});

describe('convergence', () => {
  /**
   * The one thing that makes a rescue sound like a rescue rather than like a
   * burst: the grains start at the edges and finish on the ring. If this ever
   * inverted, every act's reward would read as something scattering.
   */
  it('closes onto the ring from the edges', () => {
    for (const count of [4, 5, 6, 9, 10]) {
      for (const ring of [-0.6, 0, 0.7]) {
        const pans = Array.from({ length: count }, (_, i) => grainPan(i, count, 0.9, ring));
        const first = Math.abs(pans[0]! - ring);
        const last = Math.abs(pans[count - 1]! - ring);
        expect(last).toBeLessThan(first);
        expect(last).toBeLessThan(0.05);
        for (const p of pans) {
          expect(p).toBeGreaterThanOrEqual(-1);
          expect(p).toBeLessThanOrEqual(1);
        }
        // ...and they come from both sides, or it is a sweep rather than a gather.
        expect(new Set(pans.slice(0, 4).map((p) => Math.sign(p - ring))).size).toBeGreaterThan(1);
      }
    }
  });

  it('handles the degenerate single grain', () => {
    expect(grainPan(0, 1, 0.9, 0.4)).toBeCloseTo(0.4, 5);
  });
});
