import { describe, expect, it } from 'vitest';
import { CAMPAIGN } from '../src/config/campaign';
import { ALL_ZONES } from '../src/config/zones';
import { motifsForAct } from '../src/render/Motif';
import { parseHex, type Rgb } from '../src/render/Paint';
import { isWarm, labDistance, toLch } from './oklab';

/**
 * Slowblue: the palette as a system, guarded on the two things a number can hold.
 *
 * §14 is the one criterion in the brief that is about *hue*, and until this file
 * the suite had no way to say anything about it: every instrument reduces a pixel
 * to luminance first. The report lives in `tools/palette.sweep.ts` - forty-two
 * stations in OkLCh, run with
 *
 *   npx vitest run --config vitest.sweep.config.ts tools/palette.sweep.ts
 *
 * - and most of what it says is not gateable, for the same reason the band pass is
 * not: the arc is a design statement and a station is allowed to break it on
 * purpose. What *is* gateable is here, and it is the two claims the campaign
 * cannot afford to lose quietly.
 */

interface Station {
  act: string;
  station: number;
  key: string;
  zoneKey: string;
  mid: Rgb;
  pod: Rgb;
  wash: Rgb;
  washAmount: number;
}

function stations(): Station[] {
  const out: Station[] = [];
  for (const info of CAMPAIGN) {
    const motifs = motifsForAct(info.act.key);
    info.act.levels.forEach((level, i) => {
      // `Level.zone` rather than a running count: act I's six levels share four
      // zone palettes, which is the one place the two tables are not parallel -
      // and the whole reason the wash exists.
      const z = ALL_ZONES[level.zone]!;
      const m = motifs[i]!;
      out.push({
        act: info.act.key,
        station: i + 1,
        key: level.key,
        zoneKey: z.key,
        mid: parseHex(z.palette.mid),
        pod: z.palette.pod.split(',').map(Number) as Rgb,
        wash: m.wash,
        washAmount: m.washAmount,
      });
    });
  }
  return out;
}

describe('the colour arc', () => {
  it('covers all forty-two stations', () => {
    expect(stations()).toHaveLength(42);
  });

  /**
   * A station may have no colour of its own. It may not pay for one it is not
   * getting.
   *
   * `Renderer.drawBackground` folds the motif's wash into the three stops of the
   * zone gradient at 1, 0.6 and 0.25 of `washAmount`. That is act I's mechanism
   * and its own comment says so: four zone palettes carry six levels there, and
   * two stations sharing one have nothing else to tell them apart. Measured in
   * OkLCh, that is exactly where the only real *hue* shifts in the campaign are -
   * the midnight current and the light line, 61 and 58 degrees off the mid they
   * are laid over. Every act after act I gives each station its own zone, the
   * mechanism has nothing left to separate, and the thirty authored washes
   * degenerate into a tone: 24 sit within six degrees of their own mid.
   *
   * Which is how twelve of them came to be their zone's `mid`, byte for byte - a
   * column filled in rather than authored, in acts VI and VII and at two stations
   * of act V. Mixing the middle stop with itself is arithmetically nothing, but
   * the top and bottom stops are still pulled toward it, so those twelve rendered
   * a water 10 to 16 per cent flatter than the zone table authored, bought
   * nothing with it, and no test in the suite was in a position to notice: the
   * defect has no edge in it, and everything here measures edges.
   *
   * **The floor is where the measurement put it.** The twelve read 0.0000. The
   * smallest surviving authored wash is the squall's at 0.0063 - which is itself
   * close enough to nothing to be worth knowing about, and is left alone because
   * it was written rather than copied. Nothing was tuned to clear this: there is
   * infinite air below and half again above.
   */
  it('never charges a station for a tint it is not getting', () => {
    const paid = stations().filter((s) => s.washAmount > 0);
    for (const s of paid) {
      const moved = labDistance(toLch(s.wash), toLch(s.mid));
      expect(
        moved,
        `${s.act}/${s.key} washes with its own zone mid (${s.zoneKey}) at amount ${s.washAmount}`,
      ).toBeGreaterThan(0.004);
    }
    // ...and the twelve that declare zero really are declaring it, rather than
    // having been quietly given a colour again.
    const free = stations().filter((s) => s.washAmount === 0);
    expect(free).toHaveLength(12);
    for (const s of free) {
      expect(
        labDistance(toLch(s.wash), toLch(s.mid)),
        `${s.act}/${s.key} declares no tint but no longer holds its zone mid`,
      ).toBe(0);
    }
  });

  /**
   * The golden life-spark, which §14 calls every act's visual link.
   *
   * It is the one colour that is supposed to survive every medium in the game -
   * water, air, vacuum, plasma, rain, and water again - so it is the one hue that
   * can be asserted campaign-wide without telling the assertion the answer.
   * Measured across the forty zone palettes it lands between 42 and 97 degrees at
   * chroma 0.041 to 0.118; the band below is opened well past both ends, because
   * what this guards against is the gold going *cool* or going grey in some act,
   * not against it being retuned.
   */
  it('keeps the gold warm in every act', () => {
    for (const s of stations()) {
      const pod = toLch(s.pod);
      expect(isWarm(pod.h), `${s.act}/${s.key} pod is ${pod.h.toFixed(0)} deg, not warm`).toBe(
        true,
      );
      expect(
        pod.c,
        `${s.act}/${s.key} pod has gone grey at chroma ${pod.c.toFixed(3)}`,
      ).toBeGreaterThan(0.03);
    }
  });
});
