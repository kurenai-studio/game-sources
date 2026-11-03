/**
 * SoundEngine — the realm's audio, synthesised like everything else.
 *
 * No samples. Every sound is built from noise buffers and oscillators run
 * through Web Audio filters, and every one is driven by the same bus events
 * the visuals use, so sound and picture can never drift out of sync.
 *
 *   beds     wind (gain follows uWindStrength), the volcano's sub-bass
 *            breathing (follows eruption surge), wildfire crackle (follows how
 *            much of the world is burning)
 *   one-shots fire breath, roar, thunder, eruption blast, bomb impacts
 *
 * Thunder is delayed by distance / 343 m·s⁻¹ from the camera and low-passed
 * harder the further away it lands — far strikes arrive late as a soft roll,
 * near ones as an instant crack. That one physical detail does more for scale
 * than any visual trick in the project.
 *
 * The context can only start inside a user gesture, so `start()` is called
 * from the "Enter the Realm" click.
 */
import { bus, EV } from '../core/EventBus.js';
import { G } from '../materials/GlobalUniforms.js';

const SPEED_OF_SOUND = 343;

export class SoundEngine {
  constructor({ getListener, getSurge, getBurning } = {}) {
    this.getListener = getListener ?? (() => null);
    this.getSurge = getSurge ?? (() => 0);
    this.getBurning = getBurning ?? (() => 0);
    this.ctx = null;
    this.muted = false;
    this._unsubs = [];
  }

  /* ── boot ─────────────────────────────────────────────────────────── */

  start() {
    if (this.ctx) { this.ctx.resume?.(); return; }
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    const ctx = this.ctx = new AC();

    // Master: gentle glue compression, then a limiter so a roar over an
    // eruption over thunder can't clip.
    this.master = ctx.createGain();
    this.master.gain.value = 0;
    const comp = ctx.createDynamicsCompressor();
    comp.threshold.value = -18; comp.knee.value = 12; comp.ratio.value = 3.5;
    comp.attack.value = 0.01; comp.release.value = 0.25;
    const lim = ctx.createDynamicsCompressor();
    lim.threshold.value = -2; lim.knee.value = 0; lim.ratio.value = 20;
    lim.attack.value = 0.002; lim.release.value = 0.1;
    this.master.connect(comp).connect(lim).connect(ctx.destination);
    this.master.gain.setTargetAtTime(0.9, ctx.currentTime, 1.5);

    // A shared reverb tail: decaying noise impulse. Big valley, long tail.
    this.verb = ctx.createConvolver();
    this.verb.buffer = this._impulse(4.2, 2.6);
    this.verbIn = ctx.createGain();
    this.verbIn.gain.value = 0.55;
    this.verbIn.connect(this.verb).connect(this.master);

    this.noise = this._noiseBuffer(4, 'white');
    this.brown = this._noiseBuffer(6, 'brown');

    this._buildBeds();
    this._wire();
  }

  setMuted(m) {
    this.muted = m;
    if (!this.ctx) return;
    this.master.gain.setTargetAtTime(m ? 0 : 0.9, this.ctx.currentTime, 0.15);
  }

  toggleMute() { this.setMuted(!this.muted); return this.muted; }

  /* ── building blocks ──────────────────────────────────────────────── */

  _noiseBuffer(seconds, kind) {
    const ctx = this.ctx;
    const n = Math.floor(ctx.sampleRate * seconds);
    const buf = ctx.createBuffer(1, n, ctx.sampleRate);
    const d = buf.getChannelData(0);
    let last = 0;
    for (let i = 0; i < n; i++) {
      const w = Math.random() * 2 - 1;
      if (kind === 'brown') { last = (last + 0.02 * w) / 1.02; d[i] = last * 3.5; }
      else d[i] = w;
    }
    return buf;
  }

  _impulse(seconds, decay) {
    const ctx = this.ctx;
    const n = Math.floor(ctx.sampleRate * seconds);
    const buf = ctx.createBuffer(2, n, ctx.sampleRate);
    for (let c = 0; c < 2; c++) {
      const d = buf.getChannelData(c);
      for (let i = 0; i < n; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / n, decay);
    }
    return buf;
  }

  _src(buf, { loop = false, rate = 1, offset = Math.random() * 2 } = {}) {
    const s = this.ctx.createBufferSource();
    s.buffer = buf; s.loop = loop; s.playbackRate.value = rate;
    s._offset = offset % buf.duration;
    return s;
  }

  _filter(type, freq, Q = 0.7) {
    const f = this.ctx.createBiquadFilter();
    f.type = type; f.frequency.value = freq; f.Q.value = Q;
    return f;
  }

  _out(node, { wet = 0.3, pan = 0 } = {}) {
    const ctx = this.ctx;
    let n = node;
    if (pan && ctx.createStereoPanner) {
      const p = ctx.createStereoPanner(); p.pan.value = Math.max(-1, Math.min(1, pan));
      n.connect(p); n = p;
    }
    n.connect(this.master);
    if (wet > 0) {
      const w = ctx.createGain(); w.gain.value = wet;
      n.connect(w).connect(this.verbIn);
    }
  }

  _distort(amount) {
    const ws = this.ctx.createWaveShaper();
    const n = 1024, c = new Float32Array(n);
    for (let i = 0; i < n; i++) {
      const x = i / (n - 1) * 2 - 1;
      c[i] = Math.tanh(x * amount) / Math.tanh(amount);
    }
    ws.curve = c; ws.oversample = '2x';
    return ws;
  }

  /** Where a world point sits relative to the listener: distance and stereo pan. */
  _place(pos) {
    const L = this.getListener();
    if (!L || !pos) return { dist: 300, pan: 0 };
    const dx = pos.x - L.position.x, dy = pos.y - L.position.y, dz = pos.z - L.position.z;
    const dist = Math.hypot(dx, dy, dz);
    // Pan from the camera's right vector.
    const e = L.matrixWorld.elements;
    const rx = e[0], ry = e[1], rz = e[2];
    const pan = (dx * rx + dy * ry + dz * rz) / Math.max(dist, 1);
    return { dist, pan: pan * 0.8 };
  }

  /* ── beds ─────────────────────────────────────────────────────────── */

  _buildBeds() {
    const ctx = this.ctx;
    const t = ctx.currentTime;

    // Wind: brown noise through a wandering band-pass.
    const wind = this._src(this.brown, { loop: true });
    this.windBp = this._filter('bandpass', 380, 0.6);
    this.windGain = ctx.createGain(); this.windGain.gain.value = 0;
    wind.connect(this.windBp).connect(this.windGain);
    this._out(this.windGain, { wet: 0.15 });
    wind.start(t, wind._offset);

    // Volcano: sub-bass rumble.
    const rum = this._src(this.brown, { loop: true, rate: 0.5 });
    const rlp = this._filter('lowpass', 70, 0.9);
    this.rumbleGain = ctx.createGain(); this.rumbleGain.gain.value = 0;
    rum.connect(rlp).connect(this.rumbleGain);
    this._out(this.rumbleGain, { wet: 0.1 });
    rum.start(t, rum._offset);

    // Fire: a roar bed plus discrete crackles scheduled in update().
    const fb = this._src(this.brown, { loop: true, rate: 1.6 });
    const fbp = this._filter('bandpass', 260, 0.5);
    this.fireGain = ctx.createGain(); this.fireGain.gain.value = 0;
    fb.connect(fbp).connect(this.fireGain);
    this._out(this.fireGain, { wet: 0.2 });
    fb.start(t, fb._offset);
    this._crackleT = 0;
  }

  /* ── one-shots ────────────────────────────────────────────────────── */

  breath(duration = 3.4, pos) {
    const ctx = this.ctx, t = ctx.currentTime;
    const { dist, pan } = this._place(pos);
    const near = Math.max(0.15, Math.min(1, 220 / Math.max(dist, 40)));

    // Body: low noise roar with a sweeping low-pass — the jet "opening up".
    const s = this._src(this.noise, { loop: true });
    const lp = this._filter('lowpass', 300, 1.2);
    lp.frequency.setValueAtTime(300, t);
    lp.frequency.exponentialRampToValueAtTime(2600 * near + 400, t + 0.25);
    lp.frequency.exponentialRampToValueAtTime(900, t + duration + 0.6);
    const g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(0.55 * near, t + 0.18);
    g.gain.setValueAtTime(0.5 * near, t + duration);
    g.gain.exponentialRampToValueAtTime(0.0001, t + duration + 0.9);
    s.connect(lp).connect(this._distort(2.2)).connect(g);
    this._out(g, { wet: 0.35, pan });
    s.start(t, s._offset); s.stop(t + duration + 1);

    // Sub thump on ignition.
    this._thump(t, 55, 0.6 * near, 0.5);
  }

  roar(pos) {
    const ctx = this.ctx, t = ctx.currentTime;
    const { dist, pan } = this._place(pos);
    const near = Math.max(0.25, Math.min(1, 400 / Math.max(dist, 60)));
    const dur = 2.3;

    // Vocal folds: three detuned saws gliding down, gated by a slow tremolo.
    const mix = ctx.createGain(); mix.gain.value = 0.22;
    const oscs = [62, 64.5, 93].map((f, i) => {
      const o = ctx.createOscillator();
      o.type = 'sawtooth';
      o.frequency.setValueAtTime(f * 1.25, t);
      o.frequency.exponentialRampToValueAtTime(f, t + 0.4);
      o.frequency.exponentialRampToValueAtTime(f * 0.62, t + dur);
      o.connect(mix);
      return o;
    });
    // Growl: amplitude-modulate at ~28 Hz, the rattle of a huge throat.
    const am = ctx.createGain(); am.gain.value = 0.6;
    const lfo = ctx.createOscillator(); lfo.frequency.value = 28;
    const lfoG = ctx.createGain(); lfoG.gain.value = 0.4;
    lfo.connect(lfoG).connect(am.gain);
    mix.connect(am);

    // Breath noise through the same throat.
    const n = this._src(this.noise, { loop: true });
    const nbp = this._filter('bandpass', 900, 0.8);
    const ng = ctx.createGain(); ng.gain.value = 0.35;
    n.connect(nbp).connect(ng).connect(am);

    // Vocal tract: two formants of an open "aah", sliding toward "ooh".
    const f1 = this._filter('bandpass', 650, 3), f2 = this._filter('bandpass', 1100, 4);
    f1.frequency.linearRampToValueAtTime(420, t + dur);
    f2.frequency.linearRampToValueAtTime(800, t + dur);
    const body = this._filter('lowpass', 2200, 0.7);
    const sum = ctx.createGain();
    am.connect(f1).connect(sum); am.connect(f2).connect(sum); am.connect(body).connect(sum);

    const g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(0.9 * near, t + 0.12);
    g.gain.setValueAtTime(0.8 * near, t + dur * 0.6);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    sum.connect(this._distort(3.5)).connect(g);
    this._out(g, { wet: 0.6, pan });

    for (const o of oscs) { o.start(t); o.stop(t + dur + 0.1); }
    lfo.start(t); lfo.stop(t + dur + 0.1);
    n.start(t, n._offset); n.stop(t + dur + 0.1);
    this._thump(t + 0.05, 42, 0.5 * near, 1.2);
  }

  thunder(pos, { volcanic = false } = {}) {
    const ctx = this.ctx;
    const { dist, pan } = this._place(pos);
    const delay = Math.min(6, dist / SPEED_OF_SOUND);
    const t = ctx.currentTime + delay;
    const near = Math.max(0.12, Math.min(1, 500 / Math.max(dist, 50)));

    // Crack: bright, short, only audible when close.
    if (near > 0.3) {
      const c = this._src(this.noise);
      const hp = this._filter('highpass', 1800, 0.7);
      const cg = ctx.createGain();
      cg.gain.setValueAtTime(0.0001, t);
      cg.gain.exponentialRampToValueAtTime((volcanic ? 0.35 : 0.8) * near, t + 0.008);
      cg.gain.exponentialRampToValueAtTime(0.0001, t + 0.35);
      c.connect(hp).connect(cg);
      this._out(cg, { wet: 0.5, pan });
      c.start(t, c._offset); c.stop(t + 0.4);
    }
    if (volcanic) return;

    // Roll: brown noise, lowpassed harder with distance, rumbling for seconds.
    const r = this._src(this.brown, { rate: 0.7 });
    const lp = this._filter('lowpass', 180 + 900 * near, 0.8);
    const rg = ctx.createGain();
    const dur = 3 + Math.random() * 2.5;
    rg.gain.setValueAtTime(0.0001, t);
    rg.gain.exponentialRampToValueAtTime(1.1 * near + 0.15, t + 0.12 + (1 - near) * 0.4);
    // Rolling: a couple of re-swells as echoes come back off the mountains.
    rg.gain.exponentialRampToValueAtTime(0.35 * near + 0.05, t + dur * 0.35);
    rg.gain.exponentialRampToValueAtTime(0.6 * near + 0.08, t + dur * 0.5);
    rg.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    r.connect(lp).connect(rg);
    this._out(rg, { wet: 0.7, pan: pan * 0.5 });
    r.start(t, r._offset); r.stop(t + dur + 0.1);
  }

  eruption(pos) {
    const ctx = this.ctx;
    const { dist } = this._place(pos);
    const t = ctx.currentTime + Math.min(3, dist / SPEED_OF_SOUND);

    // The blast: a pitched-down sine for the chest, noise for the air.
    this._thump(t, 70, 1.4, 3.5, 18);
    const n = this._src(this.brown, { rate: 0.6 });
    const lp = this._filter('lowpass', 1800, 0.6);
    lp.frequency.exponentialRampToValueAtTime(120, t + 9);
    const g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(1.6, t + 0.05);
    g.gain.exponentialRampToValueAtTime(0.5, t + 2.5);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 12);
    n.connect(lp).connect(this._distort(4)).connect(g);
    this._out(g, { wet: 0.8 });
    n.start(t, n._offset); n.stop(t + 12.5);
  }

  impact(pos) {
    const { dist, pan } = this._place(pos);
    if (dist > 1400) return;
    const near = Math.max(0.08, Math.min(0.8, 260 / Math.max(dist, 40)));
    const t = this.ctx.currentTime + dist / SPEED_OF_SOUND;
    this._thump(t, 90 + Math.random() * 40, near, 0.6, 30, pan);
  }

  _thump(t, f0, gain, dur, f1 = 28, pan = 0) {
    const ctx = this.ctx;
    const o = ctx.createOscillator();
    o.type = 'sine';
    o.frequency.setValueAtTime(f0, t);
    o.frequency.exponentialRampToValueAtTime(f1, t + dur);
    const g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(gain, t + 0.01);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(g);
    this._out(g, { wet: 0.25, pan });
    o.start(t); o.stop(t + dur + 0.05);
  }

  _crackle(level) {
    const ctx = this.ctx, t = ctx.currentTime;
    const s = this._src(this.noise);
    const bp = this._filter('bandpass', 1500 + Math.random() * 3500, 2 + Math.random() * 4);
    const g = ctx.createGain();
    const len = 0.01 + Math.random() * 0.035;
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(0.25 * level * (0.4 + Math.random()), t + 0.002);
    g.gain.exponentialRampToValueAtTime(0.0001, t + len);
    s.connect(bp).connect(g);
    this._out(g, { wet: 0.2, pan: (Math.random() - 0.5) * 0.9 });
    s.start(t, s._offset); s.stop(t + len + 0.02);
  }

  /* ── wiring ───────────────────────────────────────────────────────── */

  _wire() {
    const on = (ev, fn) => this._unsubs.push(bus.on(ev, (e) => { if (this.ctx && !this.muted) fn(e ?? {}); }));
    on(EV.DRAGON_FIRE, (e) => this.breath(e.duration, e.origin));
    on(EV.ROAR, (e) => this.roar(e.origin));
    on(EV.STRIKE, (e) => this.thunder(e.to, { volcanic: e.volcanic }));
    on(EV.ERUPTION, (e) => { if (e.stage === 'blast') this.eruption(e.pos); });
    on(EV.IGNITE, (e) => { if (e.impact) this.impact(e.pos); });
  }

  update(dt) {
    if (!this.ctx || this.muted) return;
    const t = this.ctx.currentTime;
    const wind = G.uWindStrength.value;
    this.windGain.gain.setTargetAtTime(0.05 + wind * 0.11, t, 0.5);
    this.windBp.frequency.setTargetAtTime(260 + wind * 260 + Math.sin(t * 0.3) * 90, t, 0.8);

    const surge = this.getSurge();
    this.rumbleGain.gain.setTargetAtTime(0.12 + surge * 1.1, t, 0.4);

    const burning = Math.min(1, this.getBurning() / 8 + G.uFireIntensity.value * 0.4);
    this.fireGain.gain.setTargetAtTime(burning * 0.35, t, 0.3);
    this._crackleT -= dt;
    while (burning > 0.02 && this._crackleT <= 0) {
      this._crackle(burning);
      this._crackleT += (0.02 + Math.random() * 0.12) / (0.3 + burning);
    }
    if (this._crackleT < -1) this._crackleT = 0;
  }

  dispose() {
    for (const u of this._unsubs) u();
    this.ctx?.close();
  }
}
