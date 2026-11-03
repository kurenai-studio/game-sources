import { describe, expect, it } from 'vitest';
import { expectFinite, FakeContext } from './canvas';
import { paintFor } from '../src/render/Paint';
import {
  OVERVIEW_FALL_AT,
  OVERVIEW_LINE_AT,
  OVERVIEW_TOTAL,
  OVERVIEW_TURN_AT,
  OVERVIEW_WHOLE_AT,
  Overview,
} from '../src/render/Overview';
import type { FilmView } from '../src/render/Films';

const W = 390;
const H = 844;

function view(rec: FakeContext, time: number): FilmView {
  return {
    ctx: rec.as2d,
    paint: paintFor(30),
    w: W,
    h: H,
    time,
    x: W * 0.5,
    y: H * 0.38,
    breath: 0.5,
    quality: 1,
  };
}

/** Runs the whole film at 60 Hz and hands back what was drawn. */
function playThrough(quality = 1): FakeContext {
  const rec = new FakeContext();
  const o = new Overview();
  o.begin();
  for (let i = 0; i * (1 / 60) <= OVERVIEW_TOTAL + 1; i++) {
    o.update(1 / 60);
    o.draw({ ...view(rec, i / 60), quality });
  }
  return rec;
}

/** One frame at an absolute time on the film's clock. */
function frameAt(t: number): FakeContext {
  const rec = new FakeContext();
  const o = new Overview();
  o.begin();
  o.update(t);
  o.draw(view(rec, t));
  return rec;
}

describe('the overview sequence', () => {
  it('does nothing at all until the act is finished', () => {
    const rec = new FakeContext();
    const o = new Overview();
    expect(o.active).toBe(false);
    expect(o.phase).toBe('idle');
    expect(o.veil).toBe(0);
    o.update(10);
    o.draw(view(rec, 0));
    expect(rec.fills + rec.strokes).toBe(0);
    expect(o.phase).toBe('idle');
  });

  it('runs arrest, turn, whole, line and fall, in that order', () => {
    const o = new Overview();
    o.begin();
    expect(o.phase).toBe('arrest');
    o.update(OVERVIEW_TURN_AT + 0.1);
    expect(o.phase).toBe('turn');
    o.update(OVERVIEW_WHOLE_AT - OVERVIEW_TURN_AT);
    expect(o.phase).toBe('whole');
    expect(o.turned).toBe(false);
    o.update(OVERVIEW_LINE_AT - OVERVIEW_WHOLE_AT);
    expect(o.phase).toBe('line');
    expect(o.turned).toBe(false);
    o.update(OVERVIEW_FALL_AT - OVERVIEW_LINE_AT);
    expect(o.phase).toBe('fall');
    expect(o.turned).toBe(true);
  });

  it('holds on its last frame instead of ending', () => {
    const o = new Overview();
    o.begin();
    o.update(OVERVIEW_TOTAL + 30);
    expect(o.phase).toBe('fall');
    const rec = new FakeContext();
    o.draw(view(rec, OVERVIEW_TOTAL + 30));
    expect(rec.fills + rec.strokes).toBeGreaterThan(0);
  });

  it('takes the frame off the live world early, monotonically, and not completely', () => {
    const o = new Overview();
    o.begin();
    let last = 0;
    for (let t = 0; t < OVERVIEW_TOTAL + 0.5; t += 0.1) {
      expect(o.veil).toBeGreaterThanOrEqual(last - 1e-9);
      expect(o.veil).toBeLessThanOrEqual(0.97 + 1e-9);
      last = o.veil;
      o.update(0.1);
    }
    // The world has to be gone before the camera moves: two frames of a tilted
    // horizon over an untilted course would show the seam.
    const o2 = new Overview();
    o2.begin();
    o2.update(OVERVIEW_TURN_AT);
    expect(o2.veil).toBeGreaterThan(0.9);
  });

  it('draws finite geometry from the first frame to the last', () => {
    expectFinite(playThrough(), 'overview full quality');
    expectFinite(playThrough(0.35), 'overview low quality');
  });

  /**
   * The one thing this film is: the camera comes off the direction of travel.
   * Nothing else in Slowblue rotates the frame, so a rotation happening at all is the
   * assertion - and so is where it stops, because a held final frame that is
   * visibly crooked reads as a bug rather than as a shot.
   */
  it('turns the camera once, and settles it', () => {
    const rec = playThrough();
    const swing = Math.max(...rec.rotations.map(Math.abs));
    expect(swing).toBeGreaterThan(0.3);
    // ...and comes back to something close to level by the held frame.
    const held = frameAt(OVERVIEW_TOTAL).rotations;
    expect(Math.abs(held[0] ?? 0)).toBeLessThan(0.2);
    // The turn is not in the first movement. The frame stops before it moves.
    expect(Math.abs(frameAt(OVERVIEW_TURN_AT * 0.5).rotations[0] ?? 0)).toBeLessThan(1e-9);
  });

  /**
   * The composition the turn exists to deliver: a horizon too big to be a shape
   * becomes a disc. Measured on the planet's own drawn radius, which starts wider
   * than two screens and has to end up fitting inside one.
   */
  it('closes the horizon into a whole Earth', () => {
    const opening = frameAt(0.1).arcs.map((a) => a.r);
    const held = frameAt(OVERVIEW_LINE_AT + 0.5).arcs.map((a) => a.r);
    const biggest = (rs: number[]): number => Math.max(...rs);
    expect(biggest(opening)).toBeGreaterThan(W * 2);
    expect(biggest(held)).toBeLessThan(Math.min(W, H) * 0.55);
    expect(biggest(held)).toBeGreaterThan(Math.min(W, H) * 0.3);
  });

  /**
   * And the fact the whole campaign has been building to: everything the game has
   * ever happened in is a line a few pixels thick. The band is drawn as the gap
   * between two radii of one radial gradient, so its thickness is measurable -
   * and it has to stay under a fortieth of the planet it is on, or the picture is
   * making a different claim than the design does.
   */
  it('draws the whole atmosphere as a line a few pixels thick', () => {
    const rec = frameAt(OVERVIEW_LINE_AT + 1);
    const planet = Math.max(...rec.arcs.map((a) => a.r));
    // The limb's gradient runs from the planet's radius to radius + air, and the
    // outer arc of the band is the largest circle in the frame.
    const air = planet - Math.max(...rec.arcs.map((a) => a.r).filter((r) => r < planet));
    expect(air).toBeGreaterThan(1.5);
    expect(air).toBeLessThan(planet / 30);
  });

  /**
   * ...and it has to be an *annulus*. A radial gradient clamps to its first stop
   * everywhere inside its inner radius, so a band filled as a disc paints the
   * whole planet the colour of the bottom of the atmosphere. That shipped for
   * exactly as long as the body's own fill happened to cover it, which stopped
   * being true on the frame the camera rotated - a bug with no symptom until an
   * unrelated change three functions away.
   */
  it('fills the atmosphere as a ring, never as a disc', () => {
    const rec = frameAt(OVERVIEW_LINE_AT + 1);
    const outer = Math.max(...rec.arcs.map((a) => a.r));
    const band = rec.arcs.find((a) => a.r === outer)!;
    // The counter-circle that makes it a ring: same centre, just inside, wound
    // the other way.
    const hole = rec.arcs.find(
      (a) => a.ccw && a.x === band.x && a.y === band.y && a.r < outer && a.r > outer * 0.9,
    );
    expect(hole, 'the atmosphere band has no hole in it').toBeDefined();
  });

  /**
   * The handover, and the campaign turning over. The gold rises for four acts and
   * this is the frame it stops: after the stall every mote is lower than it was,
   * and that is the direction act V is flown in.
   */
  it('stalls the gold at the top of its arc and brings it back down', () => {
    const gold = (t: number): number => {
      const rec = frameAt(t);
      // The motes are the small circles; the planet and its band are the huge ones.
      const small = rec.arcs.filter((a) => a.r < 6).map((a) => a.y);
      return small.reduce((s, y) => s + y, 0) / Math.max(1, small.length);
    };
    const climbing = gold(OVERVIEW_TURN_AT);
    const stall = gold(OVERVIEW_FALL_AT);
    const falling = gold(OVERVIEW_TOTAL);
    // Rising: y decreases up the screen.
    expect(stall).toBeLessThan(climbing);
    // ...and then coming back, past where they were when the camera started to turn.
    expect(falling).toBeGreaterThan(stall);
    expect(falling).toBeGreaterThan(climbing);
  });
});
