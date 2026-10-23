/* Neon Sudoku — tema önerileri: hücre, rakam, düğme, süre çubuğu */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_TEMA) return;
  NS.V1_TEMA = true;
  NS.SURUM = globalThis.NEON_VERSION || '1.51'; /* build.py VERSION dosyasından basar; kaynaktan açılırken yedek */
  const P = NS.Game.prototype;
  const T = {
    A: { ad: 'Buz Mavisi', top: '#14344a', bot: '#07131d', side: '#03080d', edge: '#45e4ff', dig: '#e6fbff', glow: '#22d3ff', btop: '#123044', bbot: '#081621', btxt: '#e9fbff' },
    B: { ad: 'Reaktör Turuncu', top: '#36210f', bot: '#140b05', side: '#070402', edge: '#ffa04a', dig: '#fff3e2', glow: '#ff7a1a', btop: '#2e1c0e', bbot: '#120a05', btxt: '#fff1de' },
    C: { ad: 'Plazma Mor', top: '#2c1748', bot: '#0e0820', side: '#05030c', edge: '#c784ff', dig: '#f8efff', glow: '#b04dff', btop: '#261440', bbot: '#0d0820', btxt: '#f6ecff' }
  };

  const IMGS = {};
  const img = name => { if (IMGS[name]) return IMGS[name]; const i = new Image(); i.src = (globalThis.NEON_V1_MAP && globalThis.NEON_V1_MAP[name]) || 'media/' + name; return (IMGS[name] = i); };
  const okI = i => i && i.complete && i.naturalWidth > 0;
  /* V1 hücre sprite'larından 9 dilimli düğme çerçevesi: [kare çerçeve src x0, y0, boyut] */
  const FRAME = { metal: [112, 507, 520], elektrik: [780, 507, 520], alev: [1450, 507, 520], kirmizi: [2112, 507, 520] };
  function nine(c, im, fr, x, y, w, h, M, A) {
    const [fx, fy, fs] = fr, sx = fx - M, sy = fy - M, S = fs + M * 2, C = 150 + M;
    const k = Math.min(.2, (h + 0) / fs * 1.05), d = C * k, dx = x - M * k, dy = y - M * k, W = w + M * k * 2, H = h + M * k * 2;
    const cols = [[sx, C, dx, d], [sx + C, S - 2 * C, dx + d, W - 2 * d], [sx + S - C, C, dx + W - d, d]];
    const rows = [[sy, C, dy, d], [sy + C, S - 2 * C, dy + d, H - 2 * d], [sy + S - C, C, dy + H - d, d]];
    c.save(); c.globalAlpha = A == null ? 1 : A; c.globalCompositeOperation = 'screen';
    for (const r of rows) for (const q of cols) if (q[3] > 0 && r[3] > 0) c.drawImage(im, q[0], r[0], q[1], r[1], q[2], r[2], q[3], r[3]);
    c.restore();
  }
  const pal = () => (globalThis.NEON_ATES !== false && okI(img('ates-cubuk.webp'))) ? { ad: 'Ateş', top: '#2a0f08', bot: '#120604', side: '#060201', edge: '#ff7a2a', dig: '#fff1dc', glow: '#ff5a10', btop: '#2a0f08', bbot: '#120604', btxt: '#ffe9c8' } : T[globalThis.NEON_TEMA === undefined ? 'A' : globalThis.NEON_TEMA] || null;
  const live = s => ['playing', 'chain', 'paused', 'timeout', 'complete'].includes(s);
  const now = () => performance.now() / 1000;
  function rr(c, x, y, w, h, r) { c.beginPath(); c.moveTo(x + r, y); c.arcTo(x + w, y, x + w, y + h, r); c.arcTo(x + w, y + h, x, y + h, r); c.arcTo(x, y + h, x, y, r); c.arcTo(x, y, x + w, y, r); c.closePath(); }
  function block(c, x, y, w, h, p, edge, edgeA, glow, r) {
    const d = Math.max(4, Math.min(8, h * .08));
    c.save();
    rr(c, x, y + d, w, h - d, r); c.fillStyle = p.side; c.fill();
    const g = c.createLinearGradient(0, y, 0, y + h - d); g.addColorStop(0, p.top); g.addColorStop(1, p.bot);
    rr(c, x, y, w, h - d, r); c.fillStyle = g; c.fill();
    const s = c.createLinearGradient(0, y, 0, y + (h - d) * .5); s.addColorStop(0, 'rgba(255,255,255,.16)'); s.addColorStop(1, 'rgba(255,255,255,0)');
    rr(c, x + 3, y + 3, w - 6, (h - d) * .5, r - 2); c.fillStyle = s; c.fill();
    c.globalAlpha = edgeA; c.strokeStyle = edge; c.lineWidth = 2; if (glow) { c.shadowColor = edge; c.shadowBlur = glow; }
    rr(c, x + 1, y + 1, w - 2, h - d - 2, r); c.stroke();
    c.restore();
    return d;
  }
  /* Hücreler ve düğmeler */
  const hullPrev = P.hull;
  P.hull = function (x, y, w, h, accent, active) {
    const p = pal(); if (!p) return hullPrev.apply(this, arguments);
    const c = this.ctx;
    if (this.__btn) {
      if (atesOk()) { if (w < 100 ? tileFire(c, x, y, w, h, active ? 2 : 1, now(), 0, this.record.reduced) : buttonFire(c, x, y, w, h, active, now(), this.record.reduced)) return; }
      const tus = img('metal-tus.webp');
      if (metalOk() && okI(tus) && w < 100 && okI(img('metal-hucre-1.webp'))) { const S = Math.max(w, h) + 8; shadowBox(c, x + 4, y + 6, w - 8, h - 8, 8, 1, .8); c.save(); c.globalCompositeOperation = 'lighten'; c.drawImage(img('metal-hucre-' + (active ? 2 : 1) + '.webp'), x + w / 2 - S / 2, y + h / 2 - S / 2, S, S); c.restore(); return; }
      if (metalOk() && okI(tus)) {
        const iw = tus.naturalWidth, ih = tus.naturalHeight, H2 = h * 1.3, k2 = H2 / ih, cap = Math.min(iw * .2, (w / 2) / k2), y2 = y + h / 2 - H2 / 2 - (active ? 2 : 0);
        shadowBox(c, x + 6, y + 6, w - 12, h - 8, 8, active ? 4 : 1, .85);
        c.save(); c.globalCompositeOperation = 'lighten';
        c.drawImage(tus, 0, 0, cap, ih, x - 8, y2, cap * k2, H2);
        c.drawImage(tus, cap, 0, iw - 2 * cap, ih, x - 8 + cap * k2, y2, Math.max(1, w + 16 - 2 * cap * k2), H2);
        c.drawImage(tus, iw - cap, 0, cap, ih, x + w + 8 - cap * k2, y2, cap * k2, H2);
        if (active && !this.record.reduced) { c.globalCompositeOperation = 'lighter'; c.globalAlpha = .12 + .08 * Math.sin(now() * 2.5 + x); c.drawImage(tus, 0, 0, iw, ih, x - 8, y2, w + 16, H2); }
        c.restore(); return;
      }
      const cel = img('Gemini-Hucre-Durumlari-V1-Depth.jpg');
      rr(c, x + 3, y + 3, w - 6, h - 6, 10); c.fillStyle = 'rgba(4,10,18,.9)'; c.fill();
      if (!okI(cel)) { block(c, x, y, w, h, { top: p.btop, bot: p.bbot, side: p.side }, active ? p.edge : '#8aa4b8', active ? .95 : .35, 0, 12); return; }
      const tt = now(), still = this.record.reduced;
      const fl = still ? 1 : (active ? .9 + .1 * Math.sin(tt * 2 + x * .01) : .82 + .08 * Math.sin(tt * 1.6 + y * .02));
      nine(c, cel, active ? FRAME.alev : FRAME.elektrik, x, y, w, h, 70, fl);
      return;
    }
    if (w === 112 && h === 112 && this.cfg && live(this.state)) {
      const i = Math.round((x - 30) / 120) + Math.round((y - 326) / 120) * 4;
      const sel = i === this.selected;
      /* ChatGPT hücre seti: 1 normal, 2 seçili, 3 çözülmüş, 4 hata — yüz geniş, rakam net */
      const st = sel ? (this.errorFlash > 0 ? 4 : 2) : (this.popAt && this.popAt[i] !== undefined ? 3 : 1), ct = metalOk() && okI(img('metal-hucre-' + st + '.webp')) ? img('metal-hucre-' + st + '.webp') : img('hucre-yeni-' + st + '.webp');
      if (okI(ct)) {
        const tt = now(), pul = sel && !this.record.reduced ? 1 + .015 * Math.sin(tt * 4) : 1, sh = st === 4 && !this.record.reduced ? Math.sin(tt * 60) * 3 * Math.min(1, this.errorFlash) : 0, W2 = (w + 10) * pul;
        if (atesOk() && tileFire(c, x + sh, y, w, h, st, tt, sel ? 5 : 0, this.record.reduced)) return;
        const lift = sel ? 5 : 0, bx2 = x + w / 2 - W2 / 2 + sh, by2 = y + h / 2 - W2 / 2 - lift;
        if (metalOk()) shadowBox(c, bx2 + 6, by2 + 8, W2 - 12, W2 - 12, 10, lift, sel ? .9 : .7);
        c.save(); c.globalCompositeOperation = metalOk() ? 'lighten' : 'screen'; c.drawImage(ct, bx2, by2, W2, W2); c.restore();
        return;
      }
      const ctOld = img('hucre-' + ({ 1: 1, 2: 3, 3: 2, 4: 4 })[tierOf(this)] + '.webp');
      if (okI(ctOld)) { c.save(); c.globalCompositeOperation = 'screen'; c.globalAlpha = sel ? 1 : .82; c.drawImage(ctOld, x - 4, y - 4, w + 8, h + 8); c.restore(); }
      else block(c, x + 4, y + 4, w - 8, h - 8, p, p.edge, sel ? 1 : .45, sel ? 16 : 6, 14);
      if (sel) return hullPrev.apply(this, arguments);
      return;
    }
    return hullPrev.apply(this, arguments);
  };
  const btnPrev = P.button;
  P.button = function () { this.__btn = true; try { return btnPrev.apply(this, arguments); } finally { this.__btn = false; } };
  /* Rakamlar: düz, net, neon kenarlı */
  const textPrev = P.text;
  P.text = function (t, x, y, size, color, align) {
    const p = pal();
    if (p && /^[1-4]$/.test(t) && (size === 42 || size === 34)) {
      const c = this.ctx; let s = 1;
      if (size === 42 && this.popAt) {
        const col = Math.round((x - 86) / 120), row = Math.round((y - 399) / 120), at = this.popAt[row * 4 + col];
        if (at !== undefined && !this.record.reduced) { const e = now() - at; if (e < .5) s = e < .1 ? 1 - e * 2.5 : e < .25 ? .75 + (e - .1) / .15 * .38 : 1.13 - (e - .25) / .25 * .13; }
      }
      const fs = (size === 42 ? 58 : 46) * s, cy = y - (size === 42 ? 16 : 12);
      c.save(); c.font = '800 ' + fs + 'px Oxanium, sans-serif'; c.textAlign = 'center'; c.textBaseline = 'middle';
      c.fillStyle = 'rgba(0,0,0,.55)'; c.fillText(t, x, cy + 4);
      c.shadowColor = p.glow; c.shadowBlur = this.record.reduced ? 0 : 16; c.fillStyle = p.dig; c.fillText(t, x, cy);
      c.shadowBlur = 0; c.lineWidth = 1.4; c.strokeStyle = p.edge; c.strokeText(t, x, cy);
      c.restore(); return;
    }
    if (p && this.__btn && size >= 18 && size < 30) color = globalThis.NEON_CEH ? '#f2f2f2' : metalOk() ? '#ffe9c8' : (/^#ee|^#e8/.test(color || '') ? p.btxt : color);
    return textPrev.call(this, t, x, y, size, color, align);
  };
  /* Süre: V1 yıldırım çubuğu; Isı: ince alev şeridi */
  const ok = i => i && i.complete && i.naturalWidth > 0;
  let boost = null;
  const findBoost = () => { if (boost) return boost; for (const im of document.images) if (/Boost/.test(im.src)) return (boost = im); const i = new Image(); i.src = (globalThis.NEON_V1_MAP && globalThis.NEON_V1_MAP['Gemini-Boost-Yildirim-Cubugu.jpg']) || 'media/Gemini-Boost-Yildirim-Cubugu.jpg'; return (boost = i); };
  const heatPrev = P.heatGauge;
  P.heatGauge = function () {
    const p = pal(); if (!p) return heatPrev.apply(this, arguments);
    const c = this.ctx, f = Math.max(0, Math.min(1, this.heat / 100)), t = now();
    c.save(); rr(c, 28, 212, 484, 14, 7); c.fillStyle = '#0a121b'; c.fill(); c.strokeStyle = 'rgba(255,255,255,.12)'; c.stroke();
    if (f > 0) { const g = c.createLinearGradient(28, 0, 512, 0); g.addColorStop(0, '#ff4d2e'); g.addColorStop(.6, '#ffa13a'); g.addColorStop(1, '#ffe27a'); rr(c, 28, 212, 484 * f, 14, 7); c.fillStyle = g; c.shadowColor = '#ff7a1a'; c.shadowBlur = this.record.reduced ? 0 : 10 + 4 * Math.sin(t * 9); c.fill(); }
    c.restore();
  };
  /* ---------- Canlı katman: elektrikli/alevli düğmeler, şimşekli süre tüpü, hareketli menü ---------- */
  const COL = { A: ['#0a9dff', '#7ff6ff', '#e8fdff'], B: ['#ff6a00', '#ffc04a', '#fff3d6'], C: ['#8a2bff', '#d79bff', '#f7ecff'] };
  const btnPrev2 = P.button;
  P.button = function (label, x, y, w, h, action, accent) {
    (this.__fxb || (this.__fxb = [])).push({ x, y, w, h, accent: !!accent });
    return btnPrev2.apply(this, arguments);
  };
  function perim(b, s) {
    const L = 2 * (b.w + b.h); let d = ((s % 1) + 1) % 1 * L;
    if (d < b.w) return [b.x + d, b.y, 0, -1]; d -= b.w;
    if (d < b.h) return [b.x + b.w, b.y + d, 1, 0]; d -= b.h;
    if (d < b.w) return [b.x + b.w - d, b.y + b.h, 0, 1]; d -= b.w;
    return [b.x, b.y + b.h - d, -1, 0];
  }
  function rndGen(seed) { let s = seed >>> 0 || 1; return () => (s = (s * 1664525 + 1013904223) >>> 0) / 4294967296; }
  function arc(c, b, s0, len, rnd, col, width) {
    c.beginPath(); const n = 9;
    for (let k = 0; k <= n; k++) { const [px, py, nx, ny] = perim(b, s0 + len * k / n), o = (k === 0 || k === n) ? 0 : (rnd() - .5) * 9; k ? c.lineTo(px + nx * o + (rnd() - .5) * 3, py + ny * o + (rnd() - .5) * 3) : c.moveTo(px, py); }
    c.strokeStyle = col; c.lineWidth = width; c.shadowColor = col; c.shadowBlur = 12; c.stroke();
    c.strokeStyle = '#ffffff'; c.lineWidth = width * .4; c.shadowBlur = 0; c.stroke();
  }
  function flames(c, x, y, w, t, col) {
    const n = Math.max(5, Math.floor(w / 26));
    for (let k = 0; k < n; k++) {
      const fx = x + 8 + (w - 16) * (k + .5) / n, hh = 5 + 5 * Math.abs(Math.sin(t * 7 + k * 1.7)) + 3 * Math.sin(t * 13 + k);
      const g = c.createLinearGradient(0, y - hh, 0, y + 2); g.addColorStop(0, 'rgba(255,255,200,0)'); g.addColorStop(.4, col[1]); g.addColorStop(1, col[0]);
      c.fillStyle = g; c.beginPath(); c.moveTo(fx - 9, y + 2); c.quadraticCurveTo(fx - 6 + Math.sin(t * 9 + k) * 2, y - hh * .5, fx + Math.sin(t * 6 + k) * 3, y - hh); c.quadraticCurveTo(fx + 6, y - hh * .5, fx + 9, y + 2); c.fill();
    }
  }
  function buttonsFX(g) {
    const p = globalThis.NEON_TEMA || 'A', col = COL[p] || COL.A, c = g.ctx, t = now();
    for (const [k, b] of (g.__fxb || []).entries()) {
      c.save(); c.globalCompositeOperation = 'lighter';
      const rnd = rndGen(Math.floor(t * 20) * 977 + k * 131);
      if (b.accent) {
        c.globalAlpha = .75; flames(c, b.x + 4, b.y + b.h - 7, b.w - 8, t + k, ['#ff3d00', '#ffb347']); c.globalAlpha = 1;
        arc(c, b, t * .25 + k * .13, .1, rndGen(Math.floor(t * 6) * 977 + k * 131), col[1], 1.6);
      } else {
        const s = t * .18 + k * .37, [px, py] = perim(b, s);
        const gr = c.createRadialGradient(px, py, 0, px, py, 16); gr.addColorStop(0, col[2]); gr.addColorStop(.3, col[1]); gr.addColorStop(1, 'rgba(0,0,0,0)');
        c.fillStyle = gr; c.globalAlpha = .9; c.fillRect(px - 16, py - 16, 32, 32);
        c.globalAlpha = .55; arc(c, b, s - .06, .06, rndGen(Math.floor(t * 6) * 977 + k * 131), col[1], 1.1);
      }
      c.restore();
    }
  }
  /* Süre çubuğu evrimi: bölüm ilerledikçe 4 aşama */
  function tierOf(g) { const ch = (g.cfg && g.cfg.chapter) || Math.ceil((g.level || 1) / 5); if (g.cfg && g.cfg.boss) return 4; return ch <= 2 ? 1 : ch <= 4 ? 2 : ch <= 6 ? 3 : 4; }
  function tubeBasic(g, tier) {
    const c = g.ctx, t = now(), still = g.record.reduced, f = Math.max(0, Math.min(1, g.time / NS_T(g)));
    const X = 22, Y = 140, W = 496, H = 24, hx = X + W * f, urgent = g.time <= 5;
    const col = urgent ? ['#ff1f3d', '#ff8a96', '#fff0f2'] : g.time <= 10 ? ['#ff8a00', '#ffd060', '#fff6dc'] : ['#0a9dff', '#7ff6ff', '#e8fdff'];
    c.save(); c.fillStyle = '#060b12'; c.fillRect(20, 135, 500, 40);
    rr(c, X - 3, Y - 3, W + 6, H + 6, 13); const mg = c.createLinearGradient(0, Y - 3, 0, Y + H + 3); mg.addColorStop(0, '#5b6b78'); mg.addColorStop(.5, '#1d262f'); mg.addColorStop(1, '#3a4651'); c.fillStyle = mg; c.fill();
    rr(c, X, Y, W, H, 11); c.fillStyle = '#050a10'; c.fill();
    c.save(); rr(c, X, Y, W, H, 11); c.clip();
    if (f > 0) {
      const fg = c.createLinearGradient(X, 0, hx, 0); fg.addColorStop(0, col[0]); fg.addColorStop(1, col[1]); c.fillStyle = fg; c.fillRect(X, Y, hx - X, H);
      if (!still) { c.globalCompositeOperation = 'lighter'; for (let w = 0; w < 2; w++) { c.beginPath(); for (let x = X; x <= hx; x += 6) { const yy = Y + H / 2 + Math.sin(x * .05 + t * (5 + w * 3)) * (4 + w * 3); x === X ? c.moveTo(x, yy) : c.lineTo(x, yy); } c.strokeStyle = 'rgba(255,255,255,.18)'; c.lineWidth = 2; c.stroke(); }
        if (tier >= 2) { const r = rndGen(Math.floor(t * 7) * 7919 + 3); for (let k = 0; k < (urgent ? 2 : 1); k++) { c.beginPath(); let x = X + 4; c.moveTo(x, Y + H / 2); while (x < hx - 4) { x = Math.min(hx - 4, x + 10 + r() * 18); c.lineTo(x, Y + 3 + r() * (H - 6)); } c.strokeStyle = col[2]; c.lineWidth = k ? 1 : 1.8; c.shadowColor = col[1]; c.shadowBlur = 10; c.stroke(); } c.shadowBlur = 0; } }
    }
    const sh = c.createLinearGradient(0, Y, 0, Y + H * .5); sh.addColorStop(0, 'rgba(255,255,255,.28)'); sh.addColorStop(1, 'rgba(255,255,255,0)'); c.globalCompositeOperation = 'source-over'; c.fillStyle = sh; c.fillRect(X, Y + 1, W, H * .45);
    c.fillStyle = 'rgba(0,0,0,.6)'; for (const k of [1, 2]) c.fillRect(X + W * k / 3 - 1, Y, 2, H);
    c.restore();
    if (tier >= 2 && f > 0 && !still) { c.globalCompositeOperation = 'lighter'; glow2(c, hx, Y + H / 2, 20 + 6 * Math.sin(t * 15), 'rgba(255,255,255,.8)'); if (Math.random() < .3) g.fx.push({ kind: 'spark', x: hx, y: Y + H / 2, vx: 40 + Math.random() * 90, vy: (Math.random() - .5) * 120, age: 0, life: .45, color: col[1] }); }
    c.restore();
  }
  /* Yapay zekâ süre çubukları: [içX0, içY0, içX1, içY1, yükseklik] (900 px genişlik ölçeğinde) */
  const SC = { 1: [194, 43, 719, 72, 115], 2: [197, 38, 702, 69, 105], 3: [205, 36, 698, 65, 103], 4: [190, 38, 712, 64, 100] };
  const SC_SIRA = { 1: 3, 2: 2, 3: 1, 4: 4 }; /* evrim: endüstriyel boru → kristal → iblis → hologram */
  function timeAI(g, tier) {
    const boss = g.cfg && g.cfg.boss, bc = boss && NS.bosses && NS.bosses[g.cfg.goal] ? NS.bosses[g.cfg.goal].color : null;
    const n = boss ? [3, 2, 1, 4][(g.cfg.goal || 0) % 4] : SC_SIRA[tier], im = img('sure-cubuk-' + n + '.webp'); if (!okI(im)) return false;
    const BASEH = { 1: 15, 2: 210, 3: 30, 4: 265 }, hr = bc ? hueOf(bc) - BASEH[n] : 0;
    const c = g.ctx, t = now(), still = g.record.reduced, f = Math.max(0, Math.min(1, g.time / NS_T(g))), urgent = g.time <= 5;
    const [ix0, iy0, ix1, iy1, ih] = SC[n], W = 520, k = W / 900, X = 10, Y = 160 - ih * k / 2;
    const ax = X + ix0 * k, ay = Y + iy0 * k, aw = (ix1 - ix0) * k, ah = (iy1 - iy0) * k, hx = ax + aw * f;
    const col = urgent ? ['#ff1f3d', '#ff8a96'] : bc ? [bc, '#ffffff'] : g.time <= 10 ? ['#ff8a00', '#ffd060'] : [['', '#ff7a1a', '#ffc04a'], ['', '#2aa8ff', '#9ff3ff'], ['', '#ff3b1f', '#ffb04a'], ['', '#8a4dff', '#7ff6ff']][tier - 1].slice(1);
    c.save();
    c.beginPath(); c.rect(ax, ay, aw, ah); c.fillStyle = '#03060a'; c.fill(); c.clip();
    if (f > 0) {
      const fg = c.createLinearGradient(ax, 0, hx, 0); fg.addColorStop(0, col[0]); fg.addColorStop(1, col[1]); c.fillStyle = fg; c.fillRect(ax, ay, hx - ax, ah);
      if (!still) { c.globalCompositeOperation = 'lighter'; c.beginPath(); for (let x = ax; x <= hx; x += 6) { const yy = ay + ah / 2 + Math.sin(x * .05 + t * 4) * ah * .25; x === ax ? c.moveTo(x, yy) : c.lineTo(x, yy); } c.strokeStyle = 'rgba(255,255,255,.22)'; c.lineWidth = 2; c.stroke(); }
      const sh = c.createLinearGradient(0, ay, 0, ay + ah * .5); sh.addColorStop(0, 'rgba(255,255,255,.3)'); sh.addColorStop(1, 'rgba(255,255,255,0)'); c.globalCompositeOperation = 'source-over'; c.fillStyle = sh; c.fillRect(ax, ay, hx - ax, ah * .45);
      c.fillStyle = '#fff'; c.globalAlpha = .9; c.fillRect(hx - 1.5, ay, 3, ah);
    }
    c.restore();
    c.save(); if (hr) c.filter = 'hue-rotate(' + Math.round(hr) + 'deg) saturate(1.2)'; c.globalCompositeOperation = 'screen'; c.drawImage(im, X, Y, W, ih * k);
    if (!still) { c.globalCompositeOperation = 'lighter'; c.globalAlpha = .1 + .06 * Math.sin(t * 1.6); c.drawImage(im, X, Y, W, ih * k); }
    c.restore();
    return true;
  }
  function timeTube(g) {
    if (globalThis.NEON_TIME_DRAW && globalThis.NEON_TIME_DRAW(g)) return;
    const tier = tierOf(g);
    if (g.__tier !== tier) { if (g.__tier && tier > g.__tier) g.__evo = now(); g.__tier = tier; }
    if (!timeFire(g) && !timeMetal(g) && !timeAI(g, tier)) { if (tier <= 2) tubeBasic(g, tier); else timeArt(g, tier); }
    const e = g.__evo ? now() - g.__evo : 9;
    if (e < 2.2 && !g.record.reduced) { const c = g.ctx; c.save(); c.globalAlpha = Math.min(1, (2.2 - e) * 2) * Math.min(1, e * 6); c.font = '800 15px Oxanium, sans-serif'; c.textAlign = 'center'; c.fillStyle = '#ffe9a8'; c.shadowColor = '#ffb24a'; c.shadowBlur = 14; c.fillText('SÜRE ÇEKİRDEĞİ EVRİMLEŞTİ · SEVİYE ' + tier, 270, 198); c.globalCompositeOperation = 'lighter'; c.globalAlpha *= .5 * (1 - e / 2.2); c.fillStyle = '#ffd27a'; c.fillRect(14, 128, 512, 56); c.restore(); }
  }
  function timeArt(g, tier) {
    const c = g.ctx, t = now(), still = g.record.reduced, im = img('Gemini-Boost-Yildirim-Cubugu.jpg');
    const f = Math.max(0, Math.min(1, g.time / NS_T(g)));
    c.save(); c.fillStyle = '#060b12'; c.fillRect(20, 135, 500, 40); c.restore();
    if (!okI(im)) return;
    /* 3 dilim: sol kapak, gerilen orta, sağ kapak — çerçeve src y 350..1175 -> 137..181 */
    const k = 38 / 825, top = 134 - 350 * k, Hh = 1536 * k, X0 = 14, X1 = 526, cap = 562 * k;
    const draw = (alpha, comp, extra) => {
      c.save(); c.globalAlpha = alpha; c.globalCompositeOperation = comp || 'screen'; if (extra) extra();
      c.drawImage(im, 0, 0, 700, 1536, X0 - 138 * k, top, 700 * k, Hh);
      c.drawImage(im, 700, 0, 1365, 1536, X0 - 138 * k + 700 * k, top, (X1 - X0) - 2 * cap + 0, Hh);
      c.drawImage(im, 2065, 0, 687, 1536, X1 - cap, top, 687 * k, Hh);
      c.restore();
    };
    const urgent = g.time <= 5;
    draw(.95, 'screen', urgent && !still ? () => { c.filter = 'hue-rotate(-25deg) saturate(1.5)'; } : tier >= 4 && g.cfg && g.cfg.boss ? () => { c.filter = 'hue-rotate(40deg) saturate(1.3)'; } : null);
    const ix0 = X0 + (270 - 138) * k, ix1 = X1 - (2627 - 2477) * k, iy0 = 134 + (487 - 350) * k, iy1 = 134 + (1038 - 350) * k, hx = ix0 + (ix1 - ix0) * f;
    if (!still) {
      /* akan alev: iç bölgenin kayan kopyası */
      c.save(); c.beginPath(); c.rect(ix0, iy0, hx - ix0, iy1 - iy0); c.clip(); c.globalCompositeOperation = 'lighter'; c.globalAlpha = .38 + .12 * Math.sin(t * 7);
      const off = (t * 340) % 1100;
      c.drawImage(im, 300 + off, 500, 1100, 520, ix0, iy0, (ix1 - ix0) * .5, iy1 - iy0);
      c.drawImage(im, 1400 - off * .7, 500, 1000, 520, ix0 + (ix1 - ix0) * .5, iy0, (ix1 - ix0) * .5, iy1 - iy0);
      c.restore();
      /* şimşek titremesi */
      const r = rndGen(Math.floor(t * 6) * 37 + 1);
      if (r() < (tier >= 4 ? .12 : .06)) draw(.18 + r() * .2, 'lighter');
      const bolts = (urgent ? 3 : 1 + (r() < .5 ? 1 : 0)) + (tier >= 4 ? 2 : 0);
      for (let b = 0; b < bolts; b++) {
        const fromL = r() < .5, x1 = fromL ? X0 + 6 : X1 - 6, y1 = 137 + r() * 30, x2 = x1 + (fromL ? -1 : 1) * (20 + r() * 50) + (r() - .5) * 20, y2 = y1 + (r() - .5) * 70;
        c.save(); c.globalCompositeOperation = 'lighter'; c.beginPath(); c.moveTo(x1, y1); for (let j = 1; j <= 5; j++) c.lineTo(x1 + (x2 - x1) * j / 5 + (r() - .5) * 10, y1 + (y2 - y1) * j / 5 + (r() - .5) * 10);
        c.strokeStyle = fromL ? '#8ff6ff' : '#e49bff'; c.lineWidth = 1.6; c.shadowColor = c.strokeStyle; c.shadowBlur = 10; c.stroke(); c.restore();
      }
    }
    /* harcanan süre: sağdan kararan bölüm */
    if (f < 1) {
      c.save(); c.beginPath(); c.rect(hx, iy0 - 1, ix1 - hx + 1, iy1 - iy0 + 2); c.fillStyle = 'rgba(2,9,20,.93)'; c.fill();
      c.fillStyle = urgent ? '#ff8a8a' : '#ffda92'; c.shadowColor = c.fillStyle; c.shadowBlur = 10; c.fillRect(hx - 1, iy0, 2.5, iy1 - iy0); c.restore();
      for (const q of [1 / 3, 2 / 3]) { const sx = ix0 + (ix1 - ix0) * q; c.fillStyle = 'rgba(7,9,17,.66)'; c.fillRect(sx - 1, iy0, 2, iy1 - iy0); }
    }
    if (urgent && !still) { c.save(); c.globalAlpha = .18 + .18 * Math.sin(t * 14); c.fillStyle = '#ff2a3a'; c.fillRect(ix0, iy0, ix1 - ix0, iy1 - iy0); c.restore(); }
  }
  function glow2(c, x, y, r, col) { const g = c.createRadialGradient(x, y, 0, x, y, r); g.addColorStop(0, col); g.addColorStop(1, 'rgba(0,0,0,0)'); c.fillStyle = g; c.fillRect(x - r, y - r, r * 2, r * 2); }
  let LS = null;
  function lightSweep(c, t) {
    const bg = img('Gemini-Arka-Plan-V1.jpg'); if (!okI(bg)) return;
    if (!LS) { LS = document.createElement('canvas'); LS.width = LS.height = 240; }
    const l = LS.getContext('2d'), sc = 1.05, dx = Math.sin(t * .09) * 9, dy = Math.cos(t * .07) * 6, r = bg.naturalWidth / bg.naturalHeight, w = 960 * r;
    const spots = [[270 + Math.sin(t * .5) * 130, 880 + Math.cos(t * .7) * 50, 'rgba(120,240,255,'], [60 + Math.sin(t * .8) * 20, 820 + Math.sin(t * .6) * 70, 'rgba(255,170,90,'], [480 + Math.cos(t * .7) * 20, 820 + Math.cos(t * .5) * 70, 'rgba(210,140,255,']];
    for (const [px, py, col] of spots) {
      l.setTransform(1, 0, 0, 1, 0, 0); l.globalCompositeOperation = 'source-over'; l.clearRect(0, 0, 240, 240);
      l.translate(120 - px, 120 - py); l.translate(270 + dx, 480 + dy); l.scale(sc, sc); l.translate(-270, -480);
      l.drawImage(bg, (540 - w) / 2, 0, w, 960);
      l.setTransform(1, 0, 0, 1, 0, 0); l.globalCompositeOperation = 'destination-in';
      const g = l.createRadialGradient(120, 120, 0, 120, 120, 120); g.addColorStop(0, 'rgba(0,0,0,1)'); g.addColorStop(1, 'rgba(0,0,0,0)'); l.fillStyle = g; l.fillRect(0, 0, 240, 240);
      c.save(); c.globalCompositeOperation = 'lighter'; c.globalAlpha = .55; c.drawImage(LS, px - 120, py - 120); c.globalAlpha = .25; glow2(c, px, py, 90, col + '.35)'); c.restore();
    }
  }
  /* Bölüm haritası: kilitli bölümlere merak uyandıran efektler */
  const BOSS_IMG = [2, 4, 6, 5, 3, 1, 8, 7]; /* KOR, PRİZMA, MUHAFIZ, AKI, NÖBETÇİ, TUTULMA, SARMAL, NEON ÇEKİRDEK */
  function hueOf(hex) { const n = parseInt(hex.slice(1), 16), r = (n >> 16) / 255, g = (n >> 8 & 255) / 255, b = (n & 255) / 255, mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn; if (!d) return 0; let h = mx === r ? ((g - b) / d) % 6 : mx === g ? (b - r) / d + 2 : (r - g) / d + 4; return (h * 60 + 360) % 360; }
  function mapFX(g) {
    const c = g.ctx, t = g.record.reduced ? 0 : now(), L = NS.levels || [], un = g.record.unlocked || 1;
    for (let s = 0; s < 8; s++) {
      const y = 104 + s * 92, rowOpen = s * 5 < un;
      /* sektör adı parıltısı */
      const sw = ((t * .4 + s * .13) % 2.2) - .2;
      if (sw > 0 && sw < 1) { c.save(); c.globalCompositeOperation = 'lighter'; const gx = 22 + sw * 496, lg = c.createLinearGradient(gx - 40, 0, gx + 40, 0); lg.addColorStop(0, 'rgba(0,0,0,0)'); lg.addColorStop(.5, rowOpen ? 'rgba(130,240,255,.35)' : 'rgba(255,150,80,.3)'); lg.addColorStop(1, 'rgba(0,0,0,0)'); c.fillStyle = lg; c.fillRect(gx - 40, y - 4, 80, 18); c.restore(); }
      if (!rowOpen) { /* kilitli sektörün üstünde süzülen sis */
        c.save(); c.globalAlpha = .22; for (let k = 0; k < 4; k++) { const fx = ((t * (8 + k * 3) + k * 150) % 700) - 80; glow2(c, fx, y + 50 + Math.sin(t + k) * 8, 70, s >= 6 ? 'rgba(170,80,255,.6)' : s >= 4 ? 'rgba(255,110,40,.5)' : 'rgba(120,200,255,.45)'); } c.restore();
      }
      for (let k = 0; k < 5; k++) {
        const i = s * 5 + k, x = 22 + k * 100, ty = y + 18, w = 92, h = 64, open = i < un, boss = L[i] && L[i].boss, cx = x + w / 2, cy = ty + h / 2;
        const bc = boss && NS.bosses && L[i] ? (NS.bosses[L[i].goal] || {}).color || '#ff4d6d' : '#ff4d6d';
        c.save();
        if (i === un - 1) { /* sıradaki: kalp atışı */
          const b = Math.pow(Math.abs(Math.sin(t * 3.2)), 6); c.globalCompositeOperation = 'lighter'; glow2(c, cx, cy, 60 + 14 * b, 'rgba(85,232,239,' + (.25 + .35 * b) + ')');
          c.strokeStyle = '#8ff6ff'; c.globalAlpha = .4 + .6 * b; c.lineWidth = 2; rr(c, x - 2 - 3 * b, ty - 2 - 3 * b, w + 4 + 6 * b, h + 4 + 6 * b, 12); c.stroke();
        } else if (open) { /* tamamlanan: parıltı geçişi */
          const p = ((t * .5 + i * .37) % 3); if (p < 1) { c.beginPath(); c.rect(x, ty, w, h); c.clip(); c.globalCompositeOperation = 'lighter'; const gx = x - 30 + p * (w + 60), lg = c.createLinearGradient(gx - 18, ty, gx + 18, ty + h); lg.addColorStop(0, 'rgba(0,0,0,0)'); lg.addColorStop(.5, 'rgba(255,255,255,.3)'); lg.addColorStop(1, 'rgba(0,0,0,0)'); c.fillStyle = lg; c.fillRect(x, ty, w, h); }
        } else if (boss) { /* kilitli boss: yapay zekâ görseli (4 çeşit), sakin nefes alan ışık */
          const bi = img('boss-kilit-' + BOSS_IMG[s] + '.webp');
          if (okI(bi)) {
            const W2 = w + 14, H2 = W2 * bi.naturalHeight / bi.naturalWidth;
            c.drawImage(bi, cx - W2 / 2, cy - H2 / 2 - 2, W2, H2);
            c.globalCompositeOperation = 'lighter'; c.globalAlpha = .1 + .08 * Math.sin(t * 1.5 + i); c.drawImage(bi, cx - W2 / 2, cy - H2 / 2 - 2, W2, H2);
            c.globalCompositeOperation = 'source-over'; c.globalAlpha = 1;
            c.font = '700 10px "Barlow Condensed", sans-serif'; c.textAlign = 'center'; c.textBaseline = 'middle';
            const lw = c.measureText('BOSS · ???').width + 12; c.fillStyle = 'rgba(0,0,0,.7)'; rr(c, cx - lw / 2, ty + h - 14, lw, 13, 6); c.fill();
            c.fillStyle = '#ffd2dc'; c.fillText('BOSS · ???', cx, ty + h - 7.5);
          }
        } else { /* kilitli normal: sallanan asma kilit, statik parazit; zorluğa göre kor ya da mor duman */
          c.fillStyle = 'rgba(3,6,14,.55)'; c.fillRect(x + 3, ty + 3, w - 6, h - 6);
          const sway = Math.sin(t * 2 + i) * .12; c.translate(cx, cy - 6); c.rotate(sway);
          c.strokeStyle = '#7f93a8'; c.lineWidth = 3; c.beginPath(); c.arc(0, -6, 8, Math.PI, 0); c.stroke();
          c.fillStyle = '#56657c'; rr(c, -11, -6, 22, 17, 3); c.fill(); c.fillStyle = '#0c1220'; c.fillRect(-1.5, 0, 3, 6);
          c.restore(); c.save();
          const d = s >= 6 ? 'mor' : s >= 4 ? 'kor' : 'buz';
          for (let j = 0; j < (d === 'buz' ? 3 : 6); j++) { const r = rndGen(i * 31 + j), life = (t * (.4 + r() * .5) + r()) % 1, px = x + 10 + r() * (w - 20), py = ty + h - life * (h + 8); c.globalAlpha = (1 - life) * .8; c.fillStyle = d === 'kor' ? '#ff9a3c' : d === 'mor' ? '#c784ff' : '#9fdcff'; c.beginPath(); c.arc(px, py, d === 'buz' ? 1 : 1.6, 0, Math.PI * 2); c.fill(); }
          c.globalAlpha = .08 + .06 * Math.random(); c.fillStyle = '#ffffff'; for (let j = 0; j < 4; j++) c.fillRect(x + 4, ty + 4 + Math.random() * (h - 8), w - 8, 1);
        }
        c.restore();
      }
    }
  }
  function menuFX(g) {
    const c = g.ctx, t = now(), p = globalThis.NEON_TEMA || 'A', col = COL[p] || COL.A;
    c.save(); c.globalCompositeOperation = 'lighter';
    for (let k = 0; k < 46; k++) {
      const r = rndGen(k * 7349 + 11), sp = 18 + r() * 40, x0 = r() * 540, ph = r() * 1000;
      const y = 980 - ((t * sp + ph) % 1020), x = x0 + Math.sin(t * (.6 + r()) + k) * 14, sz = .8 + r() * 2.2;
      const hot = r() < .55; c.globalAlpha = Math.min(1, (980 - y) / 200) * (.35 + .5 * Math.abs(Math.sin(t * 3 + k)));
      c.fillStyle = hot ? '#ffb15a' : col[1]; c.beginPath(); c.arc(x, y, sz, 0, Math.PI * 2); c.fill();
    }
    c.globalAlpha = 1;
    /* alev jetleri: yapay zekâ görseli, oyuncu ilerledikçe evrimleşir (turuncu → sarı → mavi plazma → mor şimşek) */
    const un = g.record.unlocked || 1, lv = un <= 10 ? 1 : un <= 20 ? 2 : un <= 30 ? 3 : 4, jet = img('alev-jet-' + (globalThis.NEON_JET || lv) + '.webp');
    if (okI(jet) && !yeniBg()) for (const [nx, dir] of [[40, 1], [500, -1]]) {
      /* canlı alev: tüm görsel üç katman halinde, her katman farklı hızla uzar, kalınlaşır ve titrer */
      const L = 190, iw = jet.naturalWidth, ih = jet.naturalHeight, H0 = L * ih / iw;
      c.save(); c.translate(nx, 704); c.scale(dir, 1); c.globalCompositeOperation = 'lighter';
      for (let layer = 0; layer < 3; layer++) {
        const sp = [3.1, 4.7, 6.3][layer], ph = layer * 2.1 + nx;
        const sx = 1 + .12 * Math.sin(t * sp + ph) + .05 * Math.sin(t * sp * 2.3 + ph);
        const sy = 1 + .18 * Math.sin(t * sp * 1.4 + ph + 1) * (layer ? 1 : .5);
        c.save(); c.rotate(.035 * Math.sin(t * sp * .8 + ph)); c.translate(0, 3 * Math.sin(t * sp * 1.7 + ph));
        c.globalAlpha = [.85, .45, .3][layer]; c.drawImage(jet, 0, -H0 * sy / 2, L * sx * [1, .85, 1.1][layer], H0 * sy);
        c.restore();
      }
      /* uçuşan közler */
      for (let k = 0; k < 18; k++) {
        const r = rndGen(k * 131 + nx), life = (t * (.9 + r() * .8) + r()) % 1, x = L * (.3 + .9 * life), y = (r() - .5) * 30 * life - 14 * life * life + Math.sin(t * 7 + k) * 4;
        c.globalAlpha = (1 - life) * .9; c.fillStyle = r() < .5 ? '#ffd27a' : '#ff8a3a'; c.beginPath(); c.arc(x, y, 1.6 * (1 - life) + .6, 0, Math.PI * 2); c.fill();
      }
      c.globalAlpha = 1; glow2(c, 6, 0, 34 + 5 * Math.sin(t * 19), 'rgba(255,190,90,.6)');
      c.restore();
    }
    /* makinede 3B ışık geçişi: arka planın parlak kopyası gezen bir ışık lekesiyle */
    if (!yeniBg()) lightSweep(c, t);
    c.globalAlpha = 1;
    for (let k = 0; k < 6; k++) {
      const r = rndGen(k * 4211 + 5), vert = k % 2 === 0, base = vert ? (k < 3 ? 16 + r() * 30 : 494 + r() * 30) : 120 + r() * 700;
      const pos = ((t * (60 + r() * 80) + r() * 900) % 960);
      const x = vert ? base : (pos / 960) * 540, y = vert ? pos : base;
      const gr = c.createRadialGradient(x, y, 0, x, y, 10); gr.addColorStop(0, col[2]); gr.addColorStop(.4, col[1]); gr.addColorStop(1, 'rgba(0,0,0,0)');
      c.globalAlpha = .55; c.fillStyle = gr; c.fillRect(x - 10, y - 10, 20, 20);
    }
    c.globalAlpha = 1;
    const sw = ((t * .35) % 1.6) - .3;
    if (sw > 0 && sw < 1) { c.save(); c.beginPath(); c.rect(0, 22, 540, 86); c.clip(); const sx = sw * 700 - 80, lg = c.createLinearGradient(sx - 60, 0, sx + 60, 0); lg.addColorStop(0, 'rgba(255,255,255,0)'); lg.addColorStop(.5, 'rgba(200,250,255,.22)'); lg.addColorStop(1, 'rgba(255,255,255,0)'); c.fillStyle = lg; c.fillRect(sx - 60, 22, 120, 86); c.restore(); }
    const rnd = rndGen(Math.floor(t * 4));
    if (rnd() < .03) { c.globalAlpha = .6; c.beginPath(); let x = 60 + rnd() * 80, y = 30; c.moveTo(x, y); for (let j = 0; j < 7; j++) { x += 40 + rnd() * 30; y = 30 + rnd() * 70; c.lineTo(x, y); } c.strokeStyle = col[2]; c.shadowColor = col[1]; c.shadowBlur = 14; c.lineWidth = 1.3; c.stroke(); }
    c.restore();
  }
  /* ---------- Ana sayfa üst yazı stilleri (NEON_MENU = 1, 2, 3) ---------- */
  const textPrev3 = P.text;
  P.text = function (t, x, y, size) {
    if (this.state === 'menu' && globalThis.NEON_MENU && (y === 176 || y === 224 || y === 259) && x === 270) return;
    return textPrev3.apply(this, arguments);
  };
  function fontSet(c, w, s, fam) { c.font = w + ' ' + s + 'px ' + (fam || 'Oxanium') + ', sans-serif'; }
  function chips(c, list, y, col, t) {
    fontSet(c, 700, 15, '"Barlow Condensed"'); const pad = 12, gap = 8;
    const ws = list.map(s => c.measureText(s).width + pad * 2), tot = ws.reduce((a, b) => a + b, 0) + gap * (list.length - 1);
    let x = 270 - tot / 2;
    list.forEach((s, i) => {
      rr(c, x, y - 13, ws[i], 26, 13); c.fillStyle = 'rgba(8,20,30,.85)'; c.fill();
      c.strokeStyle = col[1]; c.globalAlpha = .45 + .35 * Math.max(0, Math.sin(t * 2 - i * .8)); c.lineWidth = 1.2; c.stroke(); c.globalAlpha = 1;
      c.fillStyle = '#e8fbff'; c.textAlign = 'center'; c.textBaseline = 'middle'; c.fillText(s, x + ws[i] / 2, y + 1); x += ws[i] + gap;
    });
  }
  function menuText(g) {
    if (globalThis.NEON_MENU === undefined) globalThis.NEON_MENU = 1;
    const v = globalThis.NEON_MENU; if (!v) return;
    g.hits.push({ x: 40, y: 130, w: 460, h: 160, name: 'menu-stil', action: () => { globalThis.NEON_MENU = globalThis.NEON_MENU % 3 + 1; } });
    if (globalThis.NEON_MENU_OVR && globalThis.NEON_MENU_OVR(g, v)) return;
    const c = g.ctx, t = now(), col = COL[globalThis.NEON_TEMA || 'A'] || COL.A, still = g.record.reduced;
    c.save(); c.textAlign = 'center'; c.textBaseline = 'middle';
    if (v === 1) {
      /* Hologram panel */
      const x = 46, y = 138, w = 448, h = 148;
      rr(c, x, y, w, h, 14); c.fillStyle = 'rgba(6,16,26,.72)'; c.fill();
      c.strokeStyle = col[1]; c.globalAlpha = .35; c.lineWidth = 1; c.stroke(); c.globalAlpha = 1;
      c.strokeStyle = col[1]; c.lineWidth = 3; c.shadowColor = col[1]; c.shadowBlur = 10;
      for (const [cx, cy, dx, dy] of [[x, y, 1, 1], [x + w, y, -1, 1], [x, y + h, 1, -1], [x + w, y + h, -1, -1]]) { c.beginPath(); c.moveTo(cx + dx * 22, cy); c.lineTo(cx, cy); c.lineTo(cx, cy + dy * 22); c.stroke(); }
      c.shadowBlur = 0;
      if (!still) { const sy = y + ((t * 60) % h); const lg = c.createLinearGradient(0, sy - 10, 0, sy + 10); lg.addColorStop(0, 'rgba(0,0,0,0)'); lg.addColorStop(.5, 'rgba(160,240,255,.12)'); lg.addColorStop(1, 'rgba(0,0,0,0)'); c.fillStyle = lg; c.fillRect(x, sy - 10, w, 20); }
      fontSet(c, 700, 13, '"Barlow Condensed"'); c.fillStyle = col[1]; c.fillText('◆  GÖREV BRİFİNGİ  ◆', 270, y + 22);
      fontSet(c, 800, 30); const gr = c.createLinearGradient(0, y + 40, 0, y + 76); gr.addColorStop(0, '#ffffff'); gr.addColorStop(1, col[1]);
      c.fillStyle = gr; c.shadowColor = col[0]; c.shadowBlur = 14; c.fillText('MANTIĞI ÇÖZ.', 270, y + 56); c.shadowBlur = 0;
      fontSet(c, 600, 17, '"Barlow Condensed"'); c.fillStyle = '#b9cde0'; c.fillText('Yanlış adaylara dokun, doğru rakamı koru.', 270, y + 88);
      chips(c, ['4×4', '30 SN', '40 BÖLÜM', '8 BOSS'], y + 122, col, t);
    } else if (v === 2) {
      /* Reaktör: iki satır, ikincisi alev */
      fontSet(c, 800, 36); c.fillStyle = '#f4fbff'; c.shadowColor = col[1]; c.shadowBlur = 12; c.fillText('MANTIĞI ÇÖZ.', 270, 160); c.shadowBlur = 0;
      fontSet(c, 800, 36); const fg = c.createLinearGradient(0, 186, 0, 222); fg.addColorStop(0, '#fff3b0'); fg.addColorStop(.45, '#ffaa2b'); fg.addColorStop(1, '#ff3d00');
      c.fillStyle = fg; c.shadowColor = '#ff5a00'; c.shadowBlur = still ? 10 : 14 + 8 * Math.abs(Math.sin(t * 6)); c.fillText('ATEŞİ YÜKSELT.', 270, 204); c.shadowBlur = 0;
      const line = '> Yanlış adaylara dokun; doğru rakamı koru.', n = still ? line.length : Math.min(line.length, Math.floor(((t % 9) / 3) * line.length));
      fontSet(c, 500, 15, 'ui-monospace, Consolas, monospace'); c.textAlign = 'left'; c.fillStyle = col[1];
      const lw = c.measureText(line).width, lx = 270 - lw / 2; c.fillText(line.slice(0, n) + ((Math.floor(t * 2) % 2 && !still) ? '▌' : ''), lx, 244);
      c.textAlign = 'center'; fontSet(c, 700, 15, '"Barlow Condensed"'); c.fillStyle = '#ffcf7a'; c.fillText('4×4   •   30 SANİYE   •   40 BÖLÜM   •   8 BOSS', 270, 274);
    } else {
      /* Glitch: büyük ve sert */
      const gl = still ? 0 : (Math.sin(t * 3.1) > .93 ? 4 : 0) + (Math.sin(t * 7.7) > .97 ? 3 : 0);
      fontSet(c, 800, 42);
      if (gl) { c.globalCompositeOperation = 'lighter'; c.fillStyle = 'rgba(255,40,120,.8)'; c.fillText('MANTIĞI ÇÖZ', 270 - gl, 170); c.fillStyle = 'rgba(40,220,255,.8)'; c.fillText('MANTIĞI ÇÖZ', 270 + gl, 170); c.globalCompositeOperation = 'source-over'; }
      c.fillStyle = '#ffffff'; c.shadowColor = col[1]; c.shadowBlur = 18; c.fillText('MANTIĞI ÇÖZ', 270, 170); c.shadowBlur = 0;
      c.fillStyle = col[1]; c.fillRect(170, 198, 200, 2);
      fontSet(c, 700, 16, '"Barlow Condensed"'); c.fillStyle = '#ffb35a';
      const sp = 'R E A K T Ö R Ü   A T E Ş L E'; c.fillText(sp, 270, 218);
      fontSet(c, 600, 16, '"Barlow Condensed"'); c.fillStyle = '#a9bfd6'; c.fillText('Yanlış adaylara dokun · doğru rakamı koru', 270, 248);
      fontSet(c, 800, 14); c.fillStyle = col[1]; c.fillText('4×4   |   30 SN   |   40 BÖLÜM   |   8 BOSS', 270, 276);
    }
    c.restore();
  }
  /* ---------- Ana sayfa uzay katmanı: yıldızlar, kayan yıldızlar, gezegenler, aurora ---------- */
  function planet(c, x, y, r, c1, c2, glow, t, ring) {
    c.save();
    const ag = c.createRadialGradient(x, y, r * .8, x, y, r * 1.7); ag.addColorStop(0, glow); ag.addColorStop(1, 'rgba(0,0,0,0)');
    c.fillStyle = ag; c.fillRect(x - r * 2, y - r * 2, r * 4, r * 4);
    if (ring) { c.save(); c.translate(x, y); c.rotate(-.35); c.scale(1, .28); c.beginPath(); c.arc(0, 0, r * 1.75, Math.PI, Math.PI * 2); c.strokeStyle = ring; c.lineWidth = r * .22; c.globalAlpha = .55; c.stroke(); c.restore(); }
    const pg = c.createRadialGradient(x - r * .4, y - r * .45, r * .1, x, y, r); pg.addColorStop(0, c1); pg.addColorStop(1, c2);
    c.beginPath(); c.arc(x, y, r, 0, Math.PI * 2); c.fillStyle = pg; c.fill();
    c.save(); c.clip(); c.globalAlpha = .22; c.strokeStyle = '#ffffff'; c.lineWidth = r * .08;
    for (let k = -2; k <= 2; k++) { c.beginPath(); c.ellipse(x + ((t * .25 * r + k * r * .7) % (r * 2.2)) - r * 1.1, y + k * r * .32, r * 1.1, r * .09, 0, 0, Math.PI * 2); c.stroke(); }
    c.globalAlpha = .55; const sh = c.createRadialGradient(x + r * .55, y + r * .5, r * .2, x + r * .3, y + r * .3, r * 1.3); sh.addColorStop(0, 'rgba(0,0,0,.85)'); sh.addColorStop(1, 'rgba(0,0,0,0)'); c.fillStyle = sh; c.fillRect(x - r, y - r, r * 2, r * 2);
    c.restore();
    if (ring) { c.save(); c.translate(x, y); c.rotate(-.35); c.scale(1, .28); c.beginPath(); c.arc(0, 0, r * 1.75, 0, Math.PI); c.strokeStyle = ring; c.lineWidth = r * .22; c.globalAlpha = .7; c.stroke(); c.restore(); }
    c.restore();
  }
  function spaceLayer(g) {
    const c = g.ctx, t = g.record.reduced ? 0 : now();
    c.save();
    /* makineyi uzaya doğru karart */
    const dk = c.createLinearGradient(0, 0, 0, 690); dk.addColorStop(0, 'rgba(4,6,20,.82)'); dk.addColorStop(.75, 'rgba(4,6,20,.55)'); dk.addColorStop(1, 'rgba(4,6,20,0)'); c.fillStyle = dk; c.fillRect(0, 0, 540, 690);
    /* aurora */
    for (let k = 0; k < 3; k++) {
      c.beginPath(); c.moveTo(0, 330);
      for (let x = 0; x <= 540; x += 20) c.lineTo(x, 250 + k * 22 + Math.sin(x * .012 + t * .4 + k) * 26 + Math.sin(x * .03 - t * .25) * 10);
      c.lineTo(540, 330); c.closePath();
      const ag = c.createLinearGradient(0, 220, 0, 330); ag.addColorStop(0, ['rgba(80,255,210,.10)', 'rgba(120,160,255,.08)', 'rgba(220,120,255,.07)'][k]); ag.addColorStop(1, 'rgba(0,0,0,0)');
      c.fillStyle = ag; c.globalCompositeOperation = 'lighter'; c.fill();
    }
    /* yıldızlar */
    for (let k = 0; k < 90; k++) {
      const r = rndGen(k * 2654435 + 17), x = r() * 540, y = 20 + r() * 640, tw = .25 + .75 * Math.abs(Math.sin(t * (1 + r() * 2.5) + k));
      c.globalAlpha = tw * (.35 + r() * .5); c.fillStyle = r() < .2 ? '#ffd9a8' : '#dff4ff'; const sz = r() < .1 ? 1.8 : .9;
      c.fillRect(x, y, sz, sz); if (sz > 1 && tw > .8) { c.fillRect(x - 3, y + .5, 7, .6); c.fillRect(x + .5, y - 3, .6, 7); }
    }
    c.globalAlpha = 1; c.globalCompositeOperation = 'source-over';
    /* yan gezegenler */
    const dx = Math.sin(t * .05) * 6, dy = Math.cos(t * .04) * 4;
    planet(c, 14 + Math.sin(t * .3) * 14, 300 + Math.sin(t * .2) * 40, 26, '#b8f3ff', '#1d3e66', 'rgba(110,220,255,.32)', t, null);
    planet(c, 528 - Math.sin(t * .25) * 12, 600 + Math.cos(t * .22) * 50, 16, '#e2c8ff', '#3b2470', 'rgba(190,140,255,.3)', t, null);
    /* kayan yıldızlar */
    if (!g.record.reduced) shooting(c, t, 2, [0, 110, 540, 560]);
    if (false) for (let k = 0; k < 3; k++) {
      const per = 5 + k * 2.3, ph = (t + k * 3.1) % per; if (ph > 1.1) continue;
      const r = rndGen(Math.floor((t + k * 3.1) / per) * 131 + k), x0 = 60 + r() * 420, y0 = 20 + r() * 220, len = 120 + r() * 90, ang = .45 + r() * .35;
      const p = ph / 1.1, hx = x0 + Math.cos(ang) * len * p * 1.6, hy = y0 + Math.sin(ang) * len * p * 1.6;
      const tx = hx - Math.cos(ang) * len * (.4 + p * .6), ty = hy - Math.sin(ang) * len * (.4 + p * .6);
      const lg = c.createLinearGradient(tx, ty, hx, hy); lg.addColorStop(0, 'rgba(255,255,255,0)'); lg.addColorStop(1, 'rgba(230,250,255,' + (1 - p * .8) + ')');
      c.strokeStyle = lg; c.lineWidth = 2; c.lineCap = 'round'; c.beginPath(); c.moveTo(tx, ty); c.lineTo(hx, hy); c.stroke();
      c.fillStyle = '#ffffff'; c.globalAlpha = 1 - p * .8; c.beginPath(); c.arc(hx, hy, 2, 0, Math.PI * 2); c.fill(); c.globalAlpha = 1;
    }
    c.restore();
  }
  function shooting(c, t, n, box) {
    for (let k = 0; k < n; k++) {
      const per = 4 + k * 2.3, ph = (t + k * 2.7) % per; if (ph > 1) continue;
      const r = rndGen(Math.floor((t + k * 2.7) / per) * 131 + k * 7), x0 = box[0] + r() * box[2] * .7, y0 = box[1] + r() * box[3] * .5, len = 70 + r() * 70, ang = .25 + r() * .3;
      const p = ph, hx = x0 + Math.cos(ang) * len * p * 1.8, hy = y0 + Math.sin(ang) * len * p * 1.8;
      const tx = hx - Math.cos(ang) * len * (.4 + p * .6), ty = hy - Math.sin(ang) * len * (.4 + p * .6);
      const lg = c.createLinearGradient(tx, ty, hx, hy); lg.addColorStop(0, 'rgba(255,255,255,0)'); lg.addColorStop(1, 'rgba(230,250,255,' + (1 - p * .8) + ')');
      c.strokeStyle = lg; c.lineWidth = 1.8; c.lineCap = 'round'; c.beginPath(); c.moveTo(tx, ty); c.lineTo(hx, hy); c.stroke();
      c.fillStyle = '#fff'; c.globalAlpha = 1 - p * .8; c.beginPath(); c.arc(hx, hy, 1.8, 0, Math.PI * 2); c.fill(); c.globalAlpha = 1;
    }
  }
  globalThis.NEON_BANNER = function (g, c) {
    if (!pal()) { c.fillStyle = '#070b1a'; c.fillRect(0, 22, 540, 86); return; }
    const t = g.record.reduced ? 0 : now();
    c.save(); c.beginPath(); c.rect(0, 22, 540, 86); c.clip();
    const bg = c.createLinearGradient(0, 22, 0, 108); bg.addColorStop(0, '#060818'); bg.addColorStop(1, '#0c1030'); c.fillStyle = bg; c.fillRect(0, 22, 540, 86);
    const neb = c.createRadialGradient(150, 70, 5, 150, 70, 170); neb.addColorStop(0, 'rgba(150,70,255,.22)'); neb.addColorStop(1, 'rgba(0,0,0,0)'); c.fillStyle = neb; c.fillRect(0, 22, 540, 86);
    const neb2 = c.createRadialGradient(400, 40, 5, 400, 40, 160); neb2.addColorStop(0, 'rgba(40,200,255,.16)'); neb2.addColorStop(1, 'rgba(0,0,0,0)'); c.fillStyle = neb2; c.fillRect(0, 22, 540, 86);
    for (let k = 0; k < 60; k++) { const r = rndGen(k * 911 + 3), x = (r() * 560 - t * (2 + r() * 4)) % 560, y = 24 + r() * 82; c.globalAlpha = .3 + .7 * Math.abs(Math.sin(t * (1 + r() * 3) + k)); c.fillStyle = r() < .2 ? '#ffd9a8' : '#e6f6ff'; c.fillRect((x + 560) % 560, y, r() < .12 ? 1.6 : .9, r() < .12 ? 1.6 : .9); }
    c.globalAlpha = 1;
    const PX = 470 + Math.sin(t * .18) * 40, PY = 70 + Math.sin(t * .27) * 6;
    const mA = t * .9, mX = PX + Math.cos(mA) * 58, mY = PY + Math.sin(mA) * 14, behind = Math.sin(mA) < 0;
    if (behind) planet(c, mX, mY, 7, '#e8f6ff', '#4a5a78', 'rgba(200,230,255,.3)', t, null);
    planet(c, PX, PY, 32, '#ffcf9a', '#6b2f5a', 'rgba(255,140,90,.3)', t, 'rgba(255,214,170,.9)');
    if (!behind) planet(c, mX, mY, 7, '#e8f6ff', '#4a5a78', 'rgba(200,230,255,.3)', t, null);
    planet(c, 44 + Math.sin(t * .23) * 18, 50 + Math.sin(t * .4) * 10, 13, '#b8f3ff', '#1d3e66', 'rgba(110,220,255,.35)', t, null);
    if (!g.record.reduced) shooting(c, t, 3, [0, 22, 540, 86]);
    c.restore();
    c.fillStyle = 'rgba(95,240,245,.35)'; c.fillRect(0, 107, 540, 1);
  };
  const atmosPrev2 = P.sceneAtmosphere;
  P.sceneAtmosphere = function () {
    const r = atmosPrev2.apply(this, arguments);
    if ((this.state === 'menu' || this.state === 'select') && pal() && globalThis.NEON_UZAY !== false) spaceLayer(this);
    return r;
  };
  const rectPrevD = P.rect;
  P.rect = function (x, y, w, h) { if (this.__defer && y === 147 && h === 12) return; return rectPrevD.apply(this, arguments); };
  const textPrevD = P.text;
  P.text = function (t, x, y) {
    if (this.__defer && y >= 112 && y <= 196) { this.__defer.push(arguments); return; }
    return textPrevD.apply(this, arguments);
  };
  const renderPrev = P.render;
  P.render = function () {
    this.__fxb = [];
    this.__defer = this.cfg && ['playing', 'chain', 'paused'].includes(this.state) && pal() ? [] : null;
    const r = renderPrev.apply(this, arguments);
    const dq = this.__defer; this.__defer = null;
    if (dq) { timeTube(this); for (const a of dq) { const b = [...a]; if (b[2] === 130) b[2] = globalThis.NEON_CEH ? 108 : atesOk() ? 112 : metalOk() ? 108 : 117; else if (b[2] === 187) b[2] = globalThis.NEON_CEH ? 218 : atesOk() ? 214 : metalOk() ? 222 : 205; textPrevD.apply(this, b); } }
    if (!pal()) return r;
    if (this.record.reduced) { if (this.state === 'menu') menuText(this); return r; }
    if (this.state === 'menu') { menuText(this); menuFX(this); const c = this.ctx; c.save(); c.font = '700 11px Oxanium, sans-serif'; c.fillStyle = 'rgba(160,190,210,.6)'; c.textAlign = 'right'; c.fillText('V' + (NS.SURUM || '1.8'), 530, 952); c.restore(); }
    if (this.state === 'select') mapFX(this);
    if (!metalOk() && !globalThis.NEON_CEH) buttonsFX(this);
    return r;
  };

  /* ---------- Yeni ana ekran arka planı (reaktör odası) ---------- */
  const yeniBg = () => okI(img('ana-ekran.webp')) && globalThis.NEON_ANA_BG !== false;
  const atmosPrev3 = P.sceneAtmosphere;
  P.sceneAtmosphere = function () {
    if (!(this.state === 'menu' || this.state === 'select' || this.state === 'brief') || !yeniBg()) return atmosPrev3.apply(this, arguments);
    const c = this.ctx, t = this.record.reduced ? 0 : now(), bg = img('ana-ekran.webp');
    const z = 1.04 + .015 * Math.sin(t * .12), W = 540 * z, H = W * bg.naturalHeight / bg.naturalWidth;
    c.save(); c.drawImage(bg, 270 - W / 2 + Math.sin(t * .09) * 5, 480 - H / 2 + Math.cos(t * .07) * 4, W, H);
    if (atesOk()) { c.save(); c.globalCompositeOperation = 'color'; c.globalAlpha = .6; c.fillStyle = '#c0391a'; c.fillRect(0, 0, 540, 960); c.restore(); }
    c.globalCompositeOperation = 'lighter';
    /* reaktör ızgarası ve borular nefes alır */
    const b = .5 + .5 * Math.sin(t * 1.4);
    glow2(c, 270, 445, 150 + 20 * b, (atesOk() ? 'rgba(255,110,40,' : 'rgba(170,90,255,') + (.10 + .12 * b) + ')');
    for (const px of [70, 470]) glow2(c, px, 448, 55 + 10 * Math.sin(t * 2.2 + px), (atesOk() ? 'rgba(255,140,60,' : 'rgba(220,120,255,') + (.18 + .1 * Math.sin(t * 2.2 + px)) + ')');
    /* ortadan inen enerji ışını */
    const lg = c.createLinearGradient(262, 0, 278, 0); lg.addColorStop(0, 'rgba(0,0,0,0)'); lg.addColorStop(.5, 'rgba(230,180,255,' + (.25 + .2 * b) + ')'); lg.addColorStop(1, 'rgba(0,0,0,0)'); c.fillStyle = lg; c.fillRect(262, 590, 16, 110);
    /* yıldız parıltısı (kubbe) */
    for (let k = 0; k < 40; k++) { const r = rndGen(k * 977 + 5), x = r() * 540, y = 10 + r() * 230, a = Math.max(0, Math.sin(t * (1 + r() * 2) + k)); c.globalAlpha = a * .8; c.fillStyle = '#eaf6ff'; c.fillRect(x, y, 1.4, 1.4); }
    c.globalAlpha = 1; c.globalCompositeOperation = 'source-over';
    /* düğmeler okunsun diye orta bölge hafif karartılır */
    const dk = c.createLinearGradient(0, 120, 0, 960); dk.addColorStop(0, 'rgba(4,6,18,0)'); dk.addColorStop(.25, 'rgba(4,6,18,' + (this.state === 'menu' ? .35 : .62) + ')'); dk.addColorStop(1, 'rgba(4,6,18,' + (this.state === 'menu' ? .3 : .62) + ')');
    c.fillStyle = dk; c.fillRect(0, 0, 540, 960);
    if (!this.record.reduced) shooting(c, t, 2, [0, 20, 540, 220]);
    c.restore();
  };

  /* ---------- METAL tarzı (ChatGPT): süre çubuğu + canlı alev, 3B hücreler, 3B tuşlar ---------- */
  const metalOk = () => globalThis.NEON_METAL !== false && okI(img('metal-cubuk.webp'));
  function shadowBox(c, x, y, w, h, r, lift, a) { c.save(); c.shadowColor = 'rgba(0,0,0,' + (a || .75) + ')'; c.shadowBlur = 10 + lift * 2; c.shadowOffsetY = 4 + lift; rr(c, x, y, w, h, r); c.fillStyle = 'rgba(8,6,6,.95)'; c.fill(); c.restore(); }
  function flameTongue(c, x, y, w, h, t, k) {
    const g = c.createLinearGradient(0, y, 0, y - h); g.addColorStop(0, 'rgba(255,90,10,.95)'); g.addColorStop(.35, 'rgba(255,170,40,.8)'); g.addColorStop(.75, 'rgba(255,230,140,.35)'); g.addColorStop(1, 'rgba(255,255,220,0)');
    const sw = Math.sin(t * 9 + k * 1.7) * w * .5;
    c.fillStyle = g; c.beginPath(); c.moveTo(x - w, y); c.quadraticCurveTo(x - w * .6 + sw * .3, y - h * .55, x + sw, y - h); c.quadraticCurveTo(x + w * .6 + sw * .3, y - h * .5, x + w, y); c.closePath(); c.fill();
  }
  function timeMetal(g) {
    if (!metalOk()) return false;
    const c = g.ctx, t = g.record.reduced ? 0 : now(), im = img('metal-cubuk.webp'), f = Math.max(0, Math.min(1, g.time / NS_T(g))), urgent = g.time <= 5;
    const W = 470, k = W / 900, X = 35, Y = 162 - 185 * k / 2, ax = X + 128 * k, ay = Y + 72 * k, aw = (816 - 128) * k, ah = (120 - 72) * k, hx = ax + aw * f;
    const bc = g.cfg && g.cfg.boss && NS.bosses && NS.bosses[g.cfg.goal] ? NS.bosses[g.cfg.goal].color : null;
    c.save();
    /* kanal */
    c.save(); rr(c, ax, ay, aw, ah, ah / 2); c.fillStyle = '#0b0605'; c.fill(); c.clip();
    if (f > 0) {
      const lg = c.createLinearGradient(0, ay, 0, ay + ah); lg.addColorStop(0, urgent ? '#ff6a5a' : '#ffd36a'); lg.addColorStop(.45, urgent ? '#ff1f2a' : (bc || '#ff7a1a')); lg.addColorStop(1, '#5a0d02');
      c.fillStyle = lg; c.fillRect(ax, ay, hx - ax, ah);
      /* akan lav damarları */
      c.globalCompositeOperation = 'lighter';
      for (let j = 0; j < 3; j++) { c.beginPath(); for (let x = ax; x <= hx; x += 5) { const yy = ay + ah * (.3 + .2 * j) + Math.sin(x * .06 - t * (3 + j) + j) * ah * .12; x === ax ? c.moveTo(x, yy) : c.lineTo(x, yy); } c.strokeStyle = 'rgba(255,240,180,' + (.28 - j * .07) + ')'; c.lineWidth = 2; c.stroke(); }
    }
    c.restore();
    /* çerçeve: derinlik için gölge, sonra görsel */
    c.save(); c.shadowColor = 'rgba(0,0,0,.8)'; c.shadowBlur = 14; c.shadowOffsetY = 6; c.globalCompositeOperation = 'lighten'; c.drawImage(im, X, Y, W, 185 * k); c.restore();
    /* canlı alevler: dolu kısmın üstünden çerçevenin dışına taşar */
    if (f > 0 && !g.record.reduced) {
      c.save(); c.globalCompositeOperation = 'lighter';
      for (let L2 = 0; L2 < 2; L2++) {
        const step = L2 ? 17 : 26, n = Math.max(2, Math.floor((hx - ax) / step));
        for (let j = 0; j < n; j++) { const x = ax + 8 + j * (hx - ax - 16) / Math.max(1, n - 1) + (L2 ? 6 : 0), h = (urgent ? 30 : 20) * (L2 ? .7 : 1) + 12 * Math.abs(Math.sin(t * (4 + L2 * 2) + j * 1.9)) + 6 * Math.sin(t * 11 + j * 2.7); c.globalAlpha = L2 ? .55 : .8; flameTongue(c, x, ay + ah * .5, L2 ? 8 : 13, h, t * (L2 ? 1.3 : 1), j + L2 * 50); }
      }
      c.globalAlpha = 1;
      flameTongue(c, hx - 4, ay + ah * .5, 10, 30 + 8 * Math.sin(t * 11), t, 99);
      glow2(c, hx, ay + ah / 2, 34 + 6 * Math.sin(t * 15), 'rgba(255,200,90,.55)');
      for (let j = 0; j < 14; j++) { const r = rndGen(j * 71 + 3), life = (t * (.8 + r() * .9) + r()) % 1, x = ax + r() * (hx - ax), y = ay - life * 46; c.globalAlpha = (1 - life); c.fillStyle = r() < .5 ? '#ffcf6a' : '#ff7a2a'; c.fillRect(x + Math.sin(t * 5 + j) * 4, y, 2, 2); }
      c.restore();
    }
    if (f < 1) { c.fillStyle = 'rgba(255,230,180,.8)'; c.fillRect(hx - 1, ay + 2, 2, ah - 4); }
    c.restore();
    return true;
  }

  /* ---------- ATEŞ tarzı (kullanıcı görselleri): dikenli süre çubuğu + ilerleyen alev, çatlak lav hücreler ---------- */
  const atesOk = () => globalThis.NEON_ATES !== false && okI(img('ates-cubuk.webp'));
  function timeFire(g) {
    if (!atesOk()) return false;
    const c = g.ctx, t = g.record.reduced ? 0 : now(), fr = img('ates-cubuk.webp'), f = Math.max(0, Math.min(1, g.time / NS_T(g))), urgent = g.time <= 5;
    const lv = g.cfg && g.cfg.boss ? 4 : Math.min(4, Math.max(1, Math.ceil((g.level || 1) / 10))), jet = img('ates-' + (urgent ? 1 : lv) + '.webp');
    const W = 530, k = W / 900, X = 5, Y = 162 - 121 * k / 2, ax = X + 188 * k, ay = Y + 40 * k, aw = (702 - 188) * k, ah = (70 - 40) * k, hx = ax + aw * f;
    c.save();
    c.save(); rr(c, ax - 4, ay, aw + 8, ah, ah / 2); c.fillStyle = '#070303'; c.fill(); c.restore();
    /* alev: kanalın içinde soldan sağa ilerler, ucu (hx) en geniş yanan kısım */
    if (f > 0 && okI(jet)) {
      c.save(); c.beginPath(); c.rect(ax - 6, ay - 26, hx - ax + 34, ah + 52); c.clip(); c.globalCompositeOperation = 'lighter';
      const len = Math.max(30, hx - ax + 26), iw = jet.naturalWidth, ih = jet.naturalHeight;
      for (let L = 0; L < 3; L++) {
        const sp = [2.7, 4.1, 5.9][L], ph = L * 1.9, sx = 1 + .05 * Math.sin(t * sp + ph), sy = 1 + .22 * Math.sin(t * sp * 1.3 + ph);
        const H = ah * 2.6 * sy * [1, .8, 1.2][L];
        c.globalAlpha = [.95, .55, .35][L];
        /* doku akışı: kaynak bölge sağa doğru kayar, ateş hareket ediyor görünür */
        const off = ((t * (40 + L * 25)) % (iw * .25));
        c.drawImage(jet, off, 0, iw - off, ih, ax - 6, ay + ah / 2 - H / 2 + 2 * Math.sin(t * sp * 2 + ph), len * sx, H);
      }
      c.restore();
    }
    /* çerçeve en üstte, gölgeli */
    c.save(); c.shadowColor = 'rgba(0,0,0,.85)'; c.shadowBlur = 14; c.shadowOffsetY = 6; c.globalCompositeOperation = 'lighten'; c.drawImage(fr, X, Y, W, 121 * k); c.restore();
    /* canlı alev dilleri: çerçevenin üstüne taşar, uç kısım en gür yanar, közler yükselir */
    if (f > 0 && !g.record.reduced) {
      c.save(); c.globalCompositeOperation = 'lighter';
      const fc = urgent ? ['#ff2a1a', '#ff8a5a'] : lv === 3 ? ['#2a7bff', '#9fdcff'] : lv === 4 ? ['#9a3bff', '#e2b0ff'] : ['#ff5a0a', '#ffd06a'];
      const n = Math.max(3, Math.floor((hx - ax) / 18));
      for (let j = 0; j < n; j++) {
        const q = j / Math.max(1, n - 1), x = ax + 6 + q * (hx - ax - 6), near = Math.pow(q, 1.6);
        const h = 8 + 26 * near + 9 * Math.abs(Math.sin(t * (5 + j % 3) + j * 2.3)) + 5 * Math.sin(t * 13 + j);
        const gtt = c.createLinearGradient(0, ay, 0, ay - h); gtt.addColorStop(0, fc[0]); gtt.addColorStop(.5, fc[1]); gtt.addColorStop(1, 'rgba(255,255,220,0)');
        const sw = Math.sin(t * 7 + j * 1.9) * 5, wd = 5 + 6 * near;
        c.globalAlpha = .55 + .35 * near; c.fillStyle = gtt; c.beginPath(); c.moveTo(x - wd, ay + 3); c.quadraticCurveTo(x - wd * .5 + sw * .4, ay - h * .5, x + sw, ay - h); c.quadraticCurveTo(x + wd * .5 + sw * .4, ay - h * .5, x + wd, ay + 3); c.fill();
      }
      /* uçtaki ateş topu */
      const r0 = 26 + 6 * Math.sin(t * 17) + 4 * Math.sin(t * 29);
      c.globalAlpha = 1; glow2(c, hx, ay + ah / 2, r0 * 1.8, urgent ? 'rgba(255,60,40,.55)' : 'rgba(255,170,60,.55)'); glow2(c, hx, ay + ah / 2, r0 * .7, 'rgba(255,250,220,.9)');
      for (let j = 0; j < 22; j++) { const rr2 = rndGen(j * 53 + 11), life = (t * (.7 + rr2() * 1.1) + rr2()) % 1, x = ax + (hx - ax) * Math.pow(rr2(), .6) + Math.sin(t * 4 + j) * 6, y = ay - life * (40 + 40 * rr2()); c.globalAlpha = (1 - life) * .95; c.fillStyle = rr2() < .5 ? fc[1] : '#fff2c0'; c.beginPath(); c.arc(x, y, 1.8 * (1 - life) + .6, 0, Math.PI * 2); c.fill(); }
      c.restore();
    }
    /* çerçevedeki lav damarları nefes alır */
    if (!g.record.reduced) { c.save(); c.globalCompositeOperation = 'lighter'; c.globalAlpha = (urgent ? .35 : .12) + .1 * Math.sin(t * (urgent ? 9 : 2)); c.drawImage(fr, X, Y, W, 121 * k); c.restore(); }
    c.restore();
    return true;
  }
  function tileFire(c, x, y, w, h, st, tt, lift, still) {
    const im = img('ates-hucre.webp'); if (!okI(im)) return false;
    const W2 = w + 8, bx = x + w / 2 - W2 / 2, by = y + h / 2 - W2 / 2 - lift;
    shadowBox(c, bx + 8, by + 10, W2 - 16, W2 - 14, 10, lift, st === 2 ? .95 : .75);
    c.save(); c.globalCompositeOperation = 'lighten';
    if (st === 1) c.filter = 'brightness(.62) saturate(.7)'; else if (st === 3) c.filter = 'hue-rotate(28deg) brightness(1.05)';
    c.drawImage(im, bx, by, W2, W2); c.filter = 'none';
    if ((st === 2 || st === 4) && !still) { c.globalCompositeOperation = 'lighter'; c.globalAlpha = .25 + .15 * Math.sin(tt * 4); c.drawImage(im, bx, by, W2, W2); }
    c.restore(); return true;
  }
  function buttonFire(c, x, y, w, h, active, tt, still) {
    const im = img('ates-hucre.webp'); if (!okI(im)) return false;
    const iw = im.naturalWidth, ih = im.naturalHeight, cap = iw * .3, H2 = h + 10, k2 = H2 / ih, cw = cap * k2, y2 = y - 5 - (active ? 2 : 0);
    shadowBox(c, x + 4, y + 6, w - 8, h - 6, 8, active ? 4 : 1, .85);
    c.save(); c.globalCompositeOperation = 'lighten'; if (!active) c.filter = 'brightness(.7) saturate(.8)';
    c.drawImage(im, 0, 0, cap, ih, x - 5, y2, cw, H2);
    c.drawImage(im, cap, 0, iw - 2 * cap, ih, x - 5 + cw, y2, Math.max(1, w + 10 - 2 * cw), H2);
    c.drawImage(im, iw - cap, 0, cap, ih, x + w + 5 - cw, y2, cw, H2);
    c.filter = 'none';
    if (active && !still) { c.globalCompositeOperation = 'lighter'; c.globalAlpha = .15 + .1 * Math.sin(tt * 2.5 + x); c.drawImage(im, 0, 0, iw, ih, x - 5, y2, w + 10, H2); }
    c.restore(); return true;
  }

  /* ---------- Ateş teması bütünlüğü: paneller, başlık bandı, atmosfer, başlık renkleri ---------- */
  if (globalThis.NEON_ATES !== false && globalThis.NEON_TEMA === undefined) globalThis.NEON_TEMA = 'B';
  const hullPrevA = P.hull;
  P.hull = function (x, y, w, h, accent, active) {
    if (!atesOk() || this.__btn || (w === 112 && h === 112) || w < 150 || h < 50) return hullPrevA.apply(this, arguments);
    const c = this.ctx, t = this.record.reduced ? 0 : now(), pu = .5 + .5 * Math.sin(t * 1.6 + x * .01);
    c.save();
    c.shadowColor = 'rgba(0,0,0,.8)'; c.shadowBlur = 18; c.shadowOffsetY = 6; rr(c, x, y, w, h, 14);
    const gf = c.createLinearGradient(0, y, 0, y + h); gf.addColorStop(0, 'rgba(34,12,8,.9)'); gf.addColorStop(1, 'rgba(14,5,4,.92)'); c.fillStyle = gf; c.fill();
    c.shadowBlur = 0; c.shadowOffsetY = 0;
    rr(c, x + 1, y + 1, w - 2, h - 2, 13); c.lineWidth = 6; c.strokeStyle = '#2a1410'; c.stroke();
    c.lineWidth = 2; const gs = c.createLinearGradient(x, 0, x + w, 0); gs.addColorStop(0, '#ff4a12'); gs.addColorStop(.5, '#ffb347'); gs.addColorStop(1, '#ff4a12');
    c.strokeStyle = gs; c.shadowColor = '#ff6a1a'; c.shadowBlur = 8 + 10 * pu; c.globalAlpha = .7 + .3 * pu; rr(c, x + 2, y + 2, w - 4, h - 4, 12); c.stroke();
    c.shadowBlur = 0; c.globalAlpha = 1;
    for (const [cx, cy] of [[x + 10, y + 10], [x + w - 10, y + 10], [x + 10, y + h - 10], [x + w - 10, y + h - 10]]) { c.fillStyle = '#5a4038'; c.beginPath(); c.arc(cx, cy, 3.2, 0, Math.PI * 2); c.fill(); c.fillStyle = 'rgba(255,170,90,.8)'; c.beginPath(); c.arc(cx - .8, cy - .8, 1.1, 0, Math.PI * 2); c.fill(); }
    if (!this.record.reduced) { const sx = x + ((t * 60 + y) % (w + 80)) - 40; c.save(); rr(c, x + 2, y + 2, w - 4, h - 4, 12); c.clip(); c.globalCompositeOperation = 'lighter'; c.globalAlpha = .9; const sg = c.createLinearGradient(sx - 40, 0, sx + 40, 0); sg.addColorStop(0, 'rgba(255,120,40,0)'); sg.addColorStop(.5, 'rgba(255,170,80,.18)'); sg.addColorStop(1, 'rgba(255,120,40,0)'); c.fillStyle = sg; c.fillRect(sx - 40, y, 80, 4); c.fillRect(sx - 40, y + h - 4, 80, 4); c.restore(); }
    c.restore();
  };
  const textPrevA = P.text;
  P.text = function (t, x, y, size, color, align) {
    if (atesOk()) { if (t === 'NEON SUDOKU') color = '#ffb347'; else if (t === 'OVERDRIVE' || t === 'O V E R D R I V E') color = '#ff5a2a'; else if (color === '#5ff0f5' || color === '#55e8ef' || color === '#7fe9f5') color = '#ffc070'; }
    return textPrevA.call(this, t, x, y, size, color, align);
  };
  const bannerPrev = globalThis.NEON_BANNER;
  globalThis.NEON_BANNER = function (g, c) {
    bannerPrev(g, c);
    if (!atesOk()) return;
    c.save(); c.beginPath(); c.rect(0, 22, 540, 86); c.clip(); c.globalCompositeOperation = 'color'; c.globalAlpha = .75; c.fillStyle = '#c0391a'; c.fillRect(0, 22, 540, 86);
    c.globalCompositeOperation = 'lighter'; c.globalAlpha = 1; const t = g.record.reduced ? 0 : now();
    for (let j = 0; j < 14; j++) { const r = rndGen(j * 31 + 7), life = (t * (.3 + r() * .4) + r()) % 1; c.globalAlpha = (1 - life) * .8; c.fillStyle = r() < .5 ? '#ffb347' : '#ff5a1a'; c.fillRect(r() * 540, 108 - life * 86, 2, 2); }
    c.restore(); c.fillStyle = 'rgba(255,120,40,.5)'; c.fillRect(0, 107, 540, 1);
  };
  const atmosPrevA = P.sceneAtmosphere;
  P.sceneAtmosphere = function () {
    const r = atmosPrevA.apply(this, arguments);
    if (!atesOk() || this.record.reduced || !['menu', 'select', 'brief'].includes(this.state)) return r;
    const c = this.ctx, t = now();
    c.save(); c.globalCompositeOperation = 'lighter';
    /* kubbede kızıl aurora */
    for (let k = 0; k < 3; k++) { c.beginPath(); c.moveTo(0, 260); for (let x = 0; x <= 540; x += 20) c.lineTo(x, 150 + k * 26 + Math.sin(x * .013 + t * .5 + k) * 30 + Math.sin(x * .031 - t * .3) * 12); c.lineTo(540, 260); c.closePath(); const ag = c.createLinearGradient(0, 120, 0, 260); ag.addColorStop(0, ['rgba(255,90,30,.16)', 'rgba(255,170,60,.12)', 'rgba(255,40,80,.10)'][k]); ag.addColorStop(1, 'rgba(0,0,0,0)'); c.fillStyle = ag; c.fill(); }
    /* yükselen közler */
    for (let j = 0; j < 40; j++) { const r = rndGen(j * 97 + 3), life = (t * (.15 + r() * .25) + r()) % 1, x = r() * 540 + Math.sin(t * (1 + r()) + j) * 16, y = 960 - life * 900; c.globalAlpha = Math.min(1, (1 - life) * 1.5) * (.4 + .5 * r()); c.fillStyle = r() < .6 ? '#ff8a2a' : '#ffd27a'; c.beginPath(); c.arc(x, y, .8 + r() * 1.8, 0, Math.PI * 2); c.fill(); }
    c.restore(); return r;
  };
})();
