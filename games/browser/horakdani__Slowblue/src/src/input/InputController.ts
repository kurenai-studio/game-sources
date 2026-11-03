import type { World } from '../sim/World';

interface PointerTrack {
  x: number;
  y: number;
  t: number;
}

export interface InputHooks {
  onGestureStart?: (count: number) => void;
  onGestureEnd?: (lengthPx: number, durationSec: number) => void;
  /**
   * Fired at most once per pointermove with the fastest sample in it, normalised
   * the same way `World.injectStroke` normalises it. Audio uses it to pitch the
   * whoosh; nothing in the simulation may depend on it.
   */
  /** `pan` is -1..1 across the canvas: where the finger was on this segment. */
  onStroke?: (speed01: number, pan: number) => void;
}

/**
 * Slowblue: pointer -> water. No smoothing, no prediction, no gesture classification.
 * Latency is the feature here, so a move event becomes momentum in the same frame
 * it arrives, and coalesced events are replayed so a fast flick keeps its shape.
 */
export class InputController {
  private tracks = new Map<number, PointerTrack>();
  private startedAt = new Map<number, { t: number; len: number }>();
  private disposers: (() => void)[] = [];

  constructor(
    private readonly canvas: HTMLCanvasElement,
    private readonly world: World,
    private readonly hooks: InputHooks = {},
  ) {
    this.attach();
  }

  private attach(): void {
    const el = this.canvas;
    const down = (e: PointerEvent) => this.onDown(e);
    const move = (e: PointerEvent) => this.onMove(e);
    const up = (e: PointerEvent) => this.onUp(e);
    // Belt and braces on iOS: touch-action alone does not stop every gesture.
    const swallow = (e: Event) => e.preventDefault();
    /*
     * The finger that never lifts.
     *
     * `pointercancel` is the browser saying "that touch is mine now", and it is
     * the polite case. The impolite one is a touch that simply stops being
     * reported: iOS hands a drag that started near an edge to the system gesture
     * without always cancelling it first, and a WebView backgrounded mid-drag
     * comes back with a pointer id nothing will ever lift. The track for it then
     * sits in the map forever, `activePointers` never returns to zero, and the
     * next `pointermove` that happens to reuse the id resumes a stroke from
     * wherever the finger was minutes ago - a flick across the whole ocean.
     *
     * Losing the page is therefore treated as every finger lifting. It costs a
     * dragged stroke that a player was not going to finish anyway (they left),
     * and it is the only thing that guarantees the map empties.
     */
    const release = () => this.endAll();
    const hidden = () => {
      if (document.visibilityState === 'hidden') this.endAll();
    };

    el.addEventListener('pointerdown', down);
    el.addEventListener('pointermove', move);
    el.addEventListener('pointerup', up);
    el.addEventListener('pointercancel', up);
    el.addEventListener('pointerleave', up);
    el.addEventListener('touchstart', swallow, { passive: false });
    el.addEventListener('touchmove', swallow, { passive: false });
    el.addEventListener('contextmenu', swallow);
    el.addEventListener('dblclick', swallow);
    window.addEventListener('blur', release);
    document.addEventListener('visibilitychange', hidden);

    this.disposers.push(() => {
      el.removeEventListener('pointerdown', down);
      el.removeEventListener('pointermove', move);
      el.removeEventListener('pointerup', up);
      el.removeEventListener('pointercancel', up);
      el.removeEventListener('pointerleave', up);
      el.removeEventListener('touchstart', swallow);
      el.removeEventListener('touchmove', swallow);
      el.removeEventListener('contextmenu', swallow);
      el.removeEventListener('dblclick', swallow);
      window.removeEventListener('blur', release);
      document.removeEventListener('visibilitychange', hidden);
    });
  }

  dispose(): void {
    for (const d of this.disposers) d();
    this.disposers.length = 0;
    this.tracks.clear();
    this.startedAt.clear();
  }

  /**
   * Ends every live gesture, reporting each one as if it had been lifted.
   *
   * The hooks are fired rather than skipped on purpose: a gesture that started is
   * a gesture that has to end, and a listener counting strokes must not be left
   * holding one that never closed.
   */
  private endAll(): void {
    if (this.tracks.size === 0) return;
    for (const id of this.tracks.keys()) this.release(id, performance.now());
    this.tracks.clear();
    this.startedAt.clear();
  }

  /** One pointer's bookkeeping, closed. Shared by lift, cancel and loss. */
  private release(id: number, timeStamp: number): void {
    const started = this.startedAt.get(id);
    if (started === undefined) return;
    this.hooks.onGestureEnd?.(started.len, Math.max(0, (timeStamp - started.t) / 1000));
  }

  private local(e: PointerEvent | { clientX: number; clientY: number }): { x: number; y: number } {
    const rect = this.canvas.getBoundingClientRect();
    return { x: e.clientX - rect.left, y: e.clientY - rect.top };
  }

  private onDown(e: PointerEvent): void {
    e.preventDefault();
    const p = this.local(e);
    // A finished run keeps its water alive on screen, but it no longer takes input:
    // the shell owns the viewport at that point.
    if (this.world.run.phase === 'over') return;
    // A second `pointerdown` for a live id means the lift for the first one never
    // arrived - the same loss `endAll` catches, seen from the other side. Closing
    // the old gesture before opening the new one is what keeps starts and ends
    // paired, and stops the stale start time from being reported as a
    // thirty-second stroke.
    if (this.tracks.has(e.pointerId)) this.release(e.pointerId, e.timeStamp);
    this.tracks.set(e.pointerId, { x: p.x, y: p.y, t: e.timeStamp });
    this.startedAt.set(e.pointerId, { t: e.timeStamp, len: 0 });
    this.world.gestureCount++;
    this.hooks.onGestureStart?.(this.world.gestureCount);
    try {
      this.canvas.setPointerCapture(e.pointerId);
    } catch {
      /* capture is a nicety, not a requirement */
    }
  }

  private onMove(e: PointerEvent): void {
    const track = this.tracks.get(e.pointerId);
    if (track === undefined) return;
    e.preventDefault();
    // The run can end under a finger that is still down - a hunter takes the last
    // of the shoal mid-stroke - and `onDown`'s guard does not help there, because
    // the gesture began while the water was still live. Without this the player
    // goes on stirring an ocean the shell already owns, and the ending plays
    // behind their own wake.
    if (this.world.run.phase === 'over') {
      this.tracks.delete(e.pointerId);
      this.release(e.pointerId, e.timeStamp);
      this.startedAt.delete(e.pointerId);
      return;
    }
    const samples: { clientX: number; clientY: number; timeStamp: number }[] = [];
    const coalesced =
      typeof e.getCoalescedEvents === 'function' ? e.getCoalescedEvents() : undefined;
    if (coalesced !== undefined && coalesced.length > 0) {
      for (const c of coalesced) {
        samples.push({ clientX: c.clientX, clientY: c.clientY, timeStamp: c.timeStamp });
      }
    } else {
      samples.push({ clientX: e.clientX, clientY: e.clientY, timeStamp: e.timeStamp });
    }

    const started = this.startedAt.get(e.pointerId);
    let fastest = 0;
    for (const s of samples) {
      const p = this.local(s);
      const dt = Math.max(0.004, (s.timeStamp - track.t) / 1000);
      const y0 = this.world.viewToWorldY(track.y);
      const y1 = this.world.viewToWorldY(p.y);
      this.world.injectStroke(track.x, y0, p.x, y1, dt);
      const len = Math.hypot(p.x - track.x, p.y - track.y);
      fastest = Math.max(fastest, Math.min(1, len / dt / 1400));
      if (started !== undefined) started.len += len;
      track.x = p.x;
      track.y = p.y;
      track.t = s.timeStamp;
    }
    // -1..1 across the canvas: the stroke is the one sound the player is playing, so
    // it is the one sound that has to come from where their finger is.
    if (fastest > 0) {
      const pan = this.world.width > 0 ? (track.x / this.world.width) * 2 - 1 : 0;
      this.hooks.onStroke?.(fastest, Math.max(-1, Math.min(1, pan)));
    }
  }

  private onUp(e: PointerEvent): void {
    if (!this.tracks.has(e.pointerId)) return;
    this.tracks.delete(e.pointerId);
    this.release(e.pointerId, e.timeStamp);
    this.startedAt.delete(e.pointerId);
  }

  get activePointers(): number {
    return this.tracks.size;
  }
}
