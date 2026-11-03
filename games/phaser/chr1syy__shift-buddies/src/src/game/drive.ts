import type { Direction } from "./rules.ts";

export const STEP_MS = 180;
export const DIRECTION_KEYS: Readonly<Record<string, Direction>> = {
  ArrowUp: "up", KeyW: "up", ArrowDown: "down", KeyS: "down",
  ArrowLeft: "left", KeyA: "left", ArrowRight: "right", KeyD: "right",
};

// One pending intention, never a growing action queue. Last newly pressed key
// wins; releasing it falls back to the most recent remaining physical key.
export class DriveInput {
  private held = new Map<string, Direction>();
  private pending?: Direction;
  private blocked = false;

  press(code: string): boolean {
    const direction = DIRECTION_KEYS[code];
    if (!direction || this.held.has(code)) return false;
    this.held.set(code, direction);
    this.pending = direction;
    this.blocked = false;
    return true;
  }
  release(code: string): void { this.held.delete(code); }
  take(): Direction | undefined {
    const direction = this.pending ?? (this.blocked ? undefined : [...this.held.values()].at(-1));
    this.pending = undefined;
    return direction;
  }
  get continuing(): boolean { return !this.blocked && (this.pending !== undefined || this.held.size > 0); }
  obstruct(): void { this.pending = undefined; this.blocked = true; }
  reset(): void { this.held.clear(); this.pending = undefined; this.blocked = false; }
}

// No per-tile easing: interior field centres have exactly the same speed.
// Only departure from rest accelerates; its endpoint derivative is 1.
export function driveProgress(t: number, starting: boolean): number {
  return starting ? 2 * t * t - t * t * t : t;
}
