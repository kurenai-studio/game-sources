import { describe, expect, it } from 'vitest';
import {
  CRYSTAL_MAX_UM,
  CRYSTAL_MIN_UM,
  crystalDuration,
  crystalFall,
  crystalFrequency,
  crystalLevel,
  crystalRate,
  crystalSize,
  infrasoundGap,
  infrasoundSwell,
  shearBand,
  shearGap,
} from '../src/audio/Crystals';
import { bubbleFrequency, bubbleRise } from '../src/audio/Bubbles';

/** A deterministic 0..1 source, so a model built out of draws can be pinned down. */
function seq(...values: number[]): () => number {
  let i = 0;
  return () => values[i++ % values.length]!;
}

describe('ice crystals', () => {
  /**
   * The one property act III's body layer has to have, because it is the only
   * thing stopping it being mistaken for act I's: **ice falls and water rises.**
   * Everything else about the two voices is the same shape - a sine, an envelope,
   * a glide - so if this ever inverted the stratosphere would sound like a shallow
   * pond and nobody would be able to say why.
   */
  it('falls where a bubble rises', () => {
    for (let s = CRYSTAL_MIN_UM; s <= CRYSTAL_MAX_UM; s += 2) {
      expect(crystalFall(s)).toBeLessThan(1);
    }
    expect(bubbleRise(4)).toBeGreaterThan(1);
  });

  it('rings a long way above the water and never crosses into it', () => {
    // The two bands must not overlap, or the acts stop being distinguishable by
    // register alone - which is the only cue a player gets with the picture off.
    let lowestCrystal = Infinity;
    for (let u = 0; u <= 1; u += 0.02) {
      for (const h of [0, 0.5, 1]) {
        lowestCrystal = Math.min(lowestCrystal, crystalFrequency(crystalSize(u, h)));
      }
    }
    expect(lowestCrystal).toBeGreaterThan(bubbleFrequency(2));
  });

  it('is long enough that four a minute still make a room', () => {
    for (let s = CRYSTAL_MIN_UM; s <= CRYSTAL_MAX_UM; s += 1) {
      const d = crystalDuration(s);
      expect(d).toBeGreaterThan(1.3);
      expect(d).toBeLessThan(3);
    }
  });

  it('makes a big crystal lower, longer and louder', () => {
    expect(crystalFrequency(CRYSTAL_MAX_UM)).toBeLessThan(crystalFrequency(CRYSTAL_MIN_UM));
    expect(crystalDuration(CRYSTAL_MAX_UM)).toBeGreaterThan(crystalDuration(CRYSTAL_MIN_UM));
    expect(crystalLevel(CRYSTAL_MAX_UM)).toBeGreaterThan(crystalLevel(CRYSTAL_MIN_UM));
    // ...and the small ones sag further, because the thin air takes their top first.
    expect(crystalFall(CRYSTAL_MIN_UM)).toBeLessThan(crystalFall(CRYSTAL_MAX_UM));
  });

  /**
   * The act's arc, as one number: there is less water the higher you go, so the
   * crystals get smaller, higher and rarer. Noctilucent cloud at 82 km should be
   * the finest thing in the mix as well as in the picture.
   */
  it('thins and brightens with height', () => {
    const mean = (h: number): number => {
      let sum = 0;
      for (let i = 0; i <= 100; i++) sum += crystalFrequency(crystalSize(i / 100, h));
      return sum / 101;
    };
    expect(mean(1)).toBeGreaterThan(mean(0) * 1.2);
    expect(crystalSize(1, 1)).toBeLessThan(crystalSize(1, 0));
    expect(crystalRate(1)).toBeLessThan(crystalRate(0));
    // ...and never stops entirely. A layer that goes to zero is a layer the player
    // hears stopping, which is an event nobody authored.
    expect(crystalRate(1)).toBeGreaterThan(0.1);
  });

  it('clamps every input rather than extrapolating', () => {
    for (const s of [-40, 0, 1e6]) {
      expect(Number.isFinite(crystalFrequency(s))).toBe(true);
      expect(crystalDuration(s)).toBeGreaterThan(0);
      expect(crystalLevel(s)).toBeGreaterThan(0);
      expect(crystalFall(s)).toBeGreaterThan(0);
    }
    expect(crystalSize(-3, -1)).toBeGreaterThanOrEqual(CRYSTAL_MIN_UM);
    expect(crystalSize(9, 4)).toBeLessThanOrEqual(CRYSTAL_MAX_UM);
  });
});

describe('layer shear', () => {
  it('always goes somewhere, and always somewhere else', () => {
    for (let i = 0; i < 60; i++) {
      const b = shearBand(Math.random, i / 60);
      // A band that lands where it started is a held whistle, which is the one
      // thing the slowest gesture in the game must not be.
      const span = Math.max(b.fromHz, b.toHz) / Math.min(b.fromHz, b.toHz);
      expect(span).toBeGreaterThan(1.8);
      // ...and it crosses the head rather than sitting on one side.
      expect(Math.sign(b.pan)).not.toBe(Math.sign(b.panTo));
      expect(Math.abs(b.pan)).toBeGreaterThan(0.5);
      expect(b.duration).toBeGreaterThanOrEqual(8);
      expect(b.duration).toBeLessThanOrEqual(20);
    }
  });

  it('narrows with height, because the layers do', () => {
    const low = shearBand(seq(0.5, 0.9, 0.5, 0.5, 0.5, 0.5, 0.5), 0);
    const high = shearBand(seq(0.5, 0.9, 0.5, 0.5, 0.5, 0.5, 0.5), 1);
    expect(high.q).toBeGreaterThan(low.q);
    expect(high.fromHz).toBeGreaterThan(low.fromHz);
  });

  it('leaves long gaps', () => {
    for (let i = 0; i < 40; i++) {
      const gap = shearGap(Math.random);
      expect(gap).toBeGreaterThanOrEqual(17);
      expect(gap).toBeLessThanOrEqual(43);
    }
  });
});

describe('infrasound', () => {
  it('stays at the bottom edge of hearing and sags', () => {
    for (let i = 0; i < 60; i++) {
      const s = infrasoundSwell(Math.random, i / 60);
      expect(s.hz).toBeGreaterThan(24);
      // 49, not 48: the band's ends are scale members now, and the nearest one to
      // the top of the range this used to draw from is the G below the root. See
      // `infrasoundSwell` - a twenty-second tone this close to the drone is the
      // last place in the game where a free frequency was worth keeping.
      expect(s.hz).toBeLessThanOrEqual(49);
      expect(s.glideTo).toBeLessThan(s.hz);
      // Ten to twenty-two seconds: it has to outlast everything else in the mix,
      // which is what makes it read as planetary rather than as a low note.
      expect(s.duration).toBeGreaterThanOrEqual(10);
      expect(s.duration).toBeLessThanOrEqual(22);
    }
  });

  it('gets lower and longer the higher the waveguide is', () => {
    const low = infrasoundSwell(seq(0.5), 0);
    const high = infrasoundSwell(seq(0.5), 1);
    expect(high.hz).toBeLessThan(low.hz);
    expect(high.duration).toBeGreaterThan(low.duration);
  });

  it('is rarer than any other scheduled voice in its act', () => {
    for (let i = 0; i < 40; i++) {
      expect(infrasoundGap(Math.random)).toBeGreaterThan(shearGap(Math.random));
    }
  });
});
