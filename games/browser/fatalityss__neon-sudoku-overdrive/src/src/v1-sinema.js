/* Neon Sudoku — bölüm geçiş sinematikleri (bölüm tamamlanınca 2,6 sn) */
(function () {
  'use strict';
  const NS = globalThis.NeonSudoku;
  if (!NS || NS.V1_SINEMA) return;
  NS.V1_SINEMA = true;
  const P = NS.Game.prototype;
  const now = () => performance.now() / 1000;
  const BX = 26, BY = 322, BW = 488, BH = 484, CX = BX + BW / 2, CY = BY + BH / 2, DUR = 2.6;
  const rg = seed => { let s = seed >>> 0 || 1; return () => (s = (s * 1664525 + 1013904223) >>> 0) / 4294967296; };
  const GI = {};
  const gimg = n => { if (!GI[n]) { const i = new Image(); i.src = (globalThis.NEON_V1_MAP && globalThis.NEON_V1_MAP[n]) || 'media/' + n; GI[n] = i; } return GI[n]; };
  const ease = p => 1 - Math.pow(1 - p, 3);
  const clamp = (v, a = 0, b = 1) => Math.max(a, Math.min(b, v));

  function glow(c, x, y, r, inner, outer) { const g = c.createRadialGradient(x, y, 0, x, y, r); g.addColorStop(0, inner); g.addColorStop(1, outer || 'rgba(0,0,0,0)'); c.fillStyle = g; c.fillRect(x - r, y - r, r * 2, r * 2); }
  function ring(c, x, y, r, w, col, a) { c.globalAlpha = a; c.strokeStyle = col; c.lineWidth = w; c.beginPath(); c.arc(x, y, r, 0, Math.PI * 2); c.stroke(); c.globalAlpha = 1; }
  function flash(c, a, col) { if (a <= 0) return; c.globalAlpha = a; c.fillStyle = col || '#ffffff'; c.fillRect(0, 0, 540, 960); c.globalAlpha = 1; }
  function debris(c, p, x, y, n, seed, cols, spd) {
    const r = rg(seed);
    for (let k = 0; k < n; k++) {
      const a = r() * Math.PI * 2, v = (60 + r() * 260) * (spd || 1), s = 2 + r() * 5;
      const px = x + Math.cos(a) * v * p, py = y + Math.sin(a) * v * p + 260 * p * p;
      c.globalAlpha = clamp(1 - p); c.fillStyle = cols[k % cols.length]; c.fillRect(px - s / 2, py - s / 2, s, s);
    }
    c.globalAlpha = 1;
  }
  function boardPiece(c, snap, sx, sy, sw, sh, dx, dy, rot, sc, a) {
    if (!snap) return;
    const d = snap.width / BW;
    c.save(); c.globalAlpha = a == null ? 1 : a; c.translate(dx + sw / 2, dy + sh / 2); c.rotate(rot || 0); c.scale(sc || 1, sc || 1);
    c.drawImage(snap, sx * d, sy * d, sw * d, sh * d, -sw / 2, -sh / 2, sw, sh); c.restore();
  }
  function planet(c, x, y, r, c1, c2) {
    const g = c.createRadialGradient(x - r * .4, y - r * .4, r * .1, x, y, r); g.addColorStop(0, c1); g.addColorStop(1, c2);
    glow(c, x, y, r * 1.6, 'rgba(255,255,255,.12)');
    c.beginPath(); c.arc(x, y, r, 0, Math.PI * 2); c.fillStyle = g; c.fill();
  }
  function bolt(c, x1, y1, x2, y2, r, col, w) {
    c.beginPath(); c.moveTo(x1, y1); const n = 10;
    for (let k = 1; k < n; k++) { const t = k / n; c.lineTo(x1 + (x2 - x1) * t + (r() - .5) * 40, y1 + (y2 - y1) * t + (r() - .5) * 18); }
    c.lineTo(x2, y2); c.strokeStyle = col; c.lineWidth = w; c.shadowColor = col; c.shadowBlur = 18; c.stroke();
    c.strokeStyle = '#fff'; c.lineWidth = w * .4; c.stroke(); c.shadowBlur = 0;
  }

  /* Her sahne: { ad, vur (çarpma anı 0-1), ciz(c, p, t, g) }  — p: 0..1 ilerleme */
  const SAHNE = [
    { ad: 'Göktaşı', vur: .38, ciz(c, p, t, g) {
      const q = clamp(p / .38), mx = 640 - (640 - CX) * ease(q), my = -160 + (CY + 160) * ease(q), shk = p > .38 ? 1 - clamp((p - .38) / .25) : 0;
      boardPiece(c, g.__snap, 0, 0, BW, BH, BX + Math.sin(t * 90) * 10 * shk, BY + (p > .45 ? 220 * Math.pow((p - .45) / .55, 2) : 0), p > .45 ? (p - .45) * .5 : 0, 1, 1 - clamp((p - .5) / .5));
      if (p < .38) spr(c, 'meteor', mx + 60, my - 60, 300 + 80 * q, 0, 1);
      if (p >= .38) { flash(c, .9 * (1 - (p - .38) * 6), '#fff2d0'); boom(c, (p - .38) / .62, CX, CY + 20, 1.1); }
    } },
    { ad: 'Gezegen çarpışması', vur: .12, ciz(c, p, t, g) {
      /* yapay zekâ görseli: beyaz patlama ile açılır, kamera geri çekilir, enkaz kameraya uçar */
      const im = gimg('gezegen-carpisma.webp');
      boardPiece(c, g.__snap, 0, 0, BW, BH, BX, BY, 0, 1 - clamp(p / .12));
      if (im && im.complete && im.naturalWidth) {
        const z = 1.25 - .25 * ease(clamp(p / .85)), H = 960 * z, W = H * im.naturalWidth / im.naturalHeight, a = clamp((p - .04) / .08) * (1 - clamp((p - .82) / .18));
        c.save(); c.globalAlpha = a; c.translate(270, 480); c.rotate(-.04 + .05 * p); c.drawImage(im, -W / 2 + (W - 540) * .42 * (1 - 2 * ease(clamp(p / .8))), -H / 2, W, H); c.restore();
      }
      flash(c, 1 - clamp((p - .1) / .12), '#fff6e0');
      ring(c, 270, 480, 40 + p * 700, 22 * (1 - p) + 2, '#ffcf8a', .8 * (1 - p));
      debris(c, clamp((p - .12) / .7), 270, 480, 70, 33, ['#ffcf7a', '#ff7a2a', '#5a3a2a', '#fff'], 2.2);
    } },
    { ad: 'Dev tokmak', vur: .42, ciz(c, p, t, g) {
      /* tokmak yukarıda kaldırılır, hızlanarak dikine iner, başı tahtanın ortasına çakılır; tahta 16 parçaya dağılır */
      const V = .42, im = gimg('fx-tokmak.webp'), HX = CX, HY = CY - 20, S0 = 1.3;
      let dy, ang, sc, al = 1;
      if (p < .12) { const q = ease(p / .12); dy = -900 + 500 * q; ang = -.32 * q; sc = .78; }
      else if (p < .22) { const q = (p - .12) / .1; dy = -400 - 50 * Math.sin(q * Math.PI / 2); ang = -.32 - .06 * q; sc = .78; }
      else if (p < V) { const q = Math.pow((p - .22) / (V - .22), 2.5); dy = -450 * (1 - q); ang = -.38 * (1 - q); sc = .78 + .22 * q; }
      else if (p < .64) { const q = (p - V) / (.64 - V); dy = -34 * Math.sin(q * Math.PI) * (1 - q * .5); ang = .05 * Math.sin(q * Math.PI); sc = 1; }
      else { const q = clamp((p - .64) / .2); dy = -900 * q * q; ang = .1 * q; sc = 1; al = 1 - q; }
      const drawH = (y, a, k, alpha) => { if (!(im.complete && im.naturalWidth) || alpha <= 0) return; const S = S0 * k; c.save(); c.globalAlpha = alpha; c.translate(HX, HY + y); c.rotate(a); c.drawImage(im, -130 * S, -322 * S, 260 * S, 423 * S); c.restore(); };
      if (p < V) {
        const tr = p > V - .08 ? Math.sin(t * 80) * 3 * (p - V + .08) / .08 : 0;
        boardPiece(c, g.__snap, 0, 0, BW, BH, BX + tr, BY, 0, 1);
        if (p > .22) { const q = (p - .22) / (V - .22), sp = q * q * 2.5;
          for (let k = 3; k >= 1; k--) drawH(dy - k * 55 * sp, ang - k * .03 * sp, sc, .14 / k);
          c.save(); c.globalCompositeOperation = 'lighter'; for (let k = 0; k < 7; k++) { const x = HX - 150 + k * 50, y0 = HY + dy - 120, L = 160 + 300 * sp; const gr = c.createLinearGradient(0, y0 - L, 0, y0); gr.addColorStop(0, 'rgba(255,140,60,0)'); gr.addColorStop(1, 'rgba(255,170,90,' + (.35 * q) + ')'); c.fillStyle = gr; c.fillRect(x, y0 - L, 4, L); } c.restore(); }
      } else {
        const q = clamp((p - V) / .55), r = rg(21);
        if (q < .06) { boardPiece(c, g.__snap, 0, 0, BW, BH, BX, BY + 10, 0, 1); }
        else for (let k = 0; k < 4; k++) for (let j = 0; j < 4; j++) {
          const sx = j * BW / 4, sy = k * BH / 4, mx = BX + sx + BW / 8, my = BY + sy + BH / 8, dx = mx - HX, dy = my - HY - 40, d = Math.hypot(dx, dy) || 1, v = (520 + r() * 420) * (1.25 - Math.min(1, d / 360) * .5), z = q - .06;
          boardPiece(c, g.__snap, sx, sy, BW / 4, BH / 4, BX + sx + dx / d * v * z, BY + sy + dy / d * v * z - 260 * z + 1100 * z * z, (r() - .5) * 9 * z, 1 + .25 * z, 1 - clamp((q - .55) / .45));
        }
        const z = clamp((p - V) / .1);
        if (z < 1) { c.save(); c.strokeStyle = 'rgba(255,190,110,' + (1 - z) + ')'; c.lineWidth = 3; for (let k = 0; k < 10; k++) { const a = k / 10 * Math.PI * 2 + r() * .4; let x = HX, y = HY + 50; c.beginPath(); c.moveTo(x, y); for (let m = 0; m < 4; m++) { x += Math.cos(a + (r() - .5) * .7) * 45; y += Math.sin(a + (r() - .5) * .7) * 45; c.lineTo(x, y); } c.stroke(); } c.restore(); }
        flash(c, .3 * (1 - clamp((p - V) / .06)), '#ffd9a0');
        ring(c, HX, HY + 60, 30 + 520 * ease(clamp((p - V) / .35)), 16 * (1 - clamp((p - V) / .35)) + 1, '#ffb070', .8 * (1 - clamp((p - V) / .35)));
        boom(c, clamp((p - V) / .45), HX, HY + 60, 1.05);
        debris(c, clamp((p - V) / .5), HX, HY + 60, 60, 7, ['#ffcf7a', '#ff7a2a', '#6b4a3a', '#2a1a14'], 1.7);
      }
      drawH(dy, ang, sc, al);
    } },
    { ad: 'Ok yağmuru', vur: .12, ciz(c, p, t, g) {
      boardPiece(c, g.__snap, 0, 0, BW, BH, BX, BY, 0, 1, p > .8 ? 1 - (p - .8) * 5 : 1);
      const r = rg(99);
      for (let k = 0; k < 60; k++) {
        const st = r() * .55, x = BX + 20 + r() * (BW - 40), y = BY + 20 + r() * (BH - 40), ang = 1.0 + (r() - .5) * .25, q = clamp((p - st) / .14);
        if (q <= 0) continue;
        const d = 700 * (1 - ease(q)), hx = x - Math.cos(ang) * d, hy = y - Math.sin(ang) * d;
        spr(c, 'ok', hx - Math.cos(ang) * 55, hy - Math.sin(ang) * 55, 120, ang, p > .8 ? 1 - (p - .8) * 5 : 1, 'source-over');
        if (q >= 1 && p - st < .25) { c.save(); c.globalCompositeOperation = 'lighter'; c.globalAlpha = 1 - (p - st - .14) * 9; c.fillStyle = '#ffcf7a'; c.beginPath(); c.arc(x, y, 9, 0, Math.PI * 2); c.fill(); c.restore(); }
      }
    } },
    { ad: 'Kara delik', vur: .55, ciz(c, p, t, g) {
      const q = Math.pow(clamp(p / .82), 2), open = ease(clamp(p / .25)) * (1 - clamp((p - .85) / .15));
      spr(c, 'karadelik', CX, CY, 560 * open, -t * 2.2, 1, 'screen');
      for (let k = 0; k < 4; k++) for (let j = 0; j < 4; j++) {
        const sx = j * BW / 4, sy = k * BH / 4, ox = BX + sx, oy = BY + sy, a = q * (6 + (k + j) * .4), rr = (1 - q) * Math.hypot(ox + BW / 8 - CX, oy + BH / 8 - CY), ba = Math.atan2(oy + BH / 8 - CY, ox + BW / 8 - CX) + a;
        boardPiece(c, g.__snap, sx, sy, BW / 4, BH / 4, CX + Math.cos(ba) * rr - BW / 8, CY + Math.sin(ba) * rr - BH / 8, a, 1 - q * .95, 1 - q * .6);
      }
      if (p > .85) { const z = (p - .85) / .15; flash(c, (1 - z) * .8, '#ffd9a0'); boom(c, z, CX, CY, .9); }
    } },
    { ad: 'Şimşek fırtınası', vur: .1, ciz(c, p, t, g) {
      boardPiece(c, g.__snap, 0, 0, BW, BH, BX, BY, 0, 1, p > .75 ? 1 - (p - .75) * 4 : 1);
      c.globalAlpha = .35; c.fillStyle = '#0a0f2a'; c.fillRect(0, 0, 540, 960); c.globalAlpha = 1;
      const r = rg(Math.floor(t * 14) * 13);
      for (let k = 0; k < 3; k++) { if (r() < .5) continue; const x = BX + r() * BW, y = BY + r() * BH; bolt(c, x + (r() - .5) * 200, 0, x, y, r, r() < .5 ? '#9ff3ff' : '#e2a6ff', 3); glow(c, x, y, 70, 'rgba(180,240,255,.6)'); if (r() < .3) flash(c, .25, '#cfeaff'); }
    } },
    { ad: 'Lazer kesik', vur: .4, ciz(c, p, t, g) {
      const q = clamp(p / .4), lx = BX - 40 + (BW + 80) * q, ly = BY - 40 + (BH + 80) * q;
      if (p < .4) { boardPiece(c, g.__snap, 0, 0, BW, BH, BX, BY, 0, 1); c.strokeStyle = '#ff2b4a'; c.lineWidth = 4; c.shadowColor = '#ff2b4a'; c.shadowBlur = 20; c.beginPath(); c.moveTo(BX - 40, BY - 40); c.lineTo(lx, ly); c.stroke(); c.shadowBlur = 0; glow(c, lx, ly, 40, 'rgba(255,80,100,.9)'); }
      else {
        const z = (p - .4) / .6;
        c.save(); c.beginPath(); c.moveTo(BX, BY); c.lineTo(BX + BW, BY + BH); c.lineTo(BX + BW, BY); c.closePath(); c.clip(); boardPiece(c, g.__snap, 0, 0, BW, BH, BX + 300 * z * z, BY - 260 * z * z, z * .4, 1); c.restore();
        c.save(); c.beginPath(); c.moveTo(BX, BY); c.lineTo(BX + BW, BY + BH); c.lineTo(BX, BY + BH); c.closePath(); c.clip(); boardPiece(c, g.__snap, 0, 0, BW, BH, BX - 300 * z * z, BY + 300 * z * z, -z * .4, 1); c.restore();
        c.globalAlpha = 1 - z; c.strokeStyle = '#ffd0d8'; c.lineWidth = 6 * (1 - z); c.beginPath(); c.moveTo(BX - 40, BY - 40); c.lineTo(BX + BW + 40, BY + BH + 40); c.stroke(); c.globalAlpha = 1;
      }
    } },
    { ad: 'Işınlanma (warp)', vur: .55, ciz(c, p, t, g) {
      const r = rg(5), sp = ease(p);
      boardPiece(c, g.__snap, 0, 0, BW, BH, BX, BY, 0, 1 - sp * .9, 1 - sp);
      for (let k = 0; k < 180; k++) { const a = r() * Math.PI * 2, d0 = 20 + r() * 300, d1 = d0 + 40 + 900 * sp * (.5 + r()); c.globalAlpha = .3 + .7 * sp; c.strokeStyle = r() < .3 ? '#ffd38a' : '#bfefff'; c.lineWidth = 1 + r() * 1.5; c.beginPath(); c.moveTo(CX + Math.cos(a) * d0, CY + Math.sin(a) * d0); c.lineTo(CX + Math.cos(a) * d1, CY + Math.sin(a) * d1); c.stroke(); }
      c.globalAlpha = 1; if (p > .55) flash(c, (1 - (p - .55) / .45) * .85, '#e6f8ff');
    } },
    { ad: 'Roket', vur: .5, ciz(c, p, t, g) {
      boardPiece(c, g.__snap, 0, 0, BW, BH, BX, BY + (p > .5 ? 0 : Math.sin(t * 60) * 3), 0, 1, 1 - clamp((p - .6) / .4) * .8);
      const ry = 1000 - 1150 * ease(clamp(p / .55)), rx = CX;
      for (let k = 0; k < 18; k++) glow(c, rx + Math.sin(k * 3 + t * 10) * 10 * k / 6, ry + 70 + k * 22, 26 + k * 2, 'rgba(255,' + (210 - k * 6) + ',120,' + (.5 - k * .025) + ')');
      c.fillStyle = '#e6edf3'; c.beginPath(); c.moveTo(rx, ry - 70); c.quadraticCurveTo(rx + 26, ry - 30, rx + 22, ry + 50); c.lineTo(rx - 22, ry + 50); c.quadraticCurveTo(rx - 26, ry - 30, rx, ry - 70); c.fill();
      c.fillStyle = '#ff4d5e'; c.beginPath(); c.moveTo(rx - 22, ry + 20); c.lineTo(rx - 40, ry + 62); c.lineTo(rx - 18, ry + 50); c.fill(); c.beginPath(); c.moveTo(rx + 22, ry + 20); c.lineTo(rx + 40, ry + 62); c.lineTo(rx + 18, ry + 50); c.fill();
      c.fillStyle = '#45e4ff'; c.beginPath(); c.arc(rx, ry - 20, 9, 0, Math.PI * 2); c.fill();
      if (p > .55) { const q = (p - .55) / .45, r = rg(77); for (let b = 0; b < 4; b++) { const fx = 90 + r() * 360, fy = 120 + r() * 200, cols = ['#ff7ad9', '#7ff6ff', '#ffe27a', '#9dff8a']; for (let k = 0; k < 28; k++) { const a = k / 28 * Math.PI * 2, d = 110 * ease(q) * (0.7 + r() * .3); c.globalAlpha = 1 - q; c.fillStyle = cols[b]; c.fillRect(fx + Math.cos(a) * d, fy + Math.sin(a) * d + 60 * q * q, 3, 3); } } c.globalAlpha = 1; }
    } },
    { ad: 'Cam kırılması', vur: .25, ciz(c, p, t, g) {
      if (p < .25) { boardPiece(c, g.__snap, 0, 0, BW, BH, BX, BY, 0, 1); const q = p / .25, r = rg(3); c.strokeStyle = 'rgba(255,220,170,.9)'; c.lineWidth = 2; for (let k = 0; k < 12; k++) { const a = k / 12 * Math.PI * 2 + r() * .3; c.beginPath(); c.moveTo(CX, CY); let x = CX, y = CY; for (let j = 0; j < 5 * q; j++) { x += Math.cos(a + (r() - .5) * .6) * 50; y += Math.sin(a + (r() - .5) * .6) * 50; c.lineTo(x, y); } c.stroke(); } return; }
      const q = (p - .25) / .75, r = rg(11);
      for (let k = 0; k < 8; k++) for (let j = 0; j < 8; j++) { const sx = j * BW / 8, sy = k * BH / 8, d = r(); boardPiece(c, g.__snap, sx, sy, BW / 8, BH / 8, BX + sx + (r() - .5) * 220 * q, BY + sy + (300 + d * 500) * q * q - 80 * q, (r() - .5) * 6 * q, 1, 1 - q); }
      spr(c, 'cam', CX, CY, 420 + 400 * ease(q), q * .6, 1 - q, 'screen');
      flash(c, .5 * (1 - q * 6), '#ffe6c0');
    } },
    { ad: 'Deprem', vur: .2, ciz(c, p, t, g) {
      const sh = p < .7 ? Math.sin(t * 70) * 8 * (1 - p) : 0, r = rg(41);
      if (p < .55) { boardPiece(c, g.__snap, 0, 0, BW, BH, BX + sh, BY, 0, 1); c.strokeStyle = '#ffb15a'; c.lineWidth = 3; c.shadowColor = '#ff6a00'; c.shadowBlur = 14; c.beginPath(); let x = BX, y = CY; c.moveTo(x, y); while (x < BX + BW * clamp(p / .4)) { x += 18 + r() * 20; y = CY + (r() - .5) * 90; c.lineTo(x + sh, y); } c.stroke(); c.shadowBlur = 0; }
      else { const q = (p - .55) / .45; boardPiece(c, g.__snap, 0, 0, BW, BH / 2, BX - 20 * q, BY + 500 * q * q, -q * .3, 1, 1 - q); boardPiece(c, g.__snap, 0, BH / 2, BW, BH / 2, BX + 20 * q, BY + BH / 2 + 620 * q * q, q * .3, 1, 1 - q); glow(c, CX, CY, 260, 'rgba(255,120,30,' + (.7 * (1 - q)) + ')'); }
    } },
    { ad: 'Kedi ve kara delik', vur: .38, ciz(c, p, t, g) {
      /* kedi sağdan gelir, patisiyle tahtayı iter; tahta düşer, altta kara delik açılır */
      const inn = ease(clamp(p / .2)), out = clamp((p - .8) / .2), kx = 600 - 150 * inn + 150 * out, ky = 300;
      const push = clamp((p - .25) / .13), fall = clamp((p - .38) / .45);
      const bx = BX - 40 * push - 120 * fall, by = BY + 900 * fall * fall, rot = -fall * 1.4, sc = 1 - clamp((p - .6) / .25) * .9;
      if (p > .45) {
        const hq = clamp((p - .45) / .1), hr = 70 * hq * (1 - clamp((p - .9) / .1));
        for (let k = 0; k < 4; k++) { c.globalAlpha = .55 * hq; c.strokeStyle = ['#b04dff', '#45e4ff', '#ff7ad9', '#ffffff'][k]; c.lineWidth = 3; c.beginPath(); c.ellipse(CX - 60, 820, Math.max(1, hr * 2.1 - k * 14), Math.max(1, hr * .55 - k * 3), t * (1.5 + k * .4), 0, Math.PI * 2); c.stroke(); }
        c.globalAlpha = 1; c.fillStyle = '#000'; c.beginPath(); c.ellipse(CX - 60, 820, Math.max(.5, hr), Math.max(.5, hr * .32), 0, 0, Math.PI * 2); c.fill();
      }
      if (sc > .05) boardPiece(c, g.__snap, 0, 0, BW, BH, bx + (p > .6 ? (CX - 60 - BW / 2 - bx) * clamp((p - .6) / .25) : 0), Math.min(by, p > .6 ? 820 - BH / 2 : by), rot + (p > .6 ? (p - .6) * 12 : 0), sc);
      c.save(); c.translate(kx, ky);
      c.fillStyle = '#ff9f43'; c.beginPath(); c.ellipse(60, 70, 70, 46, 0, 0, Math.PI * 2); c.fill();
      c.strokeStyle = '#ff9f43'; c.lineWidth = 14; c.lineCap = 'round'; c.beginPath(); c.moveTo(120, 60); c.quadraticCurveTo(170, 20 + Math.sin(t * 6) * 20, 150, -30); c.stroke();
      c.beginPath(); c.arc(0, 20, 42, 0, Math.PI * 2); c.fill();
      c.beginPath(); c.moveTo(-34, -6); c.lineTo(-26, -50); c.lineTo(-6, -18); c.fill(); c.beginPath(); c.moveTo(34, -6); c.lineTo(26, -50); c.lineTo(6, -18); c.fill();
      c.fillStyle = '#d9772a'; for (let k = 0; k < 3; k++) c.fillRect(30 + k * 26, 36, 10, 30);
      const blink = Math.sin(t * 3) > .96;
      c.fillStyle = '#fff'; c.beginPath(); c.ellipse(-15, 14, 9, blink ? 1 : 11, 0, 0, Math.PI * 2); c.ellipse(15, 14, 9, blink ? 1 : 11, 0, 0, Math.PI * 2); c.fill();
      c.fillStyle = '#123'; if (!blink) { c.beginPath(); c.arc(-17 - push * 3, 16, 5, 0, Math.PI * 2); c.arc(13 - push * 3, 16, 5, 0, Math.PI * 2); c.fill(); }
      c.fillStyle = '#ff7a9a'; c.beginPath(); c.moveTo(-4, 30); c.lineTo(4, 30); c.lineTo(0, 35); c.fill();
      c.strokeStyle = '#123'; c.lineWidth = 1.5; c.beginPath(); c.moveTo(0, 35); c.quadraticCurveTo(-6, 42, -10, 38); c.moveTo(0, 35); c.quadraticCurveTo(6, 42, 10, 38); c.stroke();
      c.strokeStyle = '#fff'; c.lineWidth = 1; for (const sgn of [-1, 1]) for (let k = 0; k < 3; k++) { c.beginPath(); c.moveTo(sgn * 20, 32 + k * 4); c.lineTo(sgn * 48, 28 + k * 6); c.stroke(); }
      const paw = Math.sin(push * Math.PI) * 60 + (p < .25 ? Math.sin(t * 12) * 6 * clamp(p / .2) : 0);
      c.fillStyle = '#ff9f43'; c.beginPath(); c.ellipse(-30 - paw, 96, 22, 13, 0, 0, Math.PI * 2); c.fill();
      c.restore();
      if (p > .3 && p < .5) { c.font = '800 22px Oxanium, sans-serif'; c.fillStyle = '#fff'; c.textAlign = 'center'; c.fillText('...', kx - 10, ky - 50); }
      if (p > .62 && p < .95) { c.font = '800 26px Oxanium, sans-serif'; c.textAlign = 'center'; c.fillStyle = '#ffd36b'; c.fillText('MİYAV.', kx + 20, ky - 60); }
      if (p > .88) { const z = (p - .88) / .12; flash(c, (1 - z) * .7, '#e9d6ff'); ring(c, CX - 60, 820, z * 400, 10, '#c784ff', 1 - z); }
    } },
    { ad: 'Lastik ördek', vur: .5, ciz(c, p, t, g) {
      boardPiece(c, g.__snap, 0, 0, BW, BH, BX, BY + (p > .5 ? Math.sin((p - .5) * 30) * 20 * (1 - p) : 0), 0, 1, 1 - clamp((p - .75) / .25));
      const fall = ease(clamp(p / .5)), y = -120 + (BY - 40 + 120) * fall, bounce = p > .5 ? Math.abs(Math.sin((p - .5) * 12)) * 160 * (1 - p) : 0, x = CX + (p > .5 ? (p - .5) * 400 : 0);
      c.save(); c.translate(x, y - bounce); const sq = p > .49 && p < .54 ? .7 : 1; c.scale(1 / sq, sq);
      c.fillStyle = '#ffd93b'; c.beginPath(); c.ellipse(0, 30, 70, 45, 0, 0, Math.PI * 2); c.fill(); c.beginPath(); c.arc(-30, -20, 38, 0, Math.PI * 2); c.fill();
      c.fillStyle = '#ff8a1e'; c.beginPath(); c.ellipse(-70, -14, 22, 10, 0, 0, Math.PI * 2); c.fill();
      c.fillStyle = '#123'; c.beginPath(); c.arc(-38, -30, 6, 0, Math.PI * 2); c.fill(); c.restore();
      if (p > .5 && p < .8) { c.font = '800 34px Oxanium, sans-serif'; c.textAlign = 'center'; c.fillStyle = '#ffffff'; c.fillText('VAAK!', CX, BY - 30); }
    } },
    { ad: 'Plazma dalgası', vur: .5, ciz(c, p, t, g) {
      const wx = -200 + 900 * ease(p);
      c.save(); c.beginPath(); c.rect(wx, 0, 900, 960); c.clip(); boardPiece(c, g.__snap, 0, 0, BW, BH, BX, BY, 0, 1); c.restore();
      const gr = c.createLinearGradient(wx - 160, 0, wx + 40, 0); gr.addColorStop(0, 'rgba(0,0,0,0)'); gr.addColorStop(.7, 'rgba(80,230,255,.7)'); gr.addColorStop(1, 'rgba(240,255,255,.95)');
      c.fillStyle = gr; c.beginPath(); c.moveTo(wx - 160, 0); for (let y = 0; y <= 960; y += 20) c.lineTo(wx + Math.sin(y * .02 + t * 9) * 26, y); c.lineTo(wx - 160, 960); c.closePath(); c.fill();
      debris(c, (p * 3) % 1, wx, CY, 40, Math.floor(p * 3), ['#bff8ff', '#45e4ff'], .6);
    } }
  ];
  NS.SINEMA = SAHNE.map(s => s.ad);


  function spr(c, n, x, y, w, rot, a, op) { const im = gimg('fx-' + n + '.webp'); if (!(im.complete && im.naturalWidth)) return; const h = w * im.naturalHeight / im.naturalWidth; c.save(); c.globalAlpha = a == null ? 1 : a; c.globalCompositeOperation = op || 'screen'; c.translate(x, y); c.rotate(rot || 0); c.drawImage(im, -w / 2, -h / 2, w, h); c.restore(); }
  function boom(c, q, x, y, s) { if (q <= 0 || q >= 1) return; const k = .35 + 1.25 * ease(q); spr(c, 'patlama', x, y, 520 * k * (s || 1), 0, 1 - q * q, 'lighter'); }

  /* ---------- Sinematik sesleri (sentez): giriş + vuruş, sahneye özel ---------- */
  let REV = null;
  function out(g) {
    const ac = g.audio; if (!ac || g.record.muted) return null;
    if (!REV || REV.context !== ac) { const len = ac.sampleRate * 2.2, b = ac.createBuffer(2, len, ac.sampleRate); for (let ch = 0; ch < 2; ch++) { const d = b.getChannelData(ch); for (let i = 0; i < len; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / len, 3); } REV = ac.createConvolver(); REV.buffer = b; const rg2 = ac.createGain(); rg2.gain.value = .35; REV.connect(rg2); rg2.connect(g.master || ac.destination); }
    const o = ac.createGain(); o.gain.value = .9; o.connect(g.master || ac.destination); o.connect(REV); return o;
  }
  function nz(ac, d) { const b = ac.createBuffer(1, ac.sampleRate * d | 0, ac.sampleRate), x = b.getChannelData(0); for (let i = 0; i < x.length; i++) x[i] = Math.random() * 2 - 1; const s = ac.createBufferSource(); s.buffer = b; return s; }
  function N(ac, dst, t, d, type, f0, f1, q, a, pk) { const n = nz(ac, d), f = ac.createBiquadFilter(); f.type = type; f.Q.value = q; f.frequency.setValueAtTime(f0, t); f.frequency.exponentialRampToValueAtTime(Math.max(20, f1), t + d); const e = ac.createGain(); e.gain.setValueAtTime(0, t); e.gain.linearRampToValueAtTime(pk, t + a); e.gain.exponentialRampToValueAtTime(.001, t + d); n.connect(f); f.connect(e); e.connect(dst); n.start(t); n.stop(t + d + .05); }
  function O(ac, dst, t, d, type, f0, f1, a, pk) { const o = ac.createOscillator(); o.type = type; o.frequency.setValueAtTime(f0, t); o.frequency.exponentialRampToValueAtTime(Math.max(20, f1), t + d); const e = ac.createGain(); e.gain.setValueAtTime(0, t); e.gain.linearRampToValueAtTime(pk, t + a); e.gain.exponentialRampToValueAtTime(.001, t + d); o.connect(e); e.connect(dst); o.start(t); o.stop(t + d + .05); }
  function boomS(ac, o, t, big) { O(ac, o, t, 1.4 * big, 'sine', 90, 28, .005, 1); O(ac, o, t, .5, 'triangle', 160, 40, .003, .5); N(ac, o, t, 1.8 * big, 'lowpass', 2400, 120, .7, .01, .9); N(ac, o, t + .02, .35, 'highpass', 3000, 1200, .5, .002, .35); for (let k = 0; k < 10; k++) N(ac, o, t + .15 + Math.random() * .9, .12, 'bandpass', 1500 + Math.random() * 2500, 800, 4, .002, .15); }
  const SES = [
    /* göktaşı */ { gir: (ac, o, t) => { N(ac, o, t, 1.2, 'bandpass', 300, 2800, 1.5, .9, .7); O(ac, o, t, 1.2, 'sawtooth', 70, 40, 1, .12); }, vur: (ac, o, t) => boomS(ac, o, t, 1.2) },
    /* gezegen */ { gir: (ac, o, t) => { O(ac, o, t, .4, 'sine', 50, 30, .3, .5); }, vur: (ac, o, t) => { boomS(ac, o, t, 1.6); O(ac, o, t + .1, 2.2, 'sawtooth', 55, 30, .05, .15); } },
    /* tokmak */ { gir: (ac, o, t) => { O(ac, o, t, .35, 'sawtooth', 70, 48, .05, .08); N(ac, o, t, .35, 'bandpass', 400, 250, 3, .1, .15); N(ac, o, t + .5, .6, 'bandpass', 260, 2400, 1.8, .56, .8); O(ac, o, t + .5, .6, 'sine', 70, 150, .56, .2); }, vur: (ac, o, t) => { O(ac, o, t, .9, 'square', 110, 35, .002, .7); O(ac, o, t, 1.6, 'triangle', 1800, 1500, .002, .25); O(ac, o, t, 1.4, 'sine', 2730, 2600, .002, .12); boomS(ac, o, t, .9); for (let k = 0; k < 16; k++) N(ac, o, t + .08 + Math.random() * .8, .09 + Math.random() * .1, 'bandpass', 400 + Math.random() * 900, 200, 3, .002, .22); } },
    /* ok */ { gir: (ac, o, t) => { for (let k = 0; k < 18; k++) N(ac, o, t + k * .07 + Math.random() * .04, .25, 'bandpass', 4000, 900, 6, .02, .25); }, vur: (ac, o, t) => { for (let k = 0; k < 22; k++) { const tt = t + k * .055 + Math.random() * .03; O(ac, o, tt, .12, 'square', 220, 80, .001, .25); N(ac, o, tt, .08, 'highpass', 5000, 2000, 1, .001, .2); } } },
    /* kara delik */ { gir: (ac, o, t) => { O(ac, o, t, 2.4, 'sawtooth', 40, 400, 1.8, .25); N(ac, o, t, 2.4, 'bandpass', 150, 3000, 3, 2, .4); }, vur: (ac, o, t) => { O(ac, o, t, .6, 'sine', 900, 40, .002, .6); boomS(ac, o, t + .05, 1); } },
    /* cam */ { gir: (ac, o, t) => { for (let k = 0; k < 6; k++) O(ac, o, t + k * .08, .1, 'triangle', 3000 + k * 300, 2500, .002, .15); }, vur: (ac, o, t) => { for (let k = 0; k < 40; k++) { const tt = t + Math.random() * .7; O(ac, o, tt, .25 + Math.random() * .4, 'triangle', 2500 + Math.random() * 4000, 2000, .001, .12); } N(ac, o, t, .9, 'highpass', 6000, 2500, .7, .002, .6); } }
  ];
  const SIDX = { 0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 9: 5 };
  function cineSound(g, i, part) { const ac = g.audio, o = out(g); if (!o) return; const S = SES[SIDX[i]]; if (!S) return; try { S[part](ac, o, ac.currentTime + .01); } catch (e) { console.log('SESHATA', e.message); } if (part === 'vur' && g.say) { const L = g.level || 1, id = (g.cfg && g.cfg.boss) ? 'fatality' : ['obliterated', 'brutal', 'sector', 'unstoppable', 'fatality'][L % 5]; setTimeout(() => { try { g.say(id); } catch (_) {} }, 380); }
    if (part === 'vur' && navigator.vibrate) try { navigator.vibrate([90, 40, 160]); } catch (_) {} }
  const IYI = [0, 1, 2, 3, 4, 9];
  ['meteor', 'patlama', 'tokmak', 'karadelik', 'ok', 'cam'].forEach(n => gimg('fx-' + n + '.webp')); gimg('gezegen-carpisma.webp');
  function pick(g) {
    const L = g.level || 1;
    if (g.cfg && g.cfg.boss) return [1, 4, 0, 2, 9, 1, 4, 0][(L / 5 | 0) % 8];
    if (typeof globalThis.NEON_SINEMA === 'number') return globalThis.NEON_SINEMA % SAHNE.length;
    return IYI[(L * 7 + 3) % IYI.length];
  }

  const updPrev = P.update;
  P.update = function (dt) {
    const before = this.state;
    const r = updPrev.apply(this, arguments);
    if (before === 'chain' && this.state === 'complete' && !this.record.reduced && globalThis.NEON_SINEMA !== false) {
      let snap = null;
      try { const d = this.canvas.width / 540; snap = document.createElement('canvas'); snap.width = Math.round(BW * d); snap.height = Math.round(BH * d); snap.getContext('2d').drawImage(this.canvas, BX * d, BY * d, BW * d, BH * d, 0, 0, snap.width, snap.height); } catch (_) { snap = null; }
      this.__snap = snap; this.__cine = { i: pick(this), t0: now(), hit: false }; cineSound(this, this.__cine.i, 'gir');
    }
    if (this.state !== 'complete' && !(this.__cine && this.__cine.demo)) this.__cine = null;
    return r;
  };
  /* önizleme: sahneyi doğrudan oynat (vitrin sayfası için) */
  NS.cineDemo = function (g, i) {
    let snap = null;
    try { const d = g.canvas.width / 540; snap = document.createElement('canvas'); snap.width = Math.round(BW * d); snap.height = Math.round(BH * d); snap.getContext('2d').drawImage(g.canvas, BX * d, BY * d, BW * d, BH * d, 0, 0, snap.width, snap.height); } catch (_) {}
    g.__snap = snap; g.__cine = { i: i, t0: now(), hit: false, demo: true }; cineSound(g, i, 'gir');
  };
  const renderPrev = P.render;
  P.render = function () {
    const k = this.__cine;
    if (!k) return renderPrev.apply(this, arguments);
    const e = now() - k.t0, p = e / DUR, s = SAHNE[k.i];
    if (p >= 1) { this.__cine = null; this.__snap = null; try { this.playZafer && this.playZafer(); } catch (_) {} return renderPrev.apply(this, arguments); }
    const c = this.ctx;
    if (!k.hit && p >= s.vur) { k.hit = true; if (SES[SIDX[k.i]]) cineSound(this, k.i, 'vur'); else try { this.sfx('blast'); } catch (_) {} }
    const shake = k.hit ? Math.max(0, 1 - (p - s.vur) * 5) * 9 : 0, tt = performance.now();
    c.save(); c.translate(Math.sin(tt * .09) * shake, Math.cos(tt * .07) * shake * .7);
    renderPrev.apply(this, arguments);
    c.restore();
    this.hits = [];
    c.save();
    c.globalAlpha = .82; c.fillStyle = '#050812'; c.fillRect(0, 0, 540, 960); c.globalAlpha = 1;
    c.translate(Math.sin(tt * .11) * shake, Math.cos(tt * .08) * shake * .7);
    s.ciz(c, p, now(), this);
    c.restore();
    c.save(); c.globalAlpha = Math.min(1, p * 4) * Math.min(1, (1 - p) * 4); c.font = '700 15px "Barlow Condensed", sans-serif'; c.textAlign = 'center'; c.fillStyle = '#9fb6cc'; c.fillText('BÖLÜM ' + this.level + ' TEMİZLENDİ', 270, 900); c.restore();
  };
})();
