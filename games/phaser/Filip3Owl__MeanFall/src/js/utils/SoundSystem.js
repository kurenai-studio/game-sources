import EventBus from './EventBus.js';

class SoundEngine {
    constructor() {
        this._ctx    = null;
        this._master = null;
        this._enabled = localStorage.getItem('meanfall_sound') !== 'off';
        this._vol     = parseFloat(localStorage.getItem('meanfall_vol') || '0.35');
    }

    // ── Init (lazy — requires a prior user gesture) ───────────────────────────
    _init() {
        if (this._ctx) return this._ctx;
        try {
            this._ctx    = new (window.AudioContext || window.webkitAudioContext)();
            this._master = this._ctx.createGain();
            this._master.gain.value          = this._vol;
            this._master.channelCount        = 2;
            this._master.channelCountMode    = 'explicit';
            this._master.channelInterpretation = 'speakers';
            this._master.connect(this._ctx.destination);
        } catch {
            this._enabled = false;
        }
        return this._ctx;
    }

    _play(fn) {
        if (!this._enabled) return;
        const ctx = this._init();
        if (!ctx) return;
        if (ctx.state === 'suspended') ctx.resume();
        try { fn(ctx, this._master); } catch { /* ignore audio errors */ }
    }

    // ── Core helpers ──────────────────────────────────────────────────────────

    // Simple oscillator with attack/decay envelope
    _tone(ctx, dest, freq, type, at, dur, peak = 0.25, bendTo = null) {
        const osc  = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = type;
        osc.frequency.setValueAtTime(freq, at);
        if (bendTo !== null) osc.frequency.linearRampToValueAtTime(bendTo, at + dur);
        gain.gain.setValueAtTime(0, at);
        gain.gain.linearRampToValueAtTime(peak, at + 0.012);
        gain.gain.linearRampToValueAtTime(0, at + dur);
        osc.connect(gain);
        gain.connect(dest);
        osc.start(at);
        osc.stop(at + dur + 0.05);
    }

    // White noise burst (for impacts / hits)
    _noise(ctx, dest, at, dur, cutoff = 800, peak = 0.2) {
        const size = Math.ceil(ctx.sampleRate * dur);
        const buf  = ctx.createBuffer(2, size, ctx.sampleRate); // stereo — evita upmix só no L
        for (let ch = 0; ch < 2; ch++) {
            const data = buf.getChannelData(ch);
            for (let i = 0; i < size; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / size);
        }
        const src  = ctx.createBufferSource();
        src.buffer = buf;
        const filt = ctx.createBiquadFilter();
        filt.type  = 'lowpass';
        filt.frequency.value = cutoff;
        const gain = ctx.createGain();
        gain.gain.value = peak;
        src.connect(filt); filt.connect(gain); gain.connect(dest);
        src.start(at);
    }

    // ── Sound effects ─────────────────────────────────────────────────────────

    correct() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 523, 'square', t,       0.10, 0.18);
            this._tone(ctx, dest, 659, 'square', t + 0.09,0.10, 0.18);
            this._tone(ctx, dest, 784, 'square', t + 0.18,0.18, 0.22);
        });
    }

    wrong() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 220, 'sawtooth', t,        0.14, 0.16);
            this._tone(ctx, dest, 185, 'sawtooth', t + 0.13, 0.18, 0.20);
        });
    }

    critical() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 523,  'square', t,        0.08, 0.25);
            this._tone(ctx, dest, 784,  'square', t + 0.07, 0.08, 0.25);
            this._tone(ctx, dest, 1046, 'square', t + 0.14, 0.12, 0.25);
            this._tone(ctx, dest, 1318, 'sine',   t + 0.20, 0.30, 0.28);
        });
    }

    hit() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 280, 'sawtooth', t, 0.10, 0.22, 160);
            this._noise(ctx, dest, t, 0.08, 600, 0.12);
        });
    }

    damage() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 80, 'sine', t, 0.18, 0.28, 45);
            this._noise(ctx, dest, t, 0.14, 900, 0.18);
        });
    }

    dodge() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 550, 'sine', t, 0.18, 0.14, 950);
        });
    }

    hint() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 880,  'sine', t,        0.22, 0.18);
            this._tone(ctx, dest, 1108, 'sine', t + 0.12, 0.22, 0.18);
            this._tone(ctx, dest, 1320, 'sine', t + 0.24, 0.25, 0.40);
        });
    }

    streak(n) {
        this._play((ctx, dest) => {
            const t    = ctx.currentTime;
            const freq = 380 + Math.min(n, 8) * 70;
            this._tone(ctx, dest, freq,         'square', t,        0.11, 0.18);
            this._tone(ctx, dest, freq * 1.5,   'sine',   t + 0.09, 0.10, 0.14);
        });
    }

    combatStart() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 65,  'sawtooth', t,        0.20, 0.30, 45);
            this._tone(ctx, dest, 440, 'square',   t + 0.12, 0.14, 0.18);
            this._tone(ctx, dest, 880, 'square',   t + 0.22, 0.08, 0.16);
        });
    }

    victory() {
        this._play((ctx, dest) => {
            const t      = ctx.currentTime;
            const notes  = [523, 523, 523, 659, 523, 659, 784];
            const durs   = [0.10, 0.10, 0.10, 0.28, 0.10, 0.10, 0.50];
            let   at     = t;
            notes.forEach((freq, i) => {
                this._tone(ctx, dest, freq, 'square', at, durs[i] * 0.85, 0.20);
                at += durs[i];
            });
        });
    }

    defeat() {
        this._play((ctx, dest) => {
            const t     = ctx.currentTime;
            const notes = [392, 370, 330, 294];
            notes.forEach((freq, i) => {
                this._tone(ctx, dest, freq, 'sawtooth', t + i * 0.28, 0.25, 0.14);
            });
        });
    }

    levelUp() {
        this._play((ctx, dest) => {
            const t     = ctx.currentTime;
            const notes = [261, 329, 392, 523, 659, 784, 1046];
            notes.forEach((freq, i) => {
                this._tone(ctx, dest, freq, 'square', t + i * 0.09, 0.16, 0.20);
            });
        });
    }

    portal() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 180, 'sine', t,        0.80, 0.28, 1400);
            this._tone(ctx, dest, 280, 'sine', t + 0.12, 0.65, 0.16, 1800);
        });
    }

    coins() {
        this._play((ctx, dest) => {
            const t     = ctx.currentTime;
            const notes = [1046, 1318, 1568];
            notes.forEach((freq, i) => {
                this._tone(ctx, dest, freq, 'sine', t + i * 0.07, 0.14, 0.16);
            });
        });
    }

    click() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 1100, 'sine', t, 0.045, 0.07);
        });
    }

    // Hover sobre item de lista — blip curtíssimo e bem suave
    hover() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 680, 'sine', t, 0.028, 0.032);
        });
    }

    // Seleção de item — dois ticks ascendentes, mais afirmativo que click
    select() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 820,  'sine', t,        0.055, 0.045);
            this._tone(ctx, dest, 1080, 'sine', t + 0.04, 0.065, 0.055);
        });
    }

    // Item consumed (potion / consumable)
    useItem() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 220, 'sine', t,        0.28, 0.16, 600); // glug: pitch rises
            this._tone(ctx, dest, 880, 'sine', t + 0.22, 0.10, 0.12);      // sparkle pop
            this._tone(ctx, dest, 1108,'sine', t + 0.28, 0.08, 0.10);
        });
    }

    // Item equipped (weapon / armor clank + confirmation chime)
    equip() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 180, 'sawtooth', t,        0.08, 0.20, 120); // metal clang
            this._noise(ctx, dest, t, 0.07, 1800, 0.10);
            this._tone(ctx, dest, 440, 'sine',     t + 0.06, 0.16, 0.12);      // confirmation
            this._tone(ctx, dest, 660, 'sine',     t + 0.12, 0.14, 0.10);
        });
    }

    // Item unequipped (softer descending version)
    unequip() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 150, 'sawtooth', t,        0.08, 0.14, 90);
            this._noise(ctx, dest, t, 0.05, 800, 0.07);
            this._tone(ctx, dest, 380, 'sine',     t + 0.05, 0.12, 0.10);
        });
    }

    // NPC dialog / interaction (friendly ascending chime)
    interact() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 440, 'sine', t,        0.14, 0.13);
            this._tone(ctx, dest, 550, 'sine', t + 0.09, 0.14, 0.11);
            this._tone(ctx, dest, 660, 'sine', t + 0.17, 0.18, 0.13);
        });
    }

    // Chest opened (wood creak + treasure sparkle)
    chest() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._noise(ctx, dest, t, 0.18, 350, 0.14);                         // creak
            this._tone(ctx, dest, 70, 'sawtooth', t, 0.16, 0.10, 50);           // thud
            [659, 784, 988, 1319].forEach((freq, i) => {                         // sparkle
                this._tone(ctx, dest, freq, 'sine', t + 0.16 + i * 0.07, 0.14, 0.12);
            });
        });
    }

    // Typewriter tick for dialog typing — pitch varies slightly per call
    dialogTick() {
        this._play((ctx, dest) => {
            const freq = 500 + (Math.random() * 80 - 40);
            this._tone(ctx, dest, freq, 'square', ctx.currentTime, 0.018, 0.020);
        });
    }

    // Door opening (creak + mechanical click)
    door() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._noise(ctx, dest, t, 0.22, 250, 0.10);             // creak (wood friction)
            this._tone(ctx, dest, 120, 'sawtooth', t, 0.18, 0.08, 90); // wood body resonance
            this._tone(ctx, dest, 880, 'sine', t + 0.18, 0.06, 0.08);  // latch click
        });
    }

    // Footstep — timbre varies by terrain tile so each area "feels" different.
    // Very short and quiet: it plays on every tile moved.
    step(terrain = 'grass') {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            const alt = (this._stepAlt = !this._stepAlt); // alternate L/R feel
            const v = alt ? 1 : 0.92;
            switch (terrain) {
                case 'stone': // hard click
                    this._noise(ctx, dest, t, 0.045, 2600, 0.055 * v);
                    this._tone(ctx, dest, 190 * v, 'triangle', t, 0.04, 0.05, 120);
                    break;
                case 'sand': // soft shuffle
                    this._noise(ctx, dest, t, 0.09, 900, 0.045 * v);
                    break;
                case 'snow': // muffled crunch
                    this._noise(ctx, dest, t, 0.07, 1600, 0.06 * v);
                    this._noise(ctx, dest, t + 0.025, 0.05, 700, 0.035);
                    break;
                case 'cave': // echoing tap
                    this._noise(ctx, dest, t, 0.04, 1800, 0.05 * v);
                    this._tone(ctx, dest, 150, 'sine', t + 0.05, 0.10, 0.02, 90);
                    break;
                default: // grass — soft thud
                    this._noise(ctx, dest, t, 0.05, 500, 0.05 * v);
                    this._tone(ctx, dest, 110 * v, 'sine', t, 0.045, 0.035, 70);
            }
        });
    }

    // Bumping into a wall/obstacle — dull knock
    bump() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 95, 'triangle', t, 0.07, 0.12, 70);
            this._noise(ctx, dest, t, 0.05, 350, 0.06);
        });
    }

    // Overlay/menu opened — quick upward whoosh
    menuOpen() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 420, 'sine', t, 0.09, 0.09, 660);
            this._tone(ctx, dest, 840, 'sine', t + 0.06, 0.07, 0.06);
        });
    }

    // Overlay/menu closed — mirrored downward whoosh
    menuClose() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 660, 'sine', t, 0.09, 0.08, 420);
            this._tone(ctx, dest, 330, 'sine', t + 0.06, 0.07, 0.05);
        });
    }

    // Action denied (locked portal, not enough gold/focus) — two flat buzzes
    denied() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 160, 'square', t,        0.09, 0.10);
            this._tone(ctx, dest, 140, 'square', t + 0.11, 0.13, 0.12);
        });
    }

    // Quest accepted — short heroic two-note call
    questAccept() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 392, 'triangle', t,        0.14, 0.16);
            this._tone(ctx, dest, 587, 'triangle', t + 0.12, 0.26, 0.18);
        });
    }

    // Quest objective complete — resolved cadence
    questComplete() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 523, 'triangle', t,        0.12, 0.16);
            this._tone(ctx, dest, 659, 'triangle', t + 0.10, 0.12, 0.16);
            this._tone(ctx, dest, 880, 'sine',     t + 0.20, 0.30, 0.20);
        });
    }

    // Achievement unlocked — sparkling fanfare (distinct from levelUp)
    achievement() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 784,  'sine', t,        0.10, 0.14);
            this._tone(ctx, dest, 988,  'sine', t + 0.08, 0.10, 0.14);
            this._tone(ctx, dest, 1175, 'sine', t + 0.16, 0.10, 0.16);
            this._tone(ctx, dest, 1568, 'sine', t + 0.24, 0.34, 0.18);
            this._tone(ctx, dest, 392,  'triangle', t + 0.24, 0.34, 0.10); // low support
        });
    }

    // Manual save — single soft confirmation
    save() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 660, 'sine', t,        0.08, 0.09);
            this._tone(ctx, dest, 990, 'sine', t + 0.07, 0.14, 0.10);
        });
    }

    // Fever mode ignition — rising sweep + shimmer
    fever() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 220, 'sawtooth', t, 0.35, 0.14, 880);
            this._tone(ctx, dest, 1046, 'sine', t + 0.28, 0.12, 0.16);
            this._tone(ctx, dest, 1318, 'sine', t + 0.36, 0.20, 0.18);
        });
    }

    // Monster respawn — reverse "pop-in" blip
    respawn() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 900, 'sine', t, 0.16, 0.07, 300);
            this._tone(ctx, dest, 450, 'triangle', t + 0.12, 0.08, 0.08);
        });
    }

    // Shop purchase — coins + confirmation
    buy() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            [1046, 1318].forEach((f, i) => this._tone(ctx, dest, f, 'sine', t + i * 0.06, 0.10, 0.13));
            this._tone(ctx, dest, 660, 'triangle', t + 0.14, 0.16, 0.12);
        });
    }

    // Shop sale — coins leaving (descending)
    sell() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            [1318, 1046, 784].forEach((f, i) => this._tone(ctx, dest, f, 'sine', t + i * 0.06, 0.10, 0.11));
        });
    }

    // Falling into a hole — descending whoosh ending in a muffled thud
    fall() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._tone(ctx, dest, 700, 'sine', t, 0.55, 0.16, 90);   // descending whistle
            this._noise(ctx, dest, t + 0.05, 0.45, 500, 0.08);       // air rush
            this._tone(ctx, dest, 60, 'sine', t + 0.55, 0.18, 0.28, 40); // thud
            this._noise(ctx, dest, t + 0.55, 0.12, 300, 0.14);
        });
    }

    // Secret passage revealed — low stone rumble + mysterious rising chime
    secret() {
        this._play((ctx, dest) => {
            const t = ctx.currentTime;
            this._noise(ctx, dest, t, 0.5, 200, 0.16);               // stone grinding
            this._tone(ctx, dest, 55, 'sawtooth', t, 0.45, 0.10, 45);
            this._tone(ctx, dest, 523, 'sine', t + 0.35, 0.16, 0.10);
            this._tone(ctx, dest, 740, 'sine', t + 0.48, 0.16, 0.12);
            this._tone(ctx, dest, 988, 'sine', t + 0.62, 0.30, 0.14);
        });
    }

    // ── Settings ──────────────────────────────────────────────────────────────

    toggle() {
        this._enabled = !this._enabled;
        localStorage.setItem('meanfall_sound', this._enabled ? 'on' : 'off');
        return this._enabled;
    }

    setVolume(v) {
        this._vol = Math.max(0, Math.min(1, v));
        localStorage.setItem('meanfall_vol', String(this._vol));
        if (this._master) this._master.gain.value = this._vol;
    }

    get enabled() { return this._enabled; }
}

export const Sound = new SoundEngine();

// ── Wire global game events ────────────────────────────────────────────────
EventBus.on('player-level-up', () => Sound.levelUp());
EventBus.on('combat-end', ({ outcome }) => {
    if (outcome === 'win')  Sound.victory();
    if (outcome === 'loss') Sound.defeat();
});
EventBus.on('quest-accepted',  () => Sound.questAccept());
EventBus.on('quest-complete',  () => Sound.questComplete());
EventBus.on('quest-claimed',   () => Sound.coins());
EventBus.on('bounty-complete', () => Sound.questComplete());
EventBus.on('achievement-unlocked', () => Sound.achievement());
