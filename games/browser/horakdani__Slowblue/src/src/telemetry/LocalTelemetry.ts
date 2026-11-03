import type { World } from '../sim/World';

export interface RunRecord {
  index: number;
  seed: number;
  seedRepeat: boolean;
  /** ms from run start to the first gesture. The core comprehension signal. */
  timeToFirstInputMs: number | null;
  durationSec: number;
  /** ms from failure to the next run start. */
  restartLatencyMs: number | null;
  gestures: number;
  meanGestureLengthPx: number;
  gates: number;
  rescued: number;
  lost: number;
  missedPods: number;
  /** Campaign: how far the dive got, and how many dashed rings it held. */
  levelsCleared: number;
  ringsHeld: number;
  completed: boolean;
  peakCount: number;
  endCount: number;
  score: number;
  averageSpread: number;
  failReason: string | null;
  fps: number;
  slowFrameRatio: number;
}

export interface TelemetryExport {
  version: 1;
  createdAt: string;
  sessionStartedAt: string;
  device: { width: number; height: number; dpr: number; ua: string };
  runsStarted: number;
  runs: RunRecord[];
}

const STORAGE_KEY = 'tide.telemetry.v1';

/**
 * Slowblue: strictly local instrumentation. Nothing leaves the device; there is no
 * network code in this project at all. Its only job is to make the falsification
 * gates measurable when a real player finally holds the phone.
 */
export class LocalTelemetry {
  private runs: RunRecord[] = [];
  private runsStarted = 0;
  private sessionStartedAt = new Date().toISOString();
  private runStartMs = 0;
  private firstInputMs: number | null = null;
  private lastFailMs: number | null = null;
  private pendingRestartLatency: number | null = null;
  private seenSeeds = new Set<number>();
  private currentSeed = 0;
  private seedRepeat = false;
  private closed = true;

  constructor() {
    this.load();
  }

  private load(): void {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw === null) return;
      const parsed = JSON.parse(raw) as Partial<TelemetryExport>;
      if (Array.isArray(parsed.runs)) this.runs = parsed.runs as RunRecord[];
      if (typeof parsed.runsStarted === 'number') this.runsStarted = parsed.runsStarted;
      if (typeof parsed.sessionStartedAt === 'string') this.sessionStartedAt = parsed.sessionStartedAt;
      for (const r of this.runs) this.seenSeeds.add(r.seed);
    } catch {
      /* corrupt local data is not worth a crash in a prototype */
    }
  }

  private persist(): void {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.snapshot()));
    } catch {
      /* private mode / quota - telemetry is best-effort */
    }
  }

  beginRun(seed: number, nowMs = performance.now()): void {
    this.runsStarted++;
    this.runStartMs = nowMs;
    this.firstInputMs = null;
    this.currentSeed = seed;
    this.seedRepeat = this.seenSeeds.has(seed);
    this.seenSeeds.add(seed);
    this.pendingRestartLatency = this.lastFailMs === null ? null : nowMs - this.lastFailMs;
    this.lastFailMs = null;
    this.closed = false;
  }

  noteFirstInput(nowMs = performance.now()): void {
    if (this.firstInputMs === null) this.firstInputMs = nowMs - this.runStartMs;
  }

  endRun(world: World, fps: number, slowFrameRatio: number, nowMs = performance.now()): void {
    if (this.closed) return;
    this.closed = true;
    this.lastFailMs = nowMs;
    const gestures = world.gestureCount;
    this.runs.push({
      index: this.runsStarted,
      seed: this.currentSeed,
      seedRepeat: this.seedRepeat,
      timeToFirstInputMs: this.firstInputMs,
      durationSec: Number(world.run.time.toFixed(2)),
      restartLatencyMs:
        this.pendingRestartLatency === null ? null : Math.round(this.pendingRestartLatency),
      gestures,
      meanGestureLengthPx: gestures === 0 ? 0 : Math.round(world.gestureLengthTotal / gestures),
      gates: world.run.gates,
      rescued: world.run.rescued,
      lost: world.run.lost,
      missedPods: world.run.missedPods,
      levelsCleared: world.run.levelsCleared,
      ringsHeld: world.run.ringsHeld,
      completed: world.run.completed,
      peakCount: world.run.peakCount,
      endCount: world.shoalCount,
      score: world.run.score,
      averageSpread: Number(world.averageSpread.toFixed(1)),
      failReason: world.run.reason,
      fps: Number(fps.toFixed(1)),
      slowFrameRatio: Number(slowFrameRatio.toFixed(4)),
    });
    if (this.runs.length > 200) this.runs = this.runs.slice(-200);
    this.persist();
  }

  snapshot(): TelemetryExport {
    return {
      version: 1,
      createdAt: new Date().toISOString(),
      sessionStartedAt: this.sessionStartedAt,
      device: {
        width: typeof window === 'undefined' ? 0 : window.innerWidth,
        height: typeof window === 'undefined' ? 0 : window.innerHeight,
        dpr: typeof window === 'undefined' ? 1 : window.devicePixelRatio,
        ua: typeof navigator === 'undefined' ? 'node' : navigator.userAgent,
      },
      runsStarted: this.runsStarted,
      runs: this.runs,
    };
  }

  get runCount(): number {
    return this.runs.length;
  }

  clear(): void {
    this.runs = [];
    this.runsStarted = 0;
    this.seenSeeds.clear();
    this.persist();
  }
}
