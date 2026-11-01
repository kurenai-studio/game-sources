import type { Scene, Types } from 'phaser';

export type SoundCue = 'launch' | 'perfectCatch' | 'catch' | 'valuableCatch' | 'chestOpen' | 'collect' | 'throw' | 'explosion' | 'buy' | 'win' | 'lose';

/** Small original arcade sounds. Audio is created only after a player gesture. */
class SoundEffects {
    private context: AudioContext | null = null;
    private master: GainNode | null = null;
    muted = false;

    unlock(): void {
        try {
            if (!this.context) {
                this.context = new AudioContext();
                this.master = this.context.createGain();
                this.master.gain.value = this.muted ? 0 : 0.22;
                this.master.connect(this.context.destination);
            }
            if (this.context.state === 'suspended') void this.context.resume().catch(() => {});
        } catch { /* Gameplay remains usable if browser audio is unavailable. */ }
    }

    toggleMute(): void {
        this.muted = !this.muted;
        if (this.master && this.context) {
            this.master.gain.setValueAtTime(this.muted ? 0 : 0.22, this.context.currentTime);
        }
    }

    play(cue: SoundCue, value = 90): void {
        const context = this.context;
        if (!context || !this.master || this.muted || context.state !== 'running') return;
        const tone = (from: number, to: number, duration: number, delay = 0, type: OscillatorType = 'square', volume = 0.3) => {
            const start = context.currentTime + delay;
            const oscillator = context.createOscillator();
            const gain = context.createGain();
            oscillator.type = type;
            oscillator.frequency.setValueAtTime(from, start);
            oscillator.frequency.exponentialRampToValueAtTime(to, start + duration);
            gain.gain.setValueAtTime(0.001, start);
            gain.gain.linearRampToValueAtTime(volume, start + 0.008);
            gain.gain.exponentialRampToValueAtTime(0.001, start + duration);
            oscillator.connect(gain);
            gain.connect(this.master!);
            oscillator.start(start);
            oscillator.stop(start + duration + 0.01);
            oscillator.onended = () => { oscillator.disconnect(); gain.disconnect(); };
        };
        switch (cue) {
            case 'launch': tone(380, 110, 0.16, 0, 'triangle'); break;
            case 'catch': tone(170, 85, 0.07); break;
            case 'perfectCatch':
                tone(1250, 1800, 0.07, 0, 'triangle', 0.35);
                tone(2093, 2093, 0.16, 0.045, 'sine', 0.25);
                break;
            case 'chestOpen':
                tone(140, 70, 0.12, 0, 'triangle');
                [523, 659, 784].forEach((frequency, i) => tone(frequency, frequency, 0.25, 0.08 + i * 0.065, 'sine'));
                break;
            case 'valuableCatch': {
                const intensity = Math.min(1, Math.max(0, (value - 90) / 660));
                tone(190, 95, 0.065, 0, 'triangle');
                const notes = [659, 880, 1175, 1568].slice(0, 1 + Math.round(intensity * 3));
                notes.forEach((frequency, i) => {
                    tone(frequency, frequency, 0.09 + intensity * 0.23,
                        0.025 + i * 0.055, 'sine', 0.07 + intensity * 0.23);
                });
                break;
            }
            case 'throw': tone(220, 650, 0.15, 0, 'triangle'); break;
            case 'collect':
            case 'buy': tone(740, 740, 0.09); tone(1110, 1110, 0.16, 0.08); break;
            case 'win': [523, 659, 784, 1047].forEach((frequency, i) => tone(frequency, frequency, 0.2, i * 0.12)); break;
            case 'lose': tone(330, 220, 0.2); tone(220, 110, 0.3, 0.2); break;
            case 'explosion': {
                const buffer = context.createBuffer(1, Math.ceil(context.sampleRate * 0.35), context.sampleRate);
                const samples = buffer.getChannelData(0);
                for (let i = 0; i < samples.length; i++) samples[i] = (Math.random() * 2 - 1) * (1 - i / samples.length) ** 2;
                const source = context.createBufferSource();
                const filter = context.createBiquadFilter();
                source.buffer = buffer;
                filter.type = 'lowpass';
                filter.frequency.value = 900;
                source.connect(filter);
                filter.connect(this.master);
                source.start();
                source.onended = () => { source.disconnect(); filter.disconnect(); };
                tone(90, 30, 0.3, 0, 'triangle');
            }
        }
    }
}

export const soundEffects = new SoundEffects();

export function addSoundButton(scene: Scene, x: number, y: number): void {
    const button = scene.add.text(x, y, '', {
        fontFamily: 'Arial', fontSize: 18, color: '#ffffff', backgroundColor: '#70452a',
        padding: { x: 12, y: 8 }
    }).setDepth(20).setInteractive({ useHandCursor: true });
    const refresh = () => button.setText(soundEffects.muted ? 'Sound: OFF' : 'Sound: ON');
    refresh();
    button.on('pointerdown', (_pointer: unknown, _x: number, _y: number, event: Types.Input.EventData) => {
        event.stopPropagation();
        soundEffects.unlock();
        soundEffects.toggleMute();
        refresh();
    });
}
