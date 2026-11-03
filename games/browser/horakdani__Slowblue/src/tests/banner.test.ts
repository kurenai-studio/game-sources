import { describe, expect, it } from 'vitest';
import { expectFinite, FakeContext } from './canvas';
import { CAMPAIGN_ACTS } from '../src/config/campaign';
import { stationDepthLabel } from '../src/config/levels';
import { BANNER_LIFE, drawBanner, type BannerView } from '../src/render/Banner';

/**
 * Slowblue: the station banner, which nothing had ever looked at.
 *
 * It is the only text in the game painted on the canvas rather than laid out by
 * the shell - every station title, every depth, and the sentence that closes the
 * circuit - and it lived inside `Renderer`, which no test can construct without
 * a real canvas. Pulled out into its own module, it is a pure function of a view
 * object, and these are the assertions that could never be made while it was not.
 */

const W = 390;
const H = 844;

/** Act I's first station and act VII's last, which is the pair that bookends everything. */
const WATER = CAMPAIGN_ACTS[0]!;
const HOME = CAMPAIGN_ACTS[CAMPAIGN_ACTS.length - 1]!;

function view(rec: FakeContext, over: Partial<BannerView> = {}): BannerView {
  return {
    ctx: rec.as2d,
    w: W,
    h: H,
    levels: WATER.levels,
    index: 0,
    // Two seconds in: fully faded up, and nowhere near the fade out.
    life: BANNER_LIFE - 2,
    final: false,
    dark: false,
    ...over,
  };
}

function shoot(over: Partial<BannerView> = {}): FakeContext {
  const rec = new FakeContext();
  drawBanner(view(rec, over));
  return rec;
}

/** The alpha out of an `rgba(r,g,b,a)` string. */
function alphaOf(style: string): number {
  const m = /rgba\([^)]*,\s*([\d.]+)\)/.exec(style);
  expect(m, `not an rgba colour: ${style}`).not.toBeNull();
  return Number(m![1]);
}

/** Every line the banner filled, in the order it drew them. */
function inked(rec: FakeContext): { text: string; alpha: number }[] {
  return rec.texts.filter((t) => !t.stroked).map((t) => ({ text: t.text, alpha: alphaOf(t.style) }));
}

describe('the station banner', () => {
  it('names the station, the depth and the line under it', () => {
    const rec = shoot();
    const said = inked(rec).map((t) => t.text);
    expect(said).toEqual([
      `STATION 1 / ${WATER.levels.length}`,
      WATER.levels[0]!.name.toUpperCase(),
      // Through the same function rather than a literal: the digit grouping is
      // the runtime's, and `tests/levels.test.ts` is where the label's own shape
      // - the range form act VI and act VII got wrong - is asserted.
      stationDepthLabel(WATER.levels, 0),
      WATER.levels[0]!.subtitle,
    ]);
    expect(said[2]).toContain('6');
    expectFinite(rec, 'banner');
  });


  /**
   * The lie told six times, from the other side. `finale` is what decides this
   * and it is asserted in `tests/circuit.test.ts`; what is asserted here is only
   * that the banner really has two eyebrows and prints the one it is given.
   */
  it('closes an act rather than opening a station when it is final', () => {
    expect(inked(shoot({ final: true }))[0]!.text).toBe('MISSION COMPLETE');
  });

  it('fades up and away rather than arriving', () => {
    const opening = inked(shoot({ life: BANNER_LIFE }));
    expect(opening).toEqual([]);
    const landing = inked(shoot({ life: BANNER_LIFE - 0.3 }));
    const up = inked(shoot());
    const leaving = inked(shoot({ life: 0.5 }));
    for (let i = 0; i < up.length; i++) {
      expect(landing[i]!.alpha, 'still arriving').toBeLessThan(up[i]!.alpha);
      expect(leaving[i]!.alpha, 'already leaving').toBeLessThan(up[i]!.alpha);
    }
  });

  /**
   * The banner is drawn last, over a frame somebody else built, so it has to
   * hand the context back the way it found it. A left-aligned HUD drawn through
   * a centred context is the kind of thing that only shows up one act later.
   */
  it('leaves the context as it found it', () => {
    const rec = new FakeContext();
    rec.lineJoin = 'bevel';
    drawBanner(view(rec));
    expect([rec.textAlign, rec.textBaseline, rec.lineJoin]).toEqual(['left', 'top', 'bevel']);
  });

  /** Every station of every act: nothing draws a `NaN` or an `undefined`. */
  it('draws every station of all seven acts', () => {
    for (const act of CAMPAIGN_ACTS) {
      for (let i = 0; i < act.levels.length; i++) {
        const rec = shoot({
          levels: act.levels,
          index: i,
          final: i === act.levels.length - 1,
        });
        expectFinite(rec, `${act.key}/${i}`);
        for (const t of rec.texts) {
          expect(t.text.length, `${act.key}/${i} drew an empty line`).toBeGreaterThan(0);
          expect(t.text, `${act.key}/${i}`).not.toContain('undefined');
        }
      }
    }
  });

  /** An index past the end clamps rather than throwing, which is what it always did. */
  it('clamps an index past the last station', () => {
    expect(inked(shoot({ index: 99 }))[1]!.text).toBe(
      WATER.levels[WATER.levels.length - 1]!.name.toUpperCase(),
    );
    expect(inked(shoot({ levels: HOME.levels, index: 99 }))[1]!.text).toBe(
      HOME.levels[HOME.levels.length - 1]!.name.toUpperCase(),
    );
  });
});
