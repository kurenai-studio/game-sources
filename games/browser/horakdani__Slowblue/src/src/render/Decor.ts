import type { DecorTheme } from '../config/levels';
import { TAU } from '../core/math';
import { Rng } from '../core/rng';
import { rgba, type Rgb, type ZonePaint } from './Paint';

/**
 * Slowblue: the life that is not in the way.
 *
 * Nothing in this file is readable by the simulation and nothing in it can touch
 * a fish. It exists because a course made only of things that can kill you reads
 * as a test, and the game wants to read as a place: seagrass turning over in the
 * current, a jellyfish going the other way, bubbles leaving for a surface you can
 * no longer see.
 *
 * Three rules keep it from turning into noise, which is the only real risk:
 *   - it is drawn at a tenth of the contrast of anything that matters,
 *   - every element is one path of thin strokes, no fills and no colour of its own
 *     (it borrows the zone palette, so it is always *in* the water, never on it),
 *   - it never crosses the middle of the play field where the shoal lives, except
 *     for the drifting kinds, which are transparent enough to see fish through.
 *
 * It is generated in bands the same way the course is, so it scrolls forever and
 * costs nothing to leave behind.
 */

type ElementKind =
  | 'grass'
  | 'fan'
  | 'urchin'
  | 'jelly'
  | 'bubbles'
  | 'ripple'
  | 'shard'
  | 'drift'
  /** Something very large passing a long way off. Never resolves, never returns. */
  | 'leviathan';

interface Element {
  kind: ElementKind;
  x: number;
  y: number;
  /** Base size in px. */
  size: number;
  /** 0 = right against the camera, 1 = far behind everything. */
  depth: number;
  /** Per-element animation offset, so nothing in a band breathes in step. */
  phase: number;
  /** -1 / 1, for the kinds that lean or swim. */
  dir: number;
  seed: number;
}

interface Band {
  /**
   * World Y of the band's near edge. Bands are laid in the act's own course
   * direction: toward -Y in the four acts that climb, toward +Y in the three that
   * fall.
   *
   * Slowblue: this said "toward -Y like everything else" and the loop below did
   * exactly that, which is a description of a bug rather than of a rule. Nothing
   * else in the engine hard-codes -Y - `World.u()` exists precisely so that
   * pruning, the camera, the spawn line and the section crossing all read one
   * signed direction - and this was the one surface that never got it. The
   * consequence was total rather than subtle: on a falling course the growth loop
   * exits on its first test and the whole decorative layer of acts V, VI and VII
   * never renders. Act VII's medusae, drifting particulate and trench shards have
   * never been on screen.
   */
  y: number;
  elements: Element[];
}

const BAND_HEIGHT = 620;
/** Elements per band at full quality. Deliberately sparse - this is not a garden. */
const PER_BAND = 4;

/**
 * How far outside the frame an element is still worth drawing, and therefore how
 * far outside it a *band* is still worth keeping.
 *
 * Slowblue: this was 260, chosen for the small decor, and the one element it is
 * actually about is the one it was too small for. A `leviathan` fills a radial
 * gradient of `len * 0.5` about its own anchor, and with `size` up to 2.8 in the
 * far layer that is 328px - so the largest thing in the water was culled whole
 * while a third of a screen of it was still inside the frame. Something the size
 * of the screen does not fade out at the edge; it was there and then it was not.
 */
const ELEMENT_REACH = 360;

/**
 * The slowest parallax rate in `draw`.
 *
 * A slow layer is the one that decides how long a band has to be kept: an element
 * at world offset D shows at screen `D * rate`, so at 0.72 the world band the
 * screen can see is 1/0.72 of the screen, not one screen. Keying the prune to the
 * screen height directly - which is what `height * 1.2` was - throws away bands
 * whose elements are still a third of the way down the frame.
 */
const SLOWEST_RATE = 0.72;

/**
 * A distant silhouette crosses the full field as its world-anchored Y travels
 * through the visible band. Keeping this pure also makes the off-screen endpoints
 * explicit: nothing may pop into existence at an edge.
 */
export function distantPassageX(
  screenY: number,
  height: number,
  width: number,
  extent: number,
  dir: number,
): number {
  const margin = 260;
  const t = Math.max(0, Math.min(1, (screenY + margin) / (height + margin * 2)));
  const from = dir >= 0 ? -extent : width + extent;
  const to = dir >= 0 ? width + extent : -extent;
  return from + (to - from) * t;
}

/**
 * What each level's theme is allowed to grow, how thickly, and what may pass
 * behind it. `passing` fires at most once every few bands, so a leviathan is
 * something you might see once in a level and might miss entirely - which is the
 * only way an event that cannot be interacted with stays worth having.
 */
const THEMES: Record<
  DecorTheme,
  { kinds: ElementKind[]; density: number; passing: ElementKind | null; chance: number }
> = {
  kelp: {
    kinds: ['bubbles', 'bubbles', 'ripple', 'grass', 'fan'],
    density: 1,
    passing: 'leviathan',
    chance: 0.1,
  },
  meadow: {
    kinds: ['bubbles', 'grass', 'fan', 'ripple'],
    density: 0.9,
    passing: 'leviathan',
    chance: 0.08,
  },
  jelly: {
    kinds: ['jelly', 'jelly', 'bubbles', 'drift'],
    density: 0.8,
    passing: 'leviathan',
    chance: 0.14,
  },
  /**
   * Open midwater. `shard` is the trench's own element - mineral, angular, the
   * one decor with a straight line in it - and it was dressing three stations of
   * open water, worst at Marine Snow, whose whole subject is that everything in
   * the frame is falling together. A medusa is the commonest large thing at two to
   * four thousand metres and is already classed as drifting.
   */
  abyss: {
    kinds: ['drift', 'drift', 'jelly'],
    density: 0.34,
    passing: null,
    chance: 0,
  },
  garden: {
    kinds: ['bubbles', 'bubbles', 'jelly', 'drift', 'fan'],
    density: 0.9,
    passing: 'leviathan',
    chance: 0.1,
  },
  trench: {
    // `urchin` is implemented, drawn, and was in no theme at all - the one
    // element in the file that says 'lived on' rather than 'broken off', which is
    // exactly what the campaign's first frame and its last one are about.
    kinds: ['shard', 'shard', 'urchin', 'drift'],
    density: 0.56,
    passing: null,
    chance: 0,
  },
  /**
   * Nothing. Thin air, vacuum, plasma and open sky, which is three whole acts.
   *
   * Every element kind in this file is marine or organic, because for two acts
   * every station was, and the campaign's new acts inherited `meadow` as a
   * default - so the shipped build grew seagrass at 82 km, sea fans in orbit and
   * a passing leviathan inside a re-entry sheath. There is no plausible thing to
   * put there instead, and that is the correct answer rather than a gap: what is
   * in those frames is the sky, the planet and the swarm, and the design says in
   * as many words that the picture empties out on the way up.
   */
  void: { kinds: [], density: 0, passing: null, chance: 0 },
  /**
   * Act VI's forest, seen from inside the rain coming through it. Leaves and
   * fronds, nothing that swims, and nothing large enough to pass.
   */
  canopy: {
    // No `drift`. Its own comment two lines up says 'nothing large enough to
    // pass', and `drift` is documented as something large and far away crossing -
    // in a forest, seen from inside the rain coming through it.
    kinds: ['fan', 'fan', 'grass', 'grass'],
    density: 0.9,
    passing: null,
    chance: 0,
  },
  /**
   * Running fresh water. Bubbles and surface ripple are exactly right in a
   * mountain brook and are the two things `garden` had that belonged there; a
   * jellyfish, which is what it also had, is not.
   */
  stream: {
    // ...and none in a mountain brook either, for the same reason.
    kinds: ['bubbles', 'bubbles', 'ripple', 'ripple'],
    density: 0.9,
    passing: null,
    chance: 0,
  },
};

export class Decor {
  private bands: Band[] = [];
  private frontierY = 0;
  private theme: DecorTheme = 'kelp';
  private rng = new Rng(0xd3c0);
  /** Rises to 1 over a couple of seconds when the theme changes, so nothing pops. */
  private fade = 1;
  /** The act's course direction: -1 climbing, +1 falling. See `Band.y`. */
  private dir: -1 | 1 = -1;

  reset(seed: number, theme: DecorTheme, cameraY: number, dir: -1 | 1 = -1): void {
    this.rng = new Rng(seed ^ 0xd3c0);
    this.bands = [];
    this.frontierY = Math.ceil(cameraY / BAND_HEIGHT) * BAND_HEIGHT;
    this.theme = theme;
    this.fade = 1;
    this.dir = dir;
  }

  /** A level change re-dresses the water; the crossfade is what hides the swap. */
  setTheme(theme: DecorTheme): void {
    if (theme === this.theme) return;
    this.theme = theme;
    this.fade = 0;
  }

  update(cameraY: number, height: number, dt: number, quality: number): void {
    this.fade = Math.min(1, this.fade + dt * 0.4);
    // Grow toward the direction of travel and prune what is behind, both signed.
    // `(a - b) * dir < 0` is "a is behind b in course terms" and is the same test
    // `ObstacleSystem.prune` and `PredatorSystem.prune` already use.
    const ahead = cameraY + this.dir * height * 1.4;
    while ((this.frontierY - ahead) * this.dir < 0) {
      this.bands.push(this.buildBand(this.frontierY, quality));
      this.frontierY += this.dir * BAND_HEIGHT;
    }
    /*
     * A band is kept while any element it could hold might still be on the glass.
     *
     * Direction-free, and both halves of that matter. `buildBand` places elements
     * anywhere in `[y - BAND_HEIGHT, y]` whichever way the act runs - the offset is
     * toward -Y on a climb *and* on a descent - so the band's own anchor is not
     * where its contents are, and a test on the anchor alone drops elements that
     * are still most of a screen inside the frame. The visible world band is then
     * wider than the screen by `1 / SLOWEST_RATE`, because that is what parallax
     * does to a distance.
     */
    const nearY = cameraY - ELEMENT_REACH / SLOWEST_RATE;
    const farY = cameraY + (height + ELEMENT_REACH) / SLOWEST_RATE;
    while (this.bands.length > 0) {
      const b = this.bands[0]!;
      if (b.y >= nearY && b.y - BAND_HEIGHT <= farY) break;
      this.bands.shift();
    }
  }

  private buildBand(y: number, quality: number): Band {
    const theme = THEMES[this.theme];
    const rng = this.rng.fork(Math.round(-y / BAND_HEIGHT) + 1);
    // A theme may legitimately grow nothing - see `void` - and an empty band is
    // the whole content of three acts rather than a failure to fill one.
    if (theme.kinds.length === 0) return { y, elements: [] };
    const count = Math.max(1, Math.round(PER_BAND * theme.density * quality));
    const elements: Element[] = [];
    for (let i = 0; i < count; i++) {
      const kind = theme.kinds[rng.int(0, theme.kinds.length)]!;
      const drifting = kind === 'jelly' || kind === 'drift' || kind === 'bubbles';
      // Rooted things hug the edges; drifting things may cross anywhere, because
      // you can see through them.
      const edge = rng.next() < 0.5 ? rng.range(0.02, 0.2) : rng.range(0.8, 0.98);
      elements.push({
        kind,
        x: drifting ? rng.range(0.06, 0.94) : edge,
        y: y - rng.next() * BAND_HEIGHT,
        size: rng.range(0.7, 1.35),
        depth: rng.next(),
        phase: rng.next() * TAU,
        dir: rng.next() < 0.5 ? -1 : 1,
        seed: rng.int(0, 9999),
      });
    }
    // ...and, rarely, something the size of the screen going the other way.
    if (theme.passing !== null && rng.next() < theme.chance) {
      elements.push({
        kind: theme.passing,
        x: rng.range(-0.1, 1.1),
        y: y - rng.next() * BAND_HEIGHT,
        size: rng.range(1.6, 2.8),
        // Always in the far layer. It has to be behind the rock, or it is a hazard.
        depth: 0.92,
        phase: rng.next() * TAU,
        dir: rng.next() < 0.5 ? -1 : 1,
        seed: rng.int(0, 9999),
      });
    }
    return { y, elements };
  }

  /**
   * `layer` 0 is drawn behind the course, layer 1 in front of it and behind the
   * shoal. Splitting by depth is what gives the water a middle distance: a
   * jellyfish that passes in front of a rock is in the same room as the rock.
   */
  draw(
    ctx: CanvasRenderingContext2D,
    paint: ZonePaint,
    width: number,
    height: number,
    cameraY: number,
    time: number,
    layer: 0 | 1,
  ): void {
    if (this.bands.length === 0) return;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    for (const band of this.bands) {
      for (const e of band.elements) {
        const far = e.depth > 0.5;
        if ((far ? 0 : 1) !== layer) continue;
        // Parallax: far things scroll slower, which is the whole trick. The band
        // that owns an element is pruned on its world position, so a slow layer
        // simply lives on screen for longer.
        const rate = far ? 0.72 : 0.94;
        const sy = (e.y - cameraY) * rate;
        if (sy < -ELEMENT_REACH || sy > height + ELEMENT_REACH) continue;
        const x = e.x * width;
        const scale = e.size * (far ? 0.78 : 1);
        const alpha = (far ? 0.055 : 0.085) * this.fade;
        this.drawElement(ctx, paint, e, x, sy, scale, alpha, time, width, height);
      }
    }
    ctx.setLineDash([]);
  }

  private drawElement(
    ctx: CanvasRenderingContext2D,
    paint: ZonePaint,
    e: Element,
    x: number,
    y: number,
    scale: number,
    alpha: number,
    t: number,
    width: number,
    height: number,
  ): void {
    const tint: Rgb = e.kind === 'shard' ? paint.tracer : paint.speck;
    const sway = Math.sin(t * 0.34 + e.phase);
    switch (e.kind) {
      case 'grass': {
        // Seagrass from above: a few blades from one root, each curling off in its
        // own direction and all of them leaning the same way in the current.
        //
        // Slowblue: the first version drew five parallel quadratics of equal length,
        // which on screen is a hatch mark - it read as a scratch on the glass
        // rather than as something growing. Blades now fan from a single point,
        // differ in length, and end in a curl, which is the difference between a
        // line and a plant.
        const blades = 4;
        ctx.strokeStyle = rgba(tint, alpha * 1.15);
        ctx.lineWidth = 1.2;
        ctx.beginPath();
        for (let i = 0; i < blades; i++) {
          const fan = (i / (blades - 1) - 0.5) * 1.5 + e.dir * 0.25;
          const len = (44 + ((e.seed + i * 37) % 30)) * scale;
          const lean = sway * (10 + i * 2) * scale;
          const tipX = x + Math.sin(fan) * len + lean;
          const tipY = y - Math.cos(fan) * len;
          ctx.moveTo(x, y + 6 * scale);
          ctx.bezierCurveTo(
            x + Math.sin(fan) * len * 0.2,
            y - len * 0.35,
            tipX - lean * 0.7,
            y - len * 0.72,
            tipX,
            tipY,
          );
        }
        ctx.stroke();
        break;
      }
      case 'fan': {
        // A fan coral: three arcs sharing a centre, opening away from the wall.
        const r = 30 * scale;
        const face = x < width * 0.5 ? 0 : Math.PI;
        ctx.strokeStyle = rgba(tint, alpha * 1.2);
        ctx.lineWidth = 1.1;
        for (let i = 1; i <= 3; i++) {
          ctx.beginPath();
          ctx.arc(x, y, (r * i) / 3, face - 1.05 + sway * 0.06, face + 1.05 + sway * 0.06);
          ctx.stroke();
        }
        break;
      }
      case 'urchin': {
        const r = 15 * scale;
        ctx.strokeStyle = rgba(tint, alpha);
        ctx.lineWidth = 1;
        ctx.beginPath();
        for (let i = 0; i < 11; i++) {
          const a = (i / 11) * TAU + e.phase * 0.1;
          ctx.moveTo(x + Math.cos(a) * r * 0.4, y + Math.sin(a) * r * 0.4);
          ctx.lineTo(x + Math.cos(a) * r, y + Math.sin(a) * r);
        }
        ctx.stroke();
        break;
      }
      case 'jelly': {
        // Seen from above: a bell that opens and closes, trailing four threads.
        const pulse = 0.82 + 0.18 * Math.sin(t * 0.7 + e.phase);
        const r = 21 * scale * pulse;
        ctx.strokeStyle = rgba(tint, alpha * 1.5);
        ctx.lineWidth = 1.2;
        ctx.beginPath();
        ctx.arc(x, y, r, 0, TAU);
        ctx.moveTo(x + r * 0.62, y);
        ctx.arc(x, y, r * 0.62, 0, TAU);
        ctx.stroke();
        ctx.strokeStyle = rgba(tint, alpha * 0.8);
        ctx.lineWidth = 0.9;
        ctx.beginPath();
        for (let i = 0; i < 4; i++) {
          const a = (i / 4) * TAU + e.phase;
          const trail = r * (1.9 + 0.5 * Math.sin(t * 0.5 + i));
          ctx.moveTo(x + Math.cos(a) * r * 0.7, y + Math.sin(a) * r * 0.7);
          ctx.quadraticCurveTo(
            x + Math.cos(a) * trail * 0.7 + sway * 4,
            y + Math.sin(a) * trail * 0.7,
            x + Math.cos(a + 0.4) * trail,
            y + Math.sin(a + 0.4) * trail,
          );
        }
        ctx.stroke();
        break;
      }
      case 'bubbles': {
        // A slow column leaving for the surface. They shrink as they go, because
        // "up" in a top-down view is toward the camera, and that reads as scale.
        ctx.strokeStyle = rgba(tint, alpha * 1.6);
        ctx.lineWidth = 1;
        ctx.beginPath();
        for (let i = 0; i < 5; i++) {
          const k = ((t * 0.16 + i * 0.2 + e.phase * 0.1) % 1 + 1) % 1;
          const r = (7 - k * 5.2) * scale;
          if (r <= 0.4) continue;
          const bx = x + Math.sin(k * 5 + e.phase) * 7 * scale;
          const by = y + (0.5 - k) * 30 * scale;
          ctx.moveTo(bx + r, by);
          ctx.arc(bx, by, r, 0, TAU);
        }
        ctx.stroke();
        break;
      }
      case 'ripple': {
        // Sand ripples on the bed, far below. Pure texture, never moves. Kept short
        // and strongly curved: a long shallow one is a straight line with extra
        // steps, and straight lines are the one thing the ocean does not have.
        ctx.strokeStyle = rgba(tint, alpha * 0.6);
        ctx.lineWidth = 1.6;
        const w = 52 * scale;
        ctx.beginPath();
        for (let i = 0; i < 3; i++) {
          const yy = y + i * 15 * scale;
          const bow = (13 + i * 3) * scale * e.dir;
          ctx.moveTo(x - w * 0.5, yy);
          ctx.quadraticCurveTo(x, yy + bow, x + w * 0.5, yy);
        }
        ctx.stroke();
        break;
      }
      case 'shard': {
        // The trench: mineral, angular, and the only decor with a straight line.
        const h = 46 * scale;
        const w = 13 * scale;
        ctx.strokeStyle = rgba(tint, alpha * 1.3);
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.moveTo(x, y - h * 0.5);
        ctx.lineTo(x + w * e.dir, y);
        ctx.lineTo(x, y + h * 0.5);
        ctx.lineTo(x - w * 0.55 * e.dir, y + h * 0.1);
        ctx.closePath();
        ctx.stroke();
        break;
      }
      case 'leviathan': {
        // Something very large, a long way off, crossing. Canvas2D has no cheap
        // blur, so the softness is faked the way distance actually works: the body
        // is filled with a gradient that never reaches its own edge, so there is no
        // edge to see. It reads as mass without ever resolving into an animal.
        const len = 300 * scale;
        const th = 52 * scale;
        const cx =
          distantPassageX(y, height, width, len * 0.55, e.dir) +
          Math.sin(t * 0.021 + e.phase) * 18;
        const cy = y + Math.sin(t * 0.05 + e.phase) * 9;
        const g = ctx.createRadialGradient(cx, cy, 0, cx, cy, len * 0.5);
        // Twice the alpha of the small decor: at 0.08 it was invisible against
        // the gradient, and something the size of the screen has to at least be
        // *noticed* passing, even if it never resolves.
        g.addColorStop(0, rgba(tint, alpha * 3.4));
        g.addColorStop(0.55, rgba(tint, alpha * 1.7));
        g.addColorStop(1, rgba(tint, 0));
        ctx.fillStyle = g;
        // Body: a long lens shape, and a tail that flexes on its own slow clock.
        const beat = Math.sin(t * 0.28 + e.phase) * th * 0.5;
        ctx.beginPath();
        ctx.moveTo(cx - len * 0.5, cy + beat * 0.35);
        ctx.quadraticCurveTo(cx - len * 0.1, cy - th, cx + len * 0.42, cy - th * 0.16);
        ctx.quadraticCurveTo(cx + len * 0.52, cy, cx + len * 0.5, cy + th * 0.5);
        ctx.quadraticCurveTo(cx + len * 0.2, cy + th * 0.2, cx - len * 0.12, cy + th * 0.75);
        ctx.quadraticCurveTo(cx - len * 0.34, cy + th, cx - len * 0.5, cy + beat * 0.35);
        ctx.closePath();
        ctx.fill();
        // One brighter line along the back, which is all the definition it gets.
        ctx.strokeStyle = rgba(tint, alpha * 2.2);
        ctx.lineWidth = 1.4;
        ctx.beginPath();
        ctx.moveTo(cx - len * 0.42, cy + beat * 0.25);
        ctx.quadraticCurveTo(cx - len * 0.05, cy - th * 0.78, cx + len * 0.4, cy - th * 0.1);
        ctx.stroke();
        break;
      }
      case 'drift': {
        // Something large and far away, crossing. Never resolves into an animal.
        const w = 120 * scale;
        const h = 34 * scale;
        const cx = x + Math.sin(t * 0.06 + e.phase) * 40 * e.dir;
        ctx.strokeStyle = rgba(tint, alpha * 0.7);
        ctx.lineWidth = 1.1;
        ctx.beginPath();
        ctx.moveTo(cx - w * 0.5, y);
        ctx.quadraticCurveTo(cx, y - h, cx + w * 0.5, y);
        ctx.quadraticCurveTo(cx, y + h * 0.6, cx - w * 0.5, y);
        ctx.stroke();
        break;
      }
    }
  }
}
