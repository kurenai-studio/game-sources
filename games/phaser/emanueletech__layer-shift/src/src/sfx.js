// Procedural audio via WebAudio — no audio files. Two buses (sfx, music) into a soft compressor,
// with a small generated reverb so the synth sounds sit in a room instead of in the speaker.
let ctx = null;
let master, sfxBus, musicBus, reverb, musicFilter;
let muted = false;
const VOL = 0.5;

function impulse(seconds = 1.6, decay = 3) {
  const len = Math.floor(ctx.sampleRate * seconds);
  const buf = ctx.createBuffer(2, len, ctx.sampleRate);
  for (let ch = 0; ch < 2; ch++) {
    const d = buf.getChannelData(ch);
    for (let i = 0; i < len; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / len, decay);
  }
  return buf;
}

export function initAudio() {
  if (ctx) return ctx;
  const AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return null;
  ctx = new AC();
  const comp = ctx.createDynamicsCompressor();
  comp.threshold.value = -16; comp.ratio.value = 4;
  master = ctx.createGain(); master.gain.value = muted ? 0 : VOL;
  master.connect(comp).connect(ctx.destination);
  reverb = ctx.createConvolver(); reverb.buffer = impulse();
  const wet = ctx.createGain(); wet.gain.value = 0.22;
  reverb.connect(wet).connect(master);
  sfxBus = ctx.createGain(); sfxBus.gain.value = 1; sfxBus.connect(master); sfxBus.connect(reverb);
  musicFilter = ctx.createBiquadFilter(); musicFilter.type = 'lowpass'; musicFilter.frequency.value = 3200;
  musicBus = ctx.createGain(); musicBus.gain.value = 0.55;
  musicBus.connect(musicFilter).connect(master);
  musicFilter.connect(reverb);
  return ctx;
}

export function resumeAudio() {
  initAudio();
  if (ctx && ctx.state === 'suspended') ctx.resume();
}

export function setMuted(m) {
  muted = m;
  try { localStorage.setItem('layershift-muted', m ? '1' : '0'); } catch (e) { /* storage may be blocked */ }
  if (master) master.gain.setTargetAtTime(m ? 0 : VOL, ctx.currentTime, 0.02);
}
export const isMuted = () => muted;
try { muted = localStorage.getItem('layershift-muted') === '1'; } catch (e) { /* ignore */ }

let _noise = null;
function noiseBuffer() {
  if (_noise) return _noise;
  const len = ctx.sampleRate;
  _noise = ctx.createBuffer(1, len, ctx.sampleRate);
  const d = _noise.getChannelData(0);
  for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
  return _noise;
}

/**
 * One synth voice. opts: { type, freq, freqEnd, dur, vol, attack, noise, filter:{type,freq,q,freqEnd},
 *   vibrato:{rate,depth}, at (audio time), bus: 'sfx'|'music', pan }
 */
export function tone(opts = {}) {
  if (!ctx || muted) return;
  const t = opts.at ?? ctx.currentTime;
  const dur = opts.dur ?? 0.15;
  const vol = opts.vol ?? 0.5;
  const g = ctx.createGain();
  g.gain.setValueAtTime(0.0001, t);
  g.gain.exponentialRampToValueAtTime(vol, t + (opts.attack ?? 0.004));
  g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
  let src;
  if (opts.noise) {
    src = ctx.createBufferSource();
    src.buffer = noiseBuffer();
    src.loop = true;
  } else {
    src = ctx.createOscillator();
    src.type = opts.type ?? 'square';
    src.frequency.setValueAtTime(opts.freq ?? 440, t);
    if (opts.freqEnd) src.frequency.exponentialRampToValueAtTime(Math.max(1, opts.freqEnd), t + dur);
    if (opts.vibrato) {
      const lfo = ctx.createOscillator(), lg = ctx.createGain();
      lfo.frequency.value = opts.vibrato.rate; lg.gain.value = opts.vibrato.depth;
      lfo.connect(lg).connect(src.frequency);
      lfo.start(t); lfo.stop(t + dur + 0.05);
    }
  }
  let node = src;
  if (opts.filter) {
    const f = ctx.createBiquadFilter();
    f.type = opts.filter.type ?? 'lowpass';
    f.frequency.setValueAtTime(opts.filter.freq ?? 1200, t);
    if (opts.filter.freqEnd) f.frequency.exponentialRampToValueAtTime(opts.filter.freqEnd, t + dur);
    f.Q.value = opts.filter.q ?? 1;
    node.connect(f); node = f;
  }
  if (opts.pan && ctx.createStereoPanner) {
    const p = ctx.createStereoPanner(); p.pan.value = opts.pan;
    node.connect(p); node = p;
  }
  node.connect(g);
  g.connect(opts.bus === 'music' ? musicBus : sfxBus);
  src.start(t);
  src.stop(t + dur + 0.05);
}

const after = (ms, fn) => setTimeout(fn, ms);

export const SFX = {
  click: () => tone({ type: 'square', freq: 660, freqEnd: 880, dur: 0.06, vol: 0.2 }),
  // stepper-motor tick: a filtered click plus a short pitched chirp
  shift: (dir) => {
    tone({ noise: true, dur: 0.03, vol: 0.25, filter: { type: 'highpass', freq: 3000 }, pan: dir * 0.4 });
    tone({ type: 'square', freq: dir < 0 ? 520 : 600, freqEnd: dir < 0 ? 440 : 720, dur: 0.05, vol: 0.12, filter: { freq: 2400 }, pan: dir * 0.4 });
  },
  lost: () => {
    [880, 660, 440, 220].forEach((f, i) => tone({ type: 'square', freq: f, dur: 0.05, vol: 0.12, at: ctx && ctx.currentTime + i * 0.035 }));
  },
  extrude: (pan = 0) => tone({ noise: true, dur: 0.07, vol: 0.12, filter: { type: 'bandpass', freq: 2600, q: 2 }, pan }),
  // the nozzle sweep: a stepper whine that rises with speed
  sweep: (dur) => tone({ type: 'sawtooth', freq: 180, freqEnd: 330, dur, vol: 0.05, filter: { freq: 900 }, attack: 0.02 }),
  perfect: (combo) => {
    const base = 523.25 * Math.pow(2, Math.min(combo, 12) / 12);
    [1, 1.25, 1.5, 2].forEach((m, i) => after(i * 55, () => tone({ type: 'triangle', freq: base * m, dur: 0.22, vol: 0.16 })));
    after(170, () => tone({ type: 'sine', freq: base * 4, dur: 0.4, vol: 0.06 }));
  },
  error: () => {
    tone({ type: 'square', freq: 140, freqEnd: 90, dur: 0.22, vol: 0.18, filter: { freq: 800 } });
    tone({ type: 'square', freq: 147, freqEnd: 93, dur: 0.22, vol: 0.12, filter: { freq: 800 } });
  },
  // comedic sag: a wobbling slide down
  spaghetti: () => tone({ type: 'sine', freq: 520, freqEnd: 110, dur: 0.55, vol: 0.2, vibrato: { rate: 14, depth: 40 } }),
  tick: () => tone({ type: 'square', freq: 1500, dur: 0.025, vol: 0.06, filter: { type: 'highpass', freq: 1000 } }),
  // classic printer start-up: homing beeps
  home: () => [988, 988, 1319].forEach((f, i) => after(i * 140, () => tone({ type: 'square', freq: f, dur: i === 2 ? 0.2 : 0.08, vol: 0.1, filter: { freq: 3000 } }))),
  hit: () => tone({ noise: true, dur: 0.18, vol: 0.4, filter: { type: 'lowpass', freq: 900 } }),
  explode: () => tone({ noise: true, dur: 0.45, vol: 0.6, filter: { type: 'lowpass', freq: 500 } }),
  lose: () => tone({ type: 'sawtooth', freq: 400, freqEnd: 60, dur: 0.6, vol: 0.3 }),
  win: () => [523, 659, 784, 1046].forEach((f, i) => after(i * 90, () => tone({ type: 'triangle', freq: f, dur: 0.22, vol: 0.25 }))),
  star: (i) => { tone({ type: 'triangle', freq: 660 * Math.pow(1.26, i), dur: 0.3, vol: 0.22 }); tone({ type: 'sine', freq: 1320 * Math.pow(1.26, i), dur: 0.5, vol: 0.06 }); },
  rumble: (dur) => tone({ noise: true, dur, vol: 0.45, filter: { type: 'lowpass', freq: 220, freqEnd: 900 }, attack: 0.3 }),
};

// ---------- music ----------
const NOTE = (n) => 440 * Math.pow(2, (n - 69) / 12);   // MIDI note -> Hz

/**
 * Tiny scheduled sequencer. song = { bpm, steps: 16th-notes per bar, lead:[midi|0], bass:[midi|0], hat:[0|1] }
 * Uses the audio clock with a look-ahead so the groove stays tight.
 */
export class Music {
  constructor(song) { this.song = song; this.timer = null; this.step = 0; this.next = 0; }
  start() {
    if (this.timer || !initAudio()) return;
    this.next = ctx.currentTime + 0.05;
    this.timer = setInterval(() => this.tick(), 25);
  }
  setBpm(bpm) { this.song = { ...this.song, bpm }; }
  tick() {
    if (!ctx) return;
    const s = this.song, dt = 60 / s.bpm / 4;
    while (this.next < ctx.currentTime + 0.12) {
      const i = this.step % s.lead.length;
      const lead = s.lead[i], bass = s.bass[i % s.bass.length], hat = s.hat?.[i % s.hat.length];
      if (lead) tone({ type: 'square', freq: NOTE(lead), dur: dt * 0.9, vol: 0.05, at: this.next, bus: 'music', filter: { freq: 2400 } });
      if (bass) tone({ type: 'triangle', freq: NOTE(bass), dur: dt * 1.8, vol: 0.16, at: this.next, bus: 'music' });
      if (hat) tone({ noise: true, dur: 0.03, vol: hat > 1 ? 0.05 : 0.025, at: this.next, bus: 'music', filter: { type: 'highpass', freq: 7000 } });
      this.next += dt; this.step++;
    }
  }
  stop() { clearInterval(this.timer); this.timer = null; }
}

// Songs: stepper-motor style chip tunes in A minor.
export const SONGS = {
  title: {
    bpm: 92,
    lead: [69, 0, 72, 0, 76, 0, 72, 0, 67, 0, 71, 0, 74, 0, 71, 0, 65, 0, 69, 0, 72, 0, 69, 0, 64, 0, 67, 0, 71, 0, 76, 0],
    bass: [45, 0, 0, 0, 45, 0, 0, 0, 43, 0, 0, 0, 43, 0, 0, 0, 41, 0, 0, 0, 41, 0, 0, 0, 40, 0, 0, 0, 40, 0, 0, 0],
    hat: [0, 0, 1, 0],
  },
  work: {
    bpm: 112,
    lead: [76, 0, 74, 76, 0, 72, 0, 69, 72, 0, 74, 0, 76, 0, 79, 0, 77, 0, 76, 74, 0, 72, 0, 69, 71, 0, 72, 0, 74, 0, 71, 0],
    bass: [45, 0, 57, 0, 45, 0, 57, 0, 41, 0, 53, 0, 41, 0, 53, 0, 43, 0, 55, 0, 43, 0, 55, 0, 40, 0, 52, 0, 40, 0, 52, 0],
    hat: [2, 0, 1, 1],
  },
};
