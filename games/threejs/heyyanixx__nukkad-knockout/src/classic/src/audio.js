// All sound is generated live with the Web Audio API: no audio files at all.
export class Audio {
  constructor() { this.ctx = null; this.sfxOn = true; this.musicOn = true; this.musicTimer = null; }

  unlock() {
    if (!this.ctx) {
      const AC = window.AudioContext || window.webkitAudioContext; if (!AC) return;
      const c = this.ctx = new AC();
      this.master = c.createGain(); this.master.gain.value = 0.8; this.master.connect(c.destination);
      this.sfx = c.createGain(); this.sfx.gain.value = this.sfxOn ? 1 : 0; this.sfx.connect(this.master);
      this.mus = c.createGain(); this.mus.gain.value = this.musicOn ? 0.32 : 0; this.mus.connect(this.master);
      const len = c.sampleRate * 1.5; this.noiseBuf = c.createBuffer(1, len, c.sampleRate);
      const d = this.noiseBuf.getChannelData(0); for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
      document.addEventListener('visibilitychange', () => { if (document.hidden) c.suspend(); else c.resume(); });
    }
    if (this.ctx.state === 'suspended') this.ctx.resume();
  }
  setSfx(on) { this.sfxOn = on; if (this.sfx) this.sfx.gain.value = on ? 1 : 0; }
  setMusic(on) { this.musicOn = on; if (this.mus) this.mus.gain.value = on ? 0.32 : 0; }

  // --- building blocks ---
  tone(type, f0, f1, dur, vol = 0.3, when = 0, dest = this.sfx) {
    const c = this.ctx, t = c.currentTime + when, o = c.createOscillator(), g = c.createGain();
    o.type = type; o.frequency.setValueAtTime(f0, t); if (f1 !== f0) o.frequency.exponentialRampToValueAtTime(Math.max(20, f1), t + dur);
    g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(vol, t + 0.008); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(g); g.connect(dest); o.start(t); o.stop(t + dur + 0.02); return o;
  }
  noise(dur, vol = 0.3, ftype = 'bandpass', f0 = 1000, f1 = f0, q = 1, when = 0, dest = this.sfx) {
    const c = this.ctx, t = c.currentTime + when, s = c.createBufferSource(), f = c.createBiquadFilter(), g = c.createGain();
    s.buffer = this.noiseBuf; f.type = ftype; f.Q.value = q; f.frequency.setValueAtTime(f0, t); if (f1 !== f0) f.frequency.exponentialRampToValueAtTime(f1, t + dur);
    g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(vol, t + 0.01); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    s.connect(f); f.connect(g); g.connect(dest); s.start(t, Math.random()); s.stop(t + dur + 0.02);
  }
  // stylised robot "voice": a sawtooth through two formant filters, one syllable per note
  voice(notes, vowel = 'a', when = 0, vol = 0.35) {
    const F = { a: [800, 1200], o: [500, 900], e: [450, 2000], i: [300, 2300], u: [350, 800] }[vowel];
    const c = this.ctx; let t0 = when;
    for (const [freq, dur] of notes) {
      const t = c.currentTime + t0, o = c.createOscillator(), g = c.createGain(); o.type = 'sawtooth'; o.frequency.setValueAtTime(freq, t); o.frequency.linearRampToValueAtTime(freq * 0.85, t + dur);
      const mix = c.createGain(); mix.gain.value = 1;
      for (const ff of F) { const bp = c.createBiquadFilter(); bp.type = 'bandpass'; bp.frequency.value = ff; bp.Q.value = 6; o.connect(bp); bp.connect(mix); }
      g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(vol, t + 0.02); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
      mix.connect(g); g.connect(this.sfx); o.start(t); o.stop(t + dur + 0.05); t0 += dur * 0.9;
    }
  }

  play(name) {
    if (!this.ctx || !this.sfxOn) return;
    const T = this.tone.bind(this), N = this.noise.bind(this);
    switch (name) {
      case 'hit': T('sine', 160, 50, 0.12, 0.6); N(0.07, 0.4, 'highpass', 1800); break;
      case 'heavy': T('sine', 120, 35, 0.25, 0.8); T('square', 90, 40, 0.12, 0.2); N(0.15, 0.5, 'lowpass', 2500, 400); break;
      case 'block': T('square', 1100, 900, 0.05, 0.15); N(0.08, 0.35, 'bandpass', 3200, 2500, 4); break;
      case 'jump': T('sine', 260, 520, 0.12, 0.15); break;
      case 'grab': N(0.12, 0.3, 'bandpass', 600, 300); T('sine', 200, 140, 0.1, 0.2); break;
      case 'thud': T('sine', 90, 40, 0.2, 0.6); N(0.2, 0.25, 'lowpass', 800, 200); break;
      case 'whoosh': N(0.3, 0.3, 'bandpass', 400, 2400, 2); break;
      case 'super': T('sawtooth', 120, 900, 0.5, 0.18); N(0.5, 0.25, 'bandpass', 500, 4000, 3); this.voice([[220, 0.14], [330, 0.2]], 'u', 0.05); break;
      case 'round': this.voice([[180, 0.18], [160, 0.18], [200, 0.25]], 'o'); break;
      case 'fight': this.voice([[300, 0.12], [360, 0.3]], 'a'); T('square', 440, 440, 0.12, 0.08, 0.3); break;
      case 'ko': T('sine', 70, 30, 0.9, 0.9); N(1.2, 0.4, 'lowpass', 1500, 100); this.voice([[150, 0.25], [110, 0.5]], 'o', 0.1, 0.4); this.play('crowd'); break;
      case 'crowd': for (let i = 0; i < 3; i++) N(0.9, 0.12, 'bandpass', 900 + i * 400, 1300 + i * 300, 1.2, i * 0.05); break;
      case 'moo': { const o = T('sawtooth', 150, 105, 0.9, 0.25); break; }
      case 'horn': T('square', 420, 420, 0.14, 0.15); T('square', 520, 520, 0.18, 0.15, 0.18); break;
      case 'splash': N(0.5, 0.4, 'lowpass', 3000, 500); T('sine', 600, 200, 0.2, 0.15); break;
      case 'lock': T('square', 1500, 1500, 0.05, 0.12); T('square', 1500, 1500, 0.05, 0.12, 0.12); T('square', 1800, 1800, 0.08, 0.12, 0.24); break;
      case 'shot': N(0.18, 0.7, 'highpass', 800); T('sine', 300, 60, 0.15, 0.5); break;
      case 'jelly': T('sine', 300, 600, 0.12, 0.3); T('sine', 600, 250, 0.25, 0.25, 0.12); break;
      case 'likes': for (let i = 0; i < 7; i++) T('sine', 700 + i * 90, 1100 + i * 90, 0.06, 0.18, i * 0.085); break;
      case 'flash': N(0.04, 0.5, 'highpass', 4000); T('sine', 2400, 3200, 0.5, 0.12, 0.02); break;
      case 'scream': { this.voice([[220, 0.25], [260, 0.35], [240, 0.5]], 'a', 0, 0.5); N(1.0, 0.25, 'bandpass', 900, 600, 1.5); break; }
      case 'lol': this.voice([[400, 0.09], [380, 0.09], [420, 0.12]], 'a', 0, 0.3); break;
      case 'roast': T('sine', 1800, 2600, 0.35, 0.08); this.voice([[200, 0.15], [180, 0.2]], 'o'); break;
      case 'bruh': this.voice([[95, 0.5]], 'u', 0, 0.5); break;
      case 'powercut': T('sawtooth', 120, 30, 0.8, 0.2); break;
      case 'thunder': N(1.6, 0.5, 'lowpass', 600, 80); break;
      case 'timeup': T('square', 220, 220, 0.6, 0.15); T('square', 233, 233, 0.6, 0.15); break;
      case 'win': [523, 659, 784, 1047].forEach((f, i) => T('square', f, f, 0.18, 0.12, i * 0.12)); this.play('crowd'); break;
      case 'train': T('square', 330, 330, 0.7, 0.12); T('square', 392, 392, 0.7, 0.1); N(2.5, 0.35, 'lowpass', 900, 300, 1, 0.1); break;
      case 'ui': T('square', 880, 880, 0.04, 0.08); break;
      case 'select': T('square', 660, 990, 0.08, 0.1); break;
    }
  }

  // --- original looping beat (Bhairav-ish scale, 104 BPM, dhol + tabla + bass) ---
  startMusic(style = 'fight') {
    if (!this.ctx) return; this.stopMusic();
    const c = this.ctx, bpm = style === 'fight' ? 112 : 92, step = 60 / bpm / 4;
    const scale = [130.8, 138.6, 164.8, 174.6, 196.0, 207.7, 246.9, 261.6];
    const bass = [0, 0, 4, 0, 5, 4, 2, 1];
    const lead = [7, -1, 6, 5, 4, -1, 5, 4, 2, -1, 1, 2, 4, -1, 2, 1];
    let i = 0, next = c.currentTime + 0.05;
    const tick = () => {
      while (next < c.currentTime + 0.15) {
        const s = i % 16, bar = Math.floor(i / 16) % 8, w = next - c.currentTime;
        if (s % 4 === 0 || s === 10) this.tone('sine', 110, 45, 0.22, 0.7, w, this.mus);           // dhol low
        if (s === 4 || s === 12) this.noise(0.12, 0.35, 'bandpass', 900, 600, 2, w, this.mus);      // dhol slap
        if (s % 2 === 1) this.tone('sine', 520 + (s % 4) * 60, 380, 0.07, 0.18, w, this.mus);        // tabla
        this.noise(0.03, 0.06, 'highpass', 7000, 7000, 1, w, this.mus);                             // shaker
        if (s % 4 === 0) this.tone('triangle', scale[bass[bar]] / 2, scale[bass[bar]] / 2, step * 3.5, 0.35, w, this.mus);
        if (style === 'fight' && bar % 2 === 1 && lead[s] >= 0) this.tone('square', scale[lead[s]] * 2, scale[lead[s]] * 2, step * 0.9, 0.06, w, this.mus);
        next += step; i++;
      }
    };
    this.musicTimer = setInterval(tick, 40); tick();
  }
  stopMusic() { if (this.musicTimer) clearInterval(this.musicTimer); this.musicTimer = null; }
}
