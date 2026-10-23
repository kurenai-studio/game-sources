// 音效引擎：Web Audio 合成，零素材。M 键静音；音量与背景音乐开关在暂停菜单调节（存 localStorage）。
// BGM 为四和弦慢速铺底（约 4.2 秒一切、极慢进出包络），固定低增益，切到后台自动静音。
let ctx = null;
let muted = false;
let volume = 1;
try {
  const saved = parseFloat(localStorage.getItem('abyss-vol'));
  if (!isNaN(saved)) volume = Math.max(0, Math.min(1, saved));
} catch (e) { }
const last = {};

const CHORDS = [
  [110.00, 164.81, 220.00],   // Am
  [87.31, 130.81, 174.61],    // F
  [130.81, 196.00, 261.63],   // C
  [98.00, 146.83, 196.00]     // G
];
const CHORD_MS = 4200;
const MUSIC_GAIN = 0.03;
let musicOn = true;
try { musicOn = localStorage.getItem('abyss-music') !== '0'; } catch (e) { }
let musicTimer = null;
let chordIdx = 0;

function ac() {
  if (!ctx) {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    ctx = new AC();
  }
  if (ctx.state === 'suspended') {
    const r = ctx.resume();
    if (r && r.catch) r.catch(() => { });
  }
  return ctx;
}

function tone(freq, dur, type = 'square', vol = 0.08, slideTo = 0, delay = 0) {
  const c = ac();
  if (!c || muted || volume <= 0) return;
  const o = c.createOscillator();
  const g = c.createGain();
  const t = c.currentTime + delay;
  o.type = type;
  o.frequency.setValueAtTime(Math.max(30, freq), t);
  if (slideTo) o.frequency.exponentialRampToValueAtTime(Math.max(30, slideTo), t + dur);
  g.gain.setValueAtTime(vol * volume, t);
  g.gain.exponentialRampToValueAtTime(0.001, t + dur);
  o.connect(g); g.connect(c.destination);
  o.start(t); o.stop(t + dur + 0.02);
}

function throttle(key, ms) {
  const now = performance.now();
  if ((last[key] || 0) + ms > now) return false;
  last[key] = now;
  return true;
}

function playChord() {
  const c = ac();
  if (!c || !musicOn || muted || volume <= 0) return;
  // 后台标签的 ctx 时钟会冻结，此时定时器被节流后补排的多个和弦会在切回时齐响
  if (document.hidden || c.state !== 'running') return;
  const notes = CHORDS[chordIdx % CHORDS.length];
  chordIdx++;
  const t = c.currentTime;
  const dur = CHORD_MS / 1000;
  for (const f of notes) {
    const o = c.createOscillator();
    const g = c.createGain();
    o.type = 'triangle';
    o.frequency.setValueAtTime(f, t);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(MUSIC_GAIN * volume, t + 1.5);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(g); g.connect(c.destination);
    o.start(t); o.stop(t + dur + 0.05);
  }
}

function startMusic() {
  if (musicTimer || !musicOn) return;
  if (!ac()) return;
  playChord();
  musicTimer = window.setInterval(playChord, CHORD_MS);
}

function stopMusic() {
  if (musicTimer) { window.clearInterval(musicTimer); musicTimer = null; }
}

document.addEventListener('visibilitychange', () => {
  if (!ctx) return;
  try {
    if (document.hidden) {
      const s = ctx.suspend();
      if (s && s.catch) s.catch(() => { });
    } else {
      const r = ctx.resume();
      if (r && r.catch) r.catch(() => { });
    }
  } catch (e) { /* 忽略不支持 suspend 的环境 */ }
});

export default {
  toggle() { muted = !muted; if (!muted) ac(); return muted; },
  get muted() { return muted; },
  getVolume() { return volume; },
  setVolume(v) {
    volume = Math.max(0, Math.min(1, v));
    try { localStorage.setItem('abyss-vol', String(volume)); } catch (e) { }
  },
  get musicEnabled() { return musicOn; },
  startMusic,
  stopMusic,
  toggleMusic() {
    musicOn = !musicOn;
    try { localStorage.setItem('abyss-music', musicOn ? '1' : '0'); } catch (e) { }
    if (musicOn) startMusic(); else stopMusic();
    return musicOn;
  },
  unlock() { ac(); startMusic(); }, // 在用户点击后调用以解除自动播放限制
  revive() { [523, 784].forEach((f, i) => tone(f, 0.14, 'sine', 0.08, 0, i * 0.1)); },
  shoot() { if (throttle('shoot', 70)) tone(500, 0.05, 'square', 0.045, 300); },
  hit() { if (throttle('hit', 90)) tone(190, 0.05, 'sawtooth', 0.05); },
  crit() { if (throttle('crit', 90)) { tone(650, 0.08, 'sawtooth', 0.08, 980); tone(1200, 0.06, 'triangle', 0.06, 0, 0.02); } },
  kill() { if (throttle('kill', 60)) tone(160, 0.1, 'triangle', 0.09, 70); },
  gem() { if (throttle('gem', 70)) tone(900, 0.07, 'sine', 0.06, 1400); },
  coin() { if (throttle('coin', 90)) { tone(1150, 0.05, 'square', 0.055); tone(1550, 0.06, 'square', 0.045, 0, 0.06); } },
  heal() { tone(700, 0.12, 'sine', 0.07, 1000); },
  hurt() { if (throttle('hurt', 150)) tone(120, 0.16, 'sawtooth', 0.1, 60); },
  whoosh() { if (throttle('whoosh', 200)) tone(1500, 0.1, 'sine', 0.05, 380); },
  levelup() { [523, 659, 784, 1046].forEach((f, i) => tone(f, 0.12, 'square', 0.06, 0, i * 0.09)); },
  evolve() { [440, 554, 659, 880, 1108].forEach((f, i) => tone(f, 0.15, 'triangle', 0.07, 0, i * 0.08)); },
  boss() { tone(90, 0.5, 'sawtooth', 0.13, 45); tone(60, 0.6, 'square', 0.09, 40, 0.1); },
  slam() { if (throttle('slam', 200)) tone(70, 0.2, 'sawtooth', 0.11, 35); },
  reroll() { tone(400, 0.09, 'square', 0.055, 800); },
  click() { tone(600, 0.04, 'square', 0.045); },
  heartbeat() { if (throttle('heartbeat', 650)) { tone(65, 0.12, 'sine', 0.10, 45); tone(55, 0.10, 'sine', 0.08, 40, 0.18); } },
  achievement() { [784, 988, 1175].forEach((f, i) => tone(f, 0.1, 'square', 0.06, 0, i * 0.07)); }
};
