export default class AudioManager {
  constructor(scene) {
    this.scene = scene;
    this.enabled = true;
    this.sounds = {};
  }

  init() {
    // Generate procedural sounds using Web Audio API
    this.generateSounds();
  }

  generateSounds() {
    try {
      const ctx = this.scene.sound.context;
      if (!ctx) return;

      // Sounds will be generated on-demand via oscillators
      this.audioContext = ctx;
    } catch {
      // Audio not available
      this.enabled = false;
    }
  }

  playFire() {
    if (!this.enabled || !this.audioContext) return;
    this.playTone(200, 0.15, 'sawtooth', 0.3);
  }

  playExplosion() {
    if (!this.enabled || !this.audioContext) return;
    this.playNoise(0.3, 0.4);
  }

  playWhistle() {
    if (!this.enabled || !this.audioContext) return;
    this.playTone(800, 0.5, 'sine', 0.1, 400);
  }

  playCollect() {
    if (!this.enabled || !this.audioContext) return;
    this.playTone(600, 0.1, 'sine', 0.2);
    setTimeout(() => this.playTone(800, 0.1, 'sine', 0.2), 100);
  }

  playSplash() {
    if (!this.enabled || !this.audioContext) return;
    this.playNoise(0.2, 0.2);
  }

  playTone(freq, duration, type = 'sine', volume = 0.3, endFreq = null) {
    try {
      const ctx = this.audioContext;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = type;
      osc.frequency.setValueAtTime(freq, ctx.currentTime);
      if (endFreq) {
        osc.frequency.linearRampToValueAtTime(endFreq, ctx.currentTime + duration);
      }

      gain.gain.setValueAtTime(volume, ctx.currentTime);
      gain.gain.linearRampToValueAtTime(0, ctx.currentTime + duration);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(ctx.currentTime);
      osc.stop(ctx.currentTime + duration);
    } catch {
      // Ignore audio errors
    }
  }

  playNoise(duration, volume = 0.3) {
    try {
      const ctx = this.audioContext;
      const bufferSize = ctx.sampleRate * duration;
      const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
      const data = buffer.getChannelData(0);

      for (let i = 0; i < bufferSize; i++) {
        data[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / bufferSize, 2);
      }

      const source = ctx.createBufferSource();
      source.buffer = buffer;

      const gain = ctx.createGain();
      gain.gain.setValueAtTime(volume, ctx.currentTime);
      gain.gain.linearRampToValueAtTime(0, ctx.currentTime + duration);

      source.connect(gain);
      gain.connect(ctx.destination);
      source.start(ctx.currentTime);
    } catch {
      // Ignore audio errors
    }
  }

  toggle() {
    this.enabled = !this.enabled;
    return this.enabled;
  }
}
