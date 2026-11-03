import { TAU, clamp } from '../core/math';
import { mix, rgba, type Rgb, type ZonePaint } from './Paint';

/**
 * Slowblue: a standing current, drawn as water instead of as a diagram.
 *
 * The first version drew two Archimedean spirals over the top of the field: constant
 * width, constant brightness, a hard start at the eye and a hard stop at the rim. It
 * did its one job - you could read the spin - and it looked like a pencil doodle laid
 * on the ocean, because a spiral of even curvature is not a shape water makes.
 *
 * Everything here is derived from the field the simulation actually samples
 * (`CurrentField.addTo`): a tangential velocity that is zero at the eye, peaks half
 * way out and is zero again at the rim. Two consequences do all the visual work:
 *
 *   - the water shears. Inner water laps outer water, so a line released at the eye
 *     winds up tightly near the middle and hangs almost straight near the rim. The
 *     filaments are exactly that curve, so their shape is the hazard's own profile.
 *   - the fastest water is a *ring*, not the centre. The light collects there, the
 *     entrained motes are longest there, and the eye is visibly the calm place -
 *     which is the line a tight shoal is supposed to find.
 *
 * The result is legible from further away than the old spiral was, because motion at
 * the right radius reads as rotation instantly, and it never has to shout to do it.
 */

/**
 * Angular speed of the water at distance `d` from the eye, in rad/s. This is
 * `CurrentField`'s own profile divided by the radius, i.e. exactly the rate at which
 * a mote sitting there is carried around, so anything drawn with it is honest.
 */
export function orbitOmega(d: number, radius: number, strength: number): number {
  if (d <= 0 || d >= radius) return 0;
  return (strength * Math.sin((Math.PI * d) / radius)) / d;
}

/**
 * The dimensionless shear profile, `sin(pi u) / u` for `u = d / radius`. Large near
 * the eye, zero at the rim: the amount a filament has been wound up at that radius.
 */
export function shearAt(u: number): number {
  if (u <= 0 || u >= 1) return 0;
  return Math.sin(Math.PI * u) / u;
}

export interface WhirlView {
  ctx: CanvasRenderingContext2D;
  paint: ZonePaint;
  /** The level's accent, so a current is tinted by the water it stands in. */
  accent: Rgb;
  time: number;
  quality: number;
}

/** Filaments per current. Three reads as rotation; more reads as a spirograph. */
const ARMS = 3;
/** Segments per filament. */
const STEPS = 15;
/** How far a filament has been wound up, in radians per unit of shear. */
const WIND = 0.78;
/** Innermost radius a filament starts at, as a fraction of the radius. */
const INNER = 0.17;

export function drawWhirl(
  v: WhirlView,
  cx: number,
  cy: number,
  radius: number,
  strength: number,
  phase: number,
): void {
  const ctx = v.ctx;
  const dir = Math.sign(strength) || 1;
  const speed = Math.abs(strength);
  // 0..1 "how much water is this". Everything else is scaled off it, so a gentle
  // teaching vortex is a suggestion and a late-campaign one is unmistakable.
  const force = clamp(speed / 190, 0.14, 1);
  const t = v.time;
  const spin = phase;
  const filament = mix(v.paint.tracer, v.accent, 0.22);

  ctx.globalCompositeOperation = 'lighter';
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';

  // --- the fast ring -----------------------------------------------------
  // One gradient, brightest at half the radius, gone at the eye and at the rim.
  // This is the whole hazard in a single fill: the shape of the speed profile.
  const halo = ctx.createRadialGradient(cx, cy, radius * 0.08, cx, cy, radius);
  halo.addColorStop(0, rgba(filament, 0));
  halo.addColorStop(0.46, rgba(filament, 0.022 + force * 0.042));
  halo.addColorStop(1, rgba(filament, 0));
  ctx.fillStyle = halo;
  ctx.beginPath();
  ctx.arc(cx, cy, radius, 0, TAU);
  ctx.fill();

  // --- filaments ---------------------------------------------------------
  // Each arm is drawn in three chunks with their own alpha, which tapers the streak
  // in and out without paying for a per-segment stroke or a stroke gradient.
  const chunk = Math.ceil(STEPS / 3);
  for (let arm = 0; arm < ARMS; arm++) {
    const base = spin + (arm / ARMS) * TAU;
    for (let part = 0; part < 3; part++) {
      const from = part * chunk;
      const to = Math.min(STEPS, from + chunk + 1);
      if (to - from < 2) continue;
      const taper = part === 0 ? 0.42 : part === 1 ? 1 : 0.5;
      ctx.strokeStyle = rgba(filament, (0.07 + force * 0.14) * taper);
      ctx.lineWidth = (1 + force * 1.7) * (part === 1 ? 1 : 0.8);
      ctx.beginPath();
      for (let i = from; i <= to; i++) {
        const s = i / STEPS;
        const u = INNER + s * (1 - INNER);
        const r = radius * u;
        const ang = base + dir * WIND * shearAt(u);
        const px = cx + Math.cos(ang) * r;
        const py = cy + Math.sin(ang) * r;
        if (i === from) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
      }
      ctx.stroke();
    }
  }

  // --- entrained motes ---------------------------------------------------
  // Silt caught in the current, each one carried at the true local angular speed and
  // smeared along its own path. Nothing else in the game says "this is moving water"
  // as immediately, and it is one path for the lot.
  const motes = v.quality > 0.6 ? 13 : 7;
  ctx.strokeStyle = rgba(mix(filament, v.paint.speck, 0.5), 0.14 + force * 0.2);
  ctx.lineWidth = 1.2;
  ctx.beginPath();
  for (let i = 0; i < motes; i++) {
    // Deterministic spread: no state, and the same current looks the same on replay.
    const u = 0.24 + ((i * 0.3819) % 1) * 0.68;
    const r = radius * u;
    const omega = orbitOmega(r, radius, speed);
    const ang = i * 2.399 + dir * omega * t;
    // Trail length is the distance this mote covers in a tenth of a second, so the
    // fastest water visibly draws the longest streaks.
    const trail = clamp(omega * r * 0.1, 2, 26);
    const span = trail / r;
    const x0 = cx + Math.cos(ang) * r;
    const y0 = cy + Math.sin(ang) * r;
    const a1 = ang - dir * span;
    ctx.moveTo(x0, y0);
    ctx.quadraticCurveTo(
      cx + Math.cos(ang - dir * span * 0.5) * r * 1.004,
      cy + Math.sin(ang - dir * span * 0.5) * r * 1.004,
      cx + Math.cos(a1) * r,
      cy + Math.sin(a1) * r,
    );
  }
  ctx.stroke();

  // --- the eye, and the edge of the water it owns -------------------------
  ctx.strokeStyle = rgba(filament, 0.06 + force * 0.1);
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.arc(cx, cy, radius * 0.12, 0, TAU);
  ctx.stroke();

  // The rim is where the current stops existing, and the player is entitled to know
  // where that is. Dashed and very dim: a boundary, never a target.
  ctx.setLineDash([5, 17]);
  ctx.lineDashOffset = -spin * radius * 0.25;
  ctx.strokeStyle = rgba(filament, 0.05 + force * 0.05);
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.arc(cx, cy, radius * 0.97, 0, TAU);
  ctx.stroke();
  ctx.setLineDash([]);
  ctx.lineDashOffset = 0;
  ctx.globalCompositeOperation = 'source-over';
}
