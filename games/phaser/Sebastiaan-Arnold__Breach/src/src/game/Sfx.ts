/**
 * Procedural sound effects through the Web Audio API, so the prototype ships with no audio assets.
 * Swap for recorded sounds (Freesound / Kenney) later; the call sites stay the same.
 */
export interface SfxOpts {
  /** -1 (left) .. 1 (right). */
  pan?: number;
  /** 0..1 multiplier, e.g. for distance. */
  vol?: number;
}

/** What a footstep lands on. */
export type Surface = 'wood' | 'deck' | 'tile' | 'concrete' | 'grass';

export class Sfx {
  private ctx?: AudioContext;
  private master?: GainNode;
  private noiseBuf?: AudioBuffer;
  private volume = 0.8;
  /** The menu's ambient bed, while it plays. */
  private bed: { stop: () => void } | null = null;
  /** A level's ambience, while a mission plays. */
  private levelBed: { stop: () => void } | null = null;

  /** Master volume, 0..1 (from the settings). */
  setVolume(v: number): void {
    this.volume = Math.max(0, Math.min(1, v));
    if (this.master && this.ctx) this.master.gain.setTargetAtTime(this.level, this.ctx.currentTime, 0.05);
  }

  private get level(): number {
    return 0.55 * this.volume;
  }

  /** Must be called from a user gesture before anything is audible. */
  unlock(): void {
    if (!this.ctx) {
      const Ctor = window.AudioContext ?? (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (!Ctor) return;
      this.ctx = new Ctor();
      this.master = this.ctx.createGain();
      this.master.gain.value = this.level;
      this.master.connect(this.ctx.destination);
      const len = this.ctx.sampleRate;
      this.noiseBuf = this.ctx.createBuffer(1, len, this.ctx.sampleRate);
      const data = this.noiseBuf.getChannelData(0);
      for (let i = 0; i < len; i++) data[i] = Math.random() * 2 - 1;
    }
    void this.ctx.resume();
  }

  shot(heavy = false, o: SfxOpts = {}, suppressed = false): void {
    if (suppressed) {
      // A muffled cough rather than a crack.
      this.noise(0.08, 900, 'lowpass', 0.5, o);
      this.tone(110, 50, 0.08, 'sine', 0.4, o);
      return;
    }
    this.noise(heavy ? 0.22 : 0.15, heavy ? 1600 : 2600, 'lowpass', 0.9, o);
    this.tone(heavy ? 120 : 160, 45, 0.14, 'sine', 0.7, o);
  }

  /** A pane shattering: a crash, then pieces landing. */
  glass(o: SfxOpts = {}): void {
    this.noise(0.18, 3800, 'highpass', 0.8, o);
    this.noise(0.4, 6000, 'highpass', 0.35, o, 0.05);
    for (let i = 0; i < 6; i++) this.tone(2400 + Math.random() * 3000, 2000 + Math.random() * 2000, 0.05, 'sine', 0.12, o, 0.08 + Math.random() * 0.35);
  }

  /** A breach charge: a deep thump, the crack, then debris coming down. */
  blast(o: SfxOpts = {}): void {
    this.tone(110, 32, 0.7, 'sine', 0.9, o);
    this.noise(0.55, 650, 'lowpass', 1, o);
    this.noise(0.22, 3200, 'highpass', 0.6, o);
    for (let i = 0; i < 9; i++) this.noise(0.04, 1200 + Math.random() * 2400, 'bandpass', 0.18, o, 0.15 + Math.random() * 0.7);
  }

  /** The charge's fuse, counting down. */
  chargeBeep(o: SfxOpts = {}): void {
    this.tone(2300, 2300, 0.05, 'square', 0.08, o);
  }

  /** Working a bolt: back, then forward. */
  bolt(o: SfxOpts = {}): void {
    this.noise(0.035, 2600, 'bandpass', 0.35, o);
    this.noise(0.045, 1700, 'bandpass', 0.4, o, 0.2);
  }

  dryFire(o: SfxOpts = {}): void {
    this.noise(0.03, 5000, 'highpass', 0.25, o);
  }

  reload(o: SfxOpts = {}): void {
    this.noise(0.04, 3500, 'bandpass', 0.35, o);
    this.noise(0.05, 2200, 'bandpass', 0.4, o, 0.35);
  }

  creak(o: SfxOpts = {}): void {
    const vol = 0.06 * (o.vol ?? 1);
    this.sweep(170, 260, 0.55, vol, o.pan);
  }

  /** A footstep, sounding like what it lands on. */
  footstep(loud: boolean, o: SfxOpts = {}, surface: Surface = 'concrete'): void {
    const v = loud ? 1 : 0.4;
    switch (surface) {
      case 'wood':
        this.noise(0.06, loud ? 1100 : 800, 'bandpass', 0.4 * v, o);
        this.tone(140, 110, 0.05, 'sine', 0.12 * v, o);
        break;
      case 'deck':
        this.noise(0.05, 1300, 'bandpass', 0.35 * v, o);
        this.tone(190, 150, 0.07, 'triangle', 0.14 * v, o);
        break;
      case 'tile':
        this.noise(0.03, 3200, 'highpass', 0.3 * v, o);
        this.noise(0.04, 900, 'lowpass', 0.18 * v, o);
        break;
      case 'grass':
        this.noise(0.08, 2600, 'highpass', 0.14 * v, o);
        break;
      default:
        this.noise(0.05, loud ? 900 : 600, 'lowpass', 0.35 * v, o);
        this.noise(0.02, 2400, 'highpass', 0.08 * v, o);
    }
  }

  /**
   * A level's background: wind outdoors, a low room tone indoors. Mixed by how much of the level
   * is open to the sky; plays until the mission ends.
   */
  levelAmbience(outdoor: number): void {
    this.stopLevelAmbience();
    if (!this.ctx || !this.master || !this.noiseBuf) return;
    const ctx = this.ctx, t = ctx.currentTime;
    const out = ctx.createGain();
    out.gain.setValueAtTime(0.0001, t);
    out.gain.linearRampToValueAtTime(1, t + 2);
    out.connect(this.master);
    // Wind: low-passed noise whose cut-off drifts.
    const wind = ctx.createBufferSource();
    wind.buffer = this.noiseBuf;
    wind.loop = true;
    const wf = ctx.createBiquadFilter();
    wf.type = 'lowpass';
    wf.frequency.value = 500;
    const gust = ctx.createOscillator(), gustGain = ctx.createGain();
    gust.frequency.value = 0.08;
    gustGain.gain.value = 260;
    gust.connect(gustGain).connect(wf.frequency);
    const wg = ctx.createGain();
    wg.gain.value = 0.09 * outdoor;
    wind.connect(wf).connect(wg).connect(out);
    // Room tone: a faint mains hum and its harmonic.
    const hum = [50, 100].map((f, i) => {
      const o = ctx.createOscillator();
      o.frequency.value = f;
      const g = ctx.createGain();
      g.gain.value = (i ? 0.006 : 0.012) * (1 - outdoor * 0.7);
      o.connect(g).connect(out);
      return o;
    });
    for (const o of [gust, ...hum]) o.start(t);
    wind.start(t);
    this.levelBed = {
      stop: () => {
        const now = ctx.currentTime;
        out.gain.cancelScheduledValues(now);
        out.gain.setValueAtTime(out.gain.value, now);
        out.gain.linearRampToValueAtTime(0.0001, now + 0.6);
        for (const o of [gust, ...hum]) o.stop(now + 0.7);
        wind.stop(now + 0.7);
      },
    };
  }

  stopLevelAmbience(): void {
    this.levelBed?.stop();
    this.levelBed = null;
  }

  railTick(o: SfxOpts = {}): void {
    this.noise(0.06, 1400, 'bandpass', 0.18, o);
  }

  hit(o: SfxOpts = {}): void {
    this.noise(0.07, 1800, 'bandpass', 0.6, o);
  }

  impact(o: SfxOpts = {}): void {
    this.noise(0.05, 3000, 'highpass', 0.15, o);
  }

  /** A UI selection tick. */
  select(): void {
    this.noise(0.02, 4000, 'highpass', 0.3);
  }

  /** Moving over a menu item: the faintest tick. */
  hover(): void {
    this.tone(1800, 1700, 0.025, 'sine', 0.05);
  }

  /** Confirming a menu choice. */
  confirm(): void {
    this.tone(520, 780, 0.09, 'triangle', 0.16);
    this.noise(0.03, 5000, 'highpass', 0.12);
  }

  /** Backing out of a menu. */
  back(): void {
    this.tone(520, 360, 0.09, 'triangle', 0.13);
  }

  /** A star stamped onto the debrief. */
  star(i: number): void {
    const f = [660, 784, 988][i] ?? 988;
    this.tone(f, f, 0.18, 'triangle', 0.2);
    this.tone(f * 2, f * 2, 0.12, 'sine', 0.06, {}, 0.02);
  }

  /**
   * A low ambient bed for the menus: two detuned drones under a slow filter sweep and a faint
   * city hiss. Starts once, keeps playing across menu screens, fades out on deploy.
   */
  menuAmbience(on: boolean): void {
    if (!on) {
      this.bed?.stop();
      this.bed = null;
      return;
    }
    if (this.bed || !this.ctx || !this.master || !this.noiseBuf) return;
    const ctx = this.ctx, t = ctx.currentTime;
    const out = ctx.createGain();
    out.gain.setValueAtTime(0.0001, t);
    out.gain.linearRampToValueAtTime(0.16, t + 3);
    const lp = ctx.createBiquadFilter();
    lp.type = 'lowpass';
    lp.frequency.value = 420;
    const lfo = ctx.createOscillator(), lfoGain = ctx.createGain();
    lfo.frequency.value = 0.05;
    lfoGain.gain.value = 180;
    lfo.connect(lfoGain).connect(lp.frequency);
    const oscs = [55, 55.4, 82.4, 110.2].map((f, i) => {
      const o = ctx.createOscillator();
      o.type = i < 2 ? 'sawtooth' : 'triangle';
      o.frequency.value = f;
      const g = ctx.createGain();
      g.gain.value = i < 2 ? 0.35 : 0.25;
      o.connect(g).connect(lp);
      return o;
    });
    const hiss = ctx.createBufferSource();
    hiss.buffer = this.noiseBuf;
    hiss.loop = true;
    const hf = ctx.createBiquadFilter();
    hf.type = 'bandpass';
    hf.frequency.value = 900;
    const hg = ctx.createGain();
    hg.gain.value = 0.05;
    hiss.connect(hf).connect(hg).connect(out);
    lp.connect(out).connect(this.master);
    for (const o of [...oscs, lfo]) o.start(t);
    hiss.start(t);
    this.bed = {
      stop: () => {
        const now = ctx.currentTime;
        out.gain.cancelScheduledValues(now);
        out.gain.setValueAtTime(out.gain.value, now);
        out.gain.linearRampToValueAtTime(0.0001, now + 1.2);
        for (const o of [...oscs, lfo]) o.stop(now + 1.3);
        hiss.stop(now + 1.3);
      },
    };
  }

  /** The operator takes a hit. */
  hurt(): void {
    this.tone(120, 60, 0.25, 'sine', 0.9);
    this.noise(0.12, 700, 'lowpass', 0.6);
  }

  /** An enemy shouting a warning: a short, rough burst. */
  shout(o: SfxOpts = {}): void {
    this.tone(260, 180, 0.3, 'sawtooth', 0.08, o);
    this.tone(330, 220, 0.25, 'square', 0.04, o, 0.05);
  }

  penalty(): void {
    this.tone(220, 200, 0.35, 'square', 0.12);
    this.tone(160, 150, 0.45, 'square', 0.12, {}, 0.12);
  }

  ok(): void {
    this.tone(660, 660, 0.12, 'triangle', 0.25);
    this.tone(990, 990, 0.2, 'triangle', 0.25, {}, 0.1);
  }

  secured(): void {
    [523, 659, 784, 1046].forEach((f, i) => this.tone(f, f, 0.35, 'triangle', 0.22, {}, i * 0.12));
  }

  private out(pan: number | undefined): AudioNode | undefined {
    if (!this.ctx || !this.master || this.volume <= 0) return undefined;
    if (pan === undefined || !this.ctx.createStereoPanner) return this.master;
    const p = this.ctx.createStereoPanner();
    p.pan.value = Math.max(-1, Math.min(1, pan));
    p.connect(this.master);
    return p;
  }

  private noise(dur: number, freq: number, type: BiquadFilterType, gain: number, o: SfxOpts = {}, delay = 0): void {
    const dest = this.out(o.pan);
    if (!this.ctx || !dest || !this.noiseBuf) return;
    const t = this.ctx.currentTime + delay;
    const src = this.ctx.createBufferSource();
    src.buffer = this.noiseBuf;
    const f = this.ctx.createBiquadFilter();
    f.type = type;
    f.frequency.value = freq;
    const g = this.ctx.createGain();
    g.gain.setValueAtTime(gain * (o.vol ?? 1), t);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    src.connect(f).connect(g).connect(dest);
    src.start(t, Math.random() * 0.5);
    src.stop(t + dur + 0.02);
  }

  private tone(f0: number, f1: number, dur: number, type: OscillatorType, gain: number, o: SfxOpts = {}, delay = 0): void {
    const dest = this.out(o.pan);
    if (!this.ctx || !dest) return;
    const t = this.ctx.currentTime + delay;
    const osc = this.ctx.createOscillator();
    osc.type = type;
    osc.frequency.setValueAtTime(f0, t);
    osc.frequency.exponentialRampToValueAtTime(Math.max(1, f1), t + dur);
    const g = this.ctx.createGain();
    g.gain.setValueAtTime(gain * (o.vol ?? 1), t);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    osc.connect(g).connect(dest);
    osc.start(t);
    osc.stop(t + dur + 0.02);
  }

  private sweep(f0: number, f1: number, dur: number, gain: number, pan?: number): void {
    const dest = this.out(pan);
    if (!this.ctx || !dest) return;
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(f0, t);
    osc.frequency.linearRampToValueAtTime(f1, t + dur * 0.6);
    osc.frequency.linearRampToValueAtTime(f0 * 0.9, t + dur);
    const f = this.ctx.createBiquadFilter();
    f.type = 'bandpass';
    f.frequency.value = 900;
    f.Q.value = 6;
    const g = this.ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.linearRampToValueAtTime(gain, t + 0.05);
    g.gain.linearRampToValueAtTime(0.0001, t + dur);
    osc.connect(f).connect(g).connect(dest);
    osc.start(t);
    osc.stop(t + dur + 0.02);
  }
}
