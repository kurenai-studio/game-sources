import { describe, it } from 'vitest';
import { CAMPAIGN_ACTS } from '../src/config/campaign';
import { DEFAULT_TUNING } from '../src/config/tuning';
import type { Act, SectionSpec } from '../src/config/levels';
import { SECTION_SPACING } from '../src/sim/ObstacleSystem';

/**
 * Slowblue: what every station in the campaign is made of, as arithmetic.
 *
 *   npm run sweep
 *
 * The one instrument here that does not run the simulation. `length.sweep.ts`
 * says how hard an act is by flying it, which takes half an hour; this says how
 * *long* it is and how much is in it, from the level files alone, in about a
 * millisecond. Both were needed for the same reason: the campaign is being
 * doubled station by station, and the table in `docs/DESIGN-LENGTH.md` §1 - the
 * measurement the whole plan was taken off the back of - was assembled by hand
 * and would have to be assembled by hand again after every act.
 *
 * A hand-made table of numbers about a file that keeps changing is a table that
 * is quietly wrong within a week. This one is not allowed to be.
 *
 * Two columns are worth reading twice:
 *
 *   - **min** is the authored length over the forced drift, and it is what the
 *     player does *not* experience: `World.pressure` adds up to 55 % to the drift
 *     across a station, so a real run of a station is roughly three quarters of
 *     the number printed here. It is the right unit to author in anyway, because
 *     it is the only one that holds still while the pressure ramp is tuned.
 *   - **ob/min** is obstacle sections per minute, and it is capped by the pace
 *     rather than by taste. Density is speed over spacing and spacing is spatial -
 *     how much course sits between two obstacles is also how many of them are on
 *     screen at once. See DESIGN-LENGTH §3.
 */

const px = (s: SectionSpec): number => s.spacing ?? SECTION_SPACING;

interface Row {
  key: string;
  sections: number;
  obstacles: number;
  px: number;
  minutes: number;
  perMinute: number;
  musts: number;
  moving: number;
  hunters: number;
}

function stations(act: Act): Row[] {
  return act.levels.map((level) => {
    // The first spacing of the *act* is never walked - the course starts at its
    // own offset - but every station after the first inherits the walk into it,
    // so this is the honest per-station figure everywhere except section 0.
    const total = level.sections.reduce((t, s) => t + px(s), 0);
    const minutes = total / (DEFAULT_TUNING.worldSpeed * level.pace) / 60;
    const obstacles = level.sections.filter((s) => s.kind !== 'open').length;
    return {
      key: level.key,
      sections: level.sections.length,
      obstacles,
      px: total,
      minutes,
      perMinute: obstacles / minutes,
      musts: level.sections.reduce(
        (n, s) => n + (s.rings ?? []).filter((r) => r.required === true).length,
        0,
      ),
      moving: level.sections.filter((s) => s.motion !== undefined).length,
      hunters: level.sections.reduce(
        (n, s) => n + ('hunters' in s ? s.hunters.length : 0),
        0,
      ),
    };
  });
}

const cols = ['station', 'sec', 'obst', 'px', 'min', 'ob/min', 'must', 'move', 'hunt'];
const widths = [16, 4, 5, 7, 6, 7, 5, 5, 5];

function line(cells: (string | number)[]): string {
  return cells
    .map((c, i) => String(c).padStart(widths[i] ?? 6))
    .join(' ');
}

describe('what each station is made of', () => {
  it('the whole campaign, station by station', () => {
    let allMin = 0;
    let allSec = 0;
    let allObst = 0;
    for (const act of CAMPAIGN_ACTS) {
      const rows = stations(act);
      console.log(`\n=== ${act.key} ===`);
      console.log(line(cols));
      for (const r of rows) {
        console.log(
          line([
            r.key,
            r.sections,
            r.obstacles,
            r.px,
            r.minutes.toFixed(1),
            r.perMinute.toFixed(1),
            r.musts,
            r.moving,
            r.hunters,
          ]),
        );
      }
      const min = rows.reduce((t, r) => t + r.minutes, 0);
      const sec = rows.reduce((t, r) => t + r.sections, 0);
      const obst = rows.reduce((t, r) => t + r.obstacles, 0);
      console.log(
        line([
          'act',
          sec,
          obst,
          rows.reduce((t, r) => t + r.px, 0),
          min.toFixed(1),
          (obst / min).toFixed(1),
          rows.reduce((t, r) => t + r.musts, 0),
          rows.reduce((t, r) => t + r.moving, 0),
          rows.reduce((t, r) => t + r.hunters, 0),
        ]),
      );
      allMin += min;
      allSec += sec;
      allObst += obst;
    }
    console.log(
      `\n=== circuit: ${String(allSec)} sections, ${String(allObst)} obstacles, ${allMin.toFixed(1)} min authored ===`,
    );
  });
});
