// All sound is synthesised at load: no audio files. One-shots are pre-rendered into buffers;
// the score is a small generative loop that gets heavier as the horde grows.
import { FLAGS } from '../config.js';

const SR = 44100;
const noise = () => Math.random() * 2 - 1;

function render(seconds, fn) {
  const n = Math.floor(seconds * SR), d = new Float32Array(n);
  const st = { lp: 0, lp2: 0, ph: 0 };
  for (let i = 0; i < n; i++) d[i] = fn(i / SR, i / n, st);
  return d;
}
const lowpass = (st, v, k) => (st.lp += (v - st.lp) * k);
const sine = (st, f) => { st.ph += (f * Math.PI * 2) / SR; return Math.sin(st.ph); };

// Crack + body + tail. `f` thump pitch, `dark` lowpass amount, `len` seconds.
const gun = (len, f, dark, crack = 1) => render(len, (t, u, st) => {
  const body = sine(st, f * Math.exp(-t * 40) + f * 0.45) * Math.exp(-t * 26) * 0.75;
  const hiss = lowpass(st, noise(), dark) * Math.exp(-t * (11 / len) * 0.2) * Math.pow(1 - u, 2) * 0.8;
  const snap = noise() * Math.exp(-t * 300) * crack;
  return Math.tanh((body + hiss + snap) * 1.6);
});

const BANK = {
  pistol: () => gun(0.2, 165, 0.34),
  rifle: () => gun(0.17, 140, 0.4),
  smg: () => gun(0.11, 190, 0.5, 0.7),
  shotgun: () => gun(0.5, 78, 0.2, 1.3),
  sawed: () => gun(0.56, 64, 0.17, 1.4),
  minigun: () => gun(0.08, 190, 0.5, 0.6),
  gauss: () => render(0.55, (t, u, st) => (sine(st, 1900 * Math.exp(-t * 8) + 90) * 0.55 + noise() * Math.exp(-t * 60) * 0.7) * Math.pow(1 - u, 1.5)),
  flame: () => render(0.26, (t, u, st) => lowpass(st, noise(), 0.13) * Math.sin(u * Math.PI) * 1.1),
  plasma: () => render(0.3, (t, u, st) => (sine(st, 860 * Math.exp(-t * 11) + 120) + sine(st, 430 * Math.exp(-t * 9)) * 0.35) * Math.pow(1 - u, 2) * 0.62),
  cannon: () => render(0.9, (t, u, st) => Math.tanh((sine(st, 300 * Math.exp(-t * 5) + 46) + lowpass(st, noise(), 0.1) * 0.7) * Math.pow(1 - u, 1.6) * 1.6)),
  rocket: () => render(0.8, (t, u, st) => lowpass(st, noise(), 0.09 + 0.1 * (1 - u)) * Math.pow(1 - u, 1.1) * 1.3 + sine(st, 120 * Math.exp(-t * 5)) * Math.exp(-t * 9) * 0.5),
  ion: () => render(0.24, (t, u) => (Math.sign(Math.sin(t * 5200 * (1 - u * 0.6) + Math.sin(t * 420) * 7)) * 0.4 + noise() * 0.25) * Math.pow(1 - u, 2.4)),
  blade: () => render(0.3, (t, u, st) => (sine(st, 1300 + 900 * u) * 0.34 + noise() * 0.1) * Math.sin(u * Math.PI)),
  pulse: () => render(0.2, (t, u, st) => sine(st, 240 * (1 + u * 3.2)) * Math.pow(1 - u, 2) * 0.72),
  shrink: () => render(0.22, (t, u, st) => sine(st, 1500 * (1 - u * 0.75)) * (1 - u) * 0.4),
  explosion: () => render(1.5, (t, u, st) => {
    st.lp2 += (noise() - st.lp2) * (0.055 + 0.2 * Math.exp(-t * 7));
    return Math.tanh((st.lp2 * 4.2 + sine(st, 74 * Math.exp(-t * 2.8) + 26) * Math.exp(-t * 3.4) * 1.1 + noise() * Math.exp(-t * 80) * 0.6) * Math.pow(1 - u, 1.7) * 1.4);
  }),
  nuke: () => render(3.2, (t, u, st) => {
    st.lp2 += (noise() - st.lp2) * (0.03 + 0.1 * Math.exp(-t * 3));
    return Math.tanh((st.lp2 * 7 + sine(st, 46 * Math.exp(-t * 0.9) + 22) * 1.4) * Math.pow(1 - u, 1.4) * 1.6);
  }),
  hit: () => render(0.09, (t, u, st) => (lowpass(st, noise(), 0.3) * 1.2 + sine(st, 210 * (1 - u * 0.5)) * 0.6) * Math.pow(1 - u, 2)),
  splat: () => render(0.26, (t, u, st) => lowpass(st, noise(), 0.17 + 0.26 * Math.sin(t * 90) ** 2) * Math.pow(1 - u, 1.8) * 1.5),
  shatter: () => render(0.42, (t, u) => noise() * Math.exp(-t * 18) * (Math.sin(t * 7400) > 0 ? 0.9 : 0.25)),
  hurt: () => render(0.26, (t, u, st) => Math.tanh((sine(st, 170 - 90 * u) + lowpass(st, noise(), 0.3) * 0.7) * 1.8) * Math.pow(1 - u, 1.2) * 0.8),
  death: () => render(1.3, (t, u, st) => Math.tanh(sine(st, 130 * (1 - u * 0.75) + Math.sin(t * 34) * 12) * 1.6) * Math.pow(1 - u, 1.1) * 0.8),
  pickup: () => render(0.26, (t, u, st) => sine(st, t < 0.08 ? 780 : 1170) * Math.pow(1 - u, 1.5) * 0.42),
  levelup: () => render(0.8, (t, u, st) => { const f = [523, 659, 784, 1047][Math.min(3, Math.floor(t * 8))]; return (sine(st, f) * 0.34 + Math.sign(Math.sin(t * f * 6.283)) * 0.06) * Math.pow(1 - u, 1.2); }),
  perk: () => render(0.32, (t, u, st) => sine(st, 340 + 700 * u) * Math.pow(1 - u, 1.2) * 0.42),
  reload: () => render(0.2, (t, u) => noise() * (Math.exp(-t * 90) + Math.exp(-Math.abs(t - 0.1) * 130) * 0.8) * 0.75),
  click: () => render(0.05, (t) => noise() * Math.exp(-t * 240) * 0.75),
  casing: () => render(0.08, (t, u, st) => sine(st, 3900 + 2600 * Math.sin(t * 300)) * Math.pow(1 - u, 3)),
  freeze: () => render(1.1, (t, u) => noise() * Math.exp(-t * 3.4) * (Math.sin(t * (6000 + 4000 * u)) * 0.7) * 0.8),
  roar: () => render(1.5, (t, u, st) => Math.tanh((Math.sign(Math.sin(t * (92 - 34 * u) * 6.283 + Math.sin(t * 22) * 2.2)) * 0.6 + lowpass(st, noise(), 0.2) * 0.7) * 1.3) * Math.sin(u * Math.PI) ** 0.6 * 0.75),
  spit: () => render(0.24, (t, u, st) => lowpass(st, noise(), 0.3) * Math.sin(u * Math.PI) * 0.9 + sine(st, 340 * (1 + u)) * (1 - u) * 0.24),
  ui: () => render(0.05, (t, u, st) => sine(st, 1000) * (1 - u) * 0.25),
};

// Minimum spacing for sounds that long-tailed or rapid sources would otherwise pile up.
const GAP = { flame: 0.11, hit: 0.05, splat: 0.06, casing: 0.05, click: 0.03, explosion: 0.07 };

export class Audio {
  constructor() {
    this.ctx = null;
    this.buffers = {};
    this.volume = 0.8;
    this.music = 0.55;
    this.intensity = 0;
    this.lastPlayed = {};
    this.voices = 0;
  }

  // Must run from a user gesture.
  unlock() {
    if (this.ctx || FLAGS.mute) { this.ctx?.resume(); return; }
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    const ctx = this.ctx = new AC({ sampleRate: SR });
    this.master = ctx.createGain();
    this.master.gain.value = this.volume;
    const comp = ctx.createDynamicsCompressor();
    comp.threshold.value = -14; comp.ratio.value = 6;
    this.master.connect(comp).connect(ctx.destination);
    this.sfx = ctx.createGain();
    this.sfx.connect(this.master);
    for (const [name, make] of Object.entries(BANK)) {
      const data = make();
      const b = ctx.createBuffer(1, data.length, SR);
      b.copyToChannel(data, 0);
      this.buffers[name] = b;
    }
    this.startMusic();
  }

  setVolume(v) { this.volume = v; if (this.master) this.master.gain.value = v; }
  setMusic(v) { this.music = v; if (this.musicBus) this.musicBus.gain.value = v * 0.4; }
  duck(on) { if (this.ctx) this.sfx.gain.setTargetAtTime(on ? 0.25 : 1, this.ctx.currentTime, 0.04); }

  play(name, { vol = 1, rate = 1 } = {}) {
    const { ctx } = this;
    if (!ctx || !this.buffers[name] || this.silent) return;
    const now = ctx.currentTime;
    if (now - (this.lastPlayed[name] ?? 0) < (GAP[name] ?? 0.025) || this.voices > 40) return; // no phase-stacked peaks
    this.lastPlayed[name] = now;
    const src = ctx.createBufferSource();
    src.buffer = this.buffers[name];
    src.playbackRate.value = rate;
    const g = ctx.createGain();
    g.gain.value = vol * 0.62;
    src.connect(g).connect(this.sfx);
    this.voices++;
    src.onended = () => { this.voices--; };
    src.start();
  }

  setIntensity(v) {
    this.intensity = v;
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    this.droneFilter.frequency.setTargetAtTime(170 + v * 620, t, 0.6);
    this.droneGain.gain.setTargetAtTime(0.16 + v * 0.16, t, 0.6);
  }

  startMusic() {
    const { ctx } = this;
    const bus = this.musicBus = ctx.createGain();
    bus.gain.value = this.music * 0.4;
    bus.connect(this.master);
    const f = this.droneFilter = ctx.createBiquadFilter();
    f.type = 'lowpass'; f.frequency.value = 200; f.Q.value = 4;
    const g = this.droneGain = ctx.createGain();
    g.gain.value = 0.16;
    f.connect(g).connect(bus);
    for (const [freq, type] of [[36.7, 'sawtooth'], [36.95, 'sawtooth'], [55.1, 'square']]) {
      const o = ctx.createOscillator();
      o.type = type; o.frequency.value = freq;
      o.connect(f); o.start();
    }
    // Sequencer: kick and a slow minor-second bass figure, scheduled ahead of the audio clock.
    const seq = [36.7, 0, 36.7, 0, 38.9, 0, 36.7, 0, 36.7, 0, 43.65, 0, 41.2, 0, 38.9, 0];
    const kick = render(0.3, (t, u, st) => sine(st, 110 * Math.exp(-t * 26) + 42) * Math.pow(1 - u, 1.6));
    const kb = ctx.createBuffer(1, kick.length, SR);
    kb.copyToChannel(kick, 0);
    let step = 0, next = ctx.currentTime + 0.1;
    const stepLen = 60 / 112 / 2;
    const tick = () => {
      while (next < ctx.currentTime + 0.25) {
        const heavy = this.intensity > 0.2;
        if (step % 8 === 0 || (heavy && step % 8 === 3) || (this.intensity > 0.6 && step % 4 === 2)) {
          const s = ctx.createBufferSource(); s.buffer = kb;
          const v = ctx.createGain(); v.gain.value = 0.32 + this.intensity * 0.42;
          s.connect(v).connect(bus); s.start(next);
        }
        const n = seq[step % 16];
        if (n && this.intensity > 0.06) {
          const o = ctx.createOscillator(); o.type = 'sawtooth'; o.frequency.value = n * 2;
          const fl = ctx.createBiquadFilter(); fl.type = 'lowpass'; fl.frequency.value = 260 + this.intensity * 520;
          const v = ctx.createGain();
          v.gain.setValueAtTime(0.28, next);
          v.gain.exponentialRampToValueAtTime(0.001, next + stepLen * 1.6);
          o.connect(fl).connect(v).connect(bus);
          o.start(next); o.stop(next + stepLen * 1.7);
        }
        step++; next += stepLen;
      }
    };
    this.musicTimer = setInterval(tick, 60);
  }
}
