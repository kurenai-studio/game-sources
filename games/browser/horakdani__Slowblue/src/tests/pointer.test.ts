import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { InputController } from '../src/input/InputController';
import type { World } from '../src/sim/World';

/**
 * The pointer edge cases, which are the ones a phone actually produces.
 *
 * Nothing here is about a clean tap-drag-lift; that path is exercised by every
 * e2e run in the suite. This is about the four ways a real touch stream goes
 * wrong - a second finger, a cancelled touch, a touch that is simply never lifted
 * because the OS took the app away, and a run that ends underneath a finger that
 * is still down - and about the one symptom all four share when they are not
 * handled: a track left in the map, an ocean being stirred by a finger that is no
 * longer on the glass.
 *
 * It runs without a browser because what is being tested is the bookkeeping, not
 * the DOM: a fake surface records the listeners, the test dispatches the events
 * the phone would have, and `activePointers` is the assertion.
 */

/** The canvas, reduced to what `InputController` actually touches. */
class FakeSurface {
  private listeners = new Map<string, ((e: unknown) => void)[]>();
  /** Set when `setPointerCapture` is made to fail, the way a stale id makes it fail. */
  captureThrows = false;
  captured: number[] = [];
  prevented = 0;

  addEventListener(type: string, fn: (e: unknown) => void): void {
    const list = this.listeners.get(type) ?? [];
    list.push(fn);
    this.listeners.set(type, list);
  }

  removeEventListener(type: string, fn: (e: unknown) => void): void {
    const list = this.listeners.get(type);
    if (list === undefined) return;
    const i = list.indexOf(fn);
    if (i >= 0) list.splice(i, 1);
  }

  getBoundingClientRect(): { left: number; top: number } {
    return { left: 0, top: 0 };
  }

  setPointerCapture(id: number): void {
    if (this.captureThrows) throw new Error('InvalidPointerId');
    this.captured.push(id);
  }

  dispatch(type: string, init: Record<string, unknown>): void {
    const event = {
      preventDefault: () => {
        this.prevented++;
      },
      ...init,
    };
    for (const fn of [...(this.listeners.get(type) ?? [])]) fn(event);
  }

  has(type: string): boolean {
    return (this.listeners.get(type) ?? []).length > 0;
  }
}

/** The world, reduced the same way. Strokes are recorded, not simulated. */
class FakeWorld {
  width = 390;
  gestureCount = 0;
  run = { phase: 'running' as 'running' | 'over' };
  strokes: { x0: number; y0: number; x1: number; y1: number; dt: number }[] = [];

  /** The drawn camera's converter, which is the one a finger has to agree with. */
  viewToWorldY(y: number): number {
    return y;
  }

  injectStroke(x0: number, y0: number, x1: number, y1: number, dt: number): void {
    this.strokes.push({ x0, y0, x1, y1, dt });
  }
}

interface Harness {
  surface: FakeSurface;
  world: FakeWorld;
  input: InputController;
  ends: { len: number; sec: number }[];
  starts: number[];
}

function down(surface: FakeSurface, id: number, x: number, y: number, t = 0): void {
  surface.dispatch('pointerdown', { pointerId: id, clientX: x, clientY: y, timeStamp: t });
}

function move(surface: FakeSurface, id: number, x: number, y: number, t: number): void {
  surface.dispatch('pointermove', { pointerId: id, clientX: x, clientY: y, timeStamp: t });
}

function up(surface: FakeSurface, id: number, t: number, type = 'pointerup'): void {
  surface.dispatch(type, { pointerId: id, clientX: 0, clientY: 0, timeStamp: t });
}

let harness: Harness;

beforeEach(() => {
  // The controller now listens to the page as well as to the canvas, because
  // losing the page is one of the ways a finger goes missing. Node has neither.
  globalThis.window = new EventTarget() as unknown as Window & typeof globalThis;
  globalThis.document = Object.assign(new EventTarget(), {
    visibilityState: 'visible' as DocumentVisibilityState,
  }) as unknown as Document;

  const surface = new FakeSurface();
  const world = new FakeWorld();
  const ends: { len: number; sec: number }[] = [];
  const starts: number[] = [];
  const input = new InputController(
    surface as unknown as HTMLCanvasElement,
    world as unknown as World,
    {
      onGestureStart: (count) => starts.push(count),
      onGestureEnd: (len, sec) => ends.push({ len, sec }),
    },
  );
  harness = { surface, world, input, ends, starts };
});

afterEach(() => {
  harness.input.dispose();
});

describe('pointer bookkeeping', () => {
  it('tracks two fingers independently and stirs the water with both', () => {
    const { surface, world, input } = harness;
    down(surface, 1, 100, 100, 0);
    down(surface, 2, 300, 700, 0);
    expect(input.activePointers).toBe(2);
    expect(harness.starts).toEqual([1, 2]);

    move(surface, 1, 140, 100, 16);
    move(surface, 2, 260, 700, 16);
    expect(world.strokes).toHaveLength(2);

    // One finger lifting must not take the other one's stroke with it.
    up(surface, 1, 32);
    expect(input.activePointers).toBe(1);
    move(surface, 2, 200, 700, 48);
    expect(world.strokes).toHaveLength(3);
    up(surface, 2, 64);
    expect(input.activePointers).toBe(0);
    expect(harness.ends).toHaveLength(2);
  });

  it('closes the gesture when the browser cancels the touch', () => {
    const { surface, input } = harness;
    down(surface, 7, 100, 100, 0);
    move(surface, 7, 160, 100, 16);
    up(surface, 7, 20, 'pointercancel');
    expect(input.activePointers).toBe(0);
    expect(harness.ends).toHaveLength(1);
    expect(harness.ends[0].len).toBeCloseTo(60, 5);
  });

  /**
   * The one that used to stick. A drag interrupted by the OS - control centre,
   * a call, the app switcher - produces no lift at all, and before the page
   * listeners the track for it stayed in the map for the rest of the session.
   */
  it('lets go of every finger when the page is taken away', () => {
    const { surface, input } = harness;
    down(surface, 1, 100, 100, 0);
    down(surface, 2, 200, 200, 0);
    expect(input.activePointers).toBe(2);

    (document as unknown as { visibilityState: string }).visibilityState = 'hidden';
    document.dispatchEvent(new Event('visibilitychange'));
    expect(input.activePointers).toBe(0);
    // Both gestures are reported as ended: a start without an end is what a
    // listener counting strokes cannot recover from.
    expect(harness.ends).toHaveLength(2);
  });

  it('lets go of every finger when the window loses focus', () => {
    const { surface, input } = harness;
    down(surface, 3, 100, 100, 0);
    window.dispatchEvent(new Event('blur'));
    expect(input.activePointers).toBe(0);
    expect(harness.ends).toHaveLength(1);
  });

  it('ignores a move for a pointer that never went down', () => {
    const { surface, world, input } = harness;
    move(surface, 9, 100, 100, 16);
    expect(world.strokes).toHaveLength(0);
    expect(input.activePointers).toBe(0);
    // ...and a lift for one is not reported as a gesture either.
    up(surface, 9, 32);
    expect(harness.ends).toHaveLength(0);
  });

  it('does not re-open a gesture for a pointer id that is already down', () => {
    const { surface, input } = harness;
    down(surface, 4, 100, 100, 0);
    down(surface, 4, 300, 300, 5000);
    expect(input.activePointers).toBe(1);
    // The lost first gesture is closed with its own clock, not folded into the
    // second one's - otherwise the next lift reports a five-second stroke.
    expect(harness.ends).toHaveLength(1);
    expect(harness.ends[0].sec).toBeCloseTo(5, 5);
  });

  it('stops stirring when the run ends under a finger that is still down', () => {
    const { surface, world, input } = harness;
    down(surface, 5, 100, 100, 0);
    move(surface, 5, 150, 100, 16);
    expect(world.strokes).toHaveLength(1);

    world.run.phase = 'over';
    move(surface, 5, 220, 100, 32);
    expect(world.strokes).toHaveLength(1);
    expect(input.activePointers).toBe(0);
    expect(harness.ends).toHaveLength(1);
  });

  it('survives a capture that will not take', () => {
    const { surface, world, input } = harness;
    surface.captureThrows = true;
    down(surface, 6, 100, 100, 0);
    move(surface, 6, 180, 100, 16);
    expect(input.activePointers).toBe(1);
    expect(world.strokes).toHaveLength(1);
  });

  it('takes its page listeners with it when disposed', () => {
    const { surface, input } = harness;
    down(surface, 8, 100, 100, 0);
    input.dispose();
    expect(input.activePointers).toBe(0);
    expect(surface.has('pointerdown')).toBe(false);
    // A disposed controller that still answers `blur` is a controller holding a
    // canvas the page has already thrown away.
    window.dispatchEvent(new Event('blur'));
    expect(harness.ends).toHaveLength(0);
  });
});
