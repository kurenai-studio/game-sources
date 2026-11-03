window.LUMEN = window.LUMEN || {};

(function (LM) {
  "use strict";

  var midi = function (n) { return LM.Synth.midi(n); };

  // Chords as [root midi note, quality]. Patterns are 16 steps per bar.
  var TRACKS = {
    // a slow, hopeful lullaby under the menus and the story
    title: { bpm: 84, chords: [[57, "m"], [53, "M"], [48, "M"], [55, "M"]], arp: "triangle", arpPat: [0, -1, 1, -1, 2, -1, 1, -1, 0, -1, 1, -1, 3, -1, 2, -1],
      bass: "sine", bassPat: [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0], bassLong: true, kick: [], hat: [], snare: [],
      pad: true, padLong: true, arpGain: 0.05, bell: true, lead: true, leadType: "sine" },
    garden: { bpm: 92, chords: [[48, "M"], [57, "m"], [53, "M"], [55, "M"]], arp: "triangle", arpPat: [0, 2, 1, 2, 3, 2, 1, 2, 0, 2, 1, 2, 3, 2, 1, 2],
      bass: "triangle", bassPat: [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0], kick: [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
      hat: [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0], snare: [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0], snareSoft: true,
      pad: false, arpGain: 0.06, lead: true, leadType: "sine" },
    city: { bpm: 96, chords: [[57, "m"], [53, "M"], [48, "M"], [52, "M"]], arp: "triangle", arpPat: [0, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1, 0, 1, 2, 1],
      bass: "triangle", bassPat: [1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0], kick: [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0],
      hat: [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0], snare: [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0], snareSoft: true,
      pad: true, arpGain: 0.04, arpFilter: 1600, lead: false },
    sky: { bpm: 76, chords: [[50, "m"], [46, "M"], [53, "M"], [48, "M"]], arp: "sine", arpPat: [0, -1, -1, 2, -1, -1, 1, -1, 3, -1, -1, 2, -1, 1, -1, -1],
      bass: "sine", bassPat: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], bassLong: true, kick: [], hat: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      snare: [], pad: true, padLong: true, arpGain: 0.08, arpOct: 24, bell: true, lead: false },
    moon: { bpm: 80, chords: [[52, "m"], [48, "M"], [55, "M"], [50, "M"]], arp: "sine", arpPat: [0, -1, 2, -1, 1, -1, 3, -1, 2, -1, 1, -1, 0, -1, 2, 3],
      bass: "sine", bassPat: [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0], bassLong: true, kick: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      hat: [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0], snare: [], pad: true, padLong: true, arpGain: 0.07, arpOct: 12, bell: true, lead: true, leadType: "sine" }
  };
  var WORLD_TRACKS = ["garden", "city", "sky", "moon"];

  function triad(ch) {
    var r = ch[0];
    return ch[1] === "m" ? [r, r + 3, r + 7, r + 12] : [r, r + 4, r + 7, r + 12];
  }

  // A look-ahead step sequencer. Each track gets its own gain so switching
  // tracks crossfades instead of cutting.
  function Music(synth) {
    this.synth = synth;
    this.track = null;
    this.name = "";
    this.timer = null;
    this.step = 0;
    this.next = 0;
    this.gain = null;
    this.rng = new LM.Rng(5);
    this.intensity = 0;
  }

  Music.prototype.play = function (name) {
    if (name === this.name && this.timer) return;
    var c = this.synth.ensure();
    if (!c) return;
    this.stop(true);
    this.name = name;
    this.track = TRACKS[name] || TRACKS.title;
    this.gain = c.createGain();
    this.gain.gain.setValueAtTime(0.0001, c.currentTime);
    this.gain.gain.exponentialRampToValueAtTime(1, c.currentTime + 1.2);
    this.gain.connect(this.synth.music);
    this.step = 0;
    this.next = c.currentTime + 0.08;
    this.rng = new LM.Rng(LM.hash(name));
    var self = this;
    this.timer = setInterval(function () { self.schedule(); }, 25);
    this.schedule();
  };

  Music.prototype.playWorld = function (w) {
    this.play(WORLD_TRACKS[w] || "garden");
  };

  Music.prototype.stop = function (fade) {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
    if (this.gain && this.synth.ctx) {
      var g = this.gain, now = this.synth.ctx.currentTime;
      g.gain.cancelScheduledValues(now);
      g.gain.setValueAtTime(Math.max(0.0001, g.gain.value), now);
      g.gain.exponentialRampToValueAtTime(0.0001, now + (fade ? 0.8 : 0.05));
      setTimeout(function () { try { g.disconnect(); } catch (e) { /* gone */ } }, 1200);
    }
    this.gain = null;
    this.name = "";
  };

  // Duck the music under the pause menu, or lift intensity with the combo.
  Music.prototype.duck = function (on) {
    if (!this.gain || !this.synth.ctx) return;
    this.gain.gain.setTargetAtTime(on ? 0.3 : 1, this.synth.ctx.currentTime, 0.15);
  };

  Music.prototype.schedule = function () {
    var c = this.synth.ctx;
    if (!c || !this.track) return;
    var spb = 60 / this.track.bpm / 4;
    while (this.next < c.currentTime + 0.15) {
      this.playStep(this.step, this.next, spb);
      this.next += spb;
      this.step = (this.step + 1) % (16 * this.track.chords.length);
    }
  };

  Music.prototype.playStep = function (step, when, spb) {
    var T = this.track, s = this.synth, dest = this.gain;
    var bar = Math.floor(step / 16), i = step % 16;
    var notes = triad(T.chords[bar % T.chords.length]);

    if (T.bassPat[i]) {
      var bn = notes[0] - 12 + (T.bassOct && i % 4 === 2 ? 12 : 0);
      s.tone(midi(bn), T.bassLong ? spb * 15 : spb * 1.8, { type: T.bass, gain: T.bass === "sine" ? 0.32 : 0.12, when: when, dest: dest,
        filter: T.bass === "sawtooth" || T.bass === "square" ? 700 : 0, filterTo: 260, attack: T.bassLong ? 0.3 : 0.01 });
    }
    var ai = T.arpPat[i];
    if (ai >= 0) {
      var an = notes[ai % notes.length] + (T.arpOct || 12);
      s.tone(midi(an), T.bell ? spb * 6 : spb * 1.2, { type: T.arp, gain: T.arpGain, when: when, dest: dest,
        filter: T.arpFilter || 0, attack: 0.004 });
      if (T.bell) s.tone(midi(an + 12), spb * 4, { type: "sine", gain: T.arpGain * 0.3, when: when + spb * 3, dest: dest });
    }
    if (T.pad && i === 0) {
      notes.slice(0, 3).forEach(function (n, k) {
        s.tone(midi(n), spb * (T.padLong ? 16 : 15), { type: "sawtooth", gain: 0.025, when: when, dest: dest, filter: 900, attack: spb * 4,
          detune: k * 4 - 4 });
      });
    }
    if (T.lead && i % 4 === 0 && this.rng.chance(0.45)) {
      var scale = [0, 2, 4, 7, 9];
      var ln = notes[0] + 24 + scale[this.rng.int(scale.length)];
      s.tone(midi(ln), spb * 3, { type: T.leadType || "triangle", gain: 0.045, when: when + spb * (this.rng.chance(0.3) ? 2 : 0), dest: dest, attack: 0.01 });
    }
    if (T.kick[i]) s.tone(150, 0.25, { type: "sine", gain: 0.5, slide: 40, when: when, dest: dest });
    if (T.hat[i]) s.noise(0.04, { ftype: "highpass", freq: 8000, gain: 0.05, when: when, dest: dest });
    if (T.snare[i]) {
      s.noise(T.snareSoft ? 0.08 : 0.16, { freq: T.snareSoft ? 5000 : 1800, gain: T.snareSoft ? 0.06 : 0.16, when: when, dest: dest });
      if (!T.snareSoft) s.tone(200, 0.1, { type: "triangle", gain: 0.08, slide: 120, when: when, dest: dest });
    }
    if (T.glitch && this.rng.chance(0.08)) {
      s.tone(midi(notes[this.rng.int(3)] + 36), 0.03, { type: "square", gain: 0.03, when: when + spb / 2, dest: dest });
    }
  };

  LM.Music = Music;
  LM.Music.TRACKS = TRACKS;
})(window.LUMEN);
