import { describe, expect, it } from 'vitest';
import {
  HEART_BPM_END,
  HEART_BPM_START,
  breathVoice,
  heartBeat,
  heartRate,
  whistlerGap,
  whistlerShower,
} from '../src/audio/Void';

/**
 * §13 allows act IV three sounds: breath, heartbeat, and a very fine internal
 * resonance. What is worth pinning down is not how they are synthesised but that
 * each of them keeps the one property that makes it that thing rather than a
 * synthesiser doing an impression of it.
 */
describe('the heartbeat', () => {
  it('is a resting rate, and it slows across the act', () => {
    expect(heartRate(0)).toBeCloseTo(HEART_BPM_START, 5);
    expect(heartRate(1)).toBeCloseTo(HEART_BPM_END, 5);
    expect(heartRate(1)).toBeLessThan(heartRate(0));
    // Nothing anywhere in the act is an exercising heart.
    for (let i = 0; i <= 20; i++) {
      const bpm = heartRate(i / 20);
      expect(bpm).toBeGreaterThan(40);
      expect(bpm).toBeLessThan(60);
    }
  });

  /**
   * Lub-dub, not two beats. The gap is systole and it is the whole reason a
   * heartbeat is heard as one event with a shape - at 0.14 s the two thumps fuse;
   * much wider and it is a drum pattern.
   */
  it('is one event with a shape, both halves under 50 Hz', () => {
    const [lub, dub] = heartBeat();
    expect(lub).toBeDefined();
    expect(dub).toBeDefined();
    expect(dub!.delay - lub!.delay).toBeCloseTo(0.14, 5);
    expect(dub!.gain).toBeLessThan(lub!.gain);
    expect(dub!.duration).toBeLessThan(lub!.duration);
    for (const thump of heartBeat()) {
      expect(thump.hz).toBeLessThan(50);
      // Nothing in a heart is fast enough to click, and nothing is long enough
      // to be a note either: a heartbeat you can hum is a horror cue.
      expect(thump.duration).toBeGreaterThan(0.1);
      expect(thump.duration).toBeLessThan(0.3);
    }
  });

  it('beats at least twice as often as it takes to say so', () => {
    // 60/bpm has to land inside the band a breath spans, or the two entrainment
    // cues in the act fight each other.
    expect(60 / heartRate(0)).toBeGreaterThan(0.9);
    expect(60 / heartRate(1)).toBeLessThan(1.4);
  });
});

describe('the breath', () => {
  /**
   * The asymmetry is the whole voice. An in-breath through the nose is dark and
   * an out-breath through the mouth is bright, and without that difference two
   * filtered noise bands moving together are a filter sweep rather than a person.
   */
  it('is brighter going out than coming in', () => {
    const inhaled = breathVoice(1);
    const exhaled = breathVoice(0);
    expect(exhaled.airGain).toBeGreaterThan(inhaled.airGain);
    expect(exhaled.airHz).toBeGreaterThan(inhaled.airHz);
    expect(inhaled.bodyHz).toBeGreaterThan(exhaled.bodyHz);
  });

  it('never goes silent at the turn', () => {
    for (let i = 0; i <= 40; i++) {
      const v = breathVoice(i / 40);
      // A breath that disappears between halves is a gate, and a gate is the one
      // thing an eleven-second cycle cannot have in it.
      expect(v.bodyGain).toBeGreaterThan(0.3);
      expect(v.airGain).toBeGreaterThanOrEqual(0);
      expect(v.bodyHz).toBeGreaterThan(150);
      expect(v.airHz).toBeLessThan(2600);
    }
  });

  it('is loudest in the middle of each half, not at the ends', () => {
    // Air actually moves during a breath and is still at the turns; the level has
    // to follow that or it reads as a volume knob.
    expect(breathVoice(0.5).bodyGain).toBeGreaterThan(breathVoice(0).bodyGain);
    expect(breathVoice(0.5).bodyGain).toBeGreaterThan(breathVoice(1).bodyGain);
  });

  it('clamps rather than extrapolating', () => {
    for (const s of [-3, 5]) {
      const v = breathVoice(s);
      expect(Number.isFinite(v.bodyGain)).toBe(true);
      expect(v.airGain).toBeGreaterThanOrEqual(0);
    }
  });
});

describe('whistlers', () => {
  /**
   * The one sound in the act that is real, and it is real in a way that can be
   * checked: a whistler *descends*, several octaves, over seconds, because the
   * high frequencies arrive first. One that rose would be nothing at all.
   */
  it('always descends, by octaves, over seconds', () => {
    for (let i = 0; i < 40; i++) {
      for (const w of whistlerShower(Math.random)) {
        expect(w.toHz).toBeLessThan(w.fromHz);
        const octaves = Math.log2(w.fromHz / w.toHz);
        expect(octaves).toBeGreaterThan(2);
        expect(octaves).toBeLessThan(3.5);
        expect(w.duration).toBeGreaterThan(1.4);
        expect(w.duration).toBeLessThan(4);
        expect(Math.abs(w.pan)).toBeGreaterThan(0.35);
      }
    }
  });

  it('comes in showers from one storm, dying away', () => {
    for (let i = 0; i < 40; i++) {
      const shower = whistlerShower(Math.random);
      expect(shower.length).toBeGreaterThanOrEqual(2);
      expect(shower.length).toBeLessThanOrEqual(5);
      // One side for the whole shower: they came down the same field line.
      const sides = new Set(shower.map((w) => Math.sign(w.pan)));
      expect(sides.size).toBe(1);
      for (let j = 1; j < shower.length; j++) {
        expect(shower[j]!.delay).toBeGreaterThan(shower[j - 1]!.delay);
        expect(shower[j]!.duration).toBeGreaterThan(shower[j - 1]!.duration - 1.6);
      }
    }
  });

  it('leaves a gap long enough that one is worth waiting for', () => {
    for (let i = 0; i < 40; i++) {
      expect(whistlerGap(Math.random)).toBeGreaterThanOrEqual(52);
      expect(whistlerGap(Math.random)).toBeLessThanOrEqual(136);
    }
  });
});
