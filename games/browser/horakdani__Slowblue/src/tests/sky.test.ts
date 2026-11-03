import { describe, expect, it } from 'vitest';
import { drawBackdrop } from '../src/render/Backdrop';
import { AIR_MOTIFS, MOTIFS, THIN_MOTIFS, motifForIn, motifsForAct } from '../src/render/Motif';
import { paintFor } from '../src/render/Paint';
import { AIR_LEVELS } from '../src/config/ascent';
import { THIN_LEVELS } from '../src/config/thinning';
import { FakeContext, expectFinite } from './canvas';

/**
 * The air's six backdrops, held to the same contract as everything else the
 * renderer draws: nothing non-finite, nothing that leaves a composite mode set
 * behind it, and something actually drawn at every point of a station. The last
 * one matters more than it looks - `progress` drives the sea sinking out of the
 * spray and the anvil spreading below the flock, so a backdrop that is blank at
 * one end of a station is a station with a hole in it.
 */

function view(rec: FakeContext, zone: number, progress: number, quality = 1): Parameters<typeof drawBackdrop>[2] {
  return {
    ctx: rec.as2d,
    paint: paintFor(zone),
    w: 390,
    h: 844,
    cameraY: -4200,
    time: 12.5,
    breath: 0.62,
    progress,
    alpha: 1,
    quality,
  };
}

/**
 * Every station above the waterline, act II's and act III's together, with the
 * level each one dresses. The two acts are one continuous climb and are held to
 * one contract, so they are tested as one list.
 */
const CLIMB: { motif: (typeof AIR_MOTIFS)[number]; zone: number }[] = [
  ...AIR_MOTIFS.map((m, i) => ({ motif: m, zone: AIR_LEVELS[i]!.zone })),
  ...THIN_MOTIFS.map((m, i) => ({ motif: m, zone: THIN_LEVELS[i]!.zone })),
];

describe('the sky', () => {
  it('draws every station of the climb without a single bad number', () => {
    for (const { motif, zone } of CLIMB) {
      for (const progress of [0, 0.5, 1]) {
        for (const quality of [0.45, 1]) {
          const rec = new FakeContext();
          drawBackdrop(motif.backdrop, motif, view(rec, zone, progress, quality));
          expectFinite(rec, `${motif.key} p=${progress} q=${quality}`);
          expect(rec.fills + rec.strokes, `${motif.key} drew nothing`).toBeGreaterThan(0);
        }
      }
    }
  });

  it('leaves the composite mode where it found it', () => {
    // A backdrop that returns with 'lighter' still set tints everything drawn
    // after it - the flock, the rings, the HUD - and it looks like a bug in the
    // thing that came next.
    for (const { motif, zone } of CLIMB) {
      const rec = new FakeContext();
      drawBackdrop(motif.backdrop, motif, view(rec, zone, 0.5));
      expect(rec.globalCompositeOperation, motif.key).toBe('source-over');
    }
  });

  it('respects alpha, so a station crossfade can reach zero', () => {
    for (const { motif, zone } of CLIMB) {
      const rec = new FakeContext();
      drawBackdrop(motif.backdrop, motif, { ...view(rec, zone, 0.5), alpha: 0 });
      expect(rec.fills + rec.strokes, motif.key).toBe(0);
    }
  });

  it('gives every station on the climb a backdrop of its own', () => {
    // Twelve stations, twelve pictures. A repeat here is a station that looks
    // like somewhere the player has already been, which on a climb whose whole
    // subject is *leaving* is the one thing the art must not say.
    const kinds = new Set(CLIMB.map((c) => c.motif.backdrop));
    expect(kinds.size).toBe(CLIMB.length);
    // ...and none of them is a water backdrop wearing a new name.
    for (const m of MOTIFS) expect(kinds.has(m.backdrop)).toBe(false);
  });

  it('gives each act its own motif table, positionally', () => {
    expect(motifsForAct('air')).toBe(AIR_MOTIFS);
    expect(motifsForAct('water')).toBe(MOTIFS);
    for (let i = 0; i < AIR_LEVELS.length; i++) {
      expect(motifForIn('air', i).key).toBe(AIR_LEVELS[i]!.key);
    }
    // ...and an out-of-range index clamps rather than falling back to the trench.
    expect(motifForIn('air', 99).key).toBe(AIR_MOTIFS[AIR_MOTIFS.length - 1]!.key);
  });

  it('paints every station of the act in cloud, and nothing in stone', () => {
    // There is no rock above the waterline. A pale slab of stone hanging in the
    // sky was the single loudest thing wrong with the first version of the act,
    // and the fix is a rule rather than a colour: act II is made of one material.
    for (const m of AIR_MOTIFS) expect(m.material, m.key).toBe('cloud');
    // ...and none of the stone fringes comes with it. Nothing grows on vapour.
    for (const m of AIR_MOTIFS) expect(m.fringe, m.key).toBe('none');
  });

  it('runs out of daylight once it is above the weather', () => {
    // `daylight` is how much open sky is lighting a mass, and it is deliberately
    // *not* monotone across act II: the squall is dark because it is underneath
    // a storm, and coming out of the top of one puts the flock back into full
    // sun. What is monotone is everything from the anvil up, where the sky itself
    // is what runs out - by the Karman line nothing in the frame is lit at all.
    //
    // The sequence spans two motif tables, because the stations above the anvil
    // belong to act III now: no bird has ever been to 25 km, so the two
    // stratospheric stations were given to a carrier that can actually be there.
    // The light does not care which act it is in, so neither does this test.
    const climb = [...AIR_MOTIFS, ...THIN_MOTIFS];
    const key = (k: string): number => climb.find((m) => m.key === k)!.daylight;
    expect(key('squall')).toBeLessThan(key('cumulus'));
    expect(key('anvil')).toBeGreaterThan(key('squall'));
    for (let i = 0; i < THIN_MOTIFS.length; i++) {
      const above = THIN_MOTIFS[i]!;
      const below = i === 0 ? AIR_MOTIFS[AIR_MOTIFS.length - 1]! : THIN_MOTIFS[i - 1]!;
      expect(above.daylight, `${above.key} vs ${below.key}`).toBeLessThan(below.daylight);
    }
    // A hundred kilometres up there is no sky left to light anything with.
    expect(key('line')).toBe(0);
  });
});
