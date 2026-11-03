import { Rng } from '../core/rng';
import { TAU, smoothstep } from '../core/math';

/**
 * Slowblue: the ocean's own current.
 *
 * Why this exists: with still water, acting early strictly dominates acting late -
 * every obstacle is visible far ahead, so there is exactly one correct strategy and
 * no reason to touch the screen twice. That was measured, not assumed (see the
 * sweeps in tools/).
 *
 * An ambient current fixes it structurally: the line you set up three seconds ago is
 * no longer the line you are on, so late correction becomes a skill rather than a
 * mistake. It also makes "ride the current" vs "fight the current" a real decision,
 * and it is what the premise implies - you bend an ocean that already moves.
 *
 * Implemented as the curl of a stream function, so the field is exactly
 * divergence-free: no sources or sinks. That is what makes it read as water instead
 * of as wind. Two isotropic octaves, evaluated analytically - no storage, no
 * advection, no per-cell cost, fully deterministic from the seed.
 */
export class AmbientFlow {
  private readonly p: Float64Array;

  /** Wavelength (px) and relative amplitude of each octave. */
  private static readonly OCTAVES = [
    { length: 480, weight: 0.72, wx: 0.085, wy: 0.062 },
    { length: 215, weight: 0.4, wx: -0.17, wy: 0.13 },
  ] as const;

  /** Playfield width, used to stop the ocean flowing into a wall. */
  width: number;

  constructor(seed: number, width = 390) {
    const rng = new Rng(seed ^ 0x0cea11);
    this.width = width;
    // Phases only: the shape of the ocean is fixed, its placement is per-seed.
    this.p = new Float64Array(4);
    for (let i = 0; i < 4; i++) this.p[i] = rng.next() * TAU;
  }

  /**
   * Adds the ambient velocity at a world position into `out`.
   * `strength` is the peak speed of the combined octaves, in px/s.
   */
  addTo(x: number, y: number, t: number, strength: number, out: { x: number; y: number }): void {
    if (strength <= 0) return;
    // No flow *into* a wall. Without this the ocean pins the shoal into a corner and
    // holds it there, which looks broken and plays worse. Flow *along* the wall is
    // kept, so the edges stay alive. This is the one place the field is allowed to
    // stop being exactly divergence-free, and only within a sixth of the width.
    const edge = this.width * 0.16;
    const wall = smoothstep(0, edge, x) * smoothstep(0, edge, this.width - x);
    for (let i = 0; i < 2; i++) {
      const o = AmbientFlow.OCTAVES[i]!;
      const k = TAU / o.length;
      const amp = strength * o.weight;
      const ax = x * k + this.p[i * 2] + t * o.wx;
      const ay = y * k + this.p[i * 2 + 1] - t * o.wy;
      // v = curl(psi), psi = (amp/k) * sin(ax) * cos(ay)
      out.x -= amp * Math.sin(ax) * Math.sin(ay) * wall;
      out.y -= amp * Math.cos(ax) * Math.cos(ay);
    }
  }
}
