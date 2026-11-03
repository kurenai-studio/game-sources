import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { AudioEngine } from '../src/audio/AudioEngine';
import { defaultAudioSettings } from '../src/config/settings';
import { HAPTIC_CUES } from '../src/platform/Haptics';
import { clearStarted, installAudioStub, reaches, started, type StubNode } from './audiobed';

/**
 * Something happened, and something answered.
 *
 * `e2e/response.spec.ts` measures this properly - it fires every event of the
 * union at its own station and reads the glass and the mixer for what came back -
 * and it takes a minute to do it. This is the cheap half that runs on every
 * commit: **no event type may exist that neither channel names.**
 *
 * That is a real drift guard rather than a formality, and the two things it found
 * the first time it was written say so. `restart` - what a failure *is* in acts
 * III to VI, thirty of the campaign's forty-two stations - was emitted by the
 * world, listened for by nothing, and reached the end of act VI as a silent cut.
 * And `streak` had been sitting in `SimEventType` since before any of this,
 * pushed by nobody and answered by nobody. A switch statement cannot notice
 * either: TypeScript is perfectly happy with a union member no `case` mentions.
 */

const world = readFileSync(new URL('../src/sim/World.ts', import.meta.url), 'utf8');
const renderer = readFileSync(new URL('../src/render/Renderer.ts', import.meta.url), 'utf8');
const main = readFileSync(new URL('../src/main.ts', import.meta.url), 'utf8');

/**
 * The union, read off its own declaration.
 *
 * Restated as a literal array here it would be a second list to keep in step, and
 * the failure this file exists to catch is exactly a list that stopped being kept
 * in step.
 */
function eventTypes(): string[] {
  const from = world.indexOf('export type SimEventType =');
  expect(from, 'SimEventType has moved or been renamed').toBeGreaterThan(-1);
  const decl = world.slice(from, world.indexOf(';', from));
  const names = [...decl.matchAll(/\|\s*'([a-zA-Z]+)'/g)].map((m) => m[1]!);
  expect(names.length).toBeGreaterThan(6);
  return names;
}

/** The file below its own declaration: where an emitter would have to be. */
const worldBody = world.slice(world.indexOf(';', world.indexOf('export type SimEventType =')));

describe('every event is answered', () => {
  it('is emitted by the world it is declared in', () => {
    for (const type of eventTypes()) {
      // Named anywhere below the declaration, rather than matched against a
      // `push` shape: a section raises its own two through a ternary
      // (`advanced ? 'gate' : 'streakBreak'`), and a check that insisted on the
      // literal form would have been a check about how the file is written.
      expect(worldBody, `nothing in World.ts ever emits '${type}'`).toContain(`'${type}'`);
    }
  });

  it('is named by the picture', () => {
    for (const type of eventTypes()) {
      expect(renderer, `Renderer.ingest says nothing about '${type}'`).toContain(`case '${type}':`);
    }
  });

  it('is named by the sound', () => {
    for (const type of eventTypes()) {
      expect(main, `handleEvents says nothing about '${type}'`).toContain(`case '${type}':`);
    }
  });
});

/**
 * The restart cue's own routing, which is the half the source scrape above cannot
 * see: that it puts voices somewhere audible, and on the track it claims.
 */
describe('the restart cue', () => {
  let restore: () => void;
  beforeAll(() => {
    restore = installAudioStub();
  });
  afterAll(() => {
    restore();
  });

  function voicesOn(track: 'objectives' | 'danger', mute: boolean): number {
    const engine = new AudioEngine();
    void engine.unlock();
    if (mute) {
      engine.setLevels({ ...defaultAudioSettings(), [track]: { enabled: false, volume: 0 } });
    }
    const routes = (engine as unknown as { tracks: Record<string, { dry: StubNode; wet: StubNode }> })
      .tracks;
    clearStarted();
    engine.restart();
    const route = routes[track]!;
    let count = 0;
    for (const source of started) {
      if (reaches(source, route.dry) || reaches(source, route.wet)) count++;
    }
    engine.dispose();
    return count;
  }

  it('arrives on the objectives track, so a quiet danger channel cannot lose it', () => {
    // Five voices: three descending sines, the swell under them, and the noise
    // that closes the room. What matters is that they arrive at all - a station
    // beginning again with nothing on any track is the defect this cue exists for.
    expect(voicesOn('objectives', false)).toBeGreaterThanOrEqual(4);
    expect(voicesOn('danger', false)).toBe(0);
  });

  it('honours its own track being turned off', () => {
    expect(voicesOn('objectives', true)).toBe(0);
  });

  it('feels different in the hand from a station opening', () => {
    // Both mean "you are at the top of a station" and they mean opposite things
    // about how you got there, so the hand has to be able to tell them apart
    // without the eye.
    expect(HAPTIC_CUES.restart.pattern).not.toEqual(HAPTIC_CUES.level.pattern);
    expect(HAPTIC_CUES.restart.pattern.length).toBeGreaterThan(
      HAPTIC_CUES.level.pattern.length,
    );
  });
});
