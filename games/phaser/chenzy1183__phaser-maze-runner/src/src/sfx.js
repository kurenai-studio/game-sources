// 使用 WebAudio 实时合成的 8-bit 音效，无需任何音频素材
const Sfx = (() => {
  let ctx = null;
  let muted = Store.get('muted', false);

  function ensure() {
    if (!ctx) {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (AC) ctx = new AC();
    }
    if (ctx && ctx.state === 'suspended') ctx.resume();
    return ctx;
  }

  function tone(freq, dur = 0.08, type = 'square', vol = 0.05, slideTo = null, delay = 0) {
    if (muted) return;
    const c = ensure();
    if (!c) return;
    const t = c.currentTime + delay;
    const osc = c.createOscillator();
    const gain = c.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, t);
    if (slideTo) osc.frequency.exponentialRampToValueAtTime(slideTo, t + dur);
    gain.gain.setValueAtTime(vol, t);
    gain.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    osc.connect(gain).connect(c.destination);
    osc.start(t);
    osc.stop(t + dur + 0.02);
  }

  return {
    step() {
      tone(240, 0.03, 'triangle', 0.02);
    },
    bump() {
      tone(120, 0.07, 'square', 0.03, 70);
    },
    coin() {
      tone(988, 0.06, 'square', 0.035);
      tone(1319, 0.1, 'square', 0.035, null, 0.06);
    },
    hint() {
      tone(520, 0.18, 'sine', 0.06, 880);
    },
    win() {
      [523, 659, 784, 1047].forEach((f, i) => tone(f, 0.16, 'square', 0.04, null, i * 0.1));
    },
    click() {
      tone(660, 0.05, 'triangle', 0.04);
    },
    unlock() {
      ensure();
    },
    isMuted() {
      return muted;
    },
    toggleMute() {
      muted = !muted;
      Store.set('muted', muted);
      return muted;
    },
  };
})();
