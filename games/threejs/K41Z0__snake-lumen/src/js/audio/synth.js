window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  function midi(n) { return 440 * Math.pow(2, (n - 69) / 12); }

  // WebAudio graph: sources -> sfx / music buses -> compressor -> speakers.
  // Nothing is created until the first user gesture, as browsers require.
  function Synth() {
    this.ctx = null;
    this.musicVol = 0.55;
    this.sfxVol = 0.8;
    this.muted = false;
    this.noiseBuf = null;
    this.lastTurn = 0;
  }

  Synth.prototype.ensure = function () {
    if (!this.ctx) {
      var Ctor = window.AudioContext || window.webkitAudioContext;
      if (!Ctor) return null;
      try { this.ctx = new Ctor(); } catch (e) { return null; }
      var c = this.ctx;
      this.comp = c.createDynamicsCompressor();
      this.comp.threshold.value = -14;
      this.comp.ratio.value = 4;
      this.master = c.createGain();
      this.music = c.createGain();
      this.sfx = c.createGain();
      this.music.connect(this.master);
      this.sfx.connect(this.master);
      this.master.connect(this.comp);
      this.comp.connect(c.destination);
      var len = c.sampleRate;
      this.noiseBuf = c.createBuffer(1, len, c.sampleRate);
      var d = this.noiseBuf.getChannelData(0);
      for (var i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
      this.apply();
    }
    if (this.ctx.state === "suspended") { try { this.ctx.resume(); } catch (e) { /* ignore */ } }
    return this.ctx;
  };

  Synth.prototype.apply = function () {
    if (!this.ctx) return;
    var now = this.ctx.currentTime;
    this.master.gain.setTargetAtTime(this.muted ? 0 : 1, now, 0.03);
    this.music.gain.setTargetAtTime(this.musicVol * 0.5, now, 0.05);
    this.sfx.gain.setTargetAtTime(this.sfxVol * 0.9, now, 0.03);
  };

  Synth.prototype.setVolumes = function (music, sfx, muted) {
    this.musicVol = music;
    this.sfxVol = sfx;
    this.muted = !!muted;
    this.apply();
  };

  Synth.prototype.now = function () {
    return this.ctx ? this.ctx.currentTime : 0;
  };

  // One enveloped oscillator. o: { type, gain, attack, slide (to freq), when, dest, filter, detune }
  Synth.prototype.tone = function (freq, dur, o) {
    var c = this.ensure();
    if (!c) return;
    o = o || {};
    var t0 = o.when || c.currentTime;
    var osc = c.createOscillator();
    var g = c.createGain();
    osc.type = o.type || "triangle";
    osc.frequency.setValueAtTime(freq, t0);
    if (o.detune) osc.detune.value = o.detune;
    if (o.slide) osc.frequency.exponentialRampToValueAtTime(Math.max(20, o.slide), t0 + dur);
    var peak = o.gain === undefined ? 0.2 : o.gain;
    var att = o.attack || 0.005;
    g.gain.setValueAtTime(0.0001, t0);
    g.gain.exponentialRampToValueAtTime(Math.max(0.0002, peak), t0 + att);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    var node = osc;
    if (o.filter) {
      var f = c.createBiquadFilter();
      f.type = "lowpass";
      f.frequency.setValueAtTime(o.filter, t0);
      if (o.filterTo) f.frequency.exponentialRampToValueAtTime(o.filterTo, t0 + dur);
      f.Q.value = o.q || 1;
      osc.connect(f);
      node = f;
    }
    node.connect(g);
    g.connect(o.dest || this.sfx);
    osc.start(t0);
    osc.stop(t0 + dur + 0.05);
  };

  Synth.prototype.noise = function (dur, o) {
    var c = this.ensure();
    if (!c) return;
    o = o || {};
    var t0 = o.when || c.currentTime;
    var src = c.createBufferSource();
    src.buffer = this.noiseBuf;
    var f = c.createBiquadFilter();
    f.type = o.ftype || "bandpass";
    f.frequency.setValueAtTime(o.freq || 2000, t0);
    if (o.freqTo) f.frequency.exponentialRampToValueAtTime(o.freqTo, t0 + dur);
    f.Q.value = o.q || 0.8;
    var g = c.createGain();
    g.gain.setValueAtTime(o.gain === undefined ? 0.15 : o.gain, t0);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    src.connect(f);
    f.connect(g);
    g.connect(o.dest || this.sfx);
    src.start(t0, Math.random() * 0.5);
    src.stop(t0 + dur + 0.05);
  };

  // ---------- sound effects ----------
  var S = Synth.prototype;

  S.eat = function (combo) {
    var base = 72 + Math.min(12, (combo || 1) - 1);
    var t = this.now();
    this.tone(midi(base), 0.12, { type: "triangle", gain: 0.22, when: t });
    this.tone(midi(base + 7), 0.14, { type: "triangle", gain: 0.18, when: t + 0.06 });
    this.tone(midi(base + 12), 0.1, { type: "sine", gain: 0.08, when: t + 0.06 });
  };
  S.golden = function () {
    var t = this.now();
    [76, 79, 84, 88, 91].forEach(function (n, i) {
      this.tone(midi(n), 0.25, { type: "sine", gain: 0.16, when: t + i * 0.05 });
      this.tone(midi(n + 12), 0.2, { type: "triangle", gain: 0.05, when: t + i * 0.05 });
    }, this);
  };
  S.powerup = function (type) {
    var t = this.now();
    var map = { slow: [72, 67, 60], ghost: [70, 75, 82], magnet: [64, 71, 76], double: [72, 79, 84] };
    (map[type] || map.double).forEach(function (n, i) {
      this.tone(midi(n), 0.18, { type: "square", gain: 0.07, when: t + i * 0.07, filter: 2400 });
    }, this);
    this.tone(midi(48), 0.4, { type: "sine", gain: 0.12, slide: midi(60), when: t });
  };
  S.powerEnd = function () {
    var t = this.now();
    this.tone(midi(67), 0.12, { type: "triangle", gain: 0.08, when: t });
    this.tone(midi(60), 0.16, { type: "triangle", gain: 0.08, when: t + 0.08 });
  };
  S.turn = function () {
    var t = this.now();
    if (t - this.lastTurn < 0.05) return;
    this.lastTurn = t;
    this.tone(1800, 0.025, { type: "sine", gain: 0.025 });
  };
  S.portal = function () {
    this.tone(200, 0.35, { type: "sine", gain: 0.14, slide: 1400 });
    this.noise(0.3, { freq: 600, freqTo: 4000, gain: 0.06 });
  };
  S.ghostPass = function () {
    this.tone(500, 0.15, { type: "sine", gain: 0.05, slide: 900 });
  };
  S.crash = function () {
    this.noise(0.5, { ftype: "lowpass", freq: 1800, freqTo: 120, gain: 0.45, q: 0.5 });
    this.tone(160, 0.5, { type: "sawtooth", gain: 0.16, slide: 40, filter: 900 });
    this.tone(90, 0.35, { type: "sine", gain: 0.3, slide: 30 });
  };
  S.expire = function () {
    this.tone(660, 0.12, { type: "sine", gain: 0.05, slide: 330 });
  };
  S.uiMove = function () {
    this.tone(1200, 0.04, { type: "sine", gain: 0.04 });
  };
  S.uiSelect = function () {
    var t = this.now();
    this.tone(midi(79), 0.07, { type: "triangle", gain: 0.1, when: t });
    this.tone(midi(86), 0.09, { type: "triangle", gain: 0.08, when: t + 0.05 });
  };
  S.uiBack = function () {
    var t = this.now();
    this.tone(midi(74), 0.07, { type: "triangle", gain: 0.08, when: t });
    this.tone(midi(67), 0.09, { type: "triangle", gain: 0.07, when: t + 0.05 });
  };
  S.error = function () {
    this.tone(180, 0.18, { type: "square", gain: 0.05, filter: 900 });
  };
  S.buy = function () {
    var t = this.now();
    [84, 88, 91, 96].forEach(function (n, i) { this.tone(midi(n), 0.15, { type: "sine", gain: 0.1, when: t + i * 0.06 }); }, this);
    this.noise(0.25, { freq: 7000, gain: 0.04, when: t + 0.05 });
  };
  S.achievement = function (rarity) {
    var t = this.now();
    var notes = rarity === "gold" ? [72, 76, 79, 84, 88] : rarity === "silver" ? [72, 76, 79, 84] : [72, 76, 79];
    notes.forEach(function (n, i) {
      this.tone(midi(n), 0.35, { type: "triangle", gain: 0.12, when: t + i * 0.08 });
      this.tone(midi(n + 12), 0.3, { type: "sine", gain: 0.05, when: t + i * 0.08 });
    }, this);
    this.tone(midi(notes[notes.length - 1] + 12), 0.8, { type: "sine", gain: 0.06, when: t + notes.length * 0.08 });
  };
  S.moonChime = function (i) {
    var n = [79, 83, 86][i] || 86;
    this.tone(midi(n), 0.4, { type: "triangle", gain: 0.16 });
    this.tone(midi(n + 12), 0.5, { type: "sine", gain: 0.07 });
  };
  S.win = function () {
    var t = this.now();
    [60, 64, 67, 72, 67, 72, 76].forEach(function (n, i) {
      this.tone(midi(n), 0.2, { type: "square", gain: 0.06, when: t + i * 0.09, filter: 3000 });
    }, this);
    this.tone(midi(48), 0.9, { type: "triangle", gain: 0.12, when: t + 0.54 });
  };
  S.lose = function () {
    var t = this.now();
    [67, 63, 60, 55].forEach(function (n, i) {
      this.tone(midi(n), 0.3, { type: "triangle", gain: 0.1, when: t + 0.35 + i * 0.16 });
    }, this);
  };
  S.count = function (go) {
    if (go) {
      this.tone(midi(84), 0.35, { type: "square", gain: 0.07, filter: 3000 });
      this.tone(midi(72), 0.35, { type: "triangle", gain: 0.12 });
    } else {
      this.tone(midi(72), 0.12, { type: "square", gain: 0.06, filter: 2000 });
    }
  };
  S.combo = function (n) {
    this.tone(midi(84 + Math.min(n, 12)), 0.15, { type: "sine", gain: 0.06 });
  };

  Synth.midi = midi;
  LM.Synth = Synth;
})(window.LUMEN);
