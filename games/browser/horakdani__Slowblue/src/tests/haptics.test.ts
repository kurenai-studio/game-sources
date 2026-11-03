import { readFileSync } from 'node:fs';
import { afterEach, describe, expect, it } from 'vitest';
import {
  HAPTIC_CUES,
  haptic,
  setHapticsDriver,
  webHaptics,
  type HapticCue,
  type HapticCueName,
} from '../src/platform/Haptics';

/**
 * The haptic table, held to the three things that make it a table rather than
 * thirteen scattered literals.
 */

afterEach(() => setHapticsDriver(webHaptics));

const NAMES = Object.keys(HAPTIC_CUES) as HapticCueName[];

describe('the haptic dictionary', () => {
  it('describes every cue in both vocabularies', () => {
    for (const name of NAMES) {
      const cue = HAPTIC_CUES[name];
      // Odd length, always: a pattern is buzz/pause/buzz..., so an even one ends
      // the cue on a silence the hand cannot feel and the last number is a lie.
      expect(cue.pattern.length % 2, name).toBe(1);
      for (const ms of cue.pattern) {
        expect(Number.isFinite(ms) && ms > 0, `${name}: ${String(ms)}`).toBe(true);
        // Anything under about 10 ms is below what a phone's motor can start and
        // stop; anything over 80 stops being a tap and becomes a buzz.
        expect(ms, name).toBeGreaterThanOrEqual(10);
        expect(ms, name).toBeLessThanOrEqual(80);
      }
      expect(cue.impact, name).toBeTruthy();
    }
  });

  it('hands the same array to the driver every time, so a cue allocates nothing', () => {
    const seen: HapticCue[] = [];
    setHapticsDriver({ play: (cue) => seen.push(cue) });
    haptic('bite');
    haptic('bite');
    expect(seen).toHaveLength(2);
    expect(seen[0]).toBe(seen[1]);
    expect(seen[0].pattern).toBe(HAPTIC_CUES.bite.pattern);
  });

  it('routes every cue through whichever driver is installed', () => {
    const played: string[] = [];
    setHapticsDriver({ play: (cue) => played.push(cue.impact) });
    for (const name of NAMES) haptic(name);
    expect(played).toHaveLength(NAMES.length);
    setHapticsDriver(webHaptics);
    // The web driver on a platform with no vibration - every desktop, and every
    // iOS device there has ever been - is a no-op, not a throw.
    expect(() => haptic('rescue')).not.toThrow();
  });

  /**
   * A dictionary with an entry nobody fires is a dictionary that has started
   * drifting from the game. This is the cheapest check that keeps the table
   * honest: the game is the only caller, so the game has to name all eleven.
   */
  it('has no cue the game never fires', () => {
    const source = readFileSync(new URL('../src/main.ts', import.meta.url), 'utf8');
    for (const name of NAMES) expect(source, name).toContain(`haptic('${name}')`);
  });

  it('is the only way the game buzzes', () => {
    const source = readFileSync(new URL('../src/main.ts', import.meta.url), 'utf8');
    expect(source).not.toContain('navigator.vibrate');
  });
});
