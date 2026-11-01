/**
 * Web Audio API 8-Bit 晶片合成音效引擎
 * 零外連依賴、毫秒級即時合成、經典街機復古音色
 */
class SoundManager {
  constructor() {
    this.ctx = null;
    this.enabled = true;
    this.masterGain = null;
    this.noiseBuffer = null; // 預載白噪聲快取緩衝區
  }

  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) {
        this.ctx = new AudioCtx();
        this.masterGain = this.ctx.createGain();
        this.masterGain.gain.setValueAtTime(0.3, this.ctx.currentTime);
        this.masterGain.connect(this.ctx.destination);

        // 預先生成 1.0 秒標準白噪聲緩衝區 (零即時記憶體分配)
        const bufferSize = this.ctx.sampleRate * 1.0;
        this.noiseBuffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
        const data = this.noiseBuffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) {
          data[i] = Math.random() * 2 - 1;
        }
      }
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  // 射擊音效 (依武器等級切換音色)
  playShoot(level = 0) {
    if (!this.enabled || !this.ctx) return;
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.connect(gain);
    gain.connect(this.masterGain);

    let duration = 0.08;
    if (level === 0) {
      // 雙針：快速高頻方波
      osc.type = 'square';
      osc.frequency.setValueAtTime(880, t);
      osc.frequency.exponentialRampToValueAtTime(220, t + 0.08);
      gain.gain.setValueAtTime(0.2, t);
      gain.gain.exponentialRampToValueAtTime(0.01, t + 0.08);
    } else if (level === 1) {
      // 散彈：三和弦急速切換
      duration = 0.12;
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(1100, t);
      osc.frequency.exponentialRampToValueAtTime(330, t + 0.12);
      gain.gain.setValueAtTime(0.25, t);
      gain.gain.exponentialRampToValueAtTime(0.01, t + 0.12);
    } else if (level === 2) {
      // 微導彈：上升渦輪嘯叫
      duration = 0.14;
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(300, t);
      osc.frequency.linearRampToValueAtTime(950, t + 0.14);
      gain.gain.setValueAtTime(0.25, t);
      gain.gain.exponentialRampToValueAtTime(0.01, t + 0.14);
    } else {
      // 等離子巨砲：深沉超低音充能突轟
      duration = 0.28;
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(150, t);
      osc.frequency.exponentialRampToValueAtTime(45, t + 0.28);
      gain.gain.setValueAtTime(0.4, t);
      gain.gain.exponentialRampToValueAtTime(0.01, t + 0.28);
    }

    osc.start(t);
    osc.stop(t + duration);
    osc.onended = () => {
      osc.disconnect();
      gain.disconnect();
    };
  }

  // 命中音效
  playHit() {
    if (!this.enabled || !this.ctx) return;
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'square';
    osc.frequency.setValueAtTime(220, t);
    osc.frequency.linearRampToValueAtTime(80, t + 0.04);
    gain.gain.setValueAtTime(0.2, t);
    gain.gain.linearRampToValueAtTime(0.01, t + 0.04);
    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(t);
    osc.stop(t + 0.04);
    osc.onended = () => {
      osc.disconnect();
      gain.disconnect();
    };
  }

  // 爆炸音效 (使用預載白噪聲緩衝區，零 Allocation)
  playExplosion(isBoss = false) {
    if (!this.enabled || !this.ctx || !this.noiseBuffer) return;
    const duration = isBoss ? 0.8 : 0.35;
    const t = this.ctx.currentTime;

    const noise = this.ctx.createBufferSource();
    noise.buffer = this.noiseBuffer;

    const filter = this.ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(isBoss ? 550 : 850, t);
    filter.frequency.exponentialRampToValueAtTime(40, t + duration);

    const gain = this.ctx.createGain();
    gain.gain.setValueAtTime(isBoss ? 0.6 : 0.35, t);
    gain.gain.exponentialRampToValueAtTime(0.01, t + duration);

    noise.connect(filter);
    filter.connect(gain);
    gain.connect(this.masterGain);

    noise.start(t);
    noise.stop(t + duration);
    noise.onended = () => {
      noise.disconnect();
      filter.disconnect();
      gain.disconnect();
    };
  }

  // 武器升級讚揚音效 (8-Bit 階梯和弦)
  playUpgrade() {
    if (!this.enabled || !this.ctx) return;
    const notes = [440, 554, 659, 880, 1108]; // A Major 琶音
    notes.forEach((freq, idx) => {
      const t = this.ctx.currentTime + idx * 0.07;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'square';
      osc.frequency.setValueAtTime(freq, t);
      gain.gain.setValueAtTime(0.25, t);
      gain.gain.exponentialRampToValueAtTime(0.01, t + 0.15);
      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(t);
      osc.stop(t + 0.15);
      osc.onended = () => {
        osc.disconnect();
        gain.disconnect();
      };
    });
  }

  // 花粉必殺核爆
  playBomb() {
    if (!this.enabled || !this.ctx) return;
    this.playExplosion(true);
    // 疊加金屬充能下墜感
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(900, t);
    osc.frequency.exponentialRampToValueAtTime(30, t + 1.2);
    gain.gain.setValueAtTime(0.4, t);
    gain.gain.exponentialRampToValueAtTime(0.01, t + 1.2);
    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(t);
    osc.stop(t + 1.2);
    osc.onended = () => {
      osc.disconnect();
      gain.disconnect();
    };
  }

  // 蜂鷹天敵長嘯 (Oriental Honey Buzzard Cry)
  playEagleCall() {
    if (!this.enabled || !this.ctx) return;
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sawtooth';
    // 鷹嘯高頻下滑帶顫音
    osc.frequency.setValueAtTime(1200, t);
    osc.frequency.linearRampToValueAtTime(2400, t + 0.15);
    osc.frequency.exponentialRampToValueAtTime(600, t + 0.9);
    gain.gain.setValueAtTime(0.35, t);
    gain.gain.exponentialRampToValueAtTime(0.01, t + 0.9);
    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(t);
    osc.stop(t + 0.9);
    osc.onended = () => {
      osc.disconnect();
      gain.disconnect();
    };
  }

  // 拾取特級蜂露回復音效
  playHeal() {
    if (!this.enabled || !this.ctx) return;
    const notes = [523, 659, 784, 1046]; // C-E-G-C 上揚吉利和弦
    notes.forEach((freq, idx) => {
      const t = this.ctx.currentTime + idx * 0.05;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, t);
      gain.gain.setValueAtTime(0.3, t);
      gain.gain.exponentialRampToValueAtTime(0.01, t + 0.12);
      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(t);
      osc.stop(t + 0.12);
      osc.onended = () => {
        osc.disconnect();
        gain.disconnect();
      };
    });
  }
}

export const soundManager = new SoundManager();
