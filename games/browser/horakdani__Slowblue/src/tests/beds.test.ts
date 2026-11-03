import { describe, expect, it } from 'vitest';
import { BEDS, BED_KEYS, BED_LIST, bedFor, bedSpec, type BedKey } from '../src/audio/Beds';
import { BED_TRACK_KEYS, isBedTrack, AUDIO_TRACK_KEYS } from '../src/config/settings';
import { CAMPAIGN } from '../src/config/campaign';
import { levelAtIn } from '../src/config/levels';

/**
 * The failure this table exists to prevent was not a wrong number, it was an
 * unowned `else`: five of the seven acts fell through to the water's branch, so
 * the upper stratosphere, vacuum, a re-entry plasma sheath and a rainstorm were
 * all played a stream of bubbles and a whale. Nothing caught it, because nothing
 * asserted that an act's bed had anything to do with the act.
 *
 * So the tests here are mostly about coverage and distinctness rather than about
 * sound: every station in the campaign resolves to a bed, every act's bed is its
 * own, and no two beds are the same set of choices.
 */
describe('the bed table', () => {
  it('gives every station in the campaign a bed', () => {
    for (const info of CAMPAIGN) {
      for (let i = 0; i < info.act.levels.length; i++) {
        const level = levelAtIn(info.act, i);
        const key = bedFor(info.act.key, level.medium ?? 'water');
        expect(BED_KEYS).toContain(key);
        expect(bedSpec(key).layers.length).toBeGreaterThan(0);
      }
    }
  });

  /**
   * Seven acts, seven different beds. This is the requirement stated as a test.
   *
   * It counts the bed at *both ends* of every station - act V's stations name
   * where the medium starts and where it ends (`Level.mediumTo`) and blend across
   * themselves - and asks which bed each act spends most of itself in. That is
   * the right question rather than "what does station one play", because three of
   * the seven acts deliberately open in the previous act's medium: act V's first
   * station is still orbit, act VI's last two are already the brook, and act VII
   * opens on the brook and turns into the sea inside the station. Those are the
   * seams the campaign is built out of, and a bed that changed on the act line
   * instead would put a cut in every one of them.
   */
  it('gives each act a bed of its own', () => {
    const dominant = CAMPAIGN.map((info) => {
      const tally = new Map<BedKey, number>();
      for (let i = 0; i < info.act.levels.length; i++) {
        const level = levelAtIn(info.act, i);
        const from = level.medium ?? 'water';
        for (const medium of [from, level.mediumTo ?? from]) {
          const key = bedFor(info.act.key, medium);
          tally.set(key, (tally.get(key) ?? 0) + 1);
        }
      }
      return [...tally.entries()].sort((a, b) => b[1] - a[1])[0]![0];
    });
    expect(dominant).toEqual([
      'deep',
      'flight',
      'thin',
      'orbit',
      'fire',
      'rain',
      'homecoming',
    ]);
    expect(new Set(dominant).size).toBe(CAMPAIGN.length);
    // The seams themselves, named. The brook is the eighth bed and belongs to two
    // acts on purpose; everything else belongs to exactly one.
    expect(bedFor('rain', 'stream')).toBe('brook');
    expect(bedFor('home', 'stream')).toBe('brook');
    expect(bedFor('reentry', 'space')).toBe('orbit');
    // ...and the two acts flown in water are not the same bed, which is the whole
    // reason `bedFor` takes the act as well as the medium.
    expect(bedFor('water', 'water')).not.toBe(bedFor('home', 'water'));
  });

  it('answers for every medium, so no station can be authored into silence', () => {
    for (const medium of ['water', 'air', 'thinAir', 'space', 'plasma', 'cloud', 'stream'] as const) {
      expect(BED_KEYS).toContain(bedFor('water', medium));
      expect(BED_KEYS).toContain(bedFor('home', medium));
    }
    // An act key nothing recognises still gets a room rather than nothing.
    expect(bedFor('nonsense', 'water')).toBe('deep');
  });

  it('names every layer it lists, on a real mixer slot', () => {
    for (const spec of BED_LIST) {
      expect(spec.layers.length).toBeGreaterThanOrEqual(5);
      const seen = new Set<string>();
      for (const layer of spec.layers) {
        expect(BED_TRACK_KEYS).toContain(layer.track);
        // One row per slot: two layers on one slider is two labels for one control.
        expect(seen.has(layer.track)).toBe(false);
        seen.add(layer.track);
        expect(layer.name.length).toBeGreaterThan(0);
      }
      // Every bed has a chord, a bell and a body. Those three are what makes it a
      // room rather than a sound effect.
      for (const required of ['ocean', 'drone', 'ambience'] as const) {
        expect(seen.has(required)).toBe(true);
      }
      expect(spec.name.length).toBeGreaterThan(0);
    }
  });

  /**
   * "Every act's audio must differ" is a claim about the table, so it is checked
   * against the table: no two beds may have both the same layer names and the
   * same voicing. In practice they differ in every field, and this is the guard
   * against a new act being added by copying an old one.
   */
  it('gives no two beds the same set of choices', () => {
    const fingerprints = new Map<string, BedKey>();
    for (const spec of BED_LIST) {
      const print = JSON.stringify([
        spec.layers.map((l) => l.name),
        spec.drone,
        spec.shimmer,
        spec.bell,
      ]);
      expect(fingerprints.has(print)).toBe(false);
      fingerprints.set(print, spec.key);
    }
    // ...and the labels themselves are distinct act to act, which is what the
    // player actually sees in the drawer.
    const bodies = BED_LIST.map((s) => s.layers.find((l) => l.track === 'ocean')?.name);
    expect(new Set(bodies).size).toBe(BED_LIST.length);
  });

  it('voices every bed inside the ranges the engine can render', () => {
    for (const spec of BED_LIST) {
      for (const p of spec.drone.partials) {
        // 27.5 Hz to 165 Hz off a 55 Hz root: below hearing at one end and still
        // under everything the events play at the other.
        expect(p).toBeGreaterThanOrEqual(0.5);
        expect(p).toBeLessThanOrEqual(6);
      }
      expect(spec.drone.cutoff).toBeGreaterThan(150);
      expect(spec.drone.cutoff).toBeLessThan(2000);
      expect(spec.drone.gain).toBeGreaterThan(0);
      expect(spec.drone.gain).toBeLessThan(0.1);
      expect(spec.drone.spread).toBeGreaterThanOrEqual(3);
      expect(spec.shimmer.gain).toBeGreaterThan(0);
      expect(spec.shimmer.gain).toBeLessThan(0.06);
      const [lo, hi] = spec.bell.gap;
      expect(lo).toBeGreaterThan(0);
      expect(hi).toBeGreaterThan(lo);
      expect(spec.bell.hold).toBeGreaterThan(1);
    }
    // Act I is the reference and does not move. Its numbers are defended
    // digit-for-digit elsewhere in this project; this is where that is enforced.
    expect(BEDS.deep.drone).toEqual({ partials: [1, 1.5, 2, 3], cutoff: 520, gain: 0.055, spread: 6 });
    expect(BEDS.deep.shimmer).toEqual({ hz: 1500, q: 1.6, gain: 0.05, rate: 1.7 });
    expect(BEDS.deep.bell).toEqual({ gap: [21, 44], octave: 1, strike: 1, hold: 5.5 });
  });
});

describe('the mixer slots', () => {
  it('separates the bed from the game, with nothing in both', () => {
    const bed = AUDIO_TRACK_KEYS.filter(isBedTrack);
    const game = AUDIO_TRACK_KEYS.filter((k) => !isBedTrack(k));
    expect(bed).toEqual([...BED_TRACK_KEYS]);
    expect(game).toEqual(['movement', 'objectives', 'danger', 'interface']);
    expect(new Set(AUDIO_TRACK_KEYS).size).toBe(AUDIO_TRACK_KEYS.length);
  });
});
