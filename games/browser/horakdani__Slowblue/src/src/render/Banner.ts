import { stationDepthLabel, type Level } from '../config/levels';
import { clamp } from '../core/math';
import { rgba, type Rgb } from './Paint';

/** Seconds a level title stays on screen, fade included. */
export const BANNER_LIFE = 5;

/**
 * Where the banner sits, as a fraction of the frame's height.
 *
 * High on the screen: a level opens with an oncoming ring more often than not,
 * and a title sitting inside one turns two calm things into clutter.
 */
export const BANNER_AT = 0.15;

/**
 * Pale ink, for every act that opens or ends somewhere dark, and dark ink for
 * act I's daylit surface. Which one is in use is decided in `showBanner` from
 * the running film, not here; this only names them.
 */
const PALE: Rgb = [226, 248, 255];
const DARK: Rgb = [13, 52, 68];

export interface BannerView {
  ctx: CanvasRenderingContext2D;
  w: number;
  h: number;
  /** The act's stations, and which of them the banner names. */
  levels: readonly Level[];
  index: number;
  /** Seconds of life left, counting down from `BANNER_LIFE`. */
  life: number;
  /** Closing an act - or, inside a circuit, closing the circuit. */
  final: boolean;
  /** Whether the picture underneath is daylit, which decides the ink. */
  dark: boolean;
}

/**
 * The level title, over the open water each level opens with. Long, slow and
 * quiet: it fades in over three quarters of a second and takes two to leave, so
 * it never arrives as an interruption.
 *
 * This is the only text in the game drawn on the canvas rather than laid out by
 * the shell, which is why it carries its own two inks: the film underneath is
 * anything from a black sky to a sunlit river, and `showBanner` picks between
 * them once, from the film, rather than every frame.
 */
export function drawBanner(v: BannerView): void {
  const { ctx } = v;
  const age = BANNER_LIFE - v.life;
  const a = Math.min(clamp(age / 0.75, 0, 1), clamp(v.life / 2, 0, 1));
  if (a <= 0) return;
  const index = Math.min(v.levels.length - 1, v.index);
  const level = v.levels[index]!;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  const cy = v.h * BANNER_AT;
  const x = v.w * 0.5;
  // Dark ink over a daylit ending, pale ink everywhere else. Act I ends on a
  // bright sky and a white heading on one is a heading nobody reads; every
  // other act ends on space, on cloud seen from a height the title never
  // reaches, or on the trench floor - where the opposite is true and the pale
  // default is correct. Decided in `showBanner`; see `Film.daylight`.
  const tone: Rgb = v.dark ? DARK : PALE;

  /** One line of the banner. */
  const say = (text: string, size: number, weight: number, alpha: number, dy: number): void => {
    ctx.font = `${weight} ${size}px ui-sans-serif, system-ui, sans-serif`;
    ctx.fillStyle = rgba(tone, alpha * a);
    ctx.fillText(text, x, cy + dy);
  };

  const eyebrow = v.final ? 'MISSION COMPLETE' : `STATION ${index + 1} / ${v.levels.length}`;
  say(eyebrow, 10, 500, 0.44, -27);
  say(level.name.toUpperCase(), 15, 600, 0.78, -6);
  say(stationDepthLabel(v.levels, index), 9, 500, 0.46, 14);
  say(level.subtitle, 10, 400, 0.38, 31);

  // The rule draws itself outward from the middle as the banner lands.
  const half = 54 * Math.min(1, age / 1.1);
  ctx.strokeStyle = rgba(tone, 0.24 * a);
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(x - half, cy + 43);
  ctx.lineTo(x + half, cy + 43);
  ctx.stroke();

  ctx.textAlign = 'left';
  ctx.textBaseline = 'top';
}
