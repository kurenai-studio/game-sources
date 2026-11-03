import {
  DEFAULT_TUNING,
  TUNING_KEYS,
  TUNING_LIMITS,
  sanitizeTuning,
  type Tuning,
} from '../config/tuning';
import type { RenderDebugFlags } from '../render/Renderer';

const TUNING_STORE = 'tide.tuning.v1';

/**
 * The rungs a measurement is taken at, and `null` for letting the ladder go again.
 *
 * Rung 0 is the gate's own number: the whole picture, the scaler held out of the way.
 * 2 and 3 are the instrument — they differ in one thing only (`dpr` 1 against 0.8, the
 * same particle budget), so a reading either side of that step is two areas of the same
 * picture on the same silicon, and the pair solves `frame = sim + area * draw` for this
 * device instead of borrowing the split from a headless browser. 1 and 4 are not here
 * because neither answers a question the other three leave open.
 */
const PIN_RUNGS: readonly (number | null)[] = [0, 2, 3, null];

export interface DebugHost {
  tuning: Tuning;
  flags: RenderDebugFlags;
  getStats(): {
    fps: number;
    frameMs: number;
    frameP95Ms: number;
    intervalP95Ms: number;
    slowFrames: number;
    totalFrames: number;
  };
  /**
   * Which rung of the frame-rate scaler the run is on, the device pixel ratio it has
   * left, and the area that ratio bought. Without the rung a p95 reading is
   * unreadable: the ladder makes the game cheaper under load, so a device that cannot
   * hold the picture reports a comfortable frame time and a quietly degraded image,
   * and the two look identical in numbers.
   *
   * `mpx` is the term that varies between the devices being compared. This renderer
   * is fill-bound, so a phone row and a tablet row do not mean the same thing until
   * the backing store each was filling is written next to them — an iPad's is four to
   * six times an iPhone SE's, a bigger multiplier than the whole headroom F0 measured.
   */
  getQuality(): { rung: number; rungs: number; dpr: number; mpx: number };
  /** Which rung the ladder is held at, or `null` while it is free to move. */
  getQualityPin(): number | null;
  setQualityPin(rung: number | null): void;
  /** The section the run is in, which is what a measured row is filed under. */
  getZone(): number;
  getSeed(): number;
  restart(seed?: number): void;
  setTimeScale(v: number): void;
  getTimeScale(): number;
  exportTelemetry(): void;
  clearTelemetry(): void;
}

/** Persisted tuning overrides, applied at boot. Empty object if none/corrupt. */
export function loadStoredTuning(): Tuning {
  try {
    const raw = localStorage.getItem(TUNING_STORE);
    if (raw === null) return { ...DEFAULT_TUNING };
    return sanitizeTuning(JSON.parse(raw));
  } catch {
    return { ...DEFAULT_TUNING };
  }
}

function storeTuning(t: Tuning): void {
  try {
    localStorage.setItem(TUNING_STORE, JSON.stringify(t));
  } catch {
    /* best effort */
  }
}

/**
 * Slowblue: the tuning surface. Feel cannot be reasoned about in the abstract, so every
 * physical parameter is live-editable on the device the game is being felt on.
 * Hidden unless ?debug=1 (or a dev build), and it never affects the sim by existing.
 */
export class DebugPanel {
  private root: HTMLDivElement;
  private body: HTMLDivElement;
  private statsEl: HTMLPreElement;
  private rows = new Map<keyof Tuning, { input: HTMLInputElement; out: HTMLSpanElement }>();
  private pins = new Map<number | null, HTMLButtonElement>();
  private open = false;

  constructor(private readonly host: DebugHost) {
    this.root = document.createElement('div');
    this.root.className = 'slowblue-debug';
    this.root.innerHTML = '';

    const toggle = document.createElement('button');
    toggle.className = 'slowblue-debug-toggle';
    toggle.textContent = '⚙';
    toggle.setAttribute('aria-label', 'debug panel');
    toggle.addEventListener('click', () => this.setOpen(!this.open));

    this.body = document.createElement('div');
    this.body.className = 'slowblue-debug-body';

    this.statsEl = document.createElement('pre');
    this.statsEl.className = 'slowblue-debug-stats';
    this.body.appendChild(this.statsEl);

    // Directly under the numbers, because it is the control those numbers are read
    // through: pin, play, read, pin the next one.
    this.body.appendChild(this.buildPins());
    this.body.appendChild(this.buildControls());
    this.body.appendChild(this.buildSliders());

    this.root.appendChild(toggle);
    this.root.appendChild(this.body);
    document.body.appendChild(this.root);
    this.setOpen(false);

    window.addEventListener('keydown', (e) => {
      if (e.key === 'd' || e.key === 'D') this.setOpen(!this.open);
    });
  }

  /**
   * The rungs, as a row of buttons — the whole of a measurement session's controls.
   *
   * This was a `pin q0` checkbox, which was the right shape while rung 0 was the only
   * rung the panel could ask for and every other one meant a console call. On an iPad
   * a console is a Mac and a cable, and a hand off the device between readings that
   * are ten seconds of play apart - so the half of the measurement that solves the
   * fill/sim split was the half still tied to a wire. The row unties it: three taps
   * and an `off`, on the glass the number is about.
   *
   * Sized for a finger rather than a mouse, and alone in the panel in that — the other
   * controls are read on a desktop, this one is worked mid-run on a tablet.
   */
  private buildPins(): HTMLElement {
    const wrap = document.createElement('div');
    wrap.className = 'slowblue-debug-controls slowblue-debug-pins';
    const label = document.createElement('span');
    label.textContent = 'pin';
    wrap.appendChild(label);
    for (const rung of PIN_RUNGS) {
      const b = this.button(rung === null ? 'off' : `q${rung}`, () => {
        this.host.setQualityPin(rung);
        // Not left to the next frame: a tap that does not light up reads as a tap
        // that missed, and the answer to that is another tap and a lost window.
        this.syncPins();
      });
      this.pins.set(rung, b);
      wrap.appendChild(b);
    }
    return wrap;
  }

  /** Which button is lit, asked of the game and not remembered here — `pinQuality`
   *  is also reachable from the console door, and two memories would disagree. */
  private syncPins(): void {
    const at = this.host.getQualityPin();
    for (const [rung, b] of this.pins) b.classList.toggle('on', rung === at);
  }

  private buildControls(): HTMLElement {
    const wrap = document.createElement('div');
    wrap.className = 'slowblue-debug-controls';

    const seed = document.createElement('input');
    seed.type = 'text';
    seed.value = String(this.host.getSeed());
    seed.className = 'slowblue-debug-seed';
    seed.setAttribute('aria-label', 'seed');

    wrap.appendChild(
      this.button('replay seed', () => {
        const n = Number(seed.value);
        this.host.restart(Number.isFinite(n) ? n >>> 0 : undefined);
      }),
    );
    wrap.appendChild(seed);
    wrap.appendChild(
      this.button('new seed', () => {
        const n = (Math.random() * 0xffffffff) >>> 0;
        seed.value = String(n);
        this.host.restart(n);
      }),
    );

    wrap.appendChild(this.checkbox('field', () => this.host.flags.showField, (v) => (this.host.flags.showField = v)));
    wrap.appendChild(this.checkbox('hash', () => this.host.flags.showHash, (v) => (this.host.flags.showHash = v)));
    wrap.appendChild(this.checkbox('stats', () => this.host.flags.showStats, (v) => (this.host.flags.showStats = v)));

    wrap.appendChild(this.button('1x', () => this.host.setTimeScale(1)));
    wrap.appendChild(this.button('0.25x', () => this.host.setTimeScale(0.25)));
    wrap.appendChild(
      this.button('pause', () => this.host.setTimeScale(this.host.getTimeScale() === 0 ? 1 : 0)),
    );

    wrap.appendChild(
      this.button('export cfg', () => {
        void copyOrDownload('slowblue-tuning.json', JSON.stringify(this.host.tuning, null, 2));
      }),
    );
    wrap.appendChild(
      this.button('import cfg', () => {
        const text = window.prompt('Paste tuning JSON');
        if (text === null) return;
        try {
          const next = sanitizeTuning(JSON.parse(text), this.host.tuning);
          Object.assign(this.host.tuning, next);
          storeTuning(this.host.tuning);
          this.syncSliders();
        } catch {
          window.alert('Invalid JSON');
        }
      }),
    );
    wrap.appendChild(
      this.button('defaults', () => {
        Object.assign(this.host.tuning, DEFAULT_TUNING);
        storeTuning(this.host.tuning);
        this.syncSliders();
      }),
    );
    wrap.appendChild(this.button('export telemetry', () => this.host.exportTelemetry()));
    wrap.appendChild(this.button('wipe telemetry', () => this.host.clearTelemetry()));
    return wrap;
  }

  private buildSliders(): HTMLElement {
    const wrap = document.createElement('div');
    wrap.className = 'slowblue-debug-sliders';
    for (const key of TUNING_KEYS) {
      const [min, max, step] = TUNING_LIMITS[key];
      const row = document.createElement('label');
      row.className = 'slowblue-debug-row';
      const name = document.createElement('span');
      name.textContent = key === 'agentCount' ? 'agentCount*' : key;
      const input = document.createElement('input');
      input.type = 'range';
      input.min = String(min);
      input.max = String(max);
      input.step = String(step);
      input.value = String(this.host.tuning[key]);
      const out = document.createElement('span');
      out.className = 'slowblue-debug-val';
      out.textContent = format(this.host.tuning[key]);
      input.addEventListener('input', () => {
        const v = Number(input.value);
        this.host.tuning[key] = v;
        out.textContent = format(v);
        storeTuning(this.host.tuning);
      });
      row.appendChild(name);
      row.appendChild(input);
      row.appendChild(out);
      wrap.appendChild(row);
      this.rows.set(key, { input, out });
    }
    const note = document.createElement('div');
    note.className = 'slowblue-debug-note';
    note.textContent = '* applies on next run';
    wrap.appendChild(note);
    return wrap;
  }

  private button(label: string, onClick: () => void): HTMLButtonElement {
    const b = document.createElement('button');
    b.textContent = label;
    b.addEventListener('click', onClick);
    return b;
  }

  private checkbox(label: string, get: () => boolean, set: (v: boolean) => void): HTMLElement {
    const l = document.createElement('label');
    l.className = 'slowblue-debug-check';
    const c = document.createElement('input');
    c.type = 'checkbox';
    c.checked = get();
    c.addEventListener('change', () => set(c.checked));
    l.appendChild(c);
    l.appendChild(document.createTextNode(label));
    return l;
  }

  private syncSliders(): void {
    for (const [key, row] of this.rows) {
      row.input.value = String(this.host.tuning[key]);
      row.out.textContent = format(this.host.tuning[key]);
    }
  }

  setOpen(open: boolean): void {
    this.open = open;
    this.body.style.display = open ? 'flex' : 'none';
  }

  update(): void {
    if (!this.open) return;
    const s = this.host.getStats();
    const slow = s.totalFrames === 0 ? 0 : (s.slowFrames / s.totalFrames) * 100;
    // The p95 line is the one the iOS gate is read off, so it says p95 in as many words
    // and sits on its own line: the reading is taken off a phone in someone's hand, and
    // the previous layout put the only stable number in the middle of a flickering one.
    //
    // `mpx` and `zone` are on the line below for the same reason the row of pins is
    // under them: a row copied off this panel has to be comparable to another device's
    // and findable again on this one, and neither is true of a bare p95.
    const q = this.host.getQuality();
    this.statsEl.textContent =
      `fps ${s.fps.toFixed(1)}  frame ${s.frameMs.toFixed(2)}ms\n` +
      `p95 work ${s.frameP95Ms.toFixed(2)}ms  gap ${s.intervalP95Ms.toFixed(2)}ms\n` +
      `rung ${q.rung}/${q.rungs - 1}  dpr ${q.dpr.toFixed(2)}${this.host.getQualityPin() === null ? '' : ' pinned'}\n` +
      `mpx ${q.mpx.toFixed(2)}  zone ${this.host.getZone()}\n` +
      `slow ${slow.toFixed(1)}%  seed ${this.host.getSeed()}`;
    this.syncPins();
  }
}

function format(v: number): string {
  if (Math.abs(v) >= 100) return v.toFixed(0);
  if (Math.abs(v) >= 1) return v.toFixed(2);
  return v.toFixed(4);
}

/** Download a blob; falls back to a clipboard copy where downloads are blocked. */
export async function copyOrDownload(filename: string, text: string): Promise<void> {
  try {
    const blob = new Blob([text], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 2000);
  } catch {
    try {
      await navigator.clipboard.writeText(text);
      window.alert('Copied to clipboard');
    } catch {
      window.alert(text.slice(0, 2000));
    }
  }
}
