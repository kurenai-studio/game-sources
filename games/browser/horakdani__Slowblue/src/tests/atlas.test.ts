import { describe, expect, it } from 'vitest';
import { ACT_COUNT, CAMPAIGN, TOTAL_STATIONS } from '../src/config/campaign';
import {
  ATLAS_LINKS,
  CIRCUIT_ACTS,
  CIRCUIT_ATLAS,
  MAP_H,
  MAP_W,
  ROUTE_LENGTH,
  SEA_Y,
  SPACE_Y,
  STOP_STEP,
  actFlownTo,
  actsCleared,
  clearedIn,
  entryOf,
  linkArrow,
  linkFlown,
  routeCurve,
  routeHeading,
  routePoint,
  seaCrestY,
  swellRise,
  worldBandPath,
  worldFacePath,
  worldRadius,
  worldY,
  stationCleared,
  stationsCleared,
  type WorldFrame,
} from '../src/meta/Circuit';

/**
 * Slowblue: the shape of the circuit, asserted rather than looked at.
 *
 * The claim the campaign makes about itself - "you did not go up, you went round"
 * - is a claim about forty-two numbers, and the line that draws it makes two more
 * on top: that the route closes, and that the way home mirrors the way out. All
 * three are checkable. `meta/Circuit.ts` is deliberately DOM-free so that this
 * file can check them: the shell draws SVG out of the same box a test reads.
 *
 * What is asserted here is the shape, not the pixels. A line that is right by
 * these properties is a line of this campaign; one that is wrong by any of them
 * is a line of a different game.
 */

/** Every station's altitude, in play order. Positive is above the sea. */
const ALTITUDES = CAMPAIGN.flatMap((info) => info.act.levels.map((l) => -l.depthMeters));

/**
 * The shortest the map is ever drawn, in CSS pixels. Written here rather than
 * read, because a test that measures nothing is the only kind this file can be -
 * but a target that is big enough in atlas units and too small on a short phone
 * is not big enough.
 *
 * The picture no longer takes a share of the window; it takes whatever the
 * heading, the count, the act and the buttons leave, so that the screen ends
 * where the window does. What stops that from shrinking it to nothing is
 * `.ui-map`'s `min-height`, and this is that number: below it the map keeps this
 * size and the screen scrolls instead. The two are one decision written in two
 * files - the assertion below is what picked it, and moving one without the
 * other is what this comment exists to stop.
 */
const MAP_FLOOR_PX = 344;

describe('the route', () => {
  it('closes: once round is back where it started', () => {
    const start = routePoint(0);
    const round = routePoint(ROUTE_LENGTH);
    expect(round.x).toBeCloseTo(start.x, 9);
    expect(round.y).toBeCloseTo(start.y, 9);
    // ...and it is continuous the whole way, corners included.
    let last = routePoint(0);
    for (let t = 1; t <= ROUTE_LENGTH; t += 1) {
      const p = routePoint(t);
      expect(Math.hypot(p.x - last.x, p.y - last.y), `at ${t}`).toBeLessThan(1.4);
      last = p;
    }
  });

  /**
   * The gutters, as the two numbers the type actually needs.
   *
   * A name is set thirteen units tall and its altitudes nine and a half, twelve
   * units clear of the line, with four left at the edge of the box - and at
   * those sizes the longest thing on the left ("III · 11 → 100 KM") wants a
   * hundred and eleven units of gutter and the longest on the right ("The
   * Homecoming") a hundred and thirty-one. Asserted rather than eyeballed
   * because the box is only as wide as it is *for* the names: shrink a gutter
   * and the picture goes back to being unreadable in exactly the way it was.
   */
  const LEFT_GUTTER = 111;
  const RIGHT_GUTTER = 131;

  it('stays inside the box it says it is in, with room for the names', () => {
    for (let t = 0; t < ROUTE_LENGTH; t += 2) {
      const p = routePoint(t);
      expect(p.x, `at ${t}`).toBeGreaterThanOrEqual(LEFT_GUTTER);
      expect(p.x, `at ${t}`).toBeLessThanOrEqual(MAP_W - RIGHT_GUTTER);
      expect(p.y, `at ${t}`).toBeGreaterThan(40);
      expect(p.y, `at ${t}`).toBeLessThan(MAP_H - 30);
    }
  });

  /**
   * Up the left, across the top, down the right, home along the bottom. That is
   * the whole reason this shape was chosen over any other closed one: it keeps
   * up being up, so the trench floor is at the bottom of the picture and orbit
   * is across the top of it without a word being written.
   */
  it('climbs one side, crosses the top and comes down the other', () => {
    const quarter = ROUTE_LENGTH / 4;
    const low = routePoint(0);
    const climbing = routePoint(quarter * 0.5);
    const top = routePoint(quarter * 1.5);
    const falling = routePoint(quarter * 2.5);
    expect(climbing.y).toBeLessThan(low.y);
    expect(top.y).toBeLessThan(climbing.y);
    expect(falling.y).toBeGreaterThan(top.y);
    // The two sides are the two sides.
    expect(climbing.x).toBeLessThan(MAP_W / 2);
    expect(falling.x).toBeGreaterThan(MAP_W / 2);
  });

  it('draws a stretch of itself as a curve that starts and ends where asked', () => {
    const leg = routeCurve(40, 200);
    expect(leg.length).toBeGreaterThan(2);
    expect(leg[0].x).toBeCloseTo(routePoint(40).x, 9);
    expect(leg[0].y).toBeCloseTo(routePoint(40).y, 9);
    expect(leg[leg.length - 1].y).toBeCloseTo(routePoint(200).y, 9);
    // Sampled finely enough that a corner is a corner and not a chord.
    for (let i = 1; i < leg.length; i++) {
      expect(Math.hypot(leg[i].x - leg[i - 1].x, leg[i].y - leg[i - 1].y)).toBeLessThan(5);
    }
  });
});

describe('the forty-two stops', () => {
  it('places one per authored station, in play order', () => {
    expect(CIRCUIT_ATLAS).toHaveLength(TOTAL_STATIONS);
    let i = 0;
    for (let act = 0; act < ACT_COUNT; act++) {
      const levels = CAMPAIGN[act].act.levels;
      for (let station = 0; station < levels.length; station++, i++) {
        const p = CIRCUIT_ATLAS[i];
        expect(p.act, `stop ${i}`).toBe(act);
        expect(p.station, `stop ${i}`).toBe(station);
        expect(p.index, `stop ${i}`).toBe(i);
        expect(p.key, `stop ${i}`).toBe(levels[station].key);
        expect(p.depthMeters, `stop ${i}`).toBe(levels[station].depthMeters);
      }
    }
  });

  /**
   * One interval, everywhere. A line whose stops bunch on the corners and spread
   * on the straights is a line that looks like it means something by it, and this
   * one does not - every station is one station.
   */
  it('spaces every stop of a run the same distance from the next', () => {
    for (const band of CIRCUIT_ACTS) {
      const stops = CIRCUIT_ATLAS.filter((p) => p.act === band.act);
      for (let i = 1; i < stops.length; i++) {
        expect(stops[i].t - stops[i - 1].t, `${stops[i - 1].key} → ${stops[i].key}`).toBeCloseTo(
          STOP_STEP,
          9,
        );
      }
    }
    // ...and they go round in order, once, without ever doubling back.
    for (let i = 1; i < CIRCUIT_ATLAS.length; i++) {
      expect(CIRCUIT_ATLAS[i].t, `stop ${i}`).toBeGreaterThan(CIRCUIT_ATLAS[i - 1].t);
    }
    expect(CIRCUIT_ATLAS[CIRCUIT_ATLAS.length - 1].t).toBeLessThan(ROUTE_LENGTH);
  });

  /**
   * ...and every act is set down away from the next one, which is the difference
   * between a line with seven services on it and a line with forty-two stations
   * on it. The seam is wider than an ordinary interval everywhere, corners
   * included - the bends are wider still, and they are the boundaries this file
   * never has to space by hand.
   */
  it('leaves a gap where one act hands over to the next', () => {
    for (let act = 1; act < ACT_COUNT; act++) {
      const before = CIRCUIT_ACTS[act - 1];
      const after = CIRCUIT_ACTS[act];
      const seam = after.from - before.to;
      expect(seam, `act ${act} → ${act + 1}`).toBeGreaterThan(STOP_STEP * 1.9);
    }
    // The closing seam is the widest of the lot: it is the whole bottom of the
    // picture, and act VII's last stop and act I's first are the same water.
    const closing = ROUTE_LENGTH - CIRCUIT_ACTS[ACT_COUNT - 1].to + CIRCUIT_ACTS[0].from;
    expect(closing).toBeGreaterThan(STOP_STEP * 1.9);
  });

  it('never lets two stops land on top of each other', () => {
    for (let i = 1; i < CIRCUIT_ATLAS.length; i++) {
      const a = routePoint(CIRCUIT_ATLAS[i - 1].t);
      const b = routePoint(CIRCUIT_ATLAS[i].t);
      expect(
        Math.hypot(a.x - b.x, a.y - b.y),
        `${CIRCUIT_ATLAS[i - 1].key} → ${CIRCUIT_ATLAS[i].key}`,
      ).toBeGreaterThan(11);
    }
  });

  /**
   * The campaign is a palindrome and the shape says so: act I and act VII stand
   * at the same height on opposite sides of the picture, and so do II and VI, and
   * III and V. Nothing tells the map this - it falls out of eighteen stops up one
   * side and eighteen down the other at one interval.
   */
  it('stands the way home level with the way out, act for act', () => {
    for (let act = 0; act < 3; act++) {
      const out = CIRCUIT_ATLAS.filter((p) => p.act === act);
      const home = CIRCUIT_ATLAS.filter((p) => p.act === ACT_COUNT - 1 - act);
      expect(home).toHaveLength(out.length);
      for (let i = 0; i < out.length; i++) {
        const a = routePoint(out[i].t);
        const b = routePoint(home[out.length - 1 - i].t);
        expect(b.y, `act ${act + 1} station ${i + 1}`).toBeCloseTo(a.y, 6);
        expect(a.x).toBeLessThan(MAP_W / 2);
        expect(b.x).toBeGreaterThan(MAP_W / 2);
      }
    }
    // ...and the turn is on its own, across the top.
    const highest = ALTITUDES.indexOf(Math.max(...ALTITUDES));
    expect(CIRCUIT_ATLAS[highest].act).toBe(3);
    for (const p of CIRCUIT_ATLAS.filter((s) => s.act === 3)) {
      expect(routePoint(p.t).y, p.key).toBeLessThan(routePoint(CIRCUIT_ATLAS[0].t).y);
    }
  });

  /**
   * The two ends of the journey are the same trench floor, six thousand metres
   * down. On the line they are the two stops either side of the bottom, and the
   * stretch between them is the circuit closing.
   */
  it('brings the last stop back alongside the first', () => {
    const first = CIRCUIT_ATLAS[0];
    const last = CIRCUIT_ATLAS[CIRCUIT_ATLAS.length - 1];
    expect(ALTITUDES[last.index]).toBe(ALTITUDES[0]);
    const a = routePoint(first.t);
    const b = routePoint(last.t);
    expect(b.y).toBeCloseTo(a.y, 6);
    expect(a.x).toBeLessThan(MAP_W / 2);
    expect(b.x).toBeGreaterThan(MAP_W / 2);
    // ...and the last link runs between exactly those two, the long way round
    // the bottom rather than back up the way it came.
    const closing = ATLAS_LINKS[ATLAS_LINKS.length - 1];
    expect(closing.closes).toBe(true);
    expect(closing.fromT).toBeCloseTo(last.t, 9);
    expect(closing.toT).toBeCloseTo(first.t + ROUTE_LENGTH, 9);
  });
});

/**
 * Which way round it goes, which is the one thing a closed line cannot say by
 * being closed. The order of the acts says it, but only to somebody who already
 * knows the acts - so the seams are arrowed, and what is asserted here is that
 * the seven arrows agree with the line they are drawn on, land on empty line,
 * and go round the same way.
 */
describe('the way round', () => {
  /** The wrapped difference between two headings, in degrees. */
  const apart = (a: number, b: number): number => ((a - b + 540) % 360) - 180;
  const arrows = ATLAS_LINKS.map((link) => linkArrow(link));

  it('points the way the line is actually travelling', () => {
    for (const [i, link] of ATLAS_LINKS.entries()) {
      const t = (link.fromT + link.toT) / 2;
      const here = routePoint(t);
      const on = routePoint(t + 8);
      // The arrow is where the route is, and pointing the way the next eight
      // units of it go - not the way it came, which is the only way to get this
      // wrong and the only one worth checking.
      expect(arrows[i].x, `link ${i}`).toBeCloseTo(here.x, 9);
      expect(arrows[i].y, `link ${i}`).toBeCloseTo(here.y, 9);
      const walked = (Math.atan2(on.y - here.y, on.x - here.x) * 180) / Math.PI;
      expect(Math.abs(apart(arrows[i].angle, walked)), `link ${i}`).toBeLessThan(12);
    }
  });

  /**
   * An arrow sits in the gap a seam already is - a stop's width and a whole act
   * gap of clear line either side of it - so nothing had to be moved to make
   * room, and no stop is ever drawn under one.
   */
  it('lands on empty line, never on a stop', () => {
    for (const [i, arrow] of arrows.entries()) {
      for (const p of CIRCUIT_ATLAS) {
        const q = routePoint(p.t);
        expect(Math.hypot(arrow.x - q.x, arrow.y - q.y), `link ${i} on ${p.key}`).toBeGreaterThan(
          14,
        );
      }
    }
  });

  /**
   * Up the left, across the top, down the right, and back along the bottom -
   * the journey the campaign describes, read off the picture in degrees. `y`
   * grows downward, so up the screen is a negative angle.
   */
  it('climbs one side, crosses the top and comes home along the bottom', () => {
    expect(routeHeading(CIRCUIT_ACTS[1].from)).toBeCloseTo(-90, 0);
    expect(routeHeading(CIRCUIT_ACTS[3].from)).toBeCloseTo(0, 0);
    expect(routeHeading(CIRCUIT_ACTS[5].from)).toBeCloseTo(90, 0);
    const closing = arrows[arrows.length - 1];
    expect(Math.abs(closing.angle)).toBeCloseTo(180, 0);
    // The closing arrow is at the bottom of the picture and midway between the
    // route's two rails - which is not the middle of the box, because the route
    // stands left of that to leave the long names their room.
    const rails = [CIRCUIT_ATLAS[0], CIRCUIT_ATLAS[CIRCUIT_ATLAS.length - 1]];
    expect(closing.x).toBeCloseTo((routePoint(rails[0].t).x + routePoint(rails[1].t).x) / 2, 6);
    expect(closing.y).toBeGreaterThan(MAP_H - 60);
  });

  /**
   * ...and it only ever turns one way. Once round the route is one whole turn,
   * which is the property that makes seven arrows a direction rather than seven
   * opinions: a line that doubled back would still be closed and would still be
   * arrowed, and would sum to something other than a circle.
   */
  it('turns through exactly one circle, and never back on itself', () => {
    // Sampled over exactly one lap rather than in whole units, because the route
    // is not a whole number of units long and the last step of it is the one
    // that closes the circle.
    const STEPS = 2000;
    let total = 0;
    let last = routeHeading(0);
    for (let i = 1; i <= STEPS; i++) {
      const now = routeHeading((ROUTE_LENGTH * i) / STEPS);
      const step = apart(now, last);
      expect(step, `at ${i}/${STEPS}`).toBeGreaterThanOrEqual(-0.001);
      total += step;
      last = now;
    }
    expect(total).toBeCloseTo(360, 0);
  });
});

/**
 * The world the line is drawn on: the sea, and the top of the air.
 *
 * Both are drawn as arcs and neither is labelled, so what says which act is
 * where is the geometry - and the geometry is checkable. What is asserted is
 * that each surface falls where the campaign crosses it, that the two of them
 * are skins of one planet rather than two curves that happen to be near each
 * other, and that they curve at all.
 */
describe('the world behind the line', () => {
  const UNDERWATER = [0, ACT_COUNT - 1];

  it('puts the waterline where the route leaves the water, on both sides', () => {
    // Act I ends at the surface and act II starts there; the same handover comes
    // back the other way between act VI and act VII. The line falls in the gap
    // between those stops - not on one of them, which would be a stop drawn
    // half in the water.
    for (const [below, above] of [
      [0, 1],
      [ACT_COUNT - 1, ACT_COUNT - 2],
    ]) {
      const wet = CIRCUIT_ATLAS.filter((p) => p.act === below).map((p) => routePoint(p.t).y);
      const dry = CIRCUIT_ATLAS.filter((p) => p.act === above).map((p) => routePoint(p.t).y);
      expect(Math.min(...wet), `act ${below + 1}`).toBeGreaterThan(SEA_Y);
      expect(Math.max(...dry), `act ${above + 1}`).toBeLessThan(SEA_Y);
    }
  });

  it('leaves exactly two acts under the water and one above the air', () => {
    for (const p of CIRCUIT_ATLAS) {
      const y = routePoint(p.t).y;
      const wet = UNDERWATER.includes(p.act);
      expect(y > SEA_Y, `${p.key} in the water`).toBe(wet);
      expect(y < SPACE_Y, `${p.key} outside the air`).toBe(p.act === 3);
    }
    // ...and the two surfaces are the right way up about each other.
    expect(SPACE_Y).toBeLessThan(SEA_Y);
  });

  /**
   * Two screens to check the world on, because it is drawn in whatever pixels
   * the browser gave the map rather than in the box units everything above is
   * in. A phone, where the map is nearly the whole screen, and a desktop, where
   * it is a column in the middle of a wide one - the two cases the frame has to
   * put the same horizon on.
   */
  const PHONE: WorldFrame = { scale: 0.99, x: 4, y: 84, width: 390, height: 844 };
  const DESKTOP: WorldFrame = { scale: 1.07, x: 514, y: 120, width: 1440, height: 900 };

  /** Every `Q` of a path, as the control point it leans on and the node it ends on. */
  const quads = (d: string): { c: [number, number]; p: [number, number] }[] =>
    [...d.matchAll(/Q (-?[\d.]+) (-?[\d.]+) (-?[\d.]+) (-?[\d.]+)/g)].map((m) => ({
      c: [Number(m[1]), Number(m[2])],
      p: [Number(m[3]), Number(m[4])],
    }));

  it('crosses the rails exactly where the campaign crosses the surface', () => {
    for (const frame of [PHONE, DESKTOP]) {
      for (const railY of [SEA_Y, SPACE_Y]) {
        // The two rails are the two places the arc has to be right: everywhere
        // else it is behind names and empty page.
        for (const p of [CIRCUIT_ATLAS[0], CIRCUIT_ATLAS[CIRCUIT_ATLAS.length - 1]]) {
          const rail = frame.x + routePoint(p.t).x * frame.scale;
          expect(worldY(frame, railY, rail)).toBeCloseTo(frame.y + railY * frame.scale, 6);
        }
      }
    }
  });

  it('curves by the same share of the screen, however wide the screen is', () => {
    for (const frame of [PHONE, DESKTOP]) {
      const sea = (x: number): number => worldY(frame, SEA_Y, x);
      /*
       * The top of the arc, found rather than assumed. It stands over the middle
       * of the route's two rails, which is near the middle of the screen and not
       * on it - the route sits left of centre in its own box, because the names
       * on the right are the long ones - and a sag measured from the middle of
       * the *screen* would be measuring that offset as well as the curve.
       */
      let apex = 0;
      for (let x = 0; x <= frame.width; x += 0.5) if (sea(x) < sea(apex)) apex = x;
      expect(sea(0)).toBeGreaterThan(sea(apex));
      expect(sea(frame.width)).toBeGreaterThan(sea(apex));
      // Six per cent of the width it has to cross, wherever the map sits in it.
      expect((sea(apex + frame.width / 2) - sea(apex)) / frame.width).toBeCloseTo(0.06, 2);
    }
  });

  it('strikes both surfaces from one centre', () => {
    for (const frame of [PHONE, DESKTOP]) {
      const centre = (railY: number): { x: number; y: number } => {
        // Through three points of the arc, which is all a circle needs.
        const p = [0, frame.width / 2, frame.width].map((x) => ({ x, y: worldY(frame, railY, x) }));
        const d =
          2 *
          (p[0].x * (p[1].y - p[2].y) + p[1].x * (p[2].y - p[0].y) + p[2].x * (p[0].y - p[1].y));
        const sq = (q: { x: number; y: number }): number => q.x * q.x + q.y * q.y;
        return {
          x:
            (sq(p[0]) * (p[1].y - p[2].y) +
              sq(p[1]) * (p[2].y - p[0].y) +
              sq(p[2]) * (p[0].y - p[1].y)) /
            d,
          y:
            (sq(p[0]) * (p[2].x - p[1].x) +
              sq(p[1]) * (p[0].x - p[2].x) +
              sq(p[2]) * (p[1].x - p[0].x)) /
            d,
        };
      };
      const sea = centre(SEA_Y);
      const space = centre(SPACE_Y);
      expect(space.x).toBeCloseTo(sea.x, 4);
      expect(space.y).toBeCloseTo(sea.y, 4);
      // ...and the centre is off the bottom of the screen, where a planet's would
      // have to be for its surface to look like this one.
      expect(sea.y).toBeGreaterThan(frame.height);
      // The air between the two never closes up.
      for (let x = 0; x <= frame.width; x += 20) {
        expect(worldY(frame, SEA_Y, x) - worldY(frame, SPACE_Y, x), `at ${x}`).toBeGreaterThan(0);
      }
    }
  });

  it('draws each surface across the whole screen, and each band off the edge of it', () => {
    for (const frame of [PHONE, DESKTOP]) {
      for (const [railY, edge] of [
        [SEA_Y, frame.height],
        [SPACE_Y, 0],
      ]) {
        const face = worldFacePath(frame, railY);
        // Edge to edge: a world that starts inside the screen has a frame.
        expect(face.startsWith('M 0 ')).toBe(true);
        expect(face).toContain(` ${frame.width.toFixed(2)} `);
        // The band is the face and nothing but the face, closed against the edge
        // of the screen the world is on that side of.
        expect(worldBandPath(frame, railY, edge)).toBe(
          `${face} L ${frame.width.toFixed(2)} ${edge} L 0 ${edge} Z`,
        );
      }
      // The top of the air is the bare circle it has always been: one arc of the
      // right radius, and nothing sampled.
      const karman = worldFacePath(frame, SPACE_Y);
      expect(karman).toContain(`A ${worldRadius(frame, SPACE_Y).toFixed(2)}`);
      expect(karman).not.toContain('Q ');
    }
  });

  /**
   * ...and the sea is that circle with a swell on it, which is the one surface
   * here that is a substance rather than an agreement.
   *
   * Three claims, and the third is the one that would fail silently. A swell
   * drawn too big stops being a texture on a horizon and becomes a drawing of
   * waves behind a map that has forty-two stops to protect; and a swell whose
   * crests are not exactly on the circle is a sea that has quietly changed
   * height, which every other number in this file is struck against.
   */
  it('puts a swell on the sea and on nothing else', () => {
    for (const frame of [PHONE, DESKTOP]) {
      const d = worldFacePath(frame, SEA_Y);
      expect(d).not.toContain('A ');
      const seg = quads(d);
      expect(seg.length).toBeGreaterThan(8);
      const rise = swellRise(frame);
      // Small: about a pixel, and never a shape.
      expect(rise).toBeGreaterThan(0.5);
      expect(rise).toBeLessThan(2);
      let from: [number, number] = [0, worldY(frame, SEA_Y, 0)];
      for (const [i, q] of seg.entries()) {
        // Every node the swell passes through is on the mean surface, so the sea
        // is still standing at the height the rest of this file struck it at...
        expect(q.p[1], `node ${i}`).toBeCloseTo(worldY(frame, SEA_Y, q.p[0]), 1);
        // ...the run only ever goes forward, and reaches the far edge...
        expect(q.p[0], `node ${i}`).toBeGreaterThan(from[0]);
        /*
         * ...and a crest tops out exactly on the line anything floating is put
         * on. A quadratic reaches half way to its control point, which is the
         * whole reason the control sits at twice the rise - and it is the join
         * between this file's drawing and `Habitat`'s placement: if the two ever
         * disagree, the sea is being drawn through the boat resting on it.
         */
        const mid = (from[0] + q.p[0]) / 2;
        const apex = 0.25 * from[1] + 0.5 * q.c[1] + 0.25 * q.p[1];
        const mean = worldY(frame, SEA_Y, mid);
        const want = i % 2 === 0 ? seaCrestY(frame, mid) : 2 * mean - seaCrestY(frame, mid);
        expect(apex, `${i % 2 === 0 ? 'crest' : 'trough'} ${i}`).toBeCloseTo(want, 1);
        from = q.p;
      }
      expect(from[0]).toBeCloseTo(frame.width, 1);
    }
  });
});

describe('the seven acts', () => {
  it('gives every act its own stretch, in order, and nothing to nobody', () => {
    expect(CIRCUIT_ACTS).toHaveLength(ACT_COUNT);
    for (const band of CIRCUIT_ACTS) {
      expect(band.count).toBe(CAMPAIGN[band.act].act.levels.length);
      expect(band.to, `act ${band.act}`).toBeGreaterThan(band.from);
      expect(band.from).toBeCloseTo(CIRCUIT_ATLAS[band.first].t, 9);
      expect(band.to).toBeCloseTo(CIRCUIT_ATLAS[band.first + band.count - 1].t, 9);
      // Its name is set beside the line, never over it.
      expect(band.range.length, `act ${band.act}`).toBeGreaterThan(0);
      if (band.side === -1) expect(band.labelX).toBeLessThan(routePoint(band.from).x);
      if (band.side === 1) expect(band.labelX).toBeGreaterThan(routePoint(band.from).x);
      if (band.side === 0) expect(band.labelY).toBeLessThan(routePoint(band.from).y);
    }
    // Three acts up, one across, three down.
    expect(CIRCUIT_ACTS.filter((b) => b.side === -1)).toHaveLength(3);
    expect(CIRCUIT_ACTS.filter((b) => b.side === 0)).toHaveLength(1);
    expect(CIRCUIT_ACTS.filter((b) => b.side === 1)).toHaveLength(3);
  });

  /**
   * The map is the act select, so every act needs a piece of the picture that is
   * unambiguously its own: one that holds its stops and its name, that no other
   * act reaches into, and that is big enough for a thumb rather than a cursor.
   */
  it('gives every act a target of its own, and no two the same ground', () => {
    for (const band of CIRCUIT_ACTS) {
      const { x, y, w, h } = band.hit;
      // Inside the picture...
      expect(x, `act ${band.act}`).toBeGreaterThanOrEqual(0);
      expect(y, `act ${band.act}`).toBeGreaterThanOrEqual(0);
      expect(x + w, `act ${band.act}`).toBeLessThanOrEqual(MAP_W);
      expect(y + h, `act ${band.act}`).toBeLessThanOrEqual(MAP_H);
      // ...and a real target at the smallest size the picture is ever drawn.
      // Forty-four CSS pixels is the floor a control is allowed to be, and the
      // atlas box is a `384 / 480` frame drawn no shorter than `MAP_FLOOR_PX`.
      expect(Math.min(w, h) * (MAP_FLOOR_PX / MAP_H), `act ${band.act}`).toBeGreaterThanOrEqual(44);

      // It holds every stop of its own act...
      for (const p of CIRCUIT_ATLAS.filter((s) => s.act === band.act)) {
        const q = routePoint(p.t);
        expect(q.x, p.key).toBeGreaterThanOrEqual(x);
        expect(q.x, p.key).toBeLessThanOrEqual(x + w);
        expect(q.y, p.key).toBeGreaterThanOrEqual(y);
        expect(q.y, p.key).toBeLessThanOrEqual(y + h);
      }
      // ...and the line its name is set on.
      expect(band.labelY, `act ${band.act}`).toBeGreaterThanOrEqual(y);
      expect(band.labelY, `act ${band.act}`).toBeLessThanOrEqual(y + h);
    }

    // No two of the seven overlap: a thumb aimed at act II never lands in act I.
    for (let a = 0; a < ACT_COUNT; a++) {
      for (let b = a + 1; b < ACT_COUNT; b++) {
        const p = CIRCUIT_ACTS[a].hit;
        const q = CIRCUIT_ACTS[b].hit;
        const apart = p.x + p.w <= q.x || q.x + q.w <= p.x || p.y + p.h <= q.y || q.y + q.h <= p.y;
        expect(apart, `act ${a + 1} overlaps act ${b + 1}`).toBe(true);
      }
    }
  });

  it('prints how far each act reaches, in one unit', () => {
    const ranges = CIRCUIT_ACTS.map((b) => b.range);
    expect(ranges[0]).toBe('6000 → 0 M');
    expect(ranges[2]).toBe('11 → 100 KM');
    expect(ranges[3]).toBe('140 → 460 KM');
    expect(ranges[6]).toBe('20 → 6000 M');
    for (const range of ranges) expect(range).toMatch(/^\d+ → \d+ (M|KM)$/);
  });

  it('links every act to the next, and the last one back to the first', () => {
    expect(ATLAS_LINKS).toHaveLength(ACT_COUNT);
    ATLAS_LINKS.forEach((link, i) => {
      expect(link.from).toBe(i);
      expect(link.to).toBe((i + 1) % ACT_COUNT);
      expect(link.toT, `link ${i}`).toBeGreaterThan(link.fromT);
      expect(link.closes).toBe(i === ACT_COUNT - 1);
    });
  });

  it('rings the stop each act is entered at', () => {
    for (const band of CIRCUIT_ACTS) {
      const entry = entryOf(band.act);
      expect(entry).toBe(CIRCUIT_ATLAS[band.first]);
      expect(entry?.station).toBe(0);
      // The link into an act lands on exactly that stop.
      const link = ATLAS_LINKS.find((l) => l.to === band.act);
      expect(link).toBeDefined();
      expect((link as { toT: number }).toT % ROUTE_LENGTH).toBeCloseTo(entry?.t as number, 6);
    }
    expect(entryOf(99)).toBeUndefined();
  });
});

describe('what is behind you', () => {
  const full = Object.fromEntries(CAMPAIGN.map((i) => [i.act.key, i.act.levels.length]));

  it('counts stations and acts out of the whole circuit', () => {
    expect(stationsCleared({})).toBe(0);
    expect(actsCleared({})).toBe(0);
    expect(stationsCleared(full)).toBe(TOTAL_STATIONS);
    expect(actsCleared(full)).toBe(ACT_COUNT);

    const partial = { water: 6, air: 3 };
    expect(stationsCleared(partial)).toBe(9);
    // Three of six is not an act.
    expect(actsCleared(partial)).toBe(1);
  });

  it('lights exactly the stations that were cleared, and no others', () => {
    const stations = { air: 3 };
    const lit = CIRCUIT_ATLAS.filter((p) => stationCleared(stations, p));
    expect(lit).toHaveLength(3);
    for (const p of lit) {
      expect(p.act).toBe(1);
      expect(p.station).toBeLessThan(3);
    }
  });

  /**
   * The lit run stops at the stop the player reached, because the stop is the
   * claim: that is where they got to.
   */
  it('draws the flown part of an act up to the station it reached', () => {
    const band = CIRCUIT_ACTS[1];
    expect(actFlownTo({}, 1)).toBeNull();
    expect(actFlownTo({ air: 1 }, 1)).toBeCloseTo(CIRCUIT_ATLAS[band.first].t, 9);
    expect(actFlownTo({ air: 3 }, 1)).toBeCloseTo(CIRCUIT_ATLAS[band.first + 2].t, 9);
    expect(actFlownTo({ air: band.count }, 1)).toBeCloseTo(band.to, 9);
    // Never outside the stretch it belongs to, whatever the record says.
    for (let done = 1; done <= band.count; done++) {
      const to = actFlownTo({ air: done }, 1) as number;
      expect(to, `${done} cleared`).toBeGreaterThanOrEqual(band.from);
      expect(to, `${done} cleared`).toBeLessThanOrEqual(band.to);
    }
    expect(actFlownTo({ air: 99 }, 1)).toBeCloseTo(band.to, 9);
    expect(actFlownTo({}, 99)).toBeNull();
  });

  /**
   * A link is earned by finishing the act it leads out of - and the last link is
   * the bottom of the map, so nothing lights it until somebody has been all the
   * way round.
   */
  it('lights a link only once the act behind it is finished', () => {
    const first = ATLAS_LINKS[0];
    expect(linkFlown({}, first)).toBe(false);
    expect(linkFlown({ water: 5 }, first)).toBe(false);
    expect(linkFlown({ water: 6 }, first)).toBe(true);

    const closing = ATLAS_LINKS[ATLAS_LINKS.length - 1];
    expect(linkFlown({ water: 6, air: 6 }, closing)).toBe(false);
    expect(linkFlown(full, closing)).toBe(true);
  });

  /** A stored record is data from disk, so nothing here may be trusted as read. */
  it('clamps a record that has been edited, corrupted or outgrown', () => {
    expect(clearedIn({ water: 99 }, 0)).toBe(CAMPAIGN[0].act.levels.length);
    expect(clearedIn({ water: -4 }, 0)).toBe(0);
    expect(clearedIn({ water: 2.9 }, 0)).toBe(2);
    expect(clearedIn({ water: Number.NaN }, 0)).toBe(0);
    expect(clearedIn({}, 0)).toBe(0);
    // An act that no longer exists is not an act.
    expect(clearedIn({ gone: 6 }, 99)).toBe(0);
    expect(stationsCleared({ gone: 6 })).toBe(0);
  });
});
