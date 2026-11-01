/* Tiny procedural sound effects via WebAudio — no audio assets needed.
   Fails soft only in the sense that the game remains playable if WebAudio
   is unavailable; it never throws into the game loop. */
'use strict';

class GameAudio {
  constructor() {
    this.ctx = null;
    this.master = null;
    this.enabled = true;
  }

  /* Must be called from a user gesture at least once. */
  ensure() {
    if (!this.enabled) return;
    if (!this.ctx) {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (!AC) { this.enabled = false; return; }
      this.ctx = new AC();
      this.master = this.ctx.createGain();
      this.master.gain.value = 0.22;
      this.master.connect(this.ctx.destination);
    }
    if (this.ctx.state === 'suspended') this.ctx.resume();
  }

  tone(f0, f1, dur, type, vol) {
    if (!this.enabled) return;
    this.ensure();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = type || 'sine';
    o.frequency.setValueAtTime(Math.max(f0, 1), t);
    o.frequency.exponentialRampToValueAtTime(Math.max(f1, 1), t + dur);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(vol || 0.6, t + 0.012);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(g);
    g.connect(this.master);
    o.start(t);
    o.stop(t + dur + 0.03);
  }

  noise(dur, vol, cutoff) {
    if (!this.enabled) return;
    this.ensure();
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    const n = Math.floor(this.ctx.sampleRate * dur);
    const buf = this.ctx.createBuffer(1, n, this.ctx.sampleRate);
    const data = buf.getChannelData(0);
    for (let i = 0; i < n; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / n);
    const src = this.ctx.createBufferSource();
    src.buffer = buf;
    const filt = this.ctx.createBiquadFilter();
    filt.type = 'lowpass';
    filt.frequency.value = cutoff || 900;
    const g = this.ctx.createGain();
    g.gain.setValueAtTime(vol || 0.4, t);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    src.connect(filt);
    filt.connect(g);
    g.connect(this.master);
    src.start(t);
  }

  jump()      { this.tone(280, 560, 0.14, 'square', 0.35); }
  land()      { this.tone(170, 75, 0.1, 'sine', 0.6); }
  dive()      { this.noise(0.28, 0.3, 1400); }
  checkpoint() {
    this.tone(523, 523, 0.1, 'triangle', 0.6);
    setTimeout(() => this.tone(784, 784, 0.18, 'triangle', 0.6), 90);
  }
  bumper()    { this.tone(180, 720, 0.16, 'sawtooth', 0.4); }
  knock()     { this.tone(210, 60, 0.22, 'square', 0.5); this.noise(0.15, 0.25, 500); }
  respawn()   { this.tone(600, 300, 0.2, 'sine', 0.45); }
  finish() {
    [523, 659, 784, 1046].forEach((f, i) =>
      setTimeout(() => this.tone(f, f, 0.2, 'triangle', 0.6), i * 110));
  }
}
