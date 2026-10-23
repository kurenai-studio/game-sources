import { describe, expect, it } from 'vitest';
import { antifungalsFor, diskSpot, diskSpots, touchedDisk, touchesDisk, touchMessage, zoneWidth } from '../public/game/antifungal.js';
import { GAME, LEVELS, SPECIES } from '../public/game/config.js';

describe('diskSpot', () => {
  it('keeps the disk off the starting spot and away from the rim', () => {
    for (let i = 0; i < 200; i++) {
      const disk = diskSpot();
      const distance = Math.hypot(disk.fx, disk.fy);
      expect(distance).toBeGreaterThanOrEqual(GAME.DISK_MIN_DISTANCE - 1e-9);
      expect(distance).toBeLessThanOrEqual(GAME.DISK_MAX_DISTANCE + 1e-9);
      expect(distance + disk.r).toBeLessThan(1); // the whole disk fits in the dish
    }
  });

  it('is never close enough to the middle to touch a gal at the start', () => {
    expect(GAME.DISK_MIN_DISTANCE - GAME.DISK_RADIUS).toBeGreaterThan(0.25);
  });

  it('can land anywhere around the dish', () => {
    // With fixed "random" numbers, the angle follows the first one.
    const right = diskSpot(() => 0);
    const left = diskSpot(() => 0.5);
    expect(right.fx).toBeGreaterThan(0);
    expect(left.fx).toBeLessThan(0);
  });
});

describe('diskSpots', () => {
  it('places three disks on every plate', () => {
    for (let i = 0; i < 200; i++) expect(diskSpots(3)).toHaveLength(3);
  });

  it('spreads the disks apart so there is room to swim between them', () => {
    for (let i = 0; i < 200; i++) {
      const disks = diskSpots(3);
      for (let a = 0; a < disks.length; a++) {
        for (let b = a + 1; b < disks.length; b++) {
          const gap = Math.hypot(disks[a].fx - disks[b].fx, disks[a].fy - disks[b].fy);
          expect(gap).toBeGreaterThanOrEqual(GAME.DISK_MIN_GAP);
          // The open space between their edges is wider than a gal (about 0.12).
          expect(gap - 2 * GAME.DISK_RADIUS).toBeGreaterThan(0.2);
        }
      }
    }
  });

  it('keeps every disk off the starting spot and away from the rim', () => {
    for (let i = 0; i < 200; i++) {
      for (const disk of diskSpots(3)) {
        const distance = Math.hypot(disk.fx, disk.fy);
        expect(distance).toBeGreaterThanOrEqual(GAME.DISK_MIN_DISTANCE - 1e-9);
        expect(distance).toBeLessThanOrEqual(GAME.DISK_MAX_DISTANCE + 1e-9);
      }
    }
  });
});

describe('touchesDisk', () => {
  const dishRadius = 200;
  const disk = { fx: 0.5, fy: 0, r: 0.1 }; // center at (100, 0), radius 20px

  it('detects a gal overlapping the disk', () => {
    expect(touchesDisk(disk, [[100, 0, 5]], dishRadius)).toBe(true);
    expect(touchesDisk(disk, [[125, 0, 10]], dishRadius)).toBe(true); // edges overlap
  });

  it('ignores a gal that is close but not touching', () => {
    expect(touchesDisk(disk, [[131, 0, 10]], dishRadius)).toBe(false);
    expect(touchesDisk(disk, [[0, 0, 30]], dishRadius)).toBe(false);
  });

  it('counts a touch by any part of a group', () => {
    const chain = [[0, 0, 10], [40, 0, 10], [80, 0, 10]]; // last cell reaches the disk
    expect(touchesDisk(disk, chain, dishRadius)).toBe(true);
  });

  it('counts coming within the buffer as touching when given one', () => {
    expect(touchesDisk(disk, [[133, 0, 10]], dishRadius)).toBe(false);
    expect(touchesDisk(disk, [[133, 0, 10]], dishRadius, 0.025)).toBe(true);
  });

  it('treats an empty body as not touching', () => {
    expect(touchesDisk(disk, [], dishRadius)).toBe(false);
  });
});

describe('touchedDisk', () => {
  const dishRadius = 200;
  const disks = [
    { fx: 0.5, fy: 0, r: 0.1, antifungal: { code: 'A' } },
    { fx: -0.5, fy: 0, r: 0.1, antifungal: { code: 'B' } },
  ];

  it('tells which disk was touched', () => {
    expect(touchedDisk(disks, [[-100, 0, 5]], dishRadius).antifungal.code).toBe('B');
    expect(touchedDisk(disks, [[100, 0, 5]], dishRadius).antifungal.code).toBe('A');
  });

  it('returns null when no disk is touched', () => {
    expect(touchedDisk(disks, [[0, 0, 5]], dishRadius)).toBeNull();
  });

  it('counts edges within the margin as touching', () => {
    // Disk A's edge is at x = 80. A circle of radius 5 at x = 73 is 2px short.
    expect(touchedDisk(disks, [[73, 0, 5]], dishRadius)).toBeNull();
    expect(touchedDisk(disks, [[73, 0, 5]], dishRadius, 0.012).antifungal.code).toBe('A');
    // But not ones farther away than the margin.
    expect(touchedDisk(disks, [[70, 0, 5]], dishRadius, 0.012)).toBeNull();
  });

});

describe('zone of inhibition', () => {
  it('turns a zone in mm into a width that grows with the zone', () => {
    expect(zoneWidth(GAME.ZONE_MM_SMALL)).toBeCloseTo(GAME.ZONE_MIN_WIDTH);
    expect(zoneWidth(GAME.ZONE_MM_BIG)).toBeCloseTo(GAME.ZONE_MAX_WIDTH);
    expect(zoneWidth(30)).toBeGreaterThan(zoneWidth(20));
    // Beyond the range it stays at the smallest or biggest width.
    expect(zoneWidth(6)).toBeCloseTo(GAME.ZONE_MIN_WIDTH);
    expect(zoneWidth(50)).toBeCloseTo(GAME.ZONE_MAX_WIDTH);
  });

  it('gives a drug with no zone size no zone, so its disk still gets placed', () => {
    expect(zoneWidth(undefined)).toBe(0);
    expect(diskSpots([zoneWidth(undefined), zoneWidth(undefined)])).toHaveLength(2);
  });

  it('gives every antifungal a zone in a believable range, different across each gal\'s drugs', () => {
    for (const [gal, species] of Object.entries(SPECIES)) {
      for (const { code, zone } of species.antifungals) {
        if (zone === null) continue; // a drug she's resistant to: no zone (checked below)
        expect(zone, `${gal} ${code}`).toBeGreaterThanOrEqual(12);
        expect(zone, `${gal} ${code}`).toBeLessThanOrEqual(40);
      }
      const sizes = species.antifungals.map((a) => a.zone).filter((zone) => zone !== null);
      expect(Math.max(...sizes) - Math.min(...sizes), gal).toBeGreaterThanOrEqual(10);
    }
  });

  it('gives the same drug different zones on different gals', () => {
    // Fluconazole, voriconazole, nystatin and caspofungin show up for both gals.
    const byDrug = {};
    for (const species of Object.values(SPECIES)) {
      for (const { code, zone } of species.antifungals) (byDrug[code] ??= new Set()).add(zone);
    }
    for (const code of ['FLC', 'VOR', 'NY', 'CAS']) {
      expect(byDrug[code].size, code).toBeGreaterThan(1);
    }
  });

  it('leaves room to swim between the two biggest zones, wider than a gal is tall', () => {
    const [a, b] = diskSpots([GAME.ZONE_MAX_WIDTH, GAME.ZONE_MAX_WIDTH]);
    const between = Math.hypot(a.fx - b.fx, a.fy - b.fy) - 2 * (GAME.DISK_RADIUS + GAME.ZONE_MAX_WIDTH);
    expect(between).toBeGreaterThanOrEqual(GAME.SWIM_ROOM - 1e-9);
    expect(GAME.SWIM_ROOM).toBeGreaterThan(0.1);
  });

  it('always fits seven disks with each gal\'s zones, with swimming room between every pair', () => {
    for (const species of Object.values(SPECIES)) {
      const zones = antifungalsFor(species.antifungals, 7).map((a) => zoneWidth(a.zone));
      for (let dish = 0; dish < 30; dish++) {
        const disks = diskSpots(zones);
        expect(disks).toHaveLength(7);
        for (let i = 0; i < disks.length; i++) {
          expect(disks[i].zone).toBe(zones[i]);
          for (let j = i + 1; j < disks.length; j++) {
            const a = disks[i];
            const b = disks[j];
            const between = Math.hypot(a.fx - b.fx, a.fy - b.fy) - (a.r + a.zone + b.r + b.zone);
            expect(between).toBeGreaterThanOrEqual(GAME.SWIM_ROOM - 1e-9);
          }
        }
      }
    }
  });

  it('never reaches the middle, where the gal starts', () => {
    // A gal reaches about 0.1 of the dish radius from her center.
    expect(GAME.DISK_MIN_DISTANCE - GAME.DISK_RADIUS - GAME.ZONE_MAX_WIDTH).toBeGreaterThan(0.2);
  });

  it('counts touching a zone as touching its disk', () => {
    const disk = { fx: 0.5, fy: 0, r: 0.1, zone: 0.05 };
    // The zone's edge is at 0.35 of the dish radius = 70px.
    expect(touchesDisk(disk, [[64, 0, 5]], 200)).toBe(false);
    expect(touchesDisk(disk, [[66, 0, 5]], 200)).toBe(true);
  });
});

describe("Olive's drugs", () => {
  it('start with ketoconazole, the classic dandruff-shampoo azole', () => {
    expect(SPECIES.olive.antifungals[0].code).toBe('KCA');
  });
});
