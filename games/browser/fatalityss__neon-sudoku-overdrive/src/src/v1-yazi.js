/* Neon Sudoku — taş-lav harf seti, lav rakamlar ve logo (kullanıcı görselleri) */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_YAZI) return;
  NS.V1_YAZI = true;
  const P = NS.Game.prototype;
  const now = () => performance.now() / 1000;
  const HARF = {"A": ["g0041", 100, 108, "n"], "B": ["g0042", 84, 100, "n"], "C": ["g0043", 82, 100, "n"], "Ç": ["g00c7", 80, 113, "ust"], "D": ["g0044", 88, 99, "n"], "E": ["g0045", 84, 103, "n"], "F": ["g0046", 82, 100, "n"], "G": ["g0047", 83, 99, "n"], "Ğ": ["g011e", 81, 119, "alt"], "H": ["g0048", 101, 104, "n"], "I": ["g0049", 49, 99, "n"], "İ": ["g0130", 50, 117, "alt"], "J": ["g004a", 76, 99, "n"], "K": ["g004b", 102, 118, "n"], "L": ["g004c", 85, 99, "n"], "M": ["g004d", 112, 102, "n"], "N": ["g004e", 97, 100, "n"], "O": ["g004f", 84, 100, "n"], "Ö": ["g00d6", 86, 116, "alt"], "P": ["g0050", 94, 102, "n"], "R": ["g0052", 101, 100, "n"], "S": ["g0053", 81, 99, "n"], "Ş": ["g015e", 81, 114, "ust"], "T": ["g0054", 81, 101, "n"], "U": ["g0055", 89, 101, "n"], "Ü": ["g00dc", 86, 109, "alt"], "V": ["g0056", 101, 97, "n"], "Y": ["g0059", 102, 97, "n"], "Z": ["g005a", 102, 101, "n"], "0": ["g0030", 85, 100, "n"], "1": ["g0031", 54, 100, "n"], "2": ["g0032", 104, 109, "n"], "3": ["g0033", 83, 99, "n"], "4": ["g0034", 94, 100, "n"], "5": ["g0035", 84, 102, "n"], "6": ["g0036", 83, 99, "n"], "7": ["g0037", 81, 101, "n"], "8": ["g0038", 85, 99, "n"], "9": ["g0039", 84, 101, "n"]};
  const IM = {};
  const img = n => { if (!IM[n]) { const i = new Image(); i.src = (globalThis.NEON_V1_MAP && globalThis.NEON_V1_MAP[n]) || 'media/' + n; IM[n] = i; } return IM[n]; };
  const ok = i => i && i.complete && i.naturalWidth > 0;
  Object.values(HARF).forEach(h => img('harf/' + h[0] + '.webp'));
  for (let k = 1; k <= 4; k++) { img('rakam-sicak-' + k + '.webp'); img('rakam-sonuk-' + k + '.webp'); }
  img('logo.webp');
  const on = () => globalThis.NEON_YAZI !== false;
  const UP = /^[A-ZÇĞİÖŞÜ0-9 ·.:!?\-–×%+/]+$/;
  const textPrev = P.text;
  const GC = new Map();
  function glyphText(g, t, x, y, size, align, maxW) {
    const c = g.ctx; let H = size * .92, gap = size * .04, sp = size * .34;
    const parts = [...t].map(ch => {
      if (ch === ' ') return { w: sp };
      const h = HARF[ch]; if (h && ok(img('harf/' + h[0] + '.webp'))) return { h, w: h[1] / 100 * H };
      c.save(); c.font = '800 ' + size + 'px Oxanium, sans-serif'; const w = c.measureText(ch).width; c.restore(); return { ch, w };
    });
    let tot = parts.reduce((a, p) => a + p.w + gap, -gap);
    if (maxW && tot > maxW) { const k = maxW / tot; H *= k; gap *= k; parts.forEach(p => p.w *= k); tot = maxW; size *= k; }
    let cx0 = align === 'center' ? x - tot / 2 : align === 'right' ? x - tot : x;
    const light = !!globalThis.NEON_GLYPH_LIGHT, key = t + '|' + H.toFixed(1) + '|' + light, pad = Math.ceil(size * .5);
    let cv = GC.get(key);
    if (!cv) {
      if (parts.some(p => p.h && !ok(img('harf/' + p.h[0] + '.webp')))) return;
      const S = 2; cv = document.createElement('canvas'); cv.width = Math.ceil((tot + pad * 2) * S); cv.height = Math.ceil((H * 1.25 + pad * 2) * S);
      const d = cv.getContext('2d'); d.scale(S, S); let cx = pad; const base = pad + H * 1.2;
      d.shadowColor = 'rgba(0,0,0,.85)'; d.shadowBlur = size * .25 * S; d.shadowOffsetY = size * .08;
      for (const p of parts) {
        if (p.h) { const im = img('harf/' + p.h[0] + '.webp'), hh = p.h[2] / 100 * H, gy = p.h[3] === 'ust' ? base - H : base - hh, o = Math.max(1.5, size * .09);
          d.save(); d.shadowColor = 'transparent'; d.filter = 'brightness(0)'; d.globalAlpha = .9;
          for (const [dx, dy] of [[-o, 0], [o, 0], [0, -o], [0, o], [-o * .7, -o * .7], [o * .7, -o * .7], [-o * .7, o * .7], [o * .7, o * .7]]) d.drawImage(im, cx + dx, gy + dy, p.w, hh);
          d.restore(); d.save(); d.shadowColor = 'transparent'; d.filter = light ? 'grayscale(1) brightness(2.6) contrast(1.2)' : 'brightness(1.7) contrast(1.15) saturate(1.1)'; d.drawImage(im, cx, gy, p.w, hh); d.restore(); }
        else if (p.ch) { d.font = '800 ' + size + 'px Oxanium, sans-serif'; d.textAlign = 'left'; d.fillStyle = '#ffb347'; d.fillText(p.ch, cx, base - size * .04); }
        cx += p.w + gap;
      }
      if (GC.size > 120) GC.clear(); GC.set(key, cv);
    }
    c.drawImage(cv, cx0 - pad, y + size * .04 - H * 1.2 - pad, cv.width / 2, cv.height / 2);
  }
  const renderPrevY = P.render;
  P.render = function () { this.__logoArgs = null; this.__logoBig = false; const r = renderPrevY.apply(this, arguments); if (this.__logoArgs && !this.__logoBig && on()) { this.__logoLate = true; try { P.text.call(this, 'NEON SUDOKU', this.__logoArgs[0], this.__logoArgs[1], this.__logoArgs[2], '#fff', 'center'); } finally { this.__logoLate = false; } } return r; };
  const hullPrevY = P.hull;
  P.hull = function (x, y, w) { if (this.__btn) this.__btnW = w; return hullPrevY.apply(this, arguments); };
  const btnPrev = P.button;
  P.button = function () { this.__btnW = 0; try { return btnPrev.apply(this, arguments); } finally { this.__btnW = 0; } };
  P.text = function (t, x, y, size, color, align) {
    if (!on()) return textPrev.apply(this, arguments);
    const c = this.ctx, s = String(t);
    if (s === 'OVERDRIVE' || s === 'O V E R D R I V E') return;
    if (s === 'NEON SUDOKU' && ok(img('logo.webp')) && size < 40 && !this.__logoLate) { this.__logoArgs = [x, y, size]; return; }
    if (s === 'NEON SUDOKU' && ok(img('logo.webp'))) {
      if (size >= 40) { if (this.__logoBig) return; this.__logoBig = true; }
      const lg = img('logo.webp'), menu = size >= 40, h = menu ? 98 : 60, w = h * lg.naturalWidth / lg.naturalHeight, cy = menu ? 70 : y + 8;
      const pu = this.record.reduced ? 0 : .5 + .5 * Math.sin(now() * 2);
      const lk = 'logo|' + h; let lc = GC.get(lk);
      if (!lc) { const S = 2, pd = 40; lc = document.createElement('canvas'); lc.width = (w + pd * 2) * S; lc.height = (h + pd * 2) * S; const d = lc.getContext('2d'); d.scale(S, S);
        const gr = d.createRadialGradient(pd + w / 2, pd + h / 2, 10, pd + w / 2, pd + h / 2, w * .62); gr.addColorStop(0, 'rgba(0,0,0,.78)'); gr.addColorStop(.7, 'rgba(0,0,0,.45)'); gr.addColorStop(1, 'rgba(0,0,0,0)'); d.fillStyle = gr; d.fillRect(0, 0, w + pd * 2, h + pd * 2);
        d.save(); d.filter = 'brightness(0)'; const o = menu ? 3 : 2; for (const [dx, dy] of [[-o, 0], [o, 0], [0, -o], [0, o], [-o, -o], [o, -o], [-o, o], [o, o]]) d.drawImage(lg, pd + dx, pd + dy, w, h); d.restore();
        d.filter = 'brightness(1.35) contrast(1.1)'; d.drawImage(lg, pd, pd, w, h); GC.set(lk, lc); }
      c.save(); c.globalAlpha = 1; c.drawImage(lc, x - w / 2 - 40, cy - h / 2 - 40, w + 80, h + 80); c.globalCompositeOperation = 'lighter'; c.globalAlpha = .12 * pu; c.drawImage(lg, x - w / 2, cy - h / 2, w, h); c.restore();
      return;
    }
    if (/^[1-4]$/.test(s) && (size === 42 || size === 34)) {
      const im = img('rakam-sicak-' + s + '.webp');
      if (ok(im)) {
        let sc = 1;
        if (size === 42 && this.popAt && !this.record.reduced) { const col = Math.round((x - 86) / 120), row = Math.round((y - 399) / 120), at = this.popAt[row * 4 + col]; if (at !== undefined) { const e = now() - at; if (e < .45) sc = e < .1 ? 1 - e * 2.5 : e < .25 ? .75 + (e - .1) / .15 * .4 : 1.15 - (e - .25) / .2 * .15; } }
        const h = (size === 42 ? 72 : 50) * sc, w = h * im.naturalWidth / im.naturalHeight, cy = y - (size === 42 ? 16 : 12);
        const dk = 'd' + s; let dc = GC.get(dk);
        if (!dc) { const W0 = 120, H0 = W0 * im.naturalHeight / im.naturalWidth, pd = 20; dc = document.createElement('canvas'); dc.width = W0 + pd * 2; dc.height = H0 + pd * 2; const d = dc.getContext('2d'); d.shadowColor = '#000'; d.shadowBlur = 16; d.shadowOffsetY = 5; if (globalThis.NEON_ZIT !== false) d.filter = 'hue-rotate(235deg) saturate(.85) brightness(.92)'; d.drawImage(im, pd, pd, W0, H0); dc.__p = pd / W0; GC.set(dk, dc); }
        const k = w / 120, pd = 20 * k; c.save(); c.globalAlpha = 1; c.drawImage(dc, x - w / 2 - pd, cy - h / 2 - pd, dc.width * k, dc.height * k); c.restore();
        return;
      }
    }
    if (/^[1-4]( +[1-4])+$/.test(s) && size <= 30) {
      const sel = this.cfg && this.selected === Math.round((x - 86) / 120) + Math.round((y - 387) / 120) * 4, txt = s.split(/ +/).join(' ');
      c.save(); c.globalAlpha = 1; c.filter = 'none'; c.font = '800 ' + (size + 4) + 'px Oxanium, sans-serif'; c.textAlign = align || 'center'; c.textBaseline = 'alphabetic';
      c.lineJoin = 'round'; c.lineWidth = 6; c.strokeStyle = 'rgba(0,0,0,.92)'; c.strokeText(txt, x, y + 2);
      c.shadowBlur = 0; c.fillStyle = sel ? '#e6d8ff' : '#bfb0dc'; c.fillText(txt, x, y + 2);
      c.restore(); return;
    }
    if (this.__btnW && size >= 16 && !/^[1-4]$/.test(s)) { let s2 = s; if (/^TEMA · /.test(s)) { t = s2 = 'TEMA · ' + ['KIZIL', 'BUZ', 'MOR', 'ZÜMRÜT'][(this.record.theme | 0) % 4]; } c.save(); c.font = '700 ' + size + 'px Oxanium, sans-serif'; const mw = this.__btnW - (this.__btnW < 260 ? 62 : 80), tw = c.measureText(s).width; c.restore(); if (tw > mw) size = Math.max(11, Math.floor(size * mw / tw)); return textPrev.call(this, t, x, y, size, color, align); }
    if ((s === 'DOKUN' || s === 'SEÇİLİ') && size <= 16) color = s === 'SEÇİLİ' ? '#cbb6ff' : '#a99cc0';
    if (/^TEMA · /.test(s)) { t = 'TEMA · ' + ['KIZIL', 'BUZ', 'MOR', 'ZÜMRÜT'][(this.record.theme | 0) % 4]; return textPrev.call(this, t, x, y, size, color, align); }
    if (!this.__btnW && size >= 22 && s.length > 1 && s === s.toLocaleUpperCase('tr') && UP.test(s) && /[A-ZÇĞİÖŞÜ]/.test(s)) { const mw = this.__btnW ? this.__btnW - 56 : (align === 'center' ? 2 * Math.min(x, 540 - x) - 24 : align === 'right' ? x - 20 : 520 - x); return glyphText(this, s, x, y, size, align, mw); }
    return textPrev.apply(this, arguments);
  };
})();
