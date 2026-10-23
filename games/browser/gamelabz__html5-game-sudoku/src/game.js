(() => {
  'use strict';

  const canvas = document.getElementById('game');
  const ctx = canvas.getContext('2d');
  const timeEl = document.getElementById('time');
  const bestEl = document.getElementById('best');
  const levelEl = document.getElementById('level');
  const messageEl = document.getElementById('message');

  const W = 540, H = 540, N = 9, CELL = W / N;
  const BEST_KEY = 'sudoku-best-time';

  let solution = [];
  let grid = [];
  let given = [];
  let selected = { r: 4, c: 4 };
  let difficulty = 'easy';
  let startTime = 0;
  let elapsed = 0;
  let running = false;
  let won = false;
  const HOLES = { easy: 40, medium: 50, hard: 58 };

  function shuffle(a) {
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

  function emptyGrid() {
    return Array.from({ length: N }, () => Array(N).fill(0));
  }

  function valid(g, r, c, v) {
    for (let i = 0; i < N; i++) {
      if (g[r][i] === v) return false;
      if (g[i][c] === v) return false;
    }
    const br = Math.floor(r / 3) * 3, bc = Math.floor(c / 3) * 3;
    for (let i = 0; i < 3; i++)
      for (let j = 0; j < 3; j++)
        if (g[br + i][bc + j] === v) return false;
    return true;
  }

  function generateSolved() {
    const g = emptyGrid();
    function fill(pos) {
      if (pos === N * N) return true;
      const r = Math.floor(pos / N), c = pos % N;
      const candidates = shuffle([1, 2, 3, 4, 5, 6, 7, 8, 9]);
      for (const v of candidates) {
        if (valid(g, r, c, v)) {
          g[r][c] = v;
          if (fill(pos + 1)) return true;
          g[r][c] = 0;
        }
      }
      return false;
    }
    fill(0);
    return g;
  }

  function countSolutions(g, limit) {
    let count = 0;
    const board = g.map(row => row.slice());
    function solve(pos) {
      if (count >= limit) return;
      if (pos === N * N) { count++; return; }
      const r = Math.floor(pos / N), c = pos % N;
      if (board[r][c] !== 0) { solve(pos + 1); return; }
      for (let v = 1; v <= 9; v++) {
        if (valid(board, r, c, v)) {
          board[r][c] = v;
          solve(pos + 1);
          board[r][c] = 0;
          if (count >= limit) return;
        }
      }
    }
    solve(0);
    return count;
  }

  function makePuzzle(holes) {
    const full = generateSolved();
    solution = full.map(row => row.slice());
    grid = full.map(row => row.slice());
    given = Array.from({ length: N }, () => Array(N).fill(true));
    const cells = shuffle(Array.from({ length: N * N }, (_, i) => i));
    let removed = 0;
    for (const idx of cells) {
      if (removed >= holes) break;
      const r = Math.floor(idx / N), c = idx % N;
      if (!given[r][c]) continue;
      const backup = grid[r][c];
      grid[r][c] = 0;
      given[r][c] = false;
      const before = countSolutions(grid, 2);
      if (before !== 1) {
        grid[r][c] = backup;
        given[r][c] = true;
      } else {
        removed++;
      }
    }
  }

  function hasConflict(r, c, v) {
    if (v === 0) return false;
    for (let i = 0; i < N; i++) {
      if (i !== c && grid[r][i] === v) return true;
      if (i !== r && grid[i][c] === v) return true;
    }
    const br = Math.floor(r / 3) * 3, bc = Math.floor(c / 3) * 3;
    for (let i = 0; i < 3; i++)
      for (let j = 0; j < 3; j++) {
        const rr = br + i, cc = bc + j;
        if ((rr !== r || cc !== c) && grid[rr][cc] === v) return true;
      }
    return false;
  }

  function isComplete() {
    for (let r = 0; r < N; r++)
      for (let c = 0; c < N; c++)
        if (grid[r][c] !== solution[r][c]) return false;
    return true;
  }

  function fmtTime(s) {
    const m = Math.floor(s / 60);
    const sec = s % 60;
    return `${m}:${String(sec).padStart(2, '0')}`;
  }

  function bestKey() { return `${BEST_KEY}-${difficulty}`; }

  function loadBest() {
    const v = localStorage.getItem(bestKey());
    bestEl.textContent = v ? fmtTime(Number(v)) : '—';
  }

  function newGame(diff) {
    if (diff) difficulty = diff;
    levelEl.textContent = difficulty.charAt(0).toUpperCase() + difficulty.slice(1);
    makePuzzle(HOLES[difficulty]);
    selected = { r: 4, c: 4 };
    startTime = Date.now();
    elapsed = 0;
    running = true;
    won = false;
    messageEl.textContent = 'Fill every cell — each row, column and box needs 1-9.';
    loadBest();
  }

  function cellFromEvent(e) {
    const rect = canvas.getBoundingClientRect();
    const x = (e.clientX - rect.left) * (W / rect.width);
    const y = (e.clientY - rect.top) * (H / rect.height);
    const c = Math.floor(x / CELL);
    const r = Math.floor(y / CELL);
    if (r < 0 || r >= N || c < 0 || c >= N) return;
    selected = { r, c };
  }

  function handleKey(e) {
    if (!running) return;
    const k = e.key;
    if (k >= '1' && k <= '9') {
      const v = Number(k);
      if (!given[selected.r][selected.c]) {
        grid[selected.r][selected.c] = v;
        if (isComplete()) win();
      }
      e.preventDefault();
    } else if (k === 'Backspace' || k === 'Delete' || k === '0') {
      if (!given[selected.r][selected.c]) grid[selected.r][selected.c] = 0;
      e.preventDefault();
    } else if (k === 'ArrowUp') { selected.r = (selected.r + N - 1) % N; e.preventDefault(); }
    else if (k === 'ArrowDown') { selected.r = (selected.r + 1) % N; e.preventDefault(); }
    else if (k === 'ArrowLeft') { selected.c = (selected.c + N - 1) % N; e.preventDefault(); }
    else if (k === 'ArrowRight') { selected.c = (selected.c + 1) % N; e.preventDefault(); }
  }

  function win() {
    running = false;
    won = true;
    const best = localStorage.getItem(bestKey());
    if (!best || elapsed < Number(best)) {
      localStorage.setItem(bestKey(), String(elapsed));
      bestEl.textContent = fmtTime(elapsed);
      messageEl.textContent = `Solved! New best time — ${fmtTime(elapsed)} 🎉`;
    } else {
      messageEl.textContent = `Solved! Time — ${fmtTime(elapsed)} 🎉`;
    }
  }

  function drawGrid() {
    ctx.clearRect(0, 0, W, H);
    const g = ctx.createLinearGradient(0, 0, W, H);
    g.addColorStop(0, '#141a3a');
    g.addColorStop(1, '#0a0c1d');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, W, H);

    for (let r = 0; r < N; r++) {
      for (let c = 0; c < N; c++) {
        const x = c * CELL, y = r * CELL;
        const isSel = r === selected.r && c === selected.c;
        const sameRow = r === selected.r;
        const sameCol = c === selected.c;
        if (isSel) ctx.fillStyle = 'rgba(76,201,240,0.28)';
        else if (sameRow || sameCol) ctx.fillStyle = 'rgba(128,237,153,0.08)';
        else ctx.fillStyle = 'rgba(255,255,255,0.03)';
        ctx.fillRect(x + 1, y + 1, CELL - 2, CELL - 2);
      }
    }

    for (let r = 0; r < N; r++) {
      for (let c = 0; c < N; c++) {
        const v = grid[r][c];
        if (!v) continue;
        const x = c * CELL, y = r * CELL;
        const conflict = hasConflict(r, c, v) && !given[r][c];
        ctx.fillStyle = given[r][c] ? '#eef1ff' : (conflict ? '#ff6b6b' : '#80ed99');
        ctx.font = `600 ${CELL * 0.55}px system-ui, sans-serif`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(String(v), x + CELL / 2, y + CELL / 2 + 2);
      }
    }

    ctx.strokeStyle = 'rgba(255,255,255,0.12)';
    ctx.lineWidth = 1;
    for (let i = 0; i <= N; i++) {
      ctx.beginPath();
      ctx.moveTo(i * CELL, 0);
      ctx.lineTo(i * CELL, H);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(0, i * CELL);
      ctx.lineTo(W, i * CELL);
      ctx.stroke();
    }
    ctx.strokeStyle = 'rgba(76,201,240,0.8)';
    ctx.lineWidth = 3;
    for (let i = 0; i <= N; i += 3) {
      ctx.beginPath();
      ctx.moveTo(i * CELL, 0);
      ctx.lineTo(i * CELL, H);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(0, i * CELL);
      ctx.lineTo(W, i * CELL);
      ctx.stroke();
    }
  }

  function loop() {
    if (running) {
      elapsed = Math.floor((Date.now() - startTime) / 1000);
      timeEl.textContent = fmtTime(elapsed);
    }
    drawGrid();
    requestAnimationFrame(loop);
  }

  canvas.addEventListener('click', cellFromEvent);
  document.addEventListener('keydown', handleKey);

  document.querySelectorAll('.diff').forEach(btn => {
    btn.addEventListener('click', () => newGame(btn.dataset.d));
  });
  document.querySelectorAll('.num').forEach(btn => {
    btn.addEventListener('click', () => {
      if (!running) return;
      const v = Number(btn.dataset.n);
      if (!given[selected.r][selected.c]) {
        grid[selected.r][selected.c] = v;
        if (isComplete()) win();
      }
    });
  });
  document.getElementById('erase').addEventListener('click', () => {
    if (running && !given[selected.r][selected.c]) grid[selected.r][selected.c] = 0;
  });
  document.getElementById('new').addEventListener('click', () => newGame());

  newGame('easy');
  requestAnimationFrame(loop);
})();
