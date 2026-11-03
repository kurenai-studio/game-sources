export interface TileHit { floor: number; index: number; revealed?: boolean }

/** Only two taps that both started on the same revealed clue can chord. */
export class DoubleTap {
  private last: { floor: number; index: number; time: number } | null = null;

  tap(tile: TileHit, time: number, eligible: boolean): boolean {
    const previous = this.last;
    this.last = null;
    if (!eligible) return false;
    if (previous && previous.floor === tile.floor && previous.index === tile.index
      && time >= previous.time && time - previous.time <= 400) return true;
    this.last = { floor: tile.floor, index: tile.index, time };
    return false;
  }

  reset(): void { this.last = null; }
}
export type GestureAction =
  | { type: 'tap' | 'flag' | 'chord'; tile: TileHit }
  | { type: 'rotate'; delta: number }
  | { type: 'zoom'; ratio: number };

/** Pointer state stays independent of WebGL so interrupted touch sequences are testable. */
export class BoardGesture {
  private pointers = new Map<number, { x: number; y: number }>();
  private press: { id: number; x: number; y: number; tile?: TileHit; dragged: boolean } | null = null;
  private pinch = 0;
  private multiTouch = false;
  private doubleTap = new DoubleTap();

  down(id: number, x: number, y: number, button: number, tile?: TileHit): GestureAction | undefined {
    if (button !== 0 && button !== 2) return;
    this.pointers.set(id, { x, y });
    if (this.pointers.size > 1 || this.multiTouch) {
      this.doubleTap.reset();
      this.multiTouch = true;
      this.press = null;
      this.pinch = this.distance();
      return;
    }
    this.press = button === 0 ? { id, x, y, tile, dragged: false } : null;
    if (button === 2) {
      this.doubleTap.reset();
      if (tile) return { type: 'flag', tile };
    }
  }

  move(id: number, x: number, y: number): GestureAction | undefined {
    const old = this.pointers.get(id);
    if (!old) return;
    this.pointers.set(id, { x, y });
    if (this.pointers.size > 1) {
      const distance = this.distance();
      const ratio = this.pinch > 0 ? distance / this.pinch : 1;
      this.pinch = distance;
      return { type: 'zoom', ratio };
    }
    if (!this.press || this.press.id !== id || this.multiTouch) return;
    if (Math.hypot(x - this.press.x, y - this.press.y) > 8) { this.press.dragged = true; this.doubleTap.reset(); }
    if (this.press.dragged) return { type: 'rotate', delta: x - old.x };
  }

  up(id: number, time = performance.now()): GestureAction | undefined {
    const press = this.press;
    this.pointers.delete(id);
    if (press?.id === id) this.press = null;
    if (this.pointers.size === 0) this.multiTouch = false;
    if (press?.id === id && !press.dragged) {
      if (press.tile) return { type: this.doubleTap.tap(press.tile, time, press.tile.revealed === true) ? 'chord' : 'tap', tile: press.tile };
      this.doubleTap.reset();
    }
  }

  hold(): GestureAction | undefined {
    if (!this.press || this.press.dragged || !this.press.tile) return;
    const tile = this.press.tile;
    this.doubleTap.reset();
    this.press = null;
    return { type: 'flag', tile };
  }

  cancel(): void {
    this.doubleTap.reset();
    this.press = null;
    this.pointers.clear();
    this.multiTouch = false;
    this.pinch = 0;
  }

  private distance(): number {
    const points = [...this.pointers.values()];
    return points.length < 2 ? 0 : Math.hypot(points[0].x - points[1].x, points[0].y - points[1].y);
  }
}
