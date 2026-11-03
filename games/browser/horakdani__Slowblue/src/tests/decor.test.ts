import { describe, expect, it } from 'vitest';
import { Decor, distantPassageX } from '../src/render/Decor';
import { FakeContext } from './canvas';
import { paintFor } from '../src/render/Paint';
import { ACT_HOME } from '../src/config/homecoming';
import { ACT_AIR } from '../src/config/ascent';
import { ACT_ORBIT } from '../src/config/orbit';
import { ACT_WATER } from '../src/config/levels';
import { ACT_RAIN } from '../src/config/rain';
import { ACT_REENTRY } from '../src/config/reentry';
import { ACT_THIN } from '../src/config/thinning';
import type { DecorTheme } from '../src/config/levels';

describe('distant decorative passages', () => {
  const width = 390;
  const height = 844;
  const margin = 260;
  const extent = 180;

  it('crosses completely from one hidden edge to the other', () => {
    expect(distantPassageX(-margin, height, width, extent, 1)).toBe(-extent);
    expect(distantPassageX(height + margin, height, width, extent, 1)).toBe(width + extent);
    expect(distantPassageX(height / 2, height, width, extent, 1)).toBeCloseTo(width / 2);
  });

  it('mirrors the crossing when the silhouette travels the other way', () => {
    expect(distantPassageX(-margin, height, width, extent, -1)).toBe(width + extent);
    expect(distantPassageX(height + margin, height, width, extent, -1)).toBe(-extent);
  });
});

/**
 * Slowblue: nothing marine above the weather.
 *
 * Every decor theme in the game was a sea theme, because for two acts every
 * station was the sea - so the campaign's new acts were authored with `meadow`,
 * the default, and shipped drawing seagrass at 82 km, sea fans in orbit, and an
 * 8%-per-band chance of a leviathan crossing the frame inside a re-entry plasma
 * sheath. Each of those passed every test the game had, because no test had any
 * reason to ask what grew where.
 *
 * This is that test. It is a content assertion rather than a code one, and it is
 * the kind worth having: the failure it catches is invisible to a type checker,
 * survives a corridor sweep, and is instantly obvious to anyone who looks at the
 * screen.
 */
describe('what grows where', () => {
  /** Themes made of things that live in water. */
  const MARINE: DecorTheme[] = ['kelp', 'meadow', 'jelly', 'abyss', 'garden', 'trench'];

  it('grows nothing marine in the air, in thin air, in vacuum or in plasma', () => {
    // ACT_AIR was missing from this loop and act II declared `meadow` on all six
    // stations - seagrass, sea fans and an 8 %-per-band passing leviathan, from
    // 60 m to 11 km. Only a `medium.kind === 'air'` early-return in the renderer
    // stopped it being drawn, and a theme that is only correct because something
    // downstream refuses to read it is not correct.
    for (const act of [ACT_AIR, ACT_THIN, ACT_ORBIT, ACT_REENTRY]) {
      for (const level of act.levels) {
        expect(MARINE, `${act.key}/${level.key}`).not.toContain(level.decor);
      }
    }
  });

  it('grows nothing marine in act VI until the water is real', () => {
    // Cirrus, under the anvil and the downpour are all still sky. The canopy is a
    // forest, the brook is fresh water, and only the estuary is the sea again.
    const themes = ACT_RAIN.levels.map((l) => l.decor);
    expect(themes.slice(0, 3).every((t) => t === 'void')).toBe(true);
    expect(themes[3]).toBe('canopy');
    expect(themes[4]).toBe('stream');
    expect(themes[5]).toBe('kelp');
  });

  /**
   * ...and the campaign still ends where it started. Act VII is the sea, all of
   * it, and the last station is the trench floor act I opened on.
   */
  /**
   * Slowblue: and it has to actually be drawn, which no test had ever asked.
   *
   * `Decor` grew its bands toward -Y and pruned everything on the +Y side of the
   * camera, which is right for the four acts that climb and total for the three
   * that fall: the growth loop fails its first test, the initial bands slide
   * behind the camera, and the layer renders nothing for the rest of the act. Act
   * VII names a marine theme on all six stations and had never put one pixel of
   * one on the screen.
   *
   * The three assertions above are content assertions about theme *names*, and
   * every one of them passed throughout. A name is not a picture.
   */
  it('actually draws its life, on a falling course as well as a climbing one', () => {
    const [w, h] = [390, 844];
    for (const dir of [-1, 1] as const) {
      const decor = new Decor();
      decor.reset(1234, 'jelly', 0, dir);
      let drawn = 0;
      // 300 s at a camera rate near act VII's measured 47 px/s, in 1 s steps.
      for (let step = 0; step < 300; step++) {
        const cameraY = dir * step * 47;
        decor.update(cameraY, h, 1, 1);
        const ctx = new FakeContext();
        decor.draw(ctx as unknown as CanvasRenderingContext2D, paintFor(0), w, h, cameraY, step, 0);
        decor.draw(ctx as unknown as CanvasRenderingContext2D, paintFor(0), w, h, cameraY, step, 1);
        if (ctx.strokes + ctx.fills > 0) drawn++;
      }
      expect(drawn, `dir ${dir}: frames with anything drawn`).toBeGreaterThan(280);
    }
  });

  it('keeps the sea in the act that is the sea', () => {
    for (const level of ACT_HOME.levels) {
      expect(MARINE, `home/${level.key}`).toContain(level.decor);
    }
    expect(ACT_HOME.levels.at(-1)!.decor).toBe('trench');
    expect(ACT_WATER.levels[0]!.decor).toBe('trench');
  });
});
