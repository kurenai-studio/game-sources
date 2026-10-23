(() => {
  'use strict';

  const canvas = document.getElementById('game');
  const ctx = canvas.getContext('2d');
  const youEl = document.getElementById('you');
  const aiEl = document.getElementById('ai');
  const targetEl = document.getElementById('target');
  const messageEl = document.getElementById('message');
  const startEl = document.getElementById('start');
  const restartEl = document.getElementById('restart');

  const W = canvas.width, H = canvas.height;
  const PR = 10, PL = 70, TARGET = 7, BALL_R = 9;

  let you, ai, ball, youScore, aiScore, running, over;

  function resetBall(dir) {
    ;
  }

  function newGame() {
    you = { x: 20, y: H / 2 - PL / 2, vy: 0 };
    ai = { x: W - 20 - PR, y: H / 2 - PL / 2 };
    youScore = 0; aiScore = 0; over = false; running = false;
    youEl.textContent = '0'; aiEl.textContent = '0'; targetEl.textContent = String(TARGET);
    messageEl.textContent = 'Press Start.';
    spawnBall(Math.random() < 0.5 ? 1 : -1);
    draw();
  }

  function spawnBall(dir) {
    ball = { x: W / 2, y: H / 2, vx: dir * 5, vy: (Math.random() * 2 - 1) * 3, r: BALL_R };
  }

  function start() {
    if (over) newGame();
    if (!running) { running = true; messageEl.textContent = 'Go!'; }
  }

  function collide(pad) {
    if (ball.x - ball.r < pad.x + PR && ball.x + ball.r > pad.x && ball.y > pad.y && ball.y < pad.y + PL) {
      const rel = (ball.y - (pad.y + PL / 2)) / (PL / 2);
      const speed = Math.min(11, Math.hypot(ball.vx, ball.vy) * 1.04);
      const sign = pad === you ? 1 : -1;
      const ang = rel * (Math.PI / 3.2);
      ball.vx = sign * speed * Math.cos(ang);
      ball.vy = speed * Math.sin(ang);
      ball.x = pad === you ? pad.x + PR + ball.r : pad.x - ball.r;
    }
  }

  function update() {
    ball.x += ball.vx; ball.y += ball.vy;
    if (ball.y - ball.r < 0) { ball.y = ball.r; ball.vy *= -1; }
    if (ball.y + ball.r > H) { ball.y = H - ball.r; ball.vy *= -1; }

    collide(you);
    collide(ai);

    // AI tracks ball
    const target = ball.y - PL / 2;
    ai.y += (target - ai.y) * 0.09;
    ai.y = Math.max(0, Math.min(H - PL, ai.y));

    if (ball.x < 0) { aiScore++; aiEl.textContent = String(aiScore); checkWin(); }
    else if (ball.x > W) { youScore++; youEl.textContent = String(youScore); checkWin(); }
  }

  function checkWin() {
    if (youScore >= TARGET) { over = true; running = false; messageEl.textContent = 'You win! 🎉'; }
    else if (aiScore >= TARGET) { over = true; running = false; messageEl.textContent = 'AI wins!'; }
    else spawnBall(youScore + aiScore % 2 === 0 ? -1 : 1);
  }

  function draw() {
    const g = ctx.createLinearGradient(0, 0, W, H);
    g.addColorStop(0, '#0f1330'); g.addColorStop(1, '#1a1f47');
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);

    ctx.strokeStyle = 'rgba(255,255,255,0.15)'; ctx.lineWidth = 3; ctx.setLineDash([10, 14]);
    ctx.beginPath(); ctx.moveTo(W / 2, 0); ctx.lineTo(W / 2, H); ctx.stroke(); ctx.setLineDash([]);

    for (const [p, col] of [[you, '#80ed99'], [ai, '#ff5e7e']]) {
      ctx.save(); ctx.shadowBlur = 14; ctx.shadowColor = col; ctx.fillStyle = col;
      ctx.beginPath(); ctx.roundRect(p.x, p.y, PR, PL, 6); ctx.fill(); ctx.restore();
    }

    ctx.save(); ctx.shadowBlur = 14; ctx.shadowColor = '#ffe66d'; ctx.fillStyle = '#ffe66d';
    ctx.beginPath(); ctx.arc(ball.x, ball.y, ball.r, 0, Math.PI * 2); ctx.fill(); ctx.restore();
  }

  function loop() {
    if (running && !over) { update(); draw(); }
    else draw();
    requestAnimationFrame(loop);
  }

  canvas.addEventListener('mousemove', e => {
    const rect = canvas.getBoundingClientRect();
    const y = (e.clientY - rect.top) * (H / rect.height);
    you.y = Math.max(0, Math.min(H - PL, y - PL / 2));
  });
  window.addEventListener('keydown', e => {
    if (!running || over) return;
    if (e.key === 'ArrowUp') you.y = Math.max(0, you.y - 22);
    else if (e.key === 'ArrowDown') you.y = Math.min(H - PL, you.y + 22);
    else return; e.preventDefault();
  });

  startEl.addEventListener('click', start);
  restartEl.addEventListener('click', () => { newGame(); start(); });
  newGame();
  requestAnimationFrame(loop);
})();
