/* ==========================================================================
   30 NOCHES - audio.js
   Sonido procedural con Web Audio API (sin ficheros externos).
   La estructura permite sustituir cada efecto por un fichero propio
   mas adelante: basta con cambiar la funcion synth correspondiente.
   ========================================================================== */
window.TN = window.TN || {};

TN.Audio = (function () {
  class AudioSystem {
    constructor() {
      this.ctx = null;
      this.master = null;
      this.volume = 0.6;
      this.muted = false;
      this.ready = false;
      this._noiseBuf = null;
    }

    /* Debe llamarse tras una interaccion del usuario (politica del navegador). */
    init() {
      if (this.ready) {
        if (this.ctx && this.ctx.state === 'suspended') this.ctx.resume();
        return;
      }
      const AC = window.AudioContext || window.webkitAudioContext;
      if (!AC) return;
      try {
        this.ctx = new AC();
        this.master = this.ctx.createGain();
        this.master.gain.value = this.muted ? 0 : this.volume;
        this.master.connect(this.ctx.destination);
        this._buildNoise();
        this.ready = true;
      } catch (e) {
        console.warn('[TN] audio no disponible', e);
        this.ready = false;
      }
    }

    _buildNoise() {
      const len = Math.floor(this.ctx.sampleRate * 0.6);
      const buf = this.ctx.createBuffer(1, len, this.ctx.sampleRate);
      const data = buf.getChannelData(0);
      for (let i = 0; i < len; i++) data[i] = Math.random() * 2 - 1;
      this._noiseBuf = buf;
    }

    setVolume(v) {
      this.volume = U_clamp(v);
      if (this.master) this.master.gain.value = this.muted ? 0 : this.volume;
    }

    setMuted(m) {
      this.muted = !!m;
      if (this.master) this.master.gain.value = this.muted ? 0 : this.volume;
    }

    suspend() { if (this.ctx && this.ctx.state === 'running') this.ctx.suspend(); }
    resume() { if (this.ctx && this.ctx.state === 'suspended') this.ctx.resume(); }

    _now() { return this.ctx.currentTime; }

    /* --- primitivas ----------------------------------------------------- */
    _tone(freq, dur, type, vol, slideTo) {
      if (!this.ready || this.muted) return;
      const t = this._now();
      const osc = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      osc.type = type || 'square';
      osc.frequency.setValueAtTime(freq, t);
      if (slideTo) osc.frequency.exponentialRampToValueAtTime(Math.max(20, slideTo), t + dur);
      g.gain.setValueAtTime(0.0001, t);
      g.gain.exponentialRampToValueAtTime(Math.max(0.0002, vol), t + 0.008);
      g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
      osc.connect(g); g.connect(this.master);
      osc.start(t); osc.stop(t + dur + 0.02);
    }

    _noise(dur, vol, filterFreq, q) {
      if (!this.ready || this.muted) return;
      const t = this._now();
      const src = this.ctx.createBufferSource();
      src.buffer = this._noiseBuf;
      const filt = this.ctx.createBiquadFilter();
      filt.type = 'bandpass';
      filt.frequency.value = filterFreq || 900;
      filt.Q.value = q || 1;
      const g = this.ctx.createGain();
      g.gain.setValueAtTime(vol, t);
      g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
      src.connect(filt); filt.connect(g); g.connect(this.master);
      src.start(t); src.stop(t + dur + 0.02);
    }

    /* --- efectos del juego ---------------------------------------------- */
    play(name, opt) {
      if (!this.ready || this.muted) return;
      switch (name) {
        case 'swing': this._noise(0.14, 0.12, 1400, 0.8); break;
        case 'hit': this._tone(180, 0.12, 'square', 0.18, 90); this._noise(0.1, 0.16, 700, 1.2); break;
        case 'crit': this._tone(320, 0.16, 'sawtooth', 0.2, 120); break;
        case 'shoot': this._tone(420, 0.1, 'square', 0.16, 120); this._noise(0.08, 0.12, 1800, 0.7); break;
        case 'arrow': this._noise(0.12, 0.1, 2600, 2); break;
        case 'explode': this._noise(0.55, 0.32, 320, 0.6); this._tone(90, 0.5, 'sine', 0.22, 40); break;
        case 'hurt': this._tone(220, 0.22, 'sawtooth', 0.22, 70); this._noise(0.18, 0.18, 500, 1); break;
        case 'pickup': this._tone(660, 0.09, 'triangle', 0.16); setTimeout(() => this._tone(880, 0.09, 'triangle', 0.14), 70); break;
        case 'craft': this._tone(330, 0.1, 'square', 0.14); setTimeout(() => this._tone(495, 0.14, 'square', 0.13), 90); break;
        case 'build': this._tone(160, 0.18, 'square', 0.16, 90); this._noise(0.2, 0.14, 800, 0.9); break;
        case 'kill': this._noise(0.3, 0.22, 260, 0.7); this._tone(120, 0.3, 'sawtooth', 0.16, 45); break;
        case 'enemyDie': this._noise(0.35, 0.2, 200, 0.6); break;
        case 'nightStart': this._tone(110, 1.2, 'sawtooth', 0.2, 70); this._noise(1.0, 0.12, 200, 0.5); break;
        case 'nightEnd': this._tone(330, 0.5, 'triangle', 0.16, 520); setTimeout(() => this._tone(440, 0.6, 'triangle', 0.14), 220); break;
        case 'bossWarn': this._tone(70, 1.6, 'sawtooth', 0.26, 45); this._noise(1.4, 0.16, 160, 0.5); break;
        case 'upgrade': [523, 659, 784, 1046].forEach((f, i) => setTimeout(() => this._tone(f, 0.16, 'triangle', 0.16), i * 110)); break;
        case 'victory': [523, 659, 784, 1046, 1318].forEach((f, i) => setTimeout(() => this._tone(f, 0.5, 'triangle', 0.2), i * 200)); break;
        case 'defeat': [330, 262, 196, 131].forEach((f, i) => setTimeout(() => this._tone(f, 0.6, 'sawtooth', 0.2), i * 260)); break;
        case 'ui': this._tone(520, 0.05, 'square', 0.08); break;
        case 'error': this._tone(180, 0.16, 'square', 0.14, 120); break;
        case 'reload': this._noise(0.1, 0.1, 600, 1.4); this._tone(240, 0.08, 'square', 0.1); break;
        case 'trap': this._noise(0.14, 0.16, 2200, 3); break;
        default: break;
      }
    }
  }

  function U_clamp(v) { return v < 0 ? 0 : (v > 1 ? 1 : v); }

  return AudioSystem;
})();
