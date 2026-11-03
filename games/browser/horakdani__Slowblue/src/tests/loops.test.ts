import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { AudioEngine } from '../src/audio/AudioEngine';
import { BED_KEYS } from '../src/audio/Beds';
import { defaultAudioSettings } from '../src/config/settings';
import { installAudioStub, StubParam } from './audiobed';

/**
 * §2's click-free clause, in the two places a click can actually come from: the
 * one buffer in the game that loops, and the parameters the engine pushes every
 * frame for as long as anybody is playing.
 *
 * ## The buffer
 *
 * §2 asks for loops with no click in them. Slowblue has exactly one loop to audit:
 * every water, air, fire and rain sound in the engine is built out of the same two
 * seconds of brown noise, and seven voices set `loop = true` on it. Four of those
 * are long enough to reach the end and start again - the shimmer in all eight beds
 * (every 1.18 s), act IV's held breath (1.67 s), act V's sheath (3.64 s) and act
 * III's shear, six to twenty times per gesture through a bandpass narrow enough to
 * ring. So the seam is crossed about once a second for as long as anybody plays.
 *
 * A step discontinuity is broadband and this signal is emphatically not, so the
 * whole of the step's energy lands where the buffer has none of its own: measured
 * through an 8 kHz highpass, the old seam peaked 3.2 dB above the loudest ordinary
 * millisecond in the same buffer. That is a tick rather than a bang, and it is
 * periodic, which is worse - a regular tick is one the ear locks onto and then
 * cannot unhear.
 *
 * The assertion is the honest form of the fix: **the wrap must be an ordinary
 * sample transition.** Not "small", not "under a threshold picked to pass" - no
 * larger than the movement between two neighbouring samples anywhere else in the
 * buffer, because that is exactly what a buffer with no seam in it means.
 *
 * ## The held parameters
 *
 * The other half of the clause. There are forty-odd `.value =` writes in
 * `AudioEngine`, and all but a handful are correct: setting a fresh oscillator's
 * frequency before `start()` is not a step in anything, because nothing is
 * carrying signal yet. What would be a step is a direct write to one of the
 * forty-six params the engine keeps a *reference* to - the chord's four voices in
 * pitch and detune, its gain and its corner, the shimmer's six, the held breath and
 * the sheath in gain and corner, the ring's two oscillators and its gain and pan,
 * and both sends of all ten mixer tracks - because those are pushed from `setBed`,
 * `setBreath`, `setLevels`, `setRingHold` and `tick`, sixty times a second,
 * underneath a graph that has been running since the player's first touch.
 *
 * That claim was true when it was written and nothing checked that it stayed true,
 * which is the only interesting thing about it. `StubParam` counts the two kinds of
 * write separately now, so it is a number.
 */

let restore: () => void;
beforeAll(() => {
  restore = installAudioStub();
});
afterAll(() => {
  restore();
});

interface Noise {
  length: number;
  getChannelData(ch: number): Float32Array;
}

/** The engine's shared noise buffer, which is only built once a context exists. */
function noiseOf(engine: AudioEngine): Float32Array {
  const buffer = (engine as unknown as { noise: Noise | null }).noise;
  expect(buffer, 'the engine built no noise buffer').not.toBeNull();
  return buffer!.getChannelData(0);
}

/** Root-mean-square movement between neighbouring samples: an ordinary transition. */
function meanStep(data: Float32Array): number {
  let sum = 0;
  for (let i = 1; i < data.length; i++) {
    const d = data[i]! - data[i - 1]!;
    sum += d * d;
  }
  return Math.sqrt(sum / (data.length - 1));
}

describe('the shared noise buffer', () => {
  it('wraps without a step, over and over', () => {
    // Twenty buffers, because the seam is one draw from a random walk and a single
    // one proves nothing: even the broken version joined up cleanly by luck about a
    // tenth of the time. Both a mean and a ceiling, because the two regimes are
    // separated at both ends and asserting only the mean would let a rare enormous
    // seam through.
    const ratios: number[] = [];
    for (let i = 0; i < 20; i++) {
      const engine = new AudioEngine();
      void engine.unlock();
      const data = noiseOf(engine);
      ratios.push(Math.abs(data[0]! - data[data.length - 1]!) / meanStep(data));
      engine.dispose();
    }
    const mean = ratios.reduce((a, b) => a + b, 0) / ratios.length;
    // Measured over four hundred buffers at the stub's length: mean 0.86 and a
    // worst-of-twenty that reaches 1.85 one run in a hundred. The same two numbers
    // before the fix were 4.08 and 10.5. Nothing between 2.5 and 4 exists.
    expect(mean).toBeLessThan(1.5);
    expect(Math.max(...ratios)).toBeLessThan(2.5);
  });

  it('is still brown noise, and still fills the buffer', () => {
    const engine = new AudioEngine();
    void engine.unlock();
    const data = noiseOf(engine);
    let sum = 0;
    let peak = 0;
    for (let i = 0; i < data.length; i++) {
      sum += data[i]! * data[i]!;
      peak = Math.max(peak, Math.abs(data[i]!));
    }
    const rms = Math.sqrt(sum / data.length);
    // The warm-up pass must not have changed what the signal *is*. Brown noise from
    // this integrator sits near 0.18 RMS with a crest factor of about four; a bug in
    // the in-place pass would leave white noise (RMS ~0.58) or silence behind, and
    // both would sail past a seam test on their own.
    expect(rms).toBeGreaterThan(0.05);
    expect(rms).toBeLessThan(0.45);
    expect(peak).toBeGreaterThan(rms * 2);
    // ...and it must be correlated sample to sample, which is the whole difference
    // between brown noise and the white it is made from.
    expect(meanStep(data)).toBeLessThan(rms * 0.6);
    engine.dispose();
  });
});

/** Every param the engine holds on to and pushes after the graph is running. */
function heldParams(engine: AudioEngine): Map<string, StubParam> {
  const e = engine as unknown as Record<string, unknown>;
  const found = new Map<string, StubParam>();
  const add = (name: string, param: unknown): void => {
    if (param instanceof StubParam) found.set(name, param);
  };
  for (const name of [
    'padGain',
    'padFilterParam',
    'shimmerGain',
    'shimmerFreq',
    'shimmerQ',
    'shimmerRate',
    'shimmerLfoDepth',
    'shimmerSweepDepth',
    'ringPan',
  ]) {
    add(name, e[name]);
  }
  // The three held voices, each a pair.
  for (const name of ['breathBody', 'breathAir', 'sheath']) {
    const voice = e[name] as Record<string, unknown> | null;
    if (voice === null || voice === undefined) continue;
    add(`${name}.gain`, voice.gain);
    add(`${name}.freq`, voice.freq);
  }
  // The chord and the ring shimmer, whose oscillators are retuned by act and by hold.
  const pad = e.padVoices as { frequency: unknown; detune: unknown }[];
  pad.forEach((osc, i) => {
    add(`padVoices[${i}].frequency`, osc.frequency);
    add(`padVoices[${i}].detune`, osc.detune);
  });
  for (const name of ['ringOsc', 'ringOsc2', 'ringGain']) {
    const node = e[name] as Record<string, unknown> | null;
    if (node === null || node === undefined) continue;
    add(`${name}.frequency`, node.frequency);
    add(`${name}.gain`, node.gain);
  }
  // ...and the mixer itself, which the settings drawer moves while the game plays.
  const tracks = e.tracks as Record<string, { dry: { gain: unknown }; wet: { gain: unknown } }>;
  for (const [key, route] of Object.entries(tracks)) {
    add(`${key}.dry.gain`, route.dry.gain);
    add(`${key}.wet.gain`, route.wet.gain);
  }
  return found;
}

describe('the parameters that never stop being pushed', () => {
  it('are only ever ramped once the graph is running', () => {
    const engine = new AudioEngine();
    void engine.unlock();
    const held = heldParams(engine);
    // Forty-six of them, and the guard is on the walk rather than on the number:
    // a refactor that renamed a field would otherwise silently assert nothing.
    expect(held.size).toBeGreaterThan(40);
    // Everything up to here is construction, and a fresh node's `.value =` is not a
    // step in anything. What is counted is what happens *after* the first touch.
    const before = new Map([...held].map(([name, p]) => [name, p.directWrites]));

    // A session: every act, the breath, the mixer, the ring and the master switch -
    // which is to say every path in the engine that writes a held param.
    for (const bed of BED_KEYS) {
      engine.setBed(bed, 0.3, -400);
      for (let i = 0; i < 240; i++) {
        engine.setBreath(0.5 + 0.5 * Math.sin(i / 66));
        engine.setRingHold((i % 60) / 60, 1, Math.sin(i / 30));
        engine.tick(1 / 60);
      }
      engine.setBed(bed, 0.9, -400);
      for (let i = 0; i < 120; i++) engine.tick(1 / 60);
    }
    engine.setMuted(true);
    engine.setMuted(false);
    engine.setLevels(defaultAudioSettings());

    const stepped = [...held]
      .filter(([name, p]) => p.directWrites > (before.get(name) ?? 0))
      .map(([name, p]) => `${name} stepped ${p.directWrites - (before.get(name) ?? 0)}x`);
    expect(stepped).toEqual([]);
    engine.dispose();
  });

  /**
   * ...and the guard's own guard. If `StubParam` ever stopped counting, the
   * assertion above would pass for the wrong reason and go on passing forever.
   */
  it('would notice a step if one happened', () => {
    const param = new StubParam(1);
    expect(param.directWrites).toBe(0);
    param.setTargetAtTime(0.5);
    param.exponentialRampToValueAtTime(0.2);
    expect(param.directWrites).toBe(0);
    expect(param.writes).toEqual([0.5, 0.2]);
    param.value = 0.9;
    expect(param.directWrites).toBe(1);
    expect(param.value).toBe(0.9);
  });
});
