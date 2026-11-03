// audio.mjs — paisaje sonoro 100% sintetizado (WebAudio), sin assets.
// Capas continuas (drip, hum electrico, tuberias graves) + eventos puntuales de
// scheduleAmbientEvents (flush, dryer, stall_noise, pipe_knock) espacializados con
// attenuation (mas cerca = mas fuerte) y pan estereo por direccion. Footsteps al andar.
import { scheduleAmbientEvents, attenuation } from './fx-logic.mjs';

const SEED = 20240711; // seed fija del scheduler ambiental

function clamp(v, lo, hi) { return v < lo ? lo : (v > hi ? hi : v); }

// buffer de ruido blanco (Math.random permitido: ruido audiovisual no persistente)
function noiseBuffer(ctx, seconds) {
  const n = Math.floor(ctx.sampleRate * seconds);
  const buf = ctx.createBuffer(1, n, ctx.sampleRate);
  const data = buf.getChannelData(0);
  for (let i = 0; i < n; i++) data[i] = Math.random() * 2 - 1;
  return buf;
}

function noiseSource(ctx, seconds) {
  const src = ctx.createBufferSource();
  src.buffer = noiseBuffer(ctx, seconds);
  return src;
}

// nodo de espacializacion: gain (atenuacion) -> panner (direccion) -> master
function spatial(A, gain, pan) {
  const g = A.ctx.createGain();
  g.gain.value = gain;
  const p = A.ctx.createStereoPanner();
  p.pan.value = clamp(pan, -1, 1);
  g.connect(p);
  p.connect(A.master);
  return g;
}

// --- capas continuas --------------------------------------------------------

// hum electrico grave: base casi inaudible; el motor lo crece por cercania a la luz viva.
// Lowpass suave para quitar el filo aspero del sawtooth (menos fatiga).
function startHum(A) {
  const g = A.ctx.createGain();
  g.gain.value = 0.006; // base casi inaudible lejos de toda luz
  const lp = A.ctx.createBiquadFilter();
  lp.type = 'lowpass';
  lp.frequency.value = 520;
  lp.Q.value = 0.6;
  const gains = [0.7, 0.28, 0.12]; // fundamental dominante, armonicos apenas
  [60, 120, 180].forEach((f, i) => {
    const o = A.ctx.createOscillator();
    o.type = 'sawtooth';
    o.frequency.value = f;
    const og = A.ctx.createGain();
    og.gain.value = gains[i];
    o.connect(og);
    og.connect(g);
    o.start();
  });
  g.connect(lp);
  lp.connect(A.master);
  A.humGain = g; // el motor modula por cercania de luces (hum)
}

function startPipe(A) {
  const src = noiseSource(A.ctx, 3);
  src.loop = true;
  const lp = A.ctx.createBiquadFilter();
  lp.type = 'lowpass';
  lp.frequency.value = 90;
  const g = A.ctx.createGain();
  g.gain.value = 0.08; // tuberia grave sutil, no debe fatigar
  src.connect(lp);
  lp.connect(g);
  g.connect(A.master);
  src.start();
}

// drip: goteo puntual (ping tonal con caida rapida + salpicadura filtrada)
function drip(A, when, gain, pan) {
  const out = spatial(A, gain, pan);
  const o = A.ctx.createOscillator();
  o.type = 'sine';
  o.frequency.setValueAtTime(1400 + Math.random() * 700, when);
  o.frequency.exponentialRampToValueAtTime(600, when + 0.08);
  const eg = A.ctx.createGain();
  eg.gain.setValueAtTime(0.0001, when);
  eg.gain.exponentialRampToValueAtTime(0.9, when + 0.004);
  eg.gain.exponentialRampToValueAtTime(0.0001, when + 0.14);
  o.connect(eg);
  eg.connect(out);
  o.start(when);
  o.stop(when + 0.16);
}

function maybeDrip(A, tMs) {
  if (tMs < A.nextDrip) return;
  A.nextDrip = tMs + 800 + Math.random() * 2600; // goteo moderado, sin saturar
  const pan = Math.random() * 2 - 1;
  drip(A, A.ctx.currentTime + 0.02, 0.34, pan);
}

// --- eventos puntuales ------------------------------------------------------

// flush: ruido de banda ancha con barrido descendente (~4s)
function flush(A, when, gain, pan) {
  const out = spatial(A, gain, pan);
  const src = noiseSource(A.ctx, 4.2);
  const bp = A.ctx.createBiquadFilter();
  bp.type = 'bandpass';
  bp.Q.value = 0.9;
  bp.frequency.setValueAtTime(1600, when);
  bp.frequency.exponentialRampToValueAtTime(180, when + 4.0);
  const eg = A.ctx.createGain();
  eg.gain.setValueAtTime(0.0001, when);
  eg.gain.linearRampToValueAtTime(0.8, when + 0.3);
  eg.gain.setValueAtTime(0.8, when + 3.2);
  eg.gain.exponentialRampToValueAtTime(0.0001, when + 4.2);
  src.connect(bp);
  bp.connect(eg);
  eg.connect(out);
  src.start(when);
  src.stop(when + 4.3);
}

// dryer: rugido subito (ruido + lowpass, ataque corto, 8-10s)
function dryer(A, when, gain, pan) {
  const out = spatial(A, gain, pan);
  const src = noiseSource(A.ctx, 9.5);
  const lp = A.ctx.createBiquadFilter();
  lp.type = 'lowpass';
  lp.frequency.value = 700;
  lp.Q.value = 1.2;
  const eg = A.ctx.createGain();
  eg.gain.setValueAtTime(0.0001, when);
  eg.gain.linearRampToValueAtTime(0.9, when + 0.12); // ataque corto
  eg.gain.setValueAtTime(0.9, when + 8.4);
  eg.gain.exponentialRampToValueAtTime(0.0001, when + 9.4);
  src.connect(lp);
  lp.connect(eg);
  eg.connect(out);
  src.start(when);
  src.stop(when + 9.5);
}

// stall_noise: golpes/crujidos apagados (varios bursts lowpass)
function stall_noise(A, when, gain, pan) {
  const out = spatial(A, gain, pan);
  for (let i = 0; i < 3; i++) {
    const t = when + i * (0.18 + Math.random() * 0.22);
    const src = noiseSource(A.ctx, 0.2);
    const lp = A.ctx.createBiquadFilter();
    lp.type = 'lowpass';
    lp.frequency.value = 320;
    const eg = A.ctx.createGain();
    eg.gain.setValueAtTime(0.0001, t);
    eg.gain.exponentialRampToValueAtTime(0.7, t + 0.01);
    eg.gain.exponentialRampToValueAtTime(0.0001, t + 0.15);
    src.connect(lp);
    lp.connect(eg);
    eg.connect(out);
    src.start(t);
    src.stop(t + 0.2);
  }
}

// pipe_knock: knocks metalicos (triangulo con caida rapida, un par de golpes)
function pipe_knock(A, when, gain, pan) {
  const out = spatial(A, gain, pan);
  for (let i = 0; i < 2; i++) {
    const t = when + i * 0.16;
    const o = A.ctx.createOscillator();
    o.type = 'triangle';
    o.frequency.setValueAtTime(220 - i * 40, t);
    o.frequency.exponentialRampToValueAtTime(90, t + 0.09);
    const eg = A.ctx.createGain();
    eg.gain.setValueAtTime(0.0001, t);
    eg.gain.exponentialRampToValueAtTime(0.8, t + 0.005);
    eg.gain.exponentialRampToValueAtTime(0.0001, t + 0.18);
    o.connect(eg);
    eg.connect(out);
    o.start(t);
    o.stop(t + 0.2);
  }
}

// --- eventos v3 (variedad sonora) -------------------------------------------

// shower_hiss: agua a presion — ruido agudo filtrado continuo (6-10s) con apertura gradual
function shower_hiss(A, when, gain, pan) {
  const out = spatial(A, gain, pan);
  const dur = 6 + Math.random() * 4; // 6..10s
  const src = noiseSource(A.ctx, dur + 0.5);
  const hp = A.ctx.createBiquadFilter();
  hp.type = 'highpass';
  hp.frequency.value = 1500;
  const bp = A.ctx.createBiquadFilter();
  bp.type = 'bandpass';
  bp.Q.value = 0.7;
  bp.frequency.value = 3200; // silbido agudo del chorro
  const eg = A.ctx.createGain();
  eg.gain.setValueAtTime(0.0001, when);
  eg.gain.linearRampToValueAtTime(0.6, when + 1.5); // apertura gradual (grifo abriendo)
  eg.gain.setValueAtTime(0.6, when + dur - 0.9);
  eg.gain.exponentialRampToValueAtTime(0.0001, when + dur); // cierre
  src.connect(hp);
  hp.connect(bp);
  bp.connect(eg);
  eg.connect(out);
  src.start(when);
  src.stop(when + dur + 0.4);
}

// door_slam: impacto seco corto (portazo) con resonancia grave del marco
function door_slam(A, when, gain, pan) {
  const out = spatial(A, gain, pan);
  const src = noiseSource(A.ctx, 0.25); // golpe de banda ancha, muy corto
  const lp = A.ctx.createBiquadFilter();
  lp.type = 'lowpass';
  lp.frequency.value = 900;
  const eg = A.ctx.createGain();
  eg.gain.setValueAtTime(0.0001, when);
  eg.gain.exponentialRampToValueAtTime(1.0, when + 0.004);
  eg.gain.exponentialRampToValueAtTime(0.0001, when + 0.16);
  src.connect(lp);
  lp.connect(eg);
  eg.connect(out);
  src.start(when);
  src.stop(when + 0.26);
  const o = A.ctx.createOscillator(); // resonancia grave (thump del marco)
  o.type = 'sine';
  o.frequency.setValueAtTime(110, when);
  o.frequency.exponentialRampToValueAtTime(48, when + 0.32);
  const og = A.ctx.createGain();
  og.gain.setValueAtTime(0.0001, when);
  og.gain.exponentialRampToValueAtTime(0.9, when + 0.01);
  og.gain.exponentialRampToValueAtTime(0.0001, when + 0.45);
  o.connect(og);
  og.connect(out);
  o.start(when);
  o.stop(when + 0.5);
}

// drain_gurgle: burbujeo grave irregular (~3-5s) — blips graves con caida y timing aleatorio
function drain_gurgle(A, when, gain, pan) {
  const out = spatial(A, gain, pan);
  const end = when + 3 + Math.random() * 2; // 3..5s
  let t = when;
  while (t < end) {
    const o = A.ctx.createOscillator();
    o.type = 'sine';
    const f0 = 70 + Math.random() * 90;
    o.frequency.setValueAtTime(f0, t);
    o.frequency.exponentialRampToValueAtTime(f0 * 0.55, t + 0.14);
    const eg = A.ctx.createGain();
    eg.gain.setValueAtTime(0.0001, t);
    eg.gain.exponentialRampToValueAtTime(0.55, t + 0.02);
    eg.gain.exponentialRampToValueAtTime(0.0001, t + 0.17);
    o.connect(eg);
    eg.connect(out);
    o.start(t);
    o.stop(t + 0.2);
    t += 0.08 + Math.random() * 0.24; // burbujas espaciadas de forma irregular
  }
}

// faucet_squeal: chirrido agudo corto de valvula (incomodo pero breve, no fatigante)
function faucet_squeal(A, when, gain, pan) {
  const out = spatial(A, gain, pan);
  const dur = 0.35 + Math.random() * 0.25; // 0.35..0.6s, deliberadamente breve
  const o = A.ctx.createOscillator();
  o.type = 'sawtooth';
  o.frequency.setValueAtTime(1800, when);
  o.frequency.linearRampToValueAtTime(2600 + Math.random() * 400, when + dur); // chirrido ascendente
  const bp = A.ctx.createBiquadFilter();
  bp.type = 'bandpass';
  bp.Q.value = 8; // formante estrecho -> timbre metalico de valvula
  bp.frequency.value = 2400;
  const eg = A.ctx.createGain();
  eg.gain.setValueAtTime(0.0001, when);
  eg.gain.exponentialRampToValueAtTime(0.45, when + 0.03);
  eg.gain.setValueAtTime(0.45, when + dur - 0.06);
  eg.gain.exponentialRampToValueAtTime(0.0001, when + dur);
  o.connect(bp);
  bp.connect(eg);
  eg.connect(out);
  o.start(when);
  o.stop(when + dur + 0.05);
}

const EVENT_SYNTH = { flush, dryer, stall_noise, pipe_knock,
  shower_hiss, door_slam, drain_gurgle, faucet_squeal };

// consumir la ventana deslizante de scheduleAmbientEvents y agendar cada evento a su hora
function pump(A, tMs) {
  const t1 = tMs + 1500; // lookahead 1.5s
  if (t1 <= A.cursor) return;
  const evs = scheduleAmbientEvents(SEED, A.cursor, t1);
  for (const e of evs) {
    const when = A.ctx.currentTime + Math.max(0, (e.t - tMs) / 1000);
    const dist = Math.hypot(e.dx, e.dz);
    const gain = attenuation(dist, A.ref, A.max);
    if (gain <= 0) continue;
    const pan = e.dx / (dist || 1);
    const fn = EVENT_SYNTH[e.type];
    if (fn) fn(A, when, gain, pan);
  }
  A.cursor = t1;
}

// footstep: pisada seca, o chapoteo si hay agua/charco cerca
function footstep(A, splash) {
  const when = A.ctx.currentTime + 0.01;
  const out = spatial(A, splash ? 0.5 : 0.3, 0);
  const src = noiseSource(A.ctx, 0.16);
  const f = A.ctx.createBiquadFilter();
  f.type = splash ? 'bandpass' : 'lowpass';
  f.frequency.value = splash ? 1200 : 240;
  const eg = A.ctx.createGain();
  eg.gain.setValueAtTime(0.0001, when);
  eg.gain.exponentialRampToValueAtTime(0.8, when + 0.008);
  eg.gain.exponentialRampToValueAtTime(0.0001, when + (splash ? 0.22 : 0.11));
  src.connect(f);
  f.connect(eg);
  eg.connect(out);
  src.start(when);
  src.stop(when + 0.24);
}

export function createAudio(GAME) {
  const A = {
    ctx: null, master: null, humGain: null, started: false,
    cursor: 0, nextDrip: 0,
    ref: GAME.platform.audio.refDist, max: GAME.platform.audio.maxDist,
  };

  function start() {
    if (A.started) return;
    A.started = true;
    const Ctx = window.AudioContext || window.webkitAudioContext;
    A.ctx = new Ctx();
    A.master = A.ctx.createGain();
    A.master.gain.value = 0.55;
    A.master.connect(A.ctx.destination);
    if (A.ctx.state === 'suspended') A.ctx.resume();
    startHum(A);
    startPipe(A);
    A.cursor = performance.now();
    A.nextDrip = A.cursor;
  }

  // humLevel 0..1 = intensidad de la luz viva mas cercana (el zumbido sigue a las luces).
  // Base minima + crecimiento sutil; tau corto para que la amplitud acompane el flicker.
  function update(tMs, humLevel) {
    if (!A.started) return;
    if (A.humGain) A.humGain.gain.setTargetAtTime(0.006 + 0.05 * (humLevel || 0), A.ctx.currentTime, 0.06);
    pump(A, tMs);
    maybeDrip(A, tMs);
  }

  function step(splash) {
    if (A.started) footstep(A, splash);
  }

  return { start, update, footstep: step };
}
