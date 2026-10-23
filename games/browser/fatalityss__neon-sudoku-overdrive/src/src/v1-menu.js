/* Neon Sudoku — Cehennem ana menü: dokunarak değişen 3 görev paneli + rütbe paneli ve dönen ipuçları */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_MENU) return;
  NS.V1_MENU = true;
  const P = NS.Game.prototype;
  const now = () => performance.now() / 1000;
  const IM = {};
  const img = n => { if (!IM[n]) { const i = new Image(); i.src = (globalThis.NEON_V1_MAP && globalThis.NEON_V1_MAP[n]) || 'media/' + n; IM[n] = i; } return IM[n]; };
  const ok = i => i && i.complete && i.naturalWidth > 0;
  const on = () => globalThis.NEON_CEH && ok(img('c-panel.webp'));
  function nine(c, im, x, y, w, h, C, d) {
    const iw = im.naturalWidth, ih = im.naturalHeight, sx = [0, C, iw - C], sw = [C, iw - 2 * C, C], sy = [0, C, ih - C], sh = [C, ih - 2 * C, C];
    const dx = [x, x + d, x + w - d], dw = [d, w - 2 * d, d], dy = [y, y + d, y + h - d], dh = [d, h - 2 * d, d];
    for (let r = 0; r < 3; r++) for (let q = 0; q < 3; q++) if (dw[q] > 0 && dh[r] > 0) c.drawImage(im, sx[q], sy[r], sw[q], sh[r], dx[q], dy[r], dw[q], dh[r]);
  }
  const panel = (c, x, y, w, h) => { nine(c, img('c-panel.webp'), x, y, w, h, 70, Math.min(34, h / 3)); c.save(); c.fillStyle = 'rgba(0,0,0,.55)'; c.fillRect(x + 22, y + 22, w - 44, h - 44); c.restore(); };
  function fade(c, a, f) { c.save(); c.globalAlpha *= a; f(); c.restore(); }
  function chip(g, x, y, w, txt) { const c = g.ctx, im = img('c-tus-1.webp'); if (ok(im)) { const iw = im.naturalWidth, ih = im.naturalHeight, cap = iw * .17, H = 30, k = H / ih, cw = cap * k; c.drawImage(im, 0, 0, cap, ih, x, y, cw, H); c.drawImage(im, cap, 0, iw - 2 * cap, ih, x + cw, y, w - 2 * cw, H); c.drawImage(im, iw - cap, 0, cap, ih, x + w - cw, y, cw, H); } g.text(txt, x + w / 2, y + 20, 13, '#ffe3b8', 'center'); }
  let changedAt = 0, last = 0;
  globalThis.NEON_MENU_OVR = function (g, v) {
    if (!on()) return false;
    globalThis.NEON_GLYPH_LIGHT = true; try { return menuDraw(g, v); } finally { globalThis.NEON_GLYPH_LIGHT = false; }
  };
  function menuDraw(g, v) {
    if (v !== last) { changedAt = now(); last = v; }
    const c = g.ctx, t = g.record.reduced ? 99 : now(), a = Math.min(1, (t - changedAt) * 3), slide = (1 - a) * 18;
    c.save(); c.translate(0, slide); c.globalAlpha = a;
    if (v === 1) { /* Görev taşı */
      panel(c, 30, 118, 480, 196);
      g.text('◆  GÖREV  ◆', 270, 162, 13, '#ffb46a', 'center');
      g.text('MANTIĞI ÇÖZ', 270, 204, 30, '#fff', 'center');
      g.text('Yanlış adaylara dokun, doğru rakamı koru.', 270, 232, 16, '#e8d2c0', 'center');
      chip(g, 70, 250, 86, '4×4'); chip(g, 162, 250, 88, '30 SN'); chip(g, 256, 250, 110, '40 BÖLÜM'); chip(g, 372, 250, 98, '8 BOSS');
    } else if (v === 2) { /* Ateş yazısı */
      g.text('MANTIĞI ÇÖZ', 270, 172, 34, '#fff', 'center');
      const pu = .5 + .5 * Math.sin(t * 2);
      c.save(); g.text('ATEŞİ YÜKSELT', 270, 222, 34, '#fff', 'center'); c.globalCompositeOperation = 'lighter'; c.globalAlpha *= .18 + .14 * pu; g.text('ATEŞİ YÜKSELT', 270, 222, 34, '#fff', 'center'); c.restore();
      const line = 'Yanlış adaylara dokun; doğru rakamı koru.', n = g.record.reduced ? line.length : Math.min(line.length, Math.floor(((t % 8) / 2.5) * line.length));
      g.text(line.slice(0, n) + (n < line.length && Math.floor(t * 3) % 2 ? '▌' : ''), 270, 256, 16, '#ffc890', 'center');
      g.text('4×4  ·  30 SANİYE  ·  40 BÖLÜM  ·  8 BOSS', 270, 284, 14, '#d8b8a0', 'center');
    } else { /* Sıradaki boss */
      panel(c, 36, 128, 468, 170);
      const L = NS.levels || [], un = g.record.unlocked || 1; let bi = -1, bl = 0;
      for (let i = un - 1; i < L.length; i++) if (L[i] && L[i].boss) { bi = L[i].goal; bl = i + 1; break; }
      if (bi < 0) bi = 7;
      const MAP = [2, 4, 6, 5, 3, 1, 8, 7], gate = img('boss-kilit-' + MAP[bi] + '.webp');
      if (ok(gate)) { const h = 112, w = h * gate.naturalWidth / gate.naturalHeight, bob = Math.sin(t * 1.5) * 2; c.drawImage(gate, 60, 158 + bob, Math.min(w, 170), h); }
      const B = (NS.bosses || [])[bi] || {};
      g.text('SIRADAKİ BOSS', 245, 172, 13, '#ff9a6a', 'left');
      g.text(B.name || 'BOSS', 245, 210, 30, '#fff', 'left');
      g.text((B.unvan || '') , 245, 236, 15, '#e8d2c0', 'left');
      g.text(bl ? 'Bölüm ' + bl + "'de seni bekliyor" : 'Tüm bosslar yenildi!', 245, 262, 15, '#ffc890', 'left');
      g.text('dokun: değiştir', 482, 288, 11, 'rgba(230,200,180,.55)', 'right');
    }
    c.restore();
    return true;
  }

  /* Alt bölüm: rütbe paneli + dönen ipuçları */
  const TIPS = ['Yıldızlar ve görevler kalıcı ödül verir.', 'Yeniden oyna, rekorunu ve yıldızını geliştir.', 'Boss saldırısını zamanında kırarsan süren kurtulur.', 'Hatasız ve hızlı bitir: üç yıldız senin.', 'Combo yaptıkça ısı yükselir, Overdrive açılır.', 'Kristallerle yeni renk temaları açılır.'];
  let tipI = 0, tipT = 0;
  const textPrev = P.text;
  P.text = function (t, x, y, size) {
    if (this.state === 'menu' && on() && x === 270 && (y === 716 || y === 759 || y === 822 || y === 852)) return;
    return textPrev.apply(this, arguments);
  };
  const renderPrev = P.render;
  P.render = function () {
    const r = renderPrev.apply(this, arguments);
    if (this.state !== 'menu' || !on()) return r;
    const c = this.ctx, t = this.record.reduced ? 0 : now(), g = this;
    if (!tipT) tipT = t;
    if (t - tipT > 4.5) { tipI = (tipI + 1) % TIPS.length; tipT = t; }
    panel(c, 50, 722, 440, 124);
    const rk = 'RÜTBE ' + this.rank();
    globalThis.NEON_GLYPH_LIGHT = true; g.text(rk, 200, 786, 30, '#fff', 'center');
    /* kristal */
    const cx = 352, cy = 776, pu = .5 + .5 * Math.sin(t * 2);
    c.save(); c.translate(cx, cy); c.beginPath(); c.moveTo(0, -14); c.lineTo(11, 0); c.lineTo(0, 14); c.lineTo(-11, 0); c.closePath();
    const gr = c.createLinearGradient(-11, -14, 11, 14); gr.addColorStop(0, '#ffe2a8'); gr.addColorStop(.5, '#ff8a2a'); gr.addColorStop(1, '#7a1a08'); c.fillStyle = gr; c.shadowColor = '#ff7a1a'; c.shadowBlur = 8 + 6 * pu; c.fill(); c.restore();
    g.text(String(this.record.crystals), 372, 786, 26, '#fff', 'left'); globalThis.NEON_GLYPH_LIGHT = false;
    g.text(this.themeCount() === 4 ? 'Tüm renk temaları açıldı' : 'Yeni temalar: 100 / 250 / 500 kristal', 270, 820, 15, '#e8c8a8', 'center');
    const ta = Math.min(1, (t - tipT) * 2.5) * Math.min(1, (4.5 - (t - tipT)) * 2.5);
    fade(c, this.record.reduced ? 1 : Math.max(0, ta), () => { g.text('✦ ' + TIPS[tipI], 270, 878, 16, '#f0d8c0', 'center'); });
    for (let k = 0; k < TIPS.length; k++) { c.fillStyle = k === tipI ? '#ff9a4a' : 'rgba(255,200,160,.3)'; c.beginPath(); c.arc(270 + (k - (TIPS.length - 1) / 2) * 12, 900, 3, 0, Math.PI * 2); c.fill(); }
    this.hits.push({ x: 40, y: 856, w: 460, h: 56, name: 'ipucu', action: () => { tipI = (tipI + 1) % TIPS.length; tipT = now(); } });
    return r;
  };
})();
