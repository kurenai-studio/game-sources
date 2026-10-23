(() => {
  'use strict';

  const canvas = document.getElementById('game');
  const ctx = canvas.getContext('2d');
  const scoreEl = document.getElementById('score');
  const bestEl = document.getElementById('best');
  const messageEl = document.getElementById('message');
  const startEl = document.getElementById('start');
  const restartEl = document.getElementById('restart');

  const W = canvas.width, H = canvas.height, N = 24, T = W / N;
  const BEST_KEY = 'snake-best';

  let snake, dir, nextDir, food, score, best, running, over, acc, step;

  function bestKey() { try { return parseInt(localStorage.getItem(BEST_KEY) || '0', 10) || 0; } catch (e) { return 0; } }

  function newGame() {
    snake = [{ x: 8, y: 12 }, { x: 7, y: 12 }, { x: 6, y: 12 }];
    dir = { x: 1, y: 0 }; nextDir = { x: 1, y: 0 };
    score = 0; running = false; over = false; acc = 0; step = 0;
    best = bestKey(); bestEl.textContent = String(best);
    placeFood();
    messageEl.textContent = 'Press Start.';
    scoreEl.textContent = '0';
    draw();
  }

  function placeFood() {
    while (true) {
      const f = { x: Math.floor(Math.random() * N), y: Math.floor(Math.random() * N) };
      if (!snake.some(s => s.x === f.x && s.y === f.y)) { food = f; return; }
    }
  }

  function start() {
    if (over) newGame();
    if (running) return;
    running = true; messageEl.textContent = 'Go!';
  }

  function setDir(x, y) {
    if (dir.x === -x && dir.y === -y) return;
    nextDir = { x, y };
  }

  function tick() {
    dir = nextDir;
    const head = { x: snake[0].x + dir.x, y: snake[0].y + dir.y };
    if (head.x < 0 || head.x >= N || head.y < 0 || head.y >= N || snake.some(s => s.x === head.x && s.y === head.y)) {
      over = true; running = false;
      messageEl.textContent = 'Game over!';
      if (score > best) { best = score; bestEl.textContent = String(best); try { localStorage.setItem(BEST_KEY, String(best)); } catch (e) {} }
      return;
    }
    snake.unshift(head);
    if (head.x === food.x && head.y === food.y) {
      score += 10; scoreEl.textContent = String(score); placeFood();
    } else snake.pop();
  }

  function draw() {
    const g = ctx.createLinearGradient(0, 0, W, H);
    g.addColorStop(0, '#0f1330'); g.addColorStop(1, '#1a1f47');
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
    for (let r = 0; r < N; r++) for (let c = 0; c < N; c++)
      if ((r + c) % 2) { ctx.fillStyle = 'rgba(255,255,255,0.03)'; ctx.fillRect(c * T, r * T, T, T); }

    ctx.fillStyle = '#80ed99'; ctx.shadowBlur = 12; ctx.shadowColor = '#80ed99';
    ctx.beginPath(); ctx.arc(food.x * T + T / 2, food.y * T + T / 2, T * 0.34, 0, Math.PI * 2); ctx.fill();
    ctx.shadowBlur = 0;

    snake.forEach((s, i) => {
      const t = 1 - i / (snake.length + 4);
      ctx.fillStyle = i === 0 ? '#ffe66d' : `rgba(76,201,240,${0.5 + 0.5 * t})`;
      const pad = 2;
      ctx.beginPath();
      const x = s.x * T + pad, y = s.y * T + pad, w = T - pad * 2, rr = 6;
      ctx.moveTo(x + rr, y); ctx.arcTo(x + w, y, x + w, y + w, rr); ctx.arcTo(x + w, y + w, x, y + w, rr);
      ctx.arcTo(x, y + w, x, y, rr); ctx.arcTo(x, y, x + w, y, rr); ctx.closePath(); ctx.fill();
    });
  }

  let last = 0;
  function loop(ts) {
    const dt = ts - last; last = ts;
    if (running && !over) {
      acc += dt;
      const interval = 110;
      while (acc >= interval) { acc -= interval; tick(); }
      if (over === false) draw();
    } else draw();
    requestAnimationFrame(loop);
  }

  window.addEventListener('keydown', e => {
    const k = e.key.toLowerCase();
    if (k === 'arrowup' || k === 'w') setDir(0, -1);
    else if (k === 'arrowdown' || k === 's') setDir(0, 1);
    else if (k === 'arrowleft' || k === 'a') setDir(-1, 0);
    else if (k === 'arrowright' || k === 'd') setDir(1, 0);
    else return;
    e.preventDefault();
  });

  startEl.addEventListener('click', start);
  restartEl.addEventListener('click', () => { newGame(); start(); });
  newGame();
  requestAnimationFrame(loop);
})();
