import { eventBus, Events } from '../core/EventBus.js';
import { gameState } from '../core/GameState.js';
import { perf } from '../core/Perf.js';

const VOL_KEY = 'cinder.vol';

function loadVol() {
  try {
    const v = parseFloat(localStorage.getItem(VOL_KEY));
    if (Number.isFinite(v)) return Math.max(0, Math.min(1, v));
  } catch { /* storage unavailable */ }
  return 1;
}

export class AudioEngine {
  constructor() {
    this.ctx = null;
    this._hooked = false;
    this._heartT = 0;
    this._volume = loadVol();
    this._nVoices = [];
    this._nI = 0;
    eventBus.on(Events.WEAPON_FIRE, (d) => this.shot(d?.id || 'rifle'));
    eventBus.on(Events.WEAPON_RELOAD, () => this.click(180, 0.08));
    eventBus.on(Events.WEAPON_EMPTY, () => this.click(90, 0.05));
    eventBus.on(Events.WEAPON_SWITCH, () => this.click(320, 0.05));
    eventBus.on(Events.PICKUP, () => this.click(520, 0.09));
    eventBus.on(Events.ENEMY_HIT, (d) => {
      this.thud(d?.killed);
      // Headshot ding: bright click layered over the thud — unmistakable.
      if (d?.headshot) this.click(1800, 0.07);
    });
    eventBus.on(Events.PLAYER_HIT, () => this.hurt());
    eventBus.on(Events.GAME_START, () => this.resume());
  }

  resume() {
    if (!this.ctx) {
      this.ctx = new (window.AudioContext || window.webkitAudioContext)();
      this._buildShared();
    }
    if (this.ctx.state === 'suspended') this.ctx.resume();
  }

  /* Shared DSP built once: a noise source buffer, a 0.4 s decaying-noise
   * impulse response (the "outdoor tail" that sells a gunshot), and a
   * master compressor so the layered shots can run hot without clipping. */
  _buildShared() {
    const ctx = this.ctx;
    this.master = ctx.createDynamicsCompressor();
    this.master.threshold.value = -12;
    this.master.ratio.value = 6;
    this.masterGain = ctx.createGain();
    this.masterGain.gain.value = this._volume;
    this.master.connect(this.masterGain);
    this.masterGain.connect(ctx.destination);
    const n = ctx.sampleRate | 0;
    this.noiseBuf = ctx.createBuffer(1, n, ctx.sampleRate);
    const nd = this.noiseBuf.getChannelData(0);
    for (let i = 0; i < n; i++) nd[i] = Math.random() * 2 - 1;
    const irN = (0.4 * ctx.sampleRate) | 0;
    const ir = ctx.createBuffer(2, irN, ctx.sampleRate);
    for (let c = 0; c < 2; c++) {
      const ch = ir.getChannelData(c);
      for (let i = 0; i < irN; i++) ch[i] = (Math.random() * 2 - 1) * (1 - i / irN) ** 2.4;
    }
    this.verb = ctx.createConvolver();
    this.verb.buffer = ir;
    this.verbGain = ctx.createGain();
    this.verbGain.gain.value = 0.9;
    this.verb.connect(this.verbGain);
    this.verbGain.connect(this.master);
  }

  _out() {
    if (!this.ctx || gameState.game.isMuted) return null;
    return this.master || this.ctx.destination;
  }

  /* Nodes stay in the audio graph until disconnect — without onended
   * teardown a 720-rpm dump leaks ~10 AudioNodes/shot (~6k/min). */
  _drop(nodes) {
    for (const n of nodes) {
      try { n.disconnect(); } catch { /* already dropped */ }
    }
  }

  /* Looping noise voices — BufferSource can only start once, so we keep
   * a small pool running silent and just retrigger filter/gain envelopes.
   * A 720-rpm dump used to build ~10 nodes/shot. */
  _noiseVoice() {
    const ctx = this.ctx;
    let v = this._nVoices.find((x) => x.readyAt <= ctx.currentTime);
    if (!v) {
      if (this._nVoices.length >= 10) {
        v = this._nVoices[this._nI++ % 10];
      } else {
        const src = ctx.createBufferSource();
        src.buffer = this.noiseBuf;
        src.loop = true;
        const filt = ctx.createBiquadFilter();
        const g = ctx.createGain();
        g.gain.value = 0.001;
        src.connect(filt); filt.connect(g); g.connect(this.master);
        const send = ctx.createGain();
        send.gain.value = 0;
        g.connect(send); send.connect(this.verb);
        src.start();
        v = { src, filt, g, send, readyAt: 0 };
        this._nVoices.push(v);
      }
    }
    return v;
  }

  /* Filtered noise burst with a frequency sweep — the body of every shot.
   * `send` routes a copy into the convolution tail. */
  _noise(f0, f1, dur, gain, t, { type = 'bandpass', q = 0.8, send = 0 } = {}) {
    const dest = this._out();
    if (!dest || !this.noiseBuf) return;
    const v = this._noiseVoice();
    v.filt.type = type;
    v.filt.Q.value = q;
    v.filt.frequency.cancelScheduledValues(t);
    v.filt.frequency.setValueAtTime(f0, t);
    v.filt.frequency.exponentialRampToValueAtTime(Math.max(1, f1), t + dur);
    v.g.gain.cancelScheduledValues(t);
    v.g.gain.setValueAtTime(gain, t);
    v.g.gain.exponentialRampToValueAtTime(0.001, t + dur);
    if (v.send) v.send.gain.value = send > 0 ? send : 0;
    v.readyAt = t + dur + 0.03;
  }

  /* Layered report (autopsy fix 7, kimi's recipe): (1) bandpass noise body
   * sweeping down — the "boom", wet into the reverb tail; (2) a highpass
   * noise crack — the transient snap; (3) a low triangle thump — the chest
   * hit. The old quiet lowpassed squares read "pew toy". */
  shot(id = 'rifle') {
    perf.mark('audio');
    const dest = this._out();
    if (!dest) { perf.done('audio'); return; }
    const t = this.ctx.currentTime;
    if (id === 'sniper') {
      this._noise(2200, 200, 0.18, 0.95, t, { send: 1.0 });
      this._noise(4200, 4200, 0.03, 0.5, t, { type: 'highpass' });
      this._osc('triangle', 100, 28, 0.30, 0.7, 500, t);
      this.click(900, 0.06);
      perf.done('audio');
      return;
    }
    if (id === 'shotgun') {
      this._noise(1600, 180, 0.20, 0.95, t, { send: 0.9 });
      this._noise(3800, 3800, 0.03, 0.45, t, { type: 'highpass' });
      this._osc('triangle', 130, 38, 0.18, 0.6, 480, t);
      this._osc('triangle', 92, 30, 0.16, 0.5, 380, t + 0.008);
      perf.done('audio');
      return;
    }
    if (id === 'pistol') {
      this._noise(3000, 500, 0.09, 0.6, t, { send: 0.7 });
      this._noise(4400, 4400, 0.02, 0.4, t, { type: 'highpass' });
      this._osc('triangle', 170, 60, 0.07, 0.35, 620, t);
      perf.done('audio');
      return;
    }
    this._noise(2600, 350, 0.12, 0.85, t, { send: 0.9 });
    this._noise(4000, 4000, 0.025, 0.5, t, { type: 'highpass' });
    this._osc('triangle', 150, 42, 0.10, 0.5, 560, t);
    perf.done('audio');
  }

  /* Soft lowpassed noise tap — driven off the player bob cycle (Game.step). */
  footstep(vol = 0.8) {
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    this._noise(620 + Math.random() * 240, 140, 0.075, 0.055 * vol, t, { type: 'lowpass', q: 0.6 });
  }

  _osc(type, f0, f1, dur, gain, lp, t) {
    const dest = this._out();
    if (!dest) return;
    const osc = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    const filt = this.ctx.createBiquadFilter();
    osc.type = type;
    osc.frequency.setValueAtTime(f0, t);
    osc.frequency.exponentialRampToValueAtTime(Math.max(1, f1), t + dur);
    filt.type = 'lowpass';
    filt.frequency.value = lp;
    g.gain.setValueAtTime(gain, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + dur + 0.05);
    osc.connect(filt); filt.connect(g); g.connect(dest);
    osc.onended = () => this._drop([osc, filt, g]);
    osc.start(t); osc.stop(t + dur + 0.06);
  }

  click(freq, dur) {
    const dest = this._out();
    if (!dest) return;
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(0.08, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + dur);
    osc.connect(gain); gain.connect(dest);
    osc.onended = () => this._drop([osc, gain]);
    osc.start(t); osc.stop(t + dur);
  }

  thud(deep = false) {
    const dest = this._out();
    if (!dest) return;
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    // Kill confirm rides a slightly deeper thud.
    osc.frequency.setValueAtTime(deep ? 70 : 90, t);
    osc.frequency.exponentialRampToValueAtTime(deep ? 32 : 40, t + 0.08);
    gain.gain.setValueAtTime(deep ? 0.15 : 0.12, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.1);
    osc.connect(gain); gain.connect(dest);
    osc.onended = () => this._drop([osc, gain]);
    osc.start(t); osc.stop(t + 0.1);
  }

  hurt() {
    const dest = this._out();
    if (!dest) return;
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.value = 70;
    gain.gain.setValueAtTime(0.07, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.16);
    osc.connect(gain); gain.connect(dest);
    osc.onended = () => this._drop([osc, gain]);
    osc.start(t); osc.stop(t + 0.16);
  }

  /* Low-health heartbeat: two 55 Hz sine thumps 0.18 s apart, repeating at
   * 1.2 Hz while health < 35; stops on heal/death (plan §6). */
  update(dt) {
    const low = gameState.player.alive && gameState.player.health < 35
      && gameState.game.isPlaying;
    if (!low) { this._heartT = 0; return; }
    this._heartT -= dt;
    if (this._heartT > 0) return;
    this._heartT = 1 / 1.2;
    const dest = this._out();
    if (!dest) return;
    for (const off of [0, 0.18]) {
      const t = this.ctx.currentTime + off;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = 55;
      gain.gain.setValueAtTime(off ? 0.07 : 0.09, t);
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.08);
      osc.connect(gain); gain.connect(dest);
      osc.onended = () => this._drop([osc, gain]);
      osc.start(t); osc.stop(t + 0.09);
    }
  }

  getVolume() { return this._volume; }

  setVolume(v) {
    this._volume = Math.max(0, Math.min(1, +v || 0));
    try { localStorage.setItem(VOL_KEY, String(this._volume)); } catch { /* ignore */ }
    if (this.masterGain) this.masterGain.gain.value = this._volume;
  }

  setPaused() {}
  dispose() { this.ctx?.close(); }
}
