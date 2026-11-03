import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { AudioEngine } from '../src/audio/AudioEngine';
import { BED_KEYS } from '../src/audio/Beds';
import {
  ROOT_HZ,
  SCALE,
  centsOff,
  degreeHz,
  degreeOf,
  scaleSemi,
  snapHz,
} from '../src/audio/Scale';
import { clearStarted, installAudioStub, started, StubOscillator } from './audiobed';

/**
 * §2's "harmonically pitched" clause, as a number.
 *
 * The engine has always had a scale and has never had a way to tell which voices
 * were obeying it. The authored cues index `SCALE` by degree and cannot be wrong;
 * every voice whose pitch comes from a physical quantity - a crystal's size, a
 * flake's depth, a whale's register, the speed of the finger - was written in Hz
 * and answered to nothing at all. Nobody could hear the difference between those
 * two populations in the source, so nobody did.
 *
 * Measured across all eight beds, five minutes each, against the harmonic model
 * `centsOffTheGame` describes below, before any of this was touched: **1445 voices
 * rang for longer than half a second, and 745 of them - a little over half - were
 * more than 25 cents off something the game is entitled to play. Mean 31 cents,
 * worst 99.** A quarter tone, held for two seconds, over a drone that never moves.
 * The same sweep afterwards: none over 25 cents, mean 0.2, worst 12 - and the 12 is
 * the whale's deliberately inharmonic partials, which are supposed to be there.
 *
 * The control matters as much as the headline. The short voices measure 44.6 cents
 * either side of this work, to one decimal place: **nothing that was texture became
 * a note.**
 *
 * The rule the assertions below encode is in `Scale.ts` and is a duration rather
 * than a taste: **a pitched voice longer than half a second is a note and must be
 * on the scale; anything shorter is texture and must not be.** The second half of
 * that matters as much as the first, and it is asserted too - snapping fifteen
 * raindrops a second onto five pitch classes would be a music box, not rain.
 */

let restore: () => void;
beforeAll(() => {
  restore = installAudioStub();
});
afterAll(() => {
  restore();
});

/**
 * How far a voice is from something the game is entitled to be playing.
 *
 * Not simply `centsOff`, because two of the engine's structures are multiplicative
 * and a scale is not, and pretending otherwise would make this file reject the
 * design instead of defending it.
 *
 *   * **The acts transpose their reward by a fifth.** `RescueVoice.octave` is 1.5,
 *     3 or 0.75 in seven of the eight acts, and that is deliberate and documented:
 *     the ring is a fifth up in the sea and lower and wider on the way home.
 *   * **A bowl's overtones are ratios of its body, not degrees of a scale.** `bowl`
 *     plays a fundamental, a fifth above it and a struck partial two octaves up.
 *     A just fifth is 702 cents and the tempered one is 700, so a partial can be
 *     two cents out and correct - and off a fifth-transposed ring, the fifth of a
 *     fifth is a ninth, which is a beautiful interval and not a scale member.
 *
 * So the divisors are 1, a fifth, and a fifth of a fifth, which is exactly the set
 * the engine can construct and no larger. Seven pitch classes out of twelve - still
 * a tight net, and every fault this file was written to catch missed it by 31 to
 * 114 cents.
 */
const PARTIALS = [1, 1.5, 2.25];

function centsOffTheGame(hz: number): number {
  let best = Infinity;
  for (const ratio of PARTIALS) {
    const d = centsOff(hz / ratio);
    if (Math.abs(d) < Math.abs(best)) best = d;
  }
  return best;
}

interface Voice {
  bed: string;
  hz: number;
  seconds: number;
  cents: number;
}

/**
 * Every pitched voice the game starts, across every bed, with how long it rings.
 *
 * Oscillators only: a bandpassed noise burst has no definite pitch and a scale has
 * nothing to say about its filter corner. Above 20 Hz only, which excludes the
 * whale's vibrato and the bed's six modulators - an LFO is a control signal, not a
 * note, and it is only in this list because the Web Audio API makes it out of the
 * same object.
 */
function sweep(seconds: number): Voice[] {
  const voices: Voice[] = [];
  for (const bed of BED_KEYS) {
    const engine = new AudioEngine();
    void engine.unlock();
    engine.setBed(bed, 0.5, -400);
    clearStarted();
    const take = (): void => {
      for (const node of started) {
        if (!(node instanceof StubOscillator)) continue;
        const hz = node.frequency.writes[0] ?? node.frequency.value;
        if (hz < 20) continue;
        voices.push({ bed, hz, seconds: node.seconds, cents: centsOffTheGame(hz) });
      }
      clearStarted();
    };
    for (let i = 0; i < 60 * seconds; i++) {
      // The breath, pushed the way the game pushes it: half the schedulers read it.
      engine.setBreath(0.5 + 0.5 * Math.sin(i / 660));
      engine.tick(1 / 60);
      take();
    }
    // ...and the cues, which no amount of ticking will deal on its own.
    engine.rescue(20, 0.3);
    engine.ring(0.3);
    engine.bite(0.2);
    engine.loss(2, 0.2);
    engine.stroke(0.2, 0.2);
    engine.stroke(0.9, -0.2);
    engine.level(3);
    // Three sines over two to three and a half seconds each: whatever else it is,
    // it is four times over the length at which this file stops calling something
    // texture, so it belongs in the sweep from the day it was written.
    engine.restart();
    engine.gate(2);
    engine.surface();
    engine.complete();
    engine.ringLost();
    engine.reform();
    take();
    engine.dispose();
  }
  return voices;
}

describe('the scale', () => {
  it('agrees with the table it replaced', () => {
    for (let i = 0; i < SCALE.length; i++) expect(scaleSemi(i)).toBe(SCALE[i]);
    // ...and keeps going in both directions, which the table cannot. Below the root
    // is what the bell's darkening needs; five degrees is always an octave.
    expect(scaleSemi(-1)).toBe(-2);
    expect(scaleSemi(-5)).toBe(-12);
    expect(scaleSemi(-6)).toBe(-14);
    expect(scaleSemi(15)).toBe(36);
    expect(degreeHz(0)).toBeCloseTo(ROOT_HZ * 4, 6);
    expect(degreeHz(5)).toBeCloseTo(ROOT_HZ * 8, 6);
    expect(degreeHz(0, 1.5)).toBeCloseTo(ROOT_HZ * 6, 6);
  });

  it('snaps to the nearest member and leaves members alone', () => {
    for (let i = -10; i <= 20; i++) {
      const exact = ROOT_HZ * Math.pow(2, scaleSemi(i) / 12);
      expect(snapHz(exact)).toBeCloseTo(exact, 6);
      expect(Math.abs(centsOff(exact))).toBeLessThan(1e-6);
    }
    // A4, which the scale does contain, and the note above it, which it does not.
    expect(snapHz(440)).toBeCloseTo(440, 6);
    expect(snapHz(466.16)).toBeCloseTo(440, 1);
    // G sharp is the interesting one and it is *not* asserted to land on A: it sits
    // exactly a hundred cents from A above and from G below, so where it goes is a
    // tie-break and not a claim. The scale's widest gap is a minor third, and its
    // midpoint has no nearest member - which is the honest reason nothing in the
    // game is allowed to arrive at a frequency this function had to guess about.
    expect([392, 440]).toContainEqual(Math.round(snapHz(415.3)));
    expect(snapHz(430)).toBeCloseTo(440, 1);
    // The wrap. 11.2 semitones into an octave is nearer the next root than it is to
    // this octave's minor seventh, and a loop over five classes cannot see that on
    // its own - this is the case that needs the extra line in `snapHz`.
    expect(snapHz(ROOT_HZ * Math.pow(2, 11.2 / 12))).toBeCloseTo(ROOT_HZ * 2, 6);
    // Nothing it returns is ever off the scale, whatever it is handed.
    for (let hz = 20; hz < 12000; hz *= 1.013) {
      expect(Math.abs(centsOff(snapHz(hz)))).toBeLessThan(1e-6);
      // ...and it never moves anything more than half the widest gap in the set,
      // which is three semitones, so 150 cents.
      expect(Math.abs(1200 * Math.log2(hz / snapHz(hz)))).toBeLessThan(151);
    }
    // Degenerate input is returned rather than turned into NaN: `AudioEngine.tick`
    // can reach this, and a NaN frequency silences a voice for the rest of a session.
    expect(snapHz(0)).toBe(0);
    expect(snapHz(-4)).toBe(-4);
    expect(centsOff(0)).toBe(0);
  });

  /**
   * `degreeOf` is `snapHz` with its answer given as a position instead of a pitch,
   * and the two must agree exactly - `Whale.ts` uses one to find where the animal
   * is and the other to check that it stayed on the scale, and a disagreement
   * between them would be invisible in both.
   */
  it('finds the degree the snap would have landed on', () => {
    for (let hz = 20; hz < 12000; hz *= 1.017) {
      expect(ROOT_HZ * Math.pow(2, scaleSemi(degreeOf(hz)) / 12)).toBeCloseTo(snapHz(hz), 6);
    }
    for (let i = -12; i <= 24; i++) {
      expect(degreeOf(ROOT_HZ * Math.pow(2, scaleSemi(i) / 12))).toBe(i);
    }
    // ...and the property `Whale.ts` actually depends on: stepping in degrees keeps
    // the interval, whatever the root was. Two degrees is always a fourth or a
    // fifth, which is the distance the animal's glide is written in.
    for (let hz = 60; hz < 400; hz *= 1.011) {
      const d = degreeOf(hz);
      const semis = scaleSemi(d + 2) - scaleSemi(d);
      expect(semis).toBeGreaterThanOrEqual(4);
      expect(semis).toBeLessThanOrEqual(5);
      expect(scaleSemi(d + 5) - scaleSemi(d)).toBe(12);
    }
  });
});

describe('what the game actually plays', () => {
  // Filled in `beforeAll`, not at collection time: the stub is not installed until
  // then, and an engine built without one is inert and deals nothing at all.
  let voices: Voice[] = [];
  beforeAll(() => {
    voices = sweep(300);
  });

  it('deals enough of everything to be worth measuring', () => {
    expect(voices.length).toBeGreaterThan(4000);
    expect(voices.filter((v) => v.seconds > 0.5).length).toBeGreaterThan(300);
    expect(voices.filter((v) => v.seconds > 0 && v.seconds <= 0.25).length).toBeGreaterThan(2000);
  });

  /**
   * The headline. Every voice that rings long enough to be heard as a note is on
   * the scale, and the tolerance is the only interesting number in this file.
   *
   * 25 cents is an eighth of a tone, and the gap either side of it is empty. Above
   * it: nothing at all now, and 745 voices before, averaging 31 cents and reaching
   * 99. Below it: the two deliberate inharmonicities the engine contains, the
   * whale's 2.01x and 3.02x partials, which are 9 and 12 cents wide and are the
   * difference between a body resonating and an oscillator bank.
   */
  it('puts every note-length voice on the scale', () => {
    const notes = voices.filter((v) => v.seconds > 0.5);
    const bad = notes.filter((v) => Math.abs(v.cents) > 25);
    expect(
      bad.slice(0, 8).map((v) => `${v.bed} ${v.hz.toFixed(1)} Hz ${v.cents.toFixed(0)}c`),
    ).toEqual([]);
    const mean = notes.reduce((a, v) => a + Math.abs(v.cents), 0) / notes.length;
    // Measured at 0.2 cents against 31.3 before, over the same 1445 voices. The
    // ceiling is where it is because a mean is the statistic that would hide one
    // act quietly going out of tune, and the `bad` list above is what catches that.
    expect(mean).toBeLessThan(6);
  });

  /**
   * ...and the other half of the rule, which is not a formality.
   *
   * The water's pitches come from Minnaert and the rain's and the brook's come from
   * the same physics; those are consequences of a radius, they are gone in forty
   * milliseconds, and the ear reads them as brightness rather than as pitch. Snapping
   * them would make act I a music box - so this asserts that nobody has, by checking
   * that the short voices are still spread across the whole continuum. They measure
   * 44.6 cents both before and after the work above, which is the number a spread
   * over this model's gaps produces; anything under 30 would mean somebody had
   * quantised the texture as well.
   */
  it('leaves the texture free, and the water still sounds like water', () => {
    const texture = voices.filter((v) => v.seconds > 0 && v.seconds <= 0.25);
    const mean = texture.reduce((a, v) => a + Math.abs(v.cents), 0) / texture.length;
    expect(mean).toBeGreaterThan(30);
    // Act I's water is the one that must not become an instrument: two bubbles a
    // second, every one of them a different pitch.
    // Act I's water is the one that must not become an instrument. Snapped, two
    // bubbles a second would be drawing from about fifteen pitches; free, they are
    // drawing from a continuum, and a few hundred distinct ones over five minutes is
    // the difference between those two worlds however the sampling falls.
    const water = texture.filter((v) => v.bed === 'deep');
    expect(new Set(water.map((v) => Math.round(v.hz))).size).toBeGreaterThan(150);
  });

  /** Every bed, so an act cannot quietly go out of tune on its own. */
  it('holds in all eight beds', () => {
    for (const bed of BED_KEYS) {
      const notes = voices.filter((v) => v.bed === bed && v.seconds > 0.5);
      expect(notes.length, `${bed} rang no notes at all`).toBeGreaterThan(10);
      const worst = notes.reduce((a, v) => Math.max(a, Math.abs(v.cents)), 0);
      expect(worst, `${bed} is ${worst.toFixed(0)} cents out`).toBeLessThan(26);
    }
  });

  /**
   * The bell's darkening, which was the single largest source of the fault: a
   * continuous multiplier from 1.0 to 0.75 whose only musical values were its two
   * ends. It is spent in whole scale steps now, so the descent still lowers the
   * bell and every step of it is a note.
   */
  it('walks the bell down the scale as the water deepens, not between the notes', () => {
    const pitches = new Set<number>();
    for (const arc of [0, 0.25, 0.5, 0.75, 1]) {
      const engine = new AudioEngine();
      void engine.unlock();
      // Act I: `arc` 0 is the trench floor, so this runs from deepest to shallowest.
      engine.setBed('deep', arc);
      clearStarted();
      engine.level(3);
      const hz = started
        .filter((n): n is StubOscillator => n instanceof StubOscillator)
        .map((n) => n.frequency.writes[0] ?? n.frequency.value)
        .filter((f) => f > 20);
      expect(hz.length).toBeGreaterThan(0);
      // The fundamental exactly, and the partials within the two cents a *just*
      // fifth sits above an equal-tempered one - a bowl's overtones are ratios of
      // its body, not degrees of a scale, and rounding them would be the one change
      // here that made something sound worse.
      expect(Math.abs(centsOff(hz[0]!))).toBeLessThan(1e-6);
      for (const f of hz) {
        expect(Math.abs(centsOffTheGame(f)), `${f} Hz at arc ${arc}`).toBeLessThan(3);
      }
      pitches.add(Math.round(hz[0]!));
      clearStarted();
      engine.dispose();
    }
    // Three distinct registers across the act - the two steps the old ratio was
    // reaching for - and the deepest is a fourth or so below the shallowest.
    expect(pitches.size).toBe(3);
    const sorted = [...pitches].sort((a, b) => a - b);
    expect(sorted[sorted.length - 1]! / sorted[0]!).toBeGreaterThan(1.25);
    expect(sorted[sorted.length - 1]! / sorted[0]!).toBeLessThan(1.45);
  });

  /**
   * The hunter, which used to resolve onto a G sharp - the leading tone, the one
   * interval `Scale.ts` exists to keep out, on the cue the player least wants to
   * hear resolve. It falls an octave now.
   */
  it('lands the bite on the root instead of the note below it', () => {
    const engine = new AudioEngine();
    void engine.unlock();
    clearStarted();
    engine.bite(0.4);
    const tones = started.filter((n): n is StubOscillator => n instanceof StubOscillator);
    expect(tones.length).toBe(1);
    const writes = tones[0]!.frequency.writes;
    expect(writes[0]).toBeCloseTo(ROOT_HZ * 2, 6);
    expect(writes[writes.length - 1]).toBeCloseTo(ROOT_HZ, 6);
    clearStarted();
    engine.dispose();
  });

  /**
   * The stroke in orbit: the one stroke in the game with a definite pitch, and the
   * only place a *player action* chooses a note. It used to slide through every
   * microtone in a ninth; it climbs the scale now, and a faster hand is still a
   * higher note.
   */
  it('lets the finger play the scale in vacuum, and only there', () => {
    const engine = new AudioEngine();
    void engine.unlock();
    engine.setBed('orbit', 0.5);
    const ladder: number[] = [];
    for (const u of [0, 0.2, 0.4, 0.6, 0.8, 1]) {
      clearStarted();
      // The stroke rate-limits itself, so each sample needs its own engine clock.
      (engine as unknown as { lastStroke: number }).lastStroke = -10;
      engine.stroke(u, 0);
      const tone = started.find((n): n is StubOscillator => n instanceof StubOscillator);
      expect(tone, `no tone at u=${u}`).toBeDefined();
      const hz = tone!.frequency.writes[0]!;
      expect(Math.abs(centsOff(hz)), `${hz} Hz at u=${u}`).toBeLessThan(1e-6);
      ladder.push(hz);
    }
    // Monotone, and it really is a ladder: fewer distinct pitches than samples.
    for (let i = 1; i < ladder.length; i++) expect(ladder[i]!).toBeGreaterThanOrEqual(ladder[i - 1]!);
    expect(new Set(ladder).size).toBeLessThan(ladder.length);
    expect(ladder[ladder.length - 1]! / ladder[0]!).toBeGreaterThan(1.4);
    clearStarted();
    engine.dispose();
  });
});
