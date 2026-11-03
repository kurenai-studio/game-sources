import { describe, it } from 'vitest';
import { ALL_ZONES } from '../src/config/zones';
import { CAMPAIGN } from '../src/config/campaign';
import { motifsForAct, type Motif } from '../src/render/Motif';
import { mix, parseHex, type Rgb } from '../src/render/Paint';
import { hueDelta, isWarm, labDistance, toLch } from '../tests/oklab';

/**
 * The colour arc, as a number. The report `tests/palette.test.ts` is the gate for.
 *
 *   npx vitest run --config vitest.sweep.config.ts tools/palette.sweep.ts
 *
 * §14 is the only part of the brief that is about *hue*, and every instrument the
 * suite owns reduces a pixel to luminance before it does anything else - so until
 * this file there was no number in the project that could tell teal from gold.
 * What it reads is the palette the way the picture is actually authored: forty
 * zone palettes in `zones.ts` and forty-two motifs in `Motif.ts`, in OkLCh.
 *
 * It is a report rather than a gate, in the same position as the band pass in
 * `e2e/acts.spec.ts`: the arc is a design statement, the campaign breaks it on
 * purpose in several places, and a threshold tuned until those passed would be a
 * threshold that had been told the answer. The two claims that *can* be held are
 * in the test file. This says where to look.
 *
 * ## What it found the first time it was run
 *
 * - The wash carries a real **hue** shift in exactly one act: act I, where four
 *   zone palettes carry six levels and two stations sharing one have nothing else
 *   to separate them. 61 and 58 degrees, at the midnight current and the light
 *   line. Everywhere else a station owns its zone, and the thirty authored washes
 *   are a *tone*: 24 within six degrees of the mid they are laid over.
 * - **Twelve** of the forty-two washed with their own zone's `mid`, byte for byte.
 *   Fixed: they declare `washAmount: 0` now.
 * - The violet crown in both auroras was computed every frame and handed to a
 *   zero-alpha stop. Fixed, and the measurement is in `Orbit.ts`.
 * - Reported, not touched: `nucleus` is the campaign's one **achromatic** station,
 *   every declared colour under 0.03 chroma, at the act V to VI handover. The gold
 *   runs at half chroma through act VI (0.057 to 0.076 against 0.105 to 0.118 in
 *   act I). And the shoal inverts *inside* act II, L 0.24 at the squall to 0.97 at
 *   the anvil, because the top of a storm is dark and a dark flock would vanish
 *   into it.
 */

interface Station {
  act: string;
  station: number;
  key: string;
  motif: Motif;
  top: Rgb;
  mid: Rgb;
  bottom: Rgb;
  pod: Rgb;
  shoal: Rgb;
}

function stations(): Station[] {
  const out: Station[] = [];
  for (const info of CAMPAIGN) {
    const motifs = motifsForAct(info.act.key);
    info.act.levels.forEach((level, i) => {
      // `Level.zone` rather than a running count: act I's six levels share four
      // zone palettes, which is the one place the two tables are not parallel.
      const z = ALL_ZONES[level.zone]!;
      out.push({
        act: info.act.key,
        station: i + 1,
        key: level.key,
        motif: motifs[i]!,
        top: parseHex(z.palette.top),
        mid: parseHex(z.palette.mid),
        bottom: parseHex(z.palette.bottom),
        pod: z.palette.pod.split(',').map(Number) as Rgb,
        shoal: parseHex(z.palette.shoal),
      });
    });
  }
  return out;
}

function f(n: number, digits = 1): string {
  return n.toFixed(digits).padStart(digits + 4);
}

/** `L/C/h`, the three numbers every row here is made of. */
function lch(rgb: Rgb): string {
  const p = toLch(rgb);
  return `${f(p.l, 2)}/${f(p.c, 3)}/${p.h.toFixed(0).padStart(3)}`;
}

describe('the colour arc', () => {
  it('reads every station in OkLCh', () => {
    const rows = [
      'act/st  key               top              mid              accent           crest            wash',
    ];
    for (const s of stations()) {
      rows.push(
        `${s.act.padEnd(8)}${s.station} ${s.key.padEnd(16)} ${lch(s.top)}  ${lch(s.mid)}  ` +
          `${lch(s.motif.accent)}  ${lch(s.motif.crest)}  ${lch(s.motif.wash)}`,
      );
    }
    console.log(rows.join('\n'));
  });

  /**
   * What the level wash actually moves, at the three stops `drawBackground` puts
   * it through. The weights are restated rather than imported on purpose: the
   * point is to measure the shipped arithmetic, not to share a constant with it.
   */
  it('measures what the level wash actually moves', () => {
    const STOPS: Array<[(s: Station) => Rgb, number]> = [
      [(s) => s.top, 1],
      [(s) => s.mid, 0.6],
      [(s) => s.bottom, 0.25],
    ];
    const rows = ['act/st  key               amt   dE(top) dE(mid) dE(bot)  vertical range'];
    for (const s of stations()) {
      const amount = s.motif.washAmount;
      const de = STOPS.map(([get, weight]) =>
        labDistance(toLch(get(s)), toLch(mix(get(s), s.motif.wash, amount * weight))),
      );
      // The cost side of the same fold: a tint mixed into all three stops pulls
      // them together, so the gradient's own top-to-bottom range shrinks. That is
      // the whole of what the twelve dead washes were buying.
      const range = toLch(s.top).l - toLch(s.bottom).l;
      const washed =
        toLch(mix(s.top, s.motif.wash, amount)).l -
        toLch(mix(s.bottom, s.motif.wash, amount * 0.25)).l;
      rows.push(
        `${s.act.padEnd(8)}${s.station} ${s.key.padEnd(16)} ${f(amount, 2)} ` +
          `${de.map((d) => f(d, 4)).join(' ')}  ${f(range, 3)} -> ${f(washed, 3)}`,
      );
    }
    console.log(rows.join('\n'));
  });

  /** How each authored wash sits against the zone mid it is laid over. */
  it('relates every authored wash to its zone mid', () => {
    const rows = ['act/st  key               dE      dL      dC     dh'];
    let authored = 0;
    for (const s of stations()) {
      const mid = toLch(s.mid);
      const w = toLch(s.motif.wash);
      if (s.motif.washAmount > 0) authored++;
      rows.push(
        `${s.act.padEnd(8)}${s.station} ${s.key.padEnd(16)} ${f(labDistance(mid, w), 4)} ` +
          `${f(w.l - mid.l, 3)} ${f(w.c - mid.c, 3)} ${f(hueDelta(mid.h, w.h), 0)}` +
          `${s.motif.washAmount === 0 ? '   (no tint declared)' : ''}`,
      );
    }
    rows.push(`declaring a tint: ${authored} of 42`);
    console.log(rows.join('\n'));
  });

  /** §14's one visual link, across every medium in the game. */
  it('follows the golden life-spark', () => {
    const rows = ['act/st  key               shoal            pod              warm?'];
    for (const s of stations()) {
      rows.push(
        `${s.act.padEnd(8)}${s.station} ${s.key.padEnd(16)} ${lch(s.shoal)}  ${lch(s.pod)}  ` +
          `${isWarm(toLch(s.pod).h) ? 'yes' : 'NO'}`,
      );
    }
    console.log(rows.join('\n'));
  });

  it('walks the arc station to station', () => {
    const all = stations();
    const rows = ['step                                 dL      dC     dh(mid)'];
    for (let i = 1; i < all.length; i++) {
      const a = all[i - 1]!;
      const b = all[i]!;
      const am = toLch(a.mid);
      const bm = toLch(b.mid);
      rows.push(
        `${`${a.key} -> ${b.key}`.padEnd(36)}${f(bm.l - am.l, 3)} ${f(bm.c - am.c, 3)} ` +
          `${f(hueDelta(am.h, bm.h), 0)}${a.act !== b.act ? '   <- act boundary' : ''}`,
      );
    }
    console.log(rows.join('\n'));
  });
});
