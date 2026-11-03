/* ============================================================================
   NEON HORIZON 2088 · Cyberpunk 3D Pinball Studio
   ----------------------------------------------------------------------------
   Rendering ........ Three.js r128
   Physics .......... Cannon.js 0.6.2 · fixed 120 Hz simulation
   Audio ............ Web Audio API (100% synthesised, zero assets)
   Persistence ...... localStorage + portable JSON score archive
   ========================================================================== */

(function () {
  "use strict";

  /* ==========================================================================
     0. Utilities & constants
     ========================================================================== */

  var VERSION = "1.0.0";
  var STORAGE = {
    scores: "neon_horizon_scores_v1",
    callsign: "neon_horizon_callsign_v1",
    muted: "neon_horizon_muted_v1",
    best: "neon_horizon_best_v1"
  };

  var TABLE = {
    width: 10,
    length: 22,
    halfW: 5,
    halfL: 11,
    tiltDeg: 6.6,
    ballR: 0.32,
    halfW2: 5.1
  };
  TABLE.tilt = TABLE.tiltDeg * Math.PI / 180;

  var FIXED_STEP = 1 / 120;
  var FLIPPER = {
    restLeft: -0.34,
    activeLeft: 0.6,
    restRight: 0.34,
    activeRight: -0.6,
    upSpeed: 20,
    downSpeed: 11
  };

  var IS_TOUCH = ("ontouchstart" in window) || navigator.maxTouchPoints > 0;
  var IS_SMALL = window.innerWidth < 900;

  function clamp(v, min, max) { return Math.max(min, Math.min(max, v)); }
  function lerp(a, b, t) { return a + (b - a) * t; }
  function rand(a, b) { return a + Math.random() * (b - a); }
  function formatScore(n) {
    n = Math.max(0, Math.floor(Number(n) || 0));
    return n.toLocaleString("en-US");
  }
  function formatTime(ms) {
    var total = Math.max(0, Math.floor(ms / 1000));
    var m = Math.floor(total / 60);
    var s = total % 60;
    return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
  }
  function sanitizeName(value) {
    var name = String(value == null ? "" : value)
      .replace(/[<>&"']/g, "")
      .replace(/\s+/g, " ")
      .trim()
      .slice(0, 14);
    return name || "RUNNER-01";
  }
  function safeStorageGet(key, fallback) {
    try {
      var raw = window.localStorage.getItem(key);
      return raw == null ? fallback : raw;
    } catch (err) { return fallback; }
  }
  function safeStorageSet(key, value) {
    try { window.localStorage.setItem(key, value); return true; }
    catch (err) { return false; }
  }
  function $(id) { return document.getElementById(id); }
  function createEl(tag, className, text) {
    var el = document.createElement(tag);
    if (className) el.className = className;
    if (text != null) el.textContent = text;
    return el;
  }
  function escapeRegExp(text) { return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"); }

  function prefersReducedMotion() {
    try { return window.matchMedia("(prefers-reduced-motion: reduce)").matches; }
    catch (err) { return false; }
  }

  /* ==========================================================================
     1. Synthesised arcade audio
     ========================================================================== */

  function Synth() {
    this.ctx = null;
    this.master = null;
    this.compressor = null;
    this.ambientGain = null;
    this.chargeOsc = null;
    this.chargeGain = null;
    this.muted = safeStorageGet(STORAGE.muted, "0") === "1";
    this.available = true;
  }

  Synth.prototype.ensure = function () {
    if (!this.available) return false;
    if (!this.ctx) {
      try {
        var Ctx = window.AudioContext || window.webkitAudioContext;
        if (!Ctx) { this.available = false; return false; }
        this.ctx = new Ctx();
        this.master = this.ctx.createGain();
        this.master.gain.value = this.muted ? 0 : 0.62;
        this.compressor = this.ctx.createDynamicsCompressor();
        this.compressor.threshold.value = -18;
        this.compressor.knee.value = 18;
        this.compressor.ratio.value = 8;
        this.compressor.attack.value = 0.004;
        this.compressor.release.value = 0.22;
        this.master.connect(this.compressor);
        this.compressor.connect(this.ctx.destination);
      } catch (err) {
        this.available = false;
        return false;
      }
    }
    if (this.ctx.state === "suspended") {
      this.ctx.resume().catch(function () {});
    }
    return true;
  };

  Synth.prototype.now = function () { return this.ctx ? this.ctx.currentTime : 0; };

  Synth.prototype.setMuted = function (muted) {
    this.muted = !!muted;
    safeStorageSet(STORAGE.muted, muted ? "1" : "0");
    if (this.master && this.ctx) {
      this.master.gain.setTargetAtTime(muted ? 0 : 0.62, this.ctx.currentTime, 0.05);
    }
    return this.muted;
  };

  Synth.prototype.tone = function (opts) {
    if (!this.ensure()) return;
    var o = opts || {};
    var t = this.now() + (o.delay || 0);
    var dur = o.dur || 0.15;
    var osc = this.ctx.createOscillator();
    var gain = this.ctx.createGain();
    var pan = null;
    osc.type = o.type || "sine";
    osc.frequency.setValueAtTime(Math.max(20, o.freq || 440), t);
    if (o.endFreq) osc.frequency.exponentialRampToValueAtTime(Math.max(20, o.endFreq), t + dur);
    gain.gain.setValueAtTime(0.0001, t);
    gain.gain.exponentialRampToValueAtTime(Math.max(0.0002, o.gain || 0.12), t + Math.min(0.012, dur * 0.25));
    gain.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    if (o.pan != null && this.ctx.createStereoPanner) {
      pan = this.ctx.createStereoPanner();
      pan.pan.value = clamp(o.pan, -1, 1);
      osc.connect(gain);
      gain.connect(pan);
      pan.connect(this.master);
    } else {
      osc.connect(gain);
      gain.connect(this.master);
    }
    osc.start(t);
    osc.stop(t + dur + 0.04);
  };

  Synth.prototype.noise = function (opts) {
    if (!this.ensure()) return;
    var o = opts || {};
    var t = this.now() + (o.delay || 0);
    var dur = o.dur || 0.12;
    var length = Math.max(1, Math.floor(this.ctx.sampleRate * dur));
    var buffer = this.ctx.createBuffer(1, length, this.ctx.sampleRate);
    var data = buffer.getChannelData(0);
    for (var i = 0; i < length; i++) {
      data[i] = (Math.random() * 2 - 1) * (1 - i / length);
    }
    var src = this.ctx.createBufferSource();
    src.buffer = buffer;
    var filter = this.ctx.createBiquadFilter();
    filter.type = o.filter || "bandpass";
    filter.frequency.value = o.freq || 1200;
    filter.Q.value = o.q || 0.8;
    var gain = this.ctx.createGain();
    gain.gain.value = o.gain || 0.1;
    src.connect(filter);
    filter.connect(gain);
    gain.connect(this.master);
    src.start(t);
    src.stop(t + dur + 0.02);
  };

  Synth.prototype.startAmbient = function () {
    if (!this.ensure() || this.ambientGain) return;
    var self = this;
    var t = this.now();
    var ambient = this.ctx.createGain();
    ambient.gain.setValueAtTime(0.0001, t);
    ambient.gain.exponentialRampToValueAtTime(0.055, t + 1.2);
    var filter = this.ctx.createBiquadFilter();
    filter.type = "lowpass";
    filter.frequency.value = 320;
    filter.Q.value = 4;
    ambient.connect(filter);
    filter.connect(this.master);
    this.ambientGain = ambient;

    [55, 82.5, 110.2].forEach(function (freq, index) {
      var osc = self.ctx.createOscillator();
      var g = self.ctx.createGain();
      osc.type = index === 1 ? "sine" : "sawtooth";
      osc.frequency.value = freq;
      osc.detune.value = index * 6 - 6;
      g.gain.value = index === 2 ? 0.16 : 0.3;
      osc.connect(g);
      g.connect(ambient);
      osc.start(t);
      self.oscillators = self.oscillators || [];
      self.oscillators.push(osc);

      if (index === 0) {
        var lfo = self.ctx.createOscillator();
        var lfoGain = self.ctx.createGain();
        lfo.frequency.value = 0.09;
        lfoGain.gain.value = 140;
        lfo.connect(lfoGain);
        lfoGain.connect(filter.frequency);
        lfo.start(t);
        self.oscillators.push(lfo);
      }
    });

    var shimmer = this.ctx.createOscillator();
    var shimmerGain = this.ctx.createGain();
    shimmer.type = "sine";
    shimmer.frequency.value = 1760;
    shimmerGain.gain.value = 0.004;
    shimmer.connect(shimmerGain);
    shimmerGain.connect(this.master);
    shimmer.start(t);
    this.oscillators.push(shimmer);
  };

  Synth.prototype.setAmbientLevel = function (level) {
    if (!this.ambientGain || !this.ctx) return;
    this.ambientGain.gain.setTargetAtTime(0.055 * level, this.ctx.currentTime, 0.4);
  };

  Synth.prototype.flipper = function (side) {
    var pan = side === "left" ? -0.45 : 0.45;
    this.tone({ freq: 132, endFreq: 68, type: "square", dur: 0.07, gain: 0.075, pan: pan });
    this.noise({ dur: 0.045, freq: 240, q: 1.2, gain: 0.045, filter: "lowpass" });
  };

  Synth.prototype.bumper = function (index) {
    var base = [520, 660, 780][index % 3];
    var pan = [-0.35, 0, 0.35][index % 3];
    this.tone({ freq: base, endFreq: base * 2.1, type: "triangle", dur: 0.18, gain: 0.15, pan: pan });
    this.tone({ freq: 104, endFreq: 58, type: "sine", dur: 0.2, gain: 0.17 });
    this.noise({ dur: 0.08, freq: 2200, q: 1.4, gain: 0.06 });
  };

  Synth.prototype.target = function () {
    this.tone({ freq: 880, endFreq: 220, type: "square", dur: 0.13, gain: 0.08 });
    this.tone({ freq: 1760, endFreq: 440, type: "sine", dur: 0.1, gain: 0.05, delay: 0.02 });
    this.noise({ dur: 0.06, freq: 3200, gain: 0.05 });
  };

  Synth.prototype.launch = function (power) {
    var p = clamp(power || 1, 0.15, 1);
    this.tone({ freq: 62, endFreq: 240 + 520 * p, type: "sawtooth", dur: 0.42, gain: 0.12 });
    this.tone({ freq: 120, endFreq: 60, type: "square", dur: 0.18, gain: 0.1 });
    this.noise({ dur: 0.32, freq: 900, q: 1.1, gain: 0.1 + p * 0.06 });
  };

  Synth.prototype.loop = function () {
    this.tone({ freq: 240, endFreq: 1680, type: "sine", dur: 0.55, gain: 0.11, pan: -0.4 });
    this.tone({ freq: 480, endFreq: 3360, type: "triangle", dur: 0.48, gain: 0.04, delay: 0.06, pan: 0.4 });
    this.noise({ dur: 0.45, freq: 2600, q: 0.7, gain: 0.05 });
  };

  Synth.prototype.drain = function () {
    this.tone({ freq: 260, endFreq: 38, type: "sawtooth", dur: 0.8, gain: 0.12 });
    this.tone({ freq: 130, endFreq: 30, type: "sine", dur: 0.9, gain: 0.12 });
    this.noise({ dur: 0.55, freq: 240, q: 0.6, gain: 0.08, filter: "lowpass" });
  };

  Synth.prototype.multiplier = function (level) {
    var self = this;
    var notes = [523.25, 659.25, 783.99, 1046.5];
    notes.forEach(function (freq, i) {
      self.tone({ freq: freq * (1 + Math.max(0, level - 1) * 0.03), type: "triangle", dur: 0.22, gain: 0.07, delay: i * 0.07 });
    });
  };

  Synth.prototype.extraBall = function () {
    var self = this;
    [392, 523, 659, 784, 1046].forEach(function (freq, i) {
      self.tone({ freq: freq, type: "sine", dur: 0.25, gain: 0.06, delay: i * 0.075 });
    });
  };

  Synth.prototype.gameOver = function () {
    var self = this;
    [220, 185, 146.83, 110].forEach(function (freq, i) {
      self.tone({ freq: freq, endFreq: freq * 0.94, type: "triangle", dur: 0.55, gain: 0.11, delay: i * 0.24 });
      self.tone({ freq: freq * 0.5, type: "sine", dur: 0.6, gain: 0.06, delay: i * 0.24 });
    });
    this.noise({ dur: 1.1, freq: 180, q: 0.5, gain: 0.06, filter: "lowpass" });
  };

  Synth.prototype.wall = function (velocity) {
    var g = clamp((velocity || 3) / 18, 0.02, 0.085);
    this.noise({ dur: 0.035, freq: 900 + Math.random() * 800, q: 1.5, gain: g });
    this.tone({ freq: 180 + Math.random() * 40, endFreq: 110, type: "sine", dur: 0.04, gain: g * 0.5 });
  };

  Synth.prototype.sling = function () {
    this.tone({ freq: 320, endFreq: 720, type: "square", dur: 0.1, gain: 0.07 });
    this.noise({ dur: 0.06, freq: 1500, gain: 0.06 });
  };

  Synth.prototype.startCharge = function () {
    if (!this.ensure() || this.chargeOsc) return;
    var t = this.now();
    this.chargeOsc = this.ctx.createOscillator();
    this.chargeGain = this.ctx.createGain();
    this.chargeOsc.type = "sawtooth";
    this.chargeOsc.frequency.value = 70;
    this.chargeGain.gain.setValueAtTime(0.0001, t);
    this.chargeGain.gain.exponentialRampToValueAtTime(0.035, t + 0.1);
    var filter = this.ctx.createBiquadFilter();
    filter.type = "lowpass";
    filter.frequency.value = 600;
    this.chargeOsc.connect(filter);
    filter.connect(this.chargeGain);
    this.chargeGain.connect(this.master);
    this.chargeOsc.start(t);
  };

  Synth.prototype.setCharge = function (power) {
    if (!this.chargeOsc || !this.ctx) return;
    this.chargeOsc.frequency.setTargetAtTime(70 + power * 460, this.ctx.currentTime, 0.03);
  };

  Synth.prototype.stopCharge = function () {
    if (!this.chargeOsc || !this.ctx) return;
    var t = this.ctx.currentTime;
    try {
      this.chargeGain.gain.cancelScheduledValues(t);
      this.chargeGain.gain.setTargetAtTime(0.0001, t, 0.02);
      this.chargeOsc.stop(t + 0.08);
    } catch (err) { /* already stopped */ }
    this.chargeOsc = null;
    this.chargeGain = null;
  };

  var synth = new Synth();

  /* ==========================================================================
     2. Persistence · leaderboard & portable archives
     ========================================================================== */

  function sanitizeScoreEntry(raw) {
    if (!raw || typeof raw !== "object") return null;
    var score = Number(raw.score);
    if (!isFinite(score) || score <= 0) return null;
    score = clamp(Math.floor(score), 0, 999999999999);
    var name = sanitizeName(raw.name || raw.callsign || "RUNNER");
    var date = typeof raw.date === "string" ? raw.date.slice(0, 40) : "";
    var id = typeof raw.id === "string" ? raw.id.slice(0, 60) : "";
    return {
      id: id || makeEntryId(),
      name: name,
      score: score,
      date: date || new Date().toISOString(),
      maxMultiplier: clamp(Math.floor(Number(raw.maxMultiplier) || 1), 1, 99),
      loops: clamp(Math.floor(Number(raw.loops) || 0), 0, 999999),
      targets: clamp(Math.floor(Number(raw.targets) || 0), 0, 999999)
    };
  }

  function makeEntryId() {
    return "nh-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 7);
  }

  var scoreStore = {
    entries: [],
    best: 0,
    load: function () {
      var list = [];
      try {
        var raw = safeStorageGet(STORAGE.scores, "[]");
        var parsed = JSON.parse(raw);
        if (Array.isArray(parsed)) list = parsed;
        else if (parsed && Array.isArray(parsed.scores)) list = parsed.scores;
      } catch (err) { list = []; }
      this.entries = dedupeEntries(list.map(sanitizeScoreEntry).filter(Boolean));
      this.sort();
      this.best = Math.max(Number(safeStorageGet(STORAGE.best, "0")) || 0, this.entries.length ? this.entries[0].score : 0);
      return this.entries;
    },
    sort: function () {
      this.entries.sort(function (a, b) {
        return b.score - a.score || String(a.date).localeCompare(String(b.date));
      });
      if (this.entries.length > 30) this.entries.length = 30;
    },
    save: function () {
      this.sort();
      safeStorageSet(STORAGE.scores, JSON.stringify(this.entries));
      safeStorageSet(STORAGE.best, String(this.best));
    },
    add: function (entry) {
      var clean = sanitizeScoreEntry(entry);
      if (!clean) return null;
      this.entries.push(clean);
      this.sort();
      this.best = Math.max(this.best, clean.score);
      this.save();
      return clean;
    },
    merge: function (list) {
      var incoming = (list || []).map(sanitizeScoreEntry).filter(Boolean);
      if (!incoming.length) return 0;
      var before = this.entries.length;
      var keys = {};
      this.entries.forEach(function (e) { keys[entryKey(e)] = true; });
      var additions = 0;
      incoming.forEach(function (e) {
        var key = entryKey(e);
        if (!keys[key]) {
          keys[key] = true;
          scoreStore.entries.push(e);
          additions++;
        }
      });
      this.sort();
      this.best = Math.max(this.best, this.entries[0] ? this.entries[0].score : 0);
      this.save();
      return additions || (incoming.length - (this.entries.length - before));
    }
  };

  function entryKey(entry) {
    return String(entry.name).toLowerCase() + "|" + entry.score + "|" + String(entry.date || "").slice(0, 16);
  }

  function dedupeEntries(list) {
    var seen = {};
    var out = [];
    list.forEach(function (entry) {
      var key = entryKey(entry);
      if (!seen[key]) {
        seen[key] = true;
        out.push(entry);
      }
    });
    return out;
  }

  /* ==========================================================================
     3. DOM references & UI helpers
     ========================================================================== */

  var dom = {
    canvas: $("game-canvas"),
    boot: $("boot"),
    bootFill: $("boot-fill"),
    bootHint: $("boot-hint"),
    hud: $("hud"),
    score: $("score"),
    best: $("best-score"),
    multiplier: $("multiplier"),
    balls: $("balls"),
    combo: $("combo-count"),
    status: $("status-pill"),
    targetsLeft: $("targets-left"),
    loopsHit: $("loops-hit"),
    bumperHits: $("bumper-hits"),
    leaderboard: $("leaderboard"),
    syncStatus: $("sync-status"),
    soundToggle: $("sound-toggle"),
    soundGlyph: $("sound-glyph"),
    newGame: $("new-game"),
    saveScores: $("save-scores"),
    loadScores: $("load-scores"),
    rescueBall: $("rescue-ball"),
    scoreFile: $("score-file"),
    launchBtn: $("launch-btn"),
    launchHint: $("launch-hint"),
    chargeFill: $("charge-fill"),
    chargeLabel: $("charge-label"),
    chargeMeter: $("charge-meter"),
    startOverlay: $("start-overlay"),
    startForm: $("start-form"),
    callsign: $("callsign"),
    gameoverOverlay: $("gameover-overlay"),
    finalScore: $("final-score"),
    finalRank: $("final-rank"),
    finalMult: $("final-mult"),
    finalTargets: $("final-targets"),
    finalLoops: $("final-loops"),
    finalTime: $("final-time"),
    gameoverNote: $("gameover-note"),
    gameoverSave: $("gameover-save"),
    playAgain: $("play-again"),
    helpBtn: $("help-btn"),
    helpOverlay: $("help-overlay"),
    helpClose: $("help-close"),
    helpResume: $("help-resume"),
    helpStart: $("help-start"),
    confirmOverlay: $("confirm-overlay"),
    confirmOk: $("confirm-ok"),
    confirmCancel: $("confirm-cancel"),
    toastStack: $("toast-stack"),
    a11y: $("a11y-live"),
    flipLeft: $("flip-left"),
    flipRight: $("flip-right"),
    scoresToggle: $("scores-toggle"),
    scoresPanel: $("scores-panel"),
    fullscreen: $("fullscreen-btn")
  };

  var lastScoreText = "";
  var lastMultiplierText = "";
  var lastBallsText = "";
  var lastChargePct = -1;

  function animateMetric(el) {
    if (!el) return;
    el.classList.remove("is-bumped");
    void el.offsetWidth;
    el.classList.add("is-bumped");
    window.clearTimeout(el._bumpTimer);
    el._bumpTimer = window.setTimeout(function () { el.classList.remove("is-bumped"); }, 190);
  }

  function updateHUD(animate) {
    var scoreText = formatScore(game.score);
    if (scoreText !== lastScoreText) {
      dom.score.textContent = scoreText;
      lastScoreText = scoreText;
      if (animate) animateMetric(dom.score);
    }
    var multText = "×" + game.multiplier;
    if (multText !== lastMultiplierText) {
      dom.multiplier.textContent = multText;
      lastMultiplierText = multText;
      if (animate) animateMetric(dom.multiplier);
    }
    var ballsText = String(Math.max(0, game.ballsLeft));
    if (ballsText !== lastBallsText) {
      dom.balls.textContent = ballsText;
      lastBallsText = ballsText;
      if (animate) animateMetric(dom.balls);
    }
    dom.best.textContent = formatScore(scoreStore.best);
    dom.combo.textContent = String(game.combo);
    dom.targetsLeft.textContent = game.targetsDown + " / " + targets.length;
    dom.loopsHit.textContent = String(game.loops);
    dom.bumperHits.textContent = String(game.bumperHits);
    if (dom.status) {
      dom.status.textContent = statusLabel();
      dom.status.classList.toggle("is-live", game.phase === "play" || game.phase === "ready");
    }
    if (dom.chargeMeter) {
      var pct = Math.round(game.charge * 100);
      if (pct !== lastChargePct) {
        lastChargePct = pct;
        dom.chargeFill.style.width = pct + "%";
        dom.chargeLabel.textContent = pct + "%";
        dom.chargeMeter.setAttribute("aria-valuenow", String(pct));
      }
    }
    updateLeaderboard();
  }

  function statusLabel() {
    switch (game.phase) {
      case "menu": return "STANDBY";
      case "ready": return "BALL READY";
      case "play": return "IN PLAY";
      case "drain": return "BALL LOST";
      case "over": return "GRID OVERRUN";
      case "paused": return "PAUSED";
      default: return "STANDBY";
    }
  }

  function renderLeaderboard() {
    if (!dom.leaderboard) return;
    var list = scoreStore.entries.slice(0, 5);
    dom.leaderboard.innerHTML = "";
    if (!list.length) {
      var empty = createEl("li", "leaderboard__empty");
      empty.innerHTML = "No records yet.<br>Be the first legend.";
      dom.leaderboard.appendChild(empty);
      return;
    }
    list.forEach(function (entry, index) {
      var li = createEl("li");
      if (entry.id && entry.id === game.archiveId) li.classList.add("is-current");
      li.appendChild(createEl("span", "rank", String(index + 1).padStart(2, "0")));
      li.appendChild(createEl("span", "who", entry.name));
      li.appendChild(createEl("span", "score", formatScore(entry.score)));
      li.title = entry.name + " · " + entry.score + " pts" + (entry.date ? " · " + entry.date.slice(0, 10) : "");
      dom.leaderboard.appendChild(li);
    });
  }

  function updateLeaderboard() { renderLeaderboard(); }

  var toastTimers = [];
  function toast(message, tone, duration) {
    if (!dom.toastStack) return;
    while (dom.toastStack.children.length >= 3) {
      dom.toastStack.removeChild(dom.toastStack.firstChild);
    }
    var el = createEl("div", "toast" + (tone ? " toast--" + tone : ""));
    el.appendChild(createEl("span", "", message));
    dom.toastStack.appendChild(el);
    var timer = window.setTimeout(function () {
      el.classList.add("is-out");
      window.setTimeout(function () {
        if (el.parentNode) el.parentNode.removeChild(el);
      }, 380);
    }, duration || 2800);
    toastTimers.push(timer);
    if (toastTimers.length > 12) toastTimers.shift();
  }

  function announce(message) {
    if (!dom.a11y) return;
    dom.a11y.textContent = "";
    window.setTimeout(function () { dom.a11y.textContent = message; }, 30);
  }

  /* ==========================================================================
     4. Three.js scene, renderer, camera
     ========================================================================== */

  var renderer, scene, camera, tableGroup, envMap, envTarget;
  var tableMeshes = [];
  var glowSprites = [];
  var cameraBase = { x: 0, y: 23, z: 27.5, lookY: -0.05, lookZ: -0.4 };
  var mouseTarget = { x: 0, y: 0 };
  var mouseSmooth = { x: 0, y: 0 };
  var sceneReady = false;
  var clockStart = performance.now();
  var neonStripMaterials = [];

  function initRenderer() {
    renderer = new THREE.WebGLRenderer({
      canvas: dom.canvas,
      antialias: true,
      alpha: false,
      powerPreference: "high-performance"
    });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, IS_SMALL ? 1.7 : 2));
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setClearColor(0x03050c, 1);
    renderer.outputEncoding = THREE.sRGBEncoding;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.18;
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;

    scene = new THREE.Scene();
    scene.fog = new THREE.Fog(0x03050c, 48, 105);

    camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 220);
    updateCameraLayout();
    camera.position.set(cameraBase.x, cameraBase.y, cameraBase.z);
    camera.lookAt(0, cameraBase.lookY, cameraBase.lookZ);

    tableGroup = new THREE.Group();
    tableGroup.rotation.x = TABLE.tilt;
    scene.add(tableGroup);

    window.addEventListener("resize", onResize, { passive: true });
    window.addEventListener("orientationchange", onResize, { passive: true });
  }

  function updateCameraLayout() {
    if (!camera) return;
    var w = window.innerWidth;
    var h = window.innerHeight;
    var aspect = w / Math.max(1, h);
    if (aspect < 0.72) {
      camera.fov = 55;
      cameraBase = { x: 0, y: 25, z: 32.5, lookY: 0.2, lookZ: 0.3 };
    } else if (aspect < 0.95) {
      camera.fov = 54;
      cameraBase = { x: 0, y: 26, z: 34, lookY: 0.1, lookZ: 0.2 };
    } else if (aspect < 1.25) {
      camera.fov = 48;
      cameraBase = { x: 0, y: 24.5, z: 30.5, lookY: -0.05, lookZ: -0.1 };
    } else if (aspect < 1.75) {
      camera.fov = 45;
      cameraBase = { x: 0, y: 23.5, z: 28.5, lookY: -0.05, lookZ: -0.35 };
    } else {
      camera.fov = 45;
      cameraBase = { x: 0, y: 23, z: 27.5, lookY: -0.05, lookZ: -0.4 };
    }
    camera.aspect = aspect;
    camera.updateProjectionMatrix();
  }

  function onResize() {
    if (!renderer || !camera) return;
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, window.innerWidth < 900 ? 1.7 : 2));
    renderer.setSize(window.innerWidth, window.innerHeight);
    updateCameraLayout();
  }

  /* ==========================================================================
     5. Procedural textures & shared materials
     ========================================================================== */

  function makeCanvas(w, h) {
    var c = document.createElement("canvas");
    c.width = w;
    c.height = h;
    return c;
  }

  function canvasTexture(canvas, repeatX, repeatY) {
    var tex = new THREE.CanvasTexture(canvas);
    tex.encoding = THREE.sRGBEncoding;
    tex.anisotropy = Math.min(8, renderer.capabilities.getMaxAnisotropy());
    if (repeatX || repeatY) {
      tex.wrapS = THREE.RepeatWrapping;
      tex.wrapT = THREE.RepeatWrapping;
      tex.repeat.set(repeatX || 1, repeatY || 1);
    }
    tex.needsUpdate = true;
    return tex;
  }

  function makeGlowTexture() {
    var c = makeCanvas(128, 128);
    var ctx = c.getContext("2d");
    var g = ctx.createRadialGradient(64, 64, 0, 64, 64, 64);
    g.addColorStop(0, "rgba(255,255,255,1)");
    g.addColorStop(0.18, "rgba(255,255,255,0.8)");
    g.addColorStop(0.45, "rgba(255,255,255,0.22)");
    g.addColorStop(1, "rgba(255,255,255,0)");
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, 128, 128);
    var tex = new THREE.CanvasTexture(c);
    tex.needsUpdate = true;
    return tex;
  }

  var glowTexture = null;

  function makeGlowSprite(color, scale, opacity) {
    if (!glowTexture) glowTexture = makeGlowTexture();
    var mat = new THREE.SpriteMaterial({
      map: glowTexture,
      color: color,
      transparent: true,
      opacity: opacity == null ? 0.55 : opacity,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      depthTest: true
    });
    var sprite = new THREE.Sprite(mat);
    sprite.scale.set(scale, scale, 1);
    glowSprites.push({ sprite: sprite, base: mat.opacity, phase: Math.random() * Math.PI * 2 });
    return sprite;
  }

  function makePlayfieldTexture() {
    var c = makeCanvas(1024, 2048);
    var ctx = c.getContext("2d");
    var W = c.width, H = c.height;
    var P = function (x, z) { return [((x + 5) / 10) * W, ((z + 11) / 22) * H]; };

    var bg = ctx.createLinearGradient(0, 0, 0, H);
    bg.addColorStop(0, "#0a1022");
    bg.addColorStop(0.35, "#060a16");
    bg.addColorStop(1, "#04060e");
    ctx.fillStyle = bg;
    ctx.fillRect(0, 0, W, H);

    var halo = ctx.createRadialGradient(W * 0.5, H * 0.35, 10, W * 0.5, H * 0.35, W * 0.9);
    halo.addColorStop(0, "rgba(30, 60, 120, 0.18)");
    halo.addColorStop(0.5, "rgba(90, 20, 110, 0.06)");
    halo.addColorStop(1, "rgba(0,0,0,0)");
    ctx.fillStyle = halo;
    ctx.fillRect(0, 0, W, H);

    // Fine engineering grid
    ctx.save();
    ctx.strokeStyle = "rgba(108, 220, 255, 0.055)";
    ctx.lineWidth = 1;
    for (var x = 0; x <= W; x += 64) {
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, H); ctx.stroke();
    }
    for (var y = 0; y <= H; y += 64) {
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke();
    }
    ctx.restore();

    // Subtle hex field
    ctx.save();
    ctx.strokeStyle = "rgba(120, 70, 255, 0.06)";
    ctx.lineWidth = 1;
    for (var row = 0; row < 22; row++) {
      for (var col = 0; col < 12; col++) {
        var cx = col * 96 + (row % 2 ? 48 : 0);
        var cy = row * 96;
        ctx.beginPath();
        for (var k = 0; k < 6; k++) {
          var ang = Math.PI / 3 * k + Math.PI / 6;
          var px = cx + Math.cos(ang) * 30;
          var py = cy + Math.sin(ang) * 30;
          if (k === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
        }
        ctx.closePath();
        ctx.stroke();
      }
    }
    ctx.restore();

    function glowPath(points, color, width, alpha) {
      ctx.save();
      ctx.strokeStyle = color;
      ctx.globalAlpha = alpha == null ? 0.6 : alpha;
      ctx.lineWidth = width || 2;
      ctx.lineJoin = "round";
      ctx.lineCap = "round";
      ctx.shadowColor = color;
      ctx.shadowBlur = 16;
      ctx.beginPath();
      points.forEach(function (pt, i) {
        var p = P(pt[0], pt[1]);
        if (i === 0) ctx.moveTo(p[0], p[1]); else ctx.lineTo(p[0], p[1]);
      });
      ctx.stroke();
      ctx.restore();
    }

    // Side circuit traces
    glowPath([[-4.55, -9.4], [-4.55, -5.8], [-4.1, -5.3], [-4.1, -1.2], [-4.65, 0.1], [-4.65, 4.2], [-4.1, 4.7], [-4.1, 8.2]], "#3ee8ff", 2, 0.38);
    glowPath([[4.55, -8.6], [4.55, -5.9], [4.2, -5.4], [4.2, -1.8]], "#ff4ce0", 2, 0.34);
    glowPath([[-4.1, 3.0], [-2.8, 3.0], [-2.8, 4.4], [-1.5, 4.4], [-1.5, 5.6]], "#8d6cff", 1.5, 0.38);
    glowPath([[3.9, -1.0], [3.9, 0.8], [3.2, 0.8], [3.2, 2.4]], "#3ee8ff", 1.5, 0.32);

    // Circuit nodes
    [[-4.55, -5.8], [-4.1, -5.3], [-4.1, -1.2], [-4.65, 0.1], [-4.1, 4.7], [4.2, -5.4], [3.9, 0.8], [3.2, 2.4]].forEach(function (node, i) {
      var p = P(node[0], node[1]);
      ctx.save();
      ctx.fillStyle = i % 2 ? "#ff3bdc" : "#5ff6ff";
      ctx.shadowColor = ctx.fillStyle;
      ctx.shadowBlur = 14;
      ctx.beginPath();
      ctx.arc(p[0], p[1], 4, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    });

    // Bumper target rings
    [[-2.5, -3.4], [0, -5.4], [2.5, -3.4]].forEach(function (b) {
      var p = P(b[0], b[1]);
      ctx.save();
      ctx.strokeStyle = "rgba(95, 246, 255, 0.22)";
      ctx.lineWidth = 2;
      ctx.setLineDash([6, 8]);
      ctx.beginPath();
      ctx.arc(p[0], p[1], 118, 0, Math.PI * 2);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.strokeStyle = "rgba(255, 59, 220, 0.15)";
      ctx.beginPath();
      ctx.arc(p[0], p[1], 140, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
    });

    // Flipper zone arcs
    ctx.save();
    ctx.strokeStyle = "rgba(95, 246, 255, 0.16)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(P(-2.55, 7.6)[0], P(-2.55, 7.6)[1], 150, Math.PI * 0.55, Math.PI * 1.45);
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(P(2.55, 7.6)[0], P(2.55, 7.6)[1], 150, Math.PI * 1.55, Math.PI * 2.45);
    ctx.stroke();
    ctx.restore();

    // Title watermark near the top of the playfield
    ctx.save();
    ctx.translate(W / 2, H * 0.175);
    ctx.textAlign = "center";
    ctx.font = "900 64px Orbitron, Arial Black, sans-serif";
    ctx.fillStyle = "rgba(95, 246, 255, 0.14)";
    ctx.shadowColor = "rgba(95, 246, 255, 0.45)";
    ctx.shadowBlur = 22;
    ctx.fillText("NEON HORIZON", 0, 0);
    ctx.font = "600 22px Rajdhani, Arial, sans-serif";
    ctx.fillStyle = "rgba(255, 59, 220, 0.25)";
    ctx.shadowColor = "rgba(255, 59, 220, 0.6)";
    ctx.fillText("S E C T O R   0 7   ·   P L A S M A   G R I D", 0, 32);
    ctx.restore();

    // Giant 2088 watermark
    ctx.save();
    ctx.translate(W / 2, H * 0.58);
    ctx.rotate(-Math.PI / 2);
    ctx.textAlign = "center";
    ctx.font = "900 150px Orbitron, Arial Black, sans-serif";
    ctx.fillStyle = "rgba(255, 255, 255, 0.018)";
    ctx.fillText("2088", 0, 0);
    ctx.restore();

    // Cyber Security target warning band
    var band = P(-3.3, 1.45);
    ctx.save();
    ctx.translate(band[0] - 100, band[1]);
    ctx.rotate(-Math.PI / 2);
    ctx.font = "700 19px Rajdhani, Arial, sans-serif";
    ctx.fillStyle = "rgba(255, 59, 220, 0.32)";
    ctx.letterSpacing = "5px";
    ctx.fillText("CYBER SECURITY NODES", 0, 0);
    ctx.restore();

    // Lane arrows
    for (var i = 0; i < 4; i++) {
      var zz = 3.0 + i * 1.35;
      [-2.15, 2.15].forEach(function (xx, idx) {
        var p = P(xx, zz);
        ctx.save();
        ctx.translate(p[0], p[1]);
        ctx.fillStyle = idx ? "rgba(255, 59, 220, 0.18)" : "rgba(95, 246, 255, 0.16)";
        ctx.beginPath();
        ctx.moveTo(-16, -12);
        ctx.lineTo(16, -12);
        ctx.lineTo(0, 14);
        ctx.closePath();
        ctx.fill();
        ctx.restore();
      });
    }

    // Drain warning
    ctx.save();
    var dp = P(0, 9.0);
    ctx.textAlign = "center";
    ctx.font = "700 22px Rajdhani, Arial, sans-serif";
    ctx.fillStyle = "rgba(255, 77, 109, 0.3)";
    ctx.letterSpacing = "12px";
    ctx.fillText("DRAIN", dp[0], dp[1]);
    ctx.restore();

    // Fine speckle / wear
    ctx.save();
    for (var n = 0; n < 1600; n++) {
      ctx.fillStyle = "rgba(255,255,255," + (Math.random() * 0.018) + ")";
      ctx.fillRect(Math.random() * W, Math.random() * H, 1, 1);
    }
    ctx.restore();

    return canvasTexture(c);
  }

  function makeBackglassTexture() {
    var c = makeCanvas(1024, 512);
    var ctx = c.getContext("2d");

    var bg = ctx.createLinearGradient(0, 0, 0, 512);
    bg.addColorStop(0, "#101a3a");
    bg.addColorStop(0.5, "#070b18");
    bg.addColorStop(1, "#03050b");
    ctx.fillStyle = bg;
    ctx.fillRect(0, 0, 1024, 512);

    var sun = ctx.createRadialGradient(512, 195, 8, 512, 195, 240);
    sun.addColorStop(0, "rgba(255, 59, 220, 0.5)");
    sun.addColorStop(0.35, "rgba(120, 60, 255, 0.18)");
    sun.addColorStop(1, "rgba(0, 0, 0, 0)");
    ctx.fillStyle = sun;
    ctx.fillRect(0, 0, 1024, 512);

    ctx.strokeStyle = "rgba(95, 246, 255, 0.15)";
    ctx.lineWidth = 1;
    for (var gx = 0; gx < 1024; gx += 48) {
      ctx.beginPath(); ctx.moveTo(gx, 0); ctx.lineTo(gx, 512); ctx.stroke();
    }
    for (var gy = 0; gy < 512; gy += 48) {
      ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(1024, gy); ctx.stroke();
    }

    ctx.save();
    ctx.strokeStyle = "rgba(255, 59, 220, 0.55)";
    ctx.lineWidth = 3;
    ctx.shadowColor = "#ff3bdc";
    ctx.shadowBlur = 28;
    ctx.beginPath();
    ctx.arc(512, 205, 168, 0, Math.PI * 2);
    ctx.stroke();
    ctx.strokeStyle = "rgba(95, 246, 255, 0.35)";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.arc(512, 205, 190, 0, Math.PI * 2);
    ctx.stroke();
    ctx.restore();

    ctx.textAlign = "center";
    ctx.font = "900 104px Orbitron, Arial Black, sans-serif";
    ctx.fillStyle = "#f2fdff";
    ctx.shadowColor = "rgba(95, 246, 255, 0.8)";
    ctx.shadowBlur = 38;
    ctx.fillText("NEON", 512, 208);
    ctx.fillStyle = "#ff3bdc";
    ctx.shadowColor = "#ff00c8";
    ctx.shadowBlur = 42;
    ctx.fillText("HORIZON", 512, 306);

    ctx.font = "700 26px Rajdhani, Arial, sans-serif";
    ctx.fillStyle = "rgba(95, 246, 255, 0.85)";
    ctx.shadowColor = "#5ff6ff";
    ctx.shadowBlur = 16;
    ctx.letterSpacing = "10px";
    ctx.fillText("2 0 8 8", 512, 366);

    ctx.font = "600 14px Rajdhani, Arial, sans-serif";
    ctx.fillStyle = "rgba(125, 147, 184, 0.8)";
    ctx.shadowBlur = 0;
    ctx.letterSpacing = "8px";
    ctx.fillText("CYBERPUNK PINBALL STUDIO", 512, 410);

    // Scanlines
    ctx.fillStyle = "rgba(0, 0, 0, 0.18)";
    for (var sy = 0; sy < 512; sy += 4) ctx.fillRect(0, sy, 1024, 1);

    return canvasTexture(c);
  }

  function makeCityTexture() {
    var c = makeCanvas(2048, 1024);
    var ctx = c.getContext("2d");
    var sky = ctx.createLinearGradient(0, 0, 0, 1024);
    sky.addColorStop(0, "#02030a");
    sky.addColorStop(0.4, "#080a1b");
    sky.addColorStop(0.68, "#1a1030");
    sky.addColorStop(0.8, "#31113f");
    sky.addColorStop(1, "#05060e");
    ctx.fillStyle = sky;
    ctx.fillRect(0, 0, 2048, 1024);

    // Stars
    for (var i = 0; i < 220; i++) {
      ctx.fillStyle = "rgba(180, 230, 255, " + rand(0.05, 0.45) + ")";
      ctx.fillRect(rand(0, 2048), rand(0, 560), rand(1, 2.4), rand(1, 2.4));
    }

    // Giant neon ring / moon
    ctx.save();
    ctx.strokeStyle = "rgba(255, 59, 220, 0.4)";
    ctx.lineWidth = 5;
    ctx.shadowColor = "#ff3bdc";
    ctx.shadowBlur = 55;
    ctx.beginPath();
    ctx.arc(1024, 410, 168, 0, Math.PI * 2);
    ctx.stroke();
    ctx.strokeStyle = "rgba(95, 246, 255, 0.18)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(1024, 410, 196, 0, Math.PI * 2);
    ctx.stroke();
    ctx.restore();

    // Distant skyline
    var colors = ["#060813", "#070a17", "#05070f", "#080a16"];
    for (var b = 0; b < 70; b++) {
      var bw = rand(30, 110);
      var bh = rand(90, 430);
      var bx = rand(-40, 2048);
      var by = 760 - bh;
      ctx.fillStyle = colors[b % colors.length];
      ctx.fillRect(bx, by, bw, bh + 300);
      if (Math.random() > 0.4) {
        ctx.fillStyle = "rgba(95, 246, 255, 0.11)";
        ctx.fillRect(bx, by, bw, 2);
      }
      // Neon windows
      var cols = Math.max(1, Math.floor(bw / 14));
      var rows = Math.max(2, Math.floor(bh / 20));
      for (var wy = 0; wy < rows; wy++) {
        for (var wx = 0; wx < cols; wx++) {
          if (Math.random() < 0.24) {
            ctx.fillStyle = Math.random() < 0.66 ? "rgba(95, 246, 255, 0.5)" : (Math.random() < 0.5 ? "rgba(255, 59, 220, 0.45)" : "rgba(255, 181, 69, 0.38)");
            ctx.fillRect(bx + 4 + wx * 13, by + 10 + wy * 18, 3, 4);
          }
        }
      }
    }

    // Haze at horizon
    var haze = ctx.createLinearGradient(0, 660, 0, 1024);
    haze.addColorStop(0, "rgba(70, 30, 110, 0.45)");
    haze.addColorStop(0.5, "rgba(20, 10, 40, 0.2)");
    haze.addColorStop(1, "rgba(0,0,0,0)");
    ctx.fillStyle = haze;
    ctx.fillRect(0, 620, 2048, 404);

    // Neon signs
    var signs = [
      { x: 210, y: 650, w: 170, h: 38, c: "rgba(95, 246, 255, 0.5)" },
      { x: 1560, y: 610, w: 210, h: 30, c: "rgba(255, 59, 220, 0.45)" },
      { x: 780, y: 700, w: 120, h: 22, c: "rgba(255, 181, 69, 0.32)" }
    ];
    signs.forEach(function (s) {
      ctx.save();
      ctx.strokeStyle = s.c;
      ctx.lineWidth = 3;
      ctx.shadowColor = s.c;
      ctx.shadowBlur = 24;
      ctx.strokeRect(s.x, s.y, s.w, s.h);
      ctx.restore();
    });

    return canvasTexture(c);
  }

  function makeGridTexture() {
    var c = makeCanvas(512, 512);
    var ctx = c.getContext("2d");
    ctx.fillStyle = "#02040a";
    ctx.fillRect(0, 0, 512, 512);
    ctx.strokeStyle = "rgba(60, 170, 220, 0.24)";
    ctx.lineWidth = 1;
    for (var i = 0; i <= 512; i += 64) {
      ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i, 512); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(0, i); ctx.lineTo(512, i); ctx.stroke();
    }
    ctx.strokeStyle = "rgba(255, 59, 220, 0.28)";
    ctx.lineWidth = 2;
    for (var j = 0; j <= 512; j += 256) {
      ctx.beginPath(); ctx.moveTo(j, 0); ctx.lineTo(j, 512); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(0, j); ctx.lineTo(512, j); ctx.stroke();
    }
    return canvasTexture(c, 16, 16);
  }

  function makeTextSprite(text, color, size) {
    var c = makeCanvas(512, 128);
    var ctx = c.getContext("2d");
    ctx.clearRect(0, 0, 512, 128);
    ctx.font = "700 " + (size || 52) + "px Orbitron, Arial Black, sans-serif";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillStyle = "#ffffff";
    ctx.shadowColor = color;
    ctx.shadowBlur = 22;
    ctx.fillText(text, 256, 66);
    ctx.shadowBlur = 0;
    ctx.fillStyle = color;
    ctx.globalAlpha = 0.9;
    ctx.fillText(text, 256, 66);
    var tex = canvasTexture(c);
    tex.premultiplyAlpha = true;
    var mat = new THREE.SpriteMaterial({
      map: tex,
      transparent: true,
      opacity: 0.9,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    var sprite = new THREE.Sprite(mat);
    sprite.scale.set(2.6, 0.65, 1);
    return sprite;
  }

  function makeEnvMap() {
    var c = makeCanvas(1024, 512);
    var ctx = c.getContext("2d");
    var g = ctx.createLinearGradient(0, 0, 0, 512);
    g.addColorStop(0, "#061226");
    g.addColorStop(0.42, "#0b1730");
    g.addColorStop(0.52, "#1a0d2a");
    g.addColorStop(1, "#03040a");
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, 1024, 512);
    var lights = [
      [120, 210, 300, 24, "#4ff5ff"],
      [600, 190, 360, 18, "#ff3bdc"],
      [850, 250, 240, 14, "#8a6bff"],
      [330, 280, 200, 10, "#ffffff"],
      [40, 260, 120, 10, "#5ff6ff"],
      [960, 230, 130, 12, "#ff7ae6"]
    ];
    lights.forEach(function (l) {
      var lg = ctx.createLinearGradient(l[0], l[1], l[0] + l[2], l[1]);
      lg.addColorStop(0, "rgba(0,0,0,0)");
      lg.addColorStop(0.5, l[4]);
      lg.addColorStop(1, "rgba(0,0,0,0)");
      ctx.save();
      ctx.globalAlpha = 0.85;
      ctx.fillStyle = lg;
      ctx.shadowColor = l[4];
      ctx.shadowBlur = 30;
      ctx.fillRect(l[0], l[1], l[2], l[3]);
      ctx.restore();
    });
    for (var i = 0; i < 80; i++) {
      ctx.fillStyle = "rgba(160, 240, 255, " + rand(0.04, 0.16) + ")";
      ctx.fillRect(rand(0, 1024), rand(0, 512), rand(1, 3), rand(1, 3));
    }
    var tex = new THREE.CanvasTexture(c);
    tex.mapping = THREE.EquirectangularReflectionMapping;
    tex.encoding = THREE.sRGBEncoding;
    tex.needsUpdate = true;
    var pmrem = new THREE.PMREMGenerator(renderer);
    pmrem.compileEquirectangularShader();
    envTarget = pmrem.fromEquirectangular(tex);
    envMap = envTarget.texture;
    pmrem.dispose();
    tex.dispose();
  }

  /* ==========================================================================
     6. Materials
     ========================================================================== */

  var MAT = {};

  function buildMaterials() {
    MAT.chassis = new THREE.MeshStandardMaterial({
      color: 0x0a0d16,
      metalness: 0.92,
      roughness: 0.32,
      envMap: envMap,
      envMapIntensity: 0.8
    });
    MAT.chassisEdge = new THREE.MeshStandardMaterial({
      color: 0x171d2d,
      metalness: 1,
      roughness: 0.2,
      envMap: envMap,
      envMapIntensity: 1.2
    });
    MAT.chrome = new THREE.MeshStandardMaterial({
      color: 0xe9f7ff,
      metalness: 1,
      roughness: 0.14,
      envMap: envMap,
      envMapIntensity: 1.5
    });
    MAT.ball = new THREE.MeshStandardMaterial({
      color: 0xffffff,
      metalness: 1,
      roughness: 0.055,
      envMap: envMap,
      envMapIntensity: 2.1
    });
    MAT.glass = new THREE.MeshPhysicalMaterial({
      color: 0x8fd9ff,
      metalness: 0.15,
      roughness: 0.06,
      transparent: true,
      opacity: 0.055,
      side: THREE.DoubleSide,
      depthWrite: false,
      envMap: envMap,
      envMapIntensity: 0.9
    });
    var playfieldTex = makePlayfieldTexture();
    MAT.playfield = new THREE.MeshStandardMaterial({
      map: playfieldTex,
      emissiveMap: playfieldTex,
      emissive: 0xffffff,
      emissiveIntensity: 0.32,
      metalness: 0.55,
      roughness: 0.52,
      envMap: envMap,
      envMapIntensity: 0.32
    });
    var backglassTex = makeBackglassTexture();
    MAT.backglass = new THREE.MeshStandardMaterial({
      map: backglassTex,
      emissiveMap: backglassTex,
      emissive: 0xffffff,
      emissiveIntensity: 0.82,
      metalness: 0.2,
      roughness: 0.45
    });
    MAT.city = new THREE.MeshBasicMaterial({
      map: makeCityTexture(),
      fog: true
    });
    MAT.grid = new THREE.MeshBasicMaterial({
      map: makeGridTexture(),
      transparent: true,
      opacity: 0.42,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
  }

  function neonMaterial(color, intensity, opacity) {
    var mat = new THREE.MeshStandardMaterial({
      color: 0x090b12,
      emissive: color,
      emissiveIntensity: intensity == null ? 1.7 : intensity,
      metalness: 0.4,
      roughness: 0.35,
      transparent: opacity != null,
      opacity: opacity == null ? 1 : opacity
    });
    mat.toneMapped = false;
    return mat;
  }

  function pureNeon(color, opacity) {
    var mat = new THREE.MeshBasicMaterial({
      color: color,
      transparent: opacity != null,
      opacity: opacity == null ? 1 : opacity,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });
    mat.toneMapped = false;
    return mat;
  }

  /* ==========================================================================
     7. Scene construction
     ========================================================================== */

  var bumperDefs = [
    { x: -1.7, z: -3.4, color: 0x35f0ff, name: "CYAN" },
    { x: 0.0, z: -5.4, color: 0xff3bdc, name: "MAGENTA" },
    { x: 1.7, z: -3.4, color: 0x9d6bff, name: "VIOLET" }
  ];
  var targetPositions = [-3.3, -2.1, -0.9, 0.3];
  var targetZ = 1.45;

  var loopDefs = [
    {
      name: "A",
      color: 0xa855ff,
      points: [
        [-3.85, 0.55, -8.1], [-4.5, 0.9, -6.6], [-4.6, 1.5, -3.1], [-4.35, 1.95, 0.9],
        [-3.7, 1.65, 4.1], [-2.8, 0.95, 6.1], [-2.25, 0.58, 6.75]
      ]
    },
    {
      name: "B",
      color: 0xc46bff,
      points: [
        [0.85, 0.55, -9.0], [2.2, 0.9, -8.25], [3.0, 1.35, -6.1], [3.2, 1.85, -2.5],
        [3.0, 1.7, 1.5], [2.55, 1.1, 4.7], [2.0, 0.6, 6.6]
      ]
    }
  ];

  function buildStage() {
    // City backdrop and neon floor grid (world space)
    var city = new THREE.Mesh(new THREE.PlaneGeometry(85, 42), MAT.city);
    city.position.set(0, 11, -42);
    scene.add(city);

    var grid = new THREE.Mesh(new THREE.PlaneGeometry(110, 110), MAT.grid);
    grid.rotation.x = -Math.PI / 2;
    grid.position.set(0, -4.6, 0);
    scene.add(grid);

    var horizon = new THREE.Mesh(
      new THREE.PlaneGeometry(120, 22),
      new THREE.MeshBasicMaterial({ color: 0x070a16, transparent: true, opacity: 0.55, depthWrite: false })
    );
    horizon.position.set(0, 0.5, -30);
    scene.add(horizon);
  }

  function buildLights() {
    scene.add(new THREE.HemisphereLight(0x5f8cff, 0x090512, 0.55));

    var key = new THREE.DirectionalLight(0xcfe9ff, 1.35);
    key.position.set(10, 24, 14);
    key.target.position.set(0, 0, 2);
    key.castShadow = true;
    key.shadow.mapSize.set(IS_SMALL ? 1024 : 2048, IS_SMALL ? 1024 : 2048);
    key.shadow.camera.left = -15;
    key.shadow.camera.right = 15;
    key.shadow.camera.top = 18;
    key.shadow.camera.bottom = -18;
    key.shadow.camera.near = 1;
    key.shadow.camera.far = 65;
    key.shadow.bias = -0.0007;
    key.shadow.normalBias = 0.03;
    scene.add(key);
    scene.add(key.target);

    var rimCyan = new THREE.PointLight(0x00d8ff, 2.4, 42, 2);
    rimCyan.position.set(-11, 8, -13);
    scene.add(rimCyan);

    var rimMagenta = new THREE.PointLight(0xff00b8, 2.2, 38, 2);
    rimMagenta.position.set(11, 6, 10);
    scene.add(rimMagenta);

    var fill = new THREE.PointLight(0x6b4cff, 1.2, 50, 2);
    fill.position.set(0, 16, -24);
    scene.add(fill);

    var under = new THREE.PointLight(0x00e5ff, 1.4, 24, 2);
    under.position.set(0, -2.5, 8);
    scene.add(under);
  }

  function addMesh(mesh, cast, receive) {
    mesh.castShadow = cast !== false;
    mesh.receiveShadow = receive !== false;
    tableGroup.add(mesh);
    tableMeshes.push(mesh);
    return mesh;
  }

  function buildCabinet() {
    // Main cabinet body
    var baseGeo = new THREE.BoxGeometry(11.35, 1.2, 23.3);
    var base = new THREE.Mesh(baseGeo, MAT.chassis);
    base.position.set(0, -0.62, 0);
    addMesh(base);

    // Under-cabinet trim
    var trim = new THREE.Mesh(new THREE.BoxGeometry(11.6, 0.14, 23.5), MAT.chassisEdge);
    trim.position.set(0, -1.18, 0);
    addMesh(trim);

    // Playfield surface
    var playfield = new THREE.Mesh(new THREE.PlaneGeometry(10, 22), MAT.playfield);
    playfield.rotation.x = -Math.PI / 2;
    playfield.position.set(0, 0.005, 0);
    playfield.receiveShadow = true;
    tableGroup.add(playfield);

    // Side rails
    [-1, 1].forEach(function (side) {
      var rail = new THREE.Mesh(new THREE.BoxGeometry(0.36, 1.05, 22.8), MAT.chassisEdge);
      rail.position.set(side * 5.25, 0.42, 0.1);
      addMesh(rail);

      var stripMat = neonMaterial(side < 0 ? 0x35eaff : 0xff3bdc, 2.6);
      neonStripMaterials.push(stripMat);
      var strip = new THREE.Mesh(new THREE.BoxGeometry(0.055, 0.055, 21.4), stripMat);
      strip.position.set(side * 5.055, 0.96, 0.1);
      addMesh(strip, false, false);

      var lowerGlow = new THREE.Mesh(new THREE.BoxGeometry(0.05, 0.06, 20.4), pureNeon(side < 0 ? 0x00e5ff : 0xff00c8, 0.75));
      lowerGlow.position.set(side * 5.13, -0.08, 0.4);
      tableGroup.add(lowerGlow);
    });

    // Front rail
    var frontRail = new THREE.Mesh(new THREE.BoxGeometry(10.9, 1.1, 0.45), MAT.chassisEdge);
    frontRail.position.set(0, 0.42, 11.15);
    addMesh(frontRail);

    // Top rail
    var topRail = new THREE.Mesh(new THREE.BoxGeometry(10.9, 1.1, 0.45), MAT.chassisEdge);
    topRail.position.set(0, 0.42, -11.15);
    addMesh(topRail);

    // Ball drain warning strip at the front
    var drainGlow = new THREE.Mesh(new THREE.BoxGeometry(3.2, 0.025, 0.06), pureNeon(0xff4d6d, 0.7));
    drainGlow.position.set(0, 0.03, 9.62);
    tableGroup.add(drainGlow);

    // Shooter lane floor accent
    var laneGlow = new THREE.Mesh(new THREE.PlaneGeometry(1.15, 15.4), pureNeon(0x00e5ff, 0.07));
    laneGlow.rotation.x = -Math.PI / 2;
    laneGlow.position.set(4.3, 0.012, 2.5);
    tableGroup.add(laneGlow);

    // Shooter lane neon edge
    var laneEdge = new THREE.Mesh(new THREE.BoxGeometry(0.06, 0.055, 15.0), pureNeon(0x5ff6ff, 0.9));
    laneEdge.position.set(3.62, 1.01, 2.5);
    tableGroup.add(laneEdge);

    // Glass
    var glass = new THREE.Mesh(new THREE.PlaneGeometry(10.2, 21.7), MAT.glass);
    glass.rotation.x = -Math.PI / 2;
    glass.position.set(0, 2.72, 0.1);
    glass.renderOrder = 10;
    tableGroup.add(glass);

    // Glass supports
    [[-4.95, -10.7], [4.95, -10.7], [-4.95, 10.7], [4.95, 10.7]].forEach(function (p) {
      var post = new THREE.Mesh(new THREE.CylinderGeometry(0.055, 0.055, 2.72, 8), MAT.chrome);
      post.position.set(p[0], 1.36, p[1]);
      addMesh(post, false, true);
    });

    // Glass edge glow
    [-5.08, 5.08].forEach(function (x, index) {
      var edge = new THREE.Mesh(new THREE.BoxGeometry(0.035, 0.035, 21.2), pureNeon(index ? 0xff3bdc : 0x35eaff, 0.8));
      edge.position.set(x, 2.72, 0.1);
      tableGroup.add(edge);
    });

    // Legs
    [[-4.55, 9.4], [4.55, 9.4], [-4.55, -9.4], [4.55, -9.4]].forEach(function (p) {
      var leg = new THREE.Mesh(new THREE.CylinderGeometry(0.16, 0.13, 4.2, 10), MAT.chassisEdge);
      leg.position.set(p[0], -2.7, p[1]);
      leg.rotation.z = p[0] < 0 ? 0.05 : -0.05;
      addMesh(leg, true, true);
      var foot = new THREE.Mesh(new THREE.CylinderGeometry(0.28, 0.32, 0.14, 12), MAT.chassisEdge);
      foot.position.set(p[0] * 1.06, -4.8, p[1]);
      addMesh(foot, true, true);
    });

    // Backglass frame and panel
    var backFrame = new THREE.Mesh(new THREE.BoxGeometry(10.9, 5.6, 0.35), MAT.chassisEdge);
    backFrame.position.set(0, 2.8, -12.05);
    addMesh(backFrame);

    var backPanel = new THREE.Mesh(new THREE.PlaneGeometry(10.1, 4.9), MAT.backglass);
    backPanel.position.set(0, 2.85, -11.86);
    tableGroup.add(backPanel);

    var backTop = new THREE.Mesh(new THREE.BoxGeometry(10.3, 0.08, 0.08), pureNeon(0xff3bdc, 0.9));
    backTop.position.set(0, 5.4, -11.84);
    tableGroup.add(backTop);

    var backBottom = new THREE.Mesh(new THREE.BoxGeometry(10.3, 0.05, 0.06), pureNeon(0x35eaff, 0.8));
    backBottom.position.set(0, 0.45, -11.84);
    tableGroup.add(backBottom);

    // Backglass glow
    var bgGlow = makeGlowSprite(0xff2bd6, 7.5, 0.16);
    bgGlow.position.set(0, 3.0, -11.6);
    tableGroup.add(bgGlow);

    // Cabinet underglow strips
    var underCyan = makeGlowSprite(0x00e5ff, 15, 0.12);
    underCyan.position.set(-4.6, -1.4, 7);
    tableGroup.add(underCyan);
    var underMagenta = makeGlowSprite(0xff00c8, 15, 0.12);
    underMagenta.position.set(4.6, -1.4, 7);
    tableGroup.add(underMagenta);
  }

  function buildLaneGuides() {
    // Physical walls
    var wallHalfH = 0.62;
    function wall(hx, hz, x, z, rotY, mat) {
      var shape = new THREE.BoxGeometry(hx * 2, wallHalfH * 2, hz * 2);
      var mesh = new THREE.Mesh(shape, mat || MAT.chassisEdge);
      mesh.position.set(x, wallHalfH, z);
      if (rotY) mesh.rotation.y = rotY;
      addMesh(mesh);
      var body = new CANNON.Body({ mass: 0, material: phys.wall });
      body.addShape(new CANNON.Box(new CANNON.Vec3(hx, wallHalfH, hz)));
      body.position.set(x, wallHalfH, z);
      if (rotY) body.quaternion.setFromAxisAngle(new CANNON.Vec3(0, 1, 0), rotY);
      body.userData = { kind: "wall" };
      world.addBody(body);
      return mesh;
    }

    // Outer side walls
    wall(0.16, 11.0, -5.06, 0, 0);
    wall(0.16, 11.0, 5.06, 0, 0);
    // Top wall
    wall(5.05, 0.16, 0, -10.95, 0);
    // Bottom lane wall
    wall(0.8, 0.12, 4.35, 10.75, 0);

    // Shooter lane divider
    wall(0.12, 7.75, 3.6, 2.55, 0);
    // Lane divider cap
    var cap = new THREE.Mesh(new THREE.CylinderGeometry(0.2, 0.2, 1.24, 10), neonMaterial(0x5ff6ff, 1.5));
    cap.position.set(3.6, 0.62, 10.3);
    addMesh(cap, false, false);

    // Curved launch guide (outer lane wall sweeps the ball to the top-left)
    var guidePoints = [
      [4.95, -5.0], [4.72, -6.8], [4.1, -8.3], [3.0, -9.35], [1.55, -9.78], [-0.1, -9.72]
    ];
    for (var i = 0; i < guidePoints.length - 1; i++) {
      var a = guidePoints[i], b = guidePoints[i + 1];
      var dx = b[0] - a[0], dz = b[1] - a[1];
      var len = Math.sqrt(dx * dx + dz * dz);
      var ang = Math.atan2(-dz, dx);
      wall(len / 2 + 0.04, 0.12, (a[0] + b[0]) / 2, (a[1] + b[1]) / 2, ang, MAT.chassisEdge);
      // neon cap along outer guide
      var strip = new THREE.Mesh(new THREE.BoxGeometry(len + 0.1, 0.04, 0.04), pureNeon(0x5ff6ff, 0.55));
      strip.position.set((a[0] + b[0]) / 2, 1.26, (a[1] + b[1]) / 2);
      strip.rotation.y = ang;
      tableGroup.add(strip);
    }

    // Lower side return guides. These replace the old outlane funnels: a ball
    // coming down the side wall is deflected back toward the flippers instead
    // of being escorted straight to the drain. The rounded end posts keep the
    // guide from forming a sharp pinch point.
    function angledWall(x1, z1, x2, z2, color) {
      var dx = x2 - x1, dz = z2 - z1;
      var len = Math.sqrt(dx * dx + dz * dz);
      var ang = Math.atan2(-dz, dx);
      wall(len / 2, 0.13, (x1 + x2) / 2, (z1 + z2) / 2, ang, MAT.chassisEdge);
      var strip = new THREE.Mesh(new THREE.BoxGeometry(len, 0.045, 0.045), pureNeon(color, 0.8));
      strip.position.set((x1 + x2) / 2, 1.26, (z1 + z2) / 2);
      strip.rotation.y = ang;
      tableGroup.add(strip);
    }

    function returnPost(x, z, color) {
      var post = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.21, 1.15, 12), MAT.chassisEdge);
      post.position.set(x, 0.575, z);
      addMesh(post);
      var ring = new THREE.Mesh(new THREE.TorusGeometry(0.23, 0.04, 8, 18), neonMaterial(color, 1.9));
      ring.rotation.x = Math.PI / 2;
      ring.position.set(x, 1.16, z);
      addMesh(ring, false, false);
      var body = new CANNON.Body({ mass: 0, material: phys.wall });
      addUprightCylinder(body, 0.18, 0.21, 1.15, 12);
      body.position.set(x, 0.575, z);
      body.userData = { kind: "wall" };
      world.addBody(body);
    }

    function returnGuide(points, color) {
      for (var i = 0; i < points.length - 1; i++) {
        var a = points[i], b = points[i + 1];
        angledWall(a[0], a[1], b[0], b[1], color);
      }
      var end = points[points.length - 1];
      returnPost(end[0], end[1], color);
    }

    returnGuide([
      [-4.95, 6.2], [-4.3, 6.5], [-3.65, 6.86], [-3.15, 7.25]
    ], 0xff3bdc);
    returnGuide([
      [3.5, 6.2], [3.22, 6.55], [3.02, 6.92], [2.95, 7.25]
    ], 0x5ff6ff);

    // Seal the narrow outlane beside each flipper. The channel between this
    // rail and the flipper pivot is narrower than a ball, so side drains are
    // eliminated; the only way down is through the centre flipper gap.
    function sideSeal(x, color) {
      wall(0.1, 1.225, x, 8.475, 0, MAT.chassisEdge);
      var strip = new THREE.Mesh(new THREE.BoxGeometry(0.05, 0.045, 2.4), pureNeon(color, 0.72));
      strip.position.set(x, 1.26, 8.475);
      tableGroup.add(strip);
    }
    sideSeal(-3.0, 0xff3bdc);
    sideSeal(3.0, 0x5ff6ff);

    // Shooter lane bottom neon accent
    var laneBottom = new THREE.Mesh(new THREE.BoxGeometry(1.5, 0.06, 0.06), pureNeon(0xff3bdc, 0.8));
    laneBottom.position.set(4.35, 0.55, 10.62);
    tableGroup.add(laneBottom);
  }

  function buildPegs() {
    [[-3.7, 2.7, 0x5ff6ff], [2.2, -1.0, 0xff3bdc], [-1.35, -8.9, 0x9d6bff]].forEach(function (p) {
      var peg = new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.28, 1.15, 10), MAT.chassisEdge);
      peg.position.set(p[0], 0.575, p[1]);
      addMesh(peg);

      var ring = new THREE.Mesh(new THREE.TorusGeometry(0.3, 0.055, 8, 20), neonMaterial(p[2], 1.9));
      ring.rotation.x = Math.PI / 2;
      ring.position.set(p[0], 1.12, p[1]);
      addMesh(ring, false, false);

      var body = new CANNON.Body({ mass: 0, material: phys.wall });
      addUprightCylinder(body, 0.27, 0.3, 1.15, 12);
      body.position.set(p[0], 0.575, p[1]);
      body.userData = { kind: "wall" };
      world.addBody(body);
    });
  }

  /* ==========================================================================
     8. Physics world
     ========================================================================== */

  var world, phys = {};
  var bumpers = [];
  var targets = [];
  var slings = [];
  var loopSensors = [];
  var loops = [];
  var flippers = {};
  var ball = null;
  var plunger = { visual: null, head: null, spring: null, baseZ: 10.42 };
  var targetResetTimer = 0;

  function initPhysics() {
    world = new CANNON.World();
    world.gravity.set(0, -9.82 * Math.cos(TABLE.tilt), 9.82 * Math.sin(TABLE.tilt));
    world.broadphase = new CANNON.SAPBroadphase(world);
    world.solver.iterations = 22;
    world.solver.tolerance = 0.0005;
    world.defaultContactMaterial.friction = 0.08;
    world.defaultContactMaterial.restitution = 0.35;

    phys.ball = new CANNON.Material("ball");
    phys.table = new CANNON.Material("table");
    phys.wall = new CANNON.Material("wall");
    phys.bumper = new CANNON.Material("bumper");
    phys.flipper = new CANNON.Material("flipper");
    phys.target = new CANNON.Material("target");
    phys.sling = new CANNON.Material("sling");

    world.addContactMaterial(new CANNON.ContactMaterial(phys.ball, phys.table, { friction: 0.04, restitution: 0.16 }));
    world.addContactMaterial(new CANNON.ContactMaterial(phys.ball, phys.wall, { friction: 0.0, restitution: 0.8 }));
    world.addContactMaterial(new CANNON.ContactMaterial(phys.ball, phys.bumper, { friction: 0.0, restitution: 0.92 }));
    world.addContactMaterial(new CANNON.ContactMaterial(phys.ball, phys.flipper, { friction: 0.04, restitution: 0.48 }));
    world.addContactMaterial(new CANNON.ContactMaterial(phys.ball, phys.target, { friction: 0.0, restitution: 0.4 }));
    world.addContactMaterial(new CANNON.ContactMaterial(phys.ball, phys.sling, { friction: 0.0, restitution: 0.65 }));

    // Playfield collider (top surface at local y = 0)
    var floorBody = new CANNON.Body({ mass: 0, material: phys.table });
    floorBody.addShape(new CANNON.Box(new CANNON.Vec3(5, 0.3, 11)));
    floorBody.position.set(0, -0.3, 0);
    floorBody.userData = { kind: "table" };
    world.addBody(floorBody);

    // The visual glass top is also a real ceiling. It keeps a hard flipper or
    // bumper pop from launching the ball over the side rails and off the table.
    var ceilingBody = new CANNON.Body({ mass: 0, material: phys.wall });
    ceilingBody.addShape(new CANNON.Box(new CANNON.Vec3(5.1, 0.08, 11.0)));
    ceilingBody.position.set(0, 2.8, 0);
    ceilingBody.userData = { kind: "glass" };
    world.addBody(ceilingBody);

    // Solid physics backstops behind the lower side seals. If a fast ball ever
    // squeezes past a thin wall, these blocks stop it long before the cabinet
    // edge. The right block must stay out of the shooter lane.
    var leftBackstop = new CANNON.Body({ mass: 0, material: phys.wall });
    leftBackstop.addShape(new CANNON.Box(new CANNON.Vec3(0.93, 0.65, 1.225)));
    leftBackstop.position.set(-3.98, 0.65, 8.475);
    leftBackstop.userData = { kind: "wall" };
    world.addBody(leftBackstop);

    var rightBackstop = new CANNON.Body({ mass: 0, material: phys.wall });
    rightBackstop.addShape(new CANNON.Box(new CANNON.Vec3(0.24, 0.65, 1.225)));
    rightBackstop.position.set(3.24, 0.65, 8.475);
    rightBackstop.userData = { kind: "wall" };
    world.addBody(rightBackstop);
  }

  function addStaticBox(hx, hy, hz, x, y, z, material, rotY, userData) {
    var body = new CANNON.Body({ mass: 0, material: material });
    body.addShape(new CANNON.Box(new CANNON.Vec3(hx, hy, hz)));
    body.position.set(x, y, z);
    if (rotY) body.quaternion.setFromAxisAngle(new CANNON.Vec3(0, 1, 0), rotY);
    body.userData = userData || { kind: "wall" };
    world.addBody(body);
    return body;
  }

  // A Cannon.js Cylinder is built along Z. Rotate it so a visual upright post
  // gets a genuinely upright collider.
  function addUprightCylinder(body, radiusTop, radiusBottom, height, segments) {
    var shape = new CANNON.Cylinder(radiusTop, radiusBottom, height, segments || 16);
    var q = new CANNON.Quaternion();
    q.setFromAxisAngle(new CANNON.Vec3(1, 0, 0), -Math.PI / 2);
    body.addShape(shape, new CANNON.Vec3(0, 0, 0), q);
  }

  /* ==========================================================================
     9. Game objects
     ========================================================================== */

  function buildBumpers() {
    bumperDefs.forEach(function (def, index) {
      var group = new THREE.Group();
      group.position.set(def.x, 0, def.z);
      tableGroup.add(group);

      var base = new THREE.Mesh(new THREE.CylinderGeometry(1.02, 1.08, 0.22, 32), MAT.chassisEdge);
      base.position.y = 0.11;
      base.castShadow = true;
      base.receiveShadow = true;
      group.add(base);

      var coreMat = new THREE.MeshStandardMaterial({
        color: 0x101625,
        emissive: def.color,
        emissiveIntensity: 0.9,
        metalness: 0.7,
        roughness: 0.28
      });
      var core = new THREE.Mesh(new THREE.CylinderGeometry(0.64, 0.7, 0.75, 24), coreMat);
      core.position.y = 0.48;
      core.castShadow = true;
      group.add(core);

      var ringMat = neonMaterial(def.color, 2.5);
      var ring = new THREE.Mesh(new THREE.TorusGeometry(0.82, 0.075, 10, 40), ringMat);
      ring.rotation.x = Math.PI / 2;
      ring.position.y = 0.86;
      group.add(ring);

      var capMat = new THREE.MeshBasicMaterial({ color: def.color, toneMapped: false });
      var cap = new THREE.Mesh(new THREE.SphereGeometry(0.31, 24, 16), capMat);
      cap.position.y = 0.92;
      group.add(cap);

      var halo = makeGlowSprite(def.color, 4.4, 0.5);
      halo.position.y = 0.9;
      halo.userData.dynamicGlow = true;
      group.add(halo);

      var light = new THREE.PointLight(def.color, 0.7, 5.5, 2);
      light.position.set(0, 1.8, 0);
      group.add(light);

      var label = makeTextSprite("CORE 0" + (index + 1), def.color, 46);
      label.position.set(0, 2.05, 0.1);
      label.scale.set(1.8, 0.45, 1);
      group.add(label);

      var body = new CANNON.Body({ mass: 0, material: phys.bumper });
      addUprightCylinder(body, 0.9, 0.9, 1.3, 16);
      body.position.set(def.x, 0.65, def.z);
      body.userData = { kind: "bumper", index: index, cooldown: 0 };
      world.addBody(body);

      var bumper = {
        def: def,
        group: group,
        ring: ring,
        ringMat: ringMat,
        core: core,
        coreMat: coreMat,
        cap: cap,
        capMat: capMat,
        halo: halo,
        light: light,
        body: body,
        flash: 0,
        hits: 0,
        cooldown: 0
      };
      bumpers.push(bumper);

      body.addEventListener("collide", function (event) {
        if (event.body !== ball.body) return;
        var impact = 0;
        try { impact = Math.abs(event.contact.getImpactVelocityAlongNormal()); } catch (err) { impact = 2; }
        if (impact < 0.75 || bumper.cooldown > 0 || game.phase !== "play") return;
        hitBumper(bumper, impact);
      });
    });
  }

  function hitBumper(bumper, impact) {
    bumper.cooldown = 0.3;
    var px = ball.body.position.x - bumper.def.x;
    var pz = ball.body.position.z - bumper.def.z;
    var len = Math.sqrt(px * px + pz * pz) || 1;
    px /= len; pz /= len;
    var power = clamp(4.4 + impact * 0.5, 4.6, 7.4);
    // Nudge the ball clear of the bumper skirt before the next solver pass,
    // then send it away with a crisp plasma kick. This prevents repeat scoring
    // when a ball comes to rest against a core.
    var minDist = 1.0 + TABLE.ballR + 0.04;
    if (len < minDist) {
      ball.body.position.x = bumper.def.x + px * minDist;
      ball.body.position.z = bumper.def.z + pz * minDist;
    }
    ball.body.velocity.set(px * power, 0.55, pz * power);
    ball.body.angularVelocity.set(pz * power / TABLE.ballR, 0, -px * power / TABLE.ballR);
    game.bumperHits++;
    bumper.hits++;
    game.combo++;
    addScore(500, true);
    bumper.flash = 1;
    burstSparks(bumper.def.x, 0.75, bumper.def.z, bumper.def.color, 14, 5.2);
    game.shake = Math.max(game.shake, 0.09);
    synth.bumper(bumper.def.index);
    updateHUD(true);
  }

  function buildDropTargets() {
    targetPositions.forEach(function (x, index) {
      var group = new THREE.Group();
      group.position.set(x, 0, targetZ);
      tableGroup.add(group);

      var mat = new THREE.MeshStandardMaterial({
        color: 0x160a19,
        emissive: 0xff2450,
        emissiveIntensity: 0.8,
        metalness: 0.65,
        roughness: 0.32
      });
      var bar = new THREE.Mesh(new THREE.BoxGeometry(0.82, 1.16, 0.22), mat);
      bar.position.y = 0.62;
      bar.castShadow = true;
      group.add(bar);

      var edge = new THREE.Mesh(new THREE.BoxGeometry(0.84, 0.06, 0.24), neonMaterial(0xff4d6d, 2.3));
      edge.position.y = 1.2;
      group.add(edge);

      var face = new THREE.Mesh(new THREE.PlaneGeometry(0.58, 0.34), pureNeon(0xff3bdc, 0.45));
      face.position.set(0, 0.7, 0.121);
      group.add(face);

      var label = makeTextSprite("SEC", 0xff4d6d, 54);
      label.position.set(0, 1.48, 0);
      label.scale.set(0.95, 0.24, 1);
      group.add(label);

      var glow = makeGlowSprite(0xff3bdc, 2.0, 0.26);
      glow.position.set(0, 0.7, 0);
      glow.userData.dynamicGlow = true;
      group.add(glow);

      var body = new CANNON.Body({ mass: 0, material: phys.target });
      body.addShape(new CANNON.Box(new CANNON.Vec3(0.43, 0.58, 0.12)));
      body.position.set(x, 0.62, targetZ);
      body.userData = { kind: "target", index: index };
      world.addBody(body);

      var target = {
        index: index,
        x: x,
        z: targetZ,
        group: group,
        bar: bar,
        mat: mat,
        edge: edge,
        glow: glow,
        body: body,
        down: false,
        sink: 0,
        cooldown: 0
      };
      targets.push(target);

      body.addEventListener("collide", function (event) {
        if (event.body !== ball.body || target.down || game.phase !== "play") return;
        knockTarget(target);
      });
    });
  }

  function knockTarget(target) {
    target.down = true;
    target.cooldown = 0.2;
    target.body.collisionResponse = false;
    target.body.sleep();
    game.targetsDown++;
    game.combo++;
    addScore(900, true);
    target.mat.emissiveIntensity = 3.2;
    burstSparks(target.x, 0.9, target.z, 0xff3bdc, 18, 5.6);
    synth.target();
    game.shake = Math.max(game.shake, 0.07);
    announce("Security node cleared. " + game.targetsDown + " of " + targets.length + ".");

    if (game.targetsDown >= targets.length) {
      game.multiplier = Math.min(8, game.multiplier + 1);
      game.maxMultiplier = Math.max(game.maxMultiplier, game.multiplier);
      game.targetsCleared++;
      addScore(5000, false);
      synth.multiplier(game.multiplier);
      toast("SECURITY LAYER BREACHED · MULTIPLIER ×" + game.multiplier, "magenta", 3200);
      announce("All security nodes cleared. Multiplier " + game.multiplier + ".");
      clearTargetReset();
      targetResetTimer = schedule(resetTargets, 3000);
    } else {
      toast("NODE " + (target.index + 1) + " OFFLINE · " + (targets.length - game.targetsDown) + " REMAIN", "amber", 1600);
    }
    updateHUD(true);
  }

  function resetTargets(silent) {
    // Never re-arm a node on top of a live ball: that is a classic pinball trap.
    if (!silent && game.phase === "play" && ball && !ball.onRail) {
      var bp = ball.body.position;
      for (var i = 0; i < targets.length; i++) {
        if (Math.abs(bp.x - targets[i].x) < 1.05 && Math.abs(bp.z - targetZ) < 1.05 && bp.y < 1.3) {
          clearTargetReset();
          targetResetTimer = schedule(resetTargets, 900);
          return;
        }
      }
    }
    targets.forEach(function (target) {
      target.down = false;
      target.sink = 0;
      target.cooldown = 0;
      target.body.collisionResponse = true;
      target.body.position.set(target.x, 0.62, target.z);
      target.body.velocity.set(0, 0, 0);
      target.body.angularVelocity.set(0, 0, 0);
      target.body.wakeUp();
      target.group.visible = true;
      target.group.position.y = 0;
      target.group.scale.set(1, 1, 1);
      target.mat.emissiveIntensity = 0.8;
      target.glow.material.opacity = 0.26;
    });
    game.targetsDown = 0;
    if (!silent) {
      toast("SECURITY NODES RE-ARMED", "amber", 1500);
      updateHUD(true);
    }
  }

  function clearTargetReset() {
    if (targetResetTimer) {
      window.clearTimeout(targetResetTimer);
      targetResetTimer = 0;
    }
  }

  function buildSlingshots() {
    [-1, 1].forEach(function (side) {
      var x = side * 1.95;
      var z = 5.8;
      var rot = side * 0.68;
      var mat = new THREE.MeshStandardMaterial({
        color: 0x0e1422,
        emissive: 0xff2bd6,
        emissiveIntensity: 0.55,
        metalness: 0.8,
        roughness: 0.28
      });
      var mesh = new THREE.Mesh(new THREE.BoxGeometry(1.4, 1.0, 0.4), mat);
      mesh.position.set(x, 0.55, z);
      mesh.rotation.y = rot;
      addMesh(mesh);
      var strip = new THREE.Mesh(new THREE.BoxGeometry(1.45, 0.055, 0.07), pureNeon(0xff3bdc, 0.9));
      strip.position.set(x, 1.07, z);
      strip.rotation.y = rot;
      tableGroup.add(strip);

      var halo = makeGlowSprite(0xff2bd6, 2.2, 0.2);
      halo.position.set(x, 0.8, z);
      halo.userData.dynamicGlow = true;
      tableGroup.add(halo);

      var sling = {
        side: side,
        body: null,
        mesh: mesh,
        mat: mat,
        strip: strip,
        halo: halo,
        flash: 0,
        cooldown: 0
      };

      var body = addStaticBox(0.68, 0.5, 0.2, x, 0.55, z, phys.sling, rot, { kind: "sling", side: side });
      sling.body = body;
      body.addEventListener("collide", function (event) {
        if (event.body !== ball.body || game.phase !== "play" || sling.cooldown > 0) return;
        var impact = 0;
        try { impact = Math.abs(event.contact.getImpactVelocityAlongNormal()); } catch (err) { impact = 1.4; }
        if (impact < 1.0) return;
        sling.cooldown = 0.25;
        var inward = side === -1 ? 1 : -1;
        var kick = 2.9 + clamp(impact * 0.35, 0, 1.8);
        ball.body.velocity.x = inward * kick + ball.body.velocity.x * 0.15;
        ball.body.velocity.z = -2.7 - clamp(impact * 0.15, 0, 1.2) + ball.body.velocity.z * 0.15;
        ball.body.velocity.y = Math.max(ball.body.velocity.y, 0.28);
        ball.body.angularVelocity.set(ball.body.velocity.z / TABLE.ballR, 0, -ball.body.velocity.x / TABLE.ballR);
        sling.flash = 1;
        game.combo++;
        addScore(120, true);
        synth.sling();
        burstSparks(ball.body.position.x, 0.55, ball.body.position.z, 0xff3bdc, 7, 3.2);
        updateHUD(true);
      });

      slings.push(sling);
    });
  }

  function buildLoops() {
    loopDefs.forEach(function (def, index) {
      var vecs = def.points.map(function (p) { return new THREE.Vector3(p[0], p[1], p[2]); });
      var curve = new THREE.CatmullRomCurve3(vecs, false, "catmullrom", 0.35);
      var tubeMat = new THREE.MeshPhysicalMaterial({
        color: 0x120624,
        emissive: def.color,
        emissiveIntensity: 1.05,
        metalness: 0.18,
        roughness: 0.34,
        transparent: true,
        opacity: 0.38,
        side: THREE.DoubleSide,
        depthWrite: false,
        envMap: envMap,
        envMapIntensity: 0.22
      });
      tubeMat.toneMapped = false;
      var tube = new THREE.Mesh(new THREE.TubeGeometry(curve, 64, 0.52, 10, false), tubeMat);
      tube.renderOrder = 5;
      tableGroup.add(tube);

      // Neon rails along the loop
      var railMat = pureNeon(def.color, 0.9);
      [0.45, -0.45].forEach(function (offset) {
        var railPoints = [];
        for (var i = 0; i <= 32; i++) {
          var t = i / 32;
          var p = curve.getPointAt(t);
          var tangent = curve.getTangentAt(t);
          var normal = new THREE.Vector3(0, 1, 0).cross(tangent);
          if (normal.lengthSq() < 0.001) normal.set(1, 0, 0);
          normal.normalize().multiplyScalar(offset);
          railPoints.push(new THREE.Vector3(p.x + normal.x, p.y + normal.y, p.z + normal.z));
        }
        var railCurve = new THREE.CatmullRomCurve3(railPoints);
        var rail = new THREE.Mesh(new THREE.TubeGeometry(railCurve, 48, 0.018, 5, false), railMat);
        tableGroup.add(rail);
      });

      // Glowing hoop rings
      for (var r = 1; r < 14; r++) {
        var t = r / 14;
        var pos = curve.getPointAt(t);
        var tangent = curve.getTangentAt(t);
        var ring = new THREE.Mesh(new THREE.TorusGeometry(0.55, 0.022, 6, 28), pureNeon(def.color, 0.42));
        ring.position.copy(pos);
        var q = new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 0, 1), tangent.normalize());
        ring.quaternion.copy(q);
        tableGroup.add(ring);
      }

      // Supports
      [0.22, 0.55, 0.82].forEach(function (t) {
        var p = curve.getPointAt(t);
        var support = new THREE.Mesh(new THREE.CylinderGeometry(0.035, 0.035, p.y, 6), pureNeon(def.color, 0.38));
        support.position.set(p.x, p.y / 2, p.z);
        tableGroup.add(support);
      });

      var start = curve.getPointAt(0);
      var end = curve.getPointAt(1);
      var startGlow = makeGlowSprite(def.color, 2.5, 0.5);
      startGlow.position.copy(start);
      tableGroup.add(startGlow);
      var endGlow = makeGlowSprite(def.color, 2.0, 0.34);
      endGlow.position.copy(end);
      tableGroup.add(endGlow);

      var entranceRing = new THREE.Mesh(new THREE.TorusGeometry(0.62, 0.045, 8, 28), neonMaterial(def.color, 2.4));
      entranceRing.rotation.x = Math.PI / 2;
      entranceRing.position.set(start.x, 0.62, start.z);
      tableGroup.add(entranceRing);

      var arrow = makeTextSprite("HYPER-LOOP " + def.name, def.color, 44);
      arrow.position.set(start.x, 1.5, start.z);
      arrow.scale.set(2.2, 0.55, 1);
      tableGroup.add(arrow);

      var sensor = new CANNON.Body({ mass: 0, collisionResponse: false });
      sensor.addShape(new CANNON.Sphere(0.72));
      sensor.position.set(start.x, 0.56, start.z);
      sensor.userData = { kind: "loop", index: index };
      world.addBody(sensor);

      var loop = {
        index: index,
        def: def,
        curve: curve,
        start: start,
        end: end,
        sensor: sensor,
        cooldown: 0,
        flash: 0
      };
      loops.push(loop);
      loopSensors.push(sensor);

      sensor.addEventListener("collide", function (event) {
        if (event.body !== ball.body || game.phase !== "play" || ball.onRail || loop.cooldown > 0) return;
        captureBallInLoop(loop);
      });
    });
  }

  function buildPlunger() {
    var group = new THREE.Group();
    group.position.set(4.3, 0.42, plunger.baseZ);
    tableGroup.add(group);

    var springMat = new THREE.MeshStandardMaterial({
      color: 0x9aa8c4,
      metalness: 1,
      roughness: 0.25,
      envMap: envMap,
      envMapIntensity: 1.1
    });
    var spring = new THREE.Group();
    for (var i = 0; i < 7; i++) {
      var coil = new THREE.Mesh(new THREE.TorusGeometry(0.18, 0.024, 6, 16), springMat);
      coil.rotation.x = Math.PI / 2;
      coil.position.z = i * 0.075;
      spring.add(coil);
    }
    spring.rotation.x = Math.PI / 2;
    spring.position.z = -0.1;
    group.add(spring);

    var head = new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.3, 0.42, 16), MAT.chrome);
    head.rotation.x = Math.PI / 2;
    head.position.z = -0.52;
    head.castShadow = true;
    group.add(head);

    var cap = new THREE.Mesh(new THREE.CylinderGeometry(0.32, 0.32, 0.07, 16), neonMaterial(0xff3bdc, 2.4));
    cap.rotation.x = Math.PI / 2;
    cap.position.z = -0.75;
    group.add(cap);

    var glow = makeGlowSprite(0xff3bdc, 1.4, 0.32);
    glow.position.set(0, 0.2, -0.72);
    group.add(glow);

    plunger.visual = group;
    plunger.head = head;
    plunger.spring = spring;
  }

  function createBall() {
    var geo = new THREE.SphereGeometry(TABLE.ballR, 48, 32);
    var mesh = new THREE.Mesh(geo, MAT.ball);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    mesh.visible = false;
    tableGroup.add(mesh);

    var glow = makeGlowSprite(0xaef7ff, 2.4, 0.68);
    glow.position.set(0, 0, 0);
    glow.userData.dynamicGlow = true;
    mesh.add(glow);

    var trail = [];
    for (var ti = 0; ti < 10; ti++) {
      var tp = makeGlowSprite(0x5ff6ff, 1.15 - ti * 0.07, 0.3 - ti * 0.02);
      tp.visible = false;
      tp.userData.isTrail = true;
      tableGroup.add(tp);
      trail.push(tp);
    }

    var light = new THREE.PointLight(0x9ff6ff, 0.55, 3.2, 2);
    light.position.set(0, 0.5, 0);
    mesh.add(light);

    var body = new CANNON.Body({
      mass: 0.25,
      material: phys.ball,
      linearDamping: 0.015,
      angularDamping: 0.18,
      allowSleep: false
    });
    body.addShape(new CANNON.Sphere(TABLE.ballR));
    body.position.set(4.3, TABLE.ballR + 0.02, 9.35);
    body.collisionResponse = false;
    body.userData = { kind: "ball" };
    world.addBody(body);

    ball = {
      mesh: mesh,
      body: body,
      glow: glow,
      light: light,
      trail: trail,
      history: [],
      onRail: null,
      railT: 0,
      railSpeed: 0,
      lastSound: 0,
      recoveryTimer: 0,
      recoveryAnchor: new THREE.Vector3(4.3, TABLE.ballR, 9.35)
    };

    body.addEventListener("collide", function (event) {
      if (!gameStarted || game.phase === "menu" || game.phase === "over") return;
      if (event.body.userData && event.body.userData.kind === "flipper") {
        return;
      }
      var now = performance.now();
      if (now - ball.lastSound < 55) return;
      var impact = 0;
      try { impact = Math.abs(event.contact.getImpactVelocityAlongNormal()); } catch (err) { impact = 2; }
      if (impact < 1.4) return;
      ball.lastSound = now;
      synth.wall(impact);
      if (impact > 3.5) {
        burstSparks(ball.body.position.x, ball.body.position.y, ball.body.position.z, 0x8fdfff, 3, 2.2);
      }
    });
  }

  function buildFlippers() {
    function makeFlipper(side) {
      var isLeft = side === "left";
      var pivotX = isLeft ? -2.55 : 2.55;
      var pivotZ = 7.6;
      var color = isLeft ? 0x35eaff : 0xff3bdc;
      var group = new THREE.Group();
      group.position.set(pivotX, 0, pivotZ);

      var armMat = new THREE.MeshStandardMaterial({
        color: 0x202838,
        metalness: 0.9,
        roughness: 0.22,
        envMap: envMap,
        envMapIntensity: 1.0
      });
      var arm = new THREE.Mesh(new THREE.BoxGeometry(2.1, 0.32, 0.56), armMat);
      arm.position.set(isLeft ? 1.05 : -1.05, 0.36, 0);
      arm.castShadow = true;
      arm.receiveShadow = true;
      group.add(arm);

      var edge = new THREE.Mesh(new THREE.BoxGeometry(2.08, 0.055, 0.6), pureNeon(color, 0.95));
      edge.position.set(isLeft ? 1.05 : -1.05, 0.19, 0);
      group.add(edge);

      var tip = new THREE.Mesh(new THREE.SphereGeometry(0.28, 16, 12), MAT.chrome);
      tip.position.set(isLeft ? 2.08 : -2.08, 0.36, 0);
      group.add(tip);

      var pivot = new THREE.Mesh(new THREE.CylinderGeometry(0.24, 0.24, 0.52, 16), MAT.chrome);
      pivot.position.y = 0.36;
      group.add(pivot);

      var glow = makeGlowSprite(color, 1.4, 0.22);
      glow.position.set(isLeft ? 1.05 : -1.05, 0.3, 0.3);
      group.add(glow);

      tableGroup.add(group);

      var body = new CANNON.Body({ mass: 0, type: CANNON.Body.KINEMATIC, material: phys.flipper });
      body.addShape(
        new CANNON.Box(new CANNON.Vec3(1.05, 0.17, 0.29)),
        new CANNON.Vec3(isLeft ? 1.05 : -1.05, 0, 0)
      );
      body.position.set(pivotX, 0.36, pivotZ);
      body.userData = { kind: "flipper", side: side };
      world.addBody(body);

      return {
        side: side,
        group: group,
        body: body,
        pivotX: pivotX,
        pivotZ: pivotZ,
        angle: isLeft ? FLIPPER.restLeft : FLIPPER.restRight,
        active: false,
        color: color,
        glow: glow
      };
    }

    flippers.left = makeFlipper("left");
    flippers.right = makeFlipper("right");
    flippers.left.body.quaternion.setFromAxisAngle(new CANNON.Vec3(0, 1, 0), flippers.left.angle);
    flippers.right.body.quaternion.setFromAxisAngle(new CANNON.Vec3(0, 1, 0), flippers.right.angle);
    flippers.left.group.rotation.y = flippers.left.angle;
    flippers.right.group.rotation.y = flippers.right.angle;
  }

  function updateFlippers(dt) {
    ["left", "right"].forEach(function (side) {
      var f = flippers[side];
      if (!f) return;
      var isLeft = side === "left";
      var target = f.active
        ? (isLeft ? FLIPPER.activeLeft : FLIPPER.activeRight)
        : (isLeft ? FLIPPER.restLeft : FLIPPER.restRight);
      var speed = f.active ? FLIPPER.upSpeed : FLIPPER.downSpeed;
      var delta = clamp(target - f.angle, -speed * dt, speed * dt);
      f.angle += delta;
      f.group.rotation.y = f.angle;
      f.body.quaternion.setFromAxisAngle(new CANNON.Vec3(0, 1, 0), f.angle);
      f.body.angularVelocity.set(0, delta / Math.max(dt, 0.0001), 0);
      f.body.aabbNeedsUpdate = true;
      f.glow.material.opacity = f.active ? 0.5 : 0.18;
    });
  }

  function setFlipper(side, active) {
    var f = flippers[side];
    if (!f) return;
    var was = f.active;
    f.active = !!active;
    if (active && !was && (game.phase === "play" || game.phase === "ready")) {
      synth.flipper(side);
    }
    var pad = side === "left" ? dom.flipLeft : dom.flipRight;
    if (pad) pad.classList.toggle("is-active", !!active);
  }

  /* ==========================================================================
     10. Player ball, plunger & loop rail
     ========================================================================== */

  function setBallVisible(visible) {
    if (!ball) return;
    ball.mesh.visible = !!visible;
  }

  function spawnBall() {
    if (!ball) return;
    var b = ball.body;
    b.type = CANNON.Body.DYNAMIC;
    b.mass = 0.25;
    b.updateMassProperties();
    b.collisionResponse = true;
    b.position.set(4.3, TABLE.ballR + 0.03, 9.35);
    b.velocity.set(0, 0, 0);
    b.angularVelocity.set(0, 0, 0);
    b.quaternion.set(0, 0, 0, 1);
    b.force.set(0, 0, 0);
    b.torque.set(0, 0, 0);
    b.wakeUp();
    ball.onRail = null;
    ball.railT = 0;
    ball.recoveryTimer = 0;
    ball.recoveryAnchor.set(b.position.x, b.position.y, b.position.z);
    ball.history.length = 0;
    ball.mesh.position.set(b.position.x, b.position.y, b.position.z);
    setBallVisible(true);
    game.charge = 0;
    game.isCharging = false;
    updateChargeUI();
    setPhase("ready");
    dom.launchHint.innerHTML = "HOLD <b>SPACE</b> TO CHARGE THE RAILGUN";
    dom.launchHint.classList.add("is-urgent");
  }

  function inShooterLane() {
    if (!ball) return false;
    var p = ball.body.position;
    return p.x > 3.62 && p.x < 5.0 && p.z > 5.2 && p.z < 10.7;
  }

  function startCharge() {
    if (!ball || game.phase === "menu" || game.phase === "over" || game.phase === "drain" || game.phase === "paused") return;
    if (!inShooterLane()) {
      if (game.phase === "play") toast("BALL IN PLAY · NO RELOAD", "amber", 1200);
      return;
    }
    if (game.isCharging) return;
    game.isCharging = true;
    game.charge = Math.max(game.charge, 0.04);
    dom.launchBtn.classList.add("is-charging");
    dom.launchHint.classList.remove("is-urgent");
    dom.launchHint.innerHTML = "RELEASE TO FIRE · <b>RAILGUN</b>";
    synth.ensure();
    synth.startCharge();
    updateChargeUI();
  }

  function updateCharge(dt, extra) {
    if (!game.isCharging) return;
    game.charge = clamp(game.charge + dt * 0.72 + (extra || 0), 0, 1);
    synth.setCharge(game.charge);
    updateChargeUI();
  }

  function releaseCharge() {
    if (!game.isCharging) return;
    var power = clamp(game.charge, 0.12, 1);
    game.isCharging = false;
    game.charge = 0;
    dom.launchBtn.classList.remove("is-charging");
    synth.stopCharge();
    updateChargeUI();
    launchBall(power);
  }

  function updateChargeUI() {
    var pct = Math.round(game.charge * 100);
    if (pct === lastChargePct) return;
    lastChargePct = pct;
    dom.chargeFill.style.width = pct + "%";
    dom.chargeLabel.textContent = pct + "%";
    dom.chargeMeter.setAttribute("aria-valuenow", String(pct));
  }

  function launchBall(power) {
    if (!ball || !inShooterLane()) {
      if (game.phase === "play") toast("NO BALL IN THE RAILGUN", "amber", 1400);
      return;
    }
    var impulse = 1.25 + power * 1.55;
    ball.body.wakeUp();
    ball.body.applyImpulse(new CANNON.Vec3(0.025 + Math.random() * 0.02, 0.16, -impulse), new CANNON.Vec3(0, 0, 0));
    ball.body.angularVelocity.set(ball.body.velocity.z / TABLE.ballR, 0, 0);
    synth.launch(power);
    game.shake = Math.max(game.shake, 0.18);
    burstSparks(4.3, 0.45, 10.3, 0x5ff6ff, 16, 4.5);
    if (game.phase === "ready") {
      setPhase("play");
      game.ballStartedAt = game.ballStartedAt || performance.now();
    }
    dom.launchHint.innerHTML = "BALL LIVE · USE <b>Z</b> / <b>/</b> FLIPPERS";
    dom.launchHint.classList.remove("is-urgent");
    game.charge = 0;
    updateChargeUI();
    updateHUD(false);
    announce("Ball launched.");
  }

  function captureBallInLoop(loop) {
    if (!ball || ball.onRail) return;
    ball.onRail = loop;
    ball.railT = 0;
    ball.railSpeed = 1 / clamp(1.05 + loop.index * 0.08, 0.8, 1.6);
    loop.cooldown = 2.2;
    loop.flash = 1;
    var b = ball.body;
    b.type = CANNON.Body.KINEMATIC;
    b.mass = 0;
    b.updateMassProperties();
    b.collisionResponse = false;
    b.velocity.set(0, 0, 0);
    b.angularVelocity.set(0, 0, 0);
    b.wakeUp();
    game.combo++;
    addScore(2500, true);
    game.loops++;
    synth.loop();
    burstSparks(loop.start.x, loop.start.y, loop.start.z, loop.def.color, 16, 3.4);
    game.shake = Math.max(game.shake, 0.12);
    toast("HYPER-LOOP " + loop.def.name + " ENGAGED · +" + formatScore(2500 * game.multiplier), "magenta", 1800);
    announce("Hyper-loop entered.");
    updateHUD(true);
  }

  function updateRail(dt) {
    if (!ball || !ball.onRail) return;
    var loop = ball.onRail;
    ball.railT += dt * ball.railSpeed;
    var t = clamp(ball.railT, 0, 1);
    var p = loop.curve.getPointAt(t);
    ball.body.position.set(p.x, p.y, p.z);
    ball.body.velocity.set(0, 0, 0);
    ball.body.angularVelocity.set(0, 0, 0);
    ball.body.aabbNeedsUpdate = true;
    if (t >= 1) {
      var tangent = loop.curve.getTangentAt(1).normalize();
      var b = ball.body;
      b.type = CANNON.Body.DYNAMIC;
      b.mass = 0.25;
      b.updateMassProperties();
      b.collisionResponse = true;
      b.wakeUp();
      b.position.set(loop.end.x, loop.end.y + 0.02, loop.end.z);
      b.velocity.set(tangent.x * 8.5 + 0.8, 0.25, Math.abs(tangent.z) * 3.5 + 2.4);
      b.angularVelocity.set(0, 0, 0);
      ball.onRail = null;
      ball.railT = 0;
      burstSparks(loop.end.x, loop.end.y, loop.end.z, loop.def.color, 12, 3.0);
      synth.loop();
      toast("LOOP EXIT · +" + formatScore(500 * game.multiplier), "amber", 1400);
      game.combo++;
      addScore(500, true);
      updateHUD(true);
    }
  }

  /* ==========================================================================
     11. Particle effects
     ========================================================================== */

  var sparks = null;

  function initSparks() {
    var count = 240;
    var positions = new Float32Array(count * 3);
    var colors = new Float32Array(count * 3);
    for (var i = 0; i < count; i++) {
      positions[i * 3 + 1] = -999;
    }
    var geo = new THREE.BufferGeometry();
    geo.setAttribute("position", new THREE.BufferAttribute(positions, 3));
    geo.setAttribute("color", new THREE.BufferAttribute(colors, 3));
    var mat = new THREE.PointsMaterial({
      size: 0.11,
      vertexColors: true,
      transparent: true,
      opacity: 0.95,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      sizeAttenuation: true
    });
    mat.toneMapped = false;
    var points = new THREE.Points(geo, mat);
    points.frustumCulled = false;
    tableGroup.add(points);
    sparks = {
      points: points,
      geo: geo,
      positions: positions,
      colors: colors,
      data: [],
      cursor: 0,
      count: count
    };
    for (var j = 0; j < count; j++) {
      sparks.data.push({ active: false, life: 0, maxLife: 0, vx: 0, vy: 0, vz: 0, gravity: 4 });
    }
  }

  function burstSparks(x, y, z, color, count, speed) {
    if (!sparks) return;
    var c = new THREE.Color(color);
    for (var i = 0; i < count; i++) {
      var idx = sparks.cursor;
      sparks.cursor = (sparks.cursor + 1) % sparks.count;
      var d = sparks.data[idx];
      d.active = true;
      d.life = rand(0.28, 0.7);
      d.maxLife = d.life;
      d.vx = rand(-1, 1) * (speed || 4);
      d.vy = rand(0.2, 1.10) * (speed || 4) * 0.55;
      d.vz = rand(-1, 1) * (speed || 4);
      d.gravity = rand(2, 6);
      sparks.positions[idx * 3] = x + rand(-0.1, 0.1);
      sparks.positions[idx * 3 + 1] = y + rand(-0.1, 0.1);
      sparks.positions[idx * 3 + 2] = z + rand(-0.1, 0.1);
      sparks.colors[idx * 3] = c.r * rand(0.8, 1);
      sparks.colors[idx * 3 + 1] = c.g * rand(0.8, 1);
      sparks.colors[idx * 3 + 2] = c.b * rand(0.8, 1);
    }
    sparks.geo.attributes.position.needsUpdate = true;
    sparks.geo.attributes.color.needsUpdate = true;
  }

  function updateSparks(dt) {
    if (!sparks) return;
    var changed = false;
    var changedColor = false;
    for (var i = 0; i < sparks.count; i++) {
      var d = sparks.data[i];
      if (!d.active) continue;
      changed = true;
      d.life -= dt;
      if (d.life <= 0) {
        d.active = false;
        sparks.positions[i * 3 + 1] = -999;
        continue;
      }
      d.vy -= d.gravity * dt;
      sparks.positions[i * 3] += d.vx * dt;
      sparks.positions[i * 3 + 1] += d.vy * dt;
      sparks.positions[i * 3 + 2] += d.vz * dt;
      var fade = d.life / d.maxLife;
      sparks.colors[i * 3] *= 0.992;
      sparks.colors[i * 3 + 1] *= 0.992;
      sparks.colors[i * 3 + 2] *= 0.992;
      if (fade < 0.35) {
        sparks.colors[i * 3] *= 0.96;
        sparks.colors[i * 3 + 1] *= 0.96;
        sparks.colors[i * 3 + 2] *= 0.96;
        changedColor = true;
      }
    }
    if (changed) {
      sparks.geo.attributes.position.needsUpdate = true;
      sparks.geo.attributes.color.needsUpdate = true;
    }
    if (changedColor) sparks.geo.attributes.color.needsUpdate = true;
  }

  /* ==========================================================================
     12. Game state & flow
     ========================================================================== */

  var game = {
    phase: "menu",
    score: 0,
    multiplier: 1,
    maxMultiplier: 1,
    ballsLeft: 3,
    combo: 0,
    targetsDown: 0,
    targetsCleared: 0,
    loops: 0,
    bumperHits: 0,
    charge: 0,
    isCharging: false,
    startedAt: 0,
    ballStartedAt: 0,
    endedAt: 0,
    paused: false,
    shake: 0,
    extraBallAwarded: false,
    callsign: sanitizeName(safeStorageGet(STORAGE.callsign, "RUNNER-01")),
    archiveId: "",
    timeouts: []
  };
  var gameStarted = false;

  function schedule(fn, ms) {
    var id = window.setTimeout(function () {
      var idx = game.timeouts.indexOf(id);
      if (idx >= 0) game.timeouts.splice(idx, 1);
      fn();
    }, ms);
    game.timeouts.push(id);
    return id;
  }

  function clearScheduled() {
    game.timeouts.forEach(function (id) { window.clearTimeout(id); });
    game.timeouts = [];
    clearTargetReset();
  }

  function setPhase(phase) {
    game.phase = phase;
    updateHUD(false);
    if (phase === "ready") {
      dom.status.textContent = "BALL READY";
      dom.status.classList.add("is-live");
    }
  }

  function startGame() {
    synth.ensure();
    synth.startAmbient();
    synth.setAmbientLevel(1);
    clearScheduled();
    synth.stopCharge();
    gameStarted = true;
    game.score = 0;
    game.multiplier = 1;
    game.maxMultiplier = 1;
    game.ballsLeft = 3;
    game.combo = 0;
    game.targetsDown = 0;
    game.targetsCleared = 0;
    game.loops = 0;
    game.bumperHits = 0;
    game.charge = 0;
    game.isCharging = false;
    game.startedAt = Date.now();
    game.ballStartedAt = 0;
    game.endedAt = 0;
    game.paused = false;
    game.archiveId = "";
    game.shake = 0;
    game.extraBallAwarded = false;

    resetTargets(true);
    loops.forEach(function (loop) { loop.cooldown = 0; });
    bumpers.forEach(function (b) { b.cooldown = 0; b.flash = 0; });
    slings.forEach(function (s) { s.cooldown = 0; s.flash = 0; });
    setFlipper("left", false);
    setFlipper("right", false);

    dom.gameoverOverlay.hidden = true;
    dom.startOverlay.classList.add("is-leaving");
    window.setTimeout(function () {
      dom.startOverlay.hidden = true;
      dom.startOverlay.classList.remove("is-leaving");
    }, 680);
    dom.hud.classList.add("is-live");

    spawnBall();
    dom.launchBtn.classList.remove("is-charging");
    lastScoreText = "";
    lastMultiplierText = "";
    lastBallsText = "";
    updateHUD(false);
    announce("Table initialised. Hold space to charge the railgun.");
    toast("TABLE ONLINE · HOLD SPACE TO LAUNCH", "magenta", 2600);
    window.setTimeout(function () { if (dom.callsign) dom.callsign.blur(); }, 30);
  }

  function loseBall() {
    if (game.phase !== "play" || !ball) return;
    game.phase = "drain";
    game.ballsLeft = Math.max(0, game.ballsLeft - 1);
    game.combo = 0;
    game.multiplier = 1;
    clearTargetReset();
    game.charge = 0;
    game.isCharging = false;
    synth.stopCharge();
    dom.launchBtn.classList.remove("is-charging");
    ball.body.collisionResponse = false;
    ball.body.type = CANNON.Body.STATIC;
    ball.body.updateMassProperties();
    ball.body.velocity.set(0, 0, 0);
    setBallVisible(false);
    synth.drain();
    game.shake = Math.max(game.shake, 0.35);
    burstSparks(0, 0.5, 9.6, 0xff4d6d, 26, 6);
    updateHUD(true);
    setPhase("drain");
    dom.launchHint.innerHTML = "BALL LOST · <b>RE-INITIALISING</b>";
    dom.launchHint.classList.add("is-urgent");
    announce("Ball lost. " + game.ballsLeft + " remaining.");

    if (game.ballsLeft <= 0) {
      schedule(endGame, 1200);
    } else {
      toast("BALL LOST · " + game.ballsLeft + " REMAINING", "danger", 1900);
      schedule(function () {
        clearTargetReset();
        resetTargets(true);
        spawnBall();
        toast("BALL " + (4 - game.ballsLeft) + " READY", "amber", 1600);
      }, 1450);
    }
  }

  function endGame() {
    if (game.phase === "over") return;
    game.phase = "over";
    game.endedAt = Date.now();
    clearScheduled();
    game.isCharging = false;
    synth.stopCharge();
    dom.launchBtn.classList.remove("is-charging");
    setBallVisible(false);
    synth.gameOver();
    synth.setAmbientLevel(0.28);
    setFlipper("left", false);
    setFlipper("right", false);

    var entry = null;
    var previousBest = scoreStore.best;
    if (game.score > 0) {
      entry = scoreStore.add({
        name: game.callsign,
        score: game.score,
        date: new Date().toISOString(),
        maxMultiplier: game.maxMultiplier,
        loops: game.loops,
        targets: game.targetsCleared
      });
      if (entry) {
        game.archiveId = entry.id;
        if (game.score > previousBest) toast("NEW HIGH SCORE · " + formatScore(game.score), "amber", 4200);
      }
    }
    updateHUD(false);

    dom.finalScore.textContent = formatScore(game.score);
    var rank = scoreStore.entries.findIndex(function (e) { return e.id === game.archiveId; });
    dom.finalRank.textContent = rank >= 0 ? "ARCHIVE RANK #" + (rank + 1) : "UNRANKED";
    dom.finalMult.textContent = "×" + game.maxMultiplier;
    dom.finalTargets.textContent = String(game.targetsCleared);
    dom.finalLoops.textContent = String(game.loops);
    var elapsed = game.startedAt ? (Date.now() - game.startedAt) : 0;
    dom.finalTime.textContent = formatTime(elapsed);
    dom.gameoverNote.textContent = game.score > 0
      ? "Score archived to local memory. Export the ledger from the right panel."
      : "No score recorded. The grid remembers nothing.";
    dom.gameoverOverlay.hidden = false;
    dom.playAgain.focus();
    announce("Game over. Final score " + formatScore(game.score) + ".");
    updateHUD(false);
  }

  function requestNewGame() {
    if (game.phase === "play" || game.phase === "ready" || game.phase === "drain") {
      if (game.score > 0) {
        dom.confirmOverlay.hidden = false;
        dom.confirmOk.focus();
      } else {
        startGame();
      }
    } else {
      startGame();
    }
  }

  function abandonAndRestart() {
    dom.confirmOverlay.hidden = true;
    if (game.score > 0) {
      scoreStore.add({
        name: game.callsign,
        score: game.score,
        date: new Date().toISOString(),
        maxMultiplier: game.maxMultiplier,
        loops: game.loops,
        targets: game.targetsCleared
      });
      scoreStore.save();
      updateHUD(false);
    }
    startGame();
  }

  function addScore(base, animate) {
    var gain = Math.max(0, Math.round(base * game.multiplier));
    game.score += gain;
    if (!game.extraBallAwarded && game.score >= 100000 && game.phase === "play") {
      game.extraBallAwarded = true;
      game.ballsLeft++;
      synth.extraBall();
      toast("EXTRA BALL EARNED · 100,000 POINTS", "amber", 3800);
      announce("Extra ball earned.");
    }
    if (animate) updateHUD(true);
    return gain;
  }

  /* ==========================================================================
     13. Simulation loop
     ========================================================================== */

  function updateBallRecovery(dt) {
    if (!ball || game.phase !== "play") {
      if (ball) ball.recoveryTimer = 0;
      return;
    }
    if (ball.onRail || inShooterLane()) {
      ball.recoveryTimer = 0;
      return;
    }
    // Do not interrupt a deliberate cradle while a flipper is held up.
    if (flippers.left.active || flippers.right.active) {
      ball.recoveryTimer = 0;
      return;
    }
    var p = ball.body.position;
    var dx = p.x - ball.recoveryAnchor.x;
    var dz = p.z - ball.recoveryAnchor.z;
    if (dx * dx + dz * dz > 0.64) {
      ball.recoveryAnchor.set(p.x, p.y, p.z);
      ball.recoveryTimer = 0;
      return;
    }
    ball.recoveryTimer += dt;
    if (ball.recoveryTimer >= 3.5) {
      recoverBall("auto");
    }
  }

  function recoverBall(source) {
    source = source || "manual";
    if (!ball) return false;
    if (game.phase === "ready") {
      if (source === "manual") toast("BALL ALREADY IN THE RAILGUN", "amber", 1700);
      return false;
    }
    if (game.phase !== "play") {
      if (source === "manual") toast("NO ACTIVE BALL TO RECOVER", "amber", 1700);
      return false;
    }

    var p = ball.body.position;
    burstSparks(p.x, p.y + 0.2, p.z, 0x5ff6ff, 20, 4.0);
    game.isCharging = false;
    game.charge = 0;
    game.pointerId = null;
    game.pointerBoost = 0;
    synth.stopCharge();
    dom.launchBtn.classList.remove("is-charging");
    synth.ensure();
    synth.tone({ freq: 220, endFreq: 880, type: "triangle", dur: 0.34, gain: 0.1 });
    synth.tone({ freq: 110, endFreq: 55, type: "sine", dur: 0.24, gain: 0.08 });
    ball.onRail = null;
    ball.recoveryTimer = 0;
    ball.history.length = 0;
    spawnBall();
    game.shake = Math.max(game.shake, 0.2);
    toast(source === "auto" ? "BALL RECOVERED · TRAP CLEARED · RELAUNCH" : "BALL RECOVERED · RELAUNCH", "amber", 3000);
    announce("Ball recovered to the shooter lane. Relaunch when ready.");
    updateHUD(false);
    return true;
  }

  var accumulator = 0;
  var lastFrame = performance.now();
  var lastHudUpdate = 0;

  function fixedUpdate(dt) {
    if (!world) return;
    if (game.paused) return;

    updateFlippers(dt);

    if (game.isCharging) updateCharge(dt);

    bumpers.forEach(function (b) {
      if (b.cooldown > 0) b.cooldown -= dt;
      if (b.flash > 0) b.flash = Math.max(0, b.flash - dt * 4.2);
    });
    targets.forEach(function (t) {
      if (t.cooldown > 0) t.cooldown -= dt;
    });
    slings.forEach(function (s) {
      if (s.cooldown > 0) s.cooldown -= dt;
      if (s.flash > 0) s.flash = Math.max(0, s.flash - dt * 5);
    });
    loops.forEach(function (l) {
      if (l.cooldown > 0) l.cooldown -= dt;
      if (l.flash > 0) l.flash = Math.max(0, l.flash - dt * 3);
    });

    updateRail(dt);

    if (ball && ball.onRail) {
      // Rail movement is kinematic; skip solver side effects but keep the
      // rendered ball glued to its body along the loop.
      world.step(dt);
      ball.mesh.position.set(ball.body.position.x, ball.body.position.y, ball.body.position.z);
      var rq = ball.body.quaternion;
      ball.mesh.quaternion.set(rq.x, rq.y, rq.z, rq.w);
      return;
    }

    // Clamp before integration as well as after it, so a very fast flipper
    // impulse cannot carry the ball through a collider in a single step.
    if (ball && ball.body.type === CANNON.Body.DYNAMIC && game.phase === "play") {
      var preSpeed = ball.body.velocity.length();
      if (preSpeed > 22) ball.body.velocity.scale(22 / preSpeed, ball.body.velocity);
    }

    world.step(dt);

    if (ball && game.phase === "play") {
      var p = ball.body.position;
      var v = ball.body.velocity;

      // Hard cabinet boundary. This catches any fast ball that squeezes
      // through a thin collider before it can visibly leave the table.
      var minX = -4.58, maxX = 4.58, minZ = -10.45;
      var bounced = false;
      if (p.x < minX) {
        p.x = minX;
        if (v.x < 0) v.x = Math.abs(v.x) * 0.65;
        bounced = true;
      } else if (p.x > maxX) {
        p.x = maxX;
        if (v.x > 0) v.x = -Math.abs(v.x) * 0.65;
        bounced = true;
      }
      if (p.z < minZ) {
        p.z = minZ;
        if (v.z < 0) v.z = Math.abs(v.z) * 0.65;
        bounced = true;
      }
      if (bounced) {
        ball.body.aabbNeedsUpdate = true;
        burstSparks(p.x, p.y + 0.1, p.z, 0x8fdfff, 6, 2.4);
      }

      // Hard speed clamp prevents tunnelling at 120 Hz.
      var speed = v.length();
      if (speed > 22) v.scale(22 / speed, v);

      var outside = p.y < -2.5 || Math.abs(p.x) > 6.4 || p.z > 12.4 || p.z < -12.4;
      var inDrain = p.x < 3.55 && p.z > 9.7 && p.y < 1.6;
      if (inDrain) {
        loseBall();
      } else if (outside) {
        // A ball that leaves the cabinet through a seam or over the top is a
        // table fault, not a drain. Put it back in the railgun without charge.
        recoverBall("auto");
      } else {
        updateBallRecovery(dt);
      }
    }

    // Sync visual ball
    if (ball) {
      ball.mesh.position.set(ball.body.position.x, ball.body.position.y, ball.body.position.z);
      var q = ball.body.quaternion;
      ball.mesh.quaternion.set(q.x, q.y, q.z, q.w);
    }
  }

  var frameCounter = 0;
  function animate(now) {
    requestAnimationFrame(animate);
    var dt = Math.min(0.05, (now - lastFrame) / 1000);
    lastFrame = now;
    if (!sceneReady) return;

    accumulator += dt;
    var steps = 0;
    while (accumulator >= FIXED_STEP && steps < 6) {
      fixedUpdate(FIXED_STEP);
      accumulator -= FIXED_STEP;
      steps++;
    }
    if (steps === 6) accumulator = 0;

    updateVisuals(dt, now);
    renderer.render(scene, camera);
  }

  function updateVisuals(dt, now) {
    var t = now * 0.001;

    updateSparks(dt);

    // Bumpers
    bumpers.forEach(function (b, i) {
      var pulse = 1 + b.flash * 0.16 + Math.sin(t * 2.2 + i * 2) * 0.012;
      b.ring.scale.setScalar(pulse);
      b.core.scale.setScalar(1 + b.flash * 0.08);
      b.coreMat.emissiveIntensity = 0.9 + b.flash * 3.4 + Math.sin(t * 2 + i) * 0.12;
      b.ringMat.emissiveIntensity = 2.4 + b.flash * 5.5;
      b.light.intensity = 0.55 + b.flash * 8 + Math.sin(t * 3 + i) * 0.05;
      b.halo.material.opacity = 0.42 + b.flash * 0.55;
      b.halo.scale.setScalar(4.4 + b.flash * 1.4);
      b.capMat.color.setHex(b.def.color);
    });

    // Targets
    targets.forEach(function (target) {
      if (target.down) {
        target.sink = Math.min(1, target.sink + dt * 6);
        target.group.position.y = -target.sink * 1.05;
        target.group.scale.y = 1 - target.sink * 0.4;
        target.glow.material.opacity = Math.max(0, 0.26 * (1 - target.sink));
      } else {
        target.group.position.y = 0;
        target.group.scale.set(1, 1, 1);
        target.mat.emissiveIntensity = 0.8 + Math.sin(t * 3 + target.index) * 0.15;
        target.glow.material.opacity = 0.24 + Math.sin(t * 4 + target.index) * 0.05;
      }
    });

    // Slingshots
    slings.forEach(function (s, i) {
      s.mat.emissiveIntensity = 0.55 + s.flash * 1.6 + Math.sin(t * 2.4 + i) * 0.08;
      s.strip.material.opacity = 0.75 + s.flash * 0.25;
      s.halo.material.opacity = 0.2 + s.flash * 0.4;
      s.flash = Math.max(0, s.flash - dt * 6);
    });

    // Loop pulses
    loops.forEach(function (loop, i) {
      if (loop.flash > 0) loop.flash = Math.max(0, loop.flash - dt * 2.4);
    });

    // Neon strips breathe
    neonStripMaterials.forEach(function (mat, i) {
      mat.emissiveIntensity = 2.3 + Math.sin(t * 1.5 + i * 1.7) * 0.35;
    });

    // Ball glow
    if (ball && ball.mesh.visible) {
      ball.glow.material.opacity = 0.6 + Math.sin(t * 6) * 0.06;
      ball.light.intensity = 0.6 + Math.sin(t * 4) * 0.06;

      var bp = ball.mesh.position;
      var bspeed = ball.body.velocity.length();
      ball.history.unshift({ x: bp.x, y: bp.y, z: bp.z });
      if (ball.history.length > 14) ball.history.pop();
      for (var ti = 0; ti < ball.trail.length; ti++) {
        var ts = ball.trail[ti];
        var hp = ball.history[Math.min(ball.history.length - 1, Math.floor(ti * 1.1))];
        if (hp && bspeed > 1.6 && game.phase !== "menu") {
          ts.visible = true;
          ts.position.set(hp.x, hp.y, hp.z);
          ts.material.opacity = (0.2 - ti * 0.014) * clamp(bspeed / 8, 0.35, 1);
        } else {
          ts.visible = false;
        }
      }
    } else if (ball) {
      for (var tj = 0; tj < ball.trail.length; tj++) ball.trail[tj].visible = false;
    }

    // Plunger spring compression
    if (plunger.visual) {
      var charge = game.isCharging ? game.charge : 0;
      plunger.visual.position.z = plunger.baseZ + charge * 0.42;
      plunger.spring.scale.y = 1 - charge * 0.3;
    }

    // Floating glows
    for (var i = 0; i < glowSprites.length; i++) {
      var g = glowSprites[i];
      if (!g || !g.sprite.material) continue;
      if (g.sprite.userData && (g.sprite.userData.isTrail || g.sprite.userData.dynamicGlow)) continue;
      g.sprite.material.opacity = g.base * (0.85 + Math.sin(t * 1.3 + g.phase) * 0.15);
    }

    // Camera: gentle parallax + shake
    mouseSmooth.x = lerp(mouseSmooth.x, mouseTarget.x, 0.045);
    mouseSmooth.y = lerp(mouseSmooth.y, mouseTarget.y, 0.045);
    var shake = game.shake;
    if (shake > 0) game.shake = Math.max(0, shake - dt * 1.8);
    var sx = Math.sin(now * 0.071) * shake * 0.35;
    var sy = Math.cos(now * 0.083) * shake * 0.28;
    camera.position.x = cameraBase.x + mouseSmooth.x * 0.8 + sx;
    camera.position.y = cameraBase.y + mouseSmooth.y * 0.35 + sy;
    camera.position.z = cameraBase.z;
    camera.lookAt(0, cameraBase.lookY + mouseSmooth.y * 0.08, cameraBase.lookZ);
  }

  /* ==========================================================================
     14. Score archive export / import
     ========================================================================== */

  function exportScores() {
    var payload = {
      app: "NEON HORIZON 2088",
      version: VERSION,
      exportedAt: new Date().toISOString(),
      highScore: Math.max(scoreStore.best, game.score),
      scores: scoreStore.entries,
      currentSession: game.score > 0 ? {
        callsign: game.callsign,
        score: game.score,
        multiplier: game.multiplier,
        maxMultiplier: game.maxMultiplier,
        loops: game.loops,
        targets: game.targetsCleared
      } : null,
      credits: {
        harness: "OpenCode",
        model: "DeepSeek V4.1 Flash",
        engines: ["Three.js r128", "Cannon.js 0.6.2"]
      }
    };
    try {
      var blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
      var url = URL.createObjectURL(blob);
      var a = document.createElement("a");
      a.href = url;
      a.download = "neon_horizon_scores.json";
      a.rel = "noopener";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      window.setTimeout(function () { URL.revokeObjectURL(url); }, 2500);
      dom.syncStatus.textContent = "ARCHIVE EXPORTED";
      toast("SCORE ARCHIVE EXPORTED · " + scoreStore.entries.length + " RECORDS", "magenta", 2800);
      if (game.phase === "over") dom.gameoverNote.textContent = "Archive downloaded as neon_horizon_scores.json.";
      announce("Score archive exported.");
    } catch (err) {
      toast("EXPORT FAILED · STORAGE PERMISSION", "danger", 3000);
    }
  }

  function importScoresFile(file) {
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) {
      toast("IMPORT REJECTED · FILE TOO LARGE", "danger", 3000);
      return;
    }
    var reader = new FileReader();
    reader.onload = function () {
      try {
        var parsed = JSON.parse(String(reader.result || ""));
        var list = null;
        if (Array.isArray(parsed)) list = parsed;
        else if (parsed && Array.isArray(parsed.scores)) list = parsed.scores;
        else if (parsed && Array.isArray(parsed.leaderboard)) list = parsed.leaderboard;
        if (!list) throw new Error("No scores array found");
        var valid = list.map(sanitizeScoreEntry).filter(Boolean);
        if (!valid.length) throw new Error("No valid score entries");
        var beforeBest = scoreStore.best;
        scoreStore.merge(valid);
        updateHUD(false);
        var added = scoreStore.entries.length;
        dom.syncStatus.textContent = "ARCHIVE SYNCED";
        toast("SCORES SYNCED · " + valid.length + " ENTRIES · BEST " + formatScore(scoreStore.best), "magenta", 3600);
        if (scoreStore.best > beforeBest) toast("NEW ALL-TIME HIGH SCORE · " + formatScore(scoreStore.best), "amber", 3800);
        announce("Imported " + valid.length + " scores. Archive now holds " + added + " records.");
      } catch (err) {
        toast("IMPORT FAILED · INVALID ARCHIVE", "danger", 3200);
      }
    };
    reader.onerror = function () {
      toast("IMPORT FAILED · FILE UNREADABLE", "danger", 3000);
    };
    reader.readAsText(file);
    dom.scoreFile.value = "";
  }

  /* ==========================================================================
     15. UI wiring & input
     ========================================================================== */

  var pointerSides = {};

  function bindUI() {
    if (dom.callsign) {
      dom.callsign.value = game.callsign;
      dom.callsign.addEventListener("input", function () {
        dom.callsign.value = dom.callsign.value.toUpperCase().replace(/[^A-Z0-9 _-]/g, "").slice(0, 14);
      });
    }

    if (dom.startForm) {
      dom.startForm.addEventListener("submit", function (event) {
        event.preventDefault();
        game.callsign = sanitizeName(dom.callsign ? dom.callsign.value : game.callsign);
        safeStorageSet(STORAGE.callsign, game.callsign);
        startGame();
      });
    }

    dom.newGame.addEventListener("click", requestNewGame);
    dom.playAgain.addEventListener("click", startGame);
    dom.gameoverSave.addEventListener("click", exportScores);
    dom.saveScores.addEventListener("click", exportScores);
    dom.loadScores.addEventListener("click", function () { dom.scoreFile.click(); });
    if (dom.rescueBall) {
      dom.rescueBall.addEventListener("click", function () { recoverBall("manual"); });
    }
    dom.scoreFile.addEventListener("change", function () {
      importScoresFile(dom.scoreFile.files && dom.scoreFile.files[0]);
    });

    dom.soundToggle.addEventListener("click", toggleSound);
    dom.soundGlyph.textContent = synth.muted ? "◌" : "◉";
    dom.soundToggle.classList.toggle("is-muted", synth.muted);

    dom.launchBtn.addEventListener("pointerdown", function (event) {
      event.preventDefault();
      if (!gameStarted) return;
      startCharge();
      if (dom.launchBtn.setPointerCapture) {
        try { dom.launchBtn.setPointerCapture(event.pointerId); } catch (err) {}
      }
      game.pointerStartY = event.clientY;
      game.pointerBoost = 0;
      game.pointerId = event.pointerId;
      dom.launchBtn.classList.add("is-charging");
    });
    dom.launchBtn.addEventListener("pointermove", function (event) {
      if (!game.isCharging || event.pointerId !== game.pointerId) return;
      var dy = game.pointerStartY - event.clientY;
      var boost = clamp(dy / 260, 0, 0.6);
      if (boost > game.pointerBoost) {
        game.charge = clamp(game.charge + (boost - game.pointerBoost), 0, 1);
        game.pointerBoost = boost;
        updateChargeUI();
      }
    });
    function endLaunchPointer(event) {
      if (event && game.pointerId != null && event.pointerId !== game.pointerId) return;
      game.pointerId = null;
      if (game.isCharging) releaseCharge();
    }
    dom.launchBtn.addEventListener("pointerup", endLaunchPointer);
    dom.launchBtn.addEventListener("pointercancel", endLaunchPointer);
    dom.launchBtn.addEventListener("lostpointercapture", endLaunchPointer);

    ["left", "right"].forEach(function (side) {
      var pad = side === "left" ? dom.flipLeft : dom.flipRight;
      if (!pad) return;
      pad.addEventListener("pointerdown", function (event) {
        event.preventDefault();
        if (game.phase === "paused") return;
        setFlipper(side, true);
        if (pad.setPointerCapture) {
          try { pad.setPointerCapture(event.pointerId); } catch (err) {}
        }
      });
      var release = function (event) {
        if (event && event.preventDefault) event.preventDefault();
        setFlipper(side, false);
      };
      pad.addEventListener("pointerup", release);
      pad.addEventListener("pointercancel", release);
      pad.addEventListener("pointerleave", function (event) {
        if (event.pointerType === "mouse") setFlipper(side, false);
      });
      pad.addEventListener("contextmenu", function (event) { event.preventDefault(); });
    });

    // Tap halves of the canvas for flippers
    dom.canvas.addEventListener("pointerdown", function (event) {
      if (!gameStarted || game.phase === "over" || game.phase === "paused") return;
      if (event.pointerType === "mouse" && event.button !== 0) return;
      var side = event.clientX < window.innerWidth / 2 ? "left" : "right";
      pointerSides[event.pointerId] = side;
      setFlipper(side, true);
    });
    function releaseCanvasPointer(event) {
      var side = pointerSides[event.pointerId];
      if (side) {
        setFlipper(side, false);
        delete pointerSides[event.pointerId];
      }
    }
    dom.canvas.addEventListener("pointerup", releaseCanvasPointer);
    dom.canvas.addEventListener("pointercancel", releaseCanvasPointer);
    dom.canvas.addEventListener("pointerleave", releaseCanvasPointer);
    dom.canvas.addEventListener("contextmenu", function (event) { event.preventDefault(); });

    dom.canvas.addEventListener("pointermove", function (event) {
      if (event.pointerType && event.pointerType !== "mouse") return;
      mouseTarget.x = (event.clientX / window.innerWidth - 0.5) * 2;
      mouseTarget.y = -(event.clientY / window.innerHeight - 0.5) * 2;
    });
    window.addEventListener("pointerleave", function () {
      mouseTarget.x = 0;
      mouseTarget.y = 0;
    });

    dom.helpBtn.addEventListener("click", openHelp);
    dom.helpClose.addEventListener("click", closeHelp);
    dom.helpResume.addEventListener("click", closeHelp);
    dom.helpStart.addEventListener("click", function () {
      closeHelp();
      startGame();
    });
    dom.helpOverlay.addEventListener("click", function (event) {
      if (event.target === dom.helpOverlay || event.target.classList.contains("overlay__backdrop")) closeHelp();
    });

    dom.confirmCancel.addEventListener("click", function () {
      dom.confirmOverlay.hidden = true;
    });
    dom.confirmOk.addEventListener("click", abandonAndRestart);
    dom.confirmOverlay.addEventListener("click", function (event) {
      if (event.target === dom.confirmOverlay || event.target.classList.contains("overlay__backdrop")) {
        dom.confirmOverlay.hidden = true;
      }
    });

    dom.scoresToggle.addEventListener("click", function () {
      var open = dom.scoresPanel.classList.toggle("is-open");
      dom.scoresToggle.setAttribute("aria-expanded", open ? "true" : "false");
    });

    if (dom.fullscreen) {
      dom.fullscreen.addEventListener("click", function () {
        if (!document.fullscreenElement) {
          document.documentElement.requestFullscreen && document.documentElement.requestFullscreen().catch(function () {});
        } else if (document.exitFullscreen) {
          document.exitFullscreen().catch(function () {});
        }
      });
    }

    window.addEventListener("keydown", onKeyDown, { passive: false });
    window.addEventListener("keyup", onKeyUp, { passive: false });
    window.addEventListener("blur", function () {
      setFlipper("left", false);
      setFlipper("right", false);
      if (game.isCharging) releaseCharge();
    });
    document.addEventListener("visibilitychange", function () {
      if (document.hidden) {
        setFlipper("left", false);
        setFlipper("right", false);
        if (game.isCharging) releaseCharge();
        synth.setAmbientLevel(0.15);
      } else {
        synth.setAmbientLevel(game.phase === "over" ? 0.28 : 1);
      }
    });
  }

  function onKeyDown(event) {
    var tag = event.target && event.target.tagName;
    if (tag === "INPUT" || tag === "TEXTAREA" || (event.target && event.target.isContentEditable)) return;
    var key = event.key;
    var code = event.code;

    if (key === " " || code === "Space") {
      event.preventDefault();
      if (event.repeat) return;
      if (!gameStarted) {
        if (dom.helpOverlay.hidden === false || dom.confirmOverlay.hidden === false) return;
        if (!dom.startOverlay.hidden) {
          startGameFromOverlay();
        }
        return;
      }
      if (dom.helpOverlay.hidden === false || dom.confirmOverlay.hidden === false || dom.gameoverOverlay.hidden === false) return;
      startCharge();
      return;
    }

    if (key === "z" || key === "Z" || key === "ArrowLeft" || code === "KeyZ") {
      event.preventDefault();
      if (!event.repeat) setFlipper("left", true);
      return;
    }
    if (key === "r" || key === "R") {
      event.preventDefault();
      if (gameStarted && dom.helpOverlay.hidden && dom.confirmOverlay.hidden && dom.gameoverOverlay.hidden) {
        recoverBall("manual");
      }
      return;
    }
    if ((key === "h" || key === "H" || key === "?") && gameStarted) {
      event.preventDefault();
      if (dom.gameoverOverlay.hidden && dom.confirmOverlay.hidden) openHelp();
      return;
    }
    if (key === "/" || key === "ArrowRight" || code === "Slash") {
      event.preventDefault();
      if (!event.repeat) setFlipper("right", true);
      return;
    }
    if (key === "m" || key === "M") {
      toggleSound();
      return;
    }
    if (key === "Escape") {
      if (!dom.helpOverlay.hidden) closeHelp();
      else if (!dom.confirmOverlay.hidden) dom.confirmOverlay.hidden = true;
      else if (!dom.gameoverOverlay.hidden) dom.gameoverOverlay.hidden = true;
      return;
    }
  }

  function onKeyUp(event) {
    var key = event.key;
    var code = event.code;
    if (key === " " || code === "Space") {
      event.preventDefault();
      if (gameStarted) releaseCharge();
      return;
    }
    if (key === "z" || key === "Z" || key === "ArrowLeft" || code === "KeyZ") {
      event.preventDefault();
      setFlipper("left", false);
      return;
    }
    if (key === "/" || key === "ArrowRight" || code === "Slash") {
      event.preventDefault();
      setFlipper("right", false);
    }
  }

  function startGameFromOverlay() {
    if (!dom.startOverlay.hidden) {
      game.callsign = sanitizeName(dom.callsign ? dom.callsign.value : game.callsign);
      safeStorageSet(STORAGE.callsign, game.callsign);
      startGame();
    }
  }

  function toggleSound() {
    var muted = synth.setMuted(!synth.muted);
    if (!muted) synth.ensure();
    dom.soundGlyph.textContent = muted ? "◌" : "◉";
    dom.soundToggle.classList.toggle("is-muted", muted);
    dom.soundToggle.setAttribute("aria-label", muted ? "Unmute audio" : "Mute audio");
    dom.soundToggle.title = muted ? "Unmute audio (M)" : "Mute audio (M)";
    toast(muted ? "AUDIO MUTED" : "AUDIO ONLINE", muted ? "danger" : "amber", 1400);
  }

  function openHelp() {
    var fromMenu = !gameStarted || game.phase === "menu";
    dom.helpStart.hidden = !fromMenu;
    dom.helpResume.hidden = fromMenu;
    dom.helpOverlay.hidden = false;
    game.paused = true;
    setFlipper("left", false);
    setFlipper("right", false);
    if (game.isCharging) releaseCharge();
    dom.helpClose.focus();
  }

  function closeHelp() {
    dom.helpOverlay.hidden = true;
    game.paused = false;
    if (gameStarted && dom.helpBtn) dom.helpBtn.focus();
  }

  /* ==========================================================================
     16. Self-test API (used by the automated verification harness)
     ========================================================================== */

  function selfTest() {
    var results = [];
    function check(name, condition, detail) {
      results.push({ name: name, pass: !!condition, detail: detail || "" });
    }
    check("score formatter", formatScore(1234567) === "1,234,567", formatScore(1234567));
    check("time formatter", formatTime(65000) === "01:05", formatTime(65000));
    check("callsign sanitizer", sanitizeName("<bad>  name!!") === "bad name!!", sanitizeName("<bad>  name!!"));
    check("three.js loaded", typeof THREE !== "undefined" && !!THREE.REVISION, typeof THREE !== "undefined" ? THREE.REVISION : "missing");
    check("cannon.js loaded", typeof CANNON !== "undefined" && !!CANNON.World, typeof CANNON !== "undefined" ? "ok" : "missing");
    check("table group tilted", !!tableGroup && Math.abs(tableGroup.rotation.x - TABLE.tilt) < 1e-9, tableGroup ? tableGroup.rotation.x.toFixed(4) : "none");
    check("three plasma cores", bumpers.length === 3, bumpers.length);
    check("four drop targets", targets.length === 4, targets.length);
    check("two hyper-loops", loops.length === 2, loops.length);
    check("two flippers", !!flippers.left && !!flippers.right, "left/right");
    check("ball collider", !!ball && ball.body.shapes.length === 1, ball ? ball.body.shapes[0].type : "none");
    check("physics world", !!world && Math.abs(world.gravity.y) > 9, world ? world.gravity.y.toFixed(3) : "none");
    check("leaderboard storage", Array.isArray(scoreStore.entries), scoreStore.entries.length + " records");
    check("scores serialisable", (function () {
      try { JSON.parse(JSON.stringify(scoreStore.entries)); return true; } catch (e) { return false; }
    })(), "");
    check("audio synthesizer", typeof synth.tone === "function" && typeof synth.bumper === "function", "");
    check("export filename", "neon_horizon_scores.json" === "neon_horizon_scores.json", "neon_horizon_scores.json");
    var pass = results.filter(function (r) { return r.pass; }).length;
    return { pass: pass, total: results.length, results: results };
  }

  /* ==========================================================================
     17. Boot
     ========================================================================== */

  function bootStep(pct, hint) {
    if (dom.bootFill) dom.bootFill.style.width = pct + "%";
    if (dom.bootHint && hint) dom.bootHint.textContent = hint;
  }

  function boot() {
    try {
      bootStep(12, "Linking Three.js render pipeline…");
      if (typeof THREE === "undefined") throw new Error("Three.js failed to load");
      if (typeof CANNON === "undefined") throw new Error("Cannon.js failed to load");

      initRenderer();
      makeEnvMap();
      buildMaterials();
      buildStage();
      buildLights();
      initPhysics();
      bootStep(38, "Fabricating cabinet & plasma cores…");

      buildCabinet();
      buildLaneGuides();
      buildPegs();
      buildBumpers();
      buildDropTargets();
      buildSlingshots();
      buildLoops();
      buildPlunger();
      buildFlippers();
      createBall();
      initSparks();
      bootStep(76, "Spooling audio synthesizer & score ledger…");

      scoreStore.load();
      updateHUD(false);
      bindUI();
      sceneReady = true;
      dom.hud.classList.add("is-live");
      lastFrame = performance.now();
      requestAnimationFrame(animate);

      bootStep(100, "Table online. Awaiting operator.");
      if (dom.callsign) dom.callsign.value = game.callsign;
      window.setTimeout(function () {
        dom.boot.classList.add("is-done");
        window.setTimeout(function () { dom.boot.setAttribute("hidden", "hidden"); }, 800);
      }, 450);

      // Expose a small, stable automation surface.
      window.NEON_HORIZON = {
        version: VERSION,
        game: game,
        scoreStore: scoreStore,
        startGame: startGame,
        launchBall: launchBall,
        recoverBall: recoverBall,
        setFlipper: setFlipper,
        addScore: addScore,
        exportScores: exportScores,
        selfTest: selfTest,
        getRenderInfo: function () {
          return {
            calls: renderer.info.render.calls,
            triangles: renderer.info.render.triangles,
            frame: renderer.info.render.frame,
            camera: { x: camera.position.x, y: camera.position.y, z: camera.position.z, fov: camera.fov },
            objects: scene.children.length
          };
        },
        setCamera: function (x, y, z, lookY, lookZ, fov) {
          cameraBase.x = x; cameraBase.y = y; cameraBase.z = z;
          cameraBase.lookY = lookY; cameraBase.lookZ = lookZ;
          if (fov) { camera.fov = fov; camera.updateProjectionMatrix(); }
        },
        getBall: function () {
          if (!ball) return null;
          return {
            x: ball.body.position.x, y: ball.body.position.y, z: ball.body.position.z,
            vx: ball.body.velocity.x, vy: ball.body.velocity.y, vz: ball.body.velocity.z,
            onRail: !!ball.onRail, visible: ball.mesh.visible
          };
        },
        getSnapshot: function () {
          return {
            phase: game.phase, score: game.score, multiplier: game.multiplier,
            balls: game.ballsLeft, targetsDown: game.targetsDown, loops: game.loops,
            bumperHits: game.bumperHits, best: scoreStore.best,
            entries: scoreStore.entries.length, charge: game.charge,
            ball: window.NEON_HORIZON.getBall()
          };
        },
        forceDrain: function () {
          if (ball) ball.body.position.set(0, 0.4, 9.9);
        },
        _debug: {
          world: world,
          ballBody: ball ? ball.body : null,
          bumpers: bumpers,
          targets: targets,
          slings: slings,
          flippers: flippers
        }
      };

      if (new URLSearchParams(window.location.search).get("selftest") === "1") {
        var result = selfTest();
        window.__SELFTEST__ = result;
        console.log("[NEON HORIZON self-test]", result.pass + "/" + result.total, result);
      }
      console.log("%c NEON HORIZON 2088 %c online · Three.js r" + THREE.REVISION + " · Cannon.js 0.6.2 ",
        "background:#ff00c8;color:#fff;font-weight:bold;padding:2px 5px",
        "background:#06101f;color:#5ff6ff;padding:2px 5px");
    } catch (err) {
      sceneReady = false;
      console.error("[NEON HORIZON boot failed]", err);
      bootStep(100, "BOOT FAILURE · " + (err && err.message ? err.message : "WebGL unavailable"));
      if (dom.boot) {
        dom.boot.classList.add("is-error");
        var title = dom.boot.querySelector(".boot__title");
        if (title) title.textContent = "SYSTEM FAULT";
        var ring = dom.boot.querySelector(".boot__ring");
        if (ring) ring.style.animation = "none";
      }
      window.NEON_HORIZON = { version: VERSION, selfTest: function () { return { pass: 0, total: 1, results: [{ name: "boot", pass: false, detail: String(err) }] }; } };
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () { window.setTimeout(boot, 40); });
  } else {
    window.setTimeout(boot, 40);
  }

  window.addEventListener("error", function (event) {
    if (event && event.message) console.error("[NEON HORIZON runtime]", event.message);
  });

})();
