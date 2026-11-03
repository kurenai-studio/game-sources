import { describe, expect, it } from 'vitest';
import { CAMPAIGN } from '../src/config/campaign';
import {
  CIRCUIT_ACTS,
  CIRCUIT_ATLAS,
  MAP_H,
  MAP_W,
  SEA_Y,
  SPACE_Y,
  linkArrow,
  routePoint,
  seaCrestY,
  worldY,
  worldFacePath,
  worldLayerPath,
  worldRadius,
  ATLAS_LINKS,
  type WorldFrame,
} from '../src/meta/Circuit';
import {
  FLOOR_Y,
  HABITAT,
  HABITAT_SHAPES,
  ROUTE_INK,
  placeHabitat,
  underRoute,
} from '../src/meta/Habitat';

/**
 * Slowblue: the world the route stands in, asserted rather than looked at.
 *
 * `meta/Habitat.ts` exists to answer one complaint about the map - three bands of
 * flat colour do not say water, air and vacuum - and it answers it with the one
 * thing a map of forty-two stops cannot afford, which is furniture. So what is
 * tested here is not that the furniture is pretty. It is the three promises that
 * stop it from being a mistake:
 *
 *   1. **Nothing is ever drawn on the picture.** Not on a stop, not on a name,
 *      not on an arrowhead, and not in the column of type under the map. This is
 *      the one that has to hold on every screen the map is drawn at, because the
 *      map is a control and a cloud over "The Homecoming" is a control you cannot
 *      read.
 *   2. **Everything is in the band it claims to be in**, at every width - a fish
 *      under the sea, a cloud under the Karman line and over the sea, a star
 *      above both - which is the whole of what the marks are for.
 *   3. **It is the same world every time.** No clock, no randomness: two calls
 *      with the same frame are the same picture, and so are two machines.
 *
 * The frames are the two the atlas suite already uses, for the same reason: a
 * phone, where the map is nearly the whole screen and the margins are nothing,
 * and a desktop, where it is a column in the middle of a wide window and the
 * margins are most of it. They are the two cases every rule here has to survive.
 */
const PHONE: WorldFrame = { scale: 0.99, x: 4, y: 84, width: 390, height: 844 };
const DESKTOP: WorldFrame = { scale: 1.07, x: 514, y: 120, width: 1440, height: 900 };
/** ...and a tablet, because that is the width the margins first appear at. */
const TABLET: WorldFrame = { scale: 1.07, x: 178, y: 96, width: 768, height: 1024 };
/**
 * ...and the smallest screen the map is drawn on, measured off one.
 *
 * A three-hundred-and-twenty by five-hundred-and-sixty-eight window, where the
 * map has run out of height rather than width: `.ui-map`'s `min-height` holds it
 * at 344 CSS pixels tall and the ratio then makes it 275 wide, which is narrower
 * than the window. That is a different case from the other three and not a
 * smaller one - the picture is inset from both edges, so a mark can be beside it
 * on a phone, which is the only place that happens.
 */
const NARROW: WorldFrame = { scale: 0.717, x: 22.4, y: 33.5, width: 320, height: 568 };
const FRAMES: [string, WorldFrame][] = [
  ['phone', PHONE],
  ['desktop', DESKTOP],
  ['tablet', TABLET],
  ['narrow phone', NARROW],
];

/** A point of the map's own ink, in box units, with how far it reaches. */
interface Mark {
  what: string;
  x: number;
  y: number;
  r: number;
}

/**
 * Every mark the shell draws on the picture, and how much room it takes.
 *
 * Built from the same atlas the shell draws from rather than listed, so that a
 * stop moved in `meta/Circuit.ts` moves here too and the keep-out is checked
 * against where the ink actually went.
 */
const INK: Mark[] = [
  // The forty-two stops, and the halo round wherever the player is standing.
  ...CIRCUIT_ATLAS.map((p) => ({ what: p.key, ...routePoint(p.t), r: 13 })),
  // The seven ways in, drawn as a ring round the stop the line arrives at.
  ...CIRCUIT_ACTS.map((b) => ({
    what: `entry ${b.act + 1}`,
    ...routePoint(b.from),
    r: 9,
  })),
  // The seven arrowheads, one on each seam.
  ...ATLAS_LINKS.map((link) => {
    const a = linkArrow(link);
    return { what: `arrow ${link.from + 1}`, x: a.x, y: a.y, r: 8 };
  }),
  /*
   * ...and the type. An act's name is anchored at `labelX` and runs away from the
   * line, so what has to be covered is the anchor and the whole gutter behind it:
   * the widest string in the picture is act VII's, and a test that measured it
   * would be a test that owns a font metric. The corner it can reach is the edge
   * of the box on its own side, which is a claim the layout already makes.
   */
  ...CIRCUIT_ACTS.flatMap((b) => {
    const x = b.side === -1 ? 2 : b.side === 1 ? MAP_W - 2 : b.labelX;
    return [
      { what: `name ${b.act + 1}`, x, y: b.labelY - 6, r: 2 },
      { what: `meta ${b.act + 1}`, x, y: b.labelY + 11, r: 2 },
      { what: `anchor ${b.act + 1}`, x: b.labelX, y: b.labelY, r: 2 },
    ];
  }),
  // ...and the one line of type under the picture: the trench floor's own name.
  { what: 'seam name', x: MAP_W / 2, y: MAP_H - 20, r: 54 },
];

/**
 * Every point a unit shape names, as points rather than as a run of numbers.
 *
 * Which matters for exactly one reason: an `A` command carries five parameters
 * that are not coordinates before the two that are - two radii, a rotation, and
 * two flags that are always `0` or `1` - and a test that reads a path as a list
 * of numbers reads that `1` as a coordinate and fails a circle of radius a half
 * for being twice the size it is.
 */
function points(d: string): { x: number; y: number }[] {
  const out: { x: number; y: number }[] = [];
  for (const [, cmd, body] of d.matchAll(/([MLCQAZ])([^MLCQAZ]*)/g)) {
    const n = (body ?? '')
      .trim()
      .split(/[\s,]+/)
      .filter(Boolean)
      .map(Number);
    const from = cmd === 'A' ? 5 : 0;
    for (let i = from; i + 1 < n.length; i += 2) out.push({ x: n[i]!, y: n[i + 1]! });
  }
  return out;
}

/** Every `Q` of a path, as the control point it leans on and the node it ends on. */
function quads(d: string): { c: [number, number]; p: [number, number] }[] {
  return [...d.matchAll(/Q (-?[\d.]+) (-?[\d.]+) (-?[\d.]+) (-?[\d.]+)/g)].map((m) => ({
    c: [Number(m[1]), Number(m[2])],
    p: [Number(m[3]), Number(m[4])],
  }));
}

/**
 * How far each kind's drawing actually reaches from its own origin, read off the
 * paths rather than taken from the authored `tall`.
 *
 * Read rather than trusted, and that is the whole point of it: `tall` is a number
 * a person types beside a colony, the keep-out multiplies it by the mark's size
 * to decide what is clear, and if it is smaller than the drawing then every rule
 * in this file is enforced against a shape that is not the one on the screen. A
 * cubic or a quadratic stays inside the hull of its own control points, so the
 * furthest point a path names bounds every curve through it.
 */
const REACH: Record<string, { x: number; y: number }> = Object.fromEntries(
  Object.entries(HABITAT_SHAPES).map(([kind, shapes]) => {
    const all = shapes.flatMap((d) => points(d));
    return [
      kind,
      {
        x: Math.max(...all.map((p) => Math.abs(p.x))),
        y: Math.max(...all.map((p) => Math.abs(p.y))),
      },
    ];
  }),
);

/**
 * Where a placed mark reaches, in the same box units the route is in.
 *
 * The upright box of a turned drawing, from that drawing's own reach - so a fish
 * tilted fourteen degrees is checked at the corner that actually sticks out.
 */
function boxOf(
  frame: WorldFrame,
  p: { x: number; y: number; drawn: number; angle: number; kind: string },
): { l: number; r: number; t: number; b: number } {
  const reach = REACH[p.kind]!;
  const rad = (p.angle * Math.PI) / 180;
  const cos = Math.abs(Math.cos(rad));
  const sin = Math.abs(Math.sin(rad));
  const halfW = p.drawn * (reach.x * cos + reach.y * sin);
  const halfH = p.drawn * (reach.x * sin + reach.y * cos);
  return {
    l: (p.x - halfW - frame.x) / frame.scale,
    r: (p.x + halfW - frame.x) / frame.scale,
    t: (p.y - halfH - frame.y) / frame.scale,
    b: (p.y + halfH - frame.y) / frame.scale,
  };
}

describe('the world behind the route', () => {
  it('never draws anything over the map', () => {
    for (const [name, frame] of FRAMES) {
      for (const p of placeHabitat(frame)) {
        if (p.ink <= 0) continue;
        const box = boxOf(frame, p);
        for (const mark of INK) {
          const clear =
            box.r < mark.x - mark.r ||
            box.l > mark.x + mark.r ||
            box.b < mark.y - mark.r ||
            box.t > mark.y + mark.r;
          expect(clear, `${p.kind} over ${mark.what} on a ${name}`).toBe(true);
        }
      }
    }
  });

  /**
   * ...and never under the shell's own column either.
   *
   * The panel is not in the atlas - it is an act's name, its verb, a sentence, a
   * count and two buttons, and how tall that is depends on the copy and on
   * whether the station list is open - so the rule the world obeys is the blunt
   * one: inside the width of the picture, stay inside the height of it.
   */
  it('never draws anything over or under the picture, inside its own width', () => {
    for (const [name, frame] of FRAMES) {
      for (const p of placeHabitat(frame)) {
        if (p.ink <= 0) continue;
        const box = boxOf(frame, p);
        if (box.r < 0 || box.l > MAP_W) continue;
        expect(box.t, `${p.kind} above the picture on a ${name}`).toBeGreaterThanOrEqual(0);
        expect(box.b, `${p.kind} below the picture on a ${name}`).toBeLessThanOrEqual(MAP_H);
      }
    }
  });

  it('keeps every mark in the band it says it is in', () => {
    for (const [name, frame] of FRAMES) {
      for (const p of placeHabitat(frame)) {
        if (p.ink <= 0) continue;
        const sea = worldY(frame, SEA_Y, p.x);
        const karman = worldY(frame, SPACE_Y, p.x);
        const floor = worldY(frame, FLOOR_Y, p.x);
        const where = `${p.kind} on a ${name}`;
        if (p.band === 'space') expect(p.y, where).toBeLessThan(karman);
        if (p.band === 'air') {
          expect(p.y, where).toBeGreaterThan(karman);
          expect(p.y, where).toBeLessThan(sea);
        }
        if (p.band === 'water') {
          expect(p.y, where).toBeGreaterThan(sea);
          expect(p.y, where).toBeLessThan(floor);
        }
        /*
         * ...and the fourth band is the one that is a line, so it is checked as
         * one: on the water exactly, not near it.
         *
         * On the crests rather than the mean, because the sea has a swell on it
         * and this is the height a hull rests at. `toBe` rather than a tolerance,
         * and it is not pedantry: the whole reason the boat carries no authored
         * height is that two pixels off is a boat hovering or a boat swamped, and
         * both of those are inside any tolerance worth writing.
         */
        if (p.band === 'surface') expect(p.y, where).toBe(seaCrestY(frame, p.x));
        // ...and that is above the mean surface, never on it.
        if (p.band === 'surface') expect(p.y, where).toBeLessThan(sea);
      }
    }
  });

  /**
   * The two built things are the reason this file is not only a scatter.
   *
   * A star field can lose forty of its forty-six to the keep-out and still be a
   * star field. There is exactly one satellite and exactly one boat, and if the
   * narrowest screen the map is drawn on hides either of them then the band it
   * names has nothing built in it on the screen most people are holding - and for
   * the boat that is the whole of what it was added for, because a waterline with
   * nothing floating on it is a change of tint.
   */
  it('shows both built things on every screen, the narrowest included', () => {
    for (const [name, frame] of FRAMES) {
      const placed = placeHabitat(frame);
      for (const kind of ['satellite', 'boat'] as const) {
        const one = placed.filter((p) => p.kind === kind && p.ink > 0);
        expect(one.length, `${kind} on a ${name}`).toBe(1);
      }
      // ...and enough of the rest to read as populations rather than as one of
      // something. Two, not one: a single fish in an ocean is a stray mark.
      for (const kind of ['fish', 'bird', 'star', 'cloud', 'streak'] as const) {
        const lit = placed.filter((p) => p.kind === kind && p.ink > 0);
        expect(lit.length, `${kind} on a ${name}`).toBeGreaterThanOrEqual(2);
      }
    }
  });

  /**
   * ...and the boat sits *on* the water rather than in it.
   *
   * Which is a drawing rule with a rendering reason behind it. `Shell` puts the
   * two horizons last and nothing over them, because a horizon with something in
   * front of it is not a horizon - so every unit a mark puts below `y = 0` is a
   * unit the sea's own stroke gets ruled straight through. A hull with a third of
   * itself under the line is honest about displacement and reads, at every size
   * the map is drawn at, as a boat with a bright wire through it.
   */
  it('sits the boat on the water rather than in it', () => {
    const ys = HABITAT_SHAPES.boat.flatMap((d) => points(d)).map((p) => p.y);
    // Nothing at all below the waterline...
    expect(Math.max(...ys)).toBe(0);
    // ...and the keel on it rather than above it, so the sea's stroke runs along
    // the bottom of the boat instead of under a gap the boat is hovering over.
    expect(ys.filter((y) => y === 0).length).toBeGreaterThanOrEqual(2);
    // ...and it is level, because water is.
    for (const life of HABITAT.filter((l) => l.band === 'surface')) expect(life.angle).toBe(0);
  });

  it('fills a wide window with more world than a narrow one', () => {
    const lit = (frame: WorldFrame): number => placeHabitat(frame).filter((p) => p.ink > 0).length;
    expect(lit(DESKTOP)).toBeGreaterThan(lit(TABLET));
    expect(lit(TABLET)).toBeGreaterThan(lit(PHONE));
  });

  it('is the same world every time it is drawn', () => {
    expect(placeHabitat(PHONE)).toEqual(placeHabitat(PHONE));
    // ...and the population itself is authored, not generated per call.
    expect(placeHabitat(DESKTOP)).toHaveLength(HABITAT.length);
    for (const life of HABITAT) {
      expect(Number.isFinite(life.u) && life.u >= 0 && life.u <= 1, life.kind).toBe(true);
      expect(Number.isFinite(life.v) && life.v >= 0 && life.v <= 1, life.kind).toBe(true);
      expect(life.size, life.kind).toBeGreaterThan(0);
      expect(life.alpha, life.kind).toBeGreaterThan(0);
      // Nothing here is allowed to be as loud as the quietest thing on the route,
      // which is a stretch of line nobody has flown at 0.16 of the pale blue -
      // except a star, which is two pixels across and buys its brightness by
      // being small enough that nothing can be behind it.
      expect(life.alpha, life.kind).toBeLessThanOrEqual(life.kind === 'star' ? 0.62 : 0.44);
    }
  });

  it('draws every kind it declares, at one unit each', () => {
    for (const life of HABITAT) {
      const shapes = HABITAT_SHAPES[life.kind];
      expect(shapes.length, life.kind).toBeGreaterThan(0);
      expect(shapes[life.shape], `${life.kind} shape ${life.shape}`).toBeTypeOf('string');
      for (const d of shapes) {
        expect(d.startsWith('M'), life.kind).toBe(true);
        // Unit-sized: nothing reaches past half a unit from the origin on either
        // axis, so that the size a mark is placed at is the size the mark is.
        // A cubic is inside the hull of its own control points, so checking those
        // checks the curve; an `A` is checked at its ends, and the only two in
        // this file are a circle of radius a half and a dish of radius a tenth.
        for (const p of points(d)) {
          expect(Math.abs(p.x), `${life.kind} x at ${p.x}`).toBeLessThanOrEqual(0.5);
          expect(Math.abs(p.y), `${life.kind} y at ${p.y}`).toBeLessThanOrEqual(0.5);
        }
      }
      /*
       * ...and `tall` is not smaller than the drawing it describes.
       *
       * This is the join between a number somebody typed and a shape somebody
       * drew, and it only fails in one direction: too big only wastes sky, too
       * small puts a cloud over a name and calls it clear. Most drawings are
       * centred on their own origin so that half of `tall` is their whole reach
       * up and down - which is why the cloud, the bird and the satellite were all
       * shifted onto their own middles when this arrived.
       *
       * The boat is not, and cannot be: its origin is the waterline it is placed
       * on, so the whole of it is above that. The rule still holds and is still
       * the right rule - `tall` covers the furthest either way, doubled - it is
       * simply buying a keep-out that is generous under a hull, in water where
       * nothing was going to be drawn.
       */
      const reach = REACH[life.kind]!;
      expect(life.tall / 2, `${life.kind} tall`).toBeGreaterThanOrEqual(reach.y);
      expect(reach.x, `${life.kind} width`).toBeCloseTo(0.5, 2);
    }
  });

  /**
   * The keep-out is written out by hand in `meta/Habitat.ts` rather than derived,
   * so this is the join that holds it to the picture: every mark the shell draws
   * has to be inside one of the four rectangles. `INK` above is the same list the
   * map draws from, which is what makes this a check and not a copy.
   */
  it('covers every mark the map draws with one of its four rectangles', () => {
    for (const mark of INK) {
      const inside = ROUTE_INK.some(
        (k) => mark.x >= k.x && mark.x <= k.x + k.w && mark.y >= k.y && mark.y <= k.y + k.h,
      );
      expect(inside, `${mark.what} at ${mark.x.toFixed(1)}, ${mark.y.toFixed(1)}`).toBe(true);
    }
    // ...and the four of them leave the two places the world actually lives: the
    // column inside the route, and the dark either side of the turn.
    for (const [what, x, y] of [
      ['inside the route', 183, 250],
      ['left of the turn', 60, 40],
      ['right of the turn', 320, 40],
    ] as const) {
      const hit = ROUTE_INK.some((k) => x >= k.x && x <= k.x + k.w && y >= k.y && y <= k.y + k.h);
      expect(hit, what).toBe(false);
    }
  });

  it('reads a mark as clear only when the whole of it is clear', () => {
    // Dead centre of the picture, which is inside the route and free...
    const centre = { x: PHONE.x + 183 * PHONE.scale, y: PHONE.y + 250 * PHONE.scale };
    expect(underRoute(PHONE, centre.x, centre.y, 2, 2)).toBe(false);
    // ...until it is wide enough to reach the rails either side of it.
    expect(underRoute(PHONE, centre.x, centre.y, 60 * PHONE.scale, 2)).toBe(true);
    /*
     * ...and the two axes are answered separately, which is the whole reason
     * `tall` exists. Low in the column, a mark reaches the seam along the bottom
     * if it is tall and clears it if it is flat - and a streak of high ice is
     * flat. Tested as a square it is deleted; tested as itself it is a streak.
     */
    const low = { x: centre.x, y: PHONE.y + 380 * PHONE.scale };
    expect(underRoute(PHONE, low.x, low.y, 30 * PHONE.scale, 40 * PHONE.scale)).toBe(true);
    expect(underRoute(PHONE, low.x, low.y, 30 * PHONE.scale, 6 * PHONE.scale)).toBe(false);
    // Off the side of the picture is free at any height: that is the margin a
    // wide window leaves, and it is where most of this world lives.
    expect(underRoute(DESKTOP, 40, 400, 30, 30)).toBe(false);
    // Over the top of it and under the bottom is not, at any width.
    expect(underRoute(PHONE, centre.x, PHONE.y - 4, 6, 6)).toBe(true);
    expect(underRoute(PHONE, centre.x, PHONE.y + MAP_H * PHONE.scale, 6, 6)).toBe(true);
  });
});

describe('the floor of the trench', () => {
  it('stands exactly where the circuit closes', () => {
    // Act I station 1 and act VII station 6 are the same six thousand metres, and
    // the seam between them is the run the floor is under.
    const first = CAMPAIGN[0].act.levels[0];
    const last = CAMPAIGN[CAMPAIGN.length - 1].act.levels;
    expect(first.depthMeters).toBe(last[last.length - 1].depthMeters);
    const seam = ATLAS_LINKS[ATLAS_LINKS.length - 1];
    expect(seam.closes).toBe(true);
    expect(FLOOR_Y).toBeCloseTo(linkArrow(seam).y, 6);
  });

  it('is a third shell of the same planet, deeper than the sea everywhere', () => {
    for (const [name, frame] of FRAMES) {
      for (let x = 0; x <= frame.width; x += 20) {
        expect(worldY(frame, FLOOR_Y, x), `at ${x} on a ${name}`).toBeGreaterThan(
          worldY(frame, SEA_Y, x),
        );
      }
      // Deeper is tighter: a shell nearer the centre of a planet curves harder.
      expect(worldRadius(frame, FLOOR_Y)).toBeLessThan(worldRadius(frame, SEA_Y));
      expect(worldRadius(frame, SEA_Y)).toBeLessThan(worldRadius(frame, SPACE_Y));
    }
  });
});

describe('the air', () => {
  /**
   * The band between the two horizons, which used to be the page showing through.
   *
   * It is one shape rather than two half-shapes: the Karman arc forward, and the
   * sea run backwards to close it - so the bottom of the air is the identical
   * curve as the top of the water rather than a second curve that agrees with it
   * near the middle.
   *
   * That mattered when the sea was a bare circle and it matters more now that it
   * has a swell on it: two surfaces struck from one radius disagree by nothing
   * anybody can see, and two independently sampled ripples disagree by a whole
   * crest. So the check is the crests themselves - every control point of the
   * water's top edge, in reverse, is a control point of the air's bottom edge.
   */
  it('closes against the sea with that surface, run the other way', () => {
    for (const [name, frame] of FRAMES) {
      const d = worldLayerPath(frame, SPACE_Y, SEA_Y);
      expect(d.startsWith('M 0 '), name).toBe(true);
      expect(d.endsWith('Z'), name).toBe(true);
      // The air's own top is still the bare circle it always was.
      expect(d, name).toContain(`A ${worldRadius(frame, SPACE_Y).toFixed(2)}`);
      // ...and its underside is the water's top edge, backwards, crest for crest.
      const water = quads(worldFacePath(frame, SEA_Y));
      const air = quads(d);
      expect(air.length, name).toBe(water.length);
      expect(air.map((q) => q.c).reverse(), name).toEqual(water.map((q) => q.c));
      // ...ending where the water started, so the shape closes on itself.
      expect(air[air.length - 1]!.p, name).toEqual([0, Number(worldY(frame, SEA_Y, 0).toFixed(2))]);
      // ...and it is a band with something in it, not a hairline.
      expect(
        worldY(frame, SEA_Y, frame.width / 2) - worldY(frame, SPACE_Y, frame.width / 2),
      ).toBeGreaterThan(40);
    }
  });
});
