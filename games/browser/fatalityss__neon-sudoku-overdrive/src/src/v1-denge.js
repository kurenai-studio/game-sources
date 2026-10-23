/* Neon Sudoku — süre dengesi (V1.50): başlangıç süresi hamle sayısına göre, bonuslar bu süreye göre */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_DENGE) return;
  NS.V1_DENGE = true;
  const P = NS.Game.prototype;
  const base = g => Math.round(30 + Math.max(0, (g.totalMoves || 0) - 12) * 0.9);
  NS.tmax = g => (g && g.__tmax) || 30;

  const start0 = P.start;
  P.start = function () {
    const r = start0.apply(this, arguments);
    this.__tmax = base(this); this.time = this.__tmax;
    return r;
  };

  /* Bonus: süre başlangıcın %70'inin altına inince verilir, başlangıç süresini aşmaz */
  const upd0 = P.update;
  P.update = function (dt) {
    const lvl = this.level, given = this.bonusGiven, earned = this.bonusEarned;
    if (this.cfg && earned > given) this.bonusEarned = given;          // eski 21 sn / 30 sn kuralını devre dışı bırak
    const r = upd0.apply(this, arguments);
    if (this.level === lvl && this.bonusGiven === given && this.bonusEarned === given) this.bonusEarned = earned;
    const T = NS.tmax(this);
    if (this.state === 'playing' && this.cfg && this.bonusEarned > this.bonusGiven && this.time <= T * 0.7) {
      this.bonusGiven++;
      this.time = Math.min(T, this.time + this.cfg.timeBonus);
      this.hourglassFlash = 1.6; this.bonusFlash = 1;
      try { this.sfx('timeBonus'); } catch (_) {}
      try { this.notify('⌛ +' + this.cfg.timeBonus + ' SANİYE · bonus ' + this.bonusGiven + '/' + this.cfg.extraTimes); } catch (_) {}
    }
    return r;
  };

  /* Yazılar: brifing ve menüdeki "30 saniye" ifadeleri; övgü yazısı logonun üstünden tahtanın üst kenarına */
  const text0 = P.text;
  P.text = function (str, x, y, size, color, align) {
    const a = [...arguments];
    if (typeof str === 'string') {
      if (str.includes(' aday · 30 saniye')) a[0] = str.replace('30 saniye', NS.tmax(this) + ' saniye');
      else if (str === '4×4 · 30 saniye · 40 bölüm · 8 boss') a[0] = '4×4 · 30–52 sn · 40 bölüm · 8 boss';
      else if (y === 112 && x === 270 && str === this.praiseText && this.state === 'playing') {
        const c = this.ctx; a[2] = 572;
        c.save(); c.shadowBlur = 0; c.globalAlpha = .6; c.fillStyle = '#120806';
        const w = Math.max(120, str.length * (size || 24) * .62 + 36);
        c.beginPath(); if (c.roundRect) c.roundRect(270 - w / 2, 546, w, 40, 20); else c.rect(270 - w / 2, 546, w, 40); c.fill(); c.restore();
      }
    }
    return text0.apply(this, a);
  };
})();
