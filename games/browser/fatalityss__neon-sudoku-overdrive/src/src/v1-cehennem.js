/* Neon Sudoku — Cehennem Ocağı seti (kullanıcının ürettiği görseller): arka planlar, paneller, süre çubuğu + kare kare ateş, hücreler, tuşlar */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_CEH) return;
  NS.V1_CEH = true;
  const P = NS.Game.prototype;
  const now = () => performance.now() / 1000;
  const IM = {};
  const img = n => { if (!IM[n]) { const i = new Image(); i.src = (globalThis.NEON_V1_MAP && globalThis.NEON_V1_MAP[n]) || 'media/' + n; IM[n] = i; } return IM[n]; };
  const ok = i => i && i.complete && i.naturalWidth > 0;
  ['c-ikon', 'c-tus-1', 'c-tus-2', 'c-hucre-1', 'c-hucre-2', 'c-hucre-3', 'c-hucre-4', 'c-cubuk', 'c-panel', 'c-menu', 'c-oyun', 'c-ates-0', 'c-ates-1', 'c-ates-2', 'c-ates-3', 'c-ates-4', 'c-ates-5'].forEach(n => img(n + '.webp'));
  const on = () => globalThis.NEON_CEH !== false && ok(img('c-cubuk.webp'));
  globalThis.NEON_CEH = true;
  const PLAY = ['playing', 'chain', 'paused', 'timeout', 'complete', 'brief'];

  function shadow(c, x, y, w, h, lift, a) { if (NS.LITE) return; c.save(); c.shadowColor = 'rgba(0,0,0,' + a + ')'; c.shadowBlur = 14 + lift * 2; c.shadowOffsetY = 6 + lift; c.shadowOffsetX = 0; c.fillStyle = 'rgba(0,0,0,.01)'; c.translate(0, -2000); c.shadowOffsetY += 2000; c.fillStyle = '#000'; c.fillRect(x, y, w, h); c.restore(); }
  /* 9 dilim: köşe C (kaynak px), hedefte d */
  function nine(c, im, x, y, w, h, C, d) {
    const iw = im.naturalWidth, ih = im.naturalHeight, sx = [0, C, iw - C], sw = [C, iw - 2 * C, C], sy = [0, C, ih - C], sh = [C, ih - 2 * C, C];
    const dx = [x, x + d, x + w - d], dw = [d, w - 2 * d, d], dy = [y, y + d, y + h - d], dh = [d, h - 2 * d, d];
    for (let r = 0; r < 3; r++) for (let q = 0; q < 3; q++) if (dw[q] > 0 && dh[r] > 0) c.drawImage(im, sx[q], sy[r], sw[q], sh[r], dx[q], dy[r], dw[q], dh[r]);
  }
  function three(c, im, x, y, w, h, capFrac) {
    const iw = im.naturalWidth, ih = im.naturalHeight, cap = iw * capFrac, k = h / ih, cw = Math.min(cap * k, w / 2);
    c.drawImage(im, 0, 0, cap, ih, x, y, cw, h);
    c.drawImage(im, cap, 0, iw - 2 * cap, ih, x + cw, y, Math.max(1, w - 2 * cw), h);
    c.drawImage(im, iw - cap, 0, cap, ih, x + w - cw, y, cw, h);
  }

  /* ses seviyesi: SES düğmesi %100 → %75 → %50 → %25 → KAPALI arasında döner */
  const LV = [1, .75, .5, .25, 0];
  let lvl = 0; try { const v = localStorage.getItem('NeonSudoku.ses'); if (v !== null) lvl = Math.max(0, Math.min(4, v | 0)); } catch (_) {}
  function applyVol(g) { const v = LV[lvl]; globalThis.NEON_VOL = v; g.record.muted = v === 0; const tv = .65 * v; if (g.master && g.audio && (g.__vol !== v || Math.abs(g.master.gain.value - tv) > .03)) { g.__vol = v; try { g.master.gain.cancelScheduledValues(g.audio.currentTime); g.master.gain.setTargetAtTime(tv, g.audio.currentTime, .02); } catch (_) { g.master.gain.value = tv; } } }
  /* menüdeki dar tuşları genişlet */
  const btnPrevC = P.button;
  P.button = function (label, x, y, w, h) {
    if (this.state === 'menu' && /^SES (AÇIK|KAPALI)$/.test(String(label))) { const a = [...arguments]; a[0] = lvl === 4 ? 'SES KAPALI' : 'SES %' + Math.round(LV[lvl] * 100); a[5] = () => { lvl = (lvl + 1) % 5; try { localStorage.setItem('NeonSudoku.ses', lvl); } catch (_) {} this.__vol = -1; applyVol(this); if (lvl < 4 && this.sfx) try { this.sfx('select'); } catch (_) {} }; if (on() && w === 190) { a[1] = x === 72 ? 30 : 276; a[3] = 234; } return btnPrevC.apply(this, a); }
    if (on() && this.state === 'menu' && w === 190 && (x === 72 || x === 278)) { const a = [...arguments]; a[1] = x === 72 ? 30 : 276; a[3] = 234; return btnPrevC.apply(this, a); }
    return btnPrevC.apply(this, arguments);
  };
  /* ---------- Paneller, hücreler, tuşlar ---------- */
  const hullPrev = P.hull;
  P.hull = function (x, y, w, h, accent, active) {
    if (!on()) return hullPrev.apply(this, arguments);
    const c = this.ctx, t = this.record.reduced ? 0 : now();
    if (this.__btn) {
      if (w < 100) { const im = img('c-ikon.webp'); if (!ok(im)) return hullPrev.apply(this, arguments); const S = Math.max(w, h) + 10;  c.drawImage(im, x + w / 2 - S / 2, y + h / 2 - S / 2 - (active ? 1 : 0), S, S); return; }
      const im = img(active ? 'c-tus-2.webp' : 'c-tus-1.webp'); if (!ok(im)) return hullPrev.apply(this, arguments);
      const H2 = h + 14, lift = active ? 3 : 0;
      
      three(c, im, x - 8, y - 7 - lift, w + 16, H2, .17);
      if (globalThis.NEON_BTN_NOTR !== false) { /* orta yüz: temadan bağımsız nötr koyu çelik */
        const ix = x + Math.min(34, w * .16), iw2 = w - 2 * Math.min(34, w * .16), iy = y + h * .2 - lift, ih2 = h * .6;
        c.save(); const gg = c.createLinearGradient(0, iy, 0, iy + ih2); gg.addColorStop(0, '#3a3d44'); gg.addColorStop(.45, '#1c1e23'); gg.addColorStop(1, '#0d0e11');
        c.beginPath(); const r = ih2 * .18; c.moveTo(ix + r, iy); c.arcTo(ix + iw2, iy, ix + iw2, iy + ih2, r); c.arcTo(ix + iw2, iy + ih2, ix, iy + ih2, r); c.arcTo(ix, iy + ih2, ix, iy, r); c.arcTo(ix, iy, ix + iw2, iy, r); c.closePath();
        c.fillStyle = gg; c.fill(); c.strokeStyle = 'rgba(255,255,255,.12)'; c.lineWidth = 1; c.stroke();
        c.fillStyle = 'rgba(255,255,255,.07)'; c.fillRect(ix + r, iy + 2, iw2 - 2 * r, ih2 * .3); c.restore(); }
      if (active && !this.record.reduced) { c.save(); c.globalCompositeOperation = 'lighter'; c.globalAlpha = .08 + .07 * Math.sin(t * 2.4 + x); three(c, im, x - 8, y - 7 - lift, w + 16, H2, .17); c.restore(); }
      return;
    }
    if (w === 112 && h === 112 && this.cfg && PLAY.includes(this.state)) {
      const i = Math.round((x - 30) / 120) + Math.round((y - 326) / 120) * 4, sel = i === this.selected;
      const st = sel ? (this.errorFlash > 0 ? 4 : 2) : (this.popAt && this.popAt[i] !== undefined ? 3 : 1), im = img('c-hucre-' + st + '.webp');
      if (!ok(im)) return hullPrev.apply(this, arguments);
      const lift = sel ? 5 : 0, sh = st === 4 && !this.record.reduced ? Math.sin(t * 60) * 3 * Math.min(1, this.errorFlash) : 0, S = w + 12;
      shadow(c, x + 10, y + 12, w - 20, h - 16, lift, sel ? .95 : .75);
      c.drawImage(im, x + w / 2 - S / 2 + sh, y + h / 2 - S / 2 - lift, S, S);
      if (sel && !this.record.reduced) { c.save(); c.globalCompositeOperation = 'lighter'; c.globalAlpha = .1 + .08 * Math.sin(t * 3); c.drawImage(im, x + w / 2 - S / 2 + sh, y + h / 2 - S / 2 - lift, S, S); c.restore(); }
      return;
    }
    if (w >= 150 && h >= 50) {
      const im = img('c-panel.webp'); if (!ok(im)) return hullPrev.apply(this, arguments);
      const d = Math.max(16, Math.min(46, h / 2.6, w / 5));
      
      nine(c, im, x - 4, y - 4, w + 8, h + 8, 70, d);
      return;
    }
    return hullPrev.apply(this, arguments);
  };

  /* modal pencere: mavi dikdörtgen yerine panel görseli */
  const rectPrev = P.rect;
  P.rect = function (x, y, w, h, fill, stroke) {
    if (on() && x === 12 && y === 263 && w === 516 && h === 659 && ok(img('c-panel.webp'))) { const c = this.ctx; c.save(); c.globalAlpha = .96; nine(c, img('c-panel.webp'), x, y, w, h, 70, 46); c.restore(); return; }
    return rectPrev.apply(this, arguments);
  };
  const modalPrev = P.modal;
  if (modalPrev) P.modal = function () { const c = this.ctx, fs = c.fillRect; if (on()) c.fillRect = function (x, y, w, h) { if (x === 0 && y === 100 && w === 540 && h === 860) { const f = this.fillStyle; this.fillStyle = 'rgba(8,2,1,.72)'; fs.call(this, x, y, w, h); this.fillStyle = f; return; } return fs.apply(this, arguments); }; try { return modalPrev.apply(this, arguments); } finally { c.fillRect = fs; } };
  /* ---------- Süre çubuğu + kare kare ateş ---------- */
  globalThis.NEON_TIME_DRAW = function (g) {
    if (!on()) return false;
    const c = g.ctx, t = g.record.reduced ? 0 : now(), fr = img('c-cubuk.webp'), f = Math.max(0, Math.min(1, g.time / NS_T(g))), urgent = g.time <= 5;
    const W = 534, k = W / 900, X = 3, H = 179 * k, Y = 162 - H / 2, ax = X + 125 * k, ay = Y + 80 * k, aw = (809 - 125) * k, ah = (120 - 80) * k, hx = ax + aw * f;
    c.save();
    c.fillStyle = '#080302'; c.fillRect(ax, ay, aw, ah);
    const fi = Math.floor(t * 12) % 6, fire = img('c-ates-' + fi + '.webp');
    if (f > 0 && ok(fire)) {
      c.save(); c.beginPath(); c.rect(ax, ay - ah * 1.2, hx - ax, ah * 2.2); c.clip();
      if (urgent && !g.record.reduced) c.filter = 'hue-rotate(-18deg) saturate(1.5)';
      const fh = ah * 2.1, fw = fh * fire.naturalWidth / fire.naturalHeight, off = (t * 70) % fw;
      for (let x = ax - off; x < hx; x += fw) c.drawImage(fire, x, ay + ah - fh, fw, fh);
      c.restore();
      if (!g.record.reduced) { c.save(); c.globalCompositeOperation = 'lighter'; const gr = c.createRadialGradient(hx, ay + ah / 2, 0, hx, ay + ah / 2, 34); gr.addColorStop(0, 'rgba(255,240,200,.85)'); gr.addColorStop(.4, 'rgba(255,140,40,.45)'); gr.addColorStop(1, 'rgba(0,0,0,0)'); c.fillStyle = gr; c.fillRect(hx - 34, ay + ah / 2 - 34, 68, 68); c.restore(); }
    }
    c.save(); c.shadowColor = 'rgba(0,0,0,.85)'; c.shadowBlur = 12; c.shadowOffsetY = 5; c.drawImage(fr, X, Y, W, H); c.restore();
    if (urgent && !g.record.reduced) { c.save(); c.globalCompositeOperation = 'lighter'; c.globalAlpha = .2 + .2 * Math.sin(t * 10); c.drawImage(fr, X, Y, W, H); c.restore(); }
    c.restore();
    return true;
  };

  /* ---------- Arka planlar ---------- */
  const BAKE = new Map();
  function bake(im) { let b = BAKE.get(im); if (b) return b; b = document.createElement('canvas'); b.width = Math.min(im.naturalWidth, 720); b.height = Math.round(b.width * im.naturalHeight / im.naturalWidth); const x = b.getContext('2d'); x.filter = 'saturate(.45) brightness(.62) contrast(1.05)'; x.drawImage(im, 0, 0, b.width, b.height); BAKE.set(im, b); return b; }
  const atmosPrev = P.sceneAtmosphere;
  P.sceneAtmosphere = function () {
    if (!on()) return atmosPrev.apply(this, arguments);
    const menu = this.state === 'menu' || this.state === 'select', bg = img(menu ? 'c-menu.webp' : 'c-oyun.webp');
    if (!ok(bg)) return atmosPrev.apply(this, arguments);
    const c = this.ctx, t = this.record.reduced ? 0 : now(), z = 1.03 + .012 * Math.sin(t * .13);
    const bb = bake(bg); c.save(); c.drawImage(bb, 270 - 270 * z + Math.sin(t * .09) * 4, 480 - 480 * z, 540 * z, 960 * z); const vg = c.createLinearGradient(0, 0, 0, 960); vg.addColorStop(0, 'rgba(10,8,22,.35)'); vg.addColorStop(.5, 'rgba(8,6,16,' + (this.state === 'select' ? .55 : .3) + ')'); vg.addColorStop(1, 'rgba(10,6,12,.45)'); c.fillStyle = vg; c.fillRect(0, 0, 540, 960);
    if (!this.record.reduced) {
      c.globalCompositeOperation = 'lighter';
      for (let j = 0; j < 36; j++) { const r = Math.sin(j * 91.7) * .5 + .5, r2 = Math.sin(j * 37.3) * .5 + .5, life = (t * (.12 + r * .2) + r2) % 1, x = r2 * 540 + Math.sin(t * (1 + r) + j) * 14, y = 960 - life * 920; c.globalAlpha = Math.min(1, (1 - life) * 1.6) * (.35 + .5 * r); c.fillStyle = r < .6 ? '#ff8a2a' : '#ffd27a'; c.beginPath(); c.arc(x, y, .8 + r * 1.8, 0, Math.PI * 2); c.fill(); }
      
    }
    c.restore();
  };
  /* TEMA düğmesi: tüm sahnenin ateş rengini değiştirir (0 kızıl, 1 buz, 2 mor, 3 zümrüt) */
  const HUE = [0, 175, 245, 95];
  const BR = [1, 1.15, 1.3, .7, .85];
  let bri = 0; try { const v = localStorage.getItem('NeonSudoku.parlak'); if (v !== null) bri = Math.max(0, Math.min(4, v | 0)); } catch (_) {}
    /* renk teması: kanvasa CSS filtresi (GPU), her karede kopyalama yok */
  const renderPrevT = P.render;
  P.render = function () {
    applyVol(this);
    const r = renderPrevT.apply(this, arguments);
    if (on() && this.state === 'menu') this.button(BR[bri] === 1 ? 'PARLAKLIK %100' : 'PARLAKLIK %' + Math.round(BR[bri] * 100), 72, 652, 396, 58, () => { bri = (bri + 1) % BR.length; try { localStorage.setItem('NeonSudoku.parlak', bri); } catch (_) {} });
    if (this.canvas) { const hue = on() ? HUE[(this.record.theme | 0) % 4] : 0, b = BR[bri], f = (hue ? 'hue-rotate(' + hue + 'deg) ' : '') + (b !== 1 ? 'brightness(' + b + ')' : ''); if (this.__hueF !== f) { this.canvas.style.filter = f.trim(); this.__hueF = f; } }
    return r;
  };
  globalThis.NEON_BANNER = (function (prev) {
    return function (g, c) {
      if (!on() || !ok(img('c-menu.webp'))) return prev(g, c);
      c.save(); c.beginPath(); c.rect(0, 22, 540, 86); c.clip(); c.drawImage(img('c-menu.webp'), 0, 40, 540, 540 * 960 / 540 * .5 * 2 / 2, 0, 22, 540, 86 * 1); c.fillStyle = 'rgba(4,2,2,.72)'; c.fillRect(0, 22, 540, 86); c.restore();
      c.fillStyle = 'rgba(255,120,40,.55)'; c.fillRect(0, 107, 540, 1.5);
    };
  })(globalThis.NEON_BANNER);
})();
