// Beach Road audio: nine generative radio stations, coastal ambience and gentle car sounds.
// Everything is synthesised live with plain Web Audio (no samples, no libraries). The music is
// composed at runtime from theory: modes, progression templates, voice-led chords, song sections
// whose layers come and go, and short motifs that are repeated with variation.

// ------------------------------------------------------------ utilities

const mtof = (m) => 440 * Math.pow(2, (m - 69) / 12);
const mod12 = (n) => ((n % 12) + 12) % 12;
const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
const rand = (a, b) => a + Math.random() * (b - a);
const chance = (p) => Math.random() < p;
const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
const num = (v) => typeof v === 'number' && Number.isFinite(v);

function weighted(items) {
  let sum = 0;
  for (const [, w] of items) sum += w;
  let r = Math.random() * sum;
  for (const [v, w] of items) if ((r -= w) <= 0) return v;
  return items.length ? items[items.length - 1][0] : undefined;
}

const LOOKAHEAD = 0.3;
const XFADE = 2.5;
const NOTE_NAMES = ['C', 'D♭', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B'];
const MODES = {
  major: [0, 2, 4, 5, 7, 9, 11],
  minor: [0, 2, 3, 5, 7, 8, 10],
  dorian: [0, 2, 3, 5, 7, 9, 10],
  mixolydian: [0, 2, 4, 5, 7, 9, 10],
  lydian: [0, 2, 4, 6, 7, 9, 11],
};
// Where each mode's tonic sits in its parent major scale (used for relative key changes).
const MODE_OFFSET = { major: 0, dorian: 2, lydian: 5, mixolydian: 7, minor: 9 };

let NOISE = null; // { white, brown } shared 4s buffers, created with the AudioContext

function noiseBuffer(ctx, brown) {
  const len = ctx.sampleRate * 4, buf = ctx.createBuffer(1, len, ctx.sampleRate), d = buf.getChannelData(0);
  let last = 0;
  for (let i = 0; i < len; i++) {
    const w = Math.random() * 2 - 1;
    if (brown) { last = (last + 0.02 * w) / 1.02; d[i] = last * 3.5; } else d[i] = w;
  }
  return buf;
}

// Stereo hall impulse whose tail darkens as it decays, so the reverb never gets fizzy.
function impulse(ctx, sec) {
  const sr = ctx.sampleRate, len = Math.floor(sr * sec), pre = Math.floor(sr * 0.015);
  const buf = ctx.createBuffer(2, len, sr);
  for (let ch = 0; ch < 2; ch++) {
    const d = buf.getChannelData(ch);
    let lp = 0;
    for (let i = pre; i < len; i++) {
      const k = (i - pre) / (len - pre);
      lp += (0.55 - 0.47 * k) * (Math.random() * 2 - 1 - lp);
      d[i] = lp * Math.pow(1 - k, 2.2);
    }
  }
  return buf;
}

// Freeze a param at its current value so new automation starts from where it is.
function hold(p, t) {
  if (p.cancelAndHoldAtTime) p.cancelAndHoldAtTime(t);
  else { const v = p.value; p.cancelScheduledValues(t); p.setValueAtTime(v, t); }
}

// Percussive envelope: quick rise, exponential fall to silence at t + dec.
function perc(p, t, a, peak, dec) {
  p.setValueAtTime(0.0001, t);
  p.exponentialRampToValueAtTime(Math.max(peak, 0.0002), t + a);
  p.exponentialRampToValueAtTime(0.0001, t + Math.max(dec, a + 0.002));
}

// Sustained envelope: attack, optional decay to sus, release after dur. Returns the silent time.
function adsr(p, t, a, peak, dur, rel, sus = 1) {
  const off = t + Math.max(dur, a);
  p.setValueAtTime(0, t);
  p.linearRampToValueAtTime(peak, t + a);
  if (sus < 1) p.setTargetAtTime(peak * sus, t + a, Math.max(0.03, dur * 0.25));
  p.setTargetAtTime(0, off, rel / 5);
  return off + rel * 1.3;
}

// Pattern strings: x accent, o normal, g ghost, ? coin flip, anything else rest.
const VEL = { X: 1.15, x: 1, o: 0.7, g: 0.35 };
function hit(pat, i) {
  const c = pat[i % pat.length];
  if (c === '?') return chance(0.5) ? 0.6 : 0;
  return VEL[c] || 0;
}

// ------------------------------------------------------------ voices

// One short-lived note: owns its nodes, stops its sources and disconnects everything when done.
class Voice {
  constructor(ctx, dest, t, pan = 0) {
    this.ctx = ctx;
    this.t = Math.max(t, ctx.currentTime);
    this.nodes = [];
    this.srcs = [];
    this.fx = [];
    this.done = false;
    this.wob = null;
    this.out = this.add(ctx.createGain());
    this.out.gain.value = 0;
    if (pan) this.out.connect(this.pan(pan, dest));
    else this.out.connect(dest);
  }

  add(n) { this.nodes.push(n); return n; }

  osc(type, freq, dest = this.out, detune = 0) {
    const o = this.add(this.ctx.createOscillator());
    o.type = type;
    o.frequency.value = freq;
    if (detune) o.detune.value = detune;
    if (this.wob) {
      const w = this.wob;
      w.connect(o.detune);
      this.fx.push(() => { try { w.disconnect(o.detune); } catch (e) { /* deck already torn down */ } });
    }
    o.connect(dest);
    o.start(this.t);
    this.srcs.push(o);
    return o;
  }

  // len: stop this noise early (a transient inside a longer note); it then isn't the voice's clock.
  noise(buf, dest = this.out, rate = 1, len = 0) {
    const s = this.add(this.ctx.createBufferSource());
    s.buffer = buf;
    s.playbackRate.value = rate;
    s.connect(dest);
    s.start(this.t, Math.random() * (buf.duration - 1.5));
    if (len) s.stop(this.t + len);
    else this.srcs.push(s);
    return s;
  }

  gain(v, dest = this.out) {
    const g = this.add(this.ctx.createGain());
    g.gain.value = v;
    g.connect(dest);
    return g;
  }

  filter(type, freq, q = 0.7, dest = this.out) {
    const f = this.add(this.ctx.createBiquadFilter());
    f.type = type;
    f.frequency.value = freq;
    f.Q.value = q;
    f.connect(dest);
    return f;
  }

  pan(v, dest = this.out) {
    const p = this.add(this.ctx.createStereoPanner());
    p.pan.value = clamp(v, -1, 1);
    p.connect(dest);
    return p;
  }

  stop(end) {
    for (const s of this.srcs) s.stop(end);
    if (this.srcs.length) this.srcs[0].onended = () => this.free();
    else this.free();
  }

  // Voice stealing / teardown: fast fade, then stop.
  kill() {
    if (this.done || this.killed) return;
    this.killed = true;
    const now = this.ctx.currentTime;
    hold(this.out.gain, now);
    this.out.gain.setTargetAtTime(0, now, 0.02);
    for (const s of this.srcs) { try { s.stop(now + 0.12); } catch (e) { /* already stopped */ } }
  }

  free() {
    if (this.done) return;
    this.done = true;
    for (const f of this.fx) f();
    for (const n of this.nodes) n.disconnect();
    this.nodes.length = 0;
    this.srcs.length = 0;
    if (this.onFree) this.onFree(this);
  }
}

// Voice budget per group: the oldest voice is stolen when a group is full.
class Pool {
  constructor(ctx) {
    this.ctx = ctx;
    this.groups = {};
    this.all = new Set();
    this.wobble = null;
  }

  voice(dest, group, max, t, pan = 0) {
    const list = this.groups[group] || (this.groups[group] = []);
    while (list.length >= max) list.shift().kill();
    const v = new Voice(this.ctx, dest, t, pan);
    v.wob = this.wobble;
    v.onFree = () => {
      const i = list.indexOf(v);
      if (i >= 0) list.splice(i, 1);
      this.all.delete(v);
    };
    list.push(v);
    this.all.add(v);
    return v;
  }

  killAll() {
    for (const v of this.all) v.kill();
    this.all.clear();
    this.groups = {};
  }
}

// ------------------------------------------------------------ instruments

function vibrato(v, oscs, f, t, dur, depth = 0.006, rate = 5) {
  if (dur < 0.35) return;
  const d = v.gain(0, oscs[0].frequency);
  for (let i = 1; i < oscs.length; i++) d.connect(oscs[i].frequency);
  d.gain.setValueAtTime(0, t + 0.15);
  d.gain.linearRampToValueAtTime(f * depth, t + Math.min(0.6, dur));
  v.osc('sine', rate * rand(0.9, 1.1), d);
}

// Two-operator FM electric piano (Rhodes = softer index, darker tine, longer ring).
function fmKeys(v, f, g, o, index, dec, tine) {
  const t = v.t, dest = v.out;
  perc(v.out.gain, t, 0.003, g, dec);
  const c = v.osc('sine', f, dest);
  const mi = v.gain(0, c.frequency);
  mi.gain.setValueAtTime(f * index * (o.bright || 1), t);
  mi.gain.exponentialRampToValueAtTime(f * 0.03, t + Math.min(dec, 1));
  v.osc('sine', f, mi);
  if (f < 900) {
    const tg = v.gain(0, dest);
    perc(tg.gain, t, 0.001, 0.05, 0.06);
    v.osc('sine', f * tine, tg);
  }
  return t + dec + 0.03;
}

// Each tone shapes v.out, builds its sources and returns the time it has gone silent.
// (v, freq, peakGain, opts{ decay, dur, ... })
const TONES = {
  marimba(v, f, g, o) {
    const t = v.t, dec = o.decay || 0.7;
    perc(v.out.gain, t, 0.004, g, dec);
    v.osc('sine', f);
    if (f * 4 < 9000) { const h = v.gain(0); perc(h.gain, t, 0.002, 0.3, 0.07); v.osc('sine', f * 4, h); }
    return t + dec + 0.03;
  },
  kalimba(v, f, g, o) {
    const t = v.t, dec = o.decay || 1.3;
    perc(v.out.gain, t, 0.003, g, dec);
    v.osc('sine', f);
    v.osc('triangle', f * 2, v.gain(0.06));
    if (f * 5.9 < 8000) { const h = v.gain(0); perc(h.gain, t, 0.002, 0.2, 0.1); v.osc('sine', f * 5.9, h); }
    return t + dec + 0.03;
  },
  vibes(v, f, g, o) {
    const t = v.t, dec = o.decay || 2.4;
    perc(v.out.gain, t, 0.003, g, dec);
    const trem = v.gain(0.8);
    v.osc('sine', 4.6, v.gain(0.2, trem.gain));
    v.osc('sine', f, trem);
    if (f * 4 < 9000) { const h = v.gain(0, trem); perc(h.gain, t, 0.002, 0.18, 0.25); v.osc('sine', f * 4, h); }
    return t + dec + 0.03;
  },
  bell(v, f, g, o) {
    const t = v.t, dec = o.decay || 4;
    perc(v.out.gain, t, 0.005, g, dec);
    const c = v.osc('sine', f);
    const mi = v.gain(0, c.frequency);
    mi.gain.setValueAtTime(f * 1.4, t);
    mi.gain.exponentialRampToValueAtTime(f * 0.04, t + dec * 0.5);
    v.osc('sine', f * 3.5, mi);
    v.osc('sine', f * 2.01, v.gain(0.12));
    return t + dec + 0.03;
  },
  piano(v, f, g, o) {
    const t = v.t, dec = Math.max(0.6, o.decay || clamp(4.2 - f / 220, 1.4, 4)), p = v.out.gain;
    p.setValueAtTime(0.0001, t);
    p.exponentialRampToValueAtTime(Math.max(g, 0.0002), t + 0.005);
    p.exponentialRampToValueAtTime(Math.max(g * 0.4, 0.0002), t + 0.3);
    p.exponentialRampToValueAtTime(0.0001, t + dec);
    const lp = v.filter('lowpass', clamp(f * 5, 700, 4500), 0.5);
    v.osc('triangle', f, lp);
    v.osc('sine', f, v.gain(0.7, lp), 3);
    const h2 = v.gain(0, lp); perc(h2.gain, t, 0.003, 0.35, Math.min(dec, 0.8)); v.osc('sine', f * 2, h2);
    const h3 = v.gain(0, lp); perc(h3.gain, t, 0.002, 0.12, 0.3); v.osc('sine', f * 3, h3);
    return t + dec + 0.03;
  },
  epiano(v, f, g, o) { return fmKeys(v, f, g, o, 1.1, o.decay || 2, 7); },
  rhodes(v, f, g, o) { return fmKeys(v, f, g, o, 0.7, o.decay || 2.6, 4); },
  guitar(v, f, g, o) {
    const t = v.t, dec = o.decay || 1.3;
    perc(v.out.gain, t, 0.002, g, dec);
    const lp = v.filter('lowpass', 3000, 1.2);
    lp.frequency.setValueAtTime(clamp(f * 8, 1500, 4500), t);
    lp.frequency.exponentialRampToValueAtTime(Math.max(300, f * 1.5), t + 0.4);
    v.osc('triangle', f, lp);
    v.osc('sawtooth', f, v.gain(0.3, lp), 4);
    const pk = v.gain(0); perc(pk.gain, t, 0.001, 0.25, 0.025);
    v.noise(NOISE.white, v.filter('bandpass', 2500, 1.2, pk), 1, 0.05);
    return t + dec + 0.03;
  },
  pluck(v, f, g, o) {
    const t = v.t, dec = o.decay || 0.4;
    perc(v.out.gain, t, 0.003, g, dec);
    const lp = v.filter('lowpass', 2000, 1);
    lp.frequency.setValueAtTime(clamp(f * 6, 800, 4000), t);
    lp.frequency.exponentialRampToValueAtTime(Math.max(200, f), t + dec);
    v.osc('triangle', f, lp);
    v.osc('sawtooth', f, v.gain(0.3, lp), 6);
    return t + dec + 0.03;
  },
  saw(v, f, g, o) {
    const t = v.t, dec = o.decay || 0.22;
    perc(v.out.gain, t, 0.003, g, dec);
    const lp = v.filter('lowpass', 2400, 2.5);
    lp.frequency.setValueAtTime(o.cutoff || 2600, t);
    lp.frequency.exponentialRampToValueAtTime(350, t + dec);
    v.osc('sawtooth', f, lp, -7);
    v.osc('sawtooth', f, lp, 7);
    return t + dec + 0.03;
  },
  pulse(v, f, g, o) {
    const t = v.t, dec = o.decay || 0.3;
    perc(v.out.gain, t, 0.003, g, dec);
    const lp = v.filter('lowpass', 1800, 1.5);
    lp.frequency.setValueAtTime(1800, t);
    lp.frequency.exponentialRampToValueAtTime(300, t + dec);
    v.osc('square', f, v.gain(0.7, lp));
    return t + dec + 0.03;
  },
  stab(v, f, g, o) {
    const t = v.t, dec = o.decay || 0.35;
    perc(v.out.gain, t, 0.004, g, dec);
    const lp = v.filter('lowpass', 1800, 2);
    lp.frequency.setValueAtTime(clamp(f * 5, 900, 2600), t);
    lp.frequency.exponentialRampToValueAtTime(Math.max(250, f * 1.2), t + dec * 0.8);
    v.osc('sawtooth', f, lp, -6);
    v.osc('sawtooth', f, v.gain(0.6, lp), 8);
    return t + dec + 0.03;
  },
  flute(v, f, g, o) {
    const t = v.t, dur = Math.max(0.12, o.dur || 0.5);
    const end = adsr(v.out.gain, t, 0.06, g, dur, 0.3, 0.85);
    const c = v.osc('sine', f), tr = v.osc('triangle', f, v.gain(0.22));
    vibrato(v, [c, tr], f, t, dur);
    const chiff = v.gain(0); perc(chiff.gain, t, 0.01, 0.12, 0.12);
    v.noise(NOISE.white, v.filter('bandpass', Math.min(f * 2, 6000), 2, chiff), 1, 0.15);
    return end;
  },
  lead(v, f, g, o) {
    const t = v.t, dur = Math.max(0.1, o.dur || 0.4);
    const end = adsr(v.out.gain, t, 0.025, g, dur, 0.35, 0.75);
    const lp = v.filter('lowpass', clamp(f * 4, 900, 2600), 0.8);
    const a = v.osc('sawtooth', f, lp, -6), b = v.osc('sawtooth', f, lp, 6);
    vibrato(v, [a, b], f, t, dur, 0.005);
    return end;
  },
  horn(v, f, g, o) {
    const t = v.t, dur = Math.max(0.12, o.dur || 0.4);
    const end = adsr(v.out.gain, t, 0.05, g, dur, 0.25, 0.8);
    const lp = v.filter('lowpass', 400, 0.7);
    lp.frequency.setValueAtTime(400, t);
    lp.frequency.linearRampToValueAtTime(clamp(f * 3, 800, 2200), t + 0.08);
    lp.frequency.setTargetAtTime(clamp(f * 2, 600, 1600), t + 0.1, 0.2);
    const a = v.osc('sawtooth', f, lp), b = v.osc('triangle', f, v.gain(0.5, lp));
    vibrato(v, [a, b], f, t, dur, 0.004);
    return end;
  },
  // basses
  sub(v, f, g, o) {
    const t = v.t, end = adsr(v.out.gain, t, 0.012, g, o.dur || 0.5, 0.15);
    v.osc('sine', f);
    v.osc('sine', f * 2, v.gain(0.22));
    return end;
  },
  round(v, f, g, o) {
    const t = v.t, end = adsr(v.out.gain, t, 0.01, g, o.dur || 0.5, 0.12, 0.85);
    v.osc('triangle', f, v.filter('lowpass', clamp(f * 5, 250, 900), 0.6));
    v.osc('sine', f, v.gain(0.6));
    return end;
  },
  drone(v, f, g, o) {
    const t = v.t, dur = o.dur || 4, end = adsr(v.out.gain, t, Math.min(2.5, dur * 0.4), g, dur, 3);
    v.osc('sine', f);
    v.osc('triangle', f * 2, v.gain(0.12), 4);
    v.osc('sine', f * 3, v.gain(0.05));
    return end;
  },
  pulsebass(v, f, g, o) {
    const t = v.t, dur = o.dur || 0.2, end = adsr(v.out.gain, t, 0.005, g, dur, 0.08, 0.7);
    const lp = v.filter('lowpass', 800, 2);
    lp.frequency.setValueAtTime(clamp(f * 10, 400, 1400), t);
    lp.frequency.exponentialRampToValueAtTime(Math.max(120, f * 2), t + Math.min(0.2, dur + 0.05));
    v.osc('square', f, v.gain(0.5, lp));
    v.osc('sawtooth', f, v.gain(0.4, lp), 5);
    v.osc('sine', f, v.gain(0.5));
    return end;
  },
  upright(v, f, g, o) {
    const t = v.t, dur = Math.max(0.1, o.dur || 0.5), p = v.out.gain;
    p.setValueAtTime(0.0001, t);
    p.exponentialRampToValueAtTime(Math.max(g, 0.0002), t + 0.008);
    p.exponentialRampToValueAtTime(Math.max(g * 0.3, 0.0002), t + Math.min(dur, 1.2));
    p.setTargetAtTime(0, t + dur, 0.05);
    const lp = v.filter('lowpass', 900, 0.9);
    lp.frequency.setValueAtTime(clamp(f * 12, 500, 1600), t);
    lp.frequency.exponentialRampToValueAtTime(clamp(f * 3, 150, 600), t + 0.15);
    const a = v.osc('triangle', f, lp), b = v.osc('sine', f, v.gain(0.8, lp));
    for (const x of [a, b]) {
      x.frequency.setValueAtTime(f * 1.012, t);
      x.frequency.exponentialRampToValueAtTime(f, t + 0.05);
    }
    return t + dur + 0.35;
  },
  fm(v, f, g, o) {
    const t = v.t, end = adsr(v.out.gain, t, 0.006, g, o.dur || 0.3, 0.1, 0.8);
    const c = v.osc('sine', f);
    const mi = v.gain(0, c.frequency);
    mi.gain.setValueAtTime(f * 1.3, t);
    mi.gain.exponentialRampToValueAtTime(f * 0.15, t + 0.18);
    v.osc('sine', f, mi);
    v.osc('triangle', f * 2, v.gain(0.08));
    return end;
  },
};

// ------------------------------------------------------------ drum kit

// (v, gain, kitEntry, freqOverride) -> silent time
const DRUMS = {
  kick(v, g, k) {
    const t = v.t, dec = k.dec || 0.4, f0 = k.f0 || 120;
    perc(v.out.gain, t, 0.002, g, dec);
    const o = v.osc('sine', f0);
    o.frequency.setValueAtTime(f0, t);
    o.frequency.exponentialRampToValueAtTime(k.f1 || 46, t + (k.pd || 0.13));
    if (k.click) {
      const c = v.gain(0); perc(c.gain, t, 0.001, k.click, 0.015);
      v.noise(NOISE.white, v.filter('lowpass', 2500, 0.7, c));
    }
    return t + dec + 0.02;
  },
  snare(v, g, k) {
    const t = v.t, dec = k.dec || 0.17, n = v.gain(0);
    v.out.gain.setValueAtTime(g, t);
    if (k.gated) {
      n.gain.setValueAtTime(0, t);
      n.gain.linearRampToValueAtTime(1, t + 0.004);
      n.gain.linearRampToValueAtTime(0.75, t + dec * 0.75);
      n.gain.linearRampToValueAtTime(0, t + dec);
    } else perc(n.gain, t, 0.002, 1, dec);
    v.noise(NOISE.white, v.filter('bandpass', k.tone || 1800, 0.7, v.filter('lowpass', k.lp || 5000, 0.5, n)));
    const b = v.gain(0); perc(b.gain, t, 0.002, 0.5, 0.09);
    const o = v.osc('sine', 200, b);
    o.frequency.setValueAtTime(200, t);
    o.frequency.exponentialRampToValueAtTime(150, t + 0.08);
    if (k.verb && k.wet) v.out.connect(v.gain(k.verb, k.wet));
    return t + dec + 0.02;
  },
  clap(v, g, k) {
    const t = v.t, dec = k.dec || 0.2, n = v.gain(0), p = n.gain;
    v.out.gain.setValueAtTime(g, t);
    p.setValueAtTime(0, t);
    for (let i = 0; i < 3; i++) {
      const a = t + i * 0.011;
      p.linearRampToValueAtTime(1, a + 0.002);
      p.linearRampToValueAtTime(0.25, a + 0.009);
    }
    p.exponentialRampToValueAtTime(0.0001, t + dec);
    v.noise(NOISE.white, v.filter('bandpass', k.tone || 1200, 1, n));
    if (k.verb && k.wet) v.out.connect(v.gain(k.verb, k.wet));
    return t + dec + 0.02;
  },
  rim(v, g, k) {
    const t = v.t, f = k.f || 1700, dec = k.dec || 0.035;
    perc(v.out.gain, t, 0.001, g, dec + 0.02);
    v.osc('sine', f);
    v.noise(NOISE.white, v.filter('bandpass', f * 1.5, 2, v.gain(0.5)));
    return t + dec + 0.04;
  },
  hat(v, g, k) {
    const t = v.t, dec = k.dec || 0.045;
    perc(v.out.gain, t, 0.001, g, dec);
    v.noise(NOISE.white, v.filter('highpass', 7000, 0.7, v.filter('lowpass', 10500, 0.5)));
    return t + dec + 0.02;
  },
  shaker(v, g, k) {
    const t = v.t, dec = k.dec || 0.09, p = v.out.gain;
    p.setValueAtTime(0.0001, t);
    p.exponentialRampToValueAtTime(Math.max(g, 0.0002), t + 0.014);
    p.exponentialRampToValueAtTime(0.0001, t + dec);
    v.noise(NOISE.white, v.filter('bandpass', 5500, 1.2));
    return t + dec + 0.02;
  },
  brush(v, g, k) {
    const t = v.t, dec = k.dec || 0.22, p = v.out.gain;
    p.setValueAtTime(0.0001, t);
    p.exponentialRampToValueAtTime(Math.max(g, 0.0002), t + 0.035);
    p.exponentialRampToValueAtTime(0.0001, t + dec);
    v.noise(NOISE.white, v.filter('bandpass', 2800, 0.5, v.filter('lowpass', 6000, 0.5)));
    return t + dec + 0.02;
  },
  ride(v, g, k) {
    const t = v.t, dec = k.dec || 0.7;
    perc(v.out.gain, t, 0.002, g, dec);
    const lp = v.filter('lowpass', 9000, 0.5);
    v.noise(NOISE.white, v.filter('bandpass', 6000, 2.5, lp));
    const pg = v.gain(0, lp); perc(pg.gain, t, 0.001, 0.25, dec * 0.6);
    v.osc('sine', 3150, pg);
    v.osc('sine', 4790, pg);
    return t + dec + 0.02;
  },
  conga(v, g, k, f) {
    const t = v.t, f0 = f || k.f || 230, dec = k.dec || 0.28;
    perc(v.out.gain, t, 0.002, g, dec);
    const o = v.osc('sine', f0 * 1.25);
    o.frequency.setValueAtTime(f0 * 1.25, t);
    o.frequency.exponentialRampToValueAtTime(f0, t + 0.04);
    const s = v.gain(0); perc(s.gain, t, 0.001, 0.3, 0.02);
    v.noise(NOISE.white, v.filter('lowpass', 1500, 0.7, s));
    return t + dec + 0.02;
  },
  tom(v, g, k, f) {
    const t = v.t, f0 = f || k.f || 150, dec = k.dec || 0.4;
    perc(v.out.gain, t, 0.002, g, dec);
    const o = v.osc('sine', f0 * 1.4);
    o.frequency.setValueAtTime(f0 * 1.4, t);
    o.frequency.exponentialRampToValueAtTime(f0, t + 0.12);
    return t + dec + 0.02;
  },
  crackle(v, g) {
    const t = v.t, dec = rand(0.002, 0.008);
    perc(v.out.gain, t, 0.0005, g, dec);
    v.noise(NOISE.white, v.filter('bandpass', rand(1200, 5000), 1.5));
    return t + dec + 0.02;
  },
};
const DRUM_GAIN = { kick: 0.3, snare: 0.09, clap: 0.06, rim: 0.04, hat: 0.016, shaker: 0.016, brush: 0.03, ride: 0.018, conga: 0.07, tom: 0.06, crackle: 0.015 };
const DRUM_PAN = { hat: 0.2, ride: 0.25, shaker: 0.3, conga: -0.3, brush: -0.1, tom: -0.15 };
// kick: needs drums > 0; back(beat): needs full drums; perc: scaled by the perc layer.
const DRUM_ROLE = { kick: 'kick', snare: 'back', clap: 'back', rim: 'back', tom: 'back' };

// ------------------------------------------------------------ composer

// Progression tokens: '1'..'7' = scale degree in the song's mode. A suffix 'm' borrows the chord from
// the parallel minor, 'M' from the parallel major ('4m' = iv in a major key, '5M' = V7 in minor).
function parseToken(tok, mode) {
  const suf = tok[tok.length - 1];
  return { deg: parseInt(tok, 10) - 1, mode: suf === 'm' ? 'minor' : suf === 'M' ? 'major' : mode };
}

function scaleNote(tonic, mode, i) {
  const sc = MODES[mode];
  return tonic + sc[((i % 7) + 7) % 7] + 12 * Math.floor(i / 7);
}

// Pick the inversion/octave of the chord that moves least from the previous voicing, with a pull
// towards the station's register centre. open = drop-2 spread for 4+ note chords.
function voiceLead(tones, prev, center, open) {
  const pcs = [...new Set(tones.map(mod12))], n = pcs.length;
  let best = null, bestCost = Infinity;
  for (let inv = 0; inv < n; inv++) {
    const v = [];
    for (let i = 0; i < n; i++) {
      let p = pcs[(inv + i) % n] + 48;
      while (v.length && p <= v[v.length - 1]) p += 12;
      v.push(p);
    }
    if (open && n >= 4) { v[n - 2] -= 12; v.sort((a, b) => a - b); }
    const base = Math.round((center - (v[0] + v[n - 1]) / 2) / 12) * 12;
    for (const sh of [base - 12, base, base + 12]) {
      const c = v.map((x) => x + sh);
      let cost = Math.abs((c[0] + c[n - 1]) / 2 - center) * 0.7;
      if (prev) {
        for (const x of c) {
          let m = 99;
          for (const y of prev) m = Math.min(m, Math.abs(x - y));
          cost += m;
        }
      }
      if (cost < bestCost) { bestCost = cost; best = c; }
    }
  }
  return best;
}

const LEAD_RHYTHMS = [
  'x-x-x---x-------',
  'x--x--x-x-------',
  '..x-x-x-x---....',
  'x---x-x-x---....',
  'x-----x-x-x-----',
  '....x-x-x-x-x---',
  'x--x--x---x-x---',
];

// A one-bar motif: rhythm template + a gentle stepwise contour, in scale steps above the chord root.
function makeMotif(rhythms) {
  const r = pick(rhythms), notes = [];
  let deg = pick([0, 2, 4, 4, 7]);
  for (let i = 0; i < 16; i++) {
    if (r[i] !== 'x') continue;
    let len = 1;
    while (i + len < 16 && r[i + len] === '-') len++;
    notes.push({ at: i, len, deg });
    deg = clamp(deg + pick([-2, -1, -1, 1, 1, 2, 0, -3, 3]), -3, 9);
  }
  return notes;
}

function varyLine(line, amt) {
  const out = [];
  for (const n of line) {
    if (out.length && chance(amt * 0.25)) continue;
    out.push({ ...n, deg: chance(amt) ? clamp(n.deg + pick([-2, -1, 1, 2]), -3, 9) : n.deg });
  }
  return out;
}

function cadence() {
  return chance(0.5)
    ? [{ at: 0, len: pick([8, 12]), deg: pick([0, 2, 4]) }]
    : [{ at: 0, len: 4, deg: pick([2, 4]) }, { at: 6, len: 8, deg: pick([0, 2]) }];
}

function toSlots(line) {
  const s = new Array(16).fill(null);
  for (const n of line) s[n.at] = n;
  return s;
}

// Four-bar phrase: statement, answer (or space), restatement, cadence.
function makePhrase(motif) {
  const answer = chance(0.3) ? [] : varyLine(motif, 0.55);
  return [motif, answer, varyLine(motif, 0.2), cadence()].map(toSlots);
}

const BEAT_FORMS = [
  ['intro', 'groove', 'melody', 'break', 'melody', 'outro'],
  ['intro', 'groove', 'break', 'melody', 'groove', 'outro'],
  ['intro', 'melody', 'groove', 'break', 'melody', 'outro'],
  ['intro', 'groove', 'melody', 'groove', 'break', 'melody', 'outro'],
];
const AMBIENT_FORMS = [
  ['intro', 'drift', 'bloom', 'still', 'bloom', 'outro'],
  ['intro', 'bloom', 'drift', 'still', 'drift', 'outro'],
  ['intro', 'drift', 'still', 'bloom', 'outro'],
];
const NOMINAL = { intro: 1, groove: 2, melody: 2, break: 1, outro: 1, drift: 2, bloom: 2, still: 1 };
const GROWS = { groove: 1, melody: 1, drift: 1, bloom: 1 };
// Layer levels per section: 0 = silent, values scale density/velocity. drums < 1 = kick only.
const LAYERS = {
  intro: { pad: 1, comp: 0.6, arp: 0.5, bass: 0, drums: 0, perc: 0.5, lead: 0 },
  groove: { pad: 0.8, comp: 1, arp: 0.8, bass: 1, drums: 1, perc: 1, lead: 0 },
  melody: { pad: 0.7, comp: 0.9, arp: 0.5, bass: 1, drums: 1, perc: 1, lead: 1 },
  break: { pad: 1, comp: 0.6, arp: 1, bass: 0.5, drums: 0, perc: 0.35, lead: 0.4 },
  outro: { pad: 1, comp: 0.7, arp: 0.5, bass: 0.6, drums: 0.5, perc: 0.6, lead: 0 },
  drift: { pad: 1, comp: 0, arp: 0.6, bass: 1, drums: 0, perc: 0, lead: 0 },
  bloom: { pad: 0.8, comp: 0, arp: 1, bass: 1, drums: 0, perc: 0, lead: 1 },
  still: { pad: 1, comp: 0, arp: 0.25, bass: 0.5, drums: 0, perc: 0, lead: 0 },
  end: { pad: 1, comp: 0.5, arp: 0, bass: 0.5, drums: 0, perc: 0, lead: 0 },
};

function sectionLayers(name, cfg) {
  const L = { ...LAYERS[name] };
  if (name === 'groove' || name === 'melody') {
    L.arp *= rand(0.6, 1);
    if (cfg.comp && chance(0.25)) L.arp = 0;
    if (cfg.comp && cfg.pad && chance(0.3)) L.pad = 0;
    if (name === 'melody' && chance(0.4)) L.arp *= 0.5;
  }
  if (name === 'break' && chance(0.3)) L.bass = 0;
  if (name === 'intro' && chance(0.4)) L.perc = 0;
  return L;
}

// A whole song: key, tempo, progression, timbre variant and a section plan with layer levels.
function makeSong(st, prev) {
  let pc, mode;
  if (!prev) {
    pc = Math.floor(Math.random() * 12);
    mode = pick(st.modes);
  } else {
    ({ pc, mode } = prev);
    const r = Math.random(), others = st.modes.filter((m) => m !== mode);
    if (r < 0.4) pc = mod12(pc + (chance(0.5) ? 7 : 5)); // round the circle of fifths
    else if (r < 0.65 && others.length) { // relative / modal shift, same key signature
      const m2 = pick(others);
      pc = mod12(pc - MODE_OFFSET[mode] + MODE_OFFSET[m2]);
      mode = m2;
    } else if (r < 0.85) pc = mod12(pc + pick([2, 3, 9, 10]));
  }
  if (!Array.isArray(st.progs) && !st.progs[mode]) mode = Object.keys(st.progs)[0];
  let tonic = st.root + mod12(pc - st.root);
  if (tonic > st.root + 6) tonic -= 12;
  const [lo, hi] = st.bpm;
  const bpm = prev ? clamp(Math.round(prev.bpm + rand(-4, 4)), lo, hi) : Math.round(rand(lo, hi));
  const pool = Array.isArray(st.progs) ? st.progs : st.progs[mode];
  const fresh = pool.filter((p) => !prev || p !== prev.prog);
  const prog = pick(fresh.length ? fresh : pool);
  const bpc = pick(st.bpc);
  const variant = prev && chance(0.4) ? prev.variant : pick(st.variants || [{}]);
  const cfg = {};
  for (const part of ['pad', 'comp', 'arp', 'bass', 'lead']) {
    const base = st[part], ov = variant[part];
    cfg[part] = !base || ov === null ? null : { ...base, ...(ov || {}) };
  }
  const song = {
    pc, mode, tonic, bpm, prog, bpc, cfg, variant,
    ext: pick(st.ext),
    key: `${NOTE_NAMES[pc]} ${mode}`,
    scale: new Set(MODES[mode].map((x) => mod12(tonic + x))),
    swing16: (st.swing16 || 0) * rand(0.85, 1.15),
    swing8: st.swing8 || 0,
    motif: makeMotif((cfg.lead && cfg.lead.rhythms) || LEAD_RHYTHMS),
  };

  const cycle = prog.length * bpc, barSec = 240 / bpm;
  let unit = cycle * Math.ceil(4 / cycle);
  if (st.ambient && unit * barSec > 40 && unit % 8 === 0) unit /= 2;
  const names = pick(st.ambient ? AMBIENT_FORMS : BEAT_FORMS);
  const units = names.map((n) => (st.ambient && GROWS[n] ? 1 : NOMINAL[n]));
  const target = rand(150, 230);
  for (let guard = 0; guard < 24; guard++) {
    if (units.reduce((a, b) => a + b, 0) * unit * barSec >= target) break;
    const grow = names.map((n, i) => (GROWS[n] && units[i] < 6 ? i : -1)).filter((i) => i >= 0);
    if (!grow.length) break;
    units[pick(grow)]++;
  }

  const alt = pool.filter((p) => p !== prog), dr = st.drums;
  const bassMain = cfg.bass ? pick(cfg.bass.patterns || ['R---------------']) : '';
  const sections = [];
  let start = 0, firstGroove = true;
  names.forEach((name, i) => {
    const sec = {
      name, start, bars: units[i] * unit, prog, bpc,
      layers: sectionLayers(name, cfg),
      drumVar: 0,
      bassPat: cfg.bass && chance(0.3) ? pick(cfg.bass.patterns || [bassMain]) : bassMain,
      arpPat: cfg.arp ? pick(cfg.arp.rhythms) : '',
      compPat: cfg.comp ? pick(cfg.comp.rhythms) : '',
      phrase: makePhrase(song.motif),
    };
    if (name === 'break' && alt.length && chance(0.45)) sec.prog = pick(alt);
    if (dr) sec.drumVar = name === 'groove' && firstGroove ? 0 : Math.floor(Math.random() * dr.patterns.length);
    if (name === 'groove') firstGroove = false;
    sections.push(sec);
    start += sec.bars * 16;
  });
  sections.forEach((s, i) => {
    const nx = sections[i + 1];
    s.fill = !!nx && s.layers.drums >= 1 && (nx.layers.drums < 1 || chance(0.35));
  });
  // Tail: let the tonic ring for two bars before the next song begins.
  sections.push({
    name: 'end', start, bars: 2, prog: ['1'], bpc: 2, layers: { ...LAYERS.end }, drumVar: 0,
    bassPat: bassMain, arpPat: '', compPat: '', phrase: null, fill: false,
  });
  song.sections = sections;
  song.total = start + 32;
  return song;
}

// ------------------------------------------------------------ stations

const DEFS_LIST = [
  {
    id: 'marimba', name: 'Island Marimba', mood: 'sunny',
    description: 'Bright marimba and kalimba patterns over a soft island shuffle.',
    bpm: [82, 96], modes: ['major', 'major', 'lydian', 'mixolydian'], root: 48,
    progs: [['1', '5', '6', '4'], ['1', '6', '4', '5'], ['1', '4', '1', '5'], ['4', '5', '3', '6'], ['1', '3', '4', '5'], ['6', '4', '1', '5'], ['1', '2', '4', '5']],
    bpc: [1, 2], ext: [[0, 2, 4], [0, 2, 4, 8], [0, 2, 4, 6]], center: 62, swing16: 0.08, trim: 1, tone: 8000,
    fx: { verb: 0.25, delay: { beats: 0.75, fb: 0.32, mix: 0.18 } },
    pad: { wave: 'sine', wave2: 'triangle', detune: 7, cutoff: 1500, gain: 0.03, attack: 1.5, release: 2.5 },
    arp: { voice: 'marimba', rhythms: ['x.x.x.xx.x.x.x.x', 'x..x..x.x..x..x.', 'x.xx.x.xx.x.x.x.', 'x...x.x.x...x.x.'], style: 'walk', octave: 12, gain: 0.12, decay: 0.6, pan: 0.4, prob: 0.85, hi: 86 },
    bass: { voice: 'sub', patterns: ['R-----.5R-----.O', 'R--R--.5R-----..', 'R-------5---O---', 'R-.R-.5-R-.R-.A.'], gain: 0.15, lo: 33 },
    lead: { voice: 'kalimba', octave: 12, gain: 0.1, lo: 67, hi: 88 },
    drums: {
      kit: {
        kick: { f0: 105, f1: 48, dec: 0.32, gain: 0.26 }, shaker: { gain: 0.018 }, conga: { gain: 0.07 },
        bongo: { fn: 'conga', f: 330, dec: 0.16, gain: 0.05 }, clave: { fn: 'rim', f: 2300, dec: 0.05, gain: 0.03, role: 'perc' },
      },
      patterns: [
        { kick: 'x.......x.......', shaker: 'xgogxgogxgogxgog', conga: '......x.....x.x.', bongo: '...x.......x....', clave: 'x..x..x...x.x...' },
        { kick: 'x.....x.x.......', shaker: 'x.o.x.o.x.o.x.o.', conga: '..x...x...x...x.', bongo: '.x.......x......' },
        { kick: 'x.......x...x...', shaker: 'xgogxgogxgogxgog', conga: 'x.....x.......x.', clave: '..x..x....x..x..' },
      ],
      fill: 'conga',
    },
    variants: [{}, { arp: { voice: 'kalimba', decay: 1.1, gain: 0.1 } }, { arp: { voice: 'vibes', decay: 1.4, gain: 0.08 }, lead: { voice: 'flute', gain: 0.06 } }],
  },
  {
    id: 'outrun', name: 'Outrun FM', mood: 'neon',
    description: 'Synthwave night drive: saw pads, pulsing bass, gated snare and glittering arps.',
    bpm: [92, 104], modes: ['minor', 'minor', 'dorian'], root: 45,
    progs: [['1', '6', '3', '7'], ['1', '7', '6', '7'], ['6', '4', '1', '7'], ['1', '4', '7', '3'], ['1', '6', '4', '5M'], ['1', '3', '7', '6']],
    bpc: [1, 2], ext: [[0, 2, 4], [0, 2, 4, 6]], center: 60, trim: 0.9, tone: 7000,
    fx: { verb: 0.3, delay: { beats: 0.75, fb: 0.4, mix: 0.22 } },
    pad: { wave: 'sawtooth', wave2: 'sawtooth', detune: 12, cutoff: 1300, gain: 0.022, attack: 0.8, release: 1.8 },
    arp: { voice: 'saw', rhythms: ['xxxxxxxxxxxxxxxx', 'x.xxx.xxx.xxx.xx', 'x.x.x.x.x.x.x.x.'], style: 'updown', octave: 12, gain: 0.04, decay: 0.2, pan: 0.5, prob: 1, hi: 88 },
    bass: { voice: 'pulsebass', patterns: ['R.O.R.O.R.O.R.O.', 'R.R.R.R.R.R.R.R.', 'R.ROR.ROR.ROR.RO'], gain: 0.1, lo: 33 },
    lead: { voice: 'lead', octave: 12, gain: 0.05, lo: 64, hi: 86 },
    drums: {
      kit: {
        kick: { f0: 150, f1: 45, dec: 0.38, gain: 0.32, click: 0.15 },
        snare: { gated: true, dec: 0.22, tone: 1500, gain: 0.08, verb: 0.6 },
        hat: { gain: 0.016 }, ohat: { fn: 'hat', dec: 0.2, gain: 0.014 },
      },
      patterns: [
        { kick: 'x...x...x...x...', snare: '....x.......x...', hat: '..x...x...x...x.' },
        { kick: 'x...x...x...x...', snare: '....x.......x...', hat: 'g.x.g.x.g.x.g.x.' },
        { kick: 'x...x...x...x.x.', snare: '....x.......x...', hat: '..x...x...x...x.', ohat: '..............x.' },
      ],
      fill: 'tom',
    },
    variants: [{}, { arp: { voice: 'pulse', gain: 0.045 } }, { pad: { wave2: 'square', cutoff: 1100 } }],
  },
  {
    id: 'drift', name: 'Golden Drift', mood: 'warm',
    description: 'Warm FM electric piano and analog pads for the hour before sunset.',
    bpm: [66, 78], modes: ['major', 'lydian', 'mixolydian'], root: 50,
    progs: [['1', '4'], ['1', '3', '4', '4m'], ['4', '5', '3', '6'], ['1', '6', '2', '5'], ['2', '5', '1', '1'], ['1', '5', '4', '4']],
    bpc: [1, 2], ext: [[0, 2, 4, 6], [0, 2, 4, 6, 8]], center: 60, open: true, trim: 1, tone: 6500,
    fx: { verb: 0.35, delay: { beats: 0.75, fb: 0.35, mix: 0.2 } },
    pad: { wave: 'sawtooth', wave2: 'triangle', detune: 9, cutoff: 750, gain: 0.03, attack: 2.2, release: 3.5 },
    comp: { voice: 'epiano', rhythms: ['x...............', 'x.........x.....', 'x.....x.........', '..x.......x.....'], len: 8, gain: 0.06, strum: 0.02 },
    arp: { voice: 'epiano', rhythms: ['x.x.x.x.x.x.x.x.', '..x...x...x...x.', 'x..x..x..x..x...'], style: 'walk', octave: 12, gain: 0.06, decay: 1.4, pan: 0.35, prob: 0.5, hi: 86 },
    bass: { voice: 'sub', patterns: ['R-------....5---', 'R-----------R-5-', 'R-------R---A---'], gain: 0.15, lo: 31 },
    lead: { voice: 'flute', octave: 12, gain: 0.05, lo: 65, hi: 84 },
    drums: {
      kit: { kick: { f0: 100, f1: 45, dec: 0.4, gain: 0.24 }, shaker: { gain: 0.012 }, rim: { gain: 0.03 } },
      patterns: [
        { kick: 'x.........x.....', shaker: 'x.o.x.o.x.o.x.o.', rim: '............x...' },
        { kick: 'x.......x.x.....', shaker: '..o...o...o...o.', rim: '....x.......x...' },
      ],
      fill: 'none',
    },
    variants: [{}, { comp: { voice: 'rhodes' }, arp: { voice: 'rhodes' } }, { lead: { voice: 'vibes', gain: 0.06 } }],
  },
  {
    id: 'lofi', name: 'Lo-fi Coast', mood: 'mellow',
    description: 'Dusty Rhodes sevenths and ninths, swung boom-bap and warm vinyl crackle.',
    bpm: [72, 86], modes: ['dorian', 'major', 'minor'], root: 50,
    progs: {
      major: [['2', '5', '1', '6'], ['4', '3', '2', '1'], ['1', '6', '2', '5'], ['4', '5', '3', '6'], ['1', '4', '3', '6']],
      dorian: [['1', '4'], ['1', '7', '4', '4'], ['1', '2', '4', '1']],
      minor: [['1', '6', '3', '7'], ['1', '4', '6', '5'], ['6', '7', '1', '1'], ['1', '7', '6', '5M']],
    },
    bpc: [1, 2], ext: [[0, 2, 4, 6, 8], [2, 4, 6, 8], [0, 2, 4, 6]], center: 60,
    swing16: 0.2, trim: 1.05, tone: 3600, vinyl: 0.6, wobble: { rate: 0.55, cents: 9, filter: 700, frate: 0.11 },
    fx: { verb: 0.2, delay: { beats: 0.75, fb: 0.3, mix: 0.12 } },
    pad: { wave: 'triangle', wave2: 'sine', detune: 8, cutoff: 900, gain: 0.014, attack: 1.5, release: 2.5 },
    comp: { voice: 'rhodes', rhythms: ['x.........x.....', 'x.....x...x.....', 'x.......x.....x.', '..x.....x.......'], len: 7, gain: 0.07, strum: 0.025 },
    arp: { voice: 'piano', rhythms: ['......x.......x.', '..........x.x...'], style: 'random', octave: 12, gain: 0.04, decay: 1.2, pan: 0.4, prob: 0.5, hi: 86 },
    bass: { voice: 'round', patterns: ['R-----...R--..A.', 'R--...R-..5-....', 'R-----R...R-.5..'], gain: 0.16, lo: 33 },
    lead: { voice: 'flute', octave: 12, gain: 0.04, lo: 64, hi: 82 },
    drums: {
      kit: {
        kick: { f0: 115, f1: 46, dec: 0.45, gain: 0.34 }, snare: { tone: 1700, lp: 3500, dec: 0.2, gain: 0.11 },
        hat: { gain: 0.02, dec: 0.035 }, rim: { gain: 0.03 },
      },
      patterns: [
        { kick: 'x.....x...x.....', snare: '....x.......x...', hat: 'x.xgx.x.x.xgx.x.' },
        { kick: 'x......xx.....x.', snare: '....x.......x..g', hat: 'x.xgx.x.x.x.x.xg' },
        { kick: 'x.....x.x.......', snare: '....x.......x...', hat: 'xgx.xgx.xgx.xgx.' },
      ],
      fill: 'snare',
    },
    variants: [{}, { comp: { voice: 'epiano' } }, { comp: { voice: 'piano', gain: 0.06 } }],
  },
  {
    id: 'glass', name: 'Sea Glass', mood: 'dreamy',
    description: 'Sparse ambient piano in a long reverb. No drums, lots of space.',
    bpm: [56, 68], modes: ['major', 'lydian'], root: 51, ambient: true,
    progs: [['1', '5', '6', '4'], ['1', '3', '6', '4'], ['4', '1', '5', '6'], ['1', '4', '6', '5'], ['6', '4', '1', '5'], ['1', '4']],
    bpc: [2], ext: [[0, 2, 4, 8], [0, 4, 8], [0, 2, 4]], center: 62, open: true, trim: 1.1, tone: 6000,
    fx: { verb: 0.6, delay: { beats: 1.5, fb: 0.4, mix: 0.22 } },
    pad: { wave: 'sine', wave2: 'sine', detune: 5, cutoff: 1000, gain: 0.025, attack: 3, release: 5 },
    arp: { voice: 'piano', rhythms: ['x.......x.......', 'x...........x...', 'x.....x.........', '....x.......x...'], style: 'random', octave: 12, gain: 0.08, decay: 3, pan: 0.3, prob: 0.55, hi: 88 },
    bass: { voice: 'piano', gain: 0.08, lo: 36, simple: true },
    lead: { voice: 'piano', octave: 24, gain: 0.07, lo: 70, hi: 91, rhythms: ['x-------x---x---', 'x---x-------....', 'x-----x-x-------'] },
    drums: null,
  },
  {
    id: 'breeze', name: 'Breezy Afternoon', mood: 'carefree',
    description: 'Fingerpicked guitar, a walking bass and light percussion in bright major keys.',
    bpm: [88, 100], modes: ['major', 'major', 'mixolydian'], root: 50,
    progs: [['1', '4', '5', '4'], ['1', '5', '6', '4'], ['1', '2', '4', '1'], ['1', '6', '2', '5'], ['4', '1', '5', '5'], ['1', '3', '4', '5'], ['1', '7m', '4', '1']],
    bpc: [1, 2], ext: [[0, 2, 4], [0, 2, 4, 8], [0, 3, 4]], center: 59, swing16: 0.05, trim: 1, tone: 7000,
    fx: { verb: 0.22, delay: { beats: 0.5, fb: 0.2, mix: 0.1 } },
    pad: { wave: 'triangle', wave2: 'sine', detune: 6, cutoff: 1100, gain: 0.018, attack: 1.5, release: 2.5 },
    arp: { voice: 'guitar', rhythms: ['x.x.x.x.x.x.x.x.', 'x.xxx.x.x.xxx.x.', 'x..x..x.x..x..x.'], style: 'pattern', order: [0, 2, 1, 3, 0, 2, 1, 3], octave: 0, gain: 0.09, decay: 1.2, pan: 0.3, prob: 0.95, hi: 84 },
    bass: { voice: 'upright', patterns: ['W---W---W---W---', 'R-----5-R-----A-', 'W---W---W---W---'], gain: 0.15, lo: 33 },
    lead: { voice: 'flute', octave: 12, gain: 0.05, lo: 67, hi: 86 },
    drums: {
      kit: { kick: { f0: 100, f1: 50, dec: 0.3, gain: 0.22 }, rim: { gain: 0.04 }, hat: { gain: 0.014 }, shaker: { gain: 0.014 } },
      patterns: [
        { kick: 'x.......x.x.....', rim: '....x.......x...', hat: 'x.x.x.x.x.x.x.x.' },
        { kick: 'x.....x...x.....', rim: '....x.......x...', shaker: 'x.o.x.o.x.o.x.oo' },
        { kick: 'x.......x.......', rim: '....x.......x..g', hat: 'x.xgx.x.x.xgx.x.' },
      ],
      fill: 'none',
    },
    variants: [{}, { arp: { order: [0, 3, 2, 3, 1, 3, 2, 3] } }, { lead: { voice: 'vibes', gain: 0.06 } }],
  },
  {
    id: 'deep', name: 'Deep Blue', mood: 'meditative',
    description: 'Slow evolving drones with the odd distant bell. No beat, just tide.',
    bpm: [50, 58], modes: ['dorian', 'minor', 'lydian'], root: 45, ambient: true,
    progs: [['1', '7'], ['1', '6'], ['1', '4'], ['1', '3', '6', '7'], ['1', '1', '6', '6'], ['1', '2']],
    bpc: [2, 4], ext: [[0, 4, 8], [0, 2, 4, 8], [0, 4, 6, 9]], center: 57, open: true, trim: 1.15, tone: 3500,
    fx: { verb: 0.7, delay: { beats: 2, fb: 0.45, mix: 0.25 } },
    pad: { wave: 'sawtooth', wave2: 'triangle', detune: 8, cutoff: 600, gain: 0.035, attack: 5, release: 7 },
    arp: { voice: 'bell', rhythms: ['x...............', '........x.......', 'x.......x.......'], style: 'random', octave: 24, gain: 0.04, decay: 4.5, pan: 0.6, prob: 0.3, hi: 90 },
    bass: { voice: 'drone', gain: 0.12, lo: 28, simple: true },
    lead: { voice: 'bell', octave: 24, gain: 0.035, lo: 72, hi: 93, rhythms: ['x-------x-------', 'x---------------', 'x-----------x---'] },
    drums: null,
  },
  {
    id: 'nightjazz', name: 'Night Jazz', mood: 'smoky',
    description: 'Brushed drums, walking upright bass and soft ii–V–I voicings after dark.',
    bpm: [80, 100], modes: ['major', 'major', 'dorian', 'minor'], root: 50,
    progs: {
      major: [['2', '5', '1', '1'], ['1', '6', '2', '5'], ['3', '6', '2', '5'], ['2', '5', '1', '6'], ['1', '4', '3', '6', '2', '5', '1', '1'], ['4', '4m', '3', '6']],
      dorian: [['1', '4'], ['1', '1', '4', '4'], ['1', '4', '7', '3']],
      minor: [['2', '5M', '1', '1'], ['1', '4', '5M', '1'], ['1', '6', '2', '5M']],
    },
    bpc: [1, 2], ext: [[2, 6, 8, 12], [0, 2, 4, 6, 8], [2, 6, 8], [0, 2, 6, 8]], center: 60, swing8: 0.62, trim: 1, tone: 6000,
    fx: { verb: 0.3, delay: { beats: 0.75, fb: 0.2, mix: 0.06 } },
    comp: { voice: 'epiano', rhythms: ['x.....x.........', '......x.....x...', '..x.....x.......', 'x.........x.....', '...x......x.....'], len: 5, gain: 0.055, strum: 0.015 },
    bass: { voice: 'upright', patterns: ['W---W---W---W---'], gain: 0.17, lo: 31 },
    lead: { voice: 'vibes', octave: 12, gain: 0.07, lo: 65, hi: 86, rhythms: ['x--x-x--x-------', '..x-x-x-x---....', 'x-x---x-x-x-----', 'x---..x-x-x-x---'] },
    drums: {
      kit: {
        ride: { gain: 0.02 }, brush: { gain: 0.03, dec: 0.3 }, hat: { dec: 0.03, gain: 0.012 },
        kick: { f0: 80, f1: 45, dec: 0.25, gain: 0.12 }, snare: { fn: 'brush', dec: 0.35, gain: 0.03 },
      },
      patterns: [
        { ride: 'x...x.x.x...x.x.', brush: 'o.o.o.o.o.o.o.o.', snare: '....x.......x...', hat: '....x.......x...', kick: 'g...............' },
        { ride: 'x...x.xgx...x.x.', brush: 'o...o...o...o...', snare: '....x.....g.x...', hat: '....x.......x...' },
        { ride: 'x.....x.x.....x.', brush: 'o.o.o.o.o.o.o.o.', hat: '....x.......x...' },
      ],
      fill: 'snare',
    },
    variants: [{}, { comp: { voice: 'piano', gain: 0.05 } }, { lead: { voice: 'horn', gain: 0.045 } }],
  },
  {
    id: 'chillhouse', name: 'Seaside House', mood: 'breezy',
    description: 'Mellow deep house: soft four-on-the-floor, offbeat hats and warm chord stabs.',
    bpm: [116, 121], modes: ['minor', 'dorian', 'major'], root: 48,
    progs: {
      minor: [['1', '6', '7', '1'], ['1', '4', '7', '3'], ['1', '6', '3', '7'], ['1', '7', '6', '7']],
      dorian: [['1', '4'], ['1', '2'], ['1', '7', '4', '1']],
      major: [['1', '3', '6', '4'], ['2', '5', '1', '6'], ['4', '5', '3', '6']],
    },
    bpc: [2], ext: [[0, 2, 4, 6, 8], [0, 2, 4, 6], [2, 4, 6, 8]], center: 60, swing16: 0.06, trim: 0.9, tone: 6500,
    fx: { verb: 0.25, delay: { beats: 0.75, fb: 0.35, mix: 0.15 } },
    pad: { wave: 'triangle', wave2: 'sawtooth', detune: 10, cutoff: 900, gain: 0.016, attack: 2, release: 3 },
    comp: { voice: 'stab', rhythms: ['...x..x....x..x.', '..x...x...x...x.', '...x.....x....x.', 'x..x..x...x..x..'], len: 2, gain: 0.05, strum: 0 },
    arp: { voice: 'pluck', rhythms: ['x..x..x...x..x..', '..x...x.x...x...'], style: 'walk', octave: 12, gain: 0.045, decay: 0.35, pan: 0.5, prob: 0.6, hi: 86 },
    bass: { voice: 'fm', patterns: ['..R...R...R...R.', '..R..5.R..R..O..', 'R.R...R...R.5.R.', '..R-..R-..R-..A-'], gain: 0.13, lo: 31 },
    lead: { voice: 'vibes', octave: 12, gain: 0.05, lo: 67, hi: 86 },
    drums: {
      kit: {
        kick: { f0: 130, f1: 48, dec: 0.42, gain: 0.32 }, clap: { gain: 0.05, verb: 0.3 }, hat: { gain: 0.012, dec: 0.03 },
        ohat: { fn: 'hat', dec: 0.16, gain: 0.016 }, shaker: { gain: 0.01 }, rim: { gain: 0.025, role: 'perc' },
      },
      patterns: [
        { kick: 'x...x...x...x...', clap: '....x.......x...', ohat: '..x...x...x...x.', shaker: 'gggggggggggggggg' },
        { kick: 'x...x...x...x...', clap: '....x.......x...', ohat: '..x...x...x...x.', hat: 'x.g.x.g.x.g.x.g.', rim: '.......x......x.' },
        { kick: 'x...x...x...x...', clap: '............x...', ohat: '..x...x...x...x.', hat: 'g.g.g.g.g.g.g.g.' },
      ],
      fill: 'none',
    },
    variants: [{}, { comp: { voice: 'epiano', len: 3, gain: 0.05 } }, { arp: null }],
  },
];

const DEFS = Object.fromEntries(DEFS_LIST.map((d) => [d.id, d]));
const OFF = { id: 'off', name: 'Radio Off', description: 'Just the sea, the wind and the road.', mood: 'quiet' };

export const STATIONS = [
  ...DEFS_LIST.map(({ id, name, description, mood }) => ({ id, name, description, mood })),
  OFF,
];

// ------------------------------------------------------------ deck (one playing station)

class Deck {
  constructor(engine, st) {
    const ctx = (this.ctx = engine.ctx), now = ctx.currentTime;
    this.st = st;
    this.pool = new Pool(ctx);
    this.persist = [];
    this.sources = [];
    this.kit = {};
    const node = (n) => (this.persist.push(n), n);
    const gain = (v) => { const g = node(ctx.createGain()); g.gain.value = v; return g; };

    // input -> tone -> fader -> music bus; post-fader sends to the shared hall and a tempo delay.
    this.input = gain(1);
    this.tone = node(ctx.createBiquadFilter());
    this.tone.type = 'lowpass';
    this.tone.frequency.value = st.tone || 8000;
    this.tone.Q.value = 0.5;
    this.fader = gain(0);
    this.input.connect(this.tone);
    this.tone.connect(this.fader);
    this.fader.connect(engine.musicBus);
    const verb = gain(st.fx.verb);
    this.fader.connect(verb);
    verb.connect(engine.hall);
    this.delay = node(ctx.createDelay(4));
    const dsend = gain(st.fx.delay.mix), dfb = gain(st.fx.delay.fb), dlp = node(ctx.createBiquadFilter());
    dlp.type = 'lowpass';
    dlp.frequency.value = 2200;
    this.fader.connect(dsend);
    dsend.connect(this.delay);
    this.delay.connect(dlp);
    dlp.connect(dfb);
    dfb.connect(this.delay);
    dlp.connect(engine.musicBus);
    // extra reverb-only send (gated snare, claps); faded with the deck
    this.wet = gain(1);
    this.wetFader = gain(0);
    this.wet.connect(this.wetFader);
    this.wetFader.connect(engine.hall);

    if (st.vinyl) {
      const hiss = node(ctx.createBufferSource()), bp = node(ctx.createBiquadFilter()), hg = gain(st.vinyl * 0.004);
      hiss.buffer = NOISE.white;
      hiss.loop = true;
      bp.type = 'bandpass';
      bp.frequency.value = 3000;
      bp.Q.value = 0.3;
      hiss.connect(bp);
      bp.connect(hg);
      hg.connect(this.input);
      hiss.start(now);
      this.sources.push(hiss);
    }
    if (st.wobble) { // tape wow on pitch plus a slow sweep of the tone filter
      const w = st.wobble, lfo = node(ctx.createOscillator()), dg = gain(w.cents);
      lfo.frequency.value = w.rate;
      lfo.connect(dg);
      lfo.start(now);
      this.pool.wobble = dg;
      const lfo2 = node(ctx.createOscillator()), fg = gain(w.filter);
      lfo2.frequency.value = w.frate;
      lfo2.connect(fg);
      fg.connect(this.tone.frequency);
      lfo2.start(now);
      this.sources.push(lfo, lfo2);
    }

    this.song = null;
    this.lastVoicing = null;
    this.lastBass = 0;
    this.lastLead = 0;
    this.arpI = 0;
    this.arpW = 2;
    this.leadOn = false;
    this.stopAt = Infinity;
    this.disposeAt = Infinity;
    this.newSong();
    this.nextTime = now + 0.12;
  }

  fadeIn(dur) {
    const t = this.ctx.currentTime, g = this.st.trim || 1;
    for (const f of [this.fader, this.wetFader]) {
      f.gain.setValueAtTime(0, t);
      f.gain.linearRampToValueAtTime(g, t + dur);
    }
  }

  fadeOut(dur) {
    const t = this.ctx.currentTime;
    for (const f of [this.fader, this.wetFader]) {
      hold(f.gain, t);
      f.gain.linearRampToValueAtTime(0, t + dur);
    }
  }

  dispose() {
    this.pool.killAll();
    for (const s of this.sources) { try { s.stop(); } catch (e) { /* already stopped */ } }
    for (const n of this.persist) n.disconnect();
    this.sources.length = 0;
    this.persist.length = 0;
    this.pool.wobble = null;
  }

  newSong() {
    const first = !this.song;
    this.song = makeSong(this.st, this.song);
    this.cfg = this.song.cfg;
    this.step = 0;
    this.secIdx = 0;
    this.sec = this.song.sections[0];
    this.sd = 60 / this.song.bpm / 4;
    const dt = clamp((this.st.fx.delay.beats * 60) / this.song.bpm, 0.05, 3.5);
    if (first) this.delay.delayTime.value = dt;
    else this.delay.delayTime.setTargetAtTime(dt, this.ctx.currentTime, 0.4);
  }

  // Lookahead scheduling. If the tab slept, skip the missed steps instead of bursting them.
  schedule(until, now) {
    if (this.nextTime < now - 0.05) this.nextTime = now + 0.05;
    while (this.nextTime < until) {
      this.playStep(this.nextTime);
      this.nextTime += this.sd;
      if (++this.step >= this.song.total) this.newSong();
    }
  }

  playStep(t0) {
    const song = this.song, cfg = this.cfg, sd = this.sd, secs = song.sections;
    while (this.secIdx < secs.length - 1 && this.step >= secs[this.secIdx + 1].start) this.secIdx++;
    const sec = (this.sec = secs[this.secIdx]), L = sec.layers;
    const local = this.step - sec.start, bar = Math.floor(local / 16), i = local % 16;
    const cs = sec.bpc * 16, atChord = local % cs === 0, end = sec.name === 'end';
    if (atChord) this.changeChord(sec, Math.floor(local / cs) % sec.prog.length, local + cs >= sec.bars * 16);
    const ch = this.chord, toChange = cs - (local % cs);
    let t = t0;
    if (i % 2 === 1) t += song.swing16 * sd;
    if (i % 4 === 2) t += song.swing8 * sd;
    const hum = () => t + rand(-0.006, 0.006);

    if (cfg.pad && L.pad > 0 && atChord) this.pad(ch.voicing, t0, cs * sd, cfg.pad, L.pad);

    if (cfg.comp && L.comp > 0) {
      if (end) { if (local === 0) this.comp(ch, t0, 0.8, cs); }
      else {
        const v = hit(sec.compPat, local);
        if (v && chance(0.35 + 0.65 * L.comp)) this.comp(ch, hum(), v * (0.6 + 0.4 * L.comp), Math.min(cfg.comp.len || 4, toChange));
      }
    }

    if (cfg.bass && L.bass > 0) this.bassStep(sec, local, atChord, toChange, hum(), L.bass);

    if (cfg.arp && L.arp > 0) {
      const v = hit(sec.arpPat, local);
      if (v && chance((cfg.arp.prob ?? 0.9) * L.arp)) this.arpNote(ch, hum(), v);
    }

    if (cfg.lead && L.lead > 0 && sec.phrase) this.leadStep(sec, bar, i, hum(), ch, L.lead);

    if (this.st.drums && !end) this.drumStep(sec, bar, local, i, t, L);
    if (this.st.vinyl && chance(this.st.vinyl * 0.3)) this.drum('crackle', t0 + rand(0, sd), rand(0.2, 1));
  }

  // ---- harmony

  changeChord(sec, ci, lastInSection) {
    this.chord = this.realize(sec.prog[ci]);
    let nt;
    if (lastInSection) {
      const ns = this.song.sections[this.secIdx + 1];
      nt = ns ? ns.prog[0] : '1';
    } else nt = sec.prog[(ci + 1) % sec.prog.length];
    this.nextRoot = this.bassRootOf(this.rootMidi(nt));
    if (this.cfg.arp && this.cfg.arp.style !== 'walk') this.arpI = 0;
  }

  realize(tok) {
    const s = this.song, { deg, mode } = parseToken(tok, s.mode);
    const root = scaleNote(s.tonic, mode, deg);
    const tones = s.ext.map((e) => scaleNote(s.tonic, mode, deg + e));
    const voicing = voiceLead(tones, this.lastVoicing, this.st.center || 60, this.st.open);
    this.lastVoicing = voicing;
    const iv = (e) => mod12(scaleNote(s.tonic, mode, deg + e) - root);
    const ch = {
      deg, mode, root, voicing,
      pcs: new Set([mod12(root), ...tones.map(mod12)]),
      third: iv(2), fifth: iv(4), seventh: iv(6) || 10,
      bassRoot: this.bassRootOf(root),
    };
    const a = this.cfg.arp;
    if (a) {
      const oct = a.octave || 0, set = new Set();
      for (const m of voicing) { set.add(m + oct); set.add(m + oct + 12); }
      let pool = [...set].sort((x, y) => x - y).filter((m) => m <= (a.hi || 88));
      if (!pool.length) pool = voicing.slice();
      ch.pool = pool;
      this.arpW = clamp(this.arpW, 0, pool.length - 1);
    }
    return ch;
  }

  rootMidi(tok) {
    const { deg, mode } = parseToken(tok, this.song.mode);
    return scaleNote(this.song.tonic, mode, deg);
  }

  bassRootOf(m) {
    const lo = (this.cfg.bass && this.cfg.bass.lo) || 33;
    return lo + mod12(m - lo);
  }

  // ---- parts

  note(kind, midi, t, o) {
    const fn = TONES[kind] || TONES.pluck;
    const v = this.pool.voice(this.input, o.group || 'note', o.max || 8, t, o.pan || 0);
    v.stop(fn(v, mtof(midi), Math.max(0.0005, o.gain), o));
  }

  pad(notes, t, dur, p, lvl) {
    const v = this.pool.voice(this.input, 'pad', 2, t, 0);
    t = v.t;
    const n = notes.length, rel = p.release;
    const end = adsr(v.out.gain, t, Math.min(p.attack, dur * 0.6), (p.gain * lvl * 2) / Math.sqrt(n), dur, rel);
    const f = v.filter('lowpass', p.cutoff * 0.6, 0.5);
    f.frequency.setValueAtTime(p.cutoff * 0.6, t);
    f.frequency.linearRampToValueAtTime(p.cutoff, t + dur * 0.5);
    f.frequency.linearRampToValueAtTime(p.cutoff * 0.7, t + dur + rel);
    const l = v.pan(-0.4, f), r = v.pan(0.4, f);
    for (const m of notes) {
      const fr = mtof(m + (p.octave || 0));
      v.osc(p.wave, fr, l, -p.detune + rand(-2, 2));
      v.osc(p.wave2 || p.wave, fr, r, p.detune + rand(-2, 2));
    }
    v.stop(end);
  }

  comp(ch, t, vel, steps) {
    const c = this.cfg.comp, notes = ch.voicing, n = notes.length, dur = steps * this.sd;
    const decay = Math.min(c.decay || 2.5, Math.max(0.3, dur * 1.3)), g = (c.gain * vel * 1.6) / Math.sqrt(n);
    notes.forEach((m, k) => this.note(c.voice, m + (c.octave || 0), t + k * (c.strum || 0) * rand(0.6, 1.2), {
      gain: g * rand(0.85, 1), dur, decay, group: 'comp', max: 10, pan: n > 1 ? (k / (n - 1) - 0.5) * 0.5 : 0,
    }));
  }

  arpNote(ch, t, vel) {
    const a = this.cfg.arp, pool = ch.pool, n = pool.length;
    let idx;
    switch (a.style) {
      case 'up': idx = this.arpI % n; break;
      case 'updown': { const cyc = Math.max(1, n * 2 - 2), p = this.arpI % cyc; idx = p < n ? p : cyc - p; break; }
      case 'pattern': idx = a.order[this.arpI % a.order.length] % n; break;
      case 'random': idx = Math.floor(Math.random() * n); break;
      default: idx = this.arpW = clamp(this.arpW + pick([-2, -1, -1, 1, 1, 2]), 0, n - 1);
    }
    this.arpI++;
    this.note(a.voice, pool[idx], t, {
      gain: a.gain * vel * rand(0.8, 1), decay: a.decay, dur: this.sd * 2, pan: rand(-a.pan, a.pan), group: 'arp', max: a.max || 6,
    });
  }

  bassStep(sec, local, atChord, toChange, t, lvl) {
    const b = this.cfg.bass, ch = this.chord, sd = this.sd;
    if (b.simple || lvl < 1) {
      if (atChord) this.bassNote(ch.bassRoot, t, toChange * sd * 0.96, 0.85);
      return;
    }
    const pat = sec.bassPat, n = pat.length, c = pat[local % n];
    if (!c || c === '.' || c === '-') return;
    let len = 1;
    while (len < toChange && pat[(local + len) % n] === '-') len++;
    let m;
    switch (c) {
      case '5': m = ch.bassRoot + ch.fifth; break;
      case 'O': m = ch.bassRoot + 12; break;
      case '3': m = ch.bassRoot + ch.third; break;
      case '7': m = ch.bassRoot + ch.seventh; break;
      case 'A': m = this.approach(); break;
      case 'W': m = this.walk(atChord, toChange); break;
      default: m = ch.bassRoot;
    }
    this.bassNote(m, t, len * sd * 0.92, (atChord ? 1 : 0.85) * rand(0.9, 1));
  }

  bassNote(m, t, dur, vel) {
    const b = this.cfg.bass;
    this.note(b.voice, m, t, { gain: b.gain * vel, dur, decay: b.decay, group: 'bass', max: 3 });
    this.lastBass = m;
  }

  // Leading note into the next chord: chromatic from either side or from its fifth.
  approach() {
    const lo = this.cfg.bass.lo || 33, g = this.nextRoot;
    const opts = [g - 1, g + 1, g + 7, g - 5].filter((m) => m >= lo && m <= lo + 20);
    return opts.length ? pick(opts) : g;
  }

  // Walking bass: root on the chord, approach before the change, stepwise chord/scale tones between.
  walk(atChord, toChange) {
    const ch = this.chord, lo = this.cfg.bass.lo || 33, hi = lo + 19, last = this.lastBass || ch.bassRoot;
    if (atChord) {
      let r = ch.bassRoot;
      if (r + 12 <= hi && Math.abs(r + 12 - last) < Math.abs(r - last)) r += 12;
      return r;
    }
    if (toChange <= 4) return this.approach();
    const goal = this.nextRoot, cands = [];
    for (let m = last - 5; m <= last + 5; m++) {
      const pc = mod12(m);
      if (m === last || m < lo || m > hi || !(this.song.scale.has(pc) || ch.pcs.has(pc))) continue;
      let w = ch.pcs.has(pc) ? 3 : 1;
      if (Math.sign(goal - last) === Math.sign(m - last)) w *= 1.6;
      cands.push([m, w]);
    }
    return cands.length ? weighted(cands) : ch.bassRoot;
  }

  leadStep(sec, bar, i, t, ch, lvl) {
    const pb = bar % 4;
    if (i === 0 && pb === 0) this.leadOn = chance(lvl >= 1 ? 0.8 : lvl * 0.7);
    if (!this.leadOn) return;
    const n = sec.phrase[pb][i];
    if (!n) return;
    const ld = this.cfg.lead, lo = ld.lo || 64, hi = ld.hi || 86;
    let m = scaleNote(this.song.tonic, ch.mode, ch.deg + n.deg) + (ld.octave ?? 12);
    while (m > hi) m -= 12;
    while (m < lo) m += 12;
    if (this.lastLead) {
      if (m - this.lastLead > 9 && m - 12 >= lo) m -= 12;
      else if (this.lastLead - m > 9 && m + 12 <= hi) m += 12;
    }
    if ((i % 8 === 0 || n.len >= 6) && !ch.pcs.has(mod12(m))) { // strong beats land on chord tones
      for (const d of [-1, 1, -2, 2]) if (ch.pcs.has(mod12(m + d))) { m += d; break; }
    }
    this.lastLead = m;
    this.note(ld.voice, m, t, {
      gain: ld.gain * rand(0.85, 1), dur: n.len * this.sd * 0.92, decay: ld.decay, group: 'lead', max: 3, pan: rand(-0.15, 0.15),
    });
  }

  // ---- drums

  kitEntry(name) {
    let k = this.kit[name];
    if (!k) {
      const src = (this.st.drums && this.st.drums.kit[name]) || {}, fn = src.fn || name;
      k = this.kit[name] = { ...src, fn, role: src.role || DRUM_ROLE[name] || DRUM_ROLE[fn] || 'perc', wet: this.wet };
    }
    return k;
  }

  drum(name, t, vel, f) {
    const k = this.kitEntry(name), fn = DRUMS[k.fn];
    if (!fn) return;
    const g = (k.gain ?? DRUM_GAIN[k.fn] ?? 0.05) * vel;
    if (g <= 0) return;
    const fx = k.fn === 'crackle';
    const v = this.pool.voice(this.input, fx ? 'fx' : 'drum', fx ? 4 : 16, t, fx ? rand(-0.7, 0.7) : (k.pan ?? DRUM_PAN[k.fn] ?? 0));
    v.stop(fn(v, g, k, f));
  }

  drumStep(sec, bar, local, i, t, L) {
    if (L.drums <= 0 && L.perc <= 0) return;
    const dr = this.st.drums, pat = dr.patterns[sec.drumVar] || dr.patterns[0];
    for (const name in pat) {
      let vel = hit(pat[name], local);
      if (!vel) continue;
      const role = this.kitEntry(name).role;
      if (role === 'kick') { if (L.drums <= 0) continue; }
      else if (role === 'back') { if (L.drums < 1) continue; }
      else { if (L.perc <= 0) continue; vel *= L.perc; }
      this.drum(name, t + rand(-0.003, 0.003), vel * rand(0.88, 1.04));
    }
    if (sec.fill && L.drums >= 1 && bar === sec.bars - 1 && i >= 12) { // soft fill into the next section
      if (dr.fill === 'snare' && i >= 13 && chance(0.7)) this.drum('snare', t, 0.25 + (i - 13) * 0.15);
      else if (dr.fill === 'tom') this.drum('tom', t, 0.6, 190 - (i - 12) * 25);
      else if (dr.fill === 'conga' && i !== 13) this.drum('conga', t, 0.7, 260 - (i - 12) * 15);
    }
  }
}

// ------------------------------------------------------------ ambience

class Ambience {
  constructor(eng) {
    const ctx = (this.ctx = eng.ctx);
    this.eng = eng;
    this.pool = new Pool(ctx);
    this.out = ctx.createGain();
    this.out.connect(eng.sfxVol);
    const loop = (buf, rate = 1) => {
      const s = ctx.createBufferSource();
      s.buffer = buf; s.loop = true; s.playbackRate.value = rate; s.start();
      return s;
    };
    const filt = (type, f, q, src) => {
      const b = ctx.createBiquadFilter();
      b.type = type; b.frequency.value = f; b.Q.value = q;
      if (src) src.connect(b);
      return b;
    };
    const gain = (v, src, dest) => {
      const g = ctx.createGain();
      g.gain.value = v;
      if (src) src.connect(g);
      if (dest) g.connect(dest);
      return g;
    };
    const pan = (v, src, dest) => {
      const p = ctx.createStereoPanner();
      p.pan.value = v;
      src.connect(p);
      p.connect(dest);
      return p;
    };
    // A few looping noise beds shared by every ambient layer.
    this.white = loop(NOISE.white);
    this.brown = loop(NOISE.brown);
    this.brown2 = loop(NOISE.brown, 0.81);

    // ocean (sea on the right): swelling surf, foam fizz on each crest, constant low wash
    this.oceanLvl = gain(0);
    pan(0.45, this.oceanLvl, this.out);
    this.surfLp = filt('lowpass', 500, 0.3, this.brown);
    this.surf = gain(0.06, this.surfLp, this.oceanLvl);
    this.fizz = gain(0, filt('bandpass', 2800, 0.5, this.white), this.oceanLvl);
    gain(0.22, filt('lowpass', 220, 0.5, this.brown2), this.oceanLvl);
    this.nextSwell = ctx.currentTime + 0.2;

    // rain: soft hiss on the road plus a duller patter on the roof; droplet ticks are scheduled
    this.rainBed = gain(0, filt('lowpass', 5500, 0.5, filt('highpass', 600, 0.5, this.white)), this.out);
    this.rainBody = gain(0, filt('bandpass', 1300, 0.8, this.white), this.out);

    // wind: two independently gusting bands, left and right
    this.windLvl = gain(0, null, this.out);
    this.wind = [[this.brown, -0.6, 500], [this.brown2, 0.6, 800]].map(([src, p, f]) => {
      const bp = filt('bandpass', f, 0.9, src), g = gain(0.5, bp);
      pan(p, g, this.windLvl);
      return { bp, g };
    });
    this.nextGust = 0;

    // night: a faint trilling cricket bed on the land side (left); single chirps are scheduled
    this.nightLvl = gain(0);
    pan(-0.5, this.nightLvl, this.out);
    const am = gain(0, filt('bandpass', 4600, 8, this.white), this.nightLvl);
    const lfo = ctx.createOscillator();
    lfo.frequency.value = 27;
    gain(1, lfo, am.gain);
    lfo.start();
    this.nextOwl = ctx.currentTime + rand(30, 90);

    // road: tyre roar with speed, a little hiss, gravel crunch and rumble on the shoulder
    this.tyreLp = filt('lowpass', 200, 0.5, this.brown);
    this.tyre = gain(0, this.tyreLp, this.out);
    this.hiss = gain(0, filt('bandpass', 900, 0.6, this.white), this.out);
    this.crunch = gain(0, filt('bandpass', 1200, 0.7, this.white));
    this.gravel = gain(0, this.crunch, this.out);
    this.rumble = gain(0, filt('lowpass', 140, 0.7, this.brown), this.out);
    this.gravelOn = false;
    this.grainLvl = 0;
    this.until = 0;
  }

  windLevel() {
    const a = this.eng.amb, sp = clamp(this.eng.speedNow() / 35, 0, 1);
    return clamp(a.wind * 0.75 + sp * 0.35, 0, 1) * 0.55 * (1 - 0.6 * a.tunnel);
  }

  apply() {
    const t = this.ctx.currentTime, a = this.eng.amb, road = this.eng.road, sp = this.eng.speedNow();
    const s35 = clamp(sp / 35, 0, 1);
    this.oceanLvl.gain.setTargetAtTime(0.9 * a.ocean * (1 - 0.7 * a.tunnel), t, 0.6);
    this.rainBed.gain.setTargetAtTime(0.05 * a.rain, t, 0.8);
    this.rainBody.gain.setTargetAtTime(0.03 * a.rain * a.rain, t, 0.8);
    this.nightLvl.gain.setTargetAtTime(0.3 * a.night, t, 1.5);
    this.windLvl.gain.setTargetAtTime(this.windLevel(), t, 0.8);
    this.tyre.gain.setTargetAtTime(0.07 * Math.pow(s35, 1.3), t, 0.3);
    this.tyreLp.frequency.setTargetAtTime(180 + sp * 14, t, 0.3);
    this.hiss.gain.setTargetAtTime(0.01 * clamp(sp / 40, 0, 1), t, 0.3);
    const gv = road.surface === 'gravel' ? clamp(sp / 15, 0, 1) : 0;
    this.gravelOn = gv > 0.03;
    this.grainLvl = 0.05 * gv;
    this.gravel.gain.setTargetAtTime(0.06 * gv, t, 0.15);
    this.rumble.gain.setTargetAtTime(0.25 * gv, t, 0.15);
  }

  tick(now, until) {
    const a = this.eng.amb, from = Math.max(this.until, now), span = until - from;
    this.until = Math.max(this.until, until);
    this.swell(now);
    if (now >= this.nextGust) this.gust(now);
    if (span > 0) {
      if (a.rain > 0.02) this.spawn(a.rain * 14 * span, from, span, (t) => this.drop(t, a.rain));
      if (a.night > 0.02) this.spawn(a.night * 0.9 * span, from, span, (t) => this.chirp(t, a.night));
      if (this.gravelOn) this.spawn(Math.min(25, this.eng.speedNow() * 1.2) * span, from, span, (t) => this.grain(t));
    }
    if (this.gravelOn) this.crunch.gain.setTargetAtTime(rand(0.15, 1), now, 0.015);
    if (a.night > 0.4 && now > this.nextOwl) {
      this.owl(now + 0.1, a.night);
      this.nextOwl = now + rand(45, 120);
    }
  }

  spawn(expected, from, span, fn) {
    let n = Math.min(12, Math.floor(expected + Math.random()));
    while (n-- > 0) fn(from + Math.random() * span);
  }

  swell(now) {
    if (now + 1 < this.nextSwell) return;
    const t = Math.max(this.nextSwell, now), dur = rand(5.5, 9.5), lvl = rand(0.45, 0.85);
    const g = this.surf.gain, lp = this.surfLp.frequency, fz = this.fizz.gain;
    g.setTargetAtTime(lvl * 0.5, t, dur * 0.18);
    g.setTargetAtTime(lvl * 0.12, t + dur * 0.45, dur * 0.25);
    lp.setTargetAtTime(1300, t, dur * 0.2);
    lp.setTargetAtTime(380, t + dur * 0.45, dur * 0.25);
    fz.setTargetAtTime(lvl * 0.035, t + dur * 0.3, dur * 0.08);
    fz.setTargetAtTime(0, t + dur * 0.5, dur * 0.2);
    this.nextSwell = t + dur;
  }

  gust(now) {
    const sp = clamp(this.eng.speedNow() / 35, 0, 1);
    this.windLvl.gain.setTargetAtTime(this.windLevel(), now, 0.8);
    for (const w of this.wind) {
      w.bp.frequency.setTargetAtTime(rand(280, 850) * (1 + sp * 0.5), now, rand(0.5, 1.4));
      w.g.gain.setTargetAtTime(rand(0.25, 1), now, rand(0.4, 1.2));
    }
    this.nextGust = now + rand(0.7, 2.2);
  }

  drop(t, rain) {
    const v = this.pool.voice(this.out, 'drop', 20, t, rand(-0.8, 0.8)), s = v.t, f = rand(1500, 4000);
    const o = v.osc('sine', f);
    o.frequency.setValueAtTime(f, s);
    o.frequency.exponentialRampToValueAtTime(f * 0.55, s + 0.03);
    perc(v.out.gain, s, 0.001, 0.008 * rain * rand(0.3, 1), 0.04);
    v.stop(s + 0.06);
  }

  chirp(t, night) {
    const v = this.pool.voice(this.out, 'chirp', 6, t, rand(-0.95, -0.35)), s = v.t, p = v.out.gain;
    const pulses = 2 + Math.floor(Math.random() * 4), g = 0.006 * night * rand(0.4, 1);
    v.osc('sine', rand(4200, 4900));
    p.setValueAtTime(0, s);
    for (let k = 0; k < pulses; k++) {
      const a = s + k * 0.045;
      p.setValueAtTime(0, a);
      p.linearRampToValueAtTime(g, a + 0.008);
      p.linearRampToValueAtTime(0, a + 0.03);
    }
    v.stop(s + pulses * 0.045 + 0.05);
  }

  owl(t, night) {
    for (let k = 0; k < 2; k++) {
      const v = this.pool.voice(this.out, 'owl', 2, t + k * 0.45, -0.7), s = v.t;
      const o = v.osc('sine', 400);
      o.frequency.setValueAtTime(400, s);
      o.frequency.exponentialRampToValueAtTime(360, s + 0.3);
      v.osc('sine', 780, v.gain(0.08));
      v.stop(adsr(v.out.gain, s, 0.06, 0.012 * night, 0.22 + k * 0.12, 0.15));
    }
  }

  grain(t) {
    const v = this.pool.voice(this.out, 'grain', 10, t, rand(-0.3, 0.3)), dec = rand(0.01, 0.03);
    perc(v.out.gain, v.t, 0.001, this.grainLvl * rand(0.3, 1), dec);
    v.noise(NOISE.white, v.filter('bandpass', rand(600, 2400), 1.4));
    v.stop(v.t + dec + 0.02);
  }
}

// ------------------------------------------------------------ engine sound

const DEFAULT_PROFILE = { cylinders: 4, idle: 800, redline: 6500, character: 'smooth', volume: 1 };
const CHARACTER = {
  smooth: { saw: 0.3, tri: 1, sine: 0.35, am: 0.06, lp: 2.2, q: 0.6, intake: 0.5 },
  rumble: { saw: 0.55, tri: 1, sine: 0.15, am: 0.32, lp: 1.8, q: 0.9, intake: 0.7 },
  buzzy: { saw: 1, tri: 0.35, sine: 0.45, am: 0.12, lp: 3.2, q: 1.6, intake: 1 },
};

// Firing-frequency oscillators through a load-dependent low-pass with crank-rate amplitude lope.
// Electric profiles swap in a soft rising two-tone whine.
class EngineSound {
  constructor(eng) {
    const ctx = (this.ctx = eng.ctx);
    const g = (v, dest) => { const n = ctx.createGain(); n.gain.value = v; if (dest) n.connect(dest); return n; };
    const osc = (type, dest) => { const o = ctx.createOscillator(); o.type = type; o.frequency.value = 30; o.connect(dest); o.start(); return o; };
    this.out = g(0, eng.sfxVol);
    this.am = g(1, this.out);
    this.lp = ctx.createBiquadFilter();
    this.lp.type = 'lowpass';
    this.lp.frequency.value = 200;
    this.lp.connect(this.am);
    this.gSaw = g(0.3, this.lp);
    this.gTri = g(1, this.lp);
    this.gSine = g(0.3, this.lp);
    this.saw = osc('sawtooth', this.gSaw);
    this.tri = osc('triangle', this.gTri);
    this.sine = osc('sine', this.gSine);
    this.lfoDepth = g(0, this.am.gain);
    this.lfo = osc('sine', this.lfoDepth);
    this.intakeBp = ctx.createBiquadFilter();
    this.intakeBp.type = 'bandpass';
    this.intakeBp.Q.value = 1.2;
    this.intake = g(0, this.am);
    this.intakeBp.connect(this.intake);
    eng.ambience.white.connect(this.intakeBp);
    this.wOut = g(0, eng.sfxVol);
    this.w1 = osc('sine', this.wOut);
    this.w2 = osc('sine', g(0.25, this.wOut));
  }

  update(e) {
    const t = this.ctx.currentTime, p = { ...DEFAULT_PROFILE, ...(e.profile || {}) };
    const vol = clamp(num(p.volume) ? p.volume : 1, 0, 1.5), load = clamp(e.load || 0, 0, 1), speed = Math.max(0, e.speed || 0);
    if (p.character === 'electric') {
      const w = 140 + speed * 22;
      this.out.gain.setTargetAtTime(0, t, 0.15);
      this.w1.frequency.setTargetAtTime(w, t, 0.08);
      this.w2.frequency.setTargetAtTime(w * 1.5, t, 0.08);
      this.wOut.gain.setTargetAtTime(vol * clamp(speed / 3, 0, 1) * (0.003 + 0.01 * load), t, 0.15);
      return;
    }
    this.wOut.gain.setTargetAtTime(0, t, 0.15);
    const c = CHARACTER[p.character] || CHARACTER.smooth, rpm = Math.max(0, e.rpm || 0), k = 0.06;
    const fire = Math.max(5, ((rpm / 60) * (p.cylinders || 4)) / 2);
    const rn = clamp((rpm - p.idle) / Math.max(1, p.redline - p.idle), 0, 1);
    this.saw.frequency.setTargetAtTime(fire, t, k);
    this.tri.frequency.setTargetAtTime(fire / 2, t, k);
    this.sine.frequency.setTargetAtTime(fire * 2, t, k);
    this.lfo.frequency.setTargetAtTime(Math.max(1, rpm / 60), t, k);
    this.gSaw.gain.setTargetAtTime(c.saw, t, 0.2);
    this.gTri.gain.setTargetAtTime(c.tri, t, 0.2);
    this.gSine.gain.setTargetAtTime(c.sine, t, 0.2);
    this.lfoDepth.gain.setTargetAtTime(c.am * (1 - 0.6 * rn), t, 0.2);
    this.lp.frequency.setTargetAtTime(clamp(fire * c.lp * (1 + load * 1.4), 80, 2200), t, k);
    this.lp.Q.setTargetAtTime(c.q, t, 0.2);
    this.intakeBp.frequency.setTargetAtTime(clamp(fire * 4, 200, 3000), t, k);
    this.intake.gain.setTargetAtTime(c.intake * load * 0.5, t, 0.1);
    // quiet at idle and cruise, comes forward under throttle
    this.out.gain.setTargetAtTime(rpm < 60 ? 0 : vol * (0.012 + 0.03 * load + 0.01 * rn), t, 0.12);
  }
}

// ------------------------------------------------------------ public engine

export class AudioEngine {
  constructor() {
    this.ctx = null;
    this._station = 'marimba';
    this.vol = { master: 0.9, music: 0.8, sfx: 0.9 };
    this.muted = false;
    this.amb = { ocean: 0.6, rain: 0, wind: 0.2, night: 0, tunnel: 0 };
    this.road = { speed: 0, surface: 'asphalt' };
    this.eng = { rpm: 0, load: 0, speed: 0, profile: { ...DEFAULT_PROFILE } };
    this.lastEng = null;
    this.deck = null;
    this.fading = [];
    this.lastBump = 0;
  }

  get started() { return !!this.ctx; }

  get station() { return this._station; }

  start() {
    if (this.ctx) {
      if (this.ctx.state !== 'running' && this.ctx.state !== 'closed') this.ctx.resume(); // 'interrupted' on iOS too
      return;
    }
    const AC = typeof window !== 'undefined' && (window.AudioContext || window.webkitAudioContext);
    if (!AC) return;
    const ctx = (this.ctx = new AC());
    NOISE = { white: noiseBuffer(ctx, false), brown: noiseBuffer(ctx, true) };
    const g = (v) => { const n = ctx.createGain(); n.gain.value = v; return n; };

    // music + sfx -> master -> glue compressor -> limiter -> mute -> out
    this.muteGain = g(this.muted ? 0 : 1);
    this.masterVol = g(0);
    this.musicVol = g(0);
    this.sfxVol = g(0);
    const comp = ctx.createDynamicsCompressor();
    comp.threshold.value = -20; comp.knee.value = 10; comp.ratio.value = 2.5; comp.attack.value = 0.015; comp.release.value = 0.35;
    const lim = ctx.createDynamicsCompressor();
    lim.threshold.value = -2; lim.knee.value = 0; lim.ratio.value = 20; lim.attack.value = 0.002; lim.release.value = 0.2;
    this.masterVol.connect(comp);
    comp.connect(lim);
    lim.connect(this.muteGain);
    this.muteGain.connect(ctx.destination);
    this.musicVol.connect(this.masterVol);
    this.sfxVol.connect(this.masterVol);
    this.musicBus = g(1);
    const tone = ctx.createBiquadFilter();
    tone.type = 'lowpass'; tone.frequency.value = 10000; tone.Q.value = 0.5;
    this.musicBus.connect(tone);
    tone.connect(this.musicVol);
    this.hall = ctx.createConvolver();
    this.hall.buffer = impulse(ctx, 4.2);
    const hallOut = g(0.9);
    this.hall.connect(hallOut);
    hallOut.connect(this.musicVol);
    this.sfxBus = g(1);
    this.sfxBus.connect(this.sfxVol);
    this.sfx = new Pool(ctx);

    this.ambience = new Ambience(this);
    this.motor = new EngineSound(this);
    this.applyVolumes(0.5);
    this.ambience.apply();
    this.motor.update(this.eng);
    if (this._station !== 'off') {
      this.deck = new Deck(this, DEFS[this._station]);
      this.deck.fadeIn(XFADE);
    }
    this.timer = setInterval(() => this.tick(), 30);
  }

  tick() {
    const ctx = this.ctx;
    if (ctx.state !== 'running') return;
    const now = ctx.currentTime, hidden = typeof document !== 'undefined' && document.hidden;
    const until = now + (hidden ? 1.5 : LOOKAHEAD); // hidden tabs tick ~1/s, so look further ahead
    if (this.deck) this.deck.schedule(until, now);
    for (const d of this.fading) if (now < d.stopAt) d.schedule(Math.min(until, d.stopAt), now);
    if (this.fading.length) this.fading = this.fading.filter((d) => (now >= d.disposeAt ? (d.dispose(), false) : true));
    this.ambience.tick(now, until);
  }

  speedNow() { return Math.max(this.road.speed || 0, this.eng.speed || 0); }

  setStation(id) {
    if (id !== 'off' && !DEFS[id]) return;
    if (id === this._station && (!this.ctx || id === 'off' || this.deck)) return;
    this._station = id;
    if (!this.ctx) return;
    const now = this.ctx.currentTime;
    if (this.deck) this.retire(this.deck, now);
    this.deck = id === 'off' ? null : new Deck(this, DEFS[id]);
    if (this.deck) this.deck.fadeIn(XFADE);
  }

  // Old deck keeps playing through the first part of the crossfade, then rings out and is torn down.
  retire(d, now) {
    d.fadeOut(XFADE);
    d.stopAt = now + XFADE * 0.6;
    d.disposeAt = now + XFADE + 0.4;
    this.fading.push(d);
    for (let i = 0; i < this.fading.length - 2; i++) { // rapid flipping: cut the oldest quickly
      const o = this.fading[i];
      if (o.disposeAt > now + 0.3) {
        o.fadeOut(0.12);
        o.stopAt = now;
        o.disposeAt = now + 0.25;
      }
    }
  }

  nowPlaying() {
    const id = this._station;
    if (id === 'off') return { station: 'off', name: OFF.name, key: '', bpm: 0, section: 'off' };
    const st = DEFS[id], d = this.deck;
    if (!d) return { station: id, name: st.name, key: '', bpm: Math.round((st.bpm[0] + st.bpm[1]) / 2), section: 'intro' };
    const sec = d.sec || d.song.sections[0];
    return { station: id, name: st.name, key: d.song.key, bpm: d.song.bpm, section: sec.name === 'end' ? 'outro' : sec.name };
  }

  setVolumes(v = {}) {
    for (const k of ['master', 'music', 'sfx']) if (num(v[k])) this.vol[k] = clamp(v[k], 0, 1);
    this.applyVolumes(0.08);
  }

  // Sliders are squared so they feel even across their range.
  applyVolumes(tau) {
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    this.masterVol.gain.setTargetAtTime(this.vol.master * this.vol.master, t, tau);
    this.musicVol.gain.setTargetAtTime(this.vol.music * this.vol.music, t, tau);
    this.sfxVol.gain.setTargetAtTime(this.vol.sfx * this.vol.sfx, t, tau);
  }

  setMuted(muted) {
    this.muted = !!muted;
    if (this.ctx) this.muteGain.gain.setTargetAtTime(this.muted ? 0 : 1, this.ctx.currentTime, 0.08);
  }

  setEngine(s = {}) {
    const e = this.eng;
    if (num(s.rpm)) e.rpm = Math.max(0, s.rpm);
    if (num(s.load)) e.load = clamp(s.load, 0, 1);
    if (num(s.speed)) e.speed = Math.max(0, s.speed);
    if (s.profile) e.profile = s.profile;
    if (!this.ctx) return;
    const p = e.profile, key = `${p.cylinders}|${p.idle}|${p.redline}|${p.character}|${p.volume}`, l = this.lastEng;
    if (l && l.key === key && Math.abs(e.rpm - l.rpm) < 15 && Math.abs(e.load - l.load) < 0.02 && Math.abs(e.speed - l.speed) < 0.25) return;
    this.lastEng = { key, rpm: e.rpm, load: e.load, speed: e.speed };
    this.motor.update(e);
  }

  setAmbience(a = {}) {
    let changed = false;
    for (const k of ['ocean', 'rain', 'wind', 'night', 'tunnel']) {
      if (!num(a[k])) continue;
      const v = clamp(a[k], 0, 1);
      if (Math.abs(v - this.amb[k]) > 0.005 || (v === 0) !== (this.amb[k] === 0)) { this.amb[k] = v; changed = true; }
    }
    if (changed && this.ctx) this.ambience.apply();
  }

  setRoad(r = {}) {
    let changed = false;
    if (num(r.speed) && Math.abs(r.speed - this.road.speed) > 0.25) { this.road.speed = Math.max(0, r.speed); changed = true; }
    if (r.surface && r.surface !== this.road.surface) { this.road.surface = r.surface; changed = true; }
    if (changed && this.ctx) this.ambience.apply();
  }

  bump(strength = 0.5) {
    if (!this.ctx) return;
    const s = clamp(num(strength) ? strength : 0.5, 0, 1), now = this.ctx.currentTime;
    if (s < 0.02 || now - this.lastBump < 0.07) return;
    this.lastBump = now;
    const v = this.sfx.voice(this.sfxBus, 'bump', 4, now + 0.005, 0), t = v.t, dec = 0.25 + s * 0.2;
    perc(v.out.gain, t, 0.004, 0.08 + 0.3 * s, dec);
    const o = v.osc('sine', 95);
    o.frequency.setValueAtTime(90 + 30 * s, t);
    o.frequency.exponentialRampToValueAtTime(38, t + 0.18);
    v.noise(NOISE.brown, v.filter('lowpass', 250 + 450 * s, 0.6, v.gain(0.9)));
    v.stop(t + dec + 0.03);
  }

  horn(pan = 0, distance = 0) {
    if (!this.ctx) return;
    const d = Math.max(0, num(distance) ? distance : 0), att = 1 / (1 + d / 25);
    if (att < 0.03) return;
    const v = this.sfx.voice(this.sfxBus, 'horn', 3, this.ctx.currentTime + 0.01, num(pan) ? pan : 0);
    const t = v.t, det = d > 0 ? rand(-60, 60) : 0; // traffic horns vary a little
    const end = adsr(v.out.gain, t, 0.025, 0.06 * att, 0.38, 0.12, 0.9);
    const lp = v.filter('lowpass', clamp(2600 * Math.sqrt(att), 450, 2600), 0.7);
    v.osc('square', 392, v.gain(0.5, lp), det);
    v.osc('square', 494, v.gain(0.4, lp), det);
    v.stop(end);
  }

  click() {
    if (!this.ctx) return;
    const v = this.sfx.voice(this.sfxBus, 'click', 3, this.ctx.currentTime + 0.002, 0), t = v.t;
    perc(v.out.gain, t, 0.001, 0.05, 0.035);
    const o = v.osc('sine', 1500);
    o.frequency.setValueAtTime(1500, t);
    o.frequency.exponentialRampToValueAtTime(900, t + 0.03);
    v.stop(t + 0.05);
  }
}
