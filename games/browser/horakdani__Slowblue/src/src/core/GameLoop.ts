/**
 * Five seconds at 60 Hz, two and a half at 120. Long enough that a p95 means
 * something on a single scene, short enough that walking into a heavy one shows up
 * within a breath instead of being averaged away by the calm before it.
 */
const SAMPLE_WINDOW = 300;

export interface GameLoopStats {
  fps: number;
  frameMs: number;
  /**
   * p95 of `frameMs` over the last {@link SAMPLE_WINDOW} frames, refreshed twice a
   * second. This is the number a frame-time budget is written against: the CPU cost of a
   * frame against the 16.7 ms budget, so it reads as headroom and a threshold on it
   * means something. `frameMs` alone flickers too fast to read off a phone held at
   * arm's length, and the `slow %` next to it counts a different thing (frames past
   * 22.2 ms, cumulative since boot).
   */
  frameP95Ms: number;
  /**
   * p95 of the delivered interval between frames, same window. The honest companion
   * to `frameP95Ms`: work can sit at 3 ms while frames still arrive at 33 ms because
   * the cost is in compositing, which nothing on this side of the callback can see.
   * On a display locked at 60 this idles at 16.7 even when nothing is wrong, so it is
   * a symptom reading, not a gate — read it when the work number looks too good.
   */
  intervalP95Ms: number;
  simStepsLastFrame: number;
  slowFrames: number;
  totalFrames: number;
}

/**
 * A ring of samples and the percentile over it, allocating nothing: this is read from
 * inside the render callback, so the scratch buffer is sorted in place and its unused
 * tail is filled with Infinity, which parks it past every real sample however full the
 * ring is. Sorting a `subarray` view would be shorter and allocates one object per read.
 */
export class SampleRing {
  private readonly ring = new Float64Array(SAMPLE_WINDOW);
  private readonly scratch = new Float64Array(SAMPLE_WINDOW);
  private index = 0;
  private count = 0;

  push(v: number): void {
    this.ring[this.index] = v;
    this.index = (this.index + 1) % SAMPLE_WINDOW;
    if (this.count < SAMPLE_WINDOW) this.count++;
  }

  /** Forgets every sample, so the next percentile is over the frames after this call. */
  clear(): void {
    this.index = 0;
    this.count = 0;
  }

  /** Nearest-rank percentile, `p` in 0..1. Zero until there is anything to read. */
  percentile(p: number): number {
    if (this.count === 0) return 0;
    this.scratch.fill(Infinity);
    for (let i = 0; i < this.count; i++) this.scratch[i] = this.ring[i];
    this.scratch.sort();
    return this.scratch[Math.max(0, Math.ceil(p * this.count) - 1)];
  }
}

export interface GameLoopOptions {
  /** Fixed simulation timestep in seconds. */
  fixedDt?: number;
  /** Hard cap on catch-up steps so a stalled tab cannot produce a spike of work. */
  maxStepsPerFrame?: number;
  onStep: (dt: number) => void;
  onRender: (alpha: number, stats: GameLoopStats) => void;
}

/**
 * Slowblue: fixed-timestep accumulator with render interpolation.
 * Simulation determinism is a hard requirement (seed replay, unit tests), so the
 * sim never sees a variable dt. Rendering gets an `alpha` to interpolate with.
 */
export class GameLoop {
  readonly fixedDt: number;
  private readonly maxSteps: number;
  private readonly onStep: (dt: number) => void;
  private readonly onRender: (alpha: number, stats: GameLoopStats) => void;

  private accumulator = 0;
  private lastTime = 0;
  private rafId = 0;
  private running = false;
  private fpsAccum = 0;
  private fpsFrames = 0;
  private readonly workSamples = new SampleRing();
  private readonly intervalSamples = new SampleRing();

  /** 1 = realtime, 0.25 = slow motion, 0 = paused (debug only). */
  timeScale = 1;

  readonly stats: GameLoopStats = {
    fps: 0,
    frameMs: 0,
    frameP95Ms: 0,
    intervalP95Ms: 0,
    simStepsLastFrame: 0,
    slowFrames: 0,
    totalFrames: 0,
  };

  constructor(opts: GameLoopOptions) {
    this.fixedDt = opts.fixedDt ?? 1 / 60;
    this.maxSteps = opts.maxStepsPerFrame ?? 5;
    this.onStep = opts.onStep;
    this.onRender = opts.onRender;
  }

  start(): void {
    if (this.running) return;
    this.running = true;
    this.lastTime = performance.now();
    this.rafId = requestAnimationFrame(this.frame);
  }

  stop(): void {
    this.running = false;
    if (this.rafId) cancelAnimationFrame(this.rafId);
    this.rafId = 0;
  }

  /** Called when the tab becomes visible again: drop the accumulated backlog. */
  resync(): void {
    this.lastTime = performance.now();
    this.accumulator = 0;
  }

  /**
   * Throws both p95 windows away, so the next reading is only about what happens
   * after this call.
   *
   * For the one thing that changes what a frame *costs* while the game is running:
   * moving the quality ladder. A rung that halves the backing store leaves 300
   * frames of the old resolution in the ring, and for five seconds after the change
   * the percentile is a blend of two different pictures - a number that is wrong in
   * a way nobody can see, which is the exact failure the ladder readout was added to
   * stop (see `qualityPinned` in `main.ts`). Both readings go, not just the work
   * one: a resize reallocates the backing store, and the frame that does it is not
   * an interval anybody wants in the sample either.
   */
  resetSamples(): void {
    this.workSamples.clear();
    this.intervalSamples.clear();
    this.stats.frameP95Ms = 0;
    this.stats.intervalP95Ms = 0;
  }

  private frame = (now: number): void => {
    if (!this.running) return;
    const frameStart = now;
    // Clamp elapsed time: a backgrounded tab must not fast-forward the sim.
    const elapsed = Math.min((now - this.lastTime) / 1000, 0.25);
    this.lastTime = now;
    this.accumulator += elapsed * this.timeScale;

    let steps = 0;
    while (this.accumulator >= this.fixedDt && steps < this.maxSteps) {
      this.onStep(this.fixedDt);
      this.accumulator -= this.fixedDt;
      steps++;
    }
    if (steps === this.maxSteps) this.accumulator = 0;
    this.stats.simStepsLastFrame = steps;

    const alpha = this.timeScale > 0 ? this.accumulator / this.fixedDt : 0;
    this.onRender(alpha, this.stats);

    this.stats.frameMs = performance.now() - frameStart;
    this.stats.totalFrames++;
    if (elapsed > 1 / 45) this.stats.slowFrames++;
    this.workSamples.push(this.stats.frameMs);
    this.intervalSamples.push(elapsed * 1000);
    this.fpsAccum += elapsed;
    this.fpsFrames++;
    if (this.fpsAccum >= 0.5) {
      this.stats.fps = this.fpsFrames / this.fpsAccum;
      // Both percentiles ride the fps clock rather than being computed per frame. Two
      // sorts of 300 doubles land inside the render callback, so they are paid out of
      // the very budget they measure; twice a second that is noise, sixty times a
      // second it is the instrument changing the reading.
      this.stats.frameP95Ms = this.workSamples.percentile(0.95);
      this.stats.intervalP95Ms = this.intervalSamples.percentile(0.95);
      this.fpsAccum = 0;
      this.fpsFrames = 0;
    }

    this.rafId = requestAnimationFrame(this.frame);
  };
}

/**
 * Headless equivalent of the loop's stepping rule. Used by unit tests to assert
 * that a wall-clock duration maps to a deterministic number of fixed steps.
 */
export function accumulateSteps(
  accumulator: number,
  elapsed: number,
  fixedDt: number,
  maxSteps: number,
): { steps: number; accumulator: number } {
  let acc = accumulator + Math.min(elapsed, 0.25);
  let steps = 0;
  while (acc >= fixedDt && steps < maxSteps) {
    acc -= fixedDt;
    steps++;
  }
  if (steps === maxSteps) acc = 0;
  return { steps, accumulator: acc };
}
