type AudioWindow = Window & typeof globalThis & { webkitAudioContext?: typeof AudioContext };

class ProceduralAudio {
  private context: AudioContext | null = null;
  private enabled = true;
  private master: GainNode | null = null;

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
    if (this.master) this.master.gain.value = enabled ? 0.15 : 0;
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  async unlock(): Promise<void> {
    if (!this.context) {
      const Context = window.AudioContext ?? (window as AudioWindow).webkitAudioContext;
      if (!Context) return;
      this.context = new Context();
      this.master = this.context.createGain();
      this.master.gain.value = this.enabled ? 0.15 : 0;
      this.master.connect(this.context.destination);
    }
    if (this.context.state === 'suspended') await this.context.resume();
  }

  private tone(frequency: number, duration: number, type: OscillatorType, detune = 0, volume = 0.24): void {
    if (!this.enabled || !this.context || !this.master) return;
    const now = this.context.currentTime;
    const oscillator = this.context.createOscillator();
    const gain = this.context.createGain();
    oscillator.type = type;
    oscillator.frequency.setValueAtTime(frequency, now);
    oscillator.detune.setValueAtTime(detune, now);
    gain.gain.setValueAtTime(volume, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + duration);
    oscillator.connect(gain);
    gain.connect(this.master);
    oscillator.start(now);
    oscillator.stop(now + duration);
  }

  shot(): void {
    this.tone(520, 0.07, 'sine', -180, 0.16);
  }

  enemyShot(): void {
    this.tone(145, 0.13, 'triangle', 0, 0.13);
  }

  hit(): void {
    this.tone(92, 0.055, 'square', 0, 0.11);
  }

  hurt(): void {
    this.tone(74, 0.22, 'sawtooth', -100, 0.24);
  }

  door(): void {
    this.tone(116, 0.32, 'triangle', -300, 0.2);
  }

  item(): void {
    this.tone(420, 0.35, 'sine', 0, 0.18);
    window.setTimeout(() => this.tone(630, 0.3, 'sine', 0, 0.15), 75);
  }

  bell(): void {
    this.tone(196, 1.4, 'sine', 0, 0.26);
    this.tone(494, 0.9, 'sine', 4, 0.12);
    this.tone(1_046, 0.45, 'triangle', -6, 0.05);
  }

  bellDenied(): void {
    this.tone(150, 0.09, 'square', 0, 0.08);
  }

  boss(): void {
    this.tone(52, 0.75, 'sawtooth', -220, 0.26);
  }

  victory(): void {
    [0, 95, 205].forEach((delay, index) => {
      window.setTimeout(() => this.tone(220 * (1 + index * 0.25), 0.5, 'sine', 0, 0.18), delay);
    });
  }
}

export const audio = new ProceduralAudio();
