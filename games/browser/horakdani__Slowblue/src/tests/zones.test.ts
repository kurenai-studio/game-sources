import { describe, expect, it } from 'vitest';
import {
  AIR_ZONES,
  ALL_ZONES,
  HOME_ZONES,
  RAIN_ZONES,
  REENTRY_ZONES,
  SPACE_ZONES,
  THIN_ZONES,
  ZONES,
  sectionKindFor,
  zoneForSection,
} from '../src/config/zones';
import { ObstacleSystem } from '../src/sim/ObstacleSystem';
import { ZONE_PAINT, blendPaint, clonePaint, parseHex, rgba } from '../src/render/Paint';
import { W } from './helpers';

describe('ascent zones', () => {
  it('starts in the hadal dark and advances monotonically toward the surface', () => {
    expect(zoneForSection(0).key).toBe('hadal');
    let last = -1;
    for (let id = 0; id < 60; id++) {
      const z = zoneForSection(id).index;
      expect(z).toBeGreaterThanOrEqual(last);
      last = z;
    }
    expect(last).toBe(ZONES.length - 1);
    expect(ZONES[last]!.key).toBe('surface');
  });

  it('keeps the opening three sections as the fixed teaching sequence', () => {
    // The first zone is the tutorial. A tutorial that shuffles is not a tutorial.
    expect([0, 1, 2].map(sectionKindFor)).toEqual(['gate', 'rock', 'narrows']);
  });

  it('only builds a kind the owning zone actually allows', () => {
    for (let id = 0; id < 80; id++) {
      expect(zoneForSection(id).pool).toContain(sectionKindFor(id));
    }
  });

  it('introduces every archetype, and holds the hazards back for the deep', () => {
    const kindsUpTo = (n: number): Set<string> =>
      new Set(Array.from({ length: n }, (_, i) => sectionKindFor(i)));
    expect(kindsUpTo(ZONES[1]!.fromSection)).toEqual(new Set(['gate', 'rock', 'narrows']));
    expect(kindsUpTo(ZONES[2]!.fromSection).has('vortex')).toBe(true);
    // A hunter is the one hazard the player cannot steer around; it waits for the deep.
    expect(kindsUpTo(ZONES[2]!.fromSection).has('predator')).toBe(false);
    expect(kindsUpTo(ZONES[2]!.fromSection + 4).has('predator')).toBe(true);
    expect(kindsUpTo(40).size).toBe(6);
  });

  it('changes palette at the same section it changes content', () => {
    for (const zone of ZONES) {
      expect(zoneForSection(zone.fromSection).index).toBe(zone.index);
      if (zone.index > 0) {
        expect(zoneForSection(zone.fromSection - 1).index).toBe(zone.index - 1);
      }
    }
  });
});

describe('zone content generation', () => {
  it('spawns standing currents only on vortex sections', () => {
    const o = new ObstacleSystem(W, 5);
    o.ensureAhead(-26000);
    for (const s of o.sections) {
      expect(s.vortexHints.length > 0).toBe(s.kind === 'vortex');
      expect(s.hunterHints.length > 0).toBe(s.kind === 'predator');
    }
  });

  it('gives every section a way to grow the shoal back', () => {
    const o = new ObstacleSystem(W, 8);
    o.ensureAhead(-26000);
    for (const s of o.sections) {
      if (s.kind === 'gate') continue; // the plain gate is the one free breather
      expect(s.podHints.length).toBeGreaterThan(0);
      for (const p of s.podHints) {
        expect(p.x).toBeGreaterThan(0);
        expect(p.x).toBeLessThan(W);
        expect(p.count).toBeGreaterThan(0);
      }
    }
  });

  it('puts a second hunter in the trench and only there', () => {
    const o = new ObstacleSystem(W, 3);
    o.ensureAhead(-30000);
    const predatorSections = o.sections.filter((s) => s.kind === 'predator');
    expect(predatorSections.length).toBeGreaterThan(2);
    for (const s of predatorSections) {
      expect(s.hunterHints.length).toBe(s.zone >= 3 ? 2 : 1);
    }
  });

  it('tags every section with its zone', () => {
    const o = new ObstacleSystem(W, 2);
    o.ensureAhead(-26000);
    for (const s of o.sections) expect(s.zone).toBe(zoneForSection(s.id).index);
  });

  it('is still deterministic per seed with the new archetypes', () => {
    const layout = (seed: number): string =>
      (() => {
        const o = new ObstacleSystem(W, seed);
        o.ensureAhead(-26000);
        return o.sections
          .map((s) => `${s.kind}:${s.blobs.length}:${Math.round(s.blobs[0]!.x)}`)
          .join('|');
      })();
    expect(layout(21)).toEqual(layout(21));
    expect(layout(21)).not.toEqual(layout(22));
  });
});

describe('zone palettes', () => {
  it('parses every zone colour, in every act', () => {
    // The paint table covers every palette the campaign can paint, while `ZONES`
    // alone remains the water's *progression* table, which is what
    // `zoneForSection` walks.
    expect(ZONE_PAINT.length).toBe(ALL_ZONES.length);
    expect(ALL_ZONES.length).toBe(
      ZONES.length +
        AIR_ZONES.length +
        THIN_ZONES.length +
        SPACE_ZONES.length +
        REENTRY_ZONES.length +
        RAIN_ZONES.length +
        HOME_ZONES.length,
    );
    for (const p of ZONE_PAINT) {
      for (const c of [p.top, p.mid, p.bottom, p.shoal, p.rock, p.tracer, p.pod]) {
        expect(c.every((v) => Number.isFinite(v) && v >= 0 && v <= 255)).toBe(true);
      }
      expect(p.shoalGlowAlpha).toBeGreaterThan(0);
    }
  });

  it('reads short and long hex the same way', () => {
    expect(parseHex('#fff')).toEqual([255, 255, 255]);
    expect(parseHex('06203a')).toEqual([6, 32, 58]);
  });

  it('brightens every band on the way to the surface', () => {
    const luminance = ([r, g, b]: [number, number, number]): number =>
      r * 0.2126 + g * 0.7152 + b * 0.0722;
    for (let i = 1; i < ZONES.length; i++) {
      expect(luminance(parseHex(ZONES[i]!.palette.top))).toBeGreaterThan(
        luminance(parseHex(ZONES[i - 1]!.palette.top)),
      );
      expect(ZONES[i]!.palette.speckDensity).toBeGreaterThan(
        ZONES[i - 1]!.palette.speckDensity,
      );
    }
  });

  /**
   * ...and then, once the climb leaves the weather behind, it darkens again -
   * which is the one visual rule that lets a frame of act II be told from a frame
   * of act I at thumbnail size. In water `top` points at the surface, so ahead is
   * brighter; in the upper air `top` points at space, so ahead is thinner and
   * darker.
   *
   * The spray is deliberately exempt and is the reason this is written as "once it
   * leaves the water" rather than "in air": fifty metres up, the bright thing
   * really is the sky and the dark thing really is the sea you just came out of.
   * The inversion is a fact about altitude, not about the medium, so it arrives
   * where altitude starts to mean something.
   */
  it('inverts the light once the climb is clear of the weather', () => {
    const luminance = ([r, g, b]: [number, number, number]): number =>
      r * 0.2126 + g * 0.7152 + b * 0.0722;
    const spray = AIR_ZONES[0]!;
    expect(spray.key).toBe('spray');
    expect(luminance(parseHex(spray.palette.top))).toBeGreaterThan(
      luminance(parseHex(spray.palette.bottom)),
    );
    for (const zone of AIR_ZONES.slice(1)) {
      expect(
        luminance(parseHex(zone.palette.top)),
        `${zone.key} top vs bottom`,
      ).toBeLessThan(luminance(parseHex(zone.palette.bottom)));
    }
    // ...and the top of the last one is darker than the sunlit water far below it.
    const last = AIR_ZONES[AIR_ZONES.length - 1]!;
    const surface = ZONES[ZONES.length - 1]!;
    expect(luminance(parseHex(last.palette.top))).toBeLessThan(
      luminance(parseHex(surface.palette.top)),
    );
  });

  /**
   * Slowblue: the ascent gets darker, all the way up, and that is a claim about
   * numbers.
   *
   * Sky is blue because there is air overhead to scatter sunlight in it, and
   * there is monotonically less of it the higher you go: by 25 km a fortieth, by
   * 50 km a thousandth, by 100 km none. So the twelve bands of acts II and III
   * form **one continuous sequence** that goes out from the wave tops to the
   * Karman line - which is why this is asserted across both tables at once rather
   * than act by act. Splitting an act does not get to break the light.
   *
   * Both halves are checked, because a palette table is exactly the kind of thing
   * a later edit brightens one entry of without noticing.
   */
  it('goes out continuously from the wave tops to the Karman line', () => {
    const luminance = ([r, g, b]: [number, number, number]): number =>
      r * 0.2126 + g * 0.7152 + b * 0.0722;
    const sky = (z: (typeof AIR_ZONES)[number]): number =>
      (luminance(parseHex(z.palette.top)) +
        luminance(parseHex(z.palette.mid)) +
        luminance(parseHex(z.palette.bottom))) /
      3;
    const climb = [...AIR_ZONES, ...THIN_ZONES];
    expect(AIR_ZONES.length).toBe(6);
    expect(THIN_ZONES.length).toBe(6);
    for (let i = 1; i < climb.length; i++) {
      expect(sky(climb[i]!), `${climb[i]!.key} vs ${climb[i - 1]!.key}`).toBeLessThan(
        sky(climb[i - 1]!),
      );
    }
    // Above the anvil the sky is night, in daylight.
    expect(sky(THIN_ZONES[0]!)).toBeLessThan(80);
    // ...and the Karman line is as close to nothing as a frame can be and still
    // read as a place.
    expect(sky(climb[climb.length - 1]!)).toBeLessThan(10);
  });

  /**
   * ...and the ice stays the brightest thing in it.
   *
   * Which is literally true above about 20 km: the crystal is still in sunlight
   * when nothing else in the frame is, and it is the only reason those stations
   * are legible at all. `rock` is the obstacle colour, so this is the assertion
   * that act III's obstacles never sink into their own background.
   */
  it('leaves the ice as the last lit thing above the weather', () => {
    const luminance = ([r, g, b]: [number, number, number]): number =>
      r * 0.2126 + g * 0.7152 + b * 0.0722;
    for (const zone of THIN_ZONES) {
      expect(
        luminance(parseHex(zone.palette.rock)),
        `${zone.key} ice vs sky`,
      ).toBeGreaterThan(luminance(parseHex(zone.palette.bottom)));
    }
  });

  /**
   * Slowblue: the campaign is a circle, and the palette has to close it.
   *
   * The last band of act VII is the trench floor the first band of act I is, to
   * within the tolerance of a colour a player could tell apart. That is the whole
   * ending: the picture the campaign finishes on and the picture it opened on are
   * the same picture, and the player is meant to notice that themselves rather
   * than be told. If a later edit drifts one of them, the ending stops landing
   * and nothing else in the codebase would complain.
   */
  it('comes home to the palette it started in', () => {
    const first = ZONES[0]!.palette;
    const last = HOME_ZONES[HOME_ZONES.length - 1]!.palette;
    expect(last.top).toBe(first.top);
    expect(last.mid).toBe(first.mid);
    expect(last.bottom).toBe(first.bottom);
    expect(last.rock).toBe(first.rock);
  });

  /** Every band knows where it sits, or `paintFor` paints the wrong act. */
  it('stamps every zone with its own position in the table', () => {
    ALL_ZONES.forEach((z, i) => expect(z.index, z.key).toBe(i));
    // ...and no two bands share a key, which is what the admin surface lists by.
    expect(new Set(ALL_ZONES.map((z) => z.key)).size).toBe(ALL_ZONES.length);
  });

  it('keeps the air out of the generator, which only ever builds water', () => {
    // `zoneForSection` walks `ZONES`, so no generated course can ever be handed an
    // air palette however far it runs.
    for (const id of [0, 5, 40, 4000, 500000]) {
      expect(ZONES).toContain(zoneForSection(id));
    }
  });

  it('blends one palette into another without ever leaving the range', () => {
    const cur = clonePaint(ZONE_PAINT[0]!);
    for (let i = 0; i < 200; i++) blendPaint(cur, ZONE_PAINT[3]!, 0.1);
    expect(cur.top[0]).toBeCloseTo(ZONE_PAINT[3]!.top[0], 3);
    expect(cur.speckDensity).toBeCloseTo(ZONE_PAINT[3]!.speckDensity, 3);
    // The source palette must not have been mutated by the blend.
    expect(ZONE_PAINT[0]!.top).toEqual(parseHex(ZONES[0]!.palette.top));
  });

  it('emits valid css', () => {
    expect(rgba([1.4, 2.6, 3], 0.5)).toBe('rgba(1,3,3,0.500)');
  });
});
