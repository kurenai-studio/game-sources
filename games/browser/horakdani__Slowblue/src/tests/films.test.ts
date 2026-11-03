import { describe, expect, it } from 'vitest';
import { expectFinite, FakeContext } from './canvas';
import { ALL_ZONES } from '../src/config/zones';
import { CAMPAIGN_ACTS } from '../src/config/campaign';
import { paintFor } from '../src/render/Paint';
import { filmForAct, filmHash, type Film, type FilmKind, type FilmView } from '../src/render/Films';
import { Circle, CIRCLE_GATHER_AT, CIRCLE_SHOAL_AT, CIRCLE_TOTAL } from '../src/render/Circle';
import { Estuary, ESTUARY_QUICKEN_AT, ESTUARY_TOTAL } from '../src/render/Estuary';
import {
  Karman,
  KARMAN_COAST_SPEED,
  KARMAN_STROKE_AT,
  KARMAN_TOTAL,
} from '../src/render/Karman';
import { Nucleus, NUCLEUS_SEED_AT, NUCLEUS_TOTAL } from '../src/render/Nucleus';
import { Overview } from '../src/render/Overview';
import { Release } from '../src/render/Release';
import { Surfacing } from '../src/render/Surfacing';

const W = 390;
const H = 844;
/** Act VII's last band, which is act I's first. Every film that closes runs in it. */
const TRENCH = ALL_ZONES.length - 1;

interface Look {
  quality?: number;
  zone?: number;
}

function view(rec: FakeContext, time: number, look: Look = {}): FilmView {
  return {
    ctx: rec.as2d,
    paint: paintFor(look.zone ?? 20),
    w: W,
    h: H,
    time,
    x: W * 0.5,
    y: H * 0.45,
    breath: 0.5,
    quality: look.quality ?? 1,
  };
}

/** One frame at an absolute time on a film's clock, with nothing before it. */
function frameAt(make: () => Film, t: number, look: Look = {}): FakeContext {
  const rec = new FakeContext();
  const film = make();
  film.begin();
  film.update(t);
  film.draw(view(rec, t, look));
  return rec;
}

/** Runs a film at 60 Hz for `seconds` and hands back everything it drew. */
function playThrough(make: () => Film, seconds: number, look: Look = {}): FakeContext {
  const rec = new FakeContext();
  const film = make();
  film.begin();
  for (let i = 0; i * (1 / 60) <= seconds; i++) {
    film.update(1 / 60);
    film.draw(view(rec, i / 60, look));
  }
  return rec;
}

/**
 * The seven, by the kind they are registered under.
 *
 * Constructed here rather than imported from the renderer on purpose: the point
 * of the table below is that a film and its registration are two different facts
 * and both have to be true, and a test that got them from one place could not
 * tell the difference.
 */
const FILMS: { kind: FilmKind; make: () => Film }[] = [
  { kind: 'surfacing', make: () => new Surfacing() },
  { kind: 'release', make: () => new Release() },
  { kind: 'karman', make: () => new Karman() },
  { kind: 'overview', make: () => new Overview() },
  { kind: 'nucleus', make: () => new Nucleus() },
  { kind: 'estuary', make: () => new Estuary() },
  { kind: 'circle', make: () => new Circle() },
];

/** Which act ends on which film. The whole campaign's seam table, in one object. */
const ENDINGS: Record<string, FilmKind> = {
  water: 'surfacing',
  air: 'release',
  thin: 'karman',
  orbit: 'overview',
  reentry: 'nucleus',
  rain: 'estuary',
  home: 'circle',
};

describe('the campaign films', () => {
  /**
   * The bug the dispatch table replaced: an act with no film got act I's, so
   * finishing act III played an ocean surface breaking eighty kilometres above
   * the sea. No act may borrow another's ending, and none may be left without
   * one now that all seven exist.
   */
  it('gives every act its own ending, and never a different act it', () => {
    for (const act of CAMPAIGN_ACTS) {
      expect([act.key, filmForAct(act.key)]).toEqual([act.key, ENDINGS[act.key]]);
    }
    // ...and seven acts, seven distinct films. A shared one would be the same bug
    // wearing a table.
    const kinds = CAMPAIGN_ACTS.map((a) => filmForAct(a.key));
    expect(new Set(kinds).size).toBe(CAMPAIGN_ACTS.length);
    expect(kinds).toEqual(FILMS.map((f) => f.kind));
  });

  /** An act key nothing knows about falls back to the beat rather than to a film. */
  it('has no film for an act that does not exist', () => {
    expect(filmForAct('thermals')).toBeNull();
  });

  /**
   * Only act I's ending takes the world away completely, and it is the only one
   * that may: above the waterline there is no water, so the layers underneath
   * have to go entirely or the ending is a shoal and a set of canyon walls
   * showing through a sky. Every other film is standing on the medium the run
   * ended in - most of all the circle, whose live world is the same trench in
   * the same palette - and covering it would be throwing away the continuity the
   * handover is made of.
   */
  it('leaves the world underneath every ending except the one that leaves the water', () => {
    const deepest = (make: () => Film): number => {
      const film = make();
      film.begin();
      let most = 0;
      for (let i = 0; i < 60 * 30; i++) {
        most = Math.max(most, film.veil);
        film.update(1 / 60);
      }
      return most;
    };
    for (const { kind, make } of FILMS) {
      const veil = deepest(make);
      if (kind === 'surfacing') expect(veil).toBe(1);
      else expect(veil, kind).toBeLessThan(1);
    }
  });

  for (const { kind, make } of FILMS) {
    describe(kind, () => {
      it('does nothing at all until the act is finished', () => {
        const rec = new FakeContext();
        const film = make();
        expect(film.active).toBe(false);
        expect(film.veil).toBe(0);
        expect(film.settled).toBe(false);
        expect(film.handedOver).toBe(false);
        film.update(10);
        film.draw(view(rec, 0));
        expect(rec.fills + rec.strokes).toBe(0);
      });

      /**
       * A `NaN` in a path is invisible in a screenshot - Canvas2D drops the
       * subpath - so a geometry bug in a sequence the player sees once per
       * circuit would ship looking like "nothing happened".
       */
      it('draws finite geometry from the first frame to the last', () => {
        expectFinite(playThrough(make, 26), `${kind} full quality`);
        expectFinite(playThrough(make, 26, { quality: 0.35 }), `${kind} low quality`);
      });

      /**
       * The handover is the film's own to declare, on the film's own clock.
       * Nothing outside may count seconds at it: the films advance on `frameDt`,
       * which is a fixed step plus the frame's cost, and a `setTimeout` in real
       * seconds disagreed with them by about a factor of one and a half.
       */
      it('says when the next act may open, and holds its last frame past it', () => {
        const film = make();
        film.begin();
        let handover = -1;
        for (let i = 0; i < 60 * 60; i++) {
          film.update(1 / 60);
          if (handover < 0 && film.handedOver) handover = i / 60;
        }
        // Never instant, and never later than the film has frames for.
        expect(handover, `${kind} never hands over`).toBeGreaterThan(2);
        expect(handover).toBeLessThan(30);
        // ...and it holds rather than ending: a whole minute later there is still
        // a picture on screen for the next act to open into.
        const rec = new FakeContext();
        film.draw(view(rec, 60));
        expect(rec.fills + rec.strokes).toBeGreaterThan(0);
      });

      /**
       * ...and it hands over inside its **last** movement.
       *
       * This is the invariant that says a film has no content nobody can reach.
       * The moment `handedOver` goes true the next act opens and `syncZone`
       * resets every film, so anything a film would have done afterwards is
       * unreachable by construction - and that is not a hypothetical. `Karman`
       * shipped for an afternoon with four movements and a handover inside the
       * third, which made its fourth about three and a half seconds of picture
       * that no player could ever have seen. Nothing else in the suite had any
       * reason to notice.
       */
      it('hands over inside its last movement, so nothing it draws is unreachable', () => {
        const film = make();
        film.begin();
        let atHandover = '';
        for (let i = 0; i < 60 * 60; i++) {
          film.update(1 / 60);
          if (atHandover === '' && film.handedOver) atHandover = film.phase;
        }
        expect(atHandover, `${kind} never hands over`).not.toBe('');
        // `film.phase` after a minute is the held frame's, i.e. the last movement.
        expect(atHandover, `${kind} hands over before its last movement`).toBe(film.phase);
      });

      /**
       * The veil is how far the film has taken the frame off the live world, and
       * it only ever goes one way. How far it goes is the film's own business -
       * see the separate assertion below about which one reaches 1.
       */
      it('takes the frame off the live world monotonically', () => {
        const film = make();
        film.begin();
        let last = 0;
        let settled = false;
        for (let i = 0; i < 60 * 26; i++) {
          expect(film.veil).toBeGreaterThanOrEqual(last - 1e-9);
          expect(film.veil).toBeLessThanOrEqual(1);
          // ...and `settled` never goes back: a title raised over a picture must
          // not be raised over a frame that then stops being one.
          if (settled) expect(film.settled).toBe(true);
          settled = film.settled;
          last = film.veil;
          film.update(1 / 60);
        }
        expect(last).toBeGreaterThan(0.5);
        expect(settled).toBe(true);
      });
    });
  }
});

/**
 * Slowblue: the Karman line, and the one thing act IV has to be taught before it
 * starts.
 *
 * §7's handover is a single sentence - *the player's first stroke makes no wind,
 * and the motes carry on anyway, on the momentum they already had* - and both
 * halves of it are geometry rather than mood, so both are asserted here.
 */
describe('the Karman line', () => {
  /**
   * The half of the film that is a fact about physics: nothing accelerates.
   *
   * Drawn at low quality so the stars and the ice are skipped and the only
   * circles in the frame are the motes themselves. Every one of them is exactly
   * `COAST_SPEED * dt` higher than it was, which is what constant velocity looks
   * like when it is drawn honestly - and is the assertion that would fail the
   * moment anything up there started pushing.
   */
  it('carries the motes on at exactly the speed they already had', () => {
    const early = frameAt(() => new Karman(), 6, { quality: 0.3 }).arcs;
    const late = frameAt(() => new Karman(), 9, { quality: 0.3 }).arcs;
    expect(late.length).toBeGreaterThan(8);
    // The film's own number, for three seconds. What is being asserted is not
    // the value - it is that it is the *same* value at both ends.
    const shift = KARMAN_COAST_SPEED * 3;
    let checked = 0;
    for (const arc of late) {
      // A mote this high was below the frame three seconds ago and was culled.
      if (arc.y + shift > H + 40) continue;
      const was = early.find(
        (e) => Math.abs(e.y - (arc.y + shift)) < 1e-6 && Math.abs(e.r - arc.r) < 1e-9,
      );
      expect(was, `no mote at y=${String(arc.y + shift)} three seconds earlier`).toBeDefined();
      checked++;
    }
    expect(checked).toBeGreaterThan(6);
  });

  /**
   * The half that is a fact about the medium: the air stops carrying things, and
   * the ice it was carrying stops with it.
   *
   * Every grain's position is a function of `min(t, KARMAN_STROKE_AT)`, so after
   * the first movement they are pinned. Checked against the film's own hash
   * rather than by counting coincidences, because the star field is frozen too
   * and a test that could not tell them apart would pass on the wrong thing.
   */
  it('stops the ice dead when the air runs out, and never moves it again', () => {
    const iceY = (i: number): number => H * (0.12 + filmHash(i * 29 + 3) * 0.78) + Math.sin(i * 2.3) * 14;
    const at = (t: number): { x: number; y: number }[] =>
      frameAt(() => new Karman(), t).arcs.filter((a) =>
        // The ice is the only thing drawn on those lines.
        Array.from({ length: 26 }, (_, i) => iceY(i)).some((y) => Math.abs(a.y - y) < 1e-9),
      );
    const moving = at(KARMAN_STROKE_AT * 0.4);
    const stopped = at(KARMAN_STROKE_AT + 1);
    const held = at(KARMAN_TOTAL);
    expect(moving.length).toBeGreaterThan(10);
    expect(stopped.length).toBeGreaterThan(10);
    // While there is still air, no grain is where it was.
    const same = (a: { x: number; y: number }[], b: { x: number; y: number }[]): number =>
      a.filter((p) => b.some((q) => Math.abs(p.x - q.x) < 1e-9 && Math.abs(p.y - q.y) < 1e-9)).length;
    expect(same(moving, stopped)).toBe(0);
    // ...and once it has gone, every one of them is, for the rest of the film.
    expect(same(stopped, held)).toBe(stopped.length);
  });
});

/**
 * Slowblue: §9's transformation, and the campaign's one visual constant surviving it.
 *
 * The gold is in every act of this game (§3). Act V is the only one that could
 * have made a liar of that, because for five minutes the swarm is white-hot and
 * the gold is not what you can see. The film's job is to show that it was in
 * there the whole time.
 */
describe('the nucleus', () => {
  it('never lets the gold out of the frame, in fire or out of it', () => {
    for (const t of [0, 1, NUCLEUS_SEED_AT, NUCLEUS_TOTAL]) {
      const rec = frameAt(() => new Nucleus(), t);
      expect(
        rec.styles.some((s) => s.startsWith('rgba(255,233,178')),
        `no gold at t=${String(t)}`,
      ).toBe(true);
    }
  });

  /**
   * The trails retract, and they retract because the grain slowed down rather
   * than because anything switched them off. The streak is drawn only while the
   * grain is doing more than 20 px/s, which the brake curve stops being true of
   * inside two and a half seconds.
   */
  it('brakes the meteor into a dust grain, and the trails go with it', () => {
    expect(frameAt(() => new Nucleus(), 0.4).strokes).toBeGreaterThan(20);
    expect(frameAt(() => new Nucleus(), 4).strokes).toBe(0);
  });

  /** ...and then the water arrives, which is the only thing that strokes after that. */
  it('grows a droplet around every cooled grain', () => {
    const dry = frameAt(() => new Nucleus(), NUCLEUS_SEED_AT - 0.5);
    const wet = frameAt(() => new Nucleus(), NUCLEUS_SEED_AT + 2);
    expect(dry.styles.some((s) => s.startsWith('rgba(214,232,246,0.2'))).toBe(false);
    expect(wet.strokes).toBeGreaterThan(20);
  });
});

/**
 * Slowblue: the first thing in six acts that moves itself.
 *
 * Everything the campaign has done since the trench floor is the medium moving
 * bodies - that is the game's one sentence, and `Karman` is the film that says
 * so hardest. This is the film that takes it back.
 */
describe('the estuary', () => {
  /**
   * The transformation, as two colours: the droplet is left behind and the gold
   * is not. Checked on what was actually painted, because "the shell fades" and
   * "the shell is gone" are different claims and only the second one is the
   * handover.
   */
  it('leaves the droplet behind and keeps the gold', () => {
    const early = frameAt(() => new Estuary(), 1);
    const late = frameAt(() => new Estuary(), ESTUARY_TOTAL);
    const gold = (rec: FakeContext): boolean =>
      rec.styles.some((s) => s.startsWith('rgba(255,233,178'));
    const drop = (rec: FakeContext): boolean =>
      rec.styles.some((s) => s.startsWith('rgba(206,232,240,0.2'));
    expect(gold(early)).toBe(true);
    expect(gold(late)).toBe(true);
    expect(drop(early)).toBe(true);
    expect(drop(late)).toBe(false);
  });

  /**
   * Nothing has anatomy before it is alive. Cilia and tails are line segments and
   * a droplet is a circle, so the count of *path points* is the difference
   * between a bead of gold being carried and an animal - and counting strokes
   * would not have been: the shells stroke too, and the two happen to come out
   * even.
   */
  it('gives the gold a body only once it is swimming', () => {
    const carried = frameAt(() => new Estuary(), ESTUARY_QUICKEN_AT - 0.5);
    const alive = frameAt(() => new Estuary(), ESTUARY_QUICKEN_AT + 2.5);
    expect(alive.points.length).toBeGreaterThan(carried.points.length * 1.5);
  });
});

/**
 * Slowblue: the last sentence.
 *
 * §11: the camera and the background dissolve imperceptibly into the title
 * screen. That is a claim about two specific pictures being the same picture,
 * and `tests/zones.test.ts` already asserts the palettes close the circle; this
 * asserts the film actually lands on them.
 */
describe('the circle', () => {
  it('draws the trench floor in the rock act I opens on', () => {
    const rec = frameAt(() => new Circle(), CIRCLE_GATHER_AT, { zone: TRENCH });
    // `#05010e`, which is act VII's last band and act I's first.
    expect(rec.styles.some((s) => s.startsWith('rgba(5,1,14'))).toBe(true);
  });

  /**
   * The shoal forms out of the dark rather than appearing. Nothing with a fish in
   * it may be on screen before the fourth movement starts assembling one.
   */
  it('forms the first shoal out of individuals arriving', () => {
    const before = frameAt(() => new Circle(), CIRCLE_GATHER_AT - 0.2, { zone: TRENCH });
    const forming = frameAt(() => new Circle(), CIRCLE_GATHER_AT + 2, { zone: TRENCH });
    const whole = frameAt(() => new Circle(), CIRCLE_SHOAL_AT + 3, { zone: TRENCH });
    expect(forming.fills).toBeGreaterThan(before.fills);
    expect(whole.fills).toBeGreaterThan(forming.fills);
  });

  /**
   * And the frame it ends on. Act VII's water is lit warm, from the inside, by
   * what the player is carrying; act I's is lit cold by six thousand metres of
   * nothing. The last movement is that one colour changing back, and the held
   * frame has to arrive exactly on `#f0e7ff` or the dissolve into the title
   * screen is a cut with a colour shift in it.
   */
  it('ends on the shoal act I opens with, not the one act VII closes with', () => {
    const warm = frameAt(() => new Circle(), CIRCLE_GATHER_AT + 2, { zone: TRENCH });
    const home = frameAt(() => new Circle(), CIRCLE_TOTAL, { zone: TRENCH });
    const actI = (rec: FakeContext): boolean =>
      rec.styles.some((s) => s.startsWith('rgba(240,231,255'));
    expect(actI(warm)).toBe(false);
    expect(actI(home)).toBe(true);
  });
});
