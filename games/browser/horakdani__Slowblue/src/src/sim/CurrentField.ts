/**
 * Slowblue: standing currents that belong to the course, not to the player.
 *
 * A rock is an obstacle you steer around. A vortex is an obstacle made of the same
 * substance you steer *with* - the only way past it is to spend water on it, which
 * is the one resource the game actually has. That makes it the most on-theme hazard
 * in the game, and it costs almost nothing: it is sampled, never simulated.
 *
 * Every current here is a pure tangential field, `v = f(r) * theta_hat`. In 2D that
 * is exactly divergence-free, so the tracer particles that visualise the water never
 * pile up or drain into one - the player sees the hazard in the water itself, before
 * it touches the shoal, with no extra rendering.
 */
export interface Vortex {
  x: number;
  y: number;
  /** Outside this radius the vortex contributes exactly nothing. */
  radius: number;
  /** Peak tangential speed (px/s). Sign is the spin direction. */
  strength: number;
  /** Section that owns it, so it can be pruned with its section. */
  sectionId: number;
  /** Radians of accumulated rotation, for the (subtle) on-screen marker. */
  phase: number;
}

/** Below this distance the tangent direction is meaningless; the amplitude is ~0 anyway. */
const EPS = 1e-3;

/** How far outside the frame a retired vortex is kept. See `CurrentField.retire`. */
const RETIRE_MARGIN = 60;

export class CurrentField {
  readonly vortices: Vortex[] = [];
  /**
   * Vortices the field has stopped sampling and the frame has not. Read by the
   * renderer, by nothing that computes water. See `prune` and `retire`.
   */
  readonly retired: Vortex[] = [];

  reset(): void {
    this.vortices.length = 0;
    this.retired.length = 0;
  }

  add(v: Vortex): void {
    this.vortices.push(v);
  }

  /**
   * Drops currents the camera has fully left behind. `dir` is the course
   * direction: -1 while the campaign climbs (larger Y is further back), +1 once
   * it turns over and falls.
   *
   * Slowblue: `behindY` is 0.9 of a screen behind the camera, which is a point *on the
   * glass* rather than past its edge, so a 125px-radius vortex was deleted with
   * the top 75px of it still drawn. The same split `ObstacleSystem` makes applies
   * here for the same reason: stopping sampling a current is a physics decision
   * and must keep happening on this line, because a vortex kept alive behind the
   * shoal still pulls at stragglers. Stopping *drawing* it is not, so it moves to
   * `retired` and `retire()` lets it go when it is off the frame.
   */
  prune(behindY: number, dir: -1 | 1 = -1): void {
    for (let i = this.vortices.length - 1; i >= 0; i--) {
      const v = this.vortices[i]!;
      if ((v.y + dir * v.radius - behindY) * dir >= 0) continue;
      this.vortices.splice(i, 1);
      this.retired.push(v);
    }
  }

  /** Drops retired vortices once no part of the disc could still be on the glass. */
  retire(cameraY: number, height: number): void {
    for (let i = this.retired.length - 1; i >= 0; i--) {
      const v = this.retired[i]!;
      const top = v.y - v.radius - cameraY;
      const bottom = v.y + v.radius - cameraY;
      if (bottom < -RETIRE_MARGIN || top > height + RETIRE_MARGIN) this.retired.splice(i, 1);
    }
  }

  step(dt: number): void {
    // Retired ones too: they are still on screen, and a swirl that stops turning
    // while you can see it is a worse artefact than the pop this list prevents.
    for (const v of this.retired) {
      v.phase += (v.strength / Math.max(1, v.radius)) * dt;
    }
    for (const v of this.vortices) {
      // Phase is purely cosmetic: the field itself is static, which is what makes it
      // something the player can learn and plan a line through.
      v.phase += (v.strength / Math.max(1, v.radius)) * dt;
    }
  }

  /**
   * Adds every current's velocity at (x, y) into `out`. Hot path: called once per
   * agent per step plus once per tracer per frame, so no allocation, no hypot chain.
   */
  addTo(x: number, y: number, out: { x: number; y: number }, scale = 1): void {
    if (scale === 0) return;
    for (const v of this.vortices) {
      const dx = x - v.x;
      const dy = y - v.y;
      const r = v.radius;
      if (dx > r || dx < -r || dy > r || dy < -r) continue;
      const d2 = dx * dx + dy * dy;
      if (d2 >= r * r || d2 < EPS) continue;
      const d = Math.sqrt(d2);
      // sin() bump: zero at the eye and zero at the rim, peak halfway out. No
      // singularity to clamp, and the rim blends into still water without a seam.
      const amp = v.strength * scale * Math.sin((Math.PI * d) / r);
      out.x += (-dy / d) * amp;
      out.y += (dx / d) * amp;
    }
  }

  /** Strongest current magnitude at a point - used by the renderer's hazard tint. */
  intensityAt(x: number, y: number): number {
    let best = 0;
    for (const v of this.vortices) {
      const d = Math.hypot(x - v.x, y - v.y);
      if (d >= v.radius) continue;
      best = Math.max(best, Math.abs(v.strength) * Math.sin((Math.PI * d) / v.radius));
    }
    return best;
  }
}
