/**
 * Browser 2048 demo — same rules as the Python Board logic.
 */
(() => {
  const SIZE = 4;
  const WIN = 2048;
  const BEST_KEY = "pygame-2048-best";

  const boardEl = document.getElementById("board");
  const scoreEl = document.getElementById("score");
  const bestEl = document.getElementById("best");
  const overlay = document.getElementById("overlay");
  const overlayTitle = document.getElementById("overlay-title");
  const overlaySub = document.getElementById("overlay-sub");

  let grid = emptyGrid();
  let score = 0;
  let best = Number(localStorage.getItem(BEST_KEY) || 0);
  let won = false;
  let continued = false;

  bestEl.textContent = String(best);

  function emptyGrid() {
    return Array.from({ length: SIZE }, () => Array(SIZE).fill(0));
  }

  function emptyCells() {
    const cells = [];
    for (let r = 0; r < SIZE; r++) {
      for (let c = 0; c < SIZE; c++) {
        if (grid[r][c] === 0) cells.push([r, c]);
      }
    }
    return cells;
  }

  function spawn() {
    const cells = emptyCells();
    if (!cells.length) return;
    const [r, c] = cells[Math.floor(Math.random() * cells.length)];
    grid[r][c] = Math.random() < 0.1 ? 4 : 2;
  }

  function compressMerge(line) {
    const tiles = line.filter((v) => v !== 0);
    const result = [];
    let gained = 0;
    let i = 0;
    while (i < tiles.length) {
      if (i + 1 < tiles.length && tiles[i] === tiles[i + 1]) {
        const m = tiles[i] * 2;
        result.push(m);
        gained += m;
        i += 2;
      } else {
        result.push(tiles[i]);
        i += 1;
      }
    }
    while (result.length < SIZE) result.push(0);
    return { line: result, gained };
  }

  function move(dir) {
    if (isGameOver()) return;
    if (won && !continued) return;

    const before = grid.map((row) => row.slice());
    let gainedTotal = 0;

    if (dir === "left" || dir === "right") {
      for (let r = 0; r < SIZE; r++) {
        let line = grid[r].slice();
        if (dir === "right") line.reverse();
        const { line: next, gained } = compressMerge(line);
        if (dir === "right") next.reverse();
        grid[r] = next;
        gainedTotal += gained;
      }
    } else {
      for (let c = 0; c < SIZE; c++) {
        let line = grid.map((row) => row[c]);
        if (dir === "down") line.reverse();
        const { line: next, gained } = compressMerge(line);
        if (dir === "down") next.reverse();
        for (let r = 0; r < SIZE; r++) grid[r][c] = next[r];
        gainedTotal += gained;
      }
    }

    const moved = JSON.stringify(grid) !== JSON.stringify(before);
    if (!moved) return;

    score += gainedTotal;
    if (score > best) {
      best = score;
      localStorage.setItem(BEST_KEY, String(best));
      bestEl.textContent = String(best);
    }
    spawn();
    if (!won && maxTile() >= WIN) {
      won = true;
    }
    render();
  }

  function maxTile() {
    return Math.max(...grid.flat());
  }

  function canMove() {
    if (emptyCells().length) return true;
    for (let r = 0; r < SIZE; r++) {
      for (let c = 0; c < SIZE; c++) {
        const v = grid[r][c];
        if (c + 1 < SIZE && grid[r][c + 1] === v) return true;
        if (r + 1 < SIZE && grid[r + 1][c] === v) return true;
      }
    }
    return false;
  }

  function isGameOver() {
    return !canMove();
  }

  function cellClass(value) {
    if (!value) return "cell";
    if (value > 2048) return "cell vhuge";
    return `cell v${value}`;
  }

  function render() {
    boardEl.innerHTML = "";
    for (let r = 0; r < SIZE; r++) {
      for (let c = 0; c < SIZE; c++) {
        const v = grid[r][c];
        const div = document.createElement("div");
        div.className = cellClass(v);
        div.textContent = v ? String(v) : "";
        boardEl.appendChild(div);
      }
    }
    scoreEl.textContent = String(score);

    if (won && !continued) {
      overlay.classList.remove("hidden");
      overlayTitle.textContent = "You win!";
      overlaySub.textContent = "Enter to continue · R to restart";
    } else if (isGameOver()) {
      overlay.classList.remove("hidden");
      overlayTitle.textContent = "Game over";
      overlaySub.textContent = "Press R to try again";
    } else {
      overlay.classList.add("hidden");
    }
  }

  function restart() {
    grid = emptyGrid();
    score = 0;
    won = false;
    continued = false;
    spawn();
    spawn();
    render();
  }

  document.addEventListener("keydown", (e) => {
    const map = {
      ArrowLeft: "left",
      a: "left",
      A: "left",
      ArrowRight: "right",
      d: "right",
      D: "right",
      ArrowUp: "up",
      w: "up",
      W: "up",
      ArrowDown: "down",
      s: "down",
      S: "down",
    };

    if (e.key === "r" || e.key === "R") {
      e.preventDefault();
      restart();
      return;
    }

    if (won && !continued && (e.key === "Enter" || e.key === " ")) {
      e.preventDefault();
      continued = true;
      render();
      return;
    }

    const dir = map[e.key];
    if (dir) {
      e.preventDefault();
      move(dir);
    }
  });

  document.querySelectorAll(".mobile-pad button").forEach((btn) => {
    btn.addEventListener("click", () => move(btn.dataset.dir));
  });

  // touch swipe
  let touchStart = null;
  boardEl.addEventListener(
    "touchstart",
    (e) => {
      const t = e.changedTouches[0];
      touchStart = { x: t.clientX, y: t.clientY };
    },
    { passive: true }
  );
  boardEl.addEventListener(
    "touchend",
    (e) => {
      if (!touchStart) return;
      const t = e.changedTouches[0];
      const dx = t.clientX - touchStart.x;
      const dy = t.clientY - touchStart.y;
      touchStart = null;
      if (Math.max(Math.abs(dx), Math.abs(dy)) < 24) return;
      if (Math.abs(dx) > Math.abs(dy)) move(dx > 0 ? "right" : "left");
      else move(dy > 0 ? "down" : "up");
    },
    { passive: true }
  );

  restart();
})();
