import { describe, expect, it } from 'vitest';
import { CAMPAIGN_ACTS } from '../src/config/campaign';
import type { Level, SectionSpec } from '../src/config/levels';
import { DEFAULT_TUNING } from '../src/config/tuning';
import { SECTION_SPACING } from '../src/sim/ObstacleSystem';

/**
 * Slowblue: the rules a station obeys, held across the whole campaign.
 *
 * Every one of these was **measured on act V's rebuild** and then written down in
 * `docs/DESIGN-LENGTH.md` - and for a while each lived in `tests/reentry.test.ts`,
 * where it guarded exactly one act. That was right while act V was the only
 * rebuilt one. Six acts have been rebuilt to the same recipe now, so a rule that
 * only holds act V is a rule five acts can break silently.
 *
 * The two that cost the most to learn, and the numbers that taught them:
 *
 *   * **A station ends on a rest, and its last demand is not a gate.** Act V's
 *     first rebuild put the rest in the middle of the station and a compulsory
 *     ring on the last demand, and measured 35.6 restarts a run against the
 *     unrebuilt act's 1.2 - every one of them the swarm being left behind rather
 *     than a missed ring. A station's pressure ramp peaks at its own end and a
 *     compulsory ring asks the body to stop and hold still; they are opposite
 *     demands, and the old four-section stations only got away with colliding them
 *     because every one of them happened to end on empty medium.
 *   * **Never two compulsory rings on one section.** One wants 28 % of the swarm
 *     inside it for 0.7 s, so two side by side ask for 56 % in two places at once.
 *     That is not a demand, it is a wall.
 *
 * `tests/geometry.test.ts` holds what an act is allowed to be *made of*;
 * `tests/motion.test.ts` holds what is allowed to move. This holds the shape of a
 * station, which is the part six agents could break in six files at once.
 */

/** The masses a body is meant to split on. Two rings round one of these are two
 * thirds of the width apart on purpose, and mean the opposite of a pair. */
const SPLITTABLE = new Set(['rock', 'predator', 'tower', 'raptor', 'column', 'plume', 'canopy', 'hulk']);

const isRest = (s: SectionSpec): boolean => s.kind === 'open';
const musts = (s: SectionSpec): number => (s.rings ?? []).filter((r) => r.required === true).length;

/** Every station in the campaign, with the act it belongs to. */
const STATIONS: { act: string; level: Level }[] = CAMPAIGN_ACTS.flatMap((act) =>
  act.levels.map((level) => ({ act: act.key, level })),
);

/**
 * ...and every station these rules actually apply to, which is every act but the
 * first.
 *
 * **Act I is the metronome and it predates all of this.** Its numbers are
 * defended digit for digit - `tests/playability.test.ts` holds a reference score
 * to sixteen places - and its stations are 1.4 to 2.0 minutes where a rebuilt
 * one is 2.5 to 5.5. It breaks two of the rules below and has always broken
 * them: Black Water ends its demands on a compulsory ring, and the Blue Rise's
 * rock asks for both of its channel rings.
 *
 * Neither is a defect at act I's scale, and that is the point of the exemption
 * rather than an excuse for it. The rule about a station's last demand was
 * measured on a station of *fifteen* sections, where the pressure ramp has four
 * minutes to build; Black Water is seven sections and ninety seconds, and the
 * ramp never gets anywhere. The rule about two compulsory rings was measured at
 * act V's pace on a swarm the rings had already doubled. A rule learned at one
 * scale is not automatically true at the other, and act I is the act that says
 * what the other scale *is*.
 */
const REBUILT = STATIONS.filter((s) => s.act !== 'water');

describe('what a station is allowed to be', () => {
  it('lands: every station in the campaign ends on a rest', () => {
    for (const { act, level } of STATIONS) {
      const last = level.sections[level.sections.length - 1]!;
      expect(isRest(last), `${act}/${level.key} ends on ${last.kind}`).toBe(true);
    }
  });

  it('does not end its demands on a compulsory ring', () => {
    for (const { act, level } of REBUILT) {
      const demands = level.sections.filter((s) => !isRest(s));
      if (demands.length === 0) continue;
      const last = demands[demands.length - 1]!;
      expect(musts(last), `${act}/${level.key} ends its demands on a gate`).toBe(0);
    }
  });

  it('never asks for two compulsory rings on one section', () => {
    for (const { act, level } of REBUILT) {
      level.sections.forEach((s, i) => {
        expect(musts(s), `${act}/${level.key} §${String(i)} (${s.kind})`).toBeLessThanOrEqual(1);
      });
    }
  });

  /**
   * Two rings on one line are act V's own grammar and they spread across the
   * campaign with the rebuild: the compulsory one on the aperture the section was
   * already asking for, an optional one beside it. A body that has stayed wide
   * takes both on one line; a scattered one takes neither cleanly. Closer than
   * 0.25 and an ordinary body covers both without having been asked for anything;
   * wider than 0.35 and none does, so the line stops rewarding width and becomes a
   * choice between two rings.
   */
  it('keeps a pair on one line between a quarter and a third of the width apart', () => {
    for (const { act, level } of REBUILT) {
      for (const s of level.sections) {
        if (SPLITTABLE.has(s.kind)) continue;
        const rings = s.rings ?? [];
        for (let i = 0; i < rings.length; i++) {
          for (let j = i + 1; j < rings.length; j++) {
            if (rings[i]!.dy !== rings[j]!.dy) continue;
            const apart = Math.abs(rings[i]!.x - rings[j]!.x);
            const where = `${act}/${level.key} ${s.kind} pair`;
            expect(apart, where).toBeGreaterThanOrEqual(0.25);
            expect(apart, where).toBeLessThanOrEqual(0.35);
          }
        }
      }
    }
  });

  /**
   * A doubled station gets *two* rests, one in each half - the mid-station breath
   * is an addition rather than the landing moved. Stated as "any station long
   * enough to need one has one", because the shortest stations in the campaign
   * predate the rebuild and are correct as they are.
   */
  it('gives a long station somewhere to put the phone down', () => {
    const thin: string[] = [];
    for (const { act, level } of REBUILT) {
      if (level.sections.length < 8) continue;
      const rests = level.sections.filter(isRest).length;
      // The plasma is the campaign's one exception and it is a measured one: it is
      // the peak of act V and has no rest in its *middle*, which cost two
      // completions in seven when it also had none at its end. It lands like
      // everything else.
      if (level.key === 'plasma') continue;
      if (rests < 2) thin.push(`${act}/${level.key} (${String(level.sections.length)} sections, ${String(rests)} rest)`);
    }
    expect(thin).toEqual([]);
  });

  /**
   * ...and the arithmetic the whole rebuild is about, per station rather than per
   * act. A station under two and a half minutes is thinner than the recipe; one
   * over five and a half is a punishment, because from act III on a lost station
   * begins again and station length *is* the price of failure.
   */
  it('keeps every station inside the length a restart can cost', () => {
    const out: string[] = [];
    for (const { act, level } of REBUILT) {
      const px = level.sections.reduce((t, s) => t + (s.spacing ?? SECTION_SPACING), 0);
      const minutes = px / (DEFAULT_TUNING.worldSpeed * level.pace) / 60;
      // Act VII's last three cannot be lost at all, so length is not a price there;
      // they are the campaign dilating to a stop and are supposed to be short.
      if (level.failure === 'none') continue;
      if (minutes < 2.5 || minutes > 5.5) {
        out.push(`${act}/${level.key} ${minutes.toFixed(1)} min`);
      }
    }
    expect(out).toEqual([]);
  });
});
