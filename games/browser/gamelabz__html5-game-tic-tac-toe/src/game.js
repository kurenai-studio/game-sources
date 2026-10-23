(() => {
  'use strict';

  const canvas = document.getElementById('game');
  const ctx = canvas.getContext('2d');
  const youEl = document.getElementById('you');
  const aiEl = document.getElementById('ai');
  const drawsEl = document.getElementById('draws');
  const messageEl = document.getElementById('message');
  const restartEl = document.getElementById('restart');

  const W = canvas.width, H = canvas.height, N = 3, T = W / N;
  // board: 0 empty, 1 you (X), 2 ai (O)
  let board, turn, winner, winLine, over, youScore, aiScore, draws;

  function newGame() {
    board = new Array(9).fill(0);
    turn = 1; winner = 0; winLine = null; over = false;
    messageEl.textContent = 'Your move — click a square.';
    draw();
  }

  function loadScores() {
    youScore = 0; aiScore = 0; draws = 0;
  }

  function winCombos() {
    const c = [];
    for (let i = 0; i < 3; i++) { c.push([i * 3, i * 3 + 1, i * 3 + 2]); c.push([i, i + 3, i + 6]); }
    c.push([0, 4, 8]); c.push([2, 4, 6]);
    return c;
  }

  function checkWin(b) {
    for (const [a, bb, c] of winCombos()) if (b[a] && b[a] === b[bb] && b[a] === b[c]) return { p: b[a], line: [a, bb, c] };
    if (b.every(v => v)) return { p: 0, line: null };
    return null;
  }

  function cellFromEvent(e) {
    const rect = canvas.getBoundingClientRect();
    const x = (e.clientX - rect.left) * (W / rect.width);
    const y = (e.clientY - rect.top) * (H / rect.height);
    const c = Math.floor(x / T), r = Math.floor(y / T);
    if (r < 0 || r > 2 || c < 0 || c > 2) return -1;
    return r * 3 + c;
  }

  function onClick(e) {
    if (over || turn !== 1) return;
    const i = cellFromEvent(e);
    if (i < 0 || board[i]) return;
    board[i] = 1;
    resolve();
  }

  function resolve() {
    const res = checkWin(board);
    if (res) { finish(res); return; }
    turn = 2;
    setTimeout(aiMove, 320);
  }

  function finish(res) {
    over = true; winner = res.p; winLine = res.line;
    if (res.p === 1) { youScore++; youEl.textContent = String(youScore); messageEl.textContent = 'You win! 🎉'; }
    else if (res.p === 2) { aiScore++; aiEl.textContent = String(aiScore); messageEl.textContent = 'AI wins!'; }
    else { draws++; drawsEl.textContent = String(draws); messageEl.textContent = 'Draw!'; }
    draw();
  }

  function aiMove() {
    if (over) return;
    const best = minimax(board, 2);
    board[best.index] = 2;
    const res = checkWin(board);
    if (res) { finish(res); return; }
    turn = 1; messageEl.textContent = 'Your move.'; draw();
  }

  function minimax(b, player) {
    const res = checkWin(b);
    if (res) { const s = res.p === 2 ? 10 : res.p === 1 ? -10 : 0; return { score: s }; }
    const avail = [];
    for (let i = 0; i < 9; i++) if (!b[i]) avail.push(i);
    let bestMove;
    if (player === 2) {
      let bestScore = -Infinity;
      for (const i of avail) {
        b[i] = 2; const s = minimax(b, 1).score - avail.length * 0; b[i] = 0;
        const sc = s - (9 - avail.length) * 0.1;
        if (sc > bestScore) { bestScore = sc; bestMove = i; }
      }
      return { score: bestScore, index: bestMove };
    } else {
      let bestScore = Infinity;
      for (const i of avail) {
        b[i] = 1; const sc = minimax(b, 2).score; b[i] = 0;
        if (sc < bestScore) { bestScore = sc; bestMove = i; }
      }
      return { score: bestScore, index: bestMove };
    }
  }

  function draw() {
    const g = ctx.createLinearGradient(0, 0, W, H);
    g.addColorStop(0, '#15233b'); g.addColorStop(1, '#0f1330');
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);

    ctx.strokeStyle = 'rgba(255,255,255,0.18)'; ctx.lineWidth = 4;
    for (let i = 1; i < 3; i++) {
      ctx.beginPath(); ctx.moveTo(i * T, 16); ctx.lineTo(i * T, H - 16); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(16, i * T); ctx.lineTo(W - 16, i * T); ctx.stroke();
    }

    if (winLine) {
      const [a, , c] = winLine;
      const ax = (a % 3) * T + T / 2, ay = Math.floor(a / 3) * T + T / 2;
      const cx = (c % 3) * T + T / 2, cy = Math.floor(c / 3) * T + T / 2;
      ctx.strokeStyle = 'rgba(128,237,153,0.7)'; ctx.lineWidth = 6; ctx.beginPath();
      ctx.moveTo(ax, ay); ctx.lineTo(cx, cy); ctx.stroke();
    }

    for (let i = 0; i < 9; i++) {
      if (!board[i]) continue;
      const x = (i % 3) * T, y = Math.floor(i / 3) * T, cx = x + T / 2, cy = y + T / 2;
      if (board[i] === 1) {
        ctx.strokeStyle = '#80ed99'; ctx.lineWidth = 7; ctx.lineCap = 'round';
        ctx.beginPath(); ctx.moveTo(cx - 30, cy - 30); ctx.lineTo(cx + 30, cy + 30);
        ctx.moveTo(cx + 30, cy - 30); ctx.lineTo(cx - 30, cy + 30); ctx.stroke();
      } else {
        ctx.strokeStyle = '#ff5e7e'; ctx.lineWidth = 7;
        ctx.beginPath(); ctx.arc(cx, cy, 30, 0, Math.PI * 2); ctx.stroke();
      }
    }
  }

  restartEl.addEventListener('click', newGame);
  loadScores();
  newGame();
})();
