// Procedural background music via Web Audio API — zero external files.
// Each track is built from: a sustained chord pad + sequenced melody + bass line.

function midiToHz(m) { return 440 * Math.pow(2, (m - 69) / 12); }

// ─── Track definitions ────────────────────────────────────────────────────────
// pad:    MIDI notes for sustained chord pad (triangle/sawtooth, fade-in)
// bass:   MIDI notes for bass line (sine, every 2 melody beats)
// melody: MIDI notes for lead melody (plays every beat, loops)
// bpm:    tempo — controls melody/bass note spacing
// ambience: optional procedural ambient layer per area —
// 'birds' | 'crickets' | 'wind' | 'drips' | 'fire'
const TRACKS = {
    menu: {
        bpm: 78,
        pad:       [45, 48, 52, 57],                          // Am: A2 C3 E3 A3
        bass:      [33, 40, 33, 40],                          // A1 E2 A1 E2
        melody:    [69, 71, 72, 76, 74, 72, 71, 69],          // A4 B4 C5 E5 D5 C5 B4 A4
        padWave:    'triangle',
        melodyWave: 'triangle',
    },
    village: {
        bpm: 100,
        ambience:  'birds',
        pad:       [48, 52, 55, 60],                          // C major: C3 E3 G3 C4
        bass:      [36, 43, 36, 43],                          // C2 G2
        melody:    [72, 76, 79, 81, 79, 76, 74, 72],          // C5 E5 G5 A5 G5 E5 D5 C5
        padWave:    'triangle',
        melodyWave: 'sine',
    },
    meadows: {
        bpm: 88,
        ambience:  'birds',
        pad:       [55, 59, 62, 67],                          // G major: G3 B3 D4 G4
        bass:      [43, 50, 43, 50],                          // G2 D3
        melody:    [67, 69, 71, 74, 71, 69, 67, 64],          // G4 A4 B4 D5 B4 A4 G4 E4
        padWave:    'triangle',
        melodyWave: 'sine',
    },
    forest: {
        bpm: 68,
        ambience:  'crickets',
        pad:       [50, 53, 57, 60],                          // Dm7: D3 F3 A3 C4
        bass:      [38, 45, 38, 45],                          // D2 A2
        melody:    [62, 65, 69, 72, 69, 67, 65, 62],          // D4 F4 A4 C5 A4 G4 F4 D4
        padWave:    'sawtooth',
        melodyWave: 'triangle',
    },
    plains: {
        bpm: 108,
        ambience:  'wind',
        pad:       [53, 57, 60, 65],                          // F major: F3 A3 C4 F4
        bass:      [41, 48, 41, 48],                          // F2 C3
        melody:    [65, 67, 69, 72, 69, 67, 65, 67],          // F4 G4 A4 C5 A4 G4 F4 G4
        padWave:    'triangle',
        melodyWave: 'sine',
    },
    mountains: {
        bpm: 80,
        ambience:  'wind',
        pad:       [52, 55, 59, 62],                          // Em7: E3 G3 B3 D4
        bass:      [40, 47, 40, 47],                          // E2 B2
        melody:    [64, 67, 71, 74, 71, 67, 64, 62],          // E4 G4 B4 D5 B4 G4 E4 D4
        padWave:    'triangle',
        melodyWave: 'sawtooth',
    },
    dungeon: {
        bpm: 58,
        ambience:  'drips',
        pad:       [47, 50, 53, 56],                          // Bdim7: B2 D3 F3 Ab3
        bass:      [35, 42, 35, 39],                          // B1 F#2 B1 Eb2
        melody:    [59, 62, 65, 68, 65, 62, 59, 56],          // B3 D4 F4 Ab4 F4 D4 B3 Ab3
        padWave:    'sawtooth',
        melodyWave: 'square',
    },
    combat: {
        bpm: 138,
        pad:       [38, 41, 45, 50],                          // Dm: D2 F2 A2 D3
        bass:      [26, 26, 33, 26],                          // D1 D1 A1 D1 (driving)
        melody:    [62, 63, 65, 69, 65, 63, 62, 60],          // D4 Eb4 F4 A4 F4 Eb4 D4 C4
        padWave:    'sawtooth',
        melodyWave: 'square',
    },
    // ── Boss fight: heavy rock / metal ─────────────────────────────────────────
    // E minor power chord pad + gallop bass + Em pentatonic riff + live drums
    boss: {
        bpm: 170,
        pad:        [40, 47, 52, 55],                          // E2 B2 E3 G3 — Em power voicing
        bass:       [28, 28, 40, 28],                          // E1 E1 E2 E1 — heavy pump
        melody:     [52, 52, 64, 62, 64, 52, 59, 57],          // E3 E3 E4 D4 E4 E3 B3 A3 — metal riff
        padWave:    'square',
        melodyWave: 'square',
        melodyPeak: 0.09,    // louder lead
        bassPeak:   0.18,    // heavy low end
        melodyDur:  0.45,    // staccato — punchy palm-mute feel
        perc:       { kick: [0, 4], snare: [2, 6] },           // classic rock 4/4 beat (8-beat cycle)
    },
    // ── Profundezas: lento, dissonante, claustrofóbico ─────────────────────────
    underground: {
        bpm: 46,
        ambience:  'drips',
        pad:       [38, 44, 47, 53],                          // D2 Ab2 B2 F3 — trítonos empilhados
        bass:      [26, 26, 25, 26],                          // D1 D1 C#1 D1 — pêndulo grave
        melody:    [50, 53, 56, 50, 47, 50, 44, 47],          // D3 F3 Ab3... arrasto cromático
        padWave:    'sawtooth',
        melodyWave: 'triangle',
        melodyPeak: 0.035,
        bassPeak:   0.10,
        melodyDur:  1.1,
    },
    // ── Cripta do Interpretador: máquina antiga ainda executando ──────────────
    codex: {
        bpm: 84,
        ambience:  'drips',
        pad:       [40, 47, 52, 55],                          // E2 B2 E3 G3 — quinta oca
        bass:      [28, 28, 33, 31],                          // E1 E1 A1 G1 — pulso de clock
        melody:    [64, 67, 71, 67, 64, 62, 64, 59],          // padrão que retorna ao início: loop
        padWave:    'square',
        melodyWave: 'square',
        melodyPeak: 0.030,
        melodyDur:  0.35,
    },
    // ── Interior / Home: soft, slow, safe ──────────────────────────────────────
    home: {
        bpm: 70,
        ambience:  'fire',
        pad:       [53, 57, 60, 64],                          // Fmaj7: F3 A3 C4 E4
        bass:      [41, 48, 41, 48],                          // F2 C3
        melody:    [72, 72, 71, 69, 67, 65, 67, 64],          // C5 C5 B4 A4 G4 F4 G4 E4
        padWave:    'triangle',
        melodyWave: 'sine',
        melodyPeak: 0.04,
        bassPeak:   0.06,
    },
};

// ─── Engine ───────────────────────────────────────────────────────────────────

class MusicEngine {
    constructor() {
        this._ctx         = null;
        this._master      = null;
        this._padNodes    = [];   // { osc, gain | null } — persistent pad oscillators
        this._schedId     = null; // setInterval ID
        this._beat        = 0;
        this._nextTime    = 0;
        this._track       = null;
        this._key         = null;
        this._wantKey     = null; // remembered key for re-enable
        this._noiseBuffer = null; // reusable white noise buffer for snare drum
        this.enabled      = localStorage.getItem('meanfall_sound') !== 'off';
        this._volume      = 0.20;
    }

    _ensureCtx() {
        if (this._ctx) {
            if (this._ctx.state === 'suspended') this._ctx.resume();
            return this._ctx;
        }
        try {
            this._ctx    = new (window.AudioContext || window.webkitAudioContext)();
            this._master = this._ctx.createGain();
            this._master.gain.value = this._volume;
            this._master.connect(this._ctx.destination);
            // Resume on first user gesture (required by browser autoplay policy)
            const resume = () => { if (this._ctx?.state === 'suspended') this._ctx.resume(); };
            document.addEventListener('click',      resume);
            document.addEventListener('keydown',    resume);
            document.addEventListener('touchstart', resume, { passive: true });
        } catch (e) {
            this.enabled = false;
        }
        return this._ctx;
    }

    // ── Public API ────────────────────────────────────────────────────────────

    play(key) {
        this._wantKey = key;
        if (!this.enabled) return;
        if (this._key === key) return;
        this._halt(true);                     // crossfade: fade out old track
        this._key   = key;
        const track = TRACKS[key];
        if (!track) return;
        const ctx = this._ensureCtx();
        if (!ctx) return;
        this._track    = track;
        this._beat     = 0;
        this._nextTime = ctx.currentTime + 0.08;
        this._startPad(ctx, track);
        this._schedId = setInterval(() => this._tick(), 80);
        this._startAmbience(track.ambience);
    }

    // Master music volume, 0..1 from the UI slider (scaled internally).
    setVolume(v) {
        this._volume = Math.max(0, Math.min(1, v)) * 0.55;
        if (this._master && this._ctx && !this._feverOrigBpm) {
            this._master.gain.setTargetAtTime(this._volume, this._ctx.currentTime, 0.1);
        }
    }

    stop() {
        this._wantKey = null;
        this._halt(true);
        this._key = null;
    }

    setEnabled(v) {
        this.enabled = v;
        if (!v) {
            this._halt(true);
            this._key = null;
        } else if (this._wantKey) {
            const k = this._wantKey;
            this._wantKey = null;
            this.play(k);
        }
    }

    // Fever mode: boost volume + speed up the current track by ~20%
    setFever(active) {
        if (!this._ctx || !this._master) return;
        const now = this._ctx.currentTime;
        if (active) {
            this._master.gain.setTargetAtTime(Math.min(0.5, this._volume * 1.9), now, 0.35);
            if (this._track && !this._feverOrigBpm) {
                this._feverOrigBpm = this._track.bpm;
                this._track = { ...this._track, bpm: Math.round(this._track.bpm * 1.22) };
            }
        } else {
            this._master.gain.setTargetAtTime(this._volume, now, 0.5);
            if (this._track && this._feverOrigBpm) {
                this._track = { ...this._track, bpm: this._feverOrigBpm };
                this._feverOrigBpm = null;
            }
        }
    }

    // ── Internal: stop/crossfade ──────────────────────────────────────────────

    _halt(fade) {
        if (this._schedId) { clearInterval(this._schedId); this._schedId = null; }
        if (this._ambId)   { clearInterval(this._ambId);   this._ambId   = null; }
        const now = this._ctx ? this._ctx.currentTime : 0;
        for (const { osc, gain } of this._padNodes) {
            if (gain && fade) {
                try { gain.gain.setTargetAtTime(0, now, 0.4); } catch (e) {}
            }
            const delay = fade ? 1800 : 0;
            setTimeout(() => { try { osc.stop(); } catch (e) {} }, delay);
        }
        this._padNodes = [];
        this._track    = null;
    }

    // ── Internal: sustained chord pad ─────────────────────────────────────────

    _startPad(ctx, track) {
        const count = track.pad.length;
        for (let i = 0; i < count; i++) {
            const freq = midiToHz(track.pad[i]);
            const osc  = ctx.createOscillator();
            const gain = ctx.createGain();
            osc.type = track.padWave || 'triangle';
            osc.frequency.value = freq;
            gain.gain.value = 0;
            gain.gain.linearRampToValueAtTime(0.03 / count, ctx.currentTime + 1.6);

            // Subtle vibrato (LFO → frequency modulation)
            const lfo  = ctx.createOscillator();
            const lfog = ctx.createGain();
            lfo.frequency.value = 0.28 + i * 0.06;
            lfog.gain.value     = freq * 0.006;
            lfo.connect(lfog);
            lfog.connect(osc.frequency);

            osc.connect(gain);
            gain.connect(this._master);
            osc.start();
            lfo.start();

            this._padNodes.push({ osc, gain });
            this._padNodes.push({ osc: lfo, gain: null }); // LFO: no gain fade needed
        }
    }

    // ── Internal: transient note (melody + bass) ──────────────────────────────

    _note(freq, type, start, dur, peak) {
        const ctx  = this._ctx;
        const osc  = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = type;
        osc.frequency.value = freq;
        gain.gain.setValueAtTime(0.001, start);
        gain.gain.linearRampToValueAtTime(peak, start + 0.015);
        gain.gain.exponentialRampToValueAtTime(0.001, start + dur);
        osc.connect(gain);
        gain.connect(this._master);
        osc.start(start);
        osc.stop(start + dur + 0.02);
    }

    // ── Internal: lookahead scheduler ─────────────────────────────────────────

    _tick() {
        const ctx   = this._ctx;
        const track = this._track;
        if (!ctx || !track) return;
        // Context still suspended (no user gesture yet) — reset clock so no burst on resume
        if (ctx.state !== 'running') { this._nextTime = ctx.currentTime + 0.08; return; }
        // Fell behind (e.g. tab was hidden) — skip ahead instead of dumping notes
        if (this._nextTime < ctx.currentTime) this._nextTime = ctx.currentTime + 0.02;
        const beatLen = 60 / track.bpm;
        while (this._nextTime < ctx.currentTime + 0.15) {
            const t  = this._nextTime;
            // Melody: every beat
            const mi    = this._beat % track.melody.length;
            const mDur  = track.melodyDur  ?? 0.78;
            const mPeak = track.melodyPeak ?? 0.06;
            this._note(midiToHz(track.melody[mi]), track.melodyWave || 'sine', t, beatLen * mDur, mPeak);
            // Bass: every 2 beats
            if (this._beat % 2 === 0) {
                const bi    = (this._beat / 2) % track.bass.length;
                const bPeak = track.bassPeak ?? 0.09;
                this._note(midiToHz(track.bass[bi]), 'sine', t, beatLen * 1.5, bPeak);
            }
            // Percussion (optional — boss track uses this for live drum kit)
            if (track.perc) {
                const pb = this._beat % 8;
                if (track.perc.kick?.includes(pb))  this._percNote(t, 'kick');
                if (track.perc.snare?.includes(pb)) this._percNote(t, 'snare');
            }
            this._beat++;
            this._nextTime += beatLen;
        }
    }

    // ── Internal: procedural ambience layer (per-area soundscape) ─────────────
    // Sparse, randomized events so each area has its own atmosphere:
    // birds (village/meadows), crickets (forest), wind (plains/mountains),
    // water drips (dungeon), fire crackle (interiors).

    _startAmbience(kind) {
        if (!kind) return;
        this._ambId = setInterval(() => this._ambEvent(kind), 700);
    }

    _ambEvent(kind) {
        const ctx = this._ctx;
        if (!ctx || ctx.state !== 'running') return;
        const t = ctx.currentTime + 0.05;
        switch (kind) {
            case 'birds':    if (Math.random() < 0.22) this._ambBird(t);    break;
            case 'crickets': if (Math.random() < 0.30) this._ambCricket(t); break;
            case 'wind':     if (Math.random() < 0.16) this._ambWind(t);    break;
            case 'drips':    if (Math.random() < 0.20) this._ambDrip(t);    break;
            case 'fire':     if (Math.random() < 0.55) this._ambCrackle(t); break;
        }
    }

    _ambNote(freq, type, start, dur, peak, bendTo = null) {
        const ctx  = this._ctx;
        const osc  = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = type;
        osc.frequency.setValueAtTime(freq, start);
        if (bendTo !== null) osc.frequency.linearRampToValueAtTime(bendTo, start + dur);
        gain.gain.setValueAtTime(0, start);
        gain.gain.linearRampToValueAtTime(peak, start + dur * 0.2);
        gain.gain.linearRampToValueAtTime(0, start + dur);
        osc.connect(gain);
        gain.connect(this._master);
        osc.start(start);
        osc.stop(start + dur + 0.05);
    }

    _ambBird(t) {
        // 2-4 quick chirps with upward bends, random base pitch
        const base = 2200 + Math.random() * 1200;
        const n    = 2 + Math.floor(Math.random() * 3);
        for (let i = 0; i < n; i++) {
            const at = t + i * (0.09 + Math.random() * 0.05);
            this._ambNote(base * (0.9 + Math.random() * 0.2), 'sine', at, 0.07, 0.035, base * 1.3);
        }
    }

    _ambCricket(t) {
        // Rapid high trill — several tiny pulses
        const f = 3800 + Math.random() * 600;
        for (let i = 0; i < 6; i++) {
            this._ambNote(f, 'sine', t + i * 0.045, 0.03, 0.018);
        }
    }

    _ambWind(t) {
        // Long filtered-noise gust with slow swell
        const ctx = this._ctx;
        const dur = 1.8 + Math.random() * 1.6;
        const size = Math.ceil(ctx.sampleRate * dur);
        const buf = ctx.createBuffer(1, size, ctx.sampleRate);
        const d = buf.getChannelData(0);
        for (let i = 0; i < size; i++) d[i] = Math.random() * 2 - 1;
        const src  = ctx.createBufferSource();
        src.buffer = buf;
        const filt = ctx.createBiquadFilter();
        filt.type = 'lowpass';
        filt.frequency.setValueAtTime(300, t);
        filt.frequency.linearRampToValueAtTime(550 + Math.random() * 250, t + dur * 0.5);
        filt.frequency.linearRampToValueAtTime(250, t + dur);
        const gain = ctx.createGain();
        gain.gain.setValueAtTime(0, t);
        gain.gain.linearRampToValueAtTime(0.05 + Math.random() * 0.03, t + dur * 0.4);
        gain.gain.linearRampToValueAtTime(0, t + dur);
        src.connect(filt); filt.connect(gain); gain.connect(this._master);
        src.start(t);
    }

    _ambDrip(t) {
        // Water drip: descending plink + faint echo
        const f = 900 + Math.random() * 500;
        this._ambNote(f, 'sine', t, 0.12, 0.045, f * 0.55);
        this._ambNote(f, 'sine', t + 0.28, 0.10, 0.018, f * 0.55);
    }

    _ambCrackle(t) {
        // Fireplace: 1-3 tiny low-passed noise pops
        const ctx = this._ctx;
        const n = 1 + Math.floor(Math.random() * 3);
        for (let i = 0; i < n; i++) {
            const at  = t + i * (0.05 + Math.random() * 0.09);
            const dur = 0.02 + Math.random() * 0.03;
            const size = Math.ceil(ctx.sampleRate * dur);
            const buf = ctx.createBuffer(1, size, ctx.sampleRate);
            const d = buf.getChannelData(0);
            for (let j = 0; j < size; j++) d[j] = (Math.random() * 2 - 1) * (1 - j / size);
            const src  = ctx.createBufferSource();
            src.buffer = buf;
            const filt = ctx.createBiquadFilter();
            filt.type = 'lowpass';
            filt.frequency.value = 900 + Math.random() * 1500;
            const gain = ctx.createGain();
            gain.gain.value = 0.03 + Math.random() * 0.03;
            src.connect(filt); filt.connect(gain); gain.connect(this._master);
            src.start(at);
        }
    }

    // ── Internal: drum hit (kick + snare synthesis) ───────────────────────────

    _percNote(t, type) {
        const ctx = this._ctx;
        if (!ctx) return;
        if (type === 'kick') {
            // Kick drum: sine sweep 150 → 40 Hz with fast attack
            const osc  = ctx.createOscillator();
            const gain = ctx.createGain();
            osc.type = 'sine';
            osc.frequency.setValueAtTime(150, t);
            osc.frequency.exponentialRampToValueAtTime(40, t + 0.12);
            gain.gain.setValueAtTime(0.42, t);
            gain.gain.exponentialRampToValueAtTime(0.001, t + 0.20);
            osc.connect(gain);
            gain.connect(this._master);
            osc.start(t);
            osc.stop(t + 0.22);
        } else {
            // Snare: white noise burst + pitched body
            if (!this._noiseBuffer) {
                const sr = ctx.sampleRate;
                this._noiseBuffer = ctx.createBuffer(1, sr, sr);
                const d = this._noiseBuffer.getChannelData(0);
                for (let i = 0; i < sr; i++) d[i] = Math.random() * 2 - 1;
            }
            const noise = ctx.createBufferSource();
            const nGain = ctx.createGain();
            noise.buffer = this._noiseBuffer;
            nGain.gain.setValueAtTime(0.22, t);
            nGain.gain.exponentialRampToValueAtTime(0.001, t + 0.11);
            noise.connect(nGain);
            nGain.connect(this._master);
            noise.start(t);
            noise.stop(t + 0.13);
            // Snare body tone
            const osc  = ctx.createOscillator();
            const gain = ctx.createGain();
            osc.type = 'triangle';
            osc.frequency.value = 200;
            gain.gain.setValueAtTime(0.11, t);
            gain.gain.exponentialRampToValueAtTime(0.001, t + 0.07);
            osc.connect(gain);
            gain.connect(this._master);
            osc.start(t);
            osc.stop(t + 0.09);
        }
    }
}

export const Music = new MusicEngine();
