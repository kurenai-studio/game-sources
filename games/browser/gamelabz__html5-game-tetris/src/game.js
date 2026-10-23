(() => {
  'use strict';

  const canvas = document.getElementById('game');
  const ctx = canvas.getContext('2d');
  const scoreEl = document.getElementById('score');
  const linesEl = document.getElementById('lines');
  const bestEl = document.getElementById('best');
  const messageEl = document.getElementById('message');
  const startEl = document.getElementById('start');
  const restartEl = document.getElementById('restart');

  const W = canvas.width, H = canvas.height, COLS = 10, ROWS = 20, T = W / COLS;
  const BEST_KEY = 'tetris-best';

  const SHAPES = {
    I: [[0,0,0,0],[1,1,1,1],[0,0,0,0],[0,0,0,0]],
    O: [[1,1],[1,1]],
    T: [[0,1,0],[1,1,1],[0,0,0]],
    S: [[0,1,1],[1,1,0],[0,0,0]],
    Z: [[1,1,0],[0,1,1],[0,0,0]],
    J: [[1,0,0],[1,1,1],[0,0,0]],
    L: [[0,0,1],[1,1,1],[0,0,0]],
  };
  const COLORS = { I:'#4cc9f0', O:'#ffe66d', T:'#b388ff', S:'#80ed99', Z:'#ff5e7e', J:'#5e9bff', L:'#ff9e5e' };

  let board, piece, next, score, lines, best, running, over, acc, dropInterval;

  function bestKey() { try { return parseInt(localStorage.getItem(BEST_KEY) || '0', 10) || 0; } catch (e) { return 0; } }

  function newBoard() {
    const b = [];
    for (let r = 0; r < ROWS; r++) b.push(new Array(COLS).fill(0));
    return b;
  }

  function rotate(m) {
    const n = m.length, res = [];
    for (let c = 0; c < n; c++) { res.push([]); for (let r = n - 1; r >= 0; r--) res[c].push(m[r][c]); }
    return res;
  }

  function spawn() {
    const keys = Object.keys(SHAPES);
    const type = next || keys[Math.floor(Math.random() * keys.length)];
    next = keys[Math.floor(Math.random() * keys.length)];
    const shape = SHAPES[type].map(r => r.slice());
    piece = { type, shape, x: Math.floor((COLS - shape[0].length) / 2), y: 0, color: COLORS[type] };
    if (collides(piece.shape, piece.x, piece.y)) { over = true; running = false; messageEl.textContent = 'Game over!'; saveBest(); }
  }

  function collides(shape, x, y) {
    for (let r = 0; r < shape.length; r++) for (let c = 0; c < shape[r].length; c++) {
      if (!shape[r][c]) continue;
      const nx = x + c, ny = y + r;
      if (nx < 0 || nx >= COLS || ny >= ROWS) return true;
      if (ny >= 0 && board[ny][nx]) return true;
    }
    return false;
  }

  function merge() {
    for (let r = 0; r < piece.shape.length; r++) for (let c = 0; c < piece.shape[r].length; c++)
      if (piece.shape[r][c]) { const ny = piece.y + r, nx = piece.x + c; if (ny >= 0) board[ny][nx] = piece.color; }
  }

  function clearLines() {
    let cleared = 0;
    for (let r = ROWS - 1; r >= 0; r--) {
      if (board[r].every(v => v)) { board.splice(r, 1); board.unshift(new Array(COLS).fill(0)); cleared++; r++; }
    }
    if (cleared) { lines += cleared; score += [0,100,300,500,800][cleared] || 800; linesEl.textContent = String(lines); scoreEl.textContent = String(score); }
  }

  function step() {
    if (!collides(piece.shape, piece.x, piece.y + 1)) piece.y++;
    else { merge(); clearLines(); spawn(); }
  }

  function move(dx) { if (!collides(piece.shape, piece.x + dx, piece.y)) piece.x += dx; }
  function softDrop() { if (!collides(piece.shape, piece.x, piece.y + 1)) { piece.y++; score += 1; scoreEl.textContent = String(score); } else step(); }

  function rotatePiece() {
    const r = rotate(piece.shape);
    for (const k of [0, -1, 1, -2, 2]) if (!collides(r, piece.x + k, piece.y)) { piece.shape = r; piece.x += k; return; }
  }

  function saveBest() { if (score > best) { best = score; bestEl.textContent = String(best); try { localStorage.setItem(BEST_KEY, String(best)); } catch (e) {} } }

  function newGame() {
    board = newBoard(); score = 0; lines = 0; running = false; over = false; acc = 0; dropInterval = 600;
    best = bestKey(); bestEl.textContent = String(best); scoreEl.textContent = '0'; linesEl.textContent = '0';
    next = null; spawn(); messageEl.textContent = 'Press Start.'; draw();
  }

  function start() { if (over) newGame(); if (!running) { running = true; messageEl.textContent = 'Go!'; } }

  function drawCell(x, y, color) {
    ctx.fillStyle = color; ctx.shadowBlur = 8; ctx.shadowColor = color;
    ctx.beginPath();
    const px = x * T, py = y * T, pad = 2, w = T - pad * 2, rr = 5;
    ctx.moveTo(px + pad + rr, py + pad); ctx.arcTo(px + pad + w, py + pad, px + pad + w, py + pad + w, rr);
    ctx.arcTo(px + pad + w, py + pad + w, px + pad, py + pad + w, rr); ctx.arcTo(px + pad, py + pad + w, px + pad, py + pad, rr);
    ctx.arcTo(px + pad, py + pad, px + pad + w, py + pad, rr); ctx.closePath(); ctx.fill();
    ctx.shadowBlur = 0;
  }

  function draw() {
    const g = ctx.createLinearGradient(0, 0, W, H);
    g.addColorStop(0, '#0f1330'); g.addColorStop(1, '#1a1f47');
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
    ctx.strokeStyle = 'rgba(255,255,255,0.04)';
    for (let r = 0; r <= ROWS; r++) { ctx.beginPath(); ctx.moveTo(0, r * T); ctx.lineTo(W, r * T); ctx.stroke(); }
    for (let c = 0; c <= COLS; c++) { ctx.beginPath(); ctx.moveTo(c * T, 0); ctx.lineTo(c * T, H); ctx.stroke(); }

    for (let r = 0; r < ROWS; r++) for (let c = 0; c < COLS; c++) if (board[r][c]) drawCell(c, r, board[r][c]);

    if (piece) for (let r = 0; r < piece.shape.length; r++) for (let c = 0; c < piece.shape[r].length; c++)
      if (piece.shape[r][c]) drawCell(piece.x + c, piece.y + r, piece.color);
  }

  let last = 0;
  function loop(ts) {
    const dt = ts - last; last = ts;
    if (running && !over) {
      acc += dt;
      while (acc >= dropInterval) { acc -= dropInterval; step(); if (over) break; }
      draw();
    } else draw();
    requestAnimationFrame(loop);
  }

  window.addEventListener('keydown', e => {
    if (!running || over) return;
    const k = e.key.toLowerCase();
    if (k === 'arrowleft') move(-1);
    else if (k === 'arrowright') move(1);
    else if (k === 'arrowdown') softDrop();
    else if (k === 'arrowup') rotatePiece();
    else return;
    e.preventDefault(); draw();
  });

  startEl.addEventListener('click', start);
  restartEl.addEventListener('click', () => { newGame(); start(); });
  newGame();
  requestAnimationFrame(loop);
})();
