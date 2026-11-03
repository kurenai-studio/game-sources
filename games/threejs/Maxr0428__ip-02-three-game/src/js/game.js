/* ============================================================
   游戏规则：开始 / 计分 / 计时 / 输赢 / 重开
   状态机：ready → playing → win | lose
   ============================================================ */

window.CORE = window.CORE || {};

CORE.createGame = function (deps) {
  const player = deps.player;
  const cores = deps.cores;
  const hazards = deps.hazards;

  const ui = {
    overlay: document.getElementById('overlay'),
    title: document.getElementById('panel-title'),
    sub: document.getElementById('panel-sub'),
    text: document.getElementById('panel-text'),
    button: document.getElementById('panel-btn'),
    hint: document.getElementById('panel-hint'),
    hud: document.getElementById('hud'),
    hudTip: document.getElementById('hud-tip'),
    score: document.getElementById('hud-score'),
    time: document.getElementById('hud-time'),
    timeBox: document.getElementById('hud-time').closest('.hud-item'),
    lives: document.getElementById('hud-lives')
  };

  const RULES = {
    targetScore: 12,
    totalTime: 60,
    totalLives: 3,
    invulnerableSeconds: 1.4
  };

  const state = {
    phase: 'ready',            // ready | playing | win | lose
    score: 0,
    lives: RULES.totalLives,
    timeLeft: RULES.totalTime,
    lastHazardHitAt: -999
  };

  function showOverlay(title, sub, html, buttonText, hint) {
    ui.title.textContent = title;
    ui.sub.textContent = sub;
    ui.text.innerHTML = html;
    ui.button.textContent = buttonText;
    ui.hint.textContent = hint;
    ui.overlay.classList.remove('hidden');
    ui.hud.classList.add('hidden');
    ui.hudTip.classList.add('hidden');
  }

  function hideOverlay() {
    ui.overlay.classList.add('hidden');
    ui.hud.classList.remove('hidden');
    ui.hudTip.classList.remove('hidden');
  }

  function refreshHud() {
    ui.score.textContent = String(state.score);
    ui.time.textContent = Math.ceil(state.timeLeft);
    ui.timeBox.classList.toggle('danger', state.timeLeft <= 10);
    ui.lives.textContent = '◆'.repeat(state.lives) + '◇'.repeat(RULES.totalLives - state.lives);
  }

  function startGame() {
    cores.reset();
    hazards.reset();
    player.group.position.set(0, player.radius, 0);
    player.velocity.set(0, 0, 0);
    player.invulnerableUntil = 1.2;      // 开局给一小段保护时间

    state.phase = 'playing';
    state.score = 0;
    state.lives = RULES.totalLives;
    state.timeLeft = RULES.totalTime;
    state.lastHazardHitAt = -999;

    hideOverlay();
    refreshHud();
  }

  function endGame(win) {
    state.phase = win ? 'win' : 'lose';
    const usedTime = Math.max(1, Math.round(RULES.totalTime - state.timeLeft));
    if (win) {
      showOverlay(
        '收集完成',
        'ALL CORES SECURED',
        '你用 <b>' + usedTime + ' 秒</b>收齐了全部能量核心。<br>剩余护盾：' + '◆'.repeat(state.lives) +
          '<br>平台边缘的方碑正在为你亮起。',
        '再来一局',
        '按空格键也可以重开'
      );
    } else if (state.lives <= 0) {
      showOverlay(
        '护盾耗尽',
        'SHIELD DOWN',
        '被巡逻者击中三次，光熄灭了。<br>本轮收集到 <b>' + state.score + ' / 12</b> 枚核心，再试一次。',
        '重新开始',
        '按空格键也可以重开'
      );
    } else {
      showOverlay(
        '时间到',
        'TIME OUT',
        '还差 <b>' + (RULES.targetScore - state.score) + '</b> 枚核心。<br>试着规划一条更顺的路线。',
        '重新开始',
        '按空格键也可以重开'
      );
    }
  }

  /* 每帧推进游戏逻辑 */
  state.update = function (dt, elapsed) {
    if (state.phase !== 'playing') return;

    // 倒计时
    state.timeLeft -= dt;
    if (state.timeLeft <= 0) {
      state.timeLeft = 0;
      refreshHud();
      endGame(false);
      return;
    }

    // 收集判定
    const collected = cores.tryCollect(player);
    if (collected) {
      state.score += 1;
      refreshHud();
      if (state.score >= RULES.targetScore) {
        endGame(true);
        return;
      }
    }

    // 碰撞判定：受击后有 1.4 秒无敌，防止连续扣血
    const hazard = hazards.hitPlayer(player);
    if (hazard && elapsed > player.invulnerableUntil) {
      state.lives -= 1;
      player.invulnerableUntil = elapsed + RULES.invulnerableSeconds;
      hazards.knockBack(player, hazard);
      refreshHud();
      if (state.lives <= 0) {
        endGame(false);
        return;
      }
    }
  };

  /* 主循环里调用：返回当前是否处于游玩中 */
  state.isRunning = function () {
    return state.phase === 'playing';
  };

  /* 开始 / 重开按钮与空格键 */
  ui.button.addEventListener('click', startGame);
  document.addEventListener('keydown', function (event) {
    if (event.code === 'Space' && state.phase !== 'playing') {
      startGame();
      event.preventDefault();
    }
  });

  refreshHud();

  // 调试与录屏辅助：网址带 ?autostart 时跳过开始面板直接进入游戏
  if (new URLSearchParams(window.location.search).has('autostart')) {
    startGame();
  }

  return state;
};
