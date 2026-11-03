// WebAudio: synthesized bells, boing, low tone, and a generative ambient
// score that layers one instrument per unlocked chime. No audio assets.
// The pure `layerPlan` is unit-tested without an AudioContext.

export const MUSIC_LAYERS = ['pad', 'pluck', 'bass', 'bells', 'flute', 'shimmer'];

// Which ambient layers are active for a given number of unlocked chimes.
// 0 unlocked -> pad only; each unlocked chime adds one layer.
export function layerPlan(unlocked) {
  const count = Math.min(MUSIC_LAYERS.length, 1 + Math.max(0, Math.floor(unlocked)));
  return MUSIC_LAYERS.slice(0, count);
}

const SCALE = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]; // C pentatonic

export class AudioEngine {
  constructor() {
    this.ctx = null;
    this.master = null;
    this.musicGain = null;
    this.activeLayers = new Set();
    this._timers = [];
    this._padNodes = [];
  }

  // Must be called from a user gesture.
  ensure() {
    if (this.ctx) {
      if (this.ctx.state === 'suspended') this.ctx.resume();
      return this.ctx;
    }
    const Ctor = typeof AudioContext !== 'undefined' ? AudioContext : webkitAudioContext;
    this.ctx = new Ctor();
    this.master = this.ctx.createGain();
    this.master.gain.value = 0.55;
    this.master.connect(this.ctx.destination);
    this.musicGain = this.ctx.createGain();
    this.musicGain.gain.value = 0.5;
    this.musicGain.connect(this.master);
    return this.ctx;
  }

  get ready() {
    return Boolean(this.ctx);
  }

  // Synthesized bell: sine + harmonics with exponential decay.
  bell(freq, when = 0, dest = null, volume = 0.5) {
    if (!this.ctx) return;
    const t0 = this.ctx.currentTime + when;
    const out = dest || this.master;
    const partials = [
      { ratio: 1, gain: 1 },
      { ratio: 2.02, gain: 0.45 },
      { ratio: 2.94, gain: 0.22 },
      { ratio: 4.2, gain: 0.08 }
    ];
    for (const p of partials) {
      const osc = this.ctx.createOscillator();
      osc.type = 'sine';
      osc.frequency.value = freq * p.ratio;
      const g = this.ctx.createGain();
      g.gain.setValueAtTime(0, t0);
      g.gain.linearRampToValueAtTime(volume * p.gain, t0 + 0.008);
      g.gain.exponentialRampToValueAtTime(0.0004, t0 + 2.4);
      osc.connect(g).connect(out);
      osc.start(t0);
      osc.stop(t0 + 2.5);
    }
  }

  boing() {
    if (!this.ctx) return;
    const t0 = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(160, t0);
    osc.frequency.exponentialRampToValueAtTime(620, t0 + 0.16);
    osc.frequency.exponentialRampToValueAtTime(280, t0 + 0.34);
    const g = this.ctx.createGain();
    g.gain.setValueAtTime(0.4, t0);
    g.gain.exponentialRampToValueAtTime(0.001, t0 + 0.4);
    osc.connect(g).connect(this.master);
    osc.start(t0);
    osc.stop(t0 + 0.45);
  }

  lowTone() {
    if (!this.ctx) return;
    const t0 = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(174, t0);
    osc.frequency.exponentialRampToValueAtTime(120, t0 + 0.5);
    const g = this.ctx.createGain();
    g.gain.setValueAtTime(0.001, t0);
    g.gain.linearRampToValueAtTime(0.28, t0 + 0.03);
    g.gain.exponentialRampToValueAtTime(0.001, t0 + 0.9);
    osc.connect(g).connect(this.master);
    osc.start(t0);
    osc.stop(t0 + 1);
  }

  portalWhoosh() {
    if (!this.ctx) return;
    const t0 = this.ctx.currentTime;
    for (let i = 0; i < 6; i++) {
      this.bell(SCALE[i % SCALE.length] * 2, i * 0.07, this.master, 0.16);
    }
    const osc = this.ctx.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(90, t0);
    osc.frequency.exponentialRampToValueAtTime(700, t0 + 0.7);
    const g = this.ctx.createGain();
    g.gain.setValueAtTime(0.18, t0);
    g.gain.exponentialRampToValueAtTime(0.001, t0 + 0.8);
    osc.connect(g).connect(this.master);
    osc.start(t0);
    osc.stop(t0 + 0.85);
  }

  // ----- ambient generative layers -----

  startAmbient() {
    if (!this.ctx) return;
    this._startLayer('pad');
  }

  setUnlocked(n) {
    if (!this.ctx) return;
    for (const layer of layerPlan(n)) this._startLayer(layer);
  }

  _startLayer(name) {
    if (!this.ctx || this.activeLayers.has(name)) return;
    this.activeLayers.add(name);
    switch (name) {
      case 'pad': this._startPad(); break;
      case 'pluck': this._startPluck(); break;
      case 'bass': this._startBass(); break;
      case 'bells': this._startBells(); break;
      case 'flute': this._startFlute(); break;
      case 'shimmer': this._startShimmer(); break;
    }
  }

  _startPad() {
    const t0 = this.ctx.currentTime;
    const filter = this.ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.value = 620;
    filter.Q.value = 0.6;
    const g = this.ctx.createGain();
    g.gain.setValueAtTime(0, t0);
    g.gain.linearRampToValueAtTime(0.05, t0 + 4);
    filter.connect(g).connect(this.musicGain);
    const chord = [130.81, 196.0, 261.63, 329.63]; // C3 G3 C4 E4
    for (const f of chord) {
      for (const detune of [-4, 3]) {
        const osc = this.ctx.createOscillator();
        osc.type = 'sawtooth';
        osc.frequency.value = f;
        osc.detune.value = detune;
        osc.connect(filter);
        osc.start(t0);
        this._padNodes.push(osc);
      }
    }
    const lfo = this.ctx.createOscillator();
    lfo.frequency.value = 0.07;
    const lfoGain = this.ctx.createGain();
    lfoGain.gain.value = 240;
    lfo.connect(lfoGain).connect(filter.frequency);
    lfo.start(t0);
    this._padNodes.push(lfo);
  }

  _every(ms, fn) {
    const id = setInterval(fn, ms);
    this._timers.push(id);
    fn();
  }

  _pluck(freq, when = 0, volume = 0.12) {
    const t0 = this.ctx.currentTime + when;
    const osc = this.ctx.createOscillator();
    osc.type = 'triangle';
    osc.frequency.value = freq;
    const g = this.ctx.createGain();
    g.gain.setValueAtTime(0, t0);
    g.gain.linearRampToValueAtTime(volume, t0 + 0.012);
    g.gain.exponentialRampToValueAtTime(0.0005, t0 + 0.9);
    osc.connect(g).connect(this.musicGain);
    osc.start(t0);
    osc.stop(t0 + 1);
  }

  _startPluck() {
    let step = 0;
    this._every(620, () => {
      if (!this.ctx || this.ctx.state !== 'running') return;
      const seq = [0, 2, 4, 3, 1, 2, 4, 5];
      this._pluck(SCALE[seq[step % seq.length]] * 2, 0, 0.075);
      step += 1;
    });
  }

  _startBass() {
    let step = 0;
    this._every(2480, () => {
      if (!this.ctx || this.ctx.state !== 'running') return;
      const roots = [65.41, 98.0, 87.31, 98.0]; // C2 G2 F2 G2
      const t0 = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      osc.type = 'sine';
      osc.frequency.value = roots[step % roots.length];
      const g = this.ctx.createGain();
      g.gain.setValueAtTime(0, t0);
      g.gain.linearRampToValueAtTime(0.16, t0 + 0.25);
      g.gain.exponentialRampToValueAtTime(0.001, t0 + 2.3);
      osc.connect(g).connect(this.musicGain);
      osc.start(t0);
      osc.stop(t0 + 2.4);
      step += 1;
    });
  }

  _startBells() {
    let step = 0;
    this._every(1980, () => {
      if (!this.ctx || this.ctx.state !== 'running') return;
      const seq = [4, 2, 0, 2, 3, 1, 2, 0];
      this.bell(SCALE[seq[step % seq.length]], 0, this.musicGain, 0.06);
      step += 1;
    });
  }

  _startFlute() {
    let step = 0;
    this._every(3100, () => {
      if (!this.ctx || this.ctx.state !== 'running') return;
      const seq = [2, 3, 4, 3, 5, 4, 3, 1];
      const t0 = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      osc.type = 'sine';
      osc.frequency.value = SCALE[seq[step % seq.length]] * 2;
      const vib = this.ctx.createOscillator();
      vib.frequency.value = 5.2;
      const vibGain = this.ctx.createGain();
      vibGain.gain.value = 6;
      vib.connect(vibGain).connect(osc.frequency);
      const g = this.ctx.createGain();
      g.gain.setValueAtTime(0, t0);
      g.gain.linearRampToValueAtTime(0.055, t0 + 0.4);
      g.gain.linearRampToValueAtTime(0.0001, t0 + 2.8);
      osc.connect(g).connect(this.musicGain);
      osc.start(t0);
      vib.start(t0);
      osc.stop(t0 + 2.9);
      vib.stop(t0 + 2.9);
      step += 1;
    });
  }

  _startShimmer() {
    this._every(4400, () => {
      if (!this.ctx || this.ctx.state !== 'running') return;
      for (let i = 0; i < 5; i++) {
        this.bell(SCALE[(i * 2 + 1) % SCALE.length] * 4, i * 0.16, this.musicGain, 0.02);
      }
    });
  }
}
