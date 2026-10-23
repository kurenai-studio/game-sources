(() => {
  'use strict';

  const canvas = document.getElementById('game');
  const ctx = canvas.getContext('2d');
  const roundEl = document.getElementById('round');
  const bestEl = document.getElementById('best');
  const messageEl = document.getElementById('message');
  const startBtn = document.getElementById('start');

  const W = canvas.width, H = canvas.height, G = W / 2;
  const PADS = [
    { x: 0, y: 0, color: '#ff5a7a', freq: 329.6 },
    { x: G, y: 0, color: '#ffd166', freq: 261.6 },
    { x: 0, y: G, color: '#4cc9f0', freq: 392.0 },
    { x: G, y: G, color: '#80ed99', freq: 523.2 },
  ];

  let sequence = [], input = 0, state = 'idle', lit = -1;

  let audioCtx = null;
  function beep(freq) {
    try {
      if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      const o = audioCtx.createOscillator();
      const g = audioCtx.createGain();
      o.frequency.value = freq; o.type = 'sine';
      g.gain.value = 0.18;
      o.connect(g); g.connect(audioCtx.destination);
      o.start(); o.stop(audioCtx.currentTime + 0.32);
    } catch (e) { /* audio optional */ }
  }

  function best() { return Number(localStorage.getItem('simon-best') || 0); }
  function loadBest() { bestEl.textContent = String(best()); }

  function draw() {
    ctx.fillStyle = '#0a0c1d';
    ctx.fillRect(0, 0, W, H);
    PADS.forEach((p, i) => {
      ctx.save();
      if (lit === i) { ctx.shadowBlur = 30; ctx.shadowColor = p.color; ctx.fillStyle = p.color; }
      else ctx.fillStyle = shade(p.color, -0.45);
      roundRect(ctx, p.x + 8, p.y + 8, G - 16, G - 16, 18);
      ctx.fill();
      ctx.restore();
    });
    requestAnimationFrame(draw);
  }

  function shade(hex, amt) {
    const n = parseInt(hex.slice(1), 16);
    let r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
    r = Math.max(0, Math.min(255, Math.round(r + r * amt)));
    g = Math.max(0, Math.min(255, Math.round(g + g * amt)));
    b = Math.max(0, Math.min(255, Math.round(b + b * amt)));
    return `rgb(${r},${g},${b})`;
  }

  function roundRect(c, x, y, w, h, r) {
    c.beginPath();
    c.moveTo(x + r, y);
    c.arcTo(x + w, y, x + w, y + h, r);
    c.arcTo(x + w, y + h, x, y + h, r);
    c.arcTo(x, y + h, x, y, r);
    c.arcTo(x, y, x + w, y, r);
    c.closePath();
  }

  function flash(i, cb) {
    lit = i; beep(PADS[i].freq);
    setTimeout(() => { lit = -1; setTimeout(cb, 180); }, 420);
  }

  function showSequence(idx) {
    if (idx >= sequence.length) { state = 'input'; input = 0; messageEl.textContent = 'Your turn!'; return; }
    flash(sequence[idx], () => showSequence(idx + 1));
  }

  function nextRound() {
    sequence.push(Math.floor(Math.random() * 4));
    roundEl.textContent = String(sequence.length);
    state = 'show';
    messageEl.textContent = 'Watch…';
    setTimeout(() => showSequence(0), 600);
  }

  function padFromEvent(e) {
    const rect = canvas.getBoundingClientRect();
    const x = (e.clientX - rect.left) * (W / rect.width);
    const y = (e.clientY - rect.top) * (H / rect.height);
    for (let i = 0; i < 4; i++)
      if (x >= PADS[i].x && x < PADS[i].x + G && y >= PADS[i].y && y < PADS[i].y + G) return i;
    return -1;
  }

  function onClick(e) {
    if (state !== 'input') return;
    const i = padFromEvent(e);
    if (i < 0) return;
    flash(i, () => {
      if (i === sequence[input]) {
        input++;
        if (input === sequence.length) {
          if (sequence.length > best()) { localStorage.setItem('simon-best', String(sequence.length)); loadBest(); }
          nextRound();
        }
      } else {
        state = 'over';
        messageEl.textContent = `Wrong! You reached round ${sequence.length}. Press Start.`;
      }
    });
  }

  startBtn.addEventListener('click', () => {
    sequence = []; input = 0; roundEl.textContent = '0';
    state = 'show'; messageEl.textContent = 'Watch…';
    setTimeout(nextRound, 300);
  });

  canvas.addEventListener('click', onClick);
  loadBest();
  draw();
})();
