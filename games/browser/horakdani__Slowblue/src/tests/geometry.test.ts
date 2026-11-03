import { describe, expect, it } from 'vitest';
import { CAMPAIGN_ACTS } from '../src/config/campaign';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { SECTION_SPACING } from '../src/sim/ObstacleSystem';
import { buildCourse, sweepCourse } from './course';

/**
 * Slowblue: the invariants that belong to no single act.
 *
 * Every act has a suite that knows what that act is about. These are the four
 * facts that have to be true of *all seven courses at once*, and they live here
 * because each of them was, until this pass, true only by accident - nothing had
 * ever been authored that could break them, so nothing had ever checked.
 *
 * They became worth checking when the acts stopped sharing one rhythm. A course
 * whose sections are 320 px apart in one station and 1400 in the next is a course
 * where geometry from one section sits inside another, and the questions below
 * are exactly the ones that stops being obvious.
 */

/**
 * How far a section's geometry may reach *past* its own scoring line.
 *
 * `ObstacleSystem.prune` retires a section when its `lineY` falls behind
 * `World.behindLine`, which is `cameraY + 0.9H` - and the swarm is anchored at
 * `cameraY + 0.62H`, so the prune line sits about 236 px behind a swarm that is
 * keeping up, and level with one that has fallen behind. Anything a section owns
 * more than that far forward of its own line therefore stops colliding while it
 * is still in front of the player: an obstacle that quietly turns to water. A
 * retired section is still *painted* until it has left the frame, which is the
 * whole point of retiring it rather than deleting it - so what that failure
 * looks like now is a rock the shoal swims straight through.
 *
 * Measured across all seven acts before this bound existed, the deepest forward
 * reach in the campaign was orbit's `node` at 180 px. The bound is set at 220,
 * which is under the prune line and above everything authored, so it fails when
 * something new reaches too far rather than when an existing act is retuned.
 */
const MAX_FORWARD_REACH = 220;

/**
 * Slowblue: what each act is allowed to be made of, in one table.
 *
 * This existed as three hand-maintained *deny*-lists - "none of the twelve kinds
 * below the tropopause may appear up here" - in the suites for acts II, III and
 * IV. A deny-list has one failure mode and this codebase hit it: acts V, VI and
 * VII had no list at all, which is exactly why they were the three biggest
 * borrowers in the campaign, and act VII ended up authored end to end out of act
 * I's rock while its own header insisted it was not act I reversed. A deny-list
 * also goes stale silently - add a kind to the shared `SectionSpec` union and
 * every deny-list stays green while saying nothing about it.
 *
 * An allow-list cannot do either. It is the shape `tests/descent.test.ts` already
 * reached for on the campaign's most delicate station, and this is that shape
 * applied to all seven acts at once.
 *
 * Two of the lists are long on purpose and neither is a lapse:
 *
 *   * **Act V borrows from both sides** because it is the transformation. It
 *     opens on orbit's debris and closes on act II's cloud, and owns only
 *     shock/plume/sheet for the part in between. Taking the borrowings away would
 *     leave the act with nothing but its middle.
 *   * **Act VI borrows three ways** for three separate reasons, each written down
 *     where it happens: ice at the Cirrus because that is the last ice in the
 *     campaign, cloud under the Anvil because it is literally the cloud act II
 *     climbed over, and water's own shapes in the brook and the estuary because a
 *     stone in a mountain stream *is* a stone on the trench floor.
 *
 * The rule the lists encode is not "every act has six shapes nobody else uses".
 * It is the narrower and older one: **a medium never borrows another medium's
 * silhouettes without a reason that is written down.**
 */
const ALPHABET: Record<string, string[]> = {
  water: ['open', 'gate', 'rock', 'narrows', 'drift', 'vortex', 'predator'],
  air: ['open', 'bank', 'tower', 'pass', 'wisps', 'rotor', 'raptor', 'street'],
  thin: ['open', 'veil', 'column', 'throat', 'flurry', 'eddy', 'shear'],
  orbit: ['open', 'arc', 'hulk', 'strait', 'shrapnel', 'node', 'flare'],
  reentry: [
    'open',
    // its own three
    'shock', 'plume', 'sheet',
    // its own fourth, and the only threat in the campaign's second half
    'ember',
    // orbit's, at the top of the act. `shrapnel` joined them when act V was
    // doubled: the night side needed a third demand and orbit's chicane is the
    // one shape in the borrowed half the act had never used, so the act got wider
    // rather than more of what it already had. `hulk` joined them on the second
    // pass, and it is the last shape in the campaign that had never been authored
    // anywhere - see the exemption list in the test below, which it comes off.
    'arc', 'node', 'flare', 'strait', 'shrapnel', 'hulk',
    // the air's, at the bottom of it
    'bank', 'tower', 'pass', 'wisps',
  ],
  rain: [
    'open',
    // its own three
    'downpour', 'canopy', 'boulder',
    // act III's ice, at the Cirrus
    'veil', 'column',
    // act II's cloud, under the Anvil
    'bank', 'tower', 'pass',
    // water's own, in the brook and the estuary
    'gate', 'narrows', 'vortex',
  ],
  home: ['open', 'drape', 'bloom', 'rock'],
};

describe('every act is made of what it says it is made of', () => {
  it('authors nothing outside its own alphabet', () => {
    for (const act of CAMPAIGN_ACTS) {
      const allowed = new Set(ALPHABET[act.key]);
      expect(allowed.size, `${act.key} has no alphabet`).toBeGreaterThan(0);
      for (const entry of act.script) {
        expect(
          allowed.has(entry.spec.kind),
          `${act.key} station ${entry.level + 1}: ${entry.spec.kind}`,
        ).toBe(true);
      }
    }
  });

  it('leaves nothing in an alphabet that the act never uses', () => {
    // The other half of the guarantee, and the half a deny-list can never give:
    // a list that quietly grows is a list that has stopped describing the act.
    // `hulk` was the one knowingly-unused entry: orbit's splittable mass was an
    // authored shape the current cut of that act had no room for, and the act was
    // half its length once. It stays unused *there* and is authored in act V's
    // deorbit now, which is the last unwritten shape in the campaign.
    //
    // `flurry` was here too and should not have been. An unused entry is a cost
    // rather than a spare part: the upper air went ten minutes on two demands
    // because its chicane was sitting in this list instead of in a station, and
    // this exemption is what let that be true silently. It is authored now, at the
    // Black Sky.
    const spare: Record<string, string[]> = { orbit: ['hulk'] };
    for (const act of CAMPAIGN_ACTS) {
      const used = new Set(act.script.map((e) => e.spec.kind));
      const unused = ALPHABET[act.key]!.filter(
        (k) => !used.has(k as never) && !(spare[act.key] ?? []).includes(k),
      );
      expect(unused, `${act.key} allows kinds it never authors`).toEqual([]);
    }
  });
});

describe('every course in the campaign', () => {
  it('never lets a section reach past its own scoring line far enough to be pruned early', () => {
    const worst: Record<string, number> = {};
    for (const act of CAMPAIGN_ACTS) {
      const o = buildCourse(act);
      let reach = 0;
      let offender = -1;
      for (const s of o.sections) {
        // On a climb the course runs toward smaller Y, so "past the line" is
        // `minY`; on a descent it is `maxY`. One sign, as everywhere else.
        const forward = act.direction < 0 ? s.lineY - s.minY : s.maxY - s.lineY;
        if (forward > reach) {
          reach = forward;
          offender = s.id;
        }
      }
      worst[act.key] = Math.round(reach);
      expect(reach, `${act.key} section ${offender}`).toBeLessThan(MAX_FORWARD_REACH);
    }
    console.log('[forward reach]', JSON.stringify(worst));
  });

  /**
   * Slowblue: `swirl` and the things it scales, in both directions.
   *
   * `Level.swirl` has exactly one consumer - `World.water` multiplies it into the
   * standing-current field - and exactly three section kinds fill that field. So a
   * station with a `swirl` and no turning air is authoring a number over an empty
   * list, and a station with turning air and no `swirl` has silently switched its
   * own hazard off. Seventeen of the forty-two were the first kind, including act
   * V's Plasma, whose header counts `swirl` among the things that escalate.
   *
   * Nothing could have caught it: the value type-checks, the corridor sweep never
   * looks at it, and a multiplication by a number nobody reads has no symptom at
   * all. It is exactly the class the design doc calls "a surface built when there
   * were two or three of a thing".
   */
  it('authors a swirl on every station that turns, and only on those', () => {
    const TURNS = new Set(['vortex', 'rotor', 'eddy']);
    for (const act of CAMPAIGN_ACTS) {
      for (const level of act.levels) {
        const turns = level.sections.some((s) => TURNS.has(s.kind));
        expect(turns, `${act.key}/${level.key} lays a current but authors swirl 0`).toBe(
          level.swirl > 0,
        );
      }
    }
  });

  /**
   * The flat sweep asks "is there a line". This asks the question the player
   * actually asks: is the ring I have to hold next reachable *from the one I am
   * holding now*. They are the same question only while a course has one corridor
   * at a time, which was true of the whole campaign until act VII stopped being
   * made of walls. See `chainRings` in `tests/course.ts`.
   */
  it('lets one body take every compulsory ring in order, in all seven acts', () => {
    const table: Record<string, unknown> = {};
    for (const act of CAMPAIGN_ACTS) {
      const sweep = sweepCourse(buildCourse(act));
      table[act.key] = {
        rings: sweep.ringsReachable.length,
        widest: sweep.minWidestRun,
        pieces: sweep.maxComponents,
      };
      expect(sweep.blockedAt, act.key).toBeNull();
      expect(sweep.chainBreaks, `${act.key}: ${JSON.stringify(sweep.chainBreaks)}`).toEqual([]);
      // ...and a floor under the width, which was printed and never bounded. The
      // sweep samples points and a body is about 150 px across, so this number is
      // how much of the approval is real - a retune that halves one act's widest
      // run leaves `blockedAt` null and every ring reachable, and is still a
      // corridor nothing can actually be flown down.
      expect(sweep.minWidestRun, act.key).toBeGreaterThanOrEqual(56);
    }
    // `widest` is the narrowest the widest reachable run ever gets, in px, and it
    // is printed rather than bounded on purpose: the sweep samples points and a
    // shoal is about 150 px across, so this is the number that says how much of
    // the approval is real. A change that halves it should be visible here.
    console.log('[corridor]', JSON.stringify(table));
  });

  /**
   * Slowblue: no ring inside anything, in any act.
   *
   * `tests/levels.test.ts` has asserted this for act I since the authored
   * campaign existed, and for six acts nothing else did - which was survivable
   * only because every act placed exactly one ring per section, on that section's
   * own centre line, where the author had just put a hole. Two things in this
   * pass end that: act V's paired rings and act VI's gathering runs both put
   * rings *beside* and *behind* the aperture, at offsets of up to 170 px, and act
   * VI's tightest sections are 380 px apart. A trailing ring reaching back into
   * the section before it is now a thing that can happen, so it is now a thing
   * that is checked - and checked for optional rings too, because a ring the
   * player can see and cannot reach is a lie whatever it costs to miss.
   */
  it('never puts a ring inside an obstacle, in any act', () => {
    for (const act of CAMPAIGN_ACTS) {
      const o = buildCourse(act);
      for (const s of o.sections) {
        for (const p of s.podHints) {
          expect(
            o.hit(p.x, p.y, 1),
            `${act.key} section ${s.id} ring at x=${Math.round(p.x)}`,
          ).toBeNull();
          if (p.required !== true) continue;
          // ...and a compulsory ring is not a sliver of water: most of the body
          // the player has to hold in it has to be somewhere they can hold it.
          const r = DEFAULT_TUNING.rescueRadius * (p.scale ?? 1);
          let open = 0;
          const samples = 24;
          for (let i = 0; i < samples; i++) {
            const a = (i / samples) * Math.PI * 2;
            if (o.hit(p.x + Math.cos(a) * r * 0.6, p.y + Math.sin(a) * r * 0.6, 1) === null) {
              open++;
            }
          }
          expect(open / samples, `${act.key} section ${s.id}`).toBeGreaterThan(0.75);
        }
      }
    }
  });

  /**
   * Slowblue: the rhythm is now the act's, and this is what stops that from meaning
   * "whatever happened".
   *
   * Every act used to be laid on the same 820 px metronome, so an act's length
   * was its section count and nothing else. Now act II runs in tight pairs with
   * long crossings between them, act III drifts, act IV clusters its gravity, act
   * V contracts as the air arrives, act VI comes in squalls and act VII dilates
   * to a stop - and the one thing that must *not* have changed is how long any of
   * them takes. Each act still keeps its ten minutes; what changed is how the ten
   * minutes are divided.
   */
  it('gives every act a rhythm of its own without changing how long it lasts', () => {
    const spread = CAMPAIGN_ACTS.map((act) => {
      const s = act.script.map((e) => e.spec.spacing ?? SECTION_SPACING);
      return Math.round(Math.max(...s) - Math.min(...s));
    });
    console.log(
      '[rhythm]',
      JSON.stringify(
        Object.fromEntries(CAMPAIGN_ACTS.map((a, i) => [a.key, spread[i]])),
      ),
    );
    // Act I is the metronome the others are heard against - it is frozen
    // (DESIGN-ASCENT §5) and it is the origin of the shape, so it is the one act
    // allowed to be regular. Every other act has to actually have a rhythm.
    expect(spread[0]!, 'act I is the reference and stays regular').toBeLessThan(400);
    for (let i = 1; i < spread.length; i++) {
      expect(spread[i]!, `${CAMPAIGN_ACTS[i]!.key} is still on the metronome`).toBeGreaterThan(400);
    }
  });
});
