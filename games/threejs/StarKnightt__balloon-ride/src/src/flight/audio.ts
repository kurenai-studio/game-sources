/**
 * The ride's sound, all synthesised in code (no samples), quiet and calm:
 *  - burner: a noisy, pulsing roar while it burns (brown and band noise, fluttered by two slow
 *    LFOs), an ignition whoosh as the valve opens, and a falling tail as it closes; the vent hisses;
 *  - wind: the reused Bay Ride breeze (sound/air.ts), rising gently with altitude and speed;
 *  - birds: songbird chirps low over the fields, skylarks pouring out song, sparse higher up;
 *  - church bells: a ring of six now and then when the village is near (long bell partials, reverb);
 *  - basket: a quiet wicker creak now and then, more after a burn.
 * Starts on the first user gesture (browsers keep audio suspended until then). M mutes.
 */
import { Kit, GEN_SR, type RideState } from "../sound/kit";
import { WindLayer } from "../sound/air";
import { clamp, reverbIR, rr, smoothstep, vnoise } from "../sound/dsp";
import { birdChirps, birdTrill, birdWarble, birdWhistle, churchBell, creak, skylark, whoosh } from "../sound/voices";

/** What the sound needs from the ride each frame. */
export interface AudioIn {
  burner: boolean;
  vent: boolean;
  /** Height above ground (m). */
  agl: number;
  /** Horizontal ground speed (m/s). */
  speed: number;
  /** Vertical speed (m/s). */
  climb: number;
  /** Horizontal distance to the village centre (m). */
  village: number;
  night: number;
  evening: number;
}

const MASTER = 0.55;
/** Bell nominals (Hz), a ring of six in a major scale, treble first. */
const BELLS = [784, 698.5, 659.3, 587.3, 523.3, 466.2];

export class FlightAudio {
  private ctx: AudioContext | null = null;
  private kit: Kit | null = null;
  private master: GainNode | null = null;
  private verb: GainNode | null = null;
  private wind: WindLayer | null = null;
  private roar: GainNode | null = null;
  private roarLP: BiquadFilterNode | null = null;
  private hiss: GainNode | null = null;
  private wasBurning = false;
  private muted = false;
  private nextBird = 0;
  private nextLark = 0;
  private nextBells = 0;
  private nextCreak = 0;
  private paramT = 0;

  /** Call from a user gesture. */
  start(): void {
    if (this.ctx) {
      if (this.ctx.state === "suspended") void this.ctx.resume();
      return;
    }
    const AC = window.AudioContext ?? (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    if (!AC) return;
    const ctx = new AC();
    this.ctx = ctx;
    const kit = new Kit(ctx, 4242);
    this.kit = kit;
    this.master = ctx.createGain();
    this.master.gain.value = this.muted ? 0 : MASTER;
    this.master.connect(ctx.destination);
    // Open-air reverb for the bells, birds and the burner's tail.
    const conv = ctx.createConvolver();
    conv.buffer = kit.buffer(reverbIR(ctx.sampleRate, kit.rng, 3.2, 2.6), ctx.sampleRate);
    this.verb = ctx.createGain();
    this.verb.gain.value = 0.5;
    this.verb.connect(conv).connect(this.master);

    this.wind = new WindLayer(kit);
    this.wind.out.connect(this.master);
    this.wind.wet.connect(this.verb);

    // Burner roar: brown noise for the body, band noise for the rush, both fluttering.
    const body = kit.loop(kit.brown);
    this.roarLP = ctx.createBiquadFilter();
    this.roarLP.type = "lowpass";
    this.roarLP.frequency.value = 420;
    this.roarLP.Q.value = 0.8;
    const bodyG = ctx.createGain();
    bodyG.gain.value = 1.1;
    body.connect(this.roarLP).connect(bodyG);
    const rush = kit.loop(kit.pink, 0.9);
    const rushBP = ctx.createBiquadFilter();
    rushBP.type = "bandpass";
    rushBP.frequency.value = 1100;
    rushBP.Q.value = 0.7;
    const rushG = ctx.createGain();
    rushG.gain.value = 0.22;
    rush.connect(rushBP).connect(rushG);
    // Pulsing: the flame's throb (~7 Hz) and a slower waver.
    const pulse = ctx.createGain();
    pulse.gain.value = 0.78;
    for (const [f, depth] of [[6.7, 0.16], [2.3, 0.09]] as const) {
      const o = ctx.createOscillator();
      o.frequency.value = f;
      const g = ctx.createGain();
      g.gain.value = depth;
      o.connect(g).connect(pulse.gain);
      o.start();
    }
    bodyG.connect(pulse);
    rushG.connect(pulse);
    this.roar = ctx.createGain();
    this.roar.gain.value = 0;
    pulse.connect(this.roar);
    this.roar.connect(this.master);
    const roarWet = ctx.createGain();
    roarWet.gain.value = 0.12;
    this.roar.connect(roarWet).connect(this.verb);

    const vs = kit.loop(kit.white);
    const vf = ctx.createBiquadFilter();
    vf.type = "highpass";
    vf.frequency.value = 2400;
    this.hiss = ctx.createGain();
    this.hiss.gain.value = 0;
    vs.connect(vf).connect(this.hiss).connect(this.master);

    kit.bank("whoosh", 2, GEN_SR, whoosh, true);
    kit.bank("chirp", 4, GEN_SR, birdChirps);
    kit.bank("trill", 3, GEN_SR, birdTrill);
    kit.bank("warble", 3, GEN_SR, birdWarble);
    kit.bank("whistle", 2, GEN_SR, birdWhistle);
    kit.bank("lark", 3, GEN_SR, skylark);
    kit.bank("creak", 4, GEN_SR, creak);
    BELLS.forEach((f, i) => kit.bank(`bell${i}`, 1, 22050, churchBell(f)));
    const now = ctx.currentTime;
    this.nextBird = now + 2;
    this.nextLark = now + 6;
    this.nextBells = now + 12;
    this.nextCreak = now + 4;
  }

  /** M: mute / unmute (smooth). */
  toggleMute(): boolean {
    this.muted = !this.muted;
    if (this.ctx && this.master) this.master.gain.setTargetAtTime(this.muted ? 0 : MASTER, this.ctx.currentTime, 0.15);
    return this.muted;
  }

  update(s: AudioIn): void {
    const ctx = this.ctx, kit = this.kit;
    if (!ctx || !kit || !this.roar || !this.roarLP || !this.hiss || !this.master || !this.verb) return;
    kit.pump(3);
    const now = ctx.currentTime;
    const r = kit.rng;

    // ---- burner
    if (s.burner && !this.wasBurning) {
      const w = kit.pick("whoosh");
      if (w) kit.play(w, now + 0.005, { dest: this.master, gain: 0.35, wet: 0.2, wetDest: this.verb, rate: rr(r, 0.95, 1.05) });
      this.roar.gain.cancelScheduledValues(now);
      this.roar.gain.setTargetAtTime(0.42, now + 0.04, 0.09);
      this.roarLP.frequency.cancelScheduledValues(now);
      this.roarLP.frequency.setTargetAtTime(460, now, 0.1);
    } else if (!s.burner && this.wasBurning) {
      // The tail: the roar sinks in pitch as it dies.
      this.roar.gain.cancelScheduledValues(now);
      this.roar.gain.setTargetAtTime(0, now, 0.22);
      this.roarLP.frequency.cancelScheduledValues(now);
      this.roarLP.frequency.setTargetAtTime(170, now, 0.25);
      this.nextCreak = Math.min(this.nextCreak, now + rr(r, 0.6, 2));
    }
    this.wasBurning = s.burner;
    this.hiss.gain.setTargetAtTime(s.vent ? 0.045 : 0, now, 0.15);

    // ---- wind (continuous params ~30 times a second)
    if (now - this.paramT > 1 / 30) {
      this.paramT = now;
      const st: RideState = {
        move: clamp(1.2 + s.agl / 110 + s.speed * 0.5 + Math.abs(s.climb) * 1.2, 0, 14),
        steer: 0,
        altitude: s.agl,
        burner: s.burner ? 1 : 0,
        vent: s.vent ? 1 : 0,
        sea: 0,
        evening: s.evening,
        night: s.night,
      };
      const gust = clamp(0.35 + 0.65 * vnoise(now / 9, 3) * smoothstep(20, 300, s.agl + 60), 0, 1);
      this.wind?.params(now, st, { gust, turb: vnoise(now * 0.7, 9) });
    }

    // ---- birds: busy low over the fields, sparse at height, quiet at night
    const low = 1 - smoothstep(60, 450, s.agl);
    const dayK = 1 - 0.85 * s.night;
    if (now >= this.nextBird) {
      const kind = ["chirp", "chirp", "trill", "warble", "whistle"][Math.floor(r() * 5)];
      const b = kit.pick(kind);
      if (b) {
        const far = 1 - low * 0.6;
        kit.play(b, now + 0.02, { dest: this.master, gain: 0.09 * (0.35 + 0.65 * low) * dayK * (1.1 - far * 0.5), pan: rr(r, -0.9, 0.9), wet: 0.5 + 0.4 * far, wetDest: this.verb, rate: rr(r, 0.94, 1.06) });
      }
      this.nextBird = now + rr(r, 1.5, 5) / Math.max(0.12, low * dayK) + (b ? b.duration : 1);
    }
    if (now >= this.nextLark) {
      const b = kit.pick("lark");
      if (b && s.night < 0.6) {
        const pan = rr(r, -0.7, 0.7);
        kit.play(b, now + 0.02, { dest: this.master, gain: 0.05 * (0.25 + 0.75 * low), pan, panTo: pan + rr(r, -0.2, 0.2), wet: 0.6, wetDest: this.verb, rate: rr(r, 0.97, 1.03) });
      }
      this.nextLark = now + (b ? b.duration : 2) + rr(r, 6, 16) / Math.max(0.15, low);
    }

    // ---- church bells: a few rows of rounds when the village is near
    if (now >= this.nextBells) {
      const near = 1 - smoothstep(350, 2300, s.village);
      if (near > 0.05 && kit.has("bell5")) {
        const rows = 2 + Math.floor(r() * 3);
        let t = now + 0.1;
        const g = 0.11 * near * (1 - 0.4 * smoothstep(200, 900, s.agl));
        const pan = rr(r, -0.5, 0.5);
        for (let row = 0; row < rows; row++) {
          for (let i = 0; i < BELLS.length; i++) {
            const b = kit.pick(`bell${i}`);
            if (b) kit.play(b, t, { dest: this.master, gain: g * (0.8 + 0.2 * r()), pan: pan + (i - 2.5) * 0.04, wet: 0.9, wetDest: this.verb });
            t += 0.46 + rr(r, -0.02, 0.02);
          }
          t += 0.46; // the handstroke gap
        }
        this.nextBells = t + rr(r, 70, 140);
      } else this.nextBells = now + 8;
    }

    // ---- basket creak: quiet, now and then
    if (now >= this.nextCreak) {
      const b = kit.pick("creak");
      if (b) kit.play(b, now + 0.02, { dest: this.master, gain: 0.05, pan: rr(r, -0.4, 0.4), rate: rr(r, 0.85, 1.15) });
      this.nextCreak = now + rr(r, 6, 16);
    }
  }
}
