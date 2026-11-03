import { describe, expect, it } from 'vitest';
import { CAMPAIGN_ACTS } from '../src/config/campaign';
import { makeAct, type Level, type SectionSpec } from '../src/config/levels';
import { BREATH_PERIOD } from '../src/sim/Breath';
import { ObstacleSystem } from '../src/sim/ObstacleSystem';
import { W } from './helpers';

/**
 * Slowblue: the second axis, and the four rules that keep it honest.
 *
 * Until act V's rebuild every obstacle in this game stood still, and the whole of
 * the difficulty was spatial. `MotionSpec` adds time to it - a gap that breathes
 * open, a mass that walks - and a moving hazard is exactly the kind of feature
 * that can quietly break the one promise this campaign makes: **nothing in it can
 * be impossible.** The corridor sweep is a static check, so a hazard that moves
 * could step outside everything the safety net ever looks at.
 *
 * It cannot, and this is why:
 *
 *   1. An `aperture` is **authored shut**. Its authored geometry is the narrowest
 *      the gap ever is, so the static sweep is already looking at the worst frame.
 *   2. A `drift` never leaves its `envelope`, and the sweep reads the envelope.
 *   3. The motion is **lateral only**, so every y quantity in the engine - the
 *      scoring line, the pruning, the retire-and-cull, the re-form window - is as
 *      true of a walking rock as of a still one.
 *   4. It is **deterministic**: position is a pure function of the simulation
 *      clock, so a seed replays and a pause actually pauses.
 *
 * Plus one authoring rule with teeth: an `aperture` pivots on its own centroid, so
 * it belongs only on the shapes that are one wall with one hole in them.
 */

/** The open span across a row, in px, as the sweep would see it. */
function openSpan(o: ObstacleSystem, y: number): number {
  let best = 0;
  let run = 0;
  for (let x = 0; x <= W; x += 2) {
    run = o.hit(x, y, 1) === null ? run + 2 : 0;
    if (run > best) best = run;
  }
  return best;
}

function oneSection(spec: SectionSpec, direction: -1 | 1 = -1): ObstacleSystem {
  const level: Level = {
    key: 'probe',
    name: 'x',
    depthMeters: 0,
    subtitle: 'x',
    zone: 0,
    decor: 'void',
    pace: 1,
    roughness: 0,
    swirl: 0,
    sections: [spec],
  };
  const o = new ObstacleSystem(W, 1, true, makeAct('probe', [level], { direction }));
  o.ensureAhead(direction * 4000);
  return o;
}

const APERTURE: SectionSpec = {
  kind: 'gate',
  centre: 0.5,
  gap: 0.3,
  motion: { kind: 'aperture', reach: 0.09 },
};

const DRIFT: SectionSpec = {
  kind: 'rock',
  centre: 0.5,
  radius: 0.12,
  motion: { kind: 'drift', reach: 0.14 },
};

describe('a course that does not stand still', () => {
  // Centred and hard off-centre. The off-centre one is the case that matters: the
  // first version of this pivoted on the geometry's centroid, which for a hole at
  // 0.26 sits out in the long run of wall to its right - so half the near side was
  // told to move inward and the gap shut on a phase the sweep never sees.
  for (const centre of [0.5, 0.26, 0.74]) {
    it(`never closes an aperture below what it was authored at, hole at ${String(centre)}`, () => {
      const o = oneSection({ ...APERTURE, centre } as SectionSpec);
      const y = o.sections[0]!.lineY;
      const shut = openSpan(o, y);
      let narrowest = Infinity;
      let widest = 0;
      // A whole cycle at half-second resolution, which is finer than the swarm can
      // cross a section in. The authored frame is phase zero of *this section's*
      // phase rather than of the clock, so this walks the cycle instead of
      // trusting t = 0.
      for (let t = 0; t <= BREATH_PERIOD; t += 0.5) {
        o.animate(t);
        const span = openSpan(o, y);
        narrowest = Math.min(narrowest, span);
        widest = Math.max(widest, span);
      }
      expect(narrowest).toBeGreaterThanOrEqual(shut - 2);
      // ...and it does open, or the whole feature is an expensive way to stand still.
      expect(widest).toBeGreaterThan(shut * 1.2);
    });
  }

  it('keeps a drifting mass inside the envelope the sweep is shown', () => {
    const o = oneSection(DRIFT);
    const s = o.sections[0]!;
    expect(s.envelope.length).toBeGreaterThan(s.blobs.length);
    for (let t = 0; t <= BREATH_PERIOD * 2; t += 0.25) {
      o.animate(t);
      for (const b of s.blobs) {
        // Containment in the *union*, not in any one copy: the envelope is a row
        // of overlapping discs, so the honest question is whether the live circle
        // - its whole rim, not its centre - is inside the union of them. Anything
        // less approves a corridor the rock can walk into.
        for (let k = 0; k < 32; k++) {
          const a = (k / 32) * Math.PI * 2;
          const px = b.x + Math.cos(a) * b.r;
          const py = b.y + Math.sin(a) * b.r;
          const inside = s.envelope.some((e) => Math.hypot(e.x - px, e.y - py) <= e.r + 0.001);
          expect(inside, `rim point at t=${t.toFixed(2)}`).toBe(true);
        }
      }
    }
  });

  it('moves sideways and nowhere else', () => {
    const o = oneSection(DRIFT, 1);
    const s = o.sections[0]!;
    const before = {
      lineY: s.lineY,
      minY: s.minY,
      maxY: s.maxY,
      entryY: s.entryY,
      exitY: s.exitY,
      ys: s.blobs.map((b) => b.y),
      rs: s.blobs.map((b) => b.r),
    };
    for (let t = 0; t <= BREATH_PERIOD; t += 0.37) o.animate(t);
    expect(s.lineY).toBe(before.lineY);
    expect(s.minY).toBe(before.minY);
    expect(s.maxY).toBe(before.maxY);
    expect(s.entryY).toBe(before.entryY);
    expect(s.exitY).toBe(before.exitY);
    expect(s.blobs.map((b) => b.y)).toEqual(before.ys);
    expect(s.blobs.map((b) => b.r)).toEqual(before.rs);
  });

  it('is a pure function of the clock, so a seed replays and a pause pauses', () => {
    const a = oneSection(DRIFT);
    const b = oneSection(DRIFT);
    // Walked forward in small steps, against one that stalled at 3 the way a
    // paused game does and then jumped. Same t, same rock, whatever the history.
    // The steps are exact tenths rather than an accumulator, because 0.1 added
    // seventy times is not 7 and this test is about the motion, not about floats.
    for (let k = 0; k <= 70; k++) a.animate(k / 10);
    b.animate(3);
    b.animate(3);
    b.animate(7);
    expect(a.sections[0]!.blobs.map((v) => v.x)).toEqual(b.sections[0]!.blobs.map((v) => v.x));
  });

  it('gives no two unauthored moving sections the same beat', () => {
    const phases = new Set<number>();
    let unauthored = 0;
    for (const act of CAMPAIGN_ACTS) {
      const o = new ObstacleSystem(W, 1, true, act);
      o.ensureAhead(act.direction * 1e6);
      for (const s of o.sections) {
        if (s.motion === null) continue;
        if (act.script[s.id]?.spec.motion?.phase !== undefined) continue;
        unauthored++;
        phases.add(s.motion.phase);
      }
    }
    // A campaign whose apertures all opened on the same beat would read as one
    // machine rather than as a world, so the default phase is keyed to where a
    // section sits on the course and no two of them collide. An *authored* phase
    // is the deliberate exception and is checked by the test underneath.
    expect(phases.size).toBe(unauthored);
  });

  /**
   * Slowblue: the one reason a phase is ever written down.
   *
   * `MotionSpec.phase` exists to make two sections move *against* each other -
   * the scissor and the counter-phase gate pair, both in act V. It is a sharp
   * tool: an authored phase is also a phase that repeats, and a campaign that
   * started writing them for any other reason would slowly lose the property the
   * test above guards. So the rule is narrow and it is checked: **every authored
   * phase has a partner in its own station, half a cycle away, of the same kind.**
   */
  it('only authors a phase to make a counter-phase pair', () => {
    for (const act of CAMPAIGN_ACTS) {
      for (const entry of act.script) {
        const motion = entry.spec.motion;
        const phase = motion?.phase;
        if (motion === undefined || phase === undefined) continue;
        const partner = act.script.some((other) => {
          const theirs = other.spec.motion;
          if (other === entry || other.level !== entry.level) return false;
          if (theirs === undefined || theirs.kind !== motion.kind) return false;
          if (theirs.phase === undefined) return false;
          // Half a cycle apart, whichever way round the two were written.
          const apart = (((theirs.phase - phase) % 1) + 1) % 1;
          return Math.abs(apart - 0.5) < 1e-9;
        });
        expect(
          partner,
          `${act.key} §${String(entry.level)}.${String(entry.step)} authors a phase with nothing to be out of step with`,
        ).toBe(true);
      }
    }
  });

  it('puts a counter-phase pair on opposite sides at every instant', () => {
    // Two masses on one clock and opposite halves of it. The claim in
    // `config/reentry.ts` is that there is no phase at which both are where you
    // last saw them, which is only true if their offsets are exact mirrors - and
    // that is a property of `animate`, not of the level file.
    const out = oneSection({ ...DRIFT, motion: { kind: 'drift', reach: 0.14, phase: 0 } });
    const back = oneSection({ ...DRIFT, motion: { kind: 'drift', reach: 0.14, phase: 0.5 } });
    const home = out.sections[0]!.blobs.map((b) => b.hx!);
    let seenApart = 0;
    for (let t = 0; t <= BREATH_PERIOD; t += 0.25) {
      out.animate(t);
      back.animate(t);
      for (let i = 0; i < home.length; i++) {
        const a = out.sections[0]!.blobs[i]!.x - home[i]!;
        const b = back.sections[0]!.blobs[i]!.x - home[i]!;
        expect(a + b, `t=${t.toFixed(2)}`).toBeCloseTo(0, 6);
      }
      if (Math.abs(out.sections[0]!.blobs[0]!.x - back.sections[0]!.blobs[0]!.x) > 20) {
        seenApart++;
      }
    }
    // ...and they are actually somewhere different for most of the cycle, rather
    // than mirroring each other about zero and never leaving it.
    expect(seenApart).toBeGreaterThan(20);
  });

  it('starts an authored aperture where it was told to', () => {
    // `PULSE_SHUT` is authored at 0.75 so that it is closed at t = 0 while its
    // partner at 0.25 is open. If the phase were not honoured the pair would be
    // two gates that happen to breathe, which is not a demand.
    const shut = oneSection({ ...APERTURE, motion: { kind: 'aperture', reach: 0.09, phase: 0.75 } });
    const open = oneSection({ ...APERTURE, motion: { kind: 'aperture', reach: 0.09, phase: 0.25 } });
    shut.animate(0);
    open.animate(0);
    const y = shut.sections[0]!.lineY;
    expect(openSpan(open, y)).toBeGreaterThan(openSpan(shut, y) * 1.4);
  });

  /**
   * An `aperture` pushes its blobs away from the geometry's own centroid, which is
   * the gap only when there is exactly one gap. On a multi-door shape the centroid
   * sits in the middle of the *field*, so the outer doors would widen while the
   * middle one pinched shut - the one way this feature can author something
   * narrower than the sweep checked.
   */
  it('keeps apertures off the shapes that have more than one door', () => {
    const MANY: string[] = ['sheet', 'flare', 'shear', 'wisps', 'drift', 'flurry', 'shrapnel'];
    for (const act of CAMPAIGN_ACTS) {
      for (const entry of act.script) {
        if (entry.spec.motion?.kind !== 'aperture') continue;
        expect(MANY, `${act.key} §${String(entry.level)}.${String(entry.step)}`).not.toContain(
          entry.spec.kind,
        );
      }
    }
  });

  it('leaves every still section in the campaign exactly as still as it was', () => {
    for (const act of CAMPAIGN_ACTS) {
      const o = new ObstacleSystem(W, 1, true, act);
      o.ensureAhead(act.direction * 1e6);
      const before = o.sections.filter((s) => s.motion === null).map((s) => s.blobs.map((b) => b.x));
      o.animate(4.2);
      const after = o.sections.filter((s) => s.motion === null).map((s) => s.blobs.map((b) => b.x));
      expect(after).toEqual(before);
    }
  });
});
