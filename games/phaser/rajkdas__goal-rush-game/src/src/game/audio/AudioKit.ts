/**
 * GOAL RUSH — procedural WebAudio SFX kit.
 *
 * Zero audio assets: every sound is synthesized on the fly with oscillators
 * and filtered noise. The context is created lazily and unlocked on the
 * first user gesture (mobile autoplay policy).
 */

type Wave = OscillatorType;

export class AudioKit {
  private ctx: AudioContext | null = null;
  private master: GainNode | null = null;
  private crowdGain: GainNode | null = null;
  private crowdSource: AudioBufferSourceNode | null = null;
  muted = false;

  /** Call from any pointer/key handler to satisfy autoplay policies. */
  unlock(): void {
    this.ensureCtx();
    if (this.ctx?.state === 'suspended') void this.ctx.resume();
  }

  toggleMute(): boolean {
    this.muted = !this.muted;
    if (this.master && this.ctx) {
      this.master.gain.setTargetAtTime(this.muted ? 0 : 0.9, this.ctx.currentTime, 0.02);
    }
    return this.muted;
  }

  // ── Table sounds ────────────────────────────────────────────────────────

  /** Referee whistle — game start. */
  whistle(): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    // Two detuned square oscillators + trill via amplitude LFO.
    for (const freq of [2350, 2650]) {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'square';
      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0, t);
      gain.gain.linearRampToValueAtTime(0.05, t + 0.02);
      // Trill.
      const lfo = ctx.createOscillator();
      const lfoGain = ctx.createGain();
      lfo.frequency.value = 26;
      lfoGain.gain.value = 0.035;
      lfo.connect(lfoGain).connect(gain.gain);
      lfo.start(t);
      lfo.stop(t + 0.55);
      gain.gain.setTargetAtTime(0, t + 0.45, 0.05);
      osc.connect(gain).connect(this.master!);
      osc.start(t);
      osc.stop(t + 0.6);
    }
  }

  /** Flipper thwack — low noise burst. */
  flipper(): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    const noise = this.noiseSource(0.07);
    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.value = 900;
    const gain = ctx.createGain();
    gain.gain.setValueAtTime(0.22, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.07);
    noise.connect(filter).connect(gain).connect(this.master!);
    noise.start(t);
    const thump = ctx.createOscillator();
    const tg = ctx.createGain();
    thump.type = 'sine';
    thump.frequency.setValueAtTime(150, t);
    thump.frequency.exponentialRampToValueAtTime(60, t + 0.08);
    tg.gain.setValueAtTime(0.18, t);
    tg.gain.exponentialRampToValueAtTime(0.001, t + 0.09);
    thump.connect(tg).connect(this.master!);
    thump.start(t);
    thump.stop(t + 0.1);
  }

  /** Pop bumper — bright ping with rising pitch per combo. */
  bumper(combo = 0): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    const base = 520 * Math.pow(1.06, Math.min(combo, 12));
    osc.frequency.setValueAtTime(base, t);
    osc.frequency.exponentialRampToValueAtTime(base * 1.9, t + 0.05);
    gain.gain.setValueAtTime(0.16, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.12);
    osc.connect(gain).connect(this.master!);
    osc.start(t);
    osc.stop(t + 0.13);
  }

  /** Slingshot snap. */
  sling(): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    const noise = this.noiseSource(0.05);
    const filter = ctx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.value = 1800;
    filter.Q.value = 1.2;
    const gain = ctx.createGain();
    gain.gain.setValueAtTime(0.2, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.06);
    noise.connect(filter).connect(gain).connect(this.master!);
    noise.start(t);
  }

  /** Spinner ratchet tick. */
  spinnerTick(): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'square';
    osc.frequency.value = 900;
    gain.gain.setValueAtTime(0.05, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.03);
    osc.connect(gain).connect(this.master!);
    osc.start(t);
    osc.stop(t + 0.035);
  }

  /** Rollover lane chime. */
  lane(letterIndex: number): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = 660 + letterIndex * 110;
    gain.gain.setValueAtTime(0.14, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.25);
    osc.connect(gain).connect(this.master!);
    osc.start(t);
    osc.stop(t + 0.26);
  }

  /** Ball drain — descending sad tone + crowd groan. */
  drain(): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(300, t);
    osc.frequency.exponentialRampToValueAtTime(70, t + 0.5);
    gain.gain.setValueAtTime(0.12, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.55);
    osc.connect(gain).connect(this.master!);
    osc.start(t);
    osc.stop(t + 0.6);
    this.crowdSwell(0.35, 0.4);
  }

  // ── Slot machine sounds ─────────────────────────────────────────────────

  /** Reel spin start — whirr. */
  reelStart(): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(90, t);
    osc.frequency.linearRampToValueAtTime(160, t + 0.3);
    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.value = 600;
    gain.gain.setValueAtTime(0.001, t);
    gain.gain.linearRampToValueAtTime(0.06, t + 0.08);
    gain.gain.setTargetAtTime(0, t + 0.3, 0.08);
    osc.connect(filter).connect(gain).connect(this.master!);
    osc.start(t);
    osc.stop(t + 0.55);
  }

  /** Reel stop thunk. */
  reelStop(index: number): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'square';
    osc.frequency.value = 140 + index * 40;
    gain.gain.setValueAtTime(0.12, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.09);
    osc.connect(gain).connect(this.master!);
    osc.start(t);
    osc.stop(t + 0.1);
  }

  /** Anticipation heartbeat (2 trophies on the line). */
  heartbeat(): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    const beat = (start: number): void => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(70, start);
      gain.gain.setValueAtTime(0.25, start);
      gain.gain.exponentialRampToValueAtTime(0.001, start + 0.14);
      osc.connect(gain).connect(this.master!);
      osc.start(start);
      osc.stop(start + 0.16);
    };
    beat(t);
    beat(t + 0.22);
  }

  /** Win jingle — ascending arpeggio sized by the win. */
  win(size: 'small' | 'big'): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    const notes = size === 'big' ? [523, 659, 784, 1047, 1319] : [523, 659, 784];
    notes.forEach((freq, i) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.value = freq;
      const start = t + i * 0.09;
      gain.gain.setValueAtTime(0.13, start);
      gain.gain.exponentialRampToValueAtTime(0.001, start + 0.28);
      osc.connect(gain).connect(this.master!);
      osc.start(start);
      osc.stop(start + 0.3);
    });
    if (size === 'big') this.crowdSwell(0.8, 0.8);
  }

  /** JACKPOT — fanfare + roaring crowd + airhorn. */
  jackpot(): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    // Fanfare.
    [392, 523, 659, 784, 1047].forEach((freq, i) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'square';
      osc.frequency.value = freq;
      const start = t + i * 0.12;
      gain.gain.setValueAtTime(0.09, start);
      gain.gain.exponentialRampToValueAtTime(0.001, start + 0.4);
      osc.connect(gain).connect(this.master!);
      osc.start(start);
      osc.stop(start + 0.42);
    });
    // Airhorn.
    const horn = ctx.createOscillator();
    const hg = ctx.createGain();
    horn.type = 'sawtooth';
    horn.frequency.setValueAtTime(220, t + 0.5);
    horn.frequency.linearRampToValueAtTime(440, t + 1.0);
    hg.gain.setValueAtTime(0.001, t + 0.5);
    hg.gain.linearRampToValueAtTime(0.12, t + 0.62);
    hg.gain.setTargetAtTime(0, t + 1.1, 0.12);
    horn.connect(hg).connect(this.master!);
    horn.start(t + 0.5);
    horn.stop(t + 1.6);
    this.crowdSwell(2.2, 1.0);
  }

  /** UI blip (buttons, spin trigger). */
  blip(freq = 880): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(0.1, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.08);
    osc.connect(gain).connect(this.master!);
    osc.start(t);
    osc.stop(t + 0.09);
  }

  /** Plunger release — spring boing. */
  plunger(): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(340, t);
    osc.frequency.exponentialRampToValueAtTime(90, t + 0.18);
    gain.gain.setValueAtTime(0.16, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.2);
    osc.connect(gain).connect(this.master!);
    osc.start(t);
    osc.stop(t + 0.22);
  }

  /** Nudge thud. */
  nudge(): void {
    const ctx = this.ensureCtx();
    if (!ctx) return;
    const t = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(90, t);
    osc.frequency.exponentialRampToValueAtTime(45, t + 0.12);
    gain.gain.setValueAtTime(0.2, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.14);
    osc.connect(gain).connect(this.master!);
    osc.start(t);
    osc.stop(t + 0.15);
  }

  // ── Internals ───────────────────────────────────────────────────────────

  private ensureCtx(): AudioContext | null {
    if (typeof window === 'undefined') return null;
    if (!this.ctx) {
      const Ctor =
        window.AudioContext ??
        (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
      if (!Ctor) return null;
      this.ctx = new Ctor();
      this.master = this.ctx.createGain();
      this.master.gain.value = this.muted ? 0 : 0.9;
      this.master.connect(this.ctx.destination);
    }
    return this.ctx;
  }

  /** Short white-noise buffer source. */
  private noiseSource(duration: number): AudioBufferSourceNode {
    const ctx = this.ctx!;
    const length = Math.max(1, Math.floor(ctx.sampleRate * duration));
    const buffer = ctx.createBuffer(1, length, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < length; i += 1) data[i] = Math.random() * 2 - 1;
    const source = ctx.createBufferSource();
    source.buffer = buffer;
    return source;
  }

  /** Crowd = filtered noise swell (cheer when winning, groan when losing). */
  private crowdSwell(duration: number, intensity: number): void {
    const ctx = this.ensureCtx();
    if (!ctx || !this.master) return;
    const t = ctx.currentTime;
    // Reuse a long noise source if the crowd is already roaring.
    if (this.crowdSource && this.crowdGain) {
      this.crowdGain.gain.cancelScheduledValues(t);
      this.crowdGain.gain.setTargetAtTime(0.14 * intensity, t, 0.1);
      this.crowdGain.gain.setTargetAtTime(0, t + duration, 0.4);
      return;
    }
    const source = this.noiseSource(Math.max(duration + 1, 3));
    const filter = ctx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.value = 900;
    filter.Q.value = 0.6;
    const gain = ctx.createGain();
    gain.gain.setValueAtTime(0.001, t);
    gain.gain.linearRampToValueAtTime(0.14 * intensity, t + 0.25);
    gain.gain.setValueAtTime(0.14 * intensity, t + duration * 0.6);
    gain.gain.setTargetAtTime(0, t + duration * 0.6, 0.4);
    source.loop = true;
    source.connect(filter).connect(gain).connect(this.master);
    source.start(t);
    source.stop(t + duration + 1.5);
    this.crowdSource = source;
    this.crowdGain = gain;
  }
}

/** Shared singleton (AudioKit survives scene restarts). */
export const audio = new AudioKit();
