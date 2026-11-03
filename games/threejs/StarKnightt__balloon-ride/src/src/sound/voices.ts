// Bird voices copied from F:\summer-cycle\src\sound\voices.ts (Summer Cycle): birdChirps, birdTrill,
// birdWarble, birdWhistle. New for Balloon Ride: skylark, church bell, wicker creak, burner whoosh.
/**
 * Procedural "recordings": each generator renders one variation of a sound into Float32Array channels.
 * They run once (lazily, a few per frame through Kit.bank) and are played back as AudioBuffers.
 */
import { Biq, envAD, envASR, lerp, mode, normPeak, note, rr, sn, smooth, trim, type Rng } from "./dsp";

export type Gen = (r: Rng, sr: number) => Float32Array[];
const mono = (d: Float32Array, sr: number): Float32Array[] => normPeak([trim(d, sr)]);

// ───────────────────────────── birds ─────────────────────────────

/** Sparrow-like "chip chip" series. */
export const birdChirps: Gen = (r, sr) => {
  const d = new Float32Array(sr * 2);
  const n = 2 + Math.floor(r() * 5);
  const base = rr(r, 3000, 5200);
  const kind = Math.floor(r() * 3);
  let t = 0.01;
  for (let k = 0; k < n; k++) {
    const dur = rr(r, 0.035, 0.075);
    const fa = base * rr(r, 0.94, 1.06);
    const f =
      kind === 0 ? (u: number) => fa * lerp(1.25, 0.8, u) : kind === 1 ? (u: number) => fa * lerp(0.85, 1.3, u) : (u: number) => fa * (1 + 0.3 * Math.sin(Math.PI * u));
    const amp = rr(r, 0.6, 1);
    const e = envAD(0.18, 1.8);
    note(d, sr, t, dur, f, (u) => e(u) * amp, [1, 0.1, 0.03]);
    t += dur + rr(r, 0.04, 0.13);
  }
  return mono(d, sr);
};

/** Fast trill of repeated notes, gliding in pitch. */
export const birdTrill: Gen = (r, sr) => {
  const d = new Float32Array(sr * 2);
  const n = 8 + Math.floor(r() * 15);
  const rate = rr(r, 12, 22);
  const base = rr(r, 3400, 6000);
  const glide = rr(r, 0.75, 1.25);
  const sweep = rr(r, -0.25, 0.3);
  const e = envAD(0.2, 1.3);
  let t = 0.01;
  for (let k = 0; k < n; k++) {
    const u = k / Math.max(1, n - 1);
    const f = base * lerp(1, glide, u);
    const amp = 0.45 + 0.55 * Math.sin(Math.PI * (0.1 + 0.8 * u));
    note(d, sr, t, 0.62 / rate, (v) => f * (1 + sweep * (v - 0.5)), (v) => e(v) * amp, [1, 0.08]);
    t += 1 / rate;
  }
  return mono(d, sr);
};

/** Mejiro / swallow style twittering warble — a continuous melodic chatter. */
export const birdWarble: Gen = (r, sr) => {
  const d = new Float32Array(sr * 3);
  const total = rr(r, 1.1, 2.3);
  let f = rr(r, 3000, 5000);
  let t = 0.01;
  while (t < total) {
    const dur = rr(r, 0.045, 0.13);
    const f0 = f;
    const f1 = Math.min(6800, Math.max(2400, f * rr(r, 0.78, 1.28)));
    const vib = rr(r, 18, 40);
    const vd = rr(r, 0.02, 0.07);
    const amp = rr(r, 0.45, 1) * (t / total < 0.1 ? 0.6 : 1);
    const e = envASR(0.15, 0.25);
    note(d, sr, t, dur, (u) => lerp(f0, f1, u) * (1 + vd * sn(vib * u * dur)), (u) => e(u) * amp, [1, 0.08]);
    f = f1;
    t += dur + (r() < 0.3 ? rr(r, 0.02, 0.08) : rr(r, 0.004, 0.015));
  }
  return mono(d, sr);
};

/** Two/three-note whistle ("pii-yo", bulbul-ish), meant to be heard at a distance. */
export const birdWhistle: Gen = (r, sr) => {
  const d = new Float32Array(sr * 2);
  const fA = rr(r, 2700, 3300);
  let t = 0.01;
  const d1 = rr(r, 0.25, 0.38);
  note(d, sr, t, d1, (u) => fA * (1 + 0.09 * smooth(u)), envASR(0.12, 0.2), [1, 0.06]);
  t += d1 + rr(r, 0.03, 0.07);
  const d2 = rr(r, 0.2, 0.3);
  note(d, sr, t, d2, (u) => fA * lerp(1.05, 0.72, Math.pow(u, 0.7)), envASR(0.08, 0.35), [1, 0.06]);
  if (r() < 0.4) {
    t += d2 + rr(r, 0.12, 0.2);
    note(d, sr, t, d1 * 0.8, (u) => fA * (1 + 0.07 * smooth(u)), (u) => envASR(0.12, 0.25)(u) * 0.7, [1, 0.06]);
  }
  return mono(d, sr);
};

/**
 * Skylark: a long, unbroken, high warbling song of quick notes and little trills, poured out from
 * high over the fields (several seconds; heard faint and far).
 */
export const skylark: Gen = (r, sr) => {
  const total = rr(r, 4.5, 7.5);
  const d = new Float32Array(Math.ceil(sr * (total + 0.5)));
  let t = 0.02;
  let f = rr(r, 3200, 4600);
  while (t < total) {
    if (r() < 0.18) {
      // a little trill
      const n = 4 + Math.floor(r() * 7), rate = rr(r, 18, 30), f0 = rr(r, 3400, 6200);
      for (let k = 0; k < n; k++) note(d, sr, t + k / rate, 0.55 / rate, (u) => f0 * (1 + 0.12 * (u - 0.5)), envAD(0.25, 1.4), [1, 0.07]);
      t += n / rate + rr(r, 0.01, 0.05);
      continue;
    }
    const dur = rr(r, 0.035, 0.11);
    const f0 = f, f1 = Math.min(7000, Math.max(2600, f * rr(r, 0.75, 1.3)));
    const vib = rr(r, 25, 60), amp = rr(r, 0.5, 1);
    const e = envASR(0.18, 0.3);
    note(d, sr, t, dur, (u) => lerp(f0, f1, u) * (1 + 0.04 * sn(vib * u * dur)), (u) => e(u) * amp, [1, 0.06]);
    f = f1;
    t += dur + rr(r, 0.004, 0.03);
  }
  // A slow swell and fade so it arrives and leaves softly.
  const n = d.length;
  for (let i = 0; i < n; i++) {
    const u = i / n;
    d[i] *= smooth(u / 0.15) * smooth((1 - u) / 0.2) * (0.75 + 0.25 * Math.sin(u * 9 + 1));
  }
  return mono(d, sr);
};

// ───────────────────────────── church bells ─────────────────────────────

/**
 * One English church bell struck once: hum, prime, minor-third tierce, quint, nominal and the upper
 * partials, each a decaying sinusoid with a slow beat, plus the clapper's soft thud. `nominal` Hz.
 */
export const churchBell = (nominal: number): Gen => (r, sr) => {
  const P: [number, number, number][] = [
    [0.25, 0.4, 6.5],
    [0.5, 0.55, 4.5],
    [0.6, 0.45, 3.6],
    [0.75, 0.25, 2.8],
    [1.0, 0.8, 2.6],
    [1.25, 0.18, 1.5],
    [1.5, 0.22, 1.2],
    [2.0, 0.14, 0.8],
    [2.61, 0.07, 0.45],
  ];
  const d = new Float32Array(Math.floor(7.5 * sr));
  for (const [ratio, amp, tau] of P) {
    const f = nominal * ratio * rr(r, 0.998, 1.002);
    mode(d, sr, 0.01, f, amp, tau, r(), 0.002);
    // each partial is a close doublet: the slow warble of a real bell
    mode(d, sr, 0.01, f * 1.0025, amp * 0.35, tau * 0.9, r(), 0.002);
  }
  const lp = new Biq("lp", sr, 500, 0.7);
  for (let i = 0; i < Math.floor(0.05 * sr); i++) d[Math.floor(0.01 * sr) + i] += lp.run((r() * 2 - 1) * 0.5 * Math.exp(-i / (0.008 * sr)));
  const fo = Math.floor(1.2 * sr);
  for (let i = 0; i < fo; i++) d[d.length - 1 - i] *= i / fo;
  return normPeak([d]);
};

// ───────────────────────────── basket and burner ─────────────────────────────

/** A wicker creak: a stick-slip run of tiny resonant clicks, its rate gliding (0.3-0.9 s). */
export const creak: Gen = (r, sr) => {
  const dur = rr(r, 0.3, 0.9);
  const d = new Float32Array(Math.ceil(sr * (dur + 0.1)));
  const r0 = rr(r, 50, 120), r1 = r0 * rr(r, 0.6, 1.8);
  const m1 = rr(r, 650, 1100), m2 = m1 * rr(r, 1.6, 2.3);
  let t = 0.005;
  while (t < dur) {
    const u = t / dur;
    const amp = Math.sin(Math.PI * u) * rr(r, 0.4, 1);
    mode(d, sr, t, m1 * rr(r, 0.97, 1.03), amp, 0.004, r(), 0.0003);
    mode(d, sr, t, m2, amp * 0.4, 0.0025, r(), 0.0003);
    t += (1 / lerp(r0, r1, u)) * rr(r, 0.6, 1.5);
  }
  return mono(d, sr);
};

/** Burner ignition: a breathy whoosh as the valve opens, the band sweeping up and settling. */
export const whoosh: Gen = (r, sr) => {
  const dur = 0.75;
  const d = new Float32Array(Math.ceil(sr * dur));
  const n = d.length;
  let lp = 0, bp1 = 0, bp2 = 0;
  for (let i = 0; i < n; i++) {
    const u = i / n;
    const fc = 280 + 2200 * Math.pow(Math.sin(Math.PI * Math.min(1, u * 1.6)), 1.5);
    const a = 1 - Math.exp((-2 * Math.PI * fc) / sr);
    const w = r() * 2 - 1;
    // two one-pole stages: a soft band round fc
    bp1 += a * (w - bp1);
    bp2 += a * (bp1 - bp2);
    lp += 0.05 * (w - lp);
    const env = Math.min(1, u / 0.04) * Math.pow(1 - u, 1.6);
    d[i] = (bp1 - bp2 * 0.7 + lp * 0.8) * env;
  }
  return normPeak([d]);
};
