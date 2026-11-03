import { clamp } from '../core/math';
import type { ZonePaint } from './Paint';

/**
 * Slowblue: which film each act ends on.
 *
 * Seven acts, six seams and a closing, and none of them is a cut. Each act that
 * completes plays its own film, and the next act's first frame arrives *inside*
 * it rather than after it - the shoal is still climbing away through the sky when
 * act II's water is already the water, and the motes are still rising off the
 * flock when act III takes them. Each film owns the moment that happens, as
 * `handedOver` on its own clock; nothing outside counts seconds at it.
 *
 * > The branch this table replaced was `if (air) release else surfacing`, and it
 * > had a real bug in its `else`: an act with no film of its own got **act I's**,
 * > so finishing act III played an ocean surface breaking - caustics, spray and
 * > daylight - eighty kilometres above the sea. An act without a film gets
 * > silence, which is honest, until it has one.
 *
 * All seven have one now. The table is still a table rather than an assumption,
 * and `NO_FILM_BEAT` is still reachable, because "every act is filmed" is a fact
 * about the current campaign and not a property of the code.
 */

/** The films that exist, in the order the circuit plays them. */
export type FilmKind =
  | 'surfacing'
  | 'release'
  | 'karman'
  | 'overview'
  | 'nucleus'
  | 'estuary'
  | 'circle';

const FILMS: Record<string, FilmKind> = {
  /** `Surfacing`: the shoal breaks out, and act II opens over the sky movement. */
  water: 'surfacing',
  /** `Release`: the flock lets the gold go, and act III opens on the motes' rise. */
  air: 'release',
  /**
   * `Karman`: the air runs out, a stroke stops working, and the motes carry on
   * anyway. Act IV opens on that coast - and on the rule it was just taught.
   */
  thin: 'karman',
  /**
   * `Overview`: the camera turns, and act V opens as the gold comes over the top
   * of its arc. The handover is the stall itself - the frame where the campaign
   * stops climbing - so the fall the player watches begin is the fall they fly.
   */
  orbit: 'overview',
  /**
   * `Nucleus`: the burning dust cools, and what is left glowing inside it is the
   * gold. Act VI opens on the cloud that grows around it.
   */
  reentry: 'nucleus',
  /**
   * `Estuary`: fresh water meets salt, and the gold starts moving on its own for
   * the first time since act I. Act VII opens in the water it swims into.
   */
  rain: 'estuary',
  /**
   * `Circle`: the trench floor, the first shoal, and the title screen. The one
   * film that hands over to nothing, because there is nothing after it.
   */
  home: 'circle',
};

/**
 * Real seconds an act with no film of its own waits before handing over.
 *
 * The one case where a clock *is* the right answer: there is no film to ask, and
 * what is on screen is the run's own last frame. Long enough not to step on it,
 * short enough to read as a pause rather than as the game having stopped.
 */
export const NO_FILM_BEAT = 1.6;

/** Which film this act ends on, or null if it still ends on a cut. */
export function filmForAct(actKey: string): FilmKind | null {
  return FILMS[actKey] ?? null;
}

/**
 * Everything the renderer needs from an ending, and nothing about what it draws.
 *
 * This is a *shape*, not a base class, and the difference is deliberate. The
 * films share no drawing code at all - `Overview` and `Release` even keep their
 * own copies of the same atmosphere gradient - because a change to act II's
 * ending must never silently redraw act IV's. What they do share is how they are
 * driven: one clock each, owned by the film, read by everyone else.
 */
export interface Film {
  /** True from `begin()` until `reset()`. Only ever one at a time. */
  readonly active: boolean;
  /** Which movement is on screen. `main.ts` cues the act's sound off this. */
  readonly phase: string;
  /** True once the next act may open into this one's last movement. */
  readonly handedOver: boolean;
  /**
   * 0..1 how far the film has taken the frame off the live world.
   *
   * The renderer dims every live layer against the largest of these, and how far
   * each film takes it is one of the clearest statements any of them makes about
   * what it is.
   *
   * **Act I's ending is the only one that reaches 1, and it has to.** Above the
   * waterline there is no water: the underwater layers must go entirely or the
   * ending is a double exposure - a shoal and a set of canyon walls showing
   * through a sky. Every other film is still standing on the medium the run ended
   * in and stops short of covering it, most of all `Circle`, whose live world is
   * the same trench in the same palette and has nothing in it worth hiding.
   */
  readonly veil: number;
  /**
   * True once the film's picture has arrived and a title may sit over it.
   *
   * The closing banner waits for this. Every other banner opens a station; this
   * one closes an act, and a heading over a frame the film is still building is
   * a caption on an unfinished sentence.
   */
  readonly settled: boolean;
  /**
   * True when this film's picture is bright enough that a pale heading would
   * disappear into it.
   *
   * Only the closing banner asks, and only once, on the frame it is raised. It is
   * the film's own question because only the film knows what is behind the title:
   * the banner sits at 0.15 of the height, so what matters is the top of the
   * frame rather than the picture as a whole - act V's cloud deck is the
   * brightest thing in the game and it is nowhere near the heading.
   */
  readonly daylight: boolean;
  /**
   * Where on screen the film will accept its anchor, as fractions of the height.
   *
   * The anchor is where the player actually left the swarm, and every film wants
   * it somewhere different: the surface has to break high enough to leave a sky,
   * and the overview has to sit low enough to leave room for a planet.
   */
  readonly anchor: readonly [number, number];
  begin(): void;
  reset(): void;
  update(dt: number): void;
  draw(v: FilmView): void;
}

/** What a film is handed every frame. One shape for all seven. */
export interface FilmView {
  ctx: CanvasRenderingContext2D;
  /** The live palette, for the films that dissolve into the world rather than over it. */
  paint: ZonePaint;
  w: number;
  h: number;
  /** The renderer's clock, for twinkles and drifts that are not on the film's own. */
  time: number;
  /** Where the swarm was left. Every film starts its last movement from there. */
  x: number;
  y: number;
  /** 0..1 breath swell. A held frame is the one picture in the game that breathes. */
  breath: number;
  quality: number;
}

/**
 * Stable 0..1 from an integer.
 *
 * Shared because it is arithmetic rather than a decision: a film owns no state
 * and rolls no dice, so every scattered thing in one is a hash of its own index.
 */
export function filmHash(i: number): number {
  let h = Math.imul(i ^ 0x9e3779b9, 0x85ebca6b);
  h = Math.imul(h ^ (h >>> 13), 0xc2b2ae35);
  return ((h >>> 8) & 0xffff) / 0xffff;
}

/** Smooth 0..1 ramp between two absolute times on a film's clock. */
export function filmRamp(t: number, from: number, over: number): number {
  const u = clamp((t - from) / over, 0, 1);
  return u * u * (3 - 2 * u);
}
