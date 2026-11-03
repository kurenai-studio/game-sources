/**
 * A Web Audio stub, just complete enough to build Slowblue's graph.
 *
 * `AudioEngine` is the one module in the project that could not be tested at all:
 * it is inert without an `AudioContext`, every browser refuses to give it one
 * without a user gesture, and a headless probe has neither. So the bed's dispatch
 * - which act deals which voices - was checked by playing the game, which is how
 * five acts came to be flown to act I's bubbles and a whale without anybody
 * noticing for a whole campaign.
 *
 * What this stub gives back is the one thing worth asserting: **which mixer track
 * a scheduled voice actually arrives on, and how often.** Every node records what
 * it was connected to, so a source started during a measured second can be walked
 * forward through panners, filters and sends until it reaches (or fails to reach)
 * a given track. Nothing here models sound; it models routing, and routing is what
 * the bed table is.
 *
 * It records two more things now, and both are the same kind of trade: a property
 * of the *schedule* that is cheap to observe here and impossible to observe from a
 * signal. `StubScheduled` keeps the arguments to `start` and `stop`, which is where
 * a voice's length is written down and is what decides whether the ear reads it as
 * a note or as texture (`tests/tuning.test.ts`). `StubParam` counts assignment
 * separately from scheduling, which is the difference between a step and a ramp
 * and therefore the difference between a click and no click
 * (`tests/loops.test.ts`). Still no sound modelled anywhere.
 */

export class StubParam {
  private held: number;
  readonly writes: number[] = [];
  /**
   * How many times this param has been assigned with `.value =` rather than
   * scheduled.
   *
   * The distinction the real API makes and this stub used to flatten. A schedule
   * interpolates and a direct assignment steps, and a step on a param that is
   * already carrying signal is a click - which is why §2 asks for the ramps by
   * name. Counting it here is what lets `tests/loops.test.ts` assert that nothing
   * the engine *holds a reference to* is ever stepped, which is a different and
   * much narrower claim than "no `.value =` anywhere": setting a fresh node's
   * frequency before it starts is correct, and there are forty-odd of those.
   */
  directWrites = 0;
  constructor(value = 0) {
    // Not through the setter: this is construction, and nothing is listening yet.
    this.held = value;
  }
  get value(): number {
    return this.held;
  }
  set value(v: number) {
    this.held = v;
    this.directWrites++;
  }
  private set(v: number): this {
    this.held = v;
    this.writes.push(v);
    return this;
  }
  setValueAtTime(v: number): this {
    return this.set(v);
  }
  setTargetAtTime(v: number): this {
    return this.set(v);
  }
  exponentialRampToValueAtTime(v: number): this {
    return this.set(v);
  }
  linearRampToValueAtTime(v: number): this {
    return this.set(v);
  }
  cancelScheduledValues(): this {
    return this;
  }
}

let nextId = 0;

export class StubNode {
  readonly id = nextId++;
  readonly outputs: StubNode[] = [];
  connect<T>(target: T): T {
    if (target instanceof StubNode) this.outputs.push(target);
    return target;
  }
  disconnect(): void {
    this.outputs.length = 0;
  }
}

class StubGain extends StubNode {
  readonly gain = new StubParam(1);
}

class StubFilter extends StubNode {
  type = 'lowpass';
  readonly frequency = new StubParam(350);
  readonly Q = new StubParam(1);
  readonly detune = new StubParam(0);
}

class StubPanner extends StubNode {
  readonly pan = new StubParam(0);
}

class StubConvolver extends StubNode {
  buffer: unknown = null;
}

class StubCompressor extends StubNode {
  readonly threshold = new StubParam(-24);
  readonly knee = new StubParam(30);
  readonly ratio = new StubParam(12);
  readonly attack = new StubParam(0.003);
  readonly release = new StubParam(0.25);
}

/** Every source started since the last `clearStarted()`. The unit of measurement. */
export const started: StubNode[] = [];

export function clearStarted(): void {
  started.length = 0;
}

/**
 * The two schedule marks, kept because they are the only place a voice's
 * *length* is written down.
 *
 * The engine schedules everything ahead of `currentTime`, so `start(t)` and
 * `stop(t)` carry the whole envelope between them - and how long a pitched voice
 * rings is what decides whether the ear hears it as a note or as texture. That
 * distinction is the entire subject of `tests/tuning.test.ts`, and without these
 * two numbers it would have to be guessed at from the source.
 */
class StubScheduled extends StubNode {
  startedAt: number | null = null;
  stoppedAt: number | null = null;
  start(when = 0): void {
    this.startedAt = when;
    started.push(this);
  }
  stop(when = 0): void {
    this.stoppedAt = when;
  }
  /** Seconds between the two marks, or 0 for a voice that is never stopped. */
  get seconds(): number {
    if (this.startedAt === null || this.stoppedAt === null) return 0;
    return this.stoppedAt - this.startedAt;
  }
}

export class StubOscillator extends StubScheduled {
  type = 'sine';
  readonly frequency = new StubParam(440);
  readonly detune = new StubParam(0);
}

export class StubBufferSource extends StubScheduled {
  buffer: unknown = null;
  loop = false;
  readonly playbackRate = new StubParam(1);
  readonly detune = new StubParam(0);
}

class StubBuffer {
  private readonly data: Float32Array[];
  constructor(
    readonly numberOfChannels: number,
    readonly length: number,
    readonly sampleRate: number,
  ) {
    this.data = Array.from({ length: numberOfChannels }, () => new Float32Array(length));
  }
  getChannelData(ch: number): Float32Array {
    return this.data[ch]!;
  }
}

export class StubAudioContext {
  state: AudioContextState = 'running';
  currentTime = 0;
  /**
   * How many times the engine asked for each transition, and whether the browser
   * is willing to grant a resume.
   *
   * These three are what make the interruption recovery testable at all. The
   * question is not "did the state end up right" - the engine's own retry would
   * make that true from almost anywhere - it is *how many attempts it took*, and
   * whether a context nobody has touched is left alone. `blocked` models the one
   * browser behaviour a stub otherwise hides: a `resume()` that resolves and
   * changes nothing, which is what every mobile browser does without a gesture.
   */
  resumes = 0;
  suspends = 0;
  blocked = false;
  private readonly listeners: (() => void)[] = [];
  // Deliberately low: the engine generates two seconds of noise and five and a
  // half of impulse response at unlock, and neither has any bearing on routing.
  readonly sampleRate = 8000;
  readonly destination = new StubNode();

  createGain(): StubGain {
    return new StubGain();
  }
  createBiquadFilter(): StubFilter {
    return new StubFilter();
  }
  createOscillator(): StubOscillator {
    return new StubOscillator();
  }
  createBufferSource(): StubBufferSource {
    return new StubBufferSource();
  }
  createStereoPanner(): StubPanner {
    return new StubPanner();
  }
  createConvolver(): StubConvolver {
    return new StubConvolver();
  }
  createDynamicsCompressor(): StubCompressor {
    return new StubCompressor();
  }
  createBuffer(ch: number, len: number, rate: number): StubBuffer {
    return new StubBuffer(ch, len, rate);
  }
  addEventListener(type: string, fn: () => void): void {
    if (type === 'statechange') this.listeners.push(fn);
  }
  removeEventListener(type: string, fn: () => void): void {
    if (type !== 'statechange') return;
    const at = this.listeners.indexOf(fn);
    if (at >= 0) this.listeners.splice(at, 1);
  }
  /**
   * A state transition, with the event the real API fires for it.
   *
   * Synchronously, and inside the call that caused it - which is stricter than a
   * browser, where the event arrives as its own task. That is deliberate: it is
   * the arrangement in which a recovery that suspends can re-enter itself before
   * its own suspend has returned, so the engine's reentry guard is actually under
   * test rather than merely present. And no event where nothing changed, because
   * that is the property the whole recovery leans on: a resume that fails to
   * resume is silent, so a failed recovery cannot loop.
   */
  private to(state: string): void {
    if (this.state === state) return;
    this.state = state as AudioContextState;
    for (const fn of [...this.listeners]) fn();
  }
  async resume(): Promise<void> {
    this.resumes++;
    if (!this.blocked) this.to('running');
  }
  async suspend(): Promise<void> {
    this.suspends++;
    this.to('suspended');
  }
  async close(): Promise<void> {
    this.to('closed');
  }
  /**
   * WebKit's non-standard `interrupted`, delivered the way a phone call does it:
   * no `visibilitychange`, no gesture, nothing but this one event.
   */
  interrupt(): void {
    this.to('interrupted');
  }
}

/** Installs the stub as the page's `AudioContext`. Returns the teardown. */
export function installAudioStub(): () => void {
  const g = globalThis as { AudioContext?: unknown; webkitAudioContext?: unknown };
  const previous = g.AudioContext;
  g.AudioContext = StubAudioContext as unknown as typeof AudioContext;
  return () => {
    g.AudioContext = previous;
  };
}

/** Whether a signal started at `from` arrives anywhere at `target`. */
export function reaches(from: StubNode, target: StubNode): boolean {
  const seen = new Set<number>();
  const queue: StubNode[] = [from];
  while (queue.length > 0) {
    const node = queue.pop()!;
    if (node === target) return true;
    if (seen.has(node.id)) continue;
    seen.add(node.id);
    queue.push(...node.outputs);
  }
  return false;
}
