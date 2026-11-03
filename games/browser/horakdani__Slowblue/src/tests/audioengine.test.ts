import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { AudioEngine } from '../src/audio/AudioEngine';
import { BED_KEYS, bedSpec, type BedKey } from '../src/audio/Beds';
import {
  AUDIO_TRACK_KEYS,
  BED_TRACK_KEYS,
  type AudioSettings,
  type BedTrackKey,
} from '../src/config/settings';
import {
  clearStarted,
  installAudioStub,
  reaches,
  started,
  StubAudioContext,
  type StubNode,
} from './audiobed';

/**
 * What the bed actually deals, per act, measured.
 *
 * The bug this whole file exists for was not audible as a wrong note; it was five
 * acts quietly falling through an `else` into act I's water, so the upper
 * stratosphere had bubbles in it and vacuum had a whale. Nothing caught it because
 * nothing could: the engine is inert without an `AudioContext` and no browser
 * gives one to a headless probe.
 *
 * `tests/audiobed.ts` supplies one that models routing rather than sound, so the
 * question "which track does this act's voice arrive on, and how often" becomes a
 * number. Every assertion below is a claim from `Beds.ts` restated as that number.
 */

let restore: () => void;

beforeAll(() => {
  restore = installAudioStub();
});

afterAll(() => {
  restore();
});

interface Route {
  dry: StubNode;
  wet: StubNode;
}

/** The engine's own mixer routes, so a started source can be traced to a track. */
function routes(engine: AudioEngine): Record<BedTrackKey, Route> {
  return (engine as unknown as { tracks: Record<BedTrackKey, Route> }).tracks;
}

/**
 * Runs one bed for `seconds` and counts the sources that arrived on each track.
 *
 * The breath is pushed the way the game pushes it, off an eleven-second cycle,
 * because half the schedulers read it - the rain gets busier on the out-breath,
 * the flock beats on the in-breath - and a bed measured at a fixed breath is a
 * bed measured in a state the game is never in.
 */
function deal(
  key: BedKey,
  seconds: number,
  options: { arc?: number; meters?: number } = {},
): Record<BedTrackKey, number> {
  const engine = new AudioEngine();
  void engine.unlock();
  // Every slot on, whatever the game's defaults are. What this file measures is
  // what a bed *schedules* - the question `Beds.ts` answers - and the mixer is a
  // separate question with its own tests. Two of these slots start off now (see
  // `QUIET_BY_DEFAULT`), and taking that from the defaults would have quietly
  // turned every assertion about the shimmer track into `0 > 0 * 3`.
  engine.setLevels(
    Object.fromEntries(
      AUDIO_TRACK_KEYS.map((k) => [k, { enabled: true, volume: 1 }]),
    ) as AudioSettings,
  );
  engine.setBed(key, options.arc ?? 0.5, options.meters ?? 0);
  const track = routes(engine);
  const counts = Object.fromEntries(BED_TRACK_KEYS.map((k) => [k, 0])) as Record<
    BedTrackKey,
    number
  >;
  const dt = 1 / 60;
  clearStarted();
  for (let i = 0; i < Math.round(seconds / dt); i++) {
    const phase = (i * dt) / 11;
    engine.setBreath(0.5 + 0.5 * Math.sin(2 * Math.PI * phase));
    engine.tick(dt);
    for (const source of started) {
      for (const name of BED_TRACK_KEYS) {
        const route = track[name];
        if (reaches(source, route.dry) || reaches(source, route.wet)) counts[name]++;
      }
    }
    clearStarted();
  }
  engine.dispose();
  return counts;
}

describe('the bed, dealt', () => {
  it('builds and disposes without a browser', () => {
    const engine = new AudioEngine();
    void engine.unlock();
    expect(engine.running).toBe(true);
    expect(engine.currentBed).toBe('deep');
    engine.dispose();
    expect(engine.running).toBe(false);
  });

  /**
   * The headline claim: every act's bed is busy, and no two of them are busy in
   * the same shape. This is "every act's audio must differ" as an
   * assertion - if two acts ever came to deal the same voices at the same rates,
   * this is where it would be caught.
   */
  it('gives every bed its own signature, and none of them silence', () => {
    const signatures = new Map<string, BedKey>();
    for (const key of BED_KEYS) {
      const counts = deal(key, 120);
      const total = Object.values(counts).reduce((a, b) => a + b, 0);
      expect(total, `${key} dealt nothing`).toBeGreaterThan(20);
      // Rounded into bands, so the comparison is about the shape of the bed and
      // not about which side of a Poisson draw a run happened to fall on.
      const shape = BED_TRACK_KEYS.map((t) => Math.round(Math.log2(1 + counts[t]))).join('/');
      expect(signatures.has(shape), `${key} deals the same as ${signatures.get(shape)}`).toBe(
        false,
      );
      signatures.set(shape, key);
    }
  });

  /**
   * A bed may only put voices on the slots it declares. This is the guard against
   * the exact failure that started all this: a scheduler that keeps running in an
   * act whose table never listed it.
   */
  it('never deals a voice onto a slot its own table does not list', () => {
    for (const key of BED_KEYS) {
      const declared = new Set(bedSpec(key).layers.map((l) => l.track));
      const counts = deal(key, 180);
      for (const track of BED_TRACK_KEYS) {
        if (declared.has(track)) continue;
        expect(counts[track], `${key} deals onto an undeclared ${track}`).toBe(0);
      }
    }
  });

  it('leaves act I exactly as it was: bubbles, a bell, and a whale', () => {
    const counts = deal('deep', 300);
    // ~2/s of bubbles, plus the gurgles and the exhale drops. The band is wide
    // because it is Poisson; what it excludes is a dripping tap and a pump.
    expect(counts.ocean / 300).toBeGreaterThan(1.4);
    expect(counts.ocean / 300).toBeLessThan(5);
    expect(counts.ambience).toBeGreaterThan(4);
    expect(counts.whale).toBeGreaterThan(0);
    // The two slots act I does not have.
    expect(counts.motion).toBe(0);
  });

  it('puts wings and a wind in act II, and no whale anywhere in it', () => {
    const counts = deal('flight', 300, { arc: 0.78 });
    expect(counts.ocean / 300).toBeGreaterThan(1);
    expect(counts.motion).toBeGreaterThan(0);
    // Thunder, not whale song - the same track, and the schedule is gated on the
    // altitude, so the squall has weather and the fair-weather field below it has
    // none.
    //
    // Slowblue: this dealt at arc 0.42 and asserted thunder, and at 0.95 and asserted
    // silence, which is precisely backwards - 0.42 is the cumulus field and 0.95 is
    // the top of the storm. The test was written from the gate rather than from the
    // act, so it enshrined the gate's mistake instead of catching it. Both ends are
    // asserted from the station list now: thunder over the Squall and the Anvil,
    // nothing over the Spray and the Cliff.
    expect(counts.whale).toBeGreaterThan(0);
    expect(deal('flight', 300, { arc: 1 }).whale).toBeGreaterThan(0);
    expect(deal('flight', 300, { arc: 0.2 }).whale).toBe(0);
  });

  it('keeps act III nearly empty, and act VI nearly full', () => {
    const thin = deal('thin', 300);
    const rain = deal('rain', 300);
    // Four crystals a minute against fifteen drops a second: the two extremes of
    // the campaign, and the ratio is the whole difference between them.
    expect(thin.ocean / 300).toBeLessThan(1);
    expect(rain.ocean / 300).toBeGreaterThan(8);
    expect(rain.ocean).toBeGreaterThan(thin.ocean * 20);
    // ...and the brook is denser still.
    expect(deal('brook', 60, { meters: -400 }).ocean / 60).toBeGreaterThan(12);
  });

  /**
   * §13: in space there is breath, heartbeat and a fine internal resonance. The
   * heartbeat is the one voice in the engine that is not Poisson, so it can be
   * counted exactly - and everything else about the act is an absence, which is
   * only checkable by counting what is *not* there.
   */
  it('gives act IV a heart that keeps time, and nothing that could not be up there', () => {
    const counts = deal('orbit', 120, { arc: 0 });
    // 58 bpm for two minutes, two thumps a beat, give or take the boundary.
    expect(counts.motion).toBeGreaterThan(200);
    expect(counts.motion).toBeLessThan(250);
    // ...and it slows across the act.
    expect(deal('orbit', 120, { arc: 1 }).motion).toBeLessThan(counts.motion);
    // No bubbles, no wings, no rain: the body layer in orbit is a held voice, so
    // nothing is *scheduled* onto it at all.
    expect(counts.ocean).toBe(0);
  });

  it('lights act V only where the air arrives, and puts it out again', () => {
    const orbitStill = deal('fire', 120, { arc: 0.1 });
    const plasma = deal('fire', 120, { arc: 0.58 });
    const cooled = deal('fire', 120, { arc: 0.95 });
    // Sparks: dense in the fire, a slow tick before and after it.
    expect(plasma.shimmer).toBeGreaterThan(orbitStill.shimmer * 3);
    expect(plasma.shimmer).toBeGreaterThan(cooled.shimmer * 3);
    // The shock tightens as the air arrives.
    expect(plasma.motion).toBeGreaterThan(cooled.motion);
  });

  it('turns act I water round for act VII, and adds the snow', () => {
    // Act VII descends. `arc` 1 is the trench floor, so the water has to be at its
    // darkest there - which is the bug this replaced, inverted.
    const salt = deal('homecoming', 240, { arc: 0 });
    const floor = deal('homecoming', 240, { arc: 1 });
    expect(salt.motion).toBeGreaterThan(0);
    // The snow is a hump: thin at the salt line, thick in the middle water, and
    // nearly gone on the floor, which is what lets the last station be quiet.
    const middle = deal('homecoming', 240, { arc: 0.55 });
    expect(middle.motion).toBeGreaterThan(salt.motion);
    expect(middle.motion).toBeGreaterThan(floor.motion);
  });

  /**
   * The rescue, measured. `Rescues.ts` asserts the table differs; this asserts
   * that the *engine* renders the difference - that act VI really does deal nine
   * grains where act I deals none, and that all of it lands on `objectives` so a
   * player who has turned the bed down still gets their reward.
   */
  it('rewards each act with its own number of voices, all of them cues', () => {
    const counts = new Map<BedKey, number>();
    for (const key of BED_KEYS) {
      const engine = new AudioEngine();
      void engine.unlock();
      engine.setBed(key, 0.5, -400);
      const track = routes(engine);
      clearStarted();
      engine.rescue(20, 0.4);
      engine.ring(0.4);
      let onCue = 0;
      for (const source of started) {
        const cue = (engine as unknown as { tracks: Record<string, Route> }).tracks.objectives;
        if (reaches(source, cue.dry) || reaches(source, cue.wet)) onCue++;
        // Nothing about a reward may arrive on a bed track: somebody who has
        // muted the rain must still hear that they gathered something.
        for (const bed of BED_TRACK_KEYS) {
          expect(reaches(source, track[bed].dry), `${key} rewards onto ${bed}`).toBe(false);
        }
      }
      expect(onCue, key).toBe(started.length);
      expect(onCue, key).toBeGreaterThan(5);
      counts.set(key, onCue);
      engine.dispose();
    }
    // Act I is the sparse end and the rain is the dense end, by construction.
    expect(counts.get('rain')!).toBeGreaterThan(counts.get('deep')! * 2);
    expect(counts.get('brook')!).toBeGreaterThan(counts.get('orbit')! * 2);
    // ...and act IV's is the smallest: no band, no grains, nothing struck.
    expect(Math.min(...counts.values())).toBe(counts.get('orbit'));
  });

  it('gives the held ring its own pitch in every act', () => {
    const pitches = new Set<number>();
    for (const key of BED_KEYS) {
      const engine = new AudioEngine();
      void engine.unlock();
      engine.setBed(key, 0.5);
      const osc = (engine as unknown as { ringOsc: { frequency: { value: number } } }).ringOsc;
      engine.setRingHold(0.5, 1, 0);
      expect(osc.frequency.value).toBeGreaterThan(100);
      expect(osc.frequency.value).toBeLessThan(8000);
      pitches.add(Math.round(osc.frequency.value));
      engine.dispose();
    }
    // The sound the player makes most often is the one that must not be the same
    // in all eight acts.
    expect(pitches.size).toBe(BED_KEYS.length);
  });

  it('survives every mixer track being off', () => {
    const engine = new AudioEngine();
    void engine.unlock();
    const silent = Object.fromEntries(
      [...BED_TRACK_KEYS, 'movement', 'objectives', 'danger', 'interface'].map((k) => [
        k,
        { enabled: false, volume: 0 },
      ]),
    );
    engine.setLevels(silent as never);
    for (const key of BED_KEYS) {
      engine.setBed(key, 0.5, -400);
      clearStarted();
      for (let i = 0; i < 600; i++) {
        engine.setBreath(0.5);
        engine.tick(1 / 60);
      }
      expect(started.length, `${key} dealt into a muted mixer`).toBe(0);
    }
    engine.dispose();
  });

  it('changes bed without a seam, and only when the bed actually changes', () => {
    const engine = new AudioEngine();
    void engine.unlock();
    const pad = (engine as unknown as { padVoices: { frequency: { value: number } }[] }).padVoices;
    expect(pad.length).toBe(4);
    // Act I's chord: root, fifth, octave, twelfth off 55 Hz.
    expect(pad.map((o) => o.frequency.value)).toEqual([55, 82.5, 110, 165]);
    engine.setBed('thin', 0.5);
    // Act III has no root in it - the fifth is the lowest voice.
    expect(pad[0]!.frequency.value).toBeCloseTo(82.5, 5);
    expect(engine.currentBed).toBe('thin');
    // ...and pushing the same bed sixty times a second changes nothing.
    const before = pad.map((o) => o.frequency.value);
    for (let i = 0; i < 60; i++) engine.setBed('thin', 0.5 + i * 0.001);
    expect(pad.map((o) => o.frequency.value)).toEqual(before);
    engine.dispose();
  });

  it('resolves act VII onto the root, which nothing else in the game does', () => {
    const engine = new AudioEngine();
    void engine.unlock();
    const pad = (engine as unknown as { padVoices: { frequency: { value: number } }[] }).padVoices;
    engine.setBed('homecoming', 0);
    for (let i = 0; i < 60; i++) engine.tick(1 / 60);
    expect(pad[0]!.frequency.value).toBeCloseTo(55, 3);
    engine.setBed('homecoming', 1);
    for (let i = 0; i < 60; i++) engine.tick(1 / 60);
    // An octave down, at the bottom of hearing, where `circle()` lands.
    expect(pad[0]!.frequency.value).toBeCloseTo(27.5, 3);
    engine.dispose();
  });
});

/** The engine's own context, for the tests that are about the context itself. */
function context(engine: AudioEngine): StubAudioContext {
  return (engine as unknown as { ctx: StubAudioContext }).ctx;
}

/** One turn of the microtask queue, which is where the whole recovery lives. */
function flush(): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

/**
 * The silence nobody sees, and the difference between the two kinds of it.
 *
 * A phone call, a Siri invocation or an alarm puts WebKit's `AudioContext` into
 * `interrupted` without hiding the page: no `visibilitychange`, no error, no
 * console line. The loop keeps running, the picture keeps moving, and the game
 * is silent until the player next touches the glass - on a title screen left on
 * a table, that is until they pick the phone up again.
 *
 * Every assertion below is about *who asked* for the silence, because from the
 * state alone the two are identical. An interruption has no author and is a bug
 * to recover from; a pause has one and must be left exactly where it is.
 */
describe('an interruption, and a pause, which look the same', () => {
  it('comes back from an interruption, in one suspend and one resume', async () => {
    const engine = new AudioEngine();
    await engine.unlock();
    const ctx = context(engine);
    ctx.suspends = 0;
    ctx.resumes = 0;

    ctx.interrupt();
    await flush();

    expect(engine.contextState).toBe('running');
    expect(engine.running).toBe(true);
    // WebKit's way out of `interrupted` is a suspend and then a resume, and the
    // suspend fires the very event that started this. One of each is the handler
    // ignoring its own footsteps; a cascade is it not.
    expect(ctx.suspends).toBe(1);
    expect(ctx.resumes).toBe(1);
    engine.dispose();
  });

  /**
   * ...and the second interruption is not thrown away.
   *
   * The reason the reentry guard is a state test rather than a flag. A
   * `recovering` flag would drop this event - it arrives inside the recovery it
   * would be guarding - and if the resume it interrupted then failed, the game
   * would be silent with nothing left to notice. Nothing here produces
   * `interrupted`; only the system does, so every one of them is real.
   */
  it('gives a second interruption its own recovery, not a shrug', async () => {
    const engine = new AudioEngine();
    await engine.unlock();
    const ctx = context(engine);
    ctx.suspends = 0;
    ctx.resumes = 0;

    // The system taking the context away again on the instant the recovery
    // parks it - a second caller, inside the same handful of milliseconds.
    let again = true;
    ctx.addEventListener('statechange', () => {
      if (!again || (ctx.state as string) !== 'suspended') return;
      again = false;
      ctx.interrupt();
    });

    ctx.interrupt();
    await flush();

    expect(engine.contextState).toBe('running');
    expect(ctx.suspends).toBe(2);
    engine.dispose();
  });

  it('leaves the silence the game itself asked for exactly where it is', async () => {
    const engine = new AudioEngine();
    await engine.unlock();
    const ctx = context(engine);

    engine.suspend();
    await flush();
    expect(engine.contextState).toBe('suspended');

    // ...and an interruption arriving on top of a pause is still a pause. The
    // resume this is waiting for is a player's.
    ctx.interrupt();
    await flush();
    expect(engine.contextState).toBe('interrupted');

    engine.resume();
    await flush();
    expect(engine.contextState).toBe('running');
    engine.dispose();
  });

  it('does not chase a context that has never been allowed to run', async () => {
    const g = globalThis as { AudioContext?: unknown };
    const previous = g.AudioContext;
    // A browser before the first gesture: it answers `resume()` and changes
    // nothing. Every mobile one does this, and it is why `started` exists.
    class Untouched extends StubAudioContext {
      constructor() {
        super();
        this.state = 'suspended';
        this.blocked = true;
      }
    }
    g.AudioContext = Untouched as unknown as typeof AudioContext;
    try {
      const engine = new AudioEngine();
      await engine.unlock();
      const ctx = context(engine);
      expect(engine.unlocked).toBe(false);
      expect(ctx.resumes).toBe(1);

      ctx.interrupt();
      await flush();
      // Still one. A sound that never started is not a sound that was lost, and
      // a resume without a gesture would fail anyway - forever, once a frame.
      expect(ctx.resumes).toBe(1);
      engine.dispose();
    } finally {
      g.AudioContext = previous;
    }
  });

  /**
   * The session type, which is not about interruptions at all - it is whether a
   * phone on silent hears the game. See `setAudioSession` for why that is yes.
   */
  it('declares a playback session, and only while something is audible', () => {
    const nav = { audioSession: { type: 'auto' } };
    const previous = Object.getOwnPropertyDescriptor(globalThis, 'navigator')!;
    Object.defineProperty(globalThis, 'navigator', { configurable: true, value: nav });
    try {
      const engine = new AudioEngine();
      void engine.unlock();
      // Not `ambient`, which is what this was: ambient obeys the silent switch,
      // and a web build that obeyed it was reported as having no sound at all.
      expect(nav.audioSession.type).toBe('playback');
      // A muted game holds no session at all.
      engine.setMuted(true);
      expect(nav.audioSession.type).toBe('auto');
      engine.setMuted(false);
      expect(nav.audioSession.type).toBe('playback');
      engine.dispose();
    } finally {
      Object.defineProperty(globalThis, 'navigator', previous);
    }
  });
});
