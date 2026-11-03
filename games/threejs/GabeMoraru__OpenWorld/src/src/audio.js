let ctx, master, engine, engineGain, engineFilter, padGain, noiseBuffer;
let muted = false;

function tone(freq, { dur = 0.3, type = 'sine', vol = 0.12, delay = 0, slide = 0 } = {}) {
  if (!ctx) return;
  const t = ctx.currentTime + delay, o = ctx.createOscillator(), g = ctx.createGain();
  o.type = type;
  o.frequency.setValueAtTime(freq, t);
  if (slide) o.frequency.exponentialRampToValueAtTime(freq * slide, t + dur);
  g.gain.setValueAtTime(0, t);
  g.gain.linearRampToValueAtTime(vol, t + 0.012);
  g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
  o.connect(g).connect(master);
  o.start(t);
  o.stop(t + dur + 0.05);
}

export const audio = {
  init() {
    if (ctx) return;
    ctx = new AudioContext();
    master = ctx.createGain();
    master.gain.value = 0.7;
    master.connect(ctx.destination);

    padGain = ctx.createGain();
    padGain.gain.value = 0.045;
    const padFilter = ctx.createBiquadFilter();
    padFilter.type = 'lowpass';
    padFilter.frequency.value = 520;
    padGain.connect(padFilter).connect(master);
    for (const f of [55, 82.4, 110.3, 164.8]) {
      const o = ctx.createOscillator();
      o.type = 'triangle';
      o.frequency.value = f;
      o.detune.value = (Math.random() - 0.5) * 14;
      o.connect(padGain);
      o.start();
    }

    engine = ctx.createOscillator();
    engine.type = 'sawtooth';
    engineFilter = ctx.createBiquadFilter();
    engineFilter.type = 'lowpass';
    engineFilter.frequency.value = 300;
    engineGain = ctx.createGain();
    engineGain.gain.value = 0;
    engine.connect(engineFilter).connect(engineGain).connect(master);
    engine.start();

    noiseBuffer = ctx.createBuffer(1, ctx.sampleRate * 0.5, ctx.sampleRate);
    const d = noiseBuffer.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  },
  engine(speed, on, boosting) {
    if (!ctx) return;
    const t = ctx.currentTime;
    engine.frequency.setTargetAtTime(34 + Math.abs(speed) * 2.3 + (boosting ? 25 : 0), t, 0.08);
    engineFilter.frequency.setTargetAtTime(260 + Math.abs(speed) * 22, t, 0.1);
    engineGain.gain.setTargetAtTime(on ? 0.028 + Math.abs(speed) * 0.0009 : 0, t, 0.12);
  },
  pickup(combo) {
    tone(520 * 2 ** (Math.min(combo, 14) / 12), { dur: 0.22, type: 'triangle', vol: 0.09 });
  },
  lantern() {
    [0, 7, 12, 19].forEach((s, i) => tone(392 * 2 ** (s / 12), { dur: 0.9, vol: 0.08, delay: i * 0.07 }));
  },
  charge(p) {
    tone(180 + p * 500, { dur: 0.09, type: 'square', vol: 0.025 });
  },
  restore() {
    [0, 4, 7, 11, 14, 19].forEach((s, i) => tone(196 * 2 ** (s / 12), { dur: 3.2, vol: 0.09, delay: i * 0.11 }));
    tone(49, { dur: 3, type: 'triangle', vol: 0.18, slide: 2 });
  },
  hit() {
    if (!ctx) return;
    const src = ctx.createBufferSource(), f = ctx.createBiquadFilter(), g = ctx.createGain();
    src.buffer = noiseBuffer;
    f.type = 'lowpass';
    f.frequency.value = 700;
    g.gain.setValueAtTime(0.35, ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.45);
    src.connect(f).connect(g).connect(master);
    src.start();
    tone(110, { dur: 0.5, type: 'sawtooth', vol: 0.08, slide: 0.4 });
  },
  banish() {
    tone(880, { dur: 0.35, type: 'triangle', vol: 0.08, slide: 0.25 });
  },
  dawn() {
    [0, 4, 7, 12, 16, 19, 24].forEach((s, i) => tone(130.8 * 2 ** (s / 12), { dur: 6, vol: 0.08, delay: i * 0.35 }));
    if (padGain) padGain.gain.setTargetAtTime(0.07, ctx.currentTime, 3);
  },
  toggleMute() {
    muted = !muted;
    if (master) master.gain.setTargetAtTime(muted ? 0 : 0.7, ctx.currentTime, 0.05);
    return muted;
  },
};
