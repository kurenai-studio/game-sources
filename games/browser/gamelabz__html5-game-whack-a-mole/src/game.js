(() => {
  'use strict';

  const canvas = document.getElementById('game');
  const ctx = canvas.getContext('2d');
  const scoreEl = document.getElementById('score');
  const bestEl = document.getElementById('best');
  const timeEl = document.getElementById('time');
  const messageEl = document.getElementById('message');
  const startEl = document.getElementById('start');
  const restartEl = document.getElementById('restart');

  const W = canvas.width, H = canvas.height, N = 3, T = W / N;
  const BEST_KEY = 'whack-best';
  const DURATION = 30;

  let holes, score, best, timeLeft, running, timer, spawnTimer, lastSpawn;

  function bestKey() { try { return parseInt(localStorage.getItem(BEST_KEY) || '0', 10) || 0; } catch (e) { return 0; } }

  function newGame() {
    holes = [];
    for (let r = 0; r < N; r++) for (let c = 0; c < N; c++) holes.push({ r, c, state: 'empty', t: 0, life: 0 });
    score = 0; timeLeft = DURATION; running = false;
    scoreEl.textContent = '0'; timeEl.textContent = String(timeLeft);
    best = bestKey(); bestEl.textContent = String(best);
    messageEl.textContent = 'Press Start.';
    draw();
  }

  function start() {
    if (running) return;
    if (timeLeft <= 0) newGame();
    running = true; messageEl.textContent = 'Whack them!';
    lastSpawn = 0; spawnTimer = 0;
    timer = setInterval(() => {
      timeLeft--;
      timeEl.textContent = String(timeLeft);
      if (timeLeft <= 0) end();
    }, 1000);
    requestAnimationFrame(loop);
  }

  function end() {
    running = false; clearInterval(timer); messageEl.textContent = 'Time up!';
    if (score > best) { best = score; bestEl.textContent = String(best); try { localStorage.setItem(BEST_KEY, String(best)); } catch (e) {} }
  }

  function spawn() {
    const empty = holes.filter(h => h.state === 'empty');
    if (!empty.length) return;
    const h = empty[Math.floor(Math.random() * empty.length)];
    h.state = 'up'; h.life = 0.9 + Math.random() * 0.5;
  }

  function cellCenter(h) {
    return { x: h.c * T + T / 2, y: h.r * T + T / 2 };
  }

  function onClick(e) {
    if (!running) return;
    const rect = canvas.getBoundingClientRect();
    const x = (e.clientX - rect.left) * (W / rect.width);
    const y = (e.clientY - rect.top) * (H / rect.height);
    for (const h of holes) {
      if (h.state !== 'up') continue;
      const c = cellCenter(h);
      if (Math.hypot(x - c.x, y - c.y) < T * 0.32) {
        h.state = 'hit'; h.t = 0; score++; scoreEl.textContent = String(score); break;
      }
    }
  }

  function update(dt) {
    spawnTimer += dt;
    if (spawnTimer > 420) { spawnTimer = 0; spawn(); }
    for (const h of holes) {
      if (h.state === 'up') {
        h.life -= dt / 1000;
        if (h.life <= 0) h.state = 'empty';
      } else if (h.state === 'hit') {
        h.t += dt / 1000;
        if (h.t > 0.18) h.state = 'empty';
      }
    }
  }

  function draw() {
    const g = ctx.createLinearGradient(0, 0, W, H);
    g.addColorStop(0, '#15233b'); g.addColorStop(1, '#0f1330');
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
    for (const h of holes) {
      const x = h.c * T, y = h.r * T;
      ctx.fillStyle = 'rgba(0,0,0,0.25)'; ctx.beginPath(); ctx.arc(x + T / 2, y + T / 2, T * 0.36, 0, Math.PI * 2); ctx.fill();
      if (h.state === 'up' || h.state === 'hit') {
        const col = h.state === 'hit' ? '#ffe66d' : '#8d6e63';
        ctx.save(); ctx.shadowBlur = 16; ctx.shadowColor = col; ctx.fillStyle = col;
        ctx.beginPath(); ctx.arc(x + T / 2, y + T / 2, T * 0.3, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#3e2723';
        ctx.beginPath(); ctx.arc(x + T / 2 - 9, y + T / 2 - 4, 4, 0, Math.PI * 2); ctx.arc(x + T / 2 + 9, y + T / 2 - 4, 4, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#ff8a80'; ctx.beginPath(); ctx.arc(x + T / 2, y + T / 2 + 8, 5, 0, Math.PI * 2); ctx.fill();
        ctx.restore();
      }
    }
  }

  let last = 0;
  function loop(ts) {
    const dt = ts - last; last = ts;
    if (running) { update(dt); draw(); requestAnimationFrame(loop); }
    else draw();
  }

  canvas.addEventListener('click', onClick);
  startEl.addEventListener('click', start);
  restartEl.addEventListener('click', () => { clearInterval(timer); newGame(); start(); });
  newGame();
})();
