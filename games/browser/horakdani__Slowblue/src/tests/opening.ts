import { World } from '../src/sim/World';
import { ACT_WATER } from '../src/config/levels';
import { DEFAULT_TUNING } from '../src/config/tuning';
import type { Policy } from './bot';
import { H, W } from './helpers';

/**
 * Slowblue: the first ninety seconds, which is the only part of this game most
 * people will ever see.
 *
 * Every other probe in this repo asks whether the campaign is *playable* -
 * whether a wall can be flown, whether skill pays, whether a station's numbers
 * are the ones its neighbours were measured against. None of them asks the
 * question a store editor asks, which is a question about **order and rate**: in
 * the minute and a half they will watch, what does the water show, when does it
 * show it, and is there a stretch in there where nothing new happens.
 *
 * ## What a mark is
 *
 * A mark is the *first* time the player is shown something they have not been
 * shown before - an archetype coming into view, a ring going in, a fish lost, a
 * station changing. First occurrence only: the second rock teaches nothing, so
 * it is not on the timeline. That makes the interesting number the **gap**, and
 * the gap is what this file is really for. A ninety-second opening with fifteen
 * marks in the first twenty seconds and nothing after is worse than one with
 * eight spread evenly, and no aggregate - marks per minute, sections cleared,
 * score - can tell those two apart.
 *
 * ## What it cannot see
 *
 * The picture and the shell. The ident, the sound card, the title screen and the
 * banner are all in front of - or on top of - the first ninety seconds, and the
 * clock here starts after all of them, at the first simulated frame. What that
 * front matter costs is measured in `e2e/measure.spec.ts` (`first launch`) and
 * `e2e/chrome.spec.ts` (the card); this file's t=0 is that file's `playing`.
 *
 * `tools/onboarding.sweep.ts` reports off this; `tests/onboarding.test.ts`
 * defends what it reported.
 */

export const DT = 1 / 60;
/** The window. Ninety seconds is a store editor's attention, not a design unit. */
export const WINDOW_S = 90;

/** Everything a first ninety seconds can put in front of a player, once each. */
export type MarkKind =
  // the verb
  | 'stroke'
  | 'field'
  // the ask
  | 'ring-required'
  | 'ring-optional'
  | 'rescue'
  | 'gate'
  // the alphabet, in the order the authored act happens to introduce it
  | 'obstacle-gate'
  | 'obstacle-rock'
  | 'obstacle-narrows'
  | 'obstacle-drift'
  | 'obstacle-vortex'
  | 'obstacle-predator'
  // consequence
  | 'loss'
  | 'bite'
  | 'reform'
  | 'streak-break'
  | 'multiplier'
  // the journey
  | 'level'
  | 'zone'
  | 'restart'
  | 'fail';

export interface Mark {
  kind: MarkKind;
  /** Simulated seconds since the first frame of play. */
  at: number;
}

export interface Opening {
  marks: Mark[];
  /** Longest stretch with no first-of-its-kind anything, in seconds. */
  quietest: number;
  /** ...and when it started. */
  quietestAt: number;
  /** Share of the frames actually run with nothing on the glass, as a percentage. */
  emptyPct: number;
  /** Longest continuous stretch of that, in seconds. */
  emptiest: number;
  emptiestAt: number;
  /** When each station handed over to the next one. */
  stations: number[];
  /** Where the run got to, so a short timeline can be told from a dense one. */
  seconds: number;
  sections: number;
  station: number;
  count: number;
  reason: string | null;
}

/**
 * Is anything the player has to deal with actually drawn right now?
 *
 * Screen space, not world space: the question is what is on the glass, and the
 * camera is what decides that. A blob's radius counts, because half a rock at
 * the top of the frame is a rock the player is looking at.
 *
 * What it deliberately does not count is the picture: the water, the tracers,
 * the decorative life and the shoal itself are always there, so an "empty" frame
 * here is a frame with nothing *asked* of the player, not a blank one. That is
 * the number a rest has to be judged on - a breath is empty of demands by
 * definition, and the question is only ever how long one runs for.
 */
function occupied(world: World): boolean {
  for (const s of world.obstacles.sections) {
    for (const b of s.blobs) {
      const y = world.worldToScreenY(b.y);
      if (y + b.r > 0 && y - b.r < H) return true;
    }
  }
  for (const p of world.rescue.pods) {
    if (p.merged) continue;
    const y = world.worldToScreenY(p.y);
    if (y + p.radius > 0 && y - p.radius < H) return true;
  }
  for (const p of world.predators.predators) {
    const y = world.worldToScreenY(p.y);
    if (y + p.size > 0 && y - p.size < H) return true;
  }
  return false;
}

/** A pod of this kind is on the glass and has not been taken yet. */
function podOnGlass(world: World, required: boolean): boolean {
  for (const p of world.rescue.pods) {
    if (p.merged || p.required !== required) continue;
    const y = world.worldToScreenY(p.y);
    if (y + p.radius > 0 && y - p.radius < H) return true;
  }
  return false;
}

/** The archetype of every section whose geometry is on the glass. */
function archetypesOnGlass(world: World, out: Set<string>): void {
  out.clear();
  for (const s of world.obstacles.sections) {
    for (const b of s.blobs) {
      const y = world.worldToScreenY(b.y);
      if (y + b.r > 0 && y - b.r < H) {
        out.add(s.kind);
        break;
      }
    }
  }
}

const ARCHETYPES = ['gate', 'rock', 'narrows', 'drift', 'vortex', 'predator'] as const;

export function openingOf(seed: number, policy: Policy, seconds = WINDOW_S): Opening {
  const budget = Math.round(seconds / DT);
  const world = new World(W, H, seed, { ...DEFAULT_TUNING }, true, ACT_WATER);
  const marks: Mark[] = [];
  const seen = new Set<MarkKind>();
  const mark = (kind: MarkKind): void => {
    if (seen.has(kind)) return;
    seen.add(kind);
    marks.push({ kind, at: Number(world.run.time.toFixed(2)) });
  };

  const kinds = new Set<string>();
  let frames = 0;
  let emptyFrames = 0;
  let emptyRun = 0;
  let emptiest = 0;
  let emptiestAt = 0;
  let station = 0;
  const stations: number[] = [];

  for (let i = 0; i < budget && world.run.phase === 'running'; i++) {
    policy(world, DT);
    world.step(DT);
    frames++;

    for (const e of world.takeEvents()) {
      switch (e.type) {
        case 'rescue':
          mark('rescue');
          break;
        case 'gate':
          mark('gate');
          break;
        case 'loss':
          mark('loss');
          break;
        case 'bite':
          mark('bite');
          break;
        case 'reform':
          mark('reform');
          break;
        case 'streakBreak':
          mark('streak-break');
          break;
        case 'level':
          mark('level');
          stations.push(Number(world.run.time.toFixed(1)));
          break;
        case 'zone':
          mark('zone');
          break;
        case 'restart':
          mark('restart');
          break;
        case 'fail':
          mark('fail');
          break;
        default:
          break;
      }
    }

    // `hasInput`, not `gestureCount`: the counter is bumped by `InputController`
    // when a real pointer goes down, and nothing here has a pointer. What the
    // simulation knows about is that a stroke was laid in it.
    if (world.hasInput) mark('stroke');
    // The ocean's own current, which is a thing the player is shown rather than
    // told: the tracers only mean anything once the field is actually moving.
    if (world.field.meanSpeed() > 1) mark('field');
    if (world.run.multiplier > 1) mark('multiplier');
    if (podOnGlass(world, true)) mark('ring-required');
    if (podOnGlass(world, false)) mark('ring-optional');
    archetypesOnGlass(world, kinds);
    for (const k of ARCHETYPES) if (kinds.has(k)) mark(`obstacle-${k}`);

    if (occupied(world)) {
      emptyRun = 0;
    } else {
      emptyFrames++;
      emptyRun += DT;
      if (emptyRun > emptiest) {
        emptiest = emptyRun;
        emptiestAt = world.run.time - emptyRun;
      }
    }
    station = Math.max(station, world.levelIndex);
  }

  // The gap that matters is measured against the end of the window, not against
  // the last mark: a timeline whose last new thing lands at 40 s has fifty
  // seconds of nothing after it, and stopping the tape at the last mark would
  // report that as its best stretch.
  let quietest = 0;
  let quietestAt = 0;
  let prev = 0;
  for (const at of [...marks.map((m) => m.at), world.run.time]) {
    if (at - prev > quietest) {
      quietest = at - prev;
      quietestAt = prev;
    }
    prev = at;
  }

  return {
    marks,
    quietest: Number(quietest.toFixed(1)),
    quietestAt: Number(quietestAt.toFixed(1)),
    emptyPct: Number(((emptyFrames / Math.max(1, frames)) * 100).toFixed(1)),
    emptiest: Number(emptiest.toFixed(1)),
    emptiestAt: Number(emptiestAt.toFixed(1)),
    stations,
    seconds: Number(world.run.time.toFixed(1)),
    sections: world.run.furthestSection + 1,
    station,
    count: world.shoalCount,
    reason: world.run.reason,
  };
}

/** When a mark landed, or `null` if the run never got to it. */
export function firstAt(o: Opening, kind: MarkKind): number | null {
  return o.marks.find((m) => m.kind === kind)?.at ?? null;
}

export function timeline(o: Opening): string {
  return o.marks.map((m) => `${m.at.toFixed(1).padStart(5)} ${m.kind}`).join('\n');
}
