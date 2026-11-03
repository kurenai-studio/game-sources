import { describe, expect, it } from 'vitest';
import { LEVELS } from '../src/config/levels';
import { AIR_MOTIFS, MOTIFS, motifForSection } from '../src/render/Motif';

describe('level background motifs', () => {
  it('gives every named station its matching, unique background', () => {
    expect(
      LEVELS.map((level, index) => ({
        key: level.key,
        name: level.name,
        decor: level.decor,
        backdrop: MOTIFS[index]?.backdrop,
      })),
    ).toEqual([
      { key: 'trench-floor', name: 'Trench Floor', decor: 'trench', backdrop: 'walls' },
      { key: 'black-water', name: 'Black Water', decor: 'abyss', backdrop: 'void' },
      {
        key: 'midnight-current',
        name: 'Midnight Current',
        decor: 'jelly',
        backdrop: 'stream',
      },
      { key: 'blue-rise', name: 'The Blue Rise', decor: 'garden', backdrop: 'rise' },
      {
        key: 'light-line',
        name: 'The Light Line',
        decor: 'meadow',
        backdrop: 'light-line',
      },
      { key: 'surface', name: 'The Surface', decor: 'kelp', backdrop: 'surface' },
    ]);
    expect(new Set(MOTIFS.map((motif) => motif.backdrop))).toHaveLength(LEVELS.length);
  });

  it('dresses a section in the motif of its own act', () => {
    // The regression this pins: `motifForSection` used to index the water table
    // unconditionally, so an air gate was painted as a slab of midnight basalt
    // hanging in the sky - the cloud material existed and was never reached.
    expect(motifForSection('air', 2, 5)).toBe(AIR_MOTIFS[2]);
    expect(motifForSection('air', 2, 5)!.material).toBe('cloud');
    expect(motifForSection('water', 2, 5)).toBe(MOTIFS[2]);
    // Generated water (the sweeps) carries no level and still borrows the zone's
    // water motif, whichever act asked.
    expect(motifForSection('water', -1, 2).key).toBe(MOTIFS[3]!.key);
    expect(motifForSection('air', -1, 2).key).toBe(MOTIFS[3]!.key);
  });
});
