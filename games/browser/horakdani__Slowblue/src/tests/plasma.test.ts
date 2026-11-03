import { describe, expect, it } from 'vitest';
import {
  sheathCorner,
  sheathLevel,
  shockGap,
  shockRoll,
  spark,
  sparkRate,
} from '../src/audio/Plasma';

/**
 * Act V is the one place the engine's standing rule against a continuous
 * broadband layer is spent, so what has to be true of it is not "does it sound
 * like fire" but "does it stop". Two properties carry the whole act: the sheath is
 * silent before the air arrives, and it is gone before the act ends.
 */
describe('the plasma sheath', () => {
  it('is silent while the act is still in orbit', () => {
    // The deorbit burn and the night side. If the roar started here, the last
    // quiet station in the campaign's second half would not be quiet.
    expect(sheathLevel(0)).toBe(0);
    expect(sheathLevel(0.27)).toBe(0);
  });

  it('peaks at the plasma station and is gone by the nucleus', () => {
    expect(sheathLevel(0.58)).toBeCloseTo(1, 2);
    expect(sheathLevel(1)).toBeCloseTo(0, 5);
    // Cooling takes longer than catching, which is what happening to you and then
    // being over actually feels like.
    const up = 0.58 - 0.28;
    const down = 1 - 0.58;
    expect(down).toBeGreaterThan(up);
  });

  it('rises and falls without a step anywhere in it', () => {
    let prev = sheathLevel(0);
    for (let i = 1; i <= 400; i++) {
      const v = sheathLevel(i / 400);
      expect(v).toBeGreaterThanOrEqual(0);
      expect(v).toBeLessThanOrEqual(1.0001);
      // No jump larger than a per-frame ramp could hide.
      expect(Math.abs(v - prev)).toBeLessThan(0.02);
      prev = v;
    }
  });

  /**
   * The roar breathes. That is the single thing keeping it from being the rumble
   * the water's noise layer was, so the corner must actually move with the breath
   * and must stay inside the band where a roar is bottom rather than hiss.
   */
  it('opens on the in-breath and stays out of the hiss band', () => {
    for (let i = 0; i <= 20; i++) {
      const arc = i / 20;
      expect(sheathCorner(arc, 1)).toBeGreaterThan(sheathCorner(arc, 0));
      for (const b of [0, 0.5, 1]) {
        const hz = sheathCorner(arc, b);
        expect(hz).toBeGreaterThanOrEqual(180);
        expect(hz).toBeLessThanOrEqual(900);
      }
    }
  });
});

describe('sparks', () => {
  it('are grains, never clicks and never tones', () => {
    for (let i = 0; i < 200; i++) {
      const s = spark(Math.random, Math.random());
      expect(s.duration).toBeGreaterThan(0.02);
      expect(s.duration).toBeLessThan(0.16);
      expect(s.hz).toBeGreaterThan(2000);
      expect(s.hz).toBeLessThan(8000);
      expect(s.gain).toBeGreaterThan(0);
      expect(Math.abs(s.pan)).toBeLessThanOrEqual(0.85);
    }
  });

  it('are dense in the fire and a slow tick after it', () => {
    expect(sparkRate(0.58)).toBeGreaterThan(sparkRate(1) * 5);
    // ...and never zero: a layer that stops outright is a layer the player hears
    // stopping, which is an event nobody authored.
    for (let i = 0; i <= 20; i++) expect(sparkRate(i / 20)).toBeGreaterThan(0.5);
  });
});

describe('the shock', () => {
  it('is a roll: three swells, staggered, from different places', () => {
    for (let i = 0; i < 40; i++) {
      const roll = shockRoll(Math.random, Math.random());
      expect(roll.length).toBe(3);
      for (let j = 1; j < roll.length; j++) {
        expect(roll[j]!.delay).toBeGreaterThan(roll[j - 1]!.delay);
        expect(roll[j]!.gain).toBeLessThan(roll[j - 1]!.gain);
        expect(roll[j]!.duration).toBeGreaterThan(roll[j - 1]!.duration);
      }
      // Every swell loses its top end as it goes. A roll that brightened would be
      // something arriving rather than something passing.
      for (const s of roll) expect(s.sweepTo).toBeLessThan(s.hz);
    }
  });

  it('becomes wind as the act cools', () => {
    const hot = shockRoll(() => 0.5, 0.58)[0]!;
    const cold = shockRoll(() => 0.5, 1)[0]!;
    expect(cold.hz).toBeGreaterThan(hot.hz);
  });

  it('comes tightest while the air is arriving', () => {
    const hot = shockGap(() => 0.5, 0.58);
    const cold = shockGap(() => 0.5, 0);
    expect(hot).toBeLessThan(cold);
    for (let i = 0; i <= 20; i++) {
      const gap = shockGap(Math.random, i / 20);
      expect(gap).toBeGreaterThan(6);
      expect(gap).toBeLessThan(50);
    }
  });
});
